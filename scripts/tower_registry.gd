class_name TowerRegistry

# 포탑 데이터 중앙 레지스트리.
# 레벨별 스탯을 Array[float]로 선언해 밸런스 조정이 쉬운 구조를 갖춘다.
# 새 포탑 추가: behavior 파일 하나 + 이 파일에 한 블록 추가하면 끝.

static var _towers: Dictionary = {}
static var _initialized: bool = false

static func init() -> void:
	if _initialized:
		return
	_initialized = true

	_towers[&"ballista"] = {
		"id":            &"ballista",
		"name":          "발리스타",
		"icon":          "▶",
		"desc":          "단일 화력 / 장갑 대응",
		"cost":          100,
		"color":         Color(0.86, 0.74, 0.48),
		"role":          &"single",
		"damage":        [26.0, 31.2, 31.2, 31.2, 31.2],
		"attack_speed":  [0.95, 0.95, 0.95, 1.09, 1.09],
		"range":         [180.0, 180.0, 180.0, 180.0, 180.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/ballista_behavior.gd"),
	}

	_towers[&"gatling"] = {
		"id":            &"gatling",
		"name":          "개틀링",
		"icon":          "⊗",
		"desc":          "지속 화력",
		"cost":          120,
		"color":         Color(0.72, 0.72, 0.78),
		"role":          &"dps",
		"damage":        [7.0, 8.05, 8.05, 8.05, 8.05],
		"attack_speed":  [3.6, 3.6, 3.6, 4.14, 4.14],
		"range":         [150.0, 150.0, 150.0, 166.0, 166.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/gatling_behavior.gd"),
	}

	_towers[&"frost"] = {
		"id":            &"frost",
		"name":          "냉기",
		"icon":          "❄",
		"desc":          "둔화 / 군중제어",
		"cost":          130,
		"color":         Color(0.42, 0.82, 1.00),
		"role":          &"cc",
		"damage":        [14.0, 16.1, 16.1, 16.1, 16.1],
		"attack_speed":  [1.6, 1.6, 1.6, 1.84, 1.84],
		"range":         [184.0, 184.0, 184.0, 196.0, 196.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/frost_behavior.gd"),
	}

	_towers[&"lightning"] = {
		"id":            &"lightning",
		"name":          "번개",
		"icon":          "⚡",
		"desc":          "연쇄 타격",
		"cost":          160,
		"color":         Color(0.98, 0.88, 0.22),
		"role":          &"aoe",
		"damage":        [18.0, 18.0, 18.0, 18.0, 18.0],
		"attack_speed":  [1.2, 1.2, 1.38, 1.38, 1.38],
		"range":         [172.0, 172.0, 172.0, 172.0, 172.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/lightning_behavior.gd"),
	}

	_towers[&"sniper"] = {
		"id":            &"sniper",
		"name":          "저격",
		"icon":          "◎",
		"desc":          "장거리 / 보스",
		"cost":          140,
		"color":         Color(0.72, 0.72, 0.48),
		"role":          &"single",
		"damage":        [78.0, 97.5, 97.5, 97.5, 97.5],
		"attack_speed":  [0.32, 0.32, 0.32, 0.35, 0.35],
		"range":         [280.0, 280.0, 280.0, 312.0, 312.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/sniper_behavior.gd"),
	}

	_towers[&"mortar"] = {
		"id":            &"mortar",
		"name":          "박격포",
		"icon":          "☄",
		"desc":          "광역 폭발",
		"cost":          150,
		"color":         Color(0.82, 0.48, 0.20),
		"role":          &"aoe",
		"damage":        [36.0, 39.6, 39.6, 45.5, 45.5],
		"attack_speed":  [0.7, 0.7, 0.7, 0.7, 0.7],
		"range":         [208.0, 208.0, 208.0, 208.0, 208.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/mortar_behavior.gd"),
	}

	_towers[&"poison"] = {
		"id":            &"poison",
		"name":          "독성",
		"icon":          "☠",
		"desc":          "지속 피해 / DoT",
		"cost":          135,
		"color":         Color(0.42, 0.90, 0.30),
		"role":          &"dot",
		"damage":        [10.0, 10.0, 10.0, 11.5, 11.5],
		"attack_speed":  [1.4, 1.4, 1.4, 1.4, 1.4],
		"range":         [192.0, 192.0, 192.0, 192.0, 192.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/poison_behavior.gd"),
	}

	_towers[&"laser"] = {
		"id":            &"laser",
		"name":          "레이저",
		"icon":          "✦",
		"desc":          "지속 집속",
		"cost":          170,
		"color":         Color(0.96, 0.38, 0.88),
		"role":          &"sustained",
		"damage":        [3.5, 4.03, 4.03, 4.03, 4.03],
		"attack_speed":  [8.0, 8.0, 8.0, 8.0, 8.0],
		"range":         [180.0, 180.0, 180.0, 200.0, 200.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/laser_behavior.gd"),
	}

	_towers[&"relay"] = {
		"id":            &"relay",
		"name":          "릴레이",
		"icon":          "⊛",
		"desc":          "주변 포탑 강화",
		"cost":          110,
		"color":         Color(0.40, 0.88, 0.90),
		"role":          &"support",
		"damage":        [6.0, 6.0, 6.0, 6.0, 6.0],
		"attack_speed":  [1.0, 1.0, 1.0, 1.0, 1.0],
		"range":         [140.0, 140.0, 140.0, 140.0, 140.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/relay_behavior.gd"),
	}

	_towers[&"drone"] = {
		"id":            &"drone",
		"name":          "드론",
		"icon":          "◈",
		"desc":          "유동 타격 / 소환형",
		"cost":          180,
		"color":         Color(0.70, 0.80, 1.00),
		"role":          &"multi",
		"damage":        [16.0, 18.0, 18.0, 20.0, 22.0],
		"attack_speed":  [1.5, 1.5, 1.5, 1.5, 1.5],
		"range":         [200.0, 200.0, 200.0, 200.0, 200.0],
		"cost_curve":    [0.0, 0.70, 1.00, 1.40, 2.00],
		"behavior_script": preload("res://scripts/drone_behavior.gd"),
	}

static func get_tower(id: StringName) -> Dictionary:
	init()
	return _towers[id]

static func get_all_ids() -> Array:
	init()
	return _towers.keys()

static func get_cost(id: StringName) -> int:
	return int(get_tower(id)["cost"])
