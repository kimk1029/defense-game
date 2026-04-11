class_name GatlingBehavior
extends TowerBehavior

# 개틀링: 지속 화력
# Lv1: 기본
# Lv2: 공격력 +15% (registry)
# Lv3: 동일 대상 지속 사격 시 ramp 누적(최대 1.5배 데미지)
# Lv4: 공속 +15%, 사거리 +0.4 (registry)
# Lv5: 연속 사격(ramp >= 1.2) 시 화상 부여

var last_target: Enemy = null
var ramp: float = 1.0

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	# Lv3: ramp 시스템
	if lvl >= 2:
		if target == last_target:
			ramp = minf(ramp + 0.04, 1.5)
		else:
			ramp = 1.0
		last_target = target
		p.base_damage *= ramp

	# Lv5: ramp가 충분히 쌓이면 화상
	if lvl >= 4 and ramp >= 1.2:
		var burn := StatusEffect.new()
		burn.kind = StatusEffect.Kind.BURN
		burn.magnitude = maxf(1.0, tower.damage * 0.5)
		burn.duration = 2.0
		burn.stack_rule = &"refresh"
		p.debuffs.append(burn)

	_spawn_projectile(target, 680.0, p)
