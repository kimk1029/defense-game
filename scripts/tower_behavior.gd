class_name TowerBehavior
extends Node

# 포탑 고유 행동(Strategy)의 베이스.
# 각 포탑 종류마다 이 클래스를 상속해 fire() / select_target() / on_level_up()을 오버라이드한다.

var tower: Tower = null

# 기본 타겟팅: 경로 진행률이 가장 높은 적(=가장 앞선 적)
func select_target(candidates: Array) -> Enemy:
	if candidates.is_empty():
		return null
	var best: Enemy = null
	var best_prog: float = -INF
	for e in candidates:
		if e == null or not is_instance_valid(e):
			continue
		var prog: float = 0.0
		if e.path_follow != null:
			prog = e.path_follow.progress
		if prog > best_prog:
			best_prog = prog
			best = e
	return best

# 기본 발사: 단발 투사체
func fire(target: Enemy) -> void:
	_spawn_projectile(target, 450.0, _build_payload())

func _build_payload() -> HitPayload:
	var p := HitPayload.new()
	p.source = tower
	p.base_damage = tower.damage
	return p

func _spawn_projectile(target: Enemy, speed: float, payload: HitPayload) -> Projectile:
	var proj := Projectile.new()
	proj.target = target
	proj.speed = speed
	proj.payload = payload
	tower.projectiles_root.add_child(proj)
	proj.global_position = tower.global_position
	return proj

func on_level_up(_new_level: int) -> void:
	pass
