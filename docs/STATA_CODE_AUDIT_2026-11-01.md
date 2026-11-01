# Fresh Stata-code audit — 1 November 2026

## Verdict and scope

**Hold production re-estimation and release clearance; authorize targeted fixes separately, without a wholesale stylistic rewrite.** The active code has a coherent empirical-research architecture and substantial data/provenance checks. Nevertheless, this fresh review found reachable data-construction, inference-status and release-boundary defects, plus confirmed reporting inconsistencies. Documentation and audit metadata are the only changes in this batch. No producing code, scientific decision, dataset, estimate, generated exhibit, dependency, or live manuscript was changed.

Baseline: branch main, clean checkout at **bd24c982ebf3072de01a1b429c31270daccb71f0**; origin https://github.com/Jorge-Zavala-D/VictimasRD.git. Intended operational load: **one collaborator running the write-enabled pipeline at a time** against the synchronized data roots; concurrent runs into shared destinations are not qualified.

Read the [standing standards](STATA_RESEARCH_CODE_STANDARDS.md), [reference evidence](STATA_REFERENCE_REVIEW_2026-11-01.md), and machine-readable [inventory](../metadata/stata-audit-2026-11-01/code-inventory.csv), [coverage](../metadata/stata-audit-2026-11-01/review-coverage.csv), and [bibliography screen](../metadata/stata-audit-2026-11-01/bibliography-screen.csv) together. Exact source locations below refer to the unchanged baseline. Inventory hashes bind the reviewed code, not a claim that every possible input or scientific assumption was validated.

### Coverage

- 26 active Stata files, **39,714 lines**, sequentially reviewed across preparation, master/environment, descriptives, historical search, fixed validation, all six main modules, all six heterogeneity modules/shared engine, migration/selection, publication and release. Preparation lines 11,268–12,591 are aggregate-post/export closeout: viewed in full at lower intensity than transformations, not numerically reproduced.
- Five Python support/ingestion/check scripts: **1,132 lines**; one Python test: 101 lines. All source read.
- Thirteen Stata tests: **1,051 lines**. Sources reviewed; not all tests executed.
- 77 preserved legacy research do-files: **50,328 lines**, 67 unique byte contents. Reviewed using sequential reading, executable-line projection, full-range template/delta comparison, and byte-identical equivalence as individually recorded. This is not 77 independent executions or 50,328 independently reread raw lines.
- 69 legacy vendor/support files inventoried; targeted locked ivreg2 source examined. No complete semantic audit of third-party package internals, compiled Mata or Stata's BASE implementation is claimed.
- Graphify used for scoped navigation; direct source/caller/protocol inspection determined findings.
- Current bibliography: 59 entries screened; shared Zotero: 39 items enumerated read-only. Three primary author Stata packages/components and an additional historical mirror inspected; reference versions and limitations are recorded separately.

## Current execution environment: an independent blocking finding

The read-only SHA-256 checker **fails the existing 3 October software lock** on this host:

| Failed checks | Count |
| --- | ---: |
| Byte-length mismatch | 251 |
| SHA-256 mismatch | 271 |
| Unlocked official file | 12 |
| Total failed checks, not distinct files | 534 |

Examples include StataMP-64.exe, mp-64.dll and official BASE files. Current MCP reports Stata 19/Windows, born date **07 Oct 2026**. The actual installation root was verified through Stata as the same root passed to the checker. Thus this is not merely a wrong-root invocation. The current files no longer match the recorded lock; the cause/history of each changed file was not investigated.

No environment was repaired, updated, downgraded or re-locked. Before production re-estimation, choose an authorized route: restore the recorded licensed environment from a verified source, or explicitly qualify the current environment against preserved results and then approve a new lock. Never modify the lock simply to make this check pass. Native lock checks should remain fail-closed. Successful synthetic checks in today's engine do not certify historical software reproduction.

## Prioritized findings

P1 means potentially destructive boundary failure that must be resolved before using the affected path. P2 means correctness, inference, provenance or reporting repair needed before clearing the affected workflow. “Current incidence unknown” is deliberate: a reachable source defect is not proof that frozen estimates changed.

### 1. [P1] Storage preflight does not enforce disjoint immutable/Git boundaries

**Source:** code/stata/00_master.do:225–297; first directory writes 325–339.

Raw==Working, current-pipeline==dated archive, or persistent data under Git can satisfy the lexical nesting checks. Equality with Raw is not rejected; .. traversal can also evade prefix reasoning. A wrong local config can therefore route replace-writes into immutable data or Git. The inspected current configuration uses the intended disjoint layout; no current overwrite found.

**Smallest remedy/test:** canonical/traversal-free absolute roots, equality and containment rejection for Raw/archive/Git, before mkdir/save. Test those bad configurations and the valid layout without creating directories.

### 2. [P1] Standalone extractors permit source/output/manifest aliases

**Sources:** code/python/extract_cman_pdf.py:270–272,306; extract_reporte_ccpp_html.py:322–324,352.

An output or manifest naming an input can replace the parsed immutable source; output==manifest replaces CSV with JSON. These scripts are correctly excluded from the routine master; none was executed here.

**Remedy/test:** reject resolved aliases before the first write; tiny temporary fixtures must leave source bytes unchanged on every invalid configuration. Keep parsers and atomic writes.

### 3. [P2] Missing/failed statistics can pass interpretation gates

**Sources:** 04a:734–735; 04b:972–973; 04c:1034–1035; 04d:759–760; 04e:933–934; 04f:1045–1049; 05a:353–406,902–906; 05d:378–382,486–490; _heterogeneity_level_engine.do:596–650.

F>10 accepts . and extended missing values. Heterogeneity gates can also remain one after estimation_rc=504 if support/SW diagnostics pass. Financing-dose 2017 has the same missing-F branch. Hard-coded graph notes assert strength even when a future fit fails.

**Current check:** all six existing primary KP statistics are finite and >10; none of the six HTE CSVs has gate_pass==1 with failed or missing required effect/diagnostic values. These checks do not test every zero-SE/inference branch. Passing-gate row counts across the full files are respectively 0, 0, 23, 48, 16 and 68 (2013 CCPP/household/person, then 2017 CCPP/household/person). The zero-inconsistency result is therefore vacuous for the first two files, not for all six.

**Remedy/test:** one explicit successful-fit, finite-statistic, positive-SE predicate feeding status, gate and wording. Test ., .a, .z, 10, 10.01, zero SE and captured failures. The approved F threshold, sample and bandwidth do not change. Locked ivreg2 genuinely returns e(rkf); that scalar name is not a finding.

### 4. [P2] Unknown ages enter some age-restricted constructions

**Sources:** 01 preparation:8506–8511,8527–8528,8550–8558,8588–8589,10269–10304,10374–10496,10781–10783,10978–10985,11125–11132; 04c:47–68,83–86,102–104,126–128.

Missing age satisfies age>=3/12/14. Valid item responses can therefore populate unknown-age outcomes or adult aggregates. Committed SISFOH sample-flow metadata reports 435,314 missing ages; all enter the line-8550 count labeled valid-age eligible. Its 23,091,791 becomes **22,656,477** when only that incorrect inclusion is removed. This arithmetic is not a new cleaned-data estimate.

**Boundary:** 2013 aggregate eligibility flags 8745–8768 already guard age; primary person complete-case rules and current 2017 individual migration adulthood guards must not be described as demonstrated failures. Downstream outcome incidence remains unmeasured.

**Remedy/test:** explicit known-age conditions, preserve approved cutoffs/linkage boundaries; synthetic ordinary/extended missings and cutoff-adjacent ages, followed by restricted-data aggregate incidence checks before regeneration.

### 5. [P2] A byte age key cannot represent valid ages 101–120

**Source:** 01:10181; using-map 10040–10068; allowed age contract 8495–8496.

Third-pass district/roster/age/sex recovery generates byte sisfoh_age_key. Ages 101–120 become missing while the using key retains them. Such a candidate can lose a legitimate deterministic match. Current candidate incidence unknown.

**Remedy/test:** int or clone source age; test matching at 100,101,120 and unknown age. Do not retain hard-coded recovery totals by suppressing newly recovered records; reconcile any actual change.

### 6. [P2] Election fallback references fields already dropped

**Source:** 01:7978–7981,8056–8073.

The release-variable loop copies and drops fallback linkage-method/predecessor fields; the following explicit statements reference/drop them again. Any nonempty fallback branch reaches r(111), even if no name recovery succeeds. Current exact-versus-recovered counts do not establish whether this branch was used.

**Remedy/test:** remove only redundant second handling. Test recovered and zero-recovered fallback cases; retain all RUV rows and correct linkage status.

### 7. [P2] Destination roster completeness lacks distinct-person validation

**Source:** 01:9935,9973–9974,10123–10124,10602–10629,10671–10726,10876–10877.

Source llave is unique, but destination id_pob_imp_f is not validated before _N==reported household size certifies completeness. Two source rows attached to the same destination person can falsely complete a two-person roster and unlock roster-dependent NBI.

**Remedy/test:** check distinct/nonmissing destination-person identity and household compatibility before completeness. Actual duplicates are not alleged. If found, retain source rows and adjudicate/quarantine completeness-dependent outcomes rather than silently deduplicating.

### 8. [P2] Financing histories can silently omit unknown/unmatched amounts

**Sources:** 05a:189–227; 05d:175–242.

Assertions amount>0 accept missing. Summation can ignore one unknown project amount, while a treated community missing from the aggregate survives positive-count assertions because .>=1. Its dose/type analysis may then silently disappear.

**Remedy/test:** finite positive source amounts, observed amount counts and explicit treated linkage validation before coding verified untreated values zero. Test partial-missing history, missing matched history and genuine untreated community. Do not change the approved CMAN-year interpretation.

### 9. [P2] 2013 CCPP binary conditional effects evaluate a missing point

**Source:** 05a:166–173,426–442; correct shared-engine counterpart 686–690.

Binary initialization uses evaluation slots 0,missing,1. The two-row branch reads slots one/two and labels the missing slot “Yes.” The pooled conditional effect should be D+D×M at one. The frozen M02 support failure may keep this dormant.

**Remedy/test:** the engine's small binary index remap, not a new framework. A supported binary fixture must recover D at No and D+D×M at Yes.

### 10. [P2] Fit failures change multiplicity-family size without a registered rule

**Sources:** 04a:692–713 and analogous six modules; 05a:765–789; shared engine:1160–1189; outcome protocol:28–30,205–217; heterogeneity protocol:100–108.

Only returned p-values/eligible successful fits enter adjustment counts. In a registered eight-test family, smallest p=.007 yields Holm .049 with seven returned tests versus .056 with eight. Unsupported moderator families can shrink similarly.

**Decision required before implementation:** confirm the registered family and any ex ante design-based exclusion policy. Do not silently reinterpret current adjusted signals. A fixed applicable family could conservatively assign p=1 for adjustment only to failed tests, retaining raw missing p/failure labels; structural identity cells need their explicit exclusion rule. Test failures, ties and identity cells. No current false discovery is alleged.

### 11. [P2] Secondary LATEs inherit strength language from different samples

**Sources:** 04a:577–678,985; 04d:448–451,602–704,1052; corresponding micro modules, e.g. 04b:1254 and 04f:1391.

Primary-only local-IV KP/AR diagnostics do not clear secondary outcomes with distinct missingness/denominators, including broader GDP samples. Per-outcome rdrobust squared-z fields are not the same as matching local-IV KP clearance.

**Remedy/test:** exact-sample diagnostic rows, or explicitly label secondary strength unassessed/interpretation-held. A deliberately weak secondary subsample must not inherit the primary sample's gate. No new sample/bandwidth tuning.

### 12. [P2] 2013 CCPP HTE omits prescribed clustering sensitivities

**Sources:** 05a:675–741; RD_HETEROGENEITY_PROTOCOL.md CCPP conventions; 05d:119–120.

The 176-row 2013 grid omits CCPP and exact-score clustering paths included in the 208-row 2017 CCPP implementation.

**Remedy/test:** confirm symmetric protocol applicability, add only those two branches (32 rows), and show unchanged common-window results. This is missing protocol coverage, not evidence that the main clustering rule is wrong.

### 13. [P2] Review/approval is inherited by path rather than reviewed bytes

**Sources:** 07:82–102,119–136; metadata/publication-review-registry.csv; _publication_review_pack.do:199–204,318–323.

A regenerated same-path file receives historical preliminary review, and could inherit future owner approval, despite changed contents. Generation-manifest integrity does not establish review identity. A dated SHA ledger exists, but this Stata path does not enforce it; the separate Python checker does.

**Remedy/test:** bind review/approval to the reviewed fingerprint; changed bytes stop or revert to held/not-reviewed. Current owner flags remain zero; no unauthorized current release alleged.

### 14. [P2] Standalone publication can combine stale mechanism synthesis

**Sources:** 07:39–81,119–133; 06:863–871.

Module 07 checks artifact-vs-generation manifest, not module 06's recorded upstream module-04 identity. Fresh 04 plus old self-consistent 06 can be accepted. Sequential run_all avoids this if 06 completes.

**Remedy/test:** validate recorded upstream identity before consuming mechanism outputs. Change upstream identity without regenerating 06 and require rejection.

### 15. [P2] Release audit can leave invalid approvals unblocked

**Source:** 08:59–67,118–142.

Selected rows with owner_approved missing or 2 are ineligible yet can receive no block_reason, allowing overall PASS when other rows clear.

**Remedy/test:** binary schema assertion and selected-row eligible-or-blocked invariant. Current all-zero inventory remains intentionally BLOCKED. Test missing/extended missing/2, not just normal zero.

### 16. [P2] Resumable search chunks lack a common generation identity

**Source:** 03:250,1179–1248,1502–1519,2736.

Valid disjoint old/new chunks can assemble 96,524 unique rows after code/data/protocol changes, while final manifest claims current input identity.

**Remedy/test:** common input/code/protocol fingerprints for all milestones and equality before assembly. Historical mixing is not established. This module remains disabled even under routine run_all; do not rerun the search as a repair.

### 17. [P2] Generated metadata/notes do not consistently describe the implemented models

**Sources:** 03b:624–629,655–658; 04f:1145,1391; 06:671; code/stata/README.md:40–42,67–70.

Six current unweighted parametric diagnostic rows say kernel=triangular. The 2017 person registry note says eight outcomes share one complete sample despite the approved migration population; its secondary note calls current attendance an attainment proxy. The original mechanism association table calls 2017-source altitude “2007 altitude.” README still describes installation/fallback behavior the locked master no longer permits.

**Remedy/test:** correct producing notes/metadata and documentation only; do not change estimators to fit labels. Validate generated text against registry/source, and prove numerical invariance. Hard-coded strength-success wording is covered in finding 3. The separate repaired publication A28 note is not evidence that the original generator note was fixed.

### 18. [P2] HTML extraction's configurable completeness claim is unsupported

**Source:** extract_reporte_ccpp_html.py:312–316,347.

expected-departments other than 25 bypasses completeness validation but the manifest still claims complete department codes.

**Remedy/test:** implement the requested count or reject unsupported values; emit true validated status. No extractor or Raw file changed.

## Maintainability: keep the architecture, remove demonstrated drift only

The useful structure should remain: one source-sectioned preparation entry point, explicit master order, wave/level-specific outcome modules, typed postfiles, meaningful registry loops, and narrowly scoped common HTE kernels. No new folder/build/dispatcher framework is warranted.

Concrete consolidation candidates after correctness repairs and preserved baselines:

- 05a's duplicate IV/conditional implementation has diverged from the common engine (findings 3,9,12).
- Six main modules repeat strength-status and multiplicity logic (3,10). Share only mechanical validation/adjustment with a clear contract; keep actual research specifications visible.
- Census assisted-source normalization/cohort setup is repeated around 01:9910–10020 and10070–10141. A single validated tempfile milestone could reduce drift without a generic importer.
- Presentation-only regeneration should eventually consume stored results where feasible. Do not reorganize merely to imitate Higgins or an institutional template.
- Fuzzy QA priority labels use unguarded missing score margins in several preparation sections; acceptance is separately adjudicated. Treat this as QA-label cleanup, not evidence of automatic false matches.

## Code-to-research/output map

| Entry point | Main products and authoritative map |
| --- | --- |
| 00_master / lib environment | Configuration, software gate, explicit ordered do calls; no routine external extraction |
| 01 preparation | Source-family intermediates in Working; analytical CCPP/household/person data in Coded; source-specific metadata/docs |
| 02 descriptives | Descriptive figures/tables; metadata/output-manifest.csv |
| 03 historical search | Opt-in exploration only; metadata/rd-design-output-manifest.csv |
| 03b fixed validation | Density/covariate/first-stage diagnostics; metadata/rd-validation-output-manifest.csv |
| 04 plus six wave/level scripts | All main/secondary estimates, graphs, contracts; metadata/rd-outcome-output-manifest*.csv |
| 05 plus six scripts/shared engine | Pooled fuzzy-IV HTE primary, assignment-only checks and held extensions; metadata/rd-heterogeneity-output-manifest*.csv |
| 06 / selection helper | Migration/intermediate/association/selection synthesis; metadata/rd-mechanism-output-manifest.csv |
| 07 / review helper | Publication candidates and internal reviewed exhibits; publication manifests/review registries |
| 08 | Release audit; passing execution is not release permission |

The manifests are the per-artifact mapping; this table does not replace them. Historical code stays historical and must never silently become an alternative production entry point. The [legacy audit](STATA_LEGACY_CODE_AUDIT_2026-11-01.md) records historical porting hazards separately, without changing any snapshot.

## Verification performed and what it establishes

1. Fresh Git/root/branch/remotes/status and full code inventory. No pre-existing changes.
2. Eight existing Python environment-lock unit tests pass. They validate fixtures, not the real host lock.
3. Real-host SHA checker fails 534 checks as above.
4. In-console Stata-only synthetic checks confirm missing comparisons, byte-age loss, failed-fit gate inconsistency and registered-versus-returned Holm arithmetic. No new .do file or synthetic dataset saved.
5. Stata read-only aggregate checks: common-primary-sample KP F = **10.486603,11.096713,11.101703,54.916052,21.044512,21.055425** in 2013 CCPP/household/person then2017 CCPP/household/person order; six HTE files have passing-gate counts 0/0/23/48/16/68 and zero checked passing/failed-missing inconsistencies; six parametric diagnostic labels are currently triangular.
6. Existing identification/publication Python audit passes: 99 reviewed exhibits, documentary source hashes, 35 review exhibits and287 source rows, with release holds retained.
7. Existing diagnostic integration source/hash check passes: 19 full-width diagnostics plus formal table,20 matching new inputs and35 prior inputs retained.
8. Optional archived-PDF check did not run: the supplied old build directory contained no online_appendix.pdf. The source/hash portion passes without that optional argument. No new compilation or rendered-image audit claimed.

### Minimal synthetic reproductions

Run only through stata_run_selection in a disposable frame; these are behavior tests, not empirical results.

~~~stata
display (. > 10)                  // 1: missing cannot clear strength
display (.a >= 14)                // 1: age eligibility needs a finite guard

generate byte age_key = age       // fixture ages100,101,120,missing
assert missing(age_key) if inlist(age,101,120)

local fit_rc = 504
local support = 1
local min_sw = 25
local idp = .01
local gate = (`support' & `min_sw'>10 & `min_sw'<. & `idp'<.05)
assert `gate'==1 & `fit_rc'!=0  // reproduces independent gate/status defect

display .007*7                    // .049: returned tests
display .007*8                    // .056: registered family
~~~

## Correction order and scientific-change boundary

1. Preserve baseline artifacts and establish the authorized software route. Resolve destructive path/ingestion and release-identity safeguards first.
2. Add focused synthetic regression cases before each targeted production fix: ages, key precision, election fallback, roster identity, financing, finite gates, binary evaluation.
3. Measure actual restricted-data incidence through Stata MCP, outputting only safe aggregate comparisons. Any corrected data/linkage/estimand change requires its own explicit decision record and downstream regeneration.
4. Adjudicate fixed multiplicity family and secondary diagnostic coverage; implement approved corrections without searching samples/windows or weakening gates.
5. Fill missing registered sensitivities; repair generator notes/metadata, prove numerical invariance for presentation-only work, and inspect final artifacts at manuscript size.
6. Re-run the final documented master from a clean qualified environment, compare IDs/contents/missingness/samples/coefficients/inference/figure data against the preserved baseline, then review exact output identities before any authorized live-paper integration.

No single audit can guarantee absence of error. This batch does not certify all input values, causal assumptions, package licensing, historical computing conditions, another machine, concurrent Dropbox execution, final rendered paper, or public release. Findings remain open; no scientific behavior was intentionally changed.

