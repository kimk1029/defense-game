extends "res://tests/test_base.gd"
## SPEC-07 (run with --fixed-fps 60 for determinism)

const SimBot := preload("res://tools/sim_bot.gd")

func test_ac07_1_early_fairness_all_stages() -> void:
	for stage in [1, 2, 3, 4]:
		seed(1)
		GameState.reset_run()
		GameState.selected_stage = stage
		var m: GameMain = load("res://scenes/main.tscn").instantiate()
		spawn(m)
		await tree.process_frame
		m.spawner.rng.seed = 1
		m.spawner.between_timer = 0.0
		var bot = SimBot.new(m)
		var frames := 0
		while GameState.wave <= 3 and not m.game_over_active and frames < 60 * 240:
			bot.step()
			await tree.process_frame
			frames += 1
		var lost := BalanceConfig.START_LIFE - GameState.life
		check(lost <= 2, "stage %d: life lost in waves 1-3 = %d (<= 2)" % [stage, lost])
		check(GameState.wave >= 4, "stage %d reached wave 4 (got %d)" % [stage, GameState.wave])
		print("   stage %d: waves 1-3 lost %d life, towers %d" % [stage, lost, m.towers_root.get_child_count()])
		cleanup()

func test_ac07_5_prep_times() -> void:
	var s := WaveSpawner.new()
	s.setup(null, null, null)
	near(s.between_timer, 15.0, "first prep 15s")
	s.free()
	near(BalanceConfig.BETWEEN_WAVES_TIME, 5.0, "between waves 5s")

func test_ac07_6_config_drives_stats() -> void:
	eq(BalanceConfig.START_GOLD, GameState.gold, "start gold from config")
	near(BalanceConfig.hp_curve(1), 1.0, "no extra hp at wave 1")
	check(BalanceConfig.hp_curve(30) > BalanceConfig.hp_curve(20), "superlinear growth")
	near(BalanceConfig.stage_hp_mult(3, 1), 1.0, "stage mult ramps from 1.0")
	near(BalanceConfig.stage_hp_mult(3, 7), float(BalanceConfig.STAGE_HP_MULT[3]), "full by wave 7")
	var a := WaveSpawner.enemy_stats(2, 10, 1)
	var b := WaveSpawner.enemy_stats(2, 10, 3)
	near(b["hp"] / a["hp"], BalanceConfig.stage_hp_mult(3, 10) / BalanceConfig.stage_hp_mult(1, 10), "stage mult applied")
	eq(BalanceConfig.wave_clear_bonus(5), 20, "clear bonus 10+2w")

func test_ac07_6_clear_bonus_paid() -> void:
	GameState.selected_stage = 1
	var m: GameMain = load("res://scenes/main.tscn").instantiate()
	spawn(m)
	await tree.process_frame
	var g := GameState.gold
	m._on_wave_cleared(5)
	eq(GameState.gold, g + 20, "bonus paid on clear")
