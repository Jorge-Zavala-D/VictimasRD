"""Behavioral tests for the offline dependency checker (no Stata invocation)."""
import csv
import hashlib
import importlib.util
import json
from collections import Counter
from pathlib import Path
import subprocess
import tempfile
import unittest


class EnvironmentLockTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.ado = self.root / 'ado'
        (self.ado / 'r').mkdir(parents=True)
        self.file = self.ado / 'r/sample.ado'
        self.file.write_bytes(b'program sample\nend\n')
        self.manifest = self.root / 'lock.csv'
        self.row = {'root_role': 'project_ado', 'relative_path': 'r/sample.ado', 'bytes': '19',
                    'sha256': hashlib.sha256(b'program sample\nend\n').hexdigest(),
                    'stata_checksum': '0', 'package': 'sample',
                    'release_marker': '', 'source': 'fixture',
                    'resolution_name': 'sample.ado', 'lock_id': 'fixture'}
        self.write_rows([self.row])
        module = Path(__file__).with_name('check_stata_environment_lock.py')
        self.assertTrue(module.is_file(), 'Offline lock checker is not implemented')
        spec = importlib.util.spec_from_file_location('environment_lock', module)
        self.checker = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.checker)

    def write_rows(self, rows):
        with self.manifest.open('w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=list(self.row))
            writer.writeheader()
            writer.writerows(rows)

    def test_accepts_exact_locked_bytes(self):
        self.assertEqual(self.checker.verify_files(self.manifest, self.ado), [])

    def test_detects_same_length_mutation(self):
        self.file.write_bytes(b'program SAMPLE\nend\n')
        self.assertIn('sha256 mismatch', '\n'.join(self.checker.verify_files(self.manifest, self.ado)))

    def test_detects_missing_file(self):
        self.file.unlink()
        self.assertIn('missing file', '\n'.join(self.checker.verify_files(self.manifest, self.ado)))

    def test_rejects_parent_traversal(self):
        self.row['relative_path'] = '../outside.ado'
        self.write_rows([self.row])
        self.assertIn('unsafe path', '\n'.join(self.checker.verify_files(self.manifest, self.ado)))

    def test_rejects_duplicate_resolution_names(self):
        self.write_rows([self.row, self.row])
        self.assertIn('duplicate', '\n'.join(self.checker.verify_files(self.manifest, self.ado)))

    def test_rejects_empty_manifest(self):
        self.write_rows([])
        self.assertIn('empty manifest', '\n'.join(self.checker.verify_files(self.manifest, self.ado)))

    def test_rejects_unlocked_executable_file(self):
        (self.ado / 'r/extra.mo').write_bytes(b'unreviewed')
        self.assertIn('unlocked executable', '\n'.join(self.checker.verify_files(self.manifest, self.ado)))


    def test_prospective_lock_preserves_project_metadata(self):
        repo = Path(__file__).resolve().parents[2]
        records = []
        for date in ('2026-10-03', '2026-11-01'):
            with (repo / f'metadata/stata-dependency-lock-{date}.csv').open(
                    encoding='utf-8-sig', newline='') as stream:
                records.append({row['relative_path']: {k: v for k, v in row.items() if k != 'lock_id'}
                                for row in csv.DictReader(stream) if row['root_role'] == 'project_ado'})
        self.assertEqual(len(records[0]), 267)
        self.assertEqual(records[0], records[1])

    def test_runtime_record_matches_active_manifest_and_guard(self):
        repo = Path(__file__).resolve().parents[2]
        runtime = json.loads((repo / 'metadata/stata-runtime-lock-2026-11-01.json').read_text())
        manifest = repo / runtime['manifest']
        content = manifest.read_bytes()
        self.assertEqual(hashlib.sha256(content).hexdigest(), runtime['manifest_sha256'])
        self.assertEqual(len(content), runtime['manifest_bytes'])
        with manifest.open(encoding='utf-8-sig', newline='') as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(len(rows), runtime['file_counts']['total'])
        for role, count in Counter(row['root_role'] for row in rows).items():
            self.assertEqual(count, runtime['file_counts'][role])
        guard = (repo / 'code/stata/lib/00_validate_environment.do').read_text()
        self.assertIn(f"r(checksum) != {runtime['manifest_stata_checksum']}", guard)
        self.assertIn(f"r(filelen) != {runtime['manifest_bytes']}", guard)
        self.assertIn(runtime['manifest'], guard)
        self.assertIn(runtime['lock_id'], guard)

    def test_git_checkout_preserves_literal_lock_under_both_settings(self):
        repo = Path(__file__).resolve().parents[2]
        locks = [
            ('2026-10-03', 'd010f2891149fc6e9026b3b501ca0ff0ad1b14087b8919c669e6532ae35e7616', 2755021),
            ('2026-11-01', 'd15827937408ccb47bdeeb1130d2e24eeb3b2c41aac03183658cacaf9a1ddd28', 2770842),
        ]
        for date, digest, size in locks:
            relative = f'metadata/stata-dependency-lock-{date}.csv'
            reviewed = (repo / relative).read_bytes()
            self.assertEqual(hashlib.sha256(reviewed).hexdigest(), digest)
            fixture = self.root / ('git-fixture-' + date)
            fixture.mkdir()

            def git(*args, input=None):
                return subprocess.run(['git', '-C', str(fixture), *args], input=input,
                                      check=True, capture_output=True).stdout.strip().decode()

            git('init', '-q')
            blob = git('hash-object', '-w', '--stdin', input=reviewed.replace(b'\r\n', b'\n'))
            git('update-index', '--add', '--cacheinfo', f'100644,{blob},{relative}')
            blob = git('hash-object', '-w', '--stdin', input=(repo / '.gitattributes').read_bytes())
            git('update-index', '--add', '--cacheinfo', f'100644,{blob},.gitattributes')
            for setting in ('false', 'true'):
                with self.subTest(lock=date, autocrlf=setting):
                    git('config', 'core.autocrlf', setting)
                    checkout = self.root / ('checkout-' + date + '-' + setting)
                    git('checkout-index', '--all', '--prefix=' + checkout.as_posix() + '/')
                    restored = (checkout / relative).read_bytes()
                    self.assertEqual(hashlib.sha256(restored).hexdigest(), digest)
                    self.assertEqual(len(restored), size)


if __name__ == '__main__':
    unittest.main()
