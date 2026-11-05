# 03. 기술 설계 (Architecture)

Godot **4.6** / GDScript / 모바일 렌더러 (웹은 gl_compatibility)

## 1. 구조
```
scenes/title.tscn   타이틀 + 스테이지 선택 (scripts/title.gd)
scenes/main.tscn    게임 본편 (scripts/main.gd = GameMain)
scripts/
  game_state.gd       GameState: static 전역 상태 (골드/생명/웨이브/선택 스테이지)
  main.gd             GameMain: 노드 조립, HUD, 인스펙터, 스테이지 경로, 게임오버
  terrain.gd          Terrain: 지형을 1회만 그림
  placement_system.gd PlacementSystem: 설치 상태 머신 (IDLE ↔ GHOST), 유효성 검사
  tower_ghost.gd      설치 미리보기
  wave_spawner.gd     WaveSpawner: 웨이브 구성, 스폰, 처치/누수 집계
  tower_registry.gd   TowerRegistry: 포탑 10종 데이터 (레벨별 배열)
  tower.gd            Tower: 사거리·쿨다운·타깃 공통 로직, 강화/판매, 릴레이 오라
  tower_behavior.gd   TowerBehavior: 포탑별 전략 베이스 (select_target/fire/on_level_up)
  *_behavior.gd       포탑 10종의 고유 행동
  enemy.gd            Enemy: PathFollow2D 이동, 피격, 상태이상 부착
  hit_payload.gd      HitPayload: 한 방의 피해/관통/스플래시/디버프 묶음
  status_effect.gd    StatusEffect: 상태이상 정의 + 중첩 규칙
  status_holder.gd    StatusHolder: 적 1마리의 상태이상 집합, tick/속도/방깎
  projectile.gd 외    투사체, 이펙트
tests/                헤드리스 테스트 (스펙 AC 대응)
tools/                시뮬레이션(밸런스), 스크린샷, 웹 E2E
```

## 2. 핵심 흐름
- **설치:** 타워 바 버튼 → `PlacementSystem.begin_placement(id)` → 클릭 → `_is_valid` 검사 → 골드 차감 → `Tower.setup` → `placed` 시그널 → HUD 갱신
- **공격:** `Tower._process`가 쿨다운을 돌린다.
  - `_enemies_in_range` → `behavior.select_target` → `behavior.fire` 순서로 실행한다.
  - 쿨다운 = `1 / (공속 × (1 + 릴레이 보너스))`
- **피격:** `Projectile` 도착 → `Enemy.take_hit(payload)` → `HitPayload.compute_damage_against` → 디버프를 `StatusHolder`에 적용
- **웨이브:** `WaveSpawner._process`가 대기 → 시작 → 스폰 큐 소진 → `alive_count == 0`이면 클리어 → 대기로 돌아간다.

## 3. 테스트 가능성 원칙 (이번 SDD 도입분)
- 무작위 요소는 주입 가능한 `RandomNumberGenerator`로 만든다. 예: `WaveSpawner.rng`. 같은 seed면 같은 결과가 나와야 한다.
- 테스트는 실제 노드를 트리에 붙여 검증한다. `tests/run_tests.gd`가 SceneTree 러너다.
  - 감시 타이머(watchdog)를 두어, 멈춘 테스트를 실패로 처리한다.
- 웹 디버그 빌드에서만 `window.rbState`로 상태를 노출한다. 브라우저 E2E용이다.

## 4. 실행
```
godot --headless --path . -s tests/run_tests.gd        # 단위/통합 테스트
godot --headless --path . -s tools/balance_sim.gd      # 밸런스 시뮬레이션 리포트
```
