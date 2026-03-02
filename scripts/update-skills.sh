#!/usr/bin/env bash
set -euo pipefail

DEFAULT_AGENT_SKILLS_DIR="${HOME}/.agents/skills"
DEFAULT_CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

AGENT_SKILLS_DIR="${OMNI_AGENT_SKILLS_DIR:-${DEFAULT_AGENT_SKILLS_DIR}}"
CODEX_SKILLS_DIR="${OMNI_CODEX_SKILLS_DIR:-${DEFAULT_CODEX_SKILLS_DIR}}"
CHECK_ONLY="false"

usage() {
  cat <<EOF
Usage:
  update-skills.sh [--check-only]

Behavior:
  - If a skills root is itself a Git repository, update that repository.
  - Otherwise scan child skill directories and update each Git repository found.
  - Never read or write the current workspace .omnicontext tree.
  - Never generate or update project documentation files.

Default roots:
  - ${AGENT_SKILLS_DIR}
  - ${CODEX_SKILLS_DIR}

Environment overrides:
  - OMNI_AGENT_SKILLS_DIR
  - OMNI_CODEX_SKILLS_DIR

Examples:
  update-skills.sh
  update-skills.sh --check-only
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --check-only)
      CHECK_ONLY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

has_remote() {
  local repo="$1"
  [[ -n "$(git -C "${repo}" remote 2>/dev/null | head -n 1)" ]]
}

git_branch_label() {
  local repo="$1"
  git -C "${repo}" symbolic-ref --quiet --short HEAD 2>/dev/null \
    || git -C "${repo}" rev-parse --short HEAD 2>/dev/null \
    || printf 'unknown\n'
}

update_repo() {
  local repo="$1"
  local branch
  branch="$(git_branch_label "${repo}")"
  if ! has_remote "${repo}"; then
    echo "- SKIP ${repo} (no remote, branch=${branch})"
    return 0
  fi

  if [[ "${CHECK_ONLY}" == "true" ]]; then
    local dirty="clean"
    if [[ -n "$(git -C "${repo}" status --short 2>/dev/null)" ]]; then
      dirty="dirty"
    fi
    echo "- CHECK ${repo} (branch=${branch}, ${dirty})"
    return 0
  fi

  if git -C "${repo}" pull --ff-only; then
    echo "- UPDATED ${repo} (branch=${branch})"
  else
    echo "- FAILED ${repo} (branch=${branch})" >&2
    return 1
  fi
}

collect_repos() {
  local root="$1"
  if [[ ! -d "${root}" ]]; then
    return 0
  fi
  if [[ -d "${root}/.git" ]]; then
    printf '%s\n' "${root}"
    return 0
  fi
  find "${root}" -mindepth 1 -maxdepth 4 -type d -name .git \
    | sed 's#/.git$##' \
    | sort -u
}

main() {
  local roots=("${AGENT_SKILLS_DIR}" "${CODEX_SKILLS_DIR}")
  local repos=()
  local failures=0
  local root
  local repo

  if [[ -d ".omnicontext" ]]; then
    :
  fi

  for root in "${roots[@]}"; do
    while IFS= read -r repo; do
      [[ -n "${repo}" ]] || continue
      repos+=("${repo}")
    done < <(collect_repos "${root}")
  done

  if [[ "${#repos[@]}" -eq 0 ]]; then
    echo "No Git-managed skill repositories found."
    exit 0
  fi

  echo "Skill roots:"
  for root in "${roots[@]}"; do
    echo "- ${root}"
  done

  echo "Workspace docs:"
  echo "- untouched (.omnicontext is not modified)"

  echo "Repositories:"
  while IFS= read -r repo; do
    update_repo "${repo}" || failures=$((failures + 1))
  done < <(printf '%s\n' "${repos[@]}" | awk '!seen[$0]++')

  if [[ "${failures}" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
