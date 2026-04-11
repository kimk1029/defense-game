class_name StatusHolder
extends Node

# 적에 부착되는 상태이상 관리자.
# Enemy._process에서 tick(delta)를 호출해야 한다.

class ActiveEffect:
	var effect: StatusEffect
	var remaining: float = 0.0
	var stacks: int = 1

var actives: Array = []   # Array[ActiveEffect]

func apply(e: StatusEffect) -> void:
	var existing: ActiveEffect = _find(e.kind)
	if existing == null:
		var a := ActiveEffect.new()
		a.effect = e
		a.remaining = e.duration
		a.stacks = 1
		actives.append(a)
		return
	match e.stack_rule:
		&"refresh":
			existing.remaining = maxf(existing.remaining, e.duration)
		&"stack":
			existing.stacks = mini(existing.stacks + 1, e.max_stacks)
			existing.remaining = e.duration
		&"strongest":
			if e.magnitude > existing.effect.magnitude:
				existing.effect = e
				existing.remaining = e.duration

func tick(delta: float) -> void:
	var parent: Enemy = get_parent() as Enemy
	if parent == null:
		return
	var survivors: Array = []
	for a in actives:
		a.remaining -= delta
		match a.effect.kind:
			StatusEffect.Kind.BURN, StatusEffect.Kind.POISON:
				parent.apply_damage(a.effect.magnitude * float(a.stacks) * delta)
		if a.remaining > 0.0:
			survivors.append(a)
	actives = survivors

func speed_multiplier() -> float:
	var m: float = 1.0
	for a in actives:
		match a.effect.kind:
			StatusEffect.Kind.SLOW:
				m *= (1.0 - a.effect.magnitude)
			StatusEffect.Kind.FREEZE, StatusEffect.Kind.STUN:
				return 0.0
	return maxf(0.0, m)

func armor_delta() -> float:
	var d: float = 0.0
	for a in actives:
		if a.effect.kind == StatusEffect.Kind.ARMOR_SHRED:
			d -= a.effect.magnitude * float(a.stacks)
	return d

func has_status(k: int) -> bool:
	return _find(k) != null

func _find(k: int) -> ActiveEffect:
	for a in actives:
		if a.effect.kind == k:
			return a
	return null
