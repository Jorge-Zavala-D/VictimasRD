# RD graphical publication audit — 3 October 2026

## Decision and scope

The owner authorized the next milestone specified in
[the reader/compression receipt](PUBLICATION_READER_COMPRESSION_2026-10-03.md):
artifact-level review of the 19 held RD diagnostic figures outside the 35
already approved internal-draft exhibits. These are the two running-variable
figures and all 17 separate covariate-continuity figures, numbered 08–26 by
`03b_validate_rd_assumptions.do`. This is not an inventory-only review, a new
sample search, or certification of the entire research project.

The owner subsequently approved presentation-only repairs to geographic-source
timing, GDP source units, and the concentration measure's population allocation.
These affect four figures: altitude, nearest district-capital distance, district
GDP in 2006, and district GDP concentration in 2006. Every sample, variable,
estimate, bandwidth, formal test, and registered multiplicity family is held
fixed. The GDP axis wording changes with its explanatory note; no underlying
GDP values or transformation are changed.

All 19 figures have been numerically checked, reproduced through Stata MCP, and
visually inspected at the current manuscript's full text width. Sixteen are
**reviewed internal candidates, pending owner integration**. Three 2006-election
figures (G11–G13) are **held for an existing source-timing note correction** found
by the independent reviewer. This receipt does not authorize copying any of
them to live Overleaf or public release. The four geographic/GDP repairs are
complete; an explicit owner question for the additional three note-only repairs
is pending. Do not extend the existing four-repair approval silently.

## Provenance and denominator checks

The batch began on a clean `main` checkout at
`3f0e7df46355291dde7da9d26e3a8817009feacf`. Its local pre-write baseline protects
896 unique files: 799 tracked files, the needed live publication inputs, and the
canonical input dataset. The live TeX inventory includes generated table inputs;
it is not a count of 90 independently editable manuscript sections.

The input is the configured Dropbox Coded current-analysis
`08_community_registry_elections.dta`, with unchanged Stata signature
`5712:283(61209):2588972924:1448729060`. Its 5,712 RUV observations remain intact.
These diagnostic plots do **not** show the full RUV distribution: they concern
the frozen geographic sample and adjacent B/C categories. The geographic sample
has 1,162 observations; the eligible B/C diagnostic universe has 549, including
294 below and 255 at/above the cutoff. There are 160 and 212 distinct recorded
scores respectively. In this subset there are no score/category sign conflicts
and no observations in the excluded half-rounding band; the closest scores are
approximately -0.00032 and +0.00008 relative to B–C.

The histogram's displayed range is ±0.02 index units, not all eligible support.
Density and covariate effective samples differ from the eligible universe.
Covariate missingness and the existing outcome-specific diagnostic bandwidth
selectors produce effective samples of 75–163 observations. The registry reports
eligible N, formal nonmissing input N, and effective N separately.

## Executed checks and invariance

- All Stata execution used `stata_run_selection`, in the isolated
  `rd_graph_audit_20261003` session. No `stata_run_file`, direct executable,
  PowerShell Stata command, or new interactive `.do` file was used.
- The isolated session initially lacked the project's dependencies in its
  default search path. The master-defined, already installed local PLUS cache
  resolved this. No package was installed or upgraded; the user's separate
  default Stata session was not changed or destroyed.
- All 36 original module-manifest checksums passed before writing artifacts.
  All 36 current checksums passed after the four presentation replacements.
- Before repairs, the existing graphical selections reproduced all 19 original
  PNGs byte-for-byte. After repairs, the final producing selections again
  reproduced all 19 current PNGs byte-for-byte. The other 15 are unchanged from
  the pre-write baseline; exactly four canonical PNGs changed.
- Each of the 17 covariates was estimated in its displayed/raw units and again
  in the standardized units used by the existing formal table. Frozen p-values,
  bandwidths, and effective N passed the declared tolerances. Raw/standardized
  p-values agree within 0.00001, bandwidths within 0.000001, and effective N
  exactly. Frozen p-values agree within 0.0000005 and bandwidths within
  0.00000001. These are numerical-comparison tolerances, not altered tests.
- The complete before/after numerical-audit CSV is byte-identical, SHA-256
  `40f2268d2fdc96faa9c1e2f9fdefe335a5f1b74438f3c5f3d97570a946d579d3`.
  This local non-observation audit record is
  not a new analytical dataset or a public release artifact.
- Execution covered the authoritative graphical producing selections and
  focused numerical checks, not another full master/data-preparation run.
- BH and Holm adjustments were independently recalculated from the frozen
  nominal p-values for the existing 11-variable core and six-variable
  timing-sensitive families, with agreement within 0.0000005. Linkage tests,
  other variance branches, primary outcome families, and outcome estimates were
  not reassigned or rerun by this graphical milestone.
- The manifest's only field-value changes are the checksum and run ID for the
  four repaired PNGs. The remaining 32 rows are unchanged in content; CSV quoting
  was normalized by Stata export. Generation-time `generated_unreviewed` fields
  remain intact. This dated artifact-review registry records a separate review
  event rather than inventing generation-time owner or release approval.
- Independent review prompted one additional aggregate Stata timing check.
  `elect_complementary_2006` and `elect_result_year_2006` identify two 2007
  replacement-election records among the 549 eligible B/C observations. Both
  have nonmissing turnout, victory margin, and mayor-party variables; one
  enters each variable's existing MSE bandwidth. The three re-estimated formal
  p-values still match the frozen values within the original tolerances. These
  are not a new sample restriction or a revised analysis family.

The unchanged formal covariate procedure is local-linear `rdrobust`, triangular
kernel, MSE selector, robust bias-corrected inference, district CR2 variance,
mass-point adjustment, and the existing rounding-band exclusion. Its covariate-
specific diagnostic bandwidths do not change the frozen common bandwidths of
the primary outcome specifications. Scientific numerical tables and all 48
primary estimates remain unchanged.

## Scientific reading and limits

The selected B/C density diagnostic reproduces T = -0.4717222085 and p =
0.63712507, with effective N = 91 below and 53 above. The density plot uses
separate local-quadratic density curves and pointwise 95% intervals; the formal
test uses cubic bias correction and jackknife inference. A nonsignificant test
does not establish no sorting or manipulation, especially for repeated/rounded
scores, finite support, small effective samples, and a historically searched
geographic design. The maintained implementation and the authors' discussion of
test-versus-plot distinctions were checked in the
[official density repository](https://github.com/rdpackages/rddensity) and
[Cattaneo, Jansson, and Ma's Stata article](https://rdpackages.github.io/references/Cattaneo-Jansson-Ma_2018_Stata.pdf).

Two of 11 core covariate tests have nominal p < 0.05:

| Covariate | Nominal p | BH q | Holm p | Effective N |
|---|---:|---:|---:|---:|
| District GDP in 2006 | 0.02558 | 0.25924 | 0.28134 | 111 |
| Effective municipal lists in 2002 | 0.04713 | 0.25924 | 0.47134 | 124 |

Neither survives either registered family correction. None of the six
timing-sensitive 2007 tests rejects after these corrections. This is a statement
about these tests, not proof of balance, equivalence, covariate continuity, or
identification. Both nominal discrepancies must remain visible alongside the
whole family and the full formal table; do not choose plots based on significance.

The 17 covariate figures display quantile-spaced, variance-mimicking binned means
and separate-side local-linear fits. Their 95% bin-mean intervals are graphical,
**not district-clustered CR2 intervals**. The subtitle separately reports the
formal district-CR2 robust bias-corrected test. This distinction was checked
against the installed `rdplot` implementation and
[Calonico, Cattaneo, and Titiunik's RD-plot paper](https://rdpackages.github.io/references/Calonico-Cattaneo-Titiunik_2015_JASA.pdf).
Unconstrained fitted lines or bin intervals may leave the support of binary or
share outcomes; do not truncate them to manufacture reassuring continuity.

The source qualifications are material to interpretation:

- Altitude is a physical attribute observed in the 2017 geographic source,
  not a verified 2006 measurement.
- Nearest district-capital distance uses 2017 code-based capital proxies.
  Historical legal capital status was not independently verified by this audit.
- GDP is a model-based estimate in source units. The workbook display scale is
  unverified; inverse-hyperbolic-sine levels depend on that scale. No PEN unit or
  inflation adjustment is invented.
- The source allocates CCPP economic activity using 2007 population shares.
  Its district concentration measure is settlement primacy, not household
  inequality, a Gini coefficient, or an independently observed 2006 distribution.
- The six 2007 measures retain their registered timing-sensitive diagnostic
  designation because that Census may overlap the first program year. The
  owner's previously approved treatment of 2007 controls is not silently changed.
- The 2006 election-cycle variables include 2007 replacement results. The
  source workflow already documents their timing sensitivity in
  `MUNICIPAL_ELECTIONS_PREPARATION.md`, lines 192–194. The existing G11–G13
  blanket pre-treatment/fixed-before-rollout notes do not disclose this and
  require correction. Do not call these particular plots wholly pre-program
  evidence, remove the two records, or move tests between registered families
  without a separately documented scientific decision. The current audit
  preserves their registered core-family tests and explicitly holds the plots.

NotebookLM was consulted at the explicit Peru project URL but returned an
authentication/HTML failure. Zotero's exact shared library
`IE Collective Reparations Peru` was consulted read-only; metadata was available,
but the targeted paper-context retrieval failed. No fresh full-notebook or
full-Zotero-attachment review is claimed. The underlying author sources and
installed command documentation, not connector-generated summaries, support the
methodological statements above.

## Presentation repairs and actual-size review

The original source-note semantic tests failed for the four affected figures.
The first longer-note candidate then failed the geometric clipping check for
distance, GDP, and concentration. The final producer places each qualification
and its source on separate note lines. All five final semantic/layout tests pass;
all four sources are fully visible in the final Stata exports. The helper's tests
read Stata-generated SVG text and positions, not merely source-code keywords.
SVGs are ignored audit intermediates, not additional canonical publication inputs.

The final audit viewed all 19 PDF-rendered pages at **165.1 mm** figure width,
the current live article's 6.5-inch text width, not the preliminary 174 mm preview.
Each canonical PNG is 3,000 × 2,100 pixels, approximately 462 ppi at that width.
Titles/subtitles fit on one line; axes, legends, plotted intervals, and full
notes are visible with no clipping or overlap in the inspected packet. The
bottom-note type is approximately 6.8 pt at this width: legible in the internal
review, but small. This is **full-width internal review clearance only**.
Half-width/composite use and a publisher's minimum-font requirements are not
cleared. If a publisher requires larger notes, another presentation-only
regeneration and review will be needed; do not downsize these plots.

The ignored 19-page review packet is
`build/rd-graphics-audit-2026-10-03/rd-graphical-diagnostics-review.pdf`, SHA-256
`7eaafd9c979c4ec5f4ba93d131f037dff7714fdb05386d5ea7dd92cec22a0be2`.
Its header explicitly says internal-only and not release-cleared. G11–G13 have
an additional explicit HOLD annotation for the replacement-election timing note.
The packet adds audit annotations; it does not replace the canonical Stata PNGs. Poppler
issued display-font lookup warnings during page rendering, but all 19 pages
rendered and were inspected; no missing or damaged glyph was observed.

## Review registry, protected scope, and next decision

[The 19-row artifact registry](../metadata/rd-graphical-review-2026-10-03.csv)
records original/current SHA-256 and Stata checksums, run IDs, generator and input
identity, formal denominators, p-values and adjustments, interval distinctions,
actual review width/pages, qualifications, and explicit zero owner-integration
and public-release approvals for these additional figures. It separately holds
G11–G13 pending the additional source-note correction.

No Raw, archived, Working, or Coded dataset was changed. No data was copied into
Git or its build cache. The prior 35 reviewed live copies, manuscript sources,
bibliography, existing result/release registries, and all unrelated tracked
files remain protected. The expected baseline deltas are the generating Stata
program, its manifest, four PNGs, and the context pointer to this receipt; the
new receipt and new artifact registry are non-observation documentation.

Immediate decision: approve or defer the three additional election-timing note
repairs, with all scientific results and registered families held fixed. Until
resolved, the three affected plots must not be integrated or called cleared.

After those repairs pass, explicitly approve or decline internal-draft
integration of the **complete** 19-figure diagnostic family at full width in an
Online Appendix C diagnostic supplement, with the formal family table and the
qualifications above available to readers. Do not add 19 plots to the main
article or select only reassuring plots. Integration would be a separate live
publication task, with exact-path/hash checks and a fresh appendix compilation.
Only after that decision should the remaining software-version-lock,
administrative, submission-file, and disclosure/public-release preflight be
closed. No new sample search or estimation strategy is authorized by this audit.

## Independent closeout

The fresh independent read-only review inspected all 19 final pages and
independently confirmed byte-identical RGB pixels between the packet images
and canonical PNGs, the protected-file scope, the five note/layout tests, and
the registered multiplicity adjustments. It identified the Important existing
election-timing note qualification described above. This issue is not concealed
by the passing technical checks and remains held pending owner direction.

Review outcome: zero Critical findings, one Important existing note issue, and
no additional actionable Minor findings. The same reviewer then checked the
corrected 16-candidate/three-held disposition against the receipt, context,
registry, and revised packet. All agree. HOLD annotations occur on exactly
pages 11–13; the held pages' images still match the unchanged canonical PNG
pixels. The Important issue is **transparently contained, not repaired**.
There is no remaining disposition-documentation inconsistency; this does not
clear the three original notes or supply the pending owner approval.

The final protected-file, registry/PDF, Stata checksum, and existing
publication-review checks pass: 896 protected paths, seven allowed changes,
889 unchanged; 19 identical final replicas; four presentation changes; no
unexpected protected-file changes. Technical reproduction and this
bounded graphical review do not certify causal identification or a release-ready
paper. No files have been staged, committed, or pushed.
