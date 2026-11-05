extends RefCounted
## Minimal assertion base. Test methods start with "test_".

var failures: Array[String] = []
var current := ""
var tree: SceneTree

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append("%s: %s" % [current, msg])

func eq(a, b, msg: String = "") -> void:
	check(a == b, "%s expected %s got %s" % [msg, str(b), str(a)])

func near(a: float, b: float, msg: String = "", eps: float = 0.001) -> void:
	check(absf(a - b) <= eps, "%s expected %.4f got %.4f" % [msg, b, a])

## Adds a node to the live tree (so _ready runs) and tracks it for cleanup.
var _spawned: Array[Node] = []
func spawn(n: Node) -> Node:
	tree.root.add_child(n)
	_spawned.append(n)
	return n

func cleanup() -> void:
	for n in _spawned:
		if is_instance_valid(n):
			n.free()
	_spawned.clear()

## Enemy on a straight 1000px path, parked at `progress`.
func make_enemy(hp: float = 100.0, armor: float = 0.0, progress: float = 0.0, pos := Vector2.ZERO) -> Enemy:
	var root: Node2D = spawn(Node2D.new())
	var path := Path2D.new()
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2.ZERO)
	path.curve.add_point(Vector2(1000, 0))
	root.add_child(path)
	var pf := PathFollow2D.new()
	pf.loop = false
	path.add_child(pf)
	pf.progress = progress
	var e := Enemy.new()
	e.setup(hp, 60.0, armor, 3, 1)
	e.path_follow = pf
	root.add_child(e)
	e.set_process(false)
	e.global_position = pos
	return e
