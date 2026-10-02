# Institutional context and conceptual framework: drafting audit

Date: 2 October 2026. Status: **this writing batch validated; whole-paper and exhibit release gates unchanged**.

## Authorized scope and delivered sources

The owner approved the next phase of the manuscript revision: institutional context, the conceptual framework, and Online Appendix A. Three existing live inputs changed, resolved under the Overleaf root in ignored `config/paths.local.do`:

- `World Development Manuscript/sections/02_context_framework.tex`: substantive context and framework draft (1,170 whitespace-delimited source words).
- `World Development Manuscript/appendix/A_program_data.tex`: source documentation, official cutoffs, implementation and measurement boundaries, and a conceptual evidence map (1,412 source words).
- `Bibliography.bib`: nine official-source entries appended. The entire previous byte prefix, including existing academic and methods entries, is retained.

These word counts include TeX commands and table material; they are not certified journal-limit counts. Two handwritten documentary/conceptual tables were added to Appendix A. Neither is a manually edited Stata output or a new quantitative result. No existing generated table or figure was synchronized.

Git records this receipt and the project-context pointer. Live manuscript sources remain in the configured Overleaf project. The preceding empirical-foundation receipt is already tracked in repository HEAD `7b00866` and is not part of this new proposed commit. This task made no Git commit, staging operation or push.

## Institutional source-to-claim record

Each citation was checked against the underlying text, not accepted from a synthesis answer. Official reports are evidence of rules and reported administrative practice; they do not establish universal implementation or community-specific compliance.

| Citation key | Verified locator | Permitted use and important boundary |
|---|---|---|
| `comision_de_la_verdad_y_reconciliacion_cvr_informe_2003` | Official final-report general conclusions 5–10 | Disproportionate rural/campesino and Indigenous victimization and unequal state protection. No newly calculated conflict statistic. |
| `peru_ley_28592_2005` | Law 28592, arts. 1–2, 7–9; first complementary and transitory provision | PIR scope, collective beneficiaries, CMAN coordination, RUV and Council responsibility. Promulgation 28 July and publication 29 July 2005; congressional approval on 20 July is a different date. |
| `peru_reglamento_pir_2006` | DS 015-2006-JUS, arts. 25–29, 58, 71 | Objectives/modalities, gradual decentralized implementation, consultation and Book II. Consulted regulation is consolidated: Article 8(d) and the added Article 69 registration language are marked as 2008 amendments, not silently attributed to original 2006 wording. |
| `defensoria_informe_139_2008` | PDF p. 50 = printed p. 52 | June 2007 launch, 440 communities selected from Censo por la Paz, planned 2008 expansion drawing partly on RUV Book II, historical financing ceiling. Planned/selected is not verified completion. |
| `consejo_reparaciones_indice_2007` | PDF pp. 2–6 = printed pp. 1–5 | Four composite dimensions, alternative standardizations/geometric aggregation, five levels, official boundaries. September 2007 methodology is not proof of the score or annual registry denominator visible before every award. |
| `cman_informe_2012` | PDF/printed pp. 7–9, 11 | Guidelines approved 30 May 2012: registration, **joint A or B priority**, executor accountability; inherited files, VRAEM, project selection, central cap and local counterparts. Not an A-before-B national queue or equal total financing. |
| `cman_informe_2013` | PDF/printed pp. 49–50, 53 | Corroborates joint priority/administrative criteria and territorial priority. Not universal compliance. |
| `cman_informe_2016` | PDF/printed pp. 39–41 | Distinct assemblies/files/transfers/starts/deliveries/liquidation; territorial priorities and reported apologies. Not universal participation, observed recognition or an independently verified exposure date. |
| `defensoria_informe_162_2013` | PDF/printed pp. 23, 37–38 | Reparations versus ordinary social provision, prioritization irregularities, execution/sustainability concerns. Not proof that partisanship caused every deviation. |
| `cman_comunidades_atendidas_2023` | 2023 list, PDF header and p. 283 | Project descriptions, geographic names, year, **legal instrument**, financing/co-financing and executor. `Dispositivo legal` is broader than ministerial resolution; record 4432 contains a budget-law reference. |

Public source anchors were checked at the [official CVR conclusions](https://www.cverdad.org.pe/ingles/ifinal/conclusiones.php), [Law 28592 listing](https://www.gob.pe/institucion/congreso-de-la-republica/normas-legales/1496834-28592), [legislative history](https://www2.congreso.gob.pe/Sicr/TraDocEstProc/TraDoc_expdig_2001.nsf/4B49849B79AF6D90052583C30007E409/CD98E2F55B0A7E3405257473007C98BC), [regulation listing](https://www.gob.pe/institucion/minjus/normas-legales/1494373-015-2006-jus), [CMAN 2012 report](https://www.gob.pe/institucion/minjus/informes-publicaciones/2730157-informe-anual-2012-de-la-comision-multisectorial-de-alto-nivel) and [2023 register listing](https://www.gob.pe/institucion/minjus/informes-publicaciones/1604763-listado-de-comunidades-atendidas-28-12-23). Some direct government PDF requests returned 403; passages were verified in the existing immutable source PDFs, not inferred from that access failure. The index has no verified public URL in the project source registry.

Eight relevant report/methodology files match the versioned documentary evidence registry at `metadata/rd-design/identification-evidence-2026-09-30.csv`. The existing law, consolidated regulation and raw CMAN register additionally had these SHA-256 hashes at review:

- `2 data/0 Support documents/ley28592.pdf (2).pdf`: `44534E3CE5279280C243DAA351AD9D83D83C6E0F71EA5D974220388B252CA4AC`.
- `2 data/0 Support documents/DS Nº 015-2006-JUS .pdf.pdf`: `67C5BF28B337EB83B321B8848950EE191B12C2447A45F44AE471FB8B9EAFE268`.
- `2 data/1 Raw/12 CMAN/1604763-listado-de-comunidades-atendidas-28-12-23.pdf`: `18D0F926A337B4E0AA6193798DD0FF8C7CF93568C64F78A120FA1BF23BB10A86`.

No raw PDF or third-party full text was copied into Git or Overleaf. The CMAN 2012 report's erroneous legal-year text was not inherited; nor was the 2016 report's inconsistent aggregate-financing total. Later 2023 guidance was not backdated to an earlier assignment regime.

## Academic anchors and literature integrations

The shared Zotero library **IE Collective Reparations Peru** was resolved to library ID 5 and consulted read-only. The explicit project NotebookLM URL was also queried. Health still reported unauthenticated, but the primary agent's bounded public-notebook query returned success (session `10f8da6d`). Separate reviewer queries failed at browser launch. This is fresh bounded consultation, not a claim of exhaustive ingestion or uniformly functioning authentication.

NotebookLM was used to identify literature leads. All cited propositions were checked in the underlying sources. Overstated or weakly located synthesis claims were not inherited. Existing BibTeX keys were retained; no library mutation, import, note write, authentication repair or journal-skill installation occurred.

| Existing citation key | Underlying passage checked | Evidentiary role |
|---|---|---|
| `united_nations_basic_2005` | Resolution A/RES/60/147, PDF pp. 7–8, paras. 15, 18, 22 | Normative redress and forms of reparation. Adopted 16 December 2005; resolution copy issued in 2006. Not an evaluation of PRC compliance. |
| `laplante_truth_2007` | PDF p. 2 / printed p. 229; PDF p. 18 / p. 245; PDF p. 22 / p. 249 | Peru-based qualitative/interpretive account of truth, concrete acknowledgment, redress and unequal citizenship. Not a causal impact estimate. DOI `10.1353/hrq.2007.0009`. |
| `gready_transitional_2014` | PDF pp. 2, 8–9 / printed pp. 340, 346–347 | Conceptual argument about local agency, socioeconomic conditions and reparative meaning. Not a validated material index or identified channel. DOI `10.1093/ijtj/iju013`. |
| `adhikari_should_2018` | PDF p. 4 / printed p. 2; PDF p. 17 / p. 15 | Review of opposing cash-transfer/mobility pathways and program-design dependence. Shared municipal projects are not household cash. DOI `10.1596/1813-9450-8525`. |
| `guarin_reparations_2023` | PDF pp. 4–5 / printed pp. 1–2 | Verified 2023 Colombian individual-payment working paper used to distinguish delivery channels. No imported effect size or claim of a later journal publication. DOI `10.32468/be.1236`. |

The World Development theory, literature-positioning and writing-style skills led to **one plain-language conceptual framework**, no decorative formal model, and a bridge between development/mobility evidence and reparative meaning. They did not determine an econometric specification or relax an identification limitation.

## Framework-to-evidence contract

- **Place anchoring:** better origin opportunities could encourage staying. A joint pattern of material improvement and less movement is consistent with that account, but composition and constrained exit are alternatives. The 2013 indicators describe observed origins; 2017 material outcomes follow a restricted linked source cohort and can describe destination conditions. They do not measure complete origin-place conditions.
- **Mobility facilitation:** usable household resources or portable opportunities could ease moving constraints. More movement with material improvement is consistent with that account, not proof of liquidity, information or employment mediation. Shared projects are not automatically liquid household grants; destination welfare is not identified by movement.
- **Recognition:** acknowledgment, dignity and trust are substantively central but directly unmeasured. A reported apology does not establish subjective recognition or universal exposure. Material services, staying or moving are not proxies for normative success.
- **Moderators:** existing baseline population, capital status and individual gender comparisons are motivated without introducing new samples, signed hypotheses or tests. Assignment-only heterogeneity is not promoted to heterogeneous effects of receipt; the empirical-strategy safeguards remain binding.
- **Endogenous/post-treatment variables:** project types, employment and internet access supply descriptive evidence relevant to possible channels, not ordinary pre-treatment controls or identified mediation. No financing-dose causal claim is added.
- **Retrospective status:** the framework organizes the revised interpretation; it is not represented as prospectively registered. Imprecision and selective observation remain alternatives rather than evidence selecting a favored pathway.

The appendix's movement note uses the locked definition: linked source-cohort people with **known 2017 age of at least 14** and valid canonical origin/destination codes. It is not a baseline-age rule or an all-resident population.

## Independent review and corrected findings

Two read-only reviewers examined the two drafts: one checked official sources/administration and one checked literature warrants, framework logic and measurement interpretation. Their findings were corrected before the final build:

1. Broadened `ministerial resolution` to the source's `legal instrument` field.
2. Added the law's first complementary/transitory provision for Council responsibility, regulation Article 71 for Book II, and Article 58 for consultation.
3. Separated 2013 observed-origin indicators from 2017 linked-cohort/destination circumstances; avoided labeling the latter full origin-community conditions.
4. Specified 2017 age, narrowed the UN claim to redress, distinguished registry inclusion from experienced recognition, and defined Book II and VRAEM.
5. Replaced stronger mechanism language with descriptive channel evidence; retained the retrospective status and all causal limitations.

Both final bounded reviews reported **no residual substantive findings**. That judgment does not certify identification or publication release. Table layout was separately corrected to avoid stretched justified columns and to keep the framework table inside Appendix A; all pages were then rendered again.

## Fresh validation and preservation

Ignored `build/manuscript-context-2026-10-02/` contains the before-source copies and 142-path SHA-256 manifest, reused/minimal read-only checking helpers, compile mirror, logs, rendered pages and compiled previews. Compilation uses the existing multi-file TeX runtime; no new toolchain or package was installed. Private `author_details.tex` was excluded from the mirror.

Validation results:

- Exactly **three** authorized live inputs changed; **139** protected files, including the legacy paper, previous manuscript sources, reviewed artifacts and registry dependencies, are unchanged.
- Original bibliography byte prefix retained; nine new keys, no duplicates, all **15** citation keys used in the new drafts resolve.
- Fresh main and online-appendix builds returned exit code 0: **20** and **24** pages. No undefined citations/references, TeX warnings, overfull or underfull boxes in the final logs.
- Every page was rendered and inspected; character bounds passed, and both appendix tables were inspected at readable scale. These are full-scaffold previews, including still-undrafted sections, not completed-paper PDFs.
- Existing publication checker passed: **99** reviewed exhibits, **94** original candidates, **10** documentary records including **8** intake sources, and **35** review-pack exhibits with all **287** recorded source rows retained. Negative controls passed.
- All 35 exhibit holds remain `owner_approved=0`, `release_eligible=0`, `hold_no_sync`. The canonical publication registry, estimates, outcomes, sample/geography, B/C support, bandwidths, treatment timing, clustering and multiplicity contracts were not changed.
- CMAN recorded year remains the sole allocation-and-delivery-year assumption, with `treat_12` and `treat_16` unchanged. No search for unavailable historical risk sets or completion dates was reopened.
- No Stata commands or re-estimation were needed. No data or log was written to Git or Overleaf; no raw/archive source was modified; no generated exhibit was manually edited, promoted or synchronized.

The main draft still has placeholders for the introduction, results, mechanisms/heterogeneity, robustness, conclusion and declarations. Appendix D/E/F also remain to be drafted. Scientific, disclosure and owner exhibit-release gates remain **BLOCKED**, distinct from this successful writing/build audit.

## Next writing batch

Draft `sections/05_results.tex` and Online Appendix D from the frozen module-04 estimates and source-cell ledger. Keep all 48 registered primary tests, the six outcome/multiplicity families, interval precision and selection boundaries visible; do not cherry-pick signs or turn nonrejection into zero effects. Place material outcomes and observed movement within the framework without claiming an identified mechanism. Exhibit insertion requires its own exact-path review and release decision; it is not authorized automatically by this prose-writing batch. Mechanisms/heterogeneity and their appendix follow, before the introduction and abstract.
