# Approved identification and precision integration — 2 November 2026

**Status: the approved five-file internal Overleaf update is applied. Exact
scope, preservation, local compilation and print-layout checks pass. Submission
and public release remain unapproved.**

## Authority and applied scope

The owner approved the exact five-file update in
[the preceding proposal](proposals/2026-11-02-identification-precision-overleaf-updates.md),
with explicit instructions to preserve all 55 existing inputs and not commit,
push, submit or release anything. The older proposal's pending-approval wording
is dated history; this receipt records subsequent approval and application.

Exactly these five live files under `World Development Manuscript/` changed:

| Live file | Applied change |
| --- | --- |
| `sections/04_empirical_strategy.tex` | Add the approved own-sample support/IV-diagnostic paragraph and an Online Appendix D pointer. |
| `sections/07_robustness.tex` | Add the approved no-automatic-promotion and interpretation boundary. |
| `appendix/D_additional_results.tex` | Add the approved exact-sample subsection, inference distinction, three marginal AR exclusions and the two table callers. |
| `tables/identification_precision_2026-11-02/tab_identification_summary.tex` | New exact canonical copy, rendered as Table A20 on page 70. |
| `tables/identification_precision_2026-11-02/tab_identification_primary.tex` | New exact canonical copy, rendered as Table A21 on pages 71–73. |

Two narrowly bounded presentation decisions were needed within those files:

1. The article and appendix compile separately without external-label support.
   The article therefore uses descriptive pointers to the two Online Appendix D
   audit tables, rather than unresolved inter-document `\ref` commands. Appendix
   references remain automatic. No sixth file or package was introduced.
2. The first rendered A21 started below A20 and left only one body row on its
   final page. A caller-level `\clearpage` before A21 fixes this without changing
   the generated table. The layout assertion failed before the repair and passes
   afterward: 20, 22 and six body rows on pages 71, 72 and 73. The initial candidate,
   first compiled PDF and report are preserved privately, not overwritten.

Neither decision changes scientific claims, numbers, samples or inference.
The [applied source patch](../metadata/overleaf-identification-integration-2026-11-02/source-update.patch)
records the exact three additive handwritten-source diffs. The two generated
tables were copied, never edited manually.

## Preservation and provenance

The checkout was clean at `ed8748b447e1f2fa535eba770fe516708f4f2ce3` when this
task began. That commit already existed; no commit was made in this task.
The configured live root, not a hard-coded analysis path, governed all targets.

The complete pre-update 197-file live tree was hashed and preserved in a
recoverable, ignored local copy. The acceptance check was exercised before
application and failed because the five-file delta was absent; it then passed
after application and again after the pagination repair.

Final whole-tree checks establish:

- 197 original live files become 199: three existing sources changed, two tables
  were added, and no file was removed.
- The other 194 original live files remain byte-identical, including all 55
  previously reviewed generated inputs, the shared bibliography, legacy paper,
  author/admin materials, presentations and unconsumed historical galleries.
- All 55 old inputs still match both their approved SHA-256 and canonical Git
  copies. No old input was recopied, regenerated or replaced.
- The two new inputs match their canonical Git bytes, generation manifest and
  the prior identification-audit validation identities. Their separate internal
  copy approval does not modify generation-time or public-release flags.
- All 901 pre-existing tracked Git files are protected by the initial inventory;
  only the documented current-status addition to `docs/PROJECT_CONTEXT.md` is
  allowed to differ. Code, numerical outputs, scientific protocols, historical
  receipts and release records are unchanged.

The [five-file change ledger](../metadata/overleaf-identification-integration-2026-11-02/live-changes.csv)
and [57-input ledger](../metadata/overleaf-identification-integration-2026-11-02/generated-inputs.csv)
give exact identities and internal-only approval scope. Prior input provenance
is inherited through its explicit earlier record, not invented anew.

## Fresh local compilation and visual review

The updated live manuscript subtree and unchanged shared bibliography were
copied byte-for-byte into the ignored Git build cache. All copied identities
were checked before validation. The installed TeX Live/pdfLaTeX toolchain and
existing compilation helper built the three entry points without installing
packages or writing build files into Dropbox.

| Document | Pages | Final checks |
| --- | ---: | --- |
| Main article | 42 | Pass |
| Online appendix | 100 | Pass |
| Submission checklist | 2 | Pass; source unchanged |

All final logs have zero checked TeX errors, overfull boxes, undefined
references/citations, multiply defined labels and duplicate destinations.
BibTeX has no warning/error messages. No out-of-page character was detected
across the 144 pages. All 41 cited keys are unchanged and resolve to the
unchanged bibliography. Static source expansion and actual compiler recorder
files confirm consumption of all 55 original inputs plus the two new tables.

All pages were rendered. The eleven contact sheets were inspected; enlarged
130-dpi checks covered the new article passages, A20, all three A21 pages and
its complete note. Sixty-three unchanged appendix pages have identical pixels
to their previously inspected first renderings. All six summary rows and all
48 primary rows are present; the final page is not a lone-row continuation.
The numeric-column geometry check finds at least 36.63 PDF points between the
RD-interval closing bracket and the KP statistic. No new clipping, overlap or
broken reference was found. Existing dense exhibits and publisher font/length
clearance remain separate; this is not a universal minimum-font certification.

The World Development exhibit guidance informed the uncertainty, units, notes
and final-width inspection. It did not authorize changing frozen outputs or
impose unverified new journal requirements. All 21 existing Python unit tests
pass. No Stata command or empirical data rerun was required in this integration.

The local previews, logs, recorder files and renderings remain under
`build/overleaf-identification-integration-2026-11-02/`. This is compilation of
the exact local live source, not a triggered Overleaf-cloud build or proof of
completed Dropbox remote synchronization.

## Scientific and governance boundaries

The new presentation retains all 48 registered primary outcomes and the
original bias-corrected RD estimates, intervals and multiplicity adjustments.
Conventional clustered local-IV Anderson–Rubin sets remain separately labeled;
passing the operational finite KP screen does not certify bias-corrected RD,
exclusion, monotonicity or ignorable linkage. The three unadjusted conventional
AR exclusions are disclosed without switching the primary inference method.
Nonsignificance is not converted into evidence of no effect.

No outcome, model, sample, weighting, cutoff, bandwidth, clustering rule,
treatment year, estimand, mediation claim or publication role was changed.
No raw, working, coded or row-level dataset was opened or modified. The seven
new audit outputs and all earlier numerical/source identities are preserved.

The Zotero MCP was unavailable and a read-only local API probe was refused.
The explicitly scoped Peru NotebookLM query returned only a searching
placeholder, not a source-bearing answer. No fresh source synthesis, citation
verification or exhaustive literature review is claimed; no source, reference
or bibliography entry was added. No library/authentication change was made,
and the unrelated active notebook was not queried.

A fresh-context read-only reviewer independently verified scope, exact hashes,
57 recorder inputs, final logs and the unchanged primary/AR claim hierarchy.
No Critical or Important integration defect or actionable Minor was found.
The reviewer did not re-estimate, independently inspect every page, or certify
causal validity, source rights, cloud synchronization or release. The parent
completed the final visual sign-off separately.

The [final verification record](../metadata/overleaf-identification-integration-2026-11-02/final-verification.json)
states the bounded checks and remaining limits. No stage, commit, push,
submission, public release or change to historical release permissions occurred.
