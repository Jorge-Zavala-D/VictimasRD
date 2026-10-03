# Observed Stata environment lock and reproducibility boundary

The batch and independent closeout review are recorded in
[the whole-manuscript environment audit](WHOLE_MANUSCRIPT_ENVIRONMENT_AUDIT_2026-10-03.md).
The reviewed CSV has literal CRLF bytes. Cross-machine checkout/restoration
must preserve those bytes or adopt a separately tested file-specific Git
line-ending contract; normalization is not a reason to relax the fingerprint
gate. Current restoration and acceptance checks are same-machine only.

This milestone replaces the master's floating package bootstrap with a native,
fail-closed preflight. It does not change a sample, treatment horizon, outcome,
estimator, bandwidth, weight, clustering choice, multiplicity family or result.

## What is locked

The Stata MCP reports Stata 19, Windows 64-bit, build **12 August 2026**, with
flavor reported as IC. The installed program folder contains MP-named engine
components. Those installation fingerprints are recorded without asserting that
they independently identify the executable hosting the MCP session. Flavor is
reported metadata, not a new statistical specification or an edition gate.

The versioned file manifest contains **13,223** rows:

- **267** project executable/support files, including ADO and Mata sources,
  compiled objects/libraries, plugins, schemes and styles;
- **12,954** files in the licensed installation's official BASE tree; and
- **2** installed engine components.

Only relative filenames, byte lengths, release comments where available,
checksums, hashes and source-tracker metadata enter Git. No installed software,
example dataset, proprietary binary, license file, credential, or research
observation is copied into Git. Official example-data filenames/hashes in the
BASE inventory are metadata, not redistributed datasets. The complete manifest
is about 2.76 MB and is deliberately more conservative than a top-level-command
list.

`metadata/stata-runtime-lock-2026-10-03.json` records the observed runtime and
manifest identity. Release comments are descriptions, not substitutes for byte
identity. Recorded installer sources may be floating URLs or historic tracker
entries; they are **not** promises that a fresh download recovers these bytes.
Unassigned installed support is explicitly marked rather than attributed to an
invented source.

## Native master behavior

`code/stata/00_master.do` sets project PLUS, discards loaded ADO programs,
removes SITE/current-directory/PERSONAL/OLDPLACE search roots, and runs
`code/stata/lib/00_validate_environment.do`. Only BASE and project PLUS may
resolve code. The master already clears Mata; its cold-session library index
and synthetic IV/RD/density/density-plot checks remain intact.

The guard validates the manifest's reviewed native checksum/length, runtime
version/build/platform, all recorded file checksums/lengths, project dependency
resolution, and the cache's flat-directory/executable inventory. It stops before
any downstream analysis if a check fails. No package download, upgrade, fallback
scheme, or external process is used to make a failing lock pass. The cache
contains the exact previously resolved `spmap`, `shp2dta` and `gr0070` files;
44 shared-package files were copied, with original shared installations left
unchanged. `plotplainblind` now resolves locally and is part of the lock.

The checker uses a disposable Stata frame. Standalone success and failure checks
preserved the caller's data, variable label, dataset characteristic, observation
order and exact regression coefficient. A standalone checker does not certify
an already loaded foreign Mata environment; use the **master entry point** for
the cold-session execution contract. Direct calls that bypass the master do not
inherit its environment certification.

Native Stata checksums are drift checks, not cryptographic authenticity proofs.
The separate, read-only `code/python/check_stata_environment_lock.py` verifies
SHA-256 identities and recursive inventories. It is a maintenance/release check,
**never a process invoked from routine Stata**. Supply local configured package
and installed-Stata roots to its `--ado-root` and `--stata-root` arguments.

## Evidence and tests

Fresh Stata-MCP execution accepted the full lock and completed the actual master
with every pipeline switch zero. Its two-endogenous IV, robust RD, formal density
and density-plot compatibility checks passed. No research estimation module ran.
The durable local master receipt records return code zero; ignored master logs
contain the complete preflight/smoke path.

Negative native tests rejected a modified manifest, changed package bytes,
missing package file, extra executable, nested unlocked cache and an extra
search-path root. Tests first exposed the nested-directory and empty-extra-path
holes; the repaired guard rejected both and accepted the canonical environment
again. A quotation-handling defect encountered while repairing path validation
was corrected and retested. An initial state-test comparison rounded a local
numeric macro; exact scalar storage corrected that test harness, without a
production-data or estimator change.

Offline behavioral tests cover exact bytes, equal-length mutation, absence,
traversal, duplicate resolution names, an empty lock and unlisted executable
files. The native runtime mismatch branch was not exercised on a different
installed Stata build, and no global installation was modified to simulate one.

An ignored, local-only project-package archive preserves the current cache and
was restored to a separate local directory for exact-byte checks. It contains
software only. This demonstrates **local restoration**, not portability on
another machine or permission to distribute third-party code.

## Updating or restoring dependencies

If preflight fails, inspect the named mismatch before analysis. Restore the exact
reviewed cache/software installation if available and licensed. Do not change a
checksum, remove a row, weaken the guard, or upgrade a package solely to get a
pass. A deliberate version change requires a separately documented change,
compatibility tests, assessment of affected research outputs, a regenerated
reviewed manifest and its native pin, and an updated runtime record.

The private package archive is ignored and not a public replication deposit.
Cross-machine restoration, platform/edition differences, software licensing,
third-party redistribution and a complete raw-data replication remain release
work. The observed lock is prospective: historic output manifests did not record
every dependency hash, so historical engine/package identity is **not certified**.
Current scientific artifacts remain frozen, with generation-time holds intact.

## Source verification

Stata distinguishes its ADO release comment from its `version` language statement:
[official Stata explanation](https://www.stata.com/support/faqs/programming/release-marker-versus-version-number/).
Neither alone locks an installed file's content. Native return values and search
resolution were verified through the running Stata MCP, including `checksum`,
`findfile`, `c(adopath)` and `sysdir`; the web manual fetch was unavailable.

Publisher-wide guidance permits a data-availability statement explaining access
constraints: [Elsevier data statements](https://www.elsevier.com/researcher/author/tools-and-resources/research-data/data-statement).
World Development's live Guide for Authors returned 403 in this check; no fresh
journal-specific length, deposit or artwork-compliance certification is inferred.
