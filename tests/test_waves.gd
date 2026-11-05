extends "res://tests/test_base.gd"
## SPEC-03

func _spawner(seed: int = 1) -> WaveSpawner:
	var s := WaveSpawner.new()
	s.rng.seed = seed
	return s

func _count(q: Array) -> Dictionary:
	var d := {}
	for t in q:
		d[t] = d.get(t, 0) + 1
	return d

func test_ac03_1_size() -> void:
	var s := _spawner()
	for w in range(1, 31):
		eq(s._build_wave(w).size(), 6 + 2 * w, "size w=%d" % w)
	s.free()

func test_ac03_2_unlocks() -> void:
	var s := _spawner(5)
	for i in 50:
		eq(_count(s._build_wave(1)).keys(), [0], "w1 type0 only")
		check(not _count(s._build_wave(2)).has(2), "no tank w2")
	var seen := {}
	for i in 50:
		for k in _count(s._build_wave(3)).keys():
			seen[k] = true
	check(seen.has(1) and seen.has(2), "types 1 and 2 appear by w3")
	s.free()

func test_ac03_3_deterministic() -> void:
	var a := _spawner(42)
	var b := _spawner(42)
	for w in [3, 8, 15]:
		eq(a._build_wave(w), b._build_wave(w), "same seed same wave %d" % w)
	a.free(); b.free()

func test_ac03_4_enemy_stats() -> void:
	var s0 := WaveSpawner.enemy_stats(0, 4)
	near(s0["hp"], 44.0, "runner hp")
	near(s0["speed"], 105.0, "runner speed")
	var s2 := WaveSpawner.enemy_stats(2, 8)
	near(s2["hp"], 110.0 + 14.0 * 8, "tank hp")
	near(s2["armor"], 5.0, "tank armor 3+0.25w")
	eq(s2["gold"], 10, "tank gold")
	eq(s2["dmg"], 2, "tank base dmg")

func test_ac03_5_flow() -> void:
	var root: Node2D = spawn(Node2D.new())
	var path := Path2D.new()
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2.ZERO)
	path.curve.add_point(Vector2(50, 0))
	root.add_child(path)
	var enemies := Node2D.new()
	root.add_child(enemies)
	var s := WaveSpawner.new()
	root.add_child(s)
	s.setup(path, enemies, null)
	var log := []
	s.wave_started.connect(func(w): log.append("start%d" % w))
	s.wave_cleared.connect(func(w): log.append("clear%d" % w))
	s.enemy_reached_base.connect(func(d): log.append("leak"))
	s.between_timer = 0.0
	Engine.time_scale = 20.0
	for i in 400:
		await tree.process_frame
		if log.has("clear1"):
			break
	Engine.time_scale = 1.0
	check(log.has("start1"), "wave_started")
	eq(log.count("leak"), 8, "all 8 leaked on a 50px path")
	check(log.has("clear1"), "wave_cleared after all resolved")
