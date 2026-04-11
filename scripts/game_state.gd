class_name GameState

# 선택된 스테이지 (1~4), 씬 전환 시에도 유지됨
static var selected_stage: int = 1

# 스테이지 메타데이터
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
# 난이도 1~3
static var STAGE_DIFF: Array[int] = [1, 2, 3, 2]
