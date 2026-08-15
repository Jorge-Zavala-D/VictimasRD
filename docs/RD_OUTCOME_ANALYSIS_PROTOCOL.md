# RD outcome-analysis protocol

## Status and scope

This protocol records the research-team decisions governing the first
canonical outcome module. It applies to the 2013 SISFOH centro-poblado (CCPP)
analysis and supplies defaults that later person-, household-, and 2017-level
modules must either inherit explicitly or supersede in a documented decision.
It does not change the geography selected in data preparation.

## Assignment rule and analysis sample

- The running variable is `running_bc`, the official RUV victimization score
  centered at the government B--C boundary.
- The authoritative support for the main analysis is the adjacent B/C branch:
  `sample_main_rd == 1` and the recorded RUV category is B or C. Full score
  support remains a diagnostic branch and is not a competing main result.
- Category membership defines eligibility for the adjacent-support branch;
  the recorded numerical score defines distance from the cutoff. The pipeline
  must fail if a B/C category conflicts with the sign of `running_bc`.
- SISFOH outcomes use communities deterministically linked to the 2012--2013
  SISFOH operation. Linkage continuity is reported by the validation module;
  unmatched RUV communities remain in the national data spine but cannot
  contribute a SISFOH outcome.
- The assignment indicator is one at or above the B--C cutoff. Treatment is
  cumulative collective-reparation receipt through 2012 (`treat_12`). The
  research team treats all SISFOH variables as 2013 outcomes.

## Estimands and reporting hierarchy

Every registered outcome reports three linked quantities:

1. the discontinuity in `treat_12` on the outcome analysis sample (first
   stage);
2. the discontinuity in the outcome by assignment (reduced form or assignment
   ITT); and
3. the fuzzy-RD ratio estimand for treatment receipt (local average treatment
   effect for compliers), conditional on a substantively and statistically
   adequate first stage.

The fuzzy estimand is the target effect, but it is not interpreted in
isolation. The first stage, reduced form, and weak-instrument diagnostics must
appear beside it. The code never searches bandwidths, samples, outcomes, or
specifications to maximize the first-stage coefficient or its significance.
When the conservative weak-first-stage gate is not met, the code still
preserves estimates for diagnosis but labels the LATE branch as
interpretation-gated; the reduced form and Anderson--Rubin inference remain
reportable.

## Common design bandwidth

The main 2013 family uses a common design bandwidth of 0.0075 index units and
a common bias bandwidth of 0.0135. These rounded values come from the
`treat_12` local-linear triangular-kernel MSE selector in the prespecified
selected-geography B/C design universe, before inspecting substantive outcome
estimates. They are called a **common design bandwidth**, not an optimal
bandwidth for every outcome.

This distinction is essential. Continuity-based MSE and coverage-error
selectors depend on the conditional curvature and variance of the dependent
variable. A fuzzy selector additionally uses the joint behavior of the
outcome and treatment discontinuities. Consequently, valid outcome-specific
selectors can return different bandwidths even with the same cutoff and
running variable. Support restrictions, polynomial order, covariate
adjustment, kernel, mass points, and variance estimator can also change pilot
quantities and admissible bandwidths. A fixed window improves cross-outcome
comparability but is not simultaneously MSE-optimal for heterogeneous
outcomes.

The fixed main window is defensible here because it is chosen from the design
stage using treatment assignment rather than from favorable outcome results.
It gives every complete primary outcome the same nominal window and effective
community sample. Missing outcome data can still change an outcome's usable
sample and outcome-specific first stage; the output records both. Required
sensitivity branches include outcome-specific MSE and coverage-error
bandwidths, fixed windows of 0.005 and 0.010, and the same common window with a
parsimonious predetermined covariate set.

## Estimation and inference

- The continuity-based primary estimator is bias-corrected local linear
  regression (`p(1) q(2)`) with a triangular kernel, mass-point adjustment,
  the common design and bias bandwidths, and district-clustered CR2 inference.
- District clustering is primary at the CCPP level because there is one
  observation per assignment unit and implementation and shocks may be shared
  within municipalities. Clustering by CCPP would be identical to
  heteroskedasticity-robust inference in this one-row-per-CCPP file. Nearest-
  neighbor, HC3, and district CR1/CR3 results are inference sensitivities.
- Later person- and household-level modules must cluster at CCPP in their main
  specifications and report district clustering as a sensitivity because
  treatment is assigned at CCPP.
- A transparent local-linear triangular-weighted 2SLS model estimates the
  parametric analogue within the same window. It includes separate running-
  variable slopes on each side, instruments `treat_12` with cutoff assignment,
  and clusters by district. It reports the Kleibergen--Paap F statistic,
  underidentification test, Anderson--Rubin p-value, and wild-cluster-bootstrap
  p-value.
- A conservative first-stage gate is Kleibergen--Paap F at least 20. This is a
  reporting and interpretation safeguard, not a device for selecting a
  bandwidth. Stock--Yogo critical values are not treated as exact under
  clustering.

## Covariates and multiplicity

The unadjusted fixed-window estimator is primary. Covariate adjustment is a
precision sensitivity using the same predetermined set for every outcome:
2017 geospatial altitude (a fixed physical attribute), log 2007 population,
and the transparent 2007 core wellbeing proxy. No covariate is selected by its
association with an outcome or by whether it improves significance.

The versioned outcome registry defines primary families, secondary outcomes,
transformations, denominators, scale, source, and paper role. Holm adjusted
p-values control family-wise error across the compact primary family;
Benjamini--Hochberg q-values are also reported. Secondary outcomes use
Benjamini--Hochberg adjustment within their declared family and are not used
to redefine the primary narrative.

## Interpretation boundaries

- SISFOH counts are enumerated roster counts, not INEI-adjusted population
  totals.
- The wellbeing measure is an equal-domain proxy, not an official poverty
  index.
- Internet access, employment, program participation, project attributes, and
  other post-treatment variables may be outcomes or explicitly labeled
  mechanisms. They cannot be inserted as ordinary controls.
- CCPP GDP is a Seminario--Palomino nightlights-based estimate and is reported
  as an exploratory economic outcome, separately from SISFOH measures.
- All generated artifacts remain `generated_unreviewed` until substantive,
  disclosure, and manuscript review. This module does not synchronize files to
  Overleaf.

## Reproducible implementation

The orchestrator is `code/stata/pipeline/04_estimate_main_effects.do`; the
first outcome module is `code/stata/pipeline/04a_sisfoh2013_ccpp.do`. The
registry is `metadata/rd-outcomes/outcome-registry.csv`. Machine-readable
results, LaTeX tables, and figures are written under
`output/tables/rd_outcomes` and `output/figures/rd_outcomes`, with checksums and
review status recorded in `metadata/rd-outcome-output-manifest.csv`.

