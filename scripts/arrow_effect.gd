extends Node2D
class_name ArrowEffect

var life: float = 0.70
var max_life: float = 0.70
var target_pos: Vector2 = Vector2.ZERO

# Arrow falls from sky (300px above target)
var start_y_offset: float = -300.0
var arrow_length: float = 22.0
var color: Color = Color(0.85, 0.62, 0.28, 1.0)

func _ready() -> void:
	z_index = 8
	global_position = Vector2(target_pos.x, target_pos.y + start_y_offset)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	# Move toward target_pos
	var t: float = 1.0 - clamp(life / max_life, 0.0, 1.0)  # 0→1 over lifetime
	global_position = Vector2(
		target_pos.x,
		target_pos.y + start_y_offset * (1.0 - t)
	)
	queue_redraw()

func _draw() -> void:
	var t: float = 1.0 - clamp(life / max_life, 0.0, 1.0)
	var fade: float = clamp(life / max_life, 0.0, 1.0)

	# Arrow shaft (pointing down)
	var tip := Vector2(0, arrow_length * 0.5)
	var tail := Vector2(0, -arrow_length * 0.5)

	# Motion blur trail
	for i in 4:
		var trail_offset := Vector2(0, -float(i) * 10.0)
		var trail_alpha := fade * (0.35 - float(i) * 0.08)
		if trail_alpha > 0.02:
			draw_line(tail + trail_offset, tip + trail_offset,
				Color(color.r, color.g, color.b, trail_alpha), 2.5 - float(i) * 0.4)

	# Main shaft
	draw_line(tail, tip, Color(color.r, color.g, color.b, fade), 3.0)

	# Arrowhead
	var head_pts := PackedVector2Array([
		Vector2(0, arrow_length * 0.5 + 8.0),
		Vector2(-5.0, arrow_length * 0.5 - 2.0),
		Vector2(5.0, arrow_length * 0.5 - 2.0),
	])
	draw_colored_polygon(head_pts, Color(color.r * 1.1, color.g * 0.9, color.b * 0.5, fade))

	# Fletching (tail feathers)
	draw_line(tail, tail + Vector2(-6.0, -6.0), Color(0.82, 0.82, 0.82, fade * 0.75), 1.5)
	draw_line(tail, tail + Vector2(6.0, -6.0), Color(0.82, 0.82, 0.82, fade * 0.75), 1.5)
	draw_line(tail, tail + Vector2(-4.0, -10.0), Color(0.72, 0.72, 0.72, fade * 0.55), 1.2)
	draw_line(tail, tail + Vector2(4.0, -10.0), Color(0.72, 0.72, 0.72, fade * 0.55), 1.2)

	# Impact flash when near ground (last 30% of lifetime)
	var impact: float = maxf(0.0, t * (1.0 / 0.3) - (0.7 / 0.3))
	if impact > 0.01:
		var flash_r := impact * 18.0
		draw_circle(tip, flash_r, Color(1.0, 0.85, 0.45, impact * 0.45))
		draw_circle(tip, flash_r * 0.5, Color(1.0, 0.95, 0.65, impact * 0.65))
		# Impact sparks
		for i in 5:
			var a: float = TAU * float(i) / 5.0 + t * 3.0
			var spark_len := impact * 12.0
			draw_line(tip, tip + Vector2(cos(a), sin(a)) * spark_len,
				Color(1.0, 0.75, 0.3, impact * 0.55), 1.2)
