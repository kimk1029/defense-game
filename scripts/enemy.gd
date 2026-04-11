class_name Enemy
extends Node2D

# 경로 이동 + 피격 + 상태이상.
# 실제 이동은 PathFollow2D를 따라가며 global_position을 동기화.

signal died(gold: int)
signal reached_base(damage: int)

var max_hp: float = 50.0
var current_hp: float = 50.0
var base_speed: float = 60.0
var armor: float = 0.0
var gold_reward: int = 3
var damage_to_base: int = 1

var path_follow: PathFollow2D = null
var status_holder: StatusHolder = null
var dead: bool = false

func _ready() -> void:
	z_index = 5
	add_to_group(&"enemies")
	status_holder = StatusHolder.new()
	status_holder.name = "StatusHolder"
	add_child(status_holder)

func setup(hp: float, spd: float, arm: float, gold: int, dmg: int) -> void:
	max_hp = hp
	current_hp = hp
	base_speed = spd
	armor = arm
	gold_reward = gold
	damage_to_base = dmg

func _process(delta: float) -> void:
	if dead or path_follow == null:
		return

	# DoT/둔화 틱
	status_holder.tick(delta)
	if current_hp <= 0.0:
		_die()
		return

	var mult: float = status_holder.speed_multiplier()
	path_follow.progress += base_speed * mult * delta
	global_position = path_follow.global_position

	if path_follow.progress_ratio >= 1.0:
		_reach_base()
		return

	queue_redraw()

func take_hit(payload: HitPayload) -> void:
	if dead:
		return
	var dmg: float = payload.compute_damage_against(self)
	current_hp -= dmg
	for eff in payload.debuffs:
		status_holder.apply((eff as StatusEffect).duplicate_effect())
	if current_hp <= 0.0:
		_die()

func apply_damage(dmg: float) -> void:
	if dead:
		return
	current_hp -= dmg

func current_armor() -> float:
	return maxf(0.0, armor + status_holder.armor_delta())

func _die() -> void:
	if dead:
		return
	dead = true
	died.emit(gold_reward)
	if path_follow != null and is_instance_valid(path_follow):
		path_follow.queue_free()
	queue_free()

func _reach_base() -> void:
	if dead:
		return
	dead = true
	reached_base.emit(damage_to_base)
	if path_follow != null and is_instance_valid(path_follow):
		path_follow.queue_free()
	queue_free()

# ── 시각화 ────────────────────────────────────────────────────────────
func _draw() -> void:
	if dead:
		return

	# 상태이상별 색상 변조
	var body_col: Color = Color(0.82, 0.20, 0.18)
	if status_holder.has_status(StatusEffect.Kind.FREEZE):
		body_col = Color(0.55, 0.85, 1.0)
	elif status_holder.has_status(StatusEffect.Kind.SLOW):
		body_col = Color(0.50, 0.65, 1.0)
	elif status_holder.has_status(StatusEffect.Kind.BURN):
		body_col = Color(1.0, 0.55, 0.20)
	elif status_holder.has_status(StatusEffect.Kind.POISON):
		body_col = Color(0.45, 0.90, 0.35)

	# 몸통
	draw_circle(Vector2.ZERO, 13.0, body_col.darkened(0.30))
	draw_circle(Vector2.ZERO, 10.0, body_col)
	draw_circle(Vector2(-3, -3), 2.2, Color.WHITE)

	# 체력바
	var bw: float = 26.0
	var ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bw * 0.5, -20.0), Vector2(bw, 3.0)),
		Color(0.08, 0.08, 0.08, 0.85))
	draw_rect(Rect2(Vector2(-bw * 0.5, -20.0), Vector2(bw * ratio, 3.0)),
		Color(0.35, 1.0, 0.42))
