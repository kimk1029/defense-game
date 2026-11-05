extends SceneTree
## Headless balance simulation (SPEC-07).
##   godot --headless --fixed-fps 60 --path . -s tools/balance_sim.gd -- [stages=1,2,3,4] [max_wave=40] [seed=1]
## --fixed-fps makes every frame exactly 1/60s, so runs are deterministic and fast.

const SimBot := preload("res://tools/sim_bot.gd")

func _initialize() -> void:
	_run.call_deferred()

func _arg(i: int, def: String) -> String:
	var a := OS.get_cmdline_user_args()
	return a[i] if a.size() > i else def

func _run() -> void:
	var stages: Array = Array(_arg(0, "1,2,3,4").split(",")).map(func(x): return int(x))
	var max_wave := int(_arg(1, "40"))
	var sd := int(_arg(2, "1"))
	var report: Array = []
	for stage in stages:
		seed(sd)
		report.append(await _sim(stage, max_wave, sd))
	print("\n==== BALANCE REPORT (seed %d) ====" % sd)
	for r in report:
		print("stage %d  reached wave %-3d %s  towers=%d  lv_sum=%d" % [
			r["stage"], r["wave"], "(survived)" if r["survived"] else "(game over)",
			r["towers"], r["lv_sum"]])
		print("   life by wave : ", r["life_curve"])
		print("   gold by wave : ", r["gold_curve"])
		print("   first leak at wave %d, sim %.0fs" % [r["first_leak"], r["sim_time"]])
		var lc: Array = r["life_curve"]
		var early_loss: int = BalanceConfig.START_LIFE - (int(lc[2]) if lc.size() >= 3 else int(lc.back()) if not lc.is_empty() else 0)
		print("SUMMARY stage=%d wave=%d first_leak=%d early_loss=%d" % [r["stage"], r["wave"], r["first_leak"], early_loss])
	quit()

func _sim(stage: int, max_wave: int, sd: int) -> Dictionary:
	GameState.selected_stage = stage
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.spawner.rng.seed = sd
	var bot = SimBot.new(m)
	var life_curve := []
	var gold_curve := []
	var first_leak := 0
	var last_wave := 0
	var t := 0.0
	while true:
		await process_frame
		t += 1.0 / 60.0
		if GameState.wave != last_wave:
			if last_wave > 0:
				life_curve.append(GameState.life)
				gold_curve.append(GameState.gold)
			last_wave = GameState.wave
		if first_leak == 0 and GameState.life < BalanceConfig.START_LIFE:
			first_leak = GameState.wave
		if m.game_over_active or GameState.wave > max_wave:
			break
		bot.step()
	var lv_sum := 0
	for tw in m.towers_root.get_children():
		lv_sum += tw.level + 1
	var res := {"stage": stage, "wave": GameState.wave, "survived": not m.game_over_active,
		"life_curve": life_curve, "gold_curve": gold_curve, "first_leak": first_leak,
		"towers": m.towers_root.get_child_count(), "lv_sum": lv_sum, "sim_time": t}
	m.queue_free()
	await process_frame
	GameState.reset_run()
	return res
