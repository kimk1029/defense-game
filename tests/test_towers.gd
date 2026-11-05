extends "res://tests/test_base.gd"
## SPEC-01

const IDS := [&"ballista", &"gatling", &"frost", &"lightning", &"sniper",
	&"mortar", &"poison", &"laser", &"relay", &"drone"]

func _tower(id: StringName) -> Tower:
	var root: Node2D = spawn(Node2D.new())
	var enemies := Node2D.new()
	var projs := Node2D.new()
	root.add_child(enemies)
	root.add_child(projs)
	var t := Tower.new()
	root.add_child(t)
	t.setup(id, enemies, projs)
	return t

func test_ac01_1_ids() -> void:
	var ids := TowerRegistry.get_all_ids()
	eq(ids.size(), 10, "10 towers")
	for id in IDS:
		check(ids.has(id), "has %s" % id)

func test_ac01_2_integrity() -> void:
	for id in IDS:
		var td := TowerRegistry.get_tower(id)
		for key in ["damage", "attack_speed", "range", "cost_curve"]:
			eq((td[key] as Array).size(), 5, "%s.%s len" % [id, key])
		for key in ["damage", "attack_speed", "range"]:
			var arr: Array = td[key]
			for i in range(1, 5):
				check(float(arr[i]) >= float(arr[i - 1]), "%s.%s non-decreasing at %d" % [id, key, i])
		check(int(td["cost"]) > 0, "%s cost" % id)
		var b: Object = (td["behavior_script"] as Script).new()
		check(b is TowerBehavior, "%s behavior type" % id)
		b.free()

func test_ac01_3_upgrade_cost() -> void:
	var t := _tower(&"ballista")
	eq(t.upgrade_cost(), 70, "100*0.7")
	t.level = 1
	eq(t.upgrade_cost(), 100, "100*1.0")
	t.level = 3
	eq(t.upgrade_cost(), 200, "100*2.0")
	t.level = 4
	eq(t.upgrade_cost(), 0, "max level")

func test_ac01_4_try_upgrade() -> void:
	var t := _tower(&"gatling")
	GameState.gold = 1000
	check(t.try_upgrade(), "upgrade ok")
	eq(t.level, 1, "level 1")
	eq(GameState.gold, 1000 - 84, "paid 120*0.7")
	eq(t.total_invested, 120 + 84, "invested")
	near(t.damage, 8.05, "stats moved to next level")
	GameState.gold = 10
	check(not t.try_upgrade(), "insufficient gold")
	eq(t.level, 1, "level unchanged")
	eq(GameState.gold, 10, "gold unchanged")
	GameState.gold = 100000
	for i in 3:
		check(t.try_upgrade(), "upgrade %d" % (i + 2))
	eq(t.level, 4, "max")
	var g := GameState.gold
	check(not t.try_upgrade(), "no beyond max")
	eq(GameState.gold, g, "no charge at max")

func test_ac01_5_sell() -> void:
	var t := _tower(&"sniper")
	eq(t.sell_refund(), 98, "140*0.7")
	t.total_invested = 333
	eq(t.sell_refund(), 233, "floor")

func test_ac01_6_next_stats() -> void:
	var t := _tower(&"frost")
	var n := t.next_level_stats()
	near(float(n["damage"]), 16.1, "next dmg")
	t.level = 4
	eq(t.next_level_stats(), {}, "empty at max")
