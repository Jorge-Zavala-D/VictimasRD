# Proposed World Development referee edits — not applied

Scope: five existing TeX files under the synchronized `World Development Manuscript` folder. Paths and line numbers below refer to the reviewed local snapshot. No table, figure, citation, bibliography, title, estimate, input path, or reporting role changes. Apply only after approval and a fresh baseline check.

## 1. Abstract — contribution, uncertainty and selection

`sections/00_abstract.tex`, replace the single abstract paragraph (line 2), leaving the keywords and JEL lines intact:

```tex
Collective reparations can finance shared infrastructure and services rather than compensate victims individually. Evaluating these projects requires distinguishing conditions in targeted places from the circumstances of people originally observed there. We study Peru's program using victim and project-financing registers, the 2013 household targeting registry, and an assisted linkage to the 2017 Census. Within a historically selected set of regions, we compare adjacent victimization categories around the B/C priority boundary using a common score window. Recorded financing years define receipt through 2012 and 2016 under an allocation-and-delivery assumption. None of the 48 primary fuzzy regression-discontinuity estimates survives adjustment within its eight-outcome family; the intervals do not rule out substantively important effects. For linked people aged 14 or older with valid origin and destination codes, the estimated receipt contrast for movement between communities is $+21.45$ percentage points (95\% confidence interval: $[-17.24,60.14]$). This contrast does not establish increased migration or describe all original residents. Complete household-outcome availability also changes at the cutoff, underscoring the need to separate outcome estimates from who is observed. The evidence supports conditional local comparisons, not a national impact estimate or a causal account of migration. Recognition of harm is a separate aim of reparations that these administrative outcomes do not measure.
```

## 2. Introduction — articulate the contribution as a measurement and design problem

`sections/01_introduction.tex`, insert immediately before the paragraph beginning “The paper connects three substantive conversations”:

```tex
The contribution is to bring the administrative record of collective project financing into the same evaluation as outcomes measured in targeted places and outcomes observed for members of an earlier source cohort. Neither population can stand in for the other. The policy comparison is local, and the observation process is part of the evidence rather than a reason to treat the linked records as a census of original residents.
```

## 3. Results — keep causal interpretation conditional at the point of use

`sections/05_results.tex`, insert immediately before `\subsection{Receipt contrasts and local information}`:

```tex
The cutoff marks a documented priority distinction, not a uniform assignment rule for every year covered by cumulative receipt. We interpret the outcome discontinuity as an assignment-side contrast. A causal receipt interpretation additionally requires continuity, exclusion, monotonicity and, for outcomes observed only in selected records, a defensible account of observation. The first stage measures relevance in the analysis sample; it does not establish these conditions.
```

## 4. Results and robustness — specify the age rule and the comparison mean

In `sections/05_results.tex`, replace “broader observed-adult migration sample” with “broader observed-movement sample of linked people aged 14 or older”. In the paragraph beginning “Primary individual movement”, replace the sentence beginning “This is not a 21.45” with:

```tex
The lower-score-side rate is descriptive, not a complier baseline; the estimated contrast is in percentage points, not a relative percentage change.
```

In `sections/07_robustness.tex`, replace the two-line sentence beginning “The primary movement contrast concerns linked adults” with:

```tex
The primary movement contrast concerns linked people aged 14 or older with valid canonical origin and destination codes, not all original residents.
```

Do not search-and-replace “adult” in generated inputs. Where retained as an abbreviated label elsewhere, the underlying threshold is defined in Sections 3 and 5.

## 5. Robustness and Appendix D — reconcile prospective wording

In `sections/07_robustness.tex`, replace the paragraph beginning “Primary-sample diagnostics do not qualify” (lines 47–49), leaving the next paragraph intact:

```tex
Primary-sample diagnostics do not qualify secondary outcomes or sensitivities estimated on different samples. Online Appendix~D reports the exact-sample diagnostic dispositions. A ratio lacking a usable diagnostic or failing the operational screen remains diagnostic only; passing the screen does not change an estimate's registered reporting role.
```

In `appendix/D_additional_results.tex`, replace the paragraph beginning “These secondary and unmatched sensitivity ratios” (lines 76–81):

```tex
The exact-sample audit below records the diagnostic disposition for each registered specification. A primary first stage cannot certify a different eligibility or missing-data sample. Receipt ratios without a usable diagnostic or that fail the operational screen remain diagnostic only, and passing does not promote secondary or sensitivity estimates. Multiplicity adjustments retain failed applicable hypotheses in their registered families; unavailable fits do not acquire reported inferential probabilities.
```

## Acceptance checks for a later integration

- Exact source diff has only the five named paths; preserve all 57 generated input hashes, including the 55 inherited inputs.
- Build main and Online Appendix from the revised exact source. Check changed-page layout, cross-references, citations and actual exhibit consumption. Verify that neither the three conventional AR exclusions nor the two adjusted parametric sensitivity results are promoted.
- Keep release and submission on hold; the proposal does not authorize even these five changes.
