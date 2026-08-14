# Census 2017 legacy and Dumez workflow audit

## Scope

This audit records how the current Census 2017 preparation block relates to
the historical project code and Ana Maria Dumez's independent thesis workflow.
It is a provenance and methods record, not a validation of the historical
estimates.

The review covered:

- the legacy `0h. clean_censo2017.do` public-module cleaner;
- the working-paper `0j. clean_INEI.do` linked-cohort cleaner and its
  community-, household-, and individual-level downstream files;
- `Datos/Creacion de nuevas variables.do` and its three large derived person
  files in the independent working-paper tree; and
- the attrition, household migration, moderation, alternative mediation, and
  consolidated estimation programs in `Do files- Estimaciones`.

The historical files remain immutable evidence. Their constructed datasets
and results are not inputs to the authoritative pipeline.

## What the historical workflows were trying to do

The legacy public-module cleaner prepared the national 2017 person,
household, and dwelling files, but those public files expose geography only to
district. The working-paper cleaner therefore used the INEI-assisted
SISFOH--Census delivery to recover 2017 outcomes for the study cohort. It
constructed person demographics and labor outcomes, household assets and
living conditions, migration and non-linkage indicators, household and CCPP
aggregates, NBI-style indicators, and a legacy poverty score.

The Dumez workflow began from an already merged and modified individual file.
It expanded household technology and asset measures, employment and sector
transitions, 2013 transfer-program exposure, person and household migration,
and source-household aggregates. The analysis programs then estimated
migration effects, attrition models, household migration, moderation, and
product-of-coefficients mediation specifications using employment, transfer
exposure, and 2017 internet access.

Those substantive targets remain important. The present pipeline reconstructs
their defensible data ingredients from the frozen source delivery instead of
using the historical derived files.

## Problems that cannot be inherited

### Linkage and migration

The legacy cleaner correctly distinguished an observed CCPP change from a
missing 2017 link at first, naming the latter `desgaste`. Later sensitivity
code explicitly changed migration to one whenever `desgaste` equaled one.
Non-linkage can also reflect failed record linkage, death, incomplete
coverage, enumeration differences, or source-code problems. It is not an
observed move.

The current pipeline therefore keeps three separate objects:

- `census2017_not_linked`: no Census record was attached;
- `moved_ccpp_2013_2017` and its district/province/department variants: an
  observed destination change among linked people with valid codes; and
- `moved_or_not_linked_sens_2017`: the historical composite, labeled for
  sensitivity analysis only.

### Community aggregation and denominators

The legacy CCPP construction dropped people coded as migrants before
aggregating many 2017 outcomes. Those variables consequently described
stayers rather than the complete linked source cohort. The Dumez household
construction mixed source-household and destination-household denominators;
ratios above one were deleted after construction rather than resolving why the
denominators disagreed.

The current pipeline never drops movers from source-level aggregation. It
preserves the 2013 source household as the analysis unit, records every linked
destination household and CCPP, flags source households split across
destinations, and reports the exact observed denominator for every migration
share. Partial destination rosters do not become complete households through
imputation.

### NBI and wellbeing

The historical NBI code used inconsistent overcrowding, sanitation, and
economic-dependency rules. Some sequential replacements could overwrite the
intended classification. The legacy poverty score also mixed ordinal rankings
and different analytical universes.

The current code follows the documented INEI-compatible component rules,
requires complete destination rosters for person-roster-dependent NBI
components, and never constructs a five-component NBI count from a partial
roster. The separate equal-domain wellbeing score has a fixed direction,
complete-component rule, and explicit household/person weighting. It is not
called an official poverty rate or MPI.

### Labor and mechanism variables

The independent workflow inferred 2013 employment from a nonmissing sector
code and manually classified selected 2013-to-2017 sector transitions as
better paid. It also initialized several program and asset indicators at zero
before checking whether the full item block was observed. These rules can
confound nonresponse, question universes, and substantive absence.

The current code derives employment and labor-force status from their survey
question sequence, retains missing values outside valid universes, and keeps
occupation and industry codes for a future documented labor-market
classification. It does not reproduce the subjective `better-paid sector`
indicator without an external wage-ranking source and a predeclared mapping.
Juntos, Pension 65, other program exposure, assets, internet, and employment
remain separate measures with explicit source years.

## Mapping of thesis ingredients to current variables

| Historical ingredient | Current implementation |
| --- | --- |
| Census linkage or attrition | `census2017_linked`, `census2017_not_linked`, CCPP and household linkage rates |
| Person migration | `moved_ccpp_2013_2017` plus nested district, province, and department indicators |
| Household migration | source-household member migration counts and shares; destination dispersion and split flags |
| Internet access | `internet_2017` and source-household/CCPP exposure summaries |
| Employment | `employed_2017`, `labor_force_2017`, `unemployed_laborforce_2017`, position, occupation, and industry |
| 2013 transfers | canonical SISFOH program indicators including Juntos and Pension 65 attached at person and source-household levels |
| Technology and assets | validated item indicators plus separate asset and connectivity domains |
| Attrition-as-migration | retained only as `moved_or_not_linked_sens_2017` |
| Better-paid sector transition | not reproduced pending an external wage mapping and approved estimand |

## Analysis boundary

The data-preparation block makes the historical mechanism variables available;
it does not reproduce the thesis estimators. Internet access and employment in
2017 are post-treatment and measured contemporaneously with the migration
outcome. Transfer exposure is measured in the earlier SISFOH source round, but
its timing relative to treatment varies. A system of regressions and a
bootstrapped product of coefficients do not by themselves identify natural
direct or indirect causal effects in this setting.

Before any mediation analysis is implemented, the research team must define
the intervention, mediator and outcome timing, target population, causal
estimand, exposure-induced confounders, linkage-selection strategy, and
assumptions. Until then, these variables support descriptive mechanism and
exploratory heterogeneity analysis only.

## Authoritative replacement

Section 13 of `code/stata/pipeline/01_data_preparation.do` is the sole current
Census 2017 construction. Its source and sample contract is in
`docs/CENSUS_2017_PREPARATION.md`; the cross-round score contract is in
`docs/CENSUS_WELLBEING_MEASURES.md`. Historical outputs remain archived and
must not be substituted for the three current Dropbox Coded analytical files.
