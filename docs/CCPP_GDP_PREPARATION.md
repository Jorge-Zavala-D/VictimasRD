# Seminario-Palomino CCPP GDP preparation

## Purpose

Section 10 of `code/stata/pipeline/01_data_preparation.do` validates and
prepares the estimated CCPP GDP series supplied in:

`2 data/1 Raw/10 Nightlights/4. PBI_CentrosPoblados_1993-2018.xlsx`

The source is immutable. The pipeline preserves its complete annual series in
Dropbox Working, constructs transparent district aggregates, and merges a
compact set of pre-treatment economic-context variables and model-based 2013
and 2017 outcome candidates into the complete RUV registry. No RUV
observation is dropped because a GDP link is unavailable.

## Provenance and source audit

The workbook accompanies Bruno Seminario and Luis Palomino's 2022 Universidad
del Pacífico book, *Estimación del PIB a nivel subnacional utilizando datos
satelitales de luminosidad: Perú, 1993-2018*:

- publication record: <https://faculty.up.edu.pe/es/publications/estimaci%C3%B3n-del-pib-a-nivel-subnacional-utilizando-datos-satelital/>;
- DOI: <https://doi.org/10.21678/978-9972-57-493-1>.

The locked `PBI_CP` range contains 98,011 unique ten-digit CCPP codes, 1,833
districts, 25 departments, 26 annual columns from 1993 through 2018, and one
national-total row. The pipeline requires every keyed annual cell to be
nonmissing and nonnegative and reconciles every reported national annual total
exactly to the sum of keyed CCPP rows. The immutable file identity is recorded
in `metadata/gdp-ccpp/source-checksums.csv`.

The publication describes estimated real GDP in 1990 Geary-Khamis
international-dollar terms. The workbook itself does not embed a unit label
that establishes whether the numeric cells are dollars, thousands, or another
display scale. The pipeline therefore does not rescale the cells and labels
levels as `source units` until that remaining provenance detail is confirmed.

## Construction and analytical variables

The authors first construct district GDP using census, income, national
accounts, and night-lights information. CCPP GDP in the benchmark year is
allocated from district GDP using 2007 CCPP population shares; the annual CCPP
series is then extended using district growth and reconciled to district
totals. This implies two important limits:

1. within a district, the source's CCPP shares are effectively fixed by the
   2007 population allocation; and
2. a CCPP growth rate adds no independent local-growth information beyond the
   district growth series.

The full annual CCPP and district sources are retained outside Git as:

- `12_ccpp_gdp_1993_2018.dta`; and
- `13_district_gdp_1993_2018.dta`.

The final registry retains 1993 and 2006 levels as pre-treatment context and
2013 and 2017 levels as model-based outcome candidates. The 2006 value is the
final strictly pre-program annual value. Because 12,141 source CCPPs have zero
in every annual column, each analysis year includes both a natural log defined
only for positive estimates and an inverse-hyperbolic-sine transform that
retains zeros. The natural log is invariant to a multiplicative source-unit
rescaling, whereas the inverse hyperbolic sine is not; the latter is therefore
a zero-inclusive sensitivity transform until the workbook display unit is
confirmed. District pre-treatment growth is the annualized compound change
from 1993 through 2006:

`(GDP_2006 / GDP_1993)^(1/13) - 1`.

The district HHI and largest-CCPP share summarize how estimated economic
activity is distributed across settlements in the source. They are potentially
useful measures of settlement primacy or activity concentration. They are not
Gini coefficients, income inequality, poverty, household welfare, or evidence
about within-community distribution. A Gini is deliberately not constructed
from these aggregate CCPP totals.

No post-2006 CCPP growth, HHI, largest-settlement share, or other distribution
outcome is added. The source applies a common district growth path to every
CCPP and holds within-district CCPP shares fixed up to numerical precision.
Those derived variables would therefore relabel district growth or repeat a
mechanically time-invariant allocation rather than measure local growth or a
change in inequality.

## Deterministic RUV linkage

The GDP workbook uses a 2007-era CCPP universe. Its code is therefore retained
as `gdp_ccpp_ubigeo` and never overwrites the verified RUV `ubigeo_ccpp`.
Linkage proceeds in this order:

1. exact current RUV CCPP code;
2. unique, unused exact 2007 Census CCPP code;
3. unique, unused exact geospatial CCPP code;
4. unique exact normalized department-province-district-CCPP path; and
5. unique exact primary CCPP name within district after removing only a
   terminal parenthetical alias.

A source code already assigned through a higher-priority pass cannot be reused
by another RUV row. No probabilistic or fuzzy candidate is accepted. The
accepted row-level crosswalk is stored only in Dropbox Working as
`14_ruv_ccpp_gdp_links.dta`. The 19 accepted exact name-based links are also
exported with both source and RUV names to the configured row-level QA area;
unmatched rows are retained and exported there separately.

District linkage first uses the district embedded in an accepted source CCPP
code. Remaining rows use exact current, Census, or spatial six-digit district
codes and finally a unique exact normalized district path. District context
does not imply that a CCPP-level GDP estimate was found.

The validated August 4, 2026 run links 5,021 of 5,712 RUV rows at CCPP level
and 5,695 at district level. Within `sample_main_rd`, 1,045 of 1,162 rows have
a CCPP-level estimate and all 1,162 have district context. The 691 CCPP-level
and 17 district-level unmatched rows remain in the final registry with missing
GDP fields; no speculative match is substituted to increase coverage.

Aggregate linkage and retention counts are regenerated into
`metadata/gdp-ccpp/sample-flow.csv`. The final all-row analytical file is:

`2 data/3 Coded/1 Current analysis datasets/07_community_registry_gdp.dta`.

## Interpretation limits

These are model-based activity estimates rather than administrative production
records. The 1993 and 2006 measures are contextual covariates; the 2013 and
2017 measures are explicitly marked as outcome candidates, never as baseline
controls. All require sensitivity analysis and must not be described as
observed community income. The 2007 population allocation can mechanically
correlate community GDP with baseline population, while all post-2006 change
comes from the district series. Models should avoid simultaneously treating
highly collinear population, community GDP, and district totals as independent
constructs without a stated purpose.

The natural-log outcomes exclude the 13 linked RUV communities whose estimates
are zero in every source year, including four in `sample_main_rd`. The
inverse-hyperbolic-sine outcomes retain them but remain sensitive to the
unconfirmed source display unit. Any causal use still requires a locked
treatment horizon, administrative risk set, estimand, clustering rule, and
interpretation of the district-generated outcome before estimation.
