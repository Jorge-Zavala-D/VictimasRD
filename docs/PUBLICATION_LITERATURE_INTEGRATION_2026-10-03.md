# Internal-draft exhibit integration and substantive literature audit

## Completed scope and authority

Completed on 3 October 2026 in the primary VictimasRD checkout, on `main` at
`7fe31483dd4eeef5495efb370a4bac10fe9f69db`. The owner explicitly approved
**internal-draft integration of all 35 reviewed publication exhibits** at
their documented destinations. Submission and public-release approval
remain blocked.

This batch places the reviewed, frozen evidence in the active World Development
manuscript and strengthens its substantive argument with verified literature.
It does not conduct a new sample search, change the estimand or outcome registry,
re-estimate a model, or promote a diagnostic result into causal evidence.

The live manuscript root is the configured Overleaf root plus
`World Development Manuscript`; it is resolved from the ignored
`config/paths.local.do`, not hard-coded into analytical programs. The
earlier [integration preflight](MANUSCRIPT_INTEGRATION_PREFLIGHT_2026-10-03.md)
and [corrective production receipt](CORRECTIVE_PUBLICATION_PRODUCTION_2026-10-03.md)
remain dated records of their own batches. Their earlier no-sync statements
do not override the subsequent, specific internal-use approval recorded here.

## Exact exhibit integration

All 35 canonical inputs were first checked in Git and then copied without
editing their contents. The live copies retain the original basenames and
extensions under `tables/publication_review_2026-10-03` and
`figures/publication_review_2026-10-03`. Every copy has the same SHA-256
checksum as its canonical Git source and appears exactly once in an active
manuscript caller.

| Live destination | Reviewed inputs |
| --- | --- |
| Main results, section 5 | M01–M06: four tables and two figures |
| Appendix B, data construction and linkage | A12, A15, A19, A23, A29 |
| Appendix C, RD design and validity | A10, A11, A13, A16, A18, A20, A22, A24, A25 |
| Appendix D, additional results | A01, A02, A14, A17, A21 |
| Appendix E, heterogeneity and mechanisms | A03, A04, A05, A06, A07, A08, A09, A26, A27, A28 |

The set contains **30 TeX tables and five PNG figures**. The dated
[35-row integration ledger](../metadata/publication-draft-integration-2026-10-03.csv)
records canonical paths, live destinations, caller paths, both checksums,
internal approval and continuing public-release holds.

The generated review registry retains its generation-time
`owner_approved=0`, `release_eligible=0` and `hold_no_sync`. Those fields
were not hand-edited. The separate dated approval permits only these exact,
checksum-frozen internal copies; it is neither automatic approval of future
generations nor public-release permission. Appendix F explains that distinction.
The original source/artifact hashes from the A25/A28/A29 corrective review also
remain unchanged.

This bounded 35-input authorization does not include every existing density
or individual covariate plot. Appendix C explicitly distinguishes the formal
diagnostic record from the plots not integrated in this batch. No additional
artifact was silently synchronized.

## Substantive literature integration

The manuscript and appendix now cite **41 distinct sources**, compared with
29 before this batch. The substantive academic component rises from **five
to 17 sources**; the other cited sources are 13 methodological and 11
official/institutional references. All 41 cited keys resolve. The shared
bibliography retains 59 entries, with no duplicate keys, normalized DOIs
or normalized titles.

The argument is organized around evidence-bearing themes rather than adding
citations to meet a quota:

| Theme | Role in the revised manuscript |
| --- | --- |
| Collective redress, beneficiary identity and justice | Distinguish community reparations from material assistance, and explain why recognition and collective rights are not measured by the available outcomes. |
| Implementation, participation and local context | Connect Peru's reparations history and comparative implementation research to selection, participation, unequal benefits and the limits of material indicators. |
| Economic assistance and development | Use cash-transfer and individual-reparations studies as comparative evidence, without equating those interventions with collective project finance. |
| Mobility, constraints and welfare | Present competing opportunity, liquidity and staying-versus-moving pathways; neither movement nor a local null estimate is treated as a welfare measure. |
| Political recognition and transformation | Connect the study to the justice/development debate without claiming effects on trust, recognition or reconciliation that the data do not measure. |

The introduction, institutional/conceptual section, extensions discussion,
conclusion and Appendix A were revised. Main-results prose and the frozen
numerical evidence in Appendices D and E were preserved.

Read-only consultation used the exact shared Zotero library,
`IE Collective Reparations Peru` (library ID 5). All **39 parent records**
were screened. Of those, 21 are cited in the active draft: 17 substantive,
two official and two methodological sources. Eighteen are not selected;
each has an explicit coverage or exclusion reason in the
[39-row library screen](../metadata/literature-library-screening-2026-10-03.csv).
No Zotero item was created, modified or deleted.

Targeted discovery extracted text from 24 local PDFs. The
[17-row source-claim audit](../metadata/literature-source-claim-audit-2026-10-03.csv)
records the bounded claim, evidence type, country/scope, underlying passage
locator, document version, attachment hash, interpretation limit and citing
sections. Selected supporting passages were checked directly. This is not
a claim to have read every page of the larger books or every attachment in
the library.

The linked project NotebookLM was consulted, but a fresh query did not return
a usable answer: the main attempt encountered a browser overlay, and the
independent attempt reported an authentication/browser-launch problem.
No new NotebookLM synthesis is represented as evidence. Successful read-only
Zotero access and direct underlying-source verification supplied the evidence
used here; no authentication or account setting was changed.

## Bibliographic and version corrections

Eight shared-bibliography entries received narrow, verified metadata repairs,
without changing their citation keys:

- Selod–Shilpi: normalize the DOI and distinguish the local World Bank
  working-paper attachment from the published record.
- United Nations: identify the issuing institution and resolution A/RES/60/147.
- de Greiff–Duthie: correct the editor list and series; institutions are not
  listed as editors.
- Firchow 2014: expand Pamina Firchow's name.
- Firchow–Mac Ginty: correct Roger Mac Ginty's name.
- Voytas: use the final 2026 volume, issue and pages while preserving the
  existing 2025 citation key and sole-authored attribution.
- Contreras-Garduño–Rombouts: correct the page range to 4–17 and document the
  PDF-header/metadata year discrepancy; the last printed page was checked.
- Morley: correct the publication month.

Thirty-two DOI metadata requests yielded 30 Crossref records. The arXiv
`rdhte` record was separately checked through its primary record/DataCite
identity, and Holm's identity through the journal issue record at JSTOR.
The absence of accessible full article HTML was not described as a fulltext
reading.

Important source-version limits remain explicit. The local
Lagakos–Mobarak–Waugh attachment is a supplement; supporting main-article
passages were checked in the author-hosted published article, not inferred
from the supplement. Guarin–Londoño-Vélez–Posso remains a working paper, not
a published AER article. A draft chapter with a different final title was
not newly cited when its published supporting passage was unavailable.
The de Greiff volume's claim is supported by its directly checked local PDF
and hash; its support URL is blank rather than fabricated.
Unused edition/date or creator problems remain visible instead of prompting
a speculative cleanup.

The complete [semantic bibliography report](../quality_reports/bib_audit_semantic.md)
contains primary-record links and the unresolved, unused-entry observations.
The original legacy manuscript source, author metadata and administrative
files were not edited. Because the bibliography is shared, its eight metadata
corrections also apply if a legacy source is compiled against it; no claim is
made that a future legacy PDF is byte-identical.

## Validation and independent review

The bounded validation completed the following checks:

1. **Protection baseline:** 932 existing protected repository/Overleaf paths
   were hashed before editing. Of these, 916 remain unchanged. The 16
   permitted changes are 14 existing live manuscript/bibliography paths
   and two repository context/review documents. There are exactly 35 new
   live files, all approved exhibits. No other live file was added.
2. **Authority, destinations and checksums:** all 35 canonical/live/ledger
   SHA-256 values match; destinations stay inside the configured live paper
   tree and outside raw-data locations. Each active caller occurs once.
   Four negative preflight cases reject before copying or creating a directory.
3. **Frozen evidence:** all 48 primary estimates still have pointwise robust
   intervals containing zero and no Holm probability below 0.05. The primary
   adult-movement estimate remains 21.45 percentage points, interval
   [−17.24, 60.14], with 7,680 local people in 63 communities. The household
   availability assignment diagnostic remains −29.71 points, interval
   [−52.20, −7.22]. Results prose and frozen Appendix D/E numerical blocks
   match the preserved pre-integration text.
4. **Publication checker:** all 287 source rows remain in the 35 derivatives;
   diagnostic headers, project standard errors, narrative values, and negative
   controls pass. The 99-item review ledger and generation-time holds remain
   intact.
5. **Heterogeneity accounting:** independent reconstruction confirms 320
   registered IV contrasts, 63 gate passes and no adjusted IV signals;
   270 supported assignment contrasts and 15 adjusted assignment signals.
   Assignment heterogeneity is not relabeled as receipt-effect heterogeneity.
6. **Release boundary:** all 261 release-audit rows remain blocked, with
   zero release eligibility and zero technical-error flags. Technical
   integration does not resolve scientific, permissions or release holds.
7. **Bibliography/dependencies:** 59 unique entries and 41 resolved cited keys;
   no duplicate normalized DOI/title, undefined citations, multiply defined
   labels, BibTeX warnings or overfull boxes in either final compilation.
   Both documents resolve `../Bibliography.bib`. The isolated mirror has
   no convenience bibliography inside the paper directory that could mask
   a broken live dependency.
8. **Visual coverage:** every page of both final previews was rasterized
   and checked for page-bound text and unresolved glyph/reference markers.
   Contact-sheet review covered every page; full-size review covered all
   exhibit starts, all five figures, relevant table continuations and notes.
   Short-table note orphans were repaired by manuscript-only space reservation.
   Long-registry row padding was reduced without changing artifact contents
   or their 9.25-point font.
9. **Git handoff:** whitespace checks pass; audit/cache files, previews,
   commit-message file and Graphify products remain ignored. HEAD is unchanged
   from the protection baseline. No file was staged, committed or pushed.

An independent, read-only reviewer checked source support, current library
access, preservation, all copied/caller hashes, outcome/heterogeneity accounting
and rendered exhibits. Review findings led to the live main bibliography
dependency repair, removal of a fabricated de Greiff URL, and pagination
repairs. These are source/metadata/layout corrections, not changes to estimates.

The independent final review reported no unresolved Critical, Important or
Minor findings within this bounded internal-draft integration. It independently
confirmed the final PDF hashes below and the repaired note endings on appendix
pages 18, 21, 23, 34 and 67. This conclusion does not clear the separate scientific,
permissions, disclosure or release boundaries.

The earlier main-file path reversion could not be attributed to a specific
process. Final live-reference and source/mirror checks were repeated rather
than assuming a preview alone proved the live dependency was correct.

## Compiled previews and length

The final internal previews use the live paper's Letter/12-point/one-inch-margin
layout, with 165.1 mm text width.

| Preview | Pages | SHA-256 |
| --- | ---: | --- |
| Main manuscript | 45 | `b48c4ca0bb096bf1b94ab92ac4e58ced1a8ca7471dfe7f8fd6aea758ea40bf21` |
| Online appendix | 82 | `e8ab65792dca68e187759756a19746b6d471476a5490739609a1d5c9ad1f4a8a` |

Comparable TeXCount core prose changes from 8,436 to **8,741 words**, an
increase of 305 words. The abstract remains **205 words**. Expanded text
counts, including generated notes but excluding the typeset bibliography,
are 10,253 for the main document and 19,177 for the appendix; headers and
captions are counted separately. These are not a journal word-limit
certification. The 82-page appendix is a comprehensive internal evidence
document, not a final submission-sized supplement.

Both previews were compiled locally from isolated, checksum-identical copies
of the live sources and approved inputs. No claim is made that the remote
Overleaf service was itself compiled or that cloud synchronization latency
was independently tested. Preview PDFs, full validation JSON, source snapshots,
word counts and rendered pages are retained only in the ignored dated
`build/manuscript-literature-integration-2026-10-03` audit area.

## Storage, commit scope and next step

Raw/archived Dropbox sources, Working/Coded datasets, analytical code,
canonical generated exhibits, scientific contracts and release registries
were not modified. No Stata command or full raw-data pipeline rerun was
performed in this integration-only batch. The publication checker was run
without `--dropbox-root`; original raw-source hashes are therefore not
represented as freshly reverified.

The seven proposed Git paths are:

- Modified: `docs/PROJECT_CONTEXT.md` and `docs/PUBLICATION_REVIEW_PACK.md`.
- Added: this receipt; the three dated integration/literature CSV ledgers;
  and `quality_reports/bib_audit_semantic.md`.

The previous corrective batch was externally committed before this batch's
protection baseline. Its producing-code changes are not silently included
in this proposed commit scope. Live Overleaf edits are outside Git; their
destinations and validation are documented here. A copy-ready, uncommitted
message is saved in ignored `build/COMMIT_MESSAGE.txt`.

The next milestone is an **internal reader and publication-compression pass**:
review the now-integrated argument and exhibits together; reduce repetition
between full numerical appendix prose and rendered tables; settle main-versus-
online exhibit placement, numbering and cross-references; then complete the
remaining administrative, disclosure and submission checks. Any additional
diagnostic inputs require their own bounded integration review. No new sample
search, estimation strategy, automatic artifact promotion or submission is
authorized by this receipt.
