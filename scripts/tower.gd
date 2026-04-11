extends Node2D
class_name Tower

@export var base_damage: int = 5
@export var base_fire_rate: float = 1.2
@export var base_range: float = 140.0
@export var base_projectile_speed: float = 380.0

var damage: int
var fire_rate: float
var range_px: float
var projectile_speed: float

var cooldown: float = 0.0
var enemies_root_path: NodePath
var projectiles_root_path: NodePath
var projectile_scene_script: Script

# Tower type system
var tower_type: String = "basic"
var tower_color: Color = Color(0.58, 0.58, 0.68)
var builtin_weapon: String = ""
var builtin_cd: float = 0.0
const BUILTIN_LEVEL: int = 3

# 개별 포탑 레벨 (1~5)
var tower_level: int = 1
const MAX_TOWER_LEVEL: int = 5
# 설치 비용 추적 (판매 환급 계산용)
var tower_idx: int = -1
var total_invested: int = 0
# 전역 모드 캐시 (개별 레벨업 시 재적용용)
var _cached_d_mult:   float = 1.0
var _cached_r_mult:   float = 1.0
var _cached_rng_mult: float = 1.0
var _cached_p_mult:   float = 1.0

func _ready() -> void:
	z_index = 4
	apply_global_mods(1.0, 1.0, 1.0, 1.0)

func setup_type(td: Dictionary) -> void:
	tower_type   = str(td["key"])
	tower_color  = td["color"] as Color
	builtin_weapon = str(td.get("weapon", ""))
	base_damage          = int(td["b_dmg"])
	base_fire_rate       = float(td["b_rate"])
	base_range           = float(td["b_range"])
	base_projectile_speed = float(td["b_speed"])
	if builtin_weapon != "":
		builtin_cd = randf_range(0.3, _get_sp_cooldown(builtin_weapon))

func apply_global_mods(d_mult: float, r_mult: float, rng_mult: float, p_mult: float) -> void:
	_cached_d_mult   = d_mult
	_cached_r_mult   = r_mult
	_cached_rng_mult = rng_mult
	_cached_p_mult   = p_mult
	# 개별 레벨 보너스: 레벨당 공격력+25%, 공속+15%, 사거리+10%
	var lv: float    = float(tower_level - 1)
	var lv_dmg:  float = 1.0 + 0.25 * lv
	var lv_rate: float = 1.0 + 0.15 * lv
	var lv_rng:  float = 1.0 + 0.10 * lv
	damage           = int(round(base_damage * d_mult * lv_dmg))
	fire_rate        = base_fire_rate * r_mult * lv_rate
	range_px         = base_range * rng_mult * lv_rng
	projectile_speed = base_projectile_speed * p_mult
	queue_redraw()

# 개별 포탑 레벨업
func do_tower_upgrade() -> void:
	if tower_level >= MAX_TOWER_LEVEL:
		return
	tower_level += 1
	apply_global_mods(_cached_d_mult, _cached_r_mult, _cached_rng_mult, _cached_p_mult)

# 다음 레벨 스탯 미리보기
func get_next_level_stats() -> Dictionary:
	var lv: float = float(tower_level)   # 다음 레벨 = tower_level + 1 → lv 증가분 = tower_level
	var lv_dmg:  float = 1.0 + 0.25 * lv
	var lv_rate: float = 1.0 + 0.15 * lv
	var lv_rng:  float = 1.0 + 0.10 * lv
	return {
		"damage":    int(round(base_damage * _cached_d_mult * lv_dmg)),
		"fire_rate": base_fire_rate * _cached_r_mult * lv_rate,
		"range":     int(base_range * _cached_rng_mult * lv_rng),
	}

func _get_sp_cooldown(key: String) -> float:
	match key:
		"chain":      return 3.0
		"freeze":     return 4.5
		"poison":     return 2.8
		"meteor":     return 6.0
		"arrow_rain": return 3.2
		"quake":      return 5.5
		"laser":      return 2.0
	return 3.0

func _process(delta: float) -> void:
	queue_redraw()

	if builtin_weapon == "":
		# 기본 포탑: 일반 투사체 공격
		cooldown -= delta
		if cooldown <= 0.0:
			var target: Node2D = _find_target()
			if target != null:
				_shoot(target)
				cooldown = 1.0 / fire_rate
	else:
		# 특수 포탑: 특수 기술만 사용
		builtin_cd -= delta
		if builtin_cd <= 0.0:
			var sp_target: Node2D = _find_target()
			if sp_target != null:
				_fire_special(builtin_weapon, sp_target)
				builtin_cd = _get_sp_cooldown(builtin_weapon)
			else:
				builtin_cd = 0.5

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist: float = range_px
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

func _shoot(target: Node2D) -> void:
	var proj: Projectile = projectile_scene_script.new()
	proj.position = global_position
	proj.target   = target
	proj.damage   = damage
	proj.speed    = projectile_speed
	get_node(projectiles_root_path).add_child(proj)

func _fire_special(key: String, target: Node2D) -> void:
	var level: int   = BUILTIN_LEVEL
	var proj_root: Node = get_node(projectiles_root_path)

	match key:
		"chain":
			var lightning := ChainLightning.new()
			lightning.global_position = global_position
			lightning.damage      = 3 + level * 3
			lightning.chain_count = 1 + level
			lightning.chain_range = range_px * 0.9
			lightning.is_max_level = false
			proj_root.add_child(lightning)
			lightning.start(target)

		"freeze":
			var bomb := FreezeBomb.new()
			bomb.global_position = global_position
			bomb.target          = target
			bomb.damage          = 2 + level * 2
			bomb.radius          = 55.0 + float(level) * 15.0
			bomb.slow_factor     = maxf(0.2, 0.7 - float(level) * 0.1)
			bomb.slow_duration   = 1.5 + float(level) * 0.3
			bomb.is_max_level    = false
			proj_root.add_child(bomb)

		"poison":
			var arrow := PoisonArrow.new()
			arrow.global_position  = global_position
			arrow.target           = target
			arrow.damage           = 1 + level
			arrow.poison_damage    = 1 + level
			arrow.poison_duration  = 2.0 + float(level) * 0.5
			arrow.poison_explodes  = false
			proj_root.add_child(arrow)

		"meteor":
			var met := Meteor.new()
			var splash_dmg: int  = 6 + level * 5
			var splash_rad: float = 55.0 + float(level) * 12.0
			met.damage       = splash_dmg
			met.radius       = splash_rad
			proj_root.add_child(met)
			var impact_pos: Vector2  = target.global_position
			var is_max: bool         = tower_level >= MAX_TOWER_LEVEL
			var travel_t: float      = maxf(0.3, global_position.distance_to(impact_pos) / 210.0)
			met.start(impact_pos)
			# 착탄 타이밍에 맥스레벨이면 지면 화염 생성
			if is_max:
				var fire_rad: float = splash_rad * 1.1
				var fire_dmg: int   = 3 + level * 2
				get_tree().create_timer(travel_t).timeout.connect(func():
					var gf := GroundFire.new()
					gf.position     = impact_pos
					gf.radius       = fire_rad
					gf.max_duration = 5.0
					gf.duration     = 5.0
					gf.burn_dmg     = fire_dmg
					proj_root.add_child(gf)
				)

		"arrow_rain":
			var arrow_count := 2 + level
			var arrow_dmg   := 3 + level * 3
			var all_e := get_tree().get_nodes_in_group("enemies").duplicate()
			all_e.shuffle()
			var hits := 0
			for e in all_e:
				if not is_instance_valid(e) or not (e is Node2D):
					continue
				if global_position.distance_to(e.global_position) > range_px:
					continue
				# Visual arrow effect falling from sky
				var ae := ArrowEffect.new()
				ae.target_pos = e.global_position
				ae.life = 0.70
				ae.max_life = 0.70
				proj_root.add_child(ae)
				# Damage after a short delay (arrow reaches ground)
				var dmg_target: Node2D = e
				var dmg_amt: int = arrow_dmg
				get_tree().create_timer(0.50).timeout.connect(func():
					if is_instance_valid(dmg_target) and dmg_target.has_method("take_damage"):
						dmg_target.take_damage(dmg_amt)
				)
				hits += 1
				if hits >= arrow_count:
					break

		"quake":
			var q_range := range_px * (1.0 + level * 0.18)
			var q_slow  := maxf(0.25, 0.75 - float(level) * 0.10)
			var q_dur   := 1.2 + float(level) * 0.5
			# Visual quake effect at tower position
			var qe := QuakeEffect.new()
			qe.global_position = global_position
			qe.radius = q_range * 0.75
			proj_root.add_child(qe)
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or not (e is Node2D):
					continue
				if global_position.distance_to(e.global_position) <= q_range:
					if e.has_method("apply_slow"):
						e.apply_slow(q_slow, q_dur)

		"laser":
			var laser_dmg := 8 + level * 8
			if target != null and target.has_method("take_damage"):
				var le := LaserEffect.new()
				le.start_pos  = global_position
				le.end_pos    = target.global_position
				proj_root.add_child(le)
				target.take_damage(laser_dmg)

func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	draw_circle(Vector2(2, 4), 22.0, Color(0.0, 0.0, 0.0, 0.16))
	match tower_type:
		"basic":     _draw_basic(t)
		"sniper":    _draw_sniper(t)
		"lightning": _draw_lightning(t)
		"freeze":    _draw_freeze(t)
		"poison":    _draw_poison(t)
		"meteor":    _draw_meteor(t)
		"arrow":     _draw_arrow(t)
		"quake":     _draw_quake(t)
	draw_arc(Vector2.ZERO, range_px, 0, TAU, 64,
		Color(tower_color.r, tower_color.g, tower_color.b, 0.10), 1.0)
	# ── 레벨 배지 (Lv2 이상 표시) ──────────────────────────────────────
	if tower_level >= 2:
		var is_max: bool = tower_level >= MAX_TOWER_LEVEL
		var badge_col: Color = Color(1.0, 0.85, 0.10) if is_max else Color(0.72, 0.92, 0.38)
		var glow_col: Color  = Color(1.0, 0.70, 0.0, 0.35) if is_max else Color(0.50, 0.85, 0.20, 0.28)
		# 배지 배경
		draw_circle(Vector2(16, -16), 10.0, Color(0.06, 0.04, 0.02, 0.88))
		draw_circle(Vector2(16, -16), 10.0, glow_col)
		draw_arc(Vector2(16, -16), 10.0, 0, TAU, 24, badge_col, 1.5)
		# 레벨 숫자 대신 점으로 표시 (최대 4점 = Lv2~5)
		var dots: int = tower_level - 1   # 1~4개
		for d in dots:
			var angle: float = TAU * float(d) / float(maxi(dots, 1)) - PI * 0.5
			var dp := Vector2(16.0, -16.0) + Vector2(cos(angle), sin(angle)) * 5.5
			draw_circle(dp, 2.2, badge_col)
		# 맥스레벨(Lv5) 펄스 링 + 별
		if is_max:
			var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
			draw_arc(Vector2(16, -16), 13.0 + pulse * 2.0, 0, TAU, 20,
				Color(1.0, 0.80, 0.10, 0.55 * pulse), 1.8)
			_draw_star(Vector2(16, -16), 5.5, Color(1.0, 0.92, 0.20))


func _draw_star(center: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a: float = TAU * float(i) / 10.0 - PI / 2.0
		var rv: float = r if i % 2 == 0 else r * 0.42
		pts.append(center + Vector2(cos(a), sin(a)) * rv)
	draw_colored_polygon(pts, color)

# ── Basic: 둥근 석조 포탑 + 회전포신 ─────────────────────────────────────
func _draw_basic(t: float) -> void:
	var tc := tower_color
	var base := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI / 8.0
		base.append(Vector2(cos(a), sin(a)) * 18.0)
	draw_colored_polygon(base, Color(0.44, 0.40, 0.34))
	var be := base.duplicate(); be.append(base[0])
	draw_polyline(be, Color(0.60, 0.55, 0.46), 1.5)
	var body := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		body.append(Vector2(cos(a), sin(a)) * 12.0)
	draw_colored_polygon(body, tc.darkened(0.32))
	var cap := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		cap.append(Vector2(cos(a), sin(a)) * 8.5)
	draw_colored_polygon(cap, tc.lightened(0.12))
	draw_circle(Vector2.ZERO, 5.0, tc)
	draw_circle(Vector2.ZERO, 2.8, tc.lightened(0.42))
	draw_circle(Vector2.ZERO, 1.2, Color.WHITE)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var bp := Vector2(cos(a), sin(a)) * 16.0
		draw_rect(Rect2(bp - Vector2(3, 3), Vector2(6, 6)), Color(0.46, 0.42, 0.36))
	var tgt := _find_target()
	var dir := Vector2.UP
	if tgt != null:
		dir = (tgt.global_position - global_position).normalized()
	var bend := dir * 20.0
	var perp := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([
		perp * 3.5, perp * 3.5 + bend, -perp * 3.5 + bend, -perp * 3.5
	]), tc.darkened(0.44))
	draw_circle(bend, 4.0, Color(tc.r, tc.g, tc.b, 0.38))
	draw_circle(bend, 2.2, tc.lightened(0.28))


# ── Sniper: 가늘고 긴 석조 탑 + 초장거리 포신 ───────────────────────────
func _draw_sniper(t: float) -> void:
	var tc := tower_color
	# 탑 몸체
	draw_rect(Rect2(Vector2(-6, -26), Vector2(12, 48)), Color(0.35, 0.32, 0.27))
	for yi in [-20, -12, -4, 4, 12, 20]:
		draw_line(Vector2(-6, float(yi)), Vector2(6, float(yi)),
			Color(0.25, 0.23, 0.19, 0.40), 0.7)
	draw_line(Vector2(-2, -26), Vector2(-2, 22), Color(0.25, 0.23, 0.19, 0.25), 0.5)
	draw_line(Vector2(2, -26),  Vector2(2, 22),  Color(0.25, 0.23, 0.19, 0.25), 0.5)
	# 총안(총구 창)
	draw_rect(Rect2(Vector2(-7, -31), Vector2(6, 7)), Color(0.40, 0.37, 0.30))
	draw_rect(Rect2(Vector2(1, -31),  Vector2(6, 7)), Color(0.40, 0.37, 0.30))
	# 조준경 창
	draw_circle(Vector2(0, -10), 4.2, Color(0.10, 0.16, 0.30))
	draw_arc(Vector2(0, -10), 4.2, 0, TAU, 12, Color(0.55, 0.52, 0.40), 1.2)
	draw_line(Vector2(-3.8, -10), Vector2(3.8, -10), Color(0.80, 0.78, 0.42, 0.75), 0.8)
	draw_line(Vector2(0, -14.2), Vector2(0, -5.8), Color(0.80, 0.78, 0.42, 0.75), 0.8)
	# 포신 (조준 방향)
	var tgt := _find_target()
	var dir := Vector2.UP
	if tgt != null:
		dir = (tgt.global_position - global_position).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var blen := 36.0
	var bend := dir * blen
	draw_colored_polygon(PackedVector2Array([
		perp*2.2, perp*2.2+bend, -perp*2.2+bend, -perp*2.2
	]), Color(0.28, 0.26, 0.22))
	draw_colored_polygon(PackedVector2Array([
		perp*1.0, perp*1.0+bend, -perp*1.0+bend, -perp*1.0
	]), Color(0.40, 0.38, 0.32))
	# 스코프 링
	for st in [0.32, 0.52]:
		var sp: Vector2 = dir * (blen * float(st))
		draw_circle(sp, 3.8, Color(0.20, 0.18, 0.16))
		draw_arc(sp, 3.8, 0, TAU, 8, Color(0.50, 0.47, 0.36), 1.6)
	draw_circle(bend, 3.5, Color(tc.r, tc.g, tc.b, 0.32))
	draw_circle(bend, 1.6, Color(1.0, 0.95, 0.55, 0.55))


# ── Lightning: 뾰족한 별 모양 전기 포탑 ─────────────────────────────────
func _draw_lightning(t: float) -> void:
	var tc := tower_color
	# 12각 별 베이스 (짝수=외곽, 홀수=내부)
	var star := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		var r := 20.0 if i % 2 == 0 else 9.0
		star.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(star, Color(0.22, 0.20, 0.08))
	var se := star.duplicate(); se.append(star[0])
	draw_polyline(se, Color(tc.r, tc.g * 0.85, 0.10, 0.65), 1.5)
	# 내부 육각 코어
	var hex := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0
		hex.append(Vector2(cos(a), sin(a)) * 11.0)
	draw_colored_polygon(hex, Color(0.16, 0.14, 0.05))
	# 애니메이션 아크 방전
	for i in 6:
		if i % 2 == 0:
			var a1 := TAU * float(i) / 12.0
			var a2 := TAU * float(i + 2) / 12.0
			var p1 := Vector2(cos(a1), sin(a1)) * 20.0
			var p2 := Vector2(cos(a2), sin(a2)) * 20.0
			var mid := (p1 + p2) * 0.5 + Vector2(
				sin(t * 7.2 + float(i)) * 3.5,
				cos(t * 5.5 + float(i)) * 3.5)
			var alpha := 0.45 + 0.55 * sin(t * 9.0 + float(i) * 1.3)
			draw_line(p1, mid, Color(tc.r, tc.g, 0.25, alpha * 0.75), 1.3)
			draw_line(mid, p2, Color(tc.r, tc.g, 0.25, alpha * 0.75), 1.3)
	# 전기 오브 (맥동)
	var pulse := 0.72 + 0.28 * sin(t * 6.5)
	draw_circle(Vector2.ZERO, 7.0 * pulse, Color(tc.r, tc.g, 0.20, 0.28))
	draw_circle(Vector2.ZERO, 4.8, tc.lightened(0.08))
	draw_circle(Vector2.ZERO, 2.6, Color(1.0, 0.97, 0.45))
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
	# 스파이크 끝 섬광
	for i in range(0, 12, 2):
		var a := TAU * float(i) / 12.0
		var tip := Vector2(cos(a), sin(a)) * 20.0
		var sa := 0.35 + 0.65 * sin(t * 10.0 + float(i) * 0.9)
		draw_circle(tip, 2.8, Color(1.0, 0.94, 0.25, sa))


# ── Freeze: 육각형 얼음 수정 포탑 ───────────────────────────────────────
func _draw_freeze(t: float) -> void:
	var tc := tower_color
	# 육각형 베이스
	var base := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 + PI / 6.0
		base.append(Vector2(cos(a), sin(a)) * 18.0)
	draw_colored_polygon(base, Color(0.18, 0.24, 0.32))
	var be := base.duplicate(); be.append(base[0])
	draw_polyline(be, Color(0.48, 0.70, 0.90, 0.60), 1.5)
	# 베이스 주변 작은 수정 가시
	for i in 6:
		var a := TAU * float(i) / 6.0 + PI / 6.0
		var tip := Vector2(cos(a), sin(a)) * 22.0
		var lft := Vector2(cos(a + 0.3), sin(a + 0.3)) * 14.0
		var rgt := Vector2(cos(a - 0.3), sin(a - 0.3)) * 14.0
		draw_colored_polygon(PackedVector2Array([lft, tip, rgt]),
			Color(0.52, 0.76, 0.95, 0.68))
	# 중앙 수정 첨탑
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -24), Vector2(6.5, -7), Vector2(4.5, 9),
		Vector2(0, 13), Vector2(-4.5, 9), Vector2(-6.5, -7),
	]), Color(0.58, 0.82, 0.97, 0.90))
	# 패싯 하이라이트
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -24), Vector2(4.5, -9), Vector2(2.5, 7), Vector2(0, 11),
	]), Color(0.88, 0.96, 1.0, 0.48))
	draw_polyline(PackedVector2Array([
		Vector2(0,-24), Vector2(6.5,-7), Vector2(4.5,9),
		Vector2(0,13), Vector2(-4.5,9), Vector2(-6.5,-7), Vector2(0,-24),
	]), Color(0.72, 0.90, 1.0, 0.60), 1.0)
	# 눈꽃 패턴
	for i in 6:
		var a := TAU * float(i) / 6.0
		draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 9.5,
			Color(0.68, 0.88, 1.0, 0.40), 0.9)
	# 맥동 얼음 오라
	var pulse := 0.58 + 0.42 * sin(t * 1.9)
	draw_arc(Vector2.ZERO, 8.5 * pulse, 0, TAU, 16, Color(0.55, 0.85, 1.0, 0.22), 2.2)
	draw_circle(Vector2.ZERO, 3.8, Color(0.68, 0.90, 1.0, 0.82))
	draw_circle(Vector2.ZERO, 1.6, Color.WHITE)


# ── Poison: 넓은 가마솥 포탑 ────────────────────────────────────────────
func _draw_poison(t: float) -> void:
	var tc := tower_color
	# 넓은 타원형 가마솥 베이스
	var base := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI / 8.0
		base.append(Vector2(cos(a) * 23.0, sin(a) * 16.0))
	draw_colored_polygon(base, Color(0.16, 0.17, 0.12))
	# 가마솥 림
	draw_arc(Vector2(0, -1), 16.0, PI, TAU + 0.2, 16, Color(0.26, 0.26, 0.20), 7.0)
	draw_arc(Vector2(0, -1), 16.0, PI, TAU + 0.2, 16, Color(0.38, 0.36, 0.27), 3.0)
	# 내용물 (보글보글)
	draw_circle(Vector2(0, 5), 12.5, Color(0.05, 0.35, 0.07))
	# 거품
	for i in 4:
		var bx := sin(t * 2.2 + float(i) * 1.9) * 7.0
		var by := 5.0 + cos(t * 1.6 + float(i) * 1.4) * 3.5
		draw_circle(Vector2(bx, by), 2.8, Color(0.10, 0.62, 0.13, 0.90))
	# 상승 거품 파티클
	for i in 6:
		var phase := fmod(t * 0.75 + float(i) * 0.167, 1.0)
		var bx := sin(float(i) * 1.1) * 9.0
		var by := 0.0 - phase * 20.0
		var ba := (1.0 - phase) * 0.62
		if ba > 0.04:
			draw_circle(Vector2(bx, by), 1.9 * (1.0 - phase * 0.4),
				Color(0.22, 0.92, 0.26, ba))
	# 해골 마크
	draw_circle(Vector2(0, -9), 4.8, Color(0.22, 0.22, 0.18, 0.85))
	draw_circle(Vector2(-1.8, -10), 1.1, Color(0.06, 0.06, 0.04))
	draw_circle(Vector2(1.8,  -10), 1.1, Color(0.06, 0.06, 0.04))
	draw_line(Vector2(-2, -7), Vector2(2, -7), Color(0.08, 0.08, 0.05, 0.75), 1.0)
	# 방울 드립
	for i in 3:
		var dx := float(i - 1) * 9.0
		var dy := 19.0 + sin(t * 1.4 + float(i)) * 2.5
		draw_circle(Vector2(dx, dy), 2.2, Color(0.16, 0.78, 0.20, 0.70))


# ── Meteor: 낮고 넓은 화산 포탑 ─────────────────────────────────────────
func _draw_meteor(t: float) -> void:
	var tc := tower_color
	# 넓은 팔각형 베이스
	var base := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI / 8.0
		base.append(Vector2(cos(a), sin(a)) * 23.0)
	draw_colored_polygon(base, Color(0.26, 0.16, 0.08))
	# 용암 균열선
	for i in 6:
		var a := TAU * float(i) / 6.0
		var p1 := Vector2(cos(a), sin(a)) * 7.0
		var p2 := Vector2(cos(a), sin(a)) * 23.0
		var glow := 0.38 + 0.32 * sin(t * 3.2 + float(i))
		draw_line(p1, p2, Color(1.0, 0.42, 0.04, glow * 0.72), 1.8)
	# 납작한 화산 몸체
	var body := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI / 8.0
		body.append(Vector2(cos(a), sin(a)) * 14.0)
	draw_colored_polygon(body, Color(0.20, 0.12, 0.06))
	# 분화구 (애니)
	var pulse := 0.72 + 0.28 * sin(t * 2.8)
	draw_circle(Vector2.ZERO, 11.0,       Color(0.82, 0.26, 0.04, 0.58))
	draw_circle(Vector2.ZERO, 7.5 * pulse, Color(1.0, 0.48, 0.06, 0.72))
	draw_circle(Vector2.ZERO, 4.2 * pulse, Color(1.0, 0.76, 0.18, 0.88))
	draw_circle(Vector2.ZERO, 2.0,         Color(1.0, 0.96, 0.52, 1.0))
	# 열기 파동 (팽창 링)
	for ring in 3:
		var rt := fmod(t * 1.3 + float(ring) * 0.33, 1.0)
		var r := 11.0 + rt * 16.0
		var alpha := (1.0 - rt) * 0.38
		draw_arc(Vector2.ZERO, r, 0, TAU, 16, Color(1.0, 0.52, 0.08, alpha), 2.2)
	var be := base.duplicate(); be.append(base[0])
	draw_polyline(be, Color(0.80, 0.42, 0.08, 0.48), 1.5)


# ── Arrow: 화살 발사대 플랫폼 ────────────────────────────────────────────
func _draw_arrow(t: float) -> void:
	var tc := tower_color
	# 낮은 석조 플랫폼
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, 4), Vector2(23, 4),
		Vector2(19, 17), Vector2(-19, 17),
	]), Color(0.36, 0.30, 0.22))
	draw_rect(Rect2(Vector2(-23, 0), Vector2(46, 6)), Color(0.42, 0.36, 0.26))
	draw_polyline(PackedVector2Array([
		Vector2(-23,0), Vector2(23,0), Vector2(23,6),
		Vector2(-23,6), Vector2(-23,0)
	]), Color(0.56, 0.48, 0.35), 1.2)
	# 활 아크
	draw_arc(Vector2(0, 3), 19.0, PI + 0.25, TAU - 0.25, 16,
		Color(0.52, 0.36, 0.16, 0.82), 3.0)
	# 활시위
	draw_line(Vector2(-18, 8), Vector2(18, 8), Color(0.82, 0.72, 0.50, 0.72), 1.2)
	# 5개 화살 (부채꼴 배열)
	var angles := [-0.42, -0.21, 0.0, 0.21, 0.42]
	for i in 5:
		var a: float = angles[i]
		var dir := Vector2(sin(a), -cos(a))
		var perp := Vector2(-dir.y, dir.x)
		var origin := Vector2(0, 5)
		var tip := origin + dir * 22.0
		var tail := origin + dir * 4.0
		# 화살대
		draw_line(tail, tip, Color(0.52, 0.36, 0.16), 1.8)
		# 화살촉
		draw_colored_polygon(PackedVector2Array([
			tip + dir * 7.0,
			tip - perp * 3.2,
			tip + perp * 3.2,
		]), Color(0.70, 0.52, 0.22))
		# 깃털
		draw_line(tail, tail - dir*3.5 + perp*4.5, Color(0.82, 0.72, 0.55, 0.68), 1.0)
		draw_line(tail, tail - dir*3.5 - perp*4.5, Color(0.82, 0.72, 0.55, 0.68), 1.0)
	# 중앙 그립
	draw_rect(Rect2(Vector2(-2.5, -1), Vector2(5, 8)), Color(0.32, 0.26, 0.17))


# ── Quake: 중장갑 요새 포탑 ─────────────────────────────────────────────
func _draw_quake(t: float) -> void:
	var tc := tower_color
	# 바닥 균열선 (포탑 아래에서 방사)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 8.0
		var clen := 34.0 + sin(t * 0.7 + float(i)) * 4.0
		var dir := Vector2(cos(a), sin(a))
		draw_line(dir * 22.0, dir * clen, Color(0.42, 0.28, 0.10, 0.52), 2.2)
		var mid := dir * (clen * 0.62)
		var fa := a + (0.38 if i % 2 == 0 else -0.38)
		draw_line(mid, mid + Vector2(cos(fa), sin(fa)) * 12.0,
			Color(0.36, 0.24, 0.08, 0.32), 1.2)
	# 외벽 (팔각형)
	var outer := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI / 8.0
		outer.append(Vector2(cos(a), sin(a)) * 22.0)
	draw_colored_polygon(outer, Color(0.32, 0.24, 0.15))
	var oe := outer.duplicate(); oe.append(outer[0])
	draw_polyline(oe, Color(0.52, 0.40, 0.26), 3.0)
	# 모서리 포루 (4개)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var bp := Vector2(cos(a), sin(a)) * 20.0
		draw_circle(bp, 6.0, Color(0.38, 0.28, 0.18))
		draw_circle(bp, 4.2, Color(0.46, 0.35, 0.22))
		draw_arc(bp, 4.2, 0, TAU, 8, Color(0.58, 0.44, 0.26), 1.2)
	# 내부 성채 (팔각형)
	var inner := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI / 8.0
		inner.append(Vector2(cos(a), sin(a)) * 13.0)
	draw_colored_polygon(inner, Color(0.25, 0.18, 0.11))
	var ie := inner.duplicate(); ie.append(inner[0])
	draw_polyline(ie, Color(0.46, 0.35, 0.22), 2.0)
	# 지진파 동심원 (애니)
	for ring in 3:
		var rp := fmod(t * 0.65 + float(ring) * 0.33, 1.0)
		var r := 6.0 + rp * 11.0
		var alpha := (1.0 - rp) * 0.48
		draw_arc(Vector2.ZERO, r, 0, TAU, 12,
			Color(tc.r, tc.g, tc.b * 0.4, alpha), 2.2)
	# 코어
	draw_circle(Vector2.ZERO, 5.2, Color(0.55, 0.38, 0.18))
	draw_circle(Vector2.ZERO, 3.2, Color(0.70, 0.52, 0.28))
	draw_circle(Vector2.ZERO, 1.6, Color(0.90, 0.72, 0.42))
