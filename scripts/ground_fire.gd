extends Node2D
class_name GroundFire

var radius:       float = 55.0
var max_duration: float = 5.0
var duration:     float = 5.0
var burn_dmg:     int   = 4
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
		_apply_burn_to_nearby()
	queue_redraw()

func _apply_burn_to_nearby() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		if global_position.distance_to(e.global_position) <= radius:
			if e.has_method("apply_burn"):
				e.apply_burn(burn_dmg, 1.5)

func _draw() -> void:
	var t: float    = Time.get_ticks_msec() / 1000.0
	# 0~1, 종료 직전 1초 동안 서서히 페이드아웃
	var fade: float = clamp(duration / 1.0, 0.0, 1.0)
	# 지속 초반(3초 이상)에는 완전히 보임
	if duration > 1.0:
		fade = 1.0

	# ── 그을린 바닥 ─────────────────────────────────────────────────────
	draw_circle(Vector2.ZERO, radius * 0.92,
		Color(0.08, 0.03, 0.01, fade * 0.72))
	draw_circle(Vector2.ZERO, radius * 0.60,
		Color(0.14, 0.06, 0.02, fade * 0.55))

	# ── 외곽 불꽃 링 (18개 혀) ──────────────────────────────────────────
	for i in 18:
		var a: float      = TAU * float(i) / 18.0 + t * 0.42
		var flicker: float = 0.55 + 0.45 * sin(t * 5.2 + float(i) * 0.72)
		var h: float      = radius * 0.62 * flicker * fade
		var w: float      = radius * 0.095
		var root_p := Vector2(cos(a), sin(a)) * (radius * 0.22)
		var tip    := root_p + Vector2(cos(a), sin(a)) * h
		var perp   := Vector2(-sin(a), cos(a))
		# 바깥 불꽃 (주황-빨강)
		draw_colored_polygon(PackedVector2Array([
			root_p - perp * w, root_p + perp * w, tip,
		]), Color(1.0, 0.20 + flicker * 0.30, 0.02, fade * 0.72 * flicker))
		# 안쪽 불꽃 (노란-주황)
		draw_colored_polygon(PackedVector2Array([
			root_p - perp * w * 0.40,
			root_p + perp * w * 0.40,
			root_p + Vector2(cos(a), sin(a)) * h * 0.55,
		]), Color(1.0, 0.68, 0.10, fade * 0.60 * flicker))

	# ── 내부 소용돌이 불꽃 (8개) ────────────────────────────────────────
	for i in 8:
		var a: float      = TAU * float(i) / 8.0 - t * 0.80
		var flicker: float = 0.60 + 0.40 * sin(t * 6.5 + float(i) * 1.1)
		var h: float      = radius * 0.38 * flicker * fade
		var w: float      = radius * 0.07
		var root_p := Vector2(cos(a), sin(a)) * (radius * 0.10)
		var tip    := root_p + Vector2(cos(a), sin(a)) * h
		var perp   := Vector2(-sin(a), cos(a))
		draw_colored_polygon(PackedVector2Array([
			root_p - perp * w, root_p + perp * w, tip,
		]), Color(1.0, 0.55, 0.05, fade * 0.65 * flicker))

	# ── 뜨거운 코어 ─────────────────────────────────────────────────────
	var cp: float = 0.78 + 0.22 * sin(t * 6.8)
	draw_circle(Vector2.ZERO, radius * 0.22 * cp,
		Color(1.0, 0.72, 0.18, fade * 0.92))
	draw_circle(Vector2.ZERO, radius * 0.10,
		Color(1.0, 0.96, 0.56, fade))

	# ── 떠오르는 불씨 파티클 (14개) ────────────────────────────────────
	for i in 14:
		var phase: float = fmod(t * 0.72 + float(i) * 0.072, 1.0)
		var ea: float    = TAU * float(i) / 14.0 + t * 0.28
		var er: float    = radius * 0.38 * (1.0 - phase * 0.55)
		var ey: float    = -phase * radius * 0.70
		var epos := Vector2(cos(ea) * er, sin(ea) * er * 0.30 + ey)
		var ealpha: float = (1.0 - phase) * fade * 0.90
		if ealpha > 0.04:
			draw_circle(epos, 2.2 * (1.0 - phase * 0.50),
				Color(1.0, 0.50 + phase * 0.42, 0.08, ealpha))

	# ── 맥스레벨 광역 글로우 링 ─────────────────────────────────────────
	var glow_a: float = fade * (0.12 + 0.08 * sin(t * 2.2))
	draw_arc(Vector2.ZERO, radius * 1.05, 0, TAU, 48,
		Color(1.0, 0.40, 0.08, glow_a), 3.5)
	draw_arc(Vector2.ZERO, radius * 1.20, 0, TAU, 36,
		Color(1.0, 0.30, 0.05, glow_a * 0.55), 1.8)
