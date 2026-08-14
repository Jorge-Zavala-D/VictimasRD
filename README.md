# Victimas RD reproducible research code

This repository is the version-controlled home for the reproducible research
components of the Victimas RD project on Peru's Collective Reparations Program
(`Programa de Reparaciones Colectivas`, PRC).

The repository is being initialized from a research archive, not from a
finished replication package. The current analysis has unresolved differences
in its sample definition, assignment cutoffs, treatment timing, canonical data
snapshots, and paper-output provenance. See
[`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) before changing analysis
code or interpreting results.

## Repository and Dropbox responsibilities

| Location | Authoritative contents |
|---|---|
| This Git repository | Reproducible code, non-observation metadata, tests, documentation, and appropriately sized non-sensitive generated outputs |
| Dropbox research archive | Raw, working, coded, linked, confidential, restricted, or large data; literature; administrative and personal documents; historical materials; archival outputs |
| Synced Overleaf project | Live editable manuscript, bibliography, presentations, and publication-facing copies of reviewed Git-generated tables and figures |

Dropbox source materials are inputs, not repository contents. Original Dropbox
data must be treated as read-only. Do not copy data into Git, including through
Git LFS. The separately synchronized Overleaf tree is not a data destination;
see [`docs/OVERLEAF_WORKFLOW.md`](docs/OVERLEAF_WORKFLOW.md) for the controlled
Git-to-publication workflow. See
[`docs/DATA_STORAGE_WORKFLOW.md`](docs/DATA_STORAGE_WORKFLOW.md) for the shared
Raw/Working/Coded data contract.

## Getting started

1. Read [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).
2. Copy `config/paths.example.do` to `config/paths.local.do`.
3. Edit `config/paths.local.do` for the local Git, research Dropbox, and
   synchronized Overleaf roots.
4. Keep the local path file untracked; `.gitignore` excludes it.
5. Use Stata `tempfile`s for scratch products, Dropbox Working for persistent
   intermediates and QA data, and Dropbox Coded for final analysis datasets.
   Never write derived files to Dropbox Raw or anywhere inside Git.
6. Track a generated table or figure only after confirming that it is
   reproducible, appropriately sized, and non-sensitive.
7. For an output used in the paper, validate it in Git and then synchronize it
   to the exact Overleaf path recorded in the output manifest.

## Initial structure

```text
.
|-- AGENTS.md
|-- README.md
|-- code/
|   `-- stata/
|-- config/
|   |-- paths.example.do
|   `-- paths.local.do       # local and ignored
|-- docs/
|   |-- OVERLEAF_WORKFLOW.md
|   `-- PROJECT_CONTEXT.md
|-- logs/
|-- metadata/
`-- output/
    |-- figures/
    `-- tables/
```

The directory README files describe what may be added to each area. A
provenance-preserving legacy-code snapshot is present, but no raw research data
or unreviewed archival outputs belong in Git.

## Current data-preparation milestone

The authoritative pipeline now prepares the RUV victimization registry, CMAN
collective-reparation treatment history through 2023, selected 2007 Census
baseline covariates, 2017 CCPP geospatial attributes and capital-distance
measures, Seminario-Palomino pre-treatment CCPP and district GDP context, and
2002/2006 municipal political and electoral context from JNE/INFOgob and ONPE.
It also prepares the national SISFOH 2012-2013 person and household files,
constructs person-, household-, and CCPP-level outcomes, and links them to the
RUV community universe without dropping unmatched RUV rows. The pipeline now
also integrates the INEI-assisted Census 2017 cohort at individual,
source-household, and source-CCPP levels while keeping Census non-linkage
distinct from observed migration.
Run `code/stata/00_master.do` after configuring
`config/paths.local.do`.

Data products remain outside Git:

- the validated foundational RUV–CMAN registry is written to Dropbox Coded as
  `04_foundational_community_registry.dta`;
- the all-row registry with 2007 Census covariates is written to Dropbox Coded
  as `05_community_registry_census2007.dta`;
- the all-row registry with 2017 geospatial attributes and geodesic distance
  measures is written to Dropbox Coded as
  `06_community_registry_geospatial.dta`;
- the all-row registry with compact CCPP and district GDP covariates is
  written to Dropbox Coded as `07_community_registry_gdp.dta`; and
- the all-row analytical registry with municipal-election covariates is written
  to Dropbox Coded as `08_community_registry_elections.dta`;
- the RUV-linked SISFOH person and household files are written to Dropbox Coded
  as `09_sisfoh_2013_individual_analysis.dta` and
  `10_sisfoh_2013_household_analysis.dta`; and
- the current 5,712-row CCPP registry with SISFOH aggregates is written to
  Dropbox Coded as `11_community_registry_sisfoh_2013.dta`;
- the complete 193,376-person Census source cohort and 58,021 source households
  are written as `12_census_2017_individual_analysis.dta` and
  `13_census_2017_household_analysis.dta`; and
- the all-row RUV registry with Census linked-cohort outcomes is written as
  `14_community_registry_census_2017.dta`.

The Census, geospatial, GDP, municipal-election, and SISFOH source audits and
linkage rules are documented in
[`docs/CENSUS_2007_PREPARATION.md`](docs/CENSUS_2007_PREPARATION.md) and
[`docs/GEOSPATIAL_2017_PREPARATION.md`](docs/GEOSPATIAL_2017_PREPARATION.md),
[`docs/CCPP_GDP_PREPARATION.md`](docs/CCPP_GDP_PREPARATION.md),
[`docs/MUNICIPAL_ELECTIONS_PREPARATION.md`](docs/MUNICIPAL_ELECTIONS_PREPARATION.md),
[`docs/SISFOH_2013_PREPARATION.md`](docs/SISFOH_2013_PREPARATION.md), and
[`docs/CENSUS_2017_PREPARATION.md`](docs/CENSUS_2017_PREPARATION.md). The
historical Census and Ana Maria Dumez workflow comparison is in
[`docs/CENSUS_2017_LEGACY_AND_DUMEZ_AUDIT.md`](docs/CENSUS_2017_LEGACY_AND_DUMEZ_AUDIT.md).

## Current release status

This repository is not yet an authoritative replication package. Before a
release, the research team must at minimum:

- reconcile the approved legacy geography with the assignment regime and
  estimand used in the manuscript;
- address score rounding and mass points at the official victimization-index
  cutoffs;
- define analysis-specific treatment timing from the recorded CMAN treatment
  year;
- identify canonical community, household, and individual data snapshots;
- assess differential Census linkage and reconcile the documented cohort with
  manuscript sample counts;
- map every live manuscript input to its producing specification and canonical
  Git output;
- regenerate paper outputs through a single versioned pipeline; and
- complete data-access, ethics, licensing, and disclosure review.

Repository visibility should remain private until the research team approves a
release and its contents.
