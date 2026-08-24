# National and selected-sample descriptive analysis

## Purpose

`code/stata/pipeline/02_describe_data.do` is the canonical descriptive module
for the Victimas RD project. It reads the final prepared community registry
from Dropbox Coded and describes both the complete 5,712-row RUV universe and
the fixed 1,162-community main RD geography.

The module is intentionally separate from RD-design validation and outcome
estimation. It uses the approved `sample_main_rd` flag but does not:

- search for, change, or optimize a geographic RD sample;
- search for a sample that maximizes a first-stage coefficient or minimizes a
  p-value;
- infer cutoff side from the rounded numerical score;
- run `rdrobust`, `rdplot`, density, balance, local-randomization, or placebo
  tests; or
- estimate treatment effects or mechanism models.

Those tasks belong in later modules after the research team resolves the
geographic sample, treatment timing, rounded-score ties, clustering, and
estimand.

## Inputs and samples

The community-level input is:

`2 data/3 Coded/1 Current analysis datasets/08_community_registry_elections.dta`

The module validates the 5,712-row RUV master, the unique `ruv_id`, the
official centered running variables, cumulative treatment coding through
2023, and the exact UBIGEO definition of `sample_main_rd`. Downstream linkage
gaps never remove an RUV row from national counts or sample membership.
Exhibits that require the 2007 Census, 2017 spatial source, CCPP GDP source, or
municipal political context report their nonmissing sample explicitly.

Project-content and financing exhibits use:

`2 data/2 Working/1 Current pipeline/01 intermediate/03_cman_projects_2023.dta`

Those outputs include all 4,433 CMAN project records, including 210 CMAN-only
rows that cannot enter the RUV-master analytical dataset. They therefore
describe the program register rather than the RUV analysis sample.

## Outputs

The module writes twenty-two figures to `output/figures/descriptive`:

1. complete and threshold-detail victimization-index distributions;
2. prevalence of positive RUV victimization components;
3. annual and cumulative collective-reparation rollout;
4. cumulative treatment coverage by RUV category;
5. a raw equal-frequency-bin treatment profile over the score;
6. department composition and treatment coverage;
7. foundational-source linkage coverage;
8. baseline wellbeing-domain means;
9. baseline wellbeing distributions by RUV category;
10. altitude and geodesic-distance context;
11. a 2017 CCPP point-location display;
12. victimized-community counts by department;
13. treated-community counts by department;
14. treatment coverage by department;
15. department mean and median victimization-index maps;
16. the distribution of primary CMAN project types;
17. cofinancing incidence and conditional amounts by project type;
18. cofinancing incidence and combined financing over the rollout; and
19. annual project composition across four broad project groups; and
20. cumulative treatment coverage and annual cohort composition by all five
    official victimization categories;
21. a province-level map of the selected legacy geographic rule; and
22. selected-versus-remaining RUV category composition and cumulative project
    coverage.

It writes eleven academic TeX tables to `output/tables/descriptive`:

1. foundational-registry coverage;
2. summary statistics;
3. category profiles;
4. annual treatment rollout;
5. department profiles;
6. project-type and financing profiles;
7. project financing by recorded year;
8. primary-category composition in 2007--2018 versus 2019--2023; and
9. cumulative treatment coverage by victimization category at selected years;
10. geographic composition, source coverage, and treatment timing within the
    selected sample; and
11. a descriptive selected-versus-remaining RUV comparison with standardized
    differences but no significance tests.

It also writes three aggregate CSV datasets:

- `output/tables/descriptive/rd_rollout_category_year.csv`, containing category
  denominators, cumulative coverage, newly linked project counts, and each
  category's share of the annual cohort;
- `output/tables/descriptive/rd_main_sample_geographic_profile.csv`, containing
  the four selected geographic components and their coverage; and
- `output/tables/descriptive/rd_main_sample_comparison.csv`, containing
  selected and remaining-universe means, nonmissing counts, and standardized
  differences.

Every output is regenerated from versioned code and recorded in
`metadata/output-manifest.csv` with its logical input, input data signature,
Stata version, generation date, checksum, size, disclosure status, and current
manuscript destination.

The coordinate point display is not a boundary map and is marked
`point_map_review_required`. The department and selected-sample province maps
use checksum-locked geometry from the preserved 2018 legacy map files. Their
original acquisition provenance is unresolved, so they are marked
`boundary_source_review_required` and cannot be publication outputs until an
official versioned boundary source verifies or replaces that geometry.

No descriptive output is synchronized to Overleaf until it has been reviewed,
assigned a manuscript destination, and processed under
`docs/OVERLEAF_WORKFLOW.md`.

## Legacy boundary

The legacy Descriptives program mixed national summaries with a preselected RD
geography, adjacent-category t-tests, RD outcome models, and migration
regressions. The canonical split is:

- `02_describe_data.do`: national and fixed-main-sample descriptions;
- `03_validate_rd_design.do`: first stages, score density, mass points,
  predetermined-covariate continuity, local-randomization diagnostics, and
  transparent geographic heterogeneity;
- `04_estimate_main_effects.do`: approved primary estimands at each outcome
  level;
- `04_estimate_main_effects.do`: outcome-specific bandwidth, donut-hole,
  specification, clustering, and weak-instrument sensitivities alongside the
  fixed-window main effects;
- `05_estimate_heterogeneity.do`: prespecified treatment-effect heterogeneity
  and bounded implementation extensions; and
- `06_analyze_migration_mechanisms.do`: migration and explicitly exploratory
  mechanism work.

Any future geographic exploration must report a predeclared, theory-grounded
candidate set and all resulting first stages. It must not choose the final
analysis sample solely from statistical significance or first-stage strength.
