# 04. 작업 계획 (SDD 추적표)

기준: `main` 660b35d (Godot 4.6). 순서: **스펙 → 테스트(레드) → 구현 → 그린**

| # | 작업 | 스펙 | 테스트 | 상태 |
|---|---|---|---|---|
| P1 | 현재 동작 문서화 (GDD/아키텍처/스펙 6종) | 전체 | — | ✅ |
| P2 | 테스트 러너 (watchdog, 노드 정리) | — | run_tests | ✅ |
| P3 | 포탑 데이터·강화·판매 | SPEC-01 | test_towers | ✅ |
| P4 | 피해·상태이상 | SPEC-02 | test_damage_status | ✅ |
| P5 | 웨이브 결정성(`rng`), `enemy_stats` 추출 | SPEC-03 | test_waves | ✅ |
| P6 | 배치 `place_at` 추출 | SPEC-04 | test_placement | ✅ |
| P7 | 행동·릴레이 오라, **번개 연쇄가 죽은 적에 낭비되던 버그 수정** | SPEC-05 | test_behaviors | ✅ |
| P8 | 흐름 스모크 (스테이지 4종) | SPEC-06 | test_smoke | ✅ |
| P9 | 웹 빌드 + **한글·기호 폰트 번들(웹에서 전부 □로 깨지던 문제)** + 브라우저 E2E | SPEC-06 AC-06-4/5 | e2e_web.js | ✅ (밸런스 의존 1항목 제외) |
| P10 | 밸런스 시뮬레이션 + 조정 | SPEC-07 | balance_sim | ⬜ |
