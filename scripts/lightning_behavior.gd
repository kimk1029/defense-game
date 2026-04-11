class_name LightningBehavior
extends TowerBehavior

# 번개 포탑: 연쇄 타격 (즉발)
# Lv1: 2 연쇄, 연쇄 70%
# Lv2: 연쇄 +1
# Lv3: 공속 +15% (registry)
# Lv4: 감전 디버프 (받는 피해 증가 → 간단히 방어력 감소로 대체)
# Lv5: 연쇄 폭발 (마지막 대상 주변 광역)

const CHAIN_FALLOFF: float = 0.70
const CHAIN_RANGE: float = 150.0

func fire(target: Enemy) -> void:
	var lvl: int = tower.level
	var chain_max: int = 2 + (1 if lvl >= 1 else 0) + (1 if lvl >= 4 else 0)
	var hit_list: Array = [target]

	# 첫 대상
	var p0: HitPayload = _build_payload()
	p0.is_magic = true
	_apply_lightning_debuff(p0, lvl)
	target.take_hit(p0)

	var current_pos: Vector2 = target.global_position

	# 연쇄
	for i in chain_max:
		var next: Enemy = _find_next_chain_target(current_pos, hit_list)
		if next == null:
			break
		hit_list.append(next)
		var pn: HitPayload = HitPayload.new()
		pn.source = tower
		pn.base_damage = tower.damage * pow(CHAIN_FALLOFF, float(i + 1))
		pn.is_magic = true
		_apply_lightning_debuff(pn, lvl)
		next.take_hit(pn)
		current_pos = next.global_position

func _apply_lightning_debuff(p: HitPayload, lvl: int) -> void:
	if lvl < 3:
		return
	var shock := StatusEffect.new()
	shock.kind = StatusEffect.Kind.ARMOR_SHRED
	shock.magnitude = maxf(2.0, tower.damage * 0.15)
	shock.duration = 2.5
	shock.stack_rule = &"refresh"
	p.debuffs.append(shock)

func _find_next_chain_target(from_pos: Vector2, already_hit: Array) -> Enemy:
	var best: Enemy = null
	var best_dist: float = CHAIN_RANGE
	for e in tower.enemies_root.get_children():
		if not (e is Enemy):
			continue
		if e in already_hit:
			continue
		var d: float = e.global_position.distance_to(from_pos)
		if d < best_dist:
			best_dist = d
			best = e
	return best
