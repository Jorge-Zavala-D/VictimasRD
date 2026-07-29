# 2007 census baseline preparation

## Purpose

The 2007 Population and Housing Census is the principal source of
pre-treatment community covariates. The authoritative preparation block lives
in `code/stata/pipeline/01_data_preparation.do`; it does not have a separate
canonical cleaner.

The block:

1. validates the supplied CCPP-level workbook;
2. assigns explicit names and analytical universes to the selected source
   fields;
3. checks every mutually exclusive category against its source total;
4. constructs transparent population, housing, service, demographic,
   education, labor, migration, and asset measures;
5. writes a reusable CCPP census milestone under Dropbox Working; and
6. links the census measures to the complete RUV-master registry without
   dropping any RUV observation.

## Source decision and limitations

The analytical input is:

`2 data/1 Raw/9 INEI/CCPP 2007.xlsx`

Its SHA-256 is
`c5121c8f5c9994437feacd9d028d4188592340b4b8d3cfb62809ae2af5f660a0`.
It is byte-identical to the copy under `2 data/1 Raw/11 Centros Poblados`
that was used as historical identifier evidence.

The original 2018 acquisition path cannot currently be reconstructed. The
workbook is consistent with an INEI CCPP-level aggregate export, but it is not
the complete national directory:

- `Hoja1` contains 259 columns and 45,677 unique ten-digit CCPP records;
- those records cover 22 departments;
- their population sums to 7,820,501 and their households to 1,919,129; and
- `Hoja2` has no CCPP key and is not treated as an independent source.

INEI reports 98,011 centros poblados for the 2007 census and a censused
population of 27,412,157. The supplied workbook therefore must not be described
as a complete national extract. It is suitable for the RUV study only to the
extent that a community links to one of its keyed records.

The official INEI census page points to the 2007 REDATAM and Datawarehouse
systems:

- <https://www.inei.gob.pe/estadisticas/censos/>
- <https://censos1.inei.gob.pe/Censos2007/redatam/>
- <https://ineidw.inei.gob.pe/ineidw/>

At the July 28, 2026 audit, the REDATAM and Datawarehouse endpoints did not
return a usable bulk CCPP-level download, and the current INEI Microdatos
catalog did not list the Population and Housing Census 2007 as a downloadable
survey. The supplied workbook is therefore retained as the current analytical
source with its scope limitation made explicit. If INEI provides a certified
bulk extract later, it should enter as a new immutable raw source and be
compared against this milestone before replacement.

## Variable construction

All proportions use a named source denominator:

- wall, floor, water, sanitation, electricity, and tenure use occupied
  dwellings with persons present;
- household assets and cooking fuel use households;
- sex, age, birth registration, disability, and insurance use population;
- language uses population age 3 and older;
- literacy, educational attainment, employment status, and labor-force
  participation use population age 14 and older;
- sector shares use employed persons;
- five-year migration excludes people not yet born from its denominator; and
- unemployment uses the labor force rather than total population.

The code verifies that every mutually exclusive category sums exactly to its
source total before calculating a share. Zero-denominator shares are missing,
not zero.

The legacy weighted `poverty2007*` variables are not reproduced. They assigned
subjective ordinal weights to marginal census shares, were not an official
INEI poverty or NBI measure, and in several cases were mislabeled.

The pipeline now constructs a transparent equal-domain ecological wellbeing
score, its reverse-coded deprivation score, housing/services/energy/human
capital domains, supplementary asset and connectivity scores, and
NBI-compatible diagnostics. These are community coverage summaries, not
official poverty headcounts. Their formulas, missing-value rules, limits, and
cross-round harmonization contract are recorded in
`docs/CENSUS_WELLBEING_MEASURES.md`.

An official poverty-map or household-microdata NBI measure can be added later
as a separately documented source. It must not be conflated with the
census-based ecological score.

## Linkage rules

The 2007 census link is distinct from the authoritative RUV CCPP identifier.
The pipeline never overwrites `ubigeo_ccpp`.

Linkage proceeds in this order:

1. exact ten-digit CCPP UBIGEO;
2. unique exact normalized department-province-district-CCPP path; and
3. unique exact normalized CCPP name within the supplied RUV district code.

Exact UBIGEO takes precedence. If an exact-name candidate points to another
2007 code, the exact-code link is retained and the disagreement is quarantined
under Dropbox Working QA. No fuzzy census match is accepted automatically.

The integrated file retains all 5,712 RUV rows. `census2007_linked`,
`census2007_link_method`, and `census2007_ubigeo_ccpp` identify the analytical
coverage and the historical code used to obtain the covariates.

## Outputs

The Stata program writes:

- Dropbox Working:
  `2 data/2 Working/1 Current pipeline/01 intermediate/04_census_2007_ccpp.dta`;
- Dropbox Coded:
  `2 data/3 Coded/1 Current analysis datasets/05_community_registry_census2007.dta`;
- Dropbox Working QA:
  `census2007_name_code_conflicts.*` and
  `census2007_unmatched_ruv.*`; and
- Git metadata:
  `metadata/census-2007/sample-flow.csv`.

The Working census milestone retains named source counts needed for future
weighted aggregation. The Coded RUV registry retains only core counts,
analytical covariates, and compact linkage fields.
