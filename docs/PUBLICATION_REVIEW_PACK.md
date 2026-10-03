# Publication-sized results review

## Integrated reader/compression addendum — 3 October 2026

Read `PUBLICATION_READER_COMPRESSION_2026-10-03.md` for the current bounded
reader pass. The assembled internal main article and online appendix compile
to 40 and 72 pages, respectively; prior counts below are historical receipts.
The six main and 29 appendix exhibit destinations are unchanged, and every
canonical/copied artifact retains its approved hash. The new
`metadata/publication-reader-navigation-2026-10-03.csv` records actual compiled
numbers and starting pages, separately from exhibit IDs. The source-audit CSV
records the eight live TeX edits. This pass removes duplicate numerical prose,
adds distinct A-prefixed appendix numbering and linked contents, repairs the
parent-relative shared bibliography, and updates the internal checklist.
No generated exhibit was manually edited, no result was re-estimated, and no
generation-time or public-release hold was relaxed. Density/covariate graphics
outside the approved 35 remain subject to separate artifact review.

## Internal-draft approval addendum — 3 October 2026

The owner explicitly approved internal-draft integration of the exact 35
reviewed exhibits after the corrective batch. The dated receipt is
`PUBLICATION_LITERATURE_INTEGRATION_2026-10-03.md`; canonical and copied hashes,
callers and exact destinations are recorded in
`metadata/publication-draft-integration-2026-10-03.csv`. The active manuscript
and appendix now consume these frozen inputs. The generated registry retains
its generation-time `hold_no_sync` and zero public-release fields; this later
approval permits only the recorded internal copies. No submission, public
release, automatic promotion of new runs or manual artifact repair is implied.
Other density/covariate plots outside this set are not silently integrated.

## Corrective production addendum — 3 October 2026

Read `CORRECTIVE_PUBLICATION_PRODUCTION_2026-10-03.md` and
`metadata/publication-corrective-review-2026-10-03.csv` for the narrowly scoped
A25/A28/A29 producing-code repairs and final-scale review. The preview now
matches the live manuscript's Letter/12-point/one-inch-margin layout (165.1 mm
text width) and compiles at 46 pages; the older page count below is a dated
receipt, not the current preview. Both corrected numeric table bodies and all
frozen source results are unchanged. All 35 generated exhibit owner/release
holds remain intact; bounded presentation clearance does not authorize sync.

## Scope and status — 30 September 2026

The project lead approved building a separate review packet from the existing
module-04–06 results. This is a presentation and interpretation milestone, not
a new estimation exercise or permission to publish. The existing sample,
treatment years, outcome populations, weights, estimators, bandwidths, source
adjudication, and release holds are unchanged.

The canonical publication registry still contains 261 artifacts: 94 appendix,
161 internal-only, and six excluded. The dated 99-item review ledger remains
unchanged. Its six proposed main-text and 22 proposed appendix exhibits are
reformatted as separate derivatives, with seven supporting selection,
heterogeneity, and mechanism exhibits. No canonical role is promoted.

The packet contains **35 exhibits: six proposed main-text and 29 supporting
exhibits, comprising 30 TeX tables and five PNG figures**. Its PDF is an ignored
local build, not an Overleaf input or a release-approved artifact. All generated
derivatives remain `generated_unreviewed`, with `owner_approved=0`,
`release_eligible=0`, and `release_action=hold_no_sync`.

## Inputs and outputs

Module `07_build_tables_figures.do` retains the original candidate inventory and
calls `_publication_review_pack.do` to format validated aggregate sources.
No analytical dataset is opened by the new helper.

| Item | Location and purpose |
| --- | --- |
| Main and supporting tables | `output/tables/publication/`, prefixed `M01`–`M06` or `A01`–`A29` |
| Five review figures | `output/figures/publication/` |
| Exhibit registry | `output/tables/publication/publication_review_exhibits.csv`: source/output checksums, proposed roles, captions, and holds |
| Source-cell ledger | `output/tables/publication/publication_review_cells.csv`: all 287 body rows from the 26 reformatted source tables |
| Numerical narrative macros | `output/tables/publication/publication_results_values.tex`: generated directly from canonical aggregate result files |
| Ordered TeX inputs | `output/tables/publication/publication_review_exhibits.tex` |
| Review narrative | `docs/PUBLICATION_RESULTS_NARRATIVE.tex`: editable prose, separate from the live manuscript |
| Review document | `code/latex/publication_review.tex` |
| Compiled preview | `build/publication_review/publication_review.pdf`, ignored |
| Generator manifest | `metadata/publication-output-manifest.csv`: 41 records, including the original two inventory products |

Exhibit IDs are registry identifiers, not the compiled document's table/figure
numbers. TeX numbers tables and figures separately. The registry resolves that
mapping without renaming any original paper input.

The formatter stacks estimates and intervals, retains all source rows, and
uses readable portrait-page tables rather than shrinking a wide table. It
preserves the distinct diagnostic schemas: the 2013 community table has two
conditional F statistics; the other tables have a minimum conditional F,
Kleibergen–Paap F, support, and IV gate. The 2017 project-composition standard
errors come from the already-validated
`rd_hte_2017_ccpp_project_discontinuities.csv`; its financing-dose row is not
included. No source table or estimate is manually rewritten.

## Scientific reading rules

- All 48 registered primary common-window fuzzy outcome tests are displayed in
  their original families; none has a within-family Holm probability below
  0.05. This is not a finding of zero effects or a global 48-test correction.
- The primary observed individual migration population remains linked people
  with known age at least 14 and valid canonical CCPP movement: 7,680 effective
  observations in 63 RUV communities. Its estimate is 21.45 percentage points,
  with robust 95% interval [−17.24, 60.14] and Holm probability 1.000. It is not
  an effect for all eligible source adults or all Peruvian victimized places.
- The complete-household analysis-availability discontinuity is −29.71
  percentage points, interval [−52.20, −7.22]. Source-cohort entry, person
  linkage, movement observability, age observability, and full household
  completeness are separate selection processes. A nonsignificant linkage
  diagnostic does not establish ignorability.
- Selection bars use CCPP-equal rates; their labels give unweighted observed
  and parent counts. They are not one sequential attrition funnel. Movement
  observed for all linked known-age adults does not establish full adult
  coverage; age is unknown for 3,148 source people locally.
- Finite-source intervals concern all-age source people and all source members
  of households. They are descriptive support intervals, not confidence
  intervals, RD effects, eligible-adult bounds, or fuzzy-LATE bounds. No IPW,
  trimming, or division by the first stage is introduced.
- The heterogeneity overview uses the registered primary `common_h_iv`
  specification. Gate-pass counts are 0/48, 0/48, and 8/64 for 2013 community,
  household, and individual families, and 24/48, 8/48, and 23/64 for 2017.
  The 63 gate-passing contrasts have available original tier-specific
  adjustments; none is below 0.05. Unavailable inference is shown as a dash,
  never counted as a nonsignificant result.
- Assignment-only `rdhte` contrasts are evaluated using supported successful
  estimation, not the fuzzy-IV gate. Of 270 supported contrasts with original
  Holm/BH adjustments, 15 fall below 0.05: 2, 1, 3, 2, 6, and 1 in the same
  wave-by-level order. These are secondary assignment-response contrasts, not
  receipt-effect heterogeneity, not one global correction family, and not
  independent replications across aggregation levels.
- All 37 candidate intermediate-outcome rows and six descriptive-association
  rows are retained. Contemporaneous 2017 employment, internet, and migration
  do not establish temporal ordering or identify causal mediation. Missing
  outcome-sample instrument-strength diagnostics remain explicit. Financing-
  dose results remain excluded; project type remains endogenous.
- Historical geographic/design search, rounding and local-support limits,
  the owner's CMAN allocation-and-delivery-year assumption, and unresolved
  population/selection assumptions accompany every eventual causal claim.

## Reproduction and verification

Execute Stata only through `stata_run_selection`. The existing master can run
modules 07 and 08 using its two corresponding switches. Alternatively, after
its default configuration/bootstrap, send the following selection:

```stata
do "${pipeline_root}/07_build_tables_figures.do"
do "${pipeline_root}/08_run_release_checks.do"
do "${project_root}/code/stata/tests/test_publication_review_pack.do"
do "${project_root}/code/stata/tests/test_publication_candidate_outputs.do"
do "${project_root}/code/stata/tests/test_release_audit_outputs.do"
```

The read-only Python checker complements Stata; it never runs Stata or writes
data. From the repository root:

```text
python code/python/check_identification_publication_review.py --review-pack --dropbox-root "<configured Dropbox project root>"
```

Compile the multi-file TeX project with the existing LaTeX compile helper or
installed TeX toolchain, putting all compiler products under
`build/publication_review/`. The source supports compilation from its own
directory or the repository root. This batch used the existing compiler and
packages; no installation was performed.

Validation receipt for this batch:

- Master executed through Stata MCP with only modules 07/08 enabled in an
  in-memory copy; the saved master switches were not changed. No module-04–06
  re-estimation occurred.
- All 12 existing/new Stata contract tests passed.
- Independent checks retained all 287 source rows and verified numerical
  narrative macros, diagnostic headers, the four 2017 project standard errors,
  six finite-source intervals, six-family heterogeneity counts, all 37
  intermediate-outcome estimates/intervals/adjustments, and all six association
  estimates/intervals. In-memory negative controls rejected a false release
  approval and an altered source cell.
- All 99 original exhibit SHA-256 hashes and all 10 documentary-source hashes
  remained intact. The canonical registry and release dispositions are
  unchanged. The release audit remains `BLOCKED` with zero technical errors.
- The 44-page PDF compiled successfully. All pages were rendered and inspected,
  including continued tables; no clipping, overlap, or TeX overflow remained.
- The code knowledge graph was refreshed with `graphify update .` (AST-only,
  no LLM). Document/image semantic ingestion was not rerun; the graph is not
  evidence for numerical or literature completeness.

No raw, archived, Working, Coded, or Overleaf file was changed by this batch.
No observation-level data, logs, or compiler products enter the proposed commit.
Nothing was staged, committed, or pushed.

## Literature receipt and publication boundary

NotebookLM was consulted for literature synthesis. Its response was treated as
a discovery aid, not evidence: no automatic complier interpretation based on
post-treatment linkage was adopted. The underlying author-version
*A Practical Introduction to Regression Discontinuity Designs: Extensions*
(Cattaneo, Idrobo, and Titiunik, 25 March 2024, Section 3.2, PDF pp. 43–45)
was checked for the fuzzy-RD exclusion/monotonicity/complier conditions.

Read-only access to the shared Zotero integration was attempted, but the local
endpoint refused the connection. No Zotero library change or authentication
reset was made; current successful Zotero retrieval is not claimed.

World Development presentation/writing skills informed restrained graphics,
booktabs tables, visible uncertainty, explicit units and denominators, and
claim-focused prose. This does not establish journal compliance or submission
readiness. The next step is artifact-level scientific/disclosure review and
approval of exact live manuscript destinations before any role promotion or
Overleaf synchronization; this task does not perform that promotion.
