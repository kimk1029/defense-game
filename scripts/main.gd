class_name GameMain
extends Node2D

# 메인 게임 허브.
# - 씬 트리의 노드 참조를 담당
# - Terrain/PlacementSystem/WaveSpawner/HUD 조립
# - 시그널 연결(골드/생명/웨이브 변화 → HUD 갱신)
#
# 주의: _draw()를 직접 오버라이드하지 않는다. 지형 그리기는 Terrain 노드가 전담한다.
# (과거 main.gd가 매 프레임 지형을 다시 그려 심각한 프레임 드랍을 일으켰음)

static var instance: GameMain = null

signal gold_changed(new_gold: int)
signal life_changed(new_life: int)

# ── 씬 참조 ───────────────────────────────────────────────────────────
@onready var path: Path2D = $Path
@onready var enemies_root: Node2D = $Enemies
@onready var towers_root: Node2D = $Towers
@onready var projectiles_root: Node2D = $Projectiles
@onready var hud: CanvasLayer = $HUD
@onready var stats_label: Label = $HUD/Stats
@onready var wave_announce: Label = $HUD/WaveAnnounce
@onready var tower_bar_row: HBoxContainer = $HUD/TowerBar/BtnRow

# ── 시스템 노드 ───────────────────────────────────────────────────────
var terrain: Terrain = null
var placement: PlacementSystem = null
var spawner: WaveSpawner = null

# ── 인스펙터(업그레이드/판매) ─────────────────────────────────────────
var tower_inspector: PanelContainer = null
var ins_title_lbl: Label = null
var ins_cur_lbl: Label = null
var ins_next_lbl: Label = null
var ins_upg_btn: Button = null
var ins_sell_btn: Button = null
var selected_tower: Tower = null

# ── 게임오버 ──────────────────────────────────────────────────────────
var game_over_active: bool = false
var enemy_sprite_frames: SpriteFrames = null

# =====================================================================

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	GameState.reset_run()

	# 레거시 UI 요소 숨김
	var um: Node = $HUD.get_node_or_null("UpgradeMenu")
	if um != null:
		um.visible = false
	var gems: Node = get_node_or_null("Gems")
	if gems != null:
		gems.visible = false

	# 적 스프라이트(메인씬 템플릿에서 SpriteFrames 캐싱)
	var monster_tmpl: Node = enemies_root.get_node_or_null("Monster")
	if monster_tmpl != null:
		var anim: AnimatedSprite2D = monster_tmpl.get_node_or_null("AnimatedSprite2D")
		if anim != null:
			enemy_sprite_frames = anim.sprite_frames
		monster_tmpl.queue_free()

	# 스테이지 경로 설정
	_setup_stage_path()

	# 지형 (1회만 그림)
	terrain = Terrain.new()
	terrain.z_index = -10
	add_child(terrain)
	terrain.setup(path)

	# 배치 시스템
	placement = PlacementSystem.new()
	placement.name = "PlacementSystem"
	add_child(placement)
	placement.setup(towers_root, path, enemies_root, projectiles_root)
	placement.placed.connect(_on_tower_placed)

	# 웨이브 스포너
	spawner = WaveSpawner.new()
	spawner.name = "WaveSpawner"
	add_child(spawner)
	spawner.setup(path, enemies_root, enemy_sprite_frames)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	spawner.enemy_killed.connect(_on_enemy_killed)
	spawner.enemy_reached_base.connect(_on_enemy_reached_base)

	# HUD 갱신 시그널 연결
	gold_changed.connect(_refresh_hud.unbind(1))
	life_changed.connect(_refresh_hud.unbind(1))

	_build_tower_bar()
	_build_tower_inspector()
	_refresh_hud()

# =====================================================================
# Input
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if game_over_active:
		return
	# 배치 중에는 Placement가 먼저 처리한다
	if placement != null and placement.is_placing():
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		var hit: Tower = _find_tower_at(pos)
		if hit != null:
			_show_inspector(hit)
			get_viewport().set_input_as_handled()
			return
		# 빈 영역 클릭 시 인스펙터 닫기
		if tower_inspector != null and tower_inspector.visible:
			var pr: Rect2 = Rect2(tower_inspector.position, tower_inspector.size)
			if not pr.has_point(pos):
				_hide_inspector()

func _find_tower_at(pos: Vector2) -> Tower:
	for t in towers_root.get_children():
		if t is Tower and (t as Tower).global_position.distance_to(pos) < 30.0:
			return t
	return null

# =====================================================================
# 이벤트 핸들러
# =====================================================================
func _on_tower_placed(_tower: Tower) -> void:
	gold_changed.emit(GameState.gold)

func _on_wave_started(wave: int) -> void:
	GameState.wave = wave
	wave_announce.text = "웨이브 %d" % wave
	wave_announce.add_theme_color_override("font_color", Color(0.12, 0.35, 0.05, 1.0))
	wave_announce.visible = true
	wave_announce.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(wave_announce, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_hide_wave_announce)
	_refresh_hud()

func _hide_wave_announce() -> void:
	wave_announce.visible = false

func _on_wave_cleared(_w: int) -> void:
	pass

func _on_enemy_killed(gold: int) -> void:
	GameState.gold += gold
	gold_changed.emit(GameState.gold)

func _on_enemy_reached_base(dmg: int) -> void:
	GameState.life -= dmg
	life_changed.emit(GameState.life)
	if GameState.life <= 0:
		_game_over()

func _game_over() -> void:
	if game_over_active:
		return
	game_over_active = true
	get_tree().paused = false
	wave_announce.text = "GAME OVER"
	wave_announce.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15))
	wave_announce.visible = true
	wave_announce.modulate.a = 1.0
	# 시뮬레이션 정지
	spawner.set_process(false)
	for e in enemies_root.get_children():
		if e is Enemy:
			(e as Enemy).set_process(false)
	for t in towers_root.get_children():
		if t is Tower:
			(t as Tower).set_process(false)
	for p in projectiles_root.get_children():
		p.set_process(false)

# =====================================================================
# HUD
# =====================================================================
func _refresh_hud() -> void:
	stats_label.text = "골드  %d     생명  %d     웨이브  %d" % [
		GameState.gold, GameState.life, GameState.wave
	]
	if tower_inspector != null and tower_inspector.visible and selected_tower != null:
		if is_instance_valid(selected_tower):
			_refresh_inspector()
		else:
			_hide_inspector()

# =====================================================================
# Tower bar
# =====================================================================
func _build_tower_bar() -> void:
	for c in tower_bar_row.get_children():
		c.queue_free()
	tower_bar_row.add_theme_constant_override("separation", 6)

	for id in TowerRegistry.get_all_ids():
		var td: Dictionary = TowerRegistry.get_tower(id)
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 108.0)
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = "%s\n%s\n%dg" % [td["icon"], td["name"], td["cost"]]
		_style_tower_btn(btn, td["color"] as Color)
		btn.pressed.connect(_on_tower_bar_pressed.bind(id))
		tower_bar_row.add_child(btn)

func _style_tower_btn(btn: Button, tc: Color) -> void:
	var mk := func(dark: float) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(tc.r * dark, tc.g * dark, tc.b * dark, 0.92)
		s.border_color = Color(tc.r, tc.g, tc.b, 1.0)
		s.border_width_left = 2; s.border_width_right = 2
		s.border_width_top = 2; s.border_width_bottom = 2
		s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
		s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(0.26))
	btn.add_theme_stylebox_override("hover",   mk.call(0.42))
	btn.add_theme_stylebox_override("pressed", mk.call(0.58))
	btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))

func _on_tower_bar_pressed(id: StringName) -> void:
	placement.begin_placement(id)
	# 배치 시작 시 인스펙터는 닫음
	if tower_inspector != null and tower_inspector.visible:
		_hide_inspector()

# =====================================================================
# Tower inspector (upgrade / sell)
# =====================================================================
func _build_tower_inspector() -> void:
	tower_inspector = PanelContainer.new()
	tower_inspector.name = "TowerInspector"
	tower_inspector.visible = false
	tower_inspector.z_index = 30
	tower_inspector.custom_minimum_size = Vector2(240.0, 0.0)
	hud.add_child(tower_inspector)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.04, 0.96)
	ps.border_color = Color(0.72, 0.54, 0.22, 0.92)
	ps.border_width_left = 2; ps.border_width_right = 2
	ps.border_width_top = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	ps.content_margin_left = 12; ps.content_margin_right = 12
	ps.content_margin_top = 10; ps.content_margin_bottom = 10
	tower_inspector.add_theme_stylebox_override("panel", ps)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	tower_inspector.add_child(vbox)

	ins_title_lbl = Label.new()
	ins_title_lbl.add_theme_font_size_override("font_size", 16)
	ins_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50))
	vbox.add_child(ins_title_lbl)

	ins_cur_lbl = Label.new()
	ins_cur_lbl.add_theme_font_size_override("font_size", 12)
	ins_cur_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.50))
	vbox.add_child(ins_cur_lbl)

	ins_next_lbl = Label.new()
	ins_next_lbl.add_theme_font_size_override("font_size", 12)
	ins_next_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.50))
	vbox.add_child(ins_next_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	vbox.add_child(row)

	ins_upg_btn = Button.new()
	ins_upg_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ins_upg_btn.custom_minimum_size = Vector2(0.0, 34.0)
	ins_upg_btn.add_theme_font_size_override("font_size", 13)
	ins_upg_btn.pressed.connect(_on_inspector_upgrade)
	row.add_child(ins_upg_btn)

	ins_sell_btn = Button.new()
	ins_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ins_sell_btn.custom_minimum_size = Vector2(0.0, 34.0)
	ins_sell_btn.add_theme_font_size_override("font_size", 13)
	ins_sell_btn.pressed.connect(_on_inspector_sell)
	row.add_child(ins_sell_btn)

func _show_inspector(tower: Tower) -> void:
	selected_tower = tower
	_refresh_inspector()
	tower_inspector.visible = true
	await get_tree().process_frame
	if not is_instance_valid(selected_tower):
		return
	var sz: Vector2 = tower_inspector.size
	var vp: Vector2 = get_viewport_rect().size
	var tx: float = clampf(tower.global_position.x - sz.x * 0.5, 4.0, vp.x - sz.x - 4.0)
	var ty: float = clampf(tower.global_position.y - sz.y - 34.0, 4.0, vp.y - 130.0 - sz.y - 4.0)
	tower_inspector.position = Vector2(tx, ty)

func _hide_inspector() -> void:
	if tower_inspector != null:
		tower_inspector.visible = false
	selected_tower = null

func _refresh_inspector() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		return
	var td: Dictionary = selected_tower.tower_data
	var lv: int = selected_tower.level
	var lv_str: String
	if lv >= Tower.MAX_LEVEL_INDEX:
		lv_str = "★MAX★"
	else:
		lv_str = "Lv.%d / %d" % [lv + 1, Tower.MAX_LEVEL_INDEX + 1]

	ins_title_lbl.text = "%s %s  [%s]" % [td["icon"], td["name"], lv_str]
	ins_cur_lbl.text = "현재  ATK %.0f  /  %.2f/s  /  RNG %d" % [
		selected_tower.damage,
		selected_tower.attack_speed,
		int(selected_tower.attack_range),
	]

	if lv < Tower.MAX_LEVEL_INDEX:
		var ns: Dictionary = selected_tower.next_level_stats()
		var cost: int = selected_tower.upgrade_cost()
		ins_next_lbl.text = "다음  ATK %.0f  /  %.2f/s  /  RNG %d" % [
			float(ns["damage"]),
			float(ns["attack_speed"]),
			int(ns["range"]),
		]
		ins_upg_btn.text = "강화 Lv%d→%d  (%dg)" % [lv + 1, lv + 2, cost]
		ins_upg_btn.disabled = GameState.gold < cost
	else:
		ins_next_lbl.text = "★ 최대 레벨 달성 ★"
		ins_upg_btn.text = "최대 레벨"
		ins_upg_btn.disabled = true

	ins_sell_btn.text = "판매 (+%dg)" % selected_tower.sell_refund()

func _on_inspector_upgrade() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		_hide_inspector()
		return
	if selected_tower.try_upgrade():
		gold_changed.emit(GameState.gold)
		_refresh_inspector()

func _on_inspector_sell() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		_hide_inspector()
		return
	var refund: int = selected_tower.sell_refund()
	GameState.gold += refund
	selected_tower.queue_free()
	gold_changed.emit(GameState.gold)
	_hide_inspector()

# =====================================================================
# Stage paths
# =====================================================================
func _setup_stage_path() -> void:
	var curve := Curve2D.new()
	match GameState.selected_stage:
		1: _path_stage1(curve)
		2: _path_stage2(curve)
		3: _path_stage3(curve)
		4: _path_stage4(curve)
		_: _path_stage1(curve)
	path.curve = curve

func _path_stage1(c: Curve2D) -> void:
	c.add_point(Vector2(80, 80),    Vector2(0, 0),     Vector2(150, 50))
	c.add_point(Vector2(640, 300),  Vector2(0, -120),  Vector2(0, 120))
	c.add_point(Vector2(80, 540),   Vector2(0, -120),  Vector2(0, 120))
	c.add_point(Vector2(640, 760),  Vector2(-20, -110),Vector2(20, 110))
	c.add_point(Vector2(80, 1000),  Vector2(-150, 0),  Vector2(0, 0))
	c.add_point(Vector2(500, 1140), Vector2(0, 0),     Vector2(0, 0))

func _path_stage2(c: Curve2D) -> void:
	c.add_point(Vector2(80, 60),    Vector2(0, 0),     Vector2(100, 0))
	c.add_point(Vector2(640, 170),  Vector2(-100, -30),Vector2(-100, 30))
	c.add_point(Vector2(80, 300),   Vector2(100, -30), Vector2(100, 30))
	c.add_point(Vector2(640, 430),  Vector2(-100, -30),Vector2(-100, 30))
	c.add_point(Vector2(80, 560),   Vector2(100, -30), Vector2(100, 30))
	c.add_point(Vector2(640, 690),  Vector2(-100, -30),Vector2(-100, 30))
	c.add_point(Vector2(80, 820),   Vector2(100, -30), Vector2(100, 30))
	c.add_point(Vector2(640, 950),  Vector2(-100, -30),Vector2(-50, 60))
	c.add_point(Vector2(360, 1130), Vector2(0, 0),     Vector2(0, 0))

func _path_stage3(c: Curve2D) -> void:
	c.add_point(Vector2(360, 60),   Vector2(0, 0),     Vector2(150, 0))
	c.add_point(Vector2(620, 230),  Vector2(0, -100),  Vector2(0, 120))
	c.add_point(Vector2(600, 660),  Vector2(80, -80),  Vector2(-60, 80))
	c.add_point(Vector2(360, 900),  Vector2(100, 60),  Vector2(-100, -60))
	c.add_point(Vector2(120, 660),  Vector2(60, 80),   Vector2(-60, -80))
	c.add_point(Vector2(160, 280),  Vector2(-80, 80),  Vector2(60, -80))
	c.add_point(Vector2(360, 460),  Vector2(-80, -40), Vector2(0, 80))
	c.add_point(Vector2(360, 1100), Vector2(0, 0),     Vector2(0, 0))

func _path_stage4(c: Curve2D) -> void:
	c.add_point(Vector2(80, 80),    Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640, 80),   Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640, 380),  Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(80, 380),   Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(80, 680),   Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640, 680),  Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(640, 980),  Vector2(0, 0),     Vector2(0, 0))
	c.add_point(Vector2(360, 1120), Vector2(0, 0),     Vector2(0, 0))
