# Census-based wellbeing and deprivation measures

## Status and purpose

This document defines the harmonization contract for census-based wellbeing
measures in Victimas RD. The authoritative data-preparation pipeline now
implements the contract for the 2007 CCPP aggregate workbook, SISFOH
2012--2013 household microdata, and the INEI-assisted Census 2017 linked
cohort. Round-specific differences remain explicit rather than being hidden
inside a common variable name.

The measures are intended for:

- pre-treatment covariates and RD continuity checks in 2007;
- descriptive comparisons;
- harmonized outcomes in 2013 and 2017; and
- sensitivity analyses that keep the component indicators visible.

They are not official poverty rates, monetary-poverty measures, household NBI
headcounts, or multidimensional poverty indices.

## Why the legacy score is replaced

The legacy `poverty2007*` variables averaged ordinal ranks assigned to
materials, services, assets, education, and labor outcomes. Higher values
generally represented better living conditions even though the variables were
named as poverty measures. The construction also:

- treated subjective ranks as if distances between categories were cardinal;
- mixed dwelling, household, and person universes without documenting them;
- allowed row means to change weights when components were missing; and
- combined structural living standards with outcomes such as employment and
  health-insurance coverage.

The useful legacy intuition—transparent aggregation without data-driven
weights—is retained. The arbitrary ranks and implicit reweighting are not.

## Identification limit of the 2007 source

The 2007 workbook reports separate CCPP-level marginal totals. It does not
show which deprivations occur together in the same household or person.
Official INEI NBI and multidimensional-poverty methods, as well as the global
MPI, identify poverty from simultaneous deprivations observed in common
microdata. Consequently:

- the pipeline cannot classify a household or person as poor;
- averages of CCPP prevalence rates cannot be called an MPI or NBI headcount;
- no poverty cutoff is applied to the ecological score; and
- the score must be interpreted as average community coverage, not the share
  of poor residents.

This distinction is especially important for RD work: the score can be a
baseline covariate or outcome, but it is not an official poverty estimand.

## Core harmonized score

Every input is scaled from zero to one, with higher values representing better
conditions. Indicators receive equal weight within a domain. The four domains
then receive equal weight:

| Domain | 2007 indicators | Domain formula |
| --- | --- | --- |
| Housing | Share of occupied dwellings without an earth floor | `1 - share_floor_earth_2007` |
| Basic services | Share with public/pylon water available every day; share using sewer, septic tank, or latrine | Arithmetic mean of the two shares |
| Energy | Share with electricity; share cooking with gas or electricity | Arithmetic mean of the two shares |
| Human capital | Literacy share age 14+; share age 14+ with secondary or higher education | Arithmetic mean of the two shares |

The canonical score is:

`wellbeing_core_2007 = (housing + services + energy + human capital) / 4`

`deprivation_core_2007 = 1 - wellbeing_core_2007`

Both have a zero-to-one range. A one-unit increase in the wellbeing score means
moving from no measured coverage to complete measured coverage across all four
equally weighted domains. The deprivation score is an exact reverse-coded
version for specifications where a higher value should represent worse living
conditions.

The basic-services water input uses the number of occupied dwellings reporting
public-network or pylon water every day divided by all occupied dwellings. It
does not claim 24-hour availability, adequate chlorination, or safe water. The
sanitation input records a reported facility; the aggregate source cannot
verify whether a latrine is safely managed or shared.

## Supplementary domain scores

Two scores remain separate from the core:

- `wellbeing_assets_2007` is the equal-weight mean of household coverage with
  a television, washing machine, refrigerator, and computer.
- `wellbeing_connectivity_2007` is the equal-weight mean of household coverage
  with a mobile telephone, internet, and cable television.

These measures are useful outcomes but are not folded into the structural core
because the meaning and diffusion of technologies change quickly across
census rounds. Fixed telephones are excluded from the connectivity score
because mobile substitution makes an equal-weight fixed/mobile average
difficult to interpret over time. The component shares remain available for
sensitivity analysis.

## NBI-compatible diagnostics

The pipeline retains the observable marginal NBI ingredients rather than
inventing a household NBI count:

- `share_floor_earth_2007` measures the earth-floor prevalence.
- `share_sanitation_none_2007` measures the share reporting no sanitation.
- `nbi_wallfloor_lb_2007` and `nbi_wallfloor_ub_2007` are Fréchet bounds for
  the wall-floor part of INEI's inadequate-housing condition.

For the bounds, let `A` be the share with woven-mat walls, `B` the share with
earth floors, and `C` the share with quincha, stone-and-mud, wood, or other
walls. The wall-floor condition is `A OR (B AND C)`. Because wall and floor are
separate marginals:

- lower bound: `A + max(0, B + C - 1)`;
- upper bound: `A + min(B, C)`.

The bounds exclude the separate improvised-dwelling condition because the
available dwelling-type table has a different universe and cannot be joined
to the occupied-dwelling wall/floor records. No midpoint is imputed.

No overcrowding rate or persons-per-room proxy is constructed. The source
population total includes a broader universe than the private
occupied-dwelling room measure, and the workbook does not report their joint
distribution. Dividing those fields produces invalid outliers and cannot
recover the share of households above INEI's overcrowding threshold.

## Missing values and aggregation

A domain is missing unless every component is observed. The core score is
missing unless all four domains are observed. The code never uses a partial
row mean and never changes weights because a component is unavailable.
Zero-denominator source shares remain missing rather than being recoded as
zero.

The score is constructed at CCPP level. Descriptive estimates for people,
households, or dwellings must use an explicit, substantively appropriate
weight; the pipeline does not embed a population weight in the score itself.

## Cross-round implementation

Every round must:

1. preserve the same direction, domains, indicators, and equal weights;
2. use equivalent question wording and analytical universes where possible;
3. record any source-round difference before calculating the score;
4. require complete components rather than silently reweighting;
5. keep the component variables alongside the score; and
6. avoid labeling the result as an official poverty rate.

If a component cannot be reconstructed comparably in a later round, the team
must choose and document either a common reduced index for all rounds or a
round-specific supplementary score. The canonical definition must not change
silently.

The SISFOH services domain is named
`wellbeing_services_proxy_2013` because the source identifies a public or
pylon water source but does not reproduce the 2007 daily-availability
condition exactly. The corresponding core and deprivation measures retain the
same `_proxy_2013` qualification. This is a transparent approximation, not an
exactly harmonized replacement.

The 2017 person and source-household files retain the component domains and a
level-appropriate core. In the source-CCPP file, housing, services, and energy
are source-household-weighted, while human capital is person-weighted among
eligible linked cohort members. The four resulting domain means receive equal
weight in `wellbeing_core_2017`; `deprivation_core_2017` is its exact reverse.
Person-weighted household-condition exposure and a household-weighted
alternative core remain separately named diagnostics. These measures describe
the assisted linked cohort, not the complete 2017 population of each CCPP.

## Methodological anchors

- INEI, *Metodología para la Medición de la Pobreza en el Perú*: the NBI
  approach uses five household deprivations and reports the population in
  households with at least one NBI.
  <https://www.inei.gob.pe/media/MenuRecursivo/metodologias/pobreza01.pdf>
- INEI, *Metodología de la Medición de la Pobreza Multidimensional – Avance
  (Revisión 2025)*: identifies simultaneous deprivations, distinguishes
  proxies from alternative indicators, and includes housing, services,
  energy, education, and connectivity.
  <https://cdn.www.gob.pe/uploads/document/file/7710254/6524650-informe-tecnico-de-pobreza-multidimensional-avance-revision-2025.pdf>
- INEI, *Perfil de la Pobreza por dominios geográficos, 2004–2012*: defines
  the five NBI components and the wall-floor inadequate-housing condition.
  <https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1106/libro.pdf>
- UNDP and OPHI, *2024 Global Multidimensional Poverty Index Technical Note*:
  constructs deprivation scores from household microdata and assigns equal
  weight to dimensions.
  <https://hdr.undp.org/sites/default/files/publications/additional-files/2024-10/2024_gMPI_TechnicalNote_1.pdf>
- WHO/UNICEF Joint Monitoring Programme, *Methodology: 2017 Update and SDG
  Baselines*: distinguishes facility type from basic or safely managed
  service, which also requires information unavailable in the 2007 aggregate
  table.
  <https://washdata.org/sites/default/files/documents/reports/2018-04/JMP-2017-update-methodology.pdf>
