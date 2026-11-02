/* Own-sample support and a conventional local-IV diagnostic, not RBC inference.
   See docs/IDENTIFICATION_PRECISION_AUDIT_2026-11-02.md. No data are saved. */
version 19
capture program drop _vrd_audit_exact_sample
program define _vrd_audit_exact_sample, rclass sortpreserve
    version 19
    syntax [if], OUTcome(varname) RUNning(varname) ///
        TREATment(varname) COMMunity(varname) DISTrict(varname) ///
        CLUSTer(varname) HLeft(real) HRight(real) BLeft(real) BRight(real) ///
        POLY(integer) KERNEL(string) SCALE(real) ///
        [COVariates(string) BASEWeight(varname) ///
        FINALWeight(varname) FUZZY ORIGinal(string) ORIGRC(integer 0) ///
        POSTHandle(name) WAVE(integer 0) LEVEL(string) OUTCOMEID(string) ///
        SPECID(string) ESTIMAND(string)]

    confirm numeric variable `outcome' `running' `treatment' `covariates' `baseweight' `finalweight'
    if "`original'" == "" local original .
    if "`original'" != "." confirm number `original'
    tempname caller_estimates ar_bounds audit_frame
    local caller_frame "`c(frame)'"
    local restore_estimates = "`e(cmd)'" != ""
    if `restore_estimates' estimates store `caller_estimates'
    marksample eligible, novarlist
    markout `eligible' `outcome' `running' `covariates'
    if "`fuzzy'" != "" markout `eligible' `treatment'
    if "`baseweight'" != "" {
        replace `eligible' = 0 if missing(`baseweight') | `baseweight' <= 0
    }
    if "`finalweight'" != "" {
        replace `eligible' = 0 if missing(`finalweight') | `finalweight' <= 0
    }
    quietly count if `eligible'
    local eligible_n = r(N)

    /* Copy only the actual eligible rows/columns; the wide input is untouched. */
    local audit_variables "`eligible' `outcome' `running' `treatment' `community' `district' `cluster' `covariates' `baseweight' `finalweight'"
    local audit_variables : list uniq audit_variables
    frame put `audit_variables' if `eligible', into(`audit_frame')
    frame change `audit_frame'

    foreach statistic in eligible_n_left eligible_n_right ///
        eligible_ccpp_left eligible_ccpp_right eligible_dist_left eligible_dist_right ///
        eligible_scores_left eligible_scores_right ///
        n_left n_right ccpp_left ccpp_right dist_left ///
        dist_right scores_left scores_right bias_n_left bias_n_right ///
        bias_ccpp_left bias_ccpp_right bias_dist_left bias_dist_right ///
        bias_scores_left bias_scores_right iv_n iv_clusters kp_f ///
        iv_effect iv_se fs_effect fs_se rf_effect rf_se ar_p ///
        ar_low1 ar_high1 ar_low2 ar_high2 coefficient_gap {
        local `statistic' .
    }
    local audit_rc = `origrc'
    local ar_rc .
    local ar_components .
    local ar_type "not_applicable"
    local status "original_fit_failed"

    foreach side in left right {
        local side_rule "`running' < 0"
        if "`side'" == "right" local side_rule "`running' >= 0"
        quietly count if `eligible' & `side_rule'
        local eligible_n_`side' = r(N)
        foreach unit in ccpp dist scores {
            local key "`community'"
            if "`unit'" == "dist" local key "`district'"
            if "`unit'" == "scores" local key "`running'"
            local eligible_`unit'_`side' = 0
            if `eligible_n_`side'' > 0 {
                tempvar eligible_tag
                quietly egen byte `eligible_tag' = tag(`key') if `eligible' & `side_rule'
                quietly count if `eligible_tag' == 1
                local eligible_`unit'_`side' = r(N)
            }
        }
    }

    if `origrc' == 0 & !missing(`hleft', `hright', `bleft', `bright') {
        assert `hleft' > 0 & `hright' > 0 & `bleft' > 0 & `bright' > 0
        assert inlist(`poly', 1, 2)
        assert inlist("`kernel'", "triangular", "uniform", "epanechnikov")
        tempvar local_sample bias_sample
        generate byte `local_sample' = `eligible' & ///
            inrange(`running', -`hleft', `hright')
        generate byte `bias_sample' = `eligible' & ///
            inrange(`running', -`bleft', `bright')
        /* rdrobust counts strictly positive kernel weights, not closed intervals. */
        if "`kernel'" != "uniform" {
            replace `local_sample' = 0 if ///
                `running' == -`hleft' | `running' == `hright'
            replace `bias_sample' = 0 if ///
                `running' == -`bleft' | `running' == `bright'
        }
        if "`finalweight'" != "" {
            replace `local_sample' = `eligible' & ///
                inrange(`running', -`hleft', `hright') & ///
                `finalweight' > 0 & `finalweight' < .
        }
        foreach side in left right {
            local side_rule "`running' < 0"
            if "`side'" == "right" local side_rule "`running' >= 0"
            quietly count if `local_sample' & `side_rule'
            local n_`side' = r(N)
            foreach unit in ccpp dist scores {
                local key "`community'"
                if "`unit'" == "dist" local key "`district'"
                if "`unit'" == "scores" local key "`running'"
                local `unit'_`side' = 0
                if `n_`side'' > 0 {
                    tempvar tag
                    quietly egen byte `tag' = tag(`key') if ///
                        `local_sample' & `side_rule'
                    quietly count if `tag' == 1
                    local `unit'_`side' = r(N)
                }
            }
            /* Registered parametric IV rows do not estimate a bias polynomial. */
            if "`finalweight'" == "" {
                quietly count if `bias_sample' & `side_rule'
                local bias_n_`side' = r(N)
                foreach unit in ccpp dist scores {
                    local key "`community'"
                    if "`unit'" == "dist" local key "`district'"
                    if "`unit'" == "scores" local key "`running'"
                    local bias_`unit'_`side' = 0
                    if `bias_n_`side'' > 0 {
                        tempvar bias_tag
                        quietly egen byte `bias_tag' = tag(`key') if ///
                            `bias_sample' & `side_rule'
                        quietly count if `bias_tag' == 1
                        local bias_`unit'_`side' = r(N)
                    }
                }
            }
        }
        local status "not_a_receipt_effect"

        if "`fuzzy'" != "" {
            tempvar above slope_right local_weight distance
            generate byte `above' = `running' >= 0 if `eligible'
            generate double `slope_right' = `running' * `above'
            generate double `distance' = cond(`running' < 0, ///
                abs(`running') / `hleft', `running' / `hright')
            generate double `local_weight' = 1 if `local_sample'
            if "`kernel'" == "triangular" {
                replace `local_weight' = 1 - `distance' if `local_sample'
            }
            if "`kernel'" == "epanechnikov" {
                replace `local_weight' = 1 - `distance'^2 if `local_sample'
            }
            if "`baseweight'" != "" {
                replace `local_weight' = `local_weight' * `baseweight'
            }
            if "`finalweight'" != "" {
                replace `local_weight' = `finalweight' if `local_sample'
            }
            replace `local_sample' = 0 if ///
                missing(`local_weight', `cluster') | `local_weight' <= 0
            local nuisance "`running' `slope_right' `covariates'"
            if `poly' == 2 {
                tempvar square square_right
                generate double `square' = `running'^2
                generate double `square_right' = `square' * `above'
                local nuisance "`nuisance' `square' `square_right'"
            }

            capture quietly ivreg2 `outcome' `nuisance' ///
                (`treatment' = `above') [aw = `local_weight'] ///
                if `local_sample', cluster(`cluster')
            local audit_rc = _rc
            local status "iv_analogue_failed"
            if !`audit_rc' {
                local iv_n = e(N)
                local iv_clusters = e(N_clust)
                local kp_f = e(rkf)
                local iv_effect = _b[`treatment'] * `scale'
                local iv_se = _se[`treatment'] * `scale'
                local coefficient_gap = `iv_effect' - `original'
                local status "iv_gate_failed"
                if `kp_f' > 10 & `kp_f' < . & ///
                    !missing(`iv_effect', `iv_se') & `iv_se' > 0 {
                    local status "iv_gate_passed_not_rbc_certified"
                }

                quietly regress `treatment' `nuisance' `above' ///
                    [aw = `local_weight'] if `local_sample', vce(cluster `cluster')
                local fs_effect = _b[`above']
                local fs_se = _se[`above']
                quietly regress `outcome' `nuisance' `above' ///
                    [aw = `local_weight'] if `local_sample', vce(cluster `cluster')
                local rf_effect = _b[`above'] * `scale'
                local rf_se = _se[`above'] * `scale'

                capture quietly ivregress 2sls `outcome' `nuisance' ///
                    (`treatment' = `above') [aw = `local_weight'] ///
                    if `local_sample', vce(cluster `cluster')
                local ar_rc = _rc
                local ar_type "failed"
                if !`ar_rc' {
                    assert abs(_b[`treatment'] * `scale' - `iv_effect') < ///
                        1e-7 * (1 + abs(`iv_effect'))
                    assert e(N) == `iv_n'
                    capture quietly estat weakrobust, ci level(95)
                    local ar_rc = _rc
                }
                if !`ar_rc' {
                    local ar_p = r(p_archi2)
                    matrix `ar_bounds' = r(ar_ci)
                    local ar_rows = rowsof(`ar_bounds')
                    local ar_columns = colsof(`ar_bounds')
                    assert (`ar_rows' == 1 & `ar_columns' == 1) | ///
                        (inlist(`ar_rows', 1, 2) & `ar_columns' == 2)
                    local ar_components = `ar_rows'
                    local ar_type "bounded"
                    if `ar_columns' == 1 {
                        local ar_components 0
                        local ar_type "empty"
                    }
                    if `ar_columns' >= 2 {
                        local ar_low1 = `ar_bounds'[1,1] * `scale'
                        local ar_high1 = `ar_bounds'[1,2] * `scale'
                        if `ar_bounds'[1,1] == .l local ar_low1 .l
                        if `ar_bounds'[1,2] == .u local ar_high1 .u
                        if missing(`ar_low1') | missing(`ar_high1') ///
                            local ar_type "unbounded"
                        if `ar_low1' == .l & `ar_high1' == .u ///
                            local ar_type "all_real"
                    }
                    if `ar_rows' == 2 {
                        local ar_type "disjoint"
                        local ar_low2 = `ar_bounds'[2,1] * `scale'
                        local ar_high2 = `ar_bounds'[2,2] * `scale'
                        if `ar_bounds'[2,1] == .l local ar_low2 .l
                        if `ar_bounds'[2,2] == .u local ar_high2 .u
                    }
                }
            }
        }
    }

    if "`posthandle'" != "" {
        post `posthandle' (`wave') ("`level'") ("`outcomeid'") ///
            ("`specid'") ("`estimand'") ("`status'") ("`cluster'") ///
            (`eligible_n') (`eligible_n_left') (`eligible_n_right') ///
            (`eligible_ccpp_left') (`eligible_ccpp_right') ///
            (`eligible_dist_left') (`eligible_dist_right') ///
            (`eligible_scores_left') (`eligible_scores_right') ///
            (`n_left') (`n_right') (`ccpp_left') (`ccpp_right') ///
            (`dist_left') (`dist_right') (`scores_left') (`scores_right') ///
            (`bias_n_left') (`bias_n_right') (`bias_ccpp_left') (`bias_ccpp_right') ///
            (`bias_dist_left') (`bias_dist_right') (`bias_scores_left') (`bias_scores_right') ///
            (`iv_n') (`iv_clusters') (`kp_f') (`iv_effect') (`iv_se') ///
            (`fs_effect') (`fs_se') (`rf_effect') (`rf_se') (`ar_p') ///
            ("`ar_type'") (`ar_components') ///
            (`ar_low1') (`ar_high1') (`ar_low2') (`ar_high2') ///
            (`coefficient_gap') (`origrc') (`audit_rc') (`ar_rc')
    }
    frame change `caller_frame'
    frame drop `audit_frame'
    if `restore_estimates' {
        quietly estimates restore `caller_estimates'
        quietly estimates drop `caller_estimates'
    }
    else ereturn clear
    foreach statistic in eligible_n eligible_n_left eligible_n_right ///
        eligible_ccpp_left eligible_ccpp_right eligible_dist_left eligible_dist_right ///
        eligible_scores_left eligible_scores_right ///
        n_left n_right ccpp_left ccpp_right dist_left dist_right scores_left scores_right ///
        bias_n_left bias_n_right bias_ccpp_left bias_ccpp_right ///
        bias_dist_left bias_dist_right bias_scores_left bias_scores_right ///
        iv_n iv_clusters kp_f iv_effect coefficient_gap ar_p ar_components ///
        ar_low1 ar_high1 ar_low2 ar_high2 audit_rc ar_rc {
        return scalar `statistic' = ``statistic''
    }
    return local status "`status'"
    return local ar_type "`ar_type'"
end
