"""Behavioral tests for the offline dependency checker (no Stata invocation)."""
import csv
import hashlib
import importlib.util
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


    def test_git_checkout_preserves_literal_lock_under_both_settings(self):
        repo = Path(__file__).resolve().parents[2]
        relative = 'metadata/stata-dependency-lock-2026-10-03.csv'
        reviewed = (repo / relative).read_bytes()
        self.assertEqual(hashlib.sha256(reviewed).hexdigest(),
                         'd010f2891149fc6e9026b3b501ca0ff0ad1b14087b8919c669e6532ae35e7616')
        fixture = self.root / 'git-fixture'
        fixture.mkdir()

        def git(*args, input=None):
            return subprocess.run(['git', '-C', str(fixture), *args], input=input,
                                  check=True, capture_output=True).stdout.strip().decode()

        git('init', '-q')
        # Reproduce the normalized LF blob already stored in the real Git index.
        blob = git('hash-object', '-w', '--stdin', input=reviewed.replace(b'\r\n', b'\n'))
        git('update-index', '--add', '--cacheinfo', f'100644,{blob},{relative}')
        attributes = repo / '.gitattributes'
        if attributes.is_file():
            blob = git('hash-object', '-w', '--stdin', input=attributes.read_bytes())
            git('update-index', '--add', '--cacheinfo', f'100644,{blob},.gitattributes')
        for setting in ('false', 'true'):
            with self.subTest(autocrlf=setting):
                git('config', 'core.autocrlf', setting)
                checkout = self.root / ('checkout-' + setting)
                git('checkout-index', '--all', '--prefix=' + checkout.as_posix() + '/')
                restored = (checkout / relative).read_bytes()
                self.assertEqual(hashlib.sha256(restored).hexdigest(),
                                 hashlib.sha256(reviewed).hexdigest())
                self.assertEqual(len(restored), 2755021)


if __name__ == '__main__':
    unittest.main()
