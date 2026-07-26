# Live Overleaf workflow

## Purpose and authority

The Dropbox-synced Overleaf project `Collective Reparations` is the live
publication workspace for this research project. Its machine-specific root is
configured as `overleaf_root` in the ignored `config/paths.local.do`.

The division of authority is:

- Git: versioned Stata code, non-observation metadata, tests, and canonical
  reproducible tables and figures.
- Research Dropbox: read-only data, literature, documents, historical
  materials, and archival outputs.
- Overleaf Dropbox: live manuscript, bibliography, presentations, and
  publication-facing copies of reviewed Git outputs.

Overleaf must never become a data, log, temporary-build, or confidential-output
destination.

## Audited project snapshot

A read-only audit on 2026-07-26 inspected all 76 files (4,053,384 bytes):

| Type | Files | Bytes |
|---|---:|---:|
| TeX | 9 | 170,263 |
| BibTeX | 2 | 42,359 |
| PNG | 49 | 3,279,934 |
| JPG | 16 | 560,828 |

The root contains `Working Paper.tex`, `Bibliography.bib`, and an older
bibliography. The `Presentations` directory contains three closely related
Beamer sources. The `Tables` directory contains five external TeX table
inputs. The `Images` and `Images APSA_2024` directories contain 65 graphics.
All graphics were hashed, dimension-checked, and visually reviewed. There are
59 unique graphic hashes and six exact duplicate pairs/groups.

No data files or PDFs are present in this Overleaf tree. No Dropbox file was
changed during the audit.

## Active working-paper dependencies

`Working Paper.tex` consumes these 15 graphics:

- `Images/number of financed communities.png`
- `Images/number of victimized communities by region.png`
- `Images/Distribution of the Victimization Index.jpg`
- `Images/average and median victimization 1.jpg`
- `Images/average and median victimization 2.jpg`
- `Images/percentage of financed communities.jpg`
- `Images/map financed communities 1.jpg`
- `Images/map financed communities 2.jpg`
- `Images/map financed communities 3.jpg`
- `Images/probtreat13_restricsample_sample2_v1.jpg`
- `Images/Density of the Index 1.jpg`
- `Images/Density of the Index 2.jpg`
- `Images/lpolyci_covs_restrictsample_sample2-altitude_msnm.jpg`
- `Images/lpolyci_covs_restrictsample_sample2-log_pob_ccpp_2007.jpg`
- `Images/lpolyci_covs_restrictsample_sample2-poverty2007_demogra.jpg`

It consumes these five external table files:

- `Tables/Main body/Main results - Formal continuity covariates tests.tex`
- `Tables/Main body/Main results - CCPP.tex`
- `Tables/Main body/Main results - Household.tex`
- `Tables/Main body/Main results - Individuals.tex`
- `Tables/Appendix/Appendix - Formal continuity covariates tests.tex`

The bibliography input is `Bibliography.bib`. At the audit snapshot, every
working-paper graphic and table input existed, all 36 cited bibliography keys
were present, and all manuscript references resolved after expanding the table
inputs.

## Git-to-Overleaf output procedure

For every Stata table or figure that is created, changed, or reviewed for use
in the paper:

1. Read `docs/PROJECT_CONTEXT.md` and resolve any specification or governance
   blocker that affects the output.
2. Run all Stata work through `stata_run_selection`.
3. Generate the canonical artifact directly into `output/tables` or
   `output/figures`; do not generate the only copy in Dropbox.
4. Inspect the rendered artifact for statistical, disclosure, formatting, and
   academic-presentation quality.
5. Record its producing code, logical inputs, specification, software
   versions, generation date, Git path, Overleaf destination, and checksum in
   the output manifest.
6. Resolve the exact destination used by `\input` or `\includegraphics`.
7. Copy the validated Git artifact to that Overleaf destination, replacing an
   existing file only when it is the intended manuscript input.
8. Verify that source and destination checksums match.
9. Recheck the affected TeX dependency and compile in Overleaf, or explicitly
   report when compilation could not be verified.

Use the same basename and extension in Git and Overleaf whenever practical. If
an extension or filename changes, update every affected TeX reference in the
same task.

## Manuscript edits

When a task requests a manuscript change, edit the live `Working Paper.tex` or
the relevant TeX/BibTeX input in the synchronized Overleaf project. Keep the
edit narrow, preserve UTF-8 encoding, inspect the exact diff, confirm that all
referenced files exist, and compile in Overleaf when possible. Do not copy raw
data or analysis intermediates into the manuscript tree.

## Known follow-up items

- All three presentation sources request
  `Images/percentage of financed communities.png`; only
  `Images/percentage of financed communities.jpg` exists.
- `Main results - CCPP.tex`, `Main results - Household.tex`, and
  `Main results - Individuals.tex` reuse the label `tab:rd_ccpp_main`.
- The abstract reports 5,713 registered communities and matched data from 2012
  and 2017, while the body reports 5,461 communities and linkage from 2013 to
  2017.
- `Working Paper.tex` uses `adjustwidth` without explicitly loading its
  defining package, and line 323 contains malformed prose.
- The main paper's title date is January 30, 2026, while its filesystem
  modification time is June 19, 2026.
- A local TeX engine was unavailable during the audit, so compilation still
  requires verification in Overleaf.
- Existing legacy figures have mixed visual styles and incomplete embedded
  notes. Regenerated figures must follow the publication standards in
  `AGENTS.md`; do not assume that an existing manuscript image is the style
  template.
