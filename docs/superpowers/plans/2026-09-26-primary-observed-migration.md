# Primary observed-migration population: implementation plan

**Decision (project owner, 26 September 2026):** The 2017 individual primary
CCPP-migration outcome uses linked adults aged 14 or older with valid canonical
2013-source/2017-destination CCPP movement. It does not require completeness
of unrelated 2017 wellbeing or other primary outcomes. The former eight-outcome
complete-case estimate remains a separately labeled sensitivity.

## Scope and invariants

- Preserve selected adjacent B/C geography, `running_bc`, `treat_16`, local
  linear triangular-kernel fuzzy RD, `h=0.0075`, `b=0.0135`, CCPP-equal person
  weights, CCPP-clustered CR2 inference, and the local-IV KP F>10 gate.
- Keep the other seven 2017 individual primary outcomes on their already
  registered complete-case population; retain all eight in one primary
  multiplicity family, with outcome-specific denominators shown explicitly.
- Label the resulting migration estimate as conditional on observed linkage
  and valid canonical movement. Neither linkage diagnostics nor a passing
  first stage establishes an effect for all source-cohort adults.
- Do not alter Dropbox datasets, historical/archived material, Overleaf, or
  substantive specifications outside this population correction.

## Milestone 1: primary migration re-estimation and downstream consistency

1. Amend the outcome and migration protocols before code. State the approved
   sample, legacy sensitivity, estimand limitation, and reporting hierarchy.
2. In `04f_census2017_individual.do`, assert the approved sample flow
   (67,125 people/409 CCPP overall; 7,157 people/62 CCPP in the fixed window),
   route only I03 through it across common-window, bandwidth, inference,
   parametric, and plotted specifications; add its own first-stage row and
   gate, and retain the old I03 result as a labeled sensitivity.
3. Test both observed-migration and legacy samples, first-stage strength,
   reduced form, fuzzy LATE, local 2SLS, fixed-window/bandwidth and cluster
   sensitivities, and Holm/BH corrections. Compare the new results to an
   independent in-console calculation, not only to prior output.
4. Update all module-04 tables/figures/notes and module-06 synthesis to show
   which population each 2017 individual migration estimate concerns. Leave
   module-05f's historic complete-case heterogeneity explicitly internal-only
   and unsuitable as heterogeneity of the newly registered migration target;
   its re-estimation is a separate milestone.
5. Run Stata modules 04f, 06, 07, and 08 using `stata_run_selection`; run
   their output tests and inspect every changed table and graph. Verify input
   signatures, manifest checksums, uniqueness, non-sensitive aggregates, and
   expected review-blocked release status. Do not sync or publish.
6. Record results, limitations, file diff, Graphify update, and a copy-ready
   ignored commit message. Do not stage, commit, or push.

## Subsequent milestones

1. Re-estimate individual migration heterogeneity on the approved observed
   population with outcome-specific moderator support and conditional-IV
   gates; compare it with, but do not relabel, legacy complete-case results.
2. Develop a separate linkage-selection analysis (including a formally
   justified weighting/bounding strategy if identifiable), and adjudicate
   historical-to-2017 CCPP-code discrepancies using documented crosswalks.
3. Only after those audits, decide which aggregate figures/tables merit
   publication review, then update manuscript text and live Overleaf inputs
   under their separate review and synchronization gates.
