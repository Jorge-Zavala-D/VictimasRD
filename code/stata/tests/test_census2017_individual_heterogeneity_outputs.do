/*
Project: Victimas RD
Purpose: Validate Census 2017 individual heterogeneity aggregate outputs
*/

version 19
set more off

foreach required_global in project_root tables_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global not defined: `required_global'"
        exit 198
    }
}

local table_dir "${tables_root}/rd_heterogeneity"
local results "`table_dir'/rd_hte_2017_individual_results.csv"
local support "`table_dir'/rd_hte_2017_individual_support.csv"
local contract "`table_dir'/rd_hte_2017_individual_analysis_contract.csv"
local manifest ///
    "${metadata_root}/rd-heterogeneity-output-manifest-2017-individual.csv"

foreach required_file in ///
    "`results'" "`support'" "`contract'" "`manifest'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Missing Census 2017 individual HTE output:"
        display as error "  `required_file'"
        exit 601
    }
}

import delimited using "`results'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

isid outcome_id moderator_id spec_id estimator
assert _N == 312

egen byte outcome_tag = tag(outcome_id)
quietly count if outcome_tag
assert r(N) == 8

egen byte moderator_tag = tag(moderator_id)
quietly count if moderator_tag
assert r(N) == 8

quietly count if estimator == "ivreg2" & spec_id == "common_h_iv"
assert r(N) == 64
assert weighting == "ccpp_equal" if ///
    estimator == "ivreg2" & spec_id == "common_h_iv"
assert cluster_rule == "ccpp" if ///
    estimator == "ivreg2" & spec_id == "common_h_iv"
assert missing(min_sw_f) if estimator == "ivreg2" & ///
    (missing(sw_f_treat) | missing(sw_f_interaction))
assert gate_pass == 0 if estimator == "ivreg2" & ///
    (missing(sw_f_treat) | missing(sw_f_interaction))

/* The female-moderator first stage uses one fixed person sample within each
specification, so its diagnostics and gate cannot vary by outcome. Identified
models must report both rank-aware conditional F statistics. */
preserve
    keep if moderator_id == "M03" & estimator == "ivreg2" & ///
        gate_status != "not_applicable_identity"
    foreach diagnostic in sw_f_treat sw_f_interaction min_sw_f gate_pass {
        bysort spec_id (outcome_id): ///
            assert `diagnostic' == `diagnostic'[1]
    }
    assert !missing(sw_f_treat, sw_f_interaction, min_sw_f) if ///
        support_pass == 1 & underid_p < .05
restore

quietly count if moderator_id == "M03" & outcome_id == "I01" & ///
    gate_status == "not_applicable_identity"
assert r(N) == 8

import delimited using "`support'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
assert _N == 20
isid moderator_id side_label category_label

import delimited using "`contract'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
assert _N == 12
quietly count if component == "weighting" & ///
    value == "CCPP-equal" & status == "approved"
assert r(N) == 1
quietly count if component == "inference" & ///
    value == "CCPP-clustered" & status == "approved"
assert r(N) == 1

import delimited using "`manifest'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
isid path
assert _N == 20
assert review_status == "generated_unreviewed"

display as result ///
    "PASS: Census 2017 individual heterogeneity outputs satisfy contract."
