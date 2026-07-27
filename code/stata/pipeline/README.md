# Canonical Stata pipeline

This directory will contain the ordered, versioned Victimas RD pipeline called
by [`code/stata/00_master.do`](../00_master.do).

The expected modules are:

1. `01_inventory_sources.do`
2. `02_build_ccpp_spine.do`
3. `03_build_treatment_history.do`
4. `04_clean_sources.do`
5. `05_link_sources.do`
6. `06_build_analysis_data.do`
7. `07_describe_data.do`
8. `08_validate_rd_design.do`
9. `09_estimate_main_effects.do`
10. `10_run_robustness.do`
11. `11_analyze_migration_mechanisms.do`
12. `12_build_tables_figures.do`
13. `13_run_release_checks.do`

Modules will be added sequentially. They must:

- read machine-specific roots from the master-loaded local path configuration;
- treat all Dropbox sources as read-only;
- write intermediates only under the ignored Git-local `build/` tree;
- write reviewed final outputs only under `output/`;
- declare inputs, outputs, units of analysis, and expected merge cardinality;
- fail on unexpected keys, duplicates, merge results, ranges, or sample flow;
- emit non-observation metadata needed for provenance and validation; and
- avoid implementing unresolved sample, cutoff, treatment, linkage, or
  governance decisions without research-team approval.

The preserved `legacy-current` tree is historical evidence. Canonical modules
may use it as a documented reference, but must not modify or execute it as the
new pipeline.
