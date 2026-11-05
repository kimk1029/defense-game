extends "res://tests/test_base.gd"
## SPEC-02

func _fx(kind: int, mag: float, dur: float, rule: StringName = &"refresh", maxs: int = 1) -> StatusEffect:
	var e := StatusEffect.new()
	e.kind = kind
	e.magnitude = mag
	e.duration = dur
	e.stack_rule = rule
	e.max_stacks = maxs
	return e

func test_ac02_1_damage_types() -> void:
	var e := make_enemy(100, 5)
	var p := HitPayload.new()
	p.base_damage = 20
	near(p.compute_damage_against(e), 15.0, "physical")
	p.base_damage = 3
	near(p.compute_damage_against(e), 1.0, "min 1")
	p.is_magic = true
	near(p.compute_damage_against(e), 3.0, "magic ignores armor")
	p.is_magic = false
	p.is_true_damage = true
	p.base_damage = 0.5
	near(p.compute_damage_against(e), 0.5, "true damage raw")

func test_ac02_2_armor_shred() -> void:
	var e := make_enemy(100, 5)
	e.status_holder.apply(_fx(StatusEffect.Kind.ARMOR_SHRED, 2, 3, &"stack", 3))
	e.status_holder.apply(_fx(StatusEffect.Kind.ARMOR_SHRED, 2, 3, &"stack", 3))
	near(e.current_armor(), 1.0, "5 - 2*2")
	e.status_holder.apply(_fx(StatusEffect.Kind.ARMOR_SHRED, 2, 3, &"stack", 3))
	near(e.current_armor(), 0.0, "floored at 0")

func test_ac02_3_stack_rules() -> void:
	var e := make_enemy()
	var h := e.status_holder
	h.apply(_fx(StatusEffect.Kind.SLOW, 0.2, 1.0, &"refresh"))
	h.apply(_fx(StatusEffect.Kind.SLOW, 0.5, 3.0, &"refresh"))
	near(h._find(StatusEffect.Kind.SLOW).remaining, 3.0, "refresh extends")
	near(h._find(StatusEffect.Kind.SLOW).effect.magnitude, 0.2, "refresh keeps effect")
	h.apply(_fx(StatusEffect.Kind.POISON, 4, 2, &"stack", 3))
	for i in 5:
		h.apply(_fx(StatusEffect.Kind.POISON, 4, 2, &"stack", 3))
	eq(h._find(StatusEffect.Kind.POISON).stacks, 3, "stack capped")
	var e2 := make_enemy()
	e2.status_holder.apply(_fx(StatusEffect.Kind.SLOW, 0.3, 2, &"strongest"))
	e2.status_holder.apply(_fx(StatusEffect.Kind.SLOW, 0.1, 9, &"strongest"))
	near(e2.status_holder._find(StatusEffect.Kind.SLOW).effect.magnitude, 0.3, "weaker ignored")
	e2.status_holder.apply(_fx(StatusEffect.Kind.SLOW, 0.5, 1, &"strongest"))
	near(e2.status_holder._find(StatusEffect.Kind.SLOW).effect.magnitude, 0.5, "stronger replaces")

func test_ac02_4_speed() -> void:
	var e := make_enemy()
	e.status_holder.apply(_fx(StatusEffect.Kind.SLOW, 0.25, 2))
	near(e.status_holder.speed_multiplier(), 0.75, "slow")
	e.status_holder.apply(_fx(StatusEffect.Kind.STUN, 1, 0.5))
	near(e.status_holder.speed_multiplier(), 0.0, "stun -> 0")

func test_ac02_5_dot_and_expiry() -> void:
	var e := make_enemy(100)
	e.status_holder.apply(_fx(StatusEffect.Kind.POISON, 4, 1.0, &"stack", 5))
	e.status_holder.apply(_fx(StatusEffect.Kind.POISON, 4, 1.0, &"stack", 5))
	e.status_holder.tick(0.5)
	near(e.current_hp, 96.0, "4 * 2 stacks * 0.5s")
	e.status_holder.tick(0.6)
	check(not e.status_holder.has_status(StatusEffect.Kind.POISON), "expired")

func test_ac02_6_take_hit_and_death() -> void:
	var e := make_enemy(30)
	var deaths := [0]
	e.died.connect(func(_g): deaths[0] += 1)
	var p := HitPayload.new()
	p.base_damage = 10
	p.debuffs.append(_fx(StatusEffect.Kind.SLOW, 0.2, 1))
	e.take_hit(p)
	near(e.current_hp, 20.0, "damage applied")
	check(e.status_holder.has_status(StatusEffect.Kind.SLOW), "debuff attached")
	check(e.status_holder._find(StatusEffect.Kind.SLOW).effect != p.debuffs[0], "debuff is a copy")
	p.base_damage = 100
	e.take_hit(p)
	e.take_hit(p)
	eq(deaths[0], 1, "died once")
	check(e.dead, "dead flag")
