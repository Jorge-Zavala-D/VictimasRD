# Census 2017 source-place adjudication implementation plan

> **For agentic workers:** Execute this plan task by task with the `superpowers:executing-plans` skill if the user chooses native execution. Do not delegate unless the user expressly chooses a subagent workflow.

**Goal:** Correct the two held source-place assignments, regenerate and audit all affected Census 2017 results, then resume publication-candidate review.

**Architecture:** The existing CSV adjudication ledgers remain the only source of place decisions. The existing monolithic `01_data_preparation.do` validates them, preserves the immutable INEI delivery denominator, and produces a smaller RUV-linked analytical cohort. Downstream modules consume only regenerated Coded files; no new data location or external conversion process is introduced.

**Tech stack:** Stata 19 through MCP `stata_run_selection` only; Git-tracked Stata/CSV/Markdown; Dropbox Raw read-only, Working/Coded pipeline writes only.

**Spec:** [Approved source-place adjudication](../../CENSUS_2017_SOURCE_ADJUDICATION_2026-09-27.md).

## Global constraints

- Never edit a Dropbox Raw or archived file; never copy respondent-level data into Git or Overleaf.
- Do not alter the 5,712-community RUV universe, geographic RD selection, treatment timing, cutoffs, or estimand without an additional decision.
- Keep all 193,376 INEI-delivered people in raw-source accounting; quarantine 34 before RUV-linked analysis; retain 836 under verified Ranracancha.
- Run every Stata check and `.do` invocation through `stata_run_selection`, not a shell, direct Stata, or `stata_run_file`.
- Do not stage, commit, push, or sync stale 2017 outputs to Overleaf.

## Review focus

- A request-list code with a conflicting district cell must not override the code's prefix, official geography, and exact SISFOH roster.
- A `9999` SISFOH aggregate code must not be mistaken for the requested ten-digit source code or for a 2017 destination code.
- A misleading `nomccpp` value must not reassign people to Ccahuanhuire, San Cristobal, or another settlement.
- The 34 quarantined people must remain visible in raw/source counts but never receive an RUV outcome or treatment assignment.
- A failed or partial long Stata run must not be mistaken for a fully refreshed publication package.

### Task 1: Pin the adjudication in executable metadata

**Files:** Modify `metadata/census-2017/source-ccpp-crosswalk.csv`, `metadata/ccpp-linkage/ruv-ubigeo-adjudication.csv`, and `metadata/census-2017/historical-to-2017-code-review.csv`. Extend an existing Census test or create `code/stata/tests/test_census2017_source_adjudication.do` only if an existing test cannot express the contract cleanly.

**Interface:** The source crosswalk retains 807 unique historical codes: 806 `accepted` rows with an RUV ID and one `quarantined` row (`0307080005`) with a blank RUV ID. The RUV-code ledger contains one accepted `S03000445 → 0306080001` row and no collision.

- [ ] Write an in-memory Stata assertion selection for those conditions and verify it fails on the current CSVs.
- [ ] Apply only the two binding metadata decisions and update their review dates/evidence locators; preserve other rows.
- [ ] Re-run the assertions; check uniqueness and code-prefix geography. Review the CSV diff for accidental line changes or row-level material.

### Task 2: Correct the preparation boundary

**Files:** Modify `code/stata/pipeline/01_data_preparation.do`; update `docs/CENSUS_2017_PREPARATION.md` and `metadata/census-2017/README.md` for the new raw-versus-analytic distinction.

**Interface:** Crosswalk validation admits only the one named quarantine; all raw-stage counts remain 193,376 people, 150,864 linked, 42,512 unlinked, 58,021 source households. Both reads of the immutable INEI delivery exclude the 34 quarantined records *after* raw accounting but *before* the RUV merge. The resulting analytical counts are 193,342 people, 58,015 source households, and 802 represented RUV communities; confirm them from the real run. Cahuapirhua stays in the 5,712-row RUV registry without Census outcomes. Ranracancha receives canonical code `0306080001` through the existing foundational adjudication, not a special-case person recode.

- [ ] Add a failing Stata in-memory source-to-RUV contract check, including 34 quarantined records and zero accepted records lacking RUV ID.
- [ ] Implement the minimum crosswalk-status guard and cohort filter in both Census-delivery passes; replace only affected hard-coded analytical assertions and sample-flow labels.
- [ ] Run focused Stata selections for key uniqueness, 34/836 source roster reconciliation, the 58,015-household denominator, and the new canonical RUV code before a full data-preparation run.
- [ ] Invoke the existing preparation `.do` from an MCP selection after master configuration. Check the durable log/metadata for completion before any retry; never launch a duplicate run merely because a display call timed out.
- [ ] Compare the regenerated Coded/Working sample flow, source coverage, person linkage, movement observability, RUV universe, geographic selection, and treatment coding against the approved spec. Stop on an unexplained delta.

### Task 3: Re-estimate and validate every dependent analysis

**Files:** Modify only affected count guards in `code/stata/pipeline/04e_census2017_household.do`, `04f_census2017_individual.do`, `05e_census2017_household_heterogeneity.do`, `05f_census2017_individual_heterogeneity.do`, and any Stata tests whose old denominators become false. Regenerated small, non-sensitive outputs and manifests remain at existing paths.

**Interface:** Six module-04 estimators, six module-05 heterogeneity estimators, and module `06_analyze_migration_mechanisms.do` read the newly regenerated authoritative Coded files. No coefficient or p-value is hard-coded in code merely to obtain a pass.

- [ ] Run a before/after comparison on the current vs new 2017 analytic counts, including Ranracancha's 673 linked people, 523 linked adults, 522 same-code destinations, and 151 different-code destinations; independently inspect exceptions.
- [ ] Update only structural guards whose contracts changed, then run each affected analysis through `stata_run_selection` in dependency order.
- [ ] Reconcile person/household/CCPP sample sizes, first stages, effective bandwidth samples, heterogeneity instrument gates, migration outcomes, and revised estimates against logs and output CSVs. Distinguish a change caused by the corrected code from any unrelated regression drift.
- [ ] Revise output tests after independent calculation, not by copying new coefficients into old tests, and execute all impacted tests through `stata_run_selection`.

### Task 4: Publication-review gate and closeout

**Files:** Update `docs/CENSUS_2017_SELECTION_AND_CODE_COMPARABILITY_AUDIT_2026-09-27.md`, `docs/PUBLICATION_RESULTS_AUDIT.md`, affected aggregate Census metadata, and only genuinely regenerated output manifests. Write ignored `build/COMMIT_MESSAGE.txt` for the completed repository batch.

- [ ] Mark the old two-case audit conclusions superseded and document the 889/899 discrepancy, generic `nomccpp` limitation, `9999` rule, and remaining linkage-selection assumptions.
- [ ] Run modules `07_build_tables_figures.do` and `08_run_release_checks.do` through Stata MCP after estimators pass; review the 94 preliminary appendix candidates against new results and disclosure status. Do not sync or publish unreviewed artifacts.
- [ ] Run `graphify update .` after code changes, inspect `git diff --check`, full diff, generated-output sizes, and `git status --short`; ensure no restricted data entered Git.
- [ ] Record validation, data-storage effects, substantive estimate changes, remaining uncertainty, and a copy-ready commit title/body in ignored `build/COMMIT_MESSAGE.txt`. Do not stage, commit, or push.

If a full pipeline run proves infeasible or stops on a pre-existing failure, leave old Census outputs explicitly stale, preserve the last complete Coded files, and report the exact failure and last validated stage rather than claiming the analytical correction is complete.
