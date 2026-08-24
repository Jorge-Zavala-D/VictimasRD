/*
Project: Victimas RD
Purpose: Estimate prespecified SISFOH 2013 individual RD heterogeneity
Unit:    SISFOH person linked to an RUV centro poblado
Input:   09_sisfoh_2013_individual_analysis.dta (Dropbox Coded)
Outputs: Aggregate CSV/LaTeX results and publication-formatted figures in Git
*/

version 19
set more off

capture log close victimasrd_hte_2013_individual
log using "${logs_root}/hte_2013_individual_${hte_run_id}.smcl", ///
    name(victimasrd_hte_2013_individual) replace


*-----------------------------------*
**# 1. Input and constructed outcomes
*-----------------------------------*

use "${hte_input_2013_individual}", clear
quietly datasignature
local input_datasignature "`r(datasignature)'"

assert _N == 1425575
isid sisfoh_pid

local required_vars ///
    sisfoh_pid sisfoh_hhid ruv_id ubigeo_dist ///
    sample_main_rd victimization_level_source ///
    ${hte_running} ${hte_treatment_2013} ///
    age_2013 female_2013 secondaryplus_2013 ///
    employed_2013 labor_status_2013 ///
    insurance_any_2013 program_any_2013 program_juntos_2013 ///
    ln_population_2007 is_dist_capital_2017 ///
    deprivation_core_2007 ln1p_dist_dist_capital ///
    ihs_gdp_ccpp_2006 altitude_m_2017 ///
    ${hte_primary_covariates}

foreach required_var of local required_vars {
    confirm variable `required_var'
}

assert regexm(ruv_id, "^S[0-9]{8}$")
assert inlist(${hte_treatment_2013}, 0, 1) ///
    if !missing(${hte_treatment_2013})

generate byte age_15_29_outcome = ///
    inrange(age_2013, 15, 29) if !missing(age_2013)
generate byte worker_independent_2013 = ///
    labor_status_2013 == 2 ///
    if age_2013 >= 14 & !missing(labor_status_2013)

local primary_outcomes ///
    female_2013 ///
    age_15_29_outcome ///
    secondaryplus_2013 ///
    employed_2013 ///
    worker_independent_2013 ///
    insurance_any_2013 ///
    program_any_2013 ///
    program_juntos_2013

foreach outcome_var of local primary_outcomes {
    confirm variable `outcome_var'
}

generate byte hte_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")

quietly count if hte_bc_design
assert r(N) == 141679
quietly count if hte_bc_design & ///
    ((victimization_level_source == "B" & ${hte_running} < 0) | ///
     (victimization_level_source == "C" & ${hte_running} >= 0))
assert r(N) == 0
quietly count if hte_bc_design & ///
    missing(ruv_id, ubigeo_dist, ${hte_running}, ${hte_treatment_2013})
assert r(N) == 0

bysort ruv_id: assert ${hte_running} == ${hte_running}[1] ///
    if hte_bc_design
bysort ruv_id: assert ${hte_treatment_2013} == ///
    ${hte_treatment_2013}[1] if hte_bc_design

encode ruv_id, generate(hte_cluster_ruv)
encode ubigeo_dist, generate(hte_cluster_dist)
egen long hte_cluster_score = group(${hte_running})
generate byte hte_assignment = ${hte_running} >= 0 ///
    if !missing(${hte_running})

egen byte hte_primary_missing = rowmiss(`primary_outcomes') ///
    if hte_bc_design
generate byte hte_primary_sample = ///
    hte_bc_design & age_2013 >= 14 & hte_primary_missing == 0

quietly count if hte_primary_sample
assert r(N) == 98005
egen byte hte_primary_ruv_tag = tag(ruv_id) if hte_primary_sample
quietly count if hte_primary_ruv_tag
assert r(N) == 487

quietly count if hte_primary_sample & ///
    abs(${hte_running}) <= ${hte_common_h}
assert r(N) == 8870
egen byte hte_window_ruv_tag = tag(ruv_id) if ///
    hte_primary_sample & abs(${hte_running}) <= ${hte_common_h}
quietly count if hte_window_ruv_tag
assert r(N) == 65

keep if hte_bc_design
assert _N == 141679


*-----------------------------------*
**# 2. Level-specific analysis contract
*-----------------------------------*

global hte_level                    "individual"
global hte_level_caption            "individual-level"
global hte_unit_label               "SISFOH person age 14 or older"
global hte_unit_plural              "people"
global hte_observation_weight_id    "person_equal"
global hte_observation_weight_label "Person-equal"
global hte_outcome_registry_level   "${hte_outcomes_13_ind}"
global hte_applicable_moderators    "M01 M02 M03 S01 S02 S03 S04 S05"
global hte_expected_results         312
global hte_expected_support_rows    20
global hte_input_basename           "09_sisfoh_2013_individual_analysis.dta"
global hte_input_datasignature      "`input_datasignature'"
global hte_module_current           "code/stata/pipeline/05c_sisfoh2013_individual_heterogeneity.do"
global hte_manifest_current         "${hte_manifest_2013_individual}"
global hte_output_stub              "2013_individual"
global hte_primary_outcomes         "`primary_outcomes'"

do "${hte_level_engine}"
local engine_rc = _rc

if `engine_rc' {
    capture log close victimasrd_hte_2013_individual
    exit `engine_rc'
}

log close victimasrd_hte_2013_individual
