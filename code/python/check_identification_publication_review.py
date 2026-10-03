"""Validate the dated review snapshot without invoking Stata or writing files."""
import argparse
import csv
import hashlib
import pathlib
import re


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def tex_rows(path):
    text = path.read_text(encoding='utf-8-sig')
    marker = r'\endhead' if r'\endhead' in text else r'\midrule'
    body = text.split(marker, 1)[1].split(r'\bottomrule', 1)[0]
    return [[cell.strip() for cell in line.replace(r'\\', '').split('&')]
            for line in body.splitlines() if '&' in line and r'\multicolumn' not in line]


def assert_cells(original, recorded):
    assert original == recorded, 'Source cells differ from the review ledger'


def assert_hold(row):
    assert row['owner_approved'] == row['release_eligible'] == '0'
    assert row['release_action'] == 'hold_no_sync'
    assert row['review_status'] == 'generated_unreviewed'


def check_pack(root):
    directory = root / 'output/tables/publication'
    exhibits = read_csv(directory / 'publication_review_exhibits.csv')
    ledger = read_csv(directory / 'publication_review_cells.csv')
    assert len(exhibits) == 35 and len({row['path'] for row in exhibits}) == 35
    assert [sum(row['proposed_role'] == role for row in exhibits)
            for role in ('main_text', 'appendix')] == [6, 29]
    assert sum(row['path'].endswith('.png') for row in exhibits) == 5
    retained_rows = 0
    for exhibit in exhibits:
        assert_hold(exhibit)
        assert re.fullmatch(r'\d+', exhibit['checksum'])
        assert re.fullmatch(r'\d+', exhibit['source_checksum'])
        path = pathlib.PurePosixPath(exhibit['path'])
        assert not path.is_absolute() and '..' not in path.parts and path.parts[0] == 'output'
        recorded = [row for row in ledger if row['exhibit_id'] == exhibit['exhibit_id']]
        if not recorded:
            continue
        original = tex_rows(root / exhibit['source_path'])
        rendered = tex_rows(root / path)
        assert len(original) == len(recorded) == len(rendered), exhibit['exhibit_id']
        source_text = (root / exhibit['source_path']).read_text(encoding='utf-8-sig')
        rendered_text = (root / path).read_text(encoding='utf-8-sig')
        if 'design_diagnostics' in str(path):
            if r'SW \(F_D\)' in source_text:
                assert r'SW \(F_D\) / \(F_{D M}\)' in rendered_text
            else:
                assert r'Min. SW \(F\) & KP \(F\) & Support & IV gate' in rendered_text
        for order, (cells, stored, display) in enumerate(zip(original, recorded, rendered), 1):
            assert int(stored['row_order']) == order
            assert_cells(cells + [''] * (8 - len(cells)), [stored[f'cell{i}'] for i in range(1, 9)])
            display_text = ' '.join(display)
            for index, cell in enumerate(cells):
                if 'design_diagnostics' in str(path) and index in (1, 2, 3):
                    cell = f'{float(cell):,.0f}'
                assert not cell or cell in display_text, (exhibit['exhibit_id'], order, cell)
        retained_rows += len(original)
    assert retained_rows == len(ledger) == 287
    project_se = [row for row in read_csv(root / 'output/tables/rd_heterogeneity/rd_hte_2017_ccpp_project_discontinuities.csv')
                  if row['component_id'].startswith('group_')]
    assert len(project_se) == 4
    project_path = next(row['path'] for row in exhibits if row['exhibit_id'] == 'A08')
    for row, display in zip(project_se, tex_rows(root / project_path)):
        assert row['component_label'] == display[0]
        assert f"({float(row['standard_error']):.2f})" in display[-1]
    results = {year: {level: read_csv(root / f'output/tables/rd_outcomes/rd_{year}_{level}_results.csv')
                     for level in ('ccpp', 'household', 'individual')} for year in (2013, 2017)}
    primary = [row for levels in results.values() for rows in levels.values() for row in rows
               if row['tier'] == 'primary' and row['spec_id'] == 'common_h_fuzzy' and row['estimand'] == 'fuzzy_late']
    assert len(primary) == 48
    macros = dict(re.findall(r'\\newcommand\{\\(\w+)\}\{([^}]*)\}',
                            (directory / 'publication_results_values.tex').read_text()))
    assert int(macros['PrimaryTests']) == len(primary)
    assert int(macros['PrimarySignals']) == sum(float(row['p_holm']) < .05 for row in primary)
    migration = next(row for row in primary if row['outcome_id'] == 'I03' and row in results[2017]['individual'])
    for name, field in [('MigrationEffect', 'estimate_bc'), ('MigrationLower', 'ci_low'), ('MigrationUpper', 'ci_high')]:
        assert macros[name] == f'{float(migration[field]):.2f}'
    assert int(macros['MigrationN'].replace(',', '')) == int(float(migration['n_eff_left']) + float(migration['n_eff_right']))
    assert int(macros['MigrationCCPP']) == int(float(migration['ccpp_left']) + float(migration['ccpp_right']))
    for name, field in [('MigrationP', 'pvalue'), ('MigrationHolm', 'p_holm')]:
        assert macros[name] == f'{float(migration[field]):.3f}'
    first_stage = next(row for row in results[2017]['individual']
                       if row['outcome_id'] == 'I03' and row['spec_id'] == 'parametric_common_h')
    assert macros['MigrationF'] == f"{float(first_stage['first_stage_f']):.2f}"
    selection = next(row for row in results[2017]['household']
                     if row['outcome_id'] == 'D05' and row['estimand'] == 'selection')
    for name, field in [('HouseholdSelectionEffect', 'estimate_bc'), ('HouseholdSelectionLower', 'ci_low'), ('HouseholdSelectionUpper', 'ci_high')]:
        assert macros[name] == f'{float(selection[field]):.2f}'
    assert macros['HouseholdSelectionP'] == f"{float(selection['pvalue']):.4f}"
    tables = {row['exhibit_id']: tex_rows(root / row['path']) for row in exhibits
              if row['exhibit_id'] in ('A25', 'A26', 'A27', 'A28')}
    intervals = sorted(read_csv(root / 'output/tables/rd_mechanisms/rd_census2017_selection_intervals.csv'),
                       key=lambda row: (row['frame'], row['side']))
    assert len(tables['A25']) == len(intervals) == 6
    interval_text = (directory / 'A25_supplement.tex').read_text(encoding='utf-8-sig')
    assert 'Side intervals: percent' in interval_text and 'differences: percentage points' in interval_text, 'A25 display units are not explicit'
    for row, display in zip(intervals, tables['A25']):
        assert display[2] == f"[{100 * float(row['lower']):.2f}, {100 * float(row['upper']):.2f}]"
        if row['side'] == 'above_minus_below':
            assert display[1] == 'Difference' and display[3] == '--'
    assignment_adjusted_total = assignment_signal_total = 0
    for display in tables['A26']:
        year, unit = display[0].split()
        rows = read_csv(root / f'output/tables/rd_heterogeneity/rd_hte_{year}_{unit.lower()}_results.csv')
        iv = [row for row in rows if row['spec_id'] == 'common_h_iv' and row['estimand'] == 'fuzzy_late_interaction']
        assignment = [row for row in rows if row['spec_id'] == 'common_h_rdhte' and row['estimand'] == 'assignment_hte']
        passed = [row for row in iv if row['gate_pass'] == '1']
        def adjusted_summary(candidates, assignment_only=False):
            eligible = [row for row in candidates if row['gate_status'] in ('assignment_hte_supported', 'secondary_assignment_supported')
                        and row['estimation_rc'] == '0'] if assignment_only else [row for row in candidates if row['gate_pass'] == '1']
            probabilities = [row['p_holm'] if row['moderator_tier'] == 'primary' else row['q_bh']
                             for row in eligible]
            available = [float(value) for value in probabilities if value]
            signals = str(sum(value < .05 for value in available)) if available else '--'
            return f'{len(available)} / {signals}'
        expected = [str(len(iv)), str(len(passed)), adjusted_summary(iv),
                    str(len(assignment)), adjusted_summary(assignment, assignment_only=True)]
        assert display[1:] == expected
        available, signals = expected[-1].split(' / ')
        assignment_adjusted_total += int(available)
        assignment_signal_total += int(signals) if signals != '--' else 0
    assert int(macros['AssignmentAdjusted']) == assignment_adjusted_total
    assert int(macros['AssignmentSignals']) == assignment_signal_total
    intermediate = sorted([row for row in read_csv(root / 'output/tables/rd_mechanisms/rd_migration_mechanism_summary.csv')
                           if row['evidence_class'] == 'mechanism_outcome_effect'],
                          key=lambda row: (row['wave'], row['level'], row['outcome_id']))
    assert len(tables['A27']) == len(intermediate) == 37
    for row, display in zip(intermediate, tables['A27']):
        assert row['outcome_label'] == display[1]
        assert f"{float(row['estimate_bc']):.2f}" in display[2]
        assert f"[{float(row['ci_low']):.2f}, {float(row['ci_high']):.2f}]" in display[2]
        assert display[3] == f"{float(row['p_holm']):.3f}"
    associations = sorted(read_csv(root / 'output/tables/rd_mechanisms/rd_migration_mechanism_associations.csv'),
                          key=lambda row: (row['analysis_id'], row['spec_id']))
    assert len(tables['A28']) == len(associations) == 6
    association_text = (directory / 'A28_supplement.tex').read_text(encoding='utf-8-sig')
    assert '2017-source altitude' in association_text and '2007 log population' in association_text and '2007 wellbeing' in association_text, 'A28 covariate years are inaccurate'
    assert '60 communities' in association_text and '42 districts' in association_text and 'unweighted OLS' in association_text and 'local standard deviation' in association_text, 'A28 model/sample note is incomplete'
    for row, display in zip(associations, tables['A28']):
        assert f"{float(row['estimate']):.3f}" in display[2]
        assert f"[{float(row['ci_low']):.3f}, {float(row['ci_high']):.3f}]" in display[2]
    # Negative controls exercise guards without altering any artifact.
    for guard, args in [(assert_hold, ({**exhibits[0], 'owner_approved': '1'},)),
                        (assert_cells, (['21.45'], ['99.99']))]:
        try:
            guard(*args)
        except AssertionError:
            continue
        raise AssertionError('Negative control was not rejected')
    print('PASS: 35 review exhibits; all 287 source rows retained; diagnostic headers, project SEs, narrative values and negative controls verified.')


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
    parser.add_argument('--review-pack', action='store_true')
    args = parser.parse_args()
    check(pathlib.Path(__file__).resolve().parents[2], args.dropbox_root)
    if args.review_pack:
        check_pack(pathlib.Path(__file__).resolve().parents[2])
