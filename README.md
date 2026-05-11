# jps-dev-skills-installer

Claude Code 개발 도구 셋업 인스톨러. gstack의 의사결정 스킬과 Superpowers의 실행 스킬만
골라 미니멀하게 설치합니다.

명지전문대학 정보통신공학과 학생들과 본인 연구실의 **개발 작업용** 표준 셋업으로
만들어졌으며, 두 프레임워크를 통째로 깔았을 때 발생하는 의사결정 레이어 중복과
토큰 폭증을 피하면서 양쪽의 핵심 강점만 가져오는 것이 목표입니다.

이 인스톨러는 `jps-*-skills-installer` 시리즈 중 **개발(dev) 용도**입니다.
다른 목적(연구, 교육, 글쓰기 등)에 맞춘 별도 인스톨러는 별도 레포로 관리됩니다.

## 무엇이 설치되나

기본 7개 스킬이 `~/.claude/skills/` 아래에 설치됩니다.

| 레이어 | 스킬 | 출처 | 역할 |
|---|---|---|---|
| 의사결정 | `office-hours` | gstack | YC 스타일 6가지 forcing question으로 코드 작성 전 제품 방향을 재정의 |
| 의사결정 | `plan-ceo-review` | gstack | 요청 안에 숨은 10-star 제품을 찾는 4가지 모드(Expansion / Selective / Hold / Reduction) |
| 의사결정 | `plan-eng-review` | gstack | 아키텍처, 데이터 흐름, 다이어그램, 엣지 케이스, 테스트 매트릭스 잠금 |
| 실행 | `writing-plans` | Superpowers | 계획을 2~5분 단위 한입 크기 태스크로 분해, DRY/YAGNI/TDD 강제 |
| 실행 | `executing-plans` | Superpowers | 작성된 계획을 비판적 리뷰 후 단계별 실행, 막히면 추측 대신 명료화 요청 |
| 실행 | `test-driven-development` | Superpowers | RED-GREEN-REFACTOR 강제, 테스트 이전 작성 코드는 삭제 |
| 실행 | `verification-before-completion` | Superpowers | "이 코드는 동작할 겁니다" 차단, 빌드/테스트/린트 출력 확인 후에만 완료 선언 |

옵션 플래그로 다음을 추가할 수 있습니다.

| 레이어 | 스킬 | 출처 | 활성화 플래그 | 역할 |
|---|---|---|---|---|
| 디버깅 | `systematic-debugging` | Superpowers | `--with-debug` | 4단계 root-cause 프로세스로 복잡한 버그 추적 |
| 리뷰 | `review` | gstack | `--with-review` | gstack 스타일 코드 리뷰 자동화 |
| 리뷰 | `requesting-code-review` | Superpowers | `--with-review` | Superpowers TDD 흐름과 통합된 리뷰 요청 |

## 무엇이 빠졌나 (의도적)

다음은 일부러 기본에서 제외했습니다.

- gstack의 페르소나 풀세트(`/qa`, `/ship`, `/design-*`, `/codex` 등) — 토큰 폭증의 주요 원인. 필요하면 `_gstack-source/` 안에서 골라 링크 가능
- gstack의 브라우저 데몬, telemetry, brain-sync — bun/Node.js 빌드 의존성 회피
- Superpowers의 `brainstorming` — gstack 의사결정 레이어와 기능 중복
- Superpowers의 `using-git-worktrees`, `subagent-driven-development` — 단일 사용자 환경에서는 옵션

위 옵션 확장 표에 있는 항목은 플래그로 쉽게 추가할 수 있습니다.

## 사전 요구사항

- Git
- bash (macOS 기본 bash 3.2도 지원, Linux는 4.x 이상)
- Claude Code 설치 및 1회 이상 실행 (`~/.claude/` 디렉토리 생성을 위해)

bun, Node.js, Python 등은 **필요하지 않습니다**. 이게 풀세트 설치와 가장 큰 차이입니다.

## 설치

```bash
# 스크립트 다운로드 후
chmod +x install-dev-skills.sh
./install-dev-skills.sh
```

또는 dry-run으로 무엇이 일어날지 먼저 확인:

```bash
./install-dev-skills.sh --dry-run
```

설치가 끝나면 Claude Code를 재시작하세요. 사용자 스킬 디렉토리는 세션 시작 시점에 스캔됩니다.

## 옵션

### 기본 플래그

| 플래그 | 동작 |
|---|---|
| (없음) | 기본 위치(`~/.claude/skills`)에 7개 스킬 설치. 기존 항목과 충돌하면 중단 |
| `--update` | 기존 설치 덮어쓰기. 두 레포의 최신 main 브랜치를 다시 가져옴 |
| `--dry-run` | 실제 변경 없이 어떤 동작이 일어날지 출력만 |
| `--remove` | 설치된 모든 스킬과 gstack 헬퍼 자산 제거 |
| `--target DIR` | 설치 위치 변경. 테스트나 격리된 환경에서 유용 |
| `-h`, `--help` | 사용법 표시 |

### 옵션 확장 플래그

기본 7개 스킬에 추가로 디버깅 또는 코드 리뷰 스킬을 설치합니다.

| 플래그 | 추가되는 스킬 | 용도 |
|---|---|---|
| `--with-debug` | `systematic-debugging` (Superpowers) | 4단계 root-cause 프로세스로 복잡한 버그를 추적. 증상 격리 → 가설 수립 → 검증 → 수정 |
| `--with-review` | `review` (gstack), `requesting-code-review` (Superpowers) | PR 머지 전 게이트로 코드 리뷰 자동화 |
| `--with-all` | 위 두 옵션 모두 | 본인 연구실용 풀세트 |

**사용 예시**

```bash
# 학생용 강의 기본 셋업 (가벼움, 7개 스킬)
./install-dev-skills.sh

# 디버깅이 잦은 본인 연구 환경 (8개 스킬)
./install-dev-skills.sh --with-debug

# 코드 리뷰까지 자동화하고 싶을 때 (9개 스킬)
./install-dev-skills.sh --with-review

# 본인 연구실용 풀세트 (10개 스킬)
./install-dev-skills.sh --with-all
```

### 어떤 작업에 어떤 스킬이 트리거되나

기본 7개 셋업에서:

| 작업 | 트리거할 명령 | 자동 동반 스킬 |
|---|---|---|
| 명확한 버그 즉시 수정 | (자연어 요청) | TDD, verification |
| 원인 불명 버그 추적 | `/plan-eng-review` | writing-plans → executing-plans → TDD → verification |
| 작은 UX 개선 | (자연어 요청) | TDD, verification |
| 기존 기능 리팩토링 | `writing-plans` 호출 | executing-plans → TDD → verification |
| 새 기능 추가 (작음) | `/plan-eng-review` | writing-plans → executing-plans → TDD → verification |
| 새 기능 추가 (큼) | `/office-hours`부터 풀 흐름 | 전체 7개 |
| 성능 최적화 | `/plan-eng-review` | TDD로 벤치마크 → executing-plans |

`--with-debug`를 켜면 "원인 불명 버그 추적" 단계에서 `systematic-debugging`이 우선 트리거되어 root-cause 분석이 강화됩니다.
`--with-review`를 켜면 모든 흐름의 끝(verification 이후)에 `/review` 또는 `requesting-code-review`가 추가로 동반됩니다.

## 동작 방식

스크립트의 핵심 설계 결정은 두 가지입니다.

**gstack은 심볼릭 링크로 처리합니다.** 레포 전체를 `~/.claude/skills/_gstack-source/`로 클론한 뒤, 의사결정 스킬 3종만 `~/.claude/skills/<name>/`으로 링크합니다. 이렇게 하는 이유는 gstack의 SKILL.md가 자기 레포의 `bin/` 아래 헬퍼 스크립트(`gstack-slug`, `gstack-question-log` 등)를 절대 경로로 호출하기 때문입니다. 폴더만 떼어서 복사하면 그 호출이 깨집니다. 다만 gstack의 `setup` 스크립트는 **실행하지 않으므로** 브라우저 빌드와 telemetry 가입은 일어나지 않습니다.

**Superpowers는 단순 복사로 처리합니다.** 의존하는 헬퍼 자산이 거의 없고, 메인 레포(`obra/superpowers`)와 스킬 레포(`obra/superpowers-skills`)가 분리된 상태라 평면 구조와 카테고리 구조 둘 다 자동 탐색합니다.

설치 후 의존성 점검 단계가 자동으로 돌면서, 각 SKILL.md에서 미설치 형제 명령을 언급하는 부분을 보고합니다. 이 메시지는 에러가 아닙니다. 예를 들어 `plan-eng-review`는 본문에서 "다음으로 `/qa`를 돌려라"고 안내하는데, `/qa`를 설치하지 않았으니 그 추천이 자동으로 이어지지 않을 뿐 스킬 자체 동작은 정상입니다.

## 설치 후 권장 작업

다음을 프로젝트의 `CLAUDE.md` 또는 `~/.claude/CLAUDE.md`에 추가하시면 Claude가 더 안정적으로 스킬을 인식합니다.

```markdown
## Available skills

이 프로젝트는 다음 7개 스킬을 사용합니다.

의사결정 (gstack):
- /office-hours       - 코드 작성 전 제품 방향 재정의
- /plan-ceo-review    - 10-star 제품 비전 도출
- /plan-eng-review    - 아키텍처와 테스트 매트릭스 잠금

실행 (Superpowers):
- writing-plans                  - 한입 크기 태스크 분해
- executing-plans                - 단계별 실행
- test-driven-development        - RED-GREEN-REFACTOR 강제
- verification-before-completion - 증거 없는 "완료" 차단
```

## 권장 워크플로우

새 기능 또는 새 프로젝트 시작 시:

```
/office-hours                        ← 진짜 만들 것 재정의
   ↓
/plan-ceo-review                     ← 비전 / 범위 결정
   ↓
/plan-eng-review                     ← 기술 설계 잠금
   ↓
writing-plans 스킬을 트리거         ← 태스크 분해
   ↓
executing-plans + TDD 스킬 트리거    ← 실제 구현
   ↓
verification-before-completion       ← 증거로 완료 확인
```

스킬은 명시적 슬래시 명령(`/office-hours`)이거나 자연어 트리거에 의해 자동 활성화됩니다. 작은 작업에 의식이 과하다 싶으면 "이건 한 줄 수정이니까 brainstorming 건너뛰어"처럼 명시적으로 우회할 수 있습니다.

## 트러블슈팅

**스킬이 안 보입니다.**
Claude Code를 완전히 재시작하셨는지 확인하세요. `/plugin list`나 `/help`로 등록 여부를 확인할 수 있습니다. 그래도 안 보이면 `~/.claude/CLAUDE.md`에 위 "Available skills" 블록을 추가하세요.

**gstack 스킬이 동작 중에 헬퍼 스크립트를 못 찾는다는 에러를 냅니다.**
`~/.claude/skills/_gstack-source/bin/`이 비어있을 가능성이 큽니다. `--update`로 다시 받으시면 해결됩니다.

**Superpowers 스킬이 설치되지 않았습니다.**
의존성 점검 출력에서 "Superpowers에 X 스킬을 찾지 못했습니다 — 건너뜀" 경고가 있다면, 스킬 레포 구조가 또 바뀐 것일 수 있습니다. `--dry-run`을 켜고 임시 작업 디렉토리에서 직접 `find skills -name "X"`로 위치를 확인해보세요.

**한 번에 너무 많은 의존성 경고가 출력됩니다.**
정상입니다. gstack 의사결정 스킬은 본문에서 워크플로우의 다음 단계를 명시적으로 추천하는데, 그 추천 명령들이 미설치 상태이기 때문입니다. 무시하셔도 됩니다.

## 제거

```bash
./install-dev-skills.sh --remove
```

이 명령은 7개 스킬 폴더와 `_gstack-source/` 헬퍼 디렉토리를 삭제합니다. `CLAUDE.md`에 직접 추가하신 스킬 목록은 자동으로 정리되지 않으니 수동으로 지워주세요.

## 비공식 도구 안내 (Unofficial Helper)

이 프로젝트는 **gstack 또는 Superpowers의 공식 도구가 아닙니다.**
Y Combinator, Garry Tan, Jesse Vincent, Prime Radiant, Anthropic 어느 쪽과도 제휴 관계가 없으며,
두 프로젝트의 추천을 받지도 않았습니다.

저는 명지전문대학 정보통신공학과 교수로서 학생들에게 일관된 셋업을 배포하기 위해
이 미니멀 인스톨러를 작성했습니다. 두 원본 프로젝트의 풀세트가 학생 환경에 과하다고 판단하여
의사결정 레이어와 실행 레이어만 추출한 cherry-pick 셋업입니다.

## 라이선스

이 인스톨러 스크립트(`install-dev-skills.sh`)와 본 README는
MIT License 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

### 재배포가 아니라 다운로더입니다

이 스크립트는 두 원본 프로젝트의 코드를 본 레포에 포함시키지 않습니다.
실행 시 사용자 머신에서 `git clone`을 트리거하여 원본 레포에서 직접 가져옵니다.
따라서 본 레포 자체에는 두 프로젝트의 코드가 vendored되어 있지 않습니다.

다운로드된 콘텐츠는 각 원본 프로젝트의 라이선스를 따릅니다.

| 프로젝트 | 라이선스 | 저작권 | URL |
|---|---|---|---|
| gstack | MIT | Garry Tan and contributors | https://github.com/garrytan/gstack |
| superpowers | MIT | Jesse Vincent and contributors | https://github.com/obra/superpowers |
| superpowers-skills | MIT | Jesse Vincent and contributors | https://github.com/obra/superpowers-skills |

### 만약 이 셋업을 fork해서 직접 수정/배포하실 경우

스크립트나 README는 자유롭게 수정/재배포 가능합니다(MIT 조건만 유지).
다만 두 원본 프로젝트의 SKILL.md를 직접 수정해서 vendored 형태로 본인 레포에 포함시키시려면,
그 시점부터는 MIT 의무가 추가로 발생합니다.

- 수정된 파일에 원본 저작권 표시 유지
- 원본 LICENSE 사본 동봉
- 변경 내역 명시(권장)

현재 인스톨러는 이런 vendored 패턴을 쓰지 않으므로 해당 의무가 적용되지 않습니다.

## 변경 이력

스크립트가 가져오는 두 레포는 활발히 개발 중이라 디렉토리 구조나 SKILL.md 내용이 바뀔 수 있습니다. 문제가 생기면 다음을 확인하세요.

1. `--update`로 최신 main을 받아 다시 시도
2. gstack 레포의 디렉토리 이름이 바뀌었는지 확인 (`https://github.com/garrytan/gstack` 루트)
3. Superpowers 스킬 레포의 카테고리 구조가 바뀌었는지 확인 (`https://github.com/obra/superpowers-skills/tree/main/skills`)

스크립트 상단의 `GSTACK_SKILLS`와 `SUPERPOWERS_SKILLS` 배열에 다른 스킬을 추가하거나 빼서 셋업을 커스터마이즈할 수 있습니다.
