# Corrective publication production — 3 October 2026

## Binding scope

The project lead authorized the corrective milestone recorded in
`MANUSCRIPT_INTEGRATION_PREFLIGHT_2026-10-03.md`. The starting checkout is clean
on `main` at `dfee26eacb8c807ae3277f87707af17de291a9d5`.

Preserve the selected geography, adjacent B/C support, recorded score,
`treat_12`/`treat_16`, outcome populations, common windows, estimators,
clustering, multiplicity families, numerical evidence and release holds.
Raw/archive sources and all existing Overleaf sources/inputs are protected.
This batch does not authorize a new design search or automatic exhibit sync.

## Execution and completion contract

1. Reproduce the presentation defects and defensive failures before editing
   production code. Test real Stata eligibility/statistic commands with ordinary
   and extended missing values; check actual generated table units/notes.
2. Repair the producing code: A25 side levels are percentages, while differences
   are percentage points; A28 uses 2017-source altitude and 2007 population and
   wellbeing; A29 must retain every denominator and nonignorability qualifier
   at manuscript scale. Require both conditional-F statistics before taking
   their minimum and explicit known age for adult eligibility.
3. Regenerate module 07 and its manifest through `stata_run_selection`, using
   the master execution path without changing saved switches. Run module 08
   and the full existing assertion suite plus focused regression checks.
   Verify source/numeric invariance independently and inspect the affected
   tables/figure at the live paper's 165.1 mm text width.
4. Record artifact-specific scientific, disclosure and presentation review.
   Preserve owner/release holds until a separate explicit integration decision
   identifies the cleared exhibit and exact live destination. Complete one
   independent final review and provide an uncommitted change/commit handoff.

## Interpretation constraints

A25 remains a descriptive finite-source-support display, not an eligible-adult
bound, confidence interval, RD effect or fuzzy-LATE bound. A28 remains an
unweighted ecological association, not causal mediation. A29 shows distinct
parent frames, not a sequential attrition funnel or evidence of ignorable
selection. Existing original-artifact presentation holds are not erased by
repairing these review derivatives.

## Validation receipt

The saved master was run through `stata_run_selection` with only modules 07
and 08 enabled in the in-memory selection; the saved switches were not edited.
The run completed on 3 October 2026 at 01:43:53. All 13 Stata contract tests,
including the new production-command regression test, passed. The independent
publication checker passed all 99 original-artifact hashes, 10 documentary
hashes, 35 review derivatives and 287 retained table-body rows. Module 08 still
reports `BLOCKED` with `technical_error == 0`: no scientific, disclosure or
owner hold was bypassed.

### Producing-code repairs and focused checks

- A25 now labels side intervals as percentages and differences as percentage
  points. Its six body rows are byte-identical to the pre-edit table.
- A28 now identifies 2017-source altitude, 2007 log population and 2007
  wellbeing, as well as unweighted OLS on 60 communities with 42 district
  clusters. Its six body rows are byte-identical to the pre-edit table.
- A29 has short, spanning title/subtitle lines and a deliberately wrapped
  seven-line note. All six rates and parent/observed counts still come from
  the unchanged source CSV; this is not a sequential attrition funnel.
- The CCPP heterogeneity block now requires both conditional-F statistics to
  be nonmissing before taking their minimum. All 32 current IV rows with
  unavailable conditional-F statistics already fail support and instrument
  gates; no passing row changes. The strict `F > 10` rule is unchanged.
- Both Census-2017 individual modules now explicitly exclude missing age from
  adult eligibility, including repeated complete-case and auxiliary age
  comparisons in module 04f. In the selected B/C population, no linked record
  with observed movement has missing age. The original and guarded primary
  predicates select exactly the same 67,648 people, including 7,680 local
  people in 63 communities.
  Linked selected records with missing age but observed marital status,
  approximate education years or indigenous-language status also number zero
  for each component; the auxiliary age guards do not alter those current
  candidate outcomes.

`code/stata/tests/test_publication_defensive_guards.do` executes the actual
production expressions against finite, boundary, ordinary-missing and
extended-missing fixtures. Before the repairs it reproduced the missing-F
minimum defect and three missing-age adult misclassifications; after the
repairs it passes. It does not save a dataset or re-estimate a model.

### Artifact-level review

The compiled review packet uses the live manuscript's Letter page, 12-point
base type and 165.1 mm text width. It has 46 pages, no overfull boxes,
undefined references or multiply-defined labels, and no text outside the page
bounds. A25, A28 and A29 were inspected individually on pages 41, 45 and 46;
their labels and complete notes are readable without clipping or overlap.
All 46 pages were also scanned in three contact sheets. This overview is a
layout screen, not an independent re-adjudication of every original result.
The long SISFOH household registry's note occupies a continuation page (25);
that noncritical review-packet pagination is not a new scientific result or
a reason to modify the frozen registry.

`metadata/publication-corrective-review-2026-10-03.csv` records the three
artifact-specific SHA-256 source/output identities, numerical-invariance
checks, bounded interpretation, aggregate-only disclosure review, final-scale
presentation clearance and continuing owner/release holds. The generated
exhibit registry deliberately retains `generated_unreviewed` and
`hold_no_sync`; the human review receipt supplements it without editing
generated classifications or authorizing a live replacement.

The preview PDF SHA-256 is
`ebb8ce5f7d1ba4cafe8c9c1bc17627f8dba145833df3d64b02e438a3fdccca64`.
Batch baselines, execution receipts and rendered previews remain in the
ignored `build/corrective-publication-2026-10-03/` area. No observation-level
dataset is stored there. All pre-existing Overleaf files and all frozen
module-04/05/06 numerical sources are unchanged.

### Coverage and remaining boundary

This batch validates the corrective code, actual edge-case expressions,
current-population invariance, regenerated publication outputs and their
manifests. It does not rerun the complete raw-data pipeline or every large
heterogeneity/migration estimation. No sample, estimand, timing, clustering,
weighting, bandwidth, multiplicity family or numerical inference was changed.
No raw/archive, Working, Coded or live Overleaf file was written; nothing was
staged, committed or pushed.

The required read-only literature integrations were consulted. NotebookLM's
exact-project query was unavailable in the unauthenticated integration;
Zotero supplied read-only discovery metadata but no new underlying passage
was used as methodological authority. The corrections instead verify the
actual frozen models and producing code, without adding a scholarly claim.

## Independent final review and closeout

The fresh, read-only `corrective_final_review` reviewer independently checked
the changed source, all conditional-F call sites, repeated eligibility paths,
actual association-model provenance, MCP RED/GREEN receipts, both test logs,
preservation audit, publication checker, three SHA-256 ledger pairs, changed
manifest fields and the rendered packet. The verdict is ready to complete this
bounded corrective batch, with no unresolved Critical, Important or actionable
Minor finding in its scope. A suspected test-helper cleanup problem was
withdrawn after exact source inspection and a direct same-session test repeat
both confirmed the existing cleanup is correct; no speculative repair was made.

The reviewer explicitly did not certify new causal identification, historical
assignment/selection assumptions, full raw-data reproduction or model
re-estimation, broader preparation-module age coding, whole-project ethics/
licensing/confidentiality, byte-level identity of every Dropbox dataset,
whole-packet pagination, new literature/whole-paper citations, live integration
or release, or authorization to commit/merge. Those are accepted scope
boundaries, not newly reopened empirical contracts. Their decisions and costs
are recorded in the ignored batch ledger. The three corrected derivatives have
bounded artifact-level review; the full research project is not thereby
certified for publication.

All 141 pre-existing live Overleaf files are byte-identical to their baseline.
The starting checkout was clean, so the 17-file proposed Git scope belongs to
this batch rather than pre-existing uncommitted work. `git diff --check` passes,
HEAD and branch are unchanged and the index is empty. The copy-ready commit
message is stored in ignored `build/COMMIT_MESSAGE.txt`; audit evidence is
preserved because no commit has been authorized. The next publication step is
an explicit exhibit/destination integration decision, with remaining holds
handled separately. No further sample search or estimator change is implied.
