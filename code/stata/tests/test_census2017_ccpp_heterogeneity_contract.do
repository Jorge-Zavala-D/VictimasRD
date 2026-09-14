/*
Project: Victimas RD
Purpose: Guard the Census 2017 CCPP heterogeneity module and its shared-engine
         inference contract before the module is admitted to orchestration
*/

version 19
set more off

local module_path ///
    "${project_root}/code/stata/pipeline/05d_census2017_ccpp_heterogeneity.do"
local orchestrator_path ///
    "${project_root}/code/stata/pipeline/05_estimate_heterogeneity.do"
local engine_path ///
    "${project_root}/code/stata/pipeline/_heterogeneity_level_engine.do"

foreach required_file in ///
    "`module_path'" ///
    "`orchestrator_path'" ///
    "`engine_path'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Required Census 2017 CCPP HTE file was not found:"
        display as error "  `required_file'"
        exit 601
    }
}

mata:
void require_tokens(string scalar path, string rowvector tokens)
{
    real scalar handle, index, failed
    string scalar line, source

    handle = fopen(path, "r")
    if (handle < 0) {
        errprintf("Unable to read contract source: %s\n", path)
        _error(601)
    }

    source = ""
    while ((line = fget(handle)) != J(0, 0, "")) {
        source = source + line + char(10)
    }
    fclose(handle)

    failed = 0
    for (index = 1; index <= cols(tokens); index++) {
        if (strpos(source, tokens[index]) == 0) {
            errprintf("Required contract token is absent from %s: %s\n", ///
                path, tokens[index])
            failed = 1
        }
    }

    if (failed) _error(9)
}

require_tokens(st_local("module_path"), ///
    (char(36) + "{hte_input_2017_ccpp}", ///
     char(36) + "{hte_treatment_2017}", ///
     "moderator_var_2017", "14_community_registry_census_2017.dta", ///
     "census2017_cohort_covered", "district", ///
     "outcome-registry-2017-ccpp.csv", ///
     "recorded_project_year <= 2016", ///
     "rd_hte_2017_ccpp_project_composition.csv", ///
     "rd_hte_2017_ccpp_project_discontinuities.csv", ///
     "rd_hte_2017_ccpp_financing_dose_iv.csv", ///
     "adjusted_pvalue", "Benjamini--Hochberg"))

require_tokens(st_local("orchestrator_path"), ///
    ("05d_census2017_ccpp_heterogeneity.do", ///
     "rd-heterogeneity-output-manifest-2017-ccpp.csv", ///
     "outcome-registry-2017-ccpp.csv", ///
     "capture estimates clear", "capture ereturn clear", ///
     "capture matrix drop _all"))

require_tokens(st_local("engine_path"), ///
    (char(36) + "{hte_primary_weighting}", ///
     char(36) + "{hte_primary_weighting_note}", ///
     char(36) + "{hte_primary_cluster_var}", ///
     char(36) + "{hte_primary_cluster_rule}", ///
     char(36) + "{hte_primary_inference_note}", ///
     char(36) + "{hte_primary_sensitivity_specs}", ///
     "local diagnostic_tick", "over(moderator_value"))
end

display as result ///
    "PASS: Census 2017 CCPP heterogeneity contract is wired correctly."
