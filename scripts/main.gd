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

# === Wave control ===
var wave_in_progress: bool = false
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8
var between_wave_timer: float = 2.0

@onready var path: Path2D = $Path
@onready var enemies_root: Node2D = $Enemies
@onready var towers_root: Node2D = $Towers
@onready var projectiles_root: Node2D = $Projectiles
@onready var gems_root: Node2D = $Gems
@onready var stats_label: Label = $HUD/Stats
@onready var upgrade_menu: ColorRect = $HUD/UpgradeMenu
@onready var btns: Array[Button] = [
	$HUD/UpgradeMenu/VBox/B0,
	$HUD/UpgradeMenu/VBox/B1,
	$HUD/UpgradeMenu/VBox/B2,
]

const Enemy = preload("res://scripts/enemy.gd")
const Tower = preload("res://scripts/tower.gd")
const Projectile = preload("res://scripts/projectile.gd")
const XpGem = preload("res://scripts/xp_gem.gd")

func _ready() -> void:
	for i in btns.size():
		btns[i].pressed.connect(_on_upgrade_picked.bind(i))
	_refresh_hud()
	_start_next_wave_after_delay()

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	# Wave logic
	if wave_in_progress:
		if enemies_to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_spawn_enemy()
				enemies_to_spawn -= 1
				spawn_timer = spawn_interval
		elif enemies_root.get_child_count() == 0:
			wave_in_progress = false
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
func _start_next_wave_after_delay() -> void:
	between_wave_timer = 2.5

func _start_wave() -> void:
	wave += 1
	wave_in_progress = true
	enemies_to_spawn = 5 + wave * 2
	spawn_interval = max(0.25, 0.8 - wave * 0.03)
	spawn_timer = 0.0
	_refresh_hud()

func _spawn_enemy() -> void:
	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	path.add_child(follow)
	var enemy: Enemy = Enemy.new()
	enemy.hp = 8 + wave * 4
	enemy.max_hp = enemy.hp
	enemy.speed = 60.0 + wave * 4.0
	enemy.gold_reward = int(round((3 + wave) * mod_gold_gain_mult))
	enemy.xp_reward = int(round((1 + wave / 3) * mod_xp_gain_mult))
	enemy.path_follow = follow
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	follow.add_child(enemy)
	# PathFollow2D is parented to Path; enemy joins the "enemies" group so towers find it.

func _on_enemy_died(enemy: Node2D) -> void:
	gold += enemy.gold_reward
	_drop_gem(enemy.global_position, enemy.xp_reward)
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
const UPGRADES := [
	{"key": "dmg",  "name": "+25% Damage",          "desc": "All towers deal more damage."},
	{"key": "rate", "name": "+20% Fire Rate",       "desc": "All towers shoot faster."},
	{"key": "rng",  "name": "+15% Range",           "desc": "All towers see further."},
	{"key": "proj", "name": "+25% Projectile Speed","desc": "Bullets fly faster."},
	{"key": "gold", "name": "+20% Gold Gain",       "desc": "Earn more gold per kill."},
	{"key": "xp",   "name": "+25% XP Gain",         "desc": "Level up faster."},
	{"key": "cost", "name": "-10 Tower Cost",       "desc": "Cheaper towers."},
]

var pending_choices: Array = []

func _offer_upgrades() -> void:
	pending_choices = UPGRADES.duplicate()
	pending_choices.shuffle()
	pending_choices = pending_choices.slice(0, 3)
	for i in btns.size():
		var u = pending_choices[i]
		btns[i].text = "%s\n%s" % [u["name"], u["desc"]]
	upgrade_menu.visible = true
	get_tree().paused = true
	# Allow buttons to receive input while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_menu.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_upgrade_picked(idx: int) -> void:
	if pending_choices.is_empty():
		return
	var key: String = pending_choices[idx]["key"]
	match key:
		"dmg":  mod_damage_mult *= 1.25
		"rate": mod_fire_rate_mult *= 1.20
		"rng":  mod_range_mult *= 1.15
		"proj": mod_projectile_speed_mult *= 1.25
		"gold": mod_gold_gain_mult *= 1.20
		"xp":   mod_xp_gain_mult *= 1.25
		"cost": tower_cost = max(10, tower_cost - 10)
	pending_choices.clear()
	upgrade_menu.visible = false
	get_tree().paused = false
	# Re-apply modifiers to existing towers
	for t in towers_root.get_children():
		if t is Tower:
			t.apply_global_mods(mod_damage_mult, mod_fire_rate_mult, mod_range_mult, mod_projectile_speed_mult)
	_refresh_hud()

# === Tower placement ===
func _try_place_tower(pos: Vector2) -> void:
	if gold < tower_cost:
		return
	# Don't place too close to existing tower
	for t in towers_root.get_children():
		if t.position.distance_to(pos) < 50.0:
			return
	# Don't place on the path
	if _near_path(pos, 38.0):
		return
	gold -= tower_cost
	var tower: Tower = Tower.new()
	tower.position = pos
	tower.enemies_root_path = enemies_root.get_path()
	tower.projectiles_root_path = projectiles_root.get_path()
	tower.projectile_scene_script = Projectile
	tower.apply_global_mods(mod_damage_mult, mod_fire_rate_mult, mod_range_mult, mod_projectile_speed_mult)
	towers_root.add_child(tower)
	_refresh_hud()

func _near_path(pos: Vector2, threshold: float) -> bool:
	var curve := path.curve
	var samples := 64
	for i in samples + 1:
		var p := curve.sample_baked(curve.get_baked_length() * float(i) / samples)
		if p.distance_to(pos) < threshold:
			return true
	return false

# === HUD ===
func _refresh_hud() -> void:
	stats_label.text = "Gold: %d   Life: %d   Wave: %d\nLv %d   XP %d/%d   TowerCost %d" % [
		gold, life, wave, player_level, xp, xp_to_next, tower_cost
	]

func _game_over() -> void:
	get_tree().paused = true
	stats_label.text = "GAME OVER — Wave %d reached" % wave
