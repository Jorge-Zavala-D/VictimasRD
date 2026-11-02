/* Compare aggregate model results to the preserved, pre-edit CSVs.
   The caller supplies the ignored baseline directory; no research data are read. */
version 19
args baseline_root
if `"`baseline_root'"' == "" {
    display as error "Supply the frozen aggregate-result baseline directory."
    exit 198
}
preserve
tempfile baseline comparisons
tempname comparison_post
postfile `comparison_post' int wave str12 level str32 variable ///
    long cells different double max_absolute_difference ///
    str32 comparison_rule using "`comparisons'", replace
foreach wave in 2013 2017 {
    foreach level in ccpp household individual {
        import delimited using "`baseline_root'/rd_`wave'_`level'_results.csv", ///
            clear varnames(1) bindquote(strict) encoding(utf8) asdouble
        isid outcome_id spec_id estimand
        ds outcome_id spec_id estimand, not
        local compare_variables "`r(varlist)'"
        foreach variable of local compare_variables {
            rename `variable' old_`variable'
        }
        save "`baseline'", replace
        import delimited using "${rd_table_dir}/rd_`wave'_`level'_results.csv", ///
            clear varnames(1) bindquote(strict) encoding(utf8) asdouble
        merge 1:1 outcome_id spec_id estimand using "`baseline'", assert(3) nogen
        foreach variable of local compare_variables {
            capture confirm numeric variable `variable' old_`variable'
            local numeric_pair = !_rc
            local maximum 0
            local rule "exact_string"
            if `numeric_pair' {
                assert missing(`variable') == missing(old_`variable')
                assert `variable' == old_`variable' if missing(`variable')
                tempvar difference
                generate double `difference' = abs(`variable' - old_`variable')
                local rule "abs_1e-10_rel_1e-12"
                assert `difference' <= 1e-10 + 1e-12 * abs(old_`variable') ///
                    if !missing(`difference')
                if inlist("`variable'", "paper_order", "p", "q", "n_input", ///
                    "n_eff_left", "n_eff_right", "ccpp_left", "ccpp_right") | ///
                    inlist("`variable'", "clusters", "estimation_rc") {
                    assert `variable' == old_`variable'
                    local rule "exact_integer"
                }
                quietly summarize `difference', meanonly
                if r(N) local maximum = r(max)
                drop `difference'
            }
            else assert `variable' == old_`variable'
            quietly count if `variable' != old_`variable'
            local differences = r(N)
            post `comparison_post' (`wave') ("`level'") ("`variable'") ///
                (_N) (`differences') (`maximum') ("`rule'")
        }
    }
}
postclose `comparison_post'
use "`comparisons'", clear
isid wave level variable
sort wave level variable
export delimited using ///
    "${metadata_root}/identification-precision-numerical-comparison-2026-11-02.csv", replace
quietly summarize different, meanonly
display as result "Continuous-value serialization differences: " r(sum)
display as result "All six frozen model-result comparisons passed."
restore
