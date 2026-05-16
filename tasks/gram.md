# 작업: 그램 네트워크 & 체감속도 최적화

- **대상**: 그램 (Windows 11, LG Gram, 고정 IP 192.168.0.50, Wi-Fi 연결, 사용자 `wh850`)
- **작성**: 맥미니 세션, 2026-05-16
- **수행 방법**: 그램 로컬 Claude Desktop 세션에서 진행 (RDP 원격제어 X — 키 입력 불안정)
- 먼저 `context/machines.md`를 읽을 것.

## 배경 / 목표

사용자 체감 두 가지:
1. 네트워크가 맥미니보다 버벅인다.
2. PC 자체가 좀 느리다.

100M 회선 자체는 못 바꾸므로, **그 한도 내에서** 네트워크 + 시스템 체감속도를 끌어올린다.

## 왜 맥미니보다 느리게 느껴지나 (1차 가설)

- 맥미니는 **유선 이더넷**으로 인터넷 → 저지연·안정.
- 그램은 **Wi-Fi**로 AX3000BCM 연결 → 본질적으로 지연·변동이 큼.
- → 유선 연결이 가능하면 그게 가장 큰 개선. 불가하면 Wi-Fi 품질을 최대로.

## 점검 & 개선 항목 (전부 비파괴)

### 네트워크
- [x] Wi-Fi 밴드 — 5GHz(`805_5G`) 연결 확인. 전환 불필요.
- [x] 링크 속도/신호 — 수신 2042 / 송신 1361Mbps, 신호 90% — 양호.
- [ ] Wi-Fi 드라이버 최신화 — **미완**. 현재 2021-06-29 v22.70.0.6 → 사용자 직접 갱신 예정.
- [x] DNS — `1.1.1.1 / 8.8.8.8` 정상.
- [ ] NIC 절전 — **미완**. PowerShell WMI 무응답 → 장치관리자 GUI 확인 필요.
- [x] `ipconfig /flushdns` — 완료.
- [ ] 유선 가능 여부 — 미확인.

### 체감 속도
- [x] 시작 프로그램 — 불필요 항목 7개 "사용 안 함" 처리.
- [x] 자원 점유 프로세스 — 점검함, 이상 없음.
- [x] 디스크 — C·D 모두 SSD, 공간 넉넉.
- [ ] Windows 업데이트 — **미점검**.
- [x] 전원 모드 — 이미 "고성능", 변경 없음.
- [x] 한국 보안 SW — 서비스 2개 수동화, AhnLab 서비스는 변경 거부(아래 결과 참고).
- [x] 시각 효과 — Windows 자동 설정, 손댈 것 없음.

## 이미 처리된 것

- AC 전원 시 화면끄기·절전 → "안 함" (사용자가 직접 설정함).
  → 덮개 닫을 때 동작도 "아무것도 안 함"인지 확인하면 절전 문제 완결 (전원·배터리 → 덮개 컨트롤).
- 공유기는 이미 최적화 완료 (펌웨어 15.34.0 / WPA3 / DNS 1.1.1.1 — `context/machines.md`).

## 주의

- 비파괴 작업만. 어댑터 비활성/재활성, `netsh winsock reset` 등 연결을 끊거나 재부팅이
  필요한 작업은 사용자에게 알리고 진행.
- **한/영 키 이슈**: 맥미니에서 RDP로 제어할 때 stuck modifier가 생겨 한/영 키가 먹지
  않은 적 있음. 재부팅하면 입력 상태가 초기화돼 해결됨.

## 결과

_그램 로컬 세션, 2026-05-16 — 사용자 프로필 `wh850`, 비관리자 PowerShell + UAC 승인 1회로 진행._

### 네트워크 — 이미 우수, 손댈 것 거의 없음
- Wi-Fi 어댑터: Intel Wi-Fi 6 AX201 160MHz.
- 링크: SSID `805_5G`, **5GHz / 802.11ax / 채널 36 / WPA3-Personal**.
  수신 2042Mbps · 송신 1361Mbps · 신호 90% · RSSI −47 → 전부 양호.
- DNS: Wi-Fi 어댑터 `1.1.1.1 / 8.8.8.8` 정상. `ipconfig /flushdns` 실행함.
- 100M 회선 천장(~86Mbps)보다 Wi-Fi 링크가 훨씬 빠름 → 체감 버벅임의 원인은
  회선/링크 속도가 아니라 **Wi-Fi 지연 변동 + 아래 시스템 요인**.

### 시스템 — 대체로 양호
- CPU i7-1165G7(4C/8T), RAM 16GB(점검 시 7.3GB 여유), C·D 모두 SSD에 공간 넉넉.
- 전원 구성표: **고성능** — 이미 최적, 변경 없음.
- 자원 점유 프로세스 이상 없음(상위는 claude/Defender/explorer 등 정상 범위).
- 시각 효과: `VisualFXSetting` 미설정 = Windows 자동 → 손댈 것 없음.

### 조치한 것 — 부팅 자동시작 정리 (전부 되돌릴 수 있음)
- 시작 항목 7개 **사용 안 함** 처리 (Task Manager "사용 안 함"과 동일한
  StartupApproved 방식 — Task Manager에서 한 번 클릭으로 재활성 가능):
  AhnLab Safe Transaction Application, ALCapture, wizvera-veraport-x64,
  Logi Download Assistant, LGPCCareExtension, Adobe Acrobat Synchronizer, CrossEXService.
- 한국 보안 SW 서비스 **자동 → 수동** 전환 (필요 시 자동 시작):
  WizveraPMSvc ✓, CrossEX Live Checker ✓.
- ⚠ **SafeTransactionSVC (AhnLab Safe Transaction Service)** 는 자체 보호 기능 때문에
  SCM을 통한 변경이 거부됨("액세스 거부"). Run 키 자동시작은 껐으나 서비스 자체는
  여전히 Automatic. 완전 비활성은 AhnLab 자체 설정 또는 제거로만 가능.
- 효과는 **다음 재부팅 후** 적용 (현재 떠 있는 프로세스는 그대로 둠 — 무중단).

### 미완 / 사용자 직접 진행 필요
- **Wi-Fi 드라이버 갱신 권장**: 현재 Intel `22.70.0.6` / **2021-06-29**자(약 5년 전).
  Intel Driver & Support Assistant 또는 LG Update Center로 최신(23.x대)으로 갱신.
  체감 안정성에 영향 큰 항목.
- **NIC 절전 해제 확인**: `Get-NetAdapterPowerManagement`가 드라이버 WMI 무응답으로
  실패. 장치관리자 → Wi-Fi 어댑터(AX201) → 전원 관리 탭에서
  "전원 절약을 위해 끌 수 있음" 체크 해제 필요(GUI).
- Windows 업데이트 보류분 점검 미실시.
- 유선(이더넷) 연결 가능 여부 미확인 — 가능하면 유선이 지연/안정성 면에서 최선.

### 한/영 키 (RDP) — 부분 해결
- 증상: Mac → RDP로 그램 제어 시 한/영 키가 안 먹음(로컬은 정상). 원인은
  Mac용 Microsoft 원격 데스크톱이 `VK_HANGUL`을 전달 못 함.
- 그램 조치: **AutoHotkey v2 설치**, `hangul-toggle.ahk` 작성 후 시작 프로그램 등록.
  `Caps Lock` 및 `Shift+Space` → 한/영(`vk15`)으로 매핑.
- `Shift+Space`는 RDP에서 정상 작동 확인됨.
- `Caps Lock`은 미작동: 사용자 Mac의 Karabiner가 Caps Lock→F18→(macOS 입력소스
  전환)으로 처리해 Windows 세션에 키가 전달되지 않음. 해결하려면 Mac Karabiner에
  앱별 규칙(RDP 포커스 시 Caps Lock→Shift+Space) 추가 필요 — Mac 세션 작업.
