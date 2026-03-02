#!/usr/bin/env bash

omni_bundle_catalog_items() {
  cat <<'EOF'
figma|local|/Users/zhouping/.codex/skills/figma
figma-implement-design|local|/Users/zhouping/.codex/skills/figma-implement-design
frontend-design|local|/Users/zhouping/.agents/skills/frontend-design
ui-design-system|local|/Users/zhouping/.agents/skills/ui-design-system
webapp-testing|local|/Users/zhouping/.agents/skills/yuque-document-management/skills/webapp-testing
doc-coauthoring|local|/Users/zhouping/.agents/skills/yuque-document-management/skills/doc-coauthoring
docs-management|local|/Users/zhouping/.agents/skills/docs-management
ant-design-vue|local|/Users/zhouping/.agents/skills/ant-design-vue
element-plus-vue3|local|/Users/zhouping/.agents/skills/element-plus-vue3
vue|local|/Users/zhouping/.agents/skills/vue
skill-installer|local|/Users/zhouping/.codex/skills/.system/skill-installer
EOF
}

omni_bundle_base_for_project_type() {
  case "$1" in
    webapp) printf '%s\n' skill-installer frontend-design webapp-testing ;;
    admin) printf '%s\n' skill-installer webapp-testing vue ant-design-vue element-plus-vue3 ;;
    workflow-platform) printf '%s\n' skill-installer doc-coauthoring webapp-testing ;;
    design-system) printf '%s\n' skill-installer ui-design-system frontend-design ;;
    docs-platform) printf '%s\n' skill-installer doc-coauthoring docs-management ;;
    backend-service) printf '%s\n' skill-installer ;;
    *) printf '%s\n' skill-installer ;;
  esac
}

omni_bundle_for_stage() {
  local project_type="$1"
  local stage="$2"
  case "${project_type}:${stage}" in
    webapp:design|design-system:design) printf '%s\n' figma figma-implement-design frontend-design ;;
    webapp:testing|admin:testing|workflow-platform:testing) printf '%s\n' webapp-testing ;;
    docs-platform:clarification|workflow-platform:clarification) printf '%s\n' doc-coauthoring ;;
    *) ;;
  esac
}

omni_bundle_for_role() {
  case "$1" in
    design) printf '%s\n' figma figma-implement-design frontend-design ;;
    frontend) printf '%s\n' frontend-design webapp-testing ;;
    testing) printf '%s\n' webapp-testing ;;
    product) printf '%s\n' doc-coauthoring ;;
    *) ;;
  esac
}

omni_bundle_source_path() {
  local id="$1"
  omni_bundle_catalog_items | awk -F'|' -v id="${id}" '$1 == id {print $3}'
}

omni_bundle_is_installed() {
  local id="$1"
  local code_home="${CODEX_HOME:-$HOME/.codex}"
  [[ -d "${code_home}/skills/${id}" ]]
}
