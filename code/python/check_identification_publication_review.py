"""Validate the dated review snapshot without invoking Stata or writing files."""
import argparse
import csv
import hashlib
import pathlib
import re


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def check(root, dropbox=None):
    review = read_csv(root / 'metadata/publication-exhibit-review-2026-09-30.csv')
    canonical = read_csv(root / 'metadata/publication-review-registry.csv')
    sources = read_csv(root / 'metadata/rd-design/identification-evidence-2026-09-30.csv')
    assert len(review) == 99 and len({row['path'] for row in review}) == 99
    assert len({row['review_id'] for row in review}) == 99
    original = {row['path'] for row in review if row['candidate_set'] == 'original_appendix_94'}
    assert len(original) == 94
    assert original == {row['path'] for row in canonical if row['disposition'] == 'appendix'}
    assert len(canonical) == 261 and all(row['owner_approved'] == '0' for row in canonical)
    assert [sum(row['proposed_role'] == role for row in review) for role in ('main_text', 'appendix', 'internal_review')] == [6, 22, 71]
    for row in review:
        path = pathlib.PurePosixPath(row['path'])
        assert not path.is_absolute() and '..' not in path.parts and path.parts[0] == 'output'
        file = (root / path).resolve()
        assert file.is_relative_to((root / 'output').resolve())
        assert file.suffix in ('.tex', '.png')
        assert hashlib.sha256(file.read_bytes()).hexdigest() == row['sha256'], row['path']
        assert row['owner_approved'] == row['release_eligible'] == '0'
        assert row['release_action'] == 'hold_no_sync'
        assert row['scientific_boundary'] and row['presentation_hold']
        assert row['review_date'] == '2026-09-30'
        destination = row['proposed_overleaf_destination']
        if row['proposed_role'] == 'internal_review':
            assert not destination
        else:
            target = pathlib.PurePosixPath(destination)
            kind = 'tables' if file.suffix == '.tex' else 'figures'
            assert target.parts == ('World Development Manuscript', kind, row['proposed_role'], file.name)
            assert not target.is_absolute() and '..' not in target.parts
            assert row['target_exists_at_review'] in ('0', '1')
            assert bool(row['target_sha256_at_review']) == (row['target_exists_at_review'] == '1')
    assert len(sources) == 10 and len({row['source_id'] for row in sources}) == 10
    assert sum(row['source_type'] == 'new_official_intake' for row in sources) == 8
    for row in sources:
        path = pathlib.PurePosixPath(row['logical_project_path'])
        assert path.parts[:2] == ('2 data', '1 Raw') or path.parts[:2] == ('2 data', '0 Support documents')
        assert not path.is_absolute() and '..' not in path.parts
        assert re.fullmatch(r'[a-f0-9]{64}', row['sha256'])
        assert row['redistribution'] == 'not_copied_to_git'
        assert row['verified_date'] == '2026-09-30' and row['verified_pdf_pages']
        if dropbox:
            source = (dropbox / path).resolve()
            assert source.is_relative_to(dropbox.resolve())
            assert hashlib.sha256(source.read_bytes()).hexdigest() == row['sha256'], row['source_id']
    print('PASS: 99 reviewed exhibits, 94 original candidates, 6 main/22 appendix proposals; all release holds and hashes intact.')
    print('PASS: 10 documentary records; 8 new sources.' + (' Dropbox source hashes verified.' if dropbox else ' Use --dropbox-root to verify source files.'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dropbox-root', type=pathlib.Path)
    args = parser.parse_args()
    check(pathlib.Path(__file__).resolve().parents[2], args.dropbox_root)
