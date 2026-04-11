class_name SniperBehavior
extends TowerBehavior

# 저격 포탑: 초장거리 고단일 / 보스 대응
# Lv1: 기본
# Lv2: +25% ATK (registry)
# Lv3: 치명타 15%, 치명 피해 200%
# Lv4: +10% 공속, +0.8 사거리 (registry)
# Lv5: 20% HP 이하 일반 적 처형, 보스 대응 대폭 보너스

const CRIT_CHANCE: float = 0.15
const CRIT_MULT: float = 2.0
const EXECUTE_THRESHOLD: float = 0.20

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	# Lv3: 치명타
	if lvl >= 2 and randf() < CRIT_CHANCE:
		p.base_damage *= CRIT_MULT
		p.is_crit = true

	# Lv5: 처형 — HP 비율이 낮으면 즉사 수준의 데미지
	if lvl >= 4:
		var ratio: float = target.current_hp / maxf(1.0, target.max_hp)
		if ratio < EXECUTE_THRESHOLD:
			p.base_damage = target.current_hp + 9999.0
			p.is_true_damage = true
			p.is_ultimate = true

	_spawn_projectile(target, 1400.0, p)
