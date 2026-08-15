# Analysis-dataset readiness audit

## Bottom line

The current pipeline now supports versioned 2013 outcome-estimation modules at
the CCPP, household, and individual levels. It is not yet ready for any
fuzzy-RD estimate to be called the primary causal result of the paper: the
implemented common-window first stages do not pass the conservative strength
gate. The remaining work is mostly interpretation, selection/linkage
sensitivity, and the 2017 wave-by-level modules, not another broad round of
data acquisition.

The correct architecture is not literally one file per analytical level.
`14_community_registry_census_2017.dta` is the complete RUV community spine,
but the person and household universes differ by outcome wave. The full 2013
SISFOH analyses must use files 09 and 10; the 2017 linked-cohort analyses must
use files 12 and 13. Treating the restricted 2017 cohort as the full 2013
person or household sample would create avoidable selection.

## Current analytical products

| Outcome universe | Canonical file | Rows | Main-sample coverage | Appropriate role |
|---|---|---:|---:|---|
| RUV communities | `14_community_registry_census_2017.dta` | 5,712 | 1,162 CCPPs | Community analysis spine; outcome-specific missingness remains |
| SISFOH people | `09_sisfoh_2013_individual_analysis.dta` | 1,425,575 | 1,033 CCPPs | Person outcomes measured during 2012--2013 fieldwork |
| SISFOH households | `10_sisfoh_2013_household_analysis.dta` | 415,007 | 1,033 CCPPs | Household and dwelling outcomes measured during 2012--2013 fieldwork |
| INEI-assisted Census cohort people | `12_census_2017_individual_analysis.dta` | 193,376 | 803 CCPPs | 2017 linkage, migration, and linked-person outcomes |
| INEI-assisted source households | `13_census_2017_household_analysis.dta` | 58,021 | 803 CCPPs | Outcomes aggregated to 2013 source households, not destination households |

The community spine preserves all RUV observations. Within the fixed
1,162-CCPP geography, 1,033 communities link to SISFOH, 803 are represented in
the INEI-assisted Census cohort, and 1,045 link to the CCPP GDP series. Missing
downstream data are never recoded as observed zero outcomes.

## Inputs that are now sufficiently prepared

- RUV victimization score, official categories, all four centered cutoffs,
  score-category conflicts, and the fixed `sample_main_rd` geography.
- CMAN first recorded funding year, cumulative treatment indicators from 2007
  through 2023, project type, financing, cofinancing, and linkage provenance.
- 2007 CCPP baseline components, transparent wellbeing domains, demographics,
  and service/housing measures.
- Geospatial coordinates, altitude, rurality, capital distances, and map
  support, with post-treatment 2017 attributes identified as such.
- Seminario-Palomino 1993/2006 economic context and 2013/2017 model-based CCPP
  GDP outcome candidates.
- Pre-program municipal political context from the 2002 and 2006 election
  cycles, including complementary-election replacements.
- SISFOH person, household, and CCPP outcomes with explicit universes,
  missingness, NBI definitions, wellbeing proxies, and interview timing.
- Census 2017 linked-cohort person, source-household, and CCPP outcomes,
  including linkage, migration, destination dispersion, NBI availability, and
  wellbeing measures.
- A routine selected-sample RD validity module covering score support, density,
  first stages, covariate and linkage continuity, local-randomization
  feasibility, multiplicity, and prespecified sensitivity branches.

## Locked decisions and remaining 2017 requirements

### Decisions locked for the 2013 modules

The research team has approved adjacent B/C support in the selected legacy
geography, `treat_12` for SISFOH 2013 outcomes, the fuzzy-RD LATE as the target
effect accompanied by the first stage and assignment reduced form, and a
common treatment-design bandwidth of 0.0075 with bias bandwidth 0.0135. The
main CCPP estimator uses local-linear triangular kernels, robust bias
correction, mass-point adjustment, and district CR2 inference. A compact
51-outcome registry fixes transformations, denominators, reporting tiers, and
multiplicity families. The common window is derived from the treatment design
and is never searched to maximize outcome significance or first-stage
strength.

The linked primary sample produces a robust first-stage statistic of
approximately 11.35, and the common-window parametric analogue produces a
Kleibergen--Paap F statistic of approximately 10.49. Both are below the
prespecified interpretation gate of 20. Consequently, fuzzy LATE estimates are
retained for diagnosis but must be presented with reduced forms and
weak-instrument-robust Anderson--Rubin inference. This status cannot be changed
by selecting a more favorable bandwidth after seeing the results.

The remaining subsections document the broader decisions that must be carried
forward or resolved for the 2017 person, household, and CCPP modules.

The household and individual modules carry the same design contract into the
correct SISFOH files. Both give each eligible RUV community total weight one,
cluster primarily by complete RUV community ID, and report observation-equal,
district, and exact-score sensitivities. The complete individual primary
sample contains 98,005 people age 14 or older in 487 communities; its common
window contains 8,870 people in 65 communities. The individual first-stage
statistic is approximately 11.11 and the parametric Kleibergen--Paap statistic
is approximately 11.10, so individual LATEs remain diagnostic under the same
gate.

### 1. Dated treatment and eligible risk set

The CMAN year is the authoritative available treatment event. SISFOH outcomes
use cumulative funding through 2012 (`treat_12`) and Census 2017 outcomes will
use cumulative funding through 2016 (`treat_16`); the team treats those
variables as materialized in 2013 and 2017, respectively. Exact approval,
start, completion, and delivery dates remain unavailable, so interview-date
and same-year alternatives are not competing primary definitions.

The analysis must also define the annual eligible untreated risk set and how
to handle inherited technical files, later-treated communities, and policy
regime changes. Treatment timing cannot be selected by the strongest observed
first stage.

### 2. RD estimand and score rule

The adjacent recorded B/C categories in the selected geography are the primary
support, and the numerical score centered at the official B--C cutoff defines
distance from the threshold. The pipeline fails if recorded category and score
sign conflict within that branch. Full support, rounding-band, and conflict
exclusions remain diagnostics rather than alternative main results.

The treatment-receipt fuzzy-RD LATE for compliers is the target effect, but it
is always reported beside the assignment reduced form and first stage. A
prespecified F-statistic gate of 20 governs interpretation; below the gate,
LATEs remain diagnostic and Anderson--Rubin and reduced-form evidence take
priority.

### 3. Inference at the assignment level

Treatment and the running variable vary at CCPP level. Household- and
individual-level models must therefore cluster at CCPP and report the number
of effective CCPP clusters on each side of the cutoff; person or household
sample size is not the effective assignment sample size. District-cluster and
score-mass-point inference remain prespecified sensitivity branches where the
outcome construction or discrete score warrants them.

The GDP outcomes deserve special caution: within-district CCPP shares are
fixed by the source and all CCPPs inherit district growth. GDP results should
be exploratory or robustness evidence, with district-aware inference, not a
standalone measure of community-specific growth.

### 4. Census linkage and outcome denominators

The Census source cohort contains 193,376 people, of whom 150,864 were linked
and 42,512 were not. Migration is observed only for linked people with valid
source and destination CCPP codes. Before complete-case effects are reported,
the analysis must estimate the RD effect on linkage itself, compare baseline
predictors of linkage, and implement a declared selection sensitivity such as
inverse-probability weighting, bounds, or both.

The household estimand also needs a denominator lock. File 13 represents 2013
source households and records splitting across 2017 destinations; it is not a
2017 destination-household census. NBI components requiring a complete
destination roster must remain restricted to the documented complete-roster
sample.

### 5. Outcome hierarchy and multiplicity

Every retained variable is not automatically an outcome. The 2013 CCPP,
household, and individual modules now use compact versioned registries
containing:

1. primary families and one preferred measure or index per family;
2. secondary outcomes;
3. mechanisms and descriptive implementation measures;
4. exploratory heterogeneity; and
5. placebo outcomes.

Each registry defines eligibility, missingness, transformation, scale, wave,
treatment horizon, paper role, and multiplicity family; the shared protocol
fixes the preferred estimator, covariates, weighting, and clustering. An
equivalent registry remains required before the 2017 modules are estimated.
The historical hundreds of model variants cannot be inherited as a
confirmatory analysis plan.

### 6. Mechanism and mediation boundary

Project category, implementation features, 2017 internet, employment, and
current-household conditions can all be affected by treatment. They must not
enter the primary model as ordinary controls. Internet and employment are
measured contemporaneously with migration and do not by themselves identify a
causal mediation effect. The initial mechanism module should be explicitly
descriptive or exploratory unless a separate causal mediation design is
approved.

## Additional data sources: required versus optional

### Required for the design, if obtainable

- CMAN administrative records that distinguish prioritization, approval,
  funding, start, completion, and delivery dates and identify inherited
  commitments or annual exceptions.
- A versioned decision on the longitudinal CCPP crosswalk and uncertainty of
  unresolved historical codes. This can be improved incrementally without
  dropping the complete RUV spine.
- The planned governed INEI linkage for Census 2025 before any 2025 extension
  is attempted.

### Valuable extensions, not prerequisites for the current core RD

- MINEDU school census and achievement data;
- MINSA health-facility data;
- CENAGRO agricultural data;
- ENDES indicators;
- Juntos and other social-program rollout records;
- public investment and expenditure records; and
- later municipal-election cycles.

Most of these sources are measured at district level, overlap treatment years,
or answer mechanism and spillover questions rather than the core CCPP RD.
They should be rebuilt only for a named estimand. Adding them before locking
the present design would enlarge the specification space without resolving
the binding identification issues.

## Recommended next implementation sequence

1. Lock the 2017 outcome registries and the linkage-selection estimand before
   estimating Census outcomes.
2. Build the 2017 modules first around sample flow, treatment timing, and
   linkage/attrition effects; do not begin with a large coefficient table.
3. Estimate 2017 assignment reduced forms first, then fuzzy effects with the
   same weak-first-stage-aware interpretation safeguards.
4. Preserve the completed household and individual modules using the correct
   wave-specific files and CCPP-level inference.
5. Add robustness, placebo outcomes, heterogeneity, and exploratory mechanisms
   only after the primary registry is frozen.
6. Map every reviewed output to the live paper through the existing manifest
   and Git-to-Overleaf gate.

## Readiness verdict

No additional broad source family is required before coding the remaining
analysis modules. The 2013 CCPP, household, and individual contracts now lock
the treatment horizon, adjacent B/C support, estimand hierarchy, common
bandwidth, assignment-level inference, weighting, and outcome/multiplicity
registries. They are not yet sufficient for an authoritative fuzzy-RD causal
claim because their first stages are below the conservative strength gate.
Census selection correction and denominator rules, plus the 2017 wave
contracts, remain to be completed.
