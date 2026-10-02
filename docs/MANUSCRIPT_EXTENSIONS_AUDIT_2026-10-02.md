# Mechanisms, heterogeneity and Online Appendix E: drafting audit

Date: 2 October 2026. Status: **this writing batch validated; scientific and exhibit-release holds unchanged**.

## Scope and delivered sources

The owner approved the next manuscript batch: mechanisms/heterogeneity and
Online Appendix E, using frozen module-05 and module-06 evidence. The live
Overleaf root was resolved from ignored `config/paths.local.do`. Exactly three
authorized live files changed:

- `World Development Manuscript/sections/06_mechanisms_heterogeneity.tex`:
  967 whitespace-delimited TeX-source tokens; the four-part evidence hierarchy,
  complete heterogeneity accounting, intermediate outcomes, project content,
  noncausal associations and the causal-mediation boundary.
- `World Development Manuscript/appendix/E_mechanisms_heterogeneity.tex`:
  3,162 source tokens; the pooled local-IV equation, moderators, reporting gates,
  all fifteen adjusted assignment signals, all 37 candidate intermediate rows,
  six associations and eight project-receipt discontinuities, with selection
  and multiplicity qualifications. These counts are not certified journal word
  counts.
- Root `Bibliography.bib`: three source-verified entries appended for Imai,
  Keele and Tingley (2010), the versioned rdhte working paper (2025), and
  Sanderson and Windmeijer (2016). Existing entries were preserved byte-for-byte.

The sources remain in the authoritative live Overleaf tree. Git records this
receipt and the context pointer; ignored build files contain preservation
checks and previews. No generated table or figure was manually edited, copied,
inserted or promoted. The legacy manuscript and prior writing batches were
preserved. The robustness/limitations section, introduction, abstract,
conclusion and transparency appendix remain outside this batch.

The initial checkout was clean, on `main` at `f91727d`. There was no pre-existing
uncommitted repository work. No staging, commit or push occurred.

## Evidence audit and independent review

Three independent read-only reviewers assessed heterogeneity, mechanisms and
inference. No observation-level dataset was opened and no estimator was rerun.

- All **1,456 module-05 aggregate result rows**, 28 CSV schemas and 52 generated
  TeX caption/note/label structures were checked. All **126 manifest artifacts**
  matched their recorded decimal Stata/POSIX checksums across eight manifests.
  This is not a claim to have recomputed SHA-256 for each manifest entry.
- The six main common-window heterogeneity result files were independently
  reconciled to support, return codes, rank/strength gates and multiplicity
  fields. All fifteen assignment-signal cards and eight project-discontinuity
  cards match their frozen estimate/interval cells at displayed precision.
- All **60 mechanism-summary rows** and **67 estimated supporting rows** match
  inherited module-04 estimates, standard errors, intervals, probabilities,
  adjustments and sample counts within the independent review's tolerance of
  1e-6. All 47 unavailable parametric slots remain unavailable, not null results.
- All **37 intermediate-outcome cards** match their estimates, intervals,
  Holm probabilities and available KP displays. All **six association cards**
  match coefficients and intervals after the documented percentage-point
  conversion, with 60 communities and 42 district clusters per fit.
- The reviewer reconciled 54 selection-flow records and six finite-source
  interval calculations; these remain descriptive, not causal selection bounds.
- The existing publication checker freshly passed 99 reviewed exhibits,
  94 original candidates, ten documentary records/eight acquired-source hashes,
  all 35 held review exhibits and all 287 source-cell ledger rows, including
  its negative controls.
- Four existing heterogeneity figures were spot-checked visually. This is
  **not** a fresh visual audit of all 46 frozen heterogeneity figures. Every
  newly produced manuscript-preview page was rendered and reviewed as below.

The final independent closure reviews found no remaining material numerical
or interpretation discrepancy in the corrected extension sources. This
finding concerns the writing batch, not overall scientific identification or
publication release.

## Binding results and interpretation checks

### Receipt-effect heterogeneity

Each estimator has 320 registered common-window contrasts: 112 primary-tier
and 208 secondary-tier. The receipt-effect local-IV gate admits:

| Wave | Community | Household | Individual |
| --- | ---: | ---: | ---: |
| 2013 | 0 of 48 | 0 of 48 | 8 of 64 |
| 2017 | 24 of 48 | 8 of 48 | 23 of 64 |

The 63 admitted contrasts comprise fifteen primary and 48 secondary contrasts.
None rejects after its original tier-specific correction. A failed screen is
not evidence of homogeneous effects, and nonrejection is not equivalence.

The draft gives the pooled local-linear equation explicitly: receipt and
receipt-by-moderator are endogenous; assignment and assignment-by-moderator
are excluded instruments. It retains moderator-specific score and side-slope
terms, triangular kernel, h=0.0075, community-equal microdata weighting and the
specified clustering. Conditional effects are linear combinations of the
same fit, not comparisons of separate significance tests. Conventional
clustered local-IV intervals are not described as rdrobust RBC intervals.

Both conditional F statistics must be available and strictly above the
owner-approved 10 threshold, with underidentification p<.05 and adequate local
support. Neither overall KP nor the other equation's statistic replaces a
missing conditional statistic. The existing fallback validation used a
synthetic 600-observation/60-cluster case and agreed with ivreg2 at six decimal
places; it was **not rerun in this prose batch**, and is not a universal
validation claim. F>10 is a reporting screen, not proof of exclusion,
monotonicity, selection ignorability or strong finite-sample identification.

Current observed-adult movement uses 67,648 eligible linked people in 410
communities, including 7,680 local people in 63 communities. The sex interaction
is +0.95 percentage points, 95% interval [-11.53,13.43], Holm=1.000 and minimum
conditional F=18.07. The other seven individual outcomes retain the distinct
54,812-person complete-case universe and 5,948 local people in 62 communities.
Continuous-moderator reference scaling remains based on that complete-case
universe; the broader movement population was not silently used to rescale it.

### Assignment-only heterogeneity

The rdhte estimates concern cutoff assignment, not receipt. There are 270
supported contrasts, with 40/40/55 in each wave's community/household/individual
families. The fifty unavailable cells are 48 district-capital support failures
and two non-applicable female-outcome/sex-moderator identities. They are not
fifty failed null tests.

Fifteen contrasts pass their inherited adjustment: three primary-moderator
Holm signals and twelve secondary-moderator BH signals. Their six-family counts
are 2/1/3 and 2/6/1. The six 2017 household signals are the largest block, not
a majority of fifteen. All fifteen effects and nominal intervals are retained,
including adverse and compositional results. There is no supported
district-capital comparison or adjusted individual migration interaction.
No new global 270-test correction is claimed. Assignment response is not
receipt-effect heterogeneity, and correlated aggregation levels are not
independent replications.

### Intermediate outcomes and noncausal associations

All 37 labor/connectivity candidate rows are retained: 21 in 2013, sixteen in
2017. Seven have available, passing outcome-sample local-IV KP diagnostics;
thirty have no such diagnostic and remain diagnostic-only fuzzy ratios. No
squared RD z statistic substitutes for KP. No raw probability is below .05;
none survives inherited Holm/BH correction. The seventeen original families
are retained, not replaced with a favorable new mechanism family.

The draft also retains all 57 supporting reduced forms, ten estimated
parametric fits and 47 unavailable slots. Three supporting raw signals fail
their inherited Holm adjustment; they are distinguished from the adjusted
parametric sensitivity signals already documented in Appendix D. Nineteen
2013 social-program outcomes are not added to the 37-row inventory, and there
is no registered 2017 social-program counterpart here.

The six associations are unweighted OLS within the local window, with an
assignment-side intercept, separate score slopes and district-clustered
intervals. Each predictor uses its local complete-case mean/SD. Only each
predictor's adjusted/unadjusted pair is verified as an identical sample;
equal counts across predictors do not establish identical communities.
Adjustment includes log 2007 population, the 2007 core wellbeing proxy and
altitude from the 2017 spatial layer as a fixed geographic proxy.

The adjusted employment association is +6.69 percentage points per predictor
SD, interval [2.18,11.19], raw p=.0046 and BH q=.0139. It is ecological and
noncausal, not an individual employment effect or an indirect reparation
effect. The three adjusted associations form the BH family; unadjusted fits
are descriptive sensitivities outside that correction family.

### Project content and causal mediation

Composition is 199 records through 2012 within 487 complete SISFOH communities,
versus 176 through 2016 within 389 complete Census communities. Productive
shares are 106/199 (53.27%) and 96/176 (54.55%). These different universes and
horizons are not a balanced rollout series. All four group-specific receipt
discontinuities in each wave are retained with nominal unadjusted probabilities.
Unconstrained fitted intervals above 100 points are not literal probabilities.

Realized project type and financing are post-assignment variables. One cutoff
instrument does not identify several endogenous project-type effects; neither
treated-only comparisons nor including type as an ordinary control solves
that problem. All six financing-dose artifacts remain excluded.

The earlier thesis motivates the substantive mechanism question, but exact
exposure/interview/move ordering is unobserved. The 2017 conditions may be
measured at destinations after movement. Noncompliance, treatment-induced
confounding and source/linkage/observability selection remain distinct issues.
No natural direct/indirect effect, ACME, proportion mediated or
product-of-coefficients decomposition is claimed. Post-treatment variables
are not inserted as total-effect controls. Finite-source all-age intervals are
not eligible-adult causal bounds, RD confidence intervals or fuzzy-LATE bounds.

## Literature consultation and underlying-source verification

Both required integrations were consulted read-only. The exact Zotero group
`IE Collective Reparations Peru` resolved to library ID 5. Targeted paper
readers returned no paper context for indexed items; the underlying local
Adhikari--Gentilini and Imai PDFs were read instead. No library mutation,
authentication repair, import or literature-file copy occurred.

NotebookLM again reported unauthenticated with an unrelated active notebook,
but a bounded question to the explicit VictimasRD public notebook URL answered
in session `381650c1`. This is a successful explicit-notebook consultation, not
an authentication repair or exhaustive notebook ingestion. Its source leads
were checked; a Lagakos lead resolving to supplementary material was not
adopted as an unverified article claim.

Underlying sources used for the new or retained substantive claims:

- Adhikari and Gentilini (2018), local source PDF pp. 2, 8--9: migration can
  respond differently to social-protection design. This motivates alternatives,
  not a transported Peru coefficient or identified pathway; the existing
  `adhikari_should_2018` bibliography key was preserved.
- Imai, Keele and Tingley (2010), source PDF pp. 4--5/printed pp. 312--313:
  sequential ignorability and mediator--outcome assumptions are additional to
  intervention assignment. Metadata and the passage were checked against the
  [author-hosted article](https://imai.fas.harvard.edu/research/files/BaronKenny.pdf).
- Calonico et al. (2025), [version 1, Sections 1--2](https://arxiv.org/html/2507.01128v1):
  the rdhte framework is sharp RD. The bibliography explicitly records the
  versioned working paper rather than inventing a journal publication. The
  [authors' software repository](https://github.com/rdpackages/rdhte) was also
  consulted.
- Sanderson and Windmeijer: the conditional-F argument was read in the
  [November 2013 working version](https://www.bristol.ac.uk/media-library/sites/cmpo/migrated/documents/wp315.pdf),
  PDF pp. 2--3 and 18. The published article's author, outlet, volume, pages and
  [DOI](https://doi.org/10.1016/j.jeconom.2015.06.004) were independently verified
  through Crossref. The publisher page returned 403; no final-version page
  locator or final-PDF retrieval is claimed.
- The previously source-verified Cattaneo--Idrobo--Titiunik (2024) RD-extension
  caution and Dong (2019) selection assumptions were retained from the prior
  writing audit, not falsely described as newly reread in full.

Six cited keys resolve in the current bibliography. World Development
identification, robustness, writing-style and exhibit skills guided the
evidence hierarchy, concise development framing, complete-family accounting
and separation of technical validation from causal interpretation.

## Corrections and historical references not promoted

Independent reviews closed after correcting the household-signal plurality,
local association weighting/scaling, cross-predictor sample-identity wording,
continuous-moderator reference scale and failed-gate terminology. The drafts
also avoid inherited association-note claims that the 2013 predictors are
pre-intervention baselines or that altitude was observed in 2007.

Some older documentation or held displays remain superseded, not silently
rewritten outside this scope: the generic complete-case migration wording in
the mechanism/heterogeneity protocols; older movement sample/association
figures in the historical results-audit body; the representative complete-case
sex diagnostic rather than I03's current F=18.07; and a moderator-registry
limitation implying nightlights allocation rather than 2007 population shares.
The new text uses the current population contract and executable definitions.
Artifact-level presentation repairs and any durable historical-note cleanup
remain separate from this frozen-source writing batch.

## Fresh preservation, compilation and visual validation

Ignored `build/manuscript-extensions-2026-10-02/` contains before-source copies,
a 425-path SHA-256 baseline, `check_extensions.py`, the reused multi-file compile
mirror/render helper, logs, page images and preview PDFs.

- The minimal runnable checker passes all 15/37/6/8 printed estimate/interval
  inventories, six heterogeneity gate counts, resolved citations and scope
  checks. Exactly three authorized live files changed; **422 protected files**,
  including frozen evidence and prior/legacy sources, remain unchanged.
- Both multi-file builds succeed with exit code 0: main **28 pages**, online
  appendix **45 pages**. Main-to-appendix references were made literal where
  the two standalone documents do not share labels. Local signal-inventory
  formatting and concise headings removed crowded lines without changing cells.
  Final logs have no warnings, undefined references/citations, overfull or
  underfull boxes.
- All pages were rendered and passed text-bound/glyph checks. Contact sheets,
  every new section/appendix page and the new bibliography entries were visually
  inspected for clipping, wrapping and readability. Remaining scaffold sections
  are clearly placeholders; these PDFs are previews, not completed submissions.

Final live SHA-256 values:

- Section 06: `579FCE82347AF383FAB337ADDB597700B74190D20C88FB8941AF068F255FE2A1`.
- Appendix E: `F8F51ECB3A55BF4EF1B4AF74737A7A351B201F21C3F744AEED23D0B7323F54C4`.
- Bibliography: `B84B4F29847895FAB4B149FA5B411F6BF1C85F983A87D9F0B9E1981742757E5E`.

No Stata run was required and no data, raw/archive material, analysis program,
estimate, sample, treatment rule or adjustment family was changed. All 35
review exhibits retain `owner_approved=0`, `release_eligible=0`, `hold_no_sync`.
The whole-paper release remains **BLOCKED**. Validating prose and compilation
does not remove scientific, disclosure or artifact-owner holds.

## Next milestone

Draft the planned robustness/limitations synthesis from the same frozen
evidence, organized by identification threat rather than favorable result.
It must retain historical design-search selection, score/support and bandwidth
limitations, marginal instruments, observational weighting targets, source
coverage/linkage/observability, post-treatment mechanism boundaries and the two
adjusted parametric sensitivity signals. Introduction, abstract and conclusion
follow afterward. Generated-exhibit repair, review and insertion remain
separate publication-production steps.
