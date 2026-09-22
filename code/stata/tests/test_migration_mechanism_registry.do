/*
Project: Victimas RD
Purpose: Validate the prespecified migration and mechanism analysis registry
*/

version 19
set more off

foreach required_global in project_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global not defined: `required_global'"
        exit 198
    }
}

local registry "${metadata_root}/rd-mechanisms/analysis-registry.csv"
capture confirm file "`registry'"
if _rc {
    exit 601
}

import delimited using "`registry'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)

isid analysis_id
assert _N == 62
assert inlist(wave, 2013, 2017)
assert inlist(level, "ccpp", "household", "individual")
assert inlist(evidence_class, ///
    "total_migration_effect", "mechanism_outcome_effect", ///
    "linkage_selection", "selection_sensitivity", ///
    "descriptive_association")

quietly count if evidence_class == "descriptive_association"
assert r(N) == 3
quietly count if evidence_class != "descriptive_association"
assert r(N) == 59

assert predictor_var != "" if evidence_class == "descriptive_association"
assert predictor_var == "" if evidence_class != "descriptive_association"
assert treatment_var == "treat_12" if wave == 2013
assert treatment_var == "treat_16" if wave == 2017

generate strL forbidden = lower(estimand_label)
assert strpos(forbidden, "acme") == 0
assert strpos(forbidden, "natural indirect") == 0
assert strpos(forbidden, "proportion mediated") == 0

display as result "PASS: migration mechanism registry satisfies contract."
