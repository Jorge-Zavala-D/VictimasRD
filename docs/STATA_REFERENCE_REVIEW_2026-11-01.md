# Stata reference-code and guidance review — 1 November 2026

Purpose: concrete comparisons for the standing research-code standard and fresh audit. No external package was executed; no external research dataset was downloaded. Reading source establishes implementation evidence, not successful numerical reproduction or permission to redistribute it.

## Literature scope and integration receipt

The live bibliography was read and screened: 59 entries. Shared Zotero group **IE Collective Reparations Peru**, library ID 5, was enumerated read-only: 39 items. Different counts reflect different scopes; neither is a claim that every literature item has a replication package. The per-entry screen is in metadata/stata-audit-2026-11-01/bibliography-screen.csv.

A direct query to the specified Peru NotebookLM URL failed after health reported unauthenticated and an unrelated Nigeria default notebook. The unrelated notebook was not queried. No authentication, cleanup, library mutation, or source upload was attempted. Consequently this is not a claim of successful NotebookLM synthesis.

Review states: **located** = authoritative record found; **inspected** = named code actually read; **traced** = code linked to named paper outputs; **executed** = run successfully. None below reached executed. An unavailable fetch is not proof that a package does not exist.

## Actual research scripts inspected

### R1. Lagakos, Mobarak and Waugh (2023), Econometrica

Bibliography key lagakos_welfare_2023; article DOI 10.3982/ECTA15962. [Journal record](https://www.econometricsociety.org/doi/10.3982/ECTA15962) and [coauthor's publication page](https://faculty.som.yale.edu/mushfiqmobarak/research/) identify the paper; the latter directly links the [author repository](https://github.com/mwaugh0328/welfare-rural-urban-migration).

Pinned snapshot: **573c5bffcb0185f482eca89e7151333ef66a72f9**, commit 19 January 2023. This is an author-maintained Econometrica-version repository, not a verified frozen journal deposit. Its 2023 snapshot and package identity must not be confused with the current article DOI.

Actual files read, whole named scripts:

| File within repository | Physical lines | SHA-256 |
| --- | ---: | --- |
| empirical-moments/Replication.do | 18 | b0c93f135d6ef8b43cdda77359c432bf293fdbd9664b4c7b74162ea40c612457 |
| empirical-moments/table-4/Replication for Table 4.do | 93 | 808c62d08fc21abac1b351ebfdeb2b035c76a5c39f221e5cecb48bf2aef2ec3c |
| empirical-moments/table-5/Replication for Table 5.do | 72 | 86f395c9f2ccf6ed7b3a4987581b46004a106eb560d93e09607179e2226de419 |

Also read root and empirical-moments READMEs. Trace: the empirical master explicitly calls Tables 4, 5, A9 and C1; Table 4 loads household inputs, collapses land values, merges savings/controls, splits consumption and affordability, and writes four calculated means to TeX. Table 5 builds 2008/2009 household-years and consumption-growth moments for spreadsheet export. This is a source-to-output trace, not a comparison with reproduced table numbers.

Adopt: short explicit master calls, task/exhibit headers, local temporary datasets, and extracting results immediately after calculation. Do not copy personal paths, path/case inconsistencies, assumptions converting missing land values to zero, or unguarded historical sums. The full project also uses MATLAB and Python: inspecting its Stata empirical component is not reviewing its structural-model implementation.

### R2. Calonico, Cattaneo, Farrell and Titiunik (2019), REStat

Current bibliography key calonico_covariates_2019. [Published empirical section/Table 1](https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell-Titiunik_2019_RESTAT.pdf) points to author replication resources; the [author index](https://rdpackages.github.io/replication/) identifies [CCFT_2019_RESTAT](https://github.com/rdpackages-replication/CCFT_2019_RESTAT).

Snapshot **b6b2711d6619e188d33ead5b1be1e75c907fa0ab**, 19 May 2026; actual Stata file last changed **8d7b26aef11d3969d44b62777d7ea4d3db90ca59**, 7 July 2021. Thus inspected code is a post-publication author revision, not certified publication-date bytes.

Read README and all **94 lines** of CCFT_2019_RESTAT.do; SHA-256 **8b5bced25aee70b21115c8cb36a4c99e85601a648040ed0c5e060aa5e690ae25**. Six explicit rdrobust calls/postfile records trace to Table 1's specification panels. Simulation and non-Stata implementations were not reviewed.

Adopt explicit model contrasts and recording both estimation and bias bandwidths. The conventional point estimate paired with robust bias-corrected inference is intentional, not automatically a bug. Do not transplant historical masspoints(off) instructions or its limited environment/data assertions. Code cutoff 59.1968 differs from the printed empirical description's 59.1984; not adjudicated here.

### R3. Cattaneo, Titiunik and Vazquez-Bare (2017), JPAM

Supplemental methodological/application example, not an independent Peru comparator. [Paper](https://rdpackages.github.io/references/Cattaneo-Titiunik-VazquezBare_2017_JPAM.pdf), [author index](https://rdpackages.github.io/replication/) and [repository](https://github.com/rdpackages-replication/CTV_2017_JPAM) establish the source chain.

Snapshot **7dd5deacaa94aa322c46dac24fd6ab2d89bf8234**, 19 May 2026; Stata file last-change **7453221b1a222d3bd68c7c9ccec1030780f02bc6**, 25 February 2021. Read README and all **527 lines** of CTV_2017_JPAM.do; SHA-256 **ff4abeab83682b2a6fbd6000519a639c7f5fff612ca030c91a3768c16c992830**. The script labels Tables 1–7/Figures 1–4; lines 203–287 trace Table 4's local-polynomial/window/placebo comparisons; 473–484 trace Table 7 sensitivity calculations. Appendix script not read.

Adopt exact exhibit mapping and clear separation of diagnostics, estimation and sensitivity. Do not copy historical compatibility/speed approximations or sharp-design assumptions into fuzzy Peru RD. R2 and R3 use the same Head Start application; they are not two independent substantive validations.

### R4. Bryan, Chowdhury and Mobarak (2014), Econometrica — mirror-only boundary

Additional migration/household-IV comparison: author-supplied replication files mirrored inside R1's pinned repository. Read the 2014 Master Table and Figure Creation.do, Table 3 and App Table 1 3 and 4.do, and Figure 4.do. The master explicitly maps main/appendix outputs; the table script directly exposes clustered ITT/OLS/IV and saved first stages; Figure 4 graphs re-migration earnings distributions.

This is an inspected **mirror**, not a separately verified frozen journal deposit. Adopt explicit outcome/denominator/exhibit links. Do not adopt required manual Excel assembly, positional e(first) extraction, old xi syntax, or editing globals to select appendix denominators. Its historical code is not authority for this project's missing-value or sample policies.

## Located, non-Stata, or incomplete searches

| Paper/source | Verified state | Limit |
| --- | --- | --- |
| Villamil and Balcells (2021), current bibliography | [Published correction](https://journals.sagepub.com/doi/10.1177/20531680251326800) supplies Dataverse DOI 10.7910/DVN/OOKUUH; author [streets_vox](https://github.com/franvillamil/streets_vox) inventory inspected at 86fcc4a40ce1f4bb95d45be0949569db89ebec78: 16 R files, zero .do files | R/Make workflow, not a Stata model; actual R analysis not reviewed. Dataverse fetch failed. |
| Voytas, More than Money, current bibliography | [Published article](https://www.cambridge.org/core/journals/american-political-science-review/article/abs/more-than-money-the-political-consequences-of-reparations/1AFB4967A0FC69B438DE2801258D11C2) identifies replication DOI 10.7910/DVN/TLLZUI | Dataverse/API fetch failed; version, language and actual code unverified. No Stata-package review claimed. |
| Kolesar and Rothe (2018), AER, current bibliography | [Article](https://www.aeaweb.org/articles?id=10.1257/aer.20160945) and [author page](https://www.princeton.edu/~mkolesar/research.html) checked; author software link leads to RDHonest-vStata | Maintained software is not a uniquely identified frozen paper-replication deposit. README/inventory only, no full ado audit. |
| Guarin et al., Reparations as Development, current bibliography | Banco de la Republica 2023 paper and author research page located | No authoritative accessible code package established in this bounded search; do not infer no package or public-data rights. |
| Morley (2017); David and Choi (2006); Dong (2019) | Bibliography and primary article/author or university records searched | No package version/code inspected. |
| Other bibliography entries | Metadata screened individually | Books, reviews, official/institutional sources and qualitative/conceptual studies are not presumed to have Stata code. Unsearched availability remains explicitly unverified. |

This review does not cover every public Stata package in AER/AEJ/QJE/JDE/JPubE/Econometrica or the entire Zotero literature. Further authoritative package searches remain work, not a silently completed checklist.

## Institutional guides and actual template code

Pinned actual-file links supplement the table: [WB main.do](https://github.com/worldbank/wb-reproducible-research-repository/blob/d4639c70e81fb20813cde4f6ca1756c8f10dca56/resources/main.do); IPA [00_run.do](https://github.com/PovertyAction/ipa-stata-template/blob/550aebd016a696cc82b04126c7b7815373328fe2/do_files/00_run.do), [01_data_cleaning.do](https://github.com/PovertyAction/ipa-stata-template/blob/550aebd016a696cc82b04126c7b7815373328fe2/do_files/01_data_cleaning.do), [04_main_analysis.do](https://github.com/PovertyAction/ipa-stata-template/blob/550aebd016a696cc82b04126c7b7815373328fe2/do_files/04_main_analysis.do), [06_generate_figures.do](https://github.com/PovertyAction/ipa-stata-template/blob/550aebd016a696cc82b04126c7b7815373328fe2/do_files/06_generate_figures.do); cfout [help/cfout.sthlp](https://github.com/PovertyAction/cfout/blob/bbfc96918115fac3ef8df25d8315cc2a8501c399/help/cfout.sthlp) and [cscript/cfout.do](https://github.com/PovertyAction/cfout/blob/bbfc96918115fac3ef8df25d8315cc2a8501c399/cscript/cfout.do). These links identify the reviewed files, not permission or instructions to execute them.

All URLs accessed 1 November 2026. Recommendations below are project adoption judgments, not institutional certification.

| Guide/code | Actual reading | Concrete project decision |
| --- | --- | --- |
| [DIME Wiki Stata practices](https://dimewiki.worldbank.org/Stata_Coding_Practices) and [reproducible research](https://dimewiki.worldbank.org/Reproducible_Research) | Paths, master, packages, comments and output/data-publication guidance | Keep quoted centralized paths, direct ordered master and code-generated outputs. Do not import routine shell/multilanguage execution or floating installation advice. |
| [Data Handbook](https://worldbank.github.io/dime-data-handbook/processing.html), chapters 1/5 and [Coding Guide/style appendix](https://worldbank.github.io/dime-data-handbook/coding.html) | Units/keys/linkage/quality checks; good-code, comments, variables, loops, indentation and missing-value/path sections | Keep scientific units/denominators visible; consistent why-comments and explicit variable names; no style-only rewrite. Relevant sections, not every chapter/resource. |
| [DIME standards](https://github.com/worldbank/dime-standards) and [World Bank repository](https://worldbank.github.io/wb-reproducible-research-repository/resources.html) | Research/coding-standard structure; checklist, README guidance, reviewer protocol and actual main.do | Separate access/disclosure, execution, stability and manuscript consistency. DIME employment requirements are not automatically this project's journal requirements. |
| WB actual main.do | All 30 lines at d4639c70e81fb20813cde4f6ca1756c8f10dca56 (21 October 2026) | Explicit three-script order is useful; do not copy automatic missing-package installation over the reviewed lock. |
| [J-PAL cleaning/management](https://www.povertyactionlab.org/resource/data-cleaning-and-management) | Organization, master/header, original-data preservation, cleaning, merges and missingness | Keep task boundaries and source preservation; reject old example environment commands or hard-coded team paths where inappropriate. |
| [J-PAL coding resources](https://www.povertyactionlab.org/resource/coding-resources-randomized-evaluations) and [publication](https://www.povertyactionlab.org/resource/data-publication) | Team/reproducibility resources, comparison tools, documentation/access/disclosure checklist | Publication-quality preparation is not permission to share restricted administrative records; no extra packages installed. |
| [IPA cleaning](https://data.poverty-action.org/data-cleaning/), variable management, [aggregation](https://data.poverty-action.org/data-cleaning/data-aggregation.html), raw management and Stata coding guide | Relevant data-flow, ID/merge, missingness, precision and QC sections | Guard unknown ages, financial sums and linkage identity before outcomes. Do not copy a generic check framework. Practical how-to index located; not every linked tutorial read. |
| [IPA Stata template](https://github.com/PovertyAction/ipa-stata-template) | HEAD 550aebd016a696cc82b04126c7b7815373328fe2 (17 August 2026); all 266 master lines; selected 01 cleaning, 04 analysis and 06 figures sections | Retain simple switches and centralized paths. Do not import optional runners/build tools, repeated standalone setup, blanket capture blocks or default in-repo data. |
| [IPA cfout](https://github.com/PovertyAction/cfout) | HEAD bbfc96918115fac3ef8df25d8315cc2a8501c399; help v2.0.1; selected certification sections 1–697, 1880–2014, 2115–2218 | Adopt small exact fixtures/expected failures, not the dependency itself. r(N) counts values compared; discrepancy=0 alone does not prove equal datasets. Row-level comparison outputs stay in Dropbox QA. |
| [Higgins Stata Guide](https://github.com/skhiggins/Stata_guide/blob/d00d5da9667f24080a87da3f82eac0203e1a36e1/README.md) | 20 May 2022 snapshot; style/path, actual master example, graph/scratch/export and reproducibility sections | Visible ordered calls, inputs/outputs and fresh-session checks; not username dispatch or a new framework. |
| [AEA policy](https://www.aeaweb.org/journals/data/data-code-policy), [README guidance](https://aeadataeditor.github.io/aea-de-guidance/preparing-replication-package-finalize) | Current policy/guidance relevant to rights, restricted access, version of record, software/hardware/runtime | Useful release benchmark, not a World Development mandate or permission to deposit. Journal-specific rules need separate current verification. |
| [Official Stata version control](https://www.stata.com/features/overview/integrated-version-control/), [version manual](https://www.stata.com/manuals/pversion.pdf) | Version behavior and scope | Keep version 19 and separate dependency identity; neither proves original hardware or package versions. |
| [Stata User Guide chapter 12](https://www.stata.com/manuals/u12.pdf), sections 12.2.1/12.2.2; [collapse](https://www.stata.com/manuals/dcollapse.pdf) | Missing-value ordering, byte range, variablewise aggregation and weights | Positive comparisons require finite guards; byte cannot store ages 101–120; sums need observed-count checks. Confirmed with in-console synthetic Stata selections. |
| Locked local ivreg2.ado | Targeted weak-ID and ereturn sections, including lines 1632–1738 and 2058–2065 | e(rkf) is genuinely returned in this locked robust/cluster implementation. Reject the preliminary suspicion that its name is itself invalid; missing-F passing remains a separate proven predicate defect. |

No guide's full linked ecosystem, IPA certification suite, or external empirical package was executed. Licenses/rights were not certified for copying third-party source into a public replication release. This record contains links, identities and analytical summaries, not copied datasets or third-party code archives.

