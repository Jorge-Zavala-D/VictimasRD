# Census 2017 selection-adjustment feasibility

## Binding owner decision and scope

On 30 September 2026 the owner closed acquisition of dated RUV registration/score
histories, annual CMAN priority/eligibility lists, and award histories as a
prerequisite. The existing CMAN project year is the **sole year record**: assume
funds were allocated and the project delivered in that year. This is an adopted
measurement assumption, not a verified execution/completion date. Do not reopen
this search or manufacture interview-date exposure or historical risk sets.

Keep `treat_12` for 2013 and `treat_16` for 2017; preserve geography, adjacent B/C
support, `h=0.0075`, `b=0.0135`, weighting, clustering, and the outcome-specific
F>10 safeguard. I03 remains linked people aged at least 14 in 2017 with valid
canonical CCPP movement. None of these outputs replaces its estimate.

## Executable audit contract

Module 06 reads the canonical community, person, and source-household files and
produces six aggregate products registered in its manifest:

1. Separate the full RUV B/C frame from source-cohort entry; person linkage from
   movement observability; and household linkage from eight-outcome completeness.
   Report selected B/C support and the fixed window, below/above-cutoff counts,
   explicit parent denominators, and CCPP-equal rates.
2. Evaluate baseline-only selection models for person linkage, movement
   observability among linked known-age adults, and household completeness.
   Fit in the registered bias window with cutoff side, side-specific linear
   score slopes, 2007 population/wellbeing, and 2006 GDP. Report missing baseline
   covariates, convergence, probability support, untrimmed inverse-probability
   weight effective size, and communities without selected observations.
   These are **feasibility diagnostics**, not corrected causal estimates or
   approval of missing-at-random (MAR).
3. Compute finite-source-cohort descriptive movement intervals separately on
   each side of the common window, using only known zero-to-one support. Include
   every missing movement value, including linked records with unknown
   destination. The side-mean difference interval is not a local-polynomial RD
   effect or a fuzzy-RD LATE bound. The all-age source-person frame is not the
   primary adult population. For households, divide known movers by all source
   members for the lower endpoint, and known movers plus all unobserved members
   by all source members for the upper endpoint. Average those endpoints with
   CCPP-equal household weights. This diagnostic target differs from the stored
   primary household share among observed-movement members; that outcome is
   unchanged. Report fully, partly, and wholly unobserved household counts.
4. Validate denominators, model sample retention, interval algebra, unchanged
   primary contracts, and input-file checksums. No source, analytical dataset,
   or crosswalk changes; scratch products use `tempfile`s. No row-level output
   or weight file enters Git.

## Scientific adjudication

- **Primary adult transport:** not identified. Unlinked people lack 2017 age,
  and community-source coverage is selective. An all-source-person linkage
  model cannot identify an all-source eligible-adult population or restore
  people absent from the delivery.
- **Household MAR weighting:** computationally assessable because the source
  household denominator is known. Baseline propensity support is necessary but
  not sufficient; lack of within-CCPP baseline predictors limits the model.
  Until MAR conditional on these variables is substantively defended, weights
  remain diagnostics rather than replacements for primary results.
- **Linked-adult movement weighting:** at most targets linked known-age adults;
  it cannot repair person linkage or uncovered communities.
- **Lee/Dong causal bounds:** an observed sign or nonsignificant selection jump
  does not establish individual potential-selection monotonicity. The multiple
  selection layers and unknown adult eligibility do not establish the required
  selected population, monotonicity, or fuzzy-design assumptions. No causal
  trimming bound is computed here.
- **Heckman:** no defensible excluded selection instrument is supplied.
  Functional-form extrapolation is not substituted for the missing argument.
- **CMAN timing:** the owner assumption does not establish score predetermination,
  cutoff exogeneity, exclusion, selection ignorability, or causal mediation.
  Existing RD estimates remain conditional on their stated assumptions.

The methodological distinctions follow Dong (2019), *Regression Discontinuity
Designs With Sample Selection*, DOI <https://doi.org/10.1080/07350015.2017.1302880>,
and Lee (2009), *Training, Wages, and Sample Selection*, DOI
<https://doi.org/10.1111/j.1467-937X.2009.00536.x>.

## Observed feasibility results

Counts below are unweighted; the exported rates give represented RUV communities
equal weight within each stated parent frame. The common window is `h=0.0075`.

| Stage | Observed numerator | Parent denominator |
| --- | ---: | ---: |
| Community source-cohort entry | 64 | 71 RUV communities |
| Person linkage | 9,862 | 13,010 source people |
| Person movement observed | 9,862 | 13,010 source people |
| Known-age linked-adult movement observed | 7,680 | 7,680 linked adults |
| 2017 age unknown | 3,148 | 13,010 source people |
| Any linked household member | 3,532 | 4,051 source households |
| Any household member with observed movement | 3,532 | 4,051 source households |
| All eight primary household outcomes observed | 2,935 | 4,051 source households |

These are separate denominators, not a single sequential attrition funnel.
Unknown 2017 age is not a count of unknown adults. Across the full selected B/C
geography, 425 of 549 RUV communities enter the source cohort; the source frames
contain 110,906 people and 33,060 households. The approved nationwide canonical
files remain 193,342 people, 58,015 households, and 5,712 RUV communities.

Baseline-only feasibility models use `b=0.0135`:

| Selection stage | Parent rows | Baseline-complete rows | Model-frame CCPPs | Probability range | Kish observation ESS | Model-frame CCPPs with no selected row |
| --- | ---: | ---: | ---: | --- | ---: | ---: |
| Person linkage | 45,740 | 45,482 | 107 | 0.607 to 0.883 | 2,664 | 1 |
| Household completeness | 13,371 | 13,285 | 107 | 0.397 to 0.927 | 1,230 | 3 |
| Linked-adult movement | 28,250 | 28,086 | 106 | Empirical probability 1 | 2,840 | 0 |

The first two logits converge and retain all baseline-complete rows. Every
baseline-complete linked adult has observed movement in this window, so no adult
logit is fitted (`n_fit=0`, convergence not applicable). This does not imply that
all source adults are linked or their movement observed. ESS includes the
CCPP-equal weights and is not a number of independent clusters. Fitted support
is not demonstrated MAR, true population overlap, or transportability.

The descriptive intervals propagate every missing person's movement. Of the
4,051 source households, 2,189 have movement for all source members, 1,343 for
only some members, and 519 for none. The partly observed households also
contribute interval width; the primary observed-member household outcome is
not altered.

| Finite source-frame mean | Below cutoff | Above cutoff | Above-minus-below interval |
| --- | --- | --- | --- |
| All-age person movement | 27.80% to 50.82% | 28.83% to 53.74% | -21.99 to 25.94 percentage points |
| Household all-source-member movement share | 28.29% to 52.85% | 28.68% to 55.59% | -24.17 to 27.30 percentage points |

These are bounded descriptions of the delivered source frames, with CCPP-equal
parent weights. They are not confidence intervals, local-polynomial RD effects,
fuzzy-RD LATE bounds, or replacements for I03. Missing communities are outside
these delivered-cohort targets. Do not divide these endpoints by a first stage.

## Literature-access and source-verification receipt

- The linked project NotebookLM answered two queries in session `51f8b4b5`.
  It was used for discovery only. Its claims that a nonsignificant linkage test
  establishes continuity or positive fitted probabilities establish common
  support were not adopted; neither establishes selection ignorability.
- The shared Zotero library `IE Collective Reparations Peru` was requested
  read-only. Native requests and the existing read-only local bridge were
  unavailable in this session (local service connection refused). No library,
  authentication, or credentials were changed. Prior library contents were not
  presented as freshly retrieved evidence.
- The underlying [Dong author PDF](https://www.yingyingdong.com/Research/J14_JBES.pdf)
  was read in memory, specifically PDF pages 5-7: smooth observed selection is
  not sufficient on its own; section 3.1 imposes individual potential-selection
  monotonicity; fuzzy selection bounds also require identified selection
  proportions and outcome distributions for the relevant principal strata.
- The [Lee author draft dated August 2008](https://www.princeton.edu/~davidlee/wp/resrevision8.pdf)
  was checked at PDF pages 14-16 and 29. Independence and individual selection
  monotonicity underpin trimming for the always-selected target; observed mean
  selection rates do not themselves prove that assumption. The published DOI
  above identifies the 2009 article; the inspected document was the author draft.
- Source PDFs were not copied into Git or newly written into Dropbox. Synthesis
  was not treated as a substitute for these supporting passages.

## Execution ledger

- Baseline: `a4570b6`; clean primary checkout; no commit/push authorized.
- Ruling: adopt CMAN year and close historical-date acquisition; cost is
  unverified allocation/delivery timing, explicitly disclosed in the protocol.
- Ruling: preserve I03 and evaluate rather than automatically apply selection
  adjustment; cost is limited transportability, not an invented adult denominator.
- Independent review: one Important finding (missing members within partly
  observed households) and one Minor label issue (model-frame CCPP counts).
  Both were resolved in one corrective pass. The primary household outcome
  remains unchanged; no additional primary analysis or estimand was introduced.
- Test evidence: the household interval check failed on the old observed-member
  endpoints (`r(9)`), then passed after all-source-member endpoints were used.
  A two-member partly observed example is checked explicitly; range, cardinality,
  denominator, convergence, support, precision, and noncausal flags are tested.
- Standalone module-06 graphics now explicitly select the verified publication
  scheme `plotplainblind`, with a built-in fallback, instead of inheriting
  session state. The new selection-flow chart explicitly uses its verified
  scientific scheme with a built-in fallback.
- Runtime closeout covers module 06, publication inventory 07, release checks 08,
  all 11 Stata contract tests, source and exhibit checksums, and rendered outputs.
  Results of these checks are reported with the delivered commit handoff.

## Next milestone

Prepare journal-sized main/appendix review exhibits with denominator and
conditional-identification notes. Artifact-level disclosure/owner approval and
exact safe Overleaf destinations remain required before publication sync.
