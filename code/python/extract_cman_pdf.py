"""Extract the 2023 CMAN project table from its publication PDF.

The source PDF is treated as immutable. This program writes a row-preserving
CSV plus a machine-readable extraction manifest to caller-supplied paths.
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
from decimal import Decimal, InvalidOperation
from pathlib import Path

import pdfplumber


EXTRACTOR_VERSION = "1.0.0"

EXPECTED_HEADER = [
    "N",
    "REGIÓN",
    "PROVINCIA",
    "DISTRITO",
    "COMUNIDAD",
    "PROYECTO",
    "Año",
    "Dispositivo legal",
    "Financiamiento",
    "COFINAN.",
    "UNIDAD EJECUTORA",
]

OUTPUT_COLUMNS = [
    "record_number",
    "region_raw",
    "province_raw",
    "district_raw",
    "community_raw",
    "project_raw",
    "recorded_year_raw",
    "legal_instrument_raw",
    "cman_financing_raw",
    "cofinancing_raw",
    "executing_unit_raw",
    "source_page",
    "source_row_on_page",
]

TABLE_SETTINGS = {
    "vertical_strategy": "lines",
    "horizontal_strategy": "lines",
    "snap_tolerance": 3,
    "join_tolerance": 3,
    "edge_min_length": 3,
    "intersection_tolerance": 4,
    "text_tolerance": 2,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--expected-pages", type=int, default=283)
    parser.add_argument("--expected-rows", type=int, default=4433)
    return parser.parse_args()


def normalize_cell(value: object) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", str(value)).strip()


def normalize_header(value: object) -> str:
    text = normalize_cell(value).upper()
    text = (
        text.replace("Á", "A")
        .replace("É", "E")
        .replace("Í", "I")
        .replace("Ó", "O")
        .replace("Ú", "U")
        .replace("Ñ", "N")
    )
    return re.sub(r"[^A-Z0-9]+", "", text)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def money_is_numeric(value: str) -> bool:
    try:
        Decimal(value.replace(",", ""))
    except InvalidOperation:
        return False
    return True


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


def main() -> None:
    args = parse_args()
    source = args.input.resolve(strict=True)
    source_stat = source.stat()
    source_digest = sha256(source)
    extracted: list[dict[str, object]] = []
    page_row_counts: dict[str, int] = {}
    observed_headers: set[tuple[str, ...]] = set()
    money_parse_issues: list[dict[str, object]] = []
    year_parse_issues: list[dict[str, object]] = []

    with pdfplumber.open(source) as pdf:
        if len(pdf.pages) != args.expected_pages:
            raise ValueError(
                f"Expected {args.expected_pages} PDF pages; found {len(pdf.pages)}"
            )

        for page_number, page in enumerate(pdf.pages, start=1):
            tables = page.extract_tables(TABLE_SETTINGS)
            if len(tables) != 1:
                raise ValueError(
                    f"Page {page_number}: expected one table; found {len(tables)}"
                )

            table = tables[0]
            if not table:
                raise ValueError(f"Page {page_number}: extracted table is empty")
            if any(len(row) != len(EXPECTED_HEADER) for row in table):
                widths = sorted({len(row) for row in table})
                raise ValueError(
                    f"Page {page_number}: expected 11 columns; found widths {widths}"
                )

            header = tuple(normalize_cell(value) for value in table[0])
            observed_headers.add(header)
            normalized_header = [normalize_header(value) for value in header]
            expected_normalized = [normalize_header(value) for value in EXPECTED_HEADER]
            if normalized_header != expected_normalized:
                raise ValueError(
                    f"Page {page_number}: unexpected table header {header!r}"
                )

            data_rows = table[1:]
            page_row_counts[str(page_number)] = len(data_rows)

            for source_row_on_page, raw_row in enumerate(data_rows, start=1):
                cells = [normalize_cell(value) for value in raw_row]
                if not any(cells):
                    continue

                try:
                    record_number = int(cells[0])
                except ValueError as exc:
                    raise ValueError(
                        f"Page {page_number}, row {source_row_on_page}: "
                        f"invalid record number {cells[0]!r}"
                    ) from exc

                required = {
                    "region": cells[1],
                    "province": cells[2],
                    "district": cells[3],
                    "community": cells[4],
                    "project": cells[5],
                    "year": cells[6],
                    "financing": cells[8],
                    "executing unit": cells[10],
                }
                missing = [name for name, value in required.items() if not value]
                if missing:
                    raise ValueError(
                        f"Record {record_number}: missing required fields {missing}"
                    )

                if not re.fullmatch(r"20(?:0[7-9]|1[0-9]|2[0-3])", cells[6]):
                    year_parse_issues.append(
                        {
                            "record_number": record_number,
                            "source_page": page_number,
                            "raw_value": cells[6],
                            "four_digit_candidates": re.findall(r"\b20\d{2}\b", cells[6]),
                        }
                    )
                for field, value in (
                    ("cman_financing_raw", cells[8]),
                    ("cofinancing_raw", cells[9]),
                ):
                    if not money_is_numeric(value):
                        money_parse_issues.append(
                            {
                                "record_number": record_number,
                                "source_page": page_number,
                                "field": field,
                                "raw_value": value,
                            }
                        )

                extracted.append(
                    {
                        "record_number": record_number,
                        "region_raw": cells[1],
                        "province_raw": cells[2],
                        "district_raw": cells[3],
                        "community_raw": cells[4],
                        "project_raw": cells[5],
                        "recorded_year_raw": cells[6],
                        "legal_instrument_raw": cells[7],
                        "cman_financing_raw": cells[8],
                        "cofinancing_raw": cells[9],
                        "executing_unit_raw": cells[10],
                        "source_page": page_number,
                        "source_row_on_page": source_row_on_page,
                    }
                )

    record_numbers = [int(row["record_number"]) for row in extracted]
    expected_numbers = list(range(1, args.expected_rows + 1))
    if len(extracted) != args.expected_rows:
        raise ValueError(
            f"Expected {args.expected_rows} rows; extracted {len(extracted)}"
        )
    if record_numbers != expected_numbers:
        raise ValueError(
            "Record numbers are not unique and consecutive from 1 through "
            f"{args.expected_rows}"
        )

    output = args.output.resolve()
    manifest = args.manifest.resolve()
    atomic_csv_write(output, extracted)
    output_digest = sha256(output)

    manifest_payload = {
        "extractor": "code/python/extract_cman_pdf.py",
        "extractor_version": EXTRACTOR_VERSION,
        "extracted_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_filename": source.name,
        "source_size_bytes": source_stat.st_size,
        "source_modified_time_utc": datetime.fromtimestamp(
            source_stat.st_mtime, timezone.utc
        ).isoformat(),
        "source_sha256": source_digest,
        "source_pages": args.expected_pages,
        "observed_header_variants": [list(header) for header in sorted(observed_headers)],
        "output_filename": output.name,
        "output_rows": len(extracted),
        "output_columns": OUTPUT_COLUMNS,
        "output_sha256": output_digest,
        "record_number_min": min(record_numbers),
        "record_number_max": max(record_numbers),
        "page_row_counts": page_row_counts,
        "money_parse_issues": money_parse_issues,
        "year_parse_issues": year_parse_issues,
        "validation": {
            "one_table_per_page": True,
            "eleven_columns_per_table": True,
            "headers_match": True,
            "record_numbers_consecutive": True,
            "required_fields_nonmissing": True,
            "years_in_2007_2023": not year_parse_issues,
            "financing_fields_numeric": not money_parse_issues,
        },
    }
    atomic_json_write(manifest, manifest_payload)

    print(
        json.dumps(
            {
                "status": "ok",
                "rows": len(extracted),
                "pages": args.expected_pages,
                "source_sha256": source_digest,
                "output_sha256": output_digest,
            }
        )
    )


if __name__ == "__main__":
    main()
