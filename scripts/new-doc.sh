#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

usage() {
  cat <<'EOF'
Usage:
  new-doc.sh <workspace-root> <project-name> <doc-type> <doc-title> [slug]

Doc types:
  technical
  design
  product
  runbook
  wiki

Example:
  new-doc.sh /path/to/workspace snapflow-web technical "Query Cache Notes"
  new-doc.sh /path/to/workspace snapflow-web wiki "Designer FAQ" designer-faq
EOF
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9._-]/-/g' \
    | sed 's/-\{2,\}/-/g' \
    | sed 's/^-//; s/-$//'
}

ensure_index_file() {
  local path="$1"
  local title="$2"
  if [[ ! -f "${path}" ]]; then
    cat > "${path}" <<EOF
# ${title}

## Entries

EOF
  fi
}

append_index_entry() {
  local index_file="$1"
  local filename="$2"
  local title="$3"
  if ! grep -Fq "[${title}](${filename})" "${index_file}"; then
    printf -- '- [%s](%s)\n' "${title}" "${filename}" >> "${index_file}"
  fi
}

if [[ "${#}" -lt 4 ]]; then
  usage >&2
  exit 1
fi

WORKSPACE_ROOT="$(cd "${1}" && pwd)"
PROJECT_NAME="${2}"
DOC_TYPE="${3}"
DOC_TITLE="${4}"
DOC_SLUG="${5:-$(slugify "${DOC_TITLE}")}"

OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
PROJECT_ROOT="${OMNI_ROOT}/projects/${PROJECT_NAME}"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"

if [[ ! -d "${PROJECT_ROOT}" ]]; then
  echo "Unknown project: ${PROJECT_NAME}" >&2
  exit 1
fi

if [[ -z "${DOC_SLUG}" ]]; then
  echo "Could not derive a valid slug from title" >&2
  exit 1
fi

case "${DOC_TYPE}" in
  technical)
    DOC_DIR="${PROJECT_ROOT}/docs/${DOC_TYPE}"
    DOC_FILE="${DOC_DIR}/${DOC_SLUG}.md"
    INDEX_FILE="${DOC_DIR}/index.md"
    INDEX_TITLE="${PROJECT_NAME} $(omni_doc_type_label "${language}" "${DOC_TYPE}")"
    ;;
  design)
    DOC_DIR="${PROJECT_ROOT}/docs/${DOC_TYPE}"
    DOC_FILE="${DOC_DIR}/${DOC_SLUG}.md"
    INDEX_FILE="${DOC_DIR}/index.md"
    INDEX_TITLE="${PROJECT_NAME} $(omni_doc_type_label "${language}" "${DOC_TYPE}")"
    ;;
  product)
    DOC_DIR="${PROJECT_ROOT}/docs/${DOC_TYPE}"
    DOC_FILE="${DOC_DIR}/${DOC_SLUG}.md"
    INDEX_FILE="${DOC_DIR}/index.md"
    INDEX_TITLE="${PROJECT_NAME} $(omni_doc_type_label "${language}" "${DOC_TYPE}")"
    ;;
  runbook)
    DOC_DIR="${PROJECT_ROOT}/docs/${DOC_TYPE}"
    DOC_FILE="${DOC_DIR}/${DOC_SLUG}.md"
    INDEX_FILE="${DOC_DIR}/index.md"
    INDEX_TITLE="${PROJECT_NAME} $(omni_doc_type_label "${language}" "${DOC_TYPE}")"
    ;;
  wiki)
    DOC_DIR="${PROJECT_ROOT}/wiki"
    DOC_FILE="${DOC_DIR}/${DOC_SLUG}.md"
    INDEX_FILE="${DOC_DIR}/index.md"
    INDEX_TITLE="${PROJECT_NAME} $(omni_doc_type_label "${language}" "${DOC_TYPE}")"
    ;;
  *)
    echo "Unsupported doc type: ${DOC_TYPE}" >&2
    usage >&2
    exit 1
    ;;
esac

mkdir -p "${DOC_DIR}"
ensure_index_file "${INDEX_FILE}" "${INDEX_TITLE}"

if [[ -f "${DOC_FILE}" ]]; then
  echo "Document already exists: ${DOC_FILE}" >&2
  exit 1
fi

omni_write_doc_template "${DOC_FILE}" "${language}" "${PROJECT_NAME}" "${DOC_TYPE}" "${DOC_TITLE}"

append_index_entry "${INDEX_FILE}" "$(basename "${DOC_FILE}")" "${DOC_TITLE}"

case "${language}" in
  zh-CN)
    echo "已创建 OmniContext 文档"
    echo "- 项目: ${PROJECT_NAME}"
    echo "- 类型: ${DOC_TYPE}"
    echo "- 文件: ${DOC_FILE}"
    echo "- 索引: ${INDEX_FILE}"
    ;;
  ja)
    echo "OmniContext 文書を作成しました"
    echo "- プロジェクト: ${PROJECT_NAME}"
    echo "- 種別: ${DOC_TYPE}"
    echo "- ファイル: ${DOC_FILE}"
    echo "- インデックス: ${INDEX_FILE}"
    ;;
  *)
    echo "Created OmniContext document"
    echo "- Project: ${PROJECT_NAME}"
    echo "- Type: ${DOC_TYPE}"
    echo "- File: ${DOC_FILE}"
    echo "- Index: ${INDEX_FILE}"
    ;;
esac
