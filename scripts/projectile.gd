class_name Projectile
extends Node2D

# 추적형 투사체. HitPayload를 소비해 명중 시 데미지+디버프를 전달한다.
# pierce 값이 남아있으면 다음 후보를 찾아 재타겟.

var target: Enemy = null
var speed: float = 450.0
var life: float = 3.0
var payload: HitPayload = null

var _hit_enemies: Array = []

func _ready() -> void:
	z_index = 6

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if target == null or not is_instance_valid(target) or target.dead:
		target = _find_fallback_target()
		if target == null:
			queue_free()
			return

	var dir: Vector2 = target.global_position - global_position
	var dist: float = dir.length()
	var step: float = speed * delta

	if dist <= step + 8.0:
		_hit_target()
		return

	var move: Vector2 = dir / dist * step
	global_position += move
	rotation = dir.angle()

func _hit_target() -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	var hit_pos: Vector2 = target.global_position

	# 스플래시가 있으면 주변 적까지 같이 맞음
	if payload != null and payload.splash_radius > 0.0:
		_apply_splash(hit_pos)
	else:
		target.take_hit(payload)
		_hit_enemies.append(target)

	if payload != null and payload.pierce > 0:
		payload.pierce -= 1
		var nxt: Enemy = _find_next_pierce_target()
		if nxt != null:
			target = nxt
			return

	queue_free()

func _apply_splash(center: Vector2) -> void:
	if payload == null or payload.source == null or not is_instance_valid(payload.source):
		return
	var tower: Tower = payload.source as Tower
	if tower == null or tower.enemies_root == null:
		return
	var r2: float = payload.splash_radius * payload.splash_radius
	for e in tower.enemies_root.get_children():
		if not (e is Enemy):
			continue
		var enemy: Enemy = e
		if enemy.dead:
			continue
		if enemy.global_position.distance_squared_to(center) > r2:
			continue
		# 복제 페이로드: 스플래시 재적용 방지
		var p2 := HitPayload.new()
		p2.source = payload.source
		p2.base_damage = payload.base_damage
		p2.is_crit = payload.is_crit
		p2.is_ultimate = payload.is_ultimate
		p2.is_magic = payload.is_magic
		p2.is_true_damage = payload.is_true_damage
		for d in payload.debuffs:
			p2.debuffs.append((d as StatusEffect).duplicate_effect())
		enemy.take_hit(p2)
		_hit_enemies.append(enemy)

func _find_next_pierce_target() -> Enemy:
	if payload == null or payload.source == null or not is_instance_valid(payload.source):
		return null
	var tower: Tower = payload.source as Tower
	if tower == null or tower.enemies_root == null:
		return null
	var best: Enemy = null
	var best_dist: float = 200.0
	for e in tower.enemies_root.get_children():
		if not (e is Enemy):
			continue
		var enemy: Enemy = e
		if enemy.dead or enemy in _hit_enemies:
			continue
		var d: float = enemy.global_position.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func _find_fallback_target() -> Enemy:
	# 원래 target이 죽으면 가장 가까운 적 하나 재선정
	if payload == null or payload.source == null or not is_instance_valid(payload.source):
		return null
	var tower: Tower = payload.source as Tower
	if tower == null or tower.enemies_root == null:
		return null
	var best: Enemy = null
	var best_dist: float = 240.0
	for e in tower.enemies_root.get_children():
		if not (e is Enemy):
			continue
		var enemy: Enemy = e
		if enemy.dead or enemy in _hit_enemies:
			continue
		var d: float = enemy.global_position.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func _draw() -> void:
	var col: Color = Color(1.0, 0.94, 0.42)
	if payload != null and payload.source is Tower:
		var td: Dictionary = (payload.source as Tower).tower_data
		if td.has("color"):
			col = td["color"] as Color
	# 단순한 화살/탄환 모양
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), col.lightened(0.2), 2.5)
	draw_line(Vector2(3.0, -3.0), Vector2(6.0, 0.0), col.lightened(0.3), 1.5)
	draw_line(Vector2(3.0, 3.0),  Vector2(6.0, 0.0), col.lightened(0.3), 1.5)
