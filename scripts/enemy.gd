extends Node2D
class_name Enemy

signal died(enemy)
signal reached_end(enemy)

var hp: int = 10
var max_hp: int = 10
var speed: float = 60.0
var gold_reward: int = 3
var xp_reward: int = 1
var path_follow: PathFollow2D
var dead: bool = false
var monster_type: int = 0
var anim_sprite: AnimatedSprite2D = null

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
	# AnimatedSprite2D 자동 추가
	anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = load("res://assets/monster_frames.tres")
	anim_sprite.play("walk")
	anim_sprite.scale = Vector2(0.3, 0.3)
	add_child(anim_sprite)

func _process(delta: float) -> void:
	if dead or path_follow == null:
		return

	if frozen_timer > 0.0:
		frozen_timer -= delta
		if anim_sprite:
			anim_sprite.modulate = Color(0.6, 0.85, 1.0)
			anim_sprite.pause()
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

	# 상태이상 색상
	if anim_sprite:
		if not anim_sprite.is_playing():
			anim_sprite.play("walk")
		if poison_timer > 0.0:
			anim_sprite.modulate = Color(0.6, 1.0, 0.6)
		elif burn_timer > 0.0:
			anim_sprite.modulate = Color(1.0, 0.7, 0.5)
		elif slow_timer > 0.0:
			anim_sprite.modulate = Color(0.7, 0.7, 1.0)
		else:
			anim_sprite.modulate = Color.WHITE

	path_follow.progress += speed * slow_factor * delta
	global_position = path_follow.global_position

	# 이동 방향에 따라 좌우 반전
	if anim_sprite and path_follow:
		var vel_x = speed * slow_factor
		if path_follow.progress_ratio < 1.0:
			anim_sprite.flip_h = false

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
	# HP bar만 그리기
	var bar_w: float = 30.0
	var ratio: float = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_w / 2, -24), Vector2(bar_w, 4)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(Vector2(-bar_w / 2, -24), Vector2(bar_w * ratio, 4)), Color(0.2, 0.9, 0.3))

func _physics_process(_delta: float) -> void:
	queue_redraw()
