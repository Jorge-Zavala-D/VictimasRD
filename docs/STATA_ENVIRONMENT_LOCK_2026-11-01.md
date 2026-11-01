# Prospective Stata environment qualification — 1 November 2026

The user approved qualifying the installed build instead of downgrading the
shared installation. The active native guard now requires **Stata 19,
7 October 2026, Windows 64-bit** and the exact manifest
`metadata/stata-dependency-lock-2026-11-01.csv`. No package was installed,
upgraded or replaced. The 267 project PLUS executable/support identities match
the previous lock. The new observation records 12,966 official BASE files and
two installed engine files: 13,235 identities in total.

The historical 3 October manifest, runtime record, dependency-cache archive and
their documentation are preserved. This prospective lock is not a claim that
earlier results were generated with the current build.

## Compatibility evidence

The full candidate guard, exact cache inventory and search resolution,
cold-session Mata, two-endogenous IV, RD, density and density-plot smoke tests
passed. An in-memory copy of the unchanged master substituted only the
candidate environment check and enabled unchanged modules 04–06. It completed
at 19:25:12 local time on 1 November; the ignored master log is
`logs/master_1nov2026_181942.smcl`. A client transport timeout did not terminate
server execution; completion was confirmed from the closed log and idle MCP
session.

All 36 regenerated aggregate CSVs outside run-metadata contracts, comprising
4,598 rows, agree with the preserved baseline. Numeric comparisons use the
predeclared absolute tolerance 1e-8 plus relative tolerance 1e-7; missingness,
labels, statuses and model identities agree. This is compatibility evidence
for the existing 04–06 workflow, not proof of causal validity. The corrected
end-to-end master, including preparation and release boundaries, completed at
21:42:47. Its dataset, output and reporting reconciliations are recorded in
`STATA_CORRECTIVE_VALIDATION_2026-11-01.md`; technical reproduction does not
remove the remaining scientific or disclosure holds.

## Exact manifest and restoration contract

- SHA-256: `d15827937408ccb47bdeeb1130d2e24eeb3b2c41aac03183658cacaf9a1ddd28`.
- Native checksum: `4040754943`; bytes: `2770842`.
- The CSV's CRLF bytes are pinned in `.gitattributes`; checkout tests cover
  both `core.autocrlf=false` and `true`.
- The SHA checker defaults to the new lock. The native guard rejects a changed
  engine/BASE/cache before analysis and does not install or update software.
- Collaborators need their own licensed installation matching this lock and
  the byte-identical project dependency cache. The previous private cache
  archive remains applicable because those 267 identities did not change.
  Official engine/BASE files are not redistributed in Git or the cache ZIP.
- A different licensed build requires an explicit qualification decision; do
  not bypass or weaken the guard. Restricted datasets retain their existing
  access and Dropbox storage boundaries.

No other machine, concurrent write-enabled pipeline, historical binary
provenance, software redistribution, manuscript synchronization or public
release is certified by this qualification.

Descriptive-marker correction: a comparison of the 267 project rows detected
two release-marker strings that acquired an extra encoding roundtrip during
the candidate's native-checksum export. Their exact historical text was
restored, without changing any software identity, version, date or command.
The pre-correction prospective CSV is preserved privately. The final hashes
above identify the corrected UTF-8/CRLF manifest; the earlier 19:36 preflight
used its descriptive-text predecessor. The final literal preflight against the
corrected fingerprint passed at 21:19:48 and again after the full run at
22:00:00 (`logs/master_1nov2026_215714.smcl`). Unit tests
now check project-row descriptive metadata equality and JSON/guard/manifest
identity consistency as well as both checkout settings.
