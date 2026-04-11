class_name GameState

# 전역 게임 상태. class_name의 static 변수로 구현되어 씬 전환에도 값이 유지된다.
# title.gd가 참조하는 스테이지 관련 static들은 그대로 보존.

# ── 스테이지 선택 ─────────────────────────────────────────────────────
static var selected_stage: int = 1

static var STAGE_NAMES: Array[String]  = [
	"초원의 길",
	"지그재그 협로",
	"나선 계곡",
	"격자 미로",
]
static var STAGE_DESCS: Array[String] = [
	"완만한 S자 곡선\n입문 난이도",
	"촘촘한 지그재그\n긴 이동 거리",
	"넓은 소용돌이\n중앙 집중 공략",
	"직각 격자 경로\n효율적 배치 요구",
]
static var STAGE_DIFF: Array[int] = [1, 2, 3, 2]

# ── 인게임 상태 ───────────────────────────────────────────────────────
static var gold: int = 150
static var life: int = 20
static var wave: int = 0

static func reset_run() -> void:
	gold = 150
	life = 20
	wave = 0

static func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

static func add_gold(amount: int) -> void:
	gold += amount
