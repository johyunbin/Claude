# dotclaude — 공유 ~/.claude 설정 (git 동기화)

3대 머신이 공유하는 `~/.claude` 설정의 스냅샷. 그램(Windows)은 SSH/rsync가 없어
맥끼리 쓰는 rsync 동기화가 불가능하므로, **git이 그램까지 닿는 유일한 공통 채널**이다.

## 내용

- `CLAUDE.md` — 전역 Claude 지침
- `rules/` — pipeline·hygiene·git·sync 규칙
- `memory/` — 메모리 인덱스(MEMORY.md) + 항목 4개
- `work-log.md` — 작업 현황표

## ⚠ 비밀번호 가림 (sanitized)

이 저장소는 공개 가능 → 평문 비밀번호 금지.
`work-log.md` 와 `memory/infrastructure_macmini.md` 의 비밀번호는 `<REDACTED-...>`
플레이스홀더로 치환돼 있다. 실제 값은 이 저장소에 없다.

## 그램에서 적용 (PowerShell)

`~/CLAUDE` 저장소를 `git pull` 한 뒤:

```powershell
$src = "$HOME\CLAUDE\dotclaude"; $dst = "$HOME\.claude"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item -Force "$src\CLAUDE.md","$src\work-log.md" $dst
Copy-Item -Recurse -Force "$src\rules","$src\memory" $dst
```

## 주의 / 갱신

- **맥(맥미니·맥북)은 이 폴더를 `~/.claude`에 덮어쓰지 말 것.** 맥은 rsync로 실제
  (비밀번호 포함) 본을 동기화한다. 여기 `work-log.md` 등은 sanitized 본이라
  덮어쓰면 비밀번호가 사라진다. 이 폴더는 그램(rsync 불가 머신)용 채널이다.
- 공유 설정이 바뀌면: `~/.claude`의 해당 파일을 이 폴더에 다시 복사 → **비밀번호
  재치환** → commit·push. 현재는 수동 스냅샷 방식(자동 동기화 아님).
- 커밋 전 항상 비밀번호 스캔할 것 (라우터/WiFi pw, 서버 pw 등).
