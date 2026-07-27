# Stata code

This directory contains the entry point and structure for the clean, versioned
Stata pipeline.

Before adding or running code:

1. read `docs/PROJECT_CONTEXT.md`;
2. load machine-specific roots from `config/paths.local.do`;
3. treat all Dropbox inputs as read-only;
4. write intermediates only to a local ignored build directory;
5. add explicit input, key, merge, sample, and output checks; and
6. record final artifacts in the metadata output manifest.

## Entry point

Run the canonical master from the repository root:

```stata
do code/stata/00_master.do
```

Each collaborator must first copy `config/paths.example.do` to the ignored
`config/paths.local.do` and configure that local file. The shared master does
not contain usernames or machine-specific absolute paths.

The master:

- validates the Git, Dropbox-input, build, output, metadata, and log paths;
- rejects build or output roots outside the Git repository;
- creates only ignored Git-local build directories;
- installs missing anticipated user-written commands into `build/ado`;
- selects a verified academic graph scheme with a built-in fallback; and
- calls the ordered modules documented in
  [`pipeline/README.md`](pipeline/README.md).

All module switches initially remain zero. The first module,
`pipeline/01_data_preparation.do`, is now the single authoritative preparation
program and currently implements the foundational INEI, RUV, and CMAN source
workflow. Later source families will be added as sections of that same file.
Analysis switches remain disabled while substantive design decisions are open.

## Legacy snapshot

`legacy-current/` is a provenance-preserving historical snapshot. It contains
stale paths, unsafe raw-directory writes, conflicting specifications, and
incomplete orchestration. Do not edit it or use it as the canonical pipeline.
New programs belong under `pipeline/` and may consult the legacy code only as a
documented reference.
