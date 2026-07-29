# Canonical Stata pipeline

This directory will contain the ordered, versioned Victimas RD pipeline called
by [`code/stata/00_master.do`](../00_master.do).

The expected modules are:

1. `01_data_preparation.do`
2. `02_describe_data.do`
3. `03_validate_rd_design.do`
4. `04_estimate_main_effects.do`
5. `05_run_robustness.do`
6. `06_analyze_migration_mechanisms.do`
7. `07_build_tables_figures.do`
8. `08_run_release_checks.do`

`01_data_preparation.do` is the single authoritative Stata preparation
program. It is organized internally by source family and performs source
validation, cleaning, deterministic linkage, candidate generation, merge
auditing, and construction of analytical inputs. New data-preparation work
must extend that program instead of creating additional canonical preparation
do-files. Its foundational source contract, current linkage results, complete-
coverage release gate, and final-variable contract are documented in
[`docs/FOUNDATIONAL_DATA_PREPARATION.md`](../../../docs/FOUNDATIONAL_DATA_PREPARATION.md).
The dated multi-source UBIGEO recovery, rejected candidates, quarantined
conflicts, and final RUV--CMAN accounting are documented in
[`docs/CCPP_UBIGEO_RECOVERY_LOG.tex`](../../../docs/CCPP_UBIGEO_RECOVERY_LOG.tex).

`02_describe_data.do` is the canonical full-universe descriptive module. It
reads the final prepared community registry, preserves all 5,712 RUV rows in
the descriptive denominator, and generates aggregate tables and figures under
`output/`. It never defines an RD geography, estimates a discontinuity, tests
adjacent categories, or analyzes outcomes. The point-location exhibit is
explicitly marked for disclosure review before public release.

Modules will be added sequentially. They must:

- read machine-specific roots from the master-loaded local path configuration;
- treat Dropbox Raw and dated archives as immutable;
- use Stata `tempfile`s for run-specific scratch products;
- write persistent intermediates, staging data, and row-level QA under the
  configured Dropbox Working current-pipeline root;
- write final analytical datasets under the configured Dropbox Coded root;
- never write datasets anywhere inside Git, including ignored `build/`;
- write reviewed final outputs only under `output/`;
- declare inputs, outputs, units of analysis, and expected merge cardinality;
- fail on unexpected keys, duplicates, merge results, ranges, or sample flow;
- emit non-observation metadata needed for provenance and validation; and
- avoid implementing unresolved sample, cutoff, treatment, linkage, or
  governance decisions without research-team approval.

The preserved `legacy-current` tree is historical evidence. Canonical modules
may use it as a documented reference, but must not modify or execute it as the
new pipeline.
