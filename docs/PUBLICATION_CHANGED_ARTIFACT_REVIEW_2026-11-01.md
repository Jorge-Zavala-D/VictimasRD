# Changed-artifact review and exact Overleaf proposal — 1 November 2026

**Disposition: review complete for the 36 changed aggregate artifacts; seven
manuscript-source updates proposed, not applied. No live file replacement,
renewed owner approval, submission, public release, staging, commit or push.**

The preceding corrective implementation is documented in
[the corrective validation receipt](STATA_CORRECTIVE_VALIDATION_2026-11-01.md).
This batch independently reviews its changed outputs and their implications
for the paper. It does not reopen the design search, change the research
contract, or repeat the full estimation run.

## Decision in brief

1. Preserve all **55 currently consumed generated inputs**. Each current Git
   file, live Overleaf copy and recorded approved-copy SHA-256 agrees exactly.
   None of the 36 changed artifacts is itself consumed by the active article
   or online appendix. Two changed source plots feed M01/M02, but those
   publication wrappers remain byte-identical. **No generated-input replacement
   is necessary for this correction.**
2. Update seven handwritten TeX sources, using the exact proposed patch below.
   The necessary changes concern roster construction, three adjusted
   assignment-heterogeneity probabilities, multiplicity/weak-IV boundaries,
   covariate source years, and current software/validation disclosure.
3. Preserve the main findings, abstract, introduction, main results section,
   conclusion, empirical specification, bibliography and administrative
   declarations. No newly qualified receipt-effect or migration-mechanism
   claim is justified by these corrections.
4. Keep historical reviews and release holds intact. Review of changed bytes
   does not inherit or grant approval of those new bytes. Secondary ratios
   without their own exact-sample instrument diagnostics remain diagnostic.

## Evidence and review identity

The starting checkout was `main` at
`2efea548f0c55ea15444c0558d8e3b88bd06dad8`, with **118 pre-existing
uncommitted files** from the corrective batch. Their bytes were hashed before
this review. Current-batch additions are only this review/proposal and
aggregate, non-observation metadata; no producer, analytical dataset, generated
artifact or existing review ledger is changed by this batch.

The comparison baseline is the preserved Git-tree ZIP recorded in the
corrective receipt. Its SHA-256 is
`b766b334acfa410dad7094a6a3ff1fa354e8914efd02b67b3a717e510f0e2765`.
**A baseline Git-blob SHA is not the historical reviewed working-tree SHA.**
Line endings and representation can differ. The new artifact ledger therefore
names baseline Git SHA, current SHA, historical native review checksum and
current native checksum separately; it does not rewrite historical records.

The full 36-row account is
[changed-artifact-review.csv](../metadata/publication-change-review-2026-11-01/changed-artifact-review.csv).
IDs C01–C36 are local to this review, not new publication exhibit numbers.

## Numerical reconciliation and narrative implications

### Main estimates and migration

- The changed set comprises **14 CSVs, 17 TeX tables and five PNGs**.
- An independent keyed comparison of the 14 CSVs finds **181 shared-cell
  differences beyond the declared serialization tolerance**, **32 additional
  rows**, no removed rows and six added `strength_scope` columns. Of the 181
  cells, 30 are heterogeneity Holm probabilities; 151 concern secondary 2017
  NBI automatic-bandwidth fits, input counts and related BH adjustments.
- All **48 registered primary outcomes / 96 common-window reduced-form and
  fuzzy rows** retain exactly identical shared serialized cells. This is an
  exact comparison, not a tolerance-based primary-result equivalence claim.
  Fresh Stata checks also confirm that all 48 primary fuzzy confidence
  intervals include zero and none rejects after within-family Holm adjustment.
- C01 project composition differs in one serialization cell by approximately
  `7.11e-15`; C35 selection overlap differs in five by at most `6.99e-15`.
  Neither changes a substantive quantity or authorizes weighting. Other
  comparison tolerances are absolute `1e-8` plus relative `1e-7`, used only
  to distinguish serialized aggregate differences, never to round source data.
- The headline observed-migration estimate remains **+21.45 percentage points,
  95% CI [-17.24, 60.14], Holm p = 1.000**. The primary population remains linked
  people with known age at least 14 and valid canonical origin/destination
  movement, not all original residents or a complete-case wellbeing cohort.
  The local sample remains 7,680 people in 63 communities. Selection and
  historical-code limitations are not resolved by these output corrections.

See [CSV comparison](../metadata/publication-change-review-2026-11-01/aggregate-csv-comparison.csv)
and [changed aggregate model cells](../metadata/publication-change-review-2026-11-01/aggregate-csv-changed-cells.csv).
These contain model-level metadata only, not observations or respondent IDs.

### Heterogeneity

Thirty Holm cells change because failed but applicable fits retain their
registered family slots. Their adjustment-only probability is one; unavailable
raw inference is not displayed as a successful null test. Structural identity
cells are excluded. Applicable primary-moderator family sizes are 16 at CCPP
and household levels and 23 at individual level.

The three displayed primary assignment signals require these exact changes:

| Wave / level / contrast | Live display | Proposed display |
|---|---:|---:|
| 2013 community: age 15–29 share × log 2007 population | Holm p = .010 | **.019** |
| 2013 individual: age 15–29 × log 2007 population | Holm p = .018 | **.028** |
| 2017 community: log population × log 2007 population | Holm p = .021 | **.042** |

All three still meet the same .05 criterion. The adjusted assignment inventory
remains **15 signals: three primary-tier Holm and 12 secondary-tier BH**, from
270 supported contrasts. These are assignment-response heterogeneity, not
fuzzy-RD receipt-effect heterogeneity. No new adjusted receipt-effect finding
emerges. The migration female-versus-male receipt interaction and its reporting
status are unchanged.

Fresh in-console Stata checks, independently recomputing the adjustments, cover the registered
primary-tier Holm calculations in both IV and assignment branches across six
wave/level families, plus the assignment signal inventory. The serialized
result comparison uses `1e-7` absolute tolerance for these reconstructed Holm
cells. The largest observed discrepancy is about `1.01e-8`, not a new result.
See [primary HTE audit](../metadata/publication-change-review-2026-11-01/primary-hte-holm-audit.csv),
[assignment family audit](../metadata/publication-change-review-2026-11-01/assignment-family-audit.csv)
and [15-signal inventory](../metadata/publication-change-review-2026-11-01/assignment-signals.csv).

The 32 new 2013 CCPP/exact-score clustering sensitivity rows all fail the
receipt-effect reporting gate. C09 displays the M01 portion: 16 additional
rows, expanding its population-robustness view from 32 to 48. They neither
replace the primary district-clustered specification nor rescue identification.

### Destination rosters and secondary NBI

The complete destination-household roster count changes **27,274 → 27,271**.
The exhaustive partition of 66,427 destination households becomes:

| Construction status | Households |
|---|---:|
| Complete internally consistent roster | 27,271 |
| Partial roster | 37,926 |
| Unknown reported household size | 1,223 |
| Overfull | 4 |
| Additional repeated-person-ID hold | 3 |
| Total | 66,427 |

The three additional holds contain 15 source rows; the people remain in the
cohort. Twelve destination households contain repeated destination-person
identifiers in total, but nine already fall in other incomplete-roster
categories. They must not be counted twice. The prior keyed dataset validation
reconciles 65 person, two household and three CCPP NBI changes. This review
does not delete or newly inspect person-level records.

Secondary outcome-specific ratios cannot inherit primary-sample first-stage
clearance. Their tables and prose should explicitly retain the diagnostic
qualification until own-sample weak-IV checks exist. A table note repair is
not a substitute for those missing diagnostics. Primary outcomes, primary
effective samples and the paper's conclusions are unchanged.

## Artifact-level review

- **C01–C07:** keyed aggregate comparison; corrected Holm cells and added
  clustering rows reconciled; no undisclosed raw-estimate/sample change.
- **C08–C16:** every displayed body row checked against current model CSVs;
  shared cells other than the documented Holm changes remain exact. C09's
  existing 32 rows also remain exact. Its full 48-row view agrees with the
  estimate, SE, conditional-F, KP and gate fields in the CSV.
- **C17–C21:** before/after image dimensions agree. Pixel differences are
  confined to the bottom strength-scope note; axes, markers, intervals and
  plot bodies are unchanged. All five current PNGs were inspected enlarged.
  C17/C20 differ only in x=86–913, y=1925–1953; C18/C19/C21 only in
  x=86–1782, y=1954–1983 on the 3000×2100 canvases. These are pixel bounding
  boxes, not statistical sample bounds.
- **C22–C27:** primary RF/fuzzy cells exact; 151 nontrivial secondary NBI
  differences and new diagnostic-scope fields accounted for as above.
- **C28–C34:** all table body cells unchanged; notes clarify own-sample IV
  holds, primary observed-adult movement population, and attendance rather
  than attainment where applicable.
- **C35:** only negligible overlap-feasibility serialization differences.
- **C36:** all six association rows unchanged; note dates the altitude source
  to 2017 and population/wellbeing covariates to 2007. The association remains
  noncausal and is not a mediation estimate.

In total, **all 17 changed TeX tables / 499 displayed body rows** received
cell-level checks. The private table-cell receipt, image comparisons and
before/after text diffs are retained under the ignored review cache.

### Presentation qualification — do not promote raw analytical tables

The 17 raw tables and five PNGs were compiled in a private 39-page diagnostic
packet, with three unchanged registry companions needed to resolve notes.
All pages received contact-sheet inspection. This unscaled packet has **191
overfull-box warnings**, including companion/label material, and some raw
tables are dense; two scaled HTE views have minimum text around 6.64/7.15 pt.
This is a **diagnostic layout hold**, not a cleared publication packet or a
claim that every warning originates in a changed table. None of those raw
tables is proposed as a direct manuscript replacement. Do not solve this by
manually editing generated tables or shrinking them further.

The active 55 publication-sized inputs use their existing wrappers and remain
unchanged. Formal journal font/length clearance, especially dense appendix
tables and small notes, remains a separate pre-submission task already on the
checklist; internal review is not publisher clearance.

## Exact publication-layer proposal

Apply **only after explicit approval**, with a fresh check that each live
source still has the baseline SHA in
[the seven-file source ledger](../metadata/publication-change-review-2026-11-01/proposed-overleaf-source-updates.csv).
Every path below is relative to the configured Overleaf root:

| File under `World Development Manuscript/` | Exact proposed change |
|---|---|
| `sections/03_data_measurement.tex` | State unique nonmissing destination-person IDs and reported-size/full-roster requirements for roster-dependent deprivation. |
| `sections/07_robustness.tex` | Explicit own-sample weak-IV qualification; failed applicable hypotheses retain multiplicity slots without reported inference. |
| `appendix/B_data_construction_linkage.tex` | Correct complete-roster count, exhaustive partition, three additional holds/15 retained rows and overlap accounting. |
| `appendix/D_additional_results.tex` | Keep secondary/unmatched sensitivity ratios diagnostic pending exact-sample IV checks; clarify multiplicity treatment. |
| `appendix/E_mechanisms_heterogeneity.tex` | Change .010/.018/.021 to .019/.028/.042; explain 16/23 families and unsuccessful added clustering sensitivities; date altitude source accurately. |
| `appendix/F_replication_transparency.tex` | Distinguish historical August build from qualified 7 October build; document unchanged packages, 13,235 identities, local corrected run/comparisons and remaining boundaries. |
| `submission_checklist.tex` | Add 1 November addendum without rewriting 8 October history or lifting portability/publication holds. |

The [exact unified patch](proposals/2026-11-01-overleaf-source-updates.patch)
contains the full proposed wording. It applies against the private live-source
baseline; the corresponding seven proposed SHA-256 identities are recorded in
the source ledger. A private seven-file patch round-trip reproduces those hashes
exactly when Git's `core.autocrlf=false` preserves the live sources' LF line
endings. The initial default-policy round-trip introduced CRLF and failed the
byte check despite identical text; no source content was changed to bypass it.
No `\input`, `\includegraphics`, generated output, filename,
bibliography or author/funding declaration changes are proposed.

**Do not overwrite the three dated gallery copies** of C28–C30 under
`tables/generated_review_2026-08-15/rd_outcomes/`. The dated
`generated_tables_review.tex` is an inspection harness, not included by the
current main/appendix. Those copies match neither the preserved November
Git baseline nor today's canonical bytes. Their exact provenance is unresolved;
preserve them as historical snapshots. See
[historical gallery holds](../metadata/publication-change-review-2026-11-01/historical-gallery-holds.csv).

## Compilation, visual inspection and independent review

Private copies only were built with the existing TeX environment:

| Document | Before | Proposed | Compile/layout checks |
|---|---:|---:|---|
| Main article | 41 pages | 41 pages | No overfull boxes, undefined/multiply-defined references or page-bound violations |
| Online appendix | 94 pages | 96 pages | Same checks pass; added disclosure prose accounts for length change |
| Submission checklist | — | 2 pages | Same checks pass |

Every proposed page received contact-sheet review. Changed roster, family-size,
three-Holm and software/provenance pages were enlarged; so were the checklist
and affected main-text passages. No new clipping, overlap or broken float
placement was found. This is visual/layout validation, not independent
re-estimation or final publisher typography approval.

The private PDFs and their identities are recorded in
[PDF validation](../metadata/publication-change-review-2026-11-01/pdf-validation.csv).
They live under `build/publication-change-review-2026-11-01/` and are not
publication uploads or versioned generated outputs. The initial separate-
output-directory BibTeX build failed in the cache; fresh in-place private builds
resolved the lookup and compiled cleanly. No live source was repaired to hide
that cache setup issue.

A read-only independent reviewer checked the seven source diffs, frozen
generated inputs, numerical/disclosure claims and build logs. No critical or
important discrepancy was identified; one minor ambiguity about non-exempt
dataset comparisons was clarified. That reviewer did not rerun Stata, inspect
restricted microdata, visually rerender the PDFs, or authorize live integration.

The previous corrected master's closed native log was rechecked: it completed
at 21:42:47 after starting at 19:50:57; the final environment-only master closed
successfully at 22:00:00. These are prior-run execution facts, not claims of a
second full master run in this review. Fresh interactive Stata checks in this
batch used `stata_run_selection` only and imported aggregate CSVs, not raw or
analytical respondent data. A final in-console loop also compared all 261
actual native artifact checksums to the current generation ledger, with an
explicit completed-comparison count; every comparison passed.

## Source use and remaining boundaries

The exact shared Zotero library `IE Collective Reparations Peru` was consulted
read-only. A relevant clustering reference was resolved and its underlying
Bartalotti–Brummet (2017) PDF opening pages checked; its Zotero attachment was
not text-indexed. The correct project NotebookLM URL was queried explicitly,
but a browser overlay/timeout prevented a new response. No fresh NotebookLM
synthesis or exhaustive literature ingestion is claimed. No citation or new
methodological recommendation is introduced by this proposal.

This review does not establish ignorability of linkage, universal code-vintage
equivalence, validity of every causal assumption, historical engine provenance,
another-machine reproducibility, data redistribution rights or final journal
font/length compliance. It does not validate all 261 artifacts individually:
the artifact-specific scope is the changed 36 and the 55 active-input identity
checks. The existing 261-row audit remains technically clean but **BLOCKED**,
with zero owner/public-release approvals and zero release-eligible rows.

Before any later live application: recheck the seven source hashes, apply only
the approved patch, verify post-write hashes, compile the actual publication
tree without placing build products there, and recheck all 55 generated-input
identities. If any source has changed, stop and reconcile the diff. That future
application is a separate authorized task; it has not occurred here.
