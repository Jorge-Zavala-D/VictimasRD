# SISFOH 2012-2013 preparation contract

## Status and purpose

This note governs the preparation of the `sisfoh_persona.dta` and
`sisfoh_hogar.dta` files supplied to the project. The objective is to create
de-identified national milestone files in Dropbox Working and RUV-linked
analysis files at the person, household, and centro-poblado (CCPP) levels in
Dropbox Coded. The RUV community registry remains the master universe at the
CCPP level; no RUV row is dropped because SISFOH information is unavailable.

This operation is not a single-date population census. INEI describes it as
the *Empadronamiento Distrital de Poblacion y Vivienda 2012-2013*, conducted
from February 2012 through September 2013. Its purpose was to update the
household register and provide socioeconomic information for targeting social
programs. The fieldwork covered private dwellings and usual residents
nationwide, but participation was not compulsory and the official methodology
documents undercoverage and other fieldwork limitations.

## Authoritative background sources

- [INEI operation page and field instruments](https://www.gob.pe/institucion/inei/informes-publicaciones/3363542-empadronamiento-distrital-de-poblacion-y-vivienda-2013)
- [INEI technical sheet for the 2013 provincial and district poverty map](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/FichaTecnica/477-Ficha.pdf)
- [INEI 2013 poverty-map methodology](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1261/Libro.pdf)
- [INEI fieldwork and source-harmonization chapter](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1261/cap03.pdf)
- [MIDIS institutional history of SISFOH](https://www.gob.pe/43472-ministerio-de-desarrollo-e-inclusion-social-sisfoh)
- [MEF definition of the official NBI components](https://www.mef.gob.pe/es/?Itemid=100694&id=4856&lang=es-ES&language=es-ES&option=com_content&view=article)

The INEI technical sheet reports 8,336,891 household records, of which
6,609,570 contain information. The project files reproduce both totals exactly.
The person file contains 24,009,026 records, also matching INEI's published
fieldwork total.

INEI constructed an adjustment factor for nonresponse, household-size
understatement, and June/July 2013 population projections. That factor is not
present in the project extracts. The pipeline therefore reports unweighted
enumerated counts and within-CCPP shares and never represents them as adjusted
population totals.

## Immutable raw inputs

| File | Observations | Variables | Role |
|---|---:|---:|---|
| `sisfoh_persona.dta` | 24,009,026 | 71 | Authoritative person-level project extract |
| `sisfoh_hogar.dta` | 8,336,891 | 119 | Authoritative household/dwelling project extract |
| `ccpp_sisfoh2013.dta` | 41,436 | 626 | Legacy-derived CCPP compilation used only for reconciliation |

The CCPP compilation represents 22 departments, is 98.4 percent rural by row,
and sums to 6,553,299 persons. It is not used to construct the new SISFOH
analysis files. Its population, household, and NBI counts are compared with the
new microdata aggregation where codes overlap.

## Key and confidentiality contract

The raw `KEY` field is not a unique household identifier and must not be used
for linkage. The unique household key is the composite of department,
province, district, CCPP, scan sequence, conglomerate, dwelling number, and
household number. The person key adds the within-household person number.

The pipeline creates a deterministic numeric household identifier from the
sorted national household-key universe and assigns it to person records by an
exact many-to-one merge. It then drops names, document numbers, dates of birth,
addresses, telephone numbers, utility-supply numbers, signatures, fingerprints,
and all raw enumeration fields from persistent cleaned files. Generated IDs
and row-level records remain in Dropbox only and are never written to Git.

## Analysis universes and item response

- All 24,009,026 rostered people are retained in the national cleaned person
  milestone. Missing age and downstream person items remain missing.
- All 6,609,570 households with a complete or incomplete interview result are
  retained in the national cleaned household milestone. The pipeline stores an
  explicit complete-interview flag and item-specific coverage indicators.
- The housing, tenure, wall, roof, floor, lighting, water, and sanitation items
  are unavailable for 201,121 households with information. They are not
  imputed.
- Insurance, disability, social-program, and asset questions are
  multiple-response blocks. A blank option means `no` only after the pipeline
  verifies that the block contains at least one selected option or its explicit
  `none` response and that `none` is not selected with another option.
- Person questions use their instrument universes: marital status and pregnancy
  from age 12, education/literacy/language from age 3, labor from age 6, and
  sector only for employed people. Analytical rates use explicit eligible and
  item-valid denominators.

## Three-level construction architecture

1. **Person source.** Clean and de-identify the national roster; construct
   demographic, education, language, insurance, disability, labor, sector, and
   social-program measures; aggregate person information to households and to
   CCPPs.
2. **Household source.** Clean dwelling, services, fuel, assets, and interview
   timing; merge the person-derived household aggregates; construct official
   NBI and transparent wellbeing measures; aggregate household information to
   CCPPs.
3. **CCPP integration.** Combine person and household CCPP aggregates, link to
   the RUV registry by deterministic code or unique normalized full path, and
   preserve the complete 5,712-row RUV master universe.

The final person and household analysis files retain only SISFOH records linked
to a unique RUV community. They include the canonical RUV design and covariate
spine. The national de-identified milestones remain in Dropbox Working so that
coverage and alternative geographic analyses can be reproduced without
re-reading direct identifiers.

The verified August 11, 2026 run produced 24,009,026 national person rows,
6,609,570 national household rows, and 81,220 SISFOH CCPP rows. Deterministic
linkage connected 4,881 of the 5,712 RUV communities, including 1,033 of the
1,162 fixed geographic-sample communities. The linked analytical files contain
1,425,575 person rows and 415,007 household rows. The remaining 831 RUV rows
stay in the CCPP registry with missing SISFOH measures and a row-level QA file;
they are not recoded as observed zero outcomes.

## Official NBI construction

The five household indicators follow INEI's published definitions:

1. **Inadequate housing:** improvised dwelling; exterior walls made of matting;
   or earth floor combined with quincha, mud-set stone, wood, or other walls.
2. **Overcrowding:** more than 3.4 rostered people per occupied room.
3. **No adequate sanitation:** sanitation connected to a river/canal or no
   sanitation facility.
4. **School nonattendance proxy:** at least one child age 7-12 with no
   education or only initial education. INEI expressly adopted this proxy for
   SISFOH because the instrument did not ask current school attendance.
5. **High economic dependency:** the household head has at most two approved
   years of primary education and the household has no employed member or at
   least four people per employed member.

The pipeline reports each component, the count of components, any NBI, and two
or more NBIs only when all information required for the relevant indicator is
observed. It does not reproduce the legacy sequential recodes that could
overwrite one another or treat missing information as satisfaction.

## Wellbeing and cross-round comparability

The pipeline preserves the common 2007/2013 components that can be measured
consistently: earth floor, improved sanitation, public electricity, clean
cooking fuel, literacy at age 14 or older, secondary-or-higher education at age
14 or older, selected durable assets, and communication assets.

SISFOH identifies the source of water but does not ask whether public/pylon
water is available every day. The 2007 core services definition therefore
cannot be reproduced exactly. The 2013 services and core indices are explicitly
named `proxy`; they must not be interpreted as the approved cross-round core
wellbeing score without a research-team decision on the water-domain contract.
No official SISFOH Classification Socioeconomic, IFH, consumption, income, or
poverty status is reconstructed from undocumented coefficients.

## CCPP linkage rules

The source CCPP key is the ten-digit concatenation of department, province,
district, and CCPP codes. The raw household file contains 7,763 codes with more
than one distinct name/area/category record. The pipeline selects the most
frequent full descriptive record within each code. For the 133 codes tied at
the highest frequency, lexical order provides a deterministic
tie-break. Every alternative record, its frequency, and the selected row are
written to Dropbox QA; the ten-digit source code itself is never changed by
this descriptive reconciliation.

RUV linkage is attempted in this order:

1. verified canonical RUV CCPP code;
2. linked 2007 census code;
3. linked 2017 geospatial code;
4. linked Seminario-Palomino GDP-source code; and
5. a unique exact normalized department-province-district-CCPP name path.

At every stage a source code and an RUV row must each be uniquely assigned.
Same-priority conflicts are quarantined. Fuzzy matches are not accepted as
analysis links. Unmatched RUV rows are retained with missing SISFOH outcomes.

## Known source limitations to carry into analysis

- The long February 2012-September 2013 fieldwork window creates nonuniform
  outcome timing relative to treatment. Household and CCPP files retain valid
  interview dates so treatment timing can be aligned explicitly. A total of
  12,662 household records have a missing or invalid final calendar date; the
  component year, month, and day diagnostics are retained in aggregate QA.
- INEI characterizes the exercise as voluntary, de jure, and restricted to
  usual residents present for the preceding six months; foreigners and
  temporary residents were excluded.
- INEI documents limited prior publicity, requests for DNI/fingerprint and
  utility-account information, distrust, nonresponse, and a smaller household
  size than ENAHO and the 2007 Census.
- The raw adjustment factor used in the official poverty-map work is absent.
- Childhood-language coverage is substantially lower than the other person
  modules and is reported with a denominator/coverage measure.
- The three supplied files lack an acquisition note documenting the original
  transfer and extraction commands. Their SHA-256 fingerprints are recorded in
  `metadata/sisfoh-2013/source-inventory.csv`.
