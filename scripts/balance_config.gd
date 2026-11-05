class_name BalanceConfig
## Single source of truth for run-level balance numbers (SPEC-07 AC-07-6).
## Tower numbers live in TowerRegistry. Verify changes with tools/balance_sim.gd.

const START_GOLD := 250
const START_LIFE := 20

const FIRST_PREP_TIME := 15.0   # AC-07-5
const BETWEEN_WAVES_TIME := 5.0
const SPAWN_INTERVAL := 0.75

## Gold paid when a wave is cleared.
static func wave_clear_bonus(w: int) -> int:
	return 10 + 2 * w

const HP_CURVE_K := 0.0025

## Multiplier applied on top of each enemy type's linear HP formula.
static func hp_curve(w: int) -> float:
	var x: float = float(w - 1)
	return 1.0 + HP_CURVE_K * x * x

## Per-stage enemy HP multiplier (compensates for path length / tower coverage).
const STAGE_HP_MULT := {1: 0.9, 2: 1.6, 3: 1.85, 4: 1.05}
## Stage multiplier ramps in over the first waves so every stage opens fairly (AC-07-1).
const STAGE_RAMP_WAVES := 6.0

static func stage_hp_mult(stage: int, w: int = 99) -> float:
	var full: float = float(STAGE_HP_MULT.get(stage, 1.0))
	var t: float = clampf(float(w - 1) / STAGE_RAMP_WAVES, 0.0, 1.0)
	return lerpf(1.0, full, t)
