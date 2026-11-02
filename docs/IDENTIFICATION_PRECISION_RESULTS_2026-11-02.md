# Identification and precision: scientific assessment

**Status: scientific audit and bounded technical validation completed on
2 November 2026. New outputs remain internal-review artifacts; live manuscript
integration, submission and public release are not approved by this record.**

## What is fixed

The protocol is `IDENTIFICATION_PRECISION_AUDIT_2026-11-02.md`. The analysis
retains the selected geography, adjacent B/C support, receipt through 2012
and 2016, all outcome families, existing eligibility and weighting, primary
bandwidths and CR2 RD inference. There is no new sample search, outcome
selection or automatic promotion of a favorable sensitivity estimate.

## Independent assessment of the frozen primary evidence

The six pre-edit aggregate result files at HEAD
`72ef0e3edd4b094d00e9ac47667ba24b85695ca1` contain 48 registered primary
fixed-window fuzzy outcomes. A separate in-console Stata calculation confirms:

- All 48 ordinary robust bias-corrected intervals include zero.
- All primary Holm-adjusted probabilities exceed 0.05; their range is
  0.45601237 to 1, not universally 1. The original six eight-outcome families
  are retained; these are not 48 independent replications or one global family.
- With the explicitly post-results larger illustration benchmarks, 34 of
  48 intervals contain both the positive and negative benchmark.
- Two intervals lie wholly inside the larger symmetric benchmark: 2013
  household roster size (about -1.26 to 1.40 members, against +/-2) and
  2017 community insurance coverage (about -6.02 to 8.10 percentage points,
  against +/-10). None lies wholly inside the smaller illustration bounds.

This is a precision description, not observed-effect power, a formal
equivalence test or a declaration that those bounds are minimal important
effects. In particular, ordinary fuzzy-RD intervals remain conditional on
adequate identification and the other design assumptions. The two contained
intervals do not establish causal bounds for all original residents.

## Interpretation rules for the new diagnostic registry

1. An original estimator failure remains a failed registered row, not a zero
   effect or a removed hypothesis.
2. An unavailable or finite KP F at most 10 keeps receipt interpretation held.
   A passing F is only the approved operational screen, not an exclusion,
   monotonicity, smoothness, selection or strong-identification theorem.
3. The conventional local-IV analogue has the actual outcome sample, weights,
   kernel, left/right estimation windows, polynomial and covariates. Its
   own first stage, reduced form and official clustered Anderson--Rubin
   confidence set are separately identified. A nonbounded or failed set must
   remain visible. Its inference is not relabeled as bias-corrected RD inference.
4. Nonclustered RD variance variants retain the assignment-level cluster for
   the separately labeled IV diagnostic. This is not a reproduction of NN,
   HC3, CR2 or CR3 variance estimation.
   Outcome-adaptive bandwidth confidence sets are recorded-window diagnostics,
   not established post-selection RD coverage. The historical design search
   also remains a qualification of the adopted fixed-window analysis.
5. Eligible, estimation-window and bias-window support are reported separately
   in observations, communities, districts and distinct scores. Positive kernel
   weights define RD support. Parametric IV's existing positive endpoint
   convention is preserved, and its nonexistent bias polynomial is marked
   not applicable rather than assigned borrowed support.
6. A supported assignment/reduced-form contrast and a supported receipt-effect
   interpretation are different claims. New diagnostics do not reverse the
   primary reporting hierarchy or automatically clear secondary receipt claims.

The current main narrative should therefore remain conditional and imprecise,
not become either "the program had no effect" or a migration-effect headline.
The 2017 observed-adult movement estimate still concerns the approved linked,
canonically observable population; the audit does not transport it to missing
or unlinked source-cohort members.

## What the extra IV inference cannot settle

The Stata 19 AR inversion addresses weak instruments for the stated local-IV
model. It does not simultaneously solve smoothing bias and irregular score
support. The bias-aware fuzzy-RD approach of
[Noack and Rothe (2024)](https://doi.org/10.3982/ECTA19466) is a different
construction with explicit smoothness restrictions. A future application would
need a documented curvature sensitivity and clustering assessment; arbitrary
bounds must not be silently imported to obtain a favorable interval.

Likewise, stronger first stages do not resolve treatment-dependent observation
or linkage. Existing Census selection qualifications and the owner's CMAN-year
allocation/delivery assumption remain binding. No unavailable historical-year
records are requested as a new prerequisite.

## Validation and publication boundary

The independent source review found two Important support-reporting defects.
Both were corrected and tested against the locked `rdrobust` command, including
asymmetric endpoint fixtures. The original inclusive count fails the fixture
(50 versus 49 positive-weight observations). The corrected three-kernel,
parametric-endpoint, complete-support, missing/empty-sample, caller-state and
official-estimator-failure checks pass.

The first obsolete attempt was stopped after source review, and its completed
aggregate files and logs were preserved locally. It is not a completed run.
The corrected six-module run supplies the final audit registry, with the
explicitly documented confidence-set export correction below.

### Production and exact numerical comparison

The documented master environment was loaded from a clean, dedicated Stata
session. All six module-04 scripts then completed through `stata_run_selection`,
run ID `2nov2026_161137`, from 16:11:37 to 17:42:36 local time. The Stata 19
7 October 2026 build and all 13,235 locked dependency identities passed the
environment guard before and after execution; nothing was installed or updated.
This is a complete module-04 run from the master environment, not a new
end-to-end execution of data preparation, heterogeneity and mechanisms.

All 1,970 original model rows remain, with no original estimation failures.
Keys, strings, integer/sample counts and missingness match the preserved
pre-edit six-file baseline exactly. There are 1,664 non-bitwise continuous
cells; the largest absolute difference is 6.95585811172e-11. Every difference
passes the documented absolute 1e-10 plus relative 1e-12 tolerance. Differences
are confined to conventional estimates, conventional first stages, one
bandwidth field, standardized conventional estimates and legacy weak-IV
p-values. The primary bias-corrected estimates, robust standard errors,
probabilities, intervals and multiplicity adjustments are unchanged. The
280-variable comparison record is
`metadata/identification-precision-numerical-comparison-2026-11-02.csv`.

### Final confidence-set geometry check

A further native synthetic check found an export defect in the newly added
audit: official `r(ar_ci)` represents a disjoint set as a 2-by-2 matrix, not a
1-by-4 matrix. The original audit parser omitted the second ray. This was an
audit-output error, not a change or error in the original model-result files.
The new regression fixture fails before the parser correction and passes
after it, including scale conversion and `.l`/`.u` infinite endpoints.

The focused versioned routine
`code/stata/tests/reproduce_unweighted_ar_sets.do` independently rebuilt all
32 unweighted 2013 household/person primary sensitivity fits from the original
Coded inputs. It checked the original primary complete-case counts (39,074
households; 98,005 adults), local observation counts, conventional IV points,
KP statistics, AR probabilities and the previously retained first components
before replacing only the new audit's confidence-set fields. Its 1e-6 relative
comparison allowance concerns the new float-serialized diagnostics only,
not the tighter original-result preservation test. Future full module-04 runs
use the corrected shared parser directly; no repair mode or new dependency
is added to the routine pipeline.

The completed output contract now checks both rays, ordered finite inner
endpoints, infinite outer endpoints, and containment of the conventional IV
point in the set. All 1,648 receipt-model points reconcile with their original
conventional estimates. There are no failed AR calculations. The remaining
322 registered rows are assignment/reduced-form models, not receipt models.

### Own-sample identification results

| Wave and unit | Registered rows | Receipt rows | KP screen passed | Held | Nonbounded AR sets |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2013 community | 319 | 265 | 157 | 108 | 0 |
| 2013 household | 352 | 295 | 163 | 132 | 16 |
| 2013 individual | 392 | 325 | 176 | 149 | 16 |
| 2017 community | 273 | 229 | 206 | 23 | 0 |
| 2017 household | 286 | 244 | 206 | 38 | 0 |
| 2017 individual | 348 | 290 | 250 | 40 | 0 |
| Total | 1,970 | 1,648 | 1,158 | 490 | 32 |

These are correlated specification rows, not independent tests or studies.
All 48 primary fixed-window fuzzy rows pass the owner-approved finite KP F
strictly above 10 screen and have bounded conventional AR sets. The 2013
primary diagnostics are close to the threshold (about 10.49 at community
level and 11.10 at household/person level); passing is not a license to call
them unquestionably strong or to reinterpret the primary RD intervals.

Three marginal conventional AR sets exclude zero: 2017 community employment
(P06), household female share (H01), and household share living in another
CCPP (H03). Their original robust bias-corrected intervals all include zero,
and their Holm-adjusted probabilities are approximately 0.467, 0.456 and
0.740, respectively. This is not an inconsistency to repair: conventional
local-IV AR inversion and bias-corrected RD inference are different procedures.
The new AR intervals are not multiplicity-adjusted. Their marginal exclusions
must not displace the registered primary estimator or become new headline
findings selected after inspecting two inference methods.

The exact-support review also prevents confusing people with independent
assignment information. Primary local windows contain 60--65 CCPPs. Across
the six primary families, side-specific support is only 27--29 distinct
scores below the threshold and 19--20 above it. The associated bias windows
have 45--48 distinct scores below and 30--33 above. Thousands of household/person
records do not create thousands of independent assignment units or a
continuously supported running variable. The registry reports the actual
row-specific support; mass-point adjustment is not proof that score
discreteness is immaterial.

Of all receipt rows, 1,616 AR sets are bounded, 20 are disjoint two-ray sets
and 12 contain all real numbers. The latter 32 are the unweighted 2013
household/person sensitivity specifications. Their original numerical
coefficients remain visible, but a bounded, precise causal receipt claim is
not supported by those sets. Weak rows cannot borrow clearance from a
CCPP-equal-weight primary fit. Other held rows are retained too, even when
their conventional AR set happens to be bounded.

The approved 2017 individual observed-migration primary row has 7,680 people
in 63 CCPPs, compared with 5,948 people in 62 CCPPs for the other complete-case
primary individual outcomes. Its conventional AR set is approximately
[-3.23, 71.37] percentage points; its unchanged bias-corrected RD interval is
approximately [-17.24, 60.14]. This is not evidence of a precisely estimated
migration effect, nor a result for all unlinked original residents.

### Outputs and print-size review

The seven new aggregate CSV/TeX outputs are recorded separately in
`metadata/rd-identification-precision-output-manifest.csv`. They do not alter
the historical 261-candidate publication roles or the original 117-artifact
module-04 inventory. The complete registry retains all 1,970 rows, 106 fields,
original probabilities and adjustments, eligible/local/bias support, own-sample
diagnostics and all confidence-set endpoints. The primary precision file has
all 48 outcomes and 118 fields. No row-level data are exported.

The private six-page review PDF was compiled at a 165.1-mm text width and
visually inspected, including the primary notes and distinct migration sample.
Its smallest text is approximately 9.96 points. Machine checks found no
overfull boxes, undefined references, multiply defined labels, TeX errors or
out-of-page characters. All six summary rows, 48 primary rows and 48 benchmark
rows are present. Group headings are kept with their first data row. The
illustration benchmarks remain internal, not a proposed paper equivalence test.

### Scientific disposition

The primary narrative should remain unchanged in substance: the evidence is
local, conditional and often imprecise, with no primary outcome surviving its
registered Holm correction. Do not promote a sensitivity merely because its
own first stage passes. Do not describe intervals covering zero as evidence
that reparations had no effect. A genuine bias-aware weak-identification RD
branch would be a separate scientific protocol, not a relabeling of these
conventional AR diagnostics.

The exact proposed next manuscript step is in
`docs/proposals/2026-11-02-identification-precision-overleaf-updates.md`: three
narrow source additions plus two new canonical tables, without replacing
any existing generated input. It remains a proposal awaiting owner approval.

Read-only SHA-256 checks confirm all 55 existing live generated
inputs and the seven previously approved manuscript sources are unchanged.
No live Overleaf file, data source, author approval, publication role or release
flag has been changed. The canonical release audit from the previous batch is
dated evidence, not certification of this new unreviewed output generation.

The final machine-readable technical/visual receipt is
`metadata/identification-precision-validation-2026-11-02.json`. A tool connection
reset during a redundant final check; the master environment and the complete
focused test suite were then rerun successfully in a fresh session. No pending
or stale tool call is counted as a passing test.
