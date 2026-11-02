/* Focused reproduction of the 32 unweighted 2013 primary sensitivity fits.
   Repairs the new audit's disjoint-set export, not any original model result.
   Run after the master environment and module 04; see the dated audit record.
   Future full module-04 runs use the corrected shared parser directly. */
version 19
set more off
do "${code_root}/lib/04_exact_sample_audit.do"

preserve
tempfile reproduced_sets
tempname set_post
postfile `set_post' int wave str12 level str12 outcome_id str40 spec_id ///
    str24 estimand long check_n double check_effect check_kp check_ar_p ///
    str20 corrected_type byte corrected_components ///
    double corrected_low1 corrected_high1 corrected_low2 corrected_high2 ///
    using "`reproduced_sets'", replace

foreach level in household individual {
    import delimited using "${rd_table_dir}/rd_2013_`level'_results.csv", ///
        clear varnames(1) bindquote(strict) encoding(utf8) asdouble
    local unit "household"
    if "`level'" == "individual" local unit "person"
    keep if tier == "primary" & inlist(spec_id, ///
        "common_h_`unit'_equal", "parametric_`unit'_equal")
    assert _N == 16
    isid outcome_id spec_id
    assert p == 1 & kernel == "triangular" & bwselect == "manual"
    assert abs(h_left - ${rd_common_h}) < 1e-9
    assert abs(h_right - ${rd_common_h}) < 1e-9
    forvalues row = 1/16 {
        local outcome_`row' = outcome_var[`row']
        local id_`row' = outcome_id[`row']
        local spec_`row' = spec_id[`row']
        local estimand_`row' = estimand[`row']
        local scale_`row' = scale[`row']
    }

    if "`level'" == "household" {
        use "${rd_input_2013_household}", clear
        assert _N == 415007
        isid sisfoh_hhid
        generate double hh_employment_rate_outcome = ///
            hh_employed_age14_2013 / hh_labor_valid_2013 if hh_labor_valid_2013 > 0
        generate byte hh_any_program_outcome = ///
            hh_program_any_2013 > 0 if hh_members_2013 > 0
        local primary_outcomes hh_members_2013 hh_share_female_2013 ///
            hh_employment_rate_outcome hh_any_program_outcome ///
            wellbeing_core_proxy_2013 nbi_any_2013 wellbeing_assets_2013 ///
            hh_share_secondaryplus_2013
    }
    else {
        use "${rd_input_2013_individual}", clear
        assert _N == 1425575
        isid sisfoh_pid
        generate byte age_15_29_outcome = ///
            inrange(age_2013, 15, 29) if !missing(age_2013)
        generate byte worker_independent_2013 = labor_status_2013 == 2 ///
            if age_2013 >= 14 & !missing(age_2013, labor_status_2013)
        local primary_outcomes female_2013 age_15_29_outcome ///
            secondaryplus_2013 employed_2013 worker_independent_2013 ///
            insurance_any_2013 program_any_2013 program_juntos_2013
    }
    generate byte rd_bc_design = sample_main_rd == 1 & ///
        inlist(victimization_level_source, "B", "C")
    egen byte primary_missing = rowmiss(`primary_outcomes') if rd_bc_design
    generate byte rd_primary_sample = rd_bc_design & primary_missing == 0
    if "`level'" == "individual" ///
        replace rd_primary_sample = rd_primary_sample & age_2013 >= 14
    quietly count if rd_primary_sample
    if "`level'" == "household" assert r(N) == 39074
    else assert r(N) == 98005
    encode ruv_id, generate(cluster_ruv)
    encode ubigeo_dist, generate(cluster_dist)
    generate double final_weight = 1 - abs(${rd_running}) / ${rd_common_h} ///
        if rd_primary_sample & abs(${rd_running}) <= ${rd_common_h}
    replace final_weight = 1e-8 if final_weight == 0
    ereturn clear

    forvalues row = 1/16 {
        local weight_option
        if strpos("`spec_`row''", "parametric_") == 1 ///
            local weight_option "finalweight(final_weight)"
        _vrd_audit_exact_sample if rd_primary_sample, ///
            outcome(`outcome_`row'') running(${rd_running}) ///
            treatment(${rd_treatment_2013}) community(cluster_ruv) ///
            district(cluster_dist) cluster(cluster_ruv) ///
            hleft(${rd_common_h}) hright(${rd_common_h}) ///
            bleft(${rd_common_b}) bright(${rd_common_b}) poly(1) ///
            kernel(triangular) scale(`scale_`row'') fuzzy `weight_option'
        assert r(audit_rc) == 0 & r(ar_rc) == 0
        post `set_post' (2013) ("`level'") ("`id_`row''") ///
            ("`spec_`row''") ("`estimand_`row''") ///
            (r(iv_n)) (r(iv_effect)) (r(kp_f)) (r(ar_p)) ///
            ("`r(ar_type)'") (r(ar_components)) ///
            (r(ar_low1)) (r(ar_high1)) (r(ar_low2)) (r(ar_high2))
    }
}
postclose `set_post'
import delimited using "${rd_table_dir}/rd_exact_sample_diagnostics.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8) asdouble
isid wave level outcome_id spec_id estimand
merge 1:1 wave level outcome_id spec_id estimand using "`reproduced_sets'", ///
    assert(1 3)
quietly count if _merge == 3
assert r(N) == 32
assert check_n == iv_n if _merge == 3
foreach pair in effect kp ar_p {
    local old_variable "iv_effect"
    if "`pair'" == "kp" local old_variable "kp_f"
    if "`pair'" == "ar_p" local old_variable "ar_p"
    assert abs(check_`pair' - `old_variable') < ///
        1e-6 * (1 + abs(`old_variable')) if _merge == 3
}
assert corrected_low1 == ar_low1 if _merge == 3
assert abs(corrected_high1 - ar_high1) < 1e-6 * (1 + abs(ar_high1)) ///
    if _merge == 3 & !missing(ar_high1)
assert corrected_high1 == ar_high1 if _merge == 3 & missing(ar_high1)
assert inlist(corrected_type, "all_real", "disjoint") if _merge == 3
replace ar_type = corrected_type if _merge == 3
replace ar_components = corrected_components if _merge == 3
foreach endpoint in low1 high1 low2 high2 {
    replace ar_`endpoint' = corrected_`endpoint' if _merge == 3
}
drop check_n check_effect check_kp check_ar_p corrected_type ///
    corrected_components corrected_low1 corrected_high1 corrected_low2 ///
    corrected_high2 _merge
assert _N == 1970
sort wave level outcome_id spec_id estimand
export delimited using "${rd_table_dir}/rd_exact_sample_diagnostics.csv", replace
restore
display as result "All 32 unweighted AR sets independently reproduced and reconciled."
