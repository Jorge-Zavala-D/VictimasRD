# Analysis-dataset readiness audit

## Bottom line

The current pipeline is ready to support construction and testing of the
outcome-estimation programs. It is not yet ready for any estimate to be called
the primary causal result of the paper. The remaining binding work is mostly a
research-design and specification lock, not another broad round of data
acquisition.

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

## Binding decisions before primary outcome estimation

### 1. Dated treatment and eligible risk set

The CMAN year is the authoritative available treatment event, but the project
still lacks exact approval, start, completion, and delivery dates. The team
must approve, for each outcome date, whether treatment means funding by the
prior calendar year, treatment before the observed interview, or another
event. Same-year treatment is ambiguous when only the year is observed.

The analysis must also define the annual eligible untreated risk set and how
to handle inherited technical files, later-treated communities, and policy
regime changes. Treatment timing cannot be selected by the strongest observed
first stage.

### 2. RD estimand and score rule

The team must designate the primary score-support branch and tie rule. The RUV
score is rounded to four decimals while the official cutoffs use six, so the
source category and numeric running variable can disagree at the boundary.
The current validation code reports adjacent-category, conflict-exclusion,
rounding-band, and full-support branches; none is yet primary.

The primary target must be named explicitly: assignment ITT, treatment-receipt
fuzzy-RD LATE for compliers, or both in a declared hierarchy. Fuzzy outcome
estimation also requires a weak-first-stage plan rather than relying only on a
conventional Wald ratio.

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

Every retained variable is not automatically an outcome. Before estimation,
the team must approve a compact outcome registry containing:

1. primary families and one preferred measure or index per family;
2. secondary outcomes;
3. mechanisms and descriptive implementation measures;
4. exploratory heterogeneity; and
5. placebo outcomes.

The registry must define eligibility, missingness, direction, transformation,
wave, treatment horizon, preferred estimator, covariates, clustering, and the
within- and across-family multiplicity rule. The historical hundreds of model
variants cannot be inherited as a confirmatory analysis plan.

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

1. Create a versioned outcome and specification registry and obtain explicit
   team approval for the treatment horizon, risk set, score rule, estimand,
   clustering, and multiplicity decisions.
2. Build the outcome module first around sample flow, treatment timing, and
   linkage/attrition effects; do not begin with a large coefficient table.
3. Estimate community-level ITT and first-stage/reduced-form results, then
   fuzzy effects with weak-first-stage-aware sensitivity.
4. Add household and individual models using the correct wave-specific files
   and CCPP-level inference.
5. Add robustness, placebo outcomes, heterogeneity, and exploratory mechanisms
   only after the primary registry is frozen.
6. Map every reviewed output to the live paper through the existing manifest
   and Git-to-Overleaf gate.

## Readiness verdict

No additional broad source family is required before coding the analysis
modules. The current data are sufficient to begin that work and to reproduce
the full sample-flow, validity, linkage, reduced-form, and fuzzy-RD workflow.
They are not yet sufficient for an authoritative primary causal claim because
the dated assignment regime, outcome-specific treatment horizon, risk set,
score-tie/support rule, estimand, clustering plan, Census selection strategy,
and outcome/multiplicity registry remain unresolved team decisions.
