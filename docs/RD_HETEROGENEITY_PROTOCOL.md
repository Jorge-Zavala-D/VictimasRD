# Victimas RD heterogeneity analysis protocol

## Status and scope

This protocol governs the prespecified effect-heterogeneity modules that follow
the main SISFOH 2013 and Census 2017 outcome analyses. It fixes the estimands,
moderators, sample, bandwidth, weighting, inference, instrument-strength gates,
and interpretation rules before reviewing heterogeneity results. The first
implemented module is `05a_sisfoh2013_ccpp_heterogeneity.do`.

The SISFOH 2013 suite is implemented in
`05a_sisfoh2013_ccpp_heterogeneity.do`,
`05b_sisfoh2013_household_heterogeneity.do`, and
`05c_sisfoh2013_individual_heterogeneity.do`. The latter two share the
versioned engine `_heterogeneity_level_engine.do` so that weighting,
identification gates, multiplicity, and output checks cannot drift across
levels.

The analysis uses the selected legacy geography, adjacent B/C support,
`running_bc`, cumulative treatment through the year preceding the outcome
wave, and the common design bandwidth `h = 0.0075`. No moderator, outcome,
bandwidth, or subgroup may be selected because it strengthens an instrument or
produces a favorable result.

## Estimand hierarchy

Three quantities are kept separate, in the following hierarchy.

1. **Fuzzy-LATE heterogeneity.** A pooled, fully interacted local-linear 2SLS
   model instruments treatment and treatment-by-moderator with cutoff
   assignment and assignment-by-moderator. The coefficient on the endogenous
   interaction is the primary formal difference or slope in the local complier
   effect.
2. **Conditional local effects.** The same pooled IV model is used to report
   the implied LATE at the 25th, 50th, and 75th percentiles of a continuous
   moderator, or at zero and one for a binary moderator. These are linear
   combinations from one model, not estimates from separately fitted
   subgroups.
3. **Assignment-effect heterogeneity.** `rdhte` estimates whether the sharp RD
   discontinuity in an outcome varies with a predetermined moderator. These
   are secondary reduced-form or assignment effects. They remain interpretable
   without dividing by a first stage, subject to local support and the RD
   assumptions, but they do not identify fuzzy-RD treatment-effect
   heterogeneity.

For a standardized continuous moderator \(M\), treatment \(D\), cutoff
assignment \(Z\), and centered running variable \(R\), the primary 2SLS model
contains \(D\), \(D M\), \(M\), \(R\), \(ZR\), \(RM\), and \(ZRM\). The
excluded instruments are \(Z\) and \(ZM\). A binary moderator uses the same
saturated interaction logic without standardization. Triangular kernel weights
are applied inside the fixed window, and inference follows the clustering rule
for the analysis level.

`rdhte` is not used as a fuzzy-RD estimator and never substitutes for a
pooled IV model that fails its identification gate. Its current Stata implementation
provides robust local-polynomial conditional assignment effects, bandwidth
selection, linear-combination tests, and plots. The project installs it from
the authors' official source:
<https://github.com/rdpackages/rdhte>.

## Moderator registry

The machine-readable registry is
`metadata/rd-heterogeneity/moderator-registry.csv`. The three primary
moderators are:

- log 2007 CCPP population;
- district-capital status; and
- respondent sex for individual-level models.

The secondary moderators are:

- baseline 2007 deprivation;
- log distance to the corresponding district capital;
- baseline 2006 CCPP economic development;
- age or birth cohort for individual-level models; and
- altitude as a fixed accessibility attribute.

Continuous moderators are centered and scaled by their standard deviation in
the complete wave-by-level analysis universe before the local-window
restriction. Population remains continuous and log transformed. Categories
are never data-mined. The district-capital and geospatial measures use the
available 2017 spatial coding as proxies for fixed location attributes; their
vintage limitation must remain visible.

NotebookLM was used only to discover theory anchors for this closed list. It
suggested population and gender mechanisms related to the allocation and
control of collective in-kind investments, and remoteness, deprivation,
baseline development, and accessibility mechanisms related to local market
integration and state capacity. These are hypotheses, not empirical findings.
Any manuscript citation must be checked against the underlying source before
use.

## Outcome and multiplicity rules

Formal heterogeneity is estimated for the eight registered primary outcomes
at each wave and level. Primary moderator-by-outcome interaction tests form one
family within estimator, wave, and level and receive Holm family-wise
adjustment. Secondary moderator interactions receive Benjamini--Hochberg
adjustment within estimator, wave, and level. Machine-readable files retain
raw and adjusted p-values, failed estimates, non-applicable identity cells, and
all interpretation gates.

Fuzzy-IV figures and tables visually identify every model that fails the
instrument gate. Assignment-effect figures are labeled secondary. A failed
fuzzy gate means that no credible causal treatment-effect heterogeneity has
been established; it does not elevate `rdhte` to the primary causal
estimator. A non-significant result is not evidence of homogeneous effects
when confidence intervals are wide.

## Instrument and support gates

The approved main first-stage interpretation gate is strictly greater than
10, not greater than or equal to 10. For a two-endogenous-variable
heterogeneity model, the relevant diagnostic is the minimum
Sanderson--Windmeijer conditional F statistic across treatment and the
treatment-by-moderator interaction. A fuzzy heterogeneity result is
interpretation-ready only when:

- the minimum conditional F is strictly greater than 10;
- the local model has adequate rank and returns finite estimates; and
- the moderator has prespecified local support.

The Kleibergen--Paap rk Wald F, underidentification p-value, equation-specific
excluded-instrument F statistics, and joint Anderson--Rubin p-value are also
reported. Stock--Yogo critical values are not treated as exact under
clustering.

For continuous moderators, local support requires at least 10 observations and
at least 10 RUV community assignment clusters on each side. For binary
moderators, every moderator-by-side cell must contain at least 10 observations
and 10 RUV community assignment clusters. Results that fail support remain in
the diagnostic files but are not presented as credible causal heterogeneity.
The gate may not be weakened after seeing results.

## CCPP-level conventions

The CCPP module uses one RUV community per row, district-clustered inference,
and the same complete eight-outcome SISFOH sample as the CCPP main-effects
module. The unadjusted fully interacted model is primary. Predetermined
covariate adjustment and fixed windows `h = 0.0050` and `h = 0.0100` are
prespecified sensitivities; no sensitivity replaces the common-window model.

## Household- and individual-level conventions

The household and person modules use the same complete eight-outcome samples
as their main-effects counterparts. Their primary estimand gives every
eligible RUV community total weight one, with observations equally weighted
within community before triangular kernel weighting. Primary inference
clusters by RUV community. Observation-equal weighting and district- and
score-mass-point-clustered inference are prespecified sensitivities, as are
the fixed windows `h = 0.0050` and `h = 0.0100` and the approved
predetermined covariate set.

CCPP-level moderators are standardized over one record per represented RUV
community in the complete level-specific sample. Respondent age is
standardized over eligible people. The female-outcome by female-moderator cell
is a mechanical identity and is retained as explicitly non-applicable rather
than estimated.

Project type, financing, and other realized implementation attributes are
handled only in the CCPP extension. Repeating them on household or person rows
would not create new assignment-level information and would risk
pseudo-replication.

## Project type and financing

Realized project type and financing are post-assignment implementation
attributes and are undefined for untreated communities. They are not ordinary
moderators and are never inserted into the primary causal heterogeneity model.
The CCPP module instead reports:

- assignment discontinuities in receipt of each broad project group;
- the observed project composition among records delivered by the outcome
  horizon; and
- an explicitly exploratory continuous-dose IV using total recorded CMAN plus
  cofinancing through the outcome horizon per 2007 resident.

The financing measure uses the recorded nominal amounts as supplied, following
the research-team decision. It does not verify disbursement, execution,
completion, or cofinancing realization. The dose-IV coefficient requires a
linear dose response and an exclusion restriction much stronger than the
binary-treatment design, because assignment can affect outcomes through
project content as well as recorded soles per resident. It is therefore an
exploratory extension even when its first stage exceeds 10.

Project-group outcome comparisons among treated communities are descriptive.
One cutoff instrument cannot separately identify several endogenous project
types, so the code does not label such comparisons causal.

## Deferred work

Treatment timing and years-since-treatment heterogeneity are excluded pending
a later research-team decision. Mediation is governed by a separate future
protocol. All outputs remain `generated_unreviewed` until substantive,
disclosure, and manuscript review.
