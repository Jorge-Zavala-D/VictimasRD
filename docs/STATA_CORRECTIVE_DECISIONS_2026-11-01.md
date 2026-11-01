# Targeted Stata corrective decisions — 1 November 2026

Authority: the user approved correction of the 18 findings in
`STATA_CODE_AUDIT_2026-11-01.md`, preserving the research design, and qualification
of the installed 7 October 2026 Stata build before any prospective relock.
The old software lock and private analytical baseline remain preserved.

## Scope and invariants

These are implementation corrections, not a new sample search. Preserve the
RUV universe, approved geography, B/C support, assignment/category rule,
common windows, treatment years, estimators, clustering hierarchy and
Ancahuasi/Ranracancha adjudication. Do not infer publication approval from a
technical pass. Do not sync regenerated artifacts into the live manuscript in
this batch. Reconcile every changed data value or result separately from
representation-only differences.

## Destination roster identity

Read-only Stata MCP checks of the original INEI delivery found 193,376 source
records, no source ages 101–120, 30 rows with repeated nonmissing destination
person identifiers, no destination person linked to different destination
households, and no missing destination person among records with a destination
household. Applying the existing accepted-source crosswalk retains 193,342
records. Twelve destination households contain repeated person identities;
three of those households, containing 15 delivered records, previously passed
the row-count completeness test.

Keep every accepted source record. A complete destination roster must have
nonmissing, globally unique destination-person identities, a known destination
household and reported size, and a delivered row count equal to that size.
Repeated or missing destination identities invalidate completeness, not the
source person's inclusion. Withhold the two roster-dependent NBI components
for invalid rosters; do not silently deduplicate or alter independently
observed dwelling, household, migration or individual items. On the inspected
inputs, this reduces certified complete destination households from 27,274 to
27,271. Regeneration must confirm the incidence and downstream changes.

The existing four destination-roster sample-flow lines are **not an exhaustive
partition after this correction**: missing size (1,223), partial row count
(37,926), certified complete (27,271), and excess row count (4) sum to 66,424.
The remaining **three equal-row-count households are identity quarantines**,
not ordinary partial rosters; adding them recovers all 66,427 destination
households. Twelve households have a duplicate-identity issue overall, but
nine are already counted among the other row-count categories. Do not add all
twelve to this partition or call the three missing households sample attrition.
All source-person and baseline-household denominators remain preserved.

Unknown age does not establish eligibility for an age-restricted measure.
For a complete-roster dependency measure, unknown member age remains an
unresolved labor-status condition rather than evidence of an ineligible child.

## Multiplicity and inference status

Retain the already registered applicable hypothesis families. A failed model
keeps a missing raw p-value, but occupies its registered place in the adjustment
with an adjustment-only p-value of one. Explicit structural identities remain
excluded where the protocol says so. A failed fit, missing statistic or
nonpositive standard error cannot pass the operational instrument gate.
Secondary specifications require their own exact-sample diagnostics; the
primary model's diagnostics cannot certify them.

For finding 11, use the audit's conservative reporting remedy rather than
quietly add a new estimation strategy: preserve every existing sensitivity
estimate and standard error, but explicitly hold secondary and unmatched
robustness LATEs as sensitivity diagnostics until their own weak-instrument
diagnostics are reported. The new `strength_scope` field distinguishes this
hold from the primary IV analogue and a parametric model's own diagnostics.
Do not cite the primary first stage as certification of an outcome-specific
secondary sample. This is not a change to the primary estimand or estimator.

## Review identities and stale upstreams

The 261 historical registry decisions are pinned to the artifact bytes and
native checksums preserved at baseline commit
`2efea548f0c55ea15444c0558d8e3b88bd06dad8`. This makes the previously implicit
scope of a historical decision explicit; it is not a new scientific, visual or
disclosure review. The recorded historical Stata checksum is enforced at
runtime. Separately, `baseline_git_sha256` identifies the committed Git blob,
not necessarily the historical working-tree bytes: Git can normalize text line
endings. Do not conflate these identities or treat a native checksum as a
cryptographic release certificate. The dated SHA review ledgers and their
independent release checks remain separate. Changed runtime fingerprints receive
`review_required` and cannot inherit an owner approval. Existing zero owner
flags remain zero. Prior dated SHA review ledgers remain immutable evidence.
Module 07 must also compare module 06's recorded module-04 manifest identity
with the currently consumed module-04 manifest, before assembling results.

## Election-index floating-point reconciliation

The first exact keyed comparison passed datasets 04–07 but stopped at dataset
08. Only `elect_hhi_2002`, `elect_nep_2002`, `elect_hhi_2006` and
`elect_nep_2006` differed; all other variables and all 5,712 matched RUV keys
agreed exactly. Missing-value patterns agreed. Native Stata diagnostics found
maximum absolute differences of 1.11022302463e-16, 5.3290705182e-15,
1.11022302463e-16 and 2.6645352591e-15, respectively. The producing formulas
are unchanged sums of squared vote shares and their reciprocals. These are
representation-scale differences consistent with finite-precision summation
and inversion, not a changed election definition. Exact-comparison failure is
retained as evidence, not relabelled an exact match.

For these four explicitly named fields only, including their downstream
copies, use an absolute comparison bound of **1e-13**. This is about nineteen
times the largest observed roundoff difference but many orders of magnitude
below the administrative measurement scale; it is not a
general data tolerance or an estimation tolerance. Require exact keys,
dimensions and missing-value codes, then test these four differences directly
before omitting only those columns from the remaining exact `cf` comparison.
Do not round, replace or overwrite any research value. Report both the number
of non-bit-identical election cells and their maximum absolute differences.
Any other variable discrepancy, or a larger election discrepancy, remains a
failure requiring separate adjudication. This comparison choice was made
after inspecting the first exact failure and is not described as predeclared.

## Evidence status

This record authorizes only the narrow implementation described above under
the approved corrective scope. Tests, real-input incidence checks, numerical
comparisons and the full master remain separate completion requirements.
