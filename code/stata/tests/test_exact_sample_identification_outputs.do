/* Aggregate output contract; does not open observation-level data. */
version 19
preserve
import delimited using "${rd_table_dir}/rd_identification_precision_registry.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8) asdouble
assert _N == 1970
isid wave level outcome_id spec_id estimand
assert original_rc == estimation_rc
assert eligible_n == eligible_n_left + eligible_n_right
foreach side in left right {
    assert eligible_ccpp_`side' <= eligible_n_`side'
    assert eligible_dist_`side' <= eligible_ccpp_`side'
    assert eligible_scores_`side' <= eligible_ccpp_`side'
    assert n_`side' <= eligible_n_`side' if original_rc == 0
    assert audit_ccpp_`side' <= n_`side' if original_rc == 0
    assert bias_ccpp_`side' <= bias_n_`side' ///
        if original_rc == 0 & estimator == "rdrobust"
    assert bias_dist_`side' <= bias_ccpp_`side' ///
        if original_rc == 0 & estimator == "rdrobust"
    assert missing(bias_ccpp_`side') if estimator == "ivreg2"
}
assert kp_gate == 0 if receipt_effect & (missing(kp_f) | kp_f <= 10)
assert kp_gate == 1 if receipt_effect & kp_f > 10 & kp_f < . & ///
    estimation_rc == 0 & audit_rc == 0 & !missing(iv_effect, iv_se) & iv_se > 0
assert ar_components == 2 if ar_type == "disjoint"
assert ar_components == 0 if ar_type == "empty"
assert ar_low1 == .l & ar_high1 == .u if ar_type == "all_real"
assert ar_low1 < ar_high1 & !missing(ar_low1, ar_high1) if ar_type == "bounded"
assert ar_low1 == .l & ar_high2 == .u & ///
    !missing(ar_high1, ar_low2) & ar_high1 < ar_low2 if ar_type == "disjoint"
assert missing(ar_low2) & missing(ar_high2) if ar_components != 2
assert !missing(ar_p) & inrange(ar_p, 0, 1) if receipt_effect & ar_rc == 0
assert ar_scope == "Conventional local-IV analogue only" if receipt_effect
assert strpos(window_inference_scope, "Adaptive") == 0 ///
    if receipt_effect & bwselect == "manual"
assert strpos(window_inference_scope, "Outcome-adaptive") == 1 ///
    if receipt_effect & bwselect != "manual"
assert inrange(iv_effect, ar_low1, ar_high1) if ar_type == "bounded"
assert (iv_effect <= ar_high1 | iv_effect >= ar_low2) if ar_type == "disjoint"
quietly count if tier == "primary" & spec_id == "common_h_fuzzy"
assert r(N) == 48

import delimited using "${rd_table_dir}/rd_primary_precision.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8) asdouble
assert _N == 48
isid wave level outcome_id
bysort wave level: assert _N == 8
assert small_benchmark > 0 & small_benchmark < large_benchmark
assert abs(interval_width - (ci_high - ci_low)) < 1e-10
assert p_holm >= pvalue & p_holm <= 1 if !missing(p_holm, pvalue)
assert strpos(benchmark_status, "post-results") > 0

import delimited using "${metadata_root}/rd-identification-precision-output-manifest.csv", ///
    clear varnames(1) stringcols(_all) bindquote(strict) encoding(utf8)
assert _N == 7
isid path
assert review_status == "generated_unreviewed"
forvalues row = 1/`=_N' {
    local artifact = path[`row']
    local expected_checksum = real(checksum[`row'])
    quietly checksum "${project_root}/`artifact'"
    assert r(checksum) == `expected_checksum'
}
restore
display as result "Exact-sample identification output contract passed."
