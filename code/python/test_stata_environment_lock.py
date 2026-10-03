"""Behavioral tests for the offline dependency checker (no Stata invocation)."""
import csv
import hashlib
import importlib.util
from pathlib import Path
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


if __name__ == '__main__':
    unittest.main()
