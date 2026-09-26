# Census 2017 heterogeneity analysis

## 27 September 2026 migration-population update

The owner-approved 2017 individual observed-migration population is linked
adults aged at least 14 with valid canonical CCPP movement. Module `05f` now
uses this population for migration heterogeneity: 67,125 people in 409 RUV
communities, including 7,157 people in 62 communities inside the common
RD window. The other seven individual outcomes retain the eight-outcome
complete-case cohort: 54,317 people in 406 communities, including 5,453
people in 61 communities inside the window. The older migration
heterogeneity output is historical complete-case sensitivity evidence,
not the current primary-population result. The CCPP and household modules
are unaffected; all individual heterogeneity artifacts remain internal-only
pending scientific-owner review.

## Scope

`05d_census2017_ccpp_heterogeneity.do`,
`05e_census2017_household_heterogeneity.do`, and
`05f_census2017_individual_heterogeneity.do` implement all three Census 2017
treatment-effect heterogeneity levels. The CCPP module uses the 388-community
complete primary sample; the household module uses 24,877 households in 406
RUV communities; and the individual module uses the two outcome-specific
cohorts described above. All use the selected
adjacent B/C design, `running_bc`, cumulative treatment through 2016, and the
common fixed bandwidth `h = 0.0075`.

No heterogeneity module alters the main RD sample, selects moderators by results, or
estimates mediation. The primary formal comparison is a pooled, fully
interacted fuzzy local-IV model. `rdhte` is secondary assignment-effect
evidence only.

## Prespecified estimators

- Primary moderators: log 2007 CCPP population and district-capital status.
- Secondary moderators: 2007 deprivation, distance to the corresponding
  district capital, 2006 estimated CCPP GDP, and altitude.
- Primary CCPP inference: district-clustered, community-equal,
  triangular-weighted local-linear IV.
- Primary household inference: CCPP-clustered and CCPP-equal before triangular
  weighting; observation-equal and district- or score-clustered branches are
  sensitivities.
- Identification gate: adequate local support, underidentification rejection,
  and minimum Sanderson--Windmeijer conditional `F > 10`.
- Sensitivities: predetermined covariates, fixed `h = 0.0050` and `h = 0.0100`
  windows, and alternate prespecified clustering and weighting rules.
- Multiplicity: Holm adjustment for primary-moderator interactions and
  Benjamini--Hochberg adjustment for secondary-moderator interactions.

## Project implementation boundary

Project type and financing are realized after assignment and are not ordinary
moderators. The CCPP extension separately reports project-record composition
through 2016, discontinuities in receipt of four broad project groups, and an
exploratory continuous-dose IV using cumulative nominal CMAN financing plus
recorded cofinancing per 2007 resident. The eight dose outcomes receive
Benjamini--Hochberg adjustment. Even a strong dose first stage does not resolve
the additional linear-dose exclusion restriction.

Project attributes are not repeated on household rows because that would add
no assignment-level information and would create pseudo-replication.

## Validation snapshot: 16 September 2026

The CCPP module completed with return code 0 and produced 208 model rows,
14 moderator-support rows, 24 project-composition rows, and 48 project-dose
rows. The two primary-moderator fuzzy-IV families fail the strength gate;
assignment-effect estimates remain secondary and cannot replace failed
fuzzy-IV identification.

Within the 388-community CCPP analysis universe, 175 CMAN project records
through 2016 are linked: 54.9 percent productive livelihoods, 20.0 percent
community and civic infrastructure, 17.7 percent social and basic services,
and 7.4 percent management-capacity support. The recorded-financing assignment
discontinuity has an `rdrobust` first-stage statistic of 13.55. All eight
exploratory financing-dose IV models share a Kleibergen--Paap statistic of
13.90 and underidentification p-value 0.0097, but none is significant at five
percent after Benjamini--Hochberg adjustment. These diagnostics do not
establish the additional exclusion restriction needed for causal dose
interpretation.

The household module also completed with return code 0. Its source has 58,021
households; 33,066 lie in the selected adjacent-B/C design, 24,877 have all
eight primary outcomes, and 2,706 households from 61 RUV communities lie
inside the common window. It produced 224 model rows and 14 support rows. Of
48 common-window fuzzy-IV rows, eight baseline-deprivation rows pass the gate
with minimum conditional `F = 14.66`; 40 fail. The district-capital equations
are unavailable because the local binary cells contain only two communities
above and three below the cutoff. No gate-passing interaction survives a
five-percent Holm or Benjamini--Hochberg correction.

## Individual migration re-estimation: 27 September 2026

The targeted `05f` run completed through the Stata MCP and passed its
312-row output contract. Its 20-artifact level manifest records the unchanged
Dropbox Coded input signature; no dataset was rewritten. The seven
non-migration outcomes have exactly the same unadjusted estimates,
standard errors, first-stage diagnostics, and gate decisions as the prior
run. Family-adjusted values can change because the migration rows changed.

Within the approved migration population, the female-moderator model uses
7,157 adults in 62 communities. Its female-versus-male treatment-effect
interaction is +0.99 percentage points (95% CI -11.51 to +13.49; raw
`p = 0.876`, Holm-adjusted `p = 1`). This row passes the registered support,
underidentification, and minimum conditional-first-stage gate
(`F = 17.95`); it provides no evidence of a gender difference. The
population interaction is underidentified (minimum conditional `F = 2.95`,
underidentification `p = 0.111`), and district-capital status has only two
communities in its smallest local cell. Do not interpret either failed-gate
coefficient causally. Secondary deprivation and age interactions pass the
gate but neither yields an adjusted signal. Across all individual outcomes,
23 of 64 common-window fuzzy-IV interactions pass the gate; the sole raw
five-percent signal remains wellbeing-by-gender, not migration, and its
Holm-adjusted `p` is about 0.455.

The 20-row support CSV and overlap plots describe the pooled
migration-eligible candidate frame. Effective support for each outcome and
moderator is in its model-result row; non-migration estimators still use the
smaller complete-case sample. Continuous moderators retain the prespecified
complete-case reference scale to preserve comparability with the seven
unchanged outcomes. These are linked, observable adults, not all Census
source-cohort adults. The historical complete-case migration-by-gender
interaction was -0.75 percentage points (`p = 0.949`); it is retained only
as a sensitivity reference, not substituted for the approved-population
estimate. `rdhte` remains assignment-effect evidence, not fuzzy-LATE
heterogeneity.

## Output contract

All outputs are aggregate and non-sensitive. Machine-readable results and
LaTeX tables are written under `output/tables/rd_heterogeneity`; figures are
written under `output/figures/rd_heterogeneity`. Level manifests are
`metadata/rd-heterogeneity-output-manifest-2017-ccpp.csv`,
`metadata/rd-heterogeneity-output-manifest-2017-household.csv`, and
`metadata/rd-heterogeneity-output-manifest-2017-individual.csv`.

The three Census 2017 modules generated 63 artifacts: 26 CCPP, 17 household,
and 20 individual. The combined 2013--2017 manifest contains 126 unique
paths; all 126 recorded checksums were verified after the targeted `05f`
run. Every artifact remains marked `generated_unreviewed`; none was
synchronized to Overleaf in this batch. The eight household LaTeX fragments
compiled into a 10-page QA document in the earlier validation, and the
revised individual migration figures were visually inspected for labels,
notes, and clipping.
