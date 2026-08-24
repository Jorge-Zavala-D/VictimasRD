/*
Project: Victimas RD
Purpose: Estimate prespecified SISFOH 2013 CCPP RD heterogeneity
Unit:    RUV centro poblado
Inputs:  2013 CCPP analysis file and row-level CMAN project registry
Outputs: Aggregate CSV/LaTeX results and publication-formatted figures in Git
*/

version 19
set more off

capture log close victimasrd_hte_2013_ccpp
log using "${logs_root}/hte_2013_ccpp_${hte_run_id}.smcl", ///
    name(victimasrd_hte_2013_ccpp) replace


*-----------------------------------*
**# 1. Input, sample, and registry checks
*-----------------------------------*

use "${hte_input_2013_ccpp}", clear
quietly datasignature
local input_datasignature "`r(datasignature)'"

assert _N == 5712

local required_vars ///
    ruv_id ubigeo_dist ubigeo_ccpp sample_main_rd ///
    victimization_level_source ${hte_running} ${hte_treatment_2013} ///
    sisfoh2013_linked sisfoh2013_population sisfoh2013_households ///
    population_2007 ln_population_2007 ///
    wellbeing_core_2007 deprivation_core_2007 ///
    is_dist_capital_2017 ln1p_dist_dist_capital ///
    ihs_gdp_ccpp_2006 altitude_m_2017

foreach required_var of local required_vars {
    confirm variable `required_var'
}

assert inlist(${hte_treatment_2013}, 0, 1) ///
    if !missing(${hte_treatment_2013})

generate byte hte_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")
quietly count if hte_bc_design
assert r(N) == 549

generate double ln_sisfoh2013_population = ///
    ln(sisfoh2013_population) if sisfoh2013_population > 0
generate double ln_sisfoh2013_households = ///
    ln(sisfoh2013_households) if sisfoh2013_households > 0

local primary_outcomes ///
    ln_sisfoh2013_population ///
    ln_sisfoh2013_households ///
    share_age_15_29_2013 ///
    share_any_program_2013 ///
    wellbeing_core_proxy_2013 ///
    share_nbi_any_2013 ///
    labor_force_participation_2013 ///
    share_educ_secondaryplus_2013

foreach outcome_var of local primary_outcomes {
    confirm variable `outcome_var'
}

generate byte hte_linked_sample = ///
    hte_bc_design & sisfoh2013_linked == 1
egen byte hte_primary_missing = rowmiss(`primary_outcomes') ///
    if hte_linked_sample
generate byte hte_primary_sample = ///
    hte_linked_sample & hte_primary_missing == 0

quietly count if hte_linked_sample
assert r(N) == 487
quietly count if hte_primary_sample
assert r(N) == 487

encode ubigeo_dist, generate(hte_cluster_dist)
generate byte hte_assignment = ${hte_running} >= 0 ///
    if !missing(${hte_running})

quietly count if hte_primary_sample & ///
    abs(${hte_running}) < ${hte_common_h}
assert r(N) == 65

preserve
import delimited using "${hte_outcome_registry}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if tier == "primary"
sort paper_order
isid outcome_id
assert _N == 8

local outcome_count = _N
forvalues outcome_index = 1/`outcome_count' {
    local o_order_`outcome_index' = paper_order[`outcome_index']
    local o_id_`outcome_index' = outcome_id[`outcome_index']
    local o_var_`outcome_index' = outcome_var[`outcome_index']
    local o_label_`outcome_index' = outcome_label[`outcome_index']
    local o_scale_`outcome_index' = scale[`outcome_index']
    local o_stub_`outcome_index' = file_stub[`outcome_index']
}
restore

preserve
import delimited using "${hte_moderator_registry}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if strpos(levels, "ccpp")
keep if inlist(moderator_id, "M01", "M02", "S01", "S02", "S03", "S05")
sort paper_order
isid moderator_id
assert _N == 6

local moderator_count = _N
forvalues moderator_index = 1/`moderator_count' {
    local m_order_`moderator_index' = paper_order[`moderator_index']
    local m_id_`moderator_index' = moderator_id[`moderator_index']
    local m_source_`moderator_index' = ///
        moderator_var_2013[`moderator_index']
    local m_label_`moderator_index' = moderator_label[`moderator_index']
    local m_tier_`moderator_index' = tier[`moderator_index']
    local m_type_`moderator_index' = type[`moderator_index']
    local m_transform_`moderator_index' = transform[`moderator_index']
}
restore


*-----------------------------------*
**# 2. Moderator construction and support
*-----------------------------------*

forvalues moderator_index = 1/`moderator_count' {
    local moderator_source "`m_source_`moderator_index''"
    local moderator_type "`m_type_`moderator_index''"
    local moderator_var "hte_m`moderator_index'"

    confirm variable `moderator_source'

    if "`moderator_type'" == "continuous" {
        quietly summarize `moderator_source' if hte_primary_sample, detail
        assert r(N) > 0
        assert r(sd) > 0

        local m_mean_`moderator_index' = r(mean)
        local m_sd_`moderator_index' = r(sd)
        local m_raw25_`moderator_index' = r(p25)
        local m_raw50_`moderator_index' = r(p50)
        local m_raw75_`moderator_index' = r(p75)
        local m_eval25_`moderator_index' = ///
            (r(p25) - r(mean)) / r(sd)
        local m_eval50_`moderator_index' = ///
            (r(p50) - r(mean)) / r(sd)
        local m_eval75_`moderator_index' = ///
            (r(p75) - r(mean)) / r(sd)

        generate double `moderator_var' = ///
            (`moderator_source' - `m_mean_`moderator_index'') / ///
            `m_sd_`moderator_index''
    }
    else {
        assert inlist(`moderator_source', 0, 1) ///
            if !missing(`moderator_source')
        generate byte `moderator_var' = `moderator_source'
        local m_mean_`moderator_index' = .
        local m_sd_`moderator_index' = .
        local m_raw25_`moderator_index' = 0
        local m_raw50_`moderator_index' = .
        local m_raw75_`moderator_index' = 1
        local m_eval25_`moderator_index' = 0
        local m_eval50_`moderator_index' = .
        local m_eval75_`moderator_index' = 1
    }

    label variable `moderator_var' "`m_label_`moderator_index''"
}

tempfile hte_analysis_base
save `hte_analysis_base'


*-----------------------------------*
**# 3. Project-type and financing inputs
*-----------------------------------*

tempfile hte_project_records hte_project_ccpp

use "${hte_project_registry}", clear
confirm variable ruv_id recorded_project_year prc_project_group ///
    prc_total_financing_soles
isid record_number

keep if !missing(ruv_id) & recorded_project_year <= 2012
assert prc_total_financing_soles > 0
assert inrange(prc_project_group, 1, 4)

forvalues project_group = 1/4 {
    generate byte hte_project_group_`project_group' = ///
        prc_project_group == `project_group'
}
generate byte hte_project_record = 1

save `hte_project_records'

collapse ///
    (sum) hte_total_financing_2012=prc_total_financing_soles ///
          hte_project_records_2012=hte_project_record ///
    (max) hte_project_group_1-hte_project_group_4, ///
    by(ruv_id)

isid ruv_id
save `hte_project_ccpp'

use `hte_analysis_base', clear
merge 1:1 ruv_id using `hte_project_ccpp', ///
    keep(master match) nogen

replace hte_total_financing_2012 = 0 if ${hte_treatment_2013} == 0
replace hte_project_records_2012 = 0 if ${hte_treatment_2013} == 0
forvalues project_group = 1/4 {
    replace hte_project_group_`project_group' = 0 ///
        if ${hte_treatment_2013} == 0
}

assert hte_total_financing_2012 > 0 if ${hte_treatment_2013} == 1
assert hte_project_records_2012 >= 1 if ${hte_treatment_2013} == 1

generate double hte_financing_pc_2012 = ///
    hte_total_financing_2012 / population_2007 ///
    if population_2007 > 0
generate double hte_financing_pc_1000 = ///
    hte_financing_pc_2012 / 1000

label variable hte_financing_pc_2012 ///
    "Recorded project financing through 2012 per 2007 resident"
label variable hte_financing_pc_1000 ///
    "Thousands of recorded soles through 2012 per 2007 resident"

save `hte_analysis_base', replace


*-----------------------------------*
**# 4. Reusable pooled local-IV estimator
*-----------------------------------*

capture program drop _vrd_post_hte_iv

program define _vrd_post_hte_iv
    version 19
    syntax, ///
        POSTHandle(name) CONDHandle(name) ///
        OUTVAR(name) OUTCOMEID(string) OUTLABel(string) ///
        PAPEROrder(real) SCALE(real) ///
        MODVAR(name) MODID(string) MODLABel(string) ///
        MODTIER(string) MODTYPE(string) ///
        SPECID(string) HValue(real) USEVAR(name) ///
        EVAL1(real) EVAL2(real) EVAL3(real) ///
        RAW1(real) RAW2(real) RAW3(real) ///
        [COVariates(varlist)]

    tempvar y_scaled kernel_weight running_right ///
        assignment_m treatment_m running_m running_right_m ///
        covariate_missing cluster_tag

    quietly generate double `y_scaled' = `outvar' * `scale'
    quietly generate double `kernel_weight' = ///
        1 - abs(${hte_running}) / `hvalue' ///
        if abs(${hte_running}) < `hvalue'
    quietly generate double `running_right' = ///
        ${hte_running} * hte_assignment
    quietly generate double `assignment_m' = ///
        hte_assignment * `modvar'
    quietly generate double `treatment_m' = ///
        ${hte_treatment_2013} * `modvar'
    quietly generate double `running_m' = ///
        ${hte_running} * `modvar'
    quietly generate double `running_right_m' = ///
        ${hte_running} * hte_assignment * `modvar'

    local estimator_sample ///
        "`usevar' & `kernel_weight' < . & `kernel_weight' > 0 & !missing(`y_scaled', `modvar', hte_cluster_dist)"

    if "`covariates'" != "" {
        quietly egen byte `covariate_missing' = rowmiss(`covariates')
        local estimator_sample ///
            "`estimator_sample' & `covariate_missing' == 0"
    }

    quietly count if `estimator_sample' & ${hte_running} < 0
    local n_left = r(N)
    quietly count if `estimator_sample' & ${hte_running} >= 0
    local n_right = r(N)
    local min_cell = min(`n_left', `n_right')

    if "`modtype'" == "binary" {
        quietly count if `estimator_sample' & ///
            ${hte_running} < 0 & `modvar' == 0
        local n_l0 = r(N)
        quietly count if `estimator_sample' & ///
            ${hte_running} >= 0 & `modvar' == 0
        local n_r0 = r(N)
        quietly count if `estimator_sample' & ///
            ${hte_running} < 0 & `modvar' == 1
        local n_l1 = r(N)
        quietly count if `estimator_sample' & ///
            ${hte_running} >= 0 & `modvar' == 1
        local n_r1 = r(N)
        local min_cell = min(`n_l0', `n_r0', `n_l1', `n_r1')
    }

    local support_pass = `min_cell' >= ${hte_min_cell}

    quietly egen byte `cluster_tag' = tag(hte_cluster_dist) ///
        if `estimator_sample'
    quietly count if `cluster_tag'
    local clusters = r(N)

    local included_covariates "`covariates'"

    local estimation_rc = 2001
    if `support_pass' {
        capture quietly ivreg2 ///
            `y_scaled' ///
            `modvar' ${hte_running} `running_right' ///
            `running_m' `running_right_m' ///
            `included_covariates' ///
            (${hte_treatment_2013} `treatment_m' = ///
                hte_assignment `assignment_m') ///
            [aw=`kernel_weight'] if `estimator_sample', ///
            cluster(hte_cluster_dist) first
        local estimation_rc = _rc
    }

    local estimate .
    local standard_error .
    local pvalue .
    local ci_low .
    local ci_high .
    local control_sd .
    local standardized_estimate .
    local standardized_ci_low .
    local standardized_ci_high .
    local kp_f .
    local underid_p .
    local ar_p .
    local sw_f_treat .
    local sw_f_interaction .
    local min_sw_f .
    local gate_pass 0
    local gate_status "estimation_failed"

    if !`estimation_rc' {
        local estimate = _b[`treatment_m']
        local standard_error = _se[`treatment_m']

        if missing(`estimate') | missing(`standard_error') {
            local estimation_rc = 504
        }
        else {
            capture quietly test `treatment_m'
            if !_rc local pvalue = r(p)
            local ci_low = `estimate' - invnormal(.975) * `standard_error'
            local ci_high = `estimate' + invnormal(.975) * `standard_error'
        }

        quietly summarize `y_scaled' if ///
            `estimator_sample' & ${hte_running} < 0
        local control_sd = r(sd)
        if `control_sd' > 0 & `control_sd' < . {
            local standardized_estimate = `estimate' / `control_sd'
            local standardized_ci_low = `ci_low' / `control_sd'
            local standardized_ci_high = `ci_high' / `control_sd'
        }

        capture local kp_f = e(widstat)
        capture local underid_p = e(idp)
        capture local ar_p = e(arfp)

        capture matrix hte_first = e(first)
        if !_rc {
            local sw_row = rownumb(hte_first, "SWF")
            if `sw_row' < . {
                local sw_f_treat = hte_first[`sw_row', 1]
                local sw_f_interaction = hte_first[`sw_row', 2]
                local min_sw_f = min(`sw_f_treat', `sw_f_interaction')
            }
        }

        local gate_pass = ///
            `support_pass' & ///
            `min_sw_f' < . & ///
            `min_sw_f' > ${hte_weak_f_gate} & ///
            `underid_p' < . & ///
            `underid_p' < .05

        local gate_status "pass"
        if !`support_pass' local gate_status "insufficient_support"
        else if missing(`underid_p') | `underid_p' >= .05 ///
            local gate_status "underidentified"
        else if missing(`min_sw_f') | ///
            `min_sw_f' <= ${hte_weak_f_gate} ///
            local gate_status "weak_interaction_instruments"
        if `estimation_rc' local gate_status "estimation_failed"
    }

    if !`support_pass' local gate_status "insufficient_support"

    post `posthandle' ///
        ("`outcomeid'") ("`outvar'") ("`outlabel'") ///
        (`paperorder') (`scale') ///
        ("`modid'") ("`modlabel'") ///
        ("`modtier'") ("`modtype'") ///
        ("`specid'") ("ivreg2") ("fuzzy_late_interaction") ///
        (`hvalue') (`n_left') (`n_right') (`min_cell') (`clusters') ///
        (`support_pass') (`estimate') (`standard_error') (`pvalue') ///
        (`ci_low') (`ci_high') (`control_sd') ///
        (`standardized_estimate') (`standardized_ci_low') ///
        (`standardized_ci_high') ///
        (`kp_f') (`sw_f_treat') (`sw_f_interaction') (`min_sw_f') ///
        (`underid_p') (`ar_p') (`gate_pass') ("`gate_status'") ///
        (`estimation_rc')

    if "`specid'" == "common_h_iv" & !`estimation_rc' {
        local value_count = 3
        if "`modtype'" == "binary" local value_count = 2

        forvalues value_index = 1/`value_count' {
            local eval_value = `eval`value_index''
            local raw_value = `raw`value_index''
            local value_label "P`=25*`value_index''"
            if `value_index' == 2 local value_label "P50"
            if `value_index' == 3 local value_label "P75"
            if "`modtype'" == "binary" {
                local value_label = cond(`value_index' == 1, "No", "Yes")
            }

            capture quietly lincom ///
                ${hte_treatment_2013} + ///
                `eval_value' * `treatment_m'

            local conditional_estimate .
            local conditional_se .
            local conditional_p .
            local conditional_low .
            local conditional_high .
            if !_rc {
                local conditional_estimate = r(estimate)
                local conditional_se = r(se)
                local conditional_p = r(p)
                local conditional_low = r(lb)
                local conditional_high = r(ub)
            }

            post `condhandle' ///
                ("`outcomeid'") ("`outlabel'") (`paperorder') ///
                ("`modid'") ("`modlabel'") ///
                ("`modtier'") ("`value_label'") ///
                (`raw_value') (`eval_value') ///
                (`conditional_estimate') (`conditional_se') ///
                (`conditional_p') (`conditional_low') (`conditional_high') ///
                (`gate_pass') ("`gate_status'")
        }
    }
end


*-----------------------------------*
**# 5. Reusable rdhte reduced-form estimator
*-----------------------------------*

capture program drop _vrd_post_hte_rdhte

program define _vrd_post_hte_rdhte
    version 19
    syntax, ///
        POSTHandle(name) OUTVAR(name) OUTCOMEID(string) ///
        OUTLABel(string) PAPEROrder(real) SCALE(real) ///
        MODVAR(name) MODID(string) MODLABel(string) ///
        MODTIER(string) MODTYPE(string) ///
        HValue(real) USEVAR(name)

    tempvar y_scaled cluster_tag
    quietly generate double `y_scaled' = `outvar' * `scale'

    local estimator_sample ///
        "`usevar' & !missing(`y_scaled', `modvar', hte_cluster_dist)"

    quietly count if `estimator_sample' & ///
        ${hte_running} < 0 & abs(${hte_running}) < `hvalue'
    local n_left = r(N)
    quietly count if `estimator_sample' & ///
        ${hte_running} >= 0 & abs(${hte_running}) < `hvalue'
    local n_right = r(N)
    local min_cell = min(`n_left', `n_right')

    if "`modtype'" == "binary" {
        quietly count if `estimator_sample' & ///
            ${hte_running} < 0 & abs(${hte_running}) < `hvalue' & ///
            `modvar' == 0
        local n_l0 = r(N)
        quietly count if `estimator_sample' & ///
            ${hte_running} >= 0 & abs(${hte_running}) < `hvalue' & ///
            `modvar' == 0
        local n_r0 = r(N)
        quietly count if `estimator_sample' & ///
            ${hte_running} < 0 & abs(${hte_running}) < `hvalue' & ///
            `modvar' == 1
        local n_l1 = r(N)
        quietly count if `estimator_sample' & ///
            ${hte_running} >= 0 & abs(${hte_running}) < `hvalue' & ///
            `modvar' == 1
        local n_r1 = r(N)
        local min_cell = min(`n_l0', `n_r0', `n_l1', `n_r1')
    }

    local support_pass = `min_cell' >= ${hte_min_cell}

    quietly egen byte `cluster_tag' = tag(hte_cluster_dist) ///
        if `estimator_sample' & abs(${hte_running}) < `hvalue'
    quietly count if `cluster_tag'
    local clusters = r(N)

    local hte_option "covs_hte(`modvar')"
    if "`modtype'" == "binary" ///
        local hte_option "covs_hte(i.`modvar') labels"

    local estimation_rc = 2001
    if `support_pass' {
        capture quietly rdhte ///
            `y_scaled' ${hte_running} if `estimator_sample', ///
            `hte_option' h(`hvalue') ///
            vce(cluster hte_cluster_dist)
        local estimation_rc = _rc
    }

    local estimate .
    local estimate_bc .
    local standard_error .
    local pvalue .
    local ci_low .
    local ci_high .
    local control_sd .
    local standardized_estimate .
    local standardized_ci_low .
    local standardized_ci_high .

    if !`estimation_rc' {
        if "`modtype'" == "continuous" {
            matrix hte_tau = e(tau_hat)
            matrix hte_tau_bc = e(tau_bc)
            matrix hte_se = e(tau_se)
            matrix hte_p = e(tau_pv)
            matrix hte_low = e(tau_ci_lb)
            matrix hte_high = e(tau_ci_ub)

            local estimate = hte_tau[1, 2]
            local estimate_bc = hte_tau_bc[1, 2]
            local standard_error = hte_se[2, 1]
            local pvalue = hte_p[2, 1]
            local ci_low = hte_low[2, 1]
            local ci_high = hte_high[2, 1]
        }
        else {
            capture quietly rdhte_lincom 1.`modvar' - 0.`modvar'
            local lincom_rc = _rc
            if `lincom_rc' {
                local estimation_rc = `lincom_rc'
            }
            else {
                local estimate = r(estimate)
                local estimate_bc = r(estimate)
                local standard_error = r(se)
                local pvalue = r(p)
                local ci_low = r(lb)
                local ci_high = r(ub)
            }
        }

        if missing(`estimate_bc') | missing(`standard_error') {
            local estimation_rc = 504
        }
        else {
            quietly summarize `y_scaled' if ///
                `estimator_sample' & ${hte_running} < 0 & ///
                abs(${hte_running}) < `hvalue'
            local control_sd = r(sd)
            if `control_sd' > 0 & `control_sd' < . {
                local standardized_estimate = `estimate_bc' / `control_sd'
                local standardized_ci_low = `ci_low' / `control_sd'
                local standardized_ci_high = `ci_high' / `control_sd'
            }
        }
    }

    local gate_status = cond(`support_pass', ///
        "assignment_hte_supported", "insufficient_support")
    if `estimation_rc' & `support_pass' local gate_status "estimation_failed"

    post `posthandle' ///
        ("`outcomeid'") ("`outvar'") ("`outlabel'") ///
        (`paperorder') (`scale') ///
        ("`modid'") ("`modlabel'") ///
        ("`modtier'") ("`modtype'") ///
        ("common_h_rdhte") ("rdhte") ///
        ("assignment_hte") ///
        (`hvalue') (`n_left') (`n_right') (`min_cell') (`clusters') ///
        (`support_pass') (`estimate_bc') (`standard_error') (`pvalue') ///
        (`ci_low') (`ci_high') (`control_sd') ///
        (`standardized_estimate') (`standardized_ci_low') ///
        (`standardized_ci_high') ///
        (.) (.) (.) (.) (.) (.) ///
        (`support_pass') ("`gate_status'") (`estimation_rc')
end


*-----------------------------------*
**# 6. Prespecified outcome-by-moderator grid
*-----------------------------------*

tempfile hte_results_raw hte_results_final hte_conditional_raw
tempname hte_post hte_cond_post

postfile `hte_post' ///
    str12 outcome_id str40 outcome_var str100 outcome_label ///
    double paper_order scale ///
    str8 moderator_id str80 moderator_label ///
    str12 moderator_tier str12 moderator_type ///
    str28 spec_id str12 estimator str32 estimand ///
    double h n_left n_right min_cell clusters support_pass ///
    estimate standard_error pvalue ci_low ci_high control_sd ///
    standardized_estimate standardized_ci_low standardized_ci_high ///
    kp_f sw_f_treat sw_f_interaction min_sw_f underid_p ar_p ///
    gate_pass str36 gate_status int estimation_rc ///
    using `hte_results_raw', replace

postfile `hte_cond_post' ///
    str12 outcome_id str100 outcome_label double paper_order ///
    str8 moderator_id str80 moderator_label str12 moderator_tier ///
    str12 value_label double raw_value standardized_value ///
    estimate standard_error pvalue ci_low ci_high ///
    gate_pass str36 gate_status ///
    using `hte_conditional_raw', replace

forvalues moderator_index = 1/`moderator_count' {
    local moderator_var "hte_m`moderator_index'"
    local moderator_id "`m_id_`moderator_index''"
    local moderator_label "`m_label_`moderator_index''"
    local moderator_tier "`m_tier_`moderator_index''"
    local moderator_type "`m_type_`moderator_index''"

    local covariates "${hte_primary_covariates}"
    if "`moderator_id'" == "M01" {
        local covariates "altitude_m_2017 wellbeing_core_2007"
    }
    if "`moderator_id'" == "S01" {
        local covariates "altitude_m_2017 ln_population_2007"
    }
    if "`moderator_id'" == "S05" {
        local covariates "ln_population_2007 wellbeing_core_2007"
    }

    forvalues outcome_index = 1/`outcome_count' {
        local outcome_var "`o_var_`outcome_index''"
        local outcome_id "`o_id_`outcome_index''"
        local outcome_label "`o_label_`outcome_index''"
        local outcome_order = `o_order_`outcome_index''
        local outcome_scale = `o_scale_`outcome_index''

        display as text ///
            "Estimating 2013 CCPP heterogeneity: `moderator_id' x `outcome_id'."

        _vrd_post_hte_iv, ///
            posthandle(`hte_post') condhandle(`hte_cond_post') ///
            outvar(`outcome_var') outcomeid("`outcome_id'") ///
            outlabel("`outcome_label'") paperorder(`outcome_order') ///
            scale(`outcome_scale') ///
            modvar(`moderator_var') modid("`moderator_id'") ///
            modlabel("`moderator_label'") ///
            modtier("`moderator_tier'") modtype("`moderator_type'") ///
            specid("common_h_iv") hvalue(${hte_common_h}) ///
            usevar(hte_primary_sample) ///
            eval1(`m_eval25_`moderator_index'') ///
            eval2(`m_eval50_`moderator_index'') ///
            eval3(`m_eval75_`moderator_index'') ///
            raw1(`m_raw25_`moderator_index'') ///
            raw2(`m_raw50_`moderator_index'') ///
            raw3(`m_raw75_`moderator_index'')

        _vrd_post_hte_rdhte, ///
            posthandle(`hte_post') ///
            outvar(`outcome_var') outcomeid("`outcome_id'") ///
            outlabel("`outcome_label'") paperorder(`outcome_order') ///
            scale(`outcome_scale') ///
            modvar(`moderator_var') modid("`moderator_id'") ///
            modlabel("`moderator_label'") ///
            modtier("`moderator_tier'") modtype("`moderator_type'") ///
            hvalue(${hte_common_h}) usevar(hte_primary_sample)

        _vrd_post_hte_iv, ///
            posthandle(`hte_post') condhandle(`hte_cond_post') ///
            outvar(`outcome_var') outcomeid("`outcome_id'") ///
            outlabel("`outcome_label'") paperorder(`outcome_order') ///
            scale(`outcome_scale') ///
            modvar(`moderator_var') modid("`moderator_id'") ///
            modlabel("`moderator_label'") ///
            modtier("`moderator_tier'") modtype("`moderator_type'") ///
            specid("common_h_covariates") hvalue(${hte_common_h}) ///
            usevar(hte_primary_sample) covariates(`covariates') ///
            eval1(`m_eval25_`moderator_index'') ///
            eval2(`m_eval50_`moderator_index'') ///
            eval3(`m_eval75_`moderator_index'') ///
            raw1(`m_raw25_`moderator_index'') ///
            raw2(`m_raw50_`moderator_index'') ///
            raw3(`m_raw75_`moderator_index'')

        if "`moderator_tier'" == "primary" {
            foreach bandwidth_name in small large {
                local bandwidth = cond("`bandwidth_name'" == "small", ///
                    ${hte_small_h}, ${hte_large_h})

                _vrd_post_hte_iv, ///
                    posthandle(`hte_post') condhandle(`hte_cond_post') ///
                    outvar(`outcome_var') outcomeid("`outcome_id'") ///
                    outlabel("`outcome_label'") ///
                    paperorder(`outcome_order') scale(`outcome_scale') ///
                    modvar(`moderator_var') modid("`moderator_id'") ///
                    modlabel("`moderator_label'") ///
                    modtier("`moderator_tier'") ///
                    modtype("`moderator_type'") ///
                    specid("`bandwidth_name'_h_iv") ///
                    hvalue(`bandwidth') usevar(hte_primary_sample) ///
                    eval1(`m_eval25_`moderator_index'') ///
                    eval2(`m_eval50_`moderator_index'') ///
                    eval3(`m_eval75_`moderator_index'') ///
                    raw1(`m_raw25_`moderator_index'') ///
                    raw2(`m_raw50_`moderator_index'') ///
                    raw3(`m_raw75_`moderator_index'')
            }
        }
    }
}

postclose `hte_post'
postclose `hte_cond_post'


*-----------------------------------*
**# 7. Multiplicity and machine-readable results
*-----------------------------------*

use `hte_results_raw', clear
assert _N == 176
assert estimation_rc >= 0 & estimation_rc < .

generate double p_holm = .
generate double q_bh = .

egen long hte_adjust_group = group(estimator moderator_tier) ///
    if inlist(spec_id, "common_h_iv", "common_h_rdhte") & ///
    estimation_rc == 0 & pvalue < .

sort hte_adjust_group pvalue
by hte_adjust_group: generate int hte_rank = _n if hte_adjust_group < .
by hte_adjust_group: generate int hte_family_n = _N if hte_adjust_group < .

generate double hte_holm_step = ///
    pvalue * (hte_family_n - hte_rank + 1) ///
    if moderator_tier == "primary" & hte_adjust_group < .
by hte_adjust_group: replace hte_holm_step = ///
    max(hte_holm_step, hte_holm_step[_n-1]) ///
    if moderator_tier == "primary" & _n > 1 & hte_adjust_group < .
replace p_holm = min(hte_holm_step, 1) ///
    if moderator_tier == "primary" & hte_holm_step < .

generate double hte_bh_step = ///
    pvalue * hte_family_n / hte_rank ///
    if moderator_tier == "secondary" & hte_adjust_group < .
gsort hte_adjust_group -hte_rank
by hte_adjust_group: replace hte_bh_step = ///
    min(hte_bh_step, hte_bh_step[_n-1]) ///
    if moderator_tier == "secondary" & _n > 1 & hte_adjust_group < .
replace q_bh = min(hte_bh_step, 1) ///
    if moderator_tier == "secondary" & hte_bh_step < .

drop hte_adjust_group hte_rank hte_family_n hte_holm_step hte_bh_step
sort moderator_id paper_order estimator spec_id
save `hte_results_final'

export delimited using ///
    "${hte_table_dir}/rd_hte_2013_ccpp_results.csv", ///
    replace nolabel

use `hte_conditional_raw', clear
sort moderator_id paper_order standardized_value
export delimited using ///
    "${hte_table_dir}/rd_hte_2013_ccpp_conditional_effects.csv", ///
    replace nolabel


*-----------------------------------*
**# 8. Project implementation and recorded financing
*-----------------------------------*

tempfile hte_implementation hte_composition hte_dose_results
tempname implementation_post dose_post

postfile `implementation_post' ///
    str20 component_id str60 component_label str24 estimand ///
    double scale estimate standard_error pvalue ci_low ci_high ///
    n_left n_right effective_n first_stage_f ///
    str28 status int estimation_rc ///
    using `hte_implementation', replace

use `hte_analysis_base', clear

local project_group_1 "Productive and livelihood"
local project_group_2 "Social and basic services"
local project_group_3 "Community and civic infrastructure"
local project_group_4 "Management and capacity support"

forvalues project_group = 1/4 {
    capture quietly rdrobust ///
        hte_project_group_`project_group' ${hte_running} ///
        if hte_primary_sample, ///
        c(0) p(1) q(2) ///
        h(${hte_common_h} ${hte_common_h}) ///
        b(${hte_common_b} ${hte_common_b}) ///
        kernel(triangular) ///
        vce(cr2 hte_cluster_dist) ///
        masspoints(adjust)
    local implementation_rc = _rc

    local implementation_estimate .
    local implementation_se .
    local implementation_p .
    local implementation_low .
    local implementation_high .
    local implementation_n_left .
    local implementation_n_right .
    local implementation_n .
    local implementation_status "estimation_failed"

    if !`implementation_rc' {
        local implementation_estimate = 100 * e(tau_bc)
        local implementation_se = 100 * e(se_tau_rb)
        local implementation_p = e(pv_rb)
        local implementation_low = 100 * e(ci_l_rb)
        local implementation_high = 100 * e(ci_r_rb)
        local implementation_n_left = e(N_h_l)
        local implementation_n_right = e(N_h_r)
        local implementation_n = e(N_h_l) + e(N_h_r)
        local implementation_status "estimated"
    }

    post `implementation_post' ///
        ("group_`project_group'") ("`project_group_`project_group''") ///
        ("assignment_discontinuity") (100) ///
        (`implementation_estimate') (`implementation_se') ///
        (`implementation_p') (`implementation_low') ///
        (`implementation_high') (`implementation_n_left') ///
        (`implementation_n_right') (`implementation_n') (.) ///
        ("`implementation_status'") (`implementation_rc')
}

capture quietly rdrobust ///
    hte_financing_pc_1000 ${hte_running} if hte_primary_sample, ///
    c(0) p(1) q(2) ///
    h(${hte_common_h} ${hte_common_h}) ///
    b(${hte_common_b} ${hte_common_b}) ///
    kernel(triangular) ///
    vce(cr2 hte_cluster_dist) ///
    masspoints(adjust)
local financing_stage_rc = _rc

local financing_stage_estimate .
local financing_stage_se .
local financing_stage_p .
local financing_stage_low .
local financing_stage_high .
local financing_stage_n_left .
local financing_stage_n_right .
local financing_stage_n .
local financing_stage_f .
local financing_stage_status "estimation_failed"

if !`financing_stage_rc' {
    local financing_stage_estimate = e(tau_bc)
    local financing_stage_se = e(se_tau_rb)
    local financing_stage_p = e(pv_rb)
    local financing_stage_low = e(ci_l_rb)
    local financing_stage_high = e(ci_r_rb)
    local financing_stage_n_left = e(N_h_l)
    local financing_stage_n_right = e(N_h_r)
    local financing_stage_n = e(N_h_l) + e(N_h_r)
    local financing_stage_f = ///
        (`financing_stage_estimate' / `financing_stage_se')^2
    local financing_stage_status = cond( ///
        `financing_stage_f' > ${hte_weak_f_gate}, ///
        "passes_f_gate", "weak_first_stage")
}

post `implementation_post' ///
    ("financing_pc") ///
    ("Recorded financing per 2007 resident") ///
    ("assignment_discontinuity") (1) ///
    (`financing_stage_estimate') (`financing_stage_se') ///
    (`financing_stage_p') (`financing_stage_low') ///
    (`financing_stage_high') (`financing_stage_n_left') ///
    (`financing_stage_n_right') (`financing_stage_n') ///
    (`financing_stage_f') ("`financing_stage_status'") ///
    (`financing_stage_rc')

postclose `implementation_post'

use `hte_implementation', clear
assert _N == 5
export delimited using ///
    "${hte_table_dir}/rd_hte_2013_ccpp_project_discontinuities.csv", ///
    replace nolabel

use `hte_analysis_base', clear
keep if hte_primary_sample
keep ruv_id
isid ruv_id
tempfile hte_eligible_ids
save `hte_eligible_ids'

use `hte_project_records', clear
merge m:1 ruv_id using `hte_eligible_ids', keep(match) nogen
by ruv_id prc_project_group, sort: generate byte hte_group_community = _n == 1
collapse ///
    (sum) project_records=hte_project_record ///
          communities=hte_group_community ///
          recorded_financing=prc_total_financing_soles, ///
    by(prc_project_group)

egen double total_project_records = total(project_records)
egen double total_recorded_financing = total(recorded_financing)
generate double record_share_pct = 100 * project_records / total_project_records
generate double financing_share_pct = ///
    100 * recorded_financing / total_recorded_financing

decode prc_project_group, generate(project_group_label)
order prc_project_group project_group_label project_records communities ///
    recorded_financing record_share_pct financing_share_pct
isid prc_project_group
save `hte_composition'

export delimited using ///
    "${hte_table_dir}/rd_hte_2013_ccpp_project_composition.csv", ///
    replace nolabel


*-----------------------------------*
**# 9. Exploratory continuous-dose IV
*-----------------------------------*

use `hte_analysis_base', clear

tempvar hte_dose_weight hte_dose_running_right hte_dose_cluster
generate double `hte_dose_weight' = ///
    1 - abs(${hte_running}) / ${hte_common_h} ///
    if abs(${hte_running}) < ${hte_common_h}
generate double `hte_dose_running_right' = ///
    ${hte_running} * hte_assignment

local dose_sample ///
    "hte_primary_sample & `hte_dose_weight' < . & `hte_dose_weight' > 0 & !missing(hte_financing_pc_1000, hte_cluster_dist)"

quietly count if `dose_sample' & ${hte_running} < 0
local dose_n_left = r(N)
quietly count if `dose_sample' & ${hte_running} >= 0
local dose_n_right = r(N)
quietly egen byte `hte_dose_cluster' = tag(hte_cluster_dist) if `dose_sample'
quietly count if `hte_dose_cluster'
local dose_clusters = r(N)

postfile `dose_post' ///
    str12 outcome_id str100 outcome_label double paper_order ///
    estimate standard_error pvalue ci_low ci_high control_sd ///
    standardized_estimate standardized_ci_low standardized_ci_high ///
    kp_f underid_p ar_p n_left n_right clusters ///
    gate_pass str28 gate_status int estimation_rc ///
    using `hte_dose_results', replace

forvalues outcome_index = 1/`outcome_count' {
    local outcome_var "`o_var_`outcome_index''"
    local outcome_id "`o_id_`outcome_index''"
    local outcome_label "`o_label_`outcome_index''"
    local outcome_order = `o_order_`outcome_index''
    local outcome_scale = `o_scale_`outcome_index''

    tempvar hte_dose_outcome
    quietly generate double `hte_dose_outcome' = ///
        `outcome_var' * `outcome_scale'

    capture quietly ivreg2 ///
        `hte_dose_outcome' ${hte_running} `hte_dose_running_right' ///
        (hte_financing_pc_1000 = hte_assignment) ///
        [aw=`hte_dose_weight'] if `dose_sample', ///
        cluster(hte_cluster_dist) first
    local dose_rc = _rc

    local dose_estimate .
    local dose_se .
    local dose_p .
    local dose_low .
    local dose_high .
    local dose_control_sd .
    local dose_standardized .
    local dose_standardized_low .
    local dose_standardized_high .
    local dose_kp_f .
    local dose_underid_p .
    local dose_ar_p .
    local dose_gate_pass 0
    local dose_gate_status "estimation_failed"

    if !`dose_rc' {
        local dose_estimate = _b[hte_financing_pc_1000]
        local dose_se = _se[hte_financing_pc_1000]
        capture quietly test hte_financing_pc_1000
        if !_rc local dose_p = r(p)
        local dose_low = `dose_estimate' - invnormal(.975) * `dose_se'
        local dose_high = `dose_estimate' + invnormal(.975) * `dose_se'
        capture local dose_kp_f = e(widstat)
        capture local dose_underid_p = e(idp)
        capture local dose_ar_p = e(arfp)

        quietly summarize `hte_dose_outcome' if ///
            `dose_sample' & ${hte_running} < 0
        local dose_control_sd = r(sd)
        if `dose_control_sd' > 0 & `dose_control_sd' < . {
            local dose_standardized = `dose_estimate' / `dose_control_sd'
            local dose_standardized_low = `dose_low' / `dose_control_sd'
            local dose_standardized_high = `dose_high' / `dose_control_sd'
        }

        local dose_gate_pass = ///
            `dose_kp_f' < . & `dose_kp_f' > ${hte_weak_f_gate} & ///
            `dose_underid_p' < . & `dose_underid_p' < .05
        local dose_gate_status "pass"
        if missing(`dose_underid_p') | `dose_underid_p' >= .05 ///
            local dose_gate_status "underidentified"
        else if missing(`dose_kp_f') | ///
            `dose_kp_f' <= ${hte_weak_f_gate} ///
            local dose_gate_status "weak_first_stage"
    }

    post `dose_post' ///
        ("`outcome_id'") ("`outcome_label'") (`outcome_order') ///
        (`dose_estimate') (`dose_se') (`dose_p') ///
        (`dose_low') (`dose_high') (`dose_control_sd') ///
        (`dose_standardized') (`dose_standardized_low') ///
        (`dose_standardized_high') (`dose_kp_f') ///
        (`dose_underid_p') (`dose_ar_p') ///
        (`dose_n_left') (`dose_n_right') (`dose_clusters') ///
        (`dose_gate_pass') ("`dose_gate_status'") (`dose_rc')

    drop `hte_dose_outcome'
}

postclose `dose_post'

use `hte_dose_results', clear
assert _N == 8
assert estimation_rc >= 0 & estimation_rc < .
sort paper_order
export delimited using ///
    "${hte_table_dir}/rd_hte_2013_ccpp_financing_dose_iv.csv", ///
    replace nolabel


*-----------------------------------*
**# 10. Publication-facing LaTeX tables
*-----------------------------------*

* Moderator registry.
preserve
import delimited using "${hte_moderator_registry}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if strpos(levels, "ccpp")
keep if inlist(moderator_id, "M01", "M02", "S01", "S02", "S03", "S05")
sort paper_order

tempname registry_tex
file open `registry_tex' using ///
    "${hte_table_dir}/tab_hte_2013_ccpp_01_moderator_registry.tex", ///
    write replace text
file write `registry_tex' "\begin{table}[!htbp]" _n
file write `registry_tex' "\centering" _n
file write `registry_tex' "\caption{Prespecified CCPP-level heterogeneity moderators}" _n
file write `registry_tex' "\label{tab:hte-2013-ccpp-registry}" _n
file write `registry_tex' "\small" _n
file write `registry_tex' "\resizebox{\textwidth}{!}{%" _n
file write `registry_tex' "\begin{tabular}{llll}" _n
file write `registry_tex' "\toprule" _n
file write `registry_tex' "ID & Moderator & Tier & Interpretation limit \\" _n
file write `registry_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local registry_id "`=moderator_id[`row']'"
    local registry_label "`=moderator_label[`row']'"
    local registry_tier "`=proper(tier[`row'])'"
    local registry_limit "`=interpretation_limit[`row']'"
    file write `registry_tex' ///
        "`registry_id' & `registry_label' & `registry_tier' & `registry_limit' \\" _n
}
file write `registry_tex' "\bottomrule" _n
file write `registry_tex' "\end{tabular}}" _n
file write `registry_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The list was fixed before inspecting heterogeneity estimates. Continuous moderators are standardized in the complete SISFOH 2013 CCPP analysis universe. District-capital status uses 2017 spatial coding as a proxy for a fixed location attribute. Sources are documented in the machine-readable moderator registry.}" _n
file write `registry_tex' "\end{table}" _n
file close `registry_tex'
restore

* Common-window instrument and support diagnostics.
use `hte_results_final', clear
keep if spec_id == "common_h_iv" & outcome_id == "P01"
sort moderator_id

tempname diagnostics_tex
file open `diagnostics_tex' using ///
    "${hte_table_dir}/tab_hte_2013_ccpp_02_design_diagnostics.tex", ///
    write replace text
file write `diagnostics_tex' "\begin{table}[!htbp]" _n
file write `diagnostics_tex' "\centering" _n
file write `diagnostics_tex' "\caption{Local support and fuzzy-heterogeneity instrument diagnostics}" _n
file write `diagnostics_tex' "\label{tab:hte-2013-ccpp-diagnostics}" _n
file write `diagnostics_tex' "\small" _n
file write `diagnostics_tex' "\resizebox{\textwidth}{!}{%" _n
file write `diagnostics_tex' "\begin{tabular}{lrrrrrrl}" _n
file write `diagnostics_tex' "\toprule" _n
file write `diagnostics_tex' "Moderator & \(N_-\) & \(N_+\) & Min. cell & SW \(F_D\) & SW \(F_{D\times M}\) & KP \(F\) & Gate \\" _n
file write `diagnostics_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local diagnostics_label "`=moderator_label[`row']'"
    local diagnostics_status "`=gate_status[`row']'"
    local diagnostics_status = subinstr("`diagnostics_status'", "_", " ", .)
    foreach value in n_left n_right min_cell sw_f_treat sw_f_interaction kp_f {
        local diagnostics_`value' : display %6.2f `value'[`row']
        local diagnostics_`value' = strtrim("`diagnostics_`value''")
        if missing(`value'[`row']) local diagnostics_`value' "--"
    }
    file write `diagnostics_tex' ///
        "`diagnostics_label' & `diagnostics_n_left' & `diagnostics_n_right' & `diagnostics_min_cell' & `diagnostics_sw_f_treat' & `diagnostics_sw_f_interaction' & `diagnostics_kp_f' & `diagnostics_status' \\" _n
}
file write `diagnostics_tex' "\bottomrule" _n
file write `diagnostics_tex' "\end{tabular}}" _n
file write `diagnostics_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The common adjacent-B/C window is \(h=0.0075\) and contains 65 complete-outcome communities before moderator-specific missingness. SW denotes the Sanderson--Windmeijer conditional statistic and KP the Kleibergen--Paap rk Wald statistic. A fuzzy interaction requires finite estimates, adequate rank and support, and \(\min(F_D,F_{D\times M})>10\). Binary moderators additionally require at least 10 communities in every side-by-moderator cell. The gate is fixed independently of the outcomes. Sources: RUV, CMAN, SISFOH 2012--2013, and registered baseline data.}" _n
file write `diagnostics_tex' "\end{table}" _n
file close `diagnostics_tex'

* Assignment-effect and fuzzy-LATE interaction tables by moderator tier.
foreach hte_tier in primary secondary {
    local tier_title = proper("`hte_tier'")
    local adjusted_label = cond("`hte_tier'" == "primary", ///
        "Holm \(p\)", "BH \(q\)")

    use `hte_results_final', clear
    keep if spec_id == "common_h_rdhte" & moderator_tier == "`hte_tier'"
    sort moderator_id paper_order

    tempname assignment_tex
    file open `assignment_tex' using ///
        "${hte_table_dir}/tab_hte_2013_ccpp_03_assignment_`hte_tier'.tex", ///
        write replace text
    file write `assignment_tex' "\begin{table}[!htbp]" _n
    file write `assignment_tex' "\centering" _n
    file write `assignment_tex' "\caption{`tier_title' assignment-effect heterogeneity in SISFOH 2013 outcomes}" _n
    file write `assignment_tex' "\label{tab:hte-2013-ccpp-assignment-`hte_tier'}" _n
    file write `assignment_tex' "\small" _n
    file write `assignment_tex' "\resizebox{\textwidth}{!}{%" _n
    file write `assignment_tex' "\begin{tabular}{llrrrrrl}" _n
    file write `assignment_tex' "\toprule" _n
    file write `assignment_tex' "Moderator & Outcome & Estimate & SE & 95\% CI low & 95\% CI high & `adjusted_label' & Support \\" _n
    file write `assignment_tex' "\midrule" _n
    forvalues row = 1/`=_N' {
        local assignment_moderator "`=moderator_label[`row']'"
        local assignment_outcome "`=outcome_label[`row']'"
        local assignment_status "`=gate_status[`row']'"
        local assignment_status = subinstr("`assignment_status'", "_", " ", .)
        foreach value in estimate standard_error ci_low ci_high {
            local assignment_`value' : display %7.2f `value'[`row']
            local assignment_`value' = strtrim("`assignment_`value''")
            if missing(`value'[`row']) local assignment_`value' "--"
        }
        local assignment_adjusted .
        if "`hte_tier'" == "primary" local assignment_adjusted = p_holm[`row']
        else local assignment_adjusted = q_bh[`row']
        local assignment_adjusted_text : display %6.3f `assignment_adjusted'
        local assignment_adjusted_text = strtrim("`assignment_adjusted_text'")
        if missing(`assignment_adjusted') local assignment_adjusted_text "--"
        file write `assignment_tex' ///
            "`assignment_moderator' & `assignment_outcome' & `assignment_estimate' & `assignment_standard_error' & `assignment_ci_low' & `assignment_ci_high' & `assignment_adjusted_text' & `assignment_status' \\" _n
    }
    file write `assignment_tex' "\bottomrule" _n
    file write `assignment_tex' "\end{tabular}}" _n
    file write `assignment_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Entries are robust bias-corrected \texttt{rdhte} slopes in the sharp assignment discontinuity, not fuzzy LATEs. Continuous moderators are measured in analysis-universe standard deviations; binary entries are differences between categories. Outcomes expressed as shares or indices are scaled to percentage points. Estimates use local-linear triangular-kernel fits, \(h=0.0075\), district-clustered inference, and the adjacent B/C sample. Multiplicity is adjusted within estimator and moderator tier. Missing district-capital estimates reflect failed prespecified local support, not a zero effect. Sources: RUV, CMAN, SISFOH 2012--2013, and registered baseline data.}" _n
    file write `assignment_tex' "\end{table}" _n
    file close `assignment_tex'

    use `hte_results_final', clear
    keep if spec_id == "common_h_iv" & moderator_tier == "`hte_tier'"
    sort moderator_id paper_order

    tempname fuzzy_tex
    file open `fuzzy_tex' using ///
        "${hte_table_dir}/tab_hte_2013_ccpp_04_fuzzy_`hte_tier'.tex", ///
        write replace text
    file write `fuzzy_tex' "\begin{table}[!htbp]" _n
    file write `fuzzy_tex' "\centering" _n
    file write `fuzzy_tex' "\caption{`tier_title' fuzzy-LATE interaction diagnostics for SISFOH 2013 outcomes}" _n
    file write `fuzzy_tex' "\label{tab:hte-2013-ccpp-fuzzy-`hte_tier'}" _n
    file write `fuzzy_tex' "\small" _n
    file write `fuzzy_tex' "\resizebox{\textwidth}{!}{%" _n
    file write `fuzzy_tex' "\begin{tabular}{llrrrrrrl}" _n
    file write `fuzzy_tex' "\toprule" _n
    file write `fuzzy_tex' "Moderator & Outcome & Interaction & SE & 95\% CI low & 95\% CI high & Min. SW \(F\) & KP \(F\) & Gate \\" _n
    file write `fuzzy_tex' "\midrule" _n
    forvalues row = 1/`=_N' {
        local fuzzy_moderator "`=moderator_label[`row']'"
        local fuzzy_outcome "`=outcome_label[`row']'"
        local fuzzy_status "`=gate_status[`row']'"
        local fuzzy_status = subinstr("`fuzzy_status'", "_", " ", .)
        foreach value in estimate standard_error ci_low ci_high min_sw_f kp_f {
            local fuzzy_`value' : display %7.2f `value'[`row']
            local fuzzy_`value' = strtrim("`fuzzy_`value''")
            if missing(`value'[`row']) local fuzzy_`value' "--"
        }
        file write `fuzzy_tex' ///
            "`fuzzy_moderator' & `fuzzy_outcome' & `fuzzy_estimate' & `fuzzy_standard_error' & `fuzzy_ci_low' & `fuzzy_ci_high' & `fuzzy_min_sw_f' & `fuzzy_kp_f' & `fuzzy_status' \\" _n
    }
    file write `fuzzy_tex' "\bottomrule" _n
    file write `fuzzy_tex' "\end{tabular}}" _n
    file write `fuzzy_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Each row comes from one pooled, fully interacted local-linear 2SLS model. Treatment and treatment-by-moderator are instrumented by cutoff assignment and assignment-by-moderator; running-variable slopes are interacted on both sides. Triangular weights use \(h=0.0075\), and standard errors are clustered by district. The interaction is not interpretation-ready unless local support and rank conditions hold and the minimum Sanderson--Windmeijer conditional \(F\) is strictly greater than 10. Rows failing a gate are retained as diagnostics and must not be described as causal heterogeneity. Sources: RUV, CMAN, SISFOH 2012--2013, and registered baseline data.}" _n
    file write `fuzzy_tex' "\end{table}" _n
    file close `fuzzy_tex'
}

* Implied population-moderated LATEs from the pooled model.
use `hte_conditional_raw', clear
keep if moderator_id == "M01"
sort paper_order standardized_value

tempname conditional_tex
file open `conditional_tex' using ///
    "${hte_table_dir}/tab_hte_2013_ccpp_05_population_conditional.tex", ///
    write replace text
file write `conditional_tex' "\begin{table}[!htbp]" _n
file write `conditional_tex' "\centering" _n
file write `conditional_tex' "\caption{Implied fuzzy local effects across baseline CCPP population}" _n
file write `conditional_tex' "\label{tab:hte-2013-ccpp-population-conditional}" _n
file write `conditional_tex' "\small" _n
file write `conditional_tex' "\resizebox{\textwidth}{!}{%" _n
file write `conditional_tex' "\begin{tabular}{llrrrrl}" _n
file write `conditional_tex' "\toprule" _n
file write `conditional_tex' "Outcome & Population point & Estimate & SE & 95\% CI low & 95\% CI high & Gate \\" _n
file write `conditional_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local conditional_outcome "`=outcome_label[`row']'"
    local conditional_value "`=value_label[`row']'"
    local conditional_status "`=gate_status[`row']'"
    local conditional_status = subinstr("`conditional_status'", "_", " ", .)
    foreach value in estimate standard_error ci_low ci_high {
        local conditional_`value' : display %7.2f `value'[`row']
        local conditional_`value' = strtrim("`conditional_`value''")
        if missing(`value'[`row']) local conditional_`value' "--"
    }
    file write `conditional_tex' ///
        "`conditional_outcome' & `conditional_value' & `conditional_estimate' & `conditional_standard_error' & `conditional_ci_low' & `conditional_ci_high' & `conditional_status' \\" _n
}
file write `conditional_tex' "\bottomrule" _n
file write `conditional_tex' "\end{tabular}}" _n
file write `conditional_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} P25, P50, and P75 refer to the empirical baseline-population quartiles in the complete SISFOH 2013 CCPP analysis universe. All entries are linear combinations from the same pooled fully interacted fuzzy-RD model; no subgroup is re-estimated. Because the population interaction instruments fail the prespecified rank and strength gates, these estimates are diagnostics rather than credible causal effects. Sources: RUV, CMAN, SISFOH 2012--2013, and INEI 2007 Census tabulations.}" _n
file write `conditional_tex' "\end{table}" _n
file close `conditional_tex'

* Population sensitivity specifications.
use `hte_results_final', clear
keep if moderator_id == "M01" & estimator == "ivreg2" & ///
    inlist(spec_id, "common_h_iv", "common_h_covariates", ///
        "small_h_iv", "large_h_iv")
sort paper_order spec_id
generate str24 spec_label = spec_id
replace spec_label = "Common bandwidth" if spec_id == "common_h_iv"
replace spec_label = "Predetermined covariates" if spec_id == "common_h_covariates"
replace spec_label = "Narrow bandwidth" if spec_id == "small_h_iv"
replace spec_label = "Wide bandwidth" if spec_id == "large_h_iv"

tempname robustness_tex
file open `robustness_tex' using ///
    "${hte_table_dir}/tab_hte_2013_ccpp_06_population_robustness.tex", ///
    write replace text
file write `robustness_tex' "\begin{table}[!htbp]" _n
file write `robustness_tex' "\centering" _n
file write `robustness_tex' "\caption{Population heterogeneity sensitivity specifications}" _n
file write `robustness_tex' "\label{tab:hte-2013-ccpp-population-robustness}" _n
file write `robustness_tex' "\small" _n
file write `robustness_tex' "\resizebox{0.88\textwidth}{!}{%" _n
file write `robustness_tex' "\begin{tabular}{llrrrrl}" _n
file write `robustness_tex' "\toprule" _n
file write `robustness_tex' "Outcome & Specification & Interaction & SE & Min. SW \(F\) & KP \(F\) & Gate \\" _n
file write `robustness_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local robustness_outcome "`=outcome_label[`row']'"
    local robustness_spec "`=spec_label[`row']'"
    local robustness_status "`=gate_status[`row']'"
    local robustness_status = subinstr("`robustness_status'", "_", " ", .)
    foreach value in estimate standard_error min_sw_f kp_f {
        local robustness_`value' : display %7.2f `value'[`row']
        local robustness_`value' = strtrim("`robustness_`value''")
        if missing(`value'[`row']) local robustness_`value' "--"
    }
    file write `robustness_tex' ///
        "`robustness_outcome' & `robustness_spec' & `robustness_estimate' & `robustness_standard_error' & `robustness_min_sw_f' & `robustness_kp_f' & `robustness_status' \\" _n
}
file write `robustness_tex' "\bottomrule" _n
file write `robustness_tex' "\end{tabular}}" _n
file write `robustness_tex' "\parbox{0.97\linewidth}{\scriptsize \textit{Notes:} The common specification is primary. Sensitivities add predetermined covariates or use fixed windows \(h=0.0050\) and \(h=0.0100\); no bandwidth is selected because it strengthens the instrument. The same pooled interaction model and district-clustered inference are used throughout. Failed rank or \(F>10\) gates preclude causal interpretation even when point estimates appear stable. Sources: RUV, CMAN, SISFOH 2012--2013, and registered baseline data.}" _n
file write `robustness_tex' "\end{table}" _n
file close `robustness_tex'

* Project composition and assignment discontinuities.
use `hte_composition', clear
generate str20 component_id = "group_" + string(prc_project_group)
merge 1:1 component_id using `hte_implementation', ///
    keep(match) nogen keepusing(estimate standard_error pvalue)
sort prc_project_group

tempname project_tex
file open `project_tex' using ///
    "${hte_table_dir}/tab_hte_2013_ccpp_07_project_implementation.tex", ///
    write replace text
file write `project_tex' "\begin{table}[!htbp]" _n
file write `project_tex' "\centering" _n
file write `project_tex' "\caption{Project composition and assignment discontinuities through 2012}" _n
file write `project_tex' "\label{tab:hte-2013-ccpp-project-implementation}" _n
file write `project_tex' "\small" _n
file write `project_tex' "\resizebox{\textwidth}{!}{%" _n
file write `project_tex' "\begin{tabular}{lrrrrr}" _n
file write `project_tex' "\toprule" _n
file write `project_tex' "Project group & Records & Communities & Share (\%) & Assignment jump (pp) & SE \\" _n
file write `project_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local project_label "`=project_group_label[`row']'"
    foreach value in record_share_pct estimate standard_error {
        local project_`value' : display %7.2f `value'[`row']
        local project_`value' = strtrim("`project_`value''")
    }
    local project_records_text : display %8.0f project_records[`row']
    local project_records_text = strtrim("`project_records_text'")
    local project_communities_text : display %8.0f communities[`row']
    local project_communities_text = strtrim("`project_communities_text'")
    file write `project_tex' ///
        "`project_label' & `project_records_text' & `project_communities_text' & `project_record_share_pct' & `project_estimate' & `project_standard_error' \\" _n
}
file write `project_tex' "\bottomrule" _n
file write `project_tex' "\end{tabular}}" _n
file write `project_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Composition is descriptive among 199 CMAN project records linked to the 487-community SISFOH analysis universe and recorded by 2012. Communities may appear in more than one project group. Assignment jumps are robust bias-corrected local-linear discontinuities in receiving at least one project of the indicated group, in percentage points, using \(h=0.0075\), triangular weights, mass-point adjustment, and district CR2 inference. Project type is a post-assignment implementation attribute; treated-only outcome comparisons are not labeled causal. Sources: RUV, CMAN, and SISFOH 2012--2013.}" _n
file write `project_tex' "\end{table}" _n
file close `project_tex'

* Exploratory per-capita financing dose IV.
use `hte_dose_results', clear
sort paper_order

tempname dose_tex
file open `dose_tex' using ///
    "${hte_table_dir}/tab_hte_2013_ccpp_08_financing_dose_iv.tex", ///
    write replace text
file write `dose_tex' "\begin{table}[!htbp]" _n
file write `dose_tex' "\centering" _n
file write `dose_tex' "\caption{Exploratory IV estimates using recorded financing per resident}" _n
file write `dose_tex' "\label{tab:hte-2013-ccpp-financing-dose}" _n
file write `dose_tex' "\small" _n
file write `dose_tex' "\resizebox{\textwidth}{!}{%" _n
file write `dose_tex' "\begin{tabular}{lrrrrrrl}" _n
file write `dose_tex' "\toprule" _n
file write `dose_tex' "Outcome & Estimate & SE & 95\% CI low & 95\% CI high & KP \(F\) & AR \(p\) & Gate \\" _n
file write `dose_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local dose_outcome "`=outcome_label[`row']'"
    local dose_status "`=gate_status[`row']'"
    local dose_status = subinstr("`dose_status'", "_", " ", .)
    foreach value in estimate standard_error ci_low ci_high kp_f ar_p {
        local dose_`value' : display %7.2f `value'[`row']
        local dose_`value' = strtrim("`dose_`value''")
        if missing(`value'[`row']) local dose_`value' "--"
    }
    file write `dose_tex' ///
        "`dose_outcome' & `dose_estimate' & `dose_standard_error' & `dose_ci_low' & `dose_ci_high' & `dose_kp_f' & `dose_ar_p' & `dose_status' \\" _n
}
file write `dose_tex' "\bottomrule" _n
file write `dose_tex' "\end{tabular}}" _n
file write `dose_tex' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The endogenous dose is total nominal CMAN financing plus recorded cofinancing through 2012 divided by 2007 population and expressed in thousands of soles per resident. Cutoff assignment is the excluded instrument in a triangular-weighted local-linear model with \(h=0.0075\) and district-clustered inference. The design does not verify disbursement, execution, completion, or cofinancing realization. A linear dose response and a stronger exclusion restriction are required. Because the first stage fails the strict \(F>10\) and rank gates, all entries are exploratory diagnostics. AR denotes the Anderson--Rubin joint test. Sources: RUV, CMAN, SISFOH 2012--2013, and INEI 2007 Census tabulations.}" _n
file write `dose_tex' "\end{table}" _n
file close `dose_tex'


*-----------------------------------*
**# 11. Publication-formatted figures
*-----------------------------------*

* Standardized assignment-effect heterogeneity forests.
foreach moderator_id in M01 S01 S02 S03 S05 {
    use `hte_results_final', clear
    keep if spec_id == "common_h_rdhte" & ///
        moderator_id == "`moderator_id'"
    sort paper_order
    assert _N == 8

    local figure_moderator "Baseline population"
    if "`moderator_id'" == "S01" local figure_moderator "Baseline deprivation"
    if "`moderator_id'" == "S02" local figure_moderator "Remoteness"
    if "`moderator_id'" == "S03" local figure_moderator "Baseline economic development"
    if "`moderator_id'" == "S05" local figure_moderator "Altitude"
    generate byte hte_outcome_axis = 9 - paper_order
    label define hte_outcome_axis ///
        8 "Log rostered population" ///
        7 "Log rostered households" ///
        6 "Residents age 15-29" ///
        5 "Any social program" ///
        4 "Core wellbeing proxy" ///
        3 "Any unmet basic need" ///
        2 "Labor-force participation" ///
        1 "Secondary education or higher", replace
    label values hte_outcome_axis hte_outcome_axis

    twoway ///
        (rcap standardized_ci_low standardized_ci_high hte_outcome_axis, ///
            horizontal lcolor(navy%55) lwidth(medium)) ///
        (scatter hte_outcome_axis standardized_estimate, ///
            mcolor(navy) msymbol(O) msize(medium)), ///
        xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
        ylabel(1(1)8, valuelabel angle(0) labsize(small) nogrid) ///
        xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
        xtitle("Assignment-effect heterogeneity (control-group SDs)", ///
            size(small)) ///
        ytitle("") ///
        title("Assignment heterogeneity: `figure_moderator'", ///
            size(medium) color(black)) ///
        subtitle("rdhte estimates with 95% confidence intervals", ///
            size(small) color(gs5)) ///
        legend(off) ///
        note( ///
            "Notes: Unit is an RUV centro poblado in the linked SISFOH 2013 adjacent-B/C sample." ///
            "Points are robust bias-corrected rdhte slopes in the assignment discontinuity; they are not fuzzy LATEs." ///
            "Continuous moderators are standardized before the local-window restriction; outcomes are scaled by the below-cutoff SD." ///
            "Fits are local linear with triangular weights, h = 0.0075, and district-clustered inference." ///
            "Multiplicity-adjusted tests are reported in the tables. Sources: RUV, CMAN, SISFOH 2012-2013, and registered baseline data.", ///
            size(vsmall) color(gs5) span) ///
        xsize(10) ysize(7) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(hte_assignment_`moderator_id', replace)

    graph export ///
        "${hte_figure_dir}/fig_hte_2013_ccpp_assignment_`moderator_id'.png", ///
        width(3000) replace
}

* Fuzzy-interaction instrument diagnostics.
use `hte_results_final', clear
keep if spec_id == "common_h_iv" & outcome_id == "P01"
sort moderator_id
generate byte hte_diagnostic_axis = 7 - _n
generate double hte_support_failure = 0 if missing(min_sw_f)
generate str14 hte_support_label = "Support fail" if missing(min_sw_f)
label define hte_diagnostic_axis ///
    6 "Population" ///
    5 "District capital" ///
    4 "Deprivation" ///
    3 "Remoteness" ///
    2 "Baseline GDP" ///
    1 "Altitude", replace
label values hte_diagnostic_axis hte_diagnostic_axis

twoway ///
    (scatter hte_diagnostic_axis min_sw_f, ///
        mcolor(navy) msymbol(O) msize(medlarge)) ///
    (scatter hte_diagnostic_axis hte_support_failure ///
        if missing(min_sw_f), ///
        mcolor(maroon) msymbol(X) msize(medlarge) ///
        mlabel(hte_support_label) mlabcolor(maroon) ///
        mlabposition(3) mlabsize(small)), ///
    xline(${hte_weak_f_gate}, lcolor(maroon) lpattern(dash) lwidth(medium)) ///
    xscale(range(0 11.5)) ///
    xlabel(0(2)10, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(1(1)6, valuelabel angle(0) labsize(small) nogrid) ///
    xtitle("Minimum Sanderson-Windmeijer conditional F", size(small)) ///
    ytitle("") ///
    title("Instrument strength for fuzzy heterogeneity", ///
        size(medium) color(black)) ///
    subtitle("Strict interpretation gate: minimum conditional F > 10", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Each point summarizes the common-window pooled model for one moderator; diagnostics do not vary by outcome in the complete-outcome sample." ///
        "Treatment and treatment-by-moderator are instrumented by assignment and assignment-by-moderator." ///
        "District-capital status fails the prespecified minimum of 10 communities in every side-by-status cell, so no F is estimated." ///
        "All estimable interactions fall below the F > 10 gate; rank diagnostics are reported in the table." ///
        "Sources: RUV, CMAN, SISFOH 2012-2013, and registered baseline data.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(6.5) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(hte_instrument_diagnostics, replace)

graph export ///
    "${hte_figure_dir}/fig_hte_2013_ccpp_instrument_diagnostics.png", ///
    width(3000) replace

* District-capital local support.
use `hte_analysis_base', clear
keep if hte_primary_sample & abs(${hte_running}) < ${hte_common_h} & ///
    !missing(hte_m2)
contract hte_assignment hte_m2
rename _freq hte_cell_n
label define hte_assignment_label 0 "Below cutoff" 1 "At or above cutoff"
label values hte_assignment hte_assignment_label
label define hte_capital_label 0 "Not district capital" 1 "District capital"
label values hte_m2 hte_capital_label

graph bar (asis) hte_cell_n, ///
    over(hte_m2, label(labsize(small))) ///
    over(hte_assignment, label(labsize(small))) ///
    blabel(bar, format(%4.0f) size(small) color(black)) ///
    bar(1, color(navy%80) lcolor(navy)) ///
    yline(${hte_min_cell}, lcolor(maroon) lpattern(dash) lwidth(medium)) ///
    ylabel(0(5)35, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Communities in local cell", size(small)) ///
    title("District-capital heterogeneity lacks local support", ///
        size(medium) color(black)) ///
    subtitle("Required minimum: 10 communities in every side-by-status cell", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Unit is an RUV centro poblado in the linked SISFOH 2013 adjacent-B/C sample with complete primary outcomes and district-capital coding." ///
        "Bars count communities inside h = 0.0075; the dashed line marks the prespecified minimum cell size." ///
        "The district-capital moderator is retained in diagnostics but no causal heterogeneity estimate is reported." ///
        "Sources: RUV, SISFOH 2012-2013, and 2017 INEI spatial coding.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(hte_capital_support, replace)

graph export ///
    "${hte_figure_dir}/fig_hte_2013_ccpp_capital_support.png", ///
    width(3000) replace

* Project composition among linked records through 2012.
use `hte_composition', clear
generate byte hte_composition_axis = 5 - prc_project_group
label define hte_composition_axis ///
    4 "Productive and livelihood" ///
    3 "Social and basic services" ///
    2 "Community and civic infrastructure" ///
    1 "Management and capacity support", replace
label values hte_composition_axis hte_composition_axis

twoway ///
    (bar record_share_pct hte_composition_axis, ///
        horizontal barwidth(.62) fcolor(navy%78) lcolor(navy)) ///
    (scatter hte_composition_axis record_share_pct, ///
        msymbol(none) mlabel(record_share_pct) ///
        mlabformat(%4.1f) mlabposition(3) mlabsize(small) ///
        mlabcolor(black)), ///
    xscale(range(0 60)) ///
    xlabel(0(10)60, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(1(1)4, valuelabel angle(0) labsize(small) nogrid) ///
    xtitle("Share of project records (percent)", size(small)) ///
    ytitle("") ///
    title("Composition of linked collective-reparation projects", ///
        size(medium) color(black)) ///
    subtitle("CMAN records through 2012 in the SISFOH analysis universe", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Bars classify 199 CMAN project records linked to the 487-community SISFOH 2013 analysis universe." ///
        "Shares describe records, not mutually exclusive communities; a community can receive more than one project." ///
        "Project type is post-assignment and is not used as an ordinary causal moderator." ///
        "Source: CMAN communities-attended register linked to RUV and SISFOH 2012-2013.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(hte_project_composition, replace)

graph export ///
    "${hte_figure_dir}/fig_hte_2013_ccpp_project_composition.png", ///
    width(3000) replace

* Assignment discontinuities in broad project-group receipt.
use `hte_implementation', clear
keep if strpos(component_id, "group_") == 1
sort component_id
generate byte hte_project_axis = 5 - _n
label define hte_project_axis ///
    4 "Productive and livelihood" ///
    3 "Social and basic services" ///
    2 "Community and civic infrastructure" ///
    1 "Management and capacity support", replace
label values hte_project_axis hte_project_axis

twoway ///
    (rcap ci_low ci_high hte_project_axis, ///
        horizontal lcolor(navy%55) lwidth(medium)) ///
    (scatter hte_project_axis estimate, ///
        mcolor(navy) msymbol(O) msize(medium)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    ylabel(1(1)4, valuelabel angle(0) labsize(small) nogrid) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Assignment discontinuity (percentage points)", size(small)) ///
    ytitle("") ///
    title("Cutoff discontinuities in project-group receipt", ///
        size(medium) color(black)) ///
    subtitle("Robust bias-corrected estimates with 95% confidence intervals", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Outcomes indicate receipt of at least one CMAN project in the broad group through 2012." ///
        "Estimates use the linked SISFOH 2013 adjacent-B/C community sample, local-linear triangular fits, h = 0.0075, mass-point adjustment, and district CR2 inference." ///
        "These are implementation discontinuities; project type is not treated as an exogenous moderator of outcomes." ///
        "Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(6.5) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(hte_project_discontinuities, replace)

graph export ///
    "${hte_figure_dir}/fig_hte_2013_ccpp_project_discontinuities.png", ///
    width(3000) replace

* Exploratory financing-dose outcome forest.
use `hte_dose_results', clear
sort paper_order
generate byte hte_dose_axis = 9 - paper_order
label define hte_outcome_axis ///
    8 "Log rostered population" ///
    7 "Log rostered households" ///
    6 "Residents age 15-29" ///
    5 "Any social program" ///
    4 "Core wellbeing proxy" ///
    3 "Any unmet basic need" ///
    2 "Labor-force participation" ///
    1 "Secondary education or higher", replace
label values hte_dose_axis hte_outcome_axis
local dose_kp_text : display %5.2f kp_f[1]
local dose_underid_text : display %5.3f underid_p[1]
foreach formatted_value in dose_kp_text dose_underid_text {
    local `formatted_value' = strtrim("``formatted_value''")
}

twoway ///
    (rcap standardized_ci_low standardized_ci_high hte_dose_axis, ///
        horizontal lcolor(navy%55) lwidth(medium)) ///
    (scatter hte_dose_axis standardized_estimate, ///
        mcolor(navy) msymbol(O) msize(medium)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    ylabel(1(1)8, valuelabel angle(0) labsize(small) nogrid) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Outcome effect per 1,000 recorded soles per resident (SDs)", ///
        size(small)) ///
    ytitle("") ///
    title("Exploratory recorded-financing dose IV", ///
        size(medium) color(black)) ///
    subtitle("KP F = `dose_kp_text'; underidentification p = `dose_underid_text'; gate not met", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: The endogenous dose is nominal CMAN financing plus recorded cofinancing through 2012 per 2007 resident." ///
        "Cutoff assignment is the excluded instrument in a local-linear triangular-weighted model with h = 0.0075 and district-clustered inference." ///
        "The design does not verify disbursement, execution, completion, or cofinancing realization." ///
        "Because strength and rank gates fail, points are exploratory diagnostics rather than causal estimates." ///
        "Sources: RUV, CMAN, SISFOH 2012-2013, and INEI 2007 Census tabulations.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(hte_financing_dose, replace)

graph export ///
    "${hte_figure_dir}/fig_hte_2013_ccpp_financing_dose_iv.png", ///
    width(3000) replace

* Binned first-stage plot for the recorded financing dose.
use `hte_analysis_base', clear
capture drop rdplot_*
quietly rdplot ///
    hte_financing_pc_1000 ${hte_running} if ///
        hte_primary_sample & abs(${hte_running}) <= ${hte_common_h}, ///
    c(0) p(1) ///
    h(${hte_common_h} ${hte_common_h}) ///
    kernel(triangular) binselect(qsmv) ///
    masspoints(adjust) ci(95) genvars hide

tempvar hte_rdplot_tag
egen byte `hte_rdplot_tag' = tag(rdplot_id) if !missing(rdplot_id)
local financing_stage_text : display %5.2f `financing_stage_estimate'
local financing_stage_p_text : display %5.3f `financing_stage_p'
local financing_stage_f_text : display %5.2f `financing_stage_f'
foreach formatted_value in ///
    financing_stage_text financing_stage_p_text financing_stage_f_text {
    local `formatted_value' = strtrim("``formatted_value''")
}

twoway ///
    (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
        if `hte_rdplot_tag' & rdplot_mean_x < 0, ///
        lcolor(navy%48) lwidth(vthin)) ///
    (scatter rdplot_mean_y rdplot_mean_x ///
        if `hte_rdplot_tag' & rdplot_mean_x < 0, ///
        mcolor(navy) msymbol(O) msize(small)) ///
    (line rdplot_hat_y ${hte_running} if ///
        hte_primary_sample & ${hte_running} < 0 & ///
        ${hte_running} >= -${hte_common_h}, ///
        sort lcolor(navy) lwidth(medthick)) ///
    (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
        if `hte_rdplot_tag' & rdplot_mean_x >= 0, ///
        lcolor(maroon%48) lwidth(vthin)) ///
    (scatter rdplot_mean_y rdplot_mean_x ///
        if `hte_rdplot_tag' & rdplot_mean_x >= 0, ///
        mcolor(maroon) msymbol(D) msize(small)) ///
    (line rdplot_hat_y ${hte_running} if ///
        hte_primary_sample & ${hte_running} >= 0 & ///
        ${hte_running} <= ${hte_common_h}, ///
        sort lcolor(maroon) lwidth(medthick)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(, format(%6.3f) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    ylabel(, angle(0) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    xtitle("Victimization index centered at B-C", size(small)) ///
    ytitle("Thousands of recorded soles per 2007 resident", size(small)) ///
    title("Assignment discontinuity in recorded financing per resident", ///
        size(medium) color(black)) ///
    subtitle("Jump = `financing_stage_text'; robust p = `financing_stage_p_text'; Fz = `financing_stage_f_text'", ///
        size(small) color(gs5)) ///
    legend(order(2 "Below cutoff" 5 "At or above cutoff" ///
        3 "Local-linear fits") rows(1) position(6) ///
        size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is an RUV centro poblado in the linked SISFOH 2013 adjacent-B/C complete-outcome sample." ///
        "Points are quantile-spaced variance-mimicking binned means; bars are 95% bin confidence intervals." ///
        "Lines use triangular-kernel local-linear fits inside h = 0.0075." ///
        "The subtitle reports the robust bias-corrected assignment jump with district CR2 and mass-point adjustment." ///
        "Recorded amounts are not verified as executed or completed. Sources: RUV, CMAN, SISFOH 2012-2013, and INEI 2007 Census tabulations.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(hte_financing_first_stage, replace)

graph export ///
    "${hte_figure_dir}/fig_hte_2013_ccpp_financing_first_stage.png", ///
    width(3000) replace


*-----------------------------------*
**# 12. Output validation, manifest, and closeout
*-----------------------------------*

use `hte_results_final', clear
quietly count if spec_id == "common_h_rdhte" & ///
    moderator_type == "continuous" & estimation_rc == 0
assert r(N) == 40
quietly count if spec_id == "common_h_rdhte" & ///
    moderator_id == "M02" & gate_status == "insufficient_support"
assert r(N) == 8
quietly count if spec_id == "common_h_iv" & gate_pass == 1
local fuzzy_interactions_passing_gate = r(N)

use `hte_dose_results', clear
quietly count if gate_pass == 1
local dose_outcomes_passing_gate = r(N)

local output_paths ///
    output/tables/rd_heterogeneity/rd_hte_2013_ccpp_results.csv ///
    output/tables/rd_heterogeneity/rd_hte_2013_ccpp_conditional_effects.csv ///
    output/tables/rd_heterogeneity/rd_hte_2013_ccpp_project_discontinuities.csv ///
    output/tables/rd_heterogeneity/rd_hte_2013_ccpp_project_composition.csv ///
    output/tables/rd_heterogeneity/rd_hte_2013_ccpp_financing_dose_iv.csv ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_01_moderator_registry.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_02_design_diagnostics.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_03_assignment_primary.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_03_assignment_secondary.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_04_fuzzy_primary.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_04_fuzzy_secondary.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_05_population_conditional.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_06_population_robustness.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_07_project_implementation.tex ///
    output/tables/rd_heterogeneity/tab_hte_2013_ccpp_08_financing_dose_iv.tex ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_assignment_M01.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_assignment_S01.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_assignment_S02.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_assignment_S03.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_assignment_S05.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_instrument_diagnostics.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_capital_support.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_project_composition.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_project_discontinuities.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_financing_dose_iv.png ///
    output/figures/rd_heterogeneity/fig_hte_2013_ccpp_financing_first_stage.png

tempname manifest_file
file open `manifest_file' using "${hte_manifest_2013_ccpp}", ///
    write replace text
file write `manifest_file' ///
    "path,artifact_type,input_data,input_datasignature,generator,run_id,checksum,review_status" _n

foreach output_path of local output_paths {
    local absolute_output "${project_root}/`output_path'"
    capture confirm file "`absolute_output'"
    if _rc {
        display as error "Expected heterogeneity output was not created:"
        display as error "  `absolute_output'"
        file close `manifest_file'
        log close victimasrd_hte_2013_ccpp
        exit 603
    }

    quietly checksum "`absolute_output'"
    local output_checksum : display %20.0f r(checksum)
    local output_checksum = strtrim("`output_checksum'")
    local artifact_type "table"
    if strpos("`output_path'", "output/figures/") == 1 {
        local artifact_type "figure"
    }

    file write `manifest_file' ///
        `""`output_path'","`artifact_type'","11_community_registry_sisfoh_2013.dta;03_cman_projects_2023.dta","`input_datasignature'","code/stata/pipeline/05a_sisfoh2013_ccpp_heterogeneity.do","${hte_run_id}","`output_checksum'","generated_unreviewed""' _n
}

file close `manifest_file'

capture program drop _vrd_post_hte_iv
capture program drop _vrd_post_hte_rdhte

display as result "SISFOH 2013 CCPP heterogeneity module completed."
display as text "Primary linked B/C communities: 487"
display as text "Common fixed-window communities: 65"
display as text ///
    "Common fuzzy interactions passing all gates: `fuzzy_interactions_passing_gate'"
display as text ///
    "Financing-dose outcomes passing all gates: `dose_outcomes_passing_gate'"
display as text "Interpretation gate: minimum conditional F > ${hte_weak_f_gate}"
display as text "Review status: generated_unreviewed"

log close victimasrd_hte_2013_ccpp
exit 0
