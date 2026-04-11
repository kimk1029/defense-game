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
	# Glow aura
	draw_circle(Vector2.ZERO, 8.5, Color(0.18, 0.88, 0.42, 0.18))
	draw_circle(Vector2.ZERO, 6.0, Color(0.22, 0.92, 0.46, 0.38))
	# Gem body (bright green diamond)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -6), Vector2(4.5, 0), Vector2(0, 5.5), Vector2(-4.5, 0),
	]), Color(0.18, 0.88, 0.40, 1.0))
	# Facet (light highlight)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -5), Vector2(2.2, -0.8), Vector2(0, 2.2), Vector2(-2.2, -0.8),
	]), Color(0.60, 1.0, 0.72, 0.85))
	# Center sparkle
	draw_circle(Vector2.ZERO, 1.4, Color(1.0, 1.0, 1.0, 0.95))
