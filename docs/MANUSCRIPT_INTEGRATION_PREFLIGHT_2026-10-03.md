# Integrated manuscript audit and production preflight

## Outcome and authority

The owner authorized the integrated whole-manuscript reader audit and
publication-production preflight, including a deep assessment of the work
completed so far. The audit began on 2 October and continued on 3 October
2026. The primary checkout was clean on `main` at
`162aa7fbab933ec5a609b796bc791638993a53a6` before this batch.

The manuscript's central promise remains a **conditional, local assessment
of collective-project reparations**, with uncertain material and movement
effects and explicit observation limits. It is not a demonstrated migration
effect, national impact estimate, identified mediation analysis, or evaluation
of recognition and reconciliation. No data, estimator, outcome family,
sample, treatment horizon, cutoff, weighting rule or frozen estimate changed.
No generated exhibit was edited, synchronized, inserted or approved.

This milestone completes the reader integration, verified transparency draft,
administrative update and a bounded artifact/contract preflight. It does
**not** certify every raw record or every line of the 40,686-line Stata tree,
and is not a signed, saturated full Econ Review certification. Technical
integrity, scientific interpretation, disclosure and publication clearance
remain distinct.

## Repairs and integration decisions

| Issue | Implemented decision | Evidence or constraint |
| --- | --- | --- |
| Repeated context/timing/design/extension recaps | Shorten four passages in the introduction, context, results and extensions; retain the detailed contracts in their best section and cross-reference them | No uncertainty, treatment horizon, outcome unit or observation warning was removed |
| Movement definition too broad in Appendix A | Restrict the age-14+ definition to the primary individual outcome; distinguish community/source-household observed-member denominators | Appendix B construction and current individual sample contract |
| Directory population mislabeled as linked-cohort population in Appendix E | Call P01 log 2017 directory population, estimated within the cohort-covered complete-outcome community sample | Outcome registry; `01_data_preparation.do` imports directory population; `04d` transforms `population_2017` at line 60; no linked-person count is substituted |
| Household-availability numerical locator pointed to Appendix B | Point to Appendix C, where the estimate is actually reported; clarify the antecedent of descriptive movement intervals | C and D report the -29.71 pp diagnostic; B explains denominators |
| Nineteen-row social-program inventory promised as a separate display in D | Say the frozen records belong to the main/secondary hierarchy summarized in D | D summarizes coverage, rather than displaying a separate 19-row inventory |
| Undecoded source/unit acronyms | Introduce INEI and the SISFOH registry at first use; expand SISFOH in data and CCPP in the standalone appendix | Multidisciplinary reader navigation, not new measures |
| Appendix F and declarations remained scaffolds | Write the access, storage, master order, prerequisites, software, provenance, audit limits and AI-assistance account | Existing code/contracts plus current access/ethics confirmations; no invented public deposit or unrestricted microdata release |
| Highlights contained placeholders and a wrong generic character rule | Supply four finding-focused draft highlights, lengths 79/66/78/81 characters including spaces | Current general Elsevier rule: 3--5 items, maximum 85 characters; not a substitute for the live journal guide |
| Future exhibit dependency absent | Load `longtable` in the shared preamble | All 30 held TeX derivatives use it; this was a future integration dependency, not a current compile failure |
| Stale administrative/scaffold prose | Replace the cover letter and checklist scaffolds with substantive internal drafts and explicit open gates; remove the obsolete citation-activation comment | No assertion of submission, exclusivity, coauthor approval or completed public release |
| Obsolete Module 06 manifest size in pipeline README | Correct 12 to 18 | Current code, manifest and tests agree on 18 |

The abstract, title metadata, empirical strategy, robustness synthesis,
conclusion and frozen main-results Appendix D were not rewritten in this
batch. The four repetition cuts and brief acronym additions reduce core
section prose from **8,614 to 8,436 TeXcount words**. Main text including the
abstract and completed review declarations is about **8,869 prose words**;
the final counts are saved in the ignored audit folder. The abstract has
**205 text words**. Headers, captions and mathematics are counted separately;
these counts exclude the rendered bibliography and do not certify an
unavailable journal-specific counting rule. The appendix grows because its
previous transparency scaffold is now substantive, not because empirical
results were added.

## Author information, ethics and access

The owner explicitly directed that the prior paper's author information,
funding and sponsor information remain unchanged, and confirmed:

- no competing interests;
- ethics exemption because the study uses administrative census data;
- research access granted by INEI and CMAN;
- the collective-reparations project list is publicly accessible through CMAN.

The identifying title-page/declaration sources retain the prior author order,
affiliations, correspondence emails, acknowledgements and named research
fund/project. Those fields come from the preserved legacy front matter,
not inferred author profiles. The obvious university-name accent/typographic
error is normalized without changing the institution or funder. No new grant
identifier, sponsor-role claim or full postal address was invented.

The previous paper's funding footnote also said ethics approval was given
through the supported project. The owner's latest statement instead describes
an exemption. The live declaration accurately attributes the current exemption
position to the authors; it does not invent an approval number or formal
exemption certificate. The legacy source is untouched. Institutional supporting
records and the relationship between those two formulations should be retained
and reconciled before final submission, without reopening the owner-approved
empirical workflow.

Research access is **not redistribution permission**. Restricted observations,
linkage identifiers and row-level QA stay outside Git and the publication tree.
Author-level CRediT roles, a required full postal address, any exact sponsor
roles not specified previously, originality/exclusivity and approval of the
submitted version are not certified by this audit. The separate identifying
draft states these boundaries instead of inventing contributions or approvals.

## Fresh numerical and technical verification

Three independent discovery lenses inspected the reader narrative, pipeline
contracts and exhibits. Their findings were reconciled centrally before edits.
Prior receipts were used for provenance and orientation, not as current proof.

| Object | Current verification |
| --- | --- |
| Primary module-04 evidence | All 48 `common_h_fuzzy` primary estimate/interval triples reconcile with Appendix D at displayed precision; every robust 95% interval includes zero and no within-family Holm rejection occurs |
| Primary individual movement | +21.45 pp, [-17.24, 60.14], 7,680 people/63 communities; seven other individual outcomes retain 5,948/62 |
| Migration eligibility | MCP-only read of the current analytical file: zero selected B/C or local observations with observed movement and missing age; known-age adults 67,648 overall and 7,680 locally |
| Household observation diagnostic | -29.710552 pp, [-52.199474, -7.2216296], raw p=.0096158301, 4,051 source households/64 clusters; remains an assignment/availability diagnostic |
| Receipt heterogeneity | 320 common-window interaction contrasts, 63 passing gates; no tier-adjusted rejection. Gate counts 0/0/8 in 2013 and 24/8/23 in 2017 |
| Assignment heterogeneity | 270 supported contrasts, 15 adjusted signals; all 15 printed triples match. Assignment effects are not receipt effects |
| Candidate intermediate outcomes | All 37 printed cards reconcile, including unavailable KP values; seven pass the reporting gate, none rejects raw or adjusted |
| Noncausal associations | All six printed cards match the share-to-pp conversion; 60 CCPP/42 districts, ecological associations rather than identified mediation |
| Social-program scope | Nineteen 2013 common-window rows, four primary/fifteen secondary; no raw/Holm/BH rejection |
| Publication sources | Existing Python `--review-pack` checker passes: 99 dated exhibits/94 original candidates, ten documentary records/eight new sources, 35 derivatives and all 287 retained source rows, negative controls, hashes and holds |
| Manifest structure | All 20 manifests parse; listed artifacts and generators exist, normalized paths are safe, signatures/checksums are populated, no normalized-path duplicates; per-wave snapshots agree with the current combined manifests |
| Additional current artifacts | Fresh Stata checksums match all 36 descriptive records and all 36 RD-assumption records |
| Existing assertion suite | All 12 tests ran via `stata_run_selection` in a separate audit session: rc=0 for every test, zero failures; none weakened |
| Preservation | A fresh 928-path baseline guards all tracked files and the Overleaf tree plus prior protected sources; only the explicitly listed manuscript/documentation edits are permitted |

The tests are:
`test_census2017_ccpp_heterogeneity_contract`,
`test_census2017_household_heterogeneity_outputs`,
`test_census2017_individual_heterogeneity_outputs`,
`test_census2017_migration_population`,
`test_census2017_selection_feasibility`,
`test_heterogeneity_engine_wave_contract`,
`test_migration_mechanism_outputs`,
`test_migration_mechanism_registry`,
`test_publication_candidate_outputs`,
`test_publication_repairs`,
`test_publication_review_pack` and
`test_release_audit_outputs`.

They assert frozen contracts and aggregates; they do not independently
re-estimate primary models or rebuild raw sources. The July design-search
manifest is a **historical** 21-artifact snapshot, not a claim of current
canonical regeneration. The 261-artifact release inventory remains BLOCKED
with technical checks passing; no candidate is release-eligible.

## Pipeline coverage and inference crosswalk

Every canonical `.do` file was inventoried and scanned for source, storage,
execution-safety and contract patterns. Coverage is explicitly graded below;
the large programs were not reread line by line in their entirety.

| Source | Direct reading coverage |
| --- | --- |
| `00_master.do` | Whole file: paths, package bootstrap, switches, runner and ordered calls |
| `01_data_preparation.do` | Focused source-family/sample, linkage/quarantine, age/movement, missingness, storage and merge assertions; full pattern scan of other internals |
| `02_describe_data.do` | Focused full-RUV/selected sample, project-record denominator, destinations and manifest |
| `03_validate_rd_design.do` | Focused governance, search grids, frozen-sample separation and historical snapshot |
| `03b_validate_rd_assumptions.do` | Focused score/density/covariate/first-stage/local-randomization and inference contracts |
| `04_estimate_main_effects.do` | Whole file |
| `04a`, `04b`, `04c` | Focused 2013 samples, outcomes, primary weights/CR2, parametric IV, multiplicity and output contracts |
| `04d`, `04e` | Focused 2017 directory/cohort/source-household and complete-case samples, CR2, weights, parametric and selection contracts |
| `04f` | Deep focused individual complete-case versus migration override, first stage, weighting, IV/KP and sensitivities |
| `05_estimate_heterogeneity.do` | Whole file |
| `05a` | Focused pooled interaction IV, SW gate, assignment-only checks, multiplicity/projects/dose reporting |
| `05b`, `05c`, `05d`, `05e`, `05f` | Whole files |
| `_heterogeneity_level_engine.do` | Deep focused interacted IV, finite/rank/support gates, weights, identity exclusion and adjustments; export blocks pattern-scanned |
| `06_analyze_migration_mechanisms.do` | Entire module path, including sample-matched KP, associations, selection invocation and 18-artifact closeout |
| `_migration_selection_audit.do` | Whole file |
| `07_build_tables_figures.do`, `_publication_review_pack.do`, `08_run_release_checks.do` | Whole files |
| All twelve `code/stata/tests/*.do` | Whole files and execution-safety inspection; then real MCP execution |

The primary bias-corrected `rdrobust` estimates use district CR2 for community
models and RUV-community CR2 for household/person models. The parametric
`ivreg2` and pooled interaction-IV fits use their conventional cluster-robust
inference, **not CR2**. The interacted model instruments receipt and
receipt-by-moderator with assignment and assignment-by-moderator and fully
interacts running slopes. Conditional SW gates are distinct from supplementary
KP statistics; squared RD z statistics are not the KP instrument gate.

No routine master/pipeline shell, PowerShell, Python or external conversion
call was found. Package bootstrap can install into the ignored local cache,
so the current convenience setup is not a complete environment lock. This
audit installed nothing, ran no production estimator/master, wrote no data
and left the existing busy default Stata session untouched.

## Complete current exhibit pass and placement

All **35** current proposed publication exhibits were traced individually.
Their decimal manifest checksums match, the 34 artifact-valued source paths
match module manifests, and the remaining supplement deliberately references
the combined heterogeneity metadata. All 28 source matches present in the
dated exhibit ledger pass SHA-256; seven supplements are outside that older
ledger. The four forest/sensitivity derivatives are replotted from aggregate
CSVs: their registered original-image paths are provenance links, not claims
of checksum-identical image copying.

The held review PDF's 40 exhibit-containing pages and continuations, all five
standalone derivative PNGs and four original forest/sensitivity PNGs were
visually inspected. The review harness is 11pt A4 (~170 mm text width); the
live paper is 12pt Letter, double-spaced (165.1 mm text width). This is **not**
final live exhibit pagination, because held outputs were not inserted.

Stable audit IDs do not predetermine final manuscript table/figure numbering.
The current six-main/29-support proposal is preserved:

| Planned home | Complete ID set | Reader purpose |
| --- | --- | --- |
| Main results | M01, M02, M03, M04, M05, M06 | Two standardized community forests with raw-unit table companions; individual 2017 family/movement; household observation diagnostic kept visible |
| Appendix B | A12, A15, A19, A23, A29 | Outcome/denominator registries and separate parent-frame flows; A29 only after repair |
| Appendix C | A10, A11, A13, A16, A18, A20, A22, A24, A25 | First stages, distinct coverage/linkage processes, selection-model feasibility and descriptive support intervals; A25 only after repair |
| Appendix D | A01, A02, A14, A17, A21 | Bandwidth sensitivity and complete remaining microdata families |
| Appendix E | A03, A04, A05, A06, A07, A08, A09, A26, A27, A28 | Receipt/assignment reporting gates, project content, intermediate candidates and explicitly noncausal associations |

M01/M03 and M02/M04 are alternative scales of the same outcome families,
not additional independent evidence. If later page economy requires moving
the raw-unit companions to D, make an explicit role decision and update the
registry rather than silently changing this held plan. No release field was
promoted: all 35 remain `owner_approved=0`, `release_eligible=0`,
`generated_unreviewed`, `hold_no_sync`.

## Remaining actionable defects, with no current numerical promotion

| Item | Evidence and consequence | Disposition |
| --- | --- | --- |
| A29 clipped bottom note | Generator `_publication_review_pack.do:506--510`; the right edge loses parent-frame, eight-outcome completeness and selection qualifiers | Repair in Stata generator, regenerate through MCP, inspect standalone and final print-scale figure; do not edit the PNG |
| A25 omitted display units | Generator header at 356, x100 scaling near 396; side levels are percentages and difference bounds are pp | Correct header/note in generator, preserve every cell and noncausal/adult-target warning |
| A28 inaccurate adjustment note | Generator near 377 says 2007 covariates; actual adjustment is 2017-source altitude, log 2007 population and 2007 wellbeing | Correct years plus 60 CCPP/42 districts, unweighted OLS and local SD standardization; do not relabel associations as mediation |
| Known original-output formatting/rounding | Earlier receipts flag original graph clipping/axis and 0.001 endpoint presentation differences; the current retained derivatives do not erase those issues | Preserve holds; repair producing code before any affected original output is consumed. Not all original images were freshly re-inspected |
| Latent older 05a SW fallback | `05a:380--395` computes `min()` without guarding both SW statistics; Stata ignores a missing operand | Future safeguard/test work: require both finite. Current affected passing rows = zero; 32 missing-SW IV rows already fail support. Not a current effect/gate error |
| Explicit age-missing defensive predicate | `04f:129`/`05f:111` use age >=14; Stata missing comparisons deserve a guard | Current observed-movement/missing-age count = zero. Adding a finite-age guard is defensive maintenance, not a correction to current migration numbers |
| Administrative completion | CRediT, postal address, institutional ethics wording/support, exact sponsor-role details if required, submitted-version approvals | Supply/document facts; do not invent them or reopen closed empirical choices |
| Portable final release | Dependency capture, source permissions, restricted-data access explanation, artifact-level scientific/disclosure review and final live exhibit layout | Separate release workflow; a passing checksum is not permission or scientific identification |

## Literature and journal-source checks

The exact shared Zotero library `IE Collective Reparations Peru` was consulted
read-only (39 parent items, targeted passages). Current underlying immutable
PDF passages were checked for Gready/Robins's socioeconomic/local-agency
agenda, Firchow's development/reparations distinction, and Guarin's Colombian
individual lump-sum/event-study comparison. The cited keys across all 27 live
TeX sources resolve to the unchanged shared bibliography. This does not mean
every cited PDF or every historical literature note was reread in full.

The correct public NotebookLM URL was queried explicitly, but the current
session reported unauthenticated and the query failed. No wrong active
notebook was substituted, no fresh synthesis was claimed, and authentication
or libraries were not modified. The underlying source record, not a synthesis
answer, remains authoritative.

Current official publisher guidance confirms the generic
[Elsevier highlights rule](https://www.elsevier.support/publishing/answer/how-do-i-include-highlights-with-my-manuscript)
and the need to disclose substantive AI assistance, including research-process
use under the
[Elsevier journal policy](https://www.elsevier.com/about/policies-and-standards/generative-ai-policies-for-journals).
The direct World Development Guide for Authors returned HTTP 403. Exact live
journal word-count exclusions, note policy, upload formats, anonymization and
artwork requirements remain unverified, not silently imported from an older
skill or template. Abstract/main-length targets are explicitly internal
working budgets until that check succeeds.

## Production verification and preservation

The ignored `build/manuscript-integration-2026-10-02/` folder preserves the
original 27 editable TeX sources, baseline hashes, a small reusable assertion
check, word counts, an isolated compile mirror and rendered previews. No
raw, working, coded or linked data was copied there. Its assertion check
allows only the 18 named live source edits and the context/README documentation
changes; all analytical `.do` files, registries, output artifacts, configuration,
shared bibliography, legacy publication sources and protected external
documents remain byte-identical.

The first compile exposed the mirror's relative bibliography lookup; the
shared bibliography copy was placed at the output-parent lookup and the
cached BibTeX error was rebuilt. No live TeX citation was deleted to make
the build pass. All seven current documents then compiled with the installed
TeX Live compiler and the existing compile helper: main, online appendix,
title page, identifying declarations, highlights, cover letter and checklist.
The title-page spacing was tightened to keep its conflict declaration on the
same single page. A short AI heading avoids an awkward heading-word split.
The identifying declarations and internal cover letter use single spacing;
their final one-page previews have no orphaned headings or closing text.

The complete main/appendix page-render and text-bound checks pass (37 and
48 pages). The five administrative previews have 1/1/1/1/2 pages (title,
declarations, highlights, cover letter, checklist): 91 pages across seven PDFs.
All 27 mirrored TeX sources and both bibliography mirrors are checksum-identical
to the live sources. Final LaTeX logs have no undefined references/citations,
multiply defined labels or overfull boxes. One pre-existing BibTeX metadata
warning remains: the United Nations 2005 entry has an empty institution field.
The shared bibliography is preserved; that small metadata cleanup is not a
missing citation or a compilation failure. The reused
render helper's one-digit filename padding was corrected after its original
two-digit assumption failed on short documents; no PDF content was changed
to hide that diagnostic failure. Final preview hashes, log/reference checks,
visual observations and the independent final review are recorded in the
ignored batch ledger. Compilation remains a **local isolated validation**,
not a claim that Overleaf's cloud compiler has run.

One fresh-context, read-only final reviewer inspected all 18 live source diffs,
the three Git candidates, current numerical sources, dependency/cache evidence
and compiled layouts. The reviewer independently reconciled all 48 primary
estimate/interval triples, the receipt/assignment heterogeneity accounting,
37 intermediate-outcome cards and six association cards. The verdict was:
**accept this internal integration/preflight batch; not ready for submission
or public release**, with no unresolved Critical or Important issue. A small
counter-record omission was corrected: saved length diagnostics now include
inline/display math counts (main 101/1; appendix 318/1). This changed no prose
or estimates. The reviewer did not independently rerun Stata or re-adjudicate
all raw records, cited PDFs or original exhibits.

Git retains this receipt, the latest context pointer and the corrected
pipeline README. The authorized live edits remain in the synchronized
publication tree. No raw/archive file, dataset, generated exhibit or
bibliography was replaced. Nothing was staged, committed, pushed, submitted
or cleared for public release.

## Next bounded milestone

Implement the generator-level A25/A28/A29 repairs and defensive finite-value
guards with focused failing checks, regenerate only the affected non-sensitive
outputs through Stata MCP, recheck numerical invariance/manifests, and inspect
the proposed exhibits at the live manuscript's final scale. Then complete the
artifact-level scientific/disclosure/release decisions and exact live exhibit
integration. Preserve the frozen evidence and the existing empirical contracts;
do not use production polish to promote imprecise estimates or noncausal
mechanism evidence.
