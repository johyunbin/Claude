# 작업: AX3000BCM QoS 적용 + 검증 — 맥북 세션

- **대상**: ipTIME AX3000BCM (192.168.0.1) QoS 기능
- **작성**: 맥미니 세션, 2026-05-16
- **수행 방법**: 맥북 로컬 Claude 세션. QoS 변경은 WLAN 재시작을 유발하지 않음 → 맥북이 직접 설정해도 자기 Wi-Fi 연결은 안 끊김.
- 먼저 `context/machines.md`를 읽을 것.

## 배경

5GHz 채널폭 160→80MHz는 맥미니 세션이 완료(`tasks/macmini.md` 참조). 남은 항목이 QoS.

맥북 네트워크 딥리뷰에서 **버퍼블로트**가 핵심 문제로 규명됨 — networkQuality 부하 시 HTTP 왕복 35ms→632ms(94 RPM). QoS로 WAN 대역을 캡하면 라우터가 자기 큐를 관리해 버퍼블로트(특히 업로드측)를 완화할 수 있음.

QoS는 맥미니로 못 넘김 — 맥미니는 인터넷이 en0(상위 공유기 유선)이라 AX3000BCM QoS의 효과를 측정할 수 없음. **맥북은 AX3000BCM Wi-Fi 경유 = QoS 수혜자이자 측정 주체** → 적용+검증을 한 세션에서 완결 가능.

## QoS 메뉴 구조 (맥미니 세션 사전 점검)

라우터 → 관리도구 → 트래픽 관리 → QoS 설정:
- QoS 동작 토글 (현재 중단)
- Down / Up 총 대역폭 슬라이더 (현재 1000 / 1000 Mbps = 캡 없음)
- 스마트 QoS 실행/중단 (현재 중단)
- IP·프로토콜별 규칙 테이블 (현재 0개)

## 작업

### 1. before 측정 (맥북에서)

- `networkQuality -v` — Responsiveness(RPM), idle/loaded latency, Up/Down capacity 기록. 2~3회 재서 중앙값.
- `ping -c 25 192.168.0.1` — 지터 stddev 기록.

### 2. QoS 적용 (라우터 192.168.0.1, admin 로그인 — 비밀번호는 사용자가 직접 입력)

- QoS 설정 페이지에서:
  - Down: 맥북 실측 Downlink capacity의 약 85~90%.
  - Up: 맥북 실측 Uplink capacity의 약 85~90%.
  - 스마트 QoS: 실행.
  - QoS 동작 토글: ON → 적용.
- ⚠ networkQuality capacity 측정은 흔들리므로 before 측정의 중앙값 기준으로 수치 결정.

### 3. after 측정 + 판정

- `networkQuality -v` 재측정.
- **Responsiveness(RPM) 상승 + loaded latency 하락 → 효과 있음, QoS 유지.**
- 변화 없거나 capacity만 깎이고 latency 그대로 → 효과 없음, **QoS 토글 OFF로 되돌림**(가역).

## 검증 지표

핵심은 속도가 아니라 **부하 시 응답성**. networkQuality의 Responsiveness RPM과 idle→loaded latency 차이를 before/after 비교. 채널폭 변경(80MHz) 후 맥북 Wi-Fi 지터(딥리뷰 당시 stddev 25ms)도 함께 재측정하면 좋음.

## 결과 (맥북 세션, 2026-05-16 19:20 — 완료)

**판정: QoS 효과 없음(오히려 악화) → 적용했다가 OFF 복원. 현재 QoS 꺼짐.**

### before / after (networkQuality 각 3회 중앙값)

| 지표 | before (QoS off) | after (QoS on: 75/44 + 스마트QoS) |
|---|---|---|
| Downlink | 72.8 Mbps | **8.2 Mbps** |
| Uplink | 49.9 Mbps | 18.9 Mbps |
| Responsiveness | 183 RPM / 327 ms | **90 RPM / 660 ms** |
| HTTP loaded 지연 | ~445 ms | **~1133 ms** |
| 라우터 ping 지터 stddev | 22.5 ms | 23.6 ms (변화 없음) |

OFF 복원 직후 재측정: Downlink 53 / Uplink 70 / Responsiveness 336 RPM — 정상 회복 확인.

### 왜 실패했나
- **스마트 QoS가 원인.** 총대역폭을 감지된 기기(7대)에 균등 분배하며 기기별 하드캡을 건다: Down 75÷7≈10, Up 44÷7≈6 Mbps. 맥북(192.168.0.25)이 10/6으로 하드캡 → networkQuality 다운로드 8Mbps가 이 캡이다.
- ipTIME 기기별 "최대속도제한"은 AQM(fq_codel류) 없는 단순 rate limiter. 좁은 파이프를 채우면 큐가 더 부풀어 부하 시 지연 1초+ 폭증. 버퍼블로트를 완화한 게 아니라 병목을 더 나쁜 리미터로 옮긴 셈.

### ⚠ 펌웨어 버그 (다음 세션 필독)
- QoS **적용 버튼**으로 Down/Up을 적용하면 값이 **÷10** 된다 (75 입력 → 7 적용). 우회: 10배로 입력 (750 → 75).
- QoS 동작 토글 ON/OFF 자체는 ÷10 영향 없음 (enable 플래그만 — 안전).
- 라우터 UI가 Flutter Web canvas라 스크린샷 자동화 불안정 — 적용은 사람이 직접 권장.

### 남은 실험 (권장)
- QoS 재시도 시 **스마트 QoS는 끄고 Down/Up 총량 캡만** 적용. 기기별 분배 없이 총 WAN 대역만 셰이핑하면 각 기기가 총량까지 burst 가능 — 표준 버퍼블로트 QoS 방식. 단 ipTIME 총량 셰이퍼의 AQM 품질은 미지수, 측정 필요.
- 80MHz 전환 후 맥북→라우터 지터 ~22-24ms (딥리뷰 160MHz 당시 25ms) — 미미한 개선. 라우터 지터는 QoS와 무관(QoS=WAN 셰이핑), Wi-Fi airtime 경합 별도 축.
- 회선 천장(LG U+ 100M)은 그대로 — 본질 개선은 회선 업그레이드.
