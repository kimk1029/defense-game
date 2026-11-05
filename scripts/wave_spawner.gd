class_name WaveSpawner
extends Node

# 단순 절차적 웨이브 생성기.
# 기본·러너·탱커 비율을 웨이브 진행에 따라 조절.

signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal enemy_killed(gold: int)
signal enemy_reached_base(damage: int)

var path: Path2D = null
var enemies_root: Node2D = null
var enemy_sprite_frames: SpriteFrames = null

var current_wave: int = 0
var in_progress: bool = false
var between_timer: float = 3.0
var spawn_timer: float = 0.0
var spawn_queue: Array = []
var alive_count: int = 0
## Injectable RNG so wave composition is reproducible (SPEC-03 AC-03-3).
var rng := RandomNumberGenerator.new()

func setup(_path: Path2D, _enemies: Node2D, _frames: SpriteFrames) -> void:
	path = _path
	enemies_root = _enemies
	enemy_sprite_frames = _frames
	between_timer = BalanceConfig.FIRST_PREP_TIME

func _process(delta: float) -> void:
	if not in_progress:
		between_timer -= delta
		if between_timer <= 0.0:
			_start_next_wave()
		return

	if not spawn_queue.is_empty():
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_one()
	elif alive_count <= 0:
		in_progress = false
		wave_cleared.emit(current_wave)
		between_timer = BalanceConfig.BETWEEN_WAVES_TIME

func _start_next_wave() -> void:
	current_wave += 1
	in_progress = true
	spawn_queue = _build_wave(current_wave)
	spawn_timer = 0.5
	wave_started.emit(current_wave)

func _build_wave(w: int) -> Array:
	var queue: Array = []
	var count: int = 6 + w * 2
	for i in count:
		var type_id: int = 0
		var r: float = rng.randf()
		if w >= 3 and r < 0.25:
			type_id = 2
		elif w >= 2 and r < 0.55:
			type_id = 1
		else:
			type_id = 0
		queue.append(type_id)
	return queue

func _spawn_one() -> void:
	if path == null or enemies_root == null:
		spawn_timer = 0.5
		return
	var type_id: int = int(spawn_queue.pop_front())
	var st: Dictionary = enemy_stats(type_id, current_wave, GameState.selected_stage)
	var hp: float = st["hp"]
	var spd: float = st["speed"]
	var arm: float = st["armor"]
	var gold: int = st["gold"]
	var dmg: int = st["dmg"]

	# Path follow
	var pf := PathFollow2D.new()
	pf.rotates = false
	pf.loop = false
	path.add_child(pf)

	var enemy := Enemy.new()
	enemy.setup(hp, spd, arm, gold, dmg)
	enemy.path_follow = pf
	enemies_root.add_child(enemy)
	enemy.global_position = pf.global_position

	# 스프라이트(선택): 있으면 붙임
	if enemy_sprite_frames != null:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = enemy_sprite_frames
		sprite.animation = &"walk"
		sprite.scale = Vector2(0.42, 0.42)
		sprite.position = Vector2(0.0, -4.0)
		sprite.play()
		enemy.add_child(sprite)
		enemy.sprite_node = sprite

	enemy.died.connect(_on_enemy_died)
	enemy.reached_base.connect(_on_reached_base)
	alive_count += 1
	spawn_timer = BalanceConfig.SPAWN_INTERVAL

## Enemy stats for a type at wave w (SPEC-03 AC-03-4, GDD §6).
## HP = linear base x BalanceConfig.hp_curve(w) x stage multiplier (SPEC-07).
static func enemy_stats(type_id: int, w: int, stage: int = 1) -> Dictionary:
	var fw: float = float(w)
	var st: Dictionary
	match type_id:
		1:
			st = {"hp": 46.0 + fw * 7.0, "speed": 68.0, "armor": 1.0, "gold": 5, "dmg": 1}
		2:
			st = {"hp": 110.0 + fw * 14.0, "speed": 42.0, "armor": 3.0 + fw * 0.25, "gold": 10, "dmg": 2}
		_:
			st = {"hp": 24.0 + fw * 5.0, "speed": 105.0, "armor": 0.0, "gold": 3, "dmg": 1}
	st["hp"] = float(st["hp"]) * BalanceConfig.hp_curve(w) * BalanceConfig.stage_hp_mult(stage, w)
	return st

func _on_enemy_died(gold: int) -> void:
	alive_count = maxi(0, alive_count - 1)
	enemy_killed.emit(gold)

func _on_reached_base(dmg: int) -> void:
	alive_count = maxi(0, alive_count - 1)
	enemy_reached_base.emit(dmg)
