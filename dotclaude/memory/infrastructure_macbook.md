---
name: 맥북 인프라 환경 (2026-05-16 기준)
description: MacBook Pro 14 시스템·네트워크·보안 상태 스냅샷. 맥북 세션 작업 시 환경 빠르게 파악.
type: project
---

**머신**: MacBook Pro 14, macOS 26.5 (25F71), 24GB RAM, Apple Silicon.
- 고정 IP 192.168.0.25 (AX3000BCM 805망 DHCP 예약). Tailscale 100.127.92.10.
- **Wi-Fi 전용** — 내장 이더넷 없음, 어댑터 미연결.

**네트워크** (2026-05-16 맥북 세션 점검):
- Wi-Fi en0: 5GHz ch36 / 160MHz / 802.11ax / WPA2-WPA3, 신호 -48dBm, Tx 1700~1800Mbps. 클라이언트 쪽 이미 최적.
- DNS: Wi-Fi 서비스 수동 1.1.1.1/1.0.0.1/8.8.8.8/8.8.4.4. Tailscale MagicDNS(100.100.100.100) 활성.
- **회선 이슈는 공유기 레벨** — 버퍼블로트(부하 시 HTTP 왕복 632ms) + Wi-Fi 첫 홉 지터. 맥북 클라이언트는 손댈 것 없음. 공유기 QoS·5GHz폭(160→80MHz) 개선은 `~/Claude/tasks/macmini.md`로 핸드오프됨.

**한국 보안 SW** (2026-05-16 비활성): plist 9개 `.disabled` 처리.
- TouchEn nxKey ×3, MagicLine4NX, Delfino, nProtect, AnySign, Kollus, CrossEX
- 인터넷뱅킹·인강 사용 시 수동 시작 패턴.
- 재활성화: `sudo mv <plist>.disabled <plist>` 후 재부팅.
- 백업: `~/.claude/backups/korea_security_macbook_20260516_1607/`
- ※ UnicornProMac은 SNI 우회 도구(보안 SW 아님) — 제외, 손대지 않음.

**멀티머신 허브**: `~/Claude` git 저장소(github.com:johyunbin/Claude)가 맥미니·맥북·그램 작업 조율 허브. 맥북 작업 결과는 `tasks/macbook.md`.

**Why**: 향후 맥북 세션 시 환경 빠르게 재구성 + 중복 작업 회피.
**How to apply**: 맥북 시스템·네트워크 작업 시 이 메모리 참조 — 한국 SW 이미 비활성·네트워크 클라이언트 최적 상태임을 알고 재진단 생략.
