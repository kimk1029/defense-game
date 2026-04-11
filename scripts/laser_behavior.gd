class_name LaserBehavior
extends TowerBehavior

# 프리즘 레이저 포탑: 지속 집속 / 보스 킬러
# 빠른 연사 투사체로 레이저를 근사.
# Lv1: 기본 DPS
# Lv2: +15% 레이저 DPS (registry로 처리)
# Lv3: 15% 방어 무시 (간이 구현: is_magic 플래그 사용 → 100% 방관 근사)
# Lv4: +회전속도 / 사거리 (registry로 처리)
# Lv5: 궁극 — 같은 대상 유지 시 최대 +30% 증폭 보너스 달성 속도 2배

var focus_target: Enemy = null
var focus_stacks: float = 0.0
const FOCUS_STEP: float = 0.05
const FOCUS_MAX: float = 0.30

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	# 집속 보너스
	if target == focus_target:
		var step: float = FOCUS_STEP
		if lvl >= 4:
			step *= 2.0
		focus_stacks = minf(focus_stacks + step, FOCUS_MAX)
	else:
		focus_target = target
		focus_stacks = 0.0
	p.base_damage *= (1.0 + focus_stacks)

	# Lv3: 방어 무시(간이)
	if lvl >= 2:
		p.is_magic = true

	_spawn_projectile(target, 1600.0, p)
