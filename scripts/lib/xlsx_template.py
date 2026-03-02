#!/usr/bin/env python3
from __future__ import annotations

import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape


def col_letter(index: int) -> str:
    result = ""
    while index > 0:
        index, rem = divmod(index - 1, 26)
        result = chr(65 + rem) + result
    return result


def xml_header() -> str:
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'


def content_types(sheet_count: int) -> str:
    overrides = [
        '<Override PartName="/xl/workbook.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
        '<Override PartName="/xl/styles.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
        '<Override PartName="/docProps/core.xml" '
        'ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>',
        '<Override PartName="/docProps/app.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>',
    ]
    for idx in range(1, sheet_count + 1):
        overrides.append(
            f'<Override PartName="/xl/worksheets/sheet{idx}.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        )
    return (
        xml_header()
        + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        + '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        + '<Default Extension="xml" ContentType="application/xml"/>'
        + "".join(overrides)
        + "</Types>"
    )


def root_rels() -> str:
    return (
        xml_header()
        + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        + '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
        'Target="xl/workbook.xml"/>'
        + '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" '
        'Target="docProps/core.xml"/>'
        + '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" '
        'Target="docProps/app.xml"/>'
        + "</Relationships>"
    )


def app_props(sheet_names: list[str]) -> str:
    titles = "".join(f"<vt:lpstr>{escape(name)}</vt:lpstr>" for name in sheet_names)
    return (
        xml_header()
        + '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
        'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
        + "<Application>OmniContext</Application>"
        + "<HeadingPairs><vt:vector size=\"2\" baseType=\"variant\">"
        + "<vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>"
        + f"<vt:variant><vt:i4>{len(sheet_names)}</vt:i4></vt:variant>"
        + "</vt:vector></HeadingPairs>"
        + f"<TitlesOfParts><vt:vector size=\"{len(sheet_names)}\" baseType=\"lpstr\">{titles}</vt:vector></TitlesOfParts>"
        + "</Properties>"
    )


def core_props() -> str:
    return (
        xml_header()
        + '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:dcmitype="http://purl.org/dc/dcmitype/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        + "<dc:creator>OmniContext</dc:creator>"
        + "<cp:lastModifiedBy>OmniContext</cp:lastModifiedBy>"
        + "</cp:coreProperties>"
    )


def workbook(sheet_names: list[str]) -> str:
    sheets = []
    for idx, name in enumerate(sheet_names, start=1):
        sheets.append(
            f'<sheet name="{escape(name)}" sheetId="{idx}" r:id="rId{idx}"/>'
        )
    return (
        xml_header()
        + '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        + "<sheets>"
        + "".join(sheets)
        + "</sheets></workbook>"
    )


def workbook_rels(sheet_count: int) -> str:
    rels = []
    for idx in range(1, sheet_count + 1):
        rels.append(
            f'<Relationship Id="rId{idx}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
            f'Target="worksheets/sheet{idx}.xml"/>'
        )
    rels.append(
        f'<Relationship Id="rId{sheet_count + 1}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
        'Target="styles.xml"/>'
    )
    return (
        xml_header()
        + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        + "".join(rels)
        + "</Relationships>"
    )


def styles() -> str:
    return (
        xml_header()
        + '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        + '<fonts count="3">'
        + '<font><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/></font>'
        + '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        + '<font><b/><sz val="11"/><color rgb="FF1F2937"/><name val="Calibri"/><family val="2"/></font>'
        + "</fonts>"
        + '<fills count="3">'
        + '<fill><patternFill patternType="none"/></fill>'
        + '<fill><patternFill patternType="gray125"/></fill>'
        + '<fill><patternFill patternType="solid"><fgColor rgb="FF1D4ED8"/><bgColor indexed="64"/></patternFill></fill>'
        + "</fills>"
        + '<borders count="2">'
        + '<border><left/><right/><top/><bottom/><diagonal/></border>'
        + '<border><left style="thin"><color rgb="FFD1D5DB"/></left><right style="thin"><color rgb="FFD1D5DB"/></right>'
        + '<top style="thin"><color rgb="FFD1D5DB"/></top><bottom style="thin"><color rgb="FFD1D5DB"/></bottom><diagonal/></border>'
        + "</borders>"
        + '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        + '<cellXfs count="4">'
        + '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        + '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>'
        + '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
        + '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>'
        + "</cellXfs>"
        + '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        + "</styleSheet>"
    )


def worksheet(sheet: dict) -> str:
    widths = "".join(
        f'<col min="{idx}" max="{idx}" width="{width}" customWidth="1"/>'
        for idx, width in enumerate(sheet["widths"], start=1)
    )
    rows_xml = []
    for row_idx, row in enumerate(sheet["rows"], start=1):
        cells = []
        style = "1" if row_idx == 1 else "2"
        if row and row[0] == "__SECTION__":
            row = ["", row[1]]
            style = "3"
        for col_idx, value in enumerate(row, start=1):
            cell_ref = f"{col_letter(col_idx)}{row_idx}"
            if value is None:
                continue
            text = escape(str(value))
            cells.append(
                f'<c r="{cell_ref}" t="inlineStr" s="{style}"><is><t>{text}</t></is></c>'
            )
        rows_xml.append(f'<row r="{row_idx}" spans="1:{len(row)}">{"".join(cells)}</row>')
    return (
        xml_header()
        + '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        + f"<cols>{widths}</cols>"
        + f"<sheetData>{''.join(rows_xml)}</sheetData>"
        + "</worksheet>"
    )


def write_workbook(path: Path, sheets: list[dict]) -> None:
    sheet_names = [sheet["name"] for sheet in sheets]
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types(len(sheets)))
        zf.writestr("_rels/.rels", root_rels())
        zf.writestr("docProps/app.xml", app_props(sheet_names))
        zf.writestr("docProps/core.xml", core_props())
        zf.writestr("xl/workbook.xml", workbook(sheet_names))
        zf.writestr("xl/_rels/workbook.xml.rels", workbook_rels(len(sheets)))
        zf.writestr("xl/styles.xml", styles())
        for idx, sheet in enumerate(sheets, start=1):
            zf.writestr(f"xl/worksheets/sheet{idx}.xml", worksheet(sheet))


def case_workbook() -> list[dict]:
    return [
        {
            "name": "Cases",
            "widths": [18, 20, 18, 22, 28, 28, 42, 36, 12, 14, 12, 10, 14, 14, 18, 18, 16, 16, 18],
            "rows": [
                [
                    "Case ID",
                    "Source Suite",
                    "Module",
                    "Requirement",
                    "Case Title",
                    "Preconditions",
                    "Test Steps",
                    "Expected Result",
                    "Priority",
                    "Case Type",
                    "Platform",
                    "Required",
                    "Automation",
                    "Status",
                    "Linked Defect",
                    "Owner",
                    "Reviewer",
                    "Updated At",
                    "Notes",
                ],
                [
                    "TC-001",
                    "login-smoke",
                    "Authentication",
                    "User login",
                    "Valid user can sign in",
                    "Account exists and is active",
                    "1. Open login page\n2. Enter valid username/password\n3. Click Sign in",
                    "Dashboard is shown and session is created",
                    "P1",
                    "Functional",
                    "Web",
                    "Yes",
                    "Candidate",
                    "Draft",
                    "",
                    "",
                    "",
                    "",
                    "",
                ],
            ],
        },
        {
            "name": "Instructions",
            "widths": [22, 88],
            "rows": [
                ["Field", "Guidance"],
                ["__SECTION__", "Workbook purpose"],
                ["Purpose", "Use this workbook as the formal test case register for a project or workflow."],
                ["__SECTION__", "Field rules"],
                ["Case ID", "Unique ID such as TC-001, API-001, MINIAPP-001."],
                ["Module", "Business module or page name."],
                ["Requirement", "The requirement point or acceptance item covered by the case."],
                ["Test Steps", "Keep ordered steps in one cell using line breaks."],
                ["Expected Result", "Describe the observable result, not the action."],
                ["Required", "Yes for must-pass cases, No for optional coverage."],
                ["Automation", "Candidate, Automated, or Manual."],
                ["Status", "Draft, Reviewed, Confirmed, Deprecated."],
            ],
        },
    ]


def report_workbook() -> list[dict]:
    return [
        {
            "name": "Summary",
            "widths": [22, 42],
            "rows": [
                ["Field", "Value"],
                ["Report ID", ""],
                ["Project Name", ""],
                ["Test Cycle", ""],
                ["Test Date", ""],
                ["Build Version", ""],
                ["Environment", ""],
                ["Scope", ""],
                ["Total Cases", ""],
                ["Passed", ""],
                ["Failed", ""],
                ["Blocked", ""],
                ["Not Run", ""],
                ["Pass Rate", ""],
                ["Defects Found", ""],
                ["Critical Defects", ""],
                ["Conclusion", ""],
                ["Risks", ""],
                ["Open Issues", ""],
                ["Evidence Path", ""],
                ["Author", ""],
                ["Reviewer", ""],
            ],
        },
        {
            "name": "Execution Details",
            "widths": [18, 24, 28, 12, 12, 14, 18, 24],
            "rows": [
                [
                    "Case ID",
                    "Case Title",
                    "Execution Result",
                    "Severity",
                    "Platform",
                    "Run ID",
                    "Defect ID",
                    "Evidence",
                ],
                ["TC-001", "Valid user can sign in", "PASS", "", "Web", "", "", ""],
            ],
        },
        {
            "name": "Instructions",
            "widths": [22, 88],
            "rows": [
                ["Field", "Guidance"],
                ["__SECTION__", "Workbook purpose"],
                ["Purpose", "Use this workbook as the formal test report for a release, workflow, or execution cycle."],
                ["__SECTION__", "Completion rules"],
                ["Summary", "Complete one row per summary field before review."],
                ["Execution Details", "List each executed case with PASS, FAIL, BLOCKED, or NOT RUN."],
                ["Evidence", "Reference screenshots, logs, trace files, or API captures stored under tests/artifacts/."],
            ],
        },
    ]


def case_workbook_from_rows(rows: list[list[str]]) -> list[dict]:
    sheet_rows = [[
        "Case ID",
        "Source Suite",
        "Module",
        "Requirement",
        "Case Title",
        "Preconditions",
        "Test Steps",
        "Expected Result",
        "Priority",
        "Case Type",
        "Platform",
        "Required",
        "Automation",
        "Status",
        "Linked Defect",
        "Owner",
        "Reviewer",
        "Updated At",
        "Notes",
    ]]
    sheet_rows.extend(rows)
    return [
        {
            "name": "Cases",
            "widths": [18, 20, 18, 22, 28, 28, 42, 36, 12, 14, 12, 10, 14, 14, 18, 18, 16, 16, 18],
            "rows": sheet_rows,
        },
        {
            "name": "Instructions",
            "widths": [22, 88],
            "rows": [
                ["Field", "Guidance"],
                ["__SECTION__", "Workbook purpose"],
                ["Purpose", "This workbook is generated from tests/suites/*.md and should be treated as the formal Excel register for review and handoff."],
                ["__SECTION__", "Generation rules"],
                ["Source Suite", "The suite_id from the Markdown source used to generate the case row."],
                ["Case ID", "Generated as <suite_id>-REQ-XX or <suite_id>-OPT-XX to keep Excel and Markdown aligned."],
                ["Required", "Yes means the case comes from Required Cases. No means Optional Cases."],
                ["Status", "Mapped from suite source_status, for example draft -> Draft, confirmed -> Confirmed."],
                ["Notes", "Includes execution target, interaction requirement, and suite notes when available."],
            ],
        },
    ]


def report_workbook_from_data(summary_rows: list[list[str]], detail_rows: list[list[str]]) -> list[dict]:
    summary = [["Field", "Value"]]
    summary.extend(summary_rows)
    details = [[
        "Case ID",
        "Case Title",
        "Execution Result",
        "Severity",
        "Platform",
        "Run ID",
        "Defect ID",
        "Evidence",
    ]]
    details.extend(detail_rows)
    return [
        {
            "name": "Summary",
            "widths": [22, 42],
            "rows": summary,
        },
        {
            "name": "Execution Details",
            "widths": [18, 24, 28, 12, 12, 18, 18, 24],
            "rows": details,
        },
        {
            "name": "Instructions",
            "widths": [22, 88],
            "rows": [
                ["Field", "Guidance"],
                ["__SECTION__", "Workbook purpose"],
                ["Purpose", "This workbook is generated from tests/runs/*.md as the formal Excel report for one run."],
                ["__SECTION__", "Generation rules"],
                ["Execution Details", "Rows are derived from required-pass and optional-pass result lines in the run record."],
                ["Evidence", "Points to files stored under tests/artifacts/ or other recorded evidence paths."],
            ],
        },
    ]


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: xlsx_template.py <cases|report> <output-path>", file=sys.stderr)
        return 1
    kind = sys.argv[1]
    output = Path(sys.argv[2])
    if kind == "cases":
        sheets = case_workbook()
    elif kind == "report":
        sheets = report_workbook()
    else:
        print(f"Unknown workbook kind: {kind}", file=sys.stderr)
        return 1
    write_workbook(output, sheets)
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
