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

_맥북 로컬 Claude 세션 수행, 2026-05-16_

### 점검 요약 — 클라이언트 쪽은 이미 최적, 변경 없음

- **Wi-Fi**: 5GHz ch36 / 160MHz / 802.11ax / WPA2·WPA3, 신호 -48dBm (SNR 45dB), Tx 1729~1814Mbps. 100M 회선 천장보다 한참 위.
- **DNS**: Wi-Fi 서비스에 1.1.1.1·1.0.0.1·8.8.8.8·8.8.4.4 수동 설정. Tailscale MagicDNS(100.100.100.100) 정상.
- **유선**: MBP14 내장 이더넷 없음, 어댑터 미연결 → 아래 권고 A.
- **로그인 항목**: Rectangle·Hidden Bar·Macs Fan Control·Maccy·Claude·ZeroTier — 전부 의도된 것.
- **프로세스**: 측정 시점 Spotlight·사진 재색인 중(corespotlightd·photolibraryd 70%+). 부팅 15h, 업데이트 후 일시적 — 끝나면 가라앉음.
- **디스크**: 926GB 중 470GB 여유, 캐시 정리 불필요. **메모리**: 24GB, swap 0, 정상.

### 한국 보안 SW 자동 시작 비활성 — 완료

맥미니와 동일 패턴(`~/.claude/memory/infrastructure_macmini.md` 참고). plist 9개 `.disabled` + launchd bootout + 프로세스 종료. 검증: 잔존 프로세스 0.

- TouchEn nxKey ×3 (`com.raon.touchen.nxkey`, `com.raon.agent.touchen.nxkey`, `com.raon.touchen.UserAgent`)
- MagicLine4NX, Wizvera Delfino, nProtect(`nosintgdmn`), AnySign, Kollus, CrossEX(`iniline`)
- 원본 백업: `~/.claude/backups/korea_security_macbook_20260516_1607/`
- 재활성화: `sudo mv <plist>.disabled <plist>` 후 재부팅. 인터넷뱅킹·인강은 해당 앱 실행 시 헬퍼 자동 복귀.
- ※ UnicornProMac은 SNI 우회 도구(보안 SW 아님) — 손대지 않음.

### 네트워크 심층 진단 (딥리뷰)

도구: `networkQuality`, `ping`×4, `netstat -i/-s`, `traceroute`, Wi-Fi 스캔, `dig`.

**결론: 문제는 "속도"가 아니라 "지연".**

1. **버퍼블로트 (심각)** — `networkQuality`: 유휴 HTTP 35ms → **부하 시 632ms**(94 RPM). 응답성 274 RPM(Medium). 다운/업로드만 하면 다른 동작이 ~0.6초 밀림 = "버벅임"의 정체. 속도(81↓/49↑ Mbps)는 100M 회선값 정상. 원인은 라우터/모뎀 과대버퍼 — 클라이언트 해결 불가.
2. **Wi-Fi 첫 홉 지터 (중간)** — 라우터 ping min3/avg15/max93/stddev25ms. 지터 전부 무선 구간 발생. 원인: ch36(160MHz)에 -47dBm 동일채널 160MHz 이웃 + AWDL 시분할.

**이상 없음**: 패킷 손실 0%, TCP 재전송 0(15h), 인터페이스 에러 0, 신호·링크레이트 완벽, DNS·TCP sysctl·전원 정상.

**개선 권고 (효과 순)**:
- **A. 유선화** — USB-C/썬더볼트 기가비트 이더넷 어댑터(₩1~3만). Wi-Fi 지터 완전 제거. 맥미니(유선)와의 체감 차이가 바로 이것.
- **B. 라우터 QoS** — 공유기 WAN 대역 ~80/45Mbps 캡 → 버퍼블로트(특히 업로드) 완화. ipTIME QoS는 SQM 아님, 부분 효과.
- **C. 5GHz 160MHz→80MHz** — ch36 동일채널 간섭↓ → 지터↓. PHY 1800→900Mbps지만 100M엔 영향 0.
- **D. 장기** — SQM(fq_codel/CAKE) 공유기 또는 LG U+ 회선 업글(500M/1G).

→ B·C는 공유기(192.168.0.1) 설정. WLAN ~50-80초 재시작이 맥미니·그램에도 영향 → **2026-05-16 `tasks/macmini.md`로 핸드오프**(맥미니=유선이라 WLAN 재시작 중 무중단). 맥북 클라이언트 자체는 추가 최적화 여지 없음.
