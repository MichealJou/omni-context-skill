#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/test-lib.sh"
source "${SCRIPT_DIR}/lib/runtime-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
SUITE_ID="${3:-}"
shift 3 || true

RUN_ID="$(date +%Y%m%d-%H%M%S)"
PLATFORM="web"
DEPENDENCY_ID=""

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --dependency) DEPENDENCY_ID="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" || -z "${SUITE_ID}" ]]; then
  echo "Usage: run-browser-suite-devtools.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--platform web|miniapp] [--dependency dep-id]" >&2
  exit 1
fi

PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
RUNTIME_FILE="${PROJECT_DIR}/standards/runtime.toml"
SUITE_FILE="${PROJECT_DIR}/tests/suites/${SUITE_ID}.md"
RUNS_DIR="${PROJECT_DIR}/tests/runs"
ARTIFACTS_DIR="${PROJECT_DIR}/tests/artifacts"
mkdir -p "${RUNS_DIR}" "${ARTIFACTS_DIR}"

[[ -f "${SUITE_FILE}" ]] || { echo "Missing suite ${SUITE_ID}" >&2; exit 1; }
[[ -f "${RUNTIME_FILE}" ]] || { echo "Missing runtime.toml" >&2; exit 1; }

source_status="$(omni_test_suite_source_status "${SUITE_FILE}")"
if ! omni_test_effective_status_allowed "${source_status}"; then
  echo "Suite ${SUITE_ID} is draft-only and cannot be used for formal browser testing" >&2
  exit 2
fi

suite_platform="$(omni_test_suite_platform "${SUITE_FILE}")"
PLATFORM="${PLATFORM:-${suite_platform:-web}}"
if [[ "${PLATFORM}" != "web" && "${PLATFORM}" != "miniapp" ]]; then
  echo "DevTools browser suite only supports web or miniapp platform" >&2
  exit 2
fi

if [[ -z "${DEPENDENCY_ID}" ]]; then
  DEPENDENCY_ID="$(omni_runtime_dependency_for_platform "${RUNTIME_FILE}" "${PLATFORM}")"
fi
[[ -n "${DEPENDENCY_ID}" ]] || { echo "No runtime dependency matched platform ${PLATFORM}" >&2; exit 2; }

target_url="$(omni_runtime_dependency_url "${RUNTIME_FILE}" "${DEPENDENCY_ID}")"
[[ -n "${target_url}" ]] || { echo "Missing target URL for ${DEPENDENCY_ID}" >&2; exit 2; }

chrome_path="$(omni_browser_executable 2>/dev/null || true)"
if [[ -z "${chrome_path}" ]]; then
  "${SCRIPT_DIR}/record-test-run.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" "DevTools execute ${SUITE_ID}" "${RUN_ID}" \
    --mode "browser" \
    --platform "${PLATFORM}" \
    --run-status "blocked_runtime" \
    --observed "chrome-compatible browser binary is missing" \
    --root-cause "devtools primary executor could not launch a local browser" \
    --next-step "run omni-context setup-test-runtime ${WORKSPACE_ROOT} ${PROJECT_NAME} --platform ${PLATFORM}" >/dev/null
  echo "DevTools browser suite runtime blocked for ${SUITE_ID}" >&2
  echo "Run: ${RUN_ID}" >&2
  exit 2
fi

"${SCRIPT_DIR}/execute-test-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --mode "browser" --platform "${PLATFORM}" --evidence "pending-evidence" >/dev/null

RESULT_JSON="${ARTIFACTS_DIR}/${RUN_ID}.devtools.json"
STEPS_JSON="$(omni_test_suite_steps_json "${SUITE_FILE}")"

python3 - "$chrome_path" "$target_url" "$RESULT_JSON" "$ARTIFACTS_DIR" "$RUN_ID" "$STEPS_JSON" <<'PY'
import base64
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

import requests
import websocket

chrome_path, target_url, result_json, artifacts_dir, run_id, steps_json = sys.argv[1:7]
result_path = Path(result_json)
artifacts = Path(artifacts_dir)
artifacts.mkdir(parents=True, exist_ok=True)
log_file = artifacts / f"{run_id}.devtools.log"
result = {
    "status": "failed",
    "artifact": str(log_file),
    "failed_step": "",
    "observed": "",
    "root_cause": "",
    "next_step": "",
    "required_result": "FAIL",
    "optional_result": "FAIL",
}

def write_result():
    result_path.write_text(json.dumps(result, ensure_ascii=False))

def free_port():
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    sock.close()
    return port

port = free_port()
user_data_dir = artifacts / f"{run_id}-chrome-profile"
user_data_dir.mkdir(parents=True, exist_ok=True)
stderr_path = artifacts / f"{run_id}.chrome.stderr.log"

chrome_proc = subprocess.Popen(
    [
        chrome_path,
        f"--remote-debugging-port={port}",
        "--remote-allow-origins=*",
        f"--user-data-dir={user_data_dir}",
        "--headless=new",
        "--disable-gpu",
        "--no-first-run",
        "--no-default-browser-check",
        "--hide-scrollbars",
        "about:blank",
    ],
    stdout=subprocess.DEVNULL,
    stderr=stderr_path.open("wb"),
)
ws = None

def cleanup():
    if chrome_proc.poll() is None:
        chrome_proc.terminate()
        try:
            chrome_proc.wait(timeout=3)
        except Exception:
            chrome_proc.kill()

def get_ws_url():
    list_endpoint = f"http://127.0.0.1:{port}/json/list"
    for _ in range(50):
        try:
            resp = requests.get(list_endpoint, timeout=1)
            if resp.ok:
                for target in resp.json():
                    if target.get("type") == "page" and target.get("webSocketDebuggerUrl"):
                        return target["webSocketDebuggerUrl"]
        except Exception:
            time.sleep(0.2)
    return None

ws_url = get_ws_url()
if not ws_url:
    result.update({
        "status": "blocked_runtime",
        "observed": "devtools page target websocket endpoint was not reachable",
        "root_cause": stderr_path.read_text() if stderr_path.exists() else "chrome startup failed",
        "next_step": "run omni-context setup-test-runtime <workspace-root> <project-name> --platform web",
    })
    write_result()
    cleanup()
    raise SystemExit(0)

ws = websocket.create_connection(ws_url, timeout=10)
seq = 0

def send(method, params=None):
    global seq
    seq += 1
    payload = {"id": seq, "method": method, "params": params or {}}
    ws.send(json.dumps(payload))
    while True:
        message = json.loads(ws.recv())
        if message.get("id") == seq:
            if "error" in message:
                raise RuntimeError(f"{method}: {message['error']}")
            return message.get("result", {})

def eval_js(expression):
    return send("Runtime.evaluate", {"expression": expression, "returnByValue": True, "awaitPromise": True})

def wait_for_text(text, timeout=10):
    deadline = time.time() + timeout
    js = """
(() => document.body && document.body.innerText && document.body.innerText.includes(%s))()
""" % json.dumps(text)
    while time.time() < deadline:
        res = eval_js(js)
        if res.get("result", {}).get("value") is True:
            return True
        time.sleep(0.2)
    return False

def query_clickable(spec):
    if spec.startswith("text="):
        target = spec.split("=", 1)[1]
        expr = """
(() => {
  const target = %s.toLowerCase();
  const nodes = Array.from(document.querySelectorAll('a,button,input,textarea,select,[role],*[onclick],*'));
  for (const el of nodes) {
    const txt = ((el.innerText || el.value || el.getAttribute('aria-label') || '') + '').trim().toLowerCase();
    if (txt && txt.includes(target)) {
      const r = el.getBoundingClientRect();
      if (r.width > 0 && r.height > 0) return {x: r.left + r.width / 2, y: r.top + r.height / 2};
    }
  }
  return null;
})()
""" % json.dumps(target)
    elif spec.startswith("role="):
        role_spec = spec.split("=", 1)[1]
        role, _, name = role_spec.partition(":")
        expr = """
(() => {
  const role = %s;
  const name = %s.toLowerCase();
  const nodes = Array.from(document.querySelectorAll('[role],button,a,input,textarea,select'));
  for (const el of nodes) {
    const rname = (el.getAttribute('role') || (el.tagName || '')).toLowerCase();
    const txt = ((el.innerText || el.value || el.getAttribute('aria-label') || '') + '').trim().toLowerCase();
    if ((rname === role.toLowerCase() || (role === 'button' && el.tagName.toLowerCase() === 'button')) && (!name || txt.includes(name))) {
      const r = el.getBoundingClientRect();
      if (r.width > 0 && r.height > 0) return {x: r.left + r.width / 2, y: r.top + r.height / 2};
    }
  }
  return null;
})()
""" % (json.dumps(role), json.dumps(name))
    else:
        expr = """
(() => {
  const el = document.querySelector(%s);
  if (!el) return null;
  const r = el.getBoundingClientRect();
  if (r.width <= 0 || r.height <= 0) return null;
  return {x: r.left + r.width / 2, y: r.top + r.height / 2};
})()
""" % json.dumps(spec)
    res = eval_js(expr)
    return res.get("result", {}).get("value")

def fill_input(spec, value):
    expr = """
(() => {
  const q = %s;
  const v = %s;
  let el = null;
  if (q.startsWith('text=')) {
    const target = q.slice(5).toLowerCase();
    el = Array.from(document.querySelectorAll('input,textarea'))
      .find(node => ((node.labels && Array.from(node.labels).map(l => l.innerText).join(' ')) || node.getAttribute('aria-label') || '').toLowerCase().includes(target));
  } else {
    el = document.querySelector(q);
  }
  if (!el) return {ok:false, reason:'element not found'};
  el.focus();
  el.value = v;
  el.dispatchEvent(new Event('input', {bubbles:true}));
  el.dispatchEvent(new Event('change', {bubbles:true}));
  return {ok:true};
})()
""" % (json.dumps(spec), json.dumps(value))
    res = eval_js(expr)
    return res.get("result", {}).get("value")

def capture(name):
    target = artifacts / f"{run_id}-{name}.png"
    data = send("Page.captureScreenshot", {"format": "png"})
    target.write_bytes(base64.b64decode(data["data"]))
    return str(target)

try:
    send("Page.enable")
    send("DOM.enable")
    send("Runtime.enable")
    send("Page.navigate", {"url": target_url})
    time.sleep(1.5)

    steps = json.loads(steps_json)
    if not steps:
      steps = [{"action": "goto", "value": "/"}]

    for idx, step in enumerate(steps, start=1):
        action = step["action"].strip().lower()
        value = step["value"].strip()
        step_name = f"{idx}:{action}"
        if action == "goto":
            url = value if value.startswith("http") else target_url.rstrip("/") + value
            send("Page.navigate", {"url": url})
            time.sleep(1.5)
        elif action == "wait_for":
            ok = False
            if value.startswith("text="):
                ok = wait_for_text(value.split("=", 1)[1], 10)
            else:
                q = eval_js(f"(() => !!document.querySelector({json.dumps(value)}))()")
                ok = q.get("result", {}).get("value") is True
            if not ok:
                raise RuntimeError("wait target not reached")
        elif action == "click":
            point = query_clickable(value)
            if not point:
                raise RuntimeError("locator_resolution_failed")
            send("Input.dispatchMouseEvent", {"type": "mousePressed", "x": point["x"], "y": point["y"], "button": "left", "clickCount": 1})
            send("Input.dispatchMouseEvent", {"type": "mouseReleased", "x": point["x"], "y": point["y"], "button": "left", "clickCount": 1})
            time.sleep(0.5)
        elif action == "fill":
            if "=>" not in value:
                raise RuntimeError("fill step must use selector => value")
            selector, content = [x.strip() for x in value.split("=>", 1)]
            result_fill = fill_input(selector, content)
            if not result_fill or not result_fill.get("ok"):
                raise RuntimeError(result_fill.get("reason", "fill failed"))
        elif action == "press":
            send("Input.dispatchKeyEvent", {"type": "keyDown", "text": value, "key": value})
            send("Input.dispatchKeyEvent", {"type": "keyUp", "text": value, "key": value})
            time.sleep(0.2)
        elif action == "assert_text":
            target = value.split("=", 1)[1] if value.startswith("text=") else value
            if not wait_for_text(target, 2):
                raise RuntimeError("assert_text_failed")
        elif action == "screenshot":
            result["artifact"] = capture(value.replace("/", "-"))
        else:
            raise RuntimeError(f"unsupported_step_action:{action}")
    if result["artifact"] == str(log_file):
        result["artifact"] = capture("final")
    result.update({
        "status": "passed",
        "observed": "devtools browser suite completed successfully",
        "root_cause": "",
        "next_step": "proceed with workflow validation",
        "required_result": "PASS",
        "optional_result": "PASS",
    })
    write_result()
except Exception as exc:
    if ws is not None:
        try:
            result["artifact"] = capture("failure")
        except Exception:
            result["artifact"] = str(log_file)
    else:
        result["artifact"] = str(log_file)
    msg = str(exc)
    status = "blocked_runtime" if ("websocket" in msg or "devtools" in msg) else "failed"
    next_step = "inspect the failing page state and verify the confirmed suite still matches the UI"
    if "unsupported_step_action" in msg:
        next_step = "remove or redesign the unsupported browser step in the confirmed suite"
    elif "locator_resolution_failed" in msg:
        next_step = "inspect the failing page state and verify the confirmed suite still matches the UI"
    elif status == "blocked_runtime":
        next_step = "run omni-context setup-test-runtime <workspace-root> <project-name> --platform web"
    result.update({
        "status": status,
        "failed_step": locals().get("step_name", ""),
        "observed": msg,
        "root_cause": "devtools primary execution failed",
        "next_step": next_step,
    })
    write_result()
finally:
    try:
        ws.close()
    except Exception:
        pass
    cleanup()
PY

python3 - "$RUNS_DIR/${RUN_ID}.md" "$RESULT_JSON" <<'PY'
import json
import re
import sys
from pathlib import Path

run_path = Path(sys.argv[1])
result = json.loads(Path(sys.argv[2]).read_text())
text = run_path.read_text()
status = result["status"]
required_marker = "[required-pass] PASS" if result["required_result"] == "PASS" else "[required-pass] FAIL"
optional_marker = "[optional-pass] PASS" if result["optional_result"] == "PASS" else "[optional-pass] FAIL"
text = re.sub(r"^- run_status:.*$", f"- run_status: {status}", text, flags=re.M)
text = re.sub(r"^- evidence:.*$", f"- evidence: {result['artifact']}", text, flags=re.M)
text = re.sub(r"^- failed_step:.*$", f"- failed_step: {result.get('failed_step', '')}", text, flags=re.M)
text = re.sub(r"^- observed_behavior:.*$", f"- observed_behavior: {result.get('observed', '')}", text, flags=re.M)
text = re.sub(r"^- suspected_root_cause:.*$", f"- suspected_root_cause: {result.get('root_cause', '')}", text, flags=re.M)
text = re.sub(r"^- recommended_next_step:.*$", f"- recommended_next_step: {result.get('next_step', '')}", text, flags=re.M)
text = re.sub(r"(?m)^\- \[required-pass\] PENDING:", f"- {required_marker}:", text)
text = re.sub(r"(?m)^\- \[optional-pass\] PENDING:", f"- {optional_marker}:", text)
if "## Findings\n\n- " in text:
    finding = "devtools browser suite executed successfully" if status == "passed" else "devtools browser suite execution produced a formal failure record"
    text = text.replace("## Findings\n\n- ", f"## Findings\n\n- {finding}", 1)
run_path.write_text(text)
PY

status="$(python3 - "$RESULT_JSON" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1]).read())["status"])
PY
)"
artifact="$(python3 - "$RESULT_JSON" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1]).read())["artifact"])
PY
)"

case "${status}" in
  passed)
    echo "Executed DevTools browser suite ${SUITE_ID}"
    echo "Run: ${RUN_ID}"
    echo "Artifact: ${artifact}"
    ;;
  blocked_runtime)
    echo "DevTools browser suite runtime blocked for ${SUITE_ID}" >&2
    echo "Run: ${RUN_ID}" >&2
    echo "Artifact: ${artifact}" >&2
    exit 2
    ;;
  *)
    echo "DevTools browser suite failed for ${SUITE_ID}" >&2
    echo "Run: ${RUN_ID}" >&2
    echo "Artifact: ${artifact}" >&2
    exit 1
    ;;
esac
