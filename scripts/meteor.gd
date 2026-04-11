extends Node2D
class_name Meteor

var damage: int = 20
var radius: float = 70.0

var delay: float = 0.6
var falling: bool = true
var impact_timer: float = 0.55

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
		queue_redraw()
		return

	impact_timer -= delta
	if impact_timer <= 0.0:
		queue_free()
	queue_redraw()

func _impact() -> void:
	# 스플래시 데미지 — 반경 내 모든 적에게 즉시
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= radius:
			if e.has_method("take_damage"):
				e.take_damage(damage)

func _draw() -> void:
	if falling:
		var progress: float = 1.0 - clamp(delay / 0.6, 0.0, 1.0)
		# 낙하 예고 원
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48,
			Color(1.0, 0.28, 0.05, 0.15 + progress * 0.55), 2.5)
		draw_arc(Vector2.ZERO, radius * 0.50, 0, TAU, 32,
			Color(1.0, 0.55, 0.10, progress * 0.30), 1.5)
		# 낙하 중인 유성
		var meteor_y: float = -200.0 * (1.0 - progress)
		var t: float = Time.get_ticks_msec() / 1000.0
		# 꼬리 불꽃
		for i in 6:
			var fi: float = float(i)
			var tail_y: float = meteor_y + fi * 14.0 * (1.0 - progress * 0.4)
			var tail_r: float = (8.0 + progress * 5.0) * (1.0 - fi / 6.0)
			var tail_a: float = (1.0 - fi / 6.0) * progress * 0.75
			draw_circle(Vector2(0, tail_y), tail_r,
				Color(1.0, 0.40 + fi * 0.06, 0.05, tail_a))
		# 유성 본체
		draw_circle(Vector2(0, meteor_y), 11.0 + progress * 5.0, Color(1.0, 0.55, 0.10))
		draw_circle(Vector2(0, meteor_y), 6.0 + progress * 2.0, Color(1.0, 0.85, 0.35))
		draw_circle(Vector2(0, meteor_y), 3.0, Color(1.0, 1.0, 0.82))
		# 충격 직전 바닥 글로우
		if progress > 0.7:
			var glow_a: float = (progress - 0.7) / 0.3
			draw_circle(Vector2.ZERO, radius * glow_a * 0.7,
				Color(1.0, 0.42, 0.08, glow_a * 0.18))
	else:
		# 착탄 폭발 플래시
		var alpha: float = clamp(impact_timer / 0.55, 0.0, 1.0)
		var exp_r: float = radius * (1.45 - alpha * 0.45)
		draw_circle(Vector2.ZERO, exp_r, Color(1.0, 0.55, 0.10, alpha * 0.45))
		draw_circle(Vector2.ZERO, exp_r * 0.55, Color(1.0, 0.80, 0.30, alpha * 0.70))
		draw_circle(Vector2.ZERO, exp_r * 0.25, Color(1.0, 0.96, 0.70, alpha * 0.90))
		# 방사형 스파크
		var t: float = Time.get_ticks_msec() / 1000.0
		for i in 8:
			var a: float = TAU * float(i) / 8.0 + t * 0.5
			var spark_len: float = radius * 0.55 * alpha
			draw_line(Vector2.ZERO,
				Vector2(cos(a), sin(a)) * spark_len,
				Color(1.0, 0.75, 0.20, alpha * 0.70), 2.5)
