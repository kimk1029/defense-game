class_name PlacementSystem
extends Node2D

# 설치 UX의 상태머신: IDLE ↔ GHOST
#   - 타워바 버튼 클릭 → begin_placement(id) → GHOST
#   - 마우스 이동: ghost가 따라다니며 유효성 표시
#   - 좌클릭: 설치 후 IDLE 복귀
#   - 우클릭 / ESC: 취소 후 IDLE 복귀

signal placed(tower: Tower)

enum State { IDLE, GHOST }

var state: int = State.IDLE
var current_data: Dictionary = {}
var ghost: TowerGhost = null

# 외부 참조
var towers_root: Node2D = null
var path: Path2D = null
var enemies_root: Node2D = null
var projectiles_root: Node2D = null

func setup(_towers: Node2D, _path: Path2D, _enemies: Node2D, _projectiles: Node2D) -> void:
	towers_root = _towers
	path = _path
	enemies_root = _enemies
	projectiles_root = _projectiles

func begin_placement(tower_id: StringName) -> void:
	var td: Dictionary = TowerRegistry.get_tower(tower_id)
	_cancel()
	current_data = td
	ghost = TowerGhost.new()
	add_child(ghost)
	ghost.setup(td)
	ghost.global_position = get_viewport().get_mouse_position()
	state = State.GHOST

func is_placing() -> bool:
	return state == State.GHOST

func _process(_delta: float) -> void:
	if state != State.GHOST or ghost == null:
		return
	var mpos: Vector2 = get_viewport().get_mouse_position()
	ghost.global_position = mpos
	ghost.set_valid(_is_valid(mpos))

func _unhandled_input(event: InputEvent) -> void:
	if state != State.GHOST:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel()
		get_viewport().set_input_as_handled()

func _try_place() -> void:
	var pos: Vector2 = get_viewport().get_mouse_position()
	if not _is_valid(pos):
		return
	var cost: int = int(current_data["cost"])
	if GameState.gold < cost:
		return
	GameState.gold -= cost

	var tower := Tower.new()
	towers_root.add_child(tower)
	tower.global_position = pos
	tower.setup(current_data["id"], enemies_root, projectiles_root)
	placed.emit(tower)
	_cancel()

func _cancel() -> void:
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	current_data = {}
	state = State.IDLE

# ── 유효성 검사 ────────────────────────────────────────────────────────
func _is_valid(pos: Vector2) -> bool:
	if current_data.is_empty():
		return false
	if GameState.gold < int(current_data["cost"]):
		return false
	# 하단 UI 영역 금지
	if pos.y > get_viewport_rect().size.y - 130.0:
		return false
	if pos.y < 10.0 or pos.x < 10.0 or pos.x > get_viewport_rect().size.x - 10.0:
		return false
	# 다른 포탑과 최소 거리
	if towers_root != null:
		for t in towers_root.get_children():
			if t is Tower and t.global_position.distance_to(pos) < 46.0:
				return false
	# 경로 위 금지
	if _near_path(pos, 36.0):
		return false
	return true

func _near_path(pos: Vector2, thr: float) -> bool:
	if path == null or path.curve == null:
		return false
	var curve: Curve2D = path.curve
	var blen: float = curve.get_baked_length()
	if blen <= 0.0:
		return false
	var samples: int = 90
	for i in samples:
		var p: Vector2 = curve.sample_baked(blen * float(i) / float(samples - 1)) + path.position
		if p.distance_to(pos) < thr:
			return true
	return false
