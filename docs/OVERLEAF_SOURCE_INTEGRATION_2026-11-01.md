# Approved seven-source Overleaf integration — 1 November 2026

**Status: the exact approved seven-file patch is applied to the live
Dropbox-synchronized manuscript source. Local compilation and preservation
checks pass. Submission and public release remain blocked.**

## Authority and exact scope

The project owner approved: “I approve the exact seven-file Overleaf patch.
Apply it, fully audit and validate the live manuscript and compilation, and
preserve all 55 generated inputs. Do not commit, push, submit, or release
anything.” This approval applies only to the seven handwritten sources in
[the preceding proposal](PUBLICATION_CHANGED_ARTIFACT_REVIEW_2026-11-01.md).

The applied [patch](proposals/2026-11-01-overleaf-source-updates.patch) has
SHA-256 `a6871dabeb974c224ea9c3159cfcc1721e5791c999150c4e16454beff114151b`.
Every live before-hash matched the proposal's baseline; every live after-hash
matches its approved proposed hash exactly. UTF-8 without a BOM and the
existing LF line endings are preserved. No additional manuscript correction,
renaming, output replacement or bibliography change was made.

Paths below are relative to the configured Overleaf root and all fall under
`World Development Manuscript/`:

| Source | Approved change now present |
|---|---|
| `sections/03_data_measurement.tex` | Unique nonmissing destination-person IDs and full-roster conditions for roster-dependent deprivation. |
| `sections/07_robustness.tex` | Own-sample weak-IV qualifications and retained applicable multiplicity slots. |
| `appendix/B_data_construction_linkage.tex` | Correct complete-roster count and accounting for the three additional identity holds. |
| `appendix/D_additional_results.tex` | Diagnostic-only status for secondary/unmatched sensitivity ratios lacking their own exact-sample instrument checks. |
| `appendix/E_mechanisms_heterogeneity.tex` | Three corrected Holm values, applicable family sizes, clustering-sensitivity holds and association covariate source years. |
| `appendix/F_replication_transparency.tex` | Qualified environment, previous corrected-master validation and remaining reproducibility boundaries. |
| `submission_checklist.tex` | The approved dated technical-review addendum and preserved outstanding holds. |

See [the seven-source before/approved/after ledger](../metadata/overleaf-source-integration-2026-11-01/source-changes.csv).
The prior proposal and review ledgers remain unchanged as historical records;
this receipt records the subsequent explicit approval and application.

## Preflight and preservation

The checkout was clean at `6e9aad110a5a60c014282188d129a09e028efd37`
(`Review changed artifacts and propose exact Overleaf source updates`). That
commit already existed when this task began. No commit was created here.
The preceding review's historical verifier intentionally still requires its
older HEAD; it stopped on that historical HEAD condition, not manuscript drift.
It was not weakened or rewritten. A fresh integration snapshot records the
actual starting HEAD and current file identities.

Before application, the whole local Overleaf publication root was inventoried:
**197 files**. All 117 files in the earlier active-manuscript/shared-bibliography
snapshot still agreed exactly. Copies of the seven pre-edit sources were
preserved only in the ignored Git review cache. The live-change acceptance
check was exercised before application and failed as expected because no
approved source had yet changed; it passed after application.

After application:

- **Exactly seven** existing live files changed, to the exact approved bytes.
- **190 other live files are byte-identical**, with no files added or removed.
  This includes the legacy manuscript, shared bibliography, author and
  administrative material, presentations and dated gallery snapshots.
- **All 55 generated inputs remain unchanged**, with exact agreement among
  the live copy, canonical Git file and recorded approved-copy SHA-256.
  None was recopied, regenerated, manually edited or replaced.
- The three older, unconsumed August review-gallery copies are preserved;
  their unresolved historical provenance was not converted into an approval.
- All 875 previously tracked Git files are protected by the preflight hash
  inventory, except the explicitly documented current-status addition to
  `docs/PROJECT_CONTEXT.md`. No analytical code, canonical output, existing
  review ledger or release flag was changed.

The [55-input preservation ledger](../metadata/overleaf-source-integration-2026-11-01/generated-inputs.csv)
records exact identities, not an inference about synchronization or licensing.

## Compilation of the updated live source

The updated live manuscript subtree and its unchanged shared bibliography
were copied byte-for-byte into the ignored Git build cache. The copied source
and asset identities were rechecked against the updated live tree before
validation. The three entry points were built there with the existing
TeX Live/pdfLaTeX toolchain through the installed LaTeX compilation helper.
No package installation or compiler change was performed.

| Document | Pages | Final-log and layout checks |
|---|---:|---|
| Main article | 41 | Pass |
| Online appendix | 96 | Pass |
| Submission checklist | 2 | Pass |

All final logs have **zero overfull boxes, undefined references/citations,
multiply-defined references, duplicate destinations or TeX errors**. The
BibTeX logs contain no warning/error messages. No character-bound violation
was detected on any page. Static dependency expansion and actual compiler
recorder files establish that:

- all **41 cited keys** resolve to the unchanged shared bibliography;
- all **55 generated publication inputs were actually consumed** by the
  fresh builds, rather than merely existing on disk; and
- no source or asset copied from the live tree drifted during compilation.

Every page was compared with the approved private proposal preview:
**139/139 pages have identical extracted text, character geometry to 0.001
PDF point, and rendered pixels at 85 dpi**. PDF file hashes need not agree
because build metadata can differ; the page comparisons test visible content
and layout directly. Current PDF hashes are recorded in
[the compile ledger](../metadata/overleaf-source-integration-2026-11-01/compile-checks.csv).

All ten fresh contact sheets were inspected. Enlarged checks covered the
updated main-text measurement/weak-IV passages, Appendix B's roster accounting,
Appendix E's family explanation and three adjusted values, Appendix F's
software/validation disclosure, and the checklist holds. No new clipping,
overlap or broken float placement was found. The World Development exhibit
skill informed the note/units/legibility check; it did not authorize editing
any frozen generated exhibit or impose new journal requirements.

The PDFs, logs, recorder files and renderings remain only under
`build/overleaf-approved-integration-2026-11-01/`. **No build product was
written into Dropbox or the live Overleaf tree.** This is a local compilation
of the exact live source, not a triggered or verified Overleaf-cloud build or
proof of completion of Dropbox's remote synchronization.

## Results narrative and governance

The live Appendix E now reports the approved Holm values **.019, .028 and
.042**, replacing .010, .018 and .021 in the three specified assignment
contrasts. The complete destination-roster count is now **27,271**, with
three additional identity holds accounting for the difference from 27,274.
The three holds contain 15 retained source rows; no deletion is implied.

The main results and headline interpretation are unchanged. This task did
not re-estimate any model, change an outcome, sample, treatment, weighting,
bandwidth, clustering rule, multiplicity family or estimand. The corrected
master's 96 exact primary RF/fuzzy rows and earlier numerical reconciliations
are evidence from the preceding audited batch, not a new statistical run here.

The existing release audit remains byte-identical: 261 candidate rows, zero
technical errors, zero owner flags and zero release-eligible rows. Approval
of seven internal manuscript sources is not approval of new analytical
artifact bytes, submission, a public data package, or public disclosure.

No data source or analytical dataset was opened or changed. No Stata command,
external data conversion or extraction was needed. The exact shared Zotero
library was resolved read-only. NotebookLM health reported no authenticated
account and an unrelated active notebook; no query was sent to that notebook.
No new literature claim, reference or bibliography entry was introduced.

## Audit boundaries and handoff

A fresh-context independent read-only reviewer verified the live/file/Git
identities, scope, copied sources, 55 recorder inputs, final build logs and
receipt claims. No Critical, Important or Minor discrepancy was identified.
The reviewer checked the page-comparison records, not an independent rerender,
compilation or Stata run, and did not adjudicate scientific assumptions or
rights. This bounded review is recorded in
[the final verification metadata](../metadata/overleaf-source-integration-2026-11-01/final-verification.json).
The exact source hashes, whole-tree preservation, actual compiler consumption
and full-page comparisons are the operative technical acceptance checks, not
an assertion of universal scientific validity.

Still separate: publisher font/length clearance for dense tables and small
notes; held raw-table presentation; secondary outcomes' own-sample weak-IV
diagnostics; linkage/measurement/identification assumptions; another-machine
replication; rights and administrative documentation; and submission/public
release approval. The approved verbatim patch does not silently resolve them.

The previous plan's source wording and dated history are preserved exactly,
including proposal-era language within the dated checklist addendum. The
current application status is supplied by this receipt and the new ledger,
not by retroactively rewriting that approved history.

No stage, commit, push, submission or public release occurred. The ignored
`build/COMMIT_MESSAGE.txt` provides a copy-ready message for this integration's
new repository documentation/metadata only; live manuscript changes themselves
remain in the synchronized Overleaf source tree.
