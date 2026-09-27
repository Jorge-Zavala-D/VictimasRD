# Census 2017 selection and CCPP-code comparability audit

**Date:** 27 September 2026. **Status:** diagnostic, not a change to the registered analysis or the data-preparation crosswalk. All checks used `stata_run_selection` on the existing Dropbox sources and analytical datasets. No Dropbox source, coded dataset, analysis program, or publication-facing output was changed.

## The three selection mechanisms are distinct

The public 2017 Census modules identify districts, not the RUV communities. CCPP-level outcomes instead start from an INEI-assisted SISFOH 2012–2013 source cohort. INEI's handoff reports 899 requested communities, 807 found in SISFOH, 193,376 source people, 150,864 linked Census records, and 42,512 unlinked people. It says 13 communities were recovered using place names and that SISFOH settlements below 150 inhabitants could be aggregated to district-level identifiers ending in `9999`. These details do not establish that each delivered person has a stable, individually verified ten-digit CCPP origin.

The table applies the fixed selected geography, adjacent B/C categories, and, for the right column, the common `|running_bc| <= 0.0075` window. Person rows are stages of the *assisted source cohort*, not national Census population counts. Community rows use the RUV universe as denominator. A later row conditions on every preceding filter unless stated otherwise.

| Stage | Selected B/C geography | Common RD window |
| --- | ---: | ---: |
| RUV communities | 549 | 71 |
| Communities with at least one assisted-cohort person | 426 | 65 |
| Communities with at least one linked person | 424 | 64 |
| Communities with at least one observable CCPP move | 410 | 62 |
| Assisted-cohort people | 110,940 | 13,044 |
| Linked to a 2017 Census record | 85,905 | 9,894 |
| Linked and CCPP movement observable | 83,717 | 9,189 |
| Linked adults aged at least 14 with observable CCPP movement | 67,125 | 7,157 |
| Those adults with the additional 2017 wellbeing score observed | 54,317 | 5,453 |

Source-cohort coverage is a **community/frame selection** problem: 123 of 549 B/C RUV communities, including six of 71 local communities, have no assisted-cohort person. Person linkage is a second selection step *within covered communities*. Movement observability is a third step: locally, 705 linked people lack a canonical CCPP movement outcome, all in two RUV communities without verified canonical ten-digit origin codes. The registered adult restriction uses `age_2017`, unavailable for unlinked people, so an exact all-source-cohort adult denominator cannot be reconstructed by applying that restriction to the unlinked group. The fourth, 2017-wellbeing-completeness filter is neither a linkage requirement nor a migration-data requirement; it removes 1,704 otherwise eligible local linked adults.

The existing robust bias-corrected RD diagnostics found a +10.73 percentage-point local jump in community cohort coverage (95% CI −11.66 to 33.12; p = .348) and a −8.28-point jump in person linkage (95% CI −35.21 to 18.65; p = .547). These intervals are wide. **Failure to reject a jump does not establish that linkage or outcome observation is ignorable.** The additional local wellbeing-completeness diagnostic is −32.96 points (95% CI −58.51 to −7.41; p = .011). These are diagnostic estimates, not identification tests that validate complete-case causal effects. See [the prior migration audit](CENSUS_2017_LINKAGE_MIGRATION_AUDIT_2026-09-22.md) for their registered estimator and population definitions.

## What weighting and bounds could, and cannot, identify

Inverse-probability weighting for *person linkage within the covered source cohort* is technically feasible as a sensitivity exercise. In the common window, a deliberately simple exploratory linkage logit using source age and sex, the running variable/side, 2007 community wellbeing, and 2006 community GDP had 12,578 complete records, of whom 9,527 linked. Predicted linkage probabilities among linked people ranged from .439 to .923 (1st–99th percentiles .592–.906); the inverse-probability-weight effective sample size was 9,438. This is a numerical overlap check, **not** evidence of missing at random, a validated weighting specification, or a corrected RD estimate. Linkage may depend on mobility, names, registration, or unmeasured factors related to migration. Treatment had already begun by the SISFOH survey, so most 2013 socioeconomic variables are not safely pre-treatment predictors for a causal selection model.

That model cannot solve source-cohort coverage: people in uncovered RUV communities are absent from the assisted frame, so their individual predictors and linkage outcomes are unavailable. Nor can weighting recover CCPP movement in the two local communities with *zero* observed canonical movement outcomes: within those communities positivity fails. Any proposed community-level frame weighting would require a separately stated target population, pre-program predictors observed in covered and uncovered communities, conditional-exchangeability and positivity assumptions, and a plan for uncertainty; it would not turn the assisted cohort into the national Census.

The binary outcome admits a transparent **descriptive missing-data range** for all ages in the fixed local assisted cohort. There are 3,475 observed movers among 13,044 source people and 3,855 people with unobserved canonical movement. Assigning every unobserved outcome first 0 and then 1 gives possible cohort prevalences of 26.6%–56.2%. This is not an RD effect interval, a fuzzy-IV LATE bound, or a bound for the registered linked-adult population. The existing “unlinked as mover/nonmover” endpoints also leave linked people with unknown movement missing and must not be relabeled formal causal bounds.

Formal selection bounds would require a common and correctly linked source population, explicit local RD continuity and treatment-compliance assumptions, and a justified assumption about the direction of selection (or another partial-identification restriction). Lee's trimming bound uses monotone selection for an always-observed stratum; Dong develops RD-specific selection results, including treatment noncompliance, under its own smoothness and principal-stratum assumptions. Neither may be applied mechanically to the present staged selection and ambiguous CCPP origins. A causal weighting or bounds result is **not currently defensible as a primary or publication claim**. [Lee's paper](https://www.princeton.edu/~davidlee/wp/resrevision8.pdf), [Dong's RD-selection article](https://doi.org/10.1080/07350015.2017.1302880), and [Wooldridge's IPW study](https://doi.org/10.1016/j.jeconom.2007.02.002) motivate the candidate methods; the project's assumptions still have to be assessed from its own records.

## Historical-to-2017 code review

The existing [source-to-RUV crosswalk](../metadata/census-2017/source-ccpp-crosswalk.csv) is an executable 807-source-code to 803-RUV-community map and marks every row accepted. The new [807-row comparison ledger](../metadata/census-2017/historical-to-2017-code-review.csv) is **audit-only**. It compares each historical source code and its RUV name with the project's 2007 CCPP workbook and 2017 GeoGPS/INEI directory, plus the currently verified RUV code. It carries no person or household records or counts. Accent/case/punctuation normalization supports exact-name comparison; it does not authorize a fuzzy match or prove continuous identity.

| Review state | Source codes | Interpretation |
| --- | ---: | --- |
| Directory-consistent candidate | 634 | Same historical and verified RUV code; RUV name agrees with the 2017 directory and with 2007 where the latter is available. Person origin remains unverified. |
| Same-code name review | 112 | Code agrees, but at least one available directory name differs or the 2017 code is absent. Distinguish alias, renaming, and code reuse. |
| Code-change review | 29 | Historical code differs from verified RUV code; a dated equivalence is still needed. |
| No verified canonical code | 30 | No safe ten-digit RUV origin for the comparison. |
| Explicit conflicting-code hold | 1 | See Cahuapirhua below. |
| Code candidate, person-origin hold | 1 | See Ranracancha below. |
| **Total** | **807** | No review state changes the executable source crosswalk. |

Across all 807 rows, 791 historical source codes appear in the 2017 directory and 16 do not; 746 equal the currently verified RUV code and 32 have no such code. These are *directory comparisons*, not a historical equivalence register. The project's 2007 workbook is incomplete nationally, and the 2017 GeoGPS files redistribute INEI material rather than constituting an INEI-supplied dated change log. INEI describes its 2017 CCPP system as a census-era directory, not a continuously updated historical crosswalk. [INEI's 2017 CCPP publication](https://www.gob.pe/institucion/inei/informes-publicaciones/4382341-censo-2017-centros-poblados), [INEI's CCPP consultation description](https://www.gob.pe/24116-consultar-informaci-n-sobre-centros-poblados).

Two locally important cases require an explicit hold:

- **S03000238, Cahuapirhua, Grau/Progreso.** The executable map attaches historical `0307080005`, but both local 2007 and 2017 directories name that code *Ancahuasi*. The assisted file's `nomccpp` field instead says *Ccahuanhuire*, which is a separate RUV entry, S03000211, with verified `0307080030`; the 2017 directory also names `0307080030` *Ccahuanhuire*. These three identities cannot be treated as synonyms. No canonical Cahuapirhua code is verified. Keep movement missing and do not reassign these people to any RUV community without INEI's original requested-place list and linkage/code rules.
- **S03000445, Ranracancha, Chincheros/Ranracancha.** RUV has no verified canonical code, although the project's 2007 and 2017 directories and its two downstream name matches all point to `0306080001` for the named settlement. This is a **community-code candidate**, not an adjudicated person-origin assignment: the assisted file associates multiple `nomccpp` strings with that single source code, including names other than Ranracancha, even without a `9999` source identifier. Preserve unknown movement until the meaning of `nomccpp`, the aggregation rule, and the origin of the requested code are resolved.

The raw-file name field is therefore a warning, not an automatic correction key. It has multiple distinct strings under 101 of 807 historical source codes. INEI's handoff says small source settlements may have `9999` IDs; the raw file contains such IDs, but variation in `nomccpp` also occurs under an ordinary-looking code. The handoff does not define that field precisely enough to determine whether it is the requested community, a constituent hamlet, or another SISFOH geography. An exact code comparison with the 2017 destination would classify some of the currently unknown cases as movers and others as nonmovers, but it would silently assume stable, correctly assigned CCPP identity. That assumption is presently unsupported.

## Decision gate and next evidence

1. Keep the approved linked-adult, canonically observed migration estimand and its missing values unchanged. Do **not** promote the raw-code comparison, reassign either held source code, or rerun publishable estimates from the comparison ledger.
2. Obtain the original 899-place request list, an INEI field dictionary for `ubigeo_ccpp`, `idccpp_sisfoh`, `nomccpp`, and `idccpp2019`, the rules for `9999` aggregation, and an official dated 2007/2013-to-2017 CCPP equivalence or confirmation for the two held places. The 2019 handoff alone is insufficient.
3. Have the research team decide whether the assisted cohort can identify the intended RUV-community origin for person and household outcomes, and whether to quarantine disputed source codes or alter the target population. Record that decision before any pipeline or estimand change. Only then evaluate an explicitly labeled selection-sensitivity analysis and a formal partial-identification design.

This audit creates no new evidence that linkage is ignorable and does not make the existing 2017 results publication-ready. The non-sensitive ledger is deliberately separate from person-level QA, which must remain in Dropbox Working.
