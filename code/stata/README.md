# Stata code

This directory will contain the clean, versioned Stata pipeline.

Before adding or running code:

1. read `docs/PROJECT_CONTEXT.md`;
2. load machine-specific roots from `config/paths.local.do`;
3. treat all Dropbox inputs as read-only;
4. write intermediates only to a local ignored build directory;
5. add explicit input, key, merge, sample, and output checks; and
6. record final artifacts in the metadata output manifest.

The legacy working-paper code has not been copied here. Its preservation should
be a separate, exact-snapshot task with file-level source paths, dates,
checksums, status, known outputs, and warnings. Do not mix legacy preservation
with refactoring.

A future clean pipeline may use ordered modules for environment validation,
cleaning, construction, description, RD validity, estimation, mechanisms, and
tables/figures. The exact module design should follow research-team decisions
on the canonical sample, cutoff, treatment event, and treatment date.
