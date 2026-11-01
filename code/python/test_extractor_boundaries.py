"""Intake boundaries: real temporary paths, no project sources or extraction."""
import argparse
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


def load(name):
    path = Path(__file__).with_name(name + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ExtractorBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_cman_refuses_input_output_alias_before_pdf_parsing(self):
        module = load("extract_cman_pdf")
        source = self.root / "input.pdf"
        source.write_bytes(b"immutable PDF fixture")
        args = argparse.Namespace(input=source, output=source,
                                  manifest=self.root / "manifest.json",
                                  expected_pages=1, expected_rows=1)
        with patch.object(module, "parse_args", return_value=args), patch.object(module.pdfplumber, "open") as parser:
            with self.assertRaisesRegex(ValueError, "distinct"):
                module.main()
            parser.assert_not_called()
        self.assertEqual(source.read_bytes(), b"immutable PDF fixture")

    def test_cman_refuses_input_manifest_alias_before_pdf_parsing(self):
        module = load("extract_cman_pdf")
        source = self.root / "input.pdf"
        source.write_bytes(b"immutable PDF fixture")
        args = argparse.Namespace(input=source, output=self.root / "rows.csv",
                                  manifest=source, expected_pages=1, expected_rows=1)
        with patch.object(module, "parse_args", return_value=args), patch.object(module.pdfplumber, "open") as parser:
            with self.assertRaisesRegex(ValueError, "distinct"):
                module.main()
            parser.assert_not_called()
        self.assertEqual(source.read_bytes(), b"immutable PDF fixture")

    def test_cman_refuses_output_manifest_alias_before_pdf_parsing(self):
        module = load("extract_cman_pdf")
        source = self.root / "input.pdf"
        source.write_bytes(b"immutable PDF fixture")
        target = self.root / "same.csv"
        args = argparse.Namespace(input=source, output=target, manifest=target,
                                  expected_pages=1, expected_rows=1)
        with patch.object(module, "parse_args", return_value=args), patch.object(module.pdfplumber, "open") as parser:
            with self.assertRaisesRegex(ValueError, "distinct"):
                module.main()
            parser.assert_not_called()
        self.assertFalse(target.exists())

    def html_args(self, output, manifest, expected=25):
        for number in range(1, 26):
            (self.root / f"ReporteCCPP{number:02}.xls").write_text(f"source{number}", encoding="utf-8")
        return argparse.Namespace(input_dir=self.root, output=output, manifest=manifest,
                                  expected_departments=expected)

    def test_html_refuses_input_output_alias(self):
        module = load("extract_reporte_ccpp_html")
        source = self.root / "ReporteCCPP01.xls"
        args = self.html_args(source, self.root / "manifest.json")
        with patch.object(module, "parse_args", return_value=args), patch.object(module, "extract_file") as parser:
            with self.assertRaisesRegex(ValueError, "distinct"):
                module.main()
            parser.assert_not_called()
        self.assertEqual(source.read_text(), "source1")

    def test_html_refuses_input_manifest_alias(self):
        module = load("extract_reporte_ccpp_html")
        source = self.root / "ReporteCCPP01.xls"
        args = self.html_args(self.root / "rows.csv", source)
        with patch.object(module, "parse_args", return_value=args), patch.object(module, "extract_file") as parser:
            with self.assertRaisesRegex(ValueError, "distinct"):
                module.main()
            parser.assert_not_called()
        self.assertEqual(source.read_text(), "source1")

    def test_html_refuses_output_manifest_alias(self):
        module = load("extract_reporte_ccpp_html")
        target = self.root / "same.csv"
        args = self.html_args(target, target)
        with patch.object(module, "parse_args", return_value=args), patch.object(module, "extract_file") as parser:
            with self.assertRaisesRegex(ValueError, "distinct"):
                module.main()
            parser.assert_not_called()
        self.assertFalse(target.exists())

    def test_html_rejects_unsupported_department_counts_before_extraction(self):
        module = load("extract_reporte_ccpp_html")
        args = self.html_args(self.root / "rows.csv", self.root / "manifest.json", expected=1)
        with patch.object(module, "parse_args", return_value=args), patch.object(module, "extract_file") as parser:
            with self.assertRaisesRegex(ValueError, "25"):
                module.main()
            parser.assert_not_called()


if __name__ == "__main__":
    unittest.main()

