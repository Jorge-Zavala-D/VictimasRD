"""Read-only SHA-256 verification of the recorded Stata installation/cache.

Not called by the Stata master. Native Stata performs its own checksum guard.
No installation, network request, file repair, or research-data access occurs.
"""
import argparse
import csv
import hashlib
from pathlib import Path, PurePosixPath
import sys

EXECUTABLE_SUFFIXES = {'.ado', '.mata', '.mlib', '.mo', '.plugin', '.scheme', '.style'}
REQUIRED_FIELDS = {'root_role', 'relative_path', 'bytes', 'sha256', 'stata_checksum',
                   'package', 'release_marker', 'source', 'resolution_name', 'lock_id'}


def verify_files(manifest, ado_root, stata_root=None):
    """Return violations, including omitted project executable/support files."""
    errors, expected, seen_names = [], set(), set()
    roots = {'project_ado': Path(ado_root).resolve()}
    if stata_root is not None:
        roots['stata_install'] = Path(stata_root).resolve()
        roots['official_base'] = roots['stata_install'] / 'ado/base'
    with Path(manifest).open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        if set(reader.fieldnames or []) != REQUIRED_FIELDS:
            return ['invalid manifest fields']
        rows = list(reader)
    if not rows:
        return ['empty manifest']
    seen_paths = set()
    for row in rows:
        role, relative = row['root_role'], row['relative_path']
        path = PurePosixPath(relative)
        if (not relative or '\\' in relative or path.is_absolute() or
                '..' in path.parts or ':' in relative or relative != path.as_posix()):
            errors.append(f'unsafe path: {relative}')
            continue
        key = (role, relative.lower())
        if key in seen_paths:
            errors.append(f'duplicate path: {role}/{relative}')
        seen_paths.add(key)
        if role not in {'project_ado', 'stata_install', 'official_base'}:
            errors.append(f'unknown root role: {role}')
            continue
        if role not in roots:
            errors.append(f'missing root argument: {role}')
            continue
        if role == 'project_ado':
            name = row['resolution_name'].lower()
            if not name or name in seen_names or name != path.name.lower():
                errors.append(f'duplicate or invalid resolution name: {name}')
            seen_names.add(name)
            expected.add(relative.lower())
        try:
            size, native = int(row['bytes']), int(row['stata_checksum'])
            if size < 0 or not 0 <= native <= 4294967295:
                raise ValueError
        except (ValueError, TypeError):
            errors.append(f'invalid numeric fingerprint: {role}/{relative}')
            continue
        digest = row['sha256']
        if len(digest) != 64 or any(c not in '0123456789abcdef' for c in digest):
            errors.append(f'invalid sha256: {role}/{relative}')
            continue
        target = (roots[role] / relative).resolve()
        if not target.is_relative_to(roots[role]):
            errors.append(f'unsafe path: {relative}')
            continue
        if not target.is_file():
            errors.append(f'missing file: {role}/{relative}')
            continue
        if target.stat().st_size != size:
            errors.append(f'byte-length mismatch: {role}/{relative}')
        h = hashlib.sha256()
        with target.open('rb') as f:
            for block in iter(lambda: f.read(1024 * 1024), b''):
                h.update(block)
        if h.hexdigest() != digest:
            errors.append(f'sha256 mismatch: {role}/{relative}')
    actual = {p.relative_to(roots['project_ado']).as_posix().lower()
              for p in roots['project_ado'].rglob('*')
              if p.is_file() and p.suffix.lower() in EXECUTABLE_SUFFIXES}
    errors.extend(f'unlocked executable: {p}' for p in sorted(actual - expected))
    if 'official_base' in roots:
        actual_base = {p.relative_to(roots['official_base']).as_posix().lower()
                       for p in roots['official_base'].rglob('*') if p.is_file()}
        expected_base = {relative for role, relative in seen_paths if role == 'official_base'}
        errors.extend(f'unlocked official file: {p}' for p in sorted(actual_base - expected_base))
    return errors


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, default=Path(__file__).resolve().parents[2] /
                        'metadata/stata-dependency-lock-2026-10-03.csv')
    parser.add_argument('--ado-root', type=Path, required=True)
    parser.add_argument('--stata-root', type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        errors = verify_files(args.manifest, args.ado_root, args.stata_root)
    except (OSError, csv.Error) as exc:
        errors = [f'unreadable environment/manifest: {exc}']
    if errors:
        for error in errors: print('FAIL:', error)
        return 1
    print('PASS: exact SHA-256 identities, manifest structure, and cache/base inventory')
    return 0


if __name__ == '__main__':
    sys.exit(main())
