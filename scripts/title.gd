extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var game_title:   Label  = $Center/VBox/GameTitle

var time: float = 0.0

# 반딧불 파티클
var fireflies: Array = []
const FF_COUNT := 40

# 스테이지 선택 패널
var stage_panel: Control = null
var stage_card_btns: Array = []

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	_init_fireflies()
	_style_button()
	_build_stage_select_panel()
	_add_stage_select_button()

# ── 반딧불 ────────────────────────────────────────────────────────────────────
func _init_fireflies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in FF_COUNT:
		fireflies.append({
			"pos":   Vector2(rng.randf() * 720.0, rng.randf() * 1280.0),
			"vel":   Vector2(rng.randf_range(-10.0, 10.0), rng.randf_range(-18.0, -6.0)),
			"size":  rng.randf_range(1.5, 3.2),
			"phase": rng.randf() * TAU,
			"spd":   rng.randf_range(0.7, 1.3),
		})

# ── 시작 버튼 스타일 ──────────────────────────────────────────────────────────
func _style_button() -> void:
	var mk := func(bg: Color, bd: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = bd
		s.border_width_left   = 2
		s.border_width_right  = 2
		s.border_width_top    = 2
		s.border_width_bottom = 2
		s.corner_radius_top_left     = 10
		s.corner_radius_top_right    = 10
		s.corner_radius_bottom_left  = 10
		s.corner_radius_bottom_right = 10
		return s
	start_button.add_theme_stylebox_override("normal",
		mk.call(Color(0.18, 0.32, 0.10, 0.92), Color(0.60, 0.80, 0.26, 0.90)))
	start_button.add_theme_stylebox_override("hover",
		mk.call(Color(0.28, 0.48, 0.16, 0.96), Color(0.78, 0.96, 0.38, 1.0)))
	start_button.add_theme_stylebox_override("pressed",
		mk.call(Color(0.14, 0.26, 0.08, 1.0),  Color(0.58, 0.76, 0.22, 1.0)))
	start_button.add_theme_color_override("font_color",        Color(0.95, 0.88, 0.55, 1.0))
	start_button.add_theme_color_override("font_hover_color",  Color(1.0,  0.96, 0.72, 1.0))
	start_button.add_theme_color_override("font_pressed_color",Color(0.86, 0.78, 0.46, 1.0))

# ── 스테이지 선택 버튼 추가 ───────────────────────────────────────────────────
func _add_stage_select_button() -> void:
	var vbox: VBoxContainer = $Center/VBox
	var btn := Button.new()
	btn.text = "스테이지 선택"
	btn.custom_minimum_size = Vector2(300, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 22)
	var mk := func(bg: Color, bd: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg; s.border_color = bd
		s.border_width_left = s.border_width_right = s.border_width_top = s.border_width_bottom = 2
		s.corner_radius_top_left = s.corner_radius_top_right = 10
		s.corner_radius_bottom_left = s.corner_radius_bottom_right = 10
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(Color(0.10, 0.20, 0.22, 0.90), Color(0.35, 0.62, 0.72, 0.88)))
	btn.add_theme_stylebox_override("hover",   mk.call(Color(0.16, 0.30, 0.36, 0.96), Color(0.50, 0.80, 0.92, 1.0)))
	btn.add_theme_stylebox_override("pressed", mk.call(Color(0.08, 0.16, 0.18, 1.0),  Color(0.30, 0.56, 0.66, 1.0)))
	btn.add_theme_color_override("font_color",       Color(0.72, 0.92, 0.98, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.90, 0.98, 1.00, 1.0))
	btn.pressed.connect(_on_stage_select_pressed)
	vbox.add_child(btn)

# ── 스테이지 선택 패널 빌드 ────────────────────────────────────────────────────
func _build_stage_select_panel() -> void:
	stage_panel = Control.new()
	stage_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_panel.visible = false
	add_child(stage_panel)

	# 반투명 배경 오버레이
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.06, 0.02, 0.94)
	stage_panel.add_child(bg)

	# 중앙 컨테이너
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_panel.add_child(center)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.custom_minimum_size = Vector2(660, 0)
	outer_vbox.add_theme_constant_override("separation", 18)
	center.add_child(outer_vbox)

	# 패널 제목
	var title_lbl := Label.new()
	title_lbl.text = "스테이지 선택"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.80, 0.38))
	outer_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "스테이지를 선택하세요"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.58, 0.40))
	outer_vbox.add_child(sub_lbl)

	# 카드 그리드 (2×2)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	outer_vbox.add_child(grid)

	for i in 4:
		var card_btn := Button.new()
		card_btn.custom_minimum_size = Vector2(320, 148)
		card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_btn.pressed.connect(_on_stage_card_pressed.bind(i + 1))
		_style_stage_card(card_btn, i, false)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Build card content via text (button text with newlines)
		var diff: int = GameState.STAGE_DIFF[i]
		var diff_str: String = "★".repeat(diff) + "☆".repeat(3 - diff)
		card_btn.text = "Stage %d  %s\n%s\n%s\n%s" % [
			i + 1,
			diff_str,
			GameState.STAGE_NAMES[i],
			"─────────────",
			GameState.STAGE_DESCS[i],
		]
		card_btn.add_theme_font_size_override("font_size", 14)
		card_btn.add_theme_color_override("font_color", Color(0.88, 0.78, 0.52))
		grid.add_child(card_btn)
		stage_card_btns.append(card_btn)

	# 뒤로 버튼
	var back_btn := Button.new()
	back_btn.text = "← 뒤로"
	back_btn.custom_minimum_size = Vector2(200, 48)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 18)
	var bk := StyleBoxFlat.new()
	bk.bg_color = Color(0.15, 0.10, 0.06, 0.88)
	bk.border_color = Color(0.52, 0.40, 0.20, 0.80)
	bk.border_width_left = bk.border_width_right = bk.border_width_top = bk.border_width_bottom = 2
	bk.corner_radius_top_left = bk.corner_radius_top_right = 10
	bk.corner_radius_bottom_left = bk.corner_radius_bottom_right = 10
	back_btn.add_theme_stylebox_override("normal", bk)
	var bkh := bk.duplicate() as StyleBoxFlat
	bkh.bg_color = Color(0.25, 0.18, 0.10, 0.92)
	back_btn.add_theme_stylebox_override("hover", bkh)
	back_btn.add_theme_color_override("font_color", Color(0.78, 0.68, 0.48))
	back_btn.pressed.connect(_hide_stage_panel)
	outer_vbox.add_child(back_btn)

	# 초기 선택 반영
	_refresh_stage_cards()

func _style_stage_card(btn: Button, idx: int, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	if selected:
		s.bg_color    = Color(0.22, 0.18, 0.06, 0.98)
		s.border_color = Color(0.92, 0.72, 0.18, 1.0)
		s.border_width_left = s.border_width_right = s.border_width_top = s.border_width_bottom = 3
	else:
		s.bg_color    = Color(0.14, 0.10, 0.06, 0.92)
		s.border_color = Color(0.45, 0.35, 0.18, 0.70)
		s.border_width_left = s.border_width_right = s.border_width_top = s.border_width_bottom = 1
	s.corner_radius_top_left = s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = s.corner_radius_bottom_right = 12
	s.content_margin_left = s.content_margin_right = 12
	s.content_margin_top = s.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.26, 0.20, 0.08, 0.98)
	sh.border_color = Color(0.78, 0.60, 0.24, 0.95)
	sh.border_width_left = sh.border_width_right = sh.border_width_top = sh.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", s)

func _refresh_stage_cards() -> void:
	for i in stage_card_btns.size():
		var selected: bool = (GameState.selected_stage == i + 1)
		_style_stage_card(stage_card_btns[i] as Button, i, selected)
		var col: Color = Color(1.0, 0.92, 0.38) if selected else Color(0.88, 0.78, 0.52)
		(stage_card_btns[i] as Button).add_theme_color_override("font_color", col)

func _on_stage_card_pressed(stage_num: int) -> void:
	GameState.selected_stage = stage_num
	_refresh_stage_cards()

func _on_stage_select_pressed() -> void:
	stage_panel.visible = true

func _hide_stage_panel() -> void:
	stage_panel.visible = false

# ── 게임 루프 ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	time += delta

	# 타이틀 따뜻한 황금빛 맥동
	var pulse: float = 0.88 + 0.12 * sin(time * 1.4)
	game_title.modulate = Color(pulse, pulse * 0.92, pulse * 0.55, 1.0)

	# 반딧불 업데이트
	for ff in fireflies:
		ff["pos"] += (ff["vel"] as Vector2) * delta * float(ff["spd"])
		ff["phase"] = float(ff["phase"]) + delta * 1.3
		var pos := ff["pos"] as Vector2
		if pos.y < -10.0: pos.y = size.y + 10.0; pos.x = randf() * size.x
		if pos.x < -10.0: pos.x = size.x + 10.0
		if pos.x > size.x + 10.0: pos.x = -10.0
		ff["pos"] = pos

	queue_redraw()

func _draw() -> void:
	var s := size
	var rng := RandomNumberGenerator.new()
	rng.seed = 77331

	# ── 밝은 잔디 베이스 ─────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.30, 0.62, 0.24))

	# 잔디 패치 변화
	for i in 130:
		var gx := rng.randf() * s.x
		var gy := rng.randf() * s.y
		var shade := rng.randf_range(-0.06, 0.07)
		var sz := rng.randf_range(10.0, 42.0)
		draw_circle(Vector2(gx, gy), sz,
			Color(0.30 + shade, 0.62 + shade * 0.8, 0.24 + shade * 0.5))

	# 꽃 (5-petal)
	var fcols: Array = [
		Color(0.98, 0.88, 0.15, 0.85), Color(0.96, 0.32, 0.38, 0.85),
		Color(0.98, 0.98, 0.98, 0.85), Color(0.68, 0.35, 0.92, 0.80),
		Color(0.96, 0.58, 0.20, 0.85), Color(0.90, 0.30, 0.60, 0.80),
	]
	for i in 55:
		var fx := rng.randf() * s.x
		var fy := rng.randf() * s.y
		var fc: Color = fcols[rng.randi() % fcols.size()]
		for p in 5:
			var pa := TAU * float(p) / 5.0
			draw_circle(Vector2(fx + cos(pa) * 3.5, fy + sin(pa) * 3.5), 2.5, fc)
		draw_circle(Vector2(fx, fy), 1.8, Color(1.0, 0.95, 0.35, 1.0))

	# 나무
	for i in 18:
		var tx := rng.randf() * s.x
		var ty := rng.randf() * s.y
		draw_rect(Rect2(Vector2(tx - 4.0, ty - 2.0), Vector2(8, 20)), Color(0.48, 0.32, 0.16))
		draw_rect(Rect2(Vector2(tx - 2.0, ty - 2.0), Vector2(4, 20)), Color(0.55, 0.38, 0.20))
		draw_circle(Vector2(tx,       ty - 8.0),  16.0, Color(0.18, 0.50, 0.15))
		draw_circle(Vector2(tx - 9.0, ty - 3.0),  12.0, Color(0.22, 0.54, 0.18))
		draw_circle(Vector2(tx + 9.0, ty - 3.0),  12.0, Color(0.20, 0.52, 0.16))
		draw_circle(Vector2(tx,       ty - 18.0), 11.0, Color(0.25, 0.58, 0.20))
		draw_circle(Vector2(tx - 3.0, ty - 14.0), 5.0,  Color(0.35, 0.70, 0.28, 0.70))

	# ── 모래 길 ──────────────────────────────────────────────────────
	var path_pts := PackedVector2Array([
		Vector2(s.x * 0.58, 0),
		Vector2(s.x * 0.52, s.y * 0.22),
		Vector2(s.x * 0.34, s.y * 0.46),
		Vector2(s.x * 0.50, s.y * 0.72),
		Vector2(s.x * 0.44, s.y),
	])
	draw_polyline(path_pts, Color(0.30, 0.22, 0.12), 56.0)
	draw_polyline(path_pts, Color(0.78, 0.62, 0.36), 42.0)
	draw_polyline(path_pts, Color(0.70, 0.55, 0.30, 0.38), 28.0)

	# ── 포탑 실루엣 (양쪽) ───────────────────────────────────────────
	var tw_defs := [
		[0.04, 40, 130], [0.13, 30, 96],
		[0.87, 30, 96],  [0.96, 40, 130],
	]
	var ground_y := s.y * 0.80
	for td in tw_defs:
		var cx: float  = s.x * float(td[0])
		var tw: float  = float(td[1])
		var th: float  = float(td[2])
		var ty_top: float = ground_y - th
		draw_rect(Rect2(Vector2(cx - tw*0.5, ty_top), Vector2(tw, th)),
			Color(0.20, 0.16, 0.10))
		var mw := tw / 4.0
		var mh := 15.0
		for m in 3:
			var mx := cx - tw*0.5 + tw * (float(m) + 0.2) / 3.0
			draw_rect(Rect2(Vector2(mx, ty_top - mh), Vector2(mw, mh)),
				Color(0.20, 0.16, 0.10))
		var glow: float = 0.30 + 0.40 * abs(sin(time * 1.0 + cx * 0.015))
		var wy := ty_top + th * 0.28
		draw_rect(Rect2(Vector2(cx - 5, wy - 2), Vector2(10, 16)),
			Color(0.95, 0.72, 0.22, glow * 0.18))
		draw_rect(Rect2(Vector2(cx - 4, wy), Vector2(8, 12)),
			Color(0.95, 0.72, 0.22, glow))
	draw_rect(Rect2(Vector2(0, ground_y), Vector2(s.x, s.y - ground_y)),
		Color(0.24, 0.50, 0.18))

	# ── 타이틀 배경 패널 (반투명 양피지) ─────────────────────────────
	var panel_cx := s.x * 0.5
	var panel_hw := 275.0
	var panel_y  := s.y * 0.32
	var panel_h  := s.y * 0.30
	for layer in 5:
		var expand_px: float = float(layer) * 7.0
		draw_rect(Rect2(
			Vector2(panel_cx - panel_hw - expand_px, panel_y - expand_px),
			Vector2((panel_hw + expand_px) * 2.0, panel_h + expand_px * 2.0)
		), Color(0.08, 0.05, 0.02, 0.07 - float(layer) * 0.010))
	draw_rect(Rect2(Vector2(panel_cx - panel_hw, panel_y),
		Vector2(panel_hw * 2.0, panel_h)),
		Color(0.07, 0.04, 0.02, 0.62))
	draw_polyline(PackedVector2Array([
		Vector2(panel_cx - panel_hw, panel_y),
		Vector2(panel_cx + panel_hw, panel_y),
		Vector2(panel_cx + panel_hw, panel_y + panel_h),
		Vector2(panel_cx - panel_hw, panel_y + panel_h),
		Vector2(panel_cx - panel_hw, panel_y),
	]), Color(0.68, 0.50, 0.22, 0.72), 2.0)
	for cx_s in [-1, 1]:
		for cy_s in [-1, 1]:
			var ox: float = panel_cx + float(cx_s) * panel_hw
			var oy: float = panel_y + (panel_h if cy_s == 1 else 0.0)
			_draw_diamond(Vector2(ox, oy), 6.0, Color(0.70, 0.52, 0.22, 0.82))
	var div_y := panel_y + panel_h - 20.0
	var gold  := Color(0.70, 0.52, 0.22, 0.78)
	var gold2 := Color(0.70, 0.52, 0.22, 0.28)
	draw_line(Vector2(panel_cx - 262, div_y), Vector2(panel_cx - 52, div_y), gold, 1.8)
	draw_line(Vector2(panel_cx + 52,  div_y), Vector2(panel_cx + 262, div_y), gold, 1.8)
	draw_line(Vector2(panel_cx - 256, div_y+4), Vector2(panel_cx - 58, div_y+4), gold2, 1.0)
	draw_line(Vector2(panel_cx + 58,  div_y+4), Vector2(panel_cx + 256, div_y+4), gold2, 1.0)
	_draw_diamond(Vector2(panel_cx - 52, div_y + 1), 5.0, gold)
	_draw_diamond(Vector2(panel_cx + 52, div_y + 1), 5.0, gold)

	# ── 반딧불 ───────────────────────────────────────────────────────
	for ff in fireflies:
		var ff_phase: float  = float(ff["phase"])
		var ff_size:  float  = float(ff["size"])
		var ff_pos:   Vector2 = ff["pos"] as Vector2
		var brightness: float = 0.42 + 0.58 * abs(sin(ff_phase * 1.7))
		draw_circle(ff_pos, ff_size * 3.0, Color(0.82, 0.98, 0.35, brightness * 0.16))
		draw_circle(ff_pos, ff_size * 1.5, Color(0.86, 0.98, 0.42, brightness * 0.50))
		draw_circle(ff_pos, ff_size,       Color(0.90, 1.0,  0.48, brightness * 0.90))

func _draw_diamond(center: Vector2, half: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -half),
		center + Vector2(half, 0),
		center + Vector2(0,  half),
		center + Vector2(-half, 0),
	]), color)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
