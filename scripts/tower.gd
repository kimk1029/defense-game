class_name Tower
extends Node2D

# 포탑 베이스.
# 공통 로직(사거리/쿨다운/타겟 선정)만 담당하고 고유 로직은 TowerBehavior에 위임.

signal leveled_up(new_level: int)

const MAX_LEVEL_INDEX: int = 4   # 0-indexed → Lv5

var tower_id: StringName = &""
var tower_data: Dictionary = {}
var level: int = 0
var total_invested: int = 0

# 런타임 스탯(레벨별 테이블에서 계산됨)
var damage: float = 0.0
var attack_speed: float = 1.0
var attack_range: float = 150.0
var cooldown: float = 0.0

# 참조
var enemies_root: Node2D = null
var projectiles_root: Node2D = null
var behavior: TowerBehavior = null

func _ready() -> void:
	z_index = 4

func setup(id: StringName, enemies: Node2D, projectiles: Node2D) -> void:
	tower_id = id
	tower_data = TowerRegistry.get_tower(id)
	enemies_root = enemies
	projectiles_root = projectiles
	total_invested = int(tower_data["cost"])
	_spawn_behavior()
	_apply_level_stats()

func _spawn_behavior() -> void:
	var script: Script = tower_data["behavior_script"]
	var inst: Object = script.new()
	behavior = inst as TowerBehavior
	if behavior == null:
		push_error("Behavior script is not a TowerBehavior: %s" % tower_id)
		return
	behavior.tower = self
	add_child(behavior)

func _apply_level_stats() -> void:
	if tower_data.is_empty():
		return
	var dmg: Array = tower_data["damage"]
	var spd: Array = tower_data["attack_speed"]
	var rng: Array = tower_data["range"]
	damage       = float(dmg[level])
	attack_speed = float(spd[level])
	attack_range = float(rng[level])
	queue_redraw()

func _process(delta: float) -> void:
	if tower_data.is_empty():
		return
	cooldown -= delta
	if cooldown > 0.0:
		return
	var in_range: Array = _enemies_in_range()
	var target: Enemy = behavior.select_target(in_range)
	if target == null:
		return
	behavior.fire(target)
	cooldown = 1.0 / maxf(0.05, attack_speed)

func _enemies_in_range() -> Array:
	var result: Array = []
	if enemies_root == null:
		return result
	for e in enemies_root.get_children():
		if not (e is Enemy):
			continue
		if (e as Enemy).dead:
			continue
		if e.global_position.distance_to(global_position) <= attack_range:
			result.append(e)
	return result

# ── 업그레이드 / 판매 ─────────────────────────────────────────────────
func upgrade_cost() -> int:
	if level >= MAX_LEVEL_INDEX:
		return 0
	var base_cost: float = float(tower_data["cost"])
	var curve: Array = tower_data["cost_curve"]
	return int(base_cost * float(curve[level + 1]))

func try_upgrade() -> bool:
	if level >= MAX_LEVEL_INDEX:
		return false
	var cost: int = upgrade_cost()
	if GameState.gold < cost:
		return false
	GameState.gold -= cost
	total_invested += cost
	level += 1
	_apply_level_stats()
	if behavior != null:
		behavior.on_level_up(level)
	leveled_up.emit(level)
	return true

func sell_refund() -> int:
	return int(float(total_invested) * 0.70)

func next_level_stats() -> Dictionary:
	if level >= MAX_LEVEL_INDEX:
		return {}
	var next: int = level + 1
	return {
		"damage":       float(tower_data["damage"][next]),
		"attack_speed": float(tower_data["attack_speed"][next]),
		"range":        float(tower_data["range"][next]),
	}

# ── 시각화 ────────────────────────────────────────────────────────────
func _draw() -> void:
	if tower_data.is_empty():
		return
	var col: Color = tower_data["color"] as Color

	# 베이스 팔각형 (어두운 색)
	var base_pts := PackedVector2Array()
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		base_pts.append(Vector2(cos(a), sin(a)) * 20.0)
	draw_colored_polygon(base_pts, Color(0.20, 0.18, 0.14))

	# 포탑 본체
	var body_pts := PackedVector2Array()
	for i in 10:
		var a: float = TAU * float(i) / 10.0
		body_pts.append(Vector2(cos(a), sin(a)) * 14.0)
	draw_colored_polygon(body_pts, col.darkened(0.30))
	body_pts.append(body_pts[0])
	draw_polyline(body_pts, col.lightened(0.20), 1.5)

	# 중심 포신
	draw_circle(Vector2.ZERO, 6.0, col)
	draw_circle(Vector2.ZERO, 3.0, col.lightened(0.50))

	# 레벨 별 표시
	var stars: int = level + 1
	var start_x: float = -float(stars - 1) * 2.5
	for s in stars:
		var px: float = start_x + float(s) * 5.0
		draw_circle(Vector2(px, 22.0), 1.6, Color(1.0, 0.92, 0.40))
