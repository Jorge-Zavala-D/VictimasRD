# Primary results narrative and Online Appendix D: drafting audit

Date: 2 October 2026. Status: **this writing batch validated; scientific and exhibit-release holds unchanged**.

## Scope and delivered sources

The owner requested the next approved manuscript batch: main results and Online
Appendix D, using frozen module-04 evidence. Exactly two existing live sources
were changed beneath the Overleaf root resolved from ignored `config/paths.local.do`:

- `World Development Manuscript/sections/05_results.tex`: 1,610 source tokens;
  complete-family synthesis, effect magnitudes, uncertainty, first stages,
  weighting, observed-adult migration, and selection boundaries.
- `World Development Manuscript/appendix/D_additional_results.tex`: 2,434 source
  tokens; all 48 primary estimate/interval pairs, six complete families,
  multiplicity definitions, secondary coverage, specification sensitivities,
  weak-instrument and selection qualifications.

Counts are whitespace-delimited TeX-source tokens, not certified journal word
counts. All manuscript sources remain in the authoritative live Overleaf tree;
Git records this receipt and the project-context pointer. No new regression
table was manually constructed, no generated exhibit was edited or inserted,
and the bibliography was unchanged. Mechanisms/heterogeneity, introduction,
abstract, conclusion and the other remaining sections were not drafted here.

The initial checkout was `main` at `7b00866`. Before this batch, the context/
framework pointer in `docs/PROJECT_CONTEXT.md` was already modified and
`docs/MANUSCRIPT_CONTEXT_FRAMEWORK_AUDIT_2026-10-02.md` was already untracked.
Both were preserved. No staging, commit or push was performed.

## Frozen-evidence audit coverage

Three independent read-only reviewers covered 2013, 2017 and inference/
multiplicity. No observation-level dataset was opened or estimate rerun.

- All **1,970 aggregate result rows** were checked: 319/352/392 at the 2013
  community/household/person levels and 273/286/348 at the 2017 levels.
  No estimator return-code failure or current numerical discrepancy requiring
  result regeneration was identified.
- All **48 primary printed rows** reconcile with their source estimates,
  intervals, control means, reduced forms and adjustments at displayed precision.
- All **245 printed nonprimary common-window rows** reconcile: 143 in 2013 and
  102 in 2017. These include secondary, mechanism and exploratory tiers; they
  are not 245 registered secondary outcomes.
- All **401 printed robustness rows** reconcile with frozen cells: 200 in 2013,
  201 in 2017. Full CSVs also retain branches not in those printed subsets.
- Independent Holm/BH reconstruction found no discrepancy in any recorded
  specification/estimand/multiplicity group across the six aggregate CSVs.
- All **117 module-04 manifest artifacts** exist. All **72 registered module-04
  figures** were individually visually inspected. Forty-two matching 2013/2017
  exhibits in the dated review register retain their SHA-256 hashes.
- The existing publication checker freshly passed 99 reviewed exhibits, 94
  original candidates, ten documentary records/eight acquired-source hashes,
  and all 35 held review exhibits and 287 source-cell ledger rows. Decimal Stata
  checksums were cross-matched, not falsely described as recomputed SHA-256.

The main result sources are `output/tables/rd_outcomes/rd_2013_*_results.csv`
and `rd_2017_*_results.csv`, their six registries under `metadata/rd-outcomes/`,
`metadata/rd-outcome-output-manifest.csv`, and the publication source-cell ledger.
These remain immutable in this writing batch.

## Binding numerical and interpretation checks

| Claim retained in the drafts | Verified source and qualification |
|---|---|
| No primary common-window fuzzy rejection after Holm | 48 rows; six eight-test families, not one global family. All pointwise robust intervals span zero. Non-rejection is not zero impact or equivalence. |
| Primary local-IV KP first stages | 2013: 10.49/11.10/11.10; 2017: 54.92/21.04/21.06; observed-adult migration: 20.80. Strict owner-approved F>10 retained, with marginal 2013 strength explicit. Squared robust RD z is a different statistic. |
| Observed-adult movement | +21.45 pp, robust interval [-17.24,60.14], raw p=.277, Holm=1.000; 7,680 local people in 63 RUV communities from 67,648 eligible linked adults. Not the all-source-adult population or a relative-percent increase. |
| Other 2017 individual outcomes | Seven rows retain 5,948 local people in 62 communities from the 54,812 complete-case population; no borrowing of the movement denominator. |
| Household availability | Assignment discontinuity -29.71 pp, interval [-52.20,-7.22], raw p=.0096; 4,051 source households in 64 local communities. Selection diagnostic, not a family-adjusted substantive outcome. |
| Household-member linkage rate | -9.82 pp, interval [-34.82,15.17], raw p=.4412. A rate, not the binary any-member-linked indicator. Nonsignificance is not ignorability. |
| Adjusted parametric sensitivity signals | 2017 community employment -17.71 pp, Holm=.0453; household female composition +10.41 pp, Holm=.0470. Their RBC counterparts do not survive correction. Adjustments do not cover the full specification search. |
| Complete-case migration sensitivity | RF +43.37 pp and fuzzy +44.81 pp; latter interval [-1.01,90.64]. Exploratory singleton adjustments, not the primary eight-test family or preferred movement population. |
| Secondary coverage | 229 explicitly secondary common-window fuzzy outcomes: 41/42/55 and 27/25/39. None has raw p<.05 or within-domain BH q<.05; no recorded secondary specification has BH q<.05. Not a global 229-test correction. |

The drafts also retain nominal reduced-form signals, weak observation-equal
weighting branches, outcome-specific windows, sample changes due to covariate
availability, and unconstrained first-stage fits above one. Related years and
aggregation levels are not independent replications. Directory totals are
separated from assisted-cohort measures; SISFOH counts are enumeration counts.
Conditional receipt ratios are not unconditional causal effects, origin-place
welfare, rural-urban migration or identified mediation.

## Literature consultation and underlying sources

Both required integrations were consulted read-only. The exact Zotero group
`IE Collective Reparations Peru` resolved to library ID 5; chapter metadata and
attachments were retrieved. Its targeted PDF reader returned no paper context,
so the underlying local Bartalotti--Brummet PDF was read instead (PDF pp. 2--4).
No Zotero mutation, import or authentication repair occurred.

NotebookLM health reported unauthenticated and an unrelated active notebook;
the explicit VictimasRD public URL nevertheless answered the bounded questions
in session `b1266b69`. This is not exhaustive ingestion or an authentication
repair. Its overstatement that every outcome *requires* an automatic bandwidth
and its automatic selected-sample CLATE claim were not adopted.

The two existing citation keys used in Appendix D were independently checked:

- `cattaneo_extensions_2024`: [author version](https://mdcattaneo.github.io/books/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf),
  Section 3.2.4, PDF p. 48/printed p. 46, explicitly warns that F10 can be too
  low for RD and discusses stronger thresholds. The owner's F>10 screen is not
  silently changed or presented as a sufficient methodological guarantee.
- `dong_selection_2019`: [author-hosted article](https://www.yingyingdong.com/Research/J14_JBES.pdf),
  PDF pp. 5--7: smooth selection alone does not supply the selected-population
  causal interpretation; bounds require additional assumptions about potential
  selection and outcomes. The browser retrieval failed, but an in-memory
  read-only HTTPS/PDF extraction succeeded. No PDF was written into Git or Dropbox.

## Review corrections and held presentation defects

The independent manuscript reviews closed with no residual actionable 2013,
2017 or inference finding after these corrections:

1. Use **20.80 KP F** for observed migration. An older
   `docs/CENSUS_2017_RD_ANALYSIS.md` passage calls 20.10 KP; that value is squared
   robust RD z. New prose follows current contracts, not the stale label.
2. Call the -9.82 diagnostic the **household-member linkage rate**, not
   any-member linkage.
3. Retain both Holm-significant parametric sensitivities, while distinguishing
   them from nonsignificant primary and RBC branches.
4. Preserve the corrected complete-case sensitivity's singleton adjustment and
   its different population; do not quote superseded historical cells.

Existing figures are not all publication-ready. Held 2013 household/person
forests have clipped source notes; household panels have overlong/crowded
headings. Held 2017 directory population/dwelling plots 45/46 and their panels
in figure 42 incorrectly say **Log roster count** on the y-axis. Their numeric
annotations are consistent, but their axes need versioned-code repairs before
insertion. The 2013 main/dedicated first-stage tables also differ by .001 in
one displayed upper endpoint due to rounding. These defects do not authorize
editing frozen artifacts during this prose batch and remain explicitly held.

## Fresh preservation and manuscript validation

Ignored `build/manuscript-results-2026-10-02/` contains the before-source copies,
279-path SHA-256 baseline, minimal read-only claim/preservation checker, reused
compile mirror/render helper, build logs, rendered pages and preview PDFs.

- Exactly **two authorized live sources** changed; **277 protected files**,
  including the bibliography, legacy sources and frozen artifacts, are unchanged.
- The runnable checker reconciles all 48 appendix estimate/interval triples,
  verifies six complete families, resolves both citation keys, rejects exhibit
  insertion, and preserves all 35 hold dispositions.
- Fresh multi-file builds succeed with exit code 0: main preview **25 pages**,
  online appendix preview **33 pages**. Four initial overfull lines were corrected
  through local result-paragraph formatting, without changing numeric cells.
  Final logs have no undefined citations/references, warnings, overfull or
  underfull boxes.
- Every preview page was rendered; text-bound checks passed. Contact sheets and
  detailed new-results pages were visually inspected for wrapping and clipping.
  These are full draft/scaffold previews, not completed submission PDFs.

Final live-source SHA-256:

- `sections/05_results.tex`: `C556374BD0BC2E472128E4BB54006C6C61C65D1963BA66A56D76813B8D278B84`.
- `appendix/D_additional_results.tex`: `3829B6A15F6927EEC3DC81C9FAD71AF6B2BB7DBBA283E0DC4F7C23D86BFCB72F`.

No Stata execution was needed. No dataset, raw/archive file, score, treatment
rule, selected sample, estimator, multiplicity family or release decision was
changed. All 35 exhibits retain `owner_approved=0`, `release_eligible=0`,
`hold_no_sync`; the whole-paper release status remains **BLOCKED**.

## Next writing batch

Draft mechanisms/heterogeneity and Online Appendix E using the frozen module-05
and module-06 evidence, separating gated receipt heterogeneity, assignment-only
checks, intermediate-outcome RD and noncausal mechanism associations. Draft the
planned robustness/limitations synthesis next or in that same approved batch.
Introduction, abstract and conclusion follow only after those boundaries are
fully reflected. Generated-exhibit presentation repairs and artifact-level
release/insertion remain separate, explicit production steps.
