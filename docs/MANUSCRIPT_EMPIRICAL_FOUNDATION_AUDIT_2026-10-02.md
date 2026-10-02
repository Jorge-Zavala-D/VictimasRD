# Empirical-foundation manuscript audit and validation receipt

Date: 2 October 2026. Status: **writing batch validated; publication release remains held**.

## Scope and authoritative destinations

The owner approved the first writing batch in
[the framing and revision plan](MANUSCRIPT_FRAMING_AND_REWRITE_PLAN_2026-10-02.md).
The configured Overleaf root was read from ignored `config/paths.local.do`.
The existing `World Development Manuscript` remains the editable draft; no
second paper scaffold or authoritative bibliography was created.

| Live source relative to the configured Overleaf root | Work completed |
| --- | --- |
| `World Development Manuscript/sections/03_data_measurement.tex` | Data sources, treatment timing assumptions, populations, measurement and linkage boundaries. |
| `World Development Manuscript/sections/04_empirical_strategy.tex` | Local contrast, conditional fuzzy-RD interpretation, support, bandwidths, weights, inference, multiplicity and sensitivity hierarchy. |
| `World Development Manuscript/appendix/B_data_construction_linkage.tex` | Source accounting, identifiers, construction rules, six primary outcome families and population eligibility. |
| `World Development Manuscript/appendix/C_rd_design_validity.tex` | Retrospective design search, discrete-score diagnostics, baseline continuity, first-stage checks and observation/selection limits. |
| `Bibliography.bib` | Eight source-verified methods entries appended; existing entry text and keys preserved. |
| `World Development Manuscript/online_appendix.tex` | Existing shared bibliography activated for appendix methods citations. |

The four substantive drafts contain approximately 6,200 whitespace-separated
words/tokens, including TeX commands. Other manuscript sections remain unchanged
scaffolds. The two held-exhibit slots in B and C are intentional: no generated
table or figure was inserted or synchronized in this batch.

## Empirical accounting checked against current records

The current aggregate ledgers and executable construction/estimation definitions
were checked rather than carrying historical manuscript counts forward.

| Component | Current fact used | Evidence |
| --- | --- | --- |
| RUV master | All 5,712 supplied communities retained; 591 unresolved community codes. | `metadata/ccpp-linkage/foundational-sample-flow.csv`; approved source adjudication. |
| CMAN receipt | 4,433 source rows; 210 CMAN-only rows excluded from the RUV universe; 4,221 treated and 1,491 untreated RUV communities. CMAN year is the sole allocation-and-delivery timing assumption. | Foundational flow; owner treatment contract and pipeline definitions. |
| Fixed geography/support | 1,162 selected communities; 549 in recorded adjacent B/C categories. Common estimation window: 71 communities, 45 left and 26 right; bias window: 122. | `output/tables/rd_validation/rd_validation_support.csv`; module-04 definitions. |
| Census 2007 | Supplied workbook has 45,677 communities in 22 departments; 4,933 RUV links and 779 unmatched. It is not represented as a verified complete national census extract. | `metadata/census-2007/sample-flow.csv`; preparation records. |
| SISFOH | Linked RUV frame includes 1,425,575 people, 415,007 households and 4,881 communities. Individual and household construction and aggregation remain distinct. | `metadata/sisfoh-2013/sample-flow.csv`; variable contract. |
| Census 2017 delivery | Original delivery: 193,376 source people. Adjudicated analytical cohort: 193,342 people, of whom 150,832 are linked and 42,510 unlinked. Delivery, source coverage, linkage and observed movement are different denominators. | `metadata/census-2017/sample-flow.csv`; source crosswalk; selection audit. |
| 2017 place quantities | Population and occupied-dwelling counts come from the separate INEI settlement-directory workbooks, not from the assisted person-linkage cohort or the GeoGPS population field. | Independent 26-workbook directory block in data preparation; geospatial source records. |
| 2017 outcome windows | Seven non-movement individual outcomes: 5,948 complete-case people in 62 communities. Primary observed movement: 7,680 linked people with known age at least 14 and valid canonical movement in 63 communities. Household primary: 2,935 complete-case households in 62 communities. | Module-04 eligibility; `output/tables/rd_mechanisms/rd_census2017_selection_flow.csv`. |

The manuscript retains treatment through 2012 for SISFOH 2013 and through 2016
for Census 2017. It does not reopen acquisition of unavailable dated RUV scores,
registration histories or annual eligibility lists.

## Independent review and corrections

Three read-only reviews independently examined data/population accounting,
econometric claims, and references/manuscript dependencies. Findings were
addressed before the final source checks and compilation:

1. Separated independent 2017 place population/dwelling measures from assisted
   cohort measures. Their primary CCPP eligibility still requires assisted-source
   coverage and the registered joint complete-case rule.
2. Distinguished the eight-outcome complete-case rule used for the seven
   non-movement individual outcomes from the broader approved primary observed-
   movement population. Corrected ambiguous references to a seven-outcome rule.
3. Described Ranracancha as a corroborated source code, not a corrected source
   identifier; distinguished the canonical RUV geographic correction.
4. Corrected the -9.82-percentage-point linkage diagnostic to the share of
   source-household members linked, not an indicator for any linked member.
5. Limited the first-stage/reduced-form/fuzzy reporting chain to primary outcome
   specifications; not every sensitivity separately reports a reduced form.
6. Distinguished the 17 substantive baseline covariate plots from table-only
   source/linkage indicators. Nonrejection is not evidence of equivalence.
7. Correctly named the squared robust RD z-statistic as a descriptive strength
   diagnostic, separate from the local-IV Kleibergen-Paap F gate. F greater than
   10 is an operational screen, not a theorem or guarantee of strong identification.
8. Clarified that common h = 0.0075 and b = 0.0135 do not imply identical effective
   samples, score support or first stages across outcomes; effects on binary
   variables and shares are expressed in percentage points.

The draft discloses retrospective geographic/cutoff exploration, finite score
support, score-side versus recorded-category rules, conditional fuzzy-LATE
assumptions, post-treatment control restrictions and outcome-family multiplicity.
It does not claim selection ignorability from a nonsignificant diagnostic, a
population-wide adult correction, identified causal trimming bounds, or causal
mediation from contemporaneous measures.

## Historical discrepancies retained transparently

Some older preparation/context passages predate the approved adjudication and
regeneration. They were not silently rewritten as if they had always described
the current data. Current ledgers supersede these historical counts for drafting.

| Older record | Superseding current accounting |
| --- | --- |
| RUV code coverage: 5,120 assigned / 592 unresolved. | 5,121 assigned / 591 unresolved. |
| All-age observed movement: 146,410 people, 45,695 CCPP movers, 33,067 district movers. | 147,083 people, 45,846 CCPP movers, 33,182 district movers. |
| Destination-household categories: 66,436 total; 27,276 complete and 37,933 partial. | 66,427 total; 27,274 complete and 37,926 partial. |
| First-pass person identifiers: 191,832. | 191,798 first-pass plus 442 and 165 supplemental links; 192,405 resolved identifiers. |
| Old common-window flow: 71 to 65 to 62 communities. | 71 RUV communities; 64 assisted-source-covered; 63 with linked/observed movement. Household complete-case eligibility has 62. |

These are documentation reconciliation findings, not a new recoding or estimate.
See [the source adjudication](CENSUS_2017_SOURCE_ADJUDICATION_2026-09-27.md)
and [the selection-feasibility record](CENSUS_2017_SELECTION_FEASIBILITY_2026-09-30.md).

## Literature and passage verification

Both the project NotebookLM and shared Zotero library `IE Collective
Reparations Peru` were consulted read-only. NotebookLM synthesis was used for
discovery, not as a citation or a substitute for reading underlying sources.
The following eight additions were verified in original papers/books; locators
are PDF pages unless a printed page is explicitly stated.

| Bibliography key | Verified source and supporting locator |
| --- | --- |
| `calonico_robust_2014` | [Calonico, Cattaneo and Titiunik (2014)](https://rdpackages.github.io/references/Calonico-Cattaneo-Titiunik_2014_ECMA.pdf), DOI 10.3982/ECTA11757. Pages 1-3: bias correction and inference; page 5, Remark 1: limited support caution. |
| `calonico_covariates_2019` | [Calonico et al. (2019)](https://maxhfarrell.com/research/Calonico-Cattaneo-Farrell-Titiunik2019_REStat.pdf), DOI 10.1162/rest_a_00760. Pages 4-5, Lemma 1: covariate adjustment and continuity conditions. |
| `cattaneo_density_2020` | [Cattaneo, Jansson and Ma (2020)](https://rdpackages.github.io/references/Cattaneo-Jansson-Ma_2020_JASA.pdf), DOI 10.1080/01621459.2019.1635480. Pages 3-4: smoothness assumptions and density testing. |
| `kolesar_discrete_2018` | [Kolesar and Rothe (2018)](https://arxiv.org/pdf/1606.04086), DOI 10.1257/aer.20160945. Pages 2-3: discrete/rounded score distinction and limits of score clustering. |
| `cattaneo_extensions_2024` | [Cattaneo, Idrobo and Titiunik (2024)](https://mdcattaneo.github.io/books/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf), DOI 10.1017/9781009441896. Pages 43-45: fuzzy assumptions; page 48: F-threshold caveat; pages 58-66: discrete support. |
| `dong_selection_2019` | [Dong (2019)](https://yingyingdong.com/Research/J14_JBES.pdf), DOI 10.1080/07350015.2017.1302880. Pages 2 and 4: joint selection/outcome assumptions. Final article: JBES 37(1), 171-186; author PDF reflects earlier online pagination. |
| `holm_simple_1979` | [Holm (1979)](https://www.ime.usp.br/~abe/lista/pdf4R8xPVzCnX.pdf), DOI 10.2307/4615733. Printed pages 66-67: sequential rejection procedure and error control. |
| `calonico_rdrobust_2017` | [Calonico et al. (2017)](https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell-Titiunik_2017_Stata.pdf), DOI 10.1177/1536867X1701700208. Page 1 and command documentation: estimation and inference implementation. |

Two existing entries were also checked in the underlying PDFs: Gelman and
Imbens (2019), `gelman_why_2019`, and Bartalotti and Brummet (2017), existing key
`cattaneo_regression_2017`. The latter key is misleading but was preserved to
avoid breaking existing citations; its authorship is correctly printed.

## Final validation and preservation receipt

- The writing-specific read-only check passed: four substantive sources, ten
  resolving citation keys, eight append-only bibliography entries, no duplicate
  keys, preserved UTF-8 and no machine-specific paths in manuscript prose.
- A before/after SHA-256 manifest covers 142 protected files. Exactly the six
  authorized live inputs changed; all 136 others were unchanged, including
  protected legacy manuscript sources, existing publication inputs and outputs.
- Existing `code/python/check_identification_publication_review.py --review-pack`
  passed against the configured Dropbox root: 99 reviewed items, 94 original
  candidates, ten documentary records/eight new source hashes, 35 review
  exhibits and all 287 source rows. All exhibit holds remained intact.
- The corrected multi-file main manuscript and online appendix compiled with
  existing TinyTeX/latexmk, exit 0, in an isolated ignored Git-side source copy.
  No package was installed and no compiler auxiliary file was written to live
  Overleaf. Final logs had no LaTeX warning, error, undefined-reference,
  overfull-box or underfull-box matches.
- Main preview: 14 pages. Appendix preview: 16 pages. All 30 pages rendered,
  passed text-boundary checks and received visual inspection; detailed equation
  and selection-diagnostic pages were also inspected at full page size.
- No Stata command, analysis rerun, dataset write, generated-table/figure edit,
  staging operation, commit, push or exhibit synchronization occurred.

Ignored reproducibility evidence is under `build/manuscript-foundation-2026-10-02/`:
`before-sha256.json`, six source backups, `check_foundation.py`,
`inspect_previews.py`, isolated compile inputs/logs and all rendered pages.
The previews are `compile/main-preview/main.pdf` and
`compile/appendix-preview/online_appendix.pdf`. SHA-256:

```text
main.pdf: 8D9070CDD9E2E4AA302F311024F4A998B5D5DCB37F8E6F7E37D7DCEB39783676
online_appendix.pdf: 2849E5E2A2808DFB7EEBB026F1695C6199869AC90C8E369E6031CFB768D4F89B
legacy Working Paper.tex: 142756E6E22AB27206D75DD192456BE0A6D14FB192EEB8F2BD461F10514B0A9A
```

## Boundaries and next batch

This is validation of source fidelity, specified accounting, citation support,
compilation and preservation for the writing batch. It is not resolution of
all causal-identification assumptions or journal/submission compliance.
All 35 review exhibits retain `owner_approved=0`, `release_eligible=0`,
`release_action=hold_no_sync`; the publication packet remains held.

The next planned writing batch is
`sections/02_context_framework.tex` and `appendix/A_program_data.tex`: explain
the reparations institution, actual priority rule and conceptual pathways using
verified official and academic sources, without promising unmeasured justice,
population-wide migration or causal mediation. Results, extensions and the
introduction/abstract follow in the previously approved sequence. Artifact-level
release approval and exact destination/checksum reconciliation remain separate
before live table/figure insertion.
