class_name Terrain
extends Node2D

# 정적 배경을 한 번만 그린다. queue_redraw()는 setup() 이후 다시 호출되지 않음.
# 과거엔 main.gd가 매 프레임 이 전부를 다시 그려 심각한 프레임 드랍이 있었다.

var path_ref: Path2D = null

func setup(p: Path2D) -> void:
	path_ref = p
	queue_redraw()

func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var game_h: float = vp.y - 130.0

	# 기본 잔디
	draw_rect(Rect2(Vector2.ZERO, Vector2(vp.x, game_h)), Color(0.30, 0.58, 0.22))
	# 하단 UI 덮개
	draw_rect(Rect2(Vector2(0.0, game_h), Vector2(vp.x, 130.0)), Color(0.12, 0.18, 0.08))
	# 경계선
	draw_rect(Rect2(Vector2(0.0, game_h - 4.0), Vector2(vp.x, 4.0)),
		Color(0.04, 0.08, 0.03, 0.80))
	draw_rect(Rect2(Vector2(0.0, game_h), Vector2(vp.x, 2.0)),
		Color(0.35, 0.58, 0.18))

	# 잔디 음영 (Terrain만 한 번 그리므로 개수를 여유 있게 사용해도 됨)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 100:
		var gx: float = rng.randf() * vp.x
		var gy: float = rng.randf() * game_h
		var shade: float = rng.randf_range(-0.05, 0.06)
		var sz: float = rng.randf_range(14.0, 32.0)
		draw_circle(Vector2(gx, gy), sz,
			Color(0.30 + shade, 0.58 + shade * 0.8, 0.22 + shade * 0.5))

	# 꽃 (간소화)
	var flower_cols: Array = [
		Color(0.98, 0.88, 0.22, 0.88),
		Color(0.96, 0.36, 0.38, 0.88),
		Color(0.98, 0.98, 0.98, 0.88),
		Color(0.72, 0.38, 0.94, 0.82),
	]
	for i in 40:
		var fx: float = rng.randf() * vp.x
		var fy: float = rng.randf() * game_h
		var fc: Color = flower_cols[rng.randi() % flower_cols.size()]
		draw_circle(Vector2(fx, fy), 2.2, fc)
		draw_circle(Vector2(fx, fy), 1.0, Color(1.0, 0.95, 0.32))

	# 경로 그리기
	if path_ref == null or path_ref.curve == null or path_ref.curve.point_count < 2:
		return
	var curve: Curve2D = path_ref.curve
	var points: PackedVector2Array = curve.get_baked_points()
	var offset: Vector2 = path_ref.position
	var world_points: PackedVector2Array = PackedVector2Array()
	for p in points:
		world_points.append(p + offset)

	# 어두운 테두리
	draw_polyline(world_points, Color(0.26, 0.18, 0.10), 52.0)
	for pt in world_points:
		draw_circle(pt, 26.0, Color(0.26, 0.18, 0.10))
	# 모래 내부
	draw_polyline(world_points, Color(0.76, 0.60, 0.34), 40.0)
	for pt in world_points:
		draw_circle(pt, 20.0, Color(0.76, 0.60, 0.34))
	# 밝은 점선
	var dash_len: float = 14.0
	var gap_len: float = 10.0
	var dist: float = 0.0
	var total_len: float = curve.get_baked_length()
	var drawing: bool = true
	while dist < total_len:
		var seg_end: float = dist + (dash_len if drawing else gap_len)
		seg_end = minf(seg_end, total_len)
		if drawing:
			var p1: Vector2 = curve.sample_baked(dist) + offset
			var p2: Vector2 = curve.sample_baked(seg_end) + offset
			draw_line(p1, p2, Color(0.92, 0.78, 0.50, 0.55), 2.2)
		dist = seg_end
		drawing = not drawing
