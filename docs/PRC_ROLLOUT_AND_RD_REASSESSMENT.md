# Collective Reparations rollout and RD design reassessment

## Status and purpose

This memo separates three questions that had become conflated in the earlier
research workflow:

1. whether the official victimization index was intended to order program
   attention;
2. whether a stable threshold rule actually governed project receipt in every
   year and place; and
3. whether the available RUV and CMAN variables measure the information and
   event dates that officials used when making each decision.

The answer to the first question is yes. The answer to the second is no: the
documented operational rule, registry, implementing institution, geographic
priorities, budget, and inherited project queue changed over time. The third
question remains unresolved and is now a binding data requirement.

The research team selected the exact legacy geography as the main analysis
geography on 29 July 2026, and `01_data_preparation.do` now creates
`sample_main_rd` for its 1,162 RUV communities. This memo still does not, by
itself, approve a treatment date, rounded-score rule, administrative risk set,
or outcome specification.

## Main conclusion

The weak national discontinuities are surprising if the program is modeled as
one deterministic queue that treated every A community, then every B
community, then every C community, and so forth. That model is not an accurate
description of the documentary record.

The evidence instead describes a multi-stage administrative priority system:

- the victimization level ordered attention, but did not itself generate an
  automatic project;
- the first 2007 cohort was selected from the preliminary *Censo por la Paz*,
  before a complete RUV existed;
- the 2008 cohort used the RUV only in part;
- A/B status, RUV inscription, and executing-body accountability were adopted
  as **new** operational criteria in 2012;
- 150 projects of diverse victimization levels inherited from prior years were
  gradually honored after the 2012 rule change;
- VRAEM and later other territorial priorities created additional assignment
  channels;
- project selection, technical formulation, investment-system viability,
  municipal execution, cofinancing, and annual budget availability all stood
  between priority and implementation; and
- official oversight found serious irregularities in 2011 prioritization,
  including communities outside the very-high/high categories and some not
  registered in the RUV.

Apparent “noncompliance” therefore mixes at least four distinct phenomena:
lawful concurrent priority channels, inherited commitments, implementation
capacity and timing, and genuine administrative deviation. These must be
distinguished before using terms such as infiltration or manipulation.

## Documents reviewed

### Project support documents

The following Dropbox files were read as source material. They remain
unmodified:

- `2 data/0 Support documents/ley28592.pdf (2).pdf`
- `2 data/0 Support documents/DS Nº 015-2006-JUS .pdf.pdf`
- `2 data/0 Support documents/Indice_Nivel_Afectacion.pdf`
- `2 data/0 Support documents/Lineamientos Generales del PRC F 05.23 (2).pdf`
- `2 data/0 Support documents/1604771-triptico-programa-reparaciones-colectivas (2).pdf`
- `2 data/0 Support documents/PRC_Proyectos_Pub_06_2018.pdf`

The decisive passages are:

- the index methodology, pages 2 and 6: the index classifies communities into
  five levels and proposes an ordered intervention by level;
- the 2023 PRC guidelines, pages 11–12: CMAN decides prioritization subject to
  the PRC budget and Libro Segundo; the general criteria are RUV inscription
  and very-high/high affectation, with other communities considered after
  completing those groups; executing-body accountability and VRAEM are
  additional considerations;
- the 2023 brochure: CMAN creates an annual list, takes the RUV affectation
  level into account, and then requires community project choice, a government
  technical file, CMAN review, and implementation; and
- the 2006 regulation: rural poverty, high affectation, territorial
  decentralization, multiple implementing actors, and available resources all
  enter the broader implementation framework.

### Official and oversight sources

- [CMAN institutional functions](https://www.gob.pe/cman)
- [Current Ministry description of the PRC process](https://www.gob.pe/44153-reparaciones-a-victimas-de-la-violencia-ocurrida-en-el-periodo-de-1980-a-2000)
- [2023 General PRC Guidelines](https://cdn.www.gob.pe/uploads/document/file/1616971/Lineamientos%20Generales%20del%20PRC%20F%2005.23.pdf?v=1684941541)
- [CMAN 2012 annual report](https://www.gob.pe/institucion/minjus/informes-publicaciones/2730157-informe-anual-2012-de-la-comision-multisectorial-de-alto-nivel)
- [Defensoría del Pueblo, Informe 139 (2008)](https://www.defensoria.gob.pe/wp-content/uploads/2018/05/informe_139.pdf)
- [Defensoría del Pueblo, Informe 162 (2013)](https://www.defensoria.gob.pe/wp-content/uploads/2018/05/INFORME-DEFENSORIAL-162.pdf)
- [CMAN 2023 annual report](https://cdn.www.gob.pe/uploads/document/file/6134503/5419322-informe-anual-cman-2023-f.pdf?v=1712244749)
- [CMAN annual-report collection](https://www.gob.pe/institucion/minjus/colecciones/2472-informes-anuales-cman)
- [Congressional committee session on the PRC (25 March 2008)](https://www2.congreso.gob.pe/Sicr/DiarioDebates/pubcomis.nsf/bb31927b8109ed9705256f1c0063e796/05256eee006fc0d8052574190066bb59?Click=&OpenDocument=)
- [APRODEH/ICTJ, second national monitoring report (2009)](https://www.ictj.org/sites/default/files/ICTJ-Aprodeh-Peru-Collective-Reparations-2009-Spanish.pdf)
- [APRODEH/ICTJ, 2007–2011 implementation review](https://www.ictj.org/es/%C3%BAltimas-noticias/per%C3%BA-%C2%BFcu%C3%A1nto-se-ha-reparado-en-las-comunidades)
- [Vera-Adrianzen, *Reclaiming Justice from Below* (2022)](https://digitalrepository.unm.edu/pols_etds/96/)
- [MINJUSDH announcement of the 2019 financing expansion](https://www.gob.pe/institucion/minjus/noticias/70089-minjusdh-atendera-con-reparaciones-colectivas-a-319-comunidades-afectadas-por-el-periodo-de-violencia-1980-2000)
- [CMAN 2025 annual report](https://cdn.www.gob.pe/uploads/document/file/9906263/8083940-informe-anual-cman-2025.pdf)

The 2009 APRODEH/ICTJ monitoring report is especially relevant to the project's
historical APRA hypothesis. It cross-referenced recipient districts with the
political organizations of their mayors. Although PAP governed the largest
national share of recipient districts, the report attributed much of that
pattern to the party's presence in highly affected regions and concluded that
the early prioritization it reviewed was not subject to party-political
manipulation. This is prior evidence against a simple APRA-favoritism account,
not proof that political alignment was irrelevant in every later year or
administrative stage.

The later implementation literature reinforces the distinction between formal
priority and realized treatment. APRODEH/ICTJ describes slow, uneven, and
development-project-centered implementation through 2011. Vera-Adrianzen
documents socio-political drivers of temporal and spatial variation, including
victims' efforts to negotiate demands with national and subnational
governments. These sources support modeling municipal capacity, local
organization, and state-community negotiation rather than treating every
departure from score order as partisan infiltration.

The 2008 congressional record helps explain why the project originally
expected a much clearer ordering. CMAN publicly stated a goal of repairing by
2011 all roughly 2,000 communities deemed highly affected in the *Censo por la
Paz*. That was a genuine priority commitment. It was not, however, a promise
to move mechanically through the later RUV A–E thresholds, and it used a
different early information source.

The compact, versioned source ledger is
`metadata/rd-design/rollout-source-registry.csv`.

## Implementation timeline and assignment regimes

| Period | Documentary rule and administrative setting | RD implication |
|---|---|---|
| Before June 2007 | PIR law and regulation established collective reparations and broad priority principles, including high affectation, rural poverty, territorial implementation, coordination, and available resources. | The index was not yet a demonstrated automatic assignment mechanism. |
| 2007 | The first 440 communities were selected using the *Censo por la Paz*. Funds passed through PCM to municipalities. | A later RUV score/category may not be the ex ante assignment variable for this cohort. |
| 2008 | A further 463 communities were selected only partly using Libro Segundo. CMAN publicly aimed to repair by 2011 all roughly 2,000 communities deemed highly affected in the *Censo por la Paz*. By October 2008, 131 of the first 440 projects had been delivered. | Strong ordinal targeting was intended, but the early instrument and category universe were not the later RUV A–E score. Selection, funding, and delivery were distinct events with heterogeneous lags. |
| 2009–2011 | The program expanded while the RUV was still evolving. Defensoría reports implementation and monitoring problems. An institutional-control report found serious irregularities in 2011 prioritization. | Pooling these years under the later A/B rule is not justified without annual decision records. |
| 2012 | CMAN moved to MINJUS. The annual report calls RUV registration, A/B affectation, and executor accountability **three new criteria**. It also records 150 inherited files of diverse affectation and a separate VRAEM priority. | This is a policy-regime break, not merely another cumulative treatment year. |
| 2013 onward | The A/B rule coexisted with annual budgets, municipal technical files, project viability, accountability conditions, territorial priorities, and inherited obligations. | The written B–C priority boundary may generate a fuzzy first stage only in a correctly defined post-rule risk set. |
| 2019 | An exceptional appropriation financed 586 communities and organizations with S/58.6 million in national resources and S/36.648 million in municipal counterpart funding—the largest annual volume in the program's first 12 years. | The sharp 2019 expansion is a financing and implementation-capacity shock, not evidence of a new victimization-score cutoff. |
| 2023 | MINJUSDH itself received no PRC implementation budget; the national budget law assigned S/19.5 million directly to local governments for 195 projects. | The financing route changed again. A pooled 2007–2023 receipt variable does not represent one stable administrative mechanism. |
| 2025 | The annual report states that PRC project financing had lacked resources for three years. Despite 250 viable technical files, CMAN could hold only upstream activities such as 147 community assemblies and validation of 132 files. | Priority, project choice, technical viability, financing, and receipt remain empirically separate events. |

## What the written rule does and does not imply

### Supported interpretation

The victimization score was intended to order intervention. From the 2012
operational change onward, communities classified A (very high) or B (high)
formed a joint priority pool. Other communities were to follow after those
groups had been repaired, subject to the other stated conditions.

### Unsupported interpretation

The reviewed operational documents do not establish five consecutive,
deterministic threshold regimes in which:

1. every A community had to be treated before the first B community;
2. every B community had to be treated before the first C community;
3. every C community had to be treated before the first D community; and
4. every D community had to be treated before the first E community.

In particular:

- A and B are grouped together in the post-2012 operational rule, so A–B is
  **not** an explicit eligibility or priority boundary in that regime;
- B–C is the documented boundary between the joint A/B priority pool and the
  remaining categories;
- the documents reviewed do not state separate C-before-D and D-before-E
  operational stages; and
- even at B–C, priority was conditional on budget, registration, geographic
  exceptions, executor readiness, and project processing.

The four cutoffs remain valuable diagnostics. Only B–C currently has a direct
post-2012 operational interpretation as a threshold in the written priority
rule.

## Why the national first stage can be weak

### 1. The score may be measured at the wrong decision date

The available RUV workbook was acquired in 2018. The registry was incomplete
and changing during the early program years. A community's 2018 category may
not equal the registry status, score, or category visible to officials when a
2007–2012 decision was made.

This is not ordinary measurement error. If registration and scoring occurred
after early treatment, the observed running variable can be post-decision for
some communities and cannot support the intended historical RD without
versioned registry data.

### 2. The program had more than one policy regime

The A/B operational rule was introduced in 2012. Pre-2012 projects, post-2012
new priorities, inherited commitments, and later budget arrangements should
not be pooled as though they followed the same assignment mapping.

### 3. Priority did not equal treatment

A project required an annual CMAN decision, a community assembly, an
executing government, a technical file, CMAN validation, budget, and often
cofinancing. Administrative capacity and processing time can therefore
separate the intended priority order from observed financing or completion.
Defensoría documented that only 131 of the 440 communities selected in 2007
had a delivered project by October 2008, while the 463 communities selected
for 2008 were still in formulation and approval. Selection, transfer,
execution, and delivery must therefore be represented as different events.

### 4. Geographic priorities overrode a national score-only queue

VRAEM was explicitly prioritized in 2012. Later reports document substantial
VRAEM and Huallaga attention. These rules may be legitimate, but they produce
different treatment probabilities for equally scored communities.

### 5. Earlier obligations were grandfathered

CMAN's 2012 report states that 150 technical files from communities of diverse
affectation had been prioritized in prior years and were gradually added to
annual beneficiary lists. Their treatment under the new rule is not evidence
that officials applied the new rule incorrectly.

### 6. Budgets and institutions changed

Annual allocations varied, the responsible national institution changed in
2012, and the 2023 financing route bypassed a MINJUSDH PRC implementation
budget. Defensoría reported that the PRC budget declined from 2010 onward in a
way that did not assure an ordered, equitable, and continuous allocation of
resources. These changes alter both treatment capacity and selection
procedures.

The scale of these shocks is visible in official records. In 2019, an
exceptional appropriation produced the largest annual PRC volume in the
program's first 12 years: 586 communities or organizations, S/58.6 million in
national financing, and S/36.648 million in municipal counterpart funding. In
2025, by contrast, the annual report stated that project financing had lacked
resources for three years even though 250 technical files were viable. CMAN
still held 147 assemblies and validated 132 files. These facts make it unsafe
to treat the roster year as a single, stable score-driven assignment event.

### 7. Some deviations were genuine

Defensoría reports that the 2011 institutional-control review found serious
priority irregularities: many selected communities were not A/B and some were
not in the RUV. This is direct evidence that administrative deviation occurred,
but it should not be generalized to every lower-category project without
identifying the applicable rule and year.

The administrative records also do not cleanly measure final delivery.
Defensoría reported that more than 700 of 1,592 projects financed during
2007–2010 lacked execution and liquidation information. A financing-list year
can therefore differ materially from project initiation, completion, or
community receipt.

## Descriptive evidence from the linked RUV–CMAN data

The new full-universe descriptive output uses all 5,712 RUV communities. It
reports both cumulative coverage within each category and the composition of
each newly linked CMAN cohort.

Selected cumulative coverage rates are:

| Category | RUV N | 2007 | 2010 | 2012 | 2016 | 2020 | 2023 |
|---|---:|---:|---:|---:|---:|---:|---:|
| A | 1,284 | 11.9% | 45.2% | 54.8% | 78.4% | 89.1% | 91.3% |
| B | 1,269 | 5.1% | 29.3% | 39.0% | 48.6% | 80.9% | 86.0% |
| C | 1,310 | 2.8% | 21.0% | 26.8% | 27.6% | 69.0% | 84.0% |
| D | 1,127 | 0.4% | 10.9% | 12.9% | 13.7% | 24.9% | 63.5% |
| E | 722 | 0.0% | 1.4% | 2.6% | 2.9% | 2.9% | 19.5% |

This confirms meaningful ordinal targeting in levels, even though it does not
show a clean local jump at every numerical cutoff. Category A dominated the
earliest cohorts; B followed; C, D, and E expanded later. The timing also shows
large post-2018 catch-up. The descriptive pattern is consistent with priority,
capacity constraints, and staggered expansion—not with officials ignoring
victimization altogether.

The output is:

- `output/figures/descriptive/fig_desc_20_treatment_by_category_over_time.png`
- `output/tables/descriptive/rd_rollout_category_year.csv`
- `output/tables/descriptive/tab_desc_09_treatment_by_category_over_time.tex`

The CMAN year is currently interpreted as the first project year recorded in
the roster. It has not yet been verified as selection, authorization,
financial transfer, implementation start, completion, or delivery.

## Re-conceptualizing the RD design

### Required assignment model

A valid first-stage audit must state:

- the administrative regime;
- the version and date of the score/category used by officials;
- the annual population at risk;
- the exact threshold rule;
- any simultaneous geographic or administrative priority rules;
- the treatment event; and
- the time between that event and outcome measurement.

Without these elements, an estimated discontinuity in cumulative receipt is a
descriptive search over historical data, not validation of a known assignment
mechanism.

### Policy-valid cutoff

B–C remains the leading cutoff for a post-2012 design because it separates the
joint A/B priority pool from the remaining categories. It is no longer treated
as an arbitrary empirical choice.

A–B, C–D, and D–E are retained in the code because:

- they can detect other discontinuities in implementation;
- they reveal whether empirical jumps arise at undocumented thresholds; and
- they help diagnose score/category problems.

They cannot become primary causal cutoffs solely because one produces the
largest first stage in a searched geography or year.

### Candidate post-2012 risk set

A defensible post-2012 B–C design would ideally start from communities that:

1. were registered and had a recorded category before the relevant annual
   priority decision;
2. had not already been selected, financed, initiated, or completed;
3. were not part of the 150 inherited commitments;
4. were subject to the same VRAEM/Huallaga or other territorial rule;
5. faced comparable executing-body accountability and technical-processing
   conditions; and
6. were observed before the outcome reference date.

The required variables are not all present in the current linked dataset.
Until they are obtained, this design is a research target rather than an
approved specification.

### Adjacent categories versus full score support

In an ordinary single-cutoff RD, the full running-variable support may be
loaded because `rdrobust` estimates locally and selects a bandwidth. There is
no general RD requirement to keep only the two labeled categories adjacent to
the cutoff.

This application has multiple policy thresholds on one score. An unrestricted
bandwidth could cross another threshold and mix assignment regimes. The
current adjacent-category restriction is therefore a conservative way to cap
the admissible support between neighboring thresholds. It is not a substitute
for checking the selected bandwidth.

The expanded audit now reports both:

- adjacent-category support for the complete geographic search; and
- full score support for every named candidate, cutoff, and treatment year.

If a full-support selected bandwidth stays inside the neighboring thresholds,
the two approaches should be substantively similar. Material differences are
a support-sensitivity warning.

### Treatment timing and the proposed exclusion of later recipients

The treatment year must follow the estimand, not be selected because it gives
the strongest first stage.

For a 2013 outcome:

- `treat_12` is appropriate for an “any recorded project by the end of 2012”
  estimand if every included project precedes outcome measurement;
- `treat_10` is appropriate for an “early receipt by 2010” estimand, but
  communities first treated in 2011–2012 should ordinarily remain in the
  not-treated-by-2010 comparison group; and
- dropping the 2011–2012 recipients based on their realized future treatment
  conditions on a post-assignment variable, changes the target population, and
  can induce selection.

The proposed exclusion can be reported only as a clearly labeled
per-protocol/principal-stratum-style sensitivity with strong assumptions. It
is not the default fuzzy RD. A safer primary distinction is:

- priority-assignment ITT at the policy cutoff; and
- a secondary early-versus-delayed receipt estimand with one fixed early
  treatment definition across outcome waves.

Exact SISFOH and Census fieldwork dates, and exact CMAN event dates, must be
verified before final coding.

### Multiple cutoffs

The data contain one score and four category thresholds, but the operational
rule does not establish four simultaneous, equivalent local experiments.
Mechanical pooling with multiple-cutoff commands would therefore be premature.
The methodological distinction follows the
[Cattaneo--Titiunik--Vazquez-Bare multiple-cutoff framework](https://rdpackages.github.io/references/Cattaneo-Titiunik-VazquezBare_2020_Stata.pdf):
cutoff-specific effects and a normalized pooled effect are distinct reported
estimands, and the latter needs a substantive interpretation rather than mere
software availability.

Any pooled estimand would need to show that:

- each cutoff represented a real assignment rule in the same regime;
- treatment and potential-outcome scales are comparable across cutoffs;
- cutoff-specific effects can be transported or pooled; and
- no bandwidth crosses another policy boundary.

Current documents support cutoff-specific diagnostics and a possible
post-2012 B–C experiment, not automatic pooled multiple-cutoff estimation.

## Expanded computational audit

`code/stata/pipeline/03_validate_rd_design.do` now estimates:

- every official cutoff;
- every cumulative treatment year from 2007 through 2023;
- the 11 named institutional and historical candidates;
- every department, leave-one-department-out sample, two-department pair, and
  normalized province cell in the broad atlas;
- all 127 nonempty subsets of the seven-department conflict/VRAEM envelope;
- all 1,023 nonempty subsets of the ten-province VRAEM envelope; and
- full-support sensitivity for all named candidates, cutoffs, and years.

The complete 96,524-cell audit is stored as a Stata QA dataset in Dropbox
Working. Git stores the named grids, the 2012/2016/2023 slices of the large
atlases, and compact cutoff-year summaries/frontiers. This preserves
auditability without turning Git into data storage.

The completed audit reinforces the institutional diagnosis:

- 81,499 cells estimate successfully; 13,510 are support-limited and 1,515
  attempted numerical failures remain visible;
- under the common sample/support floor and a robust Wald diagnostic of at
  least 20, all 79 strong positive cells are B--C and occur only in
  2012--2018;
- no strong positive cell appears in 2010 or 2023, and none appears at A--B,
  C--D, or D--E in any year;
- only the post-search Apurímac--Huancavelica--San Martín combination is
  strong in both 2012 and 2016, but it has a severe B--C altitude
  discontinuity and cannot define the sample;
- the ten-province VRAEM power set is not strong in 2012, 2016, or 2023; and
- the exact legacy B--C estimate attenuates sharply when the full running-score
  support determines a wider, still locally admissible bandwidth.

The last result is a substantive warning. Among successful named
candidate-cutoff-year comparisons, 38.3% differ by at least 0.10 between
adjacent-category and full-score support; the share is 27.8% at B--C.
Favorable estimates are therefore not invariant to the bandwidth-selection
sample even before outcome analysis.

The search remains diagnostic. It does not adjust ordinary p-values for
specification search, does not make a geography theoretically defensible, and
does not create a sample flag.

## Mechanisms to test after data integration

The following hypotheses are recorded for later analysis. None is currently a
causal finding.

### Legitimate policy and administrative channels

- VRAEM, Huallaga, or other formal territorial priorities;
- RUV registration and accreditation date;
- inherited pre-2012 technical files and signed agreements;
- annual national budget and ministerial transfer resolutions;
- executing municipality's prior project-accountability rate;
- technical-file preparation and Invierte.pe viability;
- municipal administrative and fiscal capacity;
- cofinancing capacity and project cost;
- community assembly timing and selected project type;
- CMAN decentralized-office coverage; and
- project feasibility, geography, and accessibility.

### Political and governance hypotheses

- mayoral or regional alignment with the governing national party, including
  the historical APRA variable;
- election-cycle timing and political visibility;
- discretion in annual priority lists;
- the 2011 irregularities documented by the institutional-control report;
- corruption, stalled execution, and substitution of ordinary participatory-
  budget projects for reparative projects; and
- differential monitoring and follow-through.

Political alignment must not be described as manipulation without a dated
assignment model and evidence that it predicts deviations from the applicable
rule rather than lawful geographic or administrative priority. The 2009
APRODEH/ICTJ report already performed a descriptive party-alignment check for
the early rollout and did not find evidence of party-political manipulation.
The project should replicate and extend that analysis with community-level
timing and later administrations, while treating APRA alignment as a
pre-specified hypothesis rather than an assumed explanation.

### Spatial and state-capacity channels

- `prop_a13` or an updated measure of the share of high-priority communities
  in the district;
- shared municipal project pipelines and economies of scale;
- proximity to treated communities or district/provincial capitals;
- road access, altitude, remoteness, and security conditions;
- expansion of Juntos and other social-protection delivery infrastructure;
- education, health, and other state-service presence; and
- district fiscal transfers and public-investment capacity.

These factors may explain both implementation and outcomes. Their temporal
ordering must therefore be made explicit before using them as controls,
mechanisms, or instruments.

## Data requests and reconstruction priorities

Before the RD design can be approved, seek or reconstruct:

1. annual or dated snapshots of RUV Libro Segundo, including registration,
   accreditation, score, category, and category-change history;
2. annual CMAN priority lists and the corresponding resolutions;
3. separate dates for community prioritization, assembly, technical-file
   submission, viability, approval, transfer, initiation, completion, and
   delivery;
4. flags for the 150 inherited files and other pre-rule commitments;
5. annual VRAEM, Huallaga, and other geographic-priority definitions;
6. annual executor accountability and project-liquidation status;
7. executing-government identity, cofinancing, project cost, project type, and
   technical-file history;
8. annual PRC appropriations, transfers, and financing route;
9. local election and party-alignment data;
10. Juntos and other social-program rollout data;
11. exact SISFOH 2013 and Census 2017 reference/fieldwork dates; and
12. the Census 2025 linkage protocol and timing.

## Decision gate

The current evidence changes the recommendation. The exact legacy geography
and its B–C first stage remain important historical benchmarks, but they
should not yet define the primary causal design. The next decision must wait
for a regime-specific reconstruction.

The research team should approve an RD only if the reconstruction identifies:

- a dated and stable assignment rule;
- a pre-decision running variable;
- a common risk set around the cutoff;
- a clearly ordered treatment event;
- a strong and stable local first stage;
- adequate effective observations and clusters;
- credible continuity and density diagnostics; and
- an estimand that matches the outcome date.

If those conditions cannot be satisfied, the correct conclusion is that the
available data support a rich descriptive and implementation study but not the
proposed fuzzy treatment-received RD.
