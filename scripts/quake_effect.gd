extends Node2D
class_name QuakeEffect

var radius: float = 160.0
var life: float = 0.85
var max_life: float = 0.85

func _ready() -> void:
	z_index = 10

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var t: float = 1.0 - clamp(life / max_life, 0.0, 1.0)   # 0→1 over lifetime
	var fade: float = clamp(life / max_life, 0.0, 1.0)        # 1→0 over lifetime

	# ── Expanding shockwave rings ─────────────────────────────────────
	for ring in 4:
		var ring_t: float = clamp(t * 1.6 - float(ring) * 0.22, 0.0, 1.0)
		var r: float = radius * ring_t
		var ring_fade: float = fade * (1.0 - ring_t) * 1.2
		if ring_fade > 0.01 and r > 1.0:
			# Outer glow ring
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64,
				Color(0.72, 0.42, 0.12, ring_fade * 0.55), 5.0 - float(ring) * 0.8)
			# Inner bright ring
			draw_arc(Vector2.ZERO, r * 0.92, 0.0, TAU, 64,
				Color(0.95, 0.68, 0.28, ring_fade * 0.40), 2.5)

	# ── Ground crack lines ────────────────────────────────────────────
	var crack_alpha: float = fade * 0.85
	var crack_len: float   = radius * 0.72 * t
	for i in 8:
		var angle: float    = TAU * float(i) / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		var origin := dir * 10.0
		var tip    := dir * crack_len

		# Main crack
		draw_line(origin, tip,
			Color(0.38, 0.22, 0.07, crack_alpha), 2.2)

		# Branch crack (mid-point fork)
		if crack_len > 20.0:
			var mid := origin + (tip - origin) * 0.55
			var fork_angle: float = angle + (0.45 if i % 2 == 0 else -0.45)
			var fork_dir := Vector2(cos(fork_angle), sin(fork_angle))
			draw_line(mid, mid + fork_dir * crack_len * 0.35,
				Color(0.38, 0.22, 0.07, crack_alpha * 0.65), 1.4)

	# ── Central impact flash ──────────────────────────────────────────
	var flash: float = maxf(0.0, fade * 2.0 - 1.0)  # only in first half
	if flash > 0.01:
		draw_circle(Vector2.ZERO, 22.0 * (1.0 - t) + 4.0,
			Color(0.95, 0.75, 0.35, flash * 0.80))
		draw_circle(Vector2.ZERO, 10.0 * (1.0 - t) + 2.0,
			Color(1.00, 0.95, 0.65, flash))

	# ── Dust particles (8 flying chunks) ─────────────────────────────
	for i in 8:
		var angle: float = TAU * float(i) / 8.0 + 0.2
		var dist: float  = radius * 0.35 * t
		var chunk_pos := Vector2(cos(angle), sin(angle)) * dist
		var chunk_size: float = 4.5 * (1.0 - t) * fade
		if chunk_size > 0.5:
			draw_circle(chunk_pos, chunk_size,
				Color(0.60, 0.38, 0.16, fade * 0.75))
