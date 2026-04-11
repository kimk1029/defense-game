class_name HitPayload
extends RefCounted

# 공격 한 방에 대한 모든 정보를 담는 구조체.
# 관통·치명·스플래시·디버프를 조합한 복합 공격을 한 객체로 표현한다.

var source: Node = null
var base_damage: float = 0.0
var pierce: int = 0
var splash_radius: float = 0.0
var is_crit: bool = false
var is_ultimate: bool = false
var is_magic: bool = false
var is_true_damage: bool = false
var debuffs: Array = []    # Array[StatusEffect]

func compute_damage_against(enemy: Enemy) -> float:
	if is_true_damage:
		return base_damage
	var effective_armor: float = enemy.current_armor()
	if is_magic:
		effective_armor = 0.0
	return maxf(1.0, base_damage - effective_armor)
