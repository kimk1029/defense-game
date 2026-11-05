extends "res://tests/test_base.gd"
## SPEC-06

func _main(stage: int) -> GameMain:
	GameState.selected_stage = stage
	var m: GameMain = load("res://scenes/main.tscn").instantiate()
	spawn(m)
	await tree.process_frame
	return m

func test_ac06_1_game_state() -> void:
	GameState.gold = 1; GameState.life = 1; GameState.wave = 9
	GameState.reset_run()
	eq([GameState.gold, GameState.life, GameState.wave], [150, 20, 0], "reset")
	check(not GameState.spend_gold(151), "insufficient")
	eq(GameState.gold, 150, "unchanged")
	check(GameState.spend_gold(150), "exact spend")
	eq(GameState.gold, 0, "zero")

func test_ac06_2_smoke_all_stages() -> void:
	for stage in [1, 2, 3, 4]:
		var m := await _main(stage)
		GameState.gold = 5000
		var placed := 0
		for y in range(150, 1100, 90):
			for x in range(60, 700, 90):
				if placed >= 8:
					break
				m.placement.begin_placement(TowerRegistry.get_all_ids()[placed % 10])
				if m.placement._is_valid(Vector2(x, y)):
					m.placement.place_at(Vector2(x, y))
					placed += 1
				else:
					m.placement._cancel()
		check(placed >= 6, "stage %d: placed %d towers" % [stage, placed])
		m.spawner.between_timer = 0.0
		Engine.time_scale = 8.0
		for i in 500:
			await tree.process_frame
		Engine.time_scale = 1.0
		check(GameState.wave >= 1, "stage %d progressed (wave %d)" % [stage, GameState.wave])
		print("   stage %d: wave=%d gold=%d life=%d" % [stage, GameState.wave, GameState.gold, GameState.life])
		cleanup()
		GameState.reset_run()

func test_ac06_3_kill_leak_gameover() -> void:
	var m := await _main(1)
	var g0 := GameState.gold
	m._on_enemy_killed(7)
	eq(GameState.gold, g0 + 7, "kill gold")
	m._on_enemy_reached_base(3)
	eq(GameState.life, 17, "leak")
	check(not m.game_over_active, "alive")
	m._on_enemy_reached_base(17)
	check(m.game_over_active, "game over at 0")
	check(not m.spawner.is_processing(), "spawner stopped")
