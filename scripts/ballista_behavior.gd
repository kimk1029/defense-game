class_name BallistaBehavior
extends TowerBehavior

# 발리스타: 단일 화력 / 장갑 대응
# Lv1: 기본 공격
# Lv2: 공격력 +20% (tower_registry 스탯)
# Lv3: 관통 1회, 치명타 10% / 치명 피해 175%
# Lv4: 공속 +15%, 방어력 감소 10% 디버프
# Lv5: 5번째 공격마다 250% 피해 + 최대 3 관통

var shot_counter: int = 0
const CRIT_CHANCE: float = 0.10
const CRIT_MULT: float = 1.75

func fire(target: Enemy) -> void:
	shot_counter += 1
	var lvl: int = tower.level   # 0..4
	var p: HitPayload = _build_payload()

	if lvl >= 2:
		p.pierce = 1
		if randf() < CRIT_CHANCE:
			p.base_damage *= CRIT_MULT
			p.is_crit = true

	if lvl >= 3:
		var shred := StatusEffect.new()
		shred.kind = StatusEffect.Kind.ARMOR_SHRED
		shred.magnitude = maxf(1.0, tower.damage * 0.10)
		shred.duration = 3.0
		shred.stack_rule = &"refresh"
		p.debuffs.append(shred)

	if lvl >= 4 and shot_counter % 5 == 0:
		p.base_damage *= 2.5
		p.pierce = 3
		p.is_ultimate = true

	_spawn_projectile(target, 600.0, p)
