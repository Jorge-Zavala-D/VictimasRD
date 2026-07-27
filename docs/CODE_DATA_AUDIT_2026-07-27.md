# Victimas RD code and data audit

**Audit date:** 2026-07-27  
**Status:** Current-state audit complete; historical results are not yet certified reproducible  
**Repository:** `VictimasRD`  
**Research archive:** Dropbox `VictimasRD` project, inspected read-only

## Executive assessment

The surviving materials preserve a substantial amount of valuable research
work, but they do not yet constitute a canonical, end-to-end reproducible
pipeline. The main barriers are substantive as well as technical:

1. the community universe, victimization-score snapshot, category boundaries,
   treatment timing, and geographic sample are not consistently defined;
2. historical cleaning programs write derived files into directories labeled
   `Raw`;
3. fuzzy matches were accepted at low minimum scores without retaining a
   reviewable match ledger;
4. community-level coded snapshots disagree with one another;
5. the migration/linkage branch drops unmatched communities before constructing
   outcomes and is disconnected from the repository pipeline;
6. household migration models are run on person-level rows, implicitly
   weighting households by linked household size;
7. analysis code suppresses mass-point handling in settings where the running
   variable demonstrably has repeated values;
8. the current master program is inactive and omits major branches of the
   analysis; and
9. generated results have no complete specification or output-provenance
   registry.

These are repairable problems. The correct first move is to lock research-team
decisions and build provenance, crosswalk, linkage, and sample-flow layers
before regenerating substantive estimates.

## Scope and methods

This audit used non-destructive methods throughout.

- Read and statically parsed all **77 legacy Stata `.do` files** in the Git
  snapshot: **50,328 total lines** and **28,288 active-code lines**.
- Compared all **216 files** in the Git legacy snapshot with the corresponding
  Dropbox Stata-code tree. Every file matched byte-for-byte.
- Read the six additional migration, attrition, moderation, and mediation
  programs stored outside the main code tree: **1,589 lines** in total.
- Inventoried all **593 files (70.344 GiB)** under Dropbox `2 data`, including
  **301 Stata datasets (66.136 GiB)**.
- Inventoried all **44 files (3.025 GiB)** under Dropbox `5 working paper`.
- Used Stata MCP `stata_run_selection` for read-only structural and aggregate
  checks of the principal community, household, person, Census 2017, and linked
  migration datasets. No observation-level records were displayed.
- Did not execute the historical cleaning programs because they contain active
  writes to source directories. Did not select a canonical snapshot or resolve
  a research-design ambiguity on behalf of the research team.

This is therefore a complete static audit of the surviving Stata programs and
filesystem-level inventory of the related data holdings, supplemented by
structural and aggregate validation of the central analytical datasets. It is
not a certification that every historical output can be regenerated: the
necessary canonical inputs and design decisions have not yet been approved.

The supporting metadata files are
`metadata/legacy-code-inventory.csv`,
`metadata/legacy-code-audit-summary.csv`, and
`metadata/data-audit-summary.csv`. They contain hashes and structural counts,
not research observations.

## What is preserved

### Legacy code

The Git snapshot exactly mirrors the Dropbox `1 code/1 stata` tree:

| File type | Files | Bytes |
|---|---:|---:|
| Stata programs (`.do`) | 77 | 2,005,911 |
| Stata ado programs (`.ado`) | 36 | 2,015,052 |
| Help and documentation (`.hlp`, `.sthlp`) | 39 | 2,155,838 |
| Compiled/plugin support (`.mlib`, `.mo`) | 29 | 1,469,204 |
| Schemes, styles, dialogs, trackers | 30 | 195,615 |
| Excel workbook | 1 | 34,238,871 |

The `.do` programs fall into five historical groups:

| Group | Programs |
|---|---:|
| Regional-specification archive | 37 |
| Working-paper pipeline | 16 |
| SAT branch | 14 |
| Exploratory and power analysis | 6 |
| Auxiliary or uncategorized | 4 |

Ten exact normalized-code duplicate groups were detected. These include a
working-paper Census 2017 program that is identical to a regional archive
version, duplicated attrition programs, a file explicitly labeled as a check
that is identical to its source, and seven regional variants that are identical
despite different directory labels. These should be retained as historical
evidence until a provenance-preserving consolidation is approved.

### Data holdings

Dropbox `2 data` currently contains:

| Area | Files | Size |
|---|---:|---:|
| `1 Raw` | 483 | 20.886 GiB |
| `2 Working` | 44 | 33.330 GiB |
| `3 Coded` | 23 | 16.069 GiB |
| Support and root-level materials | 43 | 0.059 GiB |

The largest source groups under `1 Raw` are SISFOH root-level files, MINEDU,
CENAGRO, nightlights, testimony materials, the victimization/community
registry, Census/INEI sources, ENDES, MINSA, and smaller administrative
sources. A root-level file is explicitly labeled as unauthorized testimony.
It must remain outside Git, outside routine analysis, and outside any shared
output unless access and use are explicitly approved.

## Critical findings

### 1. The master program is not an executable research pipeline

`code/stata/legacy-current/4 Working paper/0 RD Victimas - Master.do`:

- hard-codes an obsolete Dropbox root that does not match the current machine;
- dynamically installs packages from the network;
- places every listed analysis switch inside `if (0)`, so it performs no work;
- calls only data preparation, descriptive statistics, RD tests, and the
  community-level SISFOH 2013 analysis; and
- does not call the source cleaners, household analysis, individual analysis,
  Census 2017 individual analysis, migration, attrition, mechanisms,
  moderation, or mediation branches.

No historical result should be described as regenerated by running this master
program.

### 2. The historical code violates the raw-data boundary

The working-paper cleaners contain **77 active `save` commands that write into
paths labeled `1 Raw`**. The largest concentrations are in the ENDES, MINEDU,
CENAGRO, and MINSA cleaners. These commands create or replace cleaned or
intermediate `.dta` files beside source material.

This prevents a clean distinction between original inputs and derived files
and creates a material overwrite risk. The existing Dropbox tree must be
preserved as historical evidence, but none of these programs should be run
against it. A new pipeline must read from immutable source snapshots and write
only to a separate ignored build area.

### 3. Validation is effectively absent from the legacy pipeline

Across the 16 working-paper `.do` files, the static audit found:

- 96 merge commands;
- 123 save commands;
- no active `assert`;
- no active `isid`;
- no active duplicate-report/tag/drop validation;
- no `datasignature` or systematic dataset comparison;
- two `merge, force` calls; and
- no durable merge or sample-flow ledger.

The use of `merge, force` can silently coerce key types. Most unmatched records
are dropped without a machine-readable reason code or cumulative sample-flow
accounting.

### 4. Fuzzy community matching is not auditable

The main data-preparation program performs two active `reclink` operations with
`minscore(.6)`:

1. victimization-index communities to the financed-community registry; and
2. victimization-index communities to SISFOH communities.

The code comments report 102 financed communities absent from one match and
228 unmatched cases in the SISFOH linkage. Match scores and merge indicators
are then dropped. Duplicate handling removes only selected row numbers rather
than implementing a complete deterministic rule, and one source comment says
the cases should be reviewed one by one.

There is no retained candidate set, no clerical adjudication ledger, no
geographic blocking audit, no precision/recall validation set, and no stable
crosswalk for renamed, split, merged, created, or retired centros poblados.
The historical matches therefore cannot be independently defended or updated.

### 5. The central coded community snapshots disagree

Both the SISFOH-community and Census-2017-community coded files report 5,467
observations, but they are not the same 5,467 communities.

A read-only one-to-one merge on `ubigeo_ccpp` found:

- 36 communities only in the SISFOH-community file;
- 36 communities only in the Census-2017-community file; and
- 5,431 matched communities.

Among the 5,431 matched communities:

- 1 differs on `sample2`;
- 33 differ on `Nivel`;
- 57 differ on `index_cutBC`;
- 20 differ on `treat_13`; and
- 22 differ on `treat_17`.

This proves that downstream datasets were built from different community,
score, or treatment snapshots. The apparent 5,467 count is not sufficient
evidence of a common analytical universe.

### 6. Cutoff and category logic is not locked

The preparation code centers the index on rounded values:

- A/B: 0.1538;
- B/C: 0.0623;
- C/D: 0.0269; and
- D/E: 0.0152.

These values do not fully reconcile with the values documented in surviving
paper materials. In the current SISFOH-community snapshot, four communities
labeled `C` lie on the nonnegative side of `index_cutBC`. The research team
must identify the authoritative score precision, category rule, and boundary
treatment before any RD specification is locked.

### 7. Geographic sample selection is outcome-search vulnerable

The current code defines `sample2` as:

- Huancavelica department;
- Apurimac department;
- La Convencion province; and
- Huancayo province.

This does not fully match surviving manuscript descriptions that refer to
different combinations, including Ayacucho-related provinces. The RD-test code
systematically explores many department pairs and all four adjacent category
cutoffs. That work is useful exploratory evidence, but a sample chosen for the
largest observed discontinuity is not defensible as a confirmatory design
without a transparent, outcome-independent rule and appropriate specification
search accounting.

The current SISFOH-community B/C study sample contains 529 communities in 135
districts and 16 provinces. The corresponding Census-2017-community snapshot
contains 530 communities in 135 districts because the underlying snapshots
differ.

### 8. Treatment timing and exposure are conflated

The preparation code defines treatment from the recorded financing year:

- `treat_12`: financed by 2012;
- `treat_13`: financed by 2013; and
- `treat_17`: financed by 2017.

Funding, approval, implementation start, completion, and actual receipt are
not separated. Exposure duration is set to zero both for untreated and
not-yet-treated communities.

In the full community file, 388 communities untreated by 2013 were treated by
2017. Within the current B/C geographic sample, 23 communities have this
status. In the linked person file, those 23 communities account for 5,170
person rows. Analyses using 2017 outcomes therefore require an explicit
outcome-date exposure rule and estimand; treating all `treat_13 == 0`
observations as unaffected controls is not automatically valid.

### 9. The SISFOH analytical samples are selected through linkage

Read-only aggregate checks found:

| Dataset | Total rows | Main B/C rows | Main B/C CCPPs | Districts | Unique running values |
|---|---:|---:|---:|---:|---:|
| SISFOH community | 5,467 | 529 | 529 | 135 | not applicable |
| SISFOH household | 415,587 | 42,531 | 521 | 135 | 353 |
| SISFOH person | 539,916 | 141,614 | 516 | 135 | 351 |

The main community sample loses 8 communities in the household file and 13 in
the person file. Those losses are not represented in a sample-flow ledger.
Repeated running-variable values are substantial. The main household and person
RD programs contain 16 active uses of `masspoints(off)`; the full legacy
snapshot contains 19.

The current community-level controls are also not complete for every
observation: within the 529-community B/C sample, altitude is missing for 18
communities, 2007 log population for 14, and 2007 demographic poverty for 14.
The estimation sample can therefore change across specifications.

### 10. The migration linkage removes unmatched communities before analysis

The historical linked base contains 198,030 rows, of which 4,654 have a blank
individual linkage key. The variable-construction program immediately executes
`drop if llave==""`.

Within the current B/C geographic sample:

- 99 rows have blank linkage keys;
- those 99 rows represent 99 distinct communities in 62 districts;
- 51 of the communities were treated by 2013 and 48 were not;
- 54 were treated by 2017 and 45 were not; and
- `desgaste` is missing, not equal to one, for all 99 records.

After the drop, the linked new-variable file contains 193,376 rows. Its main
B/C sample contains 110,940 person rows but only 430 communities in 94
districts, compared with 529 communities in 135 districts before the linkage
restriction. This is a major selection process, not a minor record-cleaning
step, and must be modeled and reported explicitly.

### 11. The household migration analysis uses person-level weights

The variable-construction program collapses to household level to create
household outcomes, merges those outcomes back onto every person record, and
then the household-migration program runs `rdrobust` on the resulting
person-level file.

In the main B/C linked sample:

- there are 110,940 person rows;
- there are 33,066 unique households; and
- there are 3.355 person rows per household on average.

The household outcome is internally constant within household, but using every
person row implicitly weights each household by the number of linked household
members. A household estimand requires one observation per household or an
explicitly justified weighting scheme.

### 12. Migration and attrition outcomes require reconstruction

For the Census 2017 person file, the current main B/C sample has:

- 110,992 person rows;
- 85,842 nonmissing values of `migracion`;
- a migration mean of 0.406;
- a mean of 0.537 among `treat_17 == 0` observations; and
- a mean of 0.526 among `treat_13 == 0` observations.

The control means are unusually high and 25,150 main-sample rows have missing
migration status. The denominator, origin/destination logic, treatment of
unlinked persons, household aggregation, and interpretation of `desgaste`
must be re-established from the linkage documentation and source variables.

The separate attrition code estimates probit models of `desgaste` on
`treat_17`, uses hand-entered windows labeled as optimal, repeats geographic
conditions, and accumulates a local control-variable list without resetting it
between model blocks. Later models can therefore contain duplicated controls
and do not implement a coherent RD attrition design.

### 13. Outcome construction contains silent assumptions

The separate variable-construction program:

- initializes many indicators to zero before applying source-code conditions,
  which can convert missing or inapplicable values to substantive zeros;
- creates sums without an explicit missing-data policy;
- assigns a single 2017 sector through sequential replacement, making
  multi-sector cases order-dependent;
- hand-codes a better-paid-sector hierarchy without a versioned wage source;
- drops ratios greater than one rather than diagnosing numerator/denominator
  construction;
- constructs household migration as any linked member migrating; and
- constructs a combined migration/attrition outcome as any linked migration or
  any recorded wear/attrition.

Every constructed outcome and mediator needs a versioned definition,
admissible-value check, missing-value rule, unit of analysis, source-year
alignment, and validation table.

### 14. The mediation branch is exploratory, not a causal mediation design

The six disconnected programs are hard-coded to a coauthor's OneDrive path and
are not called from the Git master. The mediation programs:

- use manual local-polynomial/SUR product-of-coefficients calculations;
- bootstrap 50 or 200 repetitions without setting a seed;
- contain inconsistent variable and equation names;
- include malformed or duplicated model text in at least one system equation;
- dynamically depend on user-written commands; and
- treat 2017 internet access and other contemporaneous measures as mediators of
  migration measured over 2013–2017.

The timing alone prevents a straightforward causal-mediation interpretation.
These analyses should be preserved and labeled exploratory until temporal
ordering, post-treatment confounding assumptions, selection, and the causal
estimand are explicitly justified.

### 15. Multiple testing and specification governance are missing

The legacy programs contain approximately:

- 554 `rdrobust` calls;
- 11 `rddensity` calls;
- 23 `rdplot` calls;
- 62 graph exports; and
- 1,832 `putexcel` writes.

The search spans multiple outcomes, aggregation levels, regional samples,
cutoffs, polynomial orders, controls, bandwidth rules, and clustering choices.
There is no specification registry separating confirmatory estimates from
exploratory searches, no declared outcome families, and no multiple-testing
strategy.

The Excel outputs are assembled cell by cell, including manually assigned
significance stars and control means. Estimation metadata are not retained in
a machine-readable output manifest, so a paper cell cannot be reliably traced
to one input snapshot and one exact specification.

### 16. Git currently contains one tracked data workbook

The legacy snapshot includes the tracked file
`code/stata/legacy-current/SAT/4. PBI_CentrosPoblados_1993-2018.xlsx`
(32.65 MiB). Six `.dta` files copied into the legacy directory are locally
present but correctly ignored by Git.

The workbook conflicts with the repository's code-only boundary unless the
research team determines that it is redistributable, non-sensitive,
appropriately sized, and necessary as a versioned input. Do not delete it
silently: preserve its current checksum and history, decide whether to remove
it from the active tree in a dedicated task, and replace it with provenance
metadata or a public-source retrieval instruction if possible.

### 17. Dependencies are not frozen coherently

The legacy snapshot vendors a collection of ado/help/plugin files while the
master also installs packages dynamically. The included `rdrobust` tracker
reports distribution date 2022-09-30. Other historical branches depend on
`reclink`, `outreg2`, `rddensity`, `lpdensity`, `ivreg2`, `suregr`, graph
schemes, and additional user-written commands.

A reproducible environment needs a reviewed package manifest with exact
versions, sources, licenses, checksums where appropriate, and the Stata version
used for each certified result.

## Canonical dataset candidates inspected

| Logical dataset | Rows | Variables | Current assessment |
|---|---:|---:|---|
| SISFOH community | 5,467 | 742 | Unique `ubigeo_ccpp`; differs from Census 2017 snapshot |
| SISFOH household | 415,587 | 600 | 521 of 529 main-sample communities represented |
| SISFOH person, both sexes | 539,916 | 1,061 | 516 of 529 main-sample communities represented |
| Census 2017 community | 5,467 | 988 | Unique `ubigeo_ccpp`; differs from SISFOH snapshot |
| Census 2017 household | 71,102 | 906 | Structure inspected; canonical status unresolved |
| Census 2017 person | 198,036 | 1,079 | 110,992 main-sample rows; migration has substantial missingness |
| Historical linked person base | 198,030 | 1,079 | 4,654 blank linkage keys |
| Linked person plus new variables | 193,376 | 1,119 | Blank-key communities excluded; 430 main-sample communities remain |

No candidate is designated canonical by this audit.

## Research-team decision gates

The following decisions must be recorded before substantive pipeline
construction or result certification:

1. **Community universe:** authoritative source, reference date, treatment of
   splits/mergers/creations/retirements, and stable crosswalk identifiers.
2. **Victimization score and cutoffs:** authoritative precision, category
   boundaries, tie handling, and all A/B, B/C, C/D, and D/E running variables.
3. **Treatment ontology:** financing, approval, start, completion, and actual
   delivery dates; treatment type; treatment intensity; and outcome-specific
   exposure rules.
4. **Geographic design rule:** full-country default and any restriction based
   on prespecified institutional, support, overlap, or data-quality criteria,
   not significance maximization.
5. **Match governance:** deterministic blocking rules, normalized names,
   geographic constraints, candidate-generation method, human adjudication,
   uncertainty classes, and versioned match ledger.
6. **Analysis units and clustering:** community, household, person, district,
   and any multi-level dependence or weighting strategy.
7. **Migration and attrition estimands:** linked population, denominators,
   missing/nonmatch treatment, household aggregation, migration definition,
   and sensitivity bounds.
8. **Outcome families and multiplicity:** primary, secondary, mechanism, and
   exploratory outcomes, including family-wise or false-discovery control.
9. **RD specification registry:** primary cutoff(s), local polynomial order,
   kernel, bandwidth rule, bias correction, mass-point handling, covariates,
   clustering, and planned robustness checks.
10. **Mechanism and mediation claims:** temporal order, causal assumptions,
    alternative explanations, and whether analyses are descriptive,
    exploratory, or causal.
11. **2025 Census extension:** scope of the INEI request, permissible linkage
    identifiers, de-identification, output governance, linkage-quality
    metadata, and coordination with Ana María's earlier linkage work.
12. **Release governance:** access rights, licenses, sensitive sources,
    disclosure review, public/private repository status, and paper-output
    approval.

## Recommended implementation sequence

### Phase 0 — Preserve and govern

- Freeze the current Dropbox tree as historical evidence without moving or
  modifying it.
- Record logical input names, provenance, access restrictions, sizes, dates,
  and canonical-candidate status.
- Review the tracked PBI workbook and vendored Stata packages.
- Approve the decision gates above in a versioned decision log.

### Phase 1 — Build the community spine

- Construct a longitudinal centro-poblado registry with stable analytical IDs.
- Reconcile official ubigeos across years and document splits, mergers,
  creations, retirements, and name changes.
- Normalize names without discarding original strings.
- Build deterministic and probabilistic match candidates using geography,
  historical names, edit distance, token similarity, and contextual features.
- Retain every candidate score and adjudication decision.
- Measure match quality on a reviewed validation set and propagate uncertain
  links into sensitivity analyses.

### Phase 2 — Reconstruct treatment history

- Create an event-level treatment table with provenance and all available
  dates.
- Distinguish funding from actual implementation and completion.
- Create outcome-date-specific exposure variables and later-treatment flags.
- Validate community coverage and timing against official documentation.

### Phase 3 — Rebuild each source module

- Create one modular program for every source family.
- Read immutable source snapshots; write only to an ignored build directory.
- Assert keys, ranges, labels, units, and merge cardinalities.
- Emit variable dictionaries, merge ledgers, duplicate reports, and sample-flow
  records.
- Stop on unexpected conditions rather than weakening checks.

### Phase 4 — Lock the empirical design

- Analyze all four adjacent cutoffs and evaluate modern multiple-cutoff
  methods where substantively justified.
- Start from the full national support and document any outcome-independent
  restriction.
- Produce a specification registry before confirmatory estimation.
- Separate exploratory search results from confirmatory estimates.

### Phase 5 — Rebuild outcomes and longitudinal linkage

- Reconstruct SISFOH, Census 2007, Census 2017, education, health,
  agricultural, budget, nightlights, and other modules with common identifiers.
- Rebuild migration and attrition with explicit denominators and linkage
  uncertainty.
- Produce one-row-per-unit analytical files appropriate to each estimand.
- Coordinate an INEI concept note and governed linkage request for the 2025
  Census, seeking the same or improved longitudinal linkage available for the
  earlier Ana María analysis.

### Phase 6 — Estimate and validate

- Use current, version-locked RD tools with robust bias-corrected inference.
- Diagnose mass points rather than suppressing them.
- Implement density, covariate-continuity, bandwidth, kernel, polynomial,
  donut, placebo-cutoff, placebo-outcome, geographic, timing, and clustering
  checks.
- Add transparent parametric comparisons as robustness analyses, not
  replacements for the local design.
- Correct or contextualize multiplicity and report effective sample sizes and
  clusters.

### Phase 7 — Certify outputs

- Generate every table and figure from versioned code into Git output
  directories.
- Record input snapshot IDs, specification IDs, software versions, checksums,
  disclosure review, and manuscript destinations.
- Compare regenerated results with historical paper numbers and explain every
  difference.
- Synchronize only reviewed non-sensitive outputs to the live Overleaf project.

## Immediate next actions

1. Hold a research-team decision meeting using the coauthor plan and the twelve
   decision gates above.
2. Approve a canonical-snapshot and data-access inventory template.
3. Preserve the six disconnected migration/mediation programs as a separate
   provenance-tagged legacy snapshot.
4. Draft the centro-poblado longitudinal crosswalk schema and match-review
   protocol.
5. Draft the treatment-event ontology and request missing implementation dates.
6. Draft the INEI 2025 Census linkage concept note and governance checklist.
7. Only after those approvals, build the first deterministic pipeline module
   and validation harness.

## Non-actions in this audit

- No Dropbox research source, dataset, historical code file, manuscript, or
  output was modified.
- No Stata `.do` file was created or executed.
- No historical result was treated as confirmed solely because it appears in a
  paper, presentation, workbook, or console log.
- No commit or push was performed.
