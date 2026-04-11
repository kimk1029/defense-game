class_name StatusEffect
extends RefCounted

# 상태이상 정의. 같은 Kind여도 magnitude/duration이 다를 수 있다.
# stack_rule:
#   "refresh"   – 동일 종류가 걸려있으면 지속시간만 갱신 (예: 둔화)
#   "stack"     – max_stacks까지 중첩 (예: 독)
#   "strongest" – 세기가 더 강한 쪽이 이김 (예: 둔화율)

enum Kind { SLOW, BURN, POISON, FREEZE, ARMOR_SHRED, STUN, SHOCK }

var kind: int = Kind.SLOW
var magnitude: float = 0.0
var duration: float = 0.0
var stack_rule: StringName = &"refresh"
var max_stacks: int = 1

func duplicate_effect() -> StatusEffect:
	var e := StatusEffect.new()
	e.kind = kind
	e.magnitude = magnitude
	e.duration = duration
	e.stack_rule = stack_rule
	e.max_stacks = max_stacks
	return e
