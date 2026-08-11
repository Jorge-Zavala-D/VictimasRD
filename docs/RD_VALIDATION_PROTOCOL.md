# Selected-sample RD validation protocol

## Purpose and scope

This protocol governs `code/stata/pipeline/03b_validate_rd_assumptions.do`.
It evaluates whether the research-team-selected geography has the empirical
features required for an RD analysis. It does not search for or change the
geographic sample, select a preferred result, estimate substantive outcomes,
or resolve the project's open estimand and treatment-timing decisions.

The selected geography is the versioned `sample_main_rd` indicator: Apurimac,
Huancavelica, La Convencion province in Cusco, and Huancayo province in Junin.
The operational focus is the B--C boundary because the documented post-2012
rule jointly prioritizes categories A and B. A--B, C--D, and D--E remain
diagnostic boundaries in the exhaustive, opt-in design audit.

## Analysis population and score uncertainty

The routine module reports the B--C design under four transparent branches:

1. adjacent B and C categories, score as recorded;
2. adjacent categories after dropping category/score sign conflicts;
3. adjacent categories after dropping observations within 0.00005 of the
   six-decimal cutoff; and
4. full score support after applying the same conservative rounding-band rule.

The source category determines the administrative stratum, while the numeric
score determines distance from the cutoff. None of these branches is declared
the primary analysis until the research team approves the score-tie rule and
support rule. The conservative adjacent-category branch is used for compact
figures only so that the displays do not conceal the known rounding problem.

## Diagnostic families

The module produces the following reviewer-facing evidence.

- Running-variable support: observations, distinct mass points, district
  clusters, category/score sign conflicts, and cutoff-band counts by branch.
- Density continuity: local-polynomial `rddensity` tests for each score branch.
  Because the recorded score is rounded and repeated, these are sorting
  diagnostics rather than mechanical proof of manipulation or its absence.
- First-stage continuity: local-linear, triangular-kernel, robust
  bias-corrected estimates for cumulative treatment in every year from 2007
  through 2023, plus explicit support and tie-rule sensitivity.
- Predetermined covariate continuity: geography, 1993/2006 economic activity,
  and 2002/2006 municipal-election measures. Balance measures are standardized
  within the declared B--C sample for comparable reporting.
- Timing-sensitive continuity: 2007 Census measures are reported separately
  because Census timing may overlap the first program year.
- Linkage continuity: indicators for Census, geospatial, GDP, and election-data
  availability test whether data construction itself changes at the cutoff.
- Specification sensitivity: MSE- and coverage-error bandwidth selectors,
  triangular/uniform/Epanechnikov kernels, local-linear and local-quadratic
  fits, fixed bandwidths, donut exclusions, and placebo cutoffs located on one
  side of the true boundary.
- Inference sensitivity: nearest-neighbor, HC3, and district-clustered CR1,
  CR2, and CR3 variance estimators. No branch is silently promoted to the
  primary inference rule.
- Local randomization: `rdwinselect` uses a prespecified core of fully
  pre-treatment covariates and mass-point-respecting windows. Randomization
  inference is run only if the recommended window contains at least 20
  observations and at least 10 on each side; otherwise the module records that
  support is insufficient.
- Parametric diagnostic: side-specific local-linear regressions in fixed
  windows provide a transparent comparison, not a replacement for robust
  local-polynomial inference.

False-discovery-rate and Holm adjustments are reported within the core,
timing-sensitive, and linkage covariate families for each inference branch.
Individual covariate tests are not interpreted as independent design verdicts.
The same adjustments are also reported across the six placebo cutoffs within
each treatment horizon.

## Prespecified sensitivity values

Fixed bandwidths are 0.005, 0.010, 0.015, 0.020, 0.030, and 0.050 index units.
Donut radii are 0, 0.00005, 0.00025, 0.00050, and 0.00100. Placebo cutoffs are
-0.020, -0.015, -0.010, 0.010, 0.015, and 0.020 relative to B--C and are
estimated only on the corresponding side of the true cutoff. These values are
design diagnostics and must not be redefined after viewing outcome estimates.

## Items deliberately deferred

The following require an approved outcome module and therefore do not belong
in this pre-outcome validation program: outcome effect estimates; placebo
outcomes; outcome-specific bandwidth, donut, or covariate sensitivity;
fuzzy-RD/IV estimands; weak-first-stage-robust outcome inference; outcome power
and minimum detectable effects; multiplicity across substantive outcome
families; and migration or mediation analyses.

Before any causal result is labeled primary, the research team must still
approve the dated assignment regime, eligible untreated risk set, score-tie
rule, support rule, treatment horizon, estimand, and clustering/inference plan
listed in `docs/PROJECT_CONTEXT.md` and
`docs/RD_DESIGN_METHODS_AUDIT_2026-07-28.md`.

## Methodological anchors

The implementation follows the maintained RD Packages workflow: robust
bias-corrected local-polynomial inference and data-driven RD plots from
`rdrobust`; local-polynomial density testing from `rddensity`; and window
selection/randomization inference from `rdlocrand`. The discrete-running-
variable guidance in Cattaneo, Idrobo, and Titiunik's *Extensions* volume is
especially important: the number and spacing of mass points determine whether
continuity-based approximations are credible, and local randomization is an
alternative only when a defensible window has adequate support.

NotebookLM may be used to discover and synthesize relevant project sources,
but every manuscript citation and claim must be checked against the underlying
paper or official document before use.
