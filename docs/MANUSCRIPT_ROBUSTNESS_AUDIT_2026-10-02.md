# Manuscript robustness and interpretation-limits audit

## Completed milestone and exact scope

The owner authorized the next writing milestone in the approved
[revision plan](MANUSCRIPT_FRAMING_AND_REWRITE_PLAN_2026-10-02.md): synthesize
robustness and limitations after the completed results and extensions batches,
before drafting the introduction, abstract and conclusion.

The existing live `World Development Manuscript/sections/07_robustness.tex`
was replaced with a concise, threat-organized substantive draft. The root was
resolved from ignored `config/paths.local.do`. Its `sec:robustness` label is
preserved. Online Appendices C--E already contain the detailed supporting
evidence and were not changed or duplicated. No generated exhibit was inserted.

Preflight found a clean primary checkout on `main`, HEAD
`37c22a441495f586d45a8ada7963d729f855ee8b`. This batch creates this audit
record and a completion pointer in `docs/PROJECT_CONTEXT.md`; the manuscript
edit is outside Git in the authorized synchronized Overleaf publication tree.
There was no pre-existing uncommitted repository work to fold into this batch.

## Threat, check and remaining interpretation

| Threat | Frozen checks or evidence used | Verdict in the new section |
| --- | --- | --- |
| Institutional assignment and historical sample selection | Verified joint A/B priority, administrative/geographic conditions, changing earlier regimes, preserved support/cutoff audit | B/C is an institutionally relevant local margin; the extract and timing assumption do not establish a constant historical assignment regime. Conventional intervals do not cover historical geographic-search uncertainty. |
| Rounded score, finite support and sorting | 71 base-window communities, 54 distinct scores; category/sign and half-rounding-band checks; density and adjusted covariate tests; five-community local-randomization window | Non-rejection is not equivalence or absence of manipulation. Extrapolation remains necessary; mass-point adjustments and score clustering cannot create missing support. Randomization inference was not run because support failed. |
| Specification dependence | Selectors, fixed windows, kernels, polynomials, donuts, controls and weights; all primary families; both adjusted parametric signals | No primary family has a Holm rejection. The two adjusted parametric signals are retained as model-dependent findings, not promoted. Changes in availability and weights can change the compared population. |
| Weak instruments and dependence | Outcome-specific local-IV KP statistics, Anderson--Rubin/wild-cluster checks, registered cluster sensitivities | The owner's F>10 screen remains binding, not a guarantee of strong-IV inference or identification. Local-IV checks are not relabeled RBC checks. Spillovers and dependence outside chosen clusters remain unresolved. |
| Selective Census observation | Source coverage, linkage, movement observability and household completeness; baseline-only feasibility models; descriptive missing-movement intervals | A notable household-availability discontinuity is disclosed. A nonsignificant linkage result does not justify MAR, transport, automatic weights or causal trimming. |
| Measurement and cross-source comparability | Documented 2007 proxies, SISFOH administrative enumeration, linked cohort/destination measurements, district-derived GDP allocation | Transparent construction is not equivalent measurement, a population-weighted national estimate, an official poverty headcount, or independently measured local growth. |
| Multiplicity and alternative explanations | Six complete eight-outcome families, preserved heterogeneity/mechanism hierarchy, institutional implementation evidence | Within-family Holm is not a correction for every search/specification. Non-rejection is not zero; aggregation levels are not independent replications. Politics, other programs, implementation and neighbor priorities are not ruled out. Post-treatment variables cannot be ordinary identifying controls. |

The World Development robustness, identification, referee-strategy and
writing-style skills informed this organization: each named threat receives a
check and an explicit qualified verdict, including adverse or unavailable
evidence. Economics-writing guidance kept effect units and population limits
visible. No new estimator, cutoff, treatment horizon or substantive assumption
was selected to strengthen the narrative.

## Numerical reconciliation

The ignored, runnable `build/manuscript-robustness-2026-10-02/check_robustness.py`
checks frozen aggregate CSV cells, the live edit scope, citations and hold flags.
It was first run against the original placeholder and failed as expected;
after authoring, it passes. It does not invoke Stata or change any analysis file.

- All six `rd_*_{ccpp,household,individual}_results.csv` primary
  `common_h_fuzzy` families retain eight outcomes: 48 hypotheses, none with
  within-family Holm p<0.05. This is not an equivalence conclusion.
- The minimum primary `parametric_common_h` first-stage statistics for 2013
  are 10.486603, 11.096713 and 11.101704, printed as 10.49/11.10/11.10.
  These are the local-IV KP statistics, not squared `rdrobust` z-statistics.
- The two adjusted parametric signals are 2017 community P06 employment:
  -17.705044 points, interval [-30.247644,-5.1624432], Holm p=0.0452984534;
  and household H01 female composition: +10.414596 points, interval
  [3.0037448,17.825447], Holm p=0.0470367856. The main synthesis rounds the
  estimates and refers to unchanged Appendix D for the full uncertainty.
- Household D05 `common_h_primary_observed` is -29.710552 points, RBC
  interval [-52.199474,-7.2216296], raw diagnostic p=0.0096158301. Its parent
  local frame contains 4,051 source households in 64 communities. It is not
  the member-linkage diagnostic or a treatment-effect outcome.
- Individual I03 `common_h_fuzzy` is +21.448185 points, RBC interval
  [-17.242022,60.138393], raw p=0.27724916, Holm p=1. The primary observed
  adult window has 7,680 people in 63 communities; unlinked people are not
  coded non-movers. No larger source frame is substituted.
- The frozen density CSV has no p<0.05 rejection; adjusted covariate tests
  have no Holm/BH rejection. The local-randomization CSV explicitly records
  `not_run_insufficient_window_support` with five communities. Neither
  unavailable inference nor nonsignificant diagnostics is called validation.

Existing source/window counts and data-construction qualifications were also
checked for consistency with the current strategy, measurement and Online
Appendix C drafts, rather than reopening restricted row-level datasets.

## Literature and documentary source verification

Both mandated discovery integrations were consulted read-only:

- A fresh explicit-project-URL NotebookLM query timed out after 300 seconds.
  The health check reported unauthenticated status and a different active
  notebook; neither was treated as successful access to the project corpus.
  No authentication, notebook selection or source library was changed.
- Zotero resolved the exact shared `IE Collective Reparations Peru` library
  as ID 5. Read-only searches returned methodological metadata, including
  Bartalotti--Brummet and Gelman--Imbens. Targeted attachment retrieval returned
  `No paper context available`; metadata access was not represented as a
  successful reading of that attachment or comprehensive bibliography review.

The new section uses only three existing bibliography keys, verified against
underlying sources rather than AI synthesis:

- [Kolesar and Rothe, author version](https://arxiv.org/pdf/1606.04086), PDF
  pp. 1--4: finite-score gaps and approximation bias; score clustering is not
  a general solution. Bibliographic year/volume/pages/DOI were checked against
  the [author publication record](https://www.princeton.edu/~mkolesar/research.html).
  The inspected November 2017 author version corresponds to the 2018 article;
  it is not described as the publisher's typeset file.
- [Cattaneo, Idrobo and Titiunik, Extensions](https://mdcattaneo.github.io/books/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf),
  PDF pp. 46--48 and 58--60 (printed pages differ): fuzzy ratio/window logic,
  weak assignment, caution about the F=10 rule, validation and distinct score
  counts. The March 2024 author version and its published DOI match the
  existing `cattaneo_extensions_2024` entry. No source-endorsed F=10 guarantee
  or new threshold is asserted.
- [Dong, author-hosted article](https://www.yingyingdong.com/Research/J14_JBES.pdf),
  PDF pp. 5--7: selected-population effects and restrictions for causal bounds,
  including individual potential-selection monotonicity. The web reader
  could not fetch the PDF; a direct read into memory succeeded. No copy was
  downloaded to Git or Dropbox. The existing 2019 citation identifies the
  published article, not the date on the inspected online-first pages.

For the institutional paragraph, verified CMAN 2012 PDF pp. 7--9 were reread
from the immutable acquired public-source file: joint A/B priority,
registration, accountability, inherited technical files and VRAEM priority.
The [dated source register](../metadata/rd-design/identification-evidence-2026-09-30.csv)
provides the intake hash and public URL. No new source or raw-data write was
needed. All three new-section citation keys resolve in the unchanged shared
bibliography.

## Independent review and execution rulings

The executing-plans skill's single fresh-context final reviewer independently
read the new section and its supporting manuscript/audit passages and reran
the read-only checker. Verdict: **no Critical or Important finding; clean for
this writing milestone**, not unconditional identification or publication.
The reviewer did not re-estimate, mutate files, spawn agents or claim to have
recompiled/reread the complete methods papers. Root independently performed
the underlying-source, compilation and visual checks above/below.

Rulings:

- Use the existing approved manuscript map and one live section rather than
  create another pipeline, appendix or duplicate threat table. The existing
  appendices already carry the full evidence; a duplicate would add a second
  narrative maintenance target. The audit table above records the logic.
- Preserve the owner's authorized uncommitted `main` workflow; no worktree,
  staging, commit or push. Software-specific commit/workspace instructions
  do not override that authorization. Ignored checks/builds remain local.

Deferred minor: the reviewer suggested repeating that observation-equal
weighting changes the community-balanced target and fails the instrument
screen. The results section and Online Appendix D already state both facts.
The current compact synthesis mentions weights and differing effective
populations without duplicating that detailed verdict. This is not missing
analysis, a contradictory statement, or a changed weighting contract.

## Preservation, compilation and visual inspection

The ignored batch folder preserves the original section, a fresh **461-path**
SHA-256 baseline, the minimal check, reused compile mirror/render helper,
compiler log, 31 rendered pages and the review PDF. The baseline was rebased
to current files rather than compare against earlier writing-batch versions.

- Exactly **one authorized live source** changed; **460 protected files**
  remain byte-identical, including prior/legacy manuscript sources,
  bibliography, validation evidence and frozen result artifacts.
- The reused multi-file TeX build succeeds with exit code 0. Its 13 actual
  main-document TeX inputs and bibliography match current live sources.
  Unused administrative files are not asserted to be build dependencies.
- The main preview has **31 pages**. The new robustness prose spans pages
  25--28. All pages were rendered and passed glyph/text-bound checks;
  the contact sheet and the four affected pages were visually inspected.
  Final log has no warnings, undefined references/citations or overfull/
  underfull boxes. Remaining scaffold sections are visible as placeholders.
- New section: 802 TeX-source tokens, not a certified journal word count.
  SHA-256 `EB22EF893D84DDFFC27876E6DD2C4E78B1D5A5DDFF098551CE3CB49FC654D21C`.
- Preview SHA-256:
  `C04E44B0DED91246F5476A12E6C5BCB810EA060F071E9234A2FCCC62AEBE5C4A`.

The existing publication checker also passes: 99 reviewed exhibits/94
original candidates; ten documentary records and eight acquired sources;
35 review exhibits and all 287 underlying aggregate review rows. Its
negative controls, source hashes and hold checks remain intact.

No Stata execution or re-estimation was needed. Data, Raw/archive material,
Working/Coded datasets, analysis programs, registries, estimates, treatment,
samples and adjustment families were not changed. All 35 review exhibits
retain `owner_approved=0`, `release_eligible=0`, `hold_no_sync`. Whole-paper
status remains **BLOCKED**: technical writing validation is not scientific,
disclosure or artifact-level publication clearance.

## Next immediate writing milestone

Draft the introduction and conclusion from the now-completed substantive
foundation; finalize the abstract and title only after the reader promise
matches the audited evidence. Do not insert held exhibits or declare journal
submission compliance in that writing batch. Production, disclosure and
submission checks remain later and separate.
