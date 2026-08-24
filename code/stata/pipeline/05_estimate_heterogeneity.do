/*
Project: Victimas RD
Purpose: Orchestrate prespecified RD treatment-effect heterogeneity analyses
Inputs:  Dropbox Coded analytical datasets and versioned registries
Outputs: Aggregate CSV/LaTeX results, figures, and output manifests in Git
*/

version 19
set more off


*-----------------------------------*
**# 1. Paths, inputs, and dependencies
*-----------------------------------*

foreach required_global in ///
    project_root pipeline_root analysis_data_root intermediate_root ///
    figures_root tables_root metadata_root logs_root {

    if `"${`required_global'}"' == "" {
        display as error "Required master global is not defined: `required_global'"
        display as error "Run code/stata/00_master.do before this module."
        exit 198
    }
}

local input_2013_ccpp ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta"
local input_2013_household ///
    "${analysis_data_root}/10_sisfoh_2013_household_analysis.dta"
local input_2013_individual ///
    "${analysis_data_root}/09_sisfoh_2013_individual_analysis.dta"
local project_registry ///
    "${intermediate_root}/03_cman_projects_2023.dta"
local outcome_registry ///
    "${metadata_root}/rd-outcomes/outcome-registry.csv"
local registry_13_hh ///
    "${metadata_root}/rd-outcomes/outcome-registry-2013-household.csv"
local registry_13_ind ///
    "${metadata_root}/rd-outcomes/outcome-registry-2013-individual.csv"
local moderator_registry ///
    "${metadata_root}/rd-heterogeneity/moderator-registry.csv"
local protocol ///
    "${project_root}/docs/RD_HETEROGENEITY_PROTOCOL.md"
local level_engine ///
    "${pipeline_root}/_heterogeneity_level_engine.do"
local module_2013_ccpp ///
    "${pipeline_root}/05a_sisfoh2013_ccpp_heterogeneity.do"
local module_2013_household ///
    "${pipeline_root}/05b_sisfoh2013_household_heterogeneity.do"
local module_2013_individual ///
    "${pipeline_root}/05c_sisfoh2013_individual_heterogeneity.do"

foreach required_file in ///
    "`input_2013_ccpp'" ///
    "`input_2013_household'" ///
    "`input_2013_individual'" ///
    "`project_registry'" ///
    "`outcome_registry'" ///
    "`registry_13_hh'" ///
    "`registry_13_ind'" ///
    "`moderator_registry'" ///
    "`protocol'" ///
    "`level_engine'" ///
    "`module_2013_ccpp'" ///
    "`module_2013_household'" ///
    "`module_2013_individual'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Required heterogeneity input was not found:"
        display as error "  `required_file'"
        exit 601
    }
}

foreach required_command in rdrobust rdhte rdhte_lincom ivreg2 {
    capture which `required_command'
    if _rc {
        display as error "Required Stata command is unavailable: `required_command'"
        display as error "Run the master dependency checks before estimation."
        exit 499
    }
}

capture noisily mata: mata mlib index
if _rc {
    display as error "Project-local Mata libraries could not be indexed."
    display as error "Run the master dependency checks before estimation."
    exit _rc
}


*-----------------------------------*
**# 2. Shared heterogeneity contract
*-----------------------------------*

global hte_input_2013_ccpp       "`input_2013_ccpp'"
global hte_input_2013_household  "`input_2013_household'"
global hte_input_2013_individual "`input_2013_individual'"
global hte_project_registry      "`project_registry'"
global hte_outcome_registry      "`outcome_registry'"
global hte_outcomes_13_hh  "`registry_13_hh'"
global hte_outcomes_13_ind "`registry_13_ind'"
global hte_moderator_registry    "`moderator_registry'"
global hte_level_engine          "`level_engine'"
global hte_figure_dir            "${figures_root}/rd_heterogeneity"
global hte_table_dir             "${tables_root}/rd_heterogeneity"
global hte_manifest_2013_ccpp ///
    "${metadata_root}/rd-heterogeneity-output-manifest-2013-ccpp.csv"
global hte_manifest_2013_household ///
    "${metadata_root}/rd-heterogeneity-output-manifest-2013-household.csv"
global hte_manifest_2013_individual ///
    "${metadata_root}/rd-heterogeneity-output-manifest-2013-individual.csv"
global hte_manifest_2013 ///
    "${metadata_root}/rd-heterogeneity-output-manifest-2013.csv"

global hte_running               "running_bc"
global hte_treatment_2013        "treat_12"
global hte_common_h              0.0075
global hte_common_b              0.0135
global hte_small_h               0.0050
global hte_large_h               0.0100
global hte_weak_f_gate           10
global hte_min_cell              10
global hte_primary_covariates ///
    "altitude_m_2017 ln_population_2007 wellbeing_core_2007"

local run_date = subinstr("`c(current_date)'", " ", "", .)
local run_time = subinstr("`c(current_time)'", ":", "", .)
global hte_run_id = lower("`run_date'_`run_time'")

capture mkdir "${hte_figure_dir}"
capture mkdir "${hte_table_dir}"

foreach output_directory in "${hte_figure_dir}" "${hte_table_dir}" {
    if !direxists("`output_directory'") {
        display as error "Unable to create heterogeneity output directory:"
        display as error "  `output_directory'"
        exit 603
    }
}


*-----------------------------------*
**# 3. Ordered heterogeneity modules
*-----------------------------------*

display as result "Starting SISFOH 2013 CCPP heterogeneity analysis."
do "`module_2013_ccpp'"
if _rc {
    display as error "SISFOH 2013 CCPP heterogeneity module failed."
    exit _rc
}

display as result "Starting SISFOH 2013 household heterogeneity analysis."
do "`module_2013_household'"
if _rc {
    display as error "SISFOH 2013 household heterogeneity module failed."
    exit _rc
}

display as result "Starting SISFOH 2013 individual heterogeneity analysis."
do "`module_2013_individual'"
if _rc {
    display as error "SISFOH 2013 individual heterogeneity module failed."
    exit _rc
}


*-----------------------------------*
**# 4. Orchestrator closeout
*-----------------------------------*

capture confirm file "${hte_manifest_2013_ccpp}"
if _rc {
    display as error "The CCPP heterogeneity manifest was not created."
    exit 603
}

foreach level_manifest in ///
    "${hte_manifest_2013_household}" ///
    "${hte_manifest_2013_individual}" {
    capture confirm file "`level_manifest'"
    if _rc {
        display as error "A SISFOH 2013 heterogeneity manifest was not created:"
        display as error "  `level_manifest'"
        exit 603
    }
}

import delimited using "${hte_manifest_2013_ccpp}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
tempfile combined_manifest
save `combined_manifest'

foreach level_manifest in ///
    "${hte_manifest_2013_household}" ///
    "${hte_manifest_2013_individual}" {
    import delimited using "`level_manifest'", ///
        clear varnames(1) bindquote(strict) encoding(utf8)
    append using `combined_manifest'
    save `combined_manifest', replace
}

isid path
sort path
quietly count
assert r(N) == 63
export delimited using "${hte_manifest_2013}", ///
    replace nolabel

display as result "Completed SISFOH 2013 heterogeneity modules."
display as text "Instrument-strength gate: minimum conditional F > ${hte_weak_f_gate}"
display as text "Aggregate manifest: ${hte_manifest_2013}"
