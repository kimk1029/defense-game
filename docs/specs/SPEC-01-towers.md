# SPEC-01 포탑 데이터 · 강화 · 판매

**관련:** GDD §4 · 구현 `tower_registry.gd`, `tower.gd` · 테스트 `tests/test_towers.gd`

## 수용 기준
- **AC-01-1** 레지스트리에는 포탑 10종이 있다: ballista, gatling, frost, lightning, sniper, mortar, poison, laser, relay, drone.
- **AC-01-2** 데이터 무결성
  - 각 포탑의 `damage`/`attack_speed`/`range`/`cost_curve`는 길이 5다.
  - 피해·공속·사거리는 레벨이 올라도 감소하지 않는다.
  - `cost > 0`이고 `behavior_script`는 `TowerBehavior`를 상속한다.
- **AC-01-3** 강화 비용 = `int(cost × cost_curve[level+1])`. 최대 레벨(index 4)에서는 0이다.
- **AC-01-4** `try_upgrade`
  - 골드가 충분하면 차감하고 레벨을 올린다. 스탯은 다음 레벨 값이 되고, 총 투자액이 누적된다.
  - 골드가 부족하거나 최대 레벨이면 아무것도 바꾸지 않고 false다.
- **AC-01-5** `sell_refund = int(총 투자액 × 0.7)`
- **AC-01-6** `next_level_stats()`는 다음 레벨의 피해·공속·사거리를 반환한다. 최대 레벨이면 빈 딕셔너리다.
