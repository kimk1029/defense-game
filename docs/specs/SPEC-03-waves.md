# SPEC-03 웨이브

**관련:** GDD §6 · 구현 `wave_spawner.gd` · 테스트 `tests/test_waves.gd`

## 수용 기준
- **AC-03-1** `_build_wave(w)`의 길이는 `6 + 2w`다.
- **AC-03-2** 등장 조건
  - w=1이면 타입 0만 나온다.
  - 타입 1은 w ≥ 2, 타입 2는 w ≥ 3부터 등장할 수 있다.
- **AC-03-3** 결정성: 무작위 요소는 `WaveSpawner.rng`(RandomNumberGenerator)를 쓴다. 같은 seed면 같은 구성이 나온다.
- **AC-03-4** 적 스탯은 GDD §6 표를 따른다 (`enemy_stats(type, w)`).
- **AC-03-5** 흐름
  - 대기가 끝나면 `wave_started(w)`를 보낸다.
  - 큐가 비고 생존 적이 0이면 `wave_cleared(w)`를 보낸다.
  - 처치는 `enemy_killed(gold)`, 누수는 `enemy_reached_base(dmg)`를 보낸다.
