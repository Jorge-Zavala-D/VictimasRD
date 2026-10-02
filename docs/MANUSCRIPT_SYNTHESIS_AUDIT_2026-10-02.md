# Introduction, conclusion, abstract and title: writing audit

## Completed writing scope

The owner authorized the final writing batch in the approved
[manuscript revision plan](MANUSCRIPT_FRAMING_AND_REWRITE_PLAN_2026-10-02.md).
The introduction and conclusion were drafted first, and the abstract and
shared title metadata were then aligned with that evidence-to-claim route.
This is completion of a bounded writing milestone, not scientific approval
of the whole paper or permission to release its exhibits.

Preflight found a clean primary checkout on `main`, HEAD
`8ec4c8fb4f8cfecc6ba7577addd8476f24c518c2`. The live source root was resolved
from ignored `config/paths.local.do`. Exactly these existing files in
`World Development Manuscript` changed:

- `sections/01_introduction.tex`: development question, actual priority rule,
  sources and local design, complete primary-evidence summary, observation
  boundaries, extensions, literature contribution and section roadmap.
- `sections/08_conclusion.tex`: findings, distinct evaluation objects,
  bounded policy implications and two specific future measurement priorities.
- `sections/00_abstract.tex`: one self-contained paragraph, no citations;
  local design, maintained treatment-year assumption, multiplicity,
  migration uncertainty and selection boundary remain visible.
- `paper_metadata.tex`: title, short title and keywords; JEL classifications
  preserved. The title is **Collective Reparations, Local Development, and
  Mobility in Peru**. It does not promise demonstrated transformation or
  unmeasured political feedback.

All section labels, filenames and main-document dependencies are preserved.
The bibliography, completed sections 02--07, appendices A--F, administrative
sources, and legacy manuscript were not edited. No generated table or figure
was inserted, copied, manually changed or released. No Stata execution,
re-estimation, data preparation or dataset write was needed.

## Central promise and reconciliation

The paper asks what a local financing contrast reveals about material
conditions and observed mobility under a collective-project reparations
program. It distinguishes changes in a place, the circumstances of original
residents, and the reparative meaning of redress. The administrative measures
only address parts of the first two objects. The last remains unmeasured.

| Claim in the new prose | Frozen evidence and decision | Interpretation retained |
| --- | --- | --- |
| Local priority margin | Official joint A/B priority and administrative/territorial conditions; adjacent B/C support in Apurimac, Huancavelica, La Convencion and Huancayo | Not a strict national A-before-B queue, a national impact or a new sample |
| Treatment through 2012/2016 | Existing `treat_12`/`treat_16` contract; CMAN list year assumed to denote allocation and delivery | Not independently verified completion or interview-date exposure |
| Primary results | Six year--level `rd_*_results.csv` files, eight `common_h_fuzzy` primary rows each; all 48 pointwise robust intervals include zero; no within-family Holm p<0.05 | Not an equivalence test, global 48-test adjustment or proof of no effect |
| Individual movement | 2017 I03: +21.448185 points, interval [-17.242022,60.138393]; displayed +21.45 [-17.24,60.14] | Linked people aged at least 14 with valid canonical origin/destination codes; local 7,680 people in 63 communities; not all original residents, a relative percent increase or necessarily rural--urban migration |
| Household observation | 2017 D05 `common_h_primary_observed`: -29.710552 points, interval [-52.199474,-7.2216296]; displayed -29.71 [-52.20,-7.22] | Raw assignment/availability diagnostic, not a material receipt effect or the separate person-linkage test |
| Extensions | 63 diagnostic-screened common-window receipt contrasts have no adjusted rejection; 270 supported assignment-only contrasts include 15 adjusted signals; 37 intermediate-outcome candidates, seven instrument-screened, have no adjusted rejection | Assignment signals do not become receipt heterogeneity; contemporaneous associations do not identify causal mediation |
| Sensitivity dependence | The existing results and Appendix D retain the two adjusted parametric signals and their non-rejecting primary fuzzy counterparts | No favorable sensitivity replaces the primary specification |
| Future work | Previously planned 2025 Census extension and currently unmeasured recognition/participation | Prospective directions, not acquired data, an identified new treatment round or an automatic selection repair |

The interpretation remains conditional on continuity, exclusion,
monotonicity and defensible observation. Historical first-stage-based
geographic selection is not presented as prospective preregistration;
conventional intervals do not account for that historical search.
Community-balanced person/household estimates are not nationally weighted
estimates, and related aggregation levels are not independent replications.
Destination conditions are not silently treated as complete origin-community
conditions. No unsupported inverse-probability weighting or causal bound is
claimed to recover the missing source population.

## Literature and official-source verification

Both required literature integrations were consulted read-only. Zotero
resolved the exact shared `IE Collective Reparations Peru` library, ID 5,
and supplied item/attachment identities and metadata. Targeted attachment
retrieval for Laplante--Theidon and Gready--Robins returned `No paper context
available`; it is not represented as successful source reading. The explicit
project-URL NotebookLM query failed. Its health result was unauthenticated
and named a different active notebook; no unrelated notebook synthesis was
used and no authentication or library state was changed.

The fallback was direct reading of the immutable project source PDFs,
checking their title/author/year and supporting passages against the
unchanged bibliography. This is targeted framing verification, not a new
systematic review of every source in either library.

| Existing key | Underlying passage checked this batch | Warrant and boundary |
| --- | --- | --- |
| `laplante_truth_2007` | PDF p. 2 / printed p. 229; DOI 10.1353/hrq.2007.0009 | Peru-based interpretive evidence that testimony creates demands for acknowledgment and concrete redress; not a current causal program evaluation |
| `gready_transitional_2014` | PDF pp. 8--9 / printed pp. 346--347; DOI 10.1093/ijtj/iju013 | Socioeconomic conditions, local agency, and the danger of substituting ordinary development for reparations; conceptual argument, not a measured mechanism |
| `firchow_must_2013` | PDF pp. 3, 11 / printed pp. 51, 59; DOI 10.1080/15423166.2013.863689 | Colombia-focused collective-project/development tension with an explicit Peru comparison; not relabeled a Peru causal study |
| `guarin_reparations_2023` | PDF pp. 4--5 / printed pp. 1--2; DOI 10.32468/be.1236 | Colombian individual lump-sum program, linked records and event studies; the cited 2023 working-paper version, not an asserted later publication or imported effect size |
| `adhikari_should_2018` | PDF p. 17 / printed p. 15; DOI 10.1596/1813-9450-8525 | Cash-transfer mobility responses depend on program design and household incentives; municipal projects are not household cash |
| `cman_informe_2012`, `cman_informe_2013` | Immutable official intake PDFs, pp. 7--9 and 49--50 respectively; source register and hashes also pass the publication checker | Joint high/very-high priority, registration/accountability, inherited commitments and territorial implementation; not universal adherence or constant historical assignment |

The official World Development author guide again returned HTTP 403.
The abstract's 250-word ceiling is therefore an existing internal drafting
budget, not a newly verified journal requirement. The abstract contains
203 whitespace-counted TeX-source words; the source-file totals are 211
for the abstract file, 1,186 for the introduction and 493 for the conclusion.
These are reproducible source-token counts, not a certified journal count.
World Development writing, literature-positioning and identification skills
kept the development question and local warrant explicit. Economics-writing
guidance placed the result and uncertainty before the literature discussion
and avoided a claim of methodological or measured-feedback novelty.

## Preservation and executable validation

The ignored `build/manuscript-synthesis-2026-10-02/` folder holds a fresh
461-path SHA-256 baseline, the four original live sources, a small read-only
check, an isolated compilation mirror and the reused PDF inspection helper.
No raw, linked, working or coded observations were copied into that folder.

`check_synthesis.py` passes: exactly four authorized live sources changed,
457 other protected files are byte-identical, citations resolve, the primary
cells and migration/availability values reconcile, and all 35 review exhibits
retain `owner_approved=0`, `release_eligible=0`, `hold_no_sync`. Separate
read-only CSV checks reconcile the extension counts in the table above.

The existing `check_identification_publication_review.py --review-pack`
also passes: 99 reviewed exhibits/94 original candidates, ten documentary
records/eight new sources, all 35 review exhibits and all 287 aggregate source
rows, with source hashes and negative controls intact. No validation rule or
empirical contract was weakened to obtain these results.

The full multi-file main manuscript compiles locally through the existing
TeX Live helper, exit code 0, to **37 pages**. Its thirteen actual TeX source
inputs and shared bibliography byte-match the live inputs. The final log
contains no LaTeX/package warnings, undefined citations or references, or
overfull/underfull boxes. All 37 pages were rendered and checked for glyph
bounds/unresolved citation markers; the contact sheet and all affected pages
(1--5 and 32--33) were visually inspected for readable typography, wrapping
and clipping. The preview does not insert held empirical exhibits.

Main-preview SHA-256:
`3C9A1FA7D97B301405CCF75085207841D3AEEF2ECFC34ECECECF1F321416C720`.

Because the metadata is shared, the unchanged Online Appendix and title-page
template were also compiled in the isolated mirror: 44 and one pages,
respectively, with clean final logs. Their new title strings and every-page
glyph bounds were checked, and their first pages rendered and inspected.
The shorter heading can change pagination without changing appendix sources.
The title-page's existing affiliation/contact, funding, acknowledgement and
declaration text was neither corrected nor certified; remaining placeholders
are not submission-ready. The main preview was queued for the Codex panel;
queued status does not establish that the user has already seen it.

## Execution decisions and final review

Rulings recorded in the ignored ledger:

1. Retain the explicitly authorized uncommitted primary `main` workflow and
   existing ignored audit/build pattern; no worktree, staging, commit or push.
   Software-specific workspace/commit steps cannot broaden authorization.
2. Human prose does not earn production-code TDD under the skill's own
   writing-good-tests guidance. Use source/numeric verification, preservation,
   real compilation, visual review and one fresh-context final reviewer;
   no test framework or new analysis program is needed.
3. Use the approved World Development internal abstract budget rather than
   the generic economics-writing 150-word recommendation. Journal compliance
   remains unverified where official access is unavailable.

The executing-plans skill's single fresh-context final reviewer approved
this bounded writing milestone: **no Critical, Important or actionable Minor
finding**. The reviewer independently compared all four originals and drafts,
read the surrounding completed sections, reran the read-only claim/scope
check and `git diff --check`, verified the main preview's page count/hash,
and inspected all affected pages. The five targeted underlying literature
passages were independently checked, and both discovery integrations were
consulted. No reviewer edit, Stata run, Git mutation, re-review or fix pass
was needed. There are no deferred minors.

The reviewer expressly did not certify causal identification, raw-data or
analysis-code correctness, complete literature coverage/current journal
policy, official CMAN documents independently, independent compilation or
all-page/admin-preview review, or scientific/disclosure/submission clearance.
These exclusions were adjudicated as appropriate boundaries of a frozen-
evidence writing review, not hidden missing checks: root performed the
official-source, full compilation and all-page rendering checks documented
above, while scientific/release claims remain conditional or held. The
specific scope decisions and costs are retained in the ignored ledger.

## Next milestone and release boundary

The next step is a whole-manuscript integration/readability audit and a
publication-production preflight: reconcile central claims across all
sections and appendices, assess length/repetition and exhibit placement,
then address transparency/administrative components and each held exhibit's
scientific, disclosure and owner review. Do not merge later sensitivity
signals into the abstract or insert exhibits merely because prose compiles.
The writing milestone does not clear the whole-paper `BLOCKED` status,
authorize submission, or assert that administrative declarations and Online
Appendix F are already final. No team approval or historical risk-set record
acquisition is silently reopened by this recommendation.
