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

local input_data ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta"
local outcome_registry ///
    "${metadata_root}/rd-outcomes/outcome-registry.csv"
local protocol ///
    "${project_root}/docs/RD_OUTCOME_ANALYSIS_PROTOCOL.md"
local outcome_module ///
    "${pipeline_root}/04a_sisfoh2013_ccpp.do"

foreach required_file in ///
    "`input_data'" ///
    "`outcome_registry'" ///
    "`protocol'" ///
    "`outcome_module'" {

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

global rd_input_2013_ccpp  "`input_data'"
global rd_outcome_registry "`outcome_registry'"
global rd_figure_dir       "${figures_root}/rd_outcomes"
global rd_table_dir        "${tables_root}/rd_outcomes"
global rd_manifest         "${metadata_root}/rd-outcome-output-manifest.csv"

global rd_running          "running_bc"
global rd_treatment_2013   "treat_12"
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
do "`outcome_module'"

if _rc {
    display as error "SISFOH 2013 CCPP outcome module failed."
    exit _rc
}


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
    "${rd_manifest}" {

    capture confirm file "`required_output'"
    if _rc {
        display as error "Expected outcome-analysis output was not created:"
        display as error "  `required_output'"
        exit 603
    }
}

display as result "Completed SISFOH 2013 CCPP outcome analysis."
display as text "Tables:  ${rd_table_dir}"
display as text "Figures: ${rd_figure_dir}"
display as text "Manifest: ${rd_manifest}"
