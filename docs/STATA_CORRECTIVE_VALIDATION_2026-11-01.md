# Stata corrective validation — 1 November 2026

**Status: corrective implementation and technical validation complete. Public release remains BLOCKED.**

This receipt covers the 18 findings in [the audit](STATA_CODE_AUDIT_2026-11-01.md).
It does not authorize a new research design, package upgrade, commit, push,
live-manuscript replacement or public release. The binding choices are in
[the corrective decision record](STATA_CORRECTIVE_DECISIONS_2026-11-01.md).

## Baseline and environment

- The checkout was clean on `main` at `2efea548f0c55ea15444c0558d8e3b88bd06dad8`.
  The ignored committed-tree ZIP has SHA-256
  `b766b334acfa410dad7094a6a3ff1fa354e8914efd02b67b3a717e510f0e2765`.
- All 11 baseline analytical datasets were preserved only in the configured
  current Dropbox Working area before writes. Original and copied SHA-256
  identities agree; see `metadata/stata-corrections-2026-11-01/baseline-data-identities.csv`.
  Raw and pre-existing dated archives were not changed.
- The owner approved qualifying installed Stata 19, 7 October 2026, rather
  than downgrading the shared installation. No package was installed, updated
  or replaced. All 267 project PLUS identities agree with the historical lock.
- Before adopting the prospective lock, unchanged modules 04–06 completed at
  19:25:12. Their 36 aggregate CSVs / 4,598 rows agree with baseline using
  absolute tolerance 1e-8 plus relative tolerance 1e-7 for numeric serialization;
  missingness and nonnumeric identities agree. The closed native log is
  `logs/master_1nov2026_181942.smcl`.
- The final lock records 13,235 identities: 267 project, 12,966 official BASE,
  and two installed engine files. Exact native and SHA-256 inventory checks pass.
  The historical lock is unchanged. See [the environment receipt](STATA_ENVIRONMENT_LOCK_2026-11-01.md).

## Full-master execution

The in-console copy of the documented master changed only `local run_all 0`
to `1`. Routine preparation, descriptives, RD validation, six main-analysis
modules, six heterogeneity modules, mechanisms, publication assembly and
release checks completed successfully:

- Start: **19:50:57**, 1 November 2026.
- Finish: **21:42:47**, 1 November 2026.
- Closed native log: `logs/master_1nov2026_195057.smcl`.
- Execution: Stata MCP `stata_run_selection` only; no shell Stata,
  `stata_run_file`, package update or external source conversion.

The transport's 300-second timeout did not terminate the server run.
Completion was verified from the closed native log and idle MCP session.

This was a staged corrective run, not an immutable source-snapshot claim.
The conditional-inference repairs were finalized before module 05 entered;
no actively executing preparation or estimation module was edited.
Preflight-only alias and descriptive-manifest checks were tightened during
the long run. The final literal environment-only master, with the final
manifest and current path guard, separately passed at **21:19:48**
(`logs/master_1nov2026_211651.smcl`); actual roots and software identities
did not change. The historical exhaustive search remained disabled.

After all corrected production and dataset/output checks, a second literal
environment-only master passed at **22:00:00** with the final fingerprint and
current guards (`logs/master_1nov2026_215714.smcl`). Its closed log contains
the explicit successful-completion marker. The two audit-owned MCP sessions
were then destroyed to release memory; other projects' sessions were untouched.

## Disposition of all 18 findings

| Finding | Correction | Verification and boundary |
|---|---|---|
| 1 | Shared pre-write storage contract rejects overlapping roots, traversal and Windows dot/space aliases | Genuine failure then 15 passing path cases; actual configured roots pass |
| 2 | Both intake utilities reject source/output/manifest aliases before parsing | Seven ingestion boundary/completeness tests; no real Raw conversion |
| 3 | Main, HTE and dose statuses require finite successful inference; conditional rows have their own guard | Actual-source fixtures and all generated passing-IV rows checked |
| 4 | Age-dependent construction and 2013 individual samples require known age | Missing/.a/.z and boundary fixtures; raw eligibility incidence checked; final SISFOH values agree |
| 5 | District-recovery age key uses int, not byte | Ages 100/101/120 fixture; no current INEI 101–120 incidence |
| 6 | Removed redundant election fallback copy/drop after release loop | Reproduced r(111); one-recovered and zero-recovered fixtures pass without losing master rows |
| 7 | Complete destination rosters require unique nonmissing person identities | Three previously complete households / 15 rows held; all downstream changed cells reconciled |
| 8 | Financing requires finite positive amounts and matched treated histories before assigning untreated zeros | Missing-amount negative test; zero incomplete current treated histories; dose estimates agree |
| 9 | Binary HTE endpoints use 0 and 1 rather than an unused median slot | Actual-source endpoint fixtures pass; current conditional outputs agree |
| 10 | Fixed registered multiplicity families retain failed applicable slots with adjustment-only p=1 | Source-derived Holm fixtures; 30 changed HTE Holm cells reconciled; raw estimates unchanged |
| 11 | Secondary/unmatched sensitivity LATEs cannot inherit primary-sample diagnostic clearance | Explicit strength_scope and producing notes; these estimates remain held pending their own diagnostics |
| 12 | Added 2013 CCPP common-window CCPP and exact-score clustering sensitivities | 32 new rows; 208 total; primary district-clustered estimates unchanged |
| 13 | Historical review is bound to artifact fingerprint; Git-blob SHA is separately named | Changed/missing identity tests; 36 changed current artifacts require renewed review; no approval inherited |
| 14 | Publication assembly checks module 06's recorded module-04 manifest identity | Synthetic mismatch and actual stale 18-row mechanism manifest rejected before writes; fresh full run passes |
| 15 | Binary approval schema and selected-row eligible-or-blocked invariant | Missing/.a/.z/2 approval fixtures rejected; final 261-row audit has zero technical errors and remains BLOCKED |
| 16 | Search chunks bind data, code, protocol, registry and environment generation identities | Mismatch fixture rejected; historical costly search was not rerun |
| 17 | Corrected actual kernel, source years, population allocation, attendance/sample descriptions and README | Six kernel labels corrected without model changes; regenerated source/figure/table checks and print review pass |
| 18 | ReporteCCPP intake supports only the validated 25-department completeness contract | Unsupported count rejected; no new intake or source modification |

A fresh independent reviewer inspected changed producers and callers, found
the Windows alias and conditional-gate residual defects, and verified their
repairs statically after focused tests. That review did not execute Stata or
independently inspect restricted observations.

The same reviewer subsequently checked this final receipt against the aggregate
comparison tables, primary-result CSVs and release audit. No concrete claim
discrepancy was found; that read-only claims check did not independently rerun
the underlying Stata, tests or rendering.

## Dataset comparisons

The private-baseline test `code/stata/tests/test_corrective_dataset_baseline.do`
compared all 11 datasets by validated unique keys, dimensions and values using
official `cf`, without verbose observation listings.

- All 5,712 RUV records remain; the legacy geographic flag remains 1,162.
- SISFOH outputs retain 1,425,575 people and 415,007 households.
- Census outputs retain 193,342 accepted source people and 58,015 source
  households. The approved 34-person quarantine is unchanged.
- Datasets 04–11 agree exactly in every non-exempt field.
- Four election-index fields, and their downstream copies, show only
  representation-scale differences: maximum absolute difference
  **5.3290705182e-15**. After diagnosing the initial exact-comparison failure,
  a narrow **1e-13 absolute bound** was documented only for these four fields.
  Keys, dimensions and missing-value codes remain exact; no data were rounded
  or replaced. This is not a general tolerance or a predeclared exception.
- Every other changed cell is explained by the roster/NBI correction:
  **65 person cells, two household cells and three CCPP cells**. Observed
  roster-dependent NBI components become unavailable, component counts fall,
  and the corresponding aggregates change. No source person or household is
  deleted. Assertions reconcile every non-roundoff difference to this list.
- Separate metadata comparisons confirm identical variable positions, names,
  storage types, formats, value-label associations and variable labels across
  all 11 files. Value-label definitions and arbitrary dataset characteristics
  are not certified by that metadata comparison.

Disclosure-safe results are in `metadata/stata-corrections-2026-11-01/`:
`dataset-comparison.csv`, `election-roundoff.csv`,
`nbi-dataset-changes.csv` and `variable-metadata-comparison.csv`.
Earlier small-file checks are retained as intermediate evidence, not substituted
for the full comparison.

## Numerical and inferential reconciliation

The corrected comparison covers **36 aggregate CSVs / 4,630 rows** against
4,598 baseline rows. No old row is removed; the only additions are the 32
prescribed clustering sensitivities.

- All **48 registered primary outcomes / 96 common-window RF and fuzzy rows**
  have exactly identical shared serialized cells, including samples, estimates,
  uncertainty and multiplicity fields. See `primary-fixed-window-invariance.csv`.
- All 2013 main-result shared cells agree. In 2017, 151 changed main-result
  cells are confined to secondary NBI outcomes and their family adjustments:
  eight outcome-selected fuzzy fits, 12 input-count cells, and six BH cells,
  including the related secondary-family adjustment. Fixed-window effective
  estimates and primary results do not change.
- The other **30 changed cells are HTE Holm p-values** from retaining registered
  failed hypotheses. None is a raw estimate, standard error or sample change.
- Existing HTE results, conditional effects, funding-dose results, project
  composition/discontinuities and module-06 aggregate evidence otherwise agree
  within the stated serialization tolerance.
- Passing IV rows remain **0 / 0 / 23 / 48 / 16 / 68** for 2013 CCPP/household/person
  and 2017 CCPP/household/person. Every passing row has successful finite inference,
  positive SE, adequate support, minimum conditional F > 10 and underidentification
  p < .05. No rdhte row is promoted to fuzzy-LATE clearance.

The comparison tables are `corrected-all-aggregate-summary.csv` and
`corrected-all-aggregate-cells.csv`. The existing baseline/release hierarchy,
adjacent B/C support, cutoff, h/b, treatment years, weights, primary inference,
moderators and migration population are preserved. Technical reproduction is
not a proof of causal validity or ignorable linkage.

## Tests and publication review

- **21 Python unit tests pass**, covering lock identity/checkout behavior,
  environment capture and ingestion boundaries.
- Focused actual-source Stata predicates and path tests pass; the **12
  post-master output/contract tests** pass, including migration selection,
  all Census HTE levels, publication candidates and release governance.
- All **261 candidate artifacts** exist and match their generation checksums.
  There are **zero technical release errors**, 94 selected rows, zero
  release-eligible rows, and 36 changed artifact fingerprints. Owner flags stay
  zero. Historical dated SHA review records are not rewritten as current approval.
- The fresh **35-exhibit** review pack retains all **287 source rows** and
  41 manifest entries. Stata checksum tests and the current-pack Python
  cell/note/negative-control checks pass. The old dated-snapshot CLI is not
  represented as a current-generation approval check.
- The ignored private PDF compiles to **46 Letter pages**, at 165.1 mm text
  width. All pages received contact-sheet inspection; the five figures and
  targeted units/source-year/bottom-note pages were enlarged. No clipped notes,
  page-bound violations, overfull boxes, undefined or multiply-defined
  references were detected. Existing companion narrative is included for
  context, not presented as newly rewritten manuscript text.
- PDF SHA-256:
  `4bc239a522371ccd196aaae12d81da92aa304ee6a1840618c837ff985a08b369`.
  The private wrapper/render receipt lives under
  `build/corrective-audit-2026-11-01/`; its disclosure-safe summary is
  `metadata/stata-corrections-2026-11-01/publication-render-review.json`.

## Remaining boundaries

The existing Graphify map was refreshed structurally: 1,185 nodes, 1,224 edges
and 165 communities, with zero API tokens. Semantic document extraction and
community naming were not refreshed; the map is navigation, not audit evidence.

Secondary receipt-effect sensitivity estimates remain held until their own
exact-sample weak-IV diagnostics are available. Another-machine execution,
physical filesystem aliases such as junctions/8.3 paths, historical binary
provenance, software redistribution rights, all 261 artifacts rendered
individually, arbitrary dataset characteristics and public disclosure approval
are not certified here. The configured roots were checked as ordinary,
non-linked local directories.

The live Overleaf manuscript and inputs remain frozen; no renewed integration,
submission, stage, commit or push occurred. The next production step is review
of changed bytes and their manuscript/narrative implications, followed only by
explicitly authorized publication-layer integration—not another sample search.
