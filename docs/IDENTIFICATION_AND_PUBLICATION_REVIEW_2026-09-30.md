# Identification and publication review — 30 September 2026

## Decision and scope

The project lead authorized the complete evidence, results, and exhibit review.
This record fixes the **permitted interpretation of the existing analysis**;
it does not change the selected geography, adjacent B/C support, score,
`treat_12`/`treat_16`, bandwidths, outcome registries, weighting, or estimators.
The 27 September source-place adjudication remains authoritative.

**Decision:** preserve the reproducible estimates as conditional local evidence,
but hold unqualified causal, mechanism, and publication claims. Historical
assignment inputs and selection assumptions remain insufficiently established.
This is an evidence limitation, not a request for another team-approval step.
The project lead's workflow approval is not artifact-level publication approval.
The automated release status remains **BLOCKED**.

## 1. What the historical assignment documents establish

Sources, checksums, and PDF-page locators are recorded in
[the dated evidence register](../metadata/rd-design/identification-evidence-2026-09-30.csv).
Page numbers below count PDF pages, not the printed page numbering.

| Period/source | Verified rule or practice | Implication for this analysis |
|---|---|---|
| September 2007 index methodology, PDF pp. 1–2 | Five affectedness categories support ordered intervention. | Establishes the index's purpose; does not by itself establish a strict national A-then-B-then-C queue. |
| Defensoría Report 139, PDF p. 50 | The June 2007 launch selected 440 communities from Censo por la Paz; 2008 selection also used RUV Libro II. | Early cohorts do not come from one demonstrated, constant RUV assignment regime. |
| RUV 2009–2010 report, PDF pp. 6, 18 | Registration expanded from 5,409 to 5,609 communities between the cited annual snapshots. | The later 5,712-row workbook is not an observed contemporaneous eligibility denominator for every award year. |
| CMAN 2012 report, PDF pp. 7–9 | Guidelines approved on 30 May 2012 prioritized RUV registration, **A or B jointly**, and municipal executors' prior financial accountability. Inherited commitments and VRAEM priority also mattered. | A/B priority makes a B/C margin institutionally plausible after that rule, but does not establish local random treatment receipt. `treat_12` also includes earlier regimes. |
| CMAN 2013 report, PDF pp. 49–50; 53 | The updated guidelines repeat registration, joint A/B priority, and executor accountability (pp. 49–50); PRC VRAEM priority is described on p. 53. | This is corroboration, not evidence that every A community had to be financed before any B community. |
| CMAN 2014 report, PDF pp. 46–47 | The report identifies financed projects and VRAEM coverage. | Funding and geography must be distinguished from a score-only assignment rule. |
| CMAN 2015 report, PDF pp. 33–34 | PRC financing uses municipal transfers; 100 transfers and project monitoring are reported. | Financing or monitoring is not independently verified completion or exposure. |
| CMAN 2016 report, PDF pp. 39–41 | Assemblies, technical files, transfers, execution, delivery, and liquidation are distinct stages; VRAEM/Huallaga priorities remain visible. | The recorded project year is not independently verified completion or household exposure timing. `treat_16` accumulates different rollout stages and rules. |
| Defensoría Report 162, PDF pp. 37–38 | Implementation review reports priority exceptions and project-execution/sustainability concerns. | Neither perfect score compliance nor completed intervention is established by a financing entry. |
| May 2023 general guidelines | Later administrative guidance. | Useful context, not retroactive proof of the assignment rule for the 2012 or 2016 estimands. |

Eight newly acquired official PDFs were preserved under the configured Dropbox
Raw external-source root. Extracted text is in Dropbox Working; no source PDF
was copied into Git. Existing Raw and Support sources were not changed.

### Still not observed

The supplied raw RUV workbook has no community registration date, dated score
version, annual eligibility flag, award/approval date, transfer date, or
completion date. The inspected canonical fields do not supply those missing
histories. Aggregate annual counts cannot reconstruct unit-level risk sets.
We have not established that the score observed in the later workbook is
identical to the score officials used for each early decision.

These missing facts do **not** prove that RD is invalid or that a
difference-in-differences design is required. They prevent treating the current
data as verified historical assignment records. No synthetic risk set, score
repair, or new favorable sample has been constructed.

## 2. Literature access and identification boundaries

Both integrations were consulted read-only. The exact shared Zotero library
resolved to 39 parent items. NotebookLM answered two project queries and reported
45 sources, including the expanded methods collection. Its queried corpus did
not include the decisive CMAN 2012/2016 assignment documents. An upload count
is not proof of complete source access or reading coverage.

NotebookLM's initial synthesis overreached on retrospective scores, density
testing, and linkage ignorability. Those propositions were not adopted. The
underlying official documents and methods PDFs, rather than an AI answer, are
the evidence. Zotero retrieval was also incomplete for some attachments;
underlying local PDFs were read where searchable retrieval failed.

The fresh independent review's later connection attempts failed (Zotero's
local endpoint refused the connection; NotebookLM returned an unsuccessful
query). This limits repeat retrieval in that review, not the earlier successful
reading receipts. No authentication or library setting was changed. Source
files and numerical results remained available for independent local checks.

Verified methodological anchors:

- Cattaneo, Idrobo, and Titiunik, *Extensions* (25 March 2024 author version),
  PDF p. 45: the complier LATE interpretation requires additional monotonicity
  assumptions. PDF pp. 57–58: limited/discrete score support can require
  stronger assumptions; mass-point adjustments do not manufacture support.
  [Author PDF](https://mdcattaneo.github.io/books/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf),
  [published monograph](https://doi.org/10.1017/9781009441896).
- Cattaneo, Keele, and Titiunik (2023), *Covariate Adjustment in Regression
  Discontinuity Designs*, PDF p. 13: covariates and subgroup analyses require
  their own assumptions; adjustment cannot repair a broken RD design.
  [Author publication record](https://titiunik.github.io/publications/).
- Bartalotti and Brummet (2017), PDF pp. 2–4: clustering matters for inference
  and bandwidth selection. Clustering by repeated score does not solve the
  identification problem of sparse score support.
  [Published chapter](https://doi.org/10.1108/S0731-905320170000038017).
- Dong (2019; online 2017), *Regression Discontinuity Designs With Sample
  Selection*, PDF p. 6: selection bounds require explicit restrictions such as
  monotonic selection, not a nonsignificant linkage test. The assumed direction
  concerns individual potential selection, not simply the observed sign of a
  selection discontinuity.
  [Author-hosted article](https://www.yingyingdong.com/Research/J14_JBES.pdf),
  [published article](https://doi.org/10.1080/07350015.2017.1302880).

For treatment-receipt LATE, a strong first stage is necessary but insufficient:
local continuity, exclusion, monotonicity, stable measurement, and an explicit
selected-population interpretation must also be credible. An F > 10 screen is
an interpretation safeguard, not proof of those conditions. `rdhte` assignment
heterogeneity is not fuzzy treatment-effect heterogeneity. Contemporaneous
internet/employment associations are not validated causal mediation.

## 3. Numerical and sample audit

Stata selections read the raw RUV schema, canonical community dataset, and
existing aggregate results. No analysis dataset or estimation program changed.

| Check | Verified result |
|---|---|
| RUV analytical spine | 5,712 rows; unique `ruv_id`; all have an observed score. |
| Selected geography | 1,162 communities, unchanged. |
| Full score support | 2,072 distinct values; minimum 0.0077, maximum 2.3622. Out-of-range observations were not silently removed or replaced. |
| Selected adjacent B/C branch | 549 communities; official B/C cutoff 0.06232. |
| Common estimation window | `h=0.0075`: 45 left/26 right base communities; 30/24 distinct scores. |
| Common bias window | `b=0.0135`: 76 left/46 right base communities; 51/40 distinct scores. |
| Cumulative treatment | Selected-geography means: `treat_12=0.3571`, `treat_16=0.4484`; ordering assertion passes. |
| Six primary outcome families | Eight outcomes each; all 48 fixed-window primary fuzzy estimations return successfully; **zero Holm-adjusted p-values below 0.05**. |

The base score-support counts are not outcome-complete-case counts. Many person
or household rows do not create many independent treatment-assignment units.
The common design window improves nominal comparability; it is not claimed to
be simultaneously optimal for every outcome.

### Migration and selection: keep the denominators separate

The approved primary I03 population is linked adults aged at least 14 with
valid canonical CCPP movement. Its 2017 fixed-window fuzzy estimate is
**+21.45 percentage points**, 95% interval **[−17.24, 60.14]**, raw p=0.277,
Holm p=1.000. The source analysis contains 67,648 eligible adults; 7,680 are in
the local estimation window, representing 63 RUV communities. The
outcome-specific local-IV Kleibergen–Paap F is 20.80. This is neither a precise
25% relative effect nor an effect demonstrated for all source-cohort residents.
The other seven individual primary outcomes retain their different
complete-case denominator; the main table must say so.

An important diagnostic is **entry into the complete 2017 household primary
analysis sample**: −29.71 percentage points, 95% interval [−52.20, −7.22],
raw p=0.0096. Its local window contains 4,051 source households in 64 RUV
communities. Household-member linkage is a different diagnostic
(−9.82 points, interval [−34.82, 15.17], raw p=0.441).

The significant complete-case diagnostic makes household estimates
selection-sensitive. Its raw p-value is diagnostic evidence, not a
multiplicity-adjusted substantive treatment finding. Source-cohort coverage,
person linkage, movement observability, and household complete-case
availability must be reported separately. A nonsignificant diagnostic does
not establish missing-at-random selection or transportability.

No automatic inverse-probability weighting, Lee trimming, or causal effect
bounds are approved by this review. A future selection analysis must specify
its target population, missing-outcome support, positivity, and the relevant
selection/exclusion/monotonicity assumptions before choosing a method.

## 4. Binding claim map

| Legacy or tempting claim | Permitted current statement |
|---|---|
| A was exhausted before B, then C. | Documentary priority rules changed; the 2012/2013 reports jointly prioritize A/B and add administrative/geographic conditions. |
| The design is validated because its first stage exceeds 10. | The registered instrument screen passes for specified outcome samples; additional identification assumptions remain substantive. |
| Reparations demonstrably increased migration by 25%. | The approved observed-adult estimate is positive but imprecise and not multiplicity-robust; it is measured in percentage points. |
| No effect exists because adjusted tests are nonsignificant. | No primary fixed-window fuzzy effect survives Holm adjustment in these six registered families; intervals still admit substantively important effects. |
| Linkage is ignorable. | Selection remains unresolved, and complete 2017 household availability has a notable discontinuity. |
| Employment/internet causally mediate the effect. | Intermediate-outcome RD estimates and contemporaneous associations provide limited mechanism evidence, not an identified indirect effect. |
| Project category or per-capita financing causally explains migration. | Project implementation is descriptive; project choice is post-assignment and the financing-dose exclusion restriction is not established. |
| Geographic sample and common window were prospectively prespecified. | They were fixed for this revised analysis after a historical exploratory design search; selection history must be disclosed. |
| Three aggregation levels independently replicate the causal finding. | They reuse related communities/cohorts and describe different weighted populations; they are not independent replications. |

These restrictions supersede legacy manuscript assertions without editing or
deleting that manuscript. The legacy abstract (line 40), conclusions (lines
724–730), and product-of-coefficients mediation discussion (lines 829–882)
must not be carried into the new draft as established results. Those are
locators in the inspected `Working Paper - Legacy/Working Paper.tex`, not an
instruction to change the live paper during this task.

## 5. Completed exhibit review and proposed compact set

All **94 preliminary appendix candidates** were accounted for and visually
inspected in rendered contact sheets: 58 LaTeX tables and 36 PNG figures.
Three required outcome-definition tables and two corrected individual
migration tables were also inspected. The self-contained table packet compiled
to 84 pages with all dependencies resolved. This is a review rendering, not
final journal pagination or disclosure approval.

[The dated exhibit register](../metadata/publication-exhibit-review-2026-09-30.csv)
records each of these 99 items, its checksum, review limitations, proposed role,
and exact prospective destination. The canonical 255-artifact publication
registry is intentionally unchanged: 94 preliminary appendix candidates,
155 internal-only items, six excluded dose artifacts, and zero release-eligible
items. A proposed role does not promote an artifact in that canonical registry.

Proposed main evidence: six existing artifacts, not six cherry-picked
significant outcomes—2013/2017 community main tables and their complete
primary-outcome forests, the corrected observed-adult individual table, and
the household availability/linkage diagnostic. Proposed appendix: 22 items
covering other aggregation levels, first stages, heterogeneity gates, project
implementation descriptions, bandwidth sensitivity, and three definition
dependencies. The remaining 71 review items stay internal.

Reader-facing safeguards before any promotion:

- Report family-wide estimates, intervals, Holm adjustments, effective CCPP
  counts, weighting, and denominator differences; do not foreground isolated
  raw p-values from sensitivity or intermediate-outcome analyses.
- Dense technical tables need final journal-page-size review. The 84-page
  landscape packet does not demonstrate readability in a manuscript column.
- First-stage local-linear fitted probabilities/normal intervals can exceed
  [0,1]. This is not an observed probability above one. Explain unconstrained
  fits and finite-sample limitations; do not clip confidence intervals or
  change the window to improve the display.
- Keep heterogeneity gate failures and assignment-only `rdhte` results visible
  in supporting evidence; do not interpret excluded financing-dose outputs.

Destinations are **proposals only**, beneath configured `overleaf_root`:
`World Development Manuscript/tables/main_text/`, `tables/appendix/`, and the
corresponding `figures/` directories. Preserve each existing basename and
extension. They are not yet consumed by a manuscript `\input`/`\includegraphics`
reference. No destination directory was created and no live file was copied
or replaced. The historical machine-specific manuscript path is not used to
infer a safe new publication target.

## 6. Verification and next scientific milestone

Modules 07 and 08 were rerun through `stata_run_selection`, followed by
`test_publication_candidate_outputs.do`, `test_release_audit_outputs.do`, and
`test_publication_repairs.do`. The final marker is
`IDENTIFICATION_REVIEW_PUBLICATION_CONTRACTS_RC=0`; the release check correctly
reports BLOCKED. The two manifests' run IDs were refreshed; their artifact and
input checksums are unchanged. No estimation output was re-estimated or
hand-edited.
The three contracts were rerun after the documentary locator correction and
again passed, ending with `FINAL_IDENTIFICATION_PUBLICATION_CHECK_RC=0`.

The standard-library checker
`code/python/check_identification_publication_review.py` verifies the review
inventory, hashes, original-candidate coverage, proposed destinations, explicit
holds, and source hashes when supplied the configured Dropbox root. It does
not invoke Stata or become part of the routine Stata master. This review
changes documentation and non-observation metadata only; the only Dropbox
writes were the newly acquired source intake and derived reading aids.
Four in-memory negative checks also rejected false approval/release flags,
a mismatched exhibit hash, and an unsafe destination; no source file was
mutated for those tests. Generated Python bytecode is ignored. Graphify's
AST-only refresh and a scoped query succeeded; the graph remains a navigation
aid, not evidence of semantic reading coverage.

A fresh read-only reviewer independently checked official page locators,
methodological anchors, all six primary Holm families, the 99-item inventory,
and target-path containment. One CMAN 2013 locator was corrected to include
PDF p. 53; no actionable finding remains. That review did not rerun Stata or
independently re-render all exhibits, and its integration-access limits are
recorded above. It complements, rather than substitutes for, the runtime and
rendering checks performed in this task.

**Superseding owner decision, 30 September:** acquisition of dated RUV histories,
annual eligibility lists, and award histories is closed as a prerequisite. Use
the existing CMAN year under the allocation-and-delivery assumption, without
representing timing as independently verified. The
[selection-feasibility milestone](CENSUS_2017_SELECTION_FEASIBILITY_2026-09-30.md)
evaluates the fixed populations without automatically applying weights or
causal trimming. Next: journal-sized exhibits, artifact-level disclosure/owner
decisions, canonical publication roles, and authorized manuscript synchronization.
