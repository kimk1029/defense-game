extends Node2D
class_name Enemy

signal died(enemy)
signal reached_end(enemy)

var hp: int = 10
var max_hp: int = 10
var speed: float = 60.0
var gold_reward: int = 3
var xp_reward: int = 1
var path_follow: PathFollow2D  # parent we live under

func _ready() -> void:
	z_index = 5
	add_to_group("enemies")

func _process(delta: float) -> void:
	if path_follow == null:
		return
	path_follow.progress += speed * delta
	# Mirror our world position to the parent's so towers can target us.
	global_position = path_follow.global_position
	if path_follow.progress_ratio >= 1.0:
		emit_signal("reached_end", self)

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		emit_signal("died", self)

func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, 14, Color(0.85, 0.25, 0.25))
	# HP bar
	var w := 30.0
	var ratio := clamp(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-w / 2, -22), Vector2(w, 4)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(Vector2(-w / 2, -22), Vector2(w * ratio, 4)), Color(0.2, 0.9, 0.3))

func _physics_process(_delta: float) -> void:
	queue_redraw()
