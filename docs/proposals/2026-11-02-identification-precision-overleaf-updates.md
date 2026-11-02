# Proposed Overleaf changes after the identification/precision audit

**Proposal only. No live replacement or integration is authorized by this file.
Module-04 production, numerical comparison, confidence-set export checks and
private print-size review have passed. Owner approval of these five live-file
changes is still required.**

Root: the configured `overleaf_root`; active draft: `World Development Manuscript`.
Preserve all 55 previously reviewed generated inputs and the original legacy
paper. Do not replace the current primary tables, figures, outcome definitions,
coefficients, samples, weighting or reporting hierarchy.

## Five-file internal-draft integration proposed

| File under active draft | Exact proposed action |
| --- | --- |
| `sections/04_empirical_strategy.tex` | Append the paragraph below after the current first-stage safeguards. |
| `sections/07_robustness.tex` | Add the interpretation boundary below to the specification/identification discussion; retain all selection and historical-design qualifications. |
| `appendix/D_additional_results.tex` | Add the subsection below, pointing to two new reviewed inputs, without deleting any existing primary or secondary family. |
| `tables/identification_precision_2026-11-02/tab_identification_summary.tex` | New exact copy of the validated canonical Git output; do not edit its contents in Overleaf. |
| `tables/identification_precision_2026-11-02/tab_identification_primary.tex` | New exact copy of the validated canonical Git output; do not edit its contents in Overleaf. |

The destination directory is new. These two additions would increase consumed
reviewed generated inputs from 55 to 57, with none of the 55 replaced. The
active preamble already loads `booktabs`, `array` and `longtable`; no package
or bibliography edit is required for this proposed integration.

The third new exhibit, `tab_precision_benchmarks.tex`, remains an internal
scientific-review tool for now. Its post-results illustration bounds must not
be presented as prospectively chosen minimal important effects or as formal
equivalence tests. No introduction, abstract, conclusion, extension estimate,
author declaration or release flag needs changing merely because diagnostics
were added.

## Exact empirical-strategy paragraph proposed

> An additional exact-sample audit links every registered specification to its
> eligible population and positive-kernel-weight estimation and bias windows.
> It reports observations, represented communities, districts, and distinct
> scores separately, rather than borrowing support or first-stage clearance
> from a primary model. Matching conventional local-IV analogues additionally
> report clustered Anderson--Rubin confidence sets, including nonbounded or
> unavailable sets. Calculations for outcome-adaptive windows are recorded-window
> diagnostics, not established post-selection RD coverage. These sets concern
> the stated local-IV model, not the
> bias-corrected RD estimator, and do not remove smoothing bias or establish
> valid selection, exclusion, or monotonicity. The operational KP screen and
> the primary RD reporting hierarchy remain unchanged.

For TeX, replace ``KP'' with the already defined Kleibergen--Paap abbreviation
and point to `Table~\ref{tab:exact_sample_audit}` and
`Table~\ref{tab:primary_identification_precision}` in Online Appendix D.

## Exact robustness addition proposed

> The added own-sample diagnostics do not promote a secondary receipt estimate
> solely because its local-IV first stage passes the operational screen. The
> ordinary RD intervals and the separate local-IV confidence sets address
> different finite-sample inferential problems. Their joint presentation makes
> weak identification and limited information visible but does not turn
> nonsignificance into evidence of no effect. The selected design, coarse-score
> support, historical search, and treatment-dependent observation qualifications
> therefore continue to limit interpretation.

Do not add a statement that all sensitivities are cleared. Any specific newly
reportable claim requires its own outcome, specification, sample and inference
assessment against the completed registry.

## Exact Online Appendix D subsection proposed

```tex
\subsection{Exact-sample identification and precision}

The accompanying registry retains all registered model rows;
Tables~\ref{tab:exact_sample_audit} and
\ref{tab:primary_identification_precision} summarize that audit and display
all six primary outcome families. Counts of specification rows are not
counts of independent tests or populations. The first table summarizes the
own-sample diagnostic screen; the second places the original primary RD
intervals beside confidence sets for separately labeled conventional local-IV
analogues. Passing the operational screen does not certify bias-corrected
RD inference or resolve the observation and instrument-validity assumptions.
The complete machine-readable registry retains support, failures, original
multiplicity adjustments and the full confidence-set endpoints.

Three marginal conventional local-IV Anderson--Rubin sets exclude zero
(2017 community employment, household female share, and household share
living in another community). These are not multiplicity-adjusted,
bias-corrected RD intervals: all three registered primary RD intervals
include zero and their Holm-adjusted probabilities exceed 0.05. We retain
the primary reporting hierarchy rather than select the more favorable
inference procedure after inspecting the results.

\begingroup\singlespacing\setlength{\parindent}{0pt}
\input{tables/identification_precision_2026-11-02/tab_identification_summary.tex}
\small
\input{tables/identification_precision_2026-11-02/tab_identification_primary.tex}
\par\endgroup
```

## Required integration checks, only after owner approval

Resolve each target under the configured live root and outside every data
directory; verify canonical producer/manifest identities; copy only the two
cleared inputs; inspect the three narrow source diffs; preserve UTF-8; compare
post-copy SHA-256; compile main/appendix in isolation; inspect final-width
tables, counts, references, notes, and exhibit order. Keep submission and public
release blocked. The new internal review PDF is not approval of live changes.
