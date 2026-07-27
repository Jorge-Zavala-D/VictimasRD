# Foundational community data preparation

## Purpose

`code/stata/pipeline/01_data_preparation.do` is the single authoritative data
preparation program for the project. Its first implemented milestone builds and
reconciles three foundational sources:

1. the 2017 INEI national directory of centros poblados;
2. the RUV Libro Segundo victimization registry; and
3. the CMAN list of collective-reparation projects recorded through 2023.

All Dropbox inputs are immutable. Row-level staging data, matching candidates,
and review ledgers are written only to the Git-ignored `build/` tree.

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

Until every CMAN row is reconciled to the RUV universe, non-linked RUV rows
remain missing on these indicators instead of being mislabeled as untreated.
Once linkage is complete, communities absent from CMAN receive zero and the
release checks verify complete treatment-status coverage. The paper will state
the interpretation and caveats attached to the CMAN year field.

## Linkage standard

The release standard is complete coverage with documented provenance:

- every RUV row must have an adjudicated ten-digit CCPP UBIGEO;
- every CMAN project row must be reconciled to one RUV community;
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

## Current staging results

The first deterministic pass produces:

- 3,986 exact RUV-to-INEI links and 1,726 rows requiring adjudication;
- 4,343 exact CMAN district paths and 90 district paths requiring
  adjudication;
- 3,110 exact CMAN-to-INEI CCPP links and 1,323 rows requiring adjudication;
- 4,153 exact CMAN-to-RUV full-name links and 280 rows requiring adjudication;
  and
- zero UBIGEO conflicts where the two independent exact linkages coexist.

These are starting points, not acceptable final coverage rates. Until the
adjudication ledgers reach complete coverage, the program writes
`04_foundational_community_registry_draft.dta` under `build/derived`, removes
any stale release-named file, records release-blocking metrics, and exits with
an error.

The first reviewed adjudication batch adds 75 RUV-to-INEI CCPP links and 42
CMAN-to-RUV links. The current draft therefore has 4,061 RUV communities with
an INEI CCPP code and 4,195 CMAN projects reconciled to the RUV universe. The
remaining 1,651 RUV codes and 238 CMAN links continue to block release.

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
polished dataset. They remain available in stage-specific ignored QA artifacts
so that the release dataset stays lean without sacrificing auditability.
