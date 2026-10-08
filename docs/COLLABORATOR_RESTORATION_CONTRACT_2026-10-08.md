# Collaborator restoration contract

This is a fail-closed provisioning and acceptance contract for the **observed**
3 October environment. It is not an installer, historical generating-software
certificate, grant of access to restricted data, or proof of replication on a
second computer. Use it with the [environment lock](STATA_ENVIRONMENT_LOCK_2026-10-03.md)
and [data destinations](DATA_STORAGE_WORKFLOW.md).

## Components and permissions

| Component | Provisioning route | Required acceptance |
|---|---|---|
| Git code and metadata | Approved repository revision; keep this contract and .gitattributes | Clean revision, intact file lock, no unexpected research data |
| Stata | Collaborator's authorized installation, not a copied executable, BASE tree or license file | Windows 64-bit, Stata 19, build 12 August 2026; every recorded installed-file identity must match |
| Project PLUS cache | Rights-cleared exact package files from original sources or a permitted private handoff | All 267 executable/support identities, search resolution and inventory match |
| Public raw sources | Original custodians and documented project source manifests | Exact source identity and schema; public availability is not a redistribution license |
| Restricted inputs and linked delivery | Independently authorized INEI/CMAN/project access | Correct authorized delivery, source hashes and access-controlled storage |
| Converted prerequisites | Existing validated Dropbox Working staging products | Full extraction/schema/accounting checks; no conversion subprocess in routine Stata |
| Overleaf sources and inputs | Authorized synced publication project | Only reviewed inputs at recorded destinations; no datasets or logs |

The private software snapshot used in local tests contains 417 project-cache
files including help and installer-tracker files. It contains no Stata engine,
official BASE tree, research data or credentials, and **is not approved for
redistribution**. Package tracker URLs and release comments are provenance
leads, not guarantees that a fresh network download will recover exact bytes.

## Acceptance sequence

1. Obtain the approved Git revision and synchronize authorized Dropbox and
   Overleaf sources completely. Verify that only one collaborator will run a
   write-enabled pipeline. Do not use legacy dated archive files as substitutes.
2. Copy `config/paths.example.do` to ignored `config/paths.local.do`; set only the
   local Git, research Dropbox and publication roots. Leave Raw and archives
   immutable. Working/Coded destinations must obey the shared path contract.
3. Provision a licensed installation and the exact rights-cleared project PLUS
   cache under ignored `build/ado`. Never put binaries or data into version
   control. Do not solve a mismatch by reinstalling floating SSC packages.
4. Verify the manifest's working-tree identity:
   - SHA-256: `d010f2891149fc6e9026b3b501ca0ff0ad1b14087b8919c669e6532ae35e7616`;
   - bytes: `2755021`; native Stata checksum: `598622890`;
   - 13,223 records: 267 project files, 12,954 BASE files and two installed
     engine components.
5. Preserve `.gitattributes`: this one manifest uses `text eol=crlf`. Git stores
   a normalized LF blob but must restore the reviewed CRLF working-tree bytes,
   independently of `core.autocrlf`. No global Git setting change is required.
   Do not edit the checksum pin after a normalized or damaged checkout.
6. Run the read-only maintenance SHA-256 checker with the collaborator's local
   `--ado-root` and `--stata-root`. The checker performs no installation,
   research-data read or repair. The routine Stata master does not invoke it.
7. Through **Stata MCP `stata_run_selection`**, run `code/stata/00_master.do` with
   every empirical module switch zero. Inspect its complete log and final return
   code, not a partial MCP response. The master resets the session, permits only
   BASE and project PLUS, checks the native lock and runs synthetic compatibility
   tests. It must not open a shell or download software.
8. Only after this acceptance and authorized source checks may a collaborator
   enable a named empirical module. Keep logs private, keep data in Dropbox and
   treat all newly generated outputs as unreviewed until separately cleared.

## Failure and recovery

Stop on an unavailable source, changed byte identity, runtime mismatch, missing
dependency, extra executable cache file, nested cache directory or foreign code
search root. Retain the failure evidence. Recover the authorized exact bytes or
prepare a separately approved environment change with compatibility and
affected-result validation. Never weaken the guard, suppress the error or copy
another collaborator's license credentials.

The recorded MP-named installed components do not independently identify the
actual executable hosting the MCP session. Edition labels are descriptive,
not a new gate. macOS/Linux, a different Stata build and an ordinary up-to-date
installation are **not certified** by this Windows exact-byte contract.

## Tested boundary

The new behavioral test uses an isolated synthetic Git index, not the primary
index or a commit. It reproduces the existing normalized LF blob and checks
checkout under both `core.autocrlf=false` and `true`. Both must recover the exact
reviewed SHA-256 and byte length. The existing seven file-integrity tests remain
in force. Local private-cache restoration, native guard acceptance/rejection
and environment-only master evidence are recorded in the dated production
receipt; do not extend them into a claim about a second machine or a full raw
data rerun.

Acceptance on an actual collaborator machine remains a separately executed
check. Its receipt should identify revision, platform/build, manifest identity,
authorized input identity, checker result and complete master return code,
without serial numbers, credentials, raw observations or personal contact data.
