# Census 2017 preparation contract

## Purpose and analytical universe

The authoritative Census 2017 block is Section 13 of
`code/stata/pipeline/01_data_preparation.do`. It creates individual-,
source-household-, and source-CCPP-level analytical files while preserving the
complete RUV universe in the final CCPP registry.

The block has two distinct source roles:

1. The official national public person, household, and dwelling modules verify
   national row counts, key fields, and the Census questionnaire schema. Their
   public geography stops at district level, so they cannot identify the RUV
   CCPPs.
2. `CCPP_SISFOH_CPV_ENTREGAOKA.dta` is the INEI-assisted linkage supplied to
   the research team. It begins with 193,376 people in 807 historical source
   CCPP codes and attaches Census 2017 records when INEI's linkage succeeded.
   This restricted cohort, not the public national files, supports the CCPP
   analysis.

The Census outputs therefore describe the linked 2013 source cohort. They are
not full 2017 resident-population tabulations for the 803 represented RUV
communities, and they must not be interpreted as such.

## Source contract

The immutable Dropbox Raw sources are:

- `16 Censo 2017/1-pob.dta`: official public person module, 29,381,884 rows;
- `16 Censo 2017/2-hog.dta`: official public household module, 8,283,285 rows;
- `16 Censo 2017/3-viv.dta`: official public dwelling module, 10,133,850 rows;
- `16 Censo 2017/CCPP_SISFOH_CPV_ENTREGAOKA.dta`: INEI-assisted linked
  cohort, 193,376 source people; and
- `16 Censo 2017/EnlaceCCPP-SISFOH_CPV.docx`: INEI's technical handoff.

The public modules carry anonymous module IDs and district geography. The
pipeline validates their schemas without loading their billions of cells or
attempting an impossible CCPP merge. The assisted file contains restricted
linkage identifiers; none is retained in the final coded datasets.

The handoff is internally inconsistent about an early requested-community
count (899 in one passage and 889 in another). The auditable delivered data
contain 807 source CCPP codes, which is the implemented universe.

## INEI linkage and attrition

The technical handoff describes four linkage stages. The pipeline reproduces
their counts exactly:

| Stage | Method summarized from the handoff | People |
| --- | --- | ---: |
| 0 | Document/name/date-of-birth/sex deterministic linkage | 128,908 |
| 1 | Additional deterministic demographic linkage | 7,433 |
| 2 | Probabilistic linkage followed by threshold review | 10,530 |
| 3 | Manual resolution | 3,993 |
| Total linked | Any of stages 0--3 | 150,864 |
| Not linked | No attached Census record | 42,512 |

Every source person remains in the individual file. `census2017_not_linked`
means only that no Census record was attached. It is never coded as migration,
death, absence, or treatment response. The legacy combined measure is retained
only as the explicitly named sensitivity variable
`moved_or_not_linked_sens_2017`.

Because linkage is incomplete, outcome analysis must report linkage rates and
test differential linkage by treatment assignment, running variable, and
baseline covariates. Complete-case RD estimates alone do not resolve this
selection risk.

## Source CCPP crosswalk

`metadata/census-2017/source-ccpp-crosswalk.csv` maps all 807 historical source
codes to 803 canonical RUV rows. The crosswalk was built from exact legacy RUV
geographic paths and the supplied victimization score, then compared with the
current deterministic SISFOH-to-RUV map.

Most codes agree across both sources. Fifty-eight require the exact historical
path because the source code changed, and one code (`0905020049`) is resolved
by the exact historical path and victimization score rather than its current
code association. Four RUV rows legitimately receive two historical source
codes. The pipeline treats this reviewed file as a versioned adjudication, not
as a fuzzy match.

## Recovering canonical SISFOH IDs

The INEI delivery retained source roster coordinates but not the pipeline's
de-identified SISFOH IDs. During the SISFOH block, the pipeline writes a
restricted key spine to Dropbox Working as
`25_sisfoh_2013_person_linkage_keys.dta`. It contains no names, document
numbers, or open text.

The Census block then applies three deterministic passes in order:

1. historical source CCPP plus dwelling, household, and person roster number;
2. INEI source CCPP plus the same roster coordinates; and
3. a unique district/roster/age/sex key.

The first pass recovers 191,832 people, the second 442, and the third 165.
The remaining 937 source people are retained without a forced canonical
person match. Their source-round age, sex, relationship, education, labor,
insurance, disability, and program fields provide transparent fallbacks where
the coding universe is valid. A de-identified unresolved-key QA file remains
under Dropbox Working.

Five source households, containing 25 people, imply more than one canonical
SISFOH household ID across their recovered members. The pipeline does not
choose among those conflicting IDs. It retains the people and their individual
links, sets the household link to missing for all members of the affected
source household, flags the conflict, and reports it in the aggregate QA
ledger.

## Analytical levels

### Individual

`12_census_2017_individual_analysis.dta` has all 193,376 source-cohort people.
It combines the canonical CCPP/RUV/treatment context, recoverable SISFOH 2013
person measures, linkage status, Census 2017 person outcomes, current
household/dwelling conditions, and migration indicators. Direct and indirect
source linkage identifiers are removed.

### Source household

`13_census_2017_household_analysis.dta` has 58,021 de-identified 2013 source
households. It aggregates the source cohort rather than redefining households
around destination living arrangements. It records linkage rates, member
migration, outcomes among linked members, the number of destination households
and CCPPs, and whether members split across destinations. Where a source
household maps to the canonical SISFOH household, the full cleaned SISFOH
household measures are attached. This succeeds for 57,740 of the 58,021 source
households; the other 281 remain in the analytical file with the corresponding
SISFOH household fields missing.

### Source CCPP

`14_community_registry_census_2017.dta` retains all 5,712 RUV rows. Census
cohort outcomes are present for the 803 represented RUV communities and remain
missing elsewhere. Aggregates include the source-cohort size, linkage rate,
migration shares, demographic and socioeconomic outcomes, household
dispersion, NBI exposure, and harmonized wellbeing measures.

All 803 represented communities fall inside the fixed 1,162-community main RD
geography because the original INEI assistance request targeted the study
cohort. Census coverage is therefore not national coverage of the 5,712 RUV
communities and not complete coverage even within the selected geography.

## Migration definitions

Observed project migration compares the linked person's 2017 destination CCPP
with the canonical source RUV CCPP. Four nested outcomes are retained:

- different CCPP;
- different district;
- different province; and
- different department.

Each is missing when the Census link or a valid source/destination code is
missing. The independent Census five-year item is kept separately as
`moved_district_2012_2017`; it asks whether a person aged five or older lived
in another district five years before the Census and is not the same estimand
as source-cohort relocation from SISFOH.

Migration is observable for 146,410 linked people. Among them, 45,695 live in
a different CCPP, 33,067 in a different district, 22,926 in a different
province, and 18,860 in a different department. These are nested descriptive
counts from the assisted cohort, not population migration rates.

The assisted delivery may map one source household to multiple destination
households or CCPPs. The pipeline preserves this as a substantive migration
feature rather than imposing a single destination.

## Household completeness and NBI

The delivery contains 66,436 distinct destination households, but it is a
linked source cohort rather than a complete extract of every destination
household member. Comparing delivery rows with the Census household-size field
identifies:

- 27,276 complete destination rosters;
- 37,933 partial rosters;
- 1,223 destination households without a reported roster size; and
- 4 overfull inconsistencies, retained in a de-identified QA file.

The first three NBI components use household/dwelling fields. The school and
economic-dependency components require the full person roster and are
constructed only for complete, internally consistent destination households.
The five components follow INEI's definitions:

1. physically inadequate dwelling;
2. more than 3.4 people per room;
3. no sanitation service (river/canal, open air, or other);
4. at least one child aged 6--12 not attending school; and
5. a head with at most second grade of primary and at least four persons per
   employed member, or no employed member.

The 2017 wall category combines plywood, corrugated metal, and woven mat. The
inadequate-housing indicator therefore uses the closest observable proxy and
keeps the underlying components available. `nbi_count_2017` is missing unless
all five components are valid. It is not constructed from partial rosters.

## Harmonized wellbeing measures

The block follows `docs/CENSUS_WELLBEING_MEASURES.md`: higher values indicate
better conditions, indicators receive equal weight within domain, and the
four structural domains receive equal weight. The 2017 domains are housing,
basic services, energy, and human capital. Assets and connectivity remain
supplementary domains because their meaning changes rapidly across rounds.

At person level, household conditions are attached to linked members and the
human-capital domain is defined for people aged 14 or older. CCPP measures are
therefore linked-source-cohort measures, not official CCPP poverty rates.
Structural domains at CCPP level are averaged across source households;
human capital is averaged across eligible linked people. The final CCPP core
then gives the four domains equal weight, matching the 2007 ecological
construction as closely as the assisted cohort permits. Person-weighted
structural exposures and a source-household-weighted alternative core are kept
under explicit `cpv2017_*` names for sensitivity analysis. The pipeline never
labels the transparent score as monetary poverty, MPI, or an official NBI
headcount.

Age shares use five mutually exclusive bins (0--14, 15--29, 30--44, 45--64,
and 65 or older). Education and labor aggregates retain explicit eligibility
rules: the harmonized adult measures use age 14 or older, school attendance is
reported for ages 6--17, and unemployment is averaged only within the labor
force.

## Ana Maria Dumez workflow integration

The independent thesis workflow motivated the migration outcomes, internet
access, employment, transfer exposure, household dispersion, and mediation
variables. The new pipeline reproduces those analytical ingredients from the
audited source delivery while replacing the following legacy practices:

- using-only merge rows are not added to the source cohort;
- non-linkage is not treated as migration;
- CCPP outcomes are not calculated only among stayers;
- household denominators are explicit; and
- migration, linkage, current-household technology, and labor outcomes remain
  distinct variables.

Internet access and employment in 2017 are post-treatment and measured at or
near the migration outcome. They may support descriptive mechanism analysis,
but a conventional mediation regression does not by itself identify a causal
indirect effect. Any causal mediation estimand remains a research-team
decision and must be documented before analysis.

The file-level legacy and thesis audit, including the variables intentionally
not reproduced, is recorded in
`docs/CENSUS_2017_LEGACY_AND_DUMEZ_AUDIT.md`.

## Reproducibility and disclosure

All raw sources remain immutable. Persistent row-level products and QA files
stay in Dropbox Working; the three final analytical datasets stay in Dropbox
Coded. Git tracks only this contract, the source inventory, variable contract,
aggregate sample flow, and the reviewed source-CCPP crosswalk. No person or
household observations, identifiers, or restricted filenames are committed.

The pipeline asserts national module counts, source-cohort counts, linkage
stages, crosswalk coverage, person-key recovery, destination-roster status,
merge cardinality, analytical row counts, and retention of all 5,712 RUV rows.
The authoritative August 13, 2026 run and a separate post-run Stata audit both
completed with return code zero.

## Official reference points

- [INEI Census 2017 methodology](https://censo2017.inei.gob.pe/metodologia/)
- [INEI Census 2017 database access](https://www.gob.pe/institucion/inei/pages/24120-consultar-base-de-datos-de-los-censos-nacionales-2017-redatam)
- [INEI public database access](https://www.gob.pe/institucion/inei/pages/14307-consultar-bases-de-datos-del-inei)
- [INEI Census 2017 confidentiality FAQ](https://www.inei.gob.pe/preguntas-frecuentes/)
- [INEI NBI definitions](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1370/libro.pdf)
