class_name RelayBehavior
extends TowerBehavior

# 릴레이 지원 포탑: 버프 지원
# 기본 효과: 주변 포탑 공격속도 +12% (릴레이 존재만으로 적용 — Tower._compute_aura_bonus에서 계산)
# Lv2: 공속 버프 강화 (자동: Tower 계산식에서 level 반영)
# Lv3: 사거리 버프 추가 (간이 — 주변 적 추가 슬로우로 근사)
# Lv4: EMP 파동 (주변 적 둔화)
# Lv5: 마스터 포탑 지정 (가장 가까운 아군 강화 — 간이: 자체 둔화 파동 강화)
#
# 릴레이 자체는 약한 직격 공격도 수행한다.

var emp_cooldown: float = 0.0

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var p: HitPayload = _build_payload()

	# Lv4: EMP 둔화 부여
	if lvl >= 3:
		var emp := StatusEffect.new()
		emp.kind = StatusEffect.Kind.SLOW
		emp.magnitude = 0.20
		emp.duration = 1.5
		emp.stack_rule = &"strongest"
		p.debuffs.append(emp)

	_spawn_projectile(target, 500.0, p)

	# Lv5: 주기적 광역 EMP 펄스 — 공격마다 확률 트리거
	if lvl >= 4 and randf() < 0.25:
		_emp_pulse()

func _emp_pulse() -> void:
	if tower.enemies_root == null:
		return
	var pulse_radius: float = tower.attack_range * 1.2
	for e in tower.enemies_root.get_children():
		if not (e is Enemy):
			continue
		var enemy: Enemy = e
		if enemy.dead:
			continue
		if enemy.global_position.distance_to(tower.global_position) > pulse_radius:
			continue
		var slow := StatusEffect.new()
		slow.kind = StatusEffect.Kind.SLOW
		slow.magnitude = 0.35
		slow.duration = 2.0
		slow.stack_rule = &"strongest"
		enemy.status_holder.apply(slow)
