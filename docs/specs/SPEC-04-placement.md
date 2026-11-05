# SPEC-04 배치

**관련:** GDD §3 · 구현 `placement_system.gd` · 테스트 `tests/test_placement.gd`

## 수용 기준
- **AC-04-1** `begin_placement(id)`이면 GHOST 상태가 되고 `is_placing()`이 true다. 취소하면 IDLE로 돌아간다.
- **AC-04-2** `_is_valid(pos)`가 false인 경우
  - 경로 36px 이내
  - 다른 포탑 46px 이내
  - 가장자리 10px 이내
  - 하단 130px 이내
  - 골드 부족
- **AC-04-3** 유효한 위치에 설치하면 골드가 비용만큼 줄고, `towers_root`에 포탑이 추가된다. `placed`를 보낸 뒤 IDLE로 돌아간다.
