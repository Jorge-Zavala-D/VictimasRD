# Municipal-election graphical timing-note repair - 3 October 2026

## Binding decision and scope

The owner's instruction to fully implement the next workflow step authorizes
the three additional election-timing note-only repairs identified and held in
[the preceding graphical audit](RD_GRAPHICAL_PUBLICATION_AUDIT_2026-10-03.md).
That receipt and its 16-candidate/three-held registry remain preserved as dated
historical evidence. This receipt and
[the current 19-row review registry](../metadata/rd-graphical-review-after-election-notes-2026-10-03.csv)
supersede only their outstanding repair disposition and current artifact hashes.

The authoritative generator remains
`code/stata/pipeline/03b_validate_rd_assumptions.do`. Only G11-G13 are repaired:
the 2006-cycle turnout, victory-margin, and APRA-mayor continuity plots, numbered
18-20 by the Stata program. Their source note now reads:

> The 2006 cycle includes 2007 replacement elections; these measures are timing-sensitive.

The source attribution is on a separate line to preserve visibility. No title,
axis, observation, variable, sample, estimate, bandwidth, formal test, variance
branch, or registered multiplicity family is changed. In particular, the three
tests stay in their existing 11-variable core family; the six-variable 2007
timing-sensitive family is unchanged. Historical family membership is not proof
that every component is genuinely predetermined.

All 19 diagnostic figures are now **reviewed internal candidates, pending owner
integration**. Their specific election-note repair hold is resolved; none is
approved for live Overleaf integration or public release. The previous approval
of 35 internal-draft exhibits does not extend to these 19. Generation-manifest
`generated_unreviewed` fields remain intact; review is a separate dated event.

## Source timing and unchanged numerical evidence

[The electoral source workflow](MUNICIPAL_ELECTIONS_PREPARATION.md#timing-and-inference-cautions)
already documents that the 2006 cycle includes 22 replacement results observed
in 2007 nationally, identified by `elect_result_year_2006` and
`elect_complementary_2006`. A fresh aggregate Stata check finds two such records
among the 549 eligible B/C communities. Both have nonmissing values for all
three affected measures; one enters each existing effective MSE bandwidth.
These counts describe overlapping diagnostic subsets, not three different
replacement communities. No record is removed or reassigned.

The canonical input is the configured Dropbox Coded
`08_community_registry_elections.dta`. All 5,712 RUV observations are preserved,
with Stata signature `5712:283(61209):2588972924:1448729060`. The frozen geography
contains 1,162 observations; the adjacent B/C universe contains 549. These are
selected-sample RD diagnostics, not the full RUV distribution.

| Diagnostic | Nominal robust p | Effective N below/above | Replacement inputs/effective |
|---|---:|---:|---:|
| Municipal turnout, 2006 cycle | 0.43698364 | 71 / 44 | 2 / 1 |
| Municipal victory margin, 2006 cycle | 0.27083415 | 49 / 26 | 2 / 1 |
| APRA mayor, 2006 cycle | 0.72501308 | 83 / 47 | 2 / 1 |

Each measure was checked in raw units and in the standardized units used by
the existing formal table, before and after the note repair. The procedure is
unchanged: local-linear `rdrobust`, quadratic bias correction, triangular kernel,
MSE-optimal bandwidth, district CR2 variance, mass-point adjustment, and the
existing rounding-band exclusion. Frozen p-values pass tolerance 0.0000005;
bandwidths pass 0.00000001; effective N agrees exactly. Raw/standardized p-values
agree within 0.00001 and bandwidths within 0.000001. These are comparison
tolerances, not changes to estimation or inference.

The three-row before/after numerical CSV is byte-identical, SHA-256
`ce4bddfd057f8ce10022807eee62962875b627cf653ff75d88412b459d368a2e`.
It records aggregate model statistics only, not research observations. All 17
formal covariate rows, denominators, p-values, bandwidths, and family adjustments
in the current artifact registry agree with the unchanged frozen results.
BH and Holm values were independently recalculated within the existing 11/6
families and agree within 0.0000005.

The previous density and covariate interpretation limits remain binding. The
absence of adjusted rejections is not proof of balance, no manipulation, or
causal validity. The nominal GDP and 2002 effective-list discrepancies remain
visible. Plot bars are bin-mean confidence intervals, not district-CR2 intervals;
the subtitles identify the separate formal CR2 test. No binary/share fits or
intervals are truncated to their outcome support. Common primary-outcome
bandwidths, all 48 registered primary tests, linkage/selection boundaries, and
other analytical results are untouched.

## Execution, provenance, and protected scope

The batch began on clean `main` at
`e90fda02d125daa529b18ae06cdb29b2188ff20c`, after the owner committed the preceding
batch. There were no pre-existing uncommitted changes. The fresh baseline
protects 898 paths: 801 tracked files and the needed live publication inputs
and canonical input dataset. This is a bounded protected-input check, not a
new exhaustive audit of all Dropbox files.

- All Stata commands used MCP `stata_run_selection`, in the isolated
  `rd_election_note_20261003` session. The user's default session was not changed
  or destroyed. No ad hoc `.do` file, shell Stata invocation, or `stata_run_file`
  was used.
- The configured, already installed PLUS cache and `plotplainblind` scheme
  were verified; no packages were installed or upgraded.
- The three original rendered notes failed the missing-caveat tests. The three
  repaired Stata SVGs pass semantic and note-position/clipping checks. SVGs are
  ignored review intermediates, not new canonical publication formats.
- The original three PNGs were reproduced before editing. All 19 current
  canonical PNGs were then reproduced through their authoritative graphical
  producing selections, byte-identically. Exactly three canonical PNGs changed
  from this batch's baseline; the other 16 are unchanged.
- All 36 manifest checksums pass in Stata before and after regeneration. Only
  checksum and run-ID fields in the three repaired rows change. The other 33
  rows retain their field values. The repair run is
  `03oct2026_155404_election_notes`.
- Existing publication-review checks pass for the 99-item review snapshot,
  documentary source hashes, and 35-exhibit internal review pack; all release
  holds are intact. This is not another complete master/data-preparation run.
- No Raw, archive, Working, or Coded dataset is changed. No data is copied into
  Git/build. All protected live TeX, bibliography, and 35 approved live artifact
  copies are unchanged. No live synchronization, staging, commit, or push occurs.

The six allowed modifications to existing protected files are the producing
Stata program, its manifest, three PNGs, and `PROJECT_CONTEXT.md`. The two new
versioned paths are this receipt and the superseding artifact registry. The
preceding receipt and registry are preserved, not rewritten as if the notes had
always been correct. Baseline/current fields in the new registry retain the
original audit baseline and current cumulative hashes; the local fresh baseline
separately records this batch's starting hashes.

NotebookLM was consulted at the explicit Peru project URL but returned an
authentication/HTML failure. Zotero's exact shared library
`IE Collective Reparations Peru` was consulted read-only; metadata was available.
Neither was used to infer administrative election timing or claim fresh
attachment/full-corpus verification. The existing source workflow and canonical
data fields support this provenance qualification; no new academic claim or
citation is introduced.

## Actual-size inspection and current review boundary

The ignored 19-page review packet is
`build/rd-election-note-repair-2026-10-03/rd-diagnostics-after-election-notes.pdf`,
SHA-256 `8bc0b824ab0d816c007a0f09e5d881e8959d385bd93232de93e0874f9d09416a`.
Each page embeds the canonical 3,000-by-2,100 PNG at the current manuscript's
165.1 mm (6.5-inch) full width, approximately 462 ppi. All 19 embedded images
match canonical RGB pixels exactly. The repaired pages 11-13 were visually
inspected at this width: title/subtitle remain one line, source and timing notes
are visible, and no clipping or overlap was observed. The unchanged 16 source
plots retain the preceding full-width review; the new packet layout is checked
separately. Poppler reports display-font lookup warnings, but the inspected
pages have no missing or damaged glyphs.

Bottom notes remain approximately 6.8 pt at this full width. This is internal
review clearance only, not certification of a publisher's font minimum.
Half-width or composite placement is not cleared. The source limitations on
2017 geographic proxies, GDP source units and 2007 population allocation,
2007 Census timing, and linkage selection remain necessary qualifications.

## Next publication decision

The next step is a **separate, explicitly authorized internal-draft integration
of the complete 19-figure diagnostic family** at full width in an Online
Appendix C supplement, with the formal family table and the full interpretation
qualifications available to readers. Do not select only reassuring plots or
place all 19 in the main article. The existing formal table's historical
"Predetermined measures" label must be explicitly qualified in surrounding
appendix text (including the 2007 replacement returns) rather than interpreted
as proof that every registered core measure predates rollout. Any generated
table wording repair must originate in Stata, not a manual Overleaf edit.

Integration requires exact-path/checksum checks and a fresh appendix
compilation. It does not authorize public release or submission. Remaining
software-version locking, administrative/submission-file completion, and
disclosure/public-release approval follow that decision; no new sample search
or estimation strategy is required by this repair.

## Independent closeout

A fresh read-only reviewer inspected the full uncommitted batch and all 19
current packet pages: repaired pages 11-13 at 120 dpi and the other pages at
90 dpi. The reviewer independently rehashed all 898 protected paths, checked
all 19 replicas and canonical embedded RGB images, reran the original failing
and repaired passing note checks, verified frozen formal values and family
adjustments, and inspected the aggregate Stata execution log. The result is
zero Critical findings, zero Important findings within this batch, and zero
actionable Minor findings. The three original note defects are resolved.

The acknowledged approximately 6.8-point notes and the formal table's historical
family heading remain explicit downstream qualifications, not newly certified
publication properties. The reviewer did not rerun Stata or infer causal
identification, linkage ignorability, integration approval, or release readiness.
No reviewer files were changed. Final protected-scope, artifact/registry/PDF,
publication-review, and whitespace checks pass; no files are staged, committed,
or pushed. Completion applies to these three note repairs and their bounded
checks, not the entire research project or a release-ready manuscript.
