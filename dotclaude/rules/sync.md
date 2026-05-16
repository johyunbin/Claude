# PC 간 동기화

전역 룰. Trading + .claude + Capstone 양방향 동기화.

## 변수
- 맥북에서: `OTHER=macmini`
- 맥미니에서: `OTHER=macbook`

## "동기화 해줘" (양방향 완전 동기화)

### 1. Trading 코드 (git 관리)
```bash
cd ~/Trading && git add -A && git commit -m "sync: 설명" && git push origin main
```

### 2. Trading 데이터 (contents/trading.db/states/logs)
sync.sh v2 = `--delete` 기본 + 양방향
```bash
cd ~/Trading && ./src/sync.sh push $OTHER  # 내 PC → 상대, orphan 삭제 포함
```

### 3. .claude (메모리/설정/skills/rules)
unison 양쪽 다 설치돼있으면 unison, 아니면 rsync --update 양쪽 2회.
```bash
rsync -avz --update --exclude='worktrees/' --exclude='__pycache__/' \
  --exclude='statsig/' --exclude='todos/' --exclude='shell-snapshots/' \
  --exclude='plugins/cache/' --exclude='debug/' --exclude='telemetry/' \
  --exclude='session-env/' --exclude='sessions/' --exclude='backups/' \
  --exclude='cache/' --exclude='ide/' --exclude='mcp-needs-auth-cache.json' \
  --exclude='history.jsonl' --exclude='stats-cache.json' \
  --exclude='projects/*--claude-worktrees-*' \
  --exclude='projects/*/*.jsonl' --exclude='projects/*/agent-*.jsonl' \
  ~/.claude/ $OTHER:.claude/
rsync -avz --update --exclude='worktrees/' --exclude='__pycache__/' \
  --exclude='statsig/' --exclude='todos/' --exclude='shell-snapshots/' \
  --exclude='plugins/cache/' --exclude='debug/' --exclude='telemetry/' \
  --exclude='session-env/' --exclude='sessions/' --exclude='backups/' \
  --exclude='cache/' --exclude='ide/' --exclude='mcp-needs-auth-cache.json' \
  --exclude='history.jsonl' --exclude='stats-cache.json' \
  --exclude='projects/*--claude-worktrees-*' \
  --exclude='projects/*/*.jsonl' --exclude='projects/*/agent-*.jsonl' \
  $OTHER:.claude/ ~/.claude/
```

### 4. Capstone (github SSH 양쪽 / 미설치 시 rsync)
```bash
cd ~/Capstone && git add -A && git commit -m "sync: 설명" && git push origin main || \
  rsync -avz --update --exclude='__pycache__/' --exclude='*.pyc' --exclude='node_modules/' \
    ~/Capstone/ $OTHER:Capstone/
```

## "받아줘" (상대 → 내 PC)
```bash
cd ~/Trading && git pull --no-rebase origin main
cd ~/Trading && ./src/sync.sh pull $OTHER  # 상대 → 내 PC, orphan 삭제 포함
cd ~/Capstone && git pull --no-rebase origin main || \
  rsync -avz --update --exclude='__pycache__/' --exclude='*.pyc' --exclude='node_modules/' \
    $OTHER:Capstone/ ~/Capstone/
rsync -avz --update --exclude='worktrees/' --exclude='__pycache__/' \
  --exclude='statsig/' --exclude='todos/' --exclude='shell-snapshots/' \
  --exclude='plugins/cache/' --exclude='debug/' --exclude='telemetry/' \
  --exclude='session-env/' --exclude='sessions/' --exclude='backups/' \
  --exclude='cache/' --exclude='ide/' --exclude='mcp-needs-auth-cache.json' \
  --exclude='history.jsonl' --exclude='stats-cache.json' \
  --exclude='projects/*--claude-worktrees-*' \
  --exclude='projects/*/*.jsonl' --exclude='projects/*/agent-*.jsonl' \
  $OTHER:.claude/ ~/.claude/
```

## SSH / Git 환경
- 맥북 `Host macmini` (192.168.123.105) / 맥미니 `Host macbook` (192.168.0.25)
- Trading: main 브랜치 직접 작업. DB 충돌 시 `git checkout --ours trading.db`
- 맥북 SSH non-interactive PATH: `/opt/homebrew/bin` 수동 지정 필요 (brew/gh/unison)
- 2026-04-21 맥북 unison/github SSH 설정 완료 — 양쪽 모두 git push / unison 가능

## 트러블슈팅
- DB 충돌 → `git checkout --ours trading.db` (DB 마스터 = 맥미니, 맥북 동기화)
- SSH PATH 문제 (gh/brew not found) → `/opt/homebrew/bin` 수동 지정
- rsync 한쪽 실패 → 양쪽 rsync --update 2회 (unison 미설치 시)

## 🚨 mv 한 file 양방향 sync 부작용 (5/9 발견 — 영구 룰)

**증상**: 한쪽 PC 에서 archive 로 mv 한 file 들이 양방향 rsync 후 **활성 디렉토리에 다시 복원됨**.

**원인**: `rsync --update` 는 mtime 비교 — 한쪽 부재 = newer file 로 해석되어 다른 쪽 사본 받아옴. mv 가 mtime 정보 전달 X.

**5/9 발현 사례**: Trading memory 43 file mv (맥미니 활성 → archive) 후 양방향 sync → 맥북 활성에 그대로 있던 43 file 이 맥미니로 받아짐 → 활성 86 (43 정상 + 43 복원).

**해결 (영구 절차)**:
1. 한쪽 PC 에서 mv 진행
2. push 부터 (한쪽 → 다른쪽, archive 디렉토리 동기화)
3. **다른 쪽 PC 에서 즉시 동일 mv 진행** (SSH 또는 직접)
4. 그 다음 양방향 sync (이번에는 양쪽 mv 완료 상태라 부작용 X)

**또는** `--delete` 추가 — 한쪽 부재 = 다른 쪽도 삭제. 단, 의도한 file 도 삭제 위험 있어 **신중**.

**같은 룰 적용 영역**: `plans/`, `memory/`, `docs/handoff/archive/` 등 모든 mv 작업.
