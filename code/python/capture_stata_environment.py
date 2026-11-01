"""Capture a candidate Stata installation inventory; never update packages.

This maintenance utility is not called by the Stata master. The old manifest
stays immutable. Project PLUS bytes must match it exactly; only installed
engine/BASE identities are observed anew. Stata MCP supplies native checksums.
A captured candidate is not an approved lock or a compatibility certificate.
"""
import argparse
import csv
import hashlib
from pathlib import Path, PurePosixPath

from check_stata_environment_lock import EXECUTABLE_SUFFIXES, REQUIRED_FIELDS


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def capture(old_manifest, ado_root, stata_root, lock_id):
    with old_manifest.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if set(reader.fieldnames or []) != REQUIRED_FIELDS:
            raise ValueError("invalid old manifest fields")
        previous = list(reader)
    if not previous or not lock_id:
        raise ValueError("empty manifest or candidate identity")
    old = {}
    for row in previous:
        relative = PurePosixPath(row["relative_path"])
        if (relative.is_absolute() or ".." in relative.parts
                or ":" in str(relative) or "\\" in str(relative)):
            raise ValueError("unsafe old manifest path")
        key = (row["root_role"], row["relative_path"])
        if key in old:
            raise ValueError("duplicate old manifest path")
        old[key] = row

    package_rows = [row for row in previous if row["root_role"] == "project_ado"]
    expected = {row["relative_path"] for row in package_rows}
    actual = {p.relative_to(ado_root).as_posix() for p in ado_root.rglob("*")
              if p.is_file() and p.suffix.lower() in EXECUTABLE_SUFFIXES}
    if actual != expected:
        raise ValueError("unlocked project executable or missing project package")
    rows = []
    for row in package_rows:
        target = ado_root / row["relative_path"]
        if not target.resolve().is_relative_to(ado_root.resolve()):
            raise ValueError("unsafe project package target")
        if sha(target) != row["sha256"] or target.stat().st_size != int(row["bytes"]):
            raise ValueError("project package changed: " + row["relative_path"])
        rows.append({**row, "lock_id": lock_id})

    base = stata_root / "ado" / "base"
    groups = [
        ("stata_install", stata_root, [stata_root / "StataMP-64.exe", stata_root / "mp-64.dll"]),
        ("official_base", base, sorted(p for p in base.rglob("*") if p.is_file())),
    ]
    for role, root, paths in groups:
        for path in paths:
            if not path.resolve().is_relative_to(root.resolve()):
                raise ValueError("unsafe installed-file target")
            relative = path.relative_to(root).as_posix()
            digest = sha(path)
            prior = old.get((role, relative), {})
            native = prior.get("stata_checksum", "") if digest == prior.get("sha256") else ""
            rows.append(dict(root_role=role, relative_path=relative,
                             bytes=str(path.stat().st_size), sha256=digest,
                             stata_checksum=native, package="Stata19-installed-files",
                             release_marker="", source="licensed-local-installation-no-redistribution",
                             resolution_name="", lock_id=lock_id))
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--old-manifest", type=Path, required=True)
    parser.add_argument("--ado-root", type=Path, required=True)
    parser.add_argument("--stata-root", type=Path, required=True)
    parser.add_argument("--lock-id", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists() or args.output.suffix.lower() != ".csv":
        raise ValueError("candidate output must be a new CSV; never replace a lock")
    rows = capture(args.old_manifest, args.ado_root, args.stata_root, args.lock_id)
    with args.output.open("x", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Candidate only: {len(rows)} identities; project PLUS unchanged; native checks pending")


if __name__ == "__main__":
    main()

