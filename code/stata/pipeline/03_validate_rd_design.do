/*------------------------------------------------------------------------------*
| Title:            RD design and first-stage audit                             |
| Project:          Victimas RD                                                 |
| Authors:          Jorge Zavala, Matthew Bird, Ana Maria Dumez                 |
|                                                                               |
| Description:      Audit treatment discontinuities across official cutoffs,   |
|                   treatment horizons, declared candidates, and bounded        |
|                   higher-order geographic subset atlases.                    |
|                                                                               |
| Date created:     29 July 2026                                                |
| Stata version:    19                                                          |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

    0. Governance and path contracts
    1. Input and registry validation
    2. Reusable first-stage programs
    3. Named-candidate specification grid
    4. Dynamic treatment-year grid
    5. Running-variable support sensitivity
    6. Broad geographic heterogeneity atlas
    7. Bounded higher-order subset atlases
    8. Baseline-covariate continuity audit
    9. Aggregate audit tables and scorecards
   10. Academic figures and TeX tables
   11. Output manifest and closeout

*-------------------------------------------------------------------------------*/


*-----------------------------------*
**# 0. Governance and path contracts
*-----------------------------------*

version 19
set more off
set varabbrev off

/*
This module is deliberately incapable of creating or changing the main RD
sample. The research team selected the exact legacy geography on 29 July 2026;
01_data_preparation.do constructs sample_main_rd from the RUV district UBIGEO.
This audit reports every declared estimate and retains failed specifications
as design evidence and sensitivity analysis.

The post-2012 written rule jointly prioritizes A and B, so B--C is the only
explicit operational boundary in that regime. The other cutoffs remain
diagnostic and cannot be promoted solely because a searched cell is strong.
*/

local automatic_sample_selection 0
local write_main_sample_flag 0
assert `automatic_sample_selection' == 0
assert `write_main_sample_flag' == 0

local required_globals ///
    project_root ///
    pipeline_root ///
    analysis_data_root ///
    qa_data_root ///
    figures_root ///
    tables_root ///
    metadata_root ///
    logs_root

foreach global_name of local required_globals {
    if `"${`global_name'}"' == "" {
        display as error "Required global is not defined: `global_name'"
        exit 198
    }
}

local input_file ///
    "${analysis_data_root}/07_community_registry_gdp.dta"
local candidate_registry ///
    "${metadata_root}/rd-design-candidate-registry.csv"
local specification_registry ///
    "${metadata_root}/rd-design-specification-registry.csv"
local protocol_file ///
    "${project_root}/docs/RD_DESIGN_AUDIT_PROTOCOL.md"

local table_dir "${tables_root}/rd_design"
local figure_dir "${figures_root}/rd_design"
local rd_manifest "${metadata_root}/rd-design-output-manifest.csv"

/*
The default mode runs the complete audit serially. The three internal modes
make the same specification grid resumable: base writes every non-province
cell, province_chunk writes a declared slice of the 1,023-mask power set, and
assemble validates and combines those files before producing the public
outputs. These globals are orchestration controls, not research choices.
*/

local execution_mode = lower(strtrim("${rd_design_execution_mode}"))
if "`execution_mode'" == "" {
    local execution_mode "full"
}
assert inlist( ///
    "`execution_mode'", ///
    "full", ///
    "base", ///
    "province_chunk", ///
    "assemble")

local province_chunk_count 16
local province_chunk_id = real("${rd_design_chunk_id}")
local province_chunk_start = real("${rd_design_chunk_start}")
local province_chunk_end = real("${rd_design_chunk_end}")

if "`execution_mode'" == "province_chunk" {
    assert inrange(`province_chunk_id', 1, `province_chunk_count')
    assert inrange(`province_chunk_start', 1, 1023)
    assert inrange(`province_chunk_end', `province_chunk_start', 1023)
}

foreach input_path in ///
    "`input_file'" ///
    "`candidate_registry'" ///
    "`specification_registry'" ///
    "`protocol_file'" {

    capture confirm file "`input_path'"
    if _rc {
        display as error "Required RD-design input was not found:"
        display as error "  `input_path'"
        exit 601
    }
}

foreach output_directory in "`table_dir'" "`figure_dir'" {
    capture mkdir "`output_directory'"
    if !direxists("`output_directory'") {
        display as error "Could not create RD-design output directory:"
        display as error "  `output_directory'"
        exit 603
    }
}

local output_paths ///
    output/tables/rd_design/rd_design_named_first_stages.csv ///
    output/tables/rd_design/rd_design_named_first_stages.xlsx ///
    output/tables/rd_design/rd_design_dynamic_first_stages.csv ///
    output/tables/rd_design/rd_design_geographic_atlas.csv ///
    output/tables/rd_design/rd_design_department_subsets.csv ///
    output/tables/rd_design/rd_design_vraem_province_subsets.csv ///
    output/tables/rd_design/rd_design_support_sensitivity.csv ///
    output/tables/rd_design/rd_design_cutoff_year_summary.csv ///
    output/tables/rd_design/rd_design_cutoff_year_frontier.csv ///
    output/tables/rd_design/rd_design_tie_audit.csv ///
    output/tables/rd_design/rd_design_candidate_accounting.csv ///
    output/tables/rd_design/rd_design_candidate_scorecard.csv ///
    output/tables/rd_design/rd_design_candidate_scorecard.xlsx ///
    output/tables/rd_design/rd_design_covariate_continuity.csv ///
    output/tables/rd_design/tab_rd_design_01_named_first_stages.tex ///
    output/tables/rd_design/tab_rd_design_02_candidate_scorecard.tex ///
    output/figures/rd_design/fig_rd_design_01_first_stage_horizons.png ///
    output/figures/rd_design/fig_rd_design_02_dynamic_first_stage.png ///
    output/figures/rd_design/fig_rd_design_03_named_horizon_forest.png ///
    output/figures/rd_design/fig_rd_design_04_strength_support.png ///
    output/figures/rd_design/fig_rd_design_05_subset_size.png

if inlist("`execution_mode'", "full", "assemble") {
    foreach output_path of local output_paths {
        capture erase "${project_root}/`output_path'"
    }
    capture erase "`rd_manifest'"
}

local run_date = subinstr("`c(current_date)'", " ", "", .)
local run_time = subinstr("`c(current_time)'", ":", "", .)
local run_id = lower("`run_date'_`run_time'")
local run_tag "`execution_mode'"
if "`execution_mode'" == "province_chunk" {
    local chunk_text : display %02.0f `province_chunk_id'
    local chunk_text = strtrim("`chunk_text'")
    local run_tag "`run_tag'_`chunk_text'"
}

capture log close victimasrd_rd_design
log using "${logs_root}/rd_design_audit_`run_id'_`run_tag'.smcl", ///
    name(victimasrd_rd_design) replace

display as result "Starting RD design audit (`execution_mode' mode)."
display as text "No automatic sample selection is permitted."
display as text "Protocol: `protocol_file'"


*-----------------------------------*
**# 1. Input and registry validation
*-----------------------------------*

preserve
import delimited "`candidate_registry'", ///
    varnames(1) stringcols(_all) clear

assert _N == 11
isid candidate_id
destring team_review_eligible, replace
assert team_review_eligible == 1
assert !missing( ///
    candidate_id, ///
    candidate_label, ///
    candidate_type, ///
    geographic_rule, ///
    institutional_rationale, ///
    source, ///
    status)
restore

preserve
import delimited "`specification_registry'", ///
    varnames(1) stringcols(_all) clear

isid grid_id
assert inlist(scope, ///
    "named_candidates", ///
    "dynamic_treatment_years", ///
    "running_variable_support_sensitivity", ///
    "geographic_heterogeneity_atlas", ///
    "bounded_department_subsets", ///
    "bounded_province_subsets", ///
    "covariate_continuity")
restore

use "`input_file'", clear

isid ruv_id
assert _N == 5712
assert !missing( ///
    victimization_level_source, ///
    victimization_index, ///
    dpto_victim_raw, ///
    prov_victim_raw, ///
    dist_victim_raw, ///
    ubigeo_dist)
assert inlist(victimization_level_source, "A", "B", "C", "D", "E")

foreach cutoff in ab bc cd de {
    assert !missing(running_`cutoff')
}

foreach treatment_var of varlist treat_07-treat_23 {
    assert inlist(`treatment_var', 0, 1)
}

quietly datasignature
local input_datasignature "`r(datasignature)'"

encode ubigeo_dist, generate(cluster_dist)
label variable cluster_dist "District cluster identifier for RD audit"

generate str40 dpto_clean = strtrim(upper(dpto_victim_raw))
generate str60 prov_clean = strtrim(upper(prov_victim_raw))

generate byte sample_national = 1
generate byte sample_legacy = ///
    inlist(dpto_clean, "APURIMAC", "HUANCAVELICA") | ///
    (dpto_clean == "CUSCO" & prov_clean == "LA CONVENCION") | ///
    (dpto_clean == "JUNIN" & prov_clean == "HUANCAYO")
generate byte sample_legacy_core = ///
    inlist(dpto_clean, "APURIMAC", "HUANCAVELICA")
generate byte sample_core3_frontier = ///
    inlist(dpto_clean, "APURIMAC", "HUANCAVELICA", "SAN MARTIN")

generate byte sample_vraem10 = ///
    (dpto_clean == "APURIMAC" & ///
        inlist(prov_clean, "ANDAHUAYLAS", "CHINCHEROS")) | ///
    (dpto_clean == "AYACUCHO" & ///
        inlist(prov_clean, "HUANTA", "LA MAR")) | ///
    (dpto_clean == "CUSCO" & prov_clean == "LA CONVENCION") | ///
    (dpto_clean == "HUANCAVELICA" & ///
        inlist(prov_clean, "CHURCAMPA", "TAYACAJA")) | ///
    (dpto_clean == "JUNIN" & ///
        inlist(prov_clean, "HUANCAYO", "CONCEPCION", "SATIPO"))

generate byte sample_vraem8_no_aya = ///
    sample_vraem10 & dpto_clean != "AYACUCHO"

generate byte sample_vraem6_direct = ///
    (dpto_clean == "AYACUCHO" & ///
        inlist(prov_clean, "HUANTA", "LA MAR")) | ///
    (dpto_clean == "CUSCO" & prov_clean == "LA CONVENCION") | ///
    (dpto_clean == "HUANCAVELICA" & prov_clean == "TAYACAJA") | ///
    (dpto_clean == "JUNIN" & ///
        inlist(prov_clean, "HUANCAYO", "SATIPO"))

generate byte sample_vraem5_dept = ///
    inlist(dpto_clean, ///
        "APURIMAC", "AYACUCHO", "CUSCO", "HUANCAVELICA", "JUNIN")

generate byte sample_vraem4_no_aya = ///
    inlist(dpto_clean, ///
        "APURIMAC", "CUSCO", "HUANCAVELICA", "JUNIN")

generate byte sample_cvr6 = ///
    inlist(dpto_clean, ///
        "APURIMAC", "AYACUCHO", "HUANCAVELICA", "HUANUCO") | ///
    inlist(dpto_clean, "JUNIN", "SAN MARTIN")

generate byte sample_cvr5_no_aya = ///
    sample_cvr6 & dpto_clean != "AYACUCHO"

generate byte sample_conflict_belt7 = ///
    inlist(dpto_clean, ///
        "APURIMAC", "AYACUCHO", "CUSCO", "HUANCAVELICA") | ///
    inlist(dpto_clean, "HUANUCO", "JUNIN", "SAN MARTIN")

assert sample_national == 1
quietly count if sample_legacy
assert r(N) == 1162
quietly count if sample_legacy_core
assert r(N) == 907
quietly count if sample_core3_frontier
assert r(N) == 1464

foreach sample_var in ///
    sample_legacy_core ///
    sample_core3_frontier ///
    sample_vraem10 ///
    sample_vraem8_no_aya ///
    sample_vraem6_direct ///
    sample_vraem5_dept ///
    sample_vraem4_no_aya ///
    sample_cvr6 ///
    sample_cvr5_no_aya ///
    sample_conflict_belt7 {

    assert inlist(`sample_var', 0, 1)
    quietly count if `sample_var'
    assert r(N) > 100
}

egen int department_group = group(dpto_clean), label
egen int province_group = ///
    group(dpto_clean prov_clean), label

quietly levelsof department_group, local(department_ids)
local department_count : word count `department_ids'
assert `department_count' == 15

quietly levelsof province_group, local(province_ids)
local province_count : word count `province_ids'
assert `province_count' == 95

tempfile analysis_source
save "`analysis_source'", replace


*-----------------------------------*
**# 2. Reusable first-stage programs
*-----------------------------------*

capture program drop _vrd_first_stage

program define _vrd_first_stage
    version 19
    syntax, ///
        POSTHandle(name) ///
        GRIDScope(string) ///
        SAMPLEvar(name) ///
        CANDIDATEid(string) ///
        CANDIDATElabel(string) ///
        CANDIDATEtype(string) ///
        TEAMreview(integer) ///
        SUBSETsize(integer) ///
        CUTOFF(string) ///
        HIGHcat(string) ///
        LOWcat(string) ///
        RUNNINGvar(name) ///
        TREATmentvar(name) ///
        TREATmentyear(integer) ///
        TIERule(string) ///
        SUPPORTrule(string) ///
        SPECification(string)

    assert inlist("`gridscope'", ///
        "named", ///
        "dynamic", ///
        "support_sensitivity", ///
        "broad_atlas", ///
        "dept_subset", ///
        "prov_subset")
    assert inlist("`cutoff'", "ab", "bc", "cd", "de")
    assert inlist("`tierule'", ///
        "score_as_recorded", ///
        "drop_sign_conflicts", ///
        "drop_rounding_band")
    assert inlist("`supportrule'", ///
        "adjacent_categories", ///
        "full_score_support")
    assert inlist("`specification'", ///
        "p1_mserd", ///
        "p1_cerrd", ///
        "p2_mserd")
    assert inlist(`teamreview', 0, 1)
    assert inrange(`subsetsize', 0, 15)

    tempvar analysis_use
    tempvar tag_score_left tag_score_right
    tempvar tag_cluster_left tag_cluster_right

    quietly count if `samplevar'
    local candidate_n = r(N)

    quietly generate byte `analysis_use' = `samplevar' == 1

    if "`supportrule'" == "adjacent_categories" {
        quietly replace `analysis_use' = 0 if ///
            !inlist(victimization_level_source, "`highcat'", "`lowcat'")
    }

    quietly count if ///
        `analysis_use' & ///
        inlist(victimization_level_source, "`highcat'", "`lowcat'") & ///
        ((`runningvar' >= 0) != ///
        (victimization_level_source == "`highcat'"))
    local sign_conflicts = r(N)

    quietly count if ///
        `analysis_use' & ///
        abs(`runningvar') <= 0.00005
    local rounding_band_n = r(N)

    if "`tierule'" == "drop_sign_conflicts" {
        quietly replace `analysis_use' = 0 if ///
            `analysis_use' & ///
            inlist(victimization_level_source, "`highcat'", "`lowcat'") & ///
            ((`runningvar' >= 0) != ///
            (victimization_level_source == "`highcat'"))
    }

    if "`tierule'" == "drop_rounding_band" {
        quietly replace `analysis_use' = 0 if ///
            `analysis_use' & ///
            abs(`runningvar') <= 0.00005
    }

    quietly count if `analysis_use'
    local analysis_n = r(N)
    quietly count if `analysis_use' & `treatmentvar' == 1
    local treated_n = r(N)
    quietly count if `analysis_use' & `treatmentvar' == 0
    local untreated_n = r(N)
    quietly count if `analysis_use' & `runningvar' < 0
    local n_left = r(N)
    quietly count if `analysis_use' & `runningvar' >= 0
    local n_right = r(N)
    quietly count if ///
        `analysis_use' & `runningvar' < 0 & `treatmentvar' == 1
    local treated_left = r(N)
    quietly count if ///
        `analysis_use' & `runningvar' < 0 & `treatmentvar' == 0
    local untreated_left = r(N)
    quietly count if ///
        `analysis_use' & `runningvar' >= 0 & `treatmentvar' == 1
    local treated_right = r(N)
    quietly count if ///
        `analysis_use' & `runningvar' >= 0 & `treatmentvar' == 0
    local untreated_right = r(N)

    quietly egen byte `tag_score_left' = ///
        tag(`runningvar') if `analysis_use' & `runningvar' < 0
    quietly egen byte `tag_score_right' = ///
        tag(`runningvar') if `analysis_use' & `runningvar' >= 0
    quietly count if `tag_score_left' == 1
    local unique_left = r(N)
    quietly count if `tag_score_right' == 1
    local unique_right = r(N)

    quietly egen byte `tag_cluster_left' = ///
        tag(cluster_dist) if `analysis_use' & `runningvar' < 0
    quietly egen byte `tag_cluster_right' = ///
        tag(cluster_dist) if `analysis_use' & `runningvar' >= 0
    quietly count if `tag_cluster_left' == 1
    local clusters_left = r(N)
    quietly count if `tag_cluster_right' == 1
    local clusters_right = r(N)

    local support_ok = ///
        `treated_n' >= 1 & ///
        `untreated_n' >= 1 & ///
        `treated_left' >= 1 & ///
        `untreated_left' >= 1 & ///
        `treated_right' >= 1 & ///
        `untreated_right' >= 1 & ///
        `n_left' >= 20 & ///
        `n_right' >= 20 & ///
        `unique_left' >= 5 & ///
        `unique_right' >= 5 & ///
        `clusters_left' >= 10 & ///
        `clusters_right' >= 10

    local attempted 0
    local estimation_rc .
    local tau_cl .
    local tau_bc .
    local se_rb .
    local p_rb .
    local ci_left .
    local ci_right .
    local h_left .
    local h_right .
    local b_left .
    local b_right .
    local effective_left .
    local effective_right .

    local specification_options
    if "`specification'" == "p1_mserd" {
        local specification_options ///
            "p(1) q(2) bwselect(mserd)"
    }
    if "`specification'" == "p1_cerrd" {
        local specification_options ///
            "p(1) q(2) bwselect(cerrd)"
    }
    if "`specification'" == "p2_mserd" {
        local specification_options ///
            "p(2) q(3) bwselect(mserd)"
    }

    if `support_ok' {
        local attempted 1
        capture quietly rdrobust ///
            `treatmentvar' ///
            `runningvar' ///
            if `analysis_use', ///
            `specification_options' ///
            kernel(triangular) ///
            vce(cluster cluster_dist) ///
            masspoints(adjust)
        local estimation_rc = _rc

        if !`estimation_rc' {
            local tau_cl = e(tau_cl)
            local tau_bc = e(tau_bc)
            local se_rb = e(se_tau_rb)
            local p_rb = e(pv_rb)
            local ci_left = e(ci_l_rb)
            local ci_right = e(ci_r_rb)
            local h_left = e(h_l)
            local h_right = e(h_r)
            local b_left = e(b_l)
            local b_right = e(b_r)
            local effective_left = e(N_h_l)
            local effective_right = e(N_h_r)
        }
    }

    post `posthandle' ///
        ("`gridscope'") ///
        ("`candidateid'") ///
        ("`candidatelabel'") ///
        ("`candidatetype'") ///
        (`teamreview') ///
        (`subsetsize') ///
        ("`cutoff'") ///
        ("`treatmentvar'") ///
        (`treatmentyear') ///
        ("`tierule'") ///
        ("`supportrule'") ///
        ("`specification'") ///
        (`candidate_n') ///
        (`analysis_n') ///
        (`treated_n') ///
        (`untreated_n') ///
        (`n_left') ///
        (`n_right') ///
        (`treated_left') ///
        (`untreated_left') ///
        (`treated_right') ///
        (`untreated_right') ///
        (`unique_left') ///
        (`unique_right') ///
        (`clusters_left') ///
        (`clusters_right') ///
        (`sign_conflicts') ///
        (`rounding_band_n') ///
        (`support_ok') ///
        (`attempted') ///
        (`estimation_rc') ///
        (`tau_cl') ///
        (`tau_bc') ///
        (`se_rb') ///
        (`p_rb') ///
        (`ci_left') ///
        (`ci_right') ///
        (`h_left') ///
        (`h_right') ///
        (`b_left') ///
        (`b_right') ///
        (`effective_left') ///
        (`effective_right')
end

capture program drop _vrd_atlas_grid

program define _vrd_atlas_grid
    version 19
    syntax, ///
        POSTHandle(name) ///
        GRIDScope(string) ///
        SAMPLEvar(name) ///
        CANDIDATEid(string) ///
        CANDIDATElabel(string) ///
        CANDIDATEtype(string) ///
        TEAMreview(integer) ///
        SUBSETsize(integer)

    local cutoff_ids "ab bc cd de"
    local high_categories "A B C D"
    local low_categories "B C D E"
    local running_variables ///
        "running_ab running_bc running_cd running_de"

    forvalues cutoff_index = 1/4 {
        local cutoff : word `cutoff_index' of `cutoff_ids'
        local highcat : word `cutoff_index' of `high_categories'
        local lowcat : word `cutoff_index' of `low_categories'
        local runningvar : word `cutoff_index' of `running_variables'

        forvalues year_suffix = 7/23 {
            local year_text : display %02.0f `year_suffix'
            local treatmentvar "treat_`year_text'"
            local treatmentyear = 2000 + `year_suffix'

            _vrd_first_stage, ///
                posthandle(`posthandle') ///
                gridscope("`gridscope'") ///
                samplevar(`samplevar') ///
                candidateid("`candidateid'") ///
                candidatelabel("`candidatelabel'") ///
                candidatetype("`candidatetype'") ///
                teamreview(`teamreview') ///
                subsetsize(`subsetsize') ///
                cutoff("`cutoff'") ///
                highcat("`highcat'") ///
                lowcat("`lowcat'") ///
                runningvar(`runningvar') ///
                treatmentvar(`treatmentvar') ///
                treatmentyear(`treatmentyear') ///
                tierule("drop_rounding_band") ///
                supportrule("adjacent_categories") ///
                specification("p1_mserd")
        }
    }
end

tempfile audit_results covariate_results
tempname audit_post

local candidate_ids ///
    national_full legacy_historical vraem10_provinces ///
    vraem8_no_ayacucho vraem6_direct_provinces ///
    vraem5_departments vraem4_no_ayacucho ///
    cvr6_departments cvr5_no_ayacucho ///
    conflict_belt7_departments legacy_department_core

postfile `audit_post' ///
    str20 grid_scope ///
    str40 candidate_id ///
    str400 candidate_label ///
    str36 candidate_type ///
    byte team_review_eligible ///
    byte subset_size ///
    str2 cutoff ///
    str8 treatment_var ///
    int treatment_year ///
    str24 tie_rule ///
    str24 support_rule ///
    str16 specification ///
    int candidate_n ///
    int analysis_n ///
    int treated_n ///
    int untreated_n ///
    int n_left ///
    int n_right ///
    int treated_left ///
    int untreated_left ///
    int treated_right ///
    int untreated_right ///
    int unique_left ///
    int unique_right ///
    int clusters_left ///
    int clusters_right ///
    int sign_conflicts ///
    int rounding_band_n ///
    byte support_ok ///
    byte attempted ///
    int estimation_rc ///
    double tau_cl ///
    double tau_bc ///
    double se_rb ///
    double p_rb ///
    double ci_left ///
    double ci_right ///
    double h_left ///
    double h_right ///
    double b_left ///
    double b_right ///
    int effective_left ///
    int effective_right ///
    using "`audit_results'", replace


if inlist("`execution_mode'", "full", "base") {

*-----------------------------------*
**# 3. Named-candidate specification grid
*-----------------------------------*

local candidate_ids ///
    national_full legacy_historical vraem10_provinces ///
    vraem8_no_ayacucho vraem6_direct_provinces ///
    vraem5_departments vraem4_no_ayacucho ///
    cvr6_departments cvr5_no_ayacucho ///
    conflict_belt7_departments legacy_department_core
local candidate_variables ///
    sample_national sample_legacy sample_vraem10 ///
    sample_vraem8_no_aya sample_vraem6_direct ///
    sample_vraem5_dept sample_vraem4_no_aya ///
    sample_cvr6 sample_cvr5_no_aya ///
    sample_conflict_belt7 sample_legacy_core
local candidate_label_1 "National RUV universe"
local candidate_label_2 "Legacy restricted geography"
local candidate_label_3 ///
    "Official VRAEM ten-province study envelope"
local candidate_label_4 ///
    "VRAEM province envelope excluding Ayacucho"
local candidate_label_5 ///
    "VRAEM direct-intervention province envelope"
local candidate_label_6 "VRAEM five-department envelope"
local candidate_label_7 ///
    "VRAEM departments excluding Ayacucho"
local candidate_label_8 "CVR six high-burden departments"
local candidate_label_9 ///
    "CVR high-burden departments excluding Ayacucho"
local candidate_label_10 ///
    "Combined conflict and VRAEM department belt"
local candidate_label_11 "Legacy two-department core"
local candidate_types ///
    national_baseline historical_benchmark ///
    official_province_envelope predeclared_exclusion ///
    official_province_envelope official_department_envelope ///
    predeclared_exclusion official_conflict_envelope ///
    predeclared_exclusion derived_official_envelope ///
    historical_component
local candidate_review "1 1 1 1 1 1 1 1 1 1 1"

local cutoff_ids "ab bc cd de"
local high_categories "A B C D"
local low_categories "B C D E"
local running_variables ///
    "running_ab running_bc running_cd running_de"
local treatment_variables ///
    "treat_12 treat_16 treat_23"
local treatment_years "2012 2016 2023"
local tie_rules ///
    "score_as_recorded drop_sign_conflicts drop_rounding_band"
local specifications ///
    "p1_mserd p1_cerrd p2_mserd"

forvalues candidate_index = 1/11 {
    local candidate_id : ///
        word `candidate_index' of `candidate_ids'
    local candidate_var : ///
        word `candidate_index' of `candidate_variables'
    local candidate_label ///
        "`candidate_label_`candidate_index''"
    local candidate_type : ///
        word `candidate_index' of `candidate_types'
    local team_review : ///
        word `candidate_index' of `candidate_review'

    forvalues cutoff_index = 1/4 {
        local cutoff : word `cutoff_index' of `cutoff_ids'
        local highcat : word `cutoff_index' of `high_categories'
        local lowcat : word `cutoff_index' of `low_categories'
        local runningvar : word `cutoff_index' of `running_variables'

        forvalues horizon_index = 1/3 {
            local treatmentvar : ///
                word `horizon_index' of `treatment_variables'
            local treatmentyear : ///
                word `horizon_index' of `treatment_years'

            foreach tie_rule of local tie_rules {
                foreach specification of local specifications {
                    _vrd_first_stage, ///
                        posthandle(`audit_post') ///
                        gridscope("named") ///
                        samplevar(`candidate_var') ///
                        candidateid("`candidate_id'") ///
                        candidatelabel("`candidate_label'") ///
                        candidatetype("`candidate_type'") ///
                        teamreview(`team_review') ///
                        subsetsize(0) ///
                        cutoff("`cutoff'") ///
                        highcat("`highcat'") ///
                        lowcat("`lowcat'") ///
                        runningvar(`runningvar') ///
                        treatmentvar(`treatmentvar') ///
                        treatmentyear(`treatmentyear') ///
                        tierule("`tie_rule'") ///
                        supportrule("adjacent_categories") ///
                        specification("`specification'")
                }
            }
        }
    }
}


*-----------------------------------*
**# 4. Dynamic treatment-year grid
*-----------------------------------*

forvalues candidate_index = 1/11 {
    local candidate_id : ///
        word `candidate_index' of `candidate_ids'
    local candidate_var : ///
        word `candidate_index' of `candidate_variables'
    local candidate_label ///
        "`candidate_label_`candidate_index''"
    local candidate_type : ///
        word `candidate_index' of `candidate_types'
    local team_review : ///
        word `candidate_index' of `candidate_review'

    forvalues cutoff_index = 1/4 {
        local cutoff : word `cutoff_index' of `cutoff_ids'
        local highcat : word `cutoff_index' of `high_categories'
        local lowcat : word `cutoff_index' of `low_categories'
        local runningvar : word `cutoff_index' of `running_variables'

        forvalues year_suffix = 7/23 {
            local year_text : display %02.0f `year_suffix'
            local treatmentvar "treat_`year_text'"
            local treatmentyear = 2000 + `year_suffix'

            _vrd_first_stage, ///
                posthandle(`audit_post') ///
                gridscope("dynamic") ///
                samplevar(`candidate_var') ///
                candidateid("`candidate_id'") ///
                candidatelabel("`candidate_label'") ///
                candidatetype("`candidate_type'") ///
                teamreview(`team_review') ///
                subsetsize(0) ///
                cutoff("`cutoff'") ///
                highcat("`highcat'") ///
                lowcat("`lowcat'") ///
                runningvar(`runningvar') ///
                treatmentvar(`treatmentvar') ///
                treatmentyear(`treatmentyear') ///
                tierule("score_as_recorded") ///
                supportrule("adjacent_categories") ///
                specification("p1_mserd")
        }
    }
}


*-----------------------------------*
**# 5. Running-variable support sensitivity
*-----------------------------------*

/*
Standard single-cutoff RD may begin from the full score support because
rdrobust selects local bandwidths. In this ordered multi-threshold setting,
the adjacent-category restriction prevents a selected bandwidth from crossing
another policy threshold. This fully reported sensitivity quantifies whether
that conservative support rule drives the named-candidate results.
*/

forvalues candidate_index = 1/11 {
    local candidate_id : ///
        word `candidate_index' of `candidate_ids'
    local candidate_var : ///
        word `candidate_index' of `candidate_variables'
    local candidate_label ///
        "`candidate_label_`candidate_index''"
    local candidate_type : ///
        word `candidate_index' of `candidate_types'
    local team_review : ///
        word `candidate_index' of `candidate_review'

    forvalues cutoff_index = 1/4 {
        local cutoff : word `cutoff_index' of `cutoff_ids'
        local highcat : word `cutoff_index' of `high_categories'
        local lowcat : word `cutoff_index' of `low_categories'
        local runningvar : word `cutoff_index' of `running_variables'

        forvalues year_suffix = 7/23 {
            local year_text : display %02.0f `year_suffix'
            local treatmentvar "treat_`year_text'"
            local treatmentyear = 2000 + `year_suffix'

            _vrd_first_stage, ///
                posthandle(`audit_post') ///
                gridscope("support_sensitivity") ///
                samplevar(`candidate_var') ///
                candidateid("`candidate_id'") ///
                candidatelabel("`candidate_label'") ///
                candidatetype("`candidate_type'") ///
                teamreview(`team_review') ///
                subsetsize(0) ///
                cutoff("`cutoff'") ///
                highcat("`highcat'") ///
                lowcat("`lowcat'") ///
                runningvar(`runningvar') ///
                treatmentvar(`treatmentvar') ///
                treatmentyear(`treatmentyear') ///
                tierule("score_as_recorded") ///
                supportrule("full_score_support") ///
                specification("p1_mserd")
        }
    }
}


*-----------------------------------*
**# 6. Broad geographic heterogeneity atlas
*-----------------------------------*

/*
These estimates are ineligible for automatic sample selection. The atlas is
retained for comparison with the historical pairwise search. Higher-order
searches are confined to the independently defined envelopes in section 7.
*/

foreach department_id of local department_ids {
    local department_label : ///
        label (department_group) `department_id'
    local department_text : display %02.0f `department_id'
    local department_text = strtrim("`department_text'")

    generate byte sample_atlas = ///
        department_group == `department_id'
    _vrd_atlas_grid, ///
        posthandle(`audit_post') ///
        gridscope("broad_atlas") ///
        samplevar(sample_atlas) ///
        candidateid("dept_`department_text'") ///
        candidatelabel("Department: `department_label'") ///
        candidatetype("atlas_department") ///
        teamreview(0) ///
        subsetsize(1)
    drop sample_atlas

    generate byte sample_atlas = ///
        department_group != `department_id'
    _vrd_atlas_grid, ///
        posthandle(`audit_post') ///
        gridscope("broad_atlas") ///
        samplevar(sample_atlas) ///
        candidateid("leaveout_dept_`department_text'") ///
        candidatelabel("Leave out: `department_label'") ///
        candidatetype("atlas_leave_one_out") ///
        teamreview(0) ///
        subsetsize(14)
    drop sample_atlas
}

local department_position_a = 0
foreach department_a of local department_ids {
    local ++department_position_a
    local label_a : label (department_group) `department_a'
    local text_a : display %02.0f `department_a'
    local text_a = strtrim("`text_a'")

    local department_position_b = 0
    foreach department_b of local department_ids {
        local ++department_position_b

        if `department_position_b' > `department_position_a' {
            local label_b : ///
                label (department_group) `department_b'
            local text_b : display %02.0f `department_b'
            local text_b = strtrim("`text_b'")

            generate byte sample_atlas = ///
                inlist(department_group, ///
                    `department_a', `department_b')
            _vrd_atlas_grid, ///
                posthandle(`audit_post') ///
                gridscope("broad_atlas") ///
                samplevar(sample_atlas) ///
                candidateid("dept_pair_`text_a'_`text_b'") ///
                candidatelabel("Departments: `label_a' + `label_b'") ///
                candidatetype("atlas_department_pair") ///
                teamreview(0) ///
                subsetsize(2)
            drop sample_atlas
        }
    }
}

foreach province_id of local province_ids {
    local province_label : ///
        label (province_group) `province_id'
    local province_text : display %03.0f `province_id'
    local province_text = strtrim("`province_text'")

    generate byte sample_atlas = ///
        province_group == `province_id'
    _vrd_atlas_grid, ///
        posthandle(`audit_post') ///
        gridscope("broad_atlas") ///
        samplevar(sample_atlas) ///
        candidateid("province_cell_`province_text'") ///
        candidatelabel("Province cell: `province_label'") ///
        candidatetype("atlas_province_cell") ///
        teamreview(0) ///
        subsetsize(1)
    drop sample_atlas
}


*-----------------------------------*
**# 7. Bounded higher-order subset atlases
*-----------------------------------*

/*
The conflict-belt universe is the union of the five official VRAEM
departments and the six departments that account for 85 percent of victims
registered by the CVR. Every one of its 127 nonempty subsets is reported.
*/

local conflict_department_1 "APURIMAC"
local conflict_department_2 "AYACUCHO"
local conflict_department_3 "CUSCO"
local conflict_department_4 "HUANCAVELICA"
local conflict_department_5 "HUANUCO"
local conflict_department_6 "JUNIN"
local conflict_department_7 "SAN MARTIN"

forvalues subset_mask = 1/127 {
    generate byte sample_subset = 0
    local subset_label
    local subset_size 0

    forvalues component_index = 1/7 {
        if mod(floor( ///
            `subset_mask' / (2^(`component_index' - 1))), 2) == 1 {

            local component_name ///
                "`conflict_department_`component_index''"
            quietly replace sample_subset = 1 if ///
                dpto_clean == "`component_name'"
            local ++subset_size

            if `subset_size' == 1 {
                local subset_label "`component_name'"
            }
            else {
                local subset_label ///
                    "`subset_label' + `component_name'"
            }
        }
    }

    local mask_text : display %03.0f `subset_mask'
    local mask_text = strtrim("`mask_text'")

    _vrd_atlas_grid, ///
        posthandle(`audit_post') ///
        gridscope("dept_subset") ///
        samplevar(sample_subset) ///
        candidateid("conflict_dept_subset_`mask_text'") ///
        candidatelabel("Conflict-belt departments: `subset_label'") ///
        candidatetype("bounded_department_subset") ///
        teamreview(0) ///
        subsetsize(`subset_size')

    drop sample_subset
}

}

/*
The province universe is INEI's complete ten-province VRAEM study envelope.
All 1,023 nonempty subsets are estimated at all four thresholds for every
cumulative treatment year from 2007 through 2023. These results diagnose
heterogeneity and cannot select a sample without an independently stated
rule.
*/

local vraem_department_1 "APURIMAC"
local vraem_province_1 "ANDAHUAYLAS"
local vraem_component_1 "APURIMAC / ANDAHUAYLAS"
local vraem_department_2 "APURIMAC"
local vraem_province_2 "CHINCHEROS"
local vraem_component_2 "APURIMAC / CHINCHEROS"
local vraem_department_3 "AYACUCHO"
local vraem_province_3 "HUANTA"
local vraem_component_3 "AYACUCHO / HUANTA"
local vraem_department_4 "AYACUCHO"
local vraem_province_4 "LA MAR"
local vraem_component_4 "AYACUCHO / LA MAR"
local vraem_department_5 "CUSCO"
local vraem_province_5 "LA CONVENCION"
local vraem_component_5 "CUSCO / LA CONVENCION"
local vraem_department_6 "HUANCAVELICA"
local vraem_province_6 "CHURCAMPA"
local vraem_component_6 "HUANCAVELICA / CHURCAMPA"
local vraem_department_7 "HUANCAVELICA"
local vraem_province_7 "TAYACAJA"
local vraem_component_7 "HUANCAVELICA / TAYACAJA"
local vraem_department_8 "JUNIN"
local vraem_province_8 "HUANCAYO"
local vraem_component_8 "JUNIN / HUANCAYO"
local vraem_department_9 "JUNIN"
local vraem_province_9 "CONCEPCION"
local vraem_component_9 "JUNIN / CONCEPCION"
local vraem_department_10 "JUNIN"
local vraem_province_10 "SATIPO"
local vraem_component_10 "JUNIN / SATIPO"

if inlist("`execution_mode'", "full", "province_chunk") {

local province_mask_start 1
local province_mask_end 1023
if "`execution_mode'" == "province_chunk" {
    local province_mask_start `province_chunk_start'
    local province_mask_end `province_chunk_end'
}

forvalues subset_mask = `province_mask_start'/`province_mask_end' {
    generate byte sample_subset = 0
    local subset_label
    local subset_size 0

    forvalues component_index = 1/10 {
        if mod(floor( ///
            `subset_mask' / (2^(`component_index' - 1))), 2) == 1 {

            local component_department ///
                "`vraem_department_`component_index''"
            local component_province ///
                "`vraem_province_`component_index''"
            local component_name ///
                "`vraem_component_`component_index''"

            quietly replace sample_subset = 1 if ///
                dpto_clean == "`component_department'" & ///
                prov_clean == "`component_province'"
            local ++subset_size

            if `subset_size' == 1 {
                local subset_label "`component_name'"
            }
            else {
                local subset_label ///
                    "`subset_label' + `component_name'"
            }
        }
    }

    local mask_text : display %04.0f `subset_mask'
    local mask_text = strtrim("`mask_text'")

    _vrd_atlas_grid, ///
        posthandle(`audit_post') ///
        gridscope("prov_subset") ///
        samplevar(sample_subset) ///
        candidateid("vraem_prov_subset_`mask_text'") ///
        candidatelabel("VRAEM provinces: `subset_label'") ///
        candidatetype("bounded_vraem_province_subset") ///
        teamreview(0) ///
        subsetsize(`subset_size')

    drop sample_subset
}

}

postclose `audit_post'

if "`execution_mode'" == "province_chunk" {
    local chunk_text : display %02.0f `province_chunk_id'
    local chunk_text = strtrim("`chunk_text'")
    local chunk_output ///
        "${qa_data_root}/rd_design_first_stage_prov_chunk_`chunk_text'.dta"

    use "`audit_results'", clear
    local expected_chunk_rows = ///
        (`province_chunk_end' - `province_chunk_start' + 1) * 68
    assert _N == `expected_chunk_rows'
    isid ///
        grid_scope ///
        candidate_id ///
        cutoff ///
        treatment_year ///
        tie_rule ///
        support_rule ///
        specification
    save "`chunk_output'", replace

    display as result ///
        "Province chunk `chunk_text' completed: `province_chunk_start'-`province_chunk_end'."
    display as text "Rows saved: " _N
    display as text "Output: `chunk_output'"

    capture program drop _vrd_first_stage
    capture program drop _vrd_atlas_grid
    log close victimasrd_rd_design
    exit
}

if "`execution_mode'" == "assemble" {
    local base_output ///
        "${qa_data_root}/rd_design_first_stage_base.dta"
    local covariate_base ///
        "${qa_data_root}/rd_design_covariate_continuity_base.dta"

    capture confirm file "`base_output'"
    assert !_rc
    use "`base_output'", clear
    assert _N == 26960

    forvalues chunk_index = 1/`province_chunk_count' {
        local chunk_text : display %02.0f `chunk_index'
        local chunk_text = strtrim("`chunk_text'")
        local chunk_output ///
            "${qa_data_root}/rd_design_first_stage_prov_chunk_`chunk_text'.dta"
        capture confirm file "`chunk_output'"
        assert !_rc
        append using "`chunk_output'"
    }

    assert _N == 96524
    isid ///
        grid_scope ///
        candidate_id ///
        cutoff ///
        treatment_year ///
        tie_rule ///
        support_rule ///
        specification
    save "`audit_results'", replace

    capture confirm file "`covariate_base'"
    assert !_rc
    use "`covariate_base'", clear
    save "`covariate_results'", replace
}


*-----------------------------------*
**# 8. Baseline-covariate continuity audit
*-----------------------------------*

if inlist("`execution_mode'", "full", "base") {

capture program drop _vrd_covariate_test

program define _vrd_covariate_test
    version 19
    syntax, ///
        POSTHandle(name) ///
        SAMPLEvar(name) ///
        CANDIDATEid(string) ///
        CANDIDATElabel(string) ///
        CUTOFF(string) ///
        HIGHcat(string) ///
        LOWcat(string) ///
        RUNNINGvar(name) ///
        OUTCOMEvar(name) ///
        OUTCOMElabel(string)

    tempvar analysis_use
    tempvar tag_score_left tag_score_right
    tempvar tag_cluster_left tag_cluster_right

    quietly generate byte `analysis_use' = ///
        `samplevar' == 1 & ///
        inlist(victimization_level_source, "`highcat'", "`lowcat'") & ///
        abs(`runningvar') > 0.00005 & ///
        !missing(`outcomevar')

    quietly count if `samplevar' == 1 & ///
        inlist(victimization_level_source, "`highcat'", "`lowcat'")
    local eligible_n = r(N)
    quietly count if `analysis_use'
    local analysis_n = r(N)
    local missing_n = `eligible_n' - `analysis_n'
    quietly count if `analysis_use' & `runningvar' < 0
    local n_left = r(N)
    quietly count if `analysis_use' & `runningvar' >= 0
    local n_right = r(N)

    quietly egen byte `tag_score_left' = ///
        tag(`runningvar') if `analysis_use' & `runningvar' < 0
    quietly egen byte `tag_score_right' = ///
        tag(`runningvar') if `analysis_use' & `runningvar' >= 0
    quietly count if `tag_score_left' == 1
    local unique_left = r(N)
    quietly count if `tag_score_right' == 1
    local unique_right = r(N)

    quietly egen byte `tag_cluster_left' = ///
        tag(cluster_dist) if `analysis_use' & `runningvar' < 0
    quietly egen byte `tag_cluster_right' = ///
        tag(cluster_dist) if `analysis_use' & `runningvar' >= 0
    quietly count if `tag_cluster_left' == 1
    local clusters_left = r(N)
    quietly count if `tag_cluster_right' == 1
    local clusters_right = r(N)

    local support_ok = ///
        `n_left' >= 20 & ///
        `n_right' >= 20 & ///
        `unique_left' >= 5 & ///
        `unique_right' >= 5 & ///
        `clusters_left' >= 10 & ///
        `clusters_right' >= 10

    local estimation_rc .
    local tau_cl .
    local tau_bc .
    local se_rb .
    local p_rb .
    local ci_left .
    local ci_right .
    local effective_left .
    local effective_right .

    if `support_ok' {
        capture quietly rdrobust ///
            `outcomevar' ///
            `runningvar' ///
            if `analysis_use', ///
            p(1) q(2) ///
            bwselect(mserd) ///
            kernel(triangular) ///
            vce(cluster cluster_dist) ///
            masspoints(adjust)
        local estimation_rc = _rc

        if !`estimation_rc' {
            local tau_cl = e(tau_cl)
            local tau_bc = e(tau_bc)
            local se_rb = e(se_tau_rb)
            local p_rb = e(pv_rb)
            local ci_left = e(ci_l_rb)
            local ci_right = e(ci_r_rb)
            local effective_left = e(N_h_l)
            local effective_right = e(N_h_r)
        }
    }

    post `posthandle' ///
        ("`candidateid'") ///
        ("`candidatelabel'") ///
        ("`cutoff'") ///
        ("`outcomevar'") ///
        ("`outcomelabel'") ///
        (`eligible_n') ///
        (`analysis_n') ///
        (`missing_n') ///
        (`n_left') ///
        (`n_right') ///
        (`unique_left') ///
        (`unique_right') ///
        (`clusters_left') ///
        (`clusters_right') ///
        (`support_ok') ///
        (`estimation_rc') ///
        (`tau_cl') ///
        (`tau_bc') ///
        (`se_rb') ///
        (`p_rb') ///
        (`ci_left') ///
        (`ci_right') ///
        (`effective_left') ///
        (`effective_right')
end

tempname covariate_post

postfile `covariate_post' ///
    str40 candidate_id ///
    str80 candidate_label ///
    str2 cutoff ///
    str32 outcome_var ///
    str80 outcome_label ///
    int eligible_n ///
    int analysis_n ///
    int missing_n ///
    int n_left ///
    int n_right ///
    int unique_left ///
    int unique_right ///
    int clusters_left ///
    int clusters_right ///
    byte support_ok ///
    int estimation_rc ///
    double tau_cl ///
    double tau_bc ///
    double se_rb ///
    double p_rb ///
    double ci_left ///
    double ci_right ///
    int effective_left ///
    int effective_right ///
    using "`covariate_results'", replace

local covariate_variables ///
    ln_population_2007 wellbeing_core_2007 ///
    share_indigenous_language_2007 share_literate_2007 ///
    share_female_2007 urban_2007 altitude_m ///
    ln1p_dist_dist_capital
local covariate_label_1 "Log 2007 population"
local covariate_label_2 "2007 ecological wellbeing score"
local covariate_label_3 "2007 indigenous-language share"
local covariate_label_4 "2007 literacy share"
local covariate_label_5 "2007 female population share"
local covariate_label_6 "Urban community in 2007"
local covariate_label_7 "Altitude in meters"
local covariate_label_8 "Log distance to district capital"

forvalues candidate_index = 1/11 {
    local candidate_id : ///
        word `candidate_index' of `candidate_ids'
    local candidate_var : ///
        word `candidate_index' of `candidate_variables'
    local candidate_label ///
        "`candidate_label_`candidate_index''"

    forvalues cutoff_index = 1/4 {
        local cutoff : word `cutoff_index' of `cutoff_ids'
        local highcat : word `cutoff_index' of `high_categories'
        local lowcat : word `cutoff_index' of `low_categories'
        local runningvar : ///
            word `cutoff_index' of `running_variables'

        forvalues covariate_index = 1/8 {
            local covariate_var : ///
                word `covariate_index' of `covariate_variables'
            local covariate_label ///
                "`covariate_label_`covariate_index''"

            _vrd_covariate_test, ///
                posthandle(`covariate_post') ///
                samplevar(`candidate_var') ///
                candidateid("`candidate_id'") ///
                candidatelabel("`candidate_label'") ///
                cutoff("`cutoff'") ///
                highcat("`highcat'") ///
                lowcat("`lowcat'") ///
                runningvar(`runningvar') ///
                outcomevar(`covariate_var') ///
                outcomelabel("`covariate_label'")
        }
    }
}

/*
The expanded search identified the three-department historical core plus San
Martin as the early/mid statistical frontier. It remains ineligible for sample
selection because it was identified after the subset search, but its baseline
continuity must be audited rather than discussed from first-stage strength
alone.
*/

forvalues cutoff_index = 1/4 {
    local cutoff : word `cutoff_index' of `cutoff_ids'
    local highcat : word `cutoff_index' of `high_categories'
    local lowcat : word `cutoff_index' of `low_categories'
    local runningvar : word `cutoff_index' of `running_variables'

    forvalues covariate_index = 1/8 {
        local covariate_var : ///
            word `covariate_index' of `covariate_variables'
        local covariate_label ///
            "`covariate_label_`covariate_index''"

        _vrd_covariate_test, ///
            posthandle(`covariate_post') ///
            samplevar(sample_core3_frontier) ///
            candidateid("conflict_dept_subset_073") ///
            candidatelabel( ///
                "APURIMAC + HUANCAVELICA + SAN MARTIN") ///
            cutoff("`cutoff'") ///
            highcat("`highcat'") ///
            lowcat("`lowcat'") ///
            runningvar(`runningvar') ///
            outcomevar(`covariate_var') ///
            outcomelabel("`covariate_label'")
    }
}

postclose `covariate_post'

}

if "`execution_mode'" == "base" {
    local base_output ///
        "${qa_data_root}/rd_design_first_stage_base.dta"
    local covariate_base ///
        "${qa_data_root}/rd_design_covariate_continuity_base.dta"

    use "`audit_results'", clear
    assert _N == 26960
    isid ///
        grid_scope ///
        candidate_id ///
        cutoff ///
        treatment_year ///
        tie_rule ///
        support_rule ///
        specification
    save "`base_output'", replace

    use "`covariate_results'", clear
    assert _N > 0
    save "`covariate_base'", replace

    display as result "RD design base audit completed."
    display as text "First-stage rows: 26,960"
    display as text "First-stage output: `base_output'"
    display as text "Covariate output: `covariate_base'"

    capture program drop _vrd_first_stage
    capture program drop _vrd_atlas_grid
    capture program drop _vrd_covariate_test
    log close victimasrd_rd_design
    exit
}


*-----------------------------------*
**# 9. Aggregate audit tables and scorecards
*-----------------------------------*

use "`audit_results'", clear

assert _N == 96524
isid ///
    grid_scope ///
    candidate_id ///
    cutoff ///
    treatment_var ///
    tie_rule ///
    support_rule ///
    specification
assert inlist(support_ok, 0, 1)
assert inlist(attempted, 0, 1)
assert attempted <= support_ok
assert missing(tau_cl) if attempted == 0 | estimation_rc != 0

label variable tau_cl ///
    "Conventional local-polynomial first-stage point estimate"
label variable tau_bc ///
    "Bias-corrected first-stage point estimate"
label variable p_rb ///
    "Robust bias-corrected p-value"
label variable ci_left ///
    "Robust 95 percent confidence-interval lower bound"
label variable ci_right ///
    "Robust 95 percent confidence-interval upper bound"
label variable team_review_eligible ///
    "Candidate was eligible for documented team review"
label variable subset_size ///
    "Number of department or province components in subset"
label variable support_rule ///
    "Score-support rule used before local bandwidth selection"

compress
save "${qa_data_root}/rd_design_first_stage_audit.dta", ///
    replace

preserve
keep if grid_scope == "named"
sort ///
    candidate_id ///
    cutoff ///
    treatment_year ///
    tie_rule ///
    specification
export delimited using ///
    "`table_dir'/rd_design_named_first_stages.csv", ///
    replace
export excel using ///
    "`table_dir'/rd_design_named_first_stages.xlsx", ///
    sheet("named_first_stages") ///
    firstrow(variables) replace
restore

preserve
keep if grid_scope == "dynamic"
sort candidate_id cutoff treatment_year
export delimited using ///
    "`table_dir'/rd_design_dynamic_first_stages.csv", ///
    replace
restore

preserve
keep if grid_scope == "support_sensitivity"
sort candidate_id cutoff treatment_year
export delimited using ///
    "`table_dir'/rd_design_support_sensitivity.csv", ///
    replace
restore

/*
The complete all-year atlases remain in the Dropbox QA dataset. Git receives
the three outcome-linked slices plus compact all-year summaries so a large
search artifact does not become repository storage.
*/

preserve
keep if grid_scope == "broad_atlas"
keep if inlist(treatment_year, 2012, 2016, 2023)
sort candidate_type candidate_id cutoff treatment_year
export delimited using ///
    "`table_dir'/rd_design_geographic_atlas.csv", ///
    replace
restore

preserve
keep if grid_scope == "dept_subset"
keep if inlist(treatment_year, 2012, 2016, 2023)
sort subset_size candidate_id cutoff treatment_year
export delimited using ///
    "`table_dir'/rd_design_department_subsets.csv", ///
    replace
restore

preserve
keep if grid_scope == "prov_subset"
keep if inlist(treatment_year, 2012, 2016, 2023)
sort subset_size candidate_id cutoff treatment_year
export delimited using ///
    "`table_dir'/rd_design_vraem_province_subsets.csv", ///
    replace
restore

preserve
keep if inlist(grid_scope, ///
    "broad_atlas", "dept_subset", "prov_subset")
generate byte estimate_success = ///
    support_ok == 1 & estimation_rc == 0
generate double robust_wald = ///
    (tau_bc / se_rb)^2 if estimate_success & se_rb > 0 & se_rb < .
generate byte positive_ci = ///
    estimate_success & ci_left > 0 & ci_left < .
generate byte strong_positive = ///
    estimate_success & tau_cl > 0 & robust_wald >= 20 & robust_wald < .
generate int effective_n = ///
    effective_left + effective_right if estimate_success

collapse ///
    (count) candidate_cells=candidate_n ///
    (sum) support_cells=support_ok ///
    (sum) successful_cells=estimate_success ///
    (sum) positive_ci_cells=positive_ci ///
    (sum) strong_positive_cells=strong_positive ///
    (p50) median_tau=tau_cl ///
    (max) max_tau=tau_cl ///
    (max) max_robust_wald=robust_wald ///
    (max) max_effective_n=effective_n, ///
    by(grid_scope cutoff treatment_year)

sort grid_scope cutoff treatment_year
isid grid_scope cutoff treatment_year
export delimited using ///
    "`table_dir'/rd_design_cutoff_year_summary.csv", ///
    replace
restore

preserve
keep if inlist(grid_scope, ///
    "broad_atlas", "dept_subset", "prov_subset")
generate byte estimate_success = ///
    support_ok == 1 & estimation_rc == 0
generate double robust_wald = ///
    (tau_bc / se_rb)^2 if estimate_success & se_rb > 0 & se_rb < .
generate int effective_n = ///
    effective_left + effective_right if estimate_success
keep if ///
    estimate_success & ///
    tau_cl > 0 & ///
    robust_wald < . & ///
    candidate_n >= 500 & ///
    effective_n >= 50 & ///
    clusters_left >= 20 & ///
    clusters_right >= 20
gsort ///
    grid_scope ///
    cutoff ///
    treatment_year ///
    -robust_wald ///
    -effective_n ///
    candidate_id
by grid_scope cutoff treatment_year: ///
    generate int frontier_rank = _n
keep if frontier_rank <= 10
order ///
    grid_scope ///
    cutoff ///
    treatment_year ///
    frontier_rank ///
    candidate_id ///
    candidate_label ///
    subset_size ///
    candidate_n ///
    effective_n ///
    clusters_left ///
    clusters_right ///
    tau_cl ///
    tau_bc ///
    se_rb ///
    p_rb ///
    ci_left ///
    ci_right ///
    robust_wald
sort grid_scope cutoff treatment_year frontier_rank
export delimited using ///
    "`table_dir'/rd_design_cutoff_year_frontier.csv", ///
    replace
restore

preserve
keep if ///
    grid_scope == "named" & ///
    candidate_id == "national_full" & ///
    treatment_year == 2012 & ///
    tie_rule == "score_as_recorded" & ///
    specification == "p1_mserd"
keep ///
    cutoff ///
    candidate_n ///
    analysis_n ///
    sign_conflicts ///
    rounding_band_n
sort cutoff
isid cutoff
export delimited using ///
    "`table_dir'/rd_design_tie_audit.csv", ///
    replace
restore

preserve
keep if !inlist(grid_scope, "dynamic", "support_sensitivity")
keep ///
    grid_scope ///
    candidate_id ///
    candidate_label ///
    candidate_type ///
    team_review_eligible ///
    subset_size ///
    candidate_n
duplicates drop
isid candidate_id
assert _N == 1391
sort candidate_type candidate_id
export delimited using ///
    "`table_dir'/rd_design_candidate_accounting.csv", ///
    replace
restore

/*
The scorecard retains every B--C candidate and every proposed outcome-linked
horizon. The robust Wald diagnostic is descriptive and does not adjust for
the subset search.
*/

tempfile candidate_scorecard

preserve
keep if ///
    !inlist(grid_scope, "dynamic", "support_sensitivity") & ///
    cutoff == "bc" & ///
    tie_rule == "drop_rounding_band" & ///
    specification == "p1_mserd"

generate double robust_wald = ///
    (tau_bc / se_rb)^2 if ///
    estimation_rc == 0 & se_rb > 0 & se_rb < .
generate int effective_n = ///
    effective_left + effective_right if estimation_rc == 0

keep ///
    grid_scope ///
    candidate_id ///
    candidate_label ///
    candidate_type ///
    team_review_eligible ///
    subset_size ///
    candidate_n ///
    treatment_year ///
    support_ok ///
    estimation_rc ///
    tau_cl ///
    tau_bc ///
    se_rb ///
    p_rb ///
    ci_left ///
    ci_right ///
    effective_n ///
    clusters_left ///
    clusters_right ///
    robust_wald

reshape wide ///
    support_ok ///
    estimation_rc ///
    tau_cl ///
    tau_bc ///
    se_rb ///
    p_rb ///
    ci_left ///
    ci_right ///
    effective_n ///
    clusters_left ///
    clusters_right ///
    robust_wald, ///
    i( ///
        grid_scope ///
        candidate_id ///
        candidate_label ///
        candidate_type ///
        team_review_eligible ///
        subset_size ///
        candidate_n) ///
    j(treatment_year)

foreach year in 2012 2016 2023 {
    generate byte complete_`year' = ///
        support_ok`year' == 1 & ///
        estimation_rc`year' == 0 & ///
        !missing( ///
            tau_cl`year', ///
            tau_bc`year', ///
            se_rb`year', ///
            p_rb`year', ///
            ci_left`year', ///
            ci_right`year', ///
            effective_n`year', ///
            robust_wald`year') & ///
        se_rb`year' > 0
}

generate byte complete_three_horizons = ///
    complete_2012 & complete_2016 & complete_2023
generate byte complete_early_mid = ///
    complete_2012 & complete_2016
generate byte positive_early_mid = ///
    complete_early_mid & ///
    tau_cl2012 > 0 & ///
    tau_cl2016 > 0
generate byte positive_ci_early_mid = ///
    complete_early_mid & ///
    ci_left2012 > 0 & ///
    ci_left2016 > 0
generate byte positive_three_horizons = ///
    complete_three_horizons & ///
    tau_cl2012 > 0 & ///
    tau_cl2016 > 0 & ///
    tau_cl2023 > 0
generate byte positive_ci_three_horizons = ///
    complete_three_horizons & ///
    ci_left2012 > 0 & ///
    ci_left2016 > 0 & ///
    ci_left2023 > 0

egen double min_tau_three_horizons = ///
    rowmin(tau_cl2012 tau_cl2016 tau_cl2023)
egen double min_wald_three_horizons = ///
    rowmin(robust_wald2012 robust_wald2016 robust_wald2023)
egen double max_p_three_horizons = ///
    rowmax(p_rb2012 p_rb2016 p_rb2023)
egen int min_effective_three_horizons = ///
    rowmin(effective_n2012 effective_n2016 effective_n2023)
egen int min_clusters_three_horizons = ///
    rowmin( ///
        clusters_left2012 clusters_right2012 ///
        clusters_left2016 clusters_right2016 ///
        clusters_left2023 clusters_right2023)

egen double min_tau_early_mid = ///
    rowmin(tau_cl2012 tau_cl2016)
egen double min_wald_early_mid = ///
    rowmin(robust_wald2012 robust_wald2016)
egen double max_p_early_mid = ///
    rowmax(p_rb2012 p_rb2016)
egen int min_effective_early_mid = ///
    rowmin(effective_n2012 effective_n2016)
egen int min_clusters_early_mid = ///
    rowmin( ///
        clusters_left2012 clusters_right2012 ///
        clusters_left2016 clusters_right2016)

foreach summary_var in ///
    min_tau_three_horizons ///
    min_wald_three_horizons ///
    max_p_three_horizons ///
    min_effective_three_horizons ///
    min_clusters_three_horizons {

    replace `summary_var' = . if !complete_three_horizons
}

foreach summary_var in ///
    min_tau_early_mid ///
    min_wald_early_mid ///
    max_p_early_mid ///
    min_effective_early_mid ///
    min_clusters_early_mid {

    replace `summary_var' = . if !complete_early_mid
}

generate byte strong_early_mid = ///
    positive_early_mid & ///
    min_wald_early_mid >= 20 & ///
    min_wald_early_mid < .
generate byte strong_three_horizons = ///
    positive_three_horizons & ///
    min_wald_three_horizons >= 20 & ///
    min_wald_three_horizons < .
generate byte strong_early_2012 = ///
    complete_2012 & ///
    tau_cl2012 > 0 & ///
    robust_wald2012 >= 20
generate byte strong_mid_2016 = ///
    complete_2016 & ///
    tau_cl2016 > 0 & ///
    robust_wald2016 >= 20
generate byte strong_late_2023 = ///
    complete_2023 & ///
    tau_cl2023 > 0 & ///
    robust_wald2023 >= 20

assert strong_early_2012 == 0 if !complete_2012
assert strong_mid_2016 == 0 if !complete_2016
assert strong_late_2023 == 0 if !complete_2023
assert strong_early_mid == 0 if !complete_early_mid
assert strong_three_horizons == 0 if !complete_three_horizons

generate double late_to_early_ratio = ///
    tau_cl2023 / tau_cl2012 if ///
    complete_three_horizons & tau_cl2012 > 0

generate str28 horizon_pattern = "incomplete"
replace horizon_pattern = "weak at all horizons" if ///
    complete_three_horizons & ///
    !strong_early_2012 & !strong_mid_2016 & !strong_late_2023
replace horizon_pattern = "early only" if ///
    complete_three_horizons & ///
    strong_early_2012 & !strong_mid_2016 & !strong_late_2023
replace horizon_pattern = "mid only" if ///
    complete_three_horizons & ///
    !strong_early_2012 & strong_mid_2016 & !strong_late_2023
replace horizon_pattern = "early and mid" if ///
    complete_three_horizons & ///
    strong_early_2012 & strong_mid_2016 & !strong_late_2023
replace horizon_pattern = "late only" if ///
    complete_three_horizons & ///
    !strong_early_2012 & !strong_mid_2016 & strong_late_2023
replace horizon_pattern = "other mixed pattern" if ///
    complete_three_horizons & ///
    horizon_pattern == "incomplete"
replace horizon_pattern = "strong at all horizons" if ///
    strong_three_horizons

order ///
    grid_scope ///
    candidate_id ///
    candidate_label ///
    candidate_type ///
    team_review_eligible ///
    subset_size ///
    candidate_n ///
    complete_2012 ///
    complete_2016 ///
    complete_2023 ///
    complete_early_mid ///
    positive_early_mid ///
    positive_ci_early_mid ///
    strong_early_mid ///
    min_tau_early_mid ///
    min_wald_early_mid ///
    max_p_early_mid ///
    min_effective_early_mid ///
    min_clusters_early_mid ///
    complete_three_horizons ///
    positive_three_horizons ///
    positive_ci_three_horizons ///
    strong_three_horizons ///
    horizon_pattern ///
    min_tau_three_horizons ///
    min_wald_three_horizons ///
    max_p_three_horizons ///
    min_effective_three_horizons ///
    min_clusters_three_horizons

sort ///
    team_review_eligible ///
    grid_scope ///
    subset_size ///
    candidate_id
compress
save "`candidate_scorecard'", replace

export delimited using ///
    "`table_dir'/rd_design_candidate_scorecard.csv", ///
    replace
restore

preserve
use "`candidate_scorecard'", clear
keep if grid_scope == "named"
sort candidate_id
export excel using ///
    "`table_dir'/rd_design_candidate_scorecard.xlsx", ///
    sheet("named_candidates") ///
    firstrow(variables) replace
restore

preserve
use "`candidate_scorecard'", clear
keep if grid_scope == "dept_subset"
sort subset_size candidate_id
export excel using ///
    "`table_dir'/rd_design_candidate_scorecard.xlsx", ///
    sheet("department_subsets", replace) ///
    firstrow(variables)
restore

preserve
use "`candidate_scorecard'", clear
keep if grid_scope == "prov_subset"
sort subset_size candidate_id
export excel using ///
    "`table_dir'/rd_design_candidate_scorecard.xlsx", ///
    sheet("vraem_province_subsets", replace) ///
    firstrow(variables)
restore

preserve
use "`candidate_scorecard'", clear
keep if grid_scope == "broad_atlas"
sort subset_size candidate_id
export excel using ///
    "`table_dir'/rd_design_candidate_scorecard.xlsx", ///
    sheet("broad_atlas", replace) ///
    firstrow(variables)
restore

preserve
use "`covariate_results'", clear
assert _N == 384
isid candidate_id cutoff outcome_var
assert inlist(support_ok, 0, 1)
assert missing(tau_cl) if support_ok == 0 | estimation_rc != 0
sort candidate_id cutoff outcome_var
compress
save "${qa_data_root}/rd_design_covariate_continuity.dta", ///
    replace
export delimited using ///
    "`table_dir'/rd_design_covariate_continuity.csv", ///
    replace
restore


*-----------------------------------*
**# 10. Academic figures and TeX tables
*-----------------------------------*

preserve
keep if ///
    grid_scope == "named" & ///
    candidate_id == "national_full" & ///
    tie_rule == "drop_rounding_band" & ///
    specification == "p1_mserd"
assert estimation_rc == 0

generate byte cutoff_order = ///
    cond(cutoff == "ab", 1, ///
    cond(cutoff == "bc", 2, ///
    cond(cutoff == "cd", 3, 4)))
generate double plot_x = cutoff_order
replace plot_x = plot_x - 0.18 if treatment_year == 2012
replace plot_x = plot_x + 0.18 if treatment_year == 2023

twoway ///
    (rcap ci_left ci_right plot_x if treatment_year == 2012, ///
        lcolor(navy%65) lwidth(thin)) ///
    (scatter tau_cl plot_x if treatment_year == 2012, ///
        mcolor(navy) msymbol(O) msize(medsmall)) ///
    (rcap ci_left ci_right plot_x if treatment_year == 2016, ///
        lcolor(teal%65) lwidth(thin)) ///
    (scatter tau_cl plot_x if treatment_year == 2016, ///
        mcolor(teal) msymbol(D) msize(medsmall)) ///
    (rcap ci_left ci_right plot_x if treatment_year == 2023, ///
        lcolor(maroon%65) lwidth(thin)) ///
    (scatter tau_cl plot_x if treatment_year == 2023, ///
        mcolor(maroon) msymbol(T) msize(medsmall)), ///
    xline(1.5 2.5 3.5, lcolor(gs14) lwidth(vthin)) ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    xlabel( ///
        1 "A-B" ///
        2 "B-C" ///
        3 "C-D" ///
        4 "D-E", ///
        labsize(small)) ///
    ylabel(, ///
        format(%4.2f) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    xtitle("Official victimization-index cutoff", size(small)) ///
    ytitle("Discontinuity in treatment probability", size(small)) ///
    title("National first-stage estimates across policy cutoffs", ///
        size(medium) color(black)) ///
    subtitle("Conservative exclusion of the half-rounding-unit band", ///
        size(small) color(gs5)) ///
    legend( ///
        order(2 "Treated by 2012" 4 "Treated by 2016" 6 "Treated by 2023") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado. Points are local-linear rdrobust estimates; bars are robust bias-corrected 95% confidence intervals." ///
        "Triangular-kernel estimates use MSE-optimal bandwidths, district-clustered inference, and mass-point adjustment. Adjacent categories only;" ///
        "observations with abs(centered score) <= 0.00005 are excluded because the four-decimal score cannot recover six-decimal assignment." ///
        "These diagnostics do not select a cutoff or sample. Source: RUV and CMAN register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(6.8) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_design_01_first_stage_horizons.png", ///
    width(2600) replace
restore

preserve
keep if ///
    grid_scope == "dynamic" & ///
    cutoff == "bc" & ///
    tie_rule == "score_as_recorded" & ///
    specification == "p1_mserd" & ///
    inlist(candidate_id, "national_full", "legacy_historical")
assert estimation_rc == 0

twoway ///
    (rcap ci_left ci_right treatment_year ///
        if candidate_id == "national_full", ///
        lcolor(navy%35) lwidth(vthin)) ///
    (connected tau_cl treatment_year ///
        if candidate_id == "national_full", ///
        lcolor(navy) lwidth(medthick) ///
        mcolor(navy) msymbol(O) msize(small)) ///
    (rcap ci_left ci_right treatment_year ///
        if candidate_id == "legacy_historical", ///
        lcolor(maroon%35) lwidth(vthin)) ///
    (connected tau_cl treatment_year ///
        if candidate_id == "legacy_historical", ///
        lcolor(maroon) lwidth(medthick) ///
        mcolor(maroon) msymbol(D) msize(small)), ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    xline(2012 2016, ///
        lcolor(gs10) lpattern(shortdash) lwidth(vthin)) ///
    xline(2023, ///
        lcolor(gs13) lpattern(dot) lwidth(vthin)) ///
    xlabel(2007(2)2023, labsize(small)) ///
    ylabel(, ///
        format(%4.2f) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    xtitle("Treatment status through year", size(small)) ///
    ytitle("B-C discontinuity in treatment probability", size(small)) ///
    title("Evolution of the B-C first stage", ///
        size(medium) color(black)) ///
    subtitle("National universe and exact legacy geographic benchmark", ///
        size(small) color(gs5)) ///
    legend( ///
        order(2 "National RUV universe" 4 "Legacy restricted geography") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado in categories B or C. Lines show local-linear rdrobust estimates; thin bars are robust 95% confidence intervals." ///
        "Triangular-kernel estimates use MSE-optimal bandwidths, district-clustered inference, mass-point adjustment, and the score exactly as recorded." ///
        "Vertical guides at 2012 and 2016 identify the outcome-linked reference horizons. The lighter 2023 guide is a rollout-catch-up diagnostic for the planned" ///
        "Census 2025 migration extension, not a geography-selection criterion. The legacy geography was selected by the team, not by this audit. Source: RUV and CMAN through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(11) ysize(6.8) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_design_02_dynamic_first_stage.png", ///
    width(2800) replace
restore

preserve
keep if ///
    grid_scope == "named" & ///
    tie_rule == "drop_rounding_band" & ///
    specification == "p1_mserd"
sort candidate_id cutoff treatment_year

tempname first_stage_table
file open `first_stage_table' ///
    using "`table_dir'/tab_rd_design_01_named_first_stages.tex", ///
    write replace text

file write `first_stage_table' "\begin{table}[!htbp]" _n
file write `first_stage_table' "\centering" _n
file write `first_stage_table' "\caption{National and historical first-stage discontinuities across policy cutoffs}" _n
file write `first_stage_table' "\label{tab:rd_design_named_first_stages}" _n
file write `first_stage_table' "\begin{tabular}{llrrrrr}" _n
file write `first_stage_table' "\toprule" _n
file write `first_stage_table' "Candidate & Cutoff & Treatment year & Estimate & Robust 95\% CI & Robust p-value & Effective N \\" _n
file write `first_stage_table' "\midrule" _n

foreach candidate_id in national_full legacy_historical {
    quietly levelsof candidate_label if ///
        candidate_id == "`candidate_id'", ///
        local(candidate_name) clean

    foreach cutoff in ab bc cd de {
        local cutoff_label = upper("`cutoff'")
        local cutoff_label = ///
            substr("`cutoff_label'", 1, 1) + "--" + ///
            substr("`cutoff_label'", 2, 1)

        foreach treatment_year in 2012 2016 2023 {
            quietly count if ///
                candidate_id == "`candidate_id'" & ///
                cutoff == "`cutoff'" & ///
                treatment_year == `treatment_year' & ///
                estimation_rc == 0

            local estimate_fmt "--"
            local ci_fmt "--"
            local p_fmt "--"
            local effective_fmt "--"

            if r(N) == 1 {
                quietly summarize tau_cl if ///
                    candidate_id == "`candidate_id'" & ///
                    cutoff == "`cutoff'" & ///
                    treatment_year == `treatment_year', meanonly
                local estimate_fmt : display %6.3f r(mean)

                quietly summarize ci_left if ///
                    candidate_id == "`candidate_id'" & ///
                    cutoff == "`cutoff'" & ///
                    treatment_year == `treatment_year', meanonly
                local ci_left_fmt : display %6.3f r(mean)

                quietly summarize ci_right if ///
                    candidate_id == "`candidate_id'" & ///
                    cutoff == "`cutoff'" & ///
                    treatment_year == `treatment_year', meanonly
                local ci_right_fmt : display %6.3f r(mean)
                local ci_fmt ///
                    "[`ci_left_fmt', `ci_right_fmt']"

                quietly summarize p_rb if ///
                    candidate_id == "`candidate_id'" & ///
                    cutoff == "`cutoff'" & ///
                    treatment_year == `treatment_year', meanonly
                local p_value = r(mean)
                if `p_value' < 0.0005 {
                    local p_fmt "\textless{}0.001"
                }
                else {
                    local p_fmt : display %6.3f `p_value'
                }

                quietly summarize effective_left if ///
                    candidate_id == "`candidate_id'" & ///
                    cutoff == "`cutoff'" & ///
                    treatment_year == `treatment_year', meanonly
                local effective_n = r(mean)
                quietly summarize effective_right if ///
                    candidate_id == "`candidate_id'" & ///
                    cutoff == "`cutoff'" & ///
                    treatment_year == `treatment_year', meanonly
                local effective_n = `effective_n' + r(mean)
                local effective_fmt : ///
                    display %9.0fc `effective_n'

                foreach formatted_value in ///
                    estimate_fmt ///
                    ci_left_fmt ///
                    ci_right_fmt ///
                    p_fmt ///
                    effective_fmt {

                    local `formatted_value' = ///
                        strtrim("``formatted_value''")
                }
                local ci_fmt ///
                    "[`ci_left_fmt', `ci_right_fmt']"
            }

            file write `first_stage_table' ///
                "`candidate_name' & `cutoff_label' & `treatment_year' & `estimate_fmt' & `ci_fmt' & `p_fmt' & `effective_fmt' \\" _n
        }
    }
}

file write `first_stage_table' "\bottomrule" _n
file write `first_stage_table' "\end{tabular}" _n
file write `first_stage_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The outcome is cumulative receipt of a collective-reparation project by the listed year. Estimates use the two RUV categories adjacent to each official cutoff. Local-linear triangular-kernel regressions use MSE-optimal bandwidths, mass-point adjustment, and district-clustered inference. The table excludes observations with an absolute centered score no greater than 0.00005 because the four-decimal RUV score cannot recover the six-decimal administrative threshold. Effective N is the total number of observations inside the selected left and right bandwidths. The legacy geography was selected by a separate research-team decision; this table does not select or change it. Source: RUV and CMAN register through 2023.}" _n
file write `first_stage_table' "\end{table}" _n
file close `first_stage_table'
restore

/*
Forest plot of the eleven declared candidates at the B--C cutoff. The figure
uses the 2012 and 2016 outcome-linked reference horizons and shows 2023 only
as a catch-up diagnostic, without ranking candidates.
*/

preserve
use "`candidate_scorecard'", clear
keep if grid_scope == "named"
assert _N == 11

generate byte candidate_order = .
replace candidate_order = 1 if candidate_id == "national_full"
replace candidate_order = 2 if candidate_id == "legacy_historical"
replace candidate_order = 3 if candidate_id == "legacy_department_core"
replace candidate_order = 4 if candidate_id == "vraem10_provinces"
replace candidate_order = 5 if candidate_id == "vraem8_no_ayacucho"
replace candidate_order = 6 if ///
    candidate_id == "vraem6_direct_provinces"
replace candidate_order = 7 if candidate_id == "vraem5_departments"
replace candidate_order = 8 if candidate_id == "vraem4_no_ayacucho"
replace candidate_order = 9 if candidate_id == "cvr6_departments"
replace candidate_order = 10 if candidate_id == "cvr5_no_ayacucho"
replace candidate_order = 11 if ///
    candidate_id == "conflict_belt7_departments"
assert !missing(candidate_order)

label define candidate_axis ///
    1 "National RUV" ///
    2 "Legacy geography" ///
    3 "Legacy department core" ///
    4 "VRAEM 10 provinces" ///
    5 "VRAEM 8, no Ayacucho" ///
    6 "VRAEM 6 direct provinces" ///
    7 "VRAEM 5 departments" ///
    8 "VRAEM 4, no Ayacucho" ///
    9 "CVR 6 departments" ///
    10 "CVR 5, no Ayacucho" ///
    11 "Combined 7-department belt"
label values candidate_order candidate_axis

reshape long ///
    estimation_rc ///
    tau_cl ///
    tau_bc ///
    se_rb ///
    p_rb ///
    ci_left ///
    ci_right ///
    effective_n ///
    clusters_left ///
    clusters_right ///
    robust_wald, ///
    i(candidate_id candidate_order) ///
    j(treatment_year)
keep if estimation_rc == 0

twoway ///
    (rcap ci_left ci_right candidate_order, ///
        horizontal lcolor(navy%55) lwidth(thin)) ///
    (scatter candidate_order tau_cl, ///
        mcolor(navy) msymbol(O) msize(small)), ///
    by(treatment_year, ///
        rows(1) ///
        title( ///
            "B-C first stages across predeclared geographic candidates", ///
            size(medium) color(black)) ///
        subtitle( ///
            "2012 and 2016 are outcome-linked references; 2023 shows rollout catch-up", ///
            size(small) color(gs5)) ///
        note( ///
            "Notes: Unit is the RUV centro poblado in categories B or C. Points are local-linear rdrobust estimates; bars are robust 95% confidence intervals." ///
            "All specifications use triangular kernels, MSE-optimal bandwidths, district-clustered inference, mass-point adjustment, and exclude the unresolved" ///
            "half-rounding-unit band. The 2023 panel is diagnostic; the approved legacy geography was selected outside this audit. Source: RUV, CMAN, INEI, and CVR.", ///
            size(vsmall) color(gs5) span) ///
        legend(off) ///
        graphregion(color(white))) ///
    yscale(reverse) ///
    ylabel(1(1)11, valuelabel angle(0) labsize(vsmall)) ///
    xline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    xlabel(, ///
        format(%4.2f) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    xtitle("Discontinuity in treatment probability", size(small)) ///
    ytitle("") ///
    legend(off) ///
    xsize(13) ysize(7.5) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_design_03_named_horizon_forest.png", ///
    width(3200) replace
restore

/*
Strength-versus-support plot. The log transform keeps very strong but
imprecisely comparable diagnostics from dominating the visual scale.
*/

preserve
use "`candidate_scorecard'", clear
keep if inlist(grid_scope, "named", "dept_subset")
keep if complete_early_mid

generate double log_min_wald = ///
    ln(1 + min_wald_early_mid)
generate str20 plot_label = ""
replace plot_label = "National" if candidate_id == "national_full"
replace plot_label = "Legacy" if candidate_id == "legacy_historical"
replace plot_label = "Legacy core" if ///
    candidate_id == "legacy_department_core"
replace plot_label = "Core + San Martin" if ///
    candidate_id == "conflict_dept_subset_073"

twoway ///
    (scatter log_min_wald min_effective_early_mid ///
        if grid_scope == "dept_subset", ///
        mcolor(gs11%55) msymbol(o) msize(vsmall)) ///
    (scatter log_min_wald min_effective_early_mid ///
        if candidate_id == "conflict_dept_subset_073", ///
        mcolor(maroon) msymbol(D) msize(medsmall) ///
        mlabel(plot_label) mlabcolor(maroon) mlabsize(vsmall) ///
        mlabposition(12)) ///
    (scatter log_min_wald min_effective_early_mid ///
        if grid_scope == "named", ///
        mcolor(navy) msymbol(O) msize(medsmall) ///
        mlabel(plot_label) mlabcolor(navy) mlabsize(vsmall) ///
        mlabposition(12)), ///
    yline(`=ln(21)', ///
        lcolor(maroon) lpattern(dash) lwidth(thin)) ///
    xlabel(, ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel( ///
        0 "0" ///
        `=ln(6)' "5" ///
        `=ln(11)' "10" ///
        `=ln(21)' "20" ///
        `=ln(51)' "50" ///
        `=ln(101)' "100", ///
        angle(0) labsize(small)) ///
    xtitle("Minimum effective N across 2012 and 2016", size(small)) ///
    ytitle("Minimum robust Wald-strength diagnostic", size(small)) ///
    title("Early and mid-period first-stage strength and support", ///
        size(medium) color(black)) ///
    subtitle( ///
        "Joint B-C performance for treatment through 2012 and 2016", ///
        size(small) color(gs5)) ///
    legend( ///
        order( ///
            1 "Bounded department subsets" ///
            2 "Post-search statistical frontier" ///
            3 "Predeclared candidates") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is the RUV centro poblado in categories B or C. The y-axis reports (bias-corrected estimate / robust SE)^2 on a log display scale;" ///
        "the dashed line marks the conservative value 20 heuristic, not a search-adjusted test. Effective N is the smaller total inside selected bandwidths" ///
        "across treatment-through-2012 and 2016 estimates. The labeled three-department frontier was identified after the search and is ineligible for selection." ///
        "Treatment through 2023 is a catch-up diagnostic. Subset results are diagnostic only. Source: RUV and CMAN register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(11) ysize(7.2) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_design_04_strength_support.png", ///
    width(2900) replace
restore

/*
The subset-size figure plots the department power set. Every official VRAEM
province subset has a zero qualifying share at the three displayed horizons,
which is stated directly rather than devoting a blank panel to that result.
*/

preserve
use "`candidate_scorecard'", clear
keep if inlist(grid_scope, "dept_subset", "prov_subset")

collapse ///
    (mean) ///
        strong_early_2012 ///
        strong_mid_2016 ///
        strong_late_2023 ///
        complete_three_horizons, ///
    by(grid_scope subset_size)

replace strong_early_2012 = 100 * strong_early_2012
replace strong_mid_2016 = 100 * strong_mid_2016
replace strong_late_2023 = 100 * strong_late_2023

assert strong_early_2012 == 0 if grid_scope == "prov_subset"
assert strong_mid_2016 == 0 if grid_scope == "prov_subset"
assert strong_late_2023 == 0 if grid_scope == "prov_subset"
keep if grid_scope == "dept_subset"

twoway ///
    (connected strong_early_2012 subset_size, ///
        lcolor(navy) lwidth(medthick) ///
        mcolor(navy) msymbol(O) msize(small)) ///
    (connected strong_mid_2016 subset_size, ///
        lcolor(teal) lwidth(medthick) ///
        mcolor(teal) msymbol(D) msize(small)) ///
    (connected strong_late_2023 subset_size, ///
        lcolor(gs8) lpattern(dash) lwidth(medium) ///
        mcolor(gs8) msymbol(T) msize(small)), ///
    title( ///
        "First-stage strength across the bounded department power set", ///
        size(medium) color(black)) ///
    subtitle( ///
        "All VRAEM province-subset shares are zero at the displayed horizons", ///
        size(small) color(gs5)) ///
    xlabel(1(1)7, labsize(small)) ///
    ylabel(0(5)15, ///
        format(%3.0f) grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    yscale(range(0 15)) ///
    xtitle("Number of departments in subset", size(small)) ///
    ytitle("Percent of subsets meeting strength heuristic", size(small)) ///
    legend( ///
        order(1 "Treated by 2012" 2 "Treated by 2016" 3 "2023 catch-up diagnostic") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is one of all 127 nonempty subsets of the seven-department CVR-VRAEM belt." ///
        "The 1,023 nonempty subsets of INEI's ten-province VRAEM envelope have a zero qualifying share" ///
        "at every subset size for 2012, 2016, and 2023. Estimates are local-linear rdrobust models at B-C" ///
        "with MSE-optimal bandwidths, district-clustered inference, mass-point adjustment, and the conservative" ///
        "score tie rule. A subset qualifies only with a positive estimate and robust Wald diagnostic of at least 20." ///
        "Shares are descriptive and search-unadjusted. Source: RUV and CMAN register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(7.2) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_design_05_subset_size.png", ///
    width(3200) replace
restore

/*
Compact named-candidate scorecard for review. The full raw estimates and all
subset diagnostics remain in the CSV and workbook outputs.
*/

preserve
use "`candidate_scorecard'", clear
keep if grid_scope == "named"
isid candidate_id

tempname scorecard_table
file open `scorecard_table' ///
    using "`table_dir'/tab_rd_design_02_candidate_scorecard.tex", ///
    write replace text

file write `scorecard_table' "\begin{table}[!htbp]" _n
file write `scorecard_table' "\centering" _n
file write `scorecard_table' "\scriptsize" _n
file write `scorecard_table' "\caption{B--C first-stage scorecard for predeclared geographic candidates}" _n
file write `scorecard_table' "\label{tab:rd_design_candidate_scorecard}" _n
file write `scorecard_table' "\begin{tabular}{lrrrrrrrl}" _n
file write `scorecard_table' "\toprule" _n
file write `scorecard_table' "Candidate & N & \(\widehat{\tau}_{2012}\) & \(W_{2012}\) & \(\widehat{\tau}_{2016}\) & \(W_{2016}\) & \(\widehat{\tau}_{2023}\) & \(W_{2023}\) & Pattern \\" _n
file write `scorecard_table' "\midrule" _n

foreach candidate_id of local candidate_ids {
    quietly levelsof candidate_label if ///
        candidate_id == "`candidate_id'", ///
        local(candidate_name) clean
    quietly summarize candidate_n if ///
        candidate_id == "`candidate_id'", meanonly
    local candidate_n_fmt : display %9.0fc r(mean)

    foreach year in 2012 2016 2023 {
        quietly summarize tau_cl`year' if ///
            candidate_id == "`candidate_id'", meanonly
        local tau_`year'_fmt "--"
        if r(N) == 1 & r(mean) < . {
            local tau_`year'_fmt : display %6.3f r(mean)
        }

        quietly summarize robust_wald`year' if ///
            candidate_id == "`candidate_id'", meanonly
        local wald_`year'_fmt "--"
        if r(N) == 1 & r(mean) < . {
            local wald_`year'_fmt : display %6.1f r(mean)
        }
    }

    quietly levelsof horizon_pattern if ///
        candidate_id == "`candidate_id'", ///
        local(pattern_name) clean

    foreach formatted_value in ///
        candidate_n_fmt ///
        tau_2012_fmt ///
        wald_2012_fmt ///
        tau_2016_fmt ///
        wald_2016_fmt ///
        tau_2023_fmt ///
        wald_2023_fmt {

        local `formatted_value' = ///
            strtrim("``formatted_value''")
    }

    file write `scorecard_table' ///
        "`candidate_name' & `candidate_n_fmt' & `tau_2012_fmt' & `wald_2012_fmt' & `tau_2016_fmt' & `wald_2016_fmt' & `tau_2023_fmt' & `wald_2023_fmt' & `pattern_name' \\" _n
}

file write `scorecard_table' "\bottomrule" _n
file write `scorecard_table' "\end{tabular}" _n
file write `scorecard_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The outcome is cumulative collective-reparation receipt through the listed year. Estimates use adjacent B and C communities, local-linear triangular-kernel regressions, MSE-optimal bandwidths, mass-point adjustment, district-clustered inference, and exclusion of the half-rounding-unit score band. \(W=(\widehat{\tau}_{bc}/SE_{robust})^2\) is a descriptive robust Wald-strength diagnostic; 20 is a conservative heuristic, not a search-adjusted critical value. Candidates were registered before the expanded run. The approved legacy geography was selected by a separate research-team decision; this table does not select or change it. Source: RUV and CMAN register through 2023.}" _n
file write `scorecard_table' "\end{table}" _n
file close `scorecard_table'
restore


*-----------------------------------*
**# 11. Output manifest and closeout
*-----------------------------------*

foreach output_path of local output_paths {
    capture quietly checksum "${project_root}/`output_path'"
    if _rc {
        display as error "Expected RD-design output was not created:"
        display as error "  ${project_root}/`output_path'"
        exit 603
    }
    assert r(filelen) > 100
}

local output_ids ///
    rd_design_named_csv ///
    rd_design_named_xlsx ///
    rd_design_dynamic_csv ///
    rd_design_atlas_csv ///
    rd_design_department_subsets_csv ///
    rd_design_vraem_province_subsets_csv ///
    rd_design_support_sensitivity_csv ///
    rd_design_cutoff_year_summary_csv ///
    rd_design_cutoff_year_frontier_csv ///
    rd_design_tie_csv ///
    rd_design_accounting_csv ///
    rd_design_candidate_scorecard_csv ///
    rd_design_candidate_scorecard_xlsx ///
    rd_design_covariate_continuity_csv ///
    tab_rd_design_01 ///
    tab_rd_design_02 ///
    fig_rd_design_01 ///
    fig_rd_design_02 ///
    fig_rd_design_03 ///
    fig_rd_design_04 ///
    fig_rd_design_05
local output_types ///
    table ///
    workbook ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    workbook ///
    table ///
    table ///
    table ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure
local output_specs ///
    named_candidate_first_stage_grid ///
    named_candidate_first_stage_workbook ///
    dynamic_treatment_year_first_stages ///
    geographic_first_stage_heterogeneity_atlas ///
    bounded_department_subset_first_stages ///
    bounded_vraem_province_subset_first_stages ///
    named_candidate_full_support_sensitivity ///
    all_cutoff_year_atlas_summary ///
    all_cutoff_year_supported_frontier ///
    rounded_score_cutoff_audit ///
    geographic_candidate_accounting ///
    bc_candidate_horizon_scorecard ///
    bc_candidate_horizon_scorecard_workbook ///
    baseline_covariate_continuity_audit ///
    named_candidate_first_stage_summary ///
    named_candidate_bc_scorecard ///
    national_cutoff_horizon_first_stages ///
    bc_dynamic_first_stage ///
    named_candidate_bc_horizon_forest ///
    strength_support_diagnostic ///
    subset_size_strength_diagnostic

local output_count : word count `output_paths'
assert `output_count' == 21
assert `output_count' == `: word count `output_ids''
assert `output_count' == `: word count `output_types''
assert `output_count' == `: word count `output_specs''

tempname manifest_handle
file open `manifest_handle' using "`rd_manifest'", ///
    write replace text
file write `manifest_handle' ///
    "output_id,relative_path,artifact_type,producing_script,input_snapshot,input_datasignature,unit_of_analysis,specification,stata_version,generation_date,stata_checksum,file_bytes,disclosure_status,selection_status" _n

forvalues output_index = 1/`output_count' {
    local output_path : word `output_index' of `output_paths'
    local output_id : word `output_index' of `output_ids'
    local output_type : word `output_index' of `output_types'
    local output_spec : word `output_index' of `output_specs'

    quietly checksum "${project_root}/`output_path'"
    local output_checksum : display %20.0f r(checksum)
    local output_bytes : display %20.0f r(filelen)
    local output_checksum = strtrim("`output_checksum'")
    local output_bytes = strtrim("`output_bytes'")

    file write `manifest_handle' ///
        `""`output_id'","`output_path'","`output_type'","code/stata/pipeline/03_validate_rd_design.do","07_community_registry_gdp.dta","`input_datasignature'","aggregate RD first-stage specification","`output_spec'","Stata `c(stata_version)'","`c(current_date)'","`output_checksum'","`output_bytes'","aggregate_internal_review","main_geography_selected_externally""' _n
}
file close `manifest_handle'

capture confirm file "`rd_manifest'"
assert !_rc
quietly checksum "`rd_manifest'"
assert r(filelen) > 500

use "${qa_data_root}/rd_design_first_stage_audit.dta", clear
quietly count if estimation_rc == 0
local successful_estimates = r(N)
quietly count if attempted == 0
local skipped_estimates = r(N)
quietly count if attempted == 1 & estimation_rc != 0
local failed_estimates = r(N)

display as result "RD design audit completed."
display as text "Specifications recorded: " _N
display as text "Successful estimates: `successful_estimates'"
display as text "Skipped for limited support: `skipped_estimates'"
display as text "Estimation failures retained: `failed_estimates'"
display as text "The audit did not create or alter the selected legacy geography."
display as text "Tables: `table_dir'"
display as text "Figures: `figure_dir'"
display as text "Manifest: `rd_manifest'"

capture program drop _vrd_first_stage
capture program drop _vrd_atlas_grid
capture program drop _vrd_covariate_test
log close victimasrd_rd_design
