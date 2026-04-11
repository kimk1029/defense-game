class_name PoisonBehavior
extends TowerBehavior

# 독성 포탑: 지속 피해 / 고체력 적 대응
# Lv1: 독 4/초, 2초 지속, 스택 5
# Lv2: 독 지속시간 +1초
# Lv3: 최대 중첩 시 주변 전이(확률)
# Lv4: +15% ATK, 독 틱 강화
# Lv5: 최대 중첩 시 독성 폭발(스플래시)

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	# 독 스택
	var poison := StatusEffect.new()
	poison.kind = StatusEffect.Kind.POISON
	poison.magnitude = 4.0 + float(lvl) * 0.6
	poison.duration = 2.0 + (1.0 if lvl >= 1 else 0.0)
	if lvl >= 3:
		poison.magnitude *= 1.3
	poison.stack_rule = &"stack"
	poison.max_stacks = 5
	p.debuffs.append(poison)

	# Lv5: 최대 중첩된 타겟에 맞추면 폭발(주변 전이)
	if lvl >= 4 and _is_max_stacked(target):
		p.splash_radius = 55.0
		p.is_ultimate = true

	# Lv3: 최대 중첩 시 약한 전이(스플래시)
	elif lvl >= 2 and _is_max_stacked(target):
		p.splash_radius = 40.0

	_spawn_projectile(target, 400.0, p)

func _is_max_stacked(enemy: Enemy) -> bool:
	if enemy == null or enemy.status_holder == null:
		return false
	for a in enemy.status_holder.actives:
		if a.effect.kind == StatusEffect.Kind.POISON and a.stacks >= 5:
			return true
	return false
