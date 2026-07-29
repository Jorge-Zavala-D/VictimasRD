# RD design audit protocol

## Purpose

`code/stata/pipeline/03_validate_rd_design.do` audits whether the official
victimization-index thresholds generated meaningful discontinuities in the
probability of receiving collective reparations. It is a design-diagnostic
module, not an automatic sample-selection algorithm.

The module reports every estimate in its declared grids. It never ranks
geographies by the largest coefficient or smallest p-value, never deletes
unsuccessful specifications, and never writes `sample_main_rd`. A final
analysis geography requires a versioned research-team decision that states the
institutional rationale, geographic rule, cutoff strategy, score-tie rule, and
treatment horizon.

## Bounded higher-order subset search

The RUV contains 15 departments and 95 normalized department-province cells.
The raw province text contains one trailing-space variant that previously
created a spurious ninety-sixth cell. All nonempty department
subsets already imply 32,767 geographies; all normalized province-cell subsets
imply approximately 4.0 x 10^28. Searching those unrestricted sets and
retaining the largest first stage would make the sample a function of sampling
noise.
Conventional standard errors and p-values would not account for the search,
and the selected geography would lack an independent institutional
definition. Computing power does not solve that identification problem.

The expanded audit nevertheless includes groups of three, four, five, and
larger geographic cells. It bounds them before looking at the new results
using two independently defined universes:

- every nonempty subset of the seven-department union of the official VRAEM
  envelope and the CVR high-burden departments (127 subsets, sizes one through
  seven); and
- every nonempty subset of the ten complete provinces in INEI's official VRAEM
  study envelope (1,023 subsets, sizes one through ten).

Every subset is reported. None is automatically eligible merely because it
has a large coefficient or small p-value. The subset atlases diagnose where
the administrative priority rule operated; they do not manufacture a
geographic rationale after seeing results. Substantive review is limited to
the named candidates fixed in `metadata/rd-design-candidate-registry.csv`
before this expanded run.

For comparison with earlier work, the audit also retains the broader,
fully reported heterogeneity atlas:

- the complete national RUV universe;
- the exact legacy restricted geography as a historical benchmark;
- each department separately;
- each leave-one-department-out sample;
- every two-department combination across the 15 observed departments; and
- each department-province cell separately.

The national baseline, exact legacy benchmark, and externally bounded VRAEM
and CVR candidates in the registry are eligible for research-team review.
Eligibility means only that the candidate may be discussed; it does not
authorize automatic selection. Geographic-atlas estimates remain diagnostic.

## Cutoffs and treatment horizons

The audit estimates first-stage discontinuities separately at all four
official thresholds:

| Cutoff | Higher-victimization category | Lower-victimization category |
|---|---|---|
| A--B | A | B |
| B--C | B | C |
| C--D | C | D |
| D--E | D | E |

The principal sample-selection treatment horizons are:

- `treat_12` for SISFOH 2013 outcomes;
- `treat_16` for 2017 Census outcomes.

These are conservative end-of-prior-year exposure indicators. The exact
measurement date of each outcome source must still be confirmed. `treat_23`
is retained as a rollout-catch-up diagnostic and for interpreting the planned
2025 Census migration extension, but it does not select the geography because
no searched cutoff or defensible subset has a usable 2023 first stage. The
audit also estimates the complete `treat_07`--`treat_23` trajectory so the two
principal horizons cannot conceal a nonmonotonic or isolated result.

One common geography should normally be used across outcome families.
Different treatment horizons identify different time-specific first stages
and potentially different complier populations; they do not justify choosing
different geographic samples solely because one sample is stronger in a
particular year. The disappearance of the receipt discontinuity by 2023 is
interpreted as program catch-up and does not justify a new 2025 geography.

The audit also distinguishes two possible longitudinal estimands that the team
must resolve. A contemporaneous-receipt strategy uses `treat_12`, `treat_16`,
and `treat_23` for the three outcome waves, but changes the treatment and
complier population over time. An early-versus-delayed-receipt strategy fixes
an early treatment definition, such as `treat_12`, across outcome waves and
interprets later estimates as longer-run effects of early priority. The
complete annual first-stage paths are reported to reveal rollout catch-up.

## Rounded score and authoritative category

The RUV score is stored to four decimals while the official cutoffs have six
decimals. The RUV category is authoritative for administrative classification,
but `rdrobust` assigns left and right observations from the numerical running
variable. The national adjacent-category samples contain the following
score-category conflicts:

| Cutoff | Adjacent-category observations | Numerical-sign conflicts | Within 0.00005 of cutoff |
|---|---:|---:|---:|
| A--B | 2,553 | 0 | 10 |
| B--C | 2,579 | 1 | 6 |
| C--D | 2,437 | 4 | 3 |
| D--E | 1,849 | 68 | 68 |

No recoding can recover the unavailable six-decimal historical score. The
named-candidate audit therefore reports:

1. the score exactly as recorded;
2. exclusion of observations whose numerical side conflicts with the
   authoritative category; and
3. exclusion of the half-rounding-unit band, `abs(running) <= 0.00005`.

These are sensitivity analyses, not interchangeable primary specifications.
The research team must predeclare one rule before treatment-effect estimation.
The geographic atlas uses the conservative half-rounding-band exclusion to
avoid treating an unresolved side conflict as geographic heterogeneity.

## Estimation grid

The first-stage outcome is binary treatment receipt by the relevant year.
Each estimate uses the two categories adjacent to the cutoff, a triangular
kernel, mass-point adjustment, and district-clustered inference. Named
candidates are estimated with:

- local linear, MSE-optimal bandwidth (`p1_mserd`);
- local linear, coverage-error-rate bandwidth (`p1_cerrd`); and
- local quadratic, MSE-optimal bandwidth (`p2_mserd`) as sensitivity only.

Robust bias-corrected p-values and confidence intervals are reported together
with conventional point estimates, bandwidths, effective observations,
unique score values, and district clusters on both sides. A specification is
not attempted when cumulative treatment does not vary on both sides or when
either side has fewer than 20 observations, five distinct score values, or ten
district clusters. Treated and untreated counts overall and by side are
retained alongside the score and cluster support diagnostics so every skipped
cell is auditable. This is an estimability gate, not evidence against a
candidate: deterministic treatment on one side remains visible in the output
even when `rdrobust` cannot supply the declared clustered inference.

For candidate comparison, the audit reports the squared robust first-stage
test statistic, `(tau_bc / se_rb)^2`, as a transparent Wald-strength
diagnostic. Following current practical RD guidance, 20 is shown as a
conservative heuristic for a strong fuzzy-RD first stage. This diagnostic is
not an exact homoskedastic first-stage F statistic, does not correct for the
geographic search, and is never used alone to choose a sample. The comparison
also requires positive direction, stability across the 2012 and 2016 horizons
and reasonable specifications, adequate effective observations and clusters,
meaningful geographic breadth, and an independently defensible geographic
rule. A single department or a few provinces cannot become the main sample
merely because they maximize the first-stage statistic.

An incomplete estimate, missing robust standard error, or missing Wald
diagnostic can never satisfy a strength rule. The code asserts this explicitly
because Stata otherwise treats numeric missing values as larger than ordinary
numbers in comparisons.

The audit does not use `rdmulti` mechanically. This application has one score,
four ordered priority thresholds, and a common binary treatment whose receipt
can change over time. It is not automatically equivalent to a setting where
different subgroups face different cutoffs or where treatment dosage changes
deterministically at each cutoff. Cutoff-specific local experiments are
therefore reported first. Any pooled multiple-cutoff estimand requires a
separate written identification argument.

## Outputs and decision gate

Aggregate results are written under `output/tables/rd_design` and
`output/figures/rd_design`. These include complete raw grids, horizon
scorecards, candidate-by-horizon matrices, covariate-continuity tests, and
subset-size diagnostics. The complete Stata result datasets are retained in
Dropbox Working QA. No row-level community data enter Git.

Before creating `sample_main_rd`, the research team must approve:

1. one institutionally justified geographic rule;
2. one primary cutoff or an explicitly defined multiple-cutoff estimand;
3. the rounded-score/tie rule;
4. the three treatment-horizon definitions after confirming outcome dates;
5. the intended ITT and fuzzy-RD estimands;
6. weak-first-stage and finite-cluster inference procedures; and
7. the full validity-test and robustness plan.

If no defensible geography has an adequate first stage at the relevant
horizons, the correct conclusion is that the current data do not support the
proposed fuzzy-RD treatment-received design. The audit must not manufacture a
design by progressively optimizing subgroups.
