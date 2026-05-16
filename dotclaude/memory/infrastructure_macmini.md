---
name: 맥미니 인프라 환경 (2026-05-16 기준)
description: 맥미니 시스템 상태 — ISP, 네트워크, 보안, 자동화, 백업 인프라 스냅샷. 사용자 환경 이해와 시스템 작업 결정에 활용.
type: project
---

**ISP**: LG U+ (AS3786 LG DACOM Corporation) — KT 아님. 공인 IP 118.131.92.18 (서울).
- **회선 등급**: 100M로 추정 (speedtest Download 77~87 Mbps 천장). 본질적 속도 개선 = LG U+ 101 콜 → 500M/1G 업그레이드.
- **고객센터**: 101 (LG U+ 휴대폰) 또는 1644-7000.

**메인 공유기**: ipTIME AX3000BCM — 듀얼밴드 Wi-Fi 6 (6GHz 없음, 6E 아님). 192.168.0.1, 관리자 admin/<REDACTED-ROUTER-WIFI-PW> (로그인 정상).
- 펌웨어 **15.34.0** (2026-05-16 14.28.8→15.34.0 자동 업그레이드 — 신형 /ui/ 웹UI로 교체됨).
- 5GHz SSID 805_5G (ch36 / 160MHz), 2.4GHz SSID 805 (auto). 인증 **WPA2/WPA3 혼용** (WPA3SAE/WPA2PSK+AES, 2026-05-16 WPA2→전환).
- 원격 관리 포트 미설정, Easy Mesh 미사용, 포트포워드/UPnP규칙/DMZ 0건. WAN=동적IP(192.168.123.106).
- **DNS = 1.1.1.1 / 8.8.8.8** (2026-05-16 ISP DNS 203.248.252.2 → 수동 변경, DHCP가 전 클라이언트에 배포). WiFi 고급은 11ax/160MHz/Tx100%로 이미 최적.
- ⚠ 무선 설정 변경 시 WLAN 전체 ~50-80초 재시작 (5GHz/2.4GHz 동시 끊김). 펌웨어 업그레이드는 ~2분 재부팅. 맥미니 인터넷은 en0이라 무중단.

**상위 공유기/모뎀**: 게이트웨이 192.168.123.1, Flutter SPA 웹UI (LG U+ 제공 추정). 관리자 PW 미해결 — 신형 default 라벨 랜덤 PW 추정, JSON-RPC+captcha로 자동화 불가. AX3000BCM WAN이 여기서 IP 받음.

**네트워크**:
- Ethernet en0 1Gbps full-duplex, 192.168.123.105/24 (상위 공유기 직결 — 맥미니 기본 인터넷 경로)
- DNS Ethernet → 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4 (Cloudflare + Google)
- WiFi en1 802.11ax 채널 36 / 5GHz / 160MHz / WPA2-WPA3 (AX3000BCM 805_5G 연결). 공유기가 Wi-Fi 6 (6GHz 미지원)
- Tailscale 활성 (macmini 100.85.223.63, macbook/iphone 연동) + ZeroTier 활성 (둘 다 유지 결정)
- DNS 응답: 1.1.1.1 = 25ms, 168.126.63.1 = 25ms (동급)

**보안**:
- 방화벽 ON + Stealth Mode + Signed SW 자동 허용 (2026-05-16 활성화)
- FileVault OFF (사용자 결정 — 물리 접근 제한 환경)
- SIP enabled / Gatekeeper enabled
- 화면공유 ON (3283 외부 LISTEN — 맥북/타PC GUI 접속 위해 유지)

**Time Machine**: T9_TM 볼륨 (case-insensitive APFS, T9 컨테이너 공유, 1.6TB 가용에서 815G 사용)
- destination ID: 75EBF43E-57A7-4C6C-A711-4A447C4196CA
- 자동백업 ON + 첫 백업 완료 (2026-05-16 02:30)
- 제외: ~/Library/Caches, ~/.Trash, ~/.claude/projects, Docker, /tmp 등

**Trading launchd 4시대 분산** (2026-05-16 재배치):
- 03:00 recovery_drill
- 04:00 log_rotate
- 04:15 db_integrity
- 04:30 stock_integrity (이전 4:35 → DB 락 충돌 fix)
- 04:45 l3_normalize (매월 1일만)
- 05:00 icloud_db_backup (이전 4:50 → l3_normalize와 충돌 fix)

**한국 보안 SW 상태** (2026-05-16): 12개 plist .disabled 처리.
- AhnLab ASTx, Raon TouchEn nxKey, Wizvera (Delfino/Veraport), MagicLine4NX, AnySign, Interezen, KollusAgent, BugsRemoteKeyRouter
- 인터넷뱅킹/공공기관 사용 시 수동 시작 패턴
- 다시 켜려면: `sudo mv /Library/LaunchAgents/X.plist.disabled /Library/LaunchAgents/X.plist`
- 백업: `~/.claude/backups/korea_security_20260516_0146/`

**네트워크 2망 구성** (2026-05-16 규명):
- en0 192.168.123.105 — 상위 공유기/모뎀 (게이트웨이 192.168.123.1)
- en1 — ipTIME AX3000BCM 메인 공유기(192.168.0.1) 측. 상세는 위 "메인 공유기" 항목.
- **AX3000BCM 고정 IP 예약** (2026-05-16 사용자 설정): 맥미니 192.168.0.75 / 맥북 192.168.0.25 / 그램 192.168.0.50. 예약이라 안정적 (각 머신 DHCP 갱신 후 반영 — 갱신 전 macmini en1은 .6일 수 있음).
- ※ 이번 세션 초반 헤맨 192.168.123.1(Flutter SPA)은 상위 별개 공유기. 진짜 메인 = 192.168.0.1.
- 공유기 최적화 완료 (2026-05-16): 펌웨어 15.34.0 업그레이드 + WPA2/WPA3 전환. 채널36·160MHz는 점검 결과 이미 최적이라 변경 없음.

**RDP / Tailscale**:
- Gram 노트북 (Windows 11, 사용자 wh850) — 고정 IP 192.168.0.50, MAC C4-23-60-3C-00-CD.
- Tailnet johyunbin@github: macmini 100.85.223.63 / Gram 100.118.239.128 / macbook 100.127.92.10 / iphone 100.100.83.43.
- Microsoft Remote Desktop(Windows App) "내부" 연결 → Gram RDP. RDP 끊기면 Gram 전원·온라인 먼저 확인.
- ⚠ Gram WoL 안 됨 (Wi-Fi+WoWLAN 미설정). 절전 시 RDP 3389 타임아웃(0x204) → 물리적으로 깨워야 함.
- ⚠ **RDP로 Gram 원격제어 시 키 입력 깨짐** (computer-use type→'aaaaaa' garbling, modifier stuck → 한/영 키 먹통). 클립보드 동기화도 불안정. → **Gram 작업은 RDP 말고 Gram 로컬 Claude Desktop 세션으로 할 것.**
- ⚠ Windows App "연결 끊기면 자동 재연결" ON → Gram 재부팅해도 RDP가 자동 재접속해 콘솔 재점유. 확실히 끊으려면 Windows App 자체를 종료.

**멀티머신 작업 허브** (2026-05-16 신설):
- `~/Claude` = git 저장소 (github.com:johyunbin/Claude) — 맥미니·맥북·그램 3대 머신 작업 조율 허브.
- 각 머신이 git clone/pull, `tasks/<머신>.md` 지침으로 세션 간 작업 전달. `context/machines.md`에 머신·네트워크 스냅샷.
- 원격제어 대신 각 머신 로컬 Claude 세션으로 작업 + 이 저장소 문서로 핸드오프.

**시스템 정보**:
- macOS 26.5 (25F71), Apple Silicon (T6020/M2 Pro)
- 디스크 1.8T 중 ~887G 가용 (2026-05-16 정리 후)
- 메모리 50% free, swap 0
- sleep 0 (caffeinate 다중 잠금: Trading 자동화 + Capstone VPN)
- Login Items: Macs Fan Control, 카카오톡, Rectangle, Hidden Bar, ZeroTier, Claude, Tailscale, Maccy (RunCat/CheatSheet 제거됨)

**Why**: 향후 맥미니 작업 시 환경 빠르게 재구성 + 사용자 의도 파악.
**How to apply**: 시스템 작업/진단 시 이 메모리 참조해서 ISP/회선/보안/자동화 컨텍스트 즉시 파악.
