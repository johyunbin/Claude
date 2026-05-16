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

## 결과 (맥북 세션, 2026-05-16 19:35 — 완료)

**최종 판정: QoS OFF 유지.** 두 모드 다 실측 — 스마트QoS는 실패(악화), 총량캡만은 효과 있으나 대가가 큼.

### 모드 1: 스마트 QoS (75/44 + 스마트QoS 실행) — 기각

before(QoS off) → after(스마트QoS on), networkQuality 3회 중앙값:

| 지표 | QoS off | 스마트QoS on |
|---|---|---|
| Downlink | 72.8 Mbps | **8.2 Mbps** |
| Responsiveness | 183 RPM / 327ms | **90 RPM / 660ms** |
| HTTP loaded 지연 | ~445 ms | **~1133 ms** |

스마트 QoS는 총대역폭을 감지 기기 7대에 균등 하드캡(맥북 75÷7≈10 / 44÷7≈6 Mbps). networkQuality 다운로드 8Mbps가 이 캡. ipTIME 기기별 리미터는 AQM이 없어 좁은 파이프를 채우면 큐가 더 부풀어 부하 지연 1초+ 폭증 — 버퍼블로트 악화. → 즉시 OFF.

### 모드 2: 총량 캡만 (75/44, 스마트QoS OFF, 기기별 규칙 0) — 효과 있으나 대가 큼

같은 시간대(19:28~19:33) QoS ON/OFF 백투백 A/B (시간대 혼선 제거):

| 지표 | QoS OFF | 총량캡 ON (75/44) |
|---|---|---|
| Downlink | 87 Mbps | 59 Mbps (−32%) |
| Uplink | 34 Mbps | 38 Mbps (동등) |
| Responsiveness | 153 RPM / 392ms | **383 RPM / 156ms** |
| HTTP loaded 지연 | ~553 ms | **~308 ms** |
| Idle latency | ~97 ms | ~69 ms |

총량 캡은 버퍼블로트를 실제로 ~절반 줄인다(부하 지연 392→156ms, HTTP loaded 553→308ms). 스마트QoS 같은 폭락 없음. **단 다운로드를 ~32% 깎는다**(87→59). ipTIME 셰이퍼는 fq_codel/cake류 AQM이 없어 — 라우터를 병목으로 만들어 지연을 잡되 그 대가로 throughput을 크게 희생한다.

### 최종 결정: QoS OFF

다운로드 32% 상시 손실은 버퍼블로트 개선폭(여전히 networkQuality "Low~Medium" 구간) 대비 과한 대가로 판단 → **QoS 토글 OFF로 마무리.** 현재 라우터 상태: QoS 동작 OFF, 설정값 75/44 + 스마트QoS OFF + 규칙 0개 보존.

→ 응답성을 다운속도보다 우선하고 싶으면 **라우터 QoS 동작 토글만 ON** 하면 즉시 총량캡 모드(위 A/B의 "ON" 열). 가역.

근본 해결: AQM(cake/fq_codel) 지원 라우터 또는 LG U+ 회선 업그레이드.

### ⚠ 펌웨어/UI 버그 (다음 세션 필독)
- QoS 적용 시 Down/Up 값이 **÷10** 된다 — **단 스마트QoS 실행 상태로 적용할 때만**. 스마트QoS 중단으로 적용하면 ÷10 없음. (스마트QoS ON으로 적용할 땐 10배 입력: 750→75)
- QoS 동작 토글 ON/OFF 자체는 ÷10 영향 없음.
- 라우터 UI = Flutter Web canvas → 스크린샷 자동화 불안정(클릭 빗나감, 투명 입력칸 검증 어려움). 적용은 사람이 직접 권장.

### 기타
- 80MHz 전환 후 맥북→라우터 지터 stddev 18~28ms (딥리뷰 160MHz 당시 25ms) — 측정 노이즈 범위, 유의미 개선 아님. 라우터 지터는 QoS 무관(Wi-Fi airtime 경합 별도 축).
- networkQuality capacity는 토요일 저녁 ±2배 편차 — 단발값 신뢰 말 것, 중앙값·백투백 비교 필수.
