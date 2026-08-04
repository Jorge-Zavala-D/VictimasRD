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
The title-based CMAN project taxonomy, multisector rule, and financing measures
are documented in
[`docs/CMAN_PROJECT_CLASSIFICATION.md`](../../../docs/CMAN_PROJECT_CLASSIFICATION.md).
The dated multi-source UBIGEO recovery, rejected candidates, quarantined
conflicts, and final RUV--CMAN accounting are documented in
[`docs/CCPP_UBIGEO_RECOVERY_LOG.tex`](../../../docs/CCPP_UBIGEO_RECOVERY_LOG.tex).
The Seminario-Palomino annual CCPP GDP source audit, deterministic
source-vintage linkage, district aggregation, and interpretation limits are
documented in
[`docs/CCPP_GDP_PREPARATION.md`](../../../docs/CCPP_GDP_PREPARATION.md).

`02_describe_data.do` is the canonical national and selected-sample
descriptive module. It reads `07_community_registry_gdp.dta`, the current final
prepared community registry, preserves
all 5,712 RUV rows in national denominators, describes the fixed
1,162-community `sample_main_rd` geography, and uses all 4,433 canonical CMAN
project records for project-type and financing exhibits. It generates
aggregate tables and figures under `output/`. It never changes the RD
geography, estimates a discontinuity, tests adjacent categories, or analyzes
outcomes. Point and legacy-boundary maps are explicitly marked for review
before public release.

`03_validate_rd_design.do` is the first-stage and design-diagnostic module. It
reports all four official cutoffs and every cumulative treatment year from
2007 through 2023 for 11 declared national, historical, VRAEM, and CVR
geographies and a bounded geographic heterogeneity atlas. The atlas includes
every nonempty subset of the seven-department conflict/VRAEM belt and every
nonempty subset of INEI's ten-province VRAEM study envelope, so groups of
three, four, five, and larger cells are fully reported inside independently
defined universes. It also compares adjacent-category and full score support
for all named candidates, exports compact all-year cutoff summaries, candidate
scorecards, and 384 pre-treatment
covariate-continuity cells, including the post-search three-department
statistical frontier. It never automatically selects or changes a sample and
does not write `sample_main_rd`; data preparation implements the separate
research-team decision. The default execution is serial. Internal `base`,
`province_chunk`, and `assemble` modes make the same 96,524-cell grid
resumable and permit disjoint Stata MCP sessions to write validated worker
files under Dropbox Working QA before one canonical assembly. These modes
change computation only; they do not change a sample, cutoff, horizon, or
specification. Its protocol, rollout reassessment, and team recommendation
are documented in
[`docs/RD_DESIGN_AUDIT_PROTOCOL.md`](../../../docs/RD_DESIGN_AUDIT_PROTOCOL.md),
[`docs/PRC_ROLLOUT_AND_RD_REASSESSMENT.md`](../../../docs/PRC_ROLLOUT_AND_RD_REASSESSMENT.md),
and
[`docs/RD_DESIGN_RECOMMENDATION.md`](../../../docs/RD_DESIGN_RECOMMENDATION.md).
Because the audit is computationally intensive, its master invocation is
commented out, including under `run_all`; regeneration is an explicit
standalone Stata MCP task.

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
