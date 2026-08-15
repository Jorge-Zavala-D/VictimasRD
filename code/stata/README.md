# Stata code

This directory contains the entry point and structure for the clean, versioned
Stata pipeline.

Before adding or running code:

1. read `docs/PROJECT_CONTEXT.md`;
2. load machine-specific roots from `config/paths.local.do`;
3. treat Dropbox Raw and dated archives as read-only;
4. use Stata `tempfile`s for scratch data, Dropbox Working for persistent
   intermediates and QA, and Dropbox Coded for final analytical datasets;
5. add explicit input, key, merge, sample, and output checks; and
6. record final artifacts in the metadata output manifest.

## Entry point

Run the canonical master from the repository root:

```stata
do code/stata/00_master.do
```

Each collaborator must first copy `config/paths.example.do` to the ignored
`config/paths.local.do` and configure that local file. The shared master does
not contain usernames or machine-specific absolute paths. Once the local file
exists, the master may be opened in Stata's Do-file Editor and executed from
any working directory. It searches parent directories and standard Windows
GitHub locations automatically. A collaborator using a nonstandard clone
location can set the `VICTIMASRD_PROJECT_ROOT` environment variable to the
repository root.

The master:

- validates the Git, Dropbox Raw/Working/Coded, output, metadata, and log paths;
- validates and reads synchronized extracted source tables from Dropbox
  Working without launching Python, PowerShell, or an external console;
- rejects any derived-data destination inside Dropbox Raw or Git;
- creates approved current-pipeline destinations in Dropbox Working/Coded;
- installs missing anticipated user-written commands into `build/ado` and
  cold-session tests the official `rdrobust` ado/Mata installation;
- selects a verified academic graph scheme with a built-in fallback; and
- calls the ordered modules documented in
  [`pipeline/README.md`](pipeline/README.md).

The implemented `pipeline/01_data_preparation.do` and
`pipeline/02_describe_data.do` modules are enabled for push-button
reproduction. The first is the single authoritative preparation program; the
second produces full-RUV, selected-main-sample, and full-CMAN-project
descriptive tables and figures without reselecting the geography or estimating
treatment effects.

`pipeline/03_validate_rd_design.do` is implemented as a structured,
non-selective first-stage audit. It writes aggregate diagnostics but never
defines or changes `sample_main_rd`. The research-team-selected legacy
geography is created in data preparation. The exhaustive audit call is
bracketed out of the master, including `run_all`.

`pipeline/03b_validate_rd_assumptions.do` and
`pipeline/04_estimate_main_effects.do` are implemented as bounded routine
modules. The outcome orchestrator calls `pipeline/04a_sisfoh2013_ccpp.do`,
`pipeline/04b_sisfoh2013_household.do`, and
`pipeline/04c_sisfoh2013_individual.do`. All inherit adjacent B/C support,
`treat_12`, a common treatment-design bandwidth, weak-first-stage safeguards,
and versioned outcome registries. The CCPP module uses district-aware
inference; the household and individual modules give each assignment community
equal total weight, cluster by complete RUV community ID, and report
observation-equal, district, and score-mass-point sensitivities. These modules
remain switch-controlled; later 2017, dedicated robustness, and mechanism
modules are not yet implemented.

The CMAN PDF table and ReporteCCPP HTML tables are one-time source-ingestion
products shared through Dropbox Working. Their CSVs and extraction manifests
must already be synchronized before the master is run. The routine Stata
pipeline does not regenerate, erase, or overwrite them.

## Legacy snapshot

`legacy-current/` is a provenance-preserving historical snapshot. It contains
stale paths, unsafe raw-directory writes, conflicting specifications, and
incomplete orchestration. Do not edit it or use it as the canonical pipeline.
New programs belong under `pipeline/` and may consult the legacy code only as a
documented reference.
