# Git 작업 룰

전역 룰. 모든 프로젝트 공통.

## Push 룰
- **명시 요청 시만 push** — "push 해줘" / "올려줘" / "ㄱㄱ push" 등
- "커밋 해줘" 만 들어왔으면 commit 까지만, push X
- 사용자 원칙: "push 명시 요청 시만"
- main 브랜치 직접 작업 (Trading) — feature branch 강제 X (사용자 워크플로우)

## 🚨 Push 후 의무 절차 (5/8 추가 룰)
- **`git push` 후 `gh run watch` 의무**
- **이유**: 5/6 commit `8abab05` 부터 CI 5건 누적 failure 였으나 macOS local pytest 1776 pass 만으로 검증해서 미인지 발현 (5/8 작업 중 발견 → fix 11→0)
- 절차:
  ```bash
  git push origin main
  gh run watch  # latest run, 완료까지 대기
  # FAILURE 시 즉시 fix → 새 commit (amend X)
  ```
- 여러 commit 연속 push 시 마지막 push 후 한 번 watch (각 commit 마다 X)

## 비가역 작업 룰
- **사전 dry-run + 샘플 승인 의무**
- 비가역 = 데이터 손실 가능: `git push --force` / `git reset --hard` / `rm -rf` / DB DROP / migration
- 예외: 사용자 사전 위임 ("ㄱㄱ" / "전부 진행" / "전권 위임") — 다만 위임 범위 명확히 기록 + 결과 보고
- 위임 범위는 해당 메시지 scope 까지 — 다른 contexts 로 자동 확장 X

## 커밋 정책
- **새 커밋 선호** — `--amend` 는 사용자 명시 요청 시만
- **훅/서명 우회 금지** (`--no-verify`, `--no-gpg-sign`) — 사용자 명시 요청 시만 (훅 실패 시 근본 원인 fix 우선)
- **HEREDOC 으로 커밋 메시지 전달** (이모지 / 다중 줄 안전):
  ```bash
  git commit -m "$(cat <<'EOF'
  Commit message here.

  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
  EOF
  )"
  ```
- pre-commit 훅 실패 시: 새 commit 만들어 fix (amend X — 훅 실패 시 commit 자체가 없어서 amend 가 이전 commit 수정)

## CI 영구 교훈 (5/8 commit chain `70718ea` → `18f7ab2`)
1. **Python default 인자 evaluated-at-def-time** → monkeypatch 무효, 호출 시 명시 전달
2. **macOS BSD vs Linux GNU stat** `-f` 정반대 (BSD format / GNU filesystem). cross-platform: GNU `-c %s` 우선 + BSD `-f %z` fallback
3. **macOS 전용 script 테스트는 pytestmark skipif** — hardcode 경로 / iCloud / launchctl 의존 시
4. **dict return path 일관성** — early return 분기마다 모든 키 default 포함 (KeyError 방지)
5. **Tier 1 정리 부작용** — 디스크 정리 후 SKIP path 진입하는 테스트 robust 화

## 안전 룰
- **main 직접 작업 시** — `git status` 먼저 (다른 세션 commit / untracked 확인)
- **다른 세션 작업 영역 침범 금지** (병렬 세션 운영 시 영역 분리 필수)
- **gpg / signing 우회** — 사용자 명시 요청 시만
- **force push to main/master** — 경고 후 사용자 재확인

## 관련 룰
- 동기화: `~/.claude/rules/sync.md`
- 작업 파이프라인: `~/.claude/rules/pipeline.md`
- 메모리/위생: `~/.claude/rules/hygiene.md`
