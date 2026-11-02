# Exact-sample identification and precision audit

## Approved scope and fixed decisions

The owner approved this next scientific milestone on 2 November 2026. This is
an audit of the registered module-04 models, not a new search for a design.
The adjacent B/C population, selected geography, treatment years, outcome
families, weights, bandwidth rules, covariates and primary CR2 RD inference
remain fixed. The operational instrument gate remains finite KP F strictly
greater than 10; it is not a theorem establishing strong identification.

The audit must run inside the existing estimation routines, after their
reported results have been saved to locals. It therefore observes the actual
outcome eligibility flag, covariate completeness, observation weights and
selected left/right windows, without reconstructing samples from counts.
No input dataset is changed. Temporary observation-level objects stay in
Stata memory. Aggregate model records and exhibits belong under Git output.

For each registered RD model, record eligible and local observations,
communities, districts and distinct scores on each side, including the bias
window. Preserve failed fits as explicit records. For receipt-effect fits,
estimate a conventional local-polynomial IV analogue with the same outcome,
eligible observations, kernel, left/right bandwidths, polynomial order and
covariates. Report its own clustered KP statistic, reduced form and first
stage. Nonclustered RD variance sensitivities retain the assignment-level
cluster for this separately labeled IV diagnostic; the diagnostic does not
replicate NN, HC3, CR2 or CR3 variance estimation.

Anderson--Rubin tests and 95% confidence sets use Stata 19's official
`ivregress` / `estat weakrobust, ci` implementation on that IV analogue.
Retain bounded, unbounded, disjoint, empty and failed sets explicitly; do not
truncate sets to an attractive graph axis. Reconcile its point estimate to
the `ivreg2` analogue. These sets address weak identification conditional on
the local-polynomial model and valid instrument assumptions. They do not
remove smoothing bias, prove the exclusion restriction, repair selection,
or replace bias-corrected `rdrobust` inference. In particular, the new sets
must never be labeled bias-corrected fuzzy-RD confidence intervals.

The existing registered parametric rows keep their own original diagnostics;
the audit adds confidence sets on their actual estimation samples as well.
For outcome-adaptive bandwidth rows, the AR calculation is a diagnostic for
the recorded window, not an established unconditional post-selection RD
confidence set. The registry records that distinction. Even fixed-window
inference remains conditional on the adopted historical design and model;
this audit does not correct the earlier geographic/design search.
Failed or weak secondary rows cannot borrow a primary-row diagnostic.
Multiplicity families and their existing adjustments remain unchanged. New
diagnostic p-values are not a new search for significant outcome effects.

## Precision, not observed power

Cover all 48 primary fixed-window fuzzy outcomes. Report the original effect,
95% interval, adjusted p-value and exact-sample diagnostic alongside interval
width and compatibility with symmetric illustrative benchmarks. Use 5 and 10
percentage points for percentage outcomes, 5 and 10 points for 0--100 scores,
and log(1.05) and log(1.10) for log counts. A count outcome uses one and two
units. These are transparent display benchmarks chosen after the existing
results were known, not preregistered minimal important effects or universal
welfare thresholds. Do not calculate power using the observed effect or
claim equivalence from nonsignificance. A confidence interval wholly within
a benchmark is described as interval containment, not a formal equivalence
test. The ordinary RD interval remains conditional on adequate identification.

## Source and implementation basis

- [Stata 19 official weak-instrument inference](https://www.stata.com/new-in-stata/inference-robust-to-weak-instruments/):
  just-identified Anderson--Rubin inference and cluster-robust support. The
  installed official help and implementation were also inspected and tested.
- [Feir, Lemieux and Marmer (2016)](https://economics.ubc.ca/wp-content/uploads/sites/38/2018/12/pdf_paper_thomas-lemieux-fuzzy.pdf):
  weak identification can invalidate conventional fuzzy-RD inference.
- [Cattaneo, Idrobo and Titiunik (2024)](https://rdpackages.github.io/references/Cattaneo-Idrobo-Titiunik_2024_CUP.pdf):
  fuzzy identification and distinct estimands/inference requirements.
- [Noack and Rothe (2024), Econometrica](https://doi.org/10.3982/ECTA19466):
  bias-aware fuzzy-RD confidence sets explicitly address smoothing bias,
  irregular support and weak identification using smoothness restrictions.
  They are not the ordinary linear-IV AR procedure implemented here. Adopting
  such a branch would require a separately stated curvature-bound sensitivity
  and clustering assessment; no bounds are inferred or silently imposed here.
- Existing actual-code reviews are recorded in
  `STATA_REFERENCE_REVIEW_2026-11-01.md`; the explicit local-IV blocks and
  post-estimation export pattern are retained rather than replaced by a new
  sample-reconstruction framework. No external replication package is run.

The 94-line `CCFT_2019_RESTAT.do` was also refreshed directly from the
author repository at snapshot `b6b2711d6619e188d33ead5b1be1e75c907fa0ab`.
Its six explicit model calls and immediate postfile extraction illustrate the
pattern retained here; its older `masspoints(off)` compatibility advice is
not adopted. This is actual-code inspection, not successful execution or a
claim that the snapshot is the publication-date deposit.
The refreshed source is 4,685 bytes, SHA-256
`8b5bced25aee70b21115c8cb36a4c99e85601a648040ed0c5e060aa5e690ae25`,
matching the prior reference-review identity.

The shared Zotero library (ID 5) was consulted read-only for RD/clustering
references. Returned metadata is discovery, not proof of a supporting passage.
The explicit Peru NotebookLM URL was queried, but the provider failed; no new
NotebookLM source synthesis is claimed. Official sources and local help,
not a generated answer, govern the implementation.

## Execution and validation plan

1. Freeze current aggregate module-04 results and their checksums, and record
   HEAD and clean working-tree status before code changes.
2. Test synthetic strong/weak, weighted/clustered, asymmetric-window and
   missing-value cases. Verify set encoding and restoration of caller results.
3. Add a small common diagnostic routine and explicit hooks in all six
   existing estimators and parametric blocks. Preserve all model definitions.
4. Re-run module 04 from the documented master environment through Stata MCP.
   Require identical model keys, strings, integer counts and missingness.
   Compare every numerical cell, recording byte identity separately. The
   completed first module exposed two legacy AR p-values differing only at
   about 1e-16, with every other field exact. Accordingly, retain a separate
   full-cell comparison with absolute tolerance 1e-10 plus relative tolerance
   1e-12 for continuous values only. This is far below displayed precision;
   it does not permit sample, hypothesis, estimator or interpretation changes.
   Report actual differences rather than claiming bitwise reproduction.
5. Require one diagnostic record for every original model row, exact key
   uniqueness, all 48 primary outcomes and explicit statuses for failures.
   Produce complete aggregate CSVs and compact review-only LaTeX exhibits.
6. Inspect rendered exhibits and audit claim implications. Record limitations
   and exact proposed manuscript updates separately. Do not replace any live
   Overleaf input, approve artifacts, commit, push, submit or release.

This file is the prospective implementation contract, not a completion receipt.

For the completed execution, late disjoint-set export correction, numerical
comparison and remaining scientific boundaries, see
`IDENTIFICATION_PRECISION_RESULTS_2026-11-02.md` and
`metadata/identification-precision-validation-2026-11-02.json`. The written
scientific contract above was not changed to obtain a passing result.
