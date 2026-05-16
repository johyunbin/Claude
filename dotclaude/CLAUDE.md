# 글로벌 Claude Code 규칙

모든 프로젝트 공통. 프로젝트별 CLAUDE.md가 우선.

---

## KST 시간 기준 (최우선)

```bash
python3 -c "from datetime import datetime, timezone, timedelta; now=datetime.now(timezone(timedelta(hours=9))); print(now.strftime('%Y-%m-%d %H:%M KST (%A)'))"
```
의심될 때 묻지 말고 시간 먼저 확인.

---

## 세션 시작

1. `git pull --no-rebase origin main`
2. MEMORY.md 참조
3. 모든 명령어 자동 실행 (파괴적 작업만 예외)

## 세션 종료

1. work-log 갱신 (Close 단계)
2. 메모리 업데이트
3. 변경사항 push (명시 요청 시)

---

## 핵심 원칙

- **Plan 먼저, 실행은 그 다음** — 상세: `@~/.claude/rules/pipeline.md`
- **한 세션 = 한 작업** → 끝나면 /clear
- **실질적 가치만** — "있으면 좋겠다" 수준 금지. "내일 실제로 쓰는가?" 기준
- **자기 검증** — 결과물을 직접 확인할 수 있는 수단 제공
- **에러는 스택 트레이스 통째로** — 해석 말고 원문

---

## 규칙 참조

- 작업 파이프라인: `@~/.claude/rules/pipeline.md`
- 관리/정리: `@~/.claude/rules/hygiene.md`
- PC 간 동기화: `@~/.claude/rules/sync.md`
- Git 작업 (push / gh run watch / 비가역): `@~/.claude/rules/git.md`
- 작업 현황: `@~/.claude/work-log.md`
