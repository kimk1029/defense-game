extends Node2D
class_name Tower

@export var base_damage: int = 5
@export var base_fire_rate: float = 1.2  # shots per second
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

func _ready() -> void:
	z_index = 4
	apply_global_mods(1, 1, 1, 1)

func apply_global_mods(d_mult: float, r_mult: float, rng_mult: float, p_mult: float) -> void:
	damage = int(round(base_damage * d_mult))
	fire_rate = base_fire_rate * r_mult
	range_px = base_range * rng_mult
	projectile_speed = base_projectile_speed * p_mult
	queue_redraw()

func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_shoot(target)
	cooldown = 1.0 / fire_rate

func _find_target() -> Node2D:
	var enemies := get_node(enemies_root_path)
	var best: Node2D = null
	var best_dist := range_px
	# Enemies live under PathFollow2D children of Path; search the scene tree.
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

func _shoot(target: Node2D) -> void:
	var proj = projectile_scene_script.new()
	proj.position = global_position
	proj.target = target
	proj.damage = damage
	proj.speed = projectile_speed
	get_node(projectiles_root_path).add_child(proj)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color(0.25, 0.55, 0.95))
	draw_arc(Vector2.ZERO, range_px, 0, TAU, 48, Color(0.4, 0.7, 1.0, 0.18), 1.0)
