extends Node2D
class_name PoisonArrow

var target: Node2D
var speed: float = 310.0
var damage: int = 2
var poison_damage: int = 2
var poison_duration: float = 3.0
var poison_explodes: bool = false
var life: float = 3.0

func _ready() -> void:
	z_index = 6

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0 or target == null or not is_instance_valid(target):
		queue_free()
		return
	var dir: Vector2 = target.global_position - global_position
	var dist: float = dir.length()
	var step: float = speed * delta
	if dist <= step:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		if target.has_method("apply_poison"):
			target.apply_poison(poison_damage, poison_duration, poison_explodes)
		queue_free()
		return
	global_position += dir / dist * step
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5, Color(0.2, 0.7, 0.15))
	draw_circle(Vector2.ZERO, 2, Color(0.5, 1.0, 0.3))
