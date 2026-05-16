---
name: 유니콘 Pro 정체 — HTTPS SNI 차단 우회 도구
description: UnicornProMac은 한국 보안/공인인증 SW가 아니라 사용자가 의도적으로 설치한 HTTPS SNI 차단 우회 도구. 한국 보안 SW와 함께 unload하지 말 것.
type: feedback
---

**유니콘 Pro (UnicornProMac.app, com.unicornsoft.unicornproformac)는 한국 보안 SW가 아니다.**

LG U+ 등 한국 ISP의 HTTPS SNI 차단 / DPI 검열을 우회하는 도구. 차단 사이트 / 해외 게임 / 일부 서비스 접근을 위해 사용자가 **의도적으로 설치**.

기능:
- DNS 설정 (Cloudflare 1.1.1.1 등)
- 광고 차단 (필터 30개, 한국어/일본어 포함)
- HTTPS 필터링 (Unicorn CA 인증서 시스템 설치, 만료 2052-03)
- DPI 보호 (Deep Packet Inspection 우회)
- 자동 시작 (로그인 시)

**Why**: 2026-05-16 첫 작업 때 한국 보안 SW (AhnLab/Raon/Wizvera/MagicLine 등)와 같은 카테고리로 잘못 분류하고 plist를 .disabled 처리함. 사용자가 "유니콘 프로 사용 중"이라 알려주면서 발견. 그 후 plist 복구함. UnicornPro는 자체 watchdog으로 plist 재생성 메커니즘 있음.

**How to apply**: 한국 보안/공인인증 SW 정리할 때 유니콘 Pro는 **제외**. 사용자가 차단 우회 위해 의도적으로 켜놓은 것이므로 끄지 말 것. 만약 사용자가 명시적으로 "끄자"고 하면 그때 처리.

**관련 SW (실제로 한국 보안 SW — 인터넷뱅킹/공공기관용)**:
- AhnLab ASTx (astxAgent, astxd)
- Raon TouchEn nxKey (TEK_Daemon, TEK_UserAgent)
- Wizvera (Delfino, Veraport)
- DreamSecurity MagicLine4NX
- SoftForum AnySign
- Interezen NWSDaemon

이들은 "평소 unload + 은행/공공 쓸 때 수동 시작" 패턴 (사용자 선호, 2026-05-16 확인).
