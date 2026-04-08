extends Node2D
class_name Projectile

var target: Node2D
var damage: int = 5
var speed: float = 380.0
var life: float = 3.0

func _ready() -> void:
	z_index = 6

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0 or target == null or not is_instance_valid(target):
		queue_free()
		return
	var dir := (target.global_position - global_position)
	var dist := dir.length()
	var step := speed * delta
	if dist <= step:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return
	global_position += dir / dist * step
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, Color(1, 0.95, 0.4))
