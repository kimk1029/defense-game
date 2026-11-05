extends RefCounted
## "Reasonable player" bot shared by tools/balance_sim.gd and tests/test_balance.gd (SPEC-07).
## Builds on spots covering the most path, rotates a mixed build order and
## mixes in upgrades once it has a base.

const BUILD_ORDER := [&"ballista", &"gatling", &"frost", &"mortar", &"lightning",
	&"sniper", &"poison", &"ballista", &"drone", &"laser", &"relay", &"gatling"]
const UPGRADE_AFTER := 4

var main  # GameMain
var spots: Array = []
var build_index := 0

func _init(p_main) -> void:
	main = p_main
	spots = _rank_spots()

func _rank_spots() -> Array:
	var curve: Curve2D = main.path.curve
	var blen := curve.get_baked_length()
	var pts := []
	for i in 160:
		pts.append(curve.sample_baked(blen * i / 159.0) + main.path.position)
	var out := []
	for y in range(40, 1150, 40):
		for x in range(30, 700, 40):
			var p := Vector2(x, y)
			var score := 0
			for q in pts:
				if p.distance_to(q) <= 180.0:
					score += 1
			out.append([score, p])
	out.sort_custom(func(a, b): return a[0] > b[0])
	return out

func step() -> void:
	var next_id: StringName = BUILD_ORDER[build_index % BUILD_ORDER.size()]
	var build_cost := TowerRegistry.get_cost(next_id)
	var towers: Array = main.towers_root.get_children()
	if towers.size() >= UPGRADE_AFTER:
		var best = null
		for tw in towers:
			if tw.level < Tower.MAX_LEVEL_INDEX and (best == null or tw.level < best.level):
				best = tw
		if best != null and best.upgrade_cost() <= build_cost and best.level < towers.size() / 3:
			if GameState.gold >= best.upgrade_cost():
				best.try_upgrade()
			return
	if GameState.gold < build_cost:
		return
	main.placement.begin_placement(next_id)
	for s in spots:
		if main.placement._is_valid(s[1]):
			main.placement.place_at(s[1])
			build_index += 1
			return
	main.placement._cancel()
