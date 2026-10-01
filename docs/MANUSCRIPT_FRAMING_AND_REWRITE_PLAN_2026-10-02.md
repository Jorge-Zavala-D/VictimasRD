# Collective reparations: journal framing and manuscript revision plan

**Date:** 2 October 2026. **First-target recommendation:** World Development.
**Alternative framing:** International Journal of Transitional Justice (IJTJ).
**Status:** owner-requested planning deliverable, not a submission-ready paper or
an artifact-release decision. Both framings use the same audited evidence.

## 1. Decision and scope

Develop the paper first for World Development, with collective reparations as
a place-based development intervention motivated by redress for political
violence. Keep a genuinely different IJTJ argument available: what material
and mobility evidence can establish about the transformative ambitions of
collective redress. Do not treat these as two introductions to different
empirical findings.

The recommended World Development question is substantive, not a claim that
a technically elaborate estimator is itself a contribution. The paper brings
community, household, and person evidence together while showing why material
conditions, the fortunes of original residents, and the normative success of
reparations are distinct objects. The present estimates are imprecise and
selection-sensitive; the paper cannot retain its legacy headline of a
confirmed migration effect explained by causal mediation.

This batch changes planning/orientation documentation only. It does not
change data, code, estimands, numerical exhibits, registry roles, bibliography
entries, or live Overleaf source. It does not approve held outputs, install
skills, submit a paper, or authorize a commit. Existing research decisions
remain binding. The earlier request for unavailable dated RUV histories and
annual eligibility/award lists is not reopened as a prerequisite.

### Why World Development first

The development framing uses the widest defensible part of the evidence:
local living conditions, social-program coverage, demographic composition,
mobility, institutions, and the difficulty of equating place improvement with
beneficiary welfare. This aligns with the journal's multidisciplinary scope,
which includes living conditions, poverty, institutions, participation, and
civil conflict. [Official World Development scope](https://shop.elsevier.com/journals/world-development/0305-750X).

IJTJ is a strong intellectual alternative if the argument instead centers
rights-based redress, collective victimhood, recognition, and the relation
between reparation and ordinary development. But our administrative outcomes
do not measure dignity, recognition, participation, reconciliation, or justice
directly. That framing must make this boundary explicit, not label an
uncertain material estimate a test of transformative justice itself. This is
an assessment of fit, not a prediction of editorial acceptance.

## 2. Common evidence and interpretation contract

These facts are frozen for both framings. They come from the current review
packet and superseding project decisions, not from the legacy paper's tables.
See [the publication review pack](PUBLICATION_REVIEW_PACK.md),
[the identification review](IDENTIFICATION_AND_PUBLICATION_REVIEW_2026-09-30.md),
[the selection-feasibility contract](CENSUS_2017_SELECTION_FEASIBILITY_2026-09-30.md),
and [the numerical review narrative](PUBLICATION_RESULTS_NARRATIVE.tex).

| Evidence object | Current audited content | What the paper may not infer |
| --- | --- | --- |
| Source universe and geography | All 5,712 supplied RUV communities are retained. The approved geography contains 1,162: Apurimac and Huancavelica, La Convencion province in Cusco, and Huancayo province in Junin. | The selected sample is not all four departments, all highland Peru, or the national program population. |
| RD neighborhood | Adjacent B/C support; official cutoff 0.062320; common estimation window `h=0.0075`, bias window `b=0.0135`. The base window has 71 communities; outcome availability changes effective samples. | Neither geography nor the common window was prospectively chosen before the historical design search. A locked window does not imply identical samples or outcome-specific optimality. |
| Treatment and timing | Cumulative `treat_12` for 2013; `treat_16` for 2017. CMAN's recorded project year is assumed to represent both allocation and delivery. SISFOH measures are treated as materialized in 2013. | These are binding measurement assumptions, not independently verified completion dates or reconstructed historical risk sets. |
| Institutional prioritization | Dated official evidence supports joint A/B priority and additional administrative conditions, including municipal execution/accountability; not a strict national A-then-B queue. | The B/C boundary cannot be sold as automatic or universally enforced eligibility. A visible local first stage does not establish exclusion or monotonicity. |
| Primary outcomes | 48 common-window fuzzy tests in six separate eight-outcome families; none has within-family Holm `p<0.05`. Intervals often permit substantively important effects. | This is not one global 48-test adjustment, proof of zero effects, equivalence, or a finding that reparations failed. |
| Primary observed migration | Linked people with known 2017 age at least 14 and valid canonical origin/destination CCPP movement. Estimate +21.45 percentage points; robust 95% interval [-17.24, 60.14], raw `p=0.277`, family Holm `p=1.000`; effective 7,680 people in 63 communities; matching local-IV KP F=20.80. | It is not a confirmed 25% relative increase, not movement inferred from nonlinkage, and not an effect for all original residents or an identified always-linked stratum. |
| 2017 observation boundaries | Complete household analysis availability has a -29.71-point discontinuity, interval [-52.20, -7.22], raw diagnostic `p=0.0096`. Household member linkage is a different diagnostic (-9.82 points; interval [-34.82, 15.17]). | A nonsignificant linkage test does not make outcome availability ignorable. These diagnostics are not multiplicity-adjusted substantive program outcomes. |
| Source-code adjudication | Preserve the immutable 193,376-person INEI delivery. The approved 34-record Ancahuasi quarantine leaves 193,342 analytical source people, 58,015 source households and 802 represented RUV communities. Ranracancha is retained under the approved correction. | These are delivery/analytical source counts, not counts of people observed in both years or of people in the local RD outcome sample. |
| Heterogeneity | Primary receipt-effect heterogeneity uses gated local IV. Across modules, 63 gate-passing contrasts do not survive their original tier-specific multiplicity adjustments. `rdhte` has 15 adjusted assignment-side signals among 270 supported adjusted contrasts. | Failed gates are unavailable evidence, not zero effects. Assignment-side signals are not fuzzy receipt effects or independent replications. |
| Mechanism and dose evidence | Candidate intermediate outcomes and noncausal associations remain distinct. Project types are post-assignment choices. Six financing-dose artifacts remain excluded. | No identified causal mediation from contemporaneous 2017 internet, employment and migration; no causal ranking of project types; no promotion of excluded dose results. |
| GDP and wellbeing | Wellbeing/deprivation proxies use their documented components and denominators. Community GDP is allocated district GDP using fixed 2007 population shares; logs remain log points. | No independently measured CCPP inequality or growth; no automatic exponentiation of a fuzzy ratio into a complier-average percentage effect. |

Keep source-cohort coverage, person linkage, movement observability, age
eligibility and complete-outcome availability as separate populations.
Community-weighted rates and person counts are not interchangeable. The
finite-source support intervals in A25 are descriptive intervals for their
stated all-age/source-household frames, not adult causal bounds or confidence
intervals. No automatic inverse-probability weighting, Lee trimming, or
missing-outcome causal bounds are added through the writing process.

Conditional fuzzy-RD interpretations require the stated continuity,
exclusion, monotonicity and observation assumptions. F>10 is the registered
reporting gate, not proof of identification. More household/person records
do not create more independent community assignment units. Related analyses
at three aggregation levels are not three independent confirmations.

### Evidence freeze

The following SHA-256 hashes identify the reviewed material used for this
planning batch. If an input changes, rerun the existing publication-review
check and reconcile the plan before drafting numerical claims. Hashes prove
file identity, not scientific correctness or permission to publish.

| Input | SHA-256 |
| --- | --- |
| `output/tables/publication/publication_results_values.tex` | `8FFDD2AB9E8076CEFEA6BD78FE9418E9B2A9DA5EF98D18CDCBB26965478B7602` |
| `output/tables/publication/publication_review_exhibits.csv` | `B007B7BAF32B64B5947F28C081F902F21E4F5E24DCE1EE0A97E0CC49F5FAB247` |
| `metadata/publication-exhibit-review-2026-09-30.csv` | `C62273BC53D11E17BB78C497038CC3EDBF221EC70F0EABF03AD53070ECB4BF64` |
| `docs/PUBLICATION_RESULTS_NARRATIVE.tex` | `B8946D678F3282109E3FB0AB11264E496806A774599A43161FB0112A0BF0D960` |
| Configured Overleaf root: `Working Paper - Legacy/Working Paper.tex` | `142756E6E22AB27206D75DD192456BE0A6D14FB192EEB8F2BD461F10514B0A9A` |

## 3. Side-by-side framing assessment

| Element | World Development: recommended first framing | IJTJ: alternative framing |
| --- | --- | --- |
| Working title | **Collective Reparations, Local Development, and Mobility in Peru** | **Collective Reparations between Redress and Development: Evidence from Peru** |
| Central question | Can collective reparations translate redress for conflict-affected communities into improved local living conditions, and how should residents' mobility enter that assessment? | What can changes in material conditions and residents' mobility tell us, and not tell us, about the transformative ambitions of collective reparations? |
| Contribution statement | We connect the development consequences of community-level reparative investment to the distinction between places and people. Linked administrative evidence across two outcome periods permits a transparent local assessment of living conditions and mobility, while implementation and observation boundaries discipline the conclusions. | We bring local quantitative evidence to the debate over reparations and development without equating them. The analysis clarifies what observable material outcomes can establish about collective redress and why uncertain effects or population movement cannot determine whether justice was achieved. |
| Reader's initial problem | Public investment justified by historical harm is expected to support recovery, but improved place-based conditions and gains to original residents need not coincide. | Development-like projects are asked to carry reparative and sometimes transformative purposes; the evaluative standard must distinguish material benefit from acknowledgment, participation and justice. |
| Conceptual spine | Competing anchoring and mobility-enabling pathways; place outcomes versus original-resident outcomes; policy interaction as a hypothesis. | Corrective/distributive purposes; collective victimhood and boundary of redress; the difference between development provision and recognition. |
| Best use of migration | An important, imprecisely estimated observed-resident outcome, not the paper's established causal headline. | A warning against treating retention, exit or an infrastructure outcome as a sufficient measure of reparative success. |
| Main vulnerability | The present evidence is too imprecise for a confident positive/negative development verdict, and historically selected support and linkage constrain inference. | Normative reparative success is not observed; a justice-centered contribution cannot be manufactured from administrative outcomes alone. |
| Portability | Lessons for evaluating collective/place-based investment after violence, with explicit institutional and observation scope conditions. | Lessons for evaluating collective redress where material projects are delivered through ordinary administrative institutions. |
| Claim to avoid | “Reparations caused depopulation through greater market integration.” | “The program was not transformative,” or “migration demonstrates reparative failure.” |

Both papers would report the same populations, estimates, uncertainty,
multiplicity adjustments, negative evidence and scientific limitations.
The difference is the question the evidence addresses and the literature
conversation it enters, not which favorable coefficients appear.

### 3.1 Proposed World Development abstract

The following is a provisional framing abstract, not a live-manuscript edit.
The 250-word ceiling is a conservative drafting target inherited from the
existing scaffold, not a freshly verified journal requirement.

<!-- BEGIN WORLD DEVELOPMENT ABSTRACT -->
Collective reparations seek to redress violence against communities while
supporting their material recovery. Yet improving conditions in a place and
improving the lives of its original residents need not coincide. We study
Peru's community-project reparations program using victim and financing
registers, population information, the 2013 household targeting registry,
and an assisted linkage to the 2017 Census. A fuzzy regression-discontinuity
analysis compares adjacent victimization categories within a historically
selected geography and a common score window. Treatment is recorded receipt
through 2012 or 2016 for the respective outcome periods. Across six primary
outcome families, none of 48 estimates passes within-family multiplicity
adjustment; confidence intervals nevertheless permit substantial changes.
Among linked people aged 14 or older with observable community movement,
the migration estimate is +21.45 percentage points, with a 95% interval from
-17.24 to 60.14. A discontinuity in complete household outcome availability
further limits interpretation of the linked evidence. Institutional records
describe prioritization combined with administrative conditions rather than
a strict national sequence of victimization categories. These findings do
not establish either the absence of development effects or a causal
migration mechanism. They underscore the importance of distinguishing
community conditions, observed residents' mobility, and unmeasured reparative
objectives when evaluating place-based recovery after violence.
<!-- END WORLD DEVELOPMENT ABSTRACT -->

### 3.2 Proposed IJTJ abstract

This version follows the stricter 150-word limit in the current General
Instructions, despite an inconsistent older style page mentioning 200 words.

<!-- BEGIN IJTJ ABSTRACT -->
Collective reparations often finance development-like projects, but material
improvements cannot alone establish reparative or transformative success.
We examine Peru's community-project program using victim and financing
registers and linked administrative population data. A local fuzzy
regression-discontinuity analysis compares adjacent victimization categories
in a historically selected geography. None of 48 primary outcome estimates
passes within-family multiplicity adjustment, although intervals permit
substantial effects. Among linked people aged 14 or older with observable
community movement, the migration estimate is +21.45 percentage points
(95% interval: -17.24 to 60.14). Outcome availability also changes at the
threshold, limiting generalization. We distinguish these conditional
material and mobility estimates from unobserved recognition, participation,
and justice. The case clarifies the evidentiary limits of assessing
collective redress through development outcomes, without interpreting
imprecision or migration as proof of reparative failure.
<!-- END IJTJ ABSTRACT -->

## 4. Compact exhibit plans using the same evidence

The existing packet has six proposed main exhibits (M01-M06) and 29
supporting exhibits (A01-A29). These are **review artifacts**, not an approved
submission layout. Proposed recombinations below are future presentation
work: they do not exist yet as combined files, change no canonical roles and
must be generated from versioned code, not edited manually in Overleaf.

### World Development: six main exhibit slots

| Slot and question | Evidence to reuse | Presentation and claim boundary |
| --- | --- | --- |
| WD1. What population and intervention are being studied? | Institutional facts in the identification review; selection stages A23 and A29; fixed sample contract. | A concise study-architecture/sample table, to be generated later from documented aggregate metadata. Distinguish national RUV universe, geography, score neighborhood and observed cohorts. No falsely sequential attrition funnel. |
| WD2. How large and uncertain are community changes in the two periods? | M01 and M02, community forest plots. | One two-panel figure, preserving all eight outcomes per period and the stated standardization. Do not compare standardized magnitudes as identical welfare quantities. |
| WD3. What are the estimates in original units? | M03 and M04, full community result tables. | A two-panel table retaining complete families, reduced forms, fuzzy estimates, robust intervals, Holm adjustments and effective CCPP counts. Pairing is a proposed display, not a new pooled estimand. |
| WD4. What does the observed-person evidence show? | M05, complete 2017 individual family. | Preserve all eight outcomes; make migration's broader observed-adult sample explicit. Do not hide the seven non-migration outcomes or treat their complete-case sample as the migration denominator. |
| WD5. How does observability constrain that reading? | M06, household availability/linkage; A29 and A10 for distinct person/CCPP stages. | Selection graphic plus clearly separated diagnostic entries. Move this before WD4 if needed for comprehension. Never splice household and person counts into one denominator. |
| WD6. Is there an interpretable local treatment contrast? | A11 and A18, CCPP first stages; A22 for the individual/migration contrast; institutional and score diagnostics in the validity appendix. | A compact two-period design exhibit with outcome-relevant first stages and uncertainty. No blanket “all tests pass” caption; disclose finite support, historical selection and observation assumptions in text. |

The full existing M01-M06 remain available in the review packet while this
six-slot plan is considered. No combined display is called publication-ready
before it is rendered, checked against source rows and separately reviewed.

### IJTJ: four main exhibit slots

IJTJ's General Instructions limit articles to four main tables/figures/
diagrams. [Official instructions](https://academic.oup.com/ijtj/pages/General_Instructions).

| Slot and question | Exactly the same evidence | Presentation and claim boundary |
| --- | --- | --- |
| IJ1. How does collective redress become an administered local project? | Same institutional facts, sample contract and A23/A29 source architecture used by WD1. | One compact institutional/evidence table. Keep the transformative aspirations as theory, not measured outcomes; no invented process interviews or victim-satisfaction evidence. |
| IJ2. What material changes can be estimated locally? | M01 and M02, with complete M03/M04 numerical tables in the supplement. | Same paired community forest figure as WD2. Include uncertainty and all registered primary outcomes, not only social-program or population rows. |
| IJ3. Does observed mobility establish a transformative consequence? | M05, unchanged. | Same full individual primary table, with explicit population and interpretation boundaries. No mediated or “hollowing out” conclusion. |
| IJ4. Who is visible in the evidence? | M06, A10, A23 and A29, unchanged. | A single compact selection exhibit with separate household/person/CCPP denominators. This is an evidentiary qualification, not a separate outcome-effect claim. |

Both plans retain the same first stages and validity diagnostics, outcome
definitions, household/2013 person results, sensitivity estimates,
heterogeneity gates, and mechanism boundaries in supporting material. IJTJ
compresses the main presentation, not the disclosure of inconvenient evidence.

### Shared appendix organization

| Existing appendix file | Evidence and purpose |
| --- | --- |
| `appendix/A_program_data.tex` | Primary institutional sources, official index/cutoffs, treatment-year assumption, transparent CMAN classification, project composition (A04/A08). No completed-project verification claim. |
| `appendix/B_data_construction_linkage.tex` | Outcome registry, source-vintage crosswalk, approved adjudication, separate linkage/observation populations (A10/A23/A24/A25/A29). Explain feasibility limits, not automatic selection correction. |
| `appendix/C_rd_design_validity.tex` | Corresponding first stages (A11/A13/A16/A18/A20/A22), score precision/support, density and one covariate-continuity plot per tested baseline variable, bandwidth and other registered sensitivities (including A01/A02). Map additional canonical outputs only after provenance/release review. |
| `appendix/D_additional_results.tex` | Complete household and 2013 individual primary families (A14/A17/A21), outcome definitions (A12/A15/A19), remaining registered specifications and metadata. Keep units and complete families. |
| `appendix/E_mechanisms_heterogeneity.tex` | Gated fuzzy heterogeneity and assignment-only results (A03/A05/A06/A07/A09/A26), candidate intermediate outcomes (A27), noncausal associations (A28). Six excluded dose artifacts remain excluded. |
| `appendix/F_replication_transparency.tex` | Historical design search, software/specifications, restricted-data access and shareable-code boundary, output provenance, AI-use disclosure and release gates. |

## 5. Literature grounding and coverage receipt

Read the [literature integration workflow](LITERATURE_NOTEBOOKLM_WORKFLOW.md)
before using these sources. This is targeted grounding for the framing
decision, not a claim to have completed a new systematic review of the entire
library.

**Zotero:** the shared `IE Collective Reparations Peru` library resolves to
library ID 5. Read-only metadata, attachment identities and targeted
underlying text were consulted; no library item was changed. Existing BibTeX
keys below were checked in the synchronized root `Bibliography.bib`.

**NotebookLM:** the explicit project notebook
`1057e1f5-e2ff-4dc9-8b46-39ad44841f9c` was queried through both supplied URL
aliases. Both attempts failed with a closed persistent browser-context error.
No fresh NotebookLM synthesis is claimed, no unrelated active notebook was
used and no authentication/browser state was changed. The direct-source
verification below is the bounded fallback. A later successful query can
identify additional leads; it must not override the audited evidence.

| Verified source and existing key | Underlying passage checked | Use in the argument and limit |
| --- | --- | --- |
| Laplante and Theidon (2007), *Truth with Consequences*, DOI `10.1353/hrq.2007.0009`; `laplante_truth_2007`; Zotero item 1675/attachment 1676. | Source PDF p. 2 (printed p. 229), continuation of abstract/introduction: testimony and acknowledgment require concrete redress. | Ground the reparative motivation and state-response distinction. Historical interpretive evidence, not an estimate of the current program's effect on recognition. |
| Firchow (2013), *Must Our Communities Bleed to Receive Social Services?*, DOI `10.1080/15423166.2013.863689`; `firchow_must_2013`; item 1690/1691. | Source PDF p. 11 (printed p. 59), Peru comparison and conclusions; earlier conceptual distinction on PDF p. 3 (printed p. 51). | Separate ordinary service provision from reparative meaning. Colombia-focused qualitative discussion with a Peru comparison, not direct causal evidence for our sample or all later implementation years. |
| Gready and Robins (2014), *From Transitional to Transformative Justice*, DOI `10.1093/ijtj/iju013`; `gready_transitional_2014`; item 1749/1751. | Source PDF pp. 8-9 (printed pp. 346-347), socioeconomic rights, structural harms, and reparations versus development; underlying targeted participation passage also consulted. | Give the IJTJ frame its conceptual standard. Do not operationalize broad transformation as a single wellbeing score or migration coefficient. |
| Adhikari and Gentilini (2018), *Should I Stay or Should I Go?*, DOI `10.1596/1813-9450-8525`; `adhikari_should_2018`; item 1794/1795. | Source PDF p. 17 (printed p. 15), concluding synthesis; underlying discussion of financing constraints and program conditions. | Support competing anchoring/mobility hypotheses. A review of cash-transfer programs is not evidence that Peru's collective projects supplied cash to migrants or caused either pathway. |
| Guarin, Londoño-Vélez and Posso (2023), *Reparations as Development?*, Borradores de Economia 1236, DOI `10.32468/be.1236`; `guarin_reparations_2023`; item 1756/1757. | Correct source PDF pp. 1-3: title/year and English/Spanish abstracts; underlying introduction consulted through Zotero. | Locate the material-reparations comparison: individual lump-sum compensation in Colombia, not collective project investment in Peru. Cite the verified working-paper version; do not silently substitute a later publication. |

The relevant PDFs were checked in the Dropbox `Zotero library` mirror. A
legacy-folder file titled `Guarin et al (2023) Reparations as Development.pdf`
instead contains a broader social-protection/conflict discussion; that
filename was not accepted as provenance for the 2023 empirical study. The
correct titled/dated source in the Zotero mirror was used. Neither source was
renamed or modified.

### Direct-source identities

SHA-256 prefixes below identify the consulted mirror copies (full filenames
remain in the shared literature folder); this is not a redistribution of
third-party PDFs.

| Source | SHA-256 prefix |
| --- | --- |
| Laplante and Theidon 2007 | `B22DA41F776C0084` |
| Firchow 2013 | `5CE2DD975786FE4F` |
| Gready and Robins 2014 | `F31A3C7A23297CBF` |
| Adhikari and Gentilini 2018 | `9E160D72F9106D85` |
| Guarin et al. 2023, correct working-paper copy | `CB1377E8B2BEBF06` |

Before the context/introduction writing batch, complete targeted passage
checks for the other references actually used: the applicable primary legal
and CMAN records; individual-reparations political-feedback work; and any
migration/welfare comparison. In particular, the 2026 Guarin/Londoño-Vélez
chapter and Voytas reference are leads, not newly verified supporting
passages in this batch. Do not add a “first study” or “unique contribution”
claim without a documented contemporary comparison.

## 6. Conceptual framework to carry into the paper

Use one integrated framework, not a new formal model that the evidence
cannot distinguish:

1. Collective reparations combine a material intervention with a reparative
   purpose. Implementation through ordinary public institutions can connect
   communities to services but does not by itself establish recognition.
2. Better local opportunities or benefits tied to residence can encourage
   staying. Resources, information or access to opportunities elsewhere can
   make mobility easier. These are competing hypotheses, not established
   mediators in this data.
3. Place-based outcomes and original-resident outcomes can diverge.
   Aggregates may reflect changing composition as well as changed conditions;
   an original-cohort linkage observes only some residents and destinations.
4. Endogenous project choice, contemporaneous potential intermediates and
   incomplete observation prevent a causal decomposition of the migration
   coefficient into those pathways.
5. Neither migration nor retention is assigned a welfare sign without data
   on circumstances, destinations, opportunities and preferences. Exit is not
   automatically failure, nor automatically successful empowerment.

Map each proposed implication to an observable outcome, and name what is
not measured. Theory may motivate analyses; it may not manufacture support
from a raw significant coefficient or a descriptive project association.

## 7. Current manuscript inventory and revision map

The synchronized Overleaf root currently contains **Working Paper - Legacy**
and **World Development Manuscript**, plus the shared `Bibliography.bib`.
The active draft already has `main.tex`, nine section files, six appendix
files, a preamble and administrative files. Reuse them; do not create a
second manuscript scaffold or overwrite the legacy paper.

The existing World Development main/appendix are primarily placeholders,
not the current results paper. `generated_tables_review.tex` is a separate
August 2026 inspection harness, not a manuscript input and not proof that
its older synchronized tables match the corrected September evidence.
Author details were not copied into Git or the planning record.

Legacy locators below refer to `Working Paper - Legacy/Working Paper.tex` as
read on this date. Actions are proposed future source edits, not edits
already performed.

| Existing destination | Retain or build on | Rewrite/retire and evidence obligation |
| --- | --- | --- |
| `paper_metadata.tex`; `sections/00_abstract.tex` | Topic and collective-reparations focus. | Replace the transformation/policy-feedback causal promise with the preferred framing. Legacy abstract line 40 has stale universe counts, a 25% migration headline and identified-mediation language. Use the provisional abstract only after final numerical reconciliation. |
| `sections/01_introduction.tex` | Problem of material recovery after violence; distinction between individual and collective redress. | Rewrite legacy lines 69-73: no established greater migration, robust subgroup story, or proven policy-feedback channel. State conditional evidence and uncertainty before offering the contribution. |
| `sections/02_context_framework.tex` | Concise verified conflict/reparations architecture and competing conceptual pathways. | Replace the strict staggered-category narrative with the dated joint A/B/admin-conditions evidence. Separate documented requirements from execution facts not observed. Keep recognition as a purpose, not a measured result. |
| `sections/03_data_measurement.tex` | Source architecture and three units of analysis. | Legacy line 204 wrongly describes all 193,376 delivered people as linked in both sources and in the RD geography. Replace with distinct source/linkage/observability populations and the approved correction. Existing scaffold lines 11-12 incorrectly call geography pre-specified; use “historically selected and subsequently fixed.” Define each family/cohort and treatment-year assumption. |
| `sections/04_empirical_strategy.tex` | Estimand-first organization; local polynomial/RD diagnostics. | Explain the adjacent B/C contract, common-window versus outcome-completeness distinction, rounded score/ties, finite mass points, inference and gate scope. A local first stage does not verify national policy enforcement, exclusion, monotonicity or ignorable linkage. Preserve search history. |
| `sections/05_results.tex` | Complete family order and original-unit estimates. | Rewrite legacy results lines 599-666 from the current packet, not by adjusting old sentences. Keep all 48 primary tests visible across main/appendix; no selective social-program or migration victory narrative. Distinguish person/household/community weights, samples and outcome periods. |
| `sections/06_mechanisms_heterogeneity.tex` | Motivation from Ana Maria's migration/mechanism work and theory-driven moderators. | Recast as “Extensions and mechanism evidence.” Legacy lines 671-692 and appendix 831-836 do not establish mediator ignorability through RD or covariate adjustment. Report IV gates, assignment-only checks and noncausal associations separately. No automatic per-capita-dose or project-type causal claim. |
| `sections/07_robustness.tex` | Threat-organized structure. | Replace “all tests validate the design” with threat-specific findings and remaining uncertainty. Include selection and institutional conditions, not just density/balance p-values. Do not treat alternative windows as opportunities to recover significance. |
| `sections/08_conclusion.tex` | Relevance of redress to development practice. | Retire legacy lines 726-730's acceleration, demographic transformation and causal-mechanism conclusions. State the narrow populations, broad intervals, what cannot be established and what better observation would resolve. |
| Six existing appendix files | The current division of program, construction, validity, outcomes, extensions and transparency is suitable. | Populate from the source-mapped evidence above. Full inclusion is not indiscriminate dumping: every exhibit gets a question, denominator, estimator, uncertainty and limitation. |
| `preamble.tex`, `highlights.tex`, `submission_checklist.tex`, declarations/cover/title files | Existing anonymized/admin separation and clean exhibit helpers. | Reverify live requirements before declaring compliance. Current claims about endnotes, exact word limits, highlight limits and star-free tables are not all freshly verified journal rules. Treat star-free presentation as our style choice. Finalize author/ethics/funding/AI statements separately, without inventing approvals. |

## 8. Journal-specific constraints: verified versus drafting choices

**Verified 2 October 2026:** World Development's official scope supports a
multidisciplinary development argument. Its current ScienceDirect author
guide returned HTTP 403, so this batch does **not** certify manuscript length,
abstract/keyword/highlight limits, notes style, editable-table submission
details, fees, review times, or current AI policy. Use the existing LaTeX
scaffold as a drafting convenience, not proof of compliance. Recheck the
official guide before submission. [Author-guide endpoint](https://www.sciencedirect.com/journal/world-development/publish/guide-for-authors).

IJTJ's current General Instructions specify 5,000-10,000 words including
abstract/references/footnotes, up to four exhibits counted at 500 words each,
a 150-word abstract, Word format, 11-point double-spaced text with 1.5-inch
margins, double-anonymous review and Chicago-style footnotes. They also
require disclosure of AI assistance and permit a standard licence without
a licence charge. The separate style page's 200-word abstract conflicts
with the General Instructions; use 150 for planning. This is not a fees or
turnaround guarantee. [General Instructions](https://academic.oup.com/ijtj/pages/General_Instructions),
[conflicting style page](https://academic.oup.com/ijtj/pages/style_and_format).

For IJTJ, the current author-year/endnotes LaTeX setup is an internal drafting
base, not a submission-ready format. A Word/footnote conversion would be a
later, separately checked production task; do not create that duplicate now.

**Internal World Development drafting budget, not a verified journal limit:**
aim for roughly 8,000 words of main prose (excluding abstract, references,
tables and notes): introduction 900; context/framework 1,250; data 1,050;
strategy 1,100; results 1,700; extensions 800; robustness/limitations 700;
conclusion 500. Adjust for clarity after drafting. For IJTJ, target about
6,000 words of prose/abstract/footnotes/references plus at most 2,000 words
of exhibit allowance, leaving room within its stated total ceiling.

## 9. Drafting sequence, deliverables and checks

Write the empirical foundation before polishing an introduction that promises
results. Do not rerun estimates merely because a journal framing changes.
If a genuine analytical error or missing supported result is discovered,
stop that claim, document it and use a separate analysis correction task.

| Batch | Exact existing Overleaf targets | Deliverable and completion gate | Skill routing |
| --- | --- | --- | --- |
| 1. Empirical foundation: immediate next writing batch | `sections/03_data_measurement.tex`, `sections/04_empirical_strategy.tex`; supporting `appendix/B_data_construction_linkage.tex`, `appendix/C_rd_design_validity.tex`. | Complete source/cohort/treatment/estimand prose; explicit assumptions and design-search disclosure; outcome/diagnostic references resolved. Check every count/definition against current registries, no new causal or availability assumptions. Keep held-exhibit slots visibly unpopulated until their review clears. | `worlddev-identification`, `worlddev-robustness`, `worlddev-writing-style`. |
| 2. Institution and conceptual framework | `sections/02_context_framework.tex`, `appendix/A_program_data.tex`. | Concise verified institutional history, annotated primary-source passages and one competing-pathway framework. Separate policy intent, administrative conditions, measured implementation and normative purposes. | `worlddev-literature-positioning`, `worlddev-theory-model`, `worlddev-topic-selection`. |
| 3. Complete main evidence | `sections/05_results.tex`, `appendix/D_additional_results.tex`; separately versioned presentation code if combined displays are requested. | Original-unit results with complete family order, CIs/adjustments and distinct samples; proposed six-slot exhibits rendered and source-cell reconciled. Outcome registry and every reported number trace to versioned outputs. | `worlddev-tables-figures`, `worlddev-writing-style`, `worlddev-robustness`. |
| 4. Extensions and boundaries | `sections/06_mechanisms_heterogeneity.tex`, `sections/07_robustness.tex`, `appendix/E_mechanisms_heterogeneity.tex`. | Distinct receipt heterogeneity, assignment-only checks, intermediate outcomes and associations; no causal mediation/dose/type promotion. Threat/check/verdict table with unresolved assumptions left visible. | `worlddev-identification`, `worlddev-robustness`, `worlddev-referee-strategy`. |
| 5. Synthesis and reader promise | `sections/01_introduction.tex`, `sections/08_conclusion.tex`, `sections/00_abstract.tex`, `paper_metadata.tex`; later `highlights.tex`. | Final question/contribution/abstract match actual evidence and conceptual boundary. No first-in-literature claim without source comparison; no unmeasured justice or welfare conclusion. | `worlddev-literature-positioning`, `worlddev-writing-style`, `worlddev-workflow`. |
| 6. Production and release review | `appendix/F_replication_transparency.tex`, `main.tex`, `online_appendix.tex`, preamble/admin files; exact reviewed table/figure destinations. | Compilation, reference/word-count checks, anonymity and data-access declarations, permissions/disclosure and artifact-level approvals. Preserve restrictive data boundaries and owner release holds. Only then prepare a submission package. | `worlddev-replication-package`, `worlddev-submission`, `worlddev-tables-figures`. |

The author asked to prepare the ground for revision in this batch. The next
concrete deliverable is **Batch 1: complete the data/measurement and empirical
strategy sections**, not another outcome search or a polished introduction
built around legacy results. Later copyediting cannot repair a mistaken
population or estimand.

### Manuscript acceptance checks for every writing batch

- Each empirical claim identifies its population, time, unit, contrast and
  evidence source. Every number reconciles to the frozen/revalidated packet.
- No retrospective choice is called preregistered. No nonsignificant test is
  called proof of balance, absent manipulation, ignorable linkage or no effect.
- All complete primary families remain reachable in main/appendix; unavailable
  heterogeneity and excluded dose results are not quietly promoted.
- A causal claim carries its identifying assumptions. Documentary context is
  not relabeled as original mixed-methods fieldwork; theory is not an outcome.
- Bibliographic metadata and the actual supporting passage are both checked.
  Preserve verified BibTeX keys; do not add an unverified source to fill a gap.
- Review-safe text excludes author identifiers, private correspondence and
  restricted administrative records. AI assistance is recorded honestly.
- Inspect the narrow live-source diff, preserve UTF-8, check every input,
  label and citation, and compile the full multi-file project when possible.
  A successful compile does not clear scientific or disclosure review.

## 10. Live Overleaf and release procedure

Use the root in ignored `config/paths.local.do`; no machine-specific paths
are added to analysis programs. Preserve `Working Paper - Legacy` as-is.
The existing `World Development Manuscript` is the editable draft destination.
No second authoritative bibliography or manually rewritten generated table
is created.

For a later table/figure sync: generate and validate its appropriately sized,
non-sensitive Git copy; identify its manifest entry and actual TeX-consuming
path; verify artifact-level scientific/disclosure/owner approval; resolve the
target inside the configured Overleaf root and outside Raw/archive; preserve
the referenced filename/extension; copy; confirm SHA-256; and compile/inspect
the consuming manuscript. An approved framing is not approval of the 35 held
review exhibits. Do not use old August review copies as September results
without checksum reconciliation.

**Unchanged release status:** `BLOCKED` despite passing technical checks.
All current review exhibit rows remain `owner_approved=0`,
`release_eligible=0`, `release_action=hold_no_sync`. Narrative planning and
review compilation do not constitute author approval, disclosure clearance
or permission to publish restricted data.

## 11. Validation receipt for this planning batch

- Read current project, literature, live-Overleaf and publication safeguards;
  inspected the existing section/appendix scaffold and relevant legacy claims.
- Queried both project literature integrations; documented NotebookLM failure
  and verified the five framing anchors in underlying source material.
- Rechecked official journal sources and distinguished verified constraints
  from inaccessible or conflicting guidance.
- Ran the existing `check_identification_publication_review.py --review-pack`
  with the configured Dropbox root: 99 reviewed items/94 original candidates,
  ten documentary records, 35 review exhibits and 287 source rows passed;
  existing holds and hashes were intact.
- The proposed abstracts contain 200 words (World Development) and 129 words
  (IJTJ), within the stated drafting limits. All 35 referenced exhibit IDs
  resolve to existing held files; five existing bibliography keys resolve;
  local document links and requested framing components were checked.
- SHA-256 comparison confirmed all 27 World Development scaffold source files
  and five frozen inputs unchanged, including the legacy manuscript. UTF-8
  inspection found no replacement characters; `git diff --check` passed.
  No Stata execution was needed for this documentation-only batch.

This plan is ready to guide drafting. It is not a claim that all present
results are identifiable population effects or that either journal will
accept the paper.
