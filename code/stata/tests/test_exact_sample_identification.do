/* Synthetic tests only; run after the documented master environment. */
version 19
set more off

do "${code_root}/lib/04_exact_sample_audit.do"

preserve
clear
set obs 1200
set seed 18092018
generate long community = ceil(_n / 10)
generate long district = ceil(community / 2)
generate double score = runiform() * 2 - 1
generate byte above = score >= 0
generate double slope_right = score * above
generate double noise = rnormal()
generate double receipt = above + .2 * score + noise
generate double outcome = 2 * receipt + score + .4 * noise + rnormal()
generate double base_weight = .2 + runiform()
generate double kernel_weight = base_weight * ///
    (1 - cond(score < 0, abs(score) / .5, score / .75)) ///
    if inrange(score, -.5, .75)
quietly ivreg2 outcome score slope_right (receipt = above) ///
    [aw = kernel_weight] if inrange(score, -.5, .75), cluster(district)
local original = _b[receipt]
local original_n = e(N)
tempname reference_coefficient
scalar `reference_coefficient' = _b[receipt]
tempvar reference_sample
generate byte `reference_sample' = e(sample)

_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(district) cluster(district) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
    kernel(triangular) scale(1) baseweight(base_weight) fuzzy original(`original')
assert r(audit_rc) == 0 & r(ar_rc) == 0
assert r(iv_n) == `original_n'
assert abs(r(coefficient_gap)) < 1e-7
assert r(kp_f) > 10 & r(kp_f) < .
assert "`r(ar_type)'" == "bounded"
assert r(ar_low1) < 2 & r(ar_high1) > 2
assert _b[receipt] == scalar(`reference_coefficient')
assert e(sample) == `reference_sample'
assert _N == 1200

/* Separate slopes, quadratic terms and common covariates remain visible. */
generate double square = score^2
generate double square_right = square * above
generate double baseline_covariate = rnormal()
quietly ivreg2 outcome score slope_right square square_right baseline_covariate ///
    (receipt = above) [aw = kernel_weight] ///
    if inrange(score, -.5, .75), cluster(district)
local quadratic_original = _b[receipt]
quietly datasignature
local before_signature "`r(datasignature)'"
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(district) cluster(district) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(2) ///
    covariates(baseline_covariate) kernel(triangular) scale(1) ///
    baseweight(base_weight) fuzzy original(`quadratic_original')
assert r(audit_rc) == 0 & r(ar_rc) == 0
assert abs(r(coefficient_gap)) < 1e-7
quietly datasignature
assert "`r(datasignature)'" == "`before_signature'"

replace outcome = . in 1/20
quietly count if !missing(outcome) & inrange(score, -.5, .75)
local expected_n = r(N)
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(district) cluster(district) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
    kernel(triangular) scale(100) baseweight(base_weight) fuzzy
assert r(iv_n) == `expected_n'
assert r(ar_low1) < 200 & r(ar_high1) > 200

/* RED fixture: inclusive bounds gave 50 left rows; rdrobust uses 49 with
   a triangular kernel. Check both h/b endpoints against the locked command. */
clear
set obs 201
set seed 18092018
generate double score = (_n - 101) / 100
generate long community = _n
generate long district = ceil(_n / 5)
generate byte above = score >= 0
generate double slope_right = score * above
generate double receipt = above + rnormal()
generate double outcome = 2 * receipt + score + rnormal()
foreach kernel in triangular epanechnikov uniform {
    quietly rdrobust outcome score, fuzzy(receipt) h(.5 .75) b(.8 .9) ///
        kernel(`kernel') vce(cr1 community) masspoints(adjust)
    local expected_left = e(N_h_l)
    local expected_right = e(N_h_r)
    local expected_bias_left = e(N_b_l)
    local expected_bias_right = e(N_b_r)
    _vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
        community(community) district(district) cluster(community) ///
        hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
        kernel(`kernel') scale(1) fuzzy
    assert r(n_left) == `expected_left' & r(n_right) == `expected_right'
    assert r(bias_n_left) == `expected_bias_left' & r(bias_n_right) == `expected_bias_right'
    assert r(eligible_n_left) == 100 & r(eligible_n_right) == 101
    assert r(eligible_ccpp_left) == 100 & r(eligible_ccpp_right) == 101
    assert r(bias_ccpp_left) > r(ccpp_left)
    assert r(bias_dist_left) > r(dist_left)
    assert r(bias_scores_right) > r(scores_right)
}
generate double final_weight = 1 - ///
    cond(score < 0, abs(score) / .5, score / .75) if inrange(score, -.5, .75)
replace final_weight = 1e-8 if final_weight == 0
quietly ivreg2 outcome score slope_right (receipt = above) ///
    [aw = final_weight] if inrange(score, -.5, .75), cluster(community)
local endpoint_original = _b[receipt]
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(district) cluster(community) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
    kernel(triangular) scale(1) finalweight(final_weight) fuzzy ///
    original(`endpoint_original')
assert r(n_left) == 50 & r(n_right) == 76
assert missing(r(bias_ccpp_left), r(bias_dist_right))
assert abs(r(coefficient_gap)) < 1e-7

/* A failed official AR-estimator stage must be retained, not lose the row.
   This local failure stub changes no installed file and is always removed. */
capture program drop ivregress
program define ivregress
    exit 498
end
capture noisily _vrd_audit_exact_sample, outcome(outcome) running(score) ///
    treatment(receipt) community(community) district(district) cluster(community) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
    kernel(triangular) scale(1) fuzzy
local failure_helper_rc = _rc
local official_failure_rc = r(ar_rc)
local official_failure_type "`r(ar_type)'"
program drop ivregress
assert `failure_helper_rc' == 0 & `official_failure_rc' == 498
assert "`official_failure_type'" == "failed"
ereturn clear
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(district) cluster(community) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
    kernel(triangular) scale(1) fuzzy
assert "`e(cmd)'" == ""

/* A nearly irrelevant instrument must retain an unbounded confidence set. */
clear
set obs 1000
set seed 18092018
generate long community = ceil(_n / 10)
generate double score = rnormal()
generate byte above = score >= 0
generate double noise = rnormal()
generate double receipt = .000001 * above + score + noise
generate double outcome = 2 * receipt + score + noise + rnormal()
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(community) cluster(community) ///
    hleft(10) hright(10) bleft(10) bright(10) poly(1) ///
    kernel(uniform) scale(1) fuzzy
assert r(kp_f) < 10
assert inlist("`r(ar_type)'", "all_real", "disjoint", "unbounded")
assert "`r(status)'" == "iv_gate_failed"

/* Official disjoint AR sets are two rows by two columns, not one row
   with four columns. Preserve both rays and their infinite endpoints. */
clear
set obs 1200
set seed 18092018
generate long community = ceil(_n / 10)
generate double score = rnormal()
generate byte above = score >= 0
generate double slope = score * above
generate double receipt = .05 * above + rnormal()
generate double outcome = above + rnormal()
quietly ivregress 2sls outcome score slope (receipt = above), vce(cluster community)
quietly estat weakrobust, ci
tempname official_disjoint
matrix `official_disjoint' = r(ar_ci)
assert rowsof(`official_disjoint') == 2 & colsof(`official_disjoint') == 2
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(community) cluster(community) ///
    hleft(10) hright(10) bleft(10) bright(10) poly(1) ///
    kernel(uniform) scale(100) fuzzy
assert "`r(ar_type)'" == "disjoint" & r(ar_components) == 2
assert r(ar_low1) == .l & r(ar_high2) == .u
assert abs(r(ar_high1) - `official_disjoint'[1,2] * 100) < 1e-7
assert abs(r(ar_low2) - `official_disjoint'[2,1] * 100) < 1e-7

_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(community) cluster(community) ///
    hleft(.) hright(.) bleft(.) bright(.) poly(1) ///
    kernel(triangular) scale(1) fuzzy origrc(2001)
assert r(audit_rc) == 2001
assert "`r(status)'" == "original_fit_failed"

replace outcome = .
_vrd_audit_exact_sample, outcome(outcome) running(score) treatment(receipt) ///
    community(community) district(community) cluster(community) ///
    hleft(.5) hright(.75) bleft(.8) bright(.9) poly(1) ///
    kernel(triangular) scale(1) fuzzy
assert r(eligible_n) == 0 & r(iv_n) == .
assert r(audit_rc) != 0
assert "`r(status)'" == "iv_analogue_failed"
restore
display as result "Exact-sample identification synthetic checks passed."
