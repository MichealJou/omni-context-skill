#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

from xlsx_template import case_workbook_from_rows, report_workbook_from_data, write_workbook


def parse_metadata(text: str) -> dict[str, str]:
    data: dict[str, str] = {}
    for line in text.splitlines():
        m = re.match(r"^- ([a-zA-Z0-9_]+):\s*(.*)$", line.strip())
        if m:
            data[m.group(1)] = m.group(2).strip()
    return data


def parse_section_lines(text: str, heading: str) -> list[str]:
    lines = text.splitlines()
    inside = False
    items: list[str] = []
    for raw in lines:
        line = raw.rstrip()
        if line.strip() == heading:
            inside = True
            continue
        if inside and line.startswith("## "):
            break
        if not inside:
            continue
        stripped = line.strip()
        if not stripped.startswith("- "):
            continue
        items.append(stripped[2:])
    return items


def parse_title(text: str) -> str:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def normalize_status(status: str) -> str:
    mapping = {
        "draft": "Draft",
        "confirmed": "Confirmed",
        "external_locked": "External Locked",
        "ad_hoc_user": "Ad Hoc User",
    }
    return mapping.get(status, status.title() if status else "")


def case_id_for(suite_id: str, required: bool, index: int) -> str:
    suffix = "REQ" if required else "OPT"
    return f"{suite_id}-{suffix}-{index:02d}"


def suite_rows(suites_dir: Path) -> list[list[str]]:
    rows: list[list[str]] = []
    for suite_file in sorted(suites_dir.glob("*.md")):
        text = suite_file.read_text()
        meta = parse_metadata(text)
        title = parse_title(text) or suite_file.stem
        preconditions = "\n".join(parse_section_lines(text, "## Preconditions"))
        steps = []
        for idx, item in enumerate(parse_section_lines(text, "## Steps"), start=1):
            if item.startswith("[step] "):
                steps.append(f"{idx}. {item[7:]}")
            else:
                steps.append(f"{idx}. {item}")
        notes_parts = []
        execution_target = meta.get("execution_target", "")
        interaction_requirement = meta.get("interaction_requirement", "")
        note_lines = parse_section_lines(text, "## Notes")
        if execution_target:
            notes_parts.append(f"execution_target={execution_target}")
        if interaction_requirement:
            notes_parts.append(f"interaction_requirement={interaction_requirement}")
        if note_lines:
            notes_parts.extend(note_lines)
        rows.extend(
            build_case_rows(
                suite_id=meta.get("suite_id", suite_file.stem),
                title=title,
                platform=meta.get("platform", ""),
                status=meta.get("source_status", ""),
                preconditions=preconditions,
                steps="\n".join(steps),
                notes="\n".join(notes_parts),
                items=parse_section_lines(text, "## Required Cases"),
                required=True,
            )
        )
        rows.extend(
            build_case_rows(
                suite_id=meta.get("suite_id", suite_file.stem),
                title=title,
                platform=meta.get("platform", ""),
                status=meta.get("source_status", ""),
                preconditions=preconditions,
                steps="\n".join(steps),
                notes="\n".join(notes_parts),
                items=parse_section_lines(text, "## Optional Cases"),
                required=False,
            )
        )
    return rows


def build_case_rows(
    *,
    suite_id: str,
    title: str,
    platform: str,
    status: str,
    preconditions: str,
    steps: str,
    notes: str,
    items: list[str],
    required: bool,
) -> list[list[str]]:
    rows: list[list[str]] = []
    count = 0
    for item in items:
        m = re.match(r"^\[(required|optional)\]\s*(.*)$", item)
        if m:
            item = m.group(2).strip()
        if not item:
            continue
        count += 1
        rows.append([
            case_id_for(suite_id, required, count),
            suite_id,
            title,
            item,
            item,
            preconditions,
            steps,
            item,
            "P1" if required else "P3",
            "Functional",
            platform,
            "Yes" if required else "No",
            "Candidate",
            normalize_status(status),
            "",
            "",
            "",
            "",
            notes,
        ])
    return rows


def parse_results(text: str) -> list[tuple[str, str, str]]:
    results: list[tuple[str, str, str]] = []
    for line in text.splitlines():
        m = re.match(r"^- \[(required-pass|optional-pass)\]\s+([A-Z]+|PENDING):\s*(.*)$", line.strip())
        if m:
            results.append((m.group(1), m.group(2), m.group(3).strip()))
    return results


def report_data(project_name: str, runs_dir: Path, suites_dir: Path, run_id: str | None) -> tuple[str, list[list[str]], list[list[str]]]:
    if run_id:
        run_file = runs_dir / f"{run_id}.md"
    else:
        candidates = sorted(runs_dir.glob("*.md"))
        if not candidates:
            raise SystemExit("No test runs recorded")
        run_file = candidates[-1]
    if not run_file.exists():
        raise SystemExit(f"Missing run file: {run_file}")
    text = run_file.read_text()
    meta = parse_metadata(text)
    suite_id = meta.get("suite_id", "")
    suite_text = ""
    if suite_id and (suites_dir / f"{suite_id}.md").exists():
        suite_text = (suites_dir / f"{suite_id}.md").read_text()
    suite_title = parse_title(suite_text) or suite_id
    results = parse_results(text)
    passed = sum(1 for _, status, _ in results if status == "PASS")
    failed = sum(1 for _, status, _ in results if status == "FAIL")
    pending = sum(1 for _, status, _ in results if status == "PENDING")
    blocked = 1 if meta.get("run_status", "") == "blocked_runtime" else 0
    total = len(results)
    not_run = pending
    pass_rate = f"{(passed / total * 100):.1f}%" if total else "0.0%"
    summary_rows = [
        ["Report ID", run_file.stem],
        ["Project Name", project_name],
        ["Test Cycle", suite_title or suite_id],
        ["Test Date", run_file.stem[:8] if len(run_file.stem) >= 8 else ""],
        ["Build Version", ""],
        ["Environment", meta.get("platform", "")],
        ["Scope", suite_id],
        ["Total Cases", str(total)],
        ["Passed", str(passed)],
        ["Failed", str(failed)],
        ["Blocked", str(blocked)],
        ["Not Run", str(not_run)],
        ["Pass Rate", pass_rate],
        ["Defects Found", ""],
        ["Critical Defects", ""],
        ["Conclusion", meta.get("run_status", "")],
        ["Risks", meta.get("suspected_root_cause", "")],
        ["Open Issues", meta.get("recommended_next_step", "")],
        ["Evidence Path", meta.get("evidence", "")],
        ["Author", ""],
        ["Reviewer", ""],
    ]
    detail_rows: list[list[str]] = []
    req_index = 0
    opt_index = 0
    for result_type, status, title in results:
        required = result_type == "required-pass"
        if required:
            req_index += 1
            case_id = case_id_for(suite_id or "suite", True, req_index)
        else:
            opt_index += 1
            case_id = case_id_for(suite_id or "suite", False, opt_index)
        severity = "High" if status == "FAIL" else ""
        detail_rows.append([
            case_id,
            title,
            status,
            severity,
            meta.get("platform", ""),
            run_file.stem,
            "",
            meta.get("evidence", ""),
        ])
    return run_file.stem, summary_rows, detail_rows


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: test_excel_sync.py <cases|report> ...", file=sys.stderr)
        return 1
    mode = sys.argv[1]
    if mode == "cases":
        if len(sys.argv) != 4:
            print("Usage: test_excel_sync.py cases <suites-dir> <output>", file=sys.stderr)
            return 1
        suites_dir = Path(sys.argv[2])
        output = Path(sys.argv[3])
        rows = suite_rows(suites_dir) if suites_dir.exists() else []
        write_workbook(output, case_workbook_from_rows(rows))
        print(output)
        return 0
    if mode == "report":
        if len(sys.argv) not in {6, 7}:
            print("Usage: test_excel_sync.py report <project-name> <runs-dir> <suites-dir> <output> [run-id]", file=sys.stderr)
            return 1
        project_name = sys.argv[2]
        runs_dir = Path(sys.argv[3])
        suites_dir = Path(sys.argv[4])
        output = Path(sys.argv[5])
        run_id = sys.argv[6] if len(sys.argv) == 7 else None
        resolved_run_id, summary_rows, detail_rows = report_data(project_name, runs_dir, suites_dir, run_id)
        write_workbook(output, report_workbook_from_data(summary_rows, detail_rows))
        print(f"{output}|{resolved_run_id}")
        return 0
    print(f"Unknown mode: {mode}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
