# Software lock and whole-manuscript production audit

## Scope and decision

This implements the approved next milestone: lock the currently observed Stata
environment, replace floating dependency installation with native preflight,
and re-audit the assembled internal paper. It does not change the research
design or rerun research estimates. Work started from the clean primary
`main` checkout at `5758f49f59ed0019a0be89d644619840bdf25361`. No files were
staged, committed, or pushed; no journal submission or public release occurred.

The software-lock implementation and execution checks are complete. A fresh
independent read-only final review found no Critical or Important defects and
cleared the batch for an internal, uncommitted handoff. Submission, public
release, and the separate portability/licensing requirements remain blocked.

## Executable changes and verification

The master now requires the reviewed local cache and checks the 13,223-file
manifest through `code/stata/lib/00_validate_environment.do`. Recorded files
include 267 project executable/support files, 12,954 installed official BASE
files, and two installed engine components. Only BASE and project PLUS are
admitted on the code-search path. Missing or changed files, modified locks,
unapproved search roots, additional executable cache files, or unexpected
nested cache directories stop execution. Routine SSC/network installation was
removed. Neither the guard nor the routine master invokes an external process.

Native checks use Stata checksums and byte lengths; the separate read-only
Python verifier checks SHA-256 and cache/BASE inventories. Both accepted the
current installation. The Python verifier's seven behavioral tests passed.
The master passed through **Stata MCP `stata_run_selection`** with every
empirical module switch off, including its existing cold-session IV, RD,
density, and density-plot compatibility checks. Its final durable receipt
records return code zero, corroborated by the complete master log.

`metadata/stata-environment-validation-2026-10-03.csv` records 12 executed
check categories. Isolated negative tests used disposable cache clones and
search roots, not the canonical installation. Tests first exposed acceptance
of an extra nested cache directory and an empty unapproved search root; both
were fixed after witnessed failures and successfully retested. Caller
observations, ordering, labels, characteristics, and estimation results were
checked on both acceptance and rejection. Another installed Stata build was
not available for a real runtime-mismatch test.

Exact already-installed shared mapping and scheme files were copied into the
ignored project cache without changing the original shared installations or
upgrading packages. An ignored private archive of 417 project-cache files was
restored to a separate local directory. Every restored file matched SHA-256;
the native guard also accepted that restored cache. This is a **same-machine
restoration test**, not a cross-machine replication or redistribution license.
See [the environment-lock record](STATA_ENVIRONMENT_LOCK_2026-10-03.md) for
the exact manifest identity, sources, runtime caveat, and remaining limits.

## Whole-paper coverage

| Review layer | Coverage and result |
|---|---|
| Editable source | 28 TeX units reconciled to the fresh compile mirror; nine main sections, Appendices A-F and the diagnostic supplement, shared layout/metadata, and administrative sources read |
| Historical viewer | `generated_tables_review.tex` is a non-consumed inspection aid, not an active paper section or a newly certified historical archive |
| Generated paper inputs | All 55 canonical/live/mirror copies match approved hashes: six main exhibits and 49 appendix exhibits, totaling 31 generated tables and 24 figures |
| Bibliography | 41 cited keys remain unchanged and resolve against the unchanged 59-entry shared bibliography; no duplicate bibliography keys |
| Substantive sources | All 17 existing bounded source-claim records retained; all 18 underlying local PDF hashes checked against their source-verification ledger |
| Numerical evidence | Existing identification/publication checker passes frozen source rows and review copies; independent formal-diagnostic check passes all 23 rows and 115 cells, including recomputed BH and Holm adjustments |
| Complete compilation | Main paper 40 pages; appendix 94 pages; no undefined citations/references, overfull boxes, compilation errors, empty pages, or off-page text characters |
| Visual review | All 134 pages rendered and inspected in page-overview sheets; larger renders inspected for the newly changed software/transparency pages and selected dense tables and diagnostic notes |

This is an artifact-level consistency and production audit of the active
manuscript, not merely a filename inventory. It is not an independent
re-estimation of every historical transformation, a rereading of every item
in the shared literature library, or a fresh causal-identification certificate.
Small full-width diagnostic notes and dense appendix tables still require a
final journal production/font decision; overview inspection is not a claim
that every exhibit has been newly reviewed at printer resolution.

The new source registry is
`metadata/manuscript-environment-reader-audit-2026-10-03.csv`. Local compiled
receipts, before-source copies, complete text extracts, renders, and the
preservation baseline are in ignored `build/environment-lock-2026-10-03`.
The expanded TeXCount decompositions are 9,064 text + 167 heading + 77 other
words for the main paper, and 17,263 text + 298 heading + 364 other words for
the appendix. TeXCount's weighted sums including formula counts are 9,401 and
18,186. Bibliography is excluded. These explicit counting conventions are not
certification against a current journal word-limit rule.

## Structure, interpretation, and literature

The active argument remains: collective project financing, original residents,
and recognition are distinct objects of evaluation. The introduction states
the conditional local question; institutional context and conceptual pathways
precede measurement and identification; full primary results precede
heterogeneity and mechanism evidence; the conclusion respects the uncertainty
and observation boundaries. Appendix A supplies context, B construction and
linkage, C design diagnostics, D complete outcome families, E extensions, and
F transparency. Main/appendix exhibit destinations and references were checked
against the integration records rather than renamed or rearranged.

The review reconfirmed these substantive boundaries:

- Preserve all 5,712 RUV communities, the 1,162-community fixed geography,
  549 adjacent B/C communities, official cutoff 0.062320, and the adopted
  common primary window `h = 0.0075`, `b = 0.0135`.
- Treatment uses `treat_12` and `treat_16` under the owner's recorded
  allocation/delivery-year convention. Undocumented annual eligibility or
  score-registration histories are not fabricated.
- All six eight-outcome primary families remain visible. None of the 48
  primary estimates survives within-family Holm adjustment; intervals include
  zero. This is not an equivalence test or evidence of no effect.
- The observed individual migration contrast remains +21.45 percentage
  points with 95% interval [-17.24, 60.14], conditional on linked adults with
  valid community movement. The household-availability discontinuity remains
  a selection warning, not a migration effect or a solved weighting problem.
- Preserve the original 193,376-person delivery denominator, the 34-record
  quarantine, and the adjudicated 193,342-person/58,015-household analytical
  cohort. The latter counts were freshly confirmed from current Stata file
  headers without loading or printing observations.
- Receipt-effect IV heterogeneity is distinct from `rdhte` assignment-only
  contrasts. Intermediate-outcome estimates and ecological associations are
  not causal mediation; project choice is endogenous. Financing-dose effects
  remain excluded, and no post-treatment ordinary control is introduced.
- Density nonrejection and adjusted covariate tests do not prove no sorting,
  no confounding, or ignorable linkage. Geography/source timing, finite score
  support, design-search history, and missingness limitations remain explicit.

The shared Zotero library 5, **IE Collective Reparations Peru**, was consulted
read-only. Selected source metadata and supporting passages were refreshed,
including collective-redress and migration-welfare literature. No new source
claim, citation, or bibliography entry was inserted. The explicit Peru
NotebookLM query failed because authentication was unavailable; the default
active notebook belonged to another project and was not used as evidence.
The existing verified source-claim ledger, not a synthesis answer, remains the
authority for bounded substantive claims.

## Corrections, invariance, and current previews

Only Appendix F and the submission checklist changed in the live publication
tree. They now describe the observed software lock, the 55-input provenance,
and completed diagnostic integration while preserving submission/release
holds. No generated table or figure was manually edited.

The repository README contained outdated Census cohort counts and described
already-adjudicated scientific choices as still undecided. It now separates
current internal decisions, preservation of the original source denominator,
and the genuinely unfinished release requirements. `docs/PROJECT_CONTEXT.md`
has a dated superseding status note; historical decision records remain intact.

The first fresh main-paper preview returned compiler success despite unresolved
citations. It was rejected. A forced local rebuild with the shared-bibliography
search root resolved the citations. The live `main.tex` was preserved; the
local compile receipt records the required search root rather than introducing
a duplicate bibliography into the manuscript folder. Every extracted main-PDF
page matches the prior valid main preview's text. Appendix text changes begin
on page 88 and are confined to software/provenance text and resulting
bibliography repagination; scientific sections and generated inputs match the
preservation baseline.

Current internal previews:

- `build/environment-lock-2026-10-03/compile/main-preview/main.pdf`:
  40 pages; SHA-256 `2e8d22f300bee5c8e8f3d24667e3ade33129ed4780534831e0d58ff2656b43e5`.
- `build/environment-lock-2026-10-03/compile/appendix-preview/online_appendix.pdf`:
  94 pages; SHA-256 `8a7149188e7c3e83d270ecce4a1a62da69e1000c34c61685f0dc1486b9de0da7`.

The baseline covers 1,379 pre-existing protected files. Its current differences
are exactly the master, README, project-context status, Appendix F, and
submission checklist. Existing scientific code, numerical outputs/manifests,
shared bibliography, protected canonical community dataset, legacy manuscript,
and original package-cache files remain byte-identical. Newly added files are
separately enumerated in the final proposed Git scope; software-copy intake
and scratch restoration directories are ignored and contain no research data.

## Independent closeout review and deferred observation

One fresh independent read-only reviewer inspected the implementation, brief,
material live-source changes, preservation baseline, manifests, tests, and
execution/compile receipts. The reviewer independently reran all seven Python
tests, checked the exact manifest SHA-256, compared all 1,379 baseline hashes,
confirmed exactly five changed protected files with none missing, inspected
the successful master log/receipt, and ran `git diff --check`. Verdict: **ready
for internal uncommitted handoff; no Critical or Important defects**.

The reviewer did not rerun Stata, rebuild PDFs, or repeat all 134 visual page
checks. Nor did the reviewer certify causal identification, every underlying
source passage, actual MCP-host identity, historical or raw-data replication,
another machine, licensing, restricted-data permissions, or current journal
compliance. These exclusions are consistent with the approved batch scope.

One Minor observation is deferred to the authorized checkout/restoration
milestone: the reviewed manifest currently has CRLF line endings, while Git's
line-ending settings can differ across collaborators. Its literal byte length
and native checksum are deliberately pinned. A normalized checkout must fail
preflight; it must not be made to pass by casually changing the pin. Future
restoration must preserve the exact reviewed bytes or adopt and test a
file-specific Git line-ending contract. No `.gitattributes` or pin alteration
was introduced without that separate restoration test.

The local knowledge graph was updated through its AST-only workflow, without
an API extraction run. The runtime JSON produced no graph nodes; this known
coverage omission is not treated as validation or a substitute for direct
manifest/source inspection.

## Remaining boundaries and next milestone

This locks the **observed** installation prospectively. It does not establish
historical generating-software identity, actual MCP-host executable identity,
another-machine portability, software/data redistribution rights, or a fresh
end-to-end raw-data replication. Institutional selection and observational
limits are scientific qualifications, not defects to remove by formatting.

The next step is an authorization-aware administrative/disclosure and
submission-production packet: finalize verified author/CRediT and access
wording, make the restricted-data/code/software distribution plan explicit,
resolve journal font/length requirements, and independently validate an
authorized cross-machine environment before calling the package portable.
Current World Development guide access returned unavailable (HTTP 403), so
this audit does not certify current journal word limits or submission rules.
None of these remaining checks authorizes submission, public release,
invented declarations, or changes to the approved scientific estimand.
