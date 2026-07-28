# Foundational community data preparation

## Purpose

`code/stata/pipeline/01_data_preparation.do` is the single authoritative data
preparation program for the project. Its first implemented milestone builds and
reconciles three foundational sources:

1. the 2017 INEI national directory of centros poblados;
2. the RUV Libro Segundo victimization registry; and
3. the CMAN list of collective-reparation projects recorded through 2023.

Dropbox Raw inputs are immutable. Run-specific scratch datasets use Stata
`tempfile`s. Persistent intermediates, staging data, matching candidates, and
review ledgers are written under `2 data/2 Working/1 Current pipeline`; the
final analytical registry is written under
`2 data/3 Coded/1 Current analysis datasets`.

The routine Stata master never launches Python, PowerShell, PDF conversion, or
another external process. The CMAN PDF and ReporteCCPP tables were extracted
once during source ingestion. Their shared CSVs and manifests are synchronized
Dropbox Working prerequisites that Stata validates before use.

The adjudication audit also uses dated and alternative CCPP directories. The
newly supplied sources under `2 data/1 Raw/11 Centros Poblados` are:

- the 2007 CCPP census workbook;
- the 2016 FAC national code workbook;
- 26 ReporteCCPP department downloads, of which one is a byte-identical
  duplicate;
- the GeoGPS/INEI shapefile and DBF;
- the 1993–2018 PBI CCPP panel; and
- the existing 2017 INEI department workbooks.

Two additional public official downloads remain under
`2 data/1 Raw/13 External administrative sources`:

- the Instituto Geografico Nacional national CCPP layer published 26 May 2025
  at `https://www.datosabiertos.gob.pe/dataset/dataset-centros-poblados`; and
- the OSIPTEL mobile-coverage register, whose June 2023 rows carry ten-digit
  INEI CCPP codes, at
  `https://www.datosabiertos.gob.pe/dataset/cobertura-de-servicio-m%C3%B3vil-por-empresa-operadora`.

## Source and identifier findings

- The RUV workbook contains 5,712 data rows and 25 source columns. `CodRUV` and
  `NroExp` are each unique.
- `UbigeoFinalDistrito` is a six-digit district UBIGEO. It is not a ten-digit
  centro-poblado UBIGEO. The 5,712 RUV communities therefore require their own
  CCPP-level linkage.
- The 26 departmental INEI workbooks encode a ten-digit CCPP identifier as a
  six-digit district UBIGEO followed by a four-digit CCPP code.
- The workbooks reconstruct to 94,922 unique CCPP records in 25
  department-level units and 1,874 districts.
- The INEI workbooks contain natural region, altitude, population by sex, and
  dwelling counts. They do not contain an urban/rural field. Rurality must not
  be inferred from a name or population threshold.
- The CMAN PDF contains 4,433 sequential records across 283 pages and 11
  columns. The extraction preserves every source field.

## CMAN treatment year

The research team has directed the pipeline to use the CMAN PDF year as the
authoritative collective-reparation treatment year. The program creates
cumulative indicators `treat_07` through `treat_23`: a linked community equals
one in its recorded year and every year thereafter.

After exhaustive reconciliation, RUV communities without a CMAN match
receive zero in every annual indicator. CMAN-only records are retained in QA
and sample-flow metadata but excluded from the RUV analysis dataset because the
2018-vintage RUV extract has no victimization measures for them. When more than
one CMAN project is linked to one RUV community, the first recorded project
year defines treatment onset and `cman_project_count` records the number of
projects.

## Linkage standard

The release standard is complete RUV retention with documented linkage status:

- every one of the 5,712 RUV source rows must remain in the foundational
  registry;
- a missing verified ten-digit CCPP UBIGEO must be flagged and reported but
  must never cause an RUV row to be dropped;
- CMAN records should receive a verified UBIGEO whenever the available evidence
  permits, whether or not they appear in the RUV extract;
- CMAN-only records and any residual unresolved CMAN records must be counted
  and retained outside the analysis dataset for audit;
- all accepted identifiers must satisfy the relevant key and district checks;
  and
- every non-exact-name resolution must retain its evidence, method, reviewer
  status, and code vintage in a separate adjudication ledger.

The program begins with normalized exact matching inside the full geographic
hierarchy. Candidate scores use multiple name metrics and geographic blocking,
but no score is accepted automatically. Candidate ledgers are evidence for
row-level adjudication, not substitutes for it.

The historical exact pass pools six source families and accepts a code only
when the normalized name is exact within district, every occurrence identifies
one code, and the code is not already assigned to another retained RUV record.
ReporteCCPP and the GeoGPS DBF are treated as one source family because they
reproduce the same 94,922-row INEI spine. Historical CMAN codes that contradict
a direct or verified RUV relationship are quarantined and documented.

Where names or administrative boundaries changed, adjudication should consult,
in order:

1. the supplied INEI workbooks;
2. other official INEI directories and code-consultation systems;
3. RUV and CMAN administrative records;
4. official legal, regional, provincial, or municipal records documenting
   creation, merger, renaming, or relocation; and
5. secondary web sources only as corroboration.

If a community has a historical code but no 2017 successor, the ledger must
distinguish the historical identifier from any current-code crosswalk. A
historical code must not be relabeled as a verified 2017 CCPP code.

## Validated foundational results

The complete run now produces:

- 3,986 deterministic exact RUV links in the 2017 directory;
- 936 accepted, versioned RUV adjudications, including 95 added through the
  new review pass;
- 198 automatic unique historical exact-name recoveries;
- 5,120 RUV communities with a unique, verified ten-digit CCPP UBIGEO and 592
  RUV communities retained without one;
- 4,343 current exact CMAN district paths plus 22 unique historical district
  recoveries, leaving 68 unresolved district paths;
- 3,123 CMAN CCPP matches in the current directory and 412 retained historical
  exact CCPP codes after nine contradictions were quarantined;
- 4,153 exact full-name CMAN-to-RUV links, 42 additional exact-UBIGEO links,
  and 42 accepted manual adjudications;
- 411 CMAN codes inherited from an already verified RUV link;
- all 4,433 CMAN source rows preserved, including 4,223 linked to RUV and 210
  CMAN-only rows;
- 3,946 CMAN rows with a verified CCPP code and 487 without one;
- 4,221 treated RUV communities and 1,491 RUV communities with no recorded
  CMAN project through 2023;
- two later repeated CMAN project rows collapsed after the earliest treatment
  year is retained; and
- complete treatment indicators and zero remaining accepted exact-link code
  conflicts in the 5,712-row foundational registry.

Historical or later-vintage codes that do not exist in the reconstructed 2017
spine do not receive 2017 population, altitude, natural-region, or dwelling
attributes from another community. Any analysis requiring those attributes
must report the resulting sample restriction.

The Dropbox Working QA tree contains row-level unresolved-linkage ledgers.
`metadata/ccpp-linkage/foundational-sample-flow.csv` contains the corresponding
aggregate counts, and
`2 data/3 Coded/1 Current analysis datasets/04_foundational_community_registry.dta`
is the validated, 5,712-row analysis-stage registry.

The next implemented milestone integrates the 2007 census baseline while
preserving this foundational registry unchanged. Its source audit, variable
construction, linkage rules, and outputs are documented in
[`docs/CENSUS_2007_PREPARATION.md`](CENSUS_2007_PREPARATION.md).

The subsequent milestone converts and integrates the 2017 CCPP point layers,
constructs map-ready spatial files and geodesic capital-distance measures, and
again preserves all RUV rows. See
[`docs/GEOSPATIAL_2017_PREPARATION.md`](GEOSPATIAL_2017_PREPARATION.md).

The complete source, matching, conflict, and final-flow record is maintained in
[`docs/CCPP_UBIGEO_RECOVERY_LOG.tex`](CCPP_UBIGEO_RECOVERY_LOG.tex).

Historical linked datasets are retained only as candidate evidence. They were
created through the legacy fuzzy workflow and cannot be treated as certified
crosswalks. An audit of the legacy 2017-census-linked file found:

- 5,287 RUV IDs with one legacy candidate code;
- 180 rows belonging to RUV IDs with more than one legacy candidate code;
- 164 unique legacy codes absent from the reconstructed 2017 INEI spine;
- 92 disagreements with the new unique exact-name linkage; and
- 459 legacy candidates whose code is outside the RUV-supplied district.

## Final variable contract

At every major milestone, the polished dataset keeps only:

- durable identifiers and substantively necessary provenance;
- geographic fields needed for interpretation and linkage;
- victimization measures;
- approved treatment and project fields;
- INEI attributes intended for analysis; and
- compact linkage-method fields needed for sensitivity analysis.

Temporary normalized strings, parser helpers, raw numeric copies, merge flags,
row counters, candidate scores, and detailed diagnostics are removed from the
polished dataset. They remain available in stage-specific Dropbox Working QA
artifacts so that the analysis dataset stays lean without sacrificing
auditability.
