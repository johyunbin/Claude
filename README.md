# Claude — 멀티머신 작업 허브

hyunbin의 3대 머신(맥미니·맥북·그램) 간 작업을 조율하는 git 동기화 허브.

## 워크플로

1. 한 머신의 Claude 세션이 `tasks/<머신>.md`에 작업 지침을 쓰고 commit + push.
2. 다른 머신은 `git clone`(최초) 또는 `git pull`로 받는다.
3. 그 머신의 **로컬 Claude 세션**이 자기 `tasks/<머신>.md`를 읽고 수행한다.
4. 수행 결과·메모를 같은 문서 "결과" 절에 적고 commit + push → 다른 머신이 pull.

원격제어(RDP 등)는 키 입력이 불안정하다. 각 머신은 자기 위에서 도는 로컬 Claude
세션으로 작업하고, 머신 간에는 **이 저장소의 문서로만** 컨텍스트를 주고받는다.

## 구조

- `context/` — 모든 머신이 공유하는 사실 (머신·네트워크·인프라 스냅샷)
- `tasks/`   — 머신별 작업 지침 (`gram.md`, `macbook.md`, …)

## 저장소

- GitHub: `git@github.com:johyunbin/Claude.git`
- 각 머신 클론 위치: `~/Claude`
- 새 머신/세션 시작: `cd ~ && git clone git@github.com:johyunbin/Claude.git`
  (이미 있으면 `cd ~/Claude && git pull`)

## 규칙

- 작업 전 `git pull`, 작업 후 `git commit && git push`.
- 큰 변경은 작은 커밋으로. 커밋 메시지에 어떤 머신·세션인지 명시.
- 비밀번호·키 등 민감정보는 이 저장소(공개 가능)에 쓰지 않는다.
