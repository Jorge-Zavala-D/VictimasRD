# Semantic bibliography and source-claim audit — 3 October 2026

## Result and scope

The active internal manuscript/appendix cites 41 distinct keys: 17 substantive
academic sources, 13 methods sources and 11 official/institutional sources.
Before this batch it cited 29 keys, of which only five were substantive. The
shared bibliography still contains 59 entries. No library item was created,
edited or deleted, and no unused bibliography entry was removed to improve a
count artificially.

All 41 cited keys resolve. Balanced-entry parsing finds 59 unique keys and no
duplicate normalized DOI or title. The compiled main manuscript and appendix
have no undefined citations, multiply defined labels, BibTeX warnings or
overfull boxes after the manuscript-only table wrapper correction. This is
not a claim that every field of every unused entry has been independently
certified.

The source-claim ledger is
`metadata/literature-source-claim-audit-2026-10-03.csv`. Its 17 rows record the
specific claim, evidence type, country/scope, underlying passage locator,
document version, attachment hash and citing sections. The 39-item read-only
library screen is `metadata/literature-library-screening-2026-10-03.csv`:
21 items are cited (17 substantive, two official and two methods), and 18 are
not selected. Title/metadata screening, targeted extraction, selected-page
reading and full-book reading are not presented as equivalent coverage.

## Verification and version control

Local source text was extracted from 24 PDFs for targeted discovery. The
relevant source passages were checked directly rather than accepting a
library abstract or synthesis as proof. The 17 bounded substantive claims
were verified in selected underlying pages or source-tagged fulltext
passages. No claim is made to have closely read every page of the larger
books or every item in the collection.

Thirty-two DOI metadata requests were checked against Crossref; 30 returned
records. The two non-Crossref exceptions were checked separately:

- `calonico_rdhte_2025` is an arXiv preprint with a DataCite-issued DOI;
  the [arXiv source record](https://arxiv.org/abs/2507.01128) confirms the
  title, five authors and 2025 submission. It is not promoted to a published
  journal article or a fuzzy-RD receipt-effect estimator.
- Crossref did not return `holm_simple_1979`. The
  [journal issue record at JSTOR](https://www.jstor.org/stable/i412579)
  identifies Sture Holm's paper, volume 6(2), 1979, pages 65–70 and stable
  article identifier 4615733. The article HTML was not fully available to
  the browser; no fresh fulltext reading is claimed from that HTML.

Publisher/author primary records were used for the substantive publication
and version checks. In particular:

- The Lagakos--Mobarak--Waugh Zotero PDF is a supplement, not the main
  article. The main published article was checked in the
  [author-hosted Yale PDF bundle](https://economics.yale.edu/sites/default/files/2024-02/p1857.pdf),
  beginning on bundle PDF page 21 (printed page 803); the relevant model
  discussion is on bundle pages 38–39 (printed 820–821). The preceding
  unrelated article in that bundle is not treated as part of this source.
  The ledger hashes the local supplement and labels its role explicitly;
  it does not invent a hash for the remote main article.
- The local Selod--Shilpi PDF is World Bank working paper 9662. Its
  content supports the bounded review claim; the final published record
  was verified separately. The working-paper and journal versions are not
  silently treated as the same physical file.
- Guarin--Londoño-Vélez--Posso remains the 2023 reparations working paper.
  The [author's research record](https://sites.google.com/view/arlenguarin/research)
  does not justify describing it as a published AER article.
- Voytas's attached PDF is the 2025 advance version. The
  [publisher's final record](https://www.cambridge.org/core/journals/american-political-science-review/article/abs/more-than-money-the-political-consequences-of-reparations/1AFB4967A0FC69B438DE2801258D11C2)
  places the sole-authored article in 2026, volume 120(3), pages 833–852.
  The existing citation key is retained so references do not break.

## Narrow bibliography corrections

Eight entries were corrected using the verified records; their keys are
unchanged:

| Key | Correction |
| --- | --- |
| `selod_rural-urban_2021` | Normalize DOI field; preserve the published record and document local WP version. |
| `united_nations_basic_2005` | Add issuing institution and resolution number A/RES/60/147. |
| `degreiff_transitional_2009` | Correct the editor list and series; institutions are not editors. |
| `firchow_implementation_2014` | Expand author name to Pamina Firchow. |
| `firchow_reparations_2013` | Correct coauthor to Roger Mac Ginty. |
| `voytas_more_2025` | Use final 2026 volume/issue/pages while retaining Elsa Voytas as sole author. |
| `contreras-garduno_collective_2011` | Correct article page range to 4–17; record 2010 PDF-header/2011 metadata discrepancy. |
| `morley_changes_2017` | Correct verified publication month to January. |

The substantive integration is thematic, not a citation quota. Legal,
conceptual and qualitative sources motivate distinctions between collective
redress, assistance, participation and recognition. Cash-transfer and
individual-reparations evidence motivates material questions without
equating those treatments to shared projects. Mobility studies motivate
competing constraints/opportunity interpretations without treating movement
as welfare or establishing a Peruvian insurance channel.

## Unselected records and unresolved information

The screen preserves, rather than hides, problems in unused entries:
`greiff_reparations_2006` is a Falk chapter, not a de Greiff-authored chapter;
the generic local `Reparations.pdf` is instead a Guarin working-paper copy.
The Teitel and Kritz entries have original-edition/date ambiguities, and the
Yuk-ping creator attribution is incomplete. These unused entries were not
silently rewritten or newly cited.

The local Guarin--Londoño-Vélez handbook chapter is a September 2023 draft
with a different title. The publisher identifies the 2026 final chapter,
but its final supporting passage was unavailable. It is not newly cited.
Other unselected items concern different treatments/outcomes or duplicate
the conceptual role of a verified source. The item-level reasons are in the
39-row screen; omission is not a claim that those works are unimportant.

The correct project NotebookLM was consulted explicitly, but its browser
overlay blocked the query. No fresh NotebookLM answer is claimed. Successful
read-only Zotero discovery and direct underlying-source checks supplied the
evidence used here. Restoring NotebookLM access is useful but is not a
substitute for source verification.

This audit supports the bounded internal revision. It does not clear
submission, public release, all author permissions or redistribution of
third-party fulltexts.

## Final integration review

The independent read-only review checked all 17 substantive claims against
their selected underlying passages and verified all 18 associated local
attachment hashes, including the two Contreras-Garduno/Rombouts versions.
The corrected 4–17 page range is supported by PDF page 14 (printed page 17),
not just Crossref's first-page field. The de Greiff volume has local PDF/hash
and passage evidence but no successfully verified external support URL; its
ledger URL is deliberately blank.

The final 45-page main manuscript and 82-page appendix compile with 41
distinct resolved citation keys. Both consume the shared parent bibliography
directly. A convenience bibliography copy inside the preview paper directory
was removed from the task-created cache so it cannot mask a broken live
dependency. Final source/mirror checks independently match all 27 manuscript
TeX files and all 35 approved exhibit copies. The review found no unresolved
material source, citation, estimate-preservation or integration defect within
the approved internal-draft scope.
