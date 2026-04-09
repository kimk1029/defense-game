extends Node2D
class_name Meteor

var damage: int = 20
var radius: float = 70.0
var is_max_level: bool = false
var burn_damage: int = 3
var burn_duration: float = 3.0

var delay: float = 0.6
var falling: bool = true
var impact_timer: float = 0.5
var burn_life: float = 0.0
var burn_tick_timer: float = 0.0

func _ready() -> void:
	z_index = 9

func start(pos: Vector2) -> void:
	global_position = pos

func _process(delta: float) -> void:
	if falling:
		delay -= delta
		if delay <= 0.0:
			falling = false
			_impact()
			if is_max_level:
				burn_life = burn_duration
		queue_redraw()
		return

	if burn_life > 0.0:
		burn_life -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 0.5
			_burn_tick()
		if burn_life <= 0.0:
			queue_free()
		queue_redraw()
		return

	impact_timer -= delta
	if impact_timer <= 0.0:
		queue_free()
	queue_redraw()

func _impact() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= radius:
			if e.has_method("take_damage"):
				e.take_damage(damage)

func _burn_tick() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= radius:
			if e.has_method("apply_burn"):
				e.apply_burn(burn_damage, 1.0)

func _draw() -> void:
	if falling:
		var progress: float = 1.0 - clamp(delay / 0.6, 0.0, 1.0)
		# Warning circle on ground
		draw_arc(Vector2.ZERO, radius, 0, TAU, 36, Color(1.0, 0.3, 0.1, 0.2 + progress * 0.5), 2.0)
		draw_arc(Vector2.ZERO, radius * 0.5, 0, TAU, 24, Color(1.0, 0.5, 0.1, progress * 0.3), 1.5)
		# Falling meteor
		var meteor_y: float = -180.0 * (1.0 - progress)
		draw_circle(Vector2(0, meteor_y), 10.0 + progress * 4.0, Color(1.0, 0.55, 0.1))
		draw_circle(Vector2(0, meteor_y), 5.0, Color(1.0, 0.9, 0.4))
	elif burn_life > 0.0:
		var alpha: float = clamp(burn_life / burn_duration, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.25, 0.0, alpha * 0.15))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 36, Color(1.0, 0.4, 0.1, alpha * 0.5), 2.0)
		draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 24, Color(1.0, 0.6, 0.1, alpha * 0.3), 1.5)
	else:
		var alpha: float = clamp(impact_timer / 0.5, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius * (1.3 - alpha * 0.3), Color(1.0, 0.5, 0.1, alpha * 0.4))
		draw_circle(Vector2.ZERO, radius * 0.4, Color(1.0, 0.8, 0.3, alpha * 0.6))
