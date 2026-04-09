extends Node2D
class_name ChainLightning

var damage: int = 5
var chain_count: int = 2
var chain_range: float = 130.0
var is_max_level: bool = false

var chain_points: PackedVector2Array = PackedVector2Array()
var life: float = 0.35

func _ready() -> void:
	z_index = 8

func start(first_target: Node2D) -> void:
	if not is_instance_valid(first_target):
		queue_free()
		return

	var hit: Array[Node2D] = []
	var current: Node2D = first_target
	hit.append(current)
	chain_points.append(current.global_position)

	if current.has_method("take_damage"):
		current.take_damage(damage)
	if is_max_level and current.has_method("apply_slow"):
		current.apply_slow(0.4, 2.0)

	for _i in range(chain_count):
		var best: Node2D = null
		var best_dist: float = chain_range
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or hit.has(e):
				continue
			var d: float = current.global_position.distance_to(e.global_position)
			if d < best_dist:
				best_dist = d
				best = e
		if best == null:
			break
		hit.append(best)
		chain_points.append(best.global_position)
		if best.has_method("take_damage"):
			best.take_damage(damage)
		if is_max_level and best.has_method("apply_slow"):
			best.apply_slow(0.4, 2.0)
		current = best

	queue_redraw()

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if chain_points.size() < 1:
		return
	var origin: Vector2 = Vector2.ZERO
	var first: Vector2 = chain_points[0] - global_position
	_draw_bolt(origin, first)
	for i in range(chain_points.size() - 1):
		var from_pt: Vector2 = chain_points[i] - global_position
		var to_pt: Vector2 = chain_points[i + 1] - global_position
		_draw_bolt(from_pt, to_pt)

func _draw_bolt(from_pt: Vector2, to_pt: Vector2) -> void:
	var mid: Vector2 = (from_pt + to_pt) / 2.0
	var perp: Vector2 = (to_pt - from_pt).normalized().rotated(PI / 2.0) * randf_range(-12.0, 12.0)
	mid += perp
	var alpha: float = clamp(life / 0.35, 0.0, 1.0)
	var glow_color: Color = Color(0.7, 0.9, 1.0, alpha * 0.4)
	var core_color: Color = Color(0.5, 0.8, 1.0, alpha)
	draw_line(from_pt, mid, glow_color, 5.0)
	draw_line(mid, to_pt, glow_color, 5.0)
	draw_line(from_pt, mid, core_color, 2.0)
	draw_line(mid, to_pt, core_color, 2.0)
