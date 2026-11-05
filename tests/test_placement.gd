extends "res://tests/test_base.gd"
## SPEC-04

func _setup() -> PlacementSystem:
	var root: Node2D = spawn(Node2D.new())
	var path := Path2D.new()
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2(0, 400))
	path.curve.add_point(Vector2(720, 400))
	root.add_child(path)
	var towers := Node2D.new()
	var enemies := Node2D.new()
	var projs := Node2D.new()
	for n in [towers, enemies, projs]:
		root.add_child(n)
	var ps := PlacementSystem.new()
	root.add_child(ps)
	ps.setup(towers, path, enemies, projs)
	return ps

func test_ac04_1_states() -> void:
	var ps := _setup()
	check(not ps.is_placing(), "idle")
	ps.begin_placement(&"ballista")
	check(ps.is_placing(), "ghost")
	ps._cancel()
	check(not ps.is_placing(), "cancel -> idle")

func test_ac04_2_validity() -> void:
	var ps := _setup()
	GameState.gold = 1000
	ps.begin_placement(&"ballista")
	var vp := ps.get_viewport_rect().size
	check(ps._is_valid(Vector2(300, 200)), "open ground ok")
	check(not ps._is_valid(Vector2(300, 420)), "near path")
	check(not ps._is_valid(Vector2(5, 200)), "left edge")
	check(not ps._is_valid(Vector2(300, vp.y - 100)), "bottom UI")
	var t := Tower.new()
	ps.towers_root.add_child(t)
	t.setup(&"ballista", ps.enemies_root, ps.projectiles_root)
	t.global_position = Vector2(300, 200)
	check(not ps._is_valid(Vector2(330, 200)), "too close to tower")
	check(ps._is_valid(Vector2(360, 200)), "46px+ away ok")
	GameState.gold = 10
	check(not ps._is_valid(Vector2(500, 200)), "insufficient gold")

func test_ac04_3_place() -> void:
	var ps := _setup()
	GameState.gold = 500
	var placed := []
	ps.placed.connect(func(t): placed.append(t))
	ps.begin_placement(&"frost")
	ps.place_at(Vector2(300, 200))
	eq(GameState.gold, 370, "paid 130")
	eq(ps.towers_root.get_child_count(), 1, "tower added")
	eq(placed.size(), 1, "placed signal")
	check(not ps.is_placing(), "back to idle")
