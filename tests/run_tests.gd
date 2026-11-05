extends SceneTree
## Headless runner: godot --headless --fixed-fps 60 --path . -s tests/run_tests.gd
## (--fixed-fps makes frame delta exactly 1/60s so bot/balance tests are deterministic)
## Exit code = number of failed assertions.

const FILES := [
	"res://tests/test_towers.gd",
	"res://tests/test_damage_status.gd",
	"res://tests/test_waves.gd",
	"res://tests/test_placement.gd",
	"res://tests/test_behaviors.gd",
	"res://tests/test_smoke.gd",
	"res://tests/test_balance.gd",
]

func _initialize() -> void:
	_run.call_deferred()

const WATCHDOG_SEC := 300.0
var _current_test := "(startup)"

func _run() -> void:
	# A runtime error inside an awaited test aborts that coroutine and the
	# runner would wait forever; the watchdog turns that into a failure.
	# Real (wall-clock) time: with --fixed-fps, game-time timers run far faster than reality.
	var started := Time.get_ticks_msec()
	process_frame.connect(func():
		if Time.get_ticks_msec() - started > WATCHDOG_SEC * 1000.0:
			print("TIMEOUT (likely runtime error) in ", _current_test)
			quit(99))
	var total_fail := 0
	var total_tests := 0
	for f in FILES:
		var script: Script = load(f)
		if script == null or not script.can_instantiate():
			print("LOAD FAIL ", f)
			total_fail += 1
			continue
		var inst = script.new()
		inst.tree = self
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			total_tests += 1
			inst.current = "%s::%s" % [f.get_file(), name]
			_current_test = inst.current
			var before: int = inst.failures.size()
			await inst.call(name)  # works for both sync and coroutine tests
			inst.cleanup()
			GameState.reset_run()
			var ok: bool = inst.failures.size() == before
			print("%s %s" % ["PASS" if ok else "FAIL", inst.current])
		for msg in inst.failures:
			print("   ✗ ", msg)
		total_fail += inst.failures.size()
	print("\n==== %d tests, %d failed assertions ====" % [total_tests, total_fail])
	quit(total_fail)
