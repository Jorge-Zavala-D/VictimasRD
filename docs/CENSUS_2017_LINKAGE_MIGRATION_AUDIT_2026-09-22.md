# Census 2017 linkage and migration: substantive audit

**Audit dates:** 22–23 September 2026  
**Status:** Scientific-review hold; no individual migration estimate is approved for the paper.  
**Design held fixed:** Selected B/C geography, treatment through 2016 (`treat_16`), local-linear triangular-kernel RD, common `h = 0.0075` and `b = 0.0135`.

## Question and source boundary

The INEI-assisted 2017 file covers a defined SISFOH source cohort, not the full 2017 Census population of the selected RUV communities. This audit separates four filters: whether an RUV community enters that source cohort; whether a source-cohort person links to a Census record; whether linked records have a valid centro-poblado (CCPP) migration outcome; and whether the additional eight-outcome primary-sample rule retains them. The original INEI delivery and current Dropbox Coded datasets were read without alteration. Exploratory diagnostics were run in-console through `stata_run_selection`; no row-level data were exported.

The intended design is a local effect of collective-reparation receipt for B/C-cutoff compliers in the selected geography. The registered individual migration estimate has a narrower observed population: linked people aged at least 14 with a valid CCPP-move outcome **and** a complete 2017 wellbeing score. Wellbeing completeness is not needed to observe migration and is measured after treatment. The available data do not establish that selection into any observed subset is ignorable.

## Population flow

| Stage | Selected B/C geography | Within the common RD window |
|---|---:|---:|
| RUV communities | 549 CCPPs | 71 CCPPs |
| RUV communities covered by INEI-assisted source cohort | 426 CCPPs | 65 CCPPs |
| People in the source cohort | 110,940 | 13,044 |
| People linked to a 2017 Census record | 85,905 | 9,894 |
| Linked people with valid canonical CCPP movement | 83,717 | 9,189 |
| Linked adults with valid canonical CCPP movement | 67,125 | 7,157 |
| Registered eight-outcome complete-case primary sample | 54,317 | 5,453 |

The full assisted file has 193,376 source-cohort records: 150,864 linked and 42,512 unlinked. Within the common window, 1,704 linked adults with observed CCPP movement are excluded from the registered primary sample solely because `wellbeing_core_2017` is missing. These records span 60 CCPPs. The score's services component is missing for all 1,704; the other non-migration variables in the eight-outcome primary registry are complete for this group. Thus the registered migration result is also a result for a *wellbeing-complete* subgroup.

## Selection at the cutoff

These are discontinuities in percentage points, not evidence that selection is random. The first three rows are existing module-04 diagnostics; the last is an exploratory in-console diagnostic conditional on already having a valid linked adult migration record. Robust bias-corrected inference uses the fixed B/C bandwidth. The person-level diagnostics use CCPP-equal weights and CR2 clustering by RUV community.

| Stage and conditioning set | Cutoff jump, pp | 95% CI, pp | Raw p |
|---|---:|---:|---:|
| RUV community covered by assisted source cohort; all 549 B/C RUV CCPPs | +10.73 | [-11.66, 33.12] | .348 |
| Person linked to Census; assisted source-cohort members | -8.28 | [-35.21, 18.65] | .547 |
| CCPP person-linkage rate; cohort-covered communities | -8.28 | [-35.36, 18.81] | .549 |
| 2017 wellbeing score complete; linked adults with valid migration | -32.96 | [-58.51, -7.41] | .011 |

The first three intervals are wide: failure to reject a linkage discontinuity does not establish missing-at-random linkage or representativeness. Raw wellbeing-completeness rates within the window are 77.67% on the B side and 75.51% on the C side; those side averages are not the local-polynomial cutoff jump. For wellbeing completeness, the exploratory jump is -48.60 pp at `h = 0.005` (p=.0005), -32.96 pp at the registered `h = 0.0075` (p=.0114), and -15.79 pp at `h = 0.010` (p=.1976). District-clustered inference at the registered bandwidth gives p=.0138. This bandwidth sensitivity and the score's mass points warrant care. The conditional diagnostic is not a causal effect on wellbeing availability in the full source cohort and has not been added to a preregistered outcome family.

## Migration estimates across observed populations

These populations answer different questions. Changing sample membership is not a standard-error robustness check. Each row retains the selected geography, fixed bandwidth, treatment timing, CCPP-equal weights, and CR2 clustering by RUV community. New rows are exploratory and have not undergone primary-family multiplicity adjustment.

| Population and canonical migration definition | Local CCPPs | Fuzzy-RD estimate, pp | Raw p | Assignment reduced form, pp | Raw p |
|---|---:|---:|---:|---:|---:|
| Registered linked-adult, eight-outcome complete case | 61 | +45.62 | .052 | +43.72 | .004 |
| Linked adults with valid CCPP migration | 62 | +21.86 | .270 | +20.90 | .118 |
| All linked people with valid CCPP migration | 62 | +22.27 | .267 | +21.33 | .114 |

The registered reduced form is the only module-04 primary result that passed its original Holm and BH adjustment (both adjusted p=.0327). Its magnitude and significance do **not** persist when migration-observed adults excluded only for wellbeing-score missingness are included. The migration-specific adult sample still passes the project's fixed first-stage gate: the local-IV Kleibergen–Paap F is 20.66, above 10. The attenuation is therefore not explained by a failed first stage. At bandwidths .005, .0075, and .010, migration-specific adult fuzzy estimates are +26.37 (p=.312), +21.86 (p=.270), and +24.13 pp (p=.236), respectively. These findings do not justify a paper claim that treatment increased migration in the full linked-adult or source-cohort population.

## CCPP-code comparability and linkage endpoints

The canonical move outcome compares the 2017 destination CCPP with the reviewed RUV source-community code, as specified in the Census 2017 preparation contract. In the common window, 705 linked people across two CCPPs lack this canonical outcome. Both the original INEI source and 2017 destination codes are syntactically valid for these records; directly comparing them would classify 154 as movers. But a historical source code is not automatically a stable 2013–2017 community identity. Within the window, 272 linked records across two CCPPs have an original source code different from the retained SISFOH code; 265 differ even at the six-digit district prefix. Raw-code comparison is therefore a **measurement sensitivity**, not an authorized replacement for the reviewed canonical crosswalk.

Using the raw-code comparison in the registered complete-case population yields a fuzzy estimate of +44.64 pp (p=.060). Allowing raw-code comparison to expand that complete-case population yields +39.74 pp (p=.089; 63 local CCPPs). Applying it to all linked people with valid original codes yields +21.87 pp (p=.269; 64 local CCPPs). These exploratory comparisons point more strongly to the wellbeing-completeness restriction than to the code definition as the source of the headline estimate's instability. A decision to change the authoritative migration variable requires historical-to-2017 code-crosswalk adjudication first.

The existing `moved_or_not_linked_sens_2017` expression also coded linked people whose movement was *missing* as nonmovers. Its prior fuzzy estimate (+16.10 pp) used all 110,940 selected B/C source-cohort people, while the complementary endpoint (+7.84 pp) used 108,752. Versioned code now leaves linked people with unknown migration missing in **both** branches and asserts identical denominators. An in-console same-denominator check (108,752 in both) yielded +12.46 pp (p=.433) when unlinked people are assigned mover status and +7.84 pp (p=.338) when assigned nonmover status. These are alternative outcome codings, **not formal bounds on the fuzzy-RD treatment effect**. Their broader source-cohort denominator also differs from the registered 54,317-person complete-case analysis; plotting all three as one common-population sensitivity would be misleading.

## Interpretation and decision gate

1. Keep the already-approved geography, B/C cutoff, `treat_16`, common bandwidth, and first-stage gate. This audit does not reopen those decisions.
2. Hold the 2017 individual main-results table, related figures, heterogeneity exhibits, and linkage-sensitivity comparison figure out of publication review. Module 05f inherits the same wellbeing-complete primary sample. The publication registry marks these `internal_only`; nothing was sent to Overleaf.
3. **Recommended team decision:** use linked adults with a valid canonical CCPP-move outcome as the primary *observed migration* population. Report the existing eight-outcome complete-case result, if useful, only as a differently selected sensitivity. This does not identify an effect for all source-cohort adults or establish a causal effect within the linked subset without additional selection assumptions. The research team must explicitly approve this substantive change to the registered analysis contract before code or tables present it as primary.
4. Keep cohort coverage, Census linkage, and outcome observability as distinct stages. Neither a nonsignificant linkage test nor extreme-case recoding licenses a missing-at-random assumption, principal-stratum interpretation, inverse-probability correction, or formal bounds. Any such analysis needs its own estimand and assumptions.
5. Treat internet access, employment, and other 2017 variables as candidate intermediate outcomes or descriptive associations, not identified causal mediators of contemporaneously measured migration.

The need to distinguish an observed-outcome RD from an effect for people selected into observation is consistent with [Dong's sample-selection analysis](https://doi.org/10.1080/07350015.2017.1302880) and the [Lee–Lemieux RD review](https://www.princeton.edu/~davidlee/wp/RDDEconomics.pdf). Those references motivate a separate identification analysis; they do not validate the current extreme-case codings as bounds.

## Reproducibility and release status

The full module-04 results pipeline was rerun through `stata_run_selection`, followed by modules 06, 07, and 08. The corrected E01 and E02 estimates in the regenerated individual-results CSV are +12.461 and +7.835 pp, respectively; both have `n_input = 108,752` and 65 local CCPP clusters. Module 06's regenerated table separately reports source-cohort coverage and conditional person linkage. The module-04 combined output manifest has 117 artifacts; module 06 has 12. The release audit checked all 255 registered artifacts with **zero technical errors**, but correctly reports **BLOCKED**: 94 proposed appendix candidates lack owner approval and destinations, and no artifact is a main-text candidate.

The common-denominator correction is versioned in data preparation and the 2017 individual analysis module, with an assertion that both endpoints have identical missingness. The full data-preparation pipeline was **not** rerun, so its current Dropbox Coded dataset still contains the former E01 coding; module 04 reconstructs E01 before estimation, and the next full data-preparation run will propagate the corrected variable to Coded. Do not hand-edit that dataset. The new wellbeing-completion and migration-specific sample estimates remain exploratory in-console checks until the team approves a protocol amendment and versioned output. Release remains blocked irrespective of the technical pass until the target-population decision and artifact-level owner review are recorded.
