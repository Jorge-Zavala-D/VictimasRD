/*
Project: Victimas RD
Purpose: Orchestrate versioned outcome modules and common RD checks
Inputs:  Dropbox Coded analytical datasets and versioned outcome metadata
Outputs: Aggregate model results, LaTeX tables, figures, and output manifest
*/

version 19
set more off


*-----------------------------------*
**# 1. Common path and dependency checks
*-----------------------------------*

foreach required_global in ///
    project_root pipeline_root analysis_data_root ///
    figures_root tables_root metadata_root logs_root {

    if `"${`required_global'}"' == "" {
        display as error "Required master global is not defined: `required_global'"
        display as error "Run code/stata/00_master.do before this module."
        exit 198
    }
}

local input_ccpp ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta"
local input_household ///
    "${analysis_data_root}/10_sisfoh_2013_household_analysis.dta"
local input_individual ///
    "${analysis_data_root}/09_sisfoh_2013_individual_analysis.dta"
local input_2017_ccpp ///
    "${analysis_data_root}/14_community_registry_census_2017.dta"
local input_2017_household ///
    "${analysis_data_root}/13_census_2017_household_analysis.dta"
local input_2017_individual ///
    "${analysis_data_root}/12_census_2017_individual_analysis.dta"
local outcome_registry_ccpp ///
    "${metadata_root}/rd-outcomes/outcome-registry.csv"
local outcome_registry_household ///
    "${metadata_root}/rd-outcomes/outcome-registry-2013-household.csv"
local outcome_registry_individual ///
    "${metadata_root}/rd-outcomes/outcome-registry-2013-individual.csv"
local outcome_registry_2017_ccpp ///
    "${metadata_root}/rd-outcomes/outcome-registry-2017-ccpp.csv"
local outcome_registry_2017_household ///
    "${metadata_root}/rd-outcomes/outcome-registry-2017-household.csv"
local outcome_registry_2017_individual ///
    "${metadata_root}/rd-outcomes/outcome-registry-2017-individual.csv"
local protocol ///
    "${project_root}/docs/RD_OUTCOME_ANALYSIS_PROTOCOL.md"
local outcome_module_ccpp ///
    "${pipeline_root}/04a_sisfoh2013_ccpp.do"
local outcome_module_household ///
    "${pipeline_root}/04b_sisfoh2013_household.do"
local outcome_module_individual ///
    "${pipeline_root}/04c_sisfoh2013_individual.do"
local outcome_module_2017_ccpp ///
    "${pipeline_root}/04d_census2017_ccpp.do"
local outcome_module_2017_household ///
    "${pipeline_root}/04e_census2017_household.do"
local outcome_module_2017_individual ///
    "${pipeline_root}/04f_census2017_individual.do"

foreach required_file in ///
    "`input_ccpp'" ///
    "`input_household'" ///
    "`input_individual'" ///
    "`input_2017_ccpp'" ///
    "`input_2017_household'" ///
    "`input_2017_individual'" ///
    "`outcome_registry_ccpp'" ///
    "`outcome_registry_household'" ///
    "`outcome_registry_individual'" ///
    "`outcome_registry_2017_ccpp'" ///
    "`outcome_registry_2017_household'" ///
    "`outcome_registry_2017_individual'" ///
    "`protocol'" ///
    "`outcome_module_ccpp'" ///
    "`outcome_module_household'" ///
    "`outcome_module_individual'" ///
    "`outcome_module_2017_ccpp'" ///
    "`outcome_module_2017_household'" ///
    "`outcome_module_2017_individual'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Required outcome-analysis input was not found:"
        display as error "  `required_file'"
        exit 601
    }
}

foreach required_command in rdrobust rdplot ivreg2 boottest {
    capture which `required_command'
    if _rc {
        display as error "Required Stata command is unavailable: `required_command'"
        display as error "Run the master dependency checks before estimation."
        exit 499
    }
}


*-----------------------------------*
**# 2. Shared analysis contract
*-----------------------------------*

/*
The common window is selected from the treatment assignment design, not from
substantive outcomes. It is deliberately named a design bandwidth because a
single value cannot be MSE-optimal for outcomes with different curvature and
variance. Outcome-specific selectors are sensitivity branches only.
*/

global rd_input_2013_ccpp       "`input_ccpp'"
global rd_input_2013_household  "`input_household'"
global rd_input_2013_individual "`input_individual'"
global rd_input_2017_ccpp       "`input_2017_ccpp'"
global rd_input_2017_household  "`input_2017_household'"
global rd_input_2017_individual "`input_2017_individual'"
global rd_outcome_registry      "`outcome_registry_ccpp'"
global rd_household_outcome_registry ///
    "`outcome_registry_household'"
global rd_individual_outcome_registry ///
    "`outcome_registry_individual'"
global rd_registry_2017_ccpp ///
    "`outcome_registry_2017_ccpp'"
global rd_registry_2017_hh ///
    "`outcome_registry_2017_household'"
global rd_registry_2017_ind ///
    "`outcome_registry_2017_individual'"
global rd_figure_dir            "${figures_root}/rd_outcomes"
global rd_table_dir             "${tables_root}/rd_outcomes"
global rd_manifest              ///
    "${metadata_root}/rd-outcome-output-manifest.csv"
global rd_household_manifest    ///
    "${metadata_root}/rd-outcome-output-manifest-2013-household.csv"
global rd_individual_manifest   ///
    "${metadata_root}/rd-outcome-output-manifest-2013-individual.csv"
global rd_2017_ccpp_manifest ///
    "${metadata_root}/rd-outcome-output-manifest-2017-ccpp.csv"
global rd_2017_household_manifest ///
    "${metadata_root}/rd-outcome-output-manifest-2017-household.csv"
global rd_2017_individual_manifest ///
    "${metadata_root}/rd-outcome-output-manifest-2017-individual.csv"

global rd_running          "running_bc"
global rd_treatment_2013   "treat_12"
global rd_treatment_2017   "treat_16"
global rd_common_h         0.0075
global rd_common_b         0.0135
global rd_small_h          0.0050
global rd_small_b          0.0090
global rd_large_h          0.0100
global rd_large_b          0.0180
global rd_weak_f_gate      20
global rd_primary_covariates ///
    "altitude_m_2017 ln_population_2007 wellbeing_core_2007"

local run_date = subinstr("`c(current_date)'", " ", "", .)
local run_time = subinstr("`c(current_time)'", ":", "", .)
global rd_run_id = lower("`run_date'_`run_time'")

capture mkdir "${rd_figure_dir}"
capture mkdir "${rd_table_dir}"

foreach output_directory in "${rd_figure_dir}" "${rd_table_dir}" {
    if !direxists("`output_directory'") {
        display as error "Unable to create outcome output directory:"
        display as error "  `output_directory'"
        exit 603
    }
}


*-----------------------------------*
**# 3. Ordered outcome modules
*-----------------------------------*

display as result "Starting SISFOH 2013 CCPP outcome analysis."
do "`outcome_module_ccpp'"

if _rc {
    display as error "SISFOH 2013 CCPP outcome module failed."
    exit _rc
}

display as result "Starting SISFOH 2013 household outcome analysis."
do "`outcome_module_household'"

if _rc {
    display as error "SISFOH 2013 household outcome module failed."
    exit _rc
}

display as result "Starting SISFOH 2013 individual outcome analysis."
do "`outcome_module_individual'"

if _rc {
    display as error "SISFOH 2013 individual outcome module failed."
    exit _rc
}

display as result "Starting Census 2017 CCPP outcome analysis."
do "`outcome_module_2017_ccpp'"

if _rc {
    display as error "Census 2017 CCPP outcome module failed."
    exit _rc
}

display as result "Starting Census 2017 household outcome analysis."
do "`outcome_module_2017_household'"

if _rc {
    display as error "Census 2017 household outcome module failed."
    exit _rc
}

display as result "Starting Census 2017 individual outcome analysis."
do "`outcome_module_2017_individual'"

if _rc {
    display as error "Census 2017 individual outcome module failed."
    exit _rc
}

tempfile ccpp_output_manifest
import delimited using "${rd_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
save "`ccpp_output_manifest'", replace

import delimited using "${rd_household_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
append using "`ccpp_output_manifest'"
tempfile ccpp_household_output_manifest
save "`ccpp_household_output_manifest'", replace

import delimited using "${rd_individual_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
append using "`ccpp_household_output_manifest'"
isid path
assert _N == 57
sort path
export delimited using "${rd_manifest}", replace nolabel

tempfile outcomes_2013_manifest outcomes_2017_ccpp_manifest ///
    outcomes_2017_household_manifest
import delimited using "${rd_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
save "`outcomes_2013_manifest'", replace

import delimited using "${rd_2017_ccpp_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
save "`outcomes_2017_ccpp_manifest'", replace

import delimited using "${rd_2017_household_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
save "`outcomes_2017_household_manifest'", replace

import delimited using "${rd_2017_individual_manifest}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
append using "`outcomes_2017_household_manifest'" ///
    "`outcomes_2017_ccpp_manifest'" ///
    "`outcomes_2013_manifest'"
isid path
assert _N == 117
sort path
export delimited using "${rd_manifest}", replace nolabel


*-----------------------------------*
**# 4. Orchestrator closeout
*-----------------------------------*

foreach required_output in ///
    "${rd_table_dir}/rd_2013_ccpp_results.csv" ///
    "${rd_table_dir}/rd_2013_ccpp_analysis_contract.csv" ///
    "${rd_table_dir}/tab_rd_outcomes_01_registry.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_02_first_stage.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_03_main_2013_ccpp.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_04_secondary_2013_ccpp.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_05_robustness_2013_ccpp.tex" ///
    "${rd_figure_dir}/fig_rd_outcomes_01_first_stage_2012.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_02_primary_panels_2013_ccpp.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_03_late_forest_2013_ccpp.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_04_bandwidth_sensitivity_2013_ccpp.png" ///
    "${rd_table_dir}/rd_2013_household_results.csv" ///
    "${rd_table_dir}/rd_2013_household_analysis_contract.csv" ///
    "${rd_table_dir}/tab_rd_outcomes_06_registry_2013_household.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_07_sample_first_stage_2013_household.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_08_main_2013_household.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_09_secondary_2013_household.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_10_robustness_2013_household.tex" ///
    "${rd_figure_dir}/fig_rd_outcomes_05_first_stage_2012_household.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_06_primary_panels_2013_household.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_07_late_forest_2013_household.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_08_bandwidth_sensitivity_2013_household.png" ///
    "${rd_table_dir}/rd_2013_individual_results.csv" ///
    "${rd_table_dir}/rd_2013_individual_analysis_contract.csv" ///
    "${rd_table_dir}/tab_rd_outcomes_11_registry_2013_individual.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_12_sample_first_stage_2013_individual.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_13_main_2013_individual.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_14_secondary_2013_individual.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_15_robustness_2013_individual.tex" ///
    "${rd_figure_dir}/fig_rd_outcomes_09_first_stage_2012_individual.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_10_primary_panels_2013_individual.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_11_late_forest_2013_individual.png" ///
    "${rd_figure_dir}/fig_rd_outcomes_12_bandwidth_sensitivity_2013_individual.png" ///
    "${rd_household_manifest}" ///
    "${rd_individual_manifest}" ///
    "${rd_2017_ccpp_manifest}" ///
    "${rd_2017_household_manifest}" ///
    "${rd_2017_individual_manifest}" ///
    "${rd_table_dir}/rd_2017_ccpp_results.csv" ///
    "${rd_table_dir}/rd_2017_household_results.csv" ///
    "${rd_table_dir}/rd_2017_individual_results.csv" ///
    "${rd_table_dir}/tab_rd_outcomes_31_linkage_2017_ccpp.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_32_linkage_2017_household.tex" ///
    "${rd_table_dir}/tab_rd_outcomes_33_linkage_2017_individual.tex" ///
    "${rd_manifest}" {

    capture confirm file "`required_output'"
    if _rc {
        display as error "Expected outcome-analysis output was not created:"
        display as error "  `required_output'"
        exit 603
    }
}

display as result "Completed SISFOH 2013 and Census 2017 outcome analysis at all three levels."
display as text "Tables:  ${rd_table_dir}"
display as text "Figures: ${rd_figure_dir}"
display as text "Manifest: ${rd_manifest}"
