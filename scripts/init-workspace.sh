#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

WORKSPACE_ROOT="${1:-$(pwd)}"
WORKSPACE_ROOT="$(cd "${WORKSPACE_ROOT}" && pwd)"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"

if [[ -e "${OMNI_ROOT}/workspace.toml" ]]; then
  echo "OmniContext already exists at ${OMNI_ROOT}" >&2
  exit 1
fi

mkdir -p \
  "${OMNI_ROOT}/shared" \
  "${OMNI_ROOT}/shared/workflows" \
  "${OMNI_ROOT}/shared/bundles/project-types" \
  "${OMNI_ROOT}/shared/standards-library/modules" \
  "${OMNI_ROOT}/shared/standards-library/packs" \
  "${OMNI_ROOT}/personal" \
  "${OMNI_ROOT}/projects" \
  "${OMNI_ROOT}/tools/codex" \
  "${OMNI_ROOT}/tools/claude-code" \
  "${OMNI_ROOT}/tools/trae" \
  "${OMNI_ROOT}/tools/qoder"

workspace_name="$(basename "${WORKSPACE_ROOT}")"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"

discovered_projects=()
while IFS= read -r project_path; do
  discovered_projects+=("${project_path}")
done < <(
  find "${WORKSPACE_ROOT}" -mindepth 1 -maxdepth 3 -type d -name .git -prune \
    | sed "s#${WORKSPACE_ROOT}/##" \
    | sed 's#/.git$##' \
    | sort -u
)

if [[ "${#discovered_projects[@]}" -eq 0 ]]; then
  discovered_projects=("$(basename "${WORKSPACE_ROOT}")")
  mode="single"
elif [[ "${#discovered_projects[@]}" -eq 1 ]]; then
  mode="single"
else
  mode="multi"
fi

cat > "${OMNI_ROOT}/workspace.toml" <<EOF
version = 1
workspace_name = "${workspace_name}"
mode = "${mode}"
knowledge_root = ".omnicontext"

[discovery]
scan_git_repos = true
scan_depth = 3
ignore = [".git", "node_modules", "dist", "build", "coverage", "target"]

[shared]
path = "shared"

[personal]
path = "personal"

[projects]
path = "projects"

[localization]
default_language = "${language}"
supported_languages = ["zh-CN", "en", "ja"]
EOF

for project_path in "${discovered_projects[@]}"; do
  project_name="$(basename "${project_path}")"
  cat >> "${OMNI_ROOT}/workspace.toml" <<EOF

[[project_mappings]]
name = "${project_name}"
source_path = "${project_path}"
knowledge_path = "projects/${project_name}"
type = "project"
EOF
done

omni_write_workspace_index_header "${OMNI_ROOT}/INDEX.md" "${language}" "${workspace_name}" "${mode}"
omni_append_workspace_index_personal_header "${OMNI_ROOT}/INDEX.md" "${language}"

for project_path in "${discovered_projects[@]}"; do
  project_name="$(basename "${project_path}")"
  project_dir="${OMNI_ROOT}/projects/${project_name}"
  mkdir -p "${project_dir}"
  case "${language}" in
    zh-CN)
      handoff_status='由 OmniContext 初始化'
      handoff_recent='已创建 OmniContext 项目骨架'
      handoff_next='补充项目目标和关键入口'
      decision_context='OmniContext 为该项目完成初始化。'
      decision_text='先采用最小文档集。'
      decision_rationale='在流程证明有效之前，先控制维护成本。'
      decision_consequence='仅在真实需求出现后再增加文档类型。'
      ;;
    ja)
      handoff_status='OmniContext により初期化'
      handoff_recent='OmniContext のプロジェクトひな形を作成'
      handoff_next='プロジェクトの目的と主要エントリーポイントを補完する'
      decision_context='OmniContext がこのプロジェクトを初期化した。'
      decision_text='最小限の文書セットから開始する。'
      decision_rationale='ワークフローの有効性が確認できるまで保守コストを抑えるため。'
      decision_consequence='実際の必要性が出てから文書種別を追加する。'
      ;;
    *)
      handoff_status='Initialized by OmniContext'
      handoff_recent='OmniContext project scaffold created'
      handoff_next='Fill in project purpose and entry points'
      decision_context='OmniContext was initialized for this project.'
      decision_text='Start with the minimum document set.'
      decision_rationale='Keep maintenance cost low until the workflow proves useful.'
      decision_consequence='Add more document types only when real use requires them.'
      ;;
  esac

  omni_write_overview "${project_dir}/overview.md" "${language}" "${project_name}"
  omni_write_handoff \
    "${project_dir}/handoff.md" \
    "${language}" \
    "${handoff_status}" \
    "${handoff_recent}" \
    "${handoff_next}"
  omni_write_todo "${project_dir}/todo.md" "${language}"
  omni_write_decisions \
    "${project_dir}/decisions.md" \
    "${language}" \
    "OmniContext initialization" \
    "${decision_context}" \
    "${decision_text}" \
    "${decision_rationale}" \
    "${decision_consequence}"

  omni_append_workspace_index_project "${OMNI_ROOT}/INDEX.md" "${language}" "${project_name}" "${project_path}"
done
omni_append_workspace_index_notes "${OMNI_ROOT}/INDEX.md" "${language}"

cp "${SKILL_ROOT}/templates/shared-standards.md" "${OMNI_ROOT}/shared/standards.md"
cp "${SKILL_ROOT}/templates/shared-language-policy.md" "${OMNI_ROOT}/shared/language-policy.md"
cp "${SKILL_ROOT}/templates/workflow-registry.toml" "${OMNI_ROOT}/shared/workflows/registry.toml"
cp "${SKILL_ROOT}/templates/workflow-index.md" "${OMNI_ROOT}/shared/workflows/index.md"
cp "${SKILL_ROOT}/templates/personal-preferences.md" "${OMNI_ROOT}/personal/preferences.md"
cp "${SKILL_ROOT}/templates/machine.local.toml" "${OMNI_ROOT}/machine.local.toml"
cp "${SKILL_ROOT}/templates/user.local.toml" "${OMNI_ROOT}/user.local.toml"
cp "${SKILL_ROOT}/templates/codex-AGENTS.md" "${OMNI_ROOT}/tools/codex/AGENTS.md"
cp "${SKILL_ROOT}/templates/claude-CLAUDE.md" "${OMNI_ROOT}/tools/claude-code/CLAUDE.md"
cp "${SKILL_ROOT}/templates/trae-TRAE.md" "${OMNI_ROOT}/tools/trae/TRAE.md"
cp "${SKILL_ROOT}/templates/qoder-QODER.md" "${OMNI_ROOT}/tools/qoder/QODER.md"

cat > "${OMNI_ROOT}/shared/bundles/catalog.toml" <<'EOF'
version = 1
EOF
cat > "${OMNI_ROOT}/shared/standards-library/catalog.toml" <<'EOF'
version = 1
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/prd.toml" <<'EOF'
id = "prd"
category = "practice"
required_by_default = true
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/adr.toml" <<'EOF'
id = "adr"
category = "practice"
required_by_default = true
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/acceptance-criteria.toml" <<'EOF'
id = "acceptance-criteria"
category = "practice"
required_by_default = true
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/test-cases.toml" <<'EOF'
id = "test-cases"
category = "practice"
required_by_default = true
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/change-safety.toml" <<'EOF'
id = "change-safety"
category = "practice"
required_by_default = true
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/scrum-lite.toml" <<'EOF'
id = "scrum-lite"
category = "practice"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/test-pyramid.toml" <<'EOF'
id = "test-pyramid"
category = "practice"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/e2e-browser.toml" <<'EOF'
id = "e2e-browser"
category = "practice"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/backup-recovery.toml" <<'EOF'
id = "backup-recovery"
category = "practice"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/least-privilege.toml" <<'EOF'
id = "least-privilege"
category = "practice"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/iso-12207-lifecycle.toml" <<'EOF'
id = "iso-12207-lifecycle"
category = "formal-standard"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/nist-ssdf.toml" <<'EOF'
id = "nist-ssdf"
category = "formal-standard"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/owasp-asvs.toml" <<'EOF'
id = "owasp-asvs"
category = "formal-standard"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/modules/istqb-governance.toml" <<'EOF'
id = "istqb-governance"
category = "formal-standard"
required_by_default = false
EOF
cat > "${OMNI_ROOT}/shared/standards-library/packs/default-balanced.toml" <<'EOF'
id = "default-balanced"
EOF
cat > "${OMNI_ROOT}/shared/standards-library/packs/fast-delivery.toml" <<'EOF'
id = "fast-delivery"
EOF
cat > "${OMNI_ROOT}/shared/standards-library/packs/high-security.toml" <<'EOF'
id = "high-security"
EOF
cat > "${OMNI_ROOT}/shared/standards-library/packs/design-driven.toml" <<'EOF'
id = "design-driven"
EOF
cat > "${OMNI_ROOT}/shared/standards-library/packs/backend-stability.toml" <<'EOF'
id = "backend-stability"
EOF
cat > "${OMNI_ROOT}/shared/bundles/project-types/webapp.toml" <<'EOF'
project_type = "webapp"
EOF
cat > "${OMNI_ROOT}/shared/bundles/project-types/admin.toml" <<'EOF'
project_type = "admin"
EOF
cat > "${OMNI_ROOT}/shared/bundles/project-types/workflow-platform.toml" <<'EOF'
project_type = "workflow-platform"
EOF
cat > "${OMNI_ROOT}/shared/bundles/project-types/design-system.toml" <<'EOF'
project_type = "design-system"
EOF
cat > "${OMNI_ROOT}/shared/bundles/project-types/docs-platform.toml" <<'EOF'
project_type = "docs-platform"
EOF
cat > "${OMNI_ROOT}/shared/bundles/project-types/backend-service.toml" <<'EOF'
project_type = "backend-service"
EOF

case "${language}" in
  zh-CN)
    echo "已在 ${OMNI_ROOT} 初始化 OmniContext"
    echo "模式: ${mode}"
    echo "项目:"
    ;;
  ja)
    echo "${OMNI_ROOT} に OmniContext を初期化しました"
    echo "モード: ${mode}"
    echo "プロジェクト:"
    ;;
  *)
    echo "Initialized OmniContext at ${OMNI_ROOT}"
    echo "Mode: ${mode}"
    echo "Projects:"
    ;;
esac
for project_path in "${discovered_projects[@]}"; do
  echo "- $(basename "${project_path}") (${project_path})"
done
