extends Node2D

# === Game state ===
var gold: int = 150
var life: int = 20
var wave: int = 0
var player_level: int = 1
var xp: int = 0
var xp_to_next: int = 5

# === Global tower modifiers (Vampire Survivors-style permanent upgrades) ===
var mod_damage_mult: float = 1.0
var mod_fire_rate_mult: float = 1.0
var mod_range_mult: float = 1.0
var mod_projectile_speed_mult: float = 1.0
var mod_gold_gain_mult: float = 1.0
var mod_xp_gain_mult: float = 1.0
var tower_cost: int = 50

# === Special weapons: key -> level (1~5) ===
var special_weapon_levels: Dictionary = {}

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
@onready var btns: Array[Button] = [
	$HUD/UpgradeMenu/VBox/B0,
	$HUD/UpgradeMenu/VBox/B1,
	$HUD/UpgradeMenu/VBox/B2,
]

# === Base stat upgrades ===
const BASE_UPGRADES: Array[Dictionary] = [
	{"key": "dmg",  "name": "공격력 +25%",       "desc": "모든 타워의 공격력이 증가합니다."},
	{"key": "rate", "name": "공격속도 +20%",     "desc": "모든 타워가 더 빠르게 공격합니다."},
	{"key": "rng",  "name": "사거리 +15%",       "desc": "모든 타워의 사거리가 증가합니다."},
	{"key": "proj", "name": "투사체 속도 +25%",  "desc": "투사체가 더 빠르게 날아갑니다."},
	{"key": "gold", "name": "골드 획득 +20%",    "desc": "처치 시 더 많은 골드를 얻습니다."},
	{"key": "xp",   "name": "경험치 획득 +25%",  "desc": "더 빠르게 레벨업합니다."},
	{"key": "cost", "name": "타워 비용 -10",     "desc": "타워 건설 비용이 감소합니다."},
]

# === Special weapon definitions ===
const SPECIAL_WEAPONS: Array[Dictionary] = [
	{
		"key": "chain",
		"name": "체인 라이트닝",
		"icon": "⚡",
		"desc_new": "번개로 주변 적을 연쇄 공격합니다.",
		"desc_up": "연쇄 수와 데미지가 증가합니다.",
		"desc_max": "MAX! 번개에 맞은 적이 둔화됩니다!",
	},
	{
		"key": "freeze",
		"name": "냉동 폭탄",
		"icon": "❄",
		"desc_new": "폭발하여 범위 내 적을 둔화시킵니다.",
		"desc_up": "범위와 둔화 효과가 증가합니다.",
		"desc_max": "MAX! 적을 완전히 얼려버립니다!",
	},
	{
		"key": "poison",
		"name": "독화살",
		"icon": "☠",
		"desc_new": "적에게 지속 독 피해를 줍니다.",
		"desc_up": "독 데미지와 지속시간이 증가합니다.",
		"desc_max": "MAX! 중독된 적 사망 시 독이 퍼집니다!",
	},
	{
		"key": "meteor",
		"name": "유성",
		"icon": "☄",
		"desc_new": "강력한 범위 공격을 떨어뜨립니다.",
		"desc_up": "데미지와 범위가 증가합니다.",
		"desc_max": "MAX! 화염 지대를 남깁니다!",
	},
]

var pending_choices: Array = []

func _ready() -> void:
	for i in btns.size():
		btns[i].pressed.connect(_on_upgrade_picked.bind(i))
	_refresh_hud()
	_start_next_wave_after_delay()
	queue_redraw()

func _draw() -> void:
	# === Background grass ===
	var vp_size: Vector2 = get_viewport_rect().size
	# Base grass
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.22, 0.45, 0.18))
	# Grass texture pattern
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 120:
		var gx: float = rng.randf() * vp_size.x
		var gy: float = rng.randf() * vp_size.y
		var shade: float = rng.randf_range(-0.04, 0.04)
		var patch_size: float = rng.randf_range(15.0, 45.0)
		draw_circle(Vector2(gx, gy), patch_size, Color(0.22 + shade, 0.45 + shade * 2, 0.18 + shade))
	# Small flowers / details
	for i in 30:
		var fx: float = rng.randf() * vp_size.x
		var fy: float = rng.randf() * vp_size.y
		var flower_color: Color
		match rng.randi() % 4:
			0: flower_color = Color(0.9, 0.85, 0.2, 0.5)
			1: flower_color = Color(0.85, 0.35, 0.4, 0.5)
			2: flower_color = Color(0.95, 0.95, 0.9, 0.5)
			_: flower_color = Color(0.6, 0.4, 0.85, 0.5)
		draw_circle(Vector2(fx, fy), 3.0, flower_color)
	# Small trees
	for i in 12:
		var tx: float = rng.randf() * vp_size.x
		var ty: float = rng.randf() * vp_size.y
		# Skip if near path
		if not _near_path(Vector2(tx, ty), 60.0):
			# Trunk
			draw_rect(Rect2(Vector2(tx - 3, ty - 2), Vector2(6, 14)), Color(0.4, 0.28, 0.15))
			# Canopy
			draw_circle(Vector2(tx, ty - 8), 12.0, Color(0.15, 0.38, 0.12))
			draw_circle(Vector2(tx - 6, ty - 4), 9.0, Color(0.18, 0.4, 0.14))
			draw_circle(Vector2(tx + 6, ty - 4), 9.0, Color(0.18, 0.42, 0.13))

	# === Path / Road ===
	var curve: Curve2D = path.curve
	if curve == null or curve.point_count < 2:
		return
	var raw_points: PackedVector2Array = curve.get_baked_points()
	var path_offset: Vector2 = path.position
	var points: PackedVector2Array = PackedVector2Array()
	for p in raw_points:
		points.append(p + path_offset)
	var road_width: float = 42.0
	var border_width: float = 50.0
	# Dark edge
	draw_polyline(points, Color(0.28, 0.22, 0.12), border_width)
	for i in range(points.size()):
		draw_circle(points[i], border_width / 2.0, Color(0.28, 0.22, 0.12))
	# Road surface - sandy brown
	draw_polyline(points, Color(0.55, 0.42, 0.25), road_width)
	for i in range(points.size()):
		draw_circle(points[i], road_width / 2.0, Color(0.55, 0.42, 0.25))
	# Road dirt detail
	draw_polyline(points, Color(0.5, 0.38, 0.22, 0.4), road_width * 0.6)
	# Center dashed line
	var dash_len: float = 12.0
	var gap_len: float = 8.0
	var dist: float = 0.0
	var total_len: float = curve.get_baked_length()
	var drawing: bool = true
	while dist < total_len:
		var seg_end: float = dist + (dash_len if drawing else gap_len)
		seg_end = minf(seg_end, total_len)
		if drawing:
			var p1: Vector2 = curve.sample_baked(dist) + path_offset
			var p2: Vector2 = curve.sample_baked(seg_end) + path_offset
			draw_line(p1, p2, Color(0.65, 0.55, 0.35, 0.35), 2.0)
		dist = seg_end
		drawing = !drawing

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	# Wave announce fade out
	if wave_announce_timer > 0.0:
		wave_announce_timer -= delta
		var alpha: float = clamp(wave_announce_timer / 0.5, 0.0, 1.0)
		wave_announce.modulate.a = alpha
		if wave_announce_timer <= 0.0:
			wave_announce.visible = false

	# Wave clear message fade out
	if wave_clear_timer > 0.0:
		wave_clear_timer -= delta
		var alpha: float = clamp(wave_clear_timer / 0.5, 0.0, 1.0)
		wave_announce.modulate.a = alpha
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_tower(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_try_place_tower(event.position)

# === Wave ===
func _show_wave_clear() -> void:
	wave_announce.text = "웨이브 %d 클리어!" % wave
	wave_announce.modulate.a = 1.0
	wave_announce.visible = true
	wave_clear_timer = 3.0
	wave_announce_timer = 0.0  # cancel any pending wave announce fade

func _start_next_wave_after_delay() -> void:
	between_wave_timer = 5.0

func _start_wave() -> void:
	wave += 1
	wave_in_progress = true
	enemies_to_spawn = 5 + wave * 2
	spawn_interval = max(0.25, 0.8 - wave * 0.03)
	spawn_timer = 0.0
	# Show wave announcement
	wave_announce.text = "라운드 %d" % wave
	wave_announce.modulate.a = 1.0
	wave_announce.visible = true
	wave_announce_timer = 2.0
	_refresh_hud()

func _get_monster_type() -> int:
	# 웨이브에 따라 몬스터 타입 결정 (후반 웨이브에서 강한 몬스터 등장)
	if wave <= 3:
		return 0  # Slime
	elif wave <= 6:
		return [0, 1].pick_random()  # Slime + Goblin
	elif wave <= 9:
		return [1, 2].pick_random()  # Goblin + Spider
	elif wave <= 12:
		return [2, 3].pick_random()  # Spider + Skeleton
	elif wave <= 15:
		return [3, 4].pick_random()  # Skeleton + Orc
	else:
		return [3, 4, 5].pick_random()  # Skeleton + Orc + Harpy

func _spawn_enemy() -> void:
	var follow: PathFollow2D = PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	path.add_child(follow)
	var enemy: Enemy = Enemy.new()
	enemy.monster_type = _get_monster_type()
	enemy.hp = 8 + wave * 4
	enemy.max_hp = enemy.hp
	enemy.speed = 60.0 + wave * 4.0
	enemy.gold_reward = int(round((3 + wave) * mod_gold_gain_mult))
	enemy.xp_reward = int(round((1 + wave / 3) * mod_xp_gain_mult))
	enemy.path_follow = follow
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	follow.add_child(enemy)

func _on_enemy_died(enemy: Node2D) -> void:
	gold += enemy.gold_reward
	_drop_gem(enemy.global_position, enemy.xp_reward)
	# Poison explosion on death (MAX level effect)
	if enemy.poison_explodes:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == enemy or not is_instance_valid(e):
				continue
			var d: float = enemy.global_position.distance_to(e.global_position)
			if d <= 90.0 and e.has_method("apply_poison"):
				e.apply_poison(enemy.poison_damage, 2.5, false)
	enemy.path_follow.queue_free()
	_refresh_hud()

func _on_enemy_reached_end(enemy: Node2D) -> void:
	life -= 1
	enemy.path_follow.queue_free()
	if life <= 0:
		_game_over()
	_refresh_hud()

# === XP gems ===
func _drop_gem(pos: Vector2, value: int) -> void:
	var gem: XpGem = XpGem.new()
	gem.position = pos
	gem.value = value
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

# === Upgrades ===
func _build_upgrade_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	# Base stat upgrades
	for u in BASE_UPGRADES:
		pool.append(u.duplicate())

	# Special weapon upgrades
	for sw in SPECIAL_WEAPONS:
		var key: String = str(sw["key"])
		var level: int = int(special_weapon_levels.get(key, 0))
		if level >= 5:
			continue
		var entry: Dictionary = {}
		entry["key"] = "sw_" + key
		if level == 0:
			entry["name"] = "%s %s 획득" % [sw["icon"], sw["name"]]
			entry["desc"] = str(sw["desc_new"])
		elif level == 4:
			entry["name"] = "%s %s Lv5" % [sw["icon"], sw["name"]]
			entry["desc"] = str(sw["desc_max"])
		else:
			entry["name"] = "%s %s Lv%d→%d" % [sw["icon"], sw["name"], level, level + 1]
			entry["desc"] = str(sw["desc_up"])
		pool.append(entry)

	return pool

func _offer_upgrades() -> void:
	var pool: Array[Dictionary] = _build_upgrade_pool()
	pool.shuffle()
	pending_choices = pool.slice(0, 3)
	for i in btns.size():
		if i < pending_choices.size():
			var u: Dictionary = pending_choices[i]
			btns[i].text = "%s\n%s" % [u["name"], u["desc"]]
			btns[i].visible = true
		else:
			btns[i].visible = false
	upgrade_menu.visible = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_menu.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_upgrade_picked(idx: int) -> void:
	if pending_choices.is_empty() or idx >= pending_choices.size():
		return
	var key: String = str(pending_choices[idx]["key"])

	if key.begins_with("sw_"):
		# Special weapon upgrade
		var sw_key: String = key.substr(3)
		var cur_level: int = int(special_weapon_levels.get(sw_key, 0))
		special_weapon_levels[sw_key] = mini(5, cur_level + 1)
		_update_towers_special_weapons()
	else:
		# Base stat upgrade
		match key:
			"dmg":  mod_damage_mult *= 1.25
			"rate": mod_fire_rate_mult *= 1.20
			"rng":  mod_range_mult *= 1.15
			"proj": mod_projectile_speed_mult *= 1.25
			"gold": mod_gold_gain_mult *= 1.20
			"xp":   mod_xp_gain_mult *= 1.25
			"cost": tower_cost = maxi(10, tower_cost - 10)

	pending_choices.clear()
	upgrade_menu.visible = false
	get_tree().paused = false
	# Re-apply modifiers to existing towers
	for t in towers_root.get_children():
		if t is Tower:
			t.apply_global_mods(mod_damage_mult, mod_fire_rate_mult, mod_range_mult, mod_projectile_speed_mult)
	_refresh_hud()

func _update_towers_special_weapons() -> void:
	for t in towers_root.get_children():
		if t is Tower:
			t.update_special_weapons(special_weapon_levels)

# === Tower placement ===
func _try_place_tower(pos: Vector2) -> void:
	if gold < tower_cost:
		return
	for t in towers_root.get_children():
		if t.position.distance_to(pos) < 50.0:
			return
	if _near_path(pos, 38.0):
		return
	gold -= tower_cost
	var tower: Tower = Tower.new()
	tower.position = pos
	tower.enemies_root_path = enemies_root.get_path()
	tower.projectiles_root_path = projectiles_root.get_path()
	tower.projectile_scene_script = preload("res://scripts/projectile.gd")
	tower.apply_global_mods(mod_damage_mult, mod_fire_rate_mult, mod_range_mult, mod_projectile_speed_mult)
	tower.update_special_weapons(special_weapon_levels)
	towers_root.add_child(tower)
	_refresh_hud()

func _near_path(pos: Vector2, threshold: float) -> bool:
	var curve: Curve2D = path.curve
	var offset: Vector2 = path.position
	var samples: int = 64
	for i in samples + 1:
		var p: Vector2 = curve.sample_baked(curve.get_baked_length() * float(i) / samples) + offset
		if p.distance_to(pos) < threshold:
			return true
	return false

# === HUD ===
func _refresh_hud() -> void:
	var sw_text: String = ""
	for sw in SPECIAL_WEAPONS:
		var key: String = str(sw["key"])
		var level: int = int(special_weapon_levels.get(key, 0))
		if level > 0:
			var max_tag: String = " MAX" if level >= 5 else ""
			sw_text += "  %s%d%s" % [sw["icon"], level, max_tag]
	stats_label.text = "골드: %d   생명: %d   웨이브: %d\nLv %d   경험치 %d/%d   타워비용 %d%s" % [
		gold, life, wave, player_level, xp, xp_to_next, tower_cost, sw_text
	]

func _game_over() -> void:
	get_tree().paused = true
	stats_label.text = "게임 오버 — 웨이브 %d 도달" % wave
