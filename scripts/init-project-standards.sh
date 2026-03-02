#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

usage() {
  cat <<'EOF'
Usage:
  init-project-standards.sh <workspace-root> <project-name> [project-type]
EOF
}

if [[ "${#}" -lt 2 ]]; then
  usage >&2
  exit 1
fi

WORKSPACE_ROOT="$(cd "${1}" && pwd)"
PROJECT_NAME="${2}"
PROJECT_TYPE="${3:-}"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
PROJECT_DIR="${OMNI_ROOT}/projects/${PROJECT_NAME}"
WORKSPACE_TOML="${OMNI_ROOT}/workspace.toml"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"

if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "Unknown project: ${PROJECT_NAME}" >&2
  exit 1
fi

SOURCE_PATH="$(python3 - "$WORKSPACE_TOML" "$PROJECT_NAME" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
name = sys.argv[2]
for item in data.get("project_mappings", []):
    if item.get("name") == name:
        print(item.get("source_path", ""))
        break
PY
)"
SOURCE_DIR="${WORKSPACE_ROOT}/${SOURCE_PATH}"
STANDARDS_DIR="${PROJECT_DIR}/standards"
mkdir -p "${STANDARDS_DIR}"

if [[ -z "${PROJECT_TYPE}" ]]; then
  if [[ -f "${SOURCE_DIR}/package.json" ]]; then
    PROJECT_TYPE="webapp"
  elif [[ -f "${SOURCE_DIR}/pom.xml" || -f "${SOURCE_DIR}/go.mod" || -f "${SOURCE_DIR}/Cargo.toml" ]]; then
    PROJECT_TYPE="backend-service"
  else
    PROJECT_TYPE="project"
  fi
fi

has_frontend=0
has_backend=0
has_design=0
if [[ -f "${SOURCE_DIR}/package.json" ]]; then
  has_frontend=1
fi
if [[ -f "${SOURCE_DIR}/pom.xml" || -f "${SOURCE_DIR}/go.mod" || -f "${SOURCE_DIR}/Cargo.toml" ]]; then
  has_backend=1
fi
if [[ -d "${SOURCE_DIR}/src" || -d "${SOURCE_DIR}/components" || -d "${SOURCE_DIR}/pages" ]]; then
  has_design=1
fi

cat > "${STANDARDS_DIR}/roles.toml" <<EOF
version = 1
project_name = "${PROJECT_NAME}"
project_type = "${PROJECT_TYPE}"

[core_roles]
coordinator = true
product = true
architecture = true
development = $([[ "${has_frontend}" -eq 1 || "${has_backend}" -eq 1 ]] && printf 'false' || printf 'true')
testing = true

[extended_roles]
design = $([[ "${has_design}" -eq 1 ]] && printf 'true' || printf 'false')
frontend = $([[ "${has_frontend}" -eq 1 ]] && printf 'true' || printf 'false')
backend = $([[ "${has_backend}" -eq 1 ]] && printf 'true' || printf 'false')
acceptance = true

[stage_owners]
intake = "product"
clarification = "product"
design = "architecture"
delivery = "$([[ "${has_frontend}" -eq 1 ]] && printf 'frontend' || printf 'development')"
testing = "testing"
acceptance = "product"
EOF

cp "${SKILL_ROOT}/templates/skills.toml" "${STANDARDS_DIR}/skills.toml"
python3 - "${STANDARDS_DIR}/skills.toml" "${PROJECT_NAME}" "${PROJECT_TYPE}" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("replace-with-project-name", sys.argv[2]).replace("replace-with-project-type", sys.argv[3])
path.write_text(text)
PY

cp "${SKILL_ROOT}/templates/runtime.toml" "${STANDARDS_DIR}/runtime.toml"
cp "${SKILL_ROOT}/templates/testing-platforms.toml" "${STANDARDS_DIR}/testing-platforms.toml"
python3 - "${STANDARDS_DIR}/runtime.toml" "${STANDARDS_DIR}/testing-platforms.toml" "${PROJECT_NAME}" "${has_frontend}" "${has_backend}" <<'PY'
import sys
from pathlib import Path
runtime = Path(sys.argv[1])
testing = Path(sys.argv[2])
project = sys.argv[3]
has_frontend = sys.argv[4] == "1"
has_backend = sys.argv[5] == "1"
runtime_text = 'version = 1\nproject_name = "{}"\n'.format(project)
deps = []
if has_frontend:
    deps.append('[[dependencies]]\nid = "browser_app"\nkind = "browser"\nenabled = true\nenvironment = "local"\nhost = ""\nport = 0\ndatabase = ""\nuser = ""\nurl = "http://localhost:3000"\nentry_url = "http://localhost:3000"\nnotes = "Primary local web entry"\n')
if has_backend:
    deps.append('[[dependencies]]\nid = "service_api"\nkind = "service"\nenabled = true\nenvironment = "local"\nhost = "127.0.0.1"\nport = 8080\ndatabase = ""\nuser = ""\nurl = "http://127.0.0.1:8080"\nentry_url = ""\nnotes = "Primary local backend API"\n')
    deps.append('[[dependencies]]\nid = "redis_cache"\nkind = "redis"\nenabled = false\nenvironment = "local"\nhost = "127.0.0.1"\nport = 6379\ndatabase = "0"\nuser = ""\nurl = ""\nentry_url = ""\nnotes = "Optional local redis cache"\n')
runtime.write_text(runtime_text + ("\n" + "\n".join(deps) if deps else ""))
testing_text = 'version = 1\nproject_name = "{}"\n'.format(project)
platforms = []
if has_frontend:
    platforms.append('[[platforms]]\nid = "web"\nenabled = true\nrequired_test_mode = "browser"\nrequired_skills = ["webapp-testing"]\n')
if has_backend:
    platforms.append('[[platforms]]\nid = "backend"\nenabled = true\nrequired_test_mode = "api"\nrequired_skills = []\n')
testing.write_text(testing_text + ("\n" + "\n".join(platforms) if platforms else ""))
PY

cp "${SKILL_ROOT}/templates/rules-pack.toml" "${STANDARDS_DIR}/rules-pack.toml"
cp "${SKILL_ROOT}/templates/sources.toml" "${STANDARDS_DIR}/sources.toml"
cp "${SKILL_ROOT}/templates/changes.md" "${STANDARDS_DIR}/changes.md"
cp "${SKILL_ROOT}/templates/standards-map.md" "${STANDARDS_DIR}/standards-map.md"
cp "${SKILL_ROOT}/templates/coordinator.md" "${STANDARDS_DIR}/coordinator.md"
cp "${SKILL_ROOT}/templates/product.md" "${STANDARDS_DIR}/product.md"
cp "${SKILL_ROOT}/templates/architecture.md" "${STANDARDS_DIR}/architecture.md"
cp "${SKILL_ROOT}/templates/engineering.md" "${STANDARDS_DIR}/engineering.md"
cp "${SKILL_ROOT}/templates/testing.md" "${STANDARDS_DIR}/testing.md"
cp "${SKILL_ROOT}/templates/acceptance.md" "${STANDARDS_DIR}/acceptance.md"
if [[ "${has_frontend}" -eq 1 ]]; then cp "${SKILL_ROOT}/templates/frontend.md" "${STANDARDS_DIR}/frontend.md"; fi
if [[ "${has_backend}" -eq 1 ]]; then cp "${SKILL_ROOT}/templates/backend.md" "${STANDARDS_DIR}/backend.md"; fi
if [[ "${has_design}" -eq 1 ]]; then cp "${SKILL_ROOT}/templates/design.md" "${STANDARDS_DIR}/design.md"; fi

{
  echo "project_name = \"${PROJECT_NAME}\""
  echo "project_type = \"${PROJECT_TYPE}\""
  echo
  for candidate in package.json pom.xml build.gradle go.mod Cargo.toml README.md CONTRIBUTING.md .eslintrc .prettierrc tsconfig.json vite.config.ts vite.config.js; do
    if [[ -f "${SOURCE_DIR}/${candidate}" ]]; then
      echo "[[sources]]"
      echo "path = \"${SOURCE_PATH}/${candidate}\""
      echo "type = \"explicit\""
      echo
    fi
  done
} > "${STANDARDS_DIR}/sources.toml"

python3 - "${STANDARDS_DIR}/changes.md" "${PROJECT_TYPE}" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("{{CHANGE_TYPE}}", "bootstrap").replace("{{CHANGE_REASON}}", f"Initialized standards from detected project conventions ({sys.argv[2]}).").replace("{{CHANGE_SCOPE}}", "project standards").replace("{{CHANGE_ACTION}}", "Created role, rules, runtime, testing, and standards source records."))
PY

case "${language}" in
  zh-CN)
    echo "已初始化项目规范"
    echo "- 项目: ${PROJECT_NAME}"
    echo "- 类型: ${PROJECT_TYPE}"
    ;;
  ja)
    echo "プロジェクト規約を初期化しました"
    echo "- プロジェクト: ${PROJECT_NAME}"
    echo "- 種別: ${PROJECT_TYPE}"
    ;;
  *)
    echo "Initialized project standards"
    echo "- Project: ${PROJECT_NAME}"
    echo "- Type: ${PROJECT_TYPE}"
    ;;
esac
