#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${1:-$(pwd)}"
WORKSPACE_ROOT="$(cd "${WORKSPACE_ROOT}" && pwd)"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"

if [[ ! -d "${OMNI_ROOT}" ]]; then
  echo "OmniContext not found in ${WORKSPACE_ROOT}" >&2
  exit 1
fi

workspace_toml="${OMNI_ROOT}/workspace.toml"
if [[ ! -f "${workspace_toml}" ]]; then
  echo "Missing ${workspace_toml}" >&2
  exit 1
fi

workspace_name="$(sed -n 's/^workspace_name = "\(.*\)"/\1/p' "${workspace_toml}")"
mode="$(sed -n 's/^mode = "\(.*\)"/\1/p' "${workspace_toml}")"

mapped_names=()
mapped_paths=()
while IFS='|' read -r name knowledge_path; do
  [[ -n "${name}" ]] || continue
  mapped_names+=("${name}")
  mapped_paths+=("${knowledge_path}")
done < <(
  awk '
    /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && knowledge_path != "") print name "|" knowledge_path
      in_block=1
      name=""
      knowledge_path=""
      next
    }
    /^\[/ && $0 !~ /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && knowledge_path != "") print name "|" knowledge_path
      in_block=0
    }
    in_block && /^name = / {
      line=$0
      sub(/^name = "/, "", line)
      sub(/"$/, "", line)
      name=line
    }
    in_block && /^knowledge_path = / {
      line=$0
      sub(/^knowledge_path = "/, "", line)
      sub(/"$/, "", line)
      knowledge_path=line
    }
    END {
      if (in_block && name != "" && knowledge_path != "") print name "|" knowledge_path
    }
  ' "${workspace_toml}"
)

echo "Workspace: ${workspace_name}"
echo "Mode: ${mode}"
echo "OmniContext root: ${OMNI_ROOT}"

required_files=(
  "${OMNI_ROOT}/INDEX.md"
  "${OMNI_ROOT}/shared/standards.md"
  "${OMNI_ROOT}/shared/language-policy.md"
  "${OMNI_ROOT}/personal/preferences.md"
  "${OMNI_ROOT}/workspace.toml"
)

missing_required=0
echo
echo "Required files:"
for file in "${required_files[@]}"; do
  if [[ -f "${file}" ]]; then
    echo "- OK ${file#${WORKSPACE_ROOT}/}"
  else
    echo "- MISSING ${file#${WORKSPACE_ROOT}/}"
    missing_required=1
  fi
done

echo
echo "Projects:"
project_dirs_found=0
for idx in "${!mapped_names[@]}"; do
  project_dirs_found=1
  project_name="${mapped_names[$idx]}"
  project_dir="${OMNI_ROOT}/${mapped_paths[$idx]}"
  echo "- ${project_name}"
  for doc in overview.md handoff.md todo.md decisions.md; do
    if [[ -f "${project_dir}/${doc}" ]]; then
      echo "  OK ${doc}"
    else
      echo "  MISSING ${doc}"
      missing_required=1
    fi
  done
done

if [[ "${project_dirs_found}" -eq 0 ]]; then
  echo "- No mapped projects found"
  missing_required=1
fi

echo
echo "Mappings from workspace.toml:"
if [[ "${#mapped_names[@]}" -eq 0 ]]; then
  echo "- None"
else
  for name in "${mapped_names[@]}"; do
    echo "- ${name}"
  done
fi

echo
echo "Unmapped project directories:"
unmapped_found=0
while IFS= read -r -d '' project_dir; do
  rel_path="${project_dir#${OMNI_ROOT}/}"
  is_mapped=0
  for mapped_path in "${mapped_paths[@]}"; do
    if [[ "${rel_path}" == "${mapped_path}" ]]; then
      is_mapped=1
      break
    fi
  done
  if [[ "${is_mapped}" -eq 0 ]]; then
    unmapped_found=1
    echo "- ${rel_path}"
  fi
done < <(find "${OMNI_ROOT}/projects" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

if [[ "${unmapped_found}" -eq 0 ]]; then
  echo "- None"
fi

echo
if [[ "${missing_required}" -eq 0 ]]; then
  echo "Status: OK"
else
  echo "Status: INCOMPLETE"
  exit 2
fi
