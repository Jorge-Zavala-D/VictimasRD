# Regression discontinuity design methods audit

**Status:** methodological review and decision memo. The government thresholds
were approved on 2026-07-28; no RD estimand or analysis specification is
approved by this document.

**Date:** 2026-07-28

**Policy-evidence update (2026-07-29):** Read
`docs/PRC_ROLLOUT_AND_RD_REASSESSMENT.md` before applying this methodological
memo. The later documentary review finds that the post-2012 operational rule
jointly prioritized A and B, making B--C the only explicit boundary between
that priority pool and the remaining categories. The general multiple-cutoff
discussion below is therefore a diagnostic framework, not evidence that all
four category boundaries operated as equivalent assignment rules.

## Purpose

This memo consolidates the methodological issues that must be resolved before
the Victimas RD analysis is rewritten. It reviews the supplied government
methodology, the preserved legacy Stata code, the current working-paper
narrative, the supplied RD literature, maintained RD software documentation,
and a targeted set of applied studies. It also records a recommendation on
centered running variables and a staged approach to the four category
boundaries.

The recommendations are deliberately separated from research-team decisions.
The geographic sample, primary estimand, outcome families, treatment timing
for each outcome, and clustering rule remain unresolved in
`docs/PROJECT_CONTEXT.md`.

## Immediate conclusions

1. Retain `victimization_index` exactly as supplied by the RUV workbook.
2. Centered variables are useful, but they are a coding convenience rather
   than a different estimator. For example,
   `running_bc = victimization_index - cutoff_bc` with `c(0)` is
   mathematically equivalent to using `victimization_index` with
   `c(cutoff_bc)` in `rdrobust`.
3. Create four double-precision
   variables: `running_ab`, `running_bc`, `running_cd`, and `running_de`.
4. Use the exact government thresholds. The research team designated the
   official methodology as authoritative on 2026-07-28.
5. Do not infer treatment from the sign of a centered score. The design is
   fuzzy, and observed receipt by a declared year must remain a separate
   variable.
6. Start from the complete RUV universe. Restricting the stored data to source
   categories B and C is not required for a local B--C analysis.
7. Analyze each boundary as a separate candidate fuzzy RD before considering
   any pooled multi-cutoff estimate. Pooling would combine different local
   margins and possibly different complier groups.
8. The other category boundaries do not by themselves bias a local B--C RD.
   The relevant requirement is that the estimation bandwidth around B--C not
   cross an adjacent threshold.
9. The score is discrete/heaped. The current community registry has 5,712
   observations but only 2,072 distinct score values. Legacy uses of
   `masspoints(off)` should not be carried forward.
10. Historical exploratory selection of the geography and cutoff should be
    documented transparently. A confirmatory analysis plan must be fixed
    before looking across many sample/cutoff/outcome combinations.

## Cutoff evidence and recorded decision

The government note `Indice_Nivel_Afectacion.pdf` reports the following
intervals:

| Boundary | Official threshold | Category above | Category below |
|---|---:|---|---|
| A--B | 0.153750 | A: very high | B: high |
| B--C | 0.062320 | B: high | C: medium |
| C--D | 0.026930 | C: medium | D: low |
| D--E | 0.015220 | D: low | E: very low |

The full printed ranges are A = 0.153750--1.000000,
B = 0.062320--0.153749, C = 0.026930--0.062319,
D = 0.015220--0.026929, and E = 0.007740--0.015219.

The preserved legacy preparation code instead centers at rounded values:

| Boundary | Legacy value |
|---|---:|
| A--B | 0.1538 |
| B--C | 0.0623 |
| C--D | 0.0269 |
| D--E | 0.0152 |

The current working-paper appendix reports a third set of ranges:

| Category | Current manuscript range |
|---|---|
| A | 0.15370--1.00000 |
| B | 0.06310--0.15369 |
| C | 0.02520--0.06309 |
| D | 0.00742--0.02519 |
| E | 0.00000--0.00741 |

These are not harmless display differences. In particular, the manuscript
B--C, C--D, and D--E thresholds differ materially from the government note.
On 2026-07-28, the research team designated the government note as the
authoritative source. The current manuscript values must be corrected in a
future authorized manuscript task and described as a provenance discrepancy,
not used as alternative thresholds.

### What the current data reveal

Read-only Stata MCP checks on
`06_community_registry_geospatial.dta` found:

- 5,712 RUV communities and no missing victimization score;
- a score range of 0.0077 to 2.3622, despite the government note describing a
  nominal 0--1 scale;
- 2,072 distinct score values;
- 189 observations at 0.0077, the four-decimal representation of the printed
  minimum of 0.007740;
- 7 observations above the printed maximum of 1;
- 72 apparent category disagreements that occur at rounded boundary values;
  and
- 1 remaining category-score conflict away from a rounding boundary.

The score is stored to four decimal places. At the B--C boundary, the same
stored value of 0.0623 occurs in both source categories, so no numerical rule
applied to the stored score can perfectly reconstruct administrative
assignment. The canonical pipeline therefore preserves the RUV category as
authoritative for category and side-of-boundary assignment. See
`docs/VICTIMIZATION_INDEX_FORMULA_AUDIT_2026-07-28.md`.

Within a common symmetric window of 0.015 around each official threshold, the
available support is:

| Boundary | Observations | Distinct score values |
|---|---:|---:|
| A--B | 258 | 171 |
| B--C | 702 | 255 |
| C--D | 2,170 | 206 |
| D--E | 2,023 | 110 |

These are descriptive support counts, not approved effective samples and not
evidence of a valid first stage.

## Recommendation on centered running variables

Adding the four centered variables is worth doing now that the cutoff decision
is resolved. Four substantively meaningful variables are not the kind of
auxiliary-variable proliferation that the repository is trying to avoid.
They improve:

- readability of plots, tables, local-linear parametric checks, and notes;
- consistency across cutoff-specific code;
- interpretation of intercepts and treatment-by-slope interactions;
- transparent window definitions and sample-flow reporting; and
- possible future cutoff-specific stacking, if a multi-cutoff analysis is
  approved.

The implementation should follow these rules:

1. Define all four thresholds in one versioned RD design registry, not as
   repeated numeric literals scattered across programs.
2. Generate the variables as `double`.
3. Keep the original `victimization_index`.
4. Label each variable with its boundary, exact threshold, direction, and
   authoritative source.
5. Assert exact equivalence to
   `victimization_index - approved_cutoff`.
6. Keep observed treatment receipt and assignment/priority indicators
   conceptually distinct.
7. Do not use centered variables to justify a global polynomial over the full
   score support.
8. Do not add all intermediate score transformations to released datasets.

The centered variables may now be used with `c(0)`, but category membership or
the side of a fuzzy assignment rule must come from the source category rather
than mechanically from the sign when a rounded threshold value is tied across
categories.

## Full support versus an adjacent-category restriction

An RD estimate is local. A B--C estimate compares observations sufficiently
close to the B--C boundary; observations near A--B, C--D, or D--E receive no
weight when they are outside the selected B--C bandwidth.

Using the official thresholds, the B--C boundary is:

- 0.091430 below A--B; and
- 0.035390 above C--D.

Consequently, a B--C bandwidth must remain inside those adjacent boundaries.
If a data-driven bandwidth crosses an adjacent threshold, the analysis should
use a predeclared admissible bandwidth cap or an adjacent-category support
rule. It should not silently combine policy margins.

The legacy B/C category restriction was therefore not automatically necessary
when its roughly 0.015 windows were used. It may nevertheless change automatic
bandwidth selection, data checks, and sample accounting. The rewritten
analysis should:

1. begin with the full RUV universe;
2. declare the cutoff and eligible geography;
3. select or cap bandwidths under a documented rule;
4. show that included score values do not cross neighboring thresholds; and
5. report exact sample flow rather than permanently dropping other categories.

## Why the historical analysis focused on B--C

Comments preserved in the working-paper source record the historical search:

- no useful discontinuity was seen for the whole country;
- no useful A--B discontinuity was seen;
- the B--C discontinuity was positive but not statistically significant in an
  early exploration;
- C--D and D--E were not examined because the program had not progressed far
  enough by the selected year;
- departments and neighboring provinces were explored to find a clearer first
  stage; and
- Ayacucho and San Martín were excluded for stated empirical or contextual
  reasons.

This history suggests that the B--C and geographic restrictions arose from
program timing and exploratory first-stage searches, not from a theorem that
only B and C observations can identify the effect.

The history is valuable, but it creates a specification-search risk. It should
be disclosed and followed by a transparent confirmation strategy rather than
repeatedly optimizing the sample for the strongest first stage.

## Is this a multi-cutoff RD design?

Not automatically.

### Standard noncumulative multi-cutoff design

In the usual noncumulative design, each unit faces one group-specific cutoff.
For example, different administrative regions may apply different score
thresholds to the same treatment. The cutoff variable partitions the
population: each unit is exposed to one and only one cutoff.

That is not the present description of the PRC. Every community appears to
have one victimization score and the same four ordered category boundaries.

### Cumulative multi-cutoff design

The case is closer to a cumulative multi-cutoff setting if crossing each
ordered boundary changes a priority tier, treatment probability, treatment
timing, treatment dose, or treatment type. In a cumulative design, the
meaning of “treated” and “control” can change across boundaries, estimates may
be correlated when windows overlap, and pooled effects can average
heterogeneous margins.

For Victimas RD, the observed endpoint is generally binary receipt by a
specified year. The boundaries may affect the priority and timing of the same
program rather than assign four distinct treatments. This can support
cutoff-specific fuzzy RDs only if the local first stage exists and the
institutional rule is credible at each boundary.

### Recommended sequence

1. Reconstruct the written assignment and prioritization rule by year.
2. Freeze the treatment date relevant to each outcome.
3. Plot and estimate the local first-stage and reduced-form discontinuity at
   all four boundaries in the full eligible geography.
4. Evaluate score density/mass points and predetermined covariates at every
   candidate boundary.
5. Identify one primary boundary through institutional and theoretical
   reasoning, not maximum significance.
6. Treat the other boundaries as prespecified secondary or validation
   analyses.
7. Consider `rdmulti` only after cutoff-specific effects have compatible
   treatment definitions and an interpretable pooled estimand.
8. If pooling is used, report every cutoff-specific estimate and the pooling
   weights; never present only the pooled number.

A pooled fuzzy estimate would generally average local effects for different
complier groups. It may be useful, but it is not automatically “the program
effect,” and it cannot rescue a weak or absent first stage at a boundary.

## Recommended modern RD protocol

The following is a proposed protocol skeleton, not an approved specification.

### Design and estimands

- Define the score, exact cutoff, assignment direction, treatment receipt,
  treatment year, outcome measurement date, and unit of analysis.
- Report the first-stage and intention-to-treat discontinuity before the fuzzy
  Wald ratio.
- State the fuzzy-RD monotonicity and exclusion restrictions and explain their
  institutional plausibility.
- If the first stage is weak, emphasize the reduced form and use
  weak-identification-robust inference as a sensitivity analysis.

### Main continuity-based estimation

- local linear polynomial (`p(1)`) fitted separately on each side;
- triangular kernel;
- data-driven MSE-optimal bandwidth for point estimation;
- robust bias-corrected confidence intervals;
- a single jointly selected bandwidth for fuzzy numerator and denominator;
- default mass-point checks/adjustment, not `masspoints(off)`;
- heteroskedasticity-robust or appropriately clustered inference selected
  through a documented sampling/assignment argument; and
- predetermined covariate adjustment only for precision, with an additive
  common-coefficient specification.

### Discrete running-variable work

Because the score has mass points:

- report observations and distinct score values on each side of every cutoff;
- inspect whether the selected bandwidth contains enough support points;
- retain `rdrobust` mass-point adjustment;
- consider inference clustered by score value as a sensitivity analysis;
- use local-randomization methods as a complementary design when a defensible
  window of discrete values can be selected; and
- do not interpret a conventional density test mechanically when discreteness
  makes its assumptions inappropriate.

### Validity and sensitivity

- graphical first stage and reduced form;
- modern density/sorting diagnostic with a discrete-score interpretation;
- predetermined-covariate continuity checks;
- placebo outcomes that cannot be caused by treatment;
- placebo cutoffs chosen in advance;
- donut analyses that remove the closest score values;
- bandwidth sensitivity around the selected bandwidth;
- alternative kernels and local quadratic sensitivity;
- specification sensitivity with and without predetermined covariates;
- geographic and treatment-year sensitivity justified by the rollout;
- cluster-level diagnostics and effective-cluster counts;
- missingness, linkage, and sample-selection discontinuities;
- power and minimum-detectable-effect analysis; and
- multiple-testing adjustment for declared outcome families.

High-order global polynomials should not be used. A low-order parametric local
linear replication can be reported for transparency, but it should use a
limited window, separate slopes by side, and uncertainty appropriate to the
data structure.

## Clustering

The legacy analysis clusters at the district level. This may be appropriate
for within-district dependence, but it cannot be assumed correct merely
because communities are nested in districts.

Before choosing the main variance estimator, document:

- the level at which assignment shocks or treatment implementation are
  correlated;
- the number of clusters represented inside the selected bandwidth;
- treated/control and left/right cluster support;
- whether bandwidth selection itself accounts for clustering;
- whether districts straddle the cutoff; and
- sensitivity to score-level mass-point clustering and other credible
  dependence structures.

With few effective clusters, conventional cluster-robust standard errors may
be unreliable. Small-cluster sensitivity methods should be evaluated before
release.

## Treatment timing

The treatment definition must precede or align with the outcome window.
Using `treat_13` for 2017 outcomes while many 2013 controls receive treatment
by 2017 changes the estimand and threatens the exclusion/interpretation of the
fuzzy design.

For every outcome family, specify:

- the policy or assignment date;
- receipt by the baseline date;
- receipt during the outcome interval;
- receipt by the endpoint;
- whether later treatment is censoring, contamination, treatment switching,
  or part of a dynamic treatment regime; and
- the causal contrast identified by the selected instrument.

Category-level national treatment means show a strong priority gradient, but
they are not local first stages:

| RUV category | Treated by 2007 | Treated by 2013 | Treated by 2017 | Treated by 2023 |
|---|---:|---:|---:|---:|
| A | 0.119 | 0.597 | 0.852 | 0.913 |
| B | 0.051 | 0.420 | 0.611 | 0.860 |
| C | 0.028 | 0.274 | 0.279 | 0.840 |
| D | 0.004 | 0.133 | 0.137 | 0.635 |
| E | 0.000 | 0.029 | 0.029 | 0.195 |

These descriptive patterns make the multi-year assignment mechanism central
to the design.

## Lessons from the reviewed applied studies

The reviewed applied studies show a useful reporting pattern:

- clearly distinguish policy assignment (ITT) from treatment received (fuzzy
  RD/CACE);
- center the score for interpretation while keeping the actual cutoff
  documented;
- use local linear fits and side-specific slopes;
- report the first stage and its uncertainty;
- use MSE-optimal bandwidths and robust bias-corrected intervals;
- show density and predetermined-covariate diagnostics;
- vary bandwidth and kernel as sensitivity analyses; and
- state exclusion and monotonicity assumptions rather than treating
  `fuzzy()` as a mechanical option.

These practices are directly relevant. Details that are application-specific,
such as a rectangular kernel or a particular fixed time window, should not be
copied without a Victimas RD rationale.

The applied examples reviewed for this purpose include:

- Bor et al., “One Pill, Once a Day,” which reports local-linear estimates,
  triangular weights, MSE-optimal bandwidths, robust bias-corrected intervals,
  assignment ITT and fuzzy-RD treatment-receipt effects, and 50%/200%
  bandwidth and kernel sensitivity:
  <https://academic.oup.com/aje/article/191/6/999/6515666>
- the South African viral-load monitoring application, which centers the
  running variable, allows separate slopes, reports balance and bunching
  diagnostics, and illustrates that an application-specific kernel choice
  requires explanation:
  <https://academic.oup.com/aje/article/189/12/1492/5869595>
- the Ser Pilo Paga example in the 2024 *Extensions* volume, which has one
  wealth score but genuinely region-specific cutoffs. It demonstrates the
  noncumulative setting for which cutoff-specific and pooled `rdmulti`
  estimates have a direct interpretation:
  <https://rdpackages.github.io/references/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf>
- a geographic-border application that reports conventional, bias-corrected,
  and robust local-linear estimates, effective observations on each side, and
  covariate-adjusted sensitivity:
  <https://www.aeaweb.org/content/file?id=6394>

## Reviewed source set

All 15 supplied PDFs were opened, text-extracted page by page, and visually
checked. Together they contain 655 pages. The inventory and SHA-256 checksums
are recorded in `metadata/rd-design/source-inventory.csv`.

The methodological core comprises:

- Calonico, Cattaneo, Farrell, and Titiunik on `rdrobust`;
- Cattaneo, Idrobo, and Titiunik, *Foundations* and *Extensions*;
- Cattaneo, Keele, and Titiunik on practical RD implementation;
- Cattaneo, Titiunik, and Vazquez-Bare on power and multi-cutoff/multi-score
  designs;
- Calonico et al. on covariate adjustment;
- Gelman and Imbens on avoiding high-order polynomials;
- Bartalotti and Brummet on clustered data;
- Branson et al. on Bayesian Gaussian-process sensitivity analysis;
- Keele and Titiunik on geographic RD; and
- Papay et al. on multiple assignment variables.

The last two designs are not the current assignment mechanism: geography is a
covariate and contextual dimension here, not the treatment boundary, and the
victimization index is one score rather than several simultaneous assignment
variables.

The Bayesian method is a possible sensitivity analysis, not a replacement for
the canonical, reproducible `rdrobust` specification.

The supplied 2018 *Extensions* file is an unfinished draft: its late fuzzy-RD
reading section and final remarks contain “TO BE ADDED.” The review therefore
uses the completed 2024 volume for current guidance while preserving the
attached draft in the inventory.

## Current online methodological resources

This review checked the maintained RD Packages resources and current
references available on 2026-07-28:

- RD Packages overview and software:
  <https://rdpackages.github.io/>
- `rdrobust`:
  <https://rdpackages.github.io/rdrobust/>
- `rddensity`:
  <https://rdpackages.github.io/rddensity/>
- `rdlocrand`:
  <https://rdpackages.github.io/rdlocrand/>
- `rdpower`:
  <https://rdpackages.github.io/rdpower/>
- `rdmulti` methods:
  <https://rdpackages.github.io/references/Cattaneo-Titiunik-VazquezBare_2020_Stata.pdf>
- 2024 *Extensions* volume:
  <https://rdpackages.github.io/references/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf>
- replication examples:
  <https://rdpackages.github.io/replication/>
- Cattaneo and Titiunik's RD protocol:
  <https://rdpackages.github.io/references/Cattaneo-Titiunik_2024_STS--Comment.pdf>

The repository's local Stata environment currently finds `rdrobust` 11.1.0
(22 May 2026), `rddensity` 3.0 (27 May 2026), `rdmc`, `rdmcplot`, `rdms`,
`rdrandinf`, and `rdwinselect`. Installed availability does not approve their
use or settle the design.

### Emerging methods to track

The following newer work is relevant but should not displace the canonical
specification without a separate decision:

- Noack and Rothe, “Bias-Aware Inference in Fuzzy Regression Discontinuity
  Designs,” develops inference intended to remain valid under weak
  identification and in settings including discrete running variables and
  donut designs:
  <https://arxiv.org/abs/1906.04631>
- Caetano, Caetano, and Escanciano (2026) study fuzzy-RD estimands with
  covariates and heterogeneous compliance. This is a current preprint and a
  useful sensitivity-method candidate, not yet the default project estimator:
  <https://arxiv.org/abs/2602.01417>
- `rdhte` provides new local-polynomial methods for prespecified treatment
  effect heterogeneity. It should not be used for exploratory subgroup mining:
  <https://rdpackages.github.io/rdhte/>
- `rd2d` is designed for bivariate or geographic assignment boundaries. It is
  not required merely because this project uses geospatial covariates:
  <https://rdpackages.github.io/rd2d/>

## Recorded decisions and remaining analysis decisions

The research team has decided that the government methodology defines the
exact cutoffs and that the supplied RUV category governs category assignment
when the rounded score is ambiguous. The formula audit explains the 189
rounded-minimum values, 72 rounded-boundary category discrepancies, seven
scores above one, and one category-score conflict away from a boundary.

The following analysis decisions remain:

1. Which boundary is primary, and why?
2. Which treatment year corresponds to each outcome?
3. What is the assignment or encouragement at every cutoff?
4. What geography defines the target population independently of observed
   first-stage significance?
5. What is the main causal estimand: assignment ITT, receipt LATE, dynamic
   treatment effect, or another contrast?
6. What is the clustering level and minimum acceptable effective-cluster
   support?
7. Which outcomes and robustness checks are confirmatory versus exploratory?
8. Is any pooled multi-cutoff effect substantively interpretable?
9. How will tied scores at rounded boundary values enter the primary and
   sensitivity specifications?

The cutoff registry, centered variables, formula diagnostics, and validation
tests are now implemented in the preparation pipeline.

## Audit limitations

This is a comprehensive targeted review of the supplied materials and current
maintained methodology, not a claim to have exhausted every RD publication.
No outcome RD model was selected or re-estimated for this memo because the
sample, treatment timing, assignment mechanism, and estimand remain governance
blockers. The completed pipeline writes only the documented row-level formula
review to Dropbox Working QA; it does not modify any Dropbox Raw input.
