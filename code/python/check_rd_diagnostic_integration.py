"""Read-only validation of the approved Appendix C diagnostic integration.

This checks publication dependencies and hashes, not causal identification.
Use --overleaf-root with the configured synchronized root; --compiled-directory
adds checks of the actual appendix PDF and LaTeX recorder/auxiliary files.
"""
import argparse
import csv
import hashlib
import re
from pathlib import Path


def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expand_tex(path, paper, seen=None):
    """Resolve actual static input/include dependencies within this manuscript."""
    seen = set() if seen is None else seen
    path = path.resolve()
    assert path.is_relative_to(paper.resolve()), f'Unsafe TeX dependency: {path}'
    assert path not in seen, f'Cyclic/repeated TeX dependency: {path}'
    seen.add(path)
    text = re.sub(r'(?<!\\)%[^\n]*', '', path.read_text(encoding='utf-8-sig'))
    def include(match):
        child = paper/(match[1] if Path(match[1]).suffix else match[1]+'.tex')
        return expand_tex(child, paper, seen)
    return re.sub(r'\\(?:input|include)\{([^}]+)\}', include, text)


def check(repo, root, compiled=None):
    paper = root/'World Development Manuscript'
    appendix = expand_tex(paper/'online_appendix.tex', paper)
    calls = re.findall(r'\\includegraphics(?:\[([^]]*)\])?\{([^}]+)\}', appendix)
    review = rows(repo/'metadata/rd-graphical-review-after-election-notes-2026-10-03.csv')
    assert [r['artifact_id'] for r in review] == [f'G{i:02}' for i in range(1,20)]
    expected = {Path(r['path']).name: r for r in review}
    actual = [(options,name) for options,name in calls if Path(name).name in expected]
    assert len(actual)==19, f'Complete diagnostic family not consumed: {len(actual)}/19'
    assert len({name for _,name in actual})==19, 'Repeated diagnostic image caller'
    assert [Path(name).name for _,name in actual]==list(expected), 'Diagnostic order differs from complete review family'
    for options,name in actual:
        assert options.replace(' ','')=='width=\\textwidth', f'Uncleared reduced-width placement: {name}'
        target = (paper/'figures'/name).resolve()
        assert target.is_relative_to((paper/'figures').resolve()), f'Unsafe figure target: {name}'
        row = expected[target.name]
        assert sha(repo/row['path'])==sha(target)==row['current_sha256'], f'Image drift: {name}'

    manifest = {r['path']:r for r in rows(repo/'metadata/rd-validation-output-manifest.csv')}
    assert len(manifest)==36 and all(r['review_status']=='generated_unreviewed' for r in manifest.values())
    integration = rows(repo/'metadata/publication-diagnostic-integration-2026-10-03.csv')
    assert [r['exhibit_id'] for r in integration] == [f'G{i:02}' for i in range(1,20)]+['GT01']
    assert len({r['overleaf_destination'] for r in integration})==20
    for row in integration:
        source = (repo/row['canonical_path']).resolve()
        target = (root/row['overleaf_destination']).resolve()
        caller = (root/row['calling_tex']).resolve()
        assert source.is_relative_to((repo/'output').resolve())
        assert target.is_relative_to(paper.resolve()) and caller.is_relative_to(paper.resolve())
        assert row['owner_approved_internal_draft']=='1' and row['public_release_approved']=='0'
        assert row['status']=='validated_internal_draft_only'
        assert sha(source)==sha(target)==row['canonical_sha256']==row['copied_sha256']
        assert manifest[row['canonical_path']]['checksum']==row['generated_checksum']
        assert manifest[row['canonical_path']]['run_id']==row['generation_run_id']
        assert row['generator']==manifest[row['canonical_path']]['generator']
        assert sha(repo/row['generator'])==row['generator_sha256']
        assert manifest[row['canonical_path']]['input_datasignature']==row['input_datasignature']
        assert target.name in caller.read_text(encoding='utf-8-sig'), f'Absent caller: {target}'
    assert r'\label{tab:rd_validation_covariates}' in appendix, 'Formal table not consumed'
    labels = re.findall(r'\\label\{([^}]+)\}',appendix)
    assert len(labels)==len(set(labels)), 'Duplicate appendix labels'
    assert len([label for label in labels if label.startswith('fig:rd_diag_')])==19

    old = rows(repo/'metadata/publication-draft-integration-2026-10-03.csv')
    assert len(old)==35
    for row in old:
        assert sha(repo/row['canonical_path'])==sha(root/row['overleaf_destination'])==row['canonical_sha256']
        assert row['owner_approved_internal_draft']=='1' and row['public_release_approved']=='0'
    historical = rows(repo/'metadata/rd-graphical-review-after-election-notes-2026-10-03.csv')
    assert all(r['owner_internal_approval']==r['public_release_approval']=='0' for r in historical)

    if compiled:
        from pypdf import PdfReader
        pdf = PdfReader(compiled/'online_appendix.pdf')
        aux = (compiled/'online_appendix.aux').read_text(encoding='utf-8-sig')
        recorder = (compiled/'online_appendix.fls').read_text(encoding='utf-8-sig')
        log = (compiled/'online_appendix.log').read_text(encoding='utf-8-sig')
        assert not re.search(r'undefined|multiply defined|Overfull \\[hv]box|destination.*duplicate|^! ',log,re.I|re.M), 'Unresolved compile diagnostics'
        for row in integration:
            assert Path(row['overleaf_destination']).name in recorder, 'Unused compile dependency'
            label = row['tex_label']
            assert aux.count(r'\newlabel{'+label+'}')==1, f'Unresolved/duplicate compiled label: {label}'
        images = [image for page in pdf.pages for image in page.images]
        assert len(images)==22, f'Appendix image coverage: {len(images)}/22 (19 new + 3 prior)'
        print('PASS: actual appendix compilation;',len(pdf.pages),'pages;',len(images),'embedded images')
    print('PASS: all 19 full-width diagnostics and unchanged formal table; 20 hash-identical new inputs; 35 prior inputs preserved; release holds intact')


if __name__=='__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--overleaf-root',type=Path,required=True)
    parser.add_argument('--compiled-directory',type=Path)
    args=parser.parse_args()
    check(Path(__file__).resolve().parents[2], args.overleaf_root,args.compiled_directory)
