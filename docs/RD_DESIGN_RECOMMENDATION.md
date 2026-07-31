# RD design recommendation

## Status

**The research team selected the exact legacy geography as the main RD
geographic sample on 29 July 2026. The canonical `sample_main_rd` flag contains
1,162 RUV communities.**

This supersedes the earlier no-approval recommendation for geography. The
decision retains continuity with the historical paper design and fixes the
sample independently of any future outcome results. It does not erase the
documentary and empirical limitations identified by the audit, and it does not
automatically approve a treatment horizon, rounded-score rule, administrative
risk set, clustering choice, or treatment-received estimand.

The current implementation is:

1. retain all 5,712 RUV communities for national descriptive work;
2. use `sample_main_rd == 1` for the exact legacy geography in primary RD
   analyses and selected-sample descriptions;
3. retain the full national universe, the Apurímac--Huancavelica core, and
   other predeclared candidates as sensitivity or implementation benchmarks;
4. reconstruct the dated post-2012 assignment regime and risk set before
   interpreting cumulative receipt as one stable fuzzy-RD treatment; and
5. predeclare the B--C cutoff, treatment horizon, tie handling, and estimand
   before outcome analysis.

This decision is methodological, not a judgment that the program ignored
victimization. The descriptive data show very strong ordinal targeting in
levels. The unresolved question is whether a dated local threshold experiment
can be recovered from the available variables.

## Why the institutional record changes the design

The project originally treated the five RUV categories as if they generated a
deterministic sequence: all A communities, then B, C, D, and E. The reviewed
official and oversight documents do not support that stable five-stage model.

- The 2007 cohort was selected from the preliminary *Censo por la Paz*.
- The 2008 cohort used RUV Libro Segundo only in part.
- In 2012, RUV registration, A/B affectation, and executing-body
  accountability were described as three new criteria.
- The post-2012 rule placed A and B in one joint priority pool. B--C is the
  documented boundary between that pool and the remaining categories; A--B is
  inside the pool, and no reviewed operational document establishes separate
  C-before-D or D-before-E stages.
- The 2012 program also honored 150 inherited technical files of diverse
  affectation and operated a separate VRAEM priority.
- An annual list did not itself produce receipt. Community assemblies,
  municipal technical files, viability, accountability, budget, cofinancing,
  transfer, execution, and delivery created heterogeneous lags.
- Budgets and financing routes changed materially, including the exceptional
  2019 expansion and the later absence of a national PRC financing
  appropriation.

Accordingly, lower-category receipt can reflect lawful concurrent priorities,
inherited commitments, administrative readiness, or a different policy
regime. Some deviations were genuine--including the serious 2011
prioritization irregularities documented by Defensoría--but not every
lower-tier project should be labeled infiltration or political manipulation.
The full evidence chain is in
[`PRC_ROLLOUT_AND_RD_REASSESSMENT.md`](PRC_ROLLOUT_AND_RD_REASSESSMENT.md).

## What the full-universe rollout shows

Among all 5,712 RUV communities, cumulative linked receipt by 2023 is:

| RUV category | Communities | 2007 (%) | 2012 (%) | 2016 (%) | 2023 (%) |
|---|---:|---:|---:|---:|---:|
| A | 1,284 | 11.9 | 54.8 | 78.4 | 91.3 |
| B | 1,269 | 5.1 | 39.0 | 48.6 | 86.0 |
| C | 1,310 | 2.8 | 26.8 | 27.6 | 84.0 |
| D | 1,127 | 0.4 | 12.9 | 13.7 | 63.5 |
| E | 722 | 0.0 | 2.6 | 2.9 | 19.5 |

This is strong evidence that victimization rank mattered. It is not equivalent
to a discontinuity at a particular numerical boundary. Category-wide
differences can be large while local treatment probabilities remain smooth or
while a threshold operates only within a dated administrative risk set.

The annual cohort composition also changes sharply. Early cohorts are
dominated by A and B; later cohorts increasingly contain C, D, and E as the
program catches up and financing regimes change. The canonical figure and
underlying aggregate table are:

- `output/figures/descriptive/fig_desc_20_treatment_by_category_over_time.png`;
- `output/tables/descriptive/rd_rollout_category_year.csv`; and
- `output/tables/descriptive/tab_desc_09_treatment_by_category_over_time.tex`.

CMAN year is the first recorded project year in the linked roster, not yet a
verified completion or delivery date.

## What was searched

`code/stata/pipeline/03_validate_rd_design.do` reports a complete
96,524-cell first-stage audit:

| Search component | Geographic records | Cutoffs | Treatment years |
|---|---:|---:|---:|
| Named national, historical, VRAEM, and CVR candidates | 11 | 4 | 2007--2023, plus specification sensitivities |
| Broad department/province atlas | 230 | 4 | 2007--2023 |
| Seven-department conflict/VRAEM power set | 127 | 4 | 2007--2023 |
| Ten-province VRAEM power set | 1,023 | 4 | 2007--2023 |

The two power sets exhaust every nonempty combination, including groups of
three through ten components, inside independently defined geographic
universes. The unrestricted national province power set is not searched:
choosing from approximately \(4.0\times10^{28}\) combinations would make the
sample a function of noise and invalidate conventional inference.

Every failed or support-limited cell remains in the Dropbox Working QA
dataset. Git contains only aggregate, appropriately sized diagnostic outputs.
No subset is selected automatically and ordinary p-values are not treated as
search-adjusted evidence.

## Empirical first-stage diagnosis

The national RUV universe has no convincing local treatment-receipt first
stage at any policy boundary in the outcome-linked years. At B--C, the
local-linear discontinuities are approximately 0.057 through 2012, 0.152
through 2016, and 0.009 through 2023, with robust strength diagnostics of
0.32, 2.67, and 0.07.

The localized historical B--C pattern is real but not sufficient to approve a
design:

| Benchmark | RUV N | 2012 estimate (W) | 2016 estimate (W) | 2023 estimate (W) |
|---|---:|---:|---:|---:|
| Exact legacy geography | 1,162 | 0.652 (12.43) | 0.840 (22.88) | 0.035 (0.13) |
| Apurímac--Huancavelica core | 907 | 0.900 (44.49) | 0.891 (44.04) | 0.124 (1.39) |

Across all 96,524 cells, 81,499 estimates succeed, 13,510 are skipped by the
predeclared support gate, and 1,515 attempted numerical failures remain
visible. Applying the common comparison floor--at least 500 total communities,
50 effective local observations, and 20 district clusters on each side--only
79 cells have a positive estimate and robust Wald diagnostic of at least 20.
Every one is B--C. They occur only from 2012 through 2018; none occurs in 2010
or 2023, and none occurs at A--B, C--D, or D--E in any year.

Only one searched geography meets that strength/support rule in both 2012 and
2016: the post-search combination of Apurímac, Huancavelica, and San Martín.
It has 1,464 communities, estimates of 0.783 and 0.956, Wald diagnostics of
30.62 and 67.27, and effective samples of 73 and 63. It cannot be promoted:
it was discovered after the search, is geographically heterogeneous, and its
B--C altitude discontinuity is approximately -1,531 meters
(`p = 0.0047`; bias-corrected estimate approximately -1,817 meters).

The early-treatment alternative does not recover a stronger design. Among
supported positive 2010 cells, the largest robust Wald diagnostic is 10.66.
At the other end of the rollout, no 2023 cell reaches 20; the maximum is 8.80
in a searched C--D department pair, a boundary without a documented
post-2012 assignment rule.

The complete VRAEM province power set does not produce a supported strong
positive cell in 2010, 2012, 2016, or 2023 at any cutoff. Its few supported
strong cells occur at B--C in 2017--2018 after searching the power set; several
local-polynomial estimates exceed one. These are timing and finite-sample
instability diagnostics, not a new sample-selection basis.

The expanded all-cutoff atlas must be interpreted against the policy record:
an empirically favorable A--B, C--D, or D--E cell is not a policy-valid design
unless an independent document establishes that boundary as the assignment
rule for the same dated risk set.

### Support and bandwidth sensitivity

The adjacent-category first stages are also sensitive to how the running
variable is loaded. Among 729 named candidate-cutoff-year pairs with successful
adjacent and full-support estimates, 279 (38.3%) differ by at least 0.10; at
B--C, 52 of 187 (27.8%) do.

For the exact legacy geography, moving from adjacent B/C observations to the
full score support changes the conventional B--C estimate from 0.652 to 0.200
in 2012 and from 0.840 to 0.291 in 2016. The MSE-selected bandwidth expands
from 0.0074 to 0.0335 in 2012 and from 0.0066 to 0.0346 in 2016. These wider
windows remain just inside the neighboring threshold for the legacy sample,
so the attenuation is not explained by mechanically crossing another cutoff.
It shows that the favorable legacy first stage is highly local and
bandwidth-sensitive.

Full-support windows are especially problematic at the lower thresholds:
99.5% of C--D and 90.4% of D--E named cells cross a neighboring policy
boundary. The only full-support cell meeting the strength/support heuristic is
the core B--C estimate in 2017, and its selected left bandwidth marginally
crosses C--D. The adjacent-category result therefore cannot be treated as
design-invariant.

## Why the legacy geography was selected and what remains unresolved

The exact legacy rule is:

> every RUV community in Apurímac or Huancavelica, plus every RUV community in
> La Convención province in Cusco or Huancayo province in Junín.

The team selected it because it predates the expanded search, matches the
existing paper's executable empirical history better than a newly optimized
subset, retains 1,162 communities, and shows a large early/mid B--C
discontinuity. The canonical rule is encoded from the RUV district UBIGEO,
rather than repeated string conditions.

The selection does not resolve four deeper problems:

1. the executable rule and the manuscript's geographic narrative are not
   identical;
2. the observed RUV workbook was acquired in 2018 and may not contain the
   score, category, or registration status visible when early decisions were
   made;
3. cumulative receipt pools pre-2012 projects, inherited commitments, the
   post-2012 A/B rule, geographic priorities, and later financing regimes; and
4. the 2012 first stage is below the conservative strength value of 20 and
   local effective support is modest.

The smaller core has a stronger first stage but remains a sensitivity sample
because it has less local support and a baseline altitude discontinuity. The
Apurímac--Huancavelica--San Martín frontier remains post-search,
geographically heterogeneous, and severely imbalanced in altitude. It is not
an alternative main sample.

## Treatment timing

Treatment year must follow the estimand and outcome date; it cannot be chosen
because it maximizes the first stage.

- For a 2013 outcome, `treat_12` represents any recorded project by the end of
  2012 only if every included event precedes outcome measurement.
- `treat_10` defines early receipt by 2010. Communities first treated in
  2011--2012 should ordinarily remain not treated by 2010; dropping them based
  on realized future treatment conditions on a post-assignment variable and
  changes the target population.
- One fixed early-receipt definition should be used across later outcomes if
  the intended estimand is early versus delayed receipt.
- `treat_23` is a rollout-catch-up diagnostic. It should not select the
  geography or be used to divide a 2025 outcome jump by a near-zero first
  stage.

The preferred hierarchy, if the assignment regime can be reconstructed, is:

1. B--C priority-assignment ITT; and
2. secondary early-versus-delayed receipt fuzzy RD with weak-first-stage-
   robust inference.

## Running-variable support and multiple cutoffs

Full score support is valid in an ordinary single-cutoff RD when the selected
bandwidth remains local. The adjacent-category restriction used in the atlas
is a conservative cap that prevents a bandwidth from crossing another policy
threshold. The audit reports full-support sensitivity for every named
candidate, cutoff, and year. The eventual specification must inspect both the
estimate and whether its selected bandwidth reaches a neighboring threshold.

The four cutoffs should not be mechanically pooled with a multiple-cutoff
command. This application has one score, changing cumulative receipt, and only
one clearly documented post-2012 boundary. A pooled estimand would require an
argument that all component cutoffs represented comparable assignment rules
and local experiments. That argument is not currently available.

## Required reconstruction

Before approving an RD, obtain or reconstruct:

1. dated RUV snapshots with registration, accreditation, score, category, and
   category-change history;
2. annual CMAN priority lists and resolutions;
3. separate dates for prioritization, assembly, technical-file submission,
   viability, approval, transfer, initiation, completion, and delivery;
4. inherited-file and other pre-rule commitment flags;
5. annual VRAEM, Huallaga, and other territorial-priority definitions;
6. executing-body accountability, cofinancing, and project-readiness data;
7. annual PRC budgets, transfers, and financing routes; and
8. exact SISFOH 2013, Census 2017, and Census 2025 reference dates.

The resulting risk set should contain communities subject to the same dated
rule, scored before the decision, untreated and administratively eligible at
the start of the decision period, and observed before the relevant outcome.

## Geographic decision and remaining analysis gate

The geographic decision is complete. Before interpreting a treatment-received
RD as causal, the research team should still verify that the reconstruction
identifies:

- a dated, stable assignment rule and pre-decision running variable;
- a common geographic and administrative risk set;
- a clearly ordered treatment event;
- a strong, stable, policy-direction local first stage;
- adequate effective observations and clusters;
- credible density, continuity, linkage, and finite-sample diagnostics; and
- an estimand aligned with the outcome date.

If those conditions fail, the correct conclusion is not to search more
geographies. It is that the current data support a rich national rollout and
implementation analysis but not the proposed fuzzy treatment-received RD.
