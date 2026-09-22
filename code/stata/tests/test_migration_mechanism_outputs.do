/*
Project: Victimas RD
Purpose: Validate generated migration and mechanism analysis artifacts
*/

version 19
set more off

foreach required_global in project_root tables_root figures_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global not defined: `required_global'"
        exit 198
    }
}

local table_dir "${tables_root}/rd_mechanisms"
local figure_dir "${figures_root}/rd_mechanisms"
local summary "`table_dir'/rd_migration_mechanism_summary.csv"
local supporting "`table_dir'/rd_migration_mechanism_supporting.csv"
local associations "`table_dir'/rd_migration_mechanism_associations.csv"
local contract "`table_dir'/rd_migration_mechanism_contract.csv"
local manifest "${metadata_root}/rd-mechanism-output-manifest.csv"

foreach required_file in ///
    "`summary'" "`supporting'" "`associations'" "`contract'" ///
    "`manifest'" {

    capture confirm file "`required_file'"
    if _rc {
        exit 601
    }
}

import delimited using "`summary'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid analysis_id
assert _N == 59
assert inlist(evidence_class, ///
    "total_migration_effect", "mechanism_outcome_effect", ///
    "linkage_selection", "selection_sensitivity")
assert reportable_late == 0 if ///
    estimand == "fuzzy_late" & ///
    (missing(first_stage_f) | first_stage_f <= 10)

quietly count if outcome_var == "moved_ccpp_2013_2017" & ///
    evidence_class == "total_migration_effect"
assert r(N) == 1
quietly count if outcome_var == "census2017_linked" & ///
    evidence_class == "linkage_selection"
assert r(N) == 1
quietly count if outcome_var == "cpv2017_link_rate" & ///
    evidence_class == "linkage_selection"
assert r(N) == 1
quietly count if inlist(outcome_var, ///
    "moved_or_not_linked_sens_2017", ///
    "moved_or_not_linked_zero_2017") & ///
    evidence_class == "selection_sensitivity"
assert r(N) == 2

generate strL forbidden = lower(estimand_label)
assert strpos(forbidden, "acme") == 0
assert strpos(forbidden, "natural indirect") == 0
assert strpos(forbidden, "proportion mediated") == 0
assert strpos(forbidden, "product") == 0

import delimited using "`supporting'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid analysis_id spec_id estimator
assert _N == 114
assert !missing(estimator)
assert estimator == "rdrobust" if spec_id == "common_h_reduced_form"
assert estimator == "ivreg2" if spec_id == "parametric_common_h"

import delimited using "`associations'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid analysis_id spec_id
assert _N == 6
assert estimand == "noncausal_association"
assert estimation_rc == 0
assert !missing(estimate, standard_error, pvalue, ci_low, ci_high)
bysort analysis_id: assert _N == 2
quietly count if spec_id == "descriptive_adjusted" & !missing(q_bh)
assert r(N) == 3
assert missing(q_bh) if spec_id == "descriptive_unadjusted"

import delimited using "`manifest'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 12
assert review_status == "generated_unreviewed"

foreach figure_name in ///
    fig_rd_mechanisms_01_migration_forest.png ///
    fig_rd_mechanisms_02_linkage_sensitivity.png ///
    fig_rd_mechanisms_03_mechanism_forest.png {

    quietly count if path == ///
        "output/figures/rd_mechanisms/`figure_name'"
    assert r(N) == 1
}

forvalues row = 1/`=_N' {
    local relative_path = path[`row']
    local artifact "${project_root}/`relative_path'"
    capture confirm file "`artifact'"
    if _rc {
        exit 601
    }
    quietly checksum "`artifact'"
    assert r(checksum) == checksum[`row']
}

display as result "PASS: migration and mechanism outputs satisfy contract."
