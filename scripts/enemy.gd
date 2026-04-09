extends Node2D
class_name Enemy

signal died(enemy)
signal reached_end(enemy)

static var ENEMY_SHEET: Texture2D = null

# Sprite regions in the sheet (x, y, w, h) for each monster type
const SPRITE_REGIONS: Array[Rect2] = [
	Rect2(1700, 1170, 250, 230),   # 0: Slime - bottom-right, big green blob
	Rect2(140, 40, 240, 270),      # 1: Goblin - top-left, idle pose
	Rect2(1450, 520, 350, 260),    # 2: Spider - mid-right, first spider
	Rect2(120, 820, 200, 250),     # 3: Skeleton - bot-left, first skeleton
	Rect2(140, 490, 290, 270),     # 4: Orc - mid-left, orc with axe
	Rect2(1450, 40, 290, 270),     # 5: Harpy - top-right, first harpy
]

var hp: int = 10
var max_hp: int = 10
var speed: float = 60.0
var gold_reward: int = 3
var xp_reward: int = 1
var path_follow: PathFollow2D
var dead: bool = false
var monster_type: int = 0

# Status effects
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var frozen_timer: float = 0.0
var poison_timer: float = 0.0
var poison_tick_timer: float = 0.0
var poison_damage: int = 0
var poison_explodes: bool = false
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
var burn_damage: int = 0

func _ready() -> void:
	z_index = 5
	add_to_group("enemies")
	if ENEMY_SHEET == null:
		ENEMY_SHEET = load("res://assets/enemy.png")

func _process(delta: float) -> void:
	if dead or path_follow == null:
		return

	if frozen_timer > 0.0:
		frozen_timer -= delta
		queue_redraw()
		return

	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0

	if poison_timer > 0.0:
		poison_timer -= delta
		poison_tick_timer -= delta
		if poison_tick_timer <= 0.0:
			poison_tick_timer = 0.5
			take_damage(poison_damage)
			if dead:
				return

	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 0.5
			take_damage(burn_damage)
			if dead:
				return

	path_follow.progress += speed * slow_factor * delta
	global_position = path_follow.global_position
	if path_follow.progress_ratio >= 1.0:
		dead = true
		emit_signal("reached_end", self)

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	if hp <= 0:
		dead = true
		emit_signal("died", self)

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = min(slow_factor, factor)
	slow_timer = max(slow_timer, duration)

func apply_freeze(duration: float) -> void:
	frozen_timer = max(frozen_timer, duration)

func apply_poison(dmg: int, duration: float, explodes: bool) -> void:
	poison_damage = max(poison_damage, dmg)
	poison_timer = max(poison_timer, duration)
	if poison_tick_timer <= 0.0:
		poison_tick_timer = 0.5
	if explodes:
		poison_explodes = true

func apply_burn(dmg: int, duration: float) -> void:
	burn_damage = max(burn_damage, dmg)
	burn_timer = max(burn_timer, duration)
	if burn_tick_timer <= 0.0:
		burn_tick_timer = 0.5

func _draw() -> void:
	# Draw monster sprite from sheet
	var region: Rect2 = SPRITE_REGIONS[monster_type]
	var draw_size: float = 36.0
	var aspect: float = region.size.x / region.size.y
	var dest: Rect2
	if aspect > 1.0:
		var h: float = draw_size / aspect
		dest = Rect2(Vector2(-draw_size / 2.0, -h / 2.0), Vector2(draw_size, h))
	else:
		var w: float = draw_size * aspect
		dest = Rect2(Vector2(-w / 2.0, -draw_size / 2.0), Vector2(w, draw_size))

	# Status effect tint
	var tint: Color = Color.WHITE
	if frozen_timer > 0.0:
		tint = Color(0.6, 0.85, 1.0)
	elif poison_timer > 0.0:
		tint = Color(0.6, 1.0, 0.6)
	elif burn_timer > 0.0:
		tint = Color(1.0, 0.7, 0.5)
	elif slow_timer > 0.0:
		tint = Color(0.7, 0.7, 1.0)

	draw_texture_rect_region(ENEMY_SHEET, dest, region, tint)

	# HP bar
	var bar_w: float = 30.0
	var ratio: float = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_w / 2, -24), Vector2(bar_w, 4)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(Vector2(-bar_w / 2, -24), Vector2(bar_w * ratio, 4)), Color(0.2, 0.9, 0.3))

func _physics_process(_delta: float) -> void:
	queue_redraw()
