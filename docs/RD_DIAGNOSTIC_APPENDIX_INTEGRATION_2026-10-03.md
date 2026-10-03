# Complete RD diagnostic appendix integration - 3 October 2026

## Approval and scope

The owner's instruction to fully implement the next immediate task approves
the internal-draft integration described in
[the election-note repair receipt](RD_ELECTION_TIMING_NOTE_REPAIR_2026-10-03.md).
All 19 reviewed diagnostic PNGs and the existing Stata-generated formal
continuity table are now included in the active World Development manuscript's
Online Appendix C. No new sample, variable, estimator, treatment horizon,
bandwidth, test family, causal interpretation or public-release approval is
introduced. The legacy manuscript and earlier dated review records are preserved.

The formal table is one additional reviewed input required by that next-step
description, not a manually rewritten publication table. Its bytes are unchanged.
The previous 35 approved inputs plus these 20 inputs give **55 internal-draft
exhibits: 31 tables and 24 figures**. This does not promote generation-time
`generated_unreviewed` records or confer submission/disclosure clearance.

## Exact live changes

The root is resolved from ignored `config/paths.local.do`, not a machine-specific
path embedded in tracked analysis code. Beneath `World Development Manuscript`:

- All 19 canonical PNG basenames are copied unchanged into
  `figures/rd_diagnostics_review_2026-10-03/`.
- The unchanged `tab_rd_validation_03_covariates.tex` is copied into
  `tables/rd_diagnostics_review_2026-10-03/`.
- New `appendix/C_diagnostic_figures.tex` consumes all 20 inputs, with one
  full-text-width plot per page, readable typeset notes and a clean break before
  Appendix D.
- `appendix/C_rd_design_validity.tex` replaces the now-obsolete integration hold
  with the current internal-draft status and calls the complete supplement.
- `sections/04_empirical_strategy.tex` adds a compact pointer to the complete
  score/covariate diagnostic supplement.

These are 21 new live files and two edits to existing live sources. No live
generated table or figure was manually edited. All 35 previous input copies
retain their canonical SHA-256 hashes. PDF, log, auxiliary, render and temporary
files are confined to the ignored local build area, not the Overleaf tree.

## Scientific and interpretation checks

The supplement states the correct denominator: **549 selected geographic B/C
communities, 294 below and 255 above**, not the full 5,712-row RUV universe.
Measure-specific missingness and diagnostic bandwidths explain varying effective
sample sizes. The common primary-outcome window is unchanged.

The historical 11-measure core family and six-measure Census-2007 timing family
remain intact. The table's historical *Predetermined measures* heading is
explicitly qualified: geographic proxies come from a 2017 source, GDP
concentration uses the source's 2007 population allocation, and the 2006 election
cycle includes 2007 replacement contests. All six 2007 measures retain their
rollout-overlap caution. The two eligible replacement-election communities and
the one within each affected diagnostic bandwidth remain visible in figure notes.

For the 17 covariates, formal table coefficients are in standardized units;
the plots display unstandardized values or documented transformations. Bin-mean
95% intervals are distinguished from the formal district-CR2 robust
bias-corrected tests. The unconstrained fits are not clipped to binary/share
support. The population plot uses the **natural logarithm**, not log(1+population).
GDP is not relabeled household welfare or inequality, and unverified source
monetary units are not invented.

All **23 formal rows / 115 cells** match the frozen CR2 CSV after its documented
three-decimal formatting. The 17 covariate rows comprise 11 core and six timing
tests; six additional rows concern community-level source coverage, not Census
2017 person linkage. Three constant-availability rows have no reported probability
and are not treated as estimable continuity tests.

BH and Holm adjustments were independently recomputed in the existing 11/6
families. The two nominal core discrepancies remain explicit: IHS district GDP
in 2006 (p=0.025576457, BH=0.2592362463, Holm=0.2813410312) and effective municipal
lists in 2002 (p=0.047133863, BH=0.2592362463, Holm=0.4713386297). No adjusted
covariate rejection is described as proof of equivalence or causal validity.
The density diagnostic's p=0.63712507 and effective 91/53 observations retain
rounding and finite-support cautions. Smooth-looking curves do not certify
absence of manipulation. No availability result establishes ignorable linkage,
exclusion or monotonicity.

## Fresh verification evidence

The checkout began clean on `main`, at
`cc5dbe4d7d30d4db94b6c493bb789349b9a167f5`. A fresh immutable baseline protects
**980 existing paths**: the versioned project, the existing synchronized Overleaf
tree and the canonical community diagnostic input. Only the two listed live
source edits and the new current-status paragraph in `docs/PROJECT_CONTEXT.md`
are permitted existing-file changes. This is bounded preservation evidence,
not a new exhaustive raw-data or 75-GB pipeline audit.

The new read-only checker first failed against the real live appendix with
`Complete diagnostic family not consumed: 0/19`; it then passed after integration.
It checks all 19 static full-width dependencies, unique/order-complete figures,
source/copy/generation relationships, actual compiled labels, and the distinction
between historical review holds and current internal approval. No Stata command
was needed for this copy/source-only task; no Stata executable, shell analysis,
new `.do` file or new estimation run was used.

The existing 99-item review checker, 35-item publication pack, 287 source-cell
contract, frozen narrative values, negative controls and eight documentary-source
hashes pass again. The preceding 19-image graphical closeout and frozen formal
BH/Holm checks also pass. All versioned analytical code, numerical CSVs, canonical
outputs, data destinations and diagnostic input bytes remain unchanged. Logs and
row-level datasets were not copied into Git or Overleaf.

Both projects compile from an isolated source/asset mirror that is
checksum-identical to the live source. No undefined citation/reference, duplicate
label/destination or overfull box remains. The **41-key citation set** and shared
bibliography are unchanged. All 55 consumed input files match their canonical
copies; the new 19 PDF images match canonical RGB pixels exactly and are placed
at **468 pt / 165.1 mm**, with no half-width/composite placement.

The new supplement is **C.9, pages 39-60**. The formal table is **Table A16,
page 41**; the figures are **Figures A2-A20, pages 42-60**. Appendix D starts
cleanly on page 61. The navigation register records actual document numbers
and pages for all 55 exhibits; artifact IDs are not mistaken for document numbers.
The full-width table, all 19 graph pages, narrative qualifications and affected
transitions were visually reviewed. The final 40-page main paper and 94-page
appendix also received a complete contact-sheet layout overview, not a new
substantive audit of every unchanged page. Machine checks additionally cover
text bounds and dependency consistency. Small embedded Stata notes remain at the
previously reviewed size, approximately 6.8 pt, supplemented by larger typeset
notes. This is internal-draft clearance, not certification of publisher font
requirements or of reduced-width placement.

## Literature access

The exact Zotero shared library `IE Collective Reparations Peru` was resolved
and queried read-only. Its clustered-RD attachment retrieval returned no usable
passages; the underlying local Bartalotti-Brummet PDF was checked instead.
NotebookLM was consulted at the explicit Peru project URL but again returned an
authentication/HTML failure. No unrelated default notebook, new bibliography
entry, invented citation, library mutation or fresh full-corpus-read claim was used.
The existing verified methods and scientific boundaries remain unchanged.

## Records and previews

- `metadata/publication-diagnostic-integration-2026-10-03.csv`: 20 new exact
  input paths, canonical/copied hashes, generator/run provenance and separate
  internal/public approval fields.
- `metadata/publication-diagnostic-source-audit-2026-10-03.csv`: before/after
  hashes for the two edited and one created live sources.
- `metadata/publication-integrated-navigation-2026-10-03.csv`: all 55 current
  compiled exhibit labels/numbers/pages.
- `code/python/check_rd_diagnostic_integration.py`: reusable read-only
  dependency/hash/compilation checker; it does not invoke Stata or modify data.
- `build/rd-diagnostic-integration-2026-10-03/`: ignored baseline, binding brief,
  ledger, isolated source mirror, compile diagnostics, numerical reconciliation,
  protected-scope results and rendered review pages.

Current ignored previews:

- `build/rd-diagnostic-integration-2026-10-03/compile/main-preview/main.pdf`:
  **40 pages**; SHA-256
  `b882db7cc90bec942a8df7ab204e6a648e3f7d5ab9fbc013d084d6c4e1d039b1`.
- `build/rd-diagnostic-integration-2026-10-03/compile/appendix-preview/online_appendix.pdf`:
  **94 pages**; SHA-256
  `00f9c9120fd6581a7f5de5a6e2bc630122cd9466a77ef3caad4333e680793a14`.

## Independent closeout and next step

A fresh independent, read-only review of this complete batch found no Critical,
Important or actionable Minor defects in the authorized internal integration.
It independently rehashed the protected baseline, source mirror and all 55
consumed exhibits; reconciled the 23-row formal table and the 11/6 multiplicity
families; and inspected every new diagnostic figure, the formal table and the
final section transitions. All 19 embedded images match canonical RGB pixels
and span 468 pt. The review confirmed all 55 navigation entries and the current
internal-only approval record, without altering historical review flags.

The review does not certify raw-data correctness, full pipeline reproducibility,
causal identification, journal font compliance, a new full-corpus literature
review, administrative readiness or disclosure/public release. It reviewed the
new supplement and relevant transitions rather than substantively rereviewing
every unchanged manuscript page. These are explicit scope boundaries, not
waived checks. Final preservation and integration checks passed after recording
this verdict. No files are staged, committed or pushed, and no submission or
public release is approved.

The immediate remaining production workflow is software-version/dependency
locking, followed by administrative/submission-file and artifact-level disclosure
preflight. Existing author-provided information should be preserved, not inferred
or invented. This integration does not justify renewed sample search, another
estimation strategy or treating diagnostics as proof of identification.
