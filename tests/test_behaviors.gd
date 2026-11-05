extends "res://tests/test_base.gd"
## SPEC-05

var _enemies: Node2D
var _projs: Node2D
var _towers: Node2D

func _world() -> void:
	var root: Node2D = spawn(Node2D.new())
	_enemies = Node2D.new()
	_projs = Node2D.new()
	_towers = Node2D.new()
	for n in [_enemies, _projs, _towers]:
		root.add_child(n)

func _tower(id: StringName, pos: Vector2, level: int = 0) -> Tower:
	var t := Tower.new()
	_towers.add_child(t)
	t.setup(id, _enemies, _projs)
	t.global_position = pos
	t.level = level
	t._apply_level_stats()
	t.set_process(false)
	return t

## Enemy registered under _enemies (towers scan that node).
func _enemy(pos: Vector2, hp: float = 1000.0, progress: float = 0.0) -> Enemy:
	var e := make_enemy(hp, 0.0, progress, pos)
	e.reparent(_enemies)
	e.global_position = pos
	return e

func test_ac05_1_first_target() -> void:
	_world()
	var t := _tower(&"ballista", Vector2.ZERO)
	var a := _enemy(Vector2(50, 0), 100, 100)
	var b := _enemy(Vector2(60, 0), 100, 400)
	eq(t.behavior.select_target([a, b]), b, "highest progress")

func test_ac05_2_relay_aura() -> void:
	_world()
	var g := _tower(&"gatling", Vector2(100, 100))
	near(g._compute_aura_bonus(), 0.0, "no relay")
	var r1 := _tower(&"relay", Vector2(150, 100))
	near(g._compute_aura_bonus(), 0.12, "lv1 relay")
	r1.level = 2
	near(g._compute_aura_bonus(), 0.20, "lv3 relay 0.12+0.08")
	for i in 4:
		_tower(&"relay", Vector2(100, 150 + i * 10), 4)
	near(g._compute_aura_bonus(), 0.60, "capped")
	near(r1._compute_aura_bonus(), 0.0, "relay gets none")
	var far := _tower(&"gatling", Vector2(600, 600))
	near(far._compute_aura_bonus(), 0.0, "out of range")

func test_ac05_3_lightning_chain_skips_dead() -> void:
	_world()
	var t := _tower(&"lightning", Vector2.ZERO)
	var first := _enemy(Vector2(50, 0))
	var dead := _enemy(Vector2(80, 0))
	dead.dead = true
	var alive := _enemy(Vector2(140, 0))
	t.behavior.fire(first)
	check(first.current_hp < 1000.0, "primary hit")
	near(dead.current_hp, 1000.0, "dead enemy not chained")
	check(alive.current_hp < 1000.0, "chain reaches next live enemy")
	near(1000.0 - alive.current_hp, 18.0 * 0.7, "first hop falloff")

func test_ac05_3_chain_count() -> void:
	for case in [[0, 2], [1, 3], [3, 3], [4, 4]]:
		cleanup()
		_world()
		var t := _tower(&"lightning", Vector2.ZERO, case[0])
		var es := []
		for i in 7:
			es.append(_enemy(Vector2(40 + i * 60, 0)))
		t.behavior.fire(es[0])
		var hit := 0
		for e in es:
			if e.current_hp < 1000.0:
				hit += 1
		eq(hit, 1 + case[1], "lv%d chains %d" % [case[0] + 1, case[1]])

func test_ac05_4_mortar_min_range() -> void:
	_world()
	var t := _tower(&"mortar", Vector2.ZERO)
	var close := _enemy(Vector2(30, 0), 100, 900)
	var ok := _enemy(Vector2(100, 0), 100, 10)
	eq(t.behavior.select_target([close, ok]), ok, "skips < 60px")
	eq(t.behavior.select_target([close]), null, "none if only close")

func test_ac05_5_drone_count() -> void:
	for case in [[0, 2], [1, 2], [2, 3], [3, 3], [4, 4]]:
		cleanup()
		_world()
		var t := _tower(&"drone", Vector2.ZERO, case[0])
		for i in 6:
			_enemy(Vector2(40 + i * 20, 0))
		t.behavior.fire(null)
		eq(_projs.get_child_count(), case[1], "lv%d drones" % (case[0] + 1))

func test_ac05_6_frost_slow() -> void:
	for case in [[0, 0.20], [1, 0.25], [3, 0.25], [4, 0.35]]:
		cleanup()
		_world()
		var t := _tower(&"frost", Vector2.ZERO, case[0])
		var e := _enemy(Vector2(50, 0))
		t.behavior.fire(e)
		var p: Projectile = _projs.get_child(0)
		var slow_mag := -1.0
		for d in p.payload.debuffs:
			if d.kind == StatusEffect.Kind.SLOW:
				slow_mag = d.magnitude
		near(slow_mag, case[1], "lv%d slow" % (case[0] + 1))
