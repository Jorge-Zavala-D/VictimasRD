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

Dropbox source materials are inputs, not repository contents. Original Dropbox
data must be treated as read-only. Do not copy data into Git, including through
Git LFS.

## Getting started

1. Read [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).
2. Copy `config/paths.example.do` to `config/paths.local.do`.
3. Edit `config/paths.local.do` for the local Git and Dropbox roots.
4. Keep the local path file untracked; `.gitignore` excludes it.
5. Write derived intermediates only to a designated local build area, never to
   a Dropbox raw-data directory.
6. Track a generated table or figure only after confirming that it is
   reproducible, appropriately sized, and non-sensitive.

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
|   `-- PROJECT_CONTEXT.md
|-- logs/
|-- metadata/
`-- output/
    |-- figures/
    `-- tables/
```

The initial directory README files describe what may be added to each area.
No data, legacy code, analytical results, or archived Dropbox outputs have been
migrated during repository initialization.

## Current release status

This repository is not yet an authoritative replication package. Before a
release, the research team must at minimum:

- define the canonical geographic sample;
- reconcile the official and manuscript victimization-index cutoffs;
- define the treatment event and whether the main date is 2012 or 2013;
- identify canonical community, household, and individual data snapshots;
- document the migration/linkage definition and sample flow;
- recover the editable source for the January 2026 manuscript;
- regenerate paper outputs through a single versioned pipeline; and
- complete data-access, ethics, licensing, and disclosure review.

Repository visibility should remain private until the research team approves a
release and its contents.
