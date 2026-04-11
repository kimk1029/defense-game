extends Node2D
class_name GroundFire

var radius:       float = 55.0
var max_duration: float = 3.5
var duration:     float = 3.5
var burn_dmg:     int   = 3
var _tick:        float = 0.0

func _ready() -> void:
	z_index = 2

func _process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or not (e is Node2D):
				continue
			if global_position.distance_to(e.global_position) <= radius:
				if e.has_method("apply_burn"):
					e.apply_burn(burn_dmg, 1.2)
	queue_redraw()

func _draw() -> void:
	var t:    float = Time.get_ticks_msec() / 1000.0
	var fade: float = clamp(duration / max_duration, 0.0, 1.0)

	# Ground scorch circle
	draw_circle(Vector2.ZERO, radius * 0.90, Color(0.09, 0.04, 0.01, fade * 0.65))
	# Outer fire glow
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.92, 0.30, 0.04, fade * 0.16))

	# Flame tongues (14 around the circle)
	for i in 14:
		var a: float     = TAU * float(i) / 14.0 + t * 0.38
		var flicker: float = 0.62 + 0.38 * sin(t * 4.8 + float(i) * 0.85)
		var h: float     = radius * 0.50 * flicker * fade
		var w: float     = radius * 0.10
		var root_p := Vector2(cos(a), sin(a)) * (radius * 0.20)
		var tip    := root_p + Vector2(cos(a), sin(a)) * h
		var perp   := Vector2(-sin(a), cos(a))

		# Outer flame — orange-red
		draw_colored_polygon(PackedVector2Array([
			root_p - perp * w, root_p + perp * w, tip,
		]), Color(1.0, 0.22 + flicker * 0.28, 0.02, fade * 0.68 * flicker))

		# Inner flame — yellow-orange
		draw_colored_polygon(PackedVector2Array([
			root_p - perp * w * 0.42,
			root_p + perp * w * 0.42,
			root_p + Vector2(cos(a), sin(a)) * h * 0.52,
		]), Color(1.0, 0.65, 0.08, fade * 0.55 * flicker))

	# Hot core
	var cp: float = 0.78 + 0.22 * sin(t * 5.8)
	draw_circle(Vector2.ZERO, radius * 0.19 * cp, Color(1.0, 0.70, 0.16, fade * 0.88))
	draw_circle(Vector2.ZERO, radius * 0.08,       Color(1.0, 0.95, 0.52, fade))

	# Rising embers
	for i in 10:
		var phase: float = fmod(t * 0.68 + float(i) * 0.10, 1.0)
		var ea: float    = TAU * float(i) / 10.0 + t * 0.22
		var er: float    = radius * 0.30 * (1.0 - phase * 0.5)
		var ey: float    = -phase * radius * 0.58
		var epos := Vector2(cos(ea) * er, sin(ea) * er * 0.35 + ey)
		var ealpha: float = (1.0 - phase) * fade * 0.88
		if ealpha > 0.04:
			draw_circle(epos, 1.8 * (1.0 - phase * 0.45),
				Color(1.0, 0.52 + phase * 0.38, 0.10, ealpha))
