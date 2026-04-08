extends Node2D
class_name XpGem

signal collected(value)

var value: int = 1
var life: float = 12.0
var pickup_radius: float = 9999.0  # auto-collect like Vampire Survivors

func _ready() -> void:
	z_index = 3

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	# Auto-fly to nothing — just self-collect after a tiny delay so kills feel rewarding
	# (No "player" entity in a defense game; we collect immediately on next frame.)
	emit_signal("collected", value)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5, Color(0.4, 0.9, 1.0))
