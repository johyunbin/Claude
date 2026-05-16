# 작업: 맥북 네트워크 & 체감속도 최적화

- **대상**: 맥북 (MacBook Pro 14, macOS 26.5, 고정 IP 192.168.0.25)
- **작성**: 맥미니 세션, 2026-05-16
- **수행 방법**: 맥북 로컬 Claude 세션에서 진행
- 먼저 `context/machines.md`를 읽을 것.

## 목표

맥북의 네트워크 + 체감속도 최적화 (그램과 같은 취지 — `tasks/gram.md`도 참고).
100M 회선 한도 내에서 클라이언트 쪽을 최대한 끌어올린다.

## 점검 & 개선 항목 (비파괴)

### 네트워크
- [ ] Wi-Fi 링크 — 5GHz(`805_5G`)/160MHz 연결 확인:
      `system_profiler SPAirPortDataType` → PHY Mode / Channel / Security / Transmit Rate.
      Security가 "WPA2/WPA3 Personal"로 나오면 정상.
- [ ] DNS — `1.1.1.1` 등으로 잡혀 있는지. DHCP 자동이면 공유기가 1.1.1.1을 배포하므로 OK.
- [ ] 유선 연결 가능하면 유선이 최선 (지연·안정성).

### 체감 속도
- [ ] 로그인 항목 — 시스템 설정 → 일반 → 로그인 항목, 불필요한 항목 정리.
- [ ] 활성 상태 보기(Activity Monitor) — CPU/메모리/에너지 큰 프로세스 점검.
- [ ] 디스크 여유 공간 + 캐시 정리.
- [ ] 한국 보안 SW 백그라운드 상주 점검 (은행/공공 사용 시에만 필요).
- [ ] 참고: 맥미니 인프라 스냅샷이 `~/.claude/memory/infrastructure_macmini.md`에 있음
      (맥미니에서 한 보안·캐시·DNS 튜닝 내역 — 동일 패턴 적용 가능).

## 결과

_(맥북 세션이 점검·조치 내용을 여기에 적고 commit + push)_
