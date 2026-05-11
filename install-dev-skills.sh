#!/usr/bin/env bash
#
# install-dev-skills.sh (jps-dev-skills-installer)
#
# gstack의 의사결정 스킬(office-hours, plan-ceo-review, plan-eng-review)과
# Superpowers의 실행 스킬(writing-plans, executing-plans,
# test-driven-development, verification-before-completion)만 골라
# Claude Code의 사용자 스킬 디렉토리(~/.claude/skills)에 설치합니다.
#
# - gstack의 브라우저 데몬, telemetry, brain-sync 같은 무거운 보조 도구는
#   설치하지 않습니다(bun/Node 빌드 회피).
# - Superpowers의 기본 페르소나(brainstorming, requesting-code-review 등)도
#   설치하지 않습니다(중복 의사결정 레이어 회피).
# - 두 레포의 SKILL.md 안에서 자기 레포의 헬퍼 스크립트를 절대 경로로
#   호출하는 부분이 있는데, 그 경로가 깨지지 않도록 원본 디렉토리를
#   보존하고 SKILL.md만 심볼릭 링크하는 방식을 씁니다.
#
# 동작 방식:
#   1) gstack: git clone --depth 1 https://github.com/garrytan/gstack.git
#              ~/.claude/skills/_gstack-source
#      → bin/, lib/ 등 헬퍼 자산이 모두 함께 들어옵니다.
#      → 7개 슬래시 명령에 해당하는 스킬 폴더만 ~/.claude/skills/<name>/에
#        심볼릭 링크합니다. 단, gstack 폴더 자체는 setup을 돌리지 않으므로
#        브라우저/텔레메트리 컴포넌트는 비활성 상태로 남습니다.
#   2) Superpowers: 별도 스킬 레포(obra/superpowers-skills)를 클론한 뒤,
#      평면(skills/<name>) 또는 카테고리(skills/<category>/<name>) 구조 중
#      어느 쪽에서든 4개 스킬을 찾아 ~/.claude/skills/<name>/으로 복사합니다.
#
# 사용법:
#   bash install-dev-skills.sh                # 기본 7개 스킬 설치
#   bash install-dev-skills.sh --dry-run      # 변경 없이 시뮬레이션
#   bash install-dev-skills.sh --update       # 기존 설치 업데이트
#   bash install-dev-skills.sh --remove       # 설치본 제거
#   bash install-dev-skills.sh --target DIR   # 설치 위치 변경
#
# 옵션 확장 플래그:
#   --with-debug    Superpowers의 systematic-debugging 추가
#                   (4단계 root-cause 프로세스로 복잡한 버그 추적)
#   --with-review   gstack의 /review + Superpowers의 requesting-code-review 추가
#                   (PR 머지 전 게이트로 사용)
#   --with-all      위 두 옵션을 모두 켭니다
#
# 사용 예시:
#   # 학생용 강의 기본 셋업 (가벼움)
#   bash install-dev-skills.sh
#
#   # 연구실 본인 작업용 풀세트
#   bash install-dev-skills.sh --with-all
#
#   # 디버깅만 강화하고 싶을 때
#   bash install-dev-skills.sh --with-debug
#
# 동작 확인 환경: macOS(Apple Silicon, bash 3.2 호환), Ubuntu 22.04/24.04

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────
# 설정
# ────────────────────────────────────────────────────────────────────────

GSTACK_REPO="https://github.com/garrytan/gstack.git"
SUPERPOWERS_SKILLS_REPO="https://github.com/obra/superpowers-skills.git"
SUPERPOWERS_MAIN_REPO="https://github.com/obra/superpowers.git"

# 기본 스킬 목록 (의사결정 + 실행)
GSTACK_SKILLS=(
  "office-hours"
  "plan-ceo-review"
  "plan-eng-review"
)

SUPERPOWERS_SKILLS=(
  "writing-plans"
  "executing-plans"
  "test-driven-development"
  "verification-before-completion"
)

# --with-debug 옵션 추가 스킬 (체계적 디버깅)
DEBUG_GSTACK_SKILLS=()
DEBUG_SUPERPOWERS_SKILLS=(
  "systematic-debugging"
)

# --with-review 옵션 추가 스킬 (코드 리뷰 자동화)
REVIEW_GSTACK_SKILLS=(
  "review"
)
REVIEW_SUPERPOWERS_SKILLS=(
  "requesting-code-review"
)

# 기본 설치 위치
TARGET_DIR="${HOME}/.claude/skills"
GSTACK_SOURCE_NAME="_gstack-source"

# 모드 플래그
DRY_RUN=0
UPDATE=0
REMOVE=0
WITH_DEBUG=0
WITH_REVIEW=0
WITH_ALL=0

# ────────────────────────────────────────────────────────────────────────
# 유틸
# ────────────────────────────────────────────────────────────────────────

log()  { printf '[install] %s\n' "$*"; }
warn() { printf '[install] WARN: %s\n' "$*" >&2; }
err()  { printf '[install] ERROR: %s\n' "$*" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  (dry-run) %s\n' "$*"
  else
    eval "$@"
  fi
}

# 인자 파싱
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)     DRY_RUN=1; shift ;;
    --update)      UPDATE=1; shift ;;
    --remove)      REMOVE=1; shift ;;
    --with-debug)  WITH_DEBUG=1; shift ;;
    --with-review) WITH_REVIEW=1; shift ;;
    --with-all)    WITH_ALL=1; shift ;;
    --target)
      [ -n "${2:-}" ] || err "--target에 디렉토리 인자가 필요합니다"
      TARGET_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '1,50p' "$0"; exit 0 ;;
    *) err "알 수 없는 옵션: $1" ;;
  esac
done

# --with-all은 다른 with-* 플래그를 모두 켭니다
if [ "$WITH_ALL" -eq 1 ]; then
  WITH_DEBUG=1
  WITH_REVIEW=1
fi

# 옵션 플래그에 따라 스킬 배열 확장
# 주의: set -u 환경에서 빈 배열 확장이 오류를 낼 수 있어 길이 체크 후 확장
if [ "$WITH_DEBUG" -eq 1 ]; then
  if [ "${#DEBUG_GSTACK_SKILLS[@]}" -gt 0 ]; then
    GSTACK_SKILLS+=("${DEBUG_GSTACK_SKILLS[@]}")
  fi
  if [ "${#DEBUG_SUPERPOWERS_SKILLS[@]}" -gt 0 ]; then
    SUPERPOWERS_SKILLS+=("${DEBUG_SUPERPOWERS_SKILLS[@]}")
  fi
fi
if [ "$WITH_REVIEW" -eq 1 ]; then
  if [ "${#REVIEW_GSTACK_SKILLS[@]}" -gt 0 ]; then
    GSTACK_SKILLS+=("${REVIEW_GSTACK_SKILLS[@]}")
  fi
  if [ "${#REVIEW_SUPERPOWERS_SKILLS[@]}" -gt 0 ]; then
    SUPERPOWERS_SKILLS+=("${REVIEW_SUPERPOWERS_SKILLS[@]}")
  fi
fi

command -v git >/dev/null 2>&1 || err "git이 설치되어 있어야 합니다"

# ────────────────────────────────────────────────────────────────────────
# 제거 모드
# ────────────────────────────────────────────────────────────────────────

if [ "$REMOVE" -eq 1 ]; then
  log "제거 모드: $TARGET_DIR 안에서 jps-skill-installer가 설치한 스킬을 제거합니다"

  # 제거 시점에는 사용자가 어떤 옵션으로 설치했는지 모르므로,
  # 가능한 모든 스킬(기본 + 모든 옵션 확장)을 후보로 두고 시도합니다.
  # bash 3.2 set -u 환경에서 빈 배열 확장 오류를 피하기 위해
  # 빈 배열은 조건부로만 추가합니다.
  ALL_REMOVABLE=("${GSTACK_SKILLS[@]}" "${SUPERPOWERS_SKILLS[@]}")
  if [ "${#DEBUG_GSTACK_SKILLS[@]}" -gt 0 ]; then
    ALL_REMOVABLE+=("${DEBUG_GSTACK_SKILLS[@]}")
  fi
  if [ "${#DEBUG_SUPERPOWERS_SKILLS[@]}" -gt 0 ]; then
    ALL_REMOVABLE+=("${DEBUG_SUPERPOWERS_SKILLS[@]}")
  fi
  if [ "${#REVIEW_GSTACK_SKILLS[@]}" -gt 0 ]; then
    ALL_REMOVABLE+=("${REVIEW_GSTACK_SKILLS[@]}")
  fi
  if [ "${#REVIEW_SUPERPOWERS_SKILLS[@]}" -gt 0 ]; then
    ALL_REMOVABLE+=("${REVIEW_SUPERPOWERS_SKILLS[@]}")
  fi

  REMOVED_COUNT=0
  for s in "${ALL_REMOVABLE[@]}"; do
    if [ -e "$TARGET_DIR/$s" ] || [ -L "$TARGET_DIR/$s" ]; then
      log "  제거: $TARGET_DIR/$s"
      run "rm -rf '$TARGET_DIR/$s'"
      REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
  done

  if [ -d "$TARGET_DIR/$GSTACK_SOURCE_NAME" ]; then
    log "  제거: $TARGET_DIR/$GSTACK_SOURCE_NAME (gstack 헬퍼 자산)"
    run "rm -rf '$TARGET_DIR/$GSTACK_SOURCE_NAME'"
  fi

  log "총 $REMOVED_COUNT개 스킬 제거 완료. CLAUDE.md에 추가하셨던 스킬 목록도 직접 정리해 주세요."
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────
# 사전 점검
# ────────────────────────────────────────────────────────────────────────

log "설치 위치: $TARGET_DIR"
[ "$DRY_RUN" -eq 1 ] && log "DRY-RUN 모드 — 실제 변경은 일어나지 않습니다"

# 활성화된 옵션 출력
log "설치할 스킬 (총 ${#GSTACK_SKILLS[@]} + ${#SUPERPOWERS_SKILLS[@]}개):"
log "  gstack:        ${GSTACK_SKILLS[*]}"
log "  Superpowers:   ${SUPERPOWERS_SKILLS[*]}"
[ "$WITH_DEBUG" -eq 1 ]  && log "  옵션: --with-debug 활성 (체계적 디버깅 추가)"
[ "$WITH_REVIEW" -eq 1 ] && log "  옵션: --with-review 활성 (코드 리뷰 추가)"

run "mkdir -p '$TARGET_DIR'"

# 임시 작업 디렉토리
WORK_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'minimal-skills')"
trap 'rm -rf "$WORK_DIR"' EXIT
log "임시 작업 디렉토리: $WORK_DIR"

# 충돌 검사
CONFLICT=0
for s in "${GSTACK_SKILLS[@]}" "${SUPERPOWERS_SKILLS[@]}"; do
  if [ -e "$TARGET_DIR/$s" ] || [ -L "$TARGET_DIR/$s" ]; then
    if [ "$UPDATE" -eq 1 ]; then
      log "기존 항목 발견(업데이트 모드, 덮어씀): $TARGET_DIR/$s"
    else
      warn "이미 존재: $TARGET_DIR/$s"
      CONFLICT=1
    fi
  fi
done

if [ "$CONFLICT" -eq 1 ] && [ "$UPDATE" -eq 0 ]; then
  err "충돌하는 스킬이 있습니다. --update 플래그로 덮어쓰거나 직접 정리한 뒤 다시 실행하세요."
fi

# ────────────────────────────────────────────────────────────────────────
# 1) gstack: 전체 클론 후 의사결정 3종만 심볼릭 링크
# ────────────────────────────────────────────────────────────────────────

GSTACK_DEST="$TARGET_DIR/$GSTACK_SOURCE_NAME"

log "gstack 레포 가져오기..."
if [ -d "$GSTACK_DEST/.git" ]; then
  log "  기존 클론 발견 → fetch 후 reset"
  run "git -C '$GSTACK_DEST' fetch --depth 1 origin main"
  run "git -C '$GSTACK_DEST' reset --hard origin/main"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  (dry-run) git clone --depth 1 $GSTACK_REPO '$GSTACK_DEST'"
  else
    rm -rf "$GSTACK_DEST"
    git clone --depth 1 --single-branch "$GSTACK_REPO" "$GSTACK_DEST"
  fi
fi

# 각 gstack 스킬을 ~/.claude/skills/<name>으로 심볼릭 링크
for s in "${GSTACK_SKILLS[@]}"; do
  src="$GSTACK_DEST/$s"
  dst="$TARGET_DIR/$s"

  if [ "$DRY_RUN" -eq 0 ] && [ ! -d "$src" ]; then
    warn "gstack 레포에 $s 스킬 폴더가 없습니다 — 건너뜀"
    continue
  fi

  # SKILL.md.tmpl만 있고 SKILL.md가 없는 경우 처리
  if [ "$DRY_RUN" -eq 0 ] && [ ! -f "$src/SKILL.md" ] && [ -f "$src/SKILL.md.tmpl" ]; then
    log "  $s/SKILL.md가 없어 SKILL.md.tmpl을 복사합니다"
    cp "$src/SKILL.md.tmpl" "$src/SKILL.md"
  fi

  log "  링크: $dst → $src"
  run "rm -rf '$dst'"
  run "ln -sn '$src' '$dst'"
done

# ────────────────────────────────────────────────────────────────────────
# 2) Superpowers: 스킬 레포에서 4종만 복사
# ────────────────────────────────────────────────────────────────────────

SP_CLONE="$WORK_DIR/superpowers-skills"

log "Superpowers 스킬 레포 가져오기..."
if [ "$DRY_RUN" -eq 0 ]; then
  if ! git clone --depth 1 --single-branch "$SUPERPOWERS_SKILLS_REPO" "$SP_CLONE" 2>/dev/null; then
    log "  superpowers-skills 클론 실패 — 메인 레포(obra/superpowers)로 폴백"
    SP_MAIN_CLONE="$WORK_DIR/superpowers"
    git clone --depth 1 --single-branch "$SUPERPOWERS_MAIN_REPO" "$SP_MAIN_CLONE"
    SP_CLONE="$SP_MAIN_CLONE"
  fi
else
  log "  (dry-run) git clone $SUPERPOWERS_SKILLS_REPO"
fi

# 스킬 위치 탐색 함수
# 1) 평면 구조: <root>/skills/<name>/SKILL.md
# 2) 카테고리 구조: <root>/skills/<category>/<name>/SKILL.md
find_sp_skill() {
  local skill="$1"
  local root="$2"

  # 평면 우선
  if [ -f "$root/skills/$skill/SKILL.md" ]; then
    printf '%s\n' "$root/skills/$skill"
    return 0
  fi

  # 카테고리 탐색
  local found
  found="$(find "$root/skills" -maxdepth 3 -type d -name "$skill" 2>/dev/null | head -n 1 || true)"
  if [ -n "$found" ] && [ -f "$found/SKILL.md" ]; then
    printf '%s\n' "$found"
    return 0
  fi
  return 1
}

for s in "${SUPERPOWERS_SKILLS[@]}"; do
  dst="$TARGET_DIR/$s"

  if [ "$DRY_RUN" -eq 1 ]; then
    log "  (dry-run) Superpowers $s 검색 → $dst 로 복사"
    continue
  fi

  if src="$(find_sp_skill "$s" "$SP_CLONE")"; then
    log "  복사: $src → $dst"
    rm -rf "$dst"
    cp -R "$src" "$dst"
  else
    warn "Superpowers에 $s 스킬을 찾지 못했습니다 — 건너뜀"
  fi
done

# ────────────────────────────────────────────────────────────────────────
# 3) 의존성 점검: SKILL.md 안에서 빠진 형제 스킬을 참조하는지 검사
# ────────────────────────────────────────────────────────────────────────

if [ "$DRY_RUN" -eq 0 ]; then
  log ""
  log "── 의존성 점검 ────────────────────────────────────────"

  INSTALLED="${GSTACK_SKILLS[*]} ${SUPERPOWERS_SKILLS[*]}"

  # gstack 쪽에서 미설치 슬래시 명령 호출 검색
  # gstack의 알려진 슬래시 명령 화이트리스트 (디렉토리 이름과 우연히 겹치는
  # /bin, /test, /claude, /lib 같은 false positive 차단)
  GSTACK_SLASH_COMMANDS="autoplan benchmark browse canary careful codex cso \
design-consultation design-html design-review design-shotgun devex-review \
document-release freeze guard gstack-upgrade investigate land-and-deploy learn \
office-hours open-gstack-browser pair-agent plan-ceo-review plan-design-review \
plan-devex-review plan-eng-review plan-tune qa qa-only retro review setup-browser-cookies \
setup-deploy setup-gbrain ship sync-gbrain unfreeze"

  log "gstack 미설치 명령 참조 점검..."
  any_warning=0
  for s in "${GSTACK_SKILLS[@]}"; do
    f="$TARGET_DIR/$s/SKILL.md"
    [ -f "$f" ] || continue

    # 슬래시 명령 후보 추출
    refs=$(grep -oE '/[a-z][a-z-]+' "$f" 2>/dev/null | sort -u || true)

    missing=""
    for r in $refs; do
      cmd="${r#/}"
      # 화이트리스트에 있고, 설치되지 않은 경우에만 수집
      case " $GSTACK_SLASH_COMMANDS " in
        *" $cmd "*)
          case " $INSTALLED " in
            *" $cmd "*) ;;
            *) missing="$missing /$cmd" ;;
          esac
          ;;
      esac
    done

    if [ -n "$missing" ]; then
      count=$(echo "$missing" | wc -w | tr -d ' ')
      log "  $s: 미설치 gstack 명령 $count개 언급됨 →$missing"
      any_warning=1
    fi
  done
  if [ "$any_warning" -eq 0 ]; then
    log "  미설치 형제 명령 참조 없음"
  else
    log "  (참고: 위 명령들은 SKILL.md 본문에서 워크플로우의 다음 단계로"
    log "         추천되지만, 설치하지 않은 상태이므로 무시됩니다."
    log "         스킬 자체 동작은 정상입니다.)"
  fi

  # Superpowers 쪽에서 형제 스킬 호출 검색
  log "Superpowers 형제 스킬 참조 점검..."
  sp_any=0
  for s in "${SUPERPOWERS_SKILLS[@]}"; do
    f="$TARGET_DIR/$s/SKILL.md"
    [ -f "$f" ] || continue

    refs=$(grep -oE 'superpowers:[a-z][a-z-]+' "$f" 2>/dev/null | sort -u || true)
    missing=""
    for r in $refs; do
      target="${r#superpowers:}"
      case " $INSTALLED " in
        *" $target "*) ;;
        *) missing="$missing $target" ;;
      esac
    done
    if [ -n "$missing" ]; then
      log "  $s: 미설치 형제 스킬 언급 →$missing"
      sp_any=1
    fi
  done
  if [ "$sp_any" -eq 0 ]; then
    log "  Superpowers 형제 스킬 참조 없음"
  fi

  log "── 점검 완료 ─────────────────────────────────────────"
fi

# ────────────────────────────────────────────────────────────────────────
# 마무리
# ────────────────────────────────────────────────────────────────────────

log ""
log "설치 결과:"
for s in "${GSTACK_SKILLS[@]}" "${SUPERPOWERS_SKILLS[@]}"; do
  if [ -e "$TARGET_DIR/$s" ] || [ -L "$TARGET_DIR/$s" ]; then
    if [ -L "$TARGET_DIR/$s" ]; then
      printf '  [링크] %s -> %s\n' "$s" "$(readlink "$TARGET_DIR/$s" 2>/dev/null || true)"
    else
      printf '  [파일] %s\n' "$s"
    fi
  else
    printf '  [없음] %s\n' "$s"
  fi
done

TOTAL_INSTALLED=$((${#GSTACK_SKILLS[@]} + ${#SUPERPOWERS_SKILLS[@]}))

cat <<EOF

다음 단계:
  1) Claude Code를 재시작하면 ${TOTAL_INSTALLED}개 스킬이 로드됩니다.

     gstack 의사결정 (${#GSTACK_SKILLS[@]}개):
       ${GSTACK_SKILLS[*]}

     Superpowers 실행 (${#SUPERPOWERS_SKILLS[@]}개):
       ${SUPERPOWERS_SKILLS[*]}

  2) 프로젝트의 CLAUDE.md(또는 ~/.claude/CLAUDE.md)에 다음을 추가하면
     Claude가 더 안정적으로 스킬을 인식합니다:

     ## Available skills
     - gstack: ${GSTACK_SKILLS[*]}
     - Superpowers: ${SUPERPOWERS_SKILLS[*]}

  3) 업데이트는 같은 명령에 --update를 붙여 재실행하세요.
     --with-debug, --with-review, --with-all 옵션으로 스킬을 추가할 수 있습니다.
  4) 제거는 --remove로 가능합니다.
EOF
