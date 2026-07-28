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

The adjudication audit also used two public official sources. Their immutable
downloads are stored under
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

- 3,986 deterministic exact RUV links and 841 accepted, versioned
  adjudications;
- 4,827 RUV communities with unique, verified ten-digit CCPP UBIGEO codes;
- 885 RUV communities retained without a verified CCPP UBIGEO after the
  official 2017 and 2025 directories,
  legacy administrative crosswalks, OSIPTEL corroboration, geographic
  blocking, and manual review did not support a defensible code;
- 4,614 retained RUV codes with a 2017 vintage and 213 with a documented 2025
  vintage;
- 4,153 exact full-name CMAN-to-RUV links, 29 additional exact-UBIGEO links,
  and 42 accepted manual adjudications;
- 647 CMAN rows whose CCPP code is inherited from their already verified RUV
  link;
- 562 CMAN project rows linked by RUV ID to RUV communities without an
  RUV-side verified community UBIGEO;
- all 4,433 CMAN source rows preserved in the canonical CMAN registry, with
  115 code-less and 106 coded CMAN-only rows excluded from the RUV-master
  merge;
- 4,211 treated RUV communities and 1,501 RUV communities with no recorded
  CMAN project through 2023;
- complete treatment indicators for all 5,712 RUV communities;
- one community with two CMAN project records, for which the 2010 project
  establishes treatment onset and the 2021 project remains reflected in
  `cman_project_count`; and
- zero exact-link UBIGEO conflicts and zero missing treatment indicators in
  the 5,712-row foundational registry.

The 213 current-vintage CCPP codes do not exist in the reconstructed 2017
spine, so their 2017 population, altitude, natural-region, and dwelling fields
remain missing rather than being assigned from a different historical
community. Any analysis requiring those attributes must report the resulting
sample restriction.

The Dropbox Working QA tree contains row-level unresolved-linkage ledgers.
`metadata/ccpp-linkage/foundational-sample-flow.csv` contains the corresponding
aggregate counts, and
`2 data/3 Coded/1 Current analysis datasets/04_foundational_community_registry.dta`
is the validated, 5,712-row analysis-stage registry.

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
