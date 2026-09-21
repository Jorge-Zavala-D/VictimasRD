/*
Project: Victimas RD
Purpose: Estimate prespecified Census 2017 household RD heterogeneity
Unit: INEI-assisted Census source household linked to an RUV centro poblado
Input: 13_census_2017_household_analysis.dta (Dropbox Coded)
Outputs: Aggregate CSV/LaTeX results and publication-formatted figures in Git
*/

version 19
set more off

capture log close victimasrd_hte_2017_household
log using "${logs_root}/hte_2017_household_${hte_run_id}.smcl", ///
    name(victimasrd_hte_2017_household) replace


*-----------------------------------*
**# 1. Input and complete primary sample
*-----------------------------------*

use "${hte_input_2017_household}", clear
quietly datasignature
local input_datasignature "`r(datasignature)'"

assert _N == 58021
isid census2017_baseline_hhid

local required_vars ///
    census2017_baseline_hhid ruv_id ubigeo_dist ///
    sample_main_rd victimization_level_source ///
    ${hte_running} ${hte_treatment_2017} ///
    hh_share_female_2017 hh_share_age_15_29_2017 ///
    hh_share_moved_ccpp_2017 hh_share_secondary_age14_2017 ///
    hh_share_employed_age14_2017 hh_share_insured_2017 ///
    hh_share_disability_2017 hh_wellbeing_core_2017 ///
    ln_population_2007 is_dist_capital_2017 ///
    deprivation_core_2007 ln1p_dist_dist_capital ///
    ihs_gdp_ccpp_2006 altitude_m_2017 ///
    ${hte_primary_covariates}

foreach required_var of local required_vars {
    confirm variable `required_var'
}

assert regexm(ruv_id, "^S[0-9]{8}$")
assert inlist(${hte_treatment_2017}, 0, 1) ///
    if !missing(${hte_treatment_2017})

local primary_outcomes ///
    hh_share_female_2017 ///
    hh_share_age_15_29_2017 ///
    hh_share_moved_ccpp_2017 ///
    hh_share_secondary_age14_2017 ///
    hh_share_employed_age14_2017 ///
    hh_share_insured_2017 ///
    hh_share_disability_2017 ///
    hh_wellbeing_core_2017

foreach outcome_var of local primary_outcomes {
    confirm variable `outcome_var'
}

generate byte hte_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")

quietly count if hte_bc_design
assert r(N) == 33066
quietly count if hte_bc_design & ///
    ((victimization_level_source == "B" & ${hte_running} < 0) | ///
     (victimization_level_source == "C" & ${hte_running} >= 0))
assert r(N) == 0
quietly count if hte_bc_design & ///
    missing(ruv_id, ubigeo_dist, ${hte_running}, ${hte_treatment_2017})
assert r(N) == 0

bysort ruv_id: assert ${hte_running} == ${hte_running}[1] ///
    if hte_bc_design
bysort ruv_id: assert ${hte_treatment_2017} == ///
    ${hte_treatment_2017}[1] if hte_bc_design

encode ruv_id, generate(hte_cluster_ruv)
encode ubigeo_dist, generate(hte_cluster_dist)
egen long hte_cluster_score = group(${hte_running})
generate byte hte_assignment = ${hte_running} >= 0 ///
    if !missing(${hte_running})

egen byte hte_primary_missing = rowmiss(`primary_outcomes') ///
    if hte_bc_design
generate byte hte_primary_sample = ///
    hte_bc_design & hte_primary_missing == 0

quietly count if hte_primary_sample
assert r(N) == 24877
egen byte hte_primary_ruv_tag = tag(ruv_id) if hte_primary_sample
quietly count if hte_primary_ruv_tag
assert r(N) == 406

quietly count if hte_primary_sample & ///
    abs(${hte_running}) <= ${hte_common_h}
assert r(N) == 2706
egen byte hte_window_ruv_tag = tag(ruv_id) if ///
    hte_primary_sample & abs(${hte_running}) <= ${hte_common_h}
quietly count if hte_window_ruv_tag
assert r(N) == 61

keep if hte_bc_design
assert _N == 33066


*-----------------------------------*
**# 2. Level-specific analysis contract
*-----------------------------------*

global hte_level                    "household"
global hte_sort_key                 "census2017_baseline_hhid"
global hte_level_caption            "household-level"
global hte_unit_label               "Census source household"
global hte_unit_plural              "households"
global hte_observation_weight_id    "household_equal"
global hte_observation_weight_label "Household-equal"
global hte_primary_weighting        "ccpp_equal"
global hte_primary_weighting_label  "CCPP-equal"
global hte_primary_cluster_var      "hte_cluster_ruv"
global hte_primary_cluster_rule     "ccpp"
global hte_primary_cluster_label    "CCPP-clustered"
global hte_primary_sensitivity_specs ///
    "small_h_iv large_h_iv common_h_observation_equal common_h_district_cluster common_h_score_cluster"
global hte_primary_weighting_note ///
    "Eligible observations share total weight one within each RUV community before triangular kernel weighting."
global hte_primary_inference_note ///
    "Primary IV and rdhte inference clusters by RUV community; district and score-mass clustering are sensitivities."
global hte_primary_design_note ///
    "Eligible observations share total weight one within each RUV community before triangular kernel weighting; primary inference clusters by RUV community."
global hte_primary_design_note_tex ///
    "Each community has total weight one; inference clusters by RUV community."
global hte_sensitivity_note_tex ///
    "Sensitivities add predetermined covariates, use smaller or larger fixed windows, give observations equal weight, or cluster by district or score mass point."
global hte_post_treatment_detail ///
    "Project type and financing are not ordinary moderators in household or individual outcome models."
global hte_treatment                "${hte_treatment_2017}"
global hte_moderator_var_column     "moderator_var_2017"
global hte_wave_label               "Census 2017"
global hte_source_note              "INEI-assisted Census 2017"
global hte_source_note_tex          "INEI-assisted Census 2017"
global hte_treatment_timing_label ///
    "Cumulative collective-reparation receipt through 2016 for Census 2017 outcomes."
global hte_person_source_label      "INEI-assisted Census 2017 people"
global hte_outcome_registry_level   "${hte_outcomes_17_hh}"
global hte_applicable_moderators    "M01 M02 S01 S02 S03 S05"
global hte_expected_results         224
global hte_expected_support_rows    14
global hte_input_basename           "13_census_2017_household_analysis.dta"
global hte_input_datasignature      "`input_datasignature'"
global hte_module_current           "code/stata/pipeline/05e_census2017_household_heterogeneity.do"
global hte_manifest_current         "${hte_manifest_2017_household}"
global hte_output_stub              "2017_household"
global hte_primary_outcomes         "`primary_outcomes'"

do "${hte_level_engine}"
local engine_rc = _rc

if `engine_rc' {
    capture log close victimasrd_hte_2017_household
    exit `engine_rc'
}

log close victimasrd_hte_2017_household
