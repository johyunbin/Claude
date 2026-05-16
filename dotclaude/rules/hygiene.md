# Hygiene Rules

정보의 생명주기와 관리 체계.

## 정보 계층

```
CLAUDE.md          라우팅만. "이런 규칙이 있다" → @참조
  ↓
rules/*.md         변하지 않는 규칙 (pipeline, hygiene)
  ↓
work-log.md        진행 중/완료/보류 작업 현황표
  ↓
memory/*.md        다음 세션 필요 정보만
  ↓
memory/archive/    폐기된 메모리
```

위로 갈수록 안정적, 아래로 갈수록 유동적.

## 메모리 생명주기

```
생성 → 갱신 → 비활성 → 아카이브 or 삭제
```

| 상태 | 기준 | 조치 |
|------|------|------|
| 활성 | 최근 2주 내 참조됨 | 유지 |
| 비활성 | 2주+ 미참조 | SessionStart 시 경고, 갱신 or 아카이브 판단 |
| 아카이브 | 필요 없지만 이력 가치 있음 | memory/archive/로 이동, MEMORY.md에서 제거 |
| 삭제 | 이력 가치도 없음 | 삭제 |

MEMORY.md 규칙:
- 50줄 이내 유지
- 아카이브 항목은 제거하되, archive/ 포인터 한 줄만 유지
- 신규 작성 시 "3세션 뒤에도 필요한가?" 자문

## work-log

위치: `~/.claude/work-log.md` (전역, 모든 프로젝트 공통)

- Close 시 Active→Completed + 회고 1줄
- 중단 시 Active→Parked + 재개 조건
- Completed 항목은 한 달 뒤 정리

## 고아 관리

워크트리:
- 머지된 브랜치 → Close에서 삭제
- SessionStart 훅에서 감지: 워크트리 수 + 브랜치 상태
- 1주+ 방치 → 경고

stale 메모리:
- SessionStart 시 mtime 2주+ 파일 감지 → 경고

## PC 간 동기화

상세: `@~/.claude/rules/sync.md`

핵심 4단계:
- **Trading 코드** = `git push/pull origin main`
- **Trading 데이터** = `./src/sync.sh push|pull $OTHER` (`--delete` 기본)
- **.claude** = `rsync --update` 양쪽 2회 (unison 있으면 unison)
- **Capstone** = `git push/pull` (양쪽 SSH 설치) 또는 `rsync --update`

DB 충돌 시 `git checkout --ours trading.db` (맥미니 = DB 마스터)
