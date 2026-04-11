extends Node2D
class_name LaserEffect

# start_pos / end_pos are in world coordinates.
# This node lives in Projectiles (world origin), so world coords = local coords.
var start_pos: Vector2 = Vector2.ZERO
var end_pos:   Vector2 = Vector2.ZERO
var life:      float = 0.28
var max_life:  float = 0.28
var beam_color: Color = Color(0.72, 0.96, 0.40)

func _ready() -> void:
	z_index = 9

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var fade: float = clamp(life / max_life, 0.0, 1.0)
	var s := start_pos
	var e := end_pos

	# Widest outer glow
	draw_line(s, e, Color(beam_color.r, beam_color.g, beam_color.b, fade * 0.10), 22.0)
	# Mid glow
	draw_line(s, e, Color(beam_color.r, beam_color.g, beam_color.b, fade * 0.28), 9.0)
	# Bright inner
	draw_line(s, e, Color(beam_color.r, beam_color.g, beam_color.b, fade * 0.70), 3.5)
	# White-hot core
	draw_line(s, e, Color(1.0, 1.0, 0.92, fade * 0.85), 1.2)

	# Impact flash at target
	var flash: float = fade * 0.95
	draw_circle(e, 12.0 * fade, Color(beam_color.r, beam_color.g, beam_color.b, flash * 0.30))
	draw_circle(e, 6.0  * fade, Color(1.0, 1.0, 0.88, flash * 0.65))
	draw_circle(e, 2.8  * fade, Color(1.0, 1.0, 1.0,  flash))
	# Radial sparks at impact
	for i in 6:
		var a: float = TAU * float(i) / 6.0 + (1.0 - fade) * 3.0
		var sp_len: float = fade * 14.0
		draw_line(e, e + Vector2(cos(a), sin(a)) * sp_len,
			Color(beam_color.r, beam_color.g, 0.30, flash * 0.50), 1.0)

	# Muzzle flash at source
	draw_circle(s, 7.0 * fade, Color(beam_color.r, beam_color.g, beam_color.b, flash * 0.22))
	draw_circle(s, 3.5 * fade, Color(1.0, 1.0, 0.88, flash * 0.45))
