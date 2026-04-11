class_name FrostBehavior
extends TowerBehavior

# 냉기 포탑: 둔화 / 군중제어
# Lv1: 둔화 20%
# Lv2: 공격력 +15% (registry) + 둔화 25%
# Lv3: 확률적 짧은 결빙
# Lv4: 공속/사거리 +15% (registry)
# Lv5: 더 강한 둔화 + 더 긴 결빙 확률

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	var slow_amount: float = 0.20 if lvl == 0 else 0.25
	if lvl >= 4:
		slow_amount = 0.35

	var slow := StatusEffect.new()
	slow.kind = StatusEffect.Kind.SLOW
	slow.magnitude = slow_amount
	slow.duration = 2.5
	slow.stack_rule = &"strongest"
	p.debuffs.append(slow)

	# Lv3+: 결빙 확률
	if lvl >= 2:
		var freeze_chance: float = 0.15 if lvl < 4 else 0.25
		var freeze_dur: float = 0.8 if lvl < 4 else 1.4
		if randf() < freeze_chance:
			var fz := StatusEffect.new()
			fz.kind = StatusEffect.Kind.FREEZE
			fz.magnitude = 1.0
			fz.duration = freeze_dur
			fz.stack_rule = &"refresh"
			p.debuffs.append(fz)

	_spawn_projectile(target, 380.0, p)
