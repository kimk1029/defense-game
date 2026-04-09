extends Node2D
class_name FreezeBomb

var target: Node2D
var speed: float = 260.0
var damage: int = 3
var radius: float = 80.0
var slow_factor: float = 0.5
var slow_duration: float = 2.0
var is_max_level: bool = false
var life: float = 3.0

var exploded: bool = false
var explosion_timer: float = 0.4

func _ready() -> void:
	z_index = 7

func _process(delta: float) -> void:
	if exploded:
		explosion_timer -= delta
		if explosion_timer <= 0.0:
			queue_free()
		queue_redraw()
		return

	life -= delta
	if life <= 0.0 or target == null or not is_instance_valid(target):
		queue_free()
		return

	var dir: Vector2 = target.global_position - global_position
	var dist: float = dir.length()
	var step: float = speed * delta
	if dist <= step:
		_explode()
		return
	global_position += dir / dist * step
	queue_redraw()

func _explode() -> void:
	exploded = true
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= radius:
			if e.has_method("take_damage"):
				e.take_damage(damage)
			if is_max_level:
				if e.has_method("apply_freeze"):
					e.apply_freeze(1.2)
			else:
				if e.has_method("apply_slow"):
					e.apply_slow(slow_factor, slow_duration)
	queue_redraw()

func _draw() -> void:
	if exploded:
		var alpha: float = clamp(explosion_timer / 0.4, 0.0, 1.0)
		var r: float = radius * (1.2 - alpha * 0.2)
		draw_circle(Vector2.ZERO, r, Color(0.5, 0.9, 1.0, alpha * 0.2))
		draw_arc(Vector2.ZERO, r, 0, TAU, 36, Color(0.6, 0.95, 1.0, alpha * 0.7), 2.5)
	else:
		draw_circle(Vector2.ZERO, 7, Color(0.4, 0.8, 1.0))
		draw_circle(Vector2.ZERO, 3, Color(0.85, 0.95, 1.0))
