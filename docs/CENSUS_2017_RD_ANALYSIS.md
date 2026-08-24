# Census 2017 RD outcome analysis

## Scope

The Census 2017 outcome workflow estimates main effects at the CCPP,
household, and individual levels. It uses cumulative collective-reparation
receipt through 2016 (`treat_16`) and treats Census measures as 2017 outcomes.
The workflow does not estimate causal mediation or treatment-effect
heterogeneity; both require separate, versioned analysis contracts.

## Canonical implementation

- `code/stata/pipeline/04d_census2017_ccpp.do`
- `code/stata/pipeline/04e_census2017_household.do`
- `code/stata/pipeline/04f_census2017_individual.do`
- `metadata/rd-outcomes/outcome-registry-2017-ccpp.csv`
- `metadata/rd-outcomes/outcome-registry-2017-household.csv`
- `metadata/rd-outcomes/outcome-registry-2017-individual.csv`

The modules are called after the three SISFOH 2013 modules by
`code/stata/pipeline/04_estimate_main_effects.do`. Inputs remain in the
configured Dropbox Coded directory. Reproducible, non-sensitive tables,
figures, model-result CSVs, and manifests are written in Git.

## Locked design

- Selected legacy geography and adjacent B/C support.
- Running variable `running_bc`, centered at the official B--C cutoff.
- Common design bandwidth `h = 0.0075` and bias bandwidth `b = 0.0135`.
- Local-linear, triangular-kernel, robust bias-corrected RD with mass-point
  adjustment.
- Reduced forms and fuzzy-RD LATEs are reported together. A transparent
  local-linear `ivreg2` analogue supplies Kleibergen--Paap,
  underidentification, Anderson--Rubin, and wild-cluster diagnostics.
- CCPP models use district CR2 inference. Household and person models give
  each eligible RUV community total weight one and use CCPP CR2 inference;
  observation-equal, district, and score-mass-point branches are labeled
  sensitivities.
- Fixed smaller/larger windows, treatment- and outcome-based MSE/CER
  selectors, kernels, local quadratic fits, donut exclusions, clustering,
  weighting, and predetermined-covariate branches are prespecified
  sensitivities rather than outcome-driven model choices.

## Outcome and linkage governance

The registries declare transformations, display scales, denominators,
families, multiplicity families, and paper roles before estimation. The
compact primary family contains eight outcomes at each level. Holm adjustment
is applied to each primary family; Benjamini--Hochberg adjustment is applied
within declared secondary families.

The INEI-assisted Census extract follows a SISFOH source cohort, so coverage
and linkage are not assumed ignorable. Separate tables report CCPP coverage,
household outcome availability, and person linkage discontinuities. Migration
remains a primary observed outcome among linked records. Two exploratory
extreme-case sensitivities code every unlinked source-cohort person as moved
or as not moved; these do not constitute a causal correction for selection.
Internet and connectivity are labeled mechanisms and are never inserted as
ordinary post-treatment controls.

## Validation snapshot: 21 August 2026

All three modules completed through the Stata MCP from the final code. No
estimator row returned a nonzero Stata code.

| Level | Registered outcomes | Complete primary sample | RUV CCPPs | Common-window observations | Robust first-stage F | KP F |
|---|---:|---:|---:|---:|---:|---:|
| CCPP | 39 | 388 CCPPs | 388 | 59 CCPPs | 54.13 | 54.37 |
| Household | 36 | 24,877 households | 406 | 2,706 households | 20.07 | 20.89 |
| Individual | 51 | 54,317 people | 406 | 5,453 people | 20.07 | 20.90 |

The three result files contain 273, 286, and 345 estimator rows,
respectively. Every level contains the 16 expected primary common-window rows
(eight reduced forms and eight fuzzy LATEs), and all eight primary fuzzy rows
meet the prespecified strict `F > 10` interpretation gate. The three 2017 manifests
contain 20 artifacts each; the combined 2013--2017 outcome manifest contains
117 unique paths.

All artifacts remain `generated_unreviewed`. Numerical findings require
substantive interpretation, disclosure review, and manuscript review before
publication or Overleaf synchronization.

## Deferred heterogeneity design

No heterogeneity estimate is produced by the current modules. A future
protocol should preserve the common design window and use one pooled,
fully interacted local-linear IV model for formal comparisons. For a
predetermined moderator, the endogenous terms would be treatment and
treatment-by-moderator; cutoff assignment and
assignment-by-moderator would provide the corresponding excluded instruments.
Moderator main effects and side-specific running-variable slopes should be
included, with the same weighting and clustering conventions as the relevant
main model. Subgroup-specific `rdrobust` estimates may accompany this test as
descriptive displays only; separately selected bandwidths or significance
comparisons across partitions cannot establish effect heterogeneity.

Candidate predetermined moderators include 2007 population, sex for person
outcomes, and district-capital status. Continuous population should remain
continuous unless theory fixes categories in advance. Familywise inference
and effective sample sizes must be reported because the local sample is
limited.

Realized CMAN project type is different: it is post-treatment and undefined
for untreated communities. Conditioning on it, splitting the treated sample,
or inserting it as an ordinary interaction would not identify causal
heterogeneity. A defensible project-type analysis requires a separate
estimand and identification argument--for example, a multivalued-treatment
design with adequate excluded variation--or must be labeled descriptive.
These choices remain for research-team approval before any code is written.
