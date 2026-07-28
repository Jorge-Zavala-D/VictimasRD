"""Extract department CCPP reports saved as HTML with an .xls extension.

The source files are treated as immutable. The program reads every
``ReporteCCPP*.xls`` file, validates its six-column administrative table,
deduplicates byte-identical downloads, and writes one UTF-8 CSV plus a JSON
manifest to caller-supplied paths.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import tempfile
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path


EXTRACTOR_VERSION = "1.0.0"
EXPECTED_HEADERS = [
    "#",
    "DEPARTAMENTO",
    "PROVINCIA",
    "DISTRITO",
    "CENTRO POBLADO",
    "AREA",
]
OUTPUT_COLUMNS = [
    "source_file",
    "source_sha256",
    "source_row_number",
    "region_raw",
    "province_raw",
    "district_raw",
    "community_raw",
    "area_raw",
    "ubigeo_dpto",
    "ubigeo_prov",
    "ubigeo_dist",
    "ubigeo_ccpp",
]


class TableParser(HTMLParser):
    """Collect text from every HTML table row and cell."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tables: list[list[list[str]]] = []
        self._table_depth = 0
        self._current_table: list[list[str]] | None = None
        self._current_row: list[str] | None = None
        self._current_cell: list[str] | None = None

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        del attrs
        tag = tag.lower()
        if tag == "table":
            self._table_depth += 1
            if self._table_depth == 1:
                self._current_table = []
        elif tag == "tr" and self._table_depth == 1:
            self._close_row()
            self._current_row = []
        elif tag in {"td", "th"} and self._current_row is not None:
            self._current_cell = []

    def handle_data(self, data: str) -> None:
        if self._current_cell is not None:
            self._current_cell.append(data)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in {"td", "th"} and self._current_cell is not None:
            assert self._current_row is not None
            self._current_row.append(normalize_space("".join(self._current_cell)))
            self._current_cell = None
        elif tag == "tr" and self._current_row is not None:
            self._close_row()
        elif tag in {"thead", "tbody"} and self._current_row is not None:
            self._close_row()
        elif tag == "table":
            self._close_row()
            if self._table_depth == 1 and self._current_table is not None:
                self.tables.append(self._current_table)
                self._current_table = None
            self._table_depth -= 1

    def _close_row(self) -> None:
        if self._current_row is None:
            return
        assert self._current_table is not None
        if any(self._current_row):
            self._current_table.append(self._current_row)
        self._current_row = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--expected-departments", type=int, default=25)
    return parser.parse_args()


def normalize_space(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def normalize_header(value: str) -> str:
    return re.sub(r"[^A-Z0-9#]+", " ", value.upper()).strip()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def split_code_name(value: str, digits: int, label: str) -> tuple[str, str]:
    match = re.fullmatch(rf"\s*([0-9]{{{digits}}})\s+(.+?)\s*", value)
    if not match:
        raise ValueError(f"Invalid {label} value: {value!r}")
    return match.group(1), normalize_space(match.group(2))


def atomic_csv_write(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8-sig",
        newline="",
        dir=path.parent,
        delete=False,
        suffix=".tmp",
    ) as stream:
        writer = csv.DictWriter(stream, fieldnames=OUTPUT_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)
        temporary_path = Path(stream.name)
    os.replace(temporary_path, path)


def atomic_json_write(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=path.parent,
        delete=False,
        suffix=".tmp",
    ) as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
        temporary_path = Path(stream.name)
    os.replace(temporary_path, path)


def extract_file(path: Path, digest: str) -> tuple[list[dict[str, object]], int]:
    text = path.read_text(encoding="iso-8859-1")
    found_match = re.search(r"Encontrados:\s*</td>\s*<td>:</td>\s*"
                            r"<td>\s*([0-9]+)\s+Registro", text, re.I)
    if not found_match:
        raise ValueError(f"{path.name}: reported row count was not found")
    reported_rows = int(found_match.group(1))

    parser = TableParser()
    parser.feed(text)
    candidate_tables: list[list[list[str]]] = []
    for table in parser.tables:
        if not table:
            continue
        header = [normalize_header(value) for value in table[0]]
        if header == EXPECTED_HEADERS:
            candidate_tables.append(table)
    if len(candidate_tables) != 1:
        raise ValueError(
            f"{path.name}: expected one administrative table; "
            f"found {len(candidate_tables)}"
        )

    table_rows = candidate_tables[0][1:]
    data_rows: list[list[str]] = []
    footer_rows: list[list[str]] = []
    for cells in table_rows:
        if len(cells) == 6 and re.fullmatch(r"[0-9]+", cells[0]):
            data_rows.append(cells)
        else:
            footer_rows.append(cells)
    if any(
        len(cells) != 1 or normalize_space(cells[0]) != "Derechos Reservados INEI"
        for cells in footer_rows
    ):
        raise ValueError(f"{path.name}: unexpected non-data rows {footer_rows!r}")

    rows: list[dict[str, object]] = []
    for source_row_number, cells in enumerate(data_rows, start=1):
        if len(cells) != 6:
            raise ValueError(
                f"{path.name}, row {source_row_number}: "
                f"expected 6 cells; found {len(cells)}"
            )
        try:
            listed_row = int(cells[0])
        except ValueError as exc:
            raise ValueError(
                f"{path.name}, row {source_row_number}: "
                f"invalid row number {cells[0]!r}"
            ) from exc
        if listed_row != source_row_number:
            raise ValueError(
                f"{path.name}: row sequence breaks at {source_row_number}"
            )

        ubigeo_dpto, region = split_code_name(cells[1], 2, "department")
        ubigeo_prov, province = split_code_name(cells[2], 4, "province")
        ubigeo_dist, district = split_code_name(cells[3], 6, "district")
        ccpp_code, community = split_code_name(cells[4], 4, "community")
        if not (
            ubigeo_prov.startswith(ubigeo_dpto)
            and ubigeo_dist.startswith(ubigeo_prov)
        ):
            raise ValueError(
                f"{path.name}, row {source_row_number}: "
                "administrative-code hierarchy is inconsistent"
            )

        rows.append(
            {
                "source_file": path.name,
                "source_sha256": digest,
                "source_row_number": source_row_number,
                "region_raw": region,
                "province_raw": province,
                "district_raw": district,
                "community_raw": community,
                "area_raw": normalize_space(cells[5]),
                "ubigeo_dpto": ubigeo_dpto,
                "ubigeo_prov": ubigeo_prov,
                "ubigeo_dist": ubigeo_dist,
                "ubigeo_ccpp": ubigeo_dist + ccpp_code,
            }
        )

    if len(rows) != reported_rows:
        raise ValueError(
            f"{path.name}: report states {reported_rows} rows; "
            f"extracted {len(rows)}"
        )
    return rows, reported_rows


def main() -> None:
    args = parse_args()
    input_dir = args.input_dir.resolve(strict=True)
    paths = sorted(input_dir.glob("ReporteCCPP*.xls"))
    if not paths:
        raise ValueError("No ReporteCCPP*.xls files were found")

    file_records: list[dict[str, object]] = []
    digest_to_canonical: dict[str, str] = {}
    extracted: list[dict[str, object]] = []

    for path in paths:
        digest = sha256(path)
        source_stat = path.stat()
        duplicate_of = digest_to_canonical.get(digest, "")
        if duplicate_of:
            file_records.append(
                {
                    "filename": path.name,
                    "size_bytes": source_stat.st_size,
                    "sha256": digest,
                    "duplicate_of": duplicate_of,
                    "reported_rows": None,
                    "extracted_rows": 0,
                    "department_code": None,
                }
            )
            continue

        digest_to_canonical[digest] = path.name
        rows, reported_rows = extract_file(path, digest)
        department_codes = sorted({str(row["ubigeo_dpto"]) for row in rows})
        if len(department_codes) != 1:
            raise ValueError(
                f"{path.name}: expected one department; found {department_codes}"
            )
        extracted.extend(rows)
        file_records.append(
            {
                "filename": path.name,
                "size_bytes": source_stat.st_size,
                "sha256": digest,
                "duplicate_of": "",
                "reported_rows": reported_rows,
                "extracted_rows": len(rows),
                "department_code": department_codes[0],
            }
        )

    departments = sorted({str(row["ubigeo_dpto"]) for row in extracted})
    expected_departments = [f"{value:02d}" for value in range(1, 26)]
    if args.expected_departments == 25 and departments != expected_departments:
        raise ValueError(
            f"Expected department codes 01-25; found {departments}"
        )

    codes = [str(row["ubigeo_ccpp"]) for row in extracted]
    if len(codes) != len(set(codes)):
        raise ValueError("Combined ReporteCCPP codes are not unique")

    output = args.output.resolve()
    manifest = args.manifest.resolve()
    atomic_csv_write(output, extracted)
    output_digest = sha256(output)

    manifest_payload = {
        "extractor": "code/python/extract_reporte_ccpp_html.py",
        "extractor_version": EXTRACTOR_VERSION,
        "extracted_at_utc": datetime.now(timezone.utc).isoformat(),
        "input_directory": str(input_dir),
        "source_glob": "ReporteCCPP*.xls",
        "source_files_found": len(paths),
        "unique_source_files": len(digest_to_canonical),
        "duplicate_source_files": len(paths) - len(digest_to_canonical),
        "files": file_records,
        "department_codes": departments,
        "output_filename": output.name,
        "output_rows": len(extracted),
        "output_columns": OUTPUT_COLUMNS,
        "output_sha256": output_digest,
        "validation": {
            "all_reports_are_html": True,
            "one_administrative_table_per_unique_file": True,
            "six_columns_per_table": True,
            "reported_row_counts_match": True,
            "department_codes_complete": True,
            "administrative_hierarchies_valid": True,
            "ccpp_codes_unique": True,
        },
    }
    atomic_json_write(manifest, manifest_payload)

    print(
        json.dumps(
            {
                "status": "ok",
                "source_files": len(paths),
                "unique_source_files": len(digest_to_canonical),
                "rows": len(extracted),
                "output_sha256": output_digest,
            }
        )
    )


if __name__ == "__main__":
    main()
