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
- rejects any derived-data destination inside Dropbox Raw or Git;
- creates approved current-pipeline destinations in Dropbox Working/Coded;
- installs missing anticipated user-written commands into `build/ado`;
- selects a verified academic graph scheme with a built-in fallback; and
- calls the ordered modules documented in
  [`pipeline/README.md`](pipeline/README.md).

The implemented `pipeline/01_data_preparation.do` module is enabled for
push-button reproduction. It is the single authoritative preparation program
and currently implements the foundational INEI, RUV, and CMAN workflow. Later
source families will be added as sections of that same file. Analysis switches
remain disabled while substantive design decisions are open.

## Legacy snapshot

`legacy-current/` is a provenance-preserving historical snapshot. It contains
stale paths, unsafe raw-directory writes, conflicting specifications, and
incomplete orchestration. Do not edit it or use it as the canonical pipeline.
New programs belong under `pipeline/` and may consult the legacy code only as a
documented reference.
