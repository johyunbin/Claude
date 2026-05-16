# 작업: Gram 원격 접속 안정화 (always-on)

**상태**: 🟢 완료 — 그램 로컬 세션에서 always-on 3요소 적용 (2026-05-16 18:16 KST)
**먼저 읽기**: `context/machines.md`

## 사용자 목표

1. **항상 Gram 원격 접속 가능하게** — 같은 네트워크든 아니든, ZeroTier/Tailscale 통해.
2. **재부팅 후 로그인 전에도** 원격 제어 가능하게 (RDP로 로그인 화면 접속).

## 현재 문제

Windows App(RDP)로 Gram 접속 실패. 발단: 사용자가 Gram에서 와이파이/그래픽 드라이버
재설치 → 재부팅 → 그래도 접속 안 됨.

## 진단 결과 (2026-05-16 16:50, 맥미니 → Gram)

| 점검 | 결과 |
|------|------|
| Gram LAN ping (192.168.0.50) | ✅ 정상 (~15ms) |
| Gram Tailscale ping (100.118.239.128) | ❌ 100% loss |
| RDP 3389 — LAN | ✅ 열림·도달 |
| RDP 3389 — Tailscale | ❌ timeout |
| `tailscale status` 의 Gram | "offline, last seen 8m ago" |
| ARP | Gram 192.168.0.50 활성 |

**해석**: 재부팅 후 Gram은 **LAN엔 정상 연결, RDP 포트(3389)도 LAN에서 열림.**
그러나 **Tailscale에선 오프라인.**
- Windows App "내부" 연결 대상 = `192.168.0.50:3389` (LAN). 이 경로는 포트가 열려 있음.
- 접속 실패 원인 후보: ① RDP 세션 생성 단계 실패(그래픽 드라이버 재설치 잔재 가능)
  ② 인증(NLA/자격증명) ③ 사용자가 Tailscale 경로로 시도했는데 그게 오프라인.
- **→ 새 세션 1순위: Windows App의 정확한 오류 메시지/코드 확보.**

## 핵심 개념 — "로그인 전 / always-on 원격 접속"

별도 "자동 실행 파일"은 필요 없음. RDP·Tailscale·ZeroTier 모두 **Windows 서비스** =
부팅 시 시작. always-on 원격 접속의 3요소:

1. **부팅 시 네트워크** — Wi-Fi는 프로파일이 "모든 사용자 + 자동 연결"이어야 로그인
   전에 붙음 (per-user 프로파일이면 로그인해야 붙음). **유선(이더넷)이면 항상 로그인
   전 연결** — 가장 확실.
2. **오버레이가 부팅 시 연결**:
   - **Tailscale**: 기본은 로그인 사용자에 묶임 → 로그인 전엔 미연결.
     **`tailscale set --unattended`** (또는 GUI "Run unattended") 설정해야 로그인
     없이도 tailnet 유지. ← **Gram이 재부팅 후 Tailscale offline인 것의 유력 원인.**
   - **ZeroTier**: 서비스로 동작, 기본적으로 부팅 시 연결(로그인 무관). before-login엔 더 단순.
3. **RDP 활성** — TermService는 부팅 시 시작, 로그인 화면 접속 네이티브 지원.

## 새 세션 할 일

1. **즉시**: Windows App "내부"(`192.168.0.50:3389`)로 RDP 재시도 — LAN 포트는 열려
   있음. 실패 시 **정확한 오류 메시지** 확보 → 그래픽 드라이버 잔재면 Gram에서 드라이버
   정리 후 재부팅, 인증 문제면 NLA·자격증명 점검.
2. **Tailscale always-on**: Gram에서 관리자 권한으로 `tailscale set --unattended`
   적용 → 재부팅·로그아웃 후에도 tailnet 유지. (이게 "로그인 전 접속"의 핵심.)
3. **Wi-Fi 로그인 전 연결**: `netsh wlan show profiles` → `805_5G` 프로파일이 "모든
   사용자"인지 확인, 아니면 재등록. 또는 유선 연결 검토(가장 확실).
4. **오버레이 단일화 검토**: 사용자가 Tailscale + ZeroTier 둘 다 보유(macmini 둘 다
   활성, macbook ZeroTier IP 10.147.19.119). always-on 용도로 **하나로 통일** 권장
   — Tailscale `--unattended` 또는 ZeroTier 중 택1. 둘 동시는 라우팅 혼란 소지.
5. RDP 연결 대상은 LAN IP보다 **오버레이 고정 IP**(예: Tailscale 100.118.239.128)로
   — 네트워크가 바뀌어도 동일 주소로 접속.

## 참고 — 이번(맥미니) 세션 완료분

- **Karabiner**: Caps Lock RDP 한/영 fix 적용 — Windows App 최전면 시 Caps Lock →
  Right Alt(그램 한/영), 그 외엔 F19(맥 입력전환). 백업
  `~/.config/karabiner/karabiner.json.bak.20260516-1631`.
- **공유기**: 펌웨어 15.34.0 / WPA2-WPA3 / DNS 1.1.1.1 (`context/machines.md` 참조).
- 고정 IP: macmini .75 / macbook .25 / Gram .50.

## 진행 메모

### 2026-05-16 18:16 KST — 그램 로컬 세션 (한/영 해결 후 이어서)

비관리자 PowerShell + UAC 승인 2회로 진행. always-on 3요소 전부 확보:

1. **Tailscale unattended** ✅ — `tailscale set --unattended` 적용.
   `tailscale debug prefs` → `"ForceDaemon": true` 확인. 이제 재부팅·로그아웃
   후에도 tailnet 유지 → 로그인 전 원격 접속 가능. (재부팅 후 offline 이던
   직접 원인이 이거였음.)
2. **Wi-Fi 로그인 전 연결** ✅ — 이미 정상. `805_5G` = "All User Profile" +
   "Connect automatically" → 로그인 전 자동 연결됨. 손댈 것 없음.
3. **RDP** ✅ — `fDenyTSConnections=0`, TermService Running/Automatic. 활성 상태.
4. **덮개 닫기 동작 → "아무것도 안 함"** ✅ — always-on 이면 덮개 닫아도 안 자야
   함. powercfg 로 AC+DC 둘 다 LIDACTION=0 설정. (setvalueindex 는 설정이
   숨김이어도 정상 적용 — exit 0.)
5. **오버레이 단일화 → Tailscale** ✅ — 사용자 결정. ZeroTierOneService 를
   Automatic→Manual 전환 + 중지. 제거 아님(필요 시 `Start-Service` 로 재가동).
   RDP 대상 주소는 Tailscale 고정 IP `100.118.239.128:3389` 사용.

**검증 남음**: Mac(Windows App)에서 `100.118.239.128:3389` 로 실제 RDP 접속 —
Mac 세션에서 확인 필요. Gram 쪽 준비는 전부 완료.

추가 처리(체감속도 task): NIC 절전 해제(PnPCapabilities=256, 다음 부팅 적용),
Wi-Fi 드라이버는 이미 최신(24.40.0.4 / 2026-04-13)으로 갱신돼 있었음. 상세는
`tasks/gram.md` 결과 섹션 참조.
