# CMAN project classification and financing measures

## Purpose and universe

The CMAN communities-attended register contains 4,433 project records through
2023. `code/stata/pipeline/01_data_preparation.do` classifies every record from
the Spanish project title and constructs transparent financing measures before
any CMAN-to-RUV restriction. Consequently, project-level descriptive outputs
include all 4,433 CMAN rows, including projects that cannot enter the
2018-vintage RUV-master analytical dataset.

The classification is descriptive. It is not an official CMAN sector code and
does not alter the treatment indicator or recorded treatment year.

## Text preparation and categories

Stata converts each title to lower case, decomposes and removes diacritics,
replaces punctuation with spaces, and collapses repeated whitespace. The code
then applies versioned Spanish keyword dictionaries for fourteen categories:

1. Livestock;
2. Irrigation;
3. Community facilities;
4. Agriculture;
5. Education;
6. Water supply;
7. Management and other support;
8. Road infrastructure;
9. Health;
10. Fishing and aquaculture;
11. Sanitation;
12. Energy;
13. Commerce and processing; and
14. Tourism, culture, and prevention.

Definitions and examples are recorded in
`metadata/cman-project-taxonomy.csv`. These categories preserve the structure
of the manually produced working-paper table while clarifying the combined
rare category and distinguishing generic management support from projects with
a named sector.

## Multisector titles and primary-category hierarchy

All matching sector themes are counted before assigning a primary type.
`prc_project_multisector` identifies titles that contain more than one theme.
The primary category follows this fixed hierarchy:

1. fishing and aquaculture;
2. water supply;
3. sanitation;
4. irrigation;
5. health;
6. education;
7. energy;
8. road infrastructure;
9. livestock;
10. agriculture;
11. commerce and processing;
12. tourism, culture, and prevention;
13. community facilities; and
14. management and other support.

The hierarchy prevents generic terms such as *fortalecimiento* or *local
comunal* from overriding a specific named service or productive activity.
Record 1120 explicitly combines potable water with sprinkler irrigation. Its
full title was reviewed and irrigation was selected as the primary purpose;
both themes and the multisector flag are retained. The variable
`prc_project_class_method` distinguishes this record-specific decision from
the dictionary hierarchy.

Every project must match at least one theme and receive exactly one primary
category. The data-preparation code stops if either contract fails.

## Historical benchmark

The pre-existing 2,408-row Excel roster contains the authors' older
`tipo_proyecto` field. Exact normalized geography links recover 2,223 rows that
can be compared without fuzzy matching. During development, the new title
classifier agreed with the collapsed historical categories for 94.3 percent
of those rows.

The old field is not used to assign the new category. Review found
substantively inconsistent legacy labels, including an old energy record whose
title describes potable water and livestock records whose titles describe
coffee. It is therefore retained as a historical benchmark rather than ground
truth.

## Financing variables

The pipeline constructs:

- `prc_cofinanced`: one when the recorded cofinancing amount is positive;
- `prc_total_financing_soles`: CMAN financing plus cofinancing;
- `prc_cofinancing_share`: cofinancing divided by total recorded financing;
  and
- `prc_cofinancing_ratio`: cofinancing divided by CMAN financing.

All amounts are nominal soles as printed in the source. They are not
inflation-adjusted and should not be interpreted as real expenditure,
completion cost, or disbursement timing without additional documentation.

The descriptive program reports annual composition using the four broad
groups and compares all fourteen primary-category shares in 2007--2018 with
2019--2023. This split uses the complete current register retrospectively; it
is not a literal reproduction of the working paper's older data extract.

## Review evidence and released variables

The complete row-level title, normalized text, theme indicators, assigned
category, classification method, and financing measures are regenerated in
Dropbox Working QA as:

- `cman_project_classification_review.dta`; and
- `cman_project_classification_review.csv`.

Theme indicators and normalized helper text do not enter the polished
community registry. The project type, broad group, multisector flag,
classification method, and substantive financing measures are retained. For
communities with multiple CMAN records, the foundational community registry
continues to represent the earliest recorded project, while the project-level
descriptive module uses all CMAN rows.
