class_name DroneBehavior
extends TowerBehavior

# 드론 허브 포탑: 유동 타격 / 소환형
# 실제 드론 엔티티 대신 "한 번의 발사에서 여러 발의 유도 투사체"로 근사.
# Lv1: 2발 드론
# Lv2: 드론 성능 강화 (registry의 damage/attack_speed로 반영)
# Lv3: +1 드론
# Lv4: 드론 미사일 — 각 투사체 데미지 +20%
# Lv5: 엘리트 드론 추가 — +1 드론 + 집중 사격(같은 대상에 보너스)

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var drone_count: int = 2
	if lvl >= 2:
		drone_count += 1
	if lvl >= 4:
		drone_count += 1

	var targets: Array = _pick_targets(drone_count)
	if targets.is_empty():
		return

	# 대상이 1명뿐이면 모든 드론이 집중 사격
	for i in drone_count:
		var t: Enemy = targets[i % targets.size()]
		if t == null or not is_instance_valid(t) or t.dead:
			continue
		var p: HitPayload = HitPayload.new()
		p.source = tower
		p.base_damage = tower.damage * 0.5
		if lvl >= 3:
			p.base_damage *= 1.2
		# Lv5: 집중 사격 — 타깃이 1명으로 귀결될 때 드론 수만큼 누적 보너스
		if lvl >= 4 and targets.size() == 1:
			p.base_damage *= 1.15
		_spawn_projectile(t, 520.0, p)

func _pick_targets(count: int) -> Array:
	var result: Array = []
	if tower.enemies_root == null:
		return result
	var candidates: Array = []
	for e in tower.enemies_root.get_children():
		if not (e is Enemy):
			continue
		var enemy: Enemy = e
		if enemy.dead:
			continue
		if tower.global_position.distance_to(enemy.global_position) > tower.attack_range:
			continue
		candidates.append(enemy)
	# 진행률이 높은 순
	candidates.sort_custom(_sort_by_progress_desc)
	var n: int = mini(count, candidates.size())
	for i in n:
		result.append(candidates[i])
	return result

func _sort_by_progress_desc(a: Enemy, b: Enemy) -> bool:
	var pa: float = 0.0
	var pb: float = 0.0
	if a.path_follow != null:
		pa = a.path_follow.progress
	if b.path_follow != null:
		pb = b.path_follow.progress
	return pa > pb
