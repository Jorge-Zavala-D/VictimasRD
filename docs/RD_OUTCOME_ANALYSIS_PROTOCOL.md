# RD outcome-analysis protocol

## Status and scope

This protocol records the research-team decisions governing the canonical
2013 SISFOH and 2017 Census CCPP, household, and individual outcome modules.
It does not change the geography selected in data preparation and does not
cover the separate causal-mediation or heterogeneity workflows.

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
- Census outcomes use cumulative collective-reparation receipt through 2016
  (`treat_16`). The research team treats all Census variables as materialized
  in 2017. This rule is fixed across CCPP, household, and person modules.
- The INEI-assisted Census file follows a defined SISFOH source cohort rather
  than exposing nationally identified CCPP microdata. The 2017 modules report
  discontinuities in CCPP coverage, household outcome availability, and person
  linkage. Non-linkage is never silently recoded as observed migration.

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

The main 2013 and 2017 families use a common design bandwidth of 0.0075 index
units and a common bias bandwidth of 0.0135. These rounded values are validated
against the local-linear triangular-kernel treatment selectors for `treat_12`
and `treat_16` in the prespecified selected-geography B/C design universe,
before inspecting substantive outcome estimates. They are called a **common
design bandwidth**, not an optimal bandwidth for every outcome.

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

## Household estimand and weighting

Treatment and the running score are defined at the RUV community, while the
SISFOH household file has many observations per community. The primary
household estimand therefore gives every eligible RUV community total weight
one and weights households equally within community. This preserves the
assignment-level target and avoids allowing post-treatment household counts or
unequal SISFOH enumeration intensity to determine a community's contribution.
Weights are recomputed for each outcome after applying its denominator and
missing-data rule.

An unweighted household-equal branch is required and explicitly labeled as a
different population-weighted estimand. It is a sensitivity to household
composition and enumeration, not a specification from which the preferred
estimate may be selected. The complete eight-outcome primary sample contains
39,074 households in 487 RUV communities; the common window contains 3,810
households in 65 communities.

The 2017 primary household family contains 24,877 source households in 406
RUV communities; the common window contains 2,706 households in 61
communities. Its eight outcomes cover demographic composition, migration,
education, employment, insurance, disability, and core wellbeing. The same
CCPP-equal primary weighting and household-equal sensitivity apply.

## Individual estimand and weighting

The compact primary individual family describes linked SISFOH persons age 14
or older with complete age, education, labor-status, insurance, and program
responses. It contains 98,005 people in 487 RUV communities; the common window
contains 8,870 people in 65 communities. This common adolescent/adult universe
keeps the eight main outcomes directly comparable while retaining the legacy
paper's substantive focus on demographic composition, human capital, labor,
health coverage, and social protection.

The primary individual estimand gives every eligible RUV community total
weight one and weights eligible people equally within community. This targets
the average assignment-community mean among linked SISFOH people age 14 or
older and prevents community size or enumeration intensity from determining
its contribution. A person-equal branch is required and explicitly labeled as
a different population-weighted estimand.

The 2017 primary person family contains 54,317 linked people age 14 or older
in 406 RUV communities; the common window contains 5,453 people in 61
communities. It adds CCPP migration, disability, and harmonized wellbeing to
the compact main family. The primary migration variable is observed only for
linked people. Complementary exploratory bounds code every unlinked
source-cohort person as moved or as not moved; neither bound replaces the
linked-cohort primary estimate.

Secondary outcomes use the denominator appropriate to the source question:
valid-age rosters for age composition, females age 12--49 for pregnancy,
children age 7--12 with valid attainment for the schooling-deprivation proxy,
people age 14 or older for education and labor status, labor-force members for
unemployment, people age 65 or older for Pension 65, and children age 0--3 for
Cuna Mas. CCPP-equal weights are recomputed after applying each outcome's
eligibility and missing-data rule. The SISFOH source does not observe current
school enrollment, so the child measure is labeled an attainment-based proxy
and cannot be described as observed non-enrollment.

## Estimation and inference

- The continuity-based primary estimator is bias-corrected local linear
  regression (`p(1) q(2)`) with a triangular kernel, mass-point adjustment,
  the common design and bias bandwidths, and district-clustered CR2 inference.
- District clustering is primary at the CCPP level because there is one
  observation per assignment unit and implementation and shocks may be shared
  within municipalities. Clustering by CCPP would be identical to
  heteroskedasticity-robust inference in this one-row-per-CCPP file. Nearest-
  neighbor, HC3, and district CR1/CR3 results are inference sensitivities.
- Household-level models cluster by complete `ruv_id` in their primary CR2
  specifications because treatment is assigned at CCPP and three selected B/C
  communities lack a current ten-digit `ubigeo_ccpp`. District and exact-score
  mass-point clustering are required sensitivities. Person-level models
  inherit the same CCPP-equal primary weighting and `ruv_id` CR2 rule, with
  person-equal, district, and score-mass-point sensitivities.
- A transparent local-linear triangular-weighted 2SLS model estimates the
  parametric analogue within the same window. It includes separate running-
  variable slopes on each side, instruments the wave-specific treatment
  (`treat_12` or `treat_16`) with cutoff assignment,
  and clusters by district in the CCPP module and by RUV community in the
  household and individual modules. It reports the Kleibergen--Paap F
  statistic, underidentification test, Anderson--Rubin p-value, and
  wild-cluster-bootstrap p-value.
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
- Internet and connectivity remain mechanism outcomes. No mediation model is
  estimated here, and no primary effect is conditioned on a post-treatment
  mechanism.
- Subgroup splits and treatment-by-subgroup interaction estimands belong in a
  separate heterogeneity protocol. They are not selected or estimated in the
  main-effect modules.

## Reproducible implementation

The orchestrator is `code/stata/pipeline/04_estimate_main_effects.do`. The
implemented modules are `code/stata/pipeline/04a_sisfoh2013_ccpp.do`,
`code/stata/pipeline/04b_sisfoh2013_household.do`, and
`code/stata/pipeline/04c_sisfoh2013_individual.do`, followed by
`code/stata/pipeline/04d_census2017_ccpp.do`,
`code/stata/pipeline/04e_census2017_household.do`, and
`code/stata/pipeline/04f_census2017_individual.do`; their registries are
`metadata/rd-outcomes/outcome-registry.csv`,
`metadata/rd-outcomes/outcome-registry-2013-household.csv`, and
`metadata/rd-outcomes/outcome-registry-2013-individual.csv` and the three
`metadata/rd-outcomes/outcome-registry-2017-*.csv` files.
Machine-readable results, LaTeX tables, and figures are written under
`output/tables/rd_outcomes` and `output/figures/rd_outcomes`, with checksums and
review status recorded in `metadata/rd-outcome-output-manifest.csv`.
