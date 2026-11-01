"""Small, real-filesystem fixtures for prospective environment capture."""
import csv
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest


class CaptureEnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.ado = self.root / "ado"
        self.base = self.root / "stata" / "ado" / "base"
        (self.ado / "r").mkdir(parents=True)
        (self.base / "r").mkdir(parents=True)
        self.package = self.ado / "r" / "example.ado"
        self.package.write_bytes(b"program example\nend\n")
        (self.base / "r" / "regress.ado").write_bytes(b"official fixture")
        (self.base.parents[1] / "StataMP-64.exe").write_bytes(b"engine fixture")
        (self.base.parents[1] / "mp-64.dll").write_bytes(b"dll fixture")
        self.row = dict(root_role="project_ado", relative_path="r/example.ado",
                        bytes=str(self.package.stat().st_size),
                        sha256=hashlib.sha256(self.package.read_bytes()).hexdigest(),
                        stata_checksum="123", package="example", release_marker="fixture",
                        source="fixture", resolution_name="example.ado", lock_id="old")
        self.manifest = self.root / "old.csv"
        with self.manifest.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(self.row))
            writer.writeheader()
            writer.writerow(self.row)
        module = Path(__file__).with_name("capture_stata_environment.py")
        self.assertTrue(module.is_file(), "Prospective capture is not implemented")
        spec = importlib.util.spec_from_file_location("capture_environment", module)
        self.capture = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.capture)

    def test_captures_current_official_files_without_changing_old_manifest(self):
        before = self.manifest.read_bytes()
        rows = self.capture.capture(self.manifest, self.ado, self.base.parents[1], "candidate")
        self.assertEqual(self.manifest.read_bytes(), before)
        self.assertEqual(len(rows), 4)
        self.assertEqual(next(r for r in rows if r["root_role"] == "project_ado")["sha256"],
                         self.row["sha256"])
        self.assertTrue(all(r["lock_id"] == "candidate" for r in rows))

    def test_rejects_changed_package_instead_of_adopting_it(self):
        self.package.write_bytes(b"changed package")
        with self.assertRaisesRegex(ValueError, "project package changed"):
            self.capture.capture(self.manifest, self.ado, self.base.parents[1], "candidate")

    def test_rejects_unlocked_executable_in_project_cache(self):
        (self.ado / "r" / "extra.mo").write_bytes(b"extra")
        with self.assertRaisesRegex(ValueError, "unlocked project"):
            self.capture.capture(self.manifest, self.ado, self.base.parents[1], "candidate")

    def test_includes_new_official_files_explicitly(self):
        (self.base / "r" / "new.sthlp").write_bytes(b"new official help")
        rows = self.capture.capture(self.manifest, self.ado, self.base.parents[1], "candidate")
        new = next(r for r in rows if r["relative_path"] == "r/new.sthlp")
        self.assertEqual(new["root_role"], "official_base")
        self.assertEqual(new["bytes"], "17")
        self.assertEqual(new["stata_checksum"], "")


if __name__ == "__main__":
    unittest.main()

