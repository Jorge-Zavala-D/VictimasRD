/*
Project: Victimas RD
Purpose: Validate Census 2017 household heterogeneity aggregate outputs
*/

version 19
set more off

foreach required_global in project_root tables_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global is not defined: `required_global'"
        exit 198
    }
}

local table_dir "${tables_root}/rd_heterogeneity"
local results "`table_dir'/rd_hte_2017_household_results.csv"
local support "`table_dir'/rd_hte_2017_household_support.csv"
local contract "`table_dir'/rd_hte_2017_household_analysis_contract.csv"
local manifest ///
    "${metadata_root}/rd-heterogeneity-output-manifest-2017-household.csv"

foreach required_file in ///
    "`results'" "`support'" "`contract'" "`manifest'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Missing Census 2017 household HTE output:"
        display as error "  `required_file'"
        exit 601
    }
}

import delimited using "`results'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

isid outcome_id moderator_id spec_id estimator
assert _N == 224

egen byte outcome_tag = tag(outcome_id)
quietly count if outcome_tag
assert r(N) == 8

egen byte moderator_tag = tag(moderator_id)
quietly count if moderator_tag
assert r(N) == 6

quietly count if estimator == "ivreg2" & spec_id == "common_h_iv"
assert r(N) == 48
assert weighting == "ccpp_equal" if ///
    estimator == "ivreg2" & spec_id == "common_h_iv"
assert cluster_rule == "ccpp" if ///
    estimator == "ivreg2" & spec_id == "common_h_iv"
assert missing(min_sw_f) if estimator == "ivreg2" & ///
    (missing(sw_f_treat) | missing(sw_f_interaction))
assert gate_pass == 0 if estimator == "ivreg2" & ///
    (missing(sw_f_treat) | missing(sw_f_interaction))
assert gate_pass == 0 if estimator == "rdhte"

import delimited using "`support'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

assert _N == 14
isid moderator_id side_label category_label

import delimited using "`contract'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

quietly count if component == "weighting" & value == "CCPP-equal"
assert r(N) == 1
quietly count if component == "inference" & value == "CCPP-clustered"
assert r(N) == 1
encode detail, generate(detail_id)
quietly summarize detail_id if component == "weighting", meanonly
scalar weighting_note_id = r(mean)
quietly summarize detail_id if component == "inference", meanonly
scalar inference_note_id = r(mean)
assert weighting_note_id != inference_note_id

import delimited using "`manifest'", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

isid path
assert _N == 17
assert review_status == "generated_unreviewed"

display as result ///
    "PASS: Census 2017 household heterogeneity outputs satisfy contract."
