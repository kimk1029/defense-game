class_name MortarBehavior
extends TowerBehavior

# 박격포 포탑: 광역 폭발
# Lv1: 기본 폭발 반경 60px
# Lv2: 폭발 반경 +15, +10% ATK
# Lv3: 착탄 지점에 화염 지대 디버프(화상)
# Lv4: +15% ATK, 파편(추가 약화 디버프)
# Lv5: 강화 포탄 — 더 넓은 폭발 + 짧은 기절

const MIN_RANGE: float = 60.0   # 너무 가까우면 발사 안 함(최소 사거리)

func select_target(candidates: Array) -> Enemy:
	# 너무 가까운 적은 제외
	var filtered: Array = []
	for e in candidates:
		if e == null or not is_instance_valid(e):
			continue
		if tower.global_position.distance_to(e.global_position) >= MIN_RANGE:
			filtered.append(e)
	return super.select_target(filtered)

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	# 폭발 반경
	var radius: float = 60.0
	if lvl >= 1:
		radius += 15.0
	if lvl >= 4:
		radius += 20.0
	p.splash_radius = radius

	# Lv3: 화염 지대(화상 디버프)
	if lvl >= 2:
		var burn := StatusEffect.new()
		burn.kind = StatusEffect.Kind.BURN
		burn.magnitude = maxf(2.0, tower.damage * 0.15)
		burn.duration = 3.0
		burn.stack_rule = &"refresh"
		p.debuffs.append(burn)

	# Lv4: 파편 — 약한 방어력 감소
	if lvl >= 3:
		var shred := StatusEffect.new()
		shred.kind = StatusEffect.Kind.ARMOR_SHRED
		shred.magnitude = maxf(1.0, tower.damage * 0.08)
		shred.duration = 2.0
		shred.stack_rule = &"refresh"
		p.debuffs.append(shred)

	# Lv5: 궁극 — 짧은 기절
	if lvl >= 4:
		var stun := StatusEffect.new()
		stun.kind = StatusEffect.Kind.STUN
		stun.magnitude = 1.0
		stun.duration = 0.5
		stun.stack_rule = &"refresh"
		p.debuffs.append(stun)

	_spawn_projectile(target, 360.0, p)
