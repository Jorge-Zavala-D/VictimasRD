# Data storage workflow

## Responsibility boundary

The Victimas RD project uses Dropbox for every dataset and Git for reproducible
code, non-observation metadata, documentation, and reviewed non-sensitive
tables and figures. A dataset must never be written anywhere inside the Git
checkout, including an ignored `build/` directory.

Machine-specific locations are defined in `config/paths.local.do`. Tracked
Stata programs use only those shared logical roots.

## Dropbox layout

```text
2 data/
|-- 1 Raw/
|   `-- 13 External administrative sources/
|       |-- 01 IGN centros poblados 2025/
|       `-- 02 OSIPTEL mobile coverage 2023/
|-- 2 Working/
|   |-- 0 Archive - legacy workflow through 2026-07-27/
|   `-- 1 Current pipeline/
|       |-- 01 intermediate/
|       |-- 02 staging/
|       |-- 03 qa/
|       `-- 04 external derived/
`-- 3 Coded/
    |-- 0 Archive - legacy workflow through 2026-07-27/
    `-- 1 Current analysis datasets/
```

Raw and archive folders are immutable. The canonical pipeline may replace only
reproducible products within the configured current Working and Coded folders.

## Multi-author execution

Only one collaborator should run a write-enabled pipeline at a time. Confirm
that Dropbox has finished synchronizing before starting and after completion.
Simultaneous runs can create conflicted copies even when the Stata code is
deterministic. Current Working and Coded products must never be edited manually;
changes come from versioned Git code and are rebuilt through the master.

## Product lifecycle

| Product | Destination |
|---|---|
| Scratch data needed only within one Stata run | Stata `tempfile` |
| Newly acquired immutable source | Dropbox Raw external-source folder |
| Converted external source | Dropbox Working `04 external derived` |
| Extracted or staged source representation | Dropbox Working `02 staging` |
| Persistent cleaned or linked intermediate | Dropbox Working `01 intermediate` |
| Row-level matching candidates and QA ledgers | Dropbox Working `03 qa` |
| Final cleaned or analytical dataset | Dropbox Coded current-analysis folder |
| Reviewed table or figure | Git `output/tables` or `output/figures` |
| Stata packages and non-data caches | Ignored Git `build/` |
| Logs | Ignored Git `logs/`, without row-level data |

## External-source intake

For each new external source:

1. record the authoritative publisher, source URL, retrieval date, logical
   role, format, and known restrictions in versioned metadata;
2. store the downloaded file under a descriptive Dropbox Raw subfolder;
3. verify the post-move checksum before treating the source as immutable;
4. store converted `.dta` files under Dropbox Working, never Raw or Git; and
5. reference the source through logical paths loaded from
   `config/paths.local.do`.

## Legacy archives

The dated Working and Coded archive folders preserve the prior workflow and
must not be executed as the current pipeline. They may be read as documented
candidate evidence. Any restoration or alteration of archived material
requires an explicit research-team decision.
