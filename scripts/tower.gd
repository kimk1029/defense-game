extends Node2D
class_name Tower

@export var base_damage: int = 5
@export var base_fire_rate: float = 1.2
@export var base_range: float = 140.0
@export var base_projectile_speed: float = 380.0

var damage: int
var fire_rate: float
var range_px: float
var projectile_speed: float

var cooldown: float = 0.0
var enemies_root_path: NodePath
var projectiles_root_path: NodePath
var projectile_scene_script: Script

# Special weapons
var special_weapons: Dictionary = {}
var special_cooldowns: Dictionary = {}

func _ready() -> void:
	z_index = 4
	apply_global_mods(1, 1, 1, 1)

func apply_global_mods(d_mult: float, r_mult: float, rng_mult: float, p_mult: float) -> void:
	damage = int(round(base_damage * d_mult))
	fire_rate = base_fire_rate * r_mult
	range_px = base_range * rng_mult
	projectile_speed = base_projectile_speed * p_mult
	queue_redraw()

func update_special_weapons(weapons: Dictionary) -> void:
	special_weapons = weapons.duplicate()
	for key: String in special_weapons:
		if not special_cooldowns.has(key):
			special_cooldowns[key] = randf_range(0.5, _get_sp_cooldown(key))

func _get_sp_cooldown(key: String) -> float:
	match key:
		"chain": return 3.0
		"freeze": return 4.5
		"poison": return 2.8
		"meteor": return 6.0
	return 3.0

func _process(delta: float) -> void:
	queue_redraw()
	# Normal attack
	cooldown -= delta
	if cooldown <= 0.0:
		var target: Node2D = _find_target()
		if target != null:
			_shoot(target)
			cooldown = 1.0 / fire_rate

	# Special weapons
	for key: String in special_weapons:
		if not special_cooldowns.has(key):
			continue
		special_cooldowns[key] = float(special_cooldowns[key]) - delta
		if float(special_cooldowns[key]) <= 0.0:
			var sp_target: Node2D = _find_target()
			if sp_target != null:
				_fire_special(key, sp_target)
				special_cooldowns[key] = _get_sp_cooldown(key)
			else:
				special_cooldowns[key] = 0.5

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist: float = range_px
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

func _shoot(target: Node2D) -> void:
	var proj: Projectile = projectile_scene_script.new()
	proj.position = global_position
	proj.target = target
	proj.damage = damage
	proj.speed = projectile_speed
	get_node(projectiles_root_path).add_child(proj)

func _fire_special(key: String, target: Node2D) -> void:
	var level: int = int(special_weapons.get(key, 1))
	var proj_root: Node = get_node(projectiles_root_path)

	match key:
		"chain":
			var lightning: ChainLightning = ChainLightning.new()
			lightning.global_position = global_position
			lightning.damage = 3 + level * 3
			lightning.chain_count = 1 + level
			lightning.chain_range = range_px * 0.9
			lightning.is_max_level = level >= 5
			proj_root.add_child(lightning)
			lightning.start(target)
		"freeze":
			var bomb: FreezeBomb = FreezeBomb.new()
			bomb.global_position = global_position
			bomb.target = target
			bomb.damage = 2 + level * 2
			bomb.radius = 55.0 + float(level) * 15.0
			bomb.slow_factor = maxf(0.2, 0.7 - float(level) * 0.1)
			bomb.slow_duration = 1.5 + float(level) * 0.3
			bomb.is_max_level = level >= 5
			proj_root.add_child(bomb)
		"poison":
			var arrow: PoisonArrow = PoisonArrow.new()
			arrow.global_position = global_position
			arrow.target = target
			arrow.damage = 1 + level
			arrow.poison_damage = 1 + level
			arrow.poison_duration = 2.0 + float(level) * 0.5
			arrow.poison_explodes = level >= 5
			proj_root.add_child(arrow)
		"meteor":
			var met: Meteor = Meteor.new()
			met.damage = 8 + level * 7
			met.radius = 50.0 + float(level) * 12.0
			met.is_max_level = level >= 5
			met.burn_damage = 2 + level
			proj_root.add_child(met)
			met.start(target.global_position)

func _draw() -> void:
	# === Tower base (stone platform) ===
	# Shadow
	draw_circle(Vector2(2, 3), 18.0, Color(0.0, 0.0, 0.0, 0.2))
	# Stone base - octagon shape
	var base_pts: PackedVector2Array = PackedVector2Array()
	for i in 8:
		var angle: float = TAU * i / 8.0 - PI / 8.0
		base_pts.append(Vector2(cos(angle), sin(angle)) * 18.0)
	draw_colored_polygon(base_pts, Color(0.45, 0.44, 0.42))
	# Base edge highlight
	for i in 8:
		var a: Vector2 = base_pts[i]
		var b: Vector2 = base_pts[(i + 1) % 8]
		draw_line(a, b, Color(0.55, 0.54, 0.5), 1.5)

	# === Tower body ===
	# Main body (rounded square shape)
	var body_pts: PackedVector2Array = PackedVector2Array()
	for i in 12:
		var angle: float = TAU * i / 12.0
		var r: float = 12.0 + cos(angle * 4) * 1.5
		body_pts.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(body_pts, Color(0.35, 0.38, 0.5))
	# Body lighter top
	var top_pts: PackedVector2Array = PackedVector2Array()
	for i in 12:
		var angle: float = TAU * i / 12.0
		top_pts.append(Vector2(cos(angle), sin(angle)) * 10.0)
	draw_colored_polygon(top_pts, Color(0.42, 0.45, 0.58))

	# === Turret / cannon ===
	# Find target direction for turret rotation
	var turret_dir: Vector2 = Vector2.UP
	var target: Node2D = _find_target()
	if target != null:
		turret_dir = (target.global_position - global_position).normalized()
	# Cannon barrel
	var barrel_end: Vector2 = turret_dir * 16.0
	var barrel_perp: Vector2 = Vector2(-turret_dir.y, turret_dir.x)
	var b1: Vector2 = barrel_perp * 3.0
	var b2: Vector2 = barrel_perp * -3.0
	var barrel_pts: PackedVector2Array = PackedVector2Array([
		b1, b1 + barrel_end, b2 + barrel_end, b2
	])
	draw_colored_polygon(barrel_pts, Color(0.3, 0.3, 0.35))
	# Barrel tip highlight
	draw_line(b1 + barrel_end, b2 + barrel_end, Color(0.5, 0.5, 0.55), 2.0)
	# Center turret hub
	draw_circle(Vector2.ZERO, 6.0, Color(0.5, 0.52, 0.6))
	draw_circle(Vector2.ZERO, 4.0, Color(0.6, 0.62, 0.7))
	# Hub rivet
	draw_circle(Vector2.ZERO, 1.5, Color(0.4, 0.4, 0.45))

	# === Battlements (small squares on corners) ===
	for i in 4:
		var angle: float = TAU * i / 4.0 + PI / 4.0
		var bp: Vector2 = Vector2(cos(angle), sin(angle)) * 16.0
		draw_rect(Rect2(bp - Vector2(3, 3), Vector2(6, 6)), Color(0.5, 0.5, 0.48))
		draw_rect(Rect2(bp - Vector2(2, 2), Vector2(4, 4)), Color(0.58, 0.57, 0.54))

	# === Range indicator ===
	draw_arc(Vector2.ZERO, range_px, 0, TAU, 48, Color(0.4, 0.7, 1.0, 0.15), 1.0)
