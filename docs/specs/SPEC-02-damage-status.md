# SPEC-02 피해 · 상태이상

**관련:** GDD §5 · 구현 `hit_payload.gd`, `status_holder.gd`, `status_effect.gd`, `enemy.gd` · 테스트 `tests/test_damage_status.gd`

## 수용 기준
- **AC-02-1** 물리 피해 = `max(1, base - 유효 방어)`
  - 마법이면 방어 0으로 계산한다.
  - 고정 피해면 base를 그대로 적용한다. 최소 1 규칙도 적용하지 않는다.
- **AC-02-2** 유효 방어 = `max(0, armor + armor_delta)`. 방깎은 `magnitude × stacks`만큼 깎는다.
- **AC-02-3** 중첩 규칙
  - refresh: 지속시간 = max(남은 시간, 새 지속시간)
  - stack: 중첩 수를 `max_stacks`까지 올리고 지속시간을 리셋한다.
  - strongest: 새 효과가 더 강할 때만 교체한다.
- **AC-02-4** 속도 배율
  - 둔화는 `(1 - magnitude)`를 곱한다.
  - 빙결이나 기절이 하나라도 있으면 0이다.
- **AC-02-5** 화상·독은 tick마다 `magnitude × stacks × delta` 피해를 준다. 만료된 효과는 제거한다.
- **AC-02-6** `take_hit`는 피해를 적용하고 디버프 사본을 부착한다. HP가 0 이하가 되면 `died(gold)`를 1회만 보낸다.
  - 죽은 적은 추가 피격을 무시한다.
