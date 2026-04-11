extends Node2D

# === Game state ===
var gold: int = 150
var life: int = 20
var wave: int = 0
var player_level: int = 1
var xp: int = 0
var xp_to_next: int = 5

# === Global tower modifiers ===
var mod_damage_mult: float = 1.0
var mod_fire_rate_mult: float = 1.0
var mod_range_mult: float = 1.0
var mod_projectile_speed_mult: float = 1.0
var mod_gold_gain_mult: float = 1.0
var mod_xp_gain_mult: float = 1.0
var tower_cost_reduction: int = 0  # flat reduction applied to all tower costs

# === Tower selection ===
var selected_tower_idx: int = 0
var tower_btns: Array = []
var tower_info_popup: PanelContainer = null

# === Tower upgrade panel ===
var tower_upgrade_panel: Control = null
var selected_placed_tower: Tower = null

# === Game over panel ===
var game_over_panel: Control = null
var game_over_wave_lbl: Label = null
var game_over_stage_lbl: Label = null

# === Wave control ===
var wave_in_progress: bool = false
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8
var between_wave_timer: float = 2.0
var wave_announce_timer: float = 0.0
var wave_clear_timer: float = 0.0

@onready var path: Path2D = $Path
@onready var enemies_root: Node2D = $Enemies
@onready var towers_root: Node2D = $Towers
@onready var projectiles_root: Node2D = $Projectiles
@onready var gems_root: Node2D = $Gems
@onready var stats_label: Label = $HUD/Stats
@onready var wave_announce: Label = $HUD/WaveAnnounce
@onready var upgrade_menu: ColorRect = $HUD/UpgradeMenu
@onready var lv_header: Label = $HUD/UpgradeMenu/Panel/ContentVBox/Header

# Card arrays (populated in _ready)
var card_icons: Array = []
var card_names: Array = []
var card_descs: Array = []
var btns: Array = []

var pending_choices: Array = []

# ── Tower type definitions ─────────────────────────────────────────────────
const TOWER_TYPES: Array[Dictionary] = [
	{
		"key": "basic",  "name": "기본 포탑",   "icon": "◎",  "cost": 50,
		"desc": "빠른 연사 / 균형형",
		"color": Color(0.58, 0.58, 0.68),
		"weapon": "",
		"b_dmg": 6,  "b_rate": 1.5,  "b_range": 130.0, "b_speed": 400.0,
	},
	{
		"key": "sniper", "name": "저격 포탑",   "icon": "▶▶", "cost": 110,
		"desc": "긴 사거리 / 강한 단타",
		"color": Color(0.72, 0.72, 0.48),
		"weapon": "laser",
		"b_dmg": 18, "b_rate": 0.45, "b_range": 250.0, "b_speed": 650.0,
	},
	{
		"key": "lightning","name": "번개 포탑", "icon": "⚡", "cost": 90,
		"desc": "연쇄 번개 / 다수 처리",
		"color": Color(0.98, 0.88, 0.12),
		"weapon": "chain",
		"b_dmg": 3,  "b_rate": 0.85, "b_range": 155.0, "b_speed": 350.0,
	},
	{
		"key": "freeze", "name": "냉동 포탑",   "icon": "❄",  "cost": 80,
		"desc": "범위 냉각 / 둔화·동결",
		"color": Color(0.42, 0.82, 1.00),
		"weapon": "freeze",
		"b_dmg": 2,  "b_rate": 0.65, "b_range": 148.0, "b_speed": 290.0,
	},
	{
		"key": "poison", "name": "독 포탑",     "icon": "☠",  "cost": 75,
		"desc": "독 지속 피해 / DoT",
		"color": Color(0.30, 0.88, 0.30),
		"weapon": "poison",
		"b_dmg": 3,  "b_rate": 0.95, "b_range": 140.0, "b_speed": 360.0,
	},
	{
		"key": "meteor", "name": "유성 포탑",   "icon": "☄",  "cost": 130,
		"desc": "범위 대폭발 / 화염 지대",
		"color": Color(1.00, 0.48, 0.15),
		"weapon": "meteor",
		"b_dmg": 4,  "b_rate": 0.45, "b_range": 175.0, "b_speed": 290.0,
	},
	{
		"key": "arrow",  "name": "화살비 포탑", "icon": "↓",  "cost": 85,
		"desc": "다수 동시 공격 / 광역",
		"color": Color(0.78, 0.52, 0.25),
		"weapon": "arrow_rain",
		"b_dmg": 4,  "b_rate": 0.80, "b_range": 150.0, "b_speed": 440.0,
	},
	{
		"key": "quake",  "name": "지진 포탑",   "icon": "≋",  "cost": 110,
		"desc": "광역 둔화 / 넓은 사거리",
		"color": Color(0.60, 0.40, 0.20),
		"weapon": "quake",
		"b_dmg": 3,  "b_rate": 0.45, "b_range": 200.0, "b_speed": 270.0,
	},
]

# ── Level-up stat upgrades ─────────────────────────────────────────────────
const BASE_UPGRADES: Array[Dictionary] = [
	{"key": "dmg",  "icon": "⚔", "name": "공격력 +25%",     "desc": "모든 타워의\n공격력 증가"},
	{"key": "rate", "icon": "⚡", "name": "공격속도 +20%",   "desc": "모든 타워가\n더 빠르게 공격"},
	{"key": "rng",  "icon": "◎", "name": "사거리 +15%",     "desc": "모든 타워의\n사거리 증가"},
	{"key": "proj", "icon": "▶", "name": "투사체 속도 +25%", "desc": "투사체가\n더 빠르게 날아감"},
	{"key": "gold", "icon": "★", "name": "골드 획득 +20%",  "desc": "처치 시 더 많은\n골드 획득"},
	{"key": "xp",   "icon": "◆", "name": "경험치 +25%",     "desc": "더 빠르게\n레벨업"},
	{"key": "cost", "icon": "▣", "name": "건설비 -10g",     "desc": "모든 타워\n건설 비용 감소"},
]

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Build level-up card arrays
	var cards_row: HBoxContainer = $HUD/UpgradeMenu/Panel/ContentVBox/CardsRow
	for i in 3:
		var card: Node = cards_row.get_child(i)
		card_icons.append(card.get_node("InnerVBox/Icon"))
		card_names.append(card.get_node("InnerVBox/NameLabel"))
		card_descs.append(card.get_node("InnerVBox/DescLabel"))
		var btn: Button = card.get_node("InnerVBox/Btn")
		btns.append(btn)
		btn.pressed.connect(_on_upgrade_picked.bind(i))

	_setup_stage_path()
	_style_upgrade_menu()
	_build_tower_bar()
	_build_tower_info_popup()
	_build_tower_upgrade_panel()
	_build_game_over_panel()
	_refresh_hud()
	_start_next_wave_after_delay()
	queue_redraw()

# ── Tower selection bar ───────────────────────────────────────────────────────

func _build_tower_bar() -> void:
	var btn_row: HBoxContainer = $HUD/TowerBar/BtnRow
	tower_btns.clear()
	for i in TOWER_TYPES.size():
		# 슬롯 컨테이너 (타워버튼 + ? 버튼을 겹침)
		var slot := Control.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(0, 112)
		btn_row.add_child(slot)

		# 메인 타워 버튼 (슬롯 전체 채움)
		var btn := Button.new()
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(_on_tower_type_selected.bind(i))
		slot.add_child(btn)
		tower_btns.append(btn)

		# ? 정보 버튼 (우상단 고정)
		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		info_btn.offset_left = -24
		info_btn.offset_top = 2
		info_btn.offset_right = -2
		info_btn.offset_bottom = 22
		info_btn.z_index = 2
		info_btn.add_theme_font_size_override("font_size", 11)
		var qs := StyleBoxFlat.new()
		qs.bg_color = Color(0.10, 0.08, 0.05, 0.82)
		qs.border_color = Color(0.60, 0.45, 0.18, 0.80)
		qs.border_width_left = 1
		qs.border_width_right = 1
		qs.border_width_top = 1
		qs.border_width_bottom = 1
		qs.corner_radius_top_left = 4
		qs.corner_radius_top_right = 4
		qs.corner_radius_bottom_left = 4
		qs.corner_radius_bottom_right = 4
		info_btn.add_theme_stylebox_override("normal", qs)
		info_btn.add_theme_color_override("font_color", Color(0.85, 0.72, 0.38))
		info_btn.pressed.connect(_show_tower_info.bind(i))
		slot.add_child(info_btn)

	_update_tower_bar_btns()

func _on_tower_type_selected(idx: int) -> void:
	selected_tower_idx = idx
	_update_tower_bar_btns()
	_refresh_hud()

# ── Tower info popup ──────────────────────────────────────────────────────────

func _build_tower_info_popup() -> void:
	tower_info_popup = PanelContainer.new()
	tower_info_popup.visible = false
	tower_info_popup.z_index = 30
	tower_info_popup.custom_minimum_size = Vector2(300, 0)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.18, 0.12, 0.07, 0.98)
	ps.border_color = Color(0.68, 0.50, 0.22, 0.95)
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.corner_radius_top_left = 12
	ps.corner_radius_top_right = 12
	ps.corner_radius_bottom_left = 12
	ps.corner_radius_bottom_right = 12
	ps.content_margin_left = 16
	ps.content_margin_right = 16
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	tower_info_popup.add_theme_stylebox_override("panel", ps)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	tower_info_popup.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.name = "TitleLbl"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.76, 0.32))
	vbox.add_child(title_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.60, 0.45, 0.20, 0.60))
	vbox.add_child(sep)

	var desc_lbl := Label.new()
	desc_lbl.name = "DescLbl"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.70, 0.50))
	vbox.add_child(desc_lbl)

	var stats_lbl := Label.new()
	stats_lbl.name = "StatsLbl"
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.50))
	vbox.add_child(stats_lbl)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.60, 0.45, 0.20, 0.40))
	vbox.add_child(sep2)

	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color(0.88, 0.72, 0.38))
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.30, 0.18, 0.08, 0.85)
	cs.border_color = Color(0.65, 0.48, 0.20, 0.85)
	cs.border_width_left = 1
	cs.border_width_right = 1
	cs.border_width_top = 1
	cs.border_width_bottom = 1
	cs.corner_radius_top_left = 6
	cs.corner_radius_top_right = 6
	cs.corner_radius_bottom_left = 6
	cs.corner_radius_bottom_right = 6
	var cs_h := cs.duplicate() as StyleBoxFlat
	cs_h.bg_color = Color(0.44, 0.28, 0.12, 0.90)
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.add_theme_stylebox_override("hover", cs_h)
	close_btn.add_theme_stylebox_override("pressed", cs)
	close_btn.pressed.connect(_hide_tower_info)
	vbox.add_child(close_btn)

	$HUD.add_child(tower_info_popup)

func _show_tower_info(idx: int) -> void:
	var td: Dictionary = TOWER_TYPES[idx]
	var vbox: VBoxContainer = tower_info_popup.get_child(0) as VBoxContainer
	vbox.get_node("TitleLbl").text = "%s  %s" % [str(td["icon"]), str(td["name"])]
	vbox.get_node("DescLbl").text = str(td["desc"])

	var weapon_name: String
	match str(td.get("weapon", "")):
		"chain":      weapon_name = "연쇄 번개"
		"freeze":     weapon_name = "냉동 폭탄"
		"poison":     weapon_name = "독 화살"
		"meteor":     weapon_name = "유성 낙하"
		"arrow_rain": weapon_name = "화살비"
		"quake":      weapon_name = "지진파"
		"laser":      weapon_name = "레이저"
		_:            weapon_name = "기본 투사체"

	vbox.get_node("StatsLbl").text = (
		"공격력: %d   속도: %.1f/s   사거리: %d\n특수기술: %s   비용: %dg" % [
			int(td["b_dmg"]), float(td["b_rate"]), int(td["b_range"]),
			weapon_name, int(td["cost"])
		]
	)

	# 타워 바 위, 화면 중앙에 배치
	var vp: Vector2 = get_viewport_rect().size
	tower_info_popup.position = Vector2(
		(vp.x - 300.0) * 0.5,
		vp.y - 118.0 - 215.0
	)
	tower_info_popup.visible = true

func _hide_tower_info() -> void:
	tower_info_popup.visible = false

func _get_tower_cost(idx: int) -> int:
	return maxi(10, int(TOWER_TYPES[idx]["cost"]) - tower_cost_reduction)

func _update_tower_bar_btns() -> void:
	for i in tower_btns.size():
		var td: Dictionary = TOWER_TYPES[i]
		var cost: int = _get_tower_cost(i)
		var btn: Button = tower_btns[i]
		btn.text = "%s\n%s\n%dg" % [td["icon"], td["name"], cost]
		_style_tower_btn(btn, td["color"] as Color, i == selected_tower_idx, gold >= cost)

func _style_tower_btn(btn: Button, tc: Color, selected: bool, affordable: bool) -> void:
	var alpha: float = 1.0 if affordable else 0.42

	var mk := func(bg_f: float, bd_a: float) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(tc.r * bg_f, tc.g * bg_f, tc.b * bg_f, alpha * 0.90)
		s.border_color = Color(tc.r, tc.g, tc.b, bd_a * alpha)
		s.border_width_left   = 3 if selected else 1
		s.border_width_right  = 3 if selected else 1
		s.border_width_top    = 3 if selected else 1
		s.border_width_bottom = 3 if selected else 1
		s.corner_radius_top_left     = 6
		s.corner_radius_top_right    = 6
		s.corner_radius_bottom_left  = 6
		s.corner_radius_bottom_right = 6
		return s

	btn.add_theme_stylebox_override("normal",  mk.call(0.28 if selected else 0.18, 1.0 if selected else 0.50))
	btn.add_theme_stylebox_override("hover",   mk.call(0.40, 1.0))
	btn.add_theme_stylebox_override("pressed", mk.call(0.55, 1.0))
	var lum: float = 1.0 if affordable else 0.6
	btn.add_theme_color_override("font_color",
		Color(minf(tc.r * 2.0 + 0.3, 1.0) * lum,
			  minf(tc.g * 2.0 + 0.3, 1.0) * lum,
			  minf(tc.b * 2.0 + 0.3, 1.0) * lum, alpha))
	btn.add_theme_font_size_override("font_size", 12)

# ── Upgrade menu styling ──────────────────────────────────────────────────────

func _style_upgrade_menu() -> void:
	# ── Panel: dark aged-wood background with warm gold border ────────────
	var panel: PanelContainer = $HUD/UpgradeMenu/Panel
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.18, 0.12, 0.07, 0.98)
	ps.border_color = Color(0.68, 0.50, 0.22, 0.92)
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.corner_radius_top_left = 12
	ps.corner_radius_top_right = 12
	ps.corner_radius_bottom_left = 12
	ps.corner_radius_bottom_right = 12
	ps.content_margin_left = 16
	ps.content_margin_right = 16
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)

	# ── Cards: three earthy stone variants with amber border ──────────────
	var cards_row: HBoxContainer = $HUD/UpgradeMenu/Panel/ContentVBox/CardsRow
	# dark oak / olive stone / terracotta stone
	var card_colors := [
		Color(0.24, 0.16, 0.09),
		Color(0.18, 0.20, 0.12),
		Color(0.22, 0.14, 0.10),
	]
	# warm amber variants per card
	var border_cols := [
		Color(0.75, 0.56, 0.22),
		Color(0.62, 0.68, 0.30),
		Color(0.80, 0.50, 0.20),
	]
	for i in 3:
		var card: Node = cards_row.get_child(i)
		var cs := StyleBoxFlat.new()
		cs.bg_color     = card_colors[i]
		cs.border_color = border_cols[i]
		cs.border_width_left = 2
		cs.border_width_right = 2
		cs.border_width_top = 2
		cs.border_width_bottom = 2
		cs.corner_radius_top_left = 8
		cs.corner_radius_top_right = 8
		cs.corner_radius_bottom_left = 8
		cs.corner_radius_bottom_right = 8
		cs.content_margin_left = 8
		cs.content_margin_right = 8
		cs.content_margin_top = 8
		cs.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cs)

		var bc: Color = border_cols[i]
		var mk := func(bg_a: float, bo_a: float) -> StyleBoxFlat:
			var s := StyleBoxFlat.new()
			s.bg_color     = Color(bc.r * 0.45, bc.g * 0.35, bc.b * 0.15, bg_a)
			s.border_color = Color(bc.r, bc.g, bc.b, bo_a)
			s.border_width_left = 2
			s.border_width_right = 2
			s.border_width_top = 2
			s.border_width_bottom = 2
			s.corner_radius_top_left = 6
			s.corner_radius_top_right = 6
			s.corner_radius_bottom_left = 6
			s.corner_radius_bottom_right = 6
			return s
		var btn: Button = card.get_node("InnerVBox/Btn")
		btn.add_theme_stylebox_override("normal",  mk.call(0.60, 0.75))
		btn.add_theme_stylebox_override("hover",   mk.call(0.88, 1.00))
		btn.add_theme_stylebox_override("pressed", mk.call(0.35, 1.00))
		btn.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42, 1.0))

# ── Background & path drawing ─────────────────────────────────────────────────

func _draw() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	# 게임 화면은 포탑 바 위까지만 (하단 118px 제외)
	var game_h: float = vp_size.y - 118.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# ── 게임 영역 클립 마스크 ─────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, Vector2(vp_size.x, game_h)), Color(0.30, 0.62, 0.24))
	# 포탑 바 아래 영역 완전 불투명 덮개 (게임 오브젝트가 포탑 바 위로 렌더링되지 않도록)
	draw_rect(Rect2(Vector2(0, game_h), Vector2(vp_size.x, 118.0)), Color(0.14, 0.22, 0.10))
	# 경계 그림자 라인
	draw_rect(Rect2(Vector2(0, game_h - 5), Vector2(vp_size.x, 5)),
		Color(0.08, 0.06, 0.03, 0.70))
	# 경계 밝은 선
	draw_rect(Rect2(Vector2(0, game_h), Vector2(vp_size.x, 3)), Color(0.32, 0.55, 0.18))

	# Grass patch variation (게임 영역 내에서만)
	for i in 140:
		var gx: float = rng.randf() * vp_size.x
		var gy: float = rng.randf() * game_h
		var shade: float = rng.randf_range(-0.06, 0.07)
		var sz: float = rng.randf_range(10.0, 42.0)
		draw_circle(Vector2(gx, gy), sz,
			Color(0.30 + shade, 0.62 + shade * 0.8, 0.24 + shade * 0.5))

	# Bright flowers (5-petal)
	var fcols: Array = [
		Color(0.98, 0.88, 0.15, 0.85), Color(0.96, 0.32, 0.38, 0.85),
		Color(0.98, 0.98, 0.98, 0.85), Color(0.68, 0.35, 0.92, 0.80),
		Color(0.96, 0.58, 0.20, 0.85), Color(0.90, 0.30, 0.60, 0.80),
	]
	for i in 55:
		var fx: float = rng.randf() * vp_size.x
		var fy: float = rng.randf() * game_h
		var fc: Color = fcols[rng.randi() % fcols.size()]
		for p in 5:
			var pa: float = TAU * float(p) / 5.0
			draw_circle(Vector2(fx + cos(pa) * 3.5, fy + sin(pa) * 3.5), 2.5, fc)
		draw_circle(Vector2(fx, fy), 1.8, Color(1.0, 0.95, 0.35, 1.0))

	# Trees (avoid path)
	for i in 18:
		var tx: float = rng.randf() * vp_size.x
		var ty: float = rng.randf() * game_h
		if not _near_path(Vector2(tx, ty), 65.0):
			# Trunk
			draw_rect(Rect2(Vector2(tx - 4.0, ty - 2.0), Vector2(8, 20)), Color(0.48, 0.32, 0.16))
			draw_rect(Rect2(Vector2(tx - 2.0, ty - 2.0), Vector2(4, 20)), Color(0.55, 0.38, 0.20))
			# Canopy
			draw_circle(Vector2(tx, ty - 8.0),  16.0, Color(0.18, 0.50, 0.15))
			draw_circle(Vector2(tx - 9.0, ty - 3.0), 12.0, Color(0.22, 0.54, 0.18))
			draw_circle(Vector2(tx + 9.0, ty - 3.0), 12.0, Color(0.20, 0.52, 0.16))
			draw_circle(Vector2(tx, ty - 18.0), 11.0, Color(0.25, 0.58, 0.20))
			draw_circle(Vector2(tx - 3.0, ty - 14.0), 5.0, Color(0.35, 0.70, 0.28, 0.70))

	# ── Sandy road ────────────────────────────────────────────────────
	var curve: Curve2D = path.curve
	if curve == null or curve.point_count < 2:
		return
	var raw_points: PackedVector2Array = curve.get_baked_points()
	var path_offset: Vector2 = path.position
	var points: PackedVector2Array = PackedVector2Array()
	for p in raw_points:
		points.append(p + path_offset)

	# Dark earth border
	draw_polyline(points, Color(0.30, 0.22, 0.12), 54.0)
	for pt in points:
		draw_circle(pt, 27.0, Color(0.30, 0.22, 0.12))
	# Sandy surface
	draw_polyline(points, Color(0.78, 0.62, 0.36), 42.0)
	for pt in points:
		draw_circle(pt, 21.0, Color(0.78, 0.62, 0.36))
	# Subtle texture
	draw_polyline(points, Color(0.70, 0.55, 0.30, 0.40), 28.0)
	# Edge lines
	draw_polyline(points, Color(0.56, 0.44, 0.24, 0.45), 42.0)
	for pt in points:
		draw_circle(pt, 21.0, Color(0.56, 0.44, 0.24, 0.45))
	draw_polyline(points, Color(0.78, 0.62, 0.36), 38.0)
	for pt in points:
		draw_circle(pt, 19.0, Color(0.78, 0.62, 0.36))
	# Center dashes
	var dash_len: float = 14.0
	var gap_len: float  = 10.0
	var dist: float = 0.0
	var total_len: float = curve.get_baked_length()
	var drawing: bool = true
	while dist < total_len:
		var seg_end: float = dist + (dash_len if drawing else gap_len)
		seg_end = minf(seg_end, total_len)
		if drawing:
			var p1: Vector2 = curve.sample_baked(dist)     + path_offset
			var p2: Vector2 = curve.sample_baked(seg_end)  + path_offset
			draw_line(p1, p2, Color(0.88, 0.72, 0.48, 0.48), 2.5)
		dist = seg_end
		drawing = !drawing

# ── Game loop ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	if wave_announce_timer > 0.0:
		wave_announce_timer -= delta
		wave_announce.modulate.a = clamp(wave_announce_timer / 0.5, 0.0, 1.0)
		if wave_announce_timer <= 0.0:
			wave_announce.visible = false

	if wave_clear_timer > 0.0:
		wave_clear_timer -= delta
		wave_announce.modulate.a = clamp(wave_clear_timer / 0.5, 0.0, 1.0)
		if wave_clear_timer <= 0.0:
			wave_announce.visible = false

	if wave_in_progress:
		if enemies_to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_spawn_enemy()
				enemies_to_spawn -= 1
				spawn_timer = spawn_interval
		elif path.get_child_count() == 0:
			wave_in_progress = false
			_show_wave_clear()
			_start_next_wave_after_delay()
	else:
		between_wave_timer -= delta
		if between_wave_timer <= 0.0:
			_start_wave()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	var touch_pos: Vector2 = Vector2.ZERO
	var is_tap: bool = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		touch_pos = event.position
		is_tap = true
	elif event is InputEventScreenTouch and event.pressed:
		touch_pos = event.position
		is_tap = true
	if not is_tap:
		return
	# 업그레이드 패널이 열려 있으면 외부 탭으로 닫기
	if tower_upgrade_panel != null and tower_upgrade_panel.visible:
		var pr: Rect2 = Rect2(tower_upgrade_panel.position, tower_upgrade_panel.size)
		if not pr.has_point(touch_pos):
			_hide_tower_upgrade_panel()
			return
		return  # 패널 내부 탭은 버튼이 처리
	# 배치된 타워 클릭 감지
	var hit_tower: Tower = _find_tower_at(touch_pos)
	if hit_tower != null:
		_show_tower_upgrade_panel(hit_tower)
		return
	_try_place_tower(touch_pos)

# ── Wave ──────────────────────────────────────────────────────────────────────

func _show_wave_clear() -> void:
	wave_announce.text    = "웨이브 %d 클리어!" % wave
	wave_announce.modulate.a = 1.0
	wave_announce.visible = true
	wave_clear_timer      = 3.0
	wave_announce_timer   = 0.0

func _start_next_wave_after_delay() -> void:
	between_wave_timer = 5.0

func _start_wave() -> void:
	wave += 1
	wave_in_progress   = true
	enemies_to_spawn   = 5 + wave * 2
	spawn_interval     = max(0.25, 0.8 - wave * 0.03)
	spawn_timer        = 0.0
	wave_announce.text = "라운드 %d" % wave
	wave_announce.modulate.a = 1.0
	wave_announce.visible    = true
	wave_announce_timer      = 2.0
	_refresh_hud()

func _get_monster_type() -> int:
	if wave <= 3:    return 0
	elif wave <= 6:  return [0, 1].pick_random()
	elif wave <= 9:  return [1, 2].pick_random()
	elif wave <= 12: return [2, 3].pick_random()
	elif wave <= 15: return [3, 4].pick_random()
	else:            return [3, 4, 5].pick_random()

func _spawn_enemy() -> void:
	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop    = false
	path.add_child(follow)
	var enemy := Enemy.new()
	enemy.monster_type  = _get_monster_type()
	enemy.hp            = 8 + wave * 4
	enemy.max_hp        = enemy.hp
	enemy.speed         = 60.0 + wave * 4.0
	enemy.gold_reward   = int(round((3 + wave) * mod_gold_gain_mult))
	enemy.xp_reward     = int(round((1 + wave / 3) * mod_xp_gain_mult))
	enemy.path_follow   = follow
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	follow.add_child(enemy)

func _on_enemy_died(enemy: Node2D) -> void:
	gold += enemy.gold_reward
	_drop_gem(enemy.global_position, enemy.xp_reward)
	if enemy.poison_explodes:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == enemy or not is_instance_valid(e):
				continue
			if enemy.global_position.distance_to(e.global_position) <= 90.0:
				if e.has_method("apply_poison"):
					e.apply_poison(enemy.poison_damage, 2.5, false)
	enemy.path_follow.queue_free()
	_refresh_hud()
	_update_tower_bar_btns()

func _on_enemy_reached_end(enemy: Node2D) -> void:
	life -= 1
	enemy.path_follow.queue_free()
	if life <= 0:
		_game_over()
	_refresh_hud()

# ── XP gems ───────────────────────────────────────────────────────────────────

func _drop_gem(pos: Vector2, value: int) -> void:
	var gem := XpGem.new()
	gem.position = pos
	gem.value    = value
	gem.collected.connect(_on_gem_collected)
	gems_root.add_child(gem)

func _on_gem_collected(value: int) -> void:
	xp += value
	while xp >= xp_to_next:
		xp -= xp_to_next
		player_level += 1
		xp_to_next = int(round(xp_to_next * 1.5)) + 2
		_offer_upgrades()
	_refresh_hud()

# ── Level-up upgrades ─────────────────────────────────────────────────────────

func _build_upgrade_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for u in BASE_UPGRADES:
		pool.append(u.duplicate())
	return pool

func _offer_upgrades() -> void:
	var pool: Array[Dictionary] = _build_upgrade_pool()
	pool.shuffle()
	pending_choices = pool.slice(0, 3)

	lv_header.text = "⚔  LV.%d  LEVEL UP!  ⚔" % player_level

	for i in 3:
		if i < pending_choices.size():
			var u: Dictionary = pending_choices[i]
			card_icons[i].text = str(u.get("icon", "★"))
			card_names[i].text = str(u["name"])
			card_descs[i].text = str(u["desc"])
			(btns[i] as Button).visible = true
		else:
			card_icons[i].text = ""
			card_names[i].text = ""
			card_descs[i].text = ""
			(btns[i] as Button).visible = false

	upgrade_menu.visible = true
	get_tree().paused    = true
	process_mode         = Node.PROCESS_MODE_ALWAYS
	upgrade_menu.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_upgrade_picked(idx: int) -> void:
	if pending_choices.is_empty() or idx >= pending_choices.size():
		return
	var key: String = str(pending_choices[idx]["key"])
	match key:
		"dmg":  mod_damage_mult          *= 1.25
		"rate": mod_fire_rate_mult        *= 1.20
		"rng":  mod_range_mult            *= 1.15
		"proj": mod_projectile_speed_mult *= 1.25
		"gold": mod_gold_gain_mult        *= 1.20
		"xp":   mod_xp_gain_mult          *= 1.25
		"cost": tower_cost_reduction = mini(tower_cost_reduction + 10, 90)

	pending_choices.clear()
	upgrade_menu.visible = false
	get_tree().paused    = false
	for t in towers_root.get_children():
		if t is Tower:
			t.apply_global_mods(mod_damage_mult, mod_fire_rate_mult,
				mod_range_mult, mod_projectile_speed_mult)
	_refresh_hud()
	_update_tower_bar_btns()

# ── Tower placement ───────────────────────────────────────────────────────────

func _try_place_tower(pos: Vector2) -> void:
	var td: Dictionary = TOWER_TYPES[selected_tower_idx]
	var cost: int      = _get_tower_cost(selected_tower_idx)
	if gold < cost:
		return
	for t in towers_root.get_children():
		if t.position.distance_to(pos) < 50.0:
			return
	if _near_path(pos, 38.0):
		return
	# Don't place in tower bar area (bottom ~120px)
	if pos.y > get_viewport_rect().size.y - 130.0:
		return
	gold -= cost
	var tower := Tower.new()
	tower.position              = pos
	tower.enemies_root_path     = enemies_root.get_path()
	tower.projectiles_root_path = projectiles_root.get_path()
	tower.projectile_scene_script = preload("res://scripts/projectile.gd")
	tower.tower_idx      = selected_tower_idx
	tower.total_invested = cost
	tower.setup_type(td)
	tower.apply_global_mods(mod_damage_mult, mod_fire_rate_mult,
		mod_range_mult, mod_projectile_speed_mult)
	towers_root.add_child(tower)
	_refresh_hud()
	_update_tower_bar_btns()

func _near_path(pos: Vector2, threshold: float) -> bool:
	var curve: Curve2D = path.curve
	var offset: Vector2 = path.position
	for i in 65:
		var p: Vector2 = curve.sample_baked(curve.get_baked_length() * float(i) / 64.0) + offset
		if p.distance_to(pos) < threshold:
			return true
	return false

# ── Stage path setup ─────────────────────────────────────────────────────────

func _setup_stage_path() -> void:
	var curve := Curve2D.new()
	match GameState.selected_stage:
		1: _path_stage1(curve)
		2: _path_stage2(curve)
		3: _path_stage3(curve)
		4: _path_stage4(curve)
		_: _path_stage1(curve)
	path.curve = curve
	# 스테이지 이름을 웨이브 알림에 잠깐 표시
	wave_announce.text = "Stage %d  %s" % [
		GameState.selected_stage,
		GameState.STAGE_NAMES[GameState.selected_stage - 1]
	]
	wave_announce.modulate.a = 1.0
	wave_announce.visible    = true
	wave_announce_timer      = 2.5

func _path_stage1(c: Curve2D) -> void:
	# 초원의 길 — 완만한 S자
	c.add_point(Vector2(80,   80),  Vector2(0, 0),     Vector2(150, 50))
	c.add_point(Vector2(640,  300), Vector2(0, -120),  Vector2(0, 120))
	c.add_point(Vector2(80,   540), Vector2(0, -120),  Vector2(0, 120))
	c.add_point(Vector2(640,  760), Vector2(-20, -110),Vector2(20, 110))
	c.add_point(Vector2(80,   1000),Vector2(-150, 0),  Vector2(0, 0))
	c.add_point(Vector2(500,  1140),Vector2(0, 0),     Vector2(0, 0))

func _path_stage2(c: Curve2D) -> void:
	# 지그재그 협로 — 촘촘한 지그재그, 7번 꺾임
	c.add_point(Vector2(80,   60),  Vector2(0, 0),     Vector2(100, 0))
	c.add_point(Vector2(640,  170), Vector2(-100, -30),Vector2(-100, 30))
	c.add_point(Vector2(80,   300), Vector2(100, -30), Vector2(100, 30))
	c.add_point(Vector2(640,  430), Vector2(-100, -30),Vector2(-100, 30))
	c.add_point(Vector2(80,   560), Vector2(100, -30), Vector2(100, 30))
	c.add_point(Vector2(640,  690), Vector2(-100, -30),Vector2(-100, 30))
	c.add_point(Vector2(80,   820), Vector2(100, -30), Vector2(100, 30))
	c.add_point(Vector2(640,  950), Vector2(-100, -30),Vector2(-50, 60))
	c.add_point(Vector2(360,  1130),Vector2(0, 0),     Vector2(0, 0))

func _path_stage3(c: Curve2D) -> void:
	# 나선 계곡 — 시계 방향 대형 루프 후 중앙 하강
	c.add_point(Vector2(360,  60),  Vector2(0, 0),     Vector2(150, 0))
	c.add_point(Vector2(620,  230), Vector2(0, -100),  Vector2(0, 120))
	c.add_point(Vector2(600,  660), Vector2(80, -80),  Vector2(-60, 80))
	c.add_point(Vector2(360,  900), Vector2(100, 60),  Vector2(-100, -60))
	c.add_point(Vector2(120,  660), Vector2(60, 80),   Vector2(-60, -80))
	c.add_point(Vector2(160,  280), Vector2(-80, 80),  Vector2(60, -80))
	c.add_point(Vector2(360,  460), Vector2(-80, -40), Vector2(0, 80))
	c.add_point(Vector2(360,  1100),Vector2(0, 0),     Vector2(0, 0))

func _path_stage4(c: Curve2D) -> void:
	# 격자 미로 — 직각 수평 패스 3개
	c.add_point(Vector2(80,   80),  Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640,  80),  Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640,  380), Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(80,   380), Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(80,   680), Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640,  680), Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640,  980), Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(360,  1120),Vector2(0, 0),     Vector2(0, 0))

# ── Game over panel ───────────────────────────────────────────────────────────

func _build_game_over_panel() -> void:
	game_over_panel = Control.new()
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.visible      = false
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	$HUD.add_child(game_over_panel)

	# 어두운 오버레이
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.80)
	game_over_panel.add_child(overlay)

	# 중앙 패널
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left   = -220.0
	panel.offset_right  =  220.0
	panel.offset_top    = -195.0
	panel.offset_bottom =  195.0
	var ps := StyleBoxFlat.new()
	ps.bg_color    = Color(0.10, 0.04, 0.03, 0.98)
	ps.border_color = Color(0.82, 0.22, 0.08, 0.92)
	ps.border_width_left = ps.border_width_right = ps.border_width_top = ps.border_width_bottom = 3
	ps.corner_radius_top_left    = 16; ps.corner_radius_top_right   = 16
	ps.corner_radius_bottom_left = 16; ps.corner_radius_bottom_right= 16
	ps.content_margin_left  = 28; ps.content_margin_right  = 28
	ps.content_margin_top   = 22; ps.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", ps)
	game_over_panel.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# GAME OVER 제목
	var title_lbl := Label.new()
	title_lbl.text = "GAME  OVER"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 46)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.22, 0.08))
	vbox.add_child(title_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.80, 0.20, 0.08, 0.55))
	vbox.add_child(sep)

	# 웨이브 정보
	game_over_wave_lbl = Label.new()
	game_over_wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_wave_lbl.add_theme_font_size_override("font_size", 24)
	game_over_wave_lbl.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	vbox.add_child(game_over_wave_lbl)

	# 스테이지 정보
	game_over_stage_lbl = Label.new()
	game_over_stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stage_lbl.add_theme_font_size_override("font_size", 15)
	game_over_stage_lbl.add_theme_color_override("font_color", Color(0.65, 0.55, 0.38))
	vbox.add_child(game_over_stage_lbl)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.60, 0.20, 0.08, 0.35))
	vbox.add_child(sep2)

	# 다시하기 버튼
	var retry_btn := Button.new()
	retry_btn.text = "다시하기"
	retry_btn.custom_minimum_size = Vector2(240, 52)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_btn.add_theme_font_size_override("font_size", 24)
	retry_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var rs := StyleBoxFlat.new()
	rs.bg_color    = Color(0.20, 0.34, 0.10, 0.95)
	rs.border_color = Color(0.62, 0.84, 0.28, 0.92)
	rs.border_width_left = rs.border_width_right = rs.border_width_top = rs.border_width_bottom = 2
	rs.corner_radius_top_left = rs.corner_radius_top_right = 10
	rs.corner_radius_bottom_left = rs.corner_radius_bottom_right = 10
	var rsh := rs.duplicate() as StyleBoxFlat
	rsh.bg_color = Color(0.30, 0.48, 0.16, 0.98)
	retry_btn.add_theme_stylebox_override("normal", rs)
	retry_btn.add_theme_stylebox_override("hover",  rsh)
	retry_btn.add_theme_stylebox_override("pressed", rs)
	retry_btn.add_theme_color_override("font_color", Color(0.95, 0.90, 0.40))
	retry_btn.pressed.connect(_on_retry_pressed)
	vbox.add_child(retry_btn)

	# 타이틀로 버튼
	var title_btn := Button.new()
	title_btn.text = "타이틀로"
	title_btn.custom_minimum_size = Vector2(180, 42)
	title_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_btn.add_theme_font_size_override("font_size", 18)
	title_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var ts := StyleBoxFlat.new()
	ts.bg_color    = Color(0.18, 0.12, 0.07, 0.90)
	ts.border_color = Color(0.55, 0.42, 0.20, 0.75)
	ts.border_width_left = ts.border_width_right = ts.border_width_top = ts.border_width_bottom = 1
	ts.corner_radius_top_left = ts.corner_radius_top_right = 8
	ts.corner_radius_bottom_left = ts.corner_radius_bottom_right = 8
	var tsh := ts.duplicate() as StyleBoxFlat
	tsh.bg_color = Color(0.26, 0.18, 0.10, 0.95)
	title_btn.add_theme_stylebox_override("normal", ts)
	title_btn.add_theme_stylebox_override("hover",  tsh)
	title_btn.add_theme_stylebox_override("pressed", ts)
	title_btn.add_theme_color_override("font_color", Color(0.78, 0.66, 0.44))
	title_btn.pressed.connect(_on_title_btn_pressed)
	vbox.add_child(title_btn)

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_title_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _find_tower_at(pos: Vector2) -> Tower:
	for t in towers_root.get_children():
		if t is Tower and t.position.distance_to(pos) < 30.0:
			return t as Tower
	return null

# ── Tower upgrade panel ───────────────────────────────────────────────────────

func _build_tower_upgrade_panel() -> void:
	tower_upgrade_panel = Control.new()
	tower_upgrade_panel.visible = false
	tower_upgrade_panel.z_index = 25
	$HUD.add_child(tower_upgrade_panel)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(260, 0)
	var ps := StyleBoxFlat.new()
	ps.bg_color            = Color(0.14, 0.09, 0.05, 0.98)
	ps.border_color        = Color(0.70, 0.52, 0.22, 0.95)
	ps.border_width_left   = 2; ps.border_width_right  = 2
	ps.border_width_top    = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 12; ps.corner_radius_top_right   = 12
	ps.corner_radius_bottom_left = 12; ps.corner_radius_bottom_right= 12
	ps.content_margin_left = 14; ps.content_margin_right = 14
	ps.content_margin_top  = 12; ps.content_margin_bottom= 12
	panel.add_theme_stylebox_override("panel", ps)
	tower_upgrade_panel.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	panel.add_child(vbox)

	# 타워 이름 + 레벨
	var title_lbl := Label.new()
	title_lbl.name = "TitleLbl"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.35))
	vbox.add_child(title_lbl)

	var sep1 := HSeparator.new()
	sep1.add_theme_color_override("color", Color(0.60, 0.45, 0.20, 0.55))
	vbox.add_child(sep1)

	# 현재 스탯
	var cur_lbl := Label.new()
	cur_lbl.name = "CurStats"
	cur_lbl.add_theme_font_size_override("font_size", 12)
	cur_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.54))
	vbox.add_child(cur_lbl)

	# 다음 레벨 스탯 (맥스가 아닐 때만 표시)
	var next_lbl := Label.new()
	next_lbl.name = "NextStats"
	next_lbl.add_theme_font_size_override("font_size", 12)
	next_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 0.45))
	vbox.add_child(next_lbl)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.60, 0.45, 0.20, 0.35))
	vbox.add_child(sep2)

	# 버튼 행
	var btn_row := HBoxContainer.new()
	btn_row.name = "BtnRow"
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	# 업그레이드 버튼
	var upg_btn := Button.new()
	upg_btn.name = "UpgradeBtn"
	upg_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg_btn.custom_minimum_size = Vector2(0, 38)
	upg_btn.add_theme_font_size_override("font_size", 14)
	_style_action_btn(upg_btn, Color(0.25, 0.18, 0.08), Color(0.75, 0.56, 0.22))
	upg_btn.pressed.connect(_on_tower_upgrade_btn)
	btn_row.add_child(upg_btn)

	# 판매 버튼
	var sell_btn := Button.new()
	sell_btn.name = "SellBtn"
	sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_btn.custom_minimum_size = Vector2(0, 38)
	sell_btn.add_theme_font_size_override("font_size", 14)
	_style_action_btn(sell_btn, Color(0.22, 0.10, 0.06), Color(0.82, 0.38, 0.18))
	sell_btn.pressed.connect(_on_tower_sell_btn)
	btn_row.add_child(sell_btn)

	# 닫기 버튼
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 38)
	close_btn.add_theme_font_size_override("font_size", 14)
	_style_action_btn(close_btn, Color(0.18, 0.14, 0.10), Color(0.55, 0.45, 0.28))
	close_btn.pressed.connect(_hide_tower_upgrade_panel)
	btn_row.add_child(close_btn)

func _style_action_btn(btn: Button, bg: Color, bd: Color) -> void:
	var mk := func(bg_mult: float) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(bg.r * bg_mult, bg.g * bg_mult, bg.b * bg_mult, 0.95)
		s.border_color = bd
		s.border_width_left = 1; s.border_width_right  = 1
		s.border_width_top  = 1; s.border_width_bottom = 1
		s.corner_radius_top_left    = 6; s.corner_radius_top_right   = 6
		s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right= 6
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(1.0))
	btn.add_theme_stylebox_override("hover",   mk.call(1.5))
	btn.add_theme_stylebox_override("pressed", mk.call(0.7))
	btn.add_theme_color_override("font_color",
		Color(minf(bd.r + 0.3, 1.0), minf(bd.g + 0.3, 1.0), minf(bd.b + 0.3, 1.0)))

func _show_tower_upgrade_panel(tower: Tower) -> void:
	selected_placed_tower = tower
	_refresh_tower_upgrade_panel()
	# 포탑 위쪽에 패널 배치 (고정 크기 기준)
	var vp: Vector2 = get_viewport_rect().size
	var pw: float = 270.0
	var ph: float = 185.0
	var tx: float = tower.position.x - pw * 0.5
	var ty: float = tower.position.y - ph - 38.0
	tx = clamp(tx, 4.0, vp.x - pw - 4.0)
	ty = clamp(ty, 4.0, vp.y - 120.0 - ph - 4.0)
	tower_upgrade_panel.position = Vector2(tx, ty)
	tower_upgrade_panel.get_node("Panel").position = Vector2.ZERO
	tower_upgrade_panel.visible = true

func _refresh_tower_upgrade_panel() -> void:
	if selected_placed_tower == null or not is_instance_valid(selected_placed_tower):
		_hide_tower_upgrade_panel()
		return
	var tower: Tower = selected_placed_tower
	var td: Dictionary = TOWER_TYPES[tower.tower_idx] if tower.tower_idx >= 0 else TOWER_TYPES[0]
	var lv: int     = tower.tower_level
	var max_lv: int = tower.MAX_TOWER_LEVEL
	var lv_str: String = ("★MAX★" if lv >= max_lv else "Lv.%d / %d" % [lv, max_lv])

	var panel: PanelContainer = tower_upgrade_panel.get_node("Panel") as PanelContainer
	var vbox: VBoxContainer   = panel.get_child(0) as VBoxContainer
	(vbox.get_node("TitleLbl") as Label).text = "%s %s  [%s]" % [
		str(td["icon"]), str(td["name"]), lv_str]

	# 현재 스탯
	(vbox.get_node("CurStats") as Label).text = (
		"현재  ATK %d  /  %.1f/s  /  사거리 %d" % [
			tower.damage, tower.fire_rate, int(tower.range_px)])

	# 다음 레벨 스탯 & 업그레이드 버튼
	var upg_btn: Button  = vbox.get_node("BtnRow/UpgradeBtn") as Button
	var next_lbl: Label  = vbox.get_node("NextStats") as Label
	var sell_btn: Button = vbox.get_node("BtnRow/SellBtn") as Button

	if lv < max_lv:
		var ns: Dictionary = tower.get_next_level_stats()
		next_lbl.text = "다음  ATK %d  /  %.1f/s  /  사거리 %d" % [
			int(ns["damage"]), float(ns["fire_rate"]), int(ns["range"])]
		next_lbl.visible = true
		var upg_cost: int = _get_tower_upgrade_cost(tower)
		var can_afford: bool = gold >= upg_cost
		upg_btn.text = "강화 Lv%d→%d  (%dg)" % [lv, lv + 1, upg_cost]
		upg_btn.disabled = not can_afford
	else:
		next_lbl.text = "★ 최대 레벨 달성 ★"
		next_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
		next_lbl.visible = true
		upg_btn.text = "최대 레벨"
		upg_btn.disabled = true

	var sell_val: int = int(tower.total_invested * 0.6)
	sell_btn.text = "판매 (+%dg)" % sell_val

func _get_tower_upgrade_cost(tower: Tower) -> int:
	var base_cost: int = int(TOWER_TYPES[maxi(0, tower.tower_idx)]["cost"])
	# Lv1→2: 비용의 60%, Lv2→3: 비용의 100%
	if tower.tower_level == 1:
		return int(base_cost * 0.6)
	return base_cost

func _hide_tower_upgrade_panel() -> void:
	if tower_upgrade_panel != null:
		tower_upgrade_panel.visible = false
	selected_placed_tower = null

func _on_tower_upgrade_btn() -> void:
	if selected_placed_tower == null or not is_instance_valid(selected_placed_tower):
		_hide_tower_upgrade_panel(); return
	var cost: int = _get_tower_upgrade_cost(selected_placed_tower)
	if gold < cost: return
	gold -= cost
	selected_placed_tower.total_invested += cost
	selected_placed_tower.do_tower_upgrade()
	_refresh_tower_upgrade_panel()
	_refresh_hud()
	_update_tower_bar_btns()

func _on_tower_sell_btn() -> void:
	if selected_placed_tower == null or not is_instance_valid(selected_placed_tower):
		_hide_tower_upgrade_panel(); return
	var refund: int = int(selected_placed_tower.total_invested * 0.6)
	gold += refund
	selected_placed_tower.queue_free()
	_hide_tower_upgrade_panel()
	_refresh_hud()
	_update_tower_bar_btns()

# ── HUD ───────────────────────────────────────────────────────────────────────

func _refresh_hud() -> void:
	var td: Dictionary = TOWER_TYPES[selected_tower_idx]
	var cost: int = _get_tower_cost(selected_tower_idx)
	var afford: String = "" if gold >= cost else "  (골드 부족)"
	stats_label.text = "골드: %d   생명: %d   웨이브: %d\nLv%d  XP %d/%d   [%s %s %dg%s]" % [
		gold, life, wave, player_level, xp, xp_to_next,
		td["icon"], td["name"], cost, afford
	]

func _game_over() -> void:
	get_tree().paused = true
	var stage_name: String = GameState.STAGE_NAMES[GameState.selected_stage - 1]
	game_over_wave_lbl.text  = "웨이브 %d 도달" % wave
	game_over_stage_lbl.text = "Stage %d  %s" % [GameState.selected_stage, stage_name]
	game_over_panel.visible = true
