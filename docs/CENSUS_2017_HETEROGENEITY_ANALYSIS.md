# Census 2017 heterogeneity analysis

## Scope

`05d_census2017_ccpp_heterogeneity.do` is the first Census 2017
treatment-effect heterogeneity module. It uses the 388-community complete
primary CCPP sample from the INEI-assisted Census cohort, the selected adjacent
B/C design, `running_bc`, cumulative treatment through 2016, and the common
fixed bandwidth `h = 0.0075`.

The module does not alter the main RD sample, select moderators from the
results, or estimate mediation. Its primary formal comparison is a pooled,
fully interacted fuzzy local-IV model. `rdhte` is secondary
assignment-effect evidence only.

## Prespecified estimators

- Primary moderators: log 2007 CCPP population and district-capital status.
- Secondary moderators: 2007 deprivation, distance to the district capital,
  2006 estimated CCPP GDP, and altitude.
- Primary inference: district-clustered, community-equal,
  triangular-weighted local-linear IV.
- Identification gate: adequate local support, underidentification rejection,
  and minimum Sanderson--Windmeijer conditional `F > 10`.
- Sensitivities: predetermined covariates, fixed `h = 0.0050` and
  `h = 0.0100` windows, CCPP clustering, and exact-score-mass-point
  clustering.
- Multiplicity: Holm adjustment for primary-moderator interactions and
  Benjamini--Hochberg adjustment for secondary-moderator interactions.

## Project implementation boundary

Project type and financing are realized after assignment and are not ordinary
moderators. The CCPP extension separately reports project-record composition
through 2016, discontinuities in receipt of four broad project groups, and an
exploratory continuous-dose IV using cumulative nominal CMAN financing plus
recorded cofinancing per 2007 resident. The eight dose outcomes receive a
Benjamini--Hochberg adjustment. Even a strong dose first stage does not resolve
the additional linear-dose exclusion restriction.

## Validation snapshot

The validated run dated 14 September 2026 produced 208 prespecified model rows
and 14 moderator-support rows. In the primary common window, 24 of 48 fuzzy
interaction models passed every support and identification gate; eight of
those passing models belong to the two primary-moderator families. The
`rdhte` rows remain secondary assignment-effect estimates and are never marked
as passing the fuzzy-IV gate.

Within the 388-community complete analysis universe, 175 CMAN project records
through 2016 were linked: 54.9 percent productive livelihoods, 20.0 percent
community or civic infrastructure, 17.7 percent social or basic services, and
7.4 percent management or capacity support. The recorded-financing assignment
discontinuity has an `rdrobust` first-stage statistic of 13.55. All eight
exploratory financing-dose IV models share a Kleibergen--Paap statistic of
13.90 and an underidentification p-value of 0.0097, but none is significant at
five percent after Benjamini--Hochberg adjustment. These diagnostics do not
establish the additional exclusion restriction required for a causal dose
interpretation.

## Output contract

All outputs are aggregate and non-sensitive. Machine-readable results and
LaTeX tables are written under `output/tables/rd_heterogeneity`; figures are
written under `output/figures/rd_heterogeneity`. The level manifest is
`metadata/rd-heterogeneity-output-manifest-2017-ccpp.csv`.

The module generated 26 artifacts: 17 tables or machine-readable table files
and nine figures. The combined 2013--2017 manifest contains 89 unique
artifacts. Every artifact is marked `generated_unreviewed`; none has been
synchronized to Overleaf.
