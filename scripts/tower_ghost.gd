class_name TowerGhost
extends Node2D

# 설치 미리보기 전용 Node2D.
# valid가 변할 때만 queue_redraw()를 호출해 성능 부담이 적다.

var tower_data: Dictionary = {}
var valid: bool = true

func setup(data: Dictionary) -> void:
	tower_data = data
	z_index = 20
	queue_redraw()

func set_valid(v: bool) -> void:
	if v != valid:
		valid = v
		queue_redraw()

func _draw() -> void:
	if tower_data.is_empty():
		return

	var tc: Color = tower_data["color"] as Color
	var rng_val: float = float(tower_data["range"][0])

	var ok: bool = valid
	var border_col: Color = Color(0.40, 1.00, 0.45, 0.90) if ok else Color(1.0, 0.30, 0.30, 0.90)
	var range_fill: Color = Color(0.40, 1.00, 0.45, 0.14) if ok else Color(1.0, 0.30, 0.30, 0.14)
	var range_edge: Color = Color(0.55, 1.00, 0.55, 0.55) if ok else Color(1.0, 0.35, 0.35, 0.55)

	# 사거리 원
	draw_circle(Vector2.ZERO, rng_val, range_fill)
	draw_arc(Vector2.ZERO, rng_val, 0.0, TAU, 64, range_edge, 1.4)

	# 포탑 본체(반투명)
	var body := PackedVector2Array()
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		body.append(Vector2(cos(a), sin(a)) * 18.0)
	var body_col: Color
	if ok:
		body_col = Color(tc.r, tc.g, tc.b, 0.55)
	else:
		body_col = Color(1.0, 0.20, 0.20, 0.55)
	draw_colored_polygon(body, body_col)
	body.append(body[0])
	draw_polyline(body, border_col, 2.0)

	# 중심 점
	var center_col: Color = Color(1.0, 1.0, 1.0, 0.85) if ok else Color(1.0, 0.55, 0.55, 0.85)
	draw_circle(Vector2.ZERO, 4.5, center_col)
