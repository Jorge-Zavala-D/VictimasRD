/*
Project: Victimas RD
Purpose: Shared engine for household- and individual-level SISFOH 2013
         regression-discontinuity heterogeneity modules
Note:    Called by 05b and 05c after level-specific input, outcome, sample,
         and key validation. This is not a standalone pipeline module.
*/

version 19
set more off


*-----------------------------------*
**# 1. Shared contract and registries
*-----------------------------------*

local required_globals ///
    hte_level hte_level_caption hte_unit_label hte_unit_plural ///
    hte_observation_weight_id hte_observation_weight_label ///
    hte_outcome_registry_level hte_applicable_moderators ///
    hte_expected_results hte_expected_support_rows ///
    hte_input_basename hte_input_datasignature hte_module_current ///
    hte_manifest_current hte_output_stub hte_primary_outcomes ///
    hte_running hte_treatment_2013 hte_common_h hte_small_h ///
    hte_large_h hte_weak_f_gate hte_min_cell ///
    hte_primary_covariates hte_moderator_registry ///
    hte_figure_dir hte_table_dir project_root

foreach required_global of local required_globals {
    if `"${`required_global'}"' == "" {
        display as error ///
            "Required heterogeneity global is undefined: `required_global'"
        exit 198
    }
}

local output_stub "${hte_output_stub}"
local level "${hte_level}"
local level_caption "${hte_level_caption}"
local unit_label "${hte_unit_label}"
local unit_plural "${hte_unit_plural}"
local applicable_moderators "${hte_applicable_moderators}"

preserve
import delimited using "${hte_outcome_registry_level}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if tier == "primary"
sort paper_order
isid outcome_id
isid paper_order
assert _N == 8
assert inlist(scale, 1, 100)

local outcome_count = _N
forvalues outcome_index = 1/`outcome_count' {
    local o_order_`outcome_index' = paper_order[`outcome_index']
    local o_id_`outcome_index' = outcome_id[`outcome_index']
    local o_var_`outcome_index' = outcome_var[`outcome_index']
    local o_label_`outcome_index' = outcome_label[`outcome_index']
    local o_scale_`outcome_index' = scale[`outcome_index']
}
restore

local declared_outcome_count : word count ${hte_primary_outcomes}
assert `declared_outcome_count' == `outcome_count'

forvalues outcome_index = 1/`outcome_count' {
    local outcome_var "`o_var_`outcome_index''"
    confirm variable `outcome_var'
    local declared_outcome : word `outcome_index' of ${hte_primary_outcomes}
    assert "`outcome_var'" == "`declared_outcome'"
}

preserve
import delimited using "${hte_moderator_registry}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
generate byte selected_moderator = 0
foreach moderator_id of local applicable_moderators {
    replace selected_moderator = 1 if moderator_id == "`moderator_id'"
}
keep if selected_moderator
drop selected_moderator
sort paper_order
isid moderator_id
assert status == "approved"

local moderator_count = _N
local declared_moderator_count : word count `applicable_moderators'
assert `moderator_count' == `declared_moderator_count'

forvalues moderator_index = 1/`moderator_count' {
    local m_order_`moderator_index' = paper_order[`moderator_index']
    local m_id_`moderator_index' = moderator_id[`moderator_index']
    local m_source_`moderator_index' = ///
        moderator_var_2013[`moderator_index']
    local m_label_`moderator_index' = moderator_label[`moderator_index']
    local m_tier_`moderator_index' = tier[`moderator_index']
    local m_type_`moderator_index' = type[`moderator_index']
    local m_limit_`moderator_index' = ///
        interpretation_limit[`moderator_index']
}
restore


*-----------------------------------*
**# 2. Moderator scaling and local support
*-----------------------------------*

forvalues moderator_index = 1/`moderator_count' {
    local moderator_source "`m_source_`moderator_index''"
    local moderator_id "`m_id_`moderator_index''"
    local moderator_type "`m_type_`moderator_index''"
    local moderator_var "hte_m`moderator_index'"

    confirm variable `moderator_source'

    local observation_varying = ///
        "`level'" == "individual" & ///
        inlist("`moderator_id'", "M03", "S04")

    if "`moderator_type'" == "continuous" {
        if `observation_varying' {
            quietly summarize `moderator_source' ///
                if hte_primary_sample, detail
            local m_mean_`moderator_index' = r(mean)
            local m_sd_`moderator_index' = r(sd)
            local m_raw25_`moderator_index' = r(p25)
            local m_raw50_`moderator_index' = r(p50)
            local m_raw75_`moderator_index' = r(p75)
        }
        else {
            preserve
            keep if hte_primary_sample
            egen byte moderator_ruv_tag = tag(hte_cluster_ruv)
            keep if moderator_ruv_tag
            quietly summarize `moderator_source', detail
            local m_mean_`moderator_index' = r(mean)
            local m_sd_`moderator_index' = r(sd)
            local m_raw25_`moderator_index' = r(p25)
            local m_raw50_`moderator_index' = r(p50)
            local m_raw75_`moderator_index' = r(p75)
            restore
        }

        assert `m_sd_`moderator_index'' > 0 & ///
            `m_sd_`moderator_index'' < .

        local m_eval25_`moderator_index' = ///
            (`m_raw25_`moderator_index'' - ///
             `m_mean_`moderator_index'') / ///
            `m_sd_`moderator_index''
        local m_eval50_`moderator_index' = ///
            (`m_raw50_`moderator_index'' - ///
             `m_mean_`moderator_index'') / ///
            `m_sd_`moderator_index''
        local m_eval75_`moderator_index' = ///
            (`m_raw75_`moderator_index'' - ///
             `m_mean_`moderator_index'') / ///
            `m_sd_`moderator_index''

        generate double `moderator_var' = ///
            (`moderator_source' - `m_mean_`moderator_index'') / ///
            `m_sd_`moderator_index''
    }
    else {
        assert inlist(`moderator_source', 0, 1) ///
            if hte_primary_sample & !missing(`moderator_source')
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

* All planned estimators use h no wider than hte_large_h.
keep if hte_primary_sample & abs(${hte_running}) < ${hte_large_h}
assert _N > 0

tempfile hte_analysis_base hte_support
save `hte_analysis_base'

tempname support_post
postfile `support_post' ///
    double moderator_order str8 moderator_id str80 moderator_label ///
    str12 moderator_tier str12 moderator_type ///
    str8 side_label double moderator_value str24 category_label ///
    long observations int ccpp_clusters ///
    using `hte_support', replace

forvalues moderator_index = 1/`moderator_count' {
    local moderator_var "hte_m`moderator_index'"
    local moderator_id "`m_id_`moderator_index''"
    local moderator_label "`m_label_`moderator_index''"
    local moderator_tier "`m_tier_`moderator_index''"
    local moderator_type "`m_type_`moderator_index''"

    local category_count = 1
    if "`moderator_type'" == "binary" local category_count = 2

    forvalues side = 0/1 {
        local side_label = cond(`side' == 0, "Below", "Above")

        forvalues category_index = 1/`category_count' {
            local category_value .
            local category_label "All eligible"
            local category_condition ""

            if "`moderator_type'" == "binary" {
                local category_value = `category_index' - 1
                local category_condition "& `moderator_var' == `category_value'"
                local category_label = cond(`category_value' == 0, "No", "Yes")
                if "`moderator_id'" == "M02" {
                    local category_label = cond(`category_value' == 0, ///
                        "Non-capital", "District capital")
                }
                if "`moderator_id'" == "M03" {
                    local category_label = cond(`category_value' == 0, ///
                        "Men", "Women")
                }
            }

            quietly count if ///
                hte_assignment == `side' & ///
                abs(${hte_running}) < ${hte_common_h} ///
                `category_condition'
            local support_observations = r(N)

            tempvar support_tag
            quietly egen byte `support_tag' = tag(hte_cluster_ruv) if ///
                hte_assignment == `side' & ///
                abs(${hte_running}) < ${hte_common_h} ///
                `category_condition'
            quietly count if `support_tag'
            local support_clusters = r(N)
            drop `support_tag'

            post `support_post' ///
                (`m_order_`moderator_index'') ///
                ("`moderator_id'") ("`moderator_label'") ///
                ("`moderator_tier'") ("`moderator_type'") ///
                ("`side_label'") (`category_value') ///
                ("`category_label'") ///
                (`support_observations') (`support_clusters')
        }
    }
}

postclose `support_post'

use `hte_support', clear
assert _N == ${hte_expected_support_rows}
isid moderator_id side_label category_label
sort moderator_order side_label moderator_value
export delimited using ///
    "${hte_table_dir}/rd_hte_`output_stub'_support.csv", ///
    replace nolabel

use `hte_analysis_base', clear


*-----------------------------------*
**# 3. Pooled, fully interacted fuzzy local IV
*-----------------------------------*

capture program drop _vrd_post_level_hte_iv

program define _vrd_post_level_hte_iv
    version 19
    syntax, ///
        POSTHandle(name) CONDHandle(name) ///
        OUTVAR(name) OUTCOMEID(string) OUTLABel(string) ///
        PAPEROrder(real) SCALE(real) ///
        MODVAR(name) MODID(string) MODLABel(string) ///
        MODOrder(real) MODTIER(string) MODTYPE(string) ///
        SPECID(string) HValue(real) ///
        EVAL1(real) EVAL2(real) EVAL3(real) ///
        RAW1(real) RAW2(real) RAW3(real) ///
        WEIGHTING(string) CLUSTERVAR(name) CLUSTERRULE(string) ///
        [COVariates(varlist)]

    tempvar y_scaled kernel_weight unit_weight analysis_weight ///
        eligible eligible_count running_right ///
        assignment_m treatment_m running_m running_right_m ///
        covariate_missing side_tag cell_tag cluster_tag

    quietly generate double `y_scaled' = `outvar' * `scale'
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
        "abs(${hte_running}) < `hvalue' & !missing(`y_scaled', `modvar', ${hte_treatment_2013}, `clustervar')"

    if "`covariates'" != "" {
        quietly egen byte `covariate_missing' = rowmiss(`covariates')
        local estimator_sample ///
            "`estimator_sample' & `covariate_missing' == 0"
    }

    quietly generate byte `eligible' = `estimator_sample'
    bysort hte_cluster_ruv: egen long `eligible_count' = total(`eligible')

    quietly generate double `unit_weight' = 1 if `eligible'
    if "`weighting'" == "ccpp_equal" {
        quietly replace `unit_weight' = 1 / `eligible_count' ///
            if `eligible' & `eligible_count' > 0
    }
    else if "`weighting'" != "${hte_observation_weight_id}" {
        display as error "Unknown heterogeneity weighting rule: `weighting'"
        exit 198
    }

    quietly generate double `kernel_weight' = ///
        1 - abs(${hte_running}) / `hvalue' if `eligible'
    quietly generate double `analysis_weight' = ///
        `kernel_weight' * `unit_weight' if `eligible'
    quietly replace `eligible' = 0 if ///
        missing(`analysis_weight') | `analysis_weight' <= 0

    quietly count if `eligible' & hte_assignment == 0
    local n_left = r(N)
    quietly count if `eligible' & hte_assignment == 1
    local n_right = r(N)
    local min_obs_cell = min(`n_left', `n_right')

    quietly egen byte `side_tag' = ///
        tag(hte_cluster_ruv hte_assignment) if `eligible'
    quietly count if `side_tag' & hte_assignment == 0
    local ccpp_left = r(N)
    quietly count if `side_tag' & hte_assignment == 1
    local ccpp_right = r(N)
    local min_cluster_cell = min(`ccpp_left', `ccpp_right')

    if "`modtype'" == "binary" {
        local min_obs_cell = .
        local min_cluster_cell = .

        quietly egen byte `cell_tag' = ///
            tag(hte_cluster_ruv hte_assignment `modvar') if `eligible'

        forvalues side = 0/1 {
            forvalues category = 0/1 {
                quietly count if ///
                    `eligible' & hte_assignment == `side' & ///
                    `modvar' == `category'
                local cell_observations = r(N)
                local min_obs_cell = ///
                    min(`min_obs_cell', `cell_observations')

                quietly count if ///
                    `cell_tag' & hte_assignment == `side' & ///
                    `modvar' == `category'
                local cell_clusters = r(N)
                local min_cluster_cell = ///
                    min(`min_cluster_cell', `cell_clusters')
            }
        }
    }

    local support_pass = ///
        `min_obs_cell' >= ${hte_min_cell} & ///
        `min_cluster_cell' >= ${hte_min_cell}

    quietly egen byte `cluster_tag' = tag(`clustervar') if `eligible'
    quietly count if `cluster_tag'
    local clusters = r(N)

    local estimation_rc = 2001
    if `support_pass' {
        capture quietly ivreg2 ///
            `y_scaled' ///
            `modvar' ${hte_running} `running_right' ///
            `running_m' `running_right_m' ///
            `covariates' ///
            (${hte_treatment_2013} `treatment_m' = ///
                hte_assignment `assignment_m') ///
            [aw=`analysis_weight'] if `eligible', ///
            cluster(`clustervar') first
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
    local sw_f_treat .
    local sw_f_interaction .
    local min_sw_f .
    local underid_p .
    local ar_p .
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
            local ci_low = ///
                `estimate' - invnormal(.975) * `standard_error'
            local ci_high = ///
                `estimate' + invnormal(.975) * `standard_error'
        }

        quietly summarize `y_scaled' [aw=`unit_weight'] if ///
            `eligible' & hte_assignment == 0
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
                local min_sw_f = ///
                    min(`sw_f_treat', `sw_f_interaction')
            }
        }

        local gate_pass = ///
            `support_pass' & ///
            `min_sw_f' < . & ///
            `min_sw_f' > ${hte_weak_f_gate} & ///
            `underid_p' < . & `underid_p' < .05

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
        ("`modid'") ("`modlabel'") (`modorder') ///
        ("`modtier'") ("`modtype'") ///
        ("`specid'") ("ivreg2") ("fuzzy_late_interaction") ///
        ("`weighting'") ("`clusterrule'") ///
        (`hvalue') (`n_left') (`n_right') ///
        (`ccpp_left') (`ccpp_right') ///
        (`min_obs_cell') (`min_cluster_cell') (`clusters') ///
        (`support_pass') ///
        (`estimate') (`standard_error') (`pvalue') ///
        (`ci_low') (`ci_high') (`control_sd') ///
        (`standardized_estimate') ///
        (`standardized_ci_low') (`standardized_ci_high') ///
        (`kp_f') (`sw_f_treat') (`sw_f_interaction') ///
        (`min_sw_f') (`underid_p') (`ar_p') ///
        (`gate_pass') ("`gate_status'") (`estimation_rc')

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
                local eval_index = `value_index'
                if `value_index' == 2 local eval_index = 3
                local eval_value = `eval`eval_index''
                local raw_value = `raw`eval_index''
                local value_label = cond(`value_index' == 1, "No", "Yes")
                if "`modid'" == "M02" {
                    local value_label = cond(`value_index' == 1, ///
                        "Non-capital", "District capital")
                }
                if "`modid'" == "M03" {
                    local value_label = cond(`value_index' == 1, ///
                        "Men", "Women")
                }
            }

            capture quietly lincom ///
                ${hte_treatment_2013} + ///
                `eval_value' * `treatment_m'

            local conditional_estimate .
            local conditional_se .
            local conditional_p .
            local conditional_low .
            local conditional_high .
            local conditional_standardized .
            local conditional_standardized_low .
            local conditional_standardized_high .

            if !_rc {
                local conditional_estimate = r(estimate)
                local conditional_se = r(se)
                local conditional_p = r(p)
                local conditional_low = r(lb)
                local conditional_high = r(ub)

                if `control_sd' > 0 & `control_sd' < . {
                    local conditional_standardized = ///
                        `conditional_estimate' / `control_sd'
                    local conditional_standardized_low = ///
                        `conditional_low' / `control_sd'
                    local conditional_standardized_high = ///
                        `conditional_high' / `control_sd'
                }
            }

            post `condhandle' ///
                ("`outcomeid'") ("`outlabel'") (`paperorder') ///
                ("`modid'") ("`modlabel'") (`modorder') ///
                ("`modtier'") ("`value_label'") ///
                (`raw_value') (`eval_value') ///
                (`conditional_estimate') (`conditional_se') ///
                (`conditional_p') (`conditional_low') ///
                (`conditional_high') (`control_sd') ///
                (`conditional_standardized') ///
                (`conditional_standardized_low') ///
                (`conditional_standardized_high') ///
                (`gate_pass') ("`gate_status'")
        }
    }
end


*-----------------------------------*
**# 4. Secondary rdhte assignment effects
*-----------------------------------*

capture program drop _vrd_post_level_hte_rdhte

program define _vrd_post_level_hte_rdhte
    version 19
    syntax, ///
        POSTHandle(name) OUTVAR(name) OUTCOMEID(string) ///
        OUTLABel(string) PAPEROrder(real) SCALE(real) ///
        MODVAR(name) MODID(string) MODLABel(string) ///
        MODOrder(real) MODTIER(string) MODTYPE(string) ///
        HValue(real)

    tempvar y_scaled eligible eligible_count unit_weight ///
        side_tag cell_tag cluster_tag

    quietly generate double `y_scaled' = `outvar' * `scale'
    quietly generate byte `eligible' = ///
        abs(${hte_running}) < `hvalue' & ///
        !missing(`y_scaled', `modvar', hte_cluster_ruv)

    bysort hte_cluster_ruv: egen long `eligible_count' = total(`eligible')
    quietly generate double `unit_weight' = ///
        1 / `eligible_count' if `eligible' & `eligible_count' > 0

    quietly count if `eligible' & hte_assignment == 0
    local n_left = r(N)
    quietly count if `eligible' & hte_assignment == 1
    local n_right = r(N)
    local min_obs_cell = min(`n_left', `n_right')

    quietly egen byte `side_tag' = ///
        tag(hte_cluster_ruv hte_assignment) if `eligible'
    quietly count if `side_tag' & hte_assignment == 0
    local ccpp_left = r(N)
    quietly count if `side_tag' & hte_assignment == 1
    local ccpp_right = r(N)
    local min_cluster_cell = min(`ccpp_left', `ccpp_right')

    if "`modtype'" == "binary" {
        local min_obs_cell = .
        local min_cluster_cell = .
        quietly egen byte `cell_tag' = ///
            tag(hte_cluster_ruv hte_assignment `modvar') if `eligible'

        forvalues side = 0/1 {
            forvalues category = 0/1 {
                quietly count if ///
                    `eligible' & hte_assignment == `side' & ///
                    `modvar' == `category'
                local cell_observations = r(N)
                local min_obs_cell = ///
                    min(`min_obs_cell', `cell_observations')

                quietly count if ///
                    `cell_tag' & hte_assignment == `side' & ///
                    `modvar' == `category'
                local cell_clusters = r(N)
                local min_cluster_cell = ///
                    min(`min_cluster_cell', `cell_clusters')
            }
        }
    }

    local support_pass = ///
        `min_obs_cell' >= ${hte_min_cell} & ///
        `min_cluster_cell' >= ${hte_min_cell}

    quietly egen byte `cluster_tag' = tag(hte_cluster_ruv) if `eligible'
    quietly count if `cluster_tag'
    local clusters = r(N)

    local hte_option "covs_hte(`modvar')"
    if "`modtype'" == "binary" ///
        local hte_option "covs_hte(i.`modvar') labels"

    local estimation_rc = 2001
    if `support_pass' {
        capture quietly rdhte ///
            `y_scaled' ${hte_running} if `eligible', ///
            `hte_option' h(`hvalue') ///
            weights(`unit_weight') ///
            vce(cluster hte_cluster_ruv)
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

    if !`estimation_rc' {
        if "`modtype'" == "continuous" {
            matrix hte_tau_bc = e(tau_bc)
            matrix hte_se = e(tau_se)
            matrix hte_p = e(tau_pv)
            matrix hte_low = e(tau_ci_lb)
            matrix hte_high = e(tau_ci_ub)

            local estimate = hte_tau_bc[1, 2]
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
                local standard_error = r(se)
                local pvalue = r(p)
                local ci_low = r(lb)
                local ci_high = r(ub)
            }
        }

        if missing(`estimate') | missing(`standard_error') {
            local estimation_rc = 504
        }
        else {
            quietly summarize `y_scaled' [aw=`unit_weight'] if ///
                `eligible' & hte_assignment == 0
            local control_sd = r(sd)
            if `control_sd' > 0 & `control_sd' < . {
                local standardized_estimate = `estimate' / `control_sd'
                local standardized_ci_low = `ci_low' / `control_sd'
                local standardized_ci_high = `ci_high' / `control_sd'
            }
        }
    }

    local gate_status = cond(`support_pass', ///
        "secondary_assignment_supported", "insufficient_support")
    if `estimation_rc' & `support_pass' ///
        local gate_status "estimation_failed"

    * rdhte never passes the fuzzy-IV identification gate.
    post `posthandle' ///
        ("`outcomeid'") ("`outvar'") ("`outlabel'") ///
        (`paperorder') (`scale') ///
        ("`modid'") ("`modlabel'") (`modorder') ///
        ("`modtier'") ("`modtype'") ///
        ("common_h_rdhte") ("rdhte") ("assignment_hte") ///
        ("ccpp_equal") ("ccpp") ///
        (`hvalue') (`n_left') (`n_right') ///
        (`ccpp_left') (`ccpp_right') ///
        (`min_obs_cell') (`min_cluster_cell') (`clusters') ///
        (`support_pass') ///
        (`estimate') (`standard_error') (`pvalue') ///
        (`ci_low') (`ci_high') (`control_sd') ///
        (`standardized_estimate') ///
        (`standardized_ci_low') (`standardized_ci_high') ///
        (.) (.) (.) (.) (.) (.) ///
        (0) ("`gate_status'") (`estimation_rc')
end


*-----------------------------------*
**# 5. Transparent non-applicable cells
*-----------------------------------*

capture program drop _vrd_post_level_hte_na

program define _vrd_post_level_hte_na
    version 19
    syntax, ///
        POSTHandle(name) OUTVAR(name) OUTCOMEID(string) ///
        OUTLABel(string) PAPEROrder(real) SCALE(real) ///
        MODID(string) MODLABel(string) MODOrder(real) ///
        MODTIER(string) MODTYPE(string) ///
        SPECID(string) ESTIMATOR(string) ESTIMAND(string) ///
        WEIGHTING(string) CLUSTERRULE(string) HValue(real)

    post `posthandle' ///
        ("`outcomeid'") ("`outvar'") ("`outlabel'") ///
        (`paperorder') (`scale') ///
        ("`modid'") ("`modlabel'") (`modorder') ///
        ("`modtier'") ("`modtype'") ///
        ("`specid'") ("`estimator'") ("`estimand'") ///
        ("`weighting'") ("`clusterrule'") ///
        (`hvalue') (.) (.) (.) (.) (.) (.) (.) ///
        (0) ///
        (.) (.) (.) (.) (.) (.) (.) (.) (.) ///
        (.) (.) (.) (.) (.) (.) ///
        (0) ("not_applicable_identity") (2000)
end


*-----------------------------------*
**# 6. Prespecified outcome-by-moderator grid
*-----------------------------------*

tempfile hte_results_raw hte_results_final hte_conditional
tempname hte_post hte_cond_post

postfile `hte_post' ///
    str12 outcome_id str40 outcome_var str100 outcome_label ///
    double paper_order scale ///
    str8 moderator_id str80 moderator_label double moderator_order ///
    str12 moderator_tier str12 moderator_type ///
    str36 spec_id str12 estimator str32 estimand ///
    str20 weighting str16 cluster_rule ///
    double h n_left n_right ccpp_left ccpp_right ///
    min_obs_cell min_cluster_cell clusters support_pass ///
    estimate standard_error pvalue ci_low ci_high control_sd ///
    standardized_estimate standardized_ci_low standardized_ci_high ///
    kp_f sw_f_treat sw_f_interaction min_sw_f underid_p ar_p ///
    gate_pass str40 gate_status int estimation_rc ///
    using `hte_results_raw', replace

postfile `hte_cond_post' ///
    str12 outcome_id str100 outcome_label double paper_order ///
    str8 moderator_id str80 moderator_label double moderator_order ///
    str12 moderator_tier str24 value_label ///
    double raw_value standardized_value ///
    estimate standard_error pvalue ci_low ci_high control_sd ///
    standardized_estimate standardized_ci_low standardized_ci_high ///
    gate_pass str40 gate_status ///
    using `hte_conditional', replace

forvalues moderator_index = 1/`moderator_count' {
    local moderator_var "hte_m`moderator_index'"
    local moderator_id "`m_id_`moderator_index''"
    local moderator_label "`m_label_`moderator_index''"
    local moderator_order = `m_order_`moderator_index''
    local moderator_tier "`m_tier_`moderator_index''"
    local moderator_type "`m_type_`moderator_index''"
    local moderator_source "`m_source_`moderator_index''"

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
            "Estimating ${hte_output_stub}: `moderator_id' x `outcome_id'."

        local specification_list ///
            common_h_iv ///
            common_h_rdhte ///
            common_h_covariates

        if "`moderator_tier'" == "primary" {
            local specification_list ///
                "`specification_list' small_h_iv large_h_iv common_h_observation_equal common_h_district_cluster common_h_score_cluster"
        }

        local identity_cell = ///
            "`outcome_var'" == "`moderator_source'"

        foreach specification of local specification_list {
            local estimator "ivreg2"
            local estimand "fuzzy_late_interaction"
            local hvalue = ${hte_common_h}
            local weighting "ccpp_equal"
            local cluster_var "hte_cluster_ruv"
            local cluster_rule "ccpp"
            local included_covariates

            if "`specification'" == "common_h_rdhte" {
                local estimator "rdhte"
                local estimand "assignment_hte"
            }
            if "`specification'" == "common_h_covariates" {
                local included_covariates "`covariates'"
            }
            if "`specification'" == "small_h_iv" {
                local hvalue = ${hte_small_h}
            }
            if "`specification'" == "large_h_iv" {
                local hvalue = ${hte_large_h}
            }
            if "`specification'" == "common_h_observation_equal" {
                local weighting "${hte_observation_weight_id}"
            }
            if "`specification'" == "common_h_district_cluster" {
                local cluster_var "hte_cluster_dist"
                local cluster_rule "district"
            }
            if "`specification'" == "common_h_score_cluster" {
                local cluster_var "hte_cluster_score"
                local cluster_rule "score_mass"
            }

            if `identity_cell' {
                _vrd_post_level_hte_na, ///
                    posthandle(`hte_post') ///
                    outvar(`outcome_var') outcomeid("`outcome_id'") ///
                    outlabel("`outcome_label'") ///
                    paperorder(`outcome_order') scale(`outcome_scale') ///
                    modid("`moderator_id'") ///
                    modlabel("`moderator_label'") ///
                    modorder(`moderator_order') ///
                    modtier("`moderator_tier'") ///
                    modtype("`moderator_type'") ///
                    specid("`specification'") ///
                    estimator("`estimator'") estimand("`estimand'") ///
                    weighting("`weighting'") ///
                    clusterrule("`cluster_rule'") hvalue(`hvalue')
                continue
            }

            if "`specification'" == "common_h_rdhte" {
                _vrd_post_level_hte_rdhte, ///
                    posthandle(`hte_post') ///
                    outvar(`outcome_var') outcomeid("`outcome_id'") ///
                    outlabel("`outcome_label'") ///
                    paperorder(`outcome_order') scale(`outcome_scale') ///
                    modvar(`moderator_var') modid("`moderator_id'") ///
                    modlabel("`moderator_label'") ///
                    modorder(`moderator_order') ///
                    modtier("`moderator_tier'") ///
                    modtype("`moderator_type'") ///
                    hvalue(${hte_common_h})
            }
            else {
                local covariate_option
                if "`included_covariates'" != "" {
                    local covariate_option ///
                        "covariates(`included_covariates')"
                }

                _vrd_post_level_hte_iv, ///
                    posthandle(`hte_post') ///
                    condhandle(`hte_cond_post') ///
                    outvar(`outcome_var') outcomeid("`outcome_id'") ///
                    outlabel("`outcome_label'") ///
                    paperorder(`outcome_order') scale(`outcome_scale') ///
                    modvar(`moderator_var') modid("`moderator_id'") ///
                    modlabel("`moderator_label'") ///
                    modorder(`moderator_order') ///
                    modtier("`moderator_tier'") ///
                    modtype("`moderator_type'") ///
                    specid("`specification'") hvalue(`hvalue') ///
                    eval1(`m_eval25_`moderator_index'') ///
                    eval2(`m_eval50_`moderator_index'') ///
                    eval3(`m_eval75_`moderator_index'') ///
                    raw1(`m_raw25_`moderator_index'') ///
                    raw2(`m_raw50_`moderator_index'') ///
                    raw3(`m_raw75_`moderator_index'') ///
                    weighting("`weighting'") ///
                    clustervar(`cluster_var') ///
                    clusterrule("`cluster_rule'") ///
                    `covariate_option'
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
assert _N == ${hte_expected_results}
isid outcome_id moderator_id spec_id
assert estimation_rc >= 0 & estimation_rc < .
assert gate_pass == 0 if estimator == "rdhte"
assert gate_pass == 0 if gate_status == "not_applicable_identity"

generate double p_holm = .
generate double q_bh = .

egen long hte_adjust_group = group(estimator moderator_tier) ///
    if inlist(spec_id, "common_h_iv", "common_h_rdhte") & ///
    estimation_rc == 0 & pvalue < .

sort hte_adjust_group pvalue
by hte_adjust_group: generate int hte_rank = _n ///
    if hte_adjust_group < .
by hte_adjust_group: generate int hte_family_n = _N ///
    if hte_adjust_group < .

generate double hte_holm_step = ///
    pvalue * (hte_family_n - hte_rank + 1) ///
    if moderator_tier == "primary" & hte_adjust_group < .
by hte_adjust_group: replace hte_holm_step = ///
    max(hte_holm_step, hte_holm_step[_n-1]) ///
    if moderator_tier == "primary" & _n > 1 & ///
    hte_adjust_group < .
replace p_holm = min(hte_holm_step, 1) ///
    if moderator_tier == "primary" & hte_holm_step < .

generate double hte_bh_step = ///
    pvalue * hte_family_n / hte_rank ///
    if moderator_tier == "secondary" & hte_adjust_group < .
gsort hte_adjust_group -hte_rank
by hte_adjust_group: replace hte_bh_step = ///
    min(hte_bh_step, hte_bh_step[_n-1]) ///
    if moderator_tier == "secondary" & _n > 1 & ///
    hte_adjust_group < .
replace q_bh = min(hte_bh_step, 1) ///
    if moderator_tier == "secondary" & hte_bh_step < .

drop hte_adjust_group hte_rank hte_family_n ///
    hte_holm_step hte_bh_step
sort moderator_order paper_order estimator spec_id
save `hte_results_final'

export delimited using ///
    "${hte_table_dir}/rd_hte_`output_stub'_results.csv", ///
    replace nolabel

use `hte_conditional', clear
isid outcome_id moderator_id value_label
sort moderator_order paper_order standardized_value
export delimited using ///
    "${hte_table_dir}/rd_hte_`output_stub'_conditional_effects.csv", ///
    replace nolabel


*-----------------------------------*
**# 8. Machine-readable analysis contract
*-----------------------------------*

tempfile hte_contract
tempname contract_post

postfile `contract_post' ///
    str32 component str80 value str16 status str244 detail ///
    using `hte_contract', replace

post `contract_post' ///
    ("unit") ("`unit_label'") ("approved") ///
    ("One linked ${hte_level} observation; treatment and assignment are defined at RUV CCPP level.")
post `contract_post' ///
    ("sample") ("Selected adjacent B/C") ("approved") ///
    ("Legacy selected geography and official B-C running-variable support.")
post `contract_post' ///
    ("treatment") ("treat_12") ("approved") ///
    ("Cumulative collective-reparation receipt through 2012 for SISFOH 2013 outcomes.")
post `contract_post' ///
    ("bandwidth") ("h = 0.0075") ("approved") ///
    ("One common fixed bandwidth; h = 0.0050 and h = 0.0100 are prespecified sensitivities.")
post `contract_post' ///
    ("primary estimator") ("Fully interacted local IV") ("approved") ///
    ("Treatment and treatment-by-moderator are instrumented by cutoff assignment and assignment-by-moderator.")
post `contract_post' ///
    ("secondary estimator") ("rdhte assignment HTE") ("approved") ///
    ("Reduced-form assignment-effect heterogeneity only; never a substitute for fuzzy-IV identification.")
post `contract_post' ///
    ("weighting") ("CCPP-equal") ("approved") ///
    ("Eligible observations share total weight one within each RUV community before triangular kernel weighting.")
post `contract_post' ///
    ("inference") ("CCPP-clustered") ("approved") ///
    ("Primary IV and rdhte inference clusters by RUV community; district and score-mass clustering are sensitivities.")
post `contract_post' ///
    ("identification gate") ("Minimum SW F > 10") ("approved") ///
    ("Also requires local support and underidentification rejection at five percent.")
post `contract_post' ///
    ("multiplicity") ("Holm primary; BH secondary") ("approved") ///
    ("Adjusted within estimator and moderator tier for the common-window interaction family.")
post `contract_post' ///
    ("post-treatment attributes") ("Excluded") ("approved") ///
    ("Project type and financing are not ordinary moderators in household or individual outcome models.")
post `contract_post' ///
    ("identity cells") ("Not applicable") ("approved") ///
    ("An outcome cannot be used as its own moderator; such cells remain explicit in machine-readable results.")

postclose `contract_post'
use `hte_contract', clear
export delimited using ///
    "${hte_table_dir}/rd_hte_`output_stub'_analysis_contract.csv", ///
    replace nolabel


*-----------------------------------*
**# 9. Publication-facing LaTeX tables
*-----------------------------------*

* Moderator registry.
preserve
import delimited using "${hte_moderator_registry}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
generate byte selected_moderator = 0
foreach moderator_id of local applicable_moderators {
    replace selected_moderator = 1 if moderator_id == "`moderator_id'"
}
keep if selected_moderator
sort paper_order

tempname registry_tex
file open `registry_tex' using ///
    "${hte_table_dir}/tab_hte_`output_stub'_01_moderator_registry.tex", ///
    write replace text
file write `registry_tex' "\begin{table}[!htbp]" _n
file write `registry_tex' "\centering" _n
file write `registry_tex' ///
    "\caption{Prespecified `level_caption' heterogeneity moderators}" _n
file write `registry_tex' ///
    "\label{tab:hte-`output_stub'-registry}" _n
file write `registry_tex' "\small" _n
file write `registry_tex' "\resizebox{\textwidth}{!}{%" _n
file write `registry_tex' "\begin{tabular}{llll}" _n
file write `registry_tex' "\toprule" _n
file write `registry_tex' ///
    "ID & Moderator & Tier & Interpretation limit \\" _n
file write `registry_tex' "\midrule" _n

forvalues row = 1/`=_N' {
    local row_id "`=moderator_id[`row']'"
    local row_label "`=moderator_label[`row']'"
    local row_tier "`=proper(tier[`row'])'"
    local row_limit "`=interpretation_limit[`row']'"

    file write `registry_tex' ///
        "`row_id' & `row_label' & `row_tier' & `row_limit' \\" _n
}

file write `registry_tex' "\bottomrule" _n
file write `registry_tex' "\end{tabular}}" _n
file write `registry_tex' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Continuous CCPP attributes are standardized over one record per represented RUV community in the complete wave-level analysis universe. Respondent age is standardized over eligible people. Binary moderators are not standardized. The list was fixed before reviewing these heterogeneity estimates. Source: INEI 2007 Census tabulations, GeoGPS--INEI spatial data, Seminario--Palomino GDP estimates, and SISFOH 2012--2013.}" _n
file write `registry_tex' "\end{table}" _n
file close `registry_tex'
restore

* Design and instrument diagnostics.
use `hte_results_final', clear
keep if spec_id == "common_h_iv"
generate byte diagnostic_candidate = ///
    gate_status != "not_applicable_identity"
bysort moderator_id: egen double diagnostic_order = ///
    min(cond(diagnostic_candidate, paper_order, .))
keep if paper_order == diagnostic_order
bysort moderator_id (paper_order): keep if _n == 1
sort moderator_order

tempname diagnostics_tex
file open `diagnostics_tex' using ///
    "${hte_table_dir}/tab_hte_`output_stub'_02_design_diagnostics.tex", ///
    write replace text
file write `diagnostics_tex' "\begin{table}[!htbp]" _n
file write `diagnostics_tex' "\centering" _n
file write `diagnostics_tex' ///
    "\caption{Local support and fuzzy-heterogeneity identification diagnostics}" _n
file write `diagnostics_tex' ///
    "\label{tab:hte-`output_stub'-diagnostics}" _n
file write `diagnostics_tex' "\small" _n
file write `diagnostics_tex' "\resizebox{\textwidth}{!}{%" _n
file write `diagnostics_tex' ///
    "\begin{tabular}{lrrrrrll}" _n
file write `diagnostics_tex' "\toprule" _n
file write `diagnostics_tex' ///
    "Moderator & CCPP left & CCPP right & Min. cell & Min. SW \(F\) & KP \(F\) & Support & IV gate \\" _n
file write `diagnostics_tex' "\midrule" _n

forvalues row = 1/`=_N' {
    local row_label "`=moderator_label[`row']'"
    local row_left : display %6.0fc ccpp_left[`row']
    local row_right : display %6.0fc ccpp_right[`row']
    local row_cell : display %6.0fc min_cluster_cell[`row']
    local row_sw "--"
    local row_kp "--"
    if min_sw_f[`row'] < . {
        local row_sw : display %6.2f min_sw_f[`row']
    }
    if kp_f[`row'] < . {
        local row_kp : display %6.2f kp_f[`row']
    }
    local row_support = cond(support_pass[`row'] == 1, "Pass", "Fail")
    local row_gate = cond(gate_pass[`row'] == 1, "Pass", "Fail")

    foreach formatted in row_left row_right row_cell row_sw row_kp {
        local `formatted' = strtrim("``formatted''")
    }

    file write `diagnostics_tex' ///
        "`row_label' & `row_left' & `row_right' & `row_cell' & `row_sw' & `row_kp' & `row_support' & `row_gate' \\" _n
}

file write `diagnostics_tex' "\bottomrule" _n
file write `diagnostics_tex' "\end{tabular}}" _n
file write `diagnostics_tex' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Diagnostics come from the pooled, fully interacted local-linear 2SLS model in the fixed \(h=0.0075\) window. Each eligible RUV community has total weight one before triangular kernel weighting. CCPP left and right are unique assignment clusters. For binary moderators, Min. cell is the smallest moderator-by-side CCPP count; for continuous moderators it is the smaller side count. The causal gate requires support, underidentification rejection at five percent, and the minimum Sanderson--Windmeijer conditional \(F\) strictly above 10. The Kleibergen--Paap statistic is supplementary. Source: RUV, CMAN, and SISFOH 2012--2013.}" _n
file write `diagnostics_tex' "\end{table}" _n
file close `diagnostics_tex'

* Primary and secondary fuzzy-IV interaction tables.
foreach table_tier in primary secondary {
    use `hte_results_final', clear
    keep if spec_id == "common_h_iv" & ///
        moderator_tier == "`table_tier'" & ///
        gate_status != "not_applicable_identity"
    sort moderator_order paper_order

    local tier_title = proper("`table_tier'")
    local adjustment_label = cond("`table_tier'" == "primary", ///
        "Holm \(p\)", "BH \(q\)")

    tempname fuzzy_tex
    file open `fuzzy_tex' using ///
        "${hte_table_dir}/tab_hte_`output_stub'_03_fuzzy_`table_tier'.tex", ///
        write replace text
    file write `fuzzy_tex' "\begingroup" _n
    file write `fuzzy_tex' "\scriptsize" _n
    file write `fuzzy_tex' "\setlength{\tabcolsep}{3pt}" _n
    file write `fuzzy_tex' ///
        "\begin{longtable}{@{}p{0.18\linewidth}p{0.15\linewidth}rp{0.13\linewidth}rrrl@{}}" _n
    file write `fuzzy_tex' ///
        "\caption{`tier_title' fuzzy-RD treatment-effect heterogeneity}\label{tab:hte-`output_stub'-fuzzy-`table_tier'}\\" _n
    file write `fuzzy_tex' "\toprule" _n
    file write `fuzzy_tex' ///
        "Outcome & Moderator & Interaction & 95\% CI & Raw \(p\) & `adjustment_label' & Min. SW \(F\) & Gate \\" _n
    file write `fuzzy_tex' "\midrule" _n
    file write `fuzzy_tex' "\endfirsthead" _n
    file write `fuzzy_tex' "\toprule" _n
    file write `fuzzy_tex' ///
        "Outcome & Moderator & Interaction & 95\% CI & Raw \(p\) & `adjustment_label' & Min. SW \(F\) & Gate \\" _n
    file write `fuzzy_tex' "\midrule" _n
    file write `fuzzy_tex' "\endhead" _n
    file write `fuzzy_tex' "\midrule" _n
    file write `fuzzy_tex' ///
        "\multicolumn{8}{r}{\scriptsize Continued on next page} \\" _n
    file write `fuzzy_tex' "\endfoot" _n
    file write `fuzzy_tex' "\bottomrule" _n
    file write `fuzzy_tex' ///
        "\multicolumn{8}{p{0.94\textwidth}}{\footnotesize\textit{Notes:} Interaction is the coefficient on treatment by moderator in one pooled, fully interacted, triangular-weighted local-linear 2SLS model in \(h=0.0075\). Treatment and treatment-by-moderator are instrumented by cutoff assignment and assignment-by-moderator. Each community has total weight one; inference clusters by RUV community. Continuous interactions are per one-standard-deviation increase; binary interactions are differences from zero to one. Only rows passing the support, rank, and minimum conditional-\(F>10\) gate are interpretation-ready fuzzy-LATE heterogeneity. Failed rows are retained to disclose weak identification and must not be read causally. Multiplicity is adjusted within estimator and moderator tier. Source: RUV, CMAN, and SISFOH 2012--2013.} \\" _n
    file write `fuzzy_tex' "\endlastfoot" _n

    forvalues row = 1/`=_N' {
        local row_outcome "`=outcome_label[`row']'"
        local row_moderator "`=moderator_label[`row']'"
        local row_estimate "--"
        local row_ci "--"
        local row_p "--"
        local row_adjusted "--"
        local row_sw "--"

        if estimate[`row'] < . {
            local row_estimate : display %7.2f estimate[`row']
            local row_low : display %7.2f ci_low[`row']
            local row_high : display %7.2f ci_high[`row']
            local row_low = strtrim("`row_low'")
            local row_high = strtrim("`row_high'")
            local row_ci "[`row_low', `row_high']"
        }
        if pvalue[`row'] < . {
            local row_p : display %6.3f pvalue[`row']
        }
        if "`table_tier'" == "primary" & p_holm[`row'] < . {
            local row_adjusted : display %6.3f p_holm[`row']
        }
        if "`table_tier'" == "secondary" & q_bh[`row'] < . {
            local row_adjusted : display %6.3f q_bh[`row']
        }
        if min_sw_f[`row'] < . {
            local row_sw : display %6.2f min_sw_f[`row']
        }
        local row_gate = cond(gate_pass[`row'] == 1, "Pass", "Fail")

        foreach formatted in ///
            row_estimate row_p row_adjusted row_sw {
            local `formatted' = strtrim("``formatted''")
        }

        file write `fuzzy_tex' ///
            "`row_outcome' & `row_moderator' & `row_estimate' & `row_ci' & `row_p' & `row_adjusted' & `row_sw' & `row_gate' \\" _n
    }

    file write `fuzzy_tex' "\end{longtable}" _n
    file write `fuzzy_tex' "\endgroup" _n
    file close `fuzzy_tex'
}

* Secondary assignment-effect heterogeneity tables.
foreach table_tier in primary secondary {
    use `hte_results_final', clear
    keep if spec_id == "common_h_rdhte" & ///
        moderator_tier == "`table_tier'" & ///
        gate_status != "not_applicable_identity"
    sort moderator_order paper_order

    local tier_title = proper("`table_tier'")
    local adjustment_label = cond("`table_tier'" == "primary", ///
        "Holm \(p\)", "BH \(q\)")

    tempname assignment_tex
    file open `assignment_tex' using ///
        "${hte_table_dir}/tab_hte_`output_stub'_04_assignment_`table_tier'.tex", ///
        write replace text
    file write `assignment_tex' "\begingroup" _n
    file write `assignment_tex' "\scriptsize" _n
    file write `assignment_tex' "\setlength{\tabcolsep}{3pt}" _n
    file write `assignment_tex' ///
        "\begin{longtable}{@{}p{0.20\linewidth}p{0.16\linewidth}rp{0.14\linewidth}rrl@{}}" _n
    file write `assignment_tex' ///
        "\caption{`tier_title' assignment-effect heterogeneity}\label{tab:hte-`output_stub'-assignment-`table_tier'}\\" _n
    file write `assignment_tex' "\toprule" _n
    file write `assignment_tex' ///
        "Outcome & Moderator & Interaction & 95\% CI & Raw \(p\) & `adjustment_label' & Support \\" _n
    file write `assignment_tex' "\midrule" _n
    file write `assignment_tex' "\endfirsthead" _n
    file write `assignment_tex' "\toprule" _n
    file write `assignment_tex' ///
        "Outcome & Moderator & Interaction & 95\% CI & Raw \(p\) & `adjustment_label' & Support \\" _n
    file write `assignment_tex' "\midrule" _n
    file write `assignment_tex' "\endhead" _n
    file write `assignment_tex' "\midrule" _n
    file write `assignment_tex' ///
        "\multicolumn{7}{r}{\scriptsize Continued on next page} \\" _n
    file write `assignment_tex' "\endfoot" _n
    file write `assignment_tex' "\bottomrule" _n
    file write `assignment_tex' ///
        "\multicolumn{7}{p{0.94\textwidth}}{\footnotesize\textit{Notes:} These are robust local-polynomial discontinuities in the assignment effect estimated with \texttt{rdhte}, not fuzzy-RD complier effects. Each RUV community has total weight one, the window is \(h=0.0075\), and inference clusters by RUV community. Continuous coefficients are assignment-effect slopes per moderator SD; binary coefficients compare one with zero. These estimates are secondary complementary evidence and never replace a failed fuzzy-IV identification gate. Multiplicity is adjusted within estimator and moderator tier. Source: RUV, CMAN, and SISFOH 2012--2013.} \\" _n
    file write `assignment_tex' "\endlastfoot" _n

    forvalues row = 1/`=_N' {
        local row_outcome "`=outcome_label[`row']'"
        local row_moderator "`=moderator_label[`row']'"
        local row_estimate "--"
        local row_ci "--"
        local row_p "--"
        local row_adjusted "--"

        if estimate[`row'] < . {
            local row_estimate : display %7.2f estimate[`row']
            local row_low : display %7.2f ci_low[`row']
            local row_high : display %7.2f ci_high[`row']
            local row_low = strtrim("`row_low'")
            local row_high = strtrim("`row_high'")
            local row_ci "[`row_low', `row_high']"
        }
        if pvalue[`row'] < . {
            local row_p : display %6.3f pvalue[`row']
        }
        if "`table_tier'" == "primary" & p_holm[`row'] < . {
            local row_adjusted : display %6.3f p_holm[`row']
        }
        if "`table_tier'" == "secondary" & q_bh[`row'] < . {
            local row_adjusted : display %6.3f q_bh[`row']
        }
        local row_support = cond(support_pass[`row'] == 1, "Pass", "Fail")

        foreach formatted in row_estimate row_p row_adjusted {
            local `formatted' = strtrim("``formatted''")
        }

        file write `assignment_tex' ///
            "`row_outcome' & `row_moderator' & `row_estimate' & `row_ci' & `row_p' & `row_adjusted' & `row_support' \\" _n
    }

    file write `assignment_tex' "\end{longtable}" _n
    file write `assignment_tex' "\endgroup" _n
    file close `assignment_tex'
}

* Conditional local effects from the primary IV model.
use `hte_conditional', clear
keep if moderator_tier == "primary"
sort moderator_order paper_order standardized_value

tempname conditional_tex
file open `conditional_tex' using ///
    "${hte_table_dir}/tab_hte_`output_stub'_05_conditional_lates.tex", ///
    write replace text
file write `conditional_tex' "\begingroup" _n
file write `conditional_tex' "\scriptsize" _n
file write `conditional_tex' "\setlength{\tabcolsep}{3pt}" _n
file write `conditional_tex' ///
    "\begin{longtable}{@{}p{0.18\linewidth}p{0.15\linewidth}lrrp{0.13\linewidth}rl@{}}" _n
file write `conditional_tex' ///
    "\caption{Conditional local effects implied by the pooled fuzzy-RD model}\label{tab:hte-`output_stub'-conditional}\\" _n
file write `conditional_tex' "\toprule" _n
file write `conditional_tex' ///
    "Outcome & Moderator & Value & Raw value & Effect & 95\% CI & \(p\) & Gate \\" _n
file write `conditional_tex' "\midrule" _n
file write `conditional_tex' "\endfirsthead" _n
file write `conditional_tex' "\toprule" _n
file write `conditional_tex' ///
    "Outcome & Moderator & Value & Raw value & Effect & 95\% CI & \(p\) & Gate \\" _n
file write `conditional_tex' "\midrule" _n
file write `conditional_tex' "\endhead" _n
file write `conditional_tex' "\midrule" _n
file write `conditional_tex' ///
    "\multicolumn{8}{r}{\scriptsize Continued on next page} \\" _n
file write `conditional_tex' "\endfoot" _n
file write `conditional_tex' "\bottomrule" _n
file write `conditional_tex' ///
    "\multicolumn{8}{p{0.94\textwidth}}{\footnotesize\textit{Notes:} Conditional effects are linear combinations from the same pooled fuzzy local-IV model, not separately estimated subgroup RDs. Continuous moderators are evaluated at their analysis-universe quartiles; binary moderators at zero and one. The common \(h=0.0075\), CCPP-equal weighting, triangular kernel, and CCPP-clustered inference are fixed across outcomes. A failed gate means the conditional effect is diagnostic only. Source: RUV, CMAN, and SISFOH 2012--2013.} \\" _n
file write `conditional_tex' "\endlastfoot" _n

forvalues row = 1/`=_N' {
    local row_outcome "`=outcome_label[`row']'"
    local row_moderator "`=moderator_label[`row']'"
    local row_value "`=value_label[`row']'"
    local row_raw : display %8.2f raw_value[`row']
    local row_estimate : display %8.2f estimate[`row']
    local row_low : display %8.2f ci_low[`row']
    local row_high : display %8.2f ci_high[`row']
    local row_p : display %6.3f pvalue[`row']
    local row_low = strtrim("`row_low'")
    local row_high = strtrim("`row_high'")
    local row_ci "[`row_low', `row_high']"
    local row_gate = cond(gate_pass[`row'] == 1, "Pass", "Fail")

    foreach formatted in row_raw row_estimate row_p {
        local `formatted' = strtrim("``formatted''")
    }

    file write `conditional_tex' ///
        "`row_outcome' & `row_moderator' & `row_value' & `row_raw' & `row_estimate' & `row_ci' & `row_p' & `row_gate' \\" _n
}

file write `conditional_tex' "\end{longtable}" _n
file write `conditional_tex' "\endgroup" _n
file close `conditional_tex'

* Prespecified fuzzy-IV sensitivities for primary moderators.
use `hte_results_final', clear
keep if estimator == "ivreg2" & moderator_tier == "primary" & ///
    gate_status != "not_applicable_identity"
sort moderator_order paper_order spec_id

tempname robustness_tex
file open `robustness_tex' using ///
    "${hte_table_dir}/tab_hte_`output_stub'_06_fuzzy_robustness.tex", ///
    write replace text
file write `robustness_tex' "\begingroup" _n
file write `robustness_tex' "\scriptsize" _n
file write `robustness_tex' "\setlength{\tabcolsep}{3pt}" _n
file write `robustness_tex' ///
    "\begin{longtable}{@{}p{0.16\linewidth}p{0.14\linewidth}p{0.14\linewidth}rp{0.13\linewidth}rrl@{}}" _n
file write `robustness_tex' ///
    "\caption{Prespecified robustness of primary fuzzy-RD heterogeneity estimates}\label{tab:hte-`output_stub'-robustness}\\" _n
file write `robustness_tex' "\toprule" _n
file write `robustness_tex' ///
    "Outcome & Moderator & Specification & Interaction & 95\% CI & Min. SW \(F\) & Under-ID \(p\) & Gate \\" _n
file write `robustness_tex' "\midrule" _n
file write `robustness_tex' "\endfirsthead" _n
file write `robustness_tex' "\toprule" _n
file write `robustness_tex' ///
    "Outcome & Moderator & Specification & Interaction & 95\% CI & Min. SW \(F\) & Under-ID \(p\) & Gate \\" _n
file write `robustness_tex' "\midrule" _n
file write `robustness_tex' "\endhead" _n
file write `robustness_tex' "\midrule" _n
file write `robustness_tex' ///
    "\multicolumn{8}{r}{\scriptsize Continued on next page} \\" _n
file write `robustness_tex' "\endfoot" _n
file write `robustness_tex' "\bottomrule" _n
file write `robustness_tex' ///
    "\multicolumn{8}{p{0.94\textwidth}}{\footnotesize\textit{Notes:} The common-window, CCPP-equal, CCPP-clustered row is primary. Sensitivities add the fixed predetermined covariate set, use \(h=0.0050\) or \(h=0.0100\), give observations equal weight, or cluster by district or running-score mass point. All models retain the pooled fully interacted local-linear 2SLS specification. No result, bandwidth, weight, or inference rule is selected by statistical significance. Source: RUV, CMAN, and SISFOH 2012--2013.} \\" _n
file write `robustness_tex' "\endlastfoot" _n

forvalues row = 1/`=_N' {
    local row_outcome "`=outcome_label[`row']'"
    local row_moderator "`=moderator_label[`row']'"
    local row_spec "`=spec_id[`row']'"
    local row_spec = subinstr("`row_spec'", "_", " ", .)
    local row_estimate "--"
    local row_ci "--"
    local row_sw "--"
    local row_underid "--"

    if estimate[`row'] < . {
        local row_estimate : display %7.2f estimate[`row']
        local row_low : display %7.2f ci_low[`row']
        local row_high : display %7.2f ci_high[`row']
        local row_low = strtrim("`row_low'")
        local row_high = strtrim("`row_high'")
        local row_ci "[`row_low', `row_high']"
    }
    if min_sw_f[`row'] < . {
        local row_sw : display %6.2f min_sw_f[`row']
    }
    if underid_p[`row'] < . {
        local row_underid : display %6.3f underid_p[`row']
    }
    local row_gate = cond(gate_pass[`row'] == 1, "Pass", "Fail")

    foreach formatted in row_estimate row_sw row_underid {
        local `formatted' = strtrim("``formatted''")
    }

    file write `robustness_tex' ///
        "`row_outcome' & `row_moderator' & `row_spec' & `row_estimate' & `row_ci' & `row_sw' & `row_underid' & `row_gate' \\" _n
}

file write `robustness_tex' "\end{longtable}" _n
file write `robustness_tex' "\endgroup" _n
file close `robustness_tex'


*-----------------------------------*
**# 10. Publication-formatted figures
*-----------------------------------*

capture set scheme ${graph_scheme}

* Primary fuzzy-IV interaction forest, with the gate visible.
use `hte_results_final', clear
keep if spec_id == "common_h_iv" & moderator_tier == "primary" & ///
    gate_status != "not_applicable_identity" & ///
    standardized_estimate < .
sort moderator_order paper_order
assert _N > 0

generate int plot_y = _N - _n + 1
generate str80 plot_label = outcome_label
replace plot_label = "Household size" if outcome_id == "H01"
replace plot_label = "Female share" if outcome_id == "H02"
replace plot_label = "Employment rate" if outcome_id == "H03"
replace plot_label = "Any social program" if outcome_id == "H04"
replace plot_label = "Any unmet basic need" if outcome_id == "H06"
replace plot_label = "Asset wellbeing" if outcome_id == "H07"
replace plot_label = "Secondary education or higher" if outcome_id == "H08"
local fuzzy_ylabels
forvalues row = 1/`=_N' {
    local row_label = ///
        plot_label[`row'] + ": " + moderator_id[`row']
    local fuzzy_ylabels ///
        `"`fuzzy_ylabels' `=plot_y[`row']' "`row_label'""'
}

twoway ///
    (rcap standardized_ci_low standardized_ci_high plot_y ///
        if gate_pass == 1, horizontal lcolor(navy) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate if gate_pass == 1, ///
        msymbol(O) msize(medsmall) mcolor(navy)) ///
    (rcap standardized_ci_low standardized_ci_high plot_y ///
        if gate_pass == 0, horizontal lcolor(gs10) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate if gate_pass == 0, ///
        msymbol(Oh) msize(medsmall) mcolor(gs7)), ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    ylabel(`fuzzy_ylabels', angle(horizontal) labsize(vsmall) noticks) ///
    ytitle("") ///
    xtitle("Treatment-by-moderator interaction (below-cutoff SD units)") ///
    title("Primary fuzzy-RD heterogeneity: SISFOH 2013 `unit_plural'", ///
        size(medium) color(black)) ///
    subtitle("Pooled local IV; common h = 0.0075; robust 95% intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "Passes fuzzy-IV gate" 4 "Fails fuzzy-IV gate") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is a `unit_label' in the selected B/C geography; each RUV community receives total weight one." ///
        "Treatment and treatment-by-moderator are instrumented by cutoff assignment and assignment-by-moderator." ///
        "Inference clusters by RUV community. Hollow gray estimates fail support, rank, or minimum conditional F > 10 and are diagnostic only." ///
        "Continuous interactions are per moderator SD; binary interactions compare one with zero. Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
        size(tiny) color(gs5) span) ///
    xsize(11) ysize(8) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${hte_figure_dir}/fig_hte_`output_stub'_fuzzy_primary.png", ///
    width(3300) replace

* Primary assignment-effect HTE forest from rdhte.
use `hte_results_final', clear
keep if spec_id == "common_h_rdhte" & ///
    moderator_tier == "primary" & ///
    estimation_rc == 0 & standardized_estimate < .
sort moderator_order paper_order
assert _N > 0

generate int plot_y = _N - _n + 1
generate str80 plot_label = outcome_label
replace plot_label = "Household size" if outcome_id == "H01"
replace plot_label = "Female share" if outcome_id == "H02"
replace plot_label = "Employment rate" if outcome_id == "H03"
replace plot_label = "Any social program" if outcome_id == "H04"
replace plot_label = "Any unmet basic need" if outcome_id == "H06"
replace plot_label = "Asset wellbeing" if outcome_id == "H07"
replace plot_label = "Secondary education or higher" if outcome_id == "H08"
local assignment_ylabels
forvalues row = 1/`=_N' {
    local row_label = ///
        plot_label[`row'] + ": " + moderator_id[`row']
    local assignment_ylabels ///
        `"`assignment_ylabels' `=plot_y[`row']' "`row_label'""'
}

twoway ///
    (rcap standardized_ci_low standardized_ci_high plot_y, ///
        horizontal lcolor(navy) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate, ///
        msymbol(O) msize(medsmall) mcolor(navy)), ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    ylabel(`assignment_ylabels', ///
        angle(horizontal) labsize(vsmall) noticks) ///
    ytitle("") ///
    xtitle("Assignment-effect interaction (below-cutoff SD units)") ///
    title("Assignment-effect heterogeneity: SISFOH 2013 `unit_plural'", ///
        size(medium) color(black)) ///
    subtitle("Secondary rdhte evidence; common h = 0.0075; 95% intervals", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Unit is a `unit_label' in the selected B/C geography; each RUV community receives total weight one." ///
        "These rdhte estimates describe heterogeneity in the cutoff assignment effect, not heterogeneity in the fuzzy-RD complier effect." ///
        "Inference clusters by RUV community. This secondary evidence never substitutes for a failed fuzzy-IV gate." ///
        "Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
        size(tiny) color(gs5) span) ///
    xsize(11) ysize(8) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${hte_figure_dir}/fig_hte_`output_stub'_assignment_primary.png", ///
    width(3300) replace


* Minimum conditional first-stage strength by moderator.
use `hte_results_final', clear
keep if spec_id == "common_h_iv" & ///
    gate_status != "not_applicable_identity"
bysort moderator_id: egen double diagnostic_order = min(paper_order)
keep if paper_order == diagnostic_order
bysort moderator_id (paper_order): keep if _n == 1
sort moderator_order

generate double plot_sw = min_sw_f
generate byte diagnostic_available = plot_sw < .
replace plot_sw = 0 if missing(plot_sw)
generate double plot_zero = 0
generate int plot_y = _N - _n + 1
quietly summarize plot_sw, meanonly
local diagnostic_axis_max = max(10.5, ceil(r(max) + .5))

local diagnostic_ylabels
forvalues row = 1/`=_N' {
    local row_label "`=moderator_label[`row']'"
    local row_moderator_id "`=moderator_id[`row']'"
    if "`row_moderator_id'" == "M01" local row_label "Baseline population"
    if "`row_moderator_id'" == "M02" local row_label "District capital"
    if "`row_moderator_id'" == "M03" local row_label "Female respondent"
    if "`row_moderator_id'" == "S01" local row_label "Baseline deprivation"
    if "`row_moderator_id'" == "S02" local row_label "Distance to district capital"
    if "`row_moderator_id'" == "S03" local row_label "Baseline GDP"
    if "`row_moderator_id'" == "S04" local row_label "Respondent age"
    if "`row_moderator_id'" == "S05" local row_label "Altitude"
    local diagnostic_ylabels ///
        `"`diagnostic_ylabels' `=plot_y[`row']' "`row_label'""'
}
local diagnostic_ysize = cond("`level'" == "individual", 8, 7)

twoway ///
    (rspike plot_zero plot_sw plot_y if diagnostic_available, ///
        horizontal lcolor(navy) lwidth(medthick)) ///
    (scatter plot_y plot_sw if diagnostic_available, ///
        msymbol(O) mcolor(navy) msize(medsmall)) ///
    (scatter plot_y plot_sw if !diagnostic_available, ///
        msymbol(X) mcolor(maroon) msize(medsmall)), ///
    xline(${hte_weak_f_gate}, lcolor(maroon) lpattern(shortdash)) ///
    xscale(range(0 `diagnostic_axis_max')) ///
    xlabel(0(2)`diagnostic_axis_max', format(%6.1f) labsize(small)) ///
    ylabel(`diagnostic_ylabels', ///
        angle(horizontal) labsize(small) noticks) ///
    ytitle("") ///
    xtitle("Minimum conditional F statistic") ///
    title("Instrument strength by moderator", ///
        size(medium) color(black)) ///
    subtitle("Primary common-window pooled fuzzy local-IV model", ///
        size(small) color(gs5)) ///
    legend(order(2 "Available diagnostic" 3 "Unavailable: support/rank") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: The dashed line marks the prespecified strict interpretation gate F > 10." ///
        "The plotted statistic is the smaller conditional F across treatment and treatment-by-moderator equations." ///
        "Diagnostics use CCPP-equal triangular weights in h = 0.0075 and CCPP-clustered inference." ///
        "An unavailable value is plotted at zero with an X and is not evidence of a zero first stage. Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(`diagnostic_ysize') ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${hte_figure_dir}/fig_hte_`output_stub'_instrument_diagnostics.png", ///
    width(3000) replace

* District-capital support is shown because this binary moderator is sparse.
use `hte_support', clear
keep if moderator_id == "M02"
assert _N == 4

graph bar (asis) ccpp_clusters, ///
    over(category_label, label(labsize(small))) ///
    over(side_label, label(labsize(small))) ///
    asyvars ///
    bar(1, color(navy%80)) bar(2, color(cranberry%80)) ///
    ytitle("Unique RUV communities") ///
    title("Local support for district-capital heterogeneity", ///
        size(medium) color(black)) ///
    subtitle("Moderator-by-cutoff-side cells within h = 0.0075", ///
        size(small) color(gs5)) ///
    legend(order(1 "Non-capital" 2 "District capital") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Bars count unique RUV communities in the complete `level_caption' SISFOH 2013 analysis sample." ///
        "The support rule requires at least 10 communities in every moderator-by-side cell." ///
        "This figure assesses overlap only; it is not an effect estimate. Sources: RUV, INEI spatial coding, and SISFOH 2012-2013.", ///
        size(tiny) color(gs5) span) ///
    ysize(7) xsize(9) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${hte_figure_dir}/fig_hte_`output_stub'_capital_support.png", ///
    width(2700) replace


* Conditional fuzzy effects for baseline population.
use `hte_conditional', clear
keep if moderator_id == "M01" & standardized_estimate < .
sort paper_order standardized_value
assert _N > 0

generate int plot_y = _N - _n + 1
generate str48 plot_outcome = outcome_label
replace plot_outcome = "Household members" if outcome_id == "H01"
replace plot_outcome = "Female members" if outcome_id == "H02"
replace plot_outcome = "Employment rate" if outcome_id == "H03"
replace plot_outcome = "Any social program" if outcome_id == "H04"
replace plot_outcome = "Core wellbeing" if outcome_id == "H05"
replace plot_outcome = "Any unmet basic need" if outcome_id == "H06"
replace plot_outcome = "Asset wellbeing" if outcome_id == "H07"
replace plot_outcome = "Secondary education+" if outcome_id == "H08"
replace plot_outcome = "Female" if outcome_id == "I01"
replace plot_outcome = "Age 15-29" if outcome_id == "I02"
replace plot_outcome = "Secondary education+" if outcome_id == "I03"
replace plot_outcome = "Employment" if outcome_id == "I04"
replace plot_outcome = "Independent worker" if outcome_id == "I05"
replace plot_outcome = "Health insurance" if outcome_id == "I06"
replace plot_outcome = "Any social program" if outcome_id == "I07"
replace plot_outcome = "Juntos" if outcome_id == "I08"
local conditional_ylabels
forvalues row = 1/`=_N' {
    local row_label = ///
        plot_outcome[`row'] + ": " + value_label[`row']
    local conditional_ylabels ///
        `"`conditional_ylabels' `=plot_y[`row']' "`row_label'""'
}

twoway ///
    (rcap standardized_ci_low standardized_ci_high plot_y ///
        if gate_pass == 1, horizontal lcolor(navy) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate if gate_pass == 1, ///
        msymbol(O) mcolor(navy) msize(small)) ///
    (rcap standardized_ci_low standardized_ci_high plot_y ///
        if gate_pass == 0, horizontal lcolor(gs10) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate if gate_pass == 0, ///
        msymbol(Oh) mcolor(gs7) msize(small)), ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    ylabel(`conditional_ylabels', ///
        angle(horizontal) labsize(vsmall) noticks) ///
    ytitle("") ///
    xtitle("Conditional local effect (below-cutoff SD units)") ///
    title("Conditional effects by baseline population", ///
        size(medium) color(black)) ///
    subtitle("Pooled fuzzy local IV evaluated at population quartiles", ///
        size(small) color(gs5)) ///
    legend(order(2 "Passes fuzzy-IV gate" 4 "Fails fuzzy-IV gate") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: P25, P50, and P75 are quartiles of log 2007 CCPP population among represented RUV communities." ///
        "Effects are linear combinations from one pooled model, not separately estimated subgroup RDs." ///
        "Each community receives total weight one; inference clusters by RUV community. Hollow gray estimates are diagnostic only." ///
        "Sources: RUV, CMAN, INEI 2007 Census tabulations, and SISFOH 2012-2013.", ///
        size(tiny) color(gs5) span) ///
    xsize(11) ysize(9) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${hte_figure_dir}/fig_hte_`output_stub'_conditional_M01.png", ///
    width(3300) replace

if "`level'" == "individual" {
    * Gender support and conditional effects are individual-level only.
    use `hte_support', clear
    keep if moderator_id == "M03"
    assert _N == 4

    graph bar (asis) ccpp_clusters, ///
        over(category_label, label(labsize(small))) ///
        over(side_label, label(labsize(small))) ///
        asyvars ///
        bar(1, color(navy%80)) bar(2, color(cranberry%80)) ///
        ytitle("Unique RUV communities") ///
        title("Local support for gender heterogeneity", ///
            size(medium) color(black)) ///
        subtitle("Respondent-sex-by-cutoff-side cells within h = 0.0075", ///
            size(small) color(gs5)) ///
        legend(order(1 "Men" 2 "Women") rows(1) position(6) ///
            size(small) region(lcolor(none))) ///
        note( ///
            "Notes: Bars count unique RUV communities containing eligible SISFOH people of each sex in the common design window." ///
            "The support rule requires at least 10 people and at least 10 assignment clusters in every sex-by-side cell." ///
            "This figure assesses overlap only; it is not an effect estimate. Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
            size(tiny) color(gs5) span) ///
        ysize(7) xsize(9) ///
        graphregion(color(white)) plotregion(color(white))

    graph export ///
        "${hte_figure_dir}/fig_hte_`output_stub'_gender_support.png", ///
        width(2700) replace

    use `hte_conditional', clear
    keep if moderator_id == "M03" & standardized_estimate < .
    sort paper_order standardized_value
    assert _N > 0

    generate int plot_y = _N - _n + 1
    local gender_ylabels
    forvalues row = 1/`=_N' {
        local row_label = ///
            outcome_label[`row'] + ": " + value_label[`row']
        local gender_ylabels ///
            `"`gender_ylabels' `=plot_y[`row']' "`row_label'""'
    }

    twoway ///
        (rcap standardized_ci_low standardized_ci_high plot_y ///
            if gate_pass == 1, horizontal lcolor(navy) lwidth(medthin)) ///
        (scatter plot_y standardized_estimate if gate_pass == 1, ///
            msymbol(O) mcolor(navy) msize(small)) ///
        (rcap standardized_ci_low standardized_ci_high plot_y ///
            if gate_pass == 0, horizontal lcolor(gs10) lwidth(medthin)) ///
        (scatter plot_y standardized_estimate if gate_pass == 0, ///
            msymbol(Oh) mcolor(gs7) msize(small)), ///
        xline(0, lcolor(gs8) lpattern(shortdash)) ///
        ylabel(`gender_ylabels', ///
            angle(horizontal) labsize(vsmall) noticks) ///
        ytitle("") ///
        xtitle("Conditional local effect (below-cutoff SD units)") ///
        title("Conditional effects by respondent sex", ///
            size(medium) color(black)) ///
        subtitle("One pooled fuzzy local-IV model; common h = 0.0075", ///
            size(small) color(gs5)) ///
        legend(order(2 "Passes fuzzy-IV gate" 4 "Fails fuzzy-IV gate") ///
            rows(1) position(6) size(small) region(lcolor(none))) ///
        note( ///
            "Notes: Effects for men and women are linear combinations from one pooled fully interacted fuzzy local-IV model." ///
            "The female outcome is excluded from its own moderator analysis as a mechanical identity." ///
            "Each community receives total weight one; inference clusters by RUV community. Hollow gray estimates are diagnostic only." ///
            "Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
            size(tiny) color(gs5) span) ///
        xsize(11) ysize(8) ///
        graphregion(color(white)) plotregion(color(white))

    graph export ///
        "${hte_figure_dir}/fig_hte_`output_stub'_conditional_M03.png", ///
        width(3300) replace


    * The only common-window fuzzy models passing the gate are secondary
    * respondent-age interactions; show them with their composition caveat.
    use `hte_results_final', clear
    keep if spec_id == "common_h_iv" & gate_pass == 1
    assert _N == 8
    assert moderator_id == "S04"
    sort paper_order

    generate int age_plot_y = _N - _n + 1
    local age_ylabels
    forvalues row = 1/`=_N' {
        local row_label "`=outcome_label[`row']'"
        local age_ylabels ///
            `"`age_ylabels' `=age_plot_y[`row']' "`row_label'""'
    }

    twoway ///
        (rcap standardized_ci_low standardized_ci_high age_plot_y, ///
            horizontal lcolor(navy) lwidth(medthin)) ///
        (scatter age_plot_y standardized_estimate, ///
            msymbol(O) mcolor(navy) msize(medsmall)), ///
        xline(0, lcolor(gs8) lpattern(shortdash)) ///
        ylabel(`age_ylabels', ///
            angle(horizontal) labsize(vsmall) noticks) ///
        ytitle("") ///
        xtitle("Treatment-by-age interaction (below-cutoff SD units)") ///
        title("Secondary age heterogeneity: SISFOH 2013 people", ///
            size(medium) color(black)) ///
        subtitle("Models pass the fuzzy-IV gate; robust 95% intervals", ///
            size(small) color(gs5)) ///
        legend(off) ///
        note( ///
            "Notes: The moderator is respondent age standardized in the complete person-level analysis universe." ///
            "All eight models pass support, underidentification, and minimum conditional F > 10, but none survives BH correction." ///
            "Observed age composition can respond through migration or survival, so these secondary estimates do not establish baseline age moderation." ///
            "Each RUV community receives total weight one; inference clusters by community. Sources: RUV, CMAN, and SISFOH 2012-2013.", ///
            size(tiny) color(gs5) span) ///
        xsize(10) ysize(7) ///
        graphregion(color(white)) plotregion(color(white))

    graph export ///
        "${hte_figure_dir}/fig_hte_`output_stub'_fuzzy_secondary_age.png", ///
        width(3000) replace

}


*-----------------------------------*
**# 11. Output validation, manifest, and closeout
*-----------------------------------*

use `hte_results_final', clear
assert _N == ${hte_expected_results}

quietly count if spec_id == "common_h_iv"
assert r(N) == `moderator_count' * `outcome_count'
quietly count if spec_id == "common_h_rdhte"
assert r(N) == `moderator_count' * `outcome_count'
quietly count if estimator == "rdhte" & gate_pass == 1
assert r(N) == 0

if "`level'" == "individual" {
    quietly count if moderator_id == "M03" & outcome_id == "I01" & ///
        gate_status == "not_applicable_identity"
    assert r(N) == 8
}

quietly count if spec_id == "common_h_iv" & gate_pass == 1
local fuzzy_interactions_passing_gate = r(N)
quietly count if spec_id == "common_h_rdhte" & estimation_rc == 0
local assignment_hte_estimated = r(N)

local output_paths ///
    output/tables/rd_heterogeneity/rd_hte_`output_stub'_results.csv ///
    output/tables/rd_heterogeneity/rd_hte_`output_stub'_conditional_effects.csv ///
    output/tables/rd_heterogeneity/rd_hte_`output_stub'_support.csv ///
    output/tables/rd_heterogeneity/rd_hte_`output_stub'_analysis_contract.csv ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_01_moderator_registry.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_02_design_diagnostics.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_03_fuzzy_primary.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_03_fuzzy_secondary.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_04_assignment_primary.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_04_assignment_secondary.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_05_conditional_lates.tex ///
    output/tables/rd_heterogeneity/tab_hte_`output_stub'_06_fuzzy_robustness.tex ///
    output/figures/rd_heterogeneity/fig_hte_`output_stub'_fuzzy_primary.png ///
    output/figures/rd_heterogeneity/fig_hte_`output_stub'_assignment_primary.png ///
    output/figures/rd_heterogeneity/fig_hte_`output_stub'_instrument_diagnostics.png ///
    output/figures/rd_heterogeneity/fig_hte_`output_stub'_capital_support.png ///
    output/figures/rd_heterogeneity/fig_hte_`output_stub'_conditional_M01.png

if "`level'" == "individual" {
    local output_paths ///
        "`output_paths' output/figures/rd_heterogeneity/fig_hte_`output_stub'_gender_support.png output/figures/rd_heterogeneity/fig_hte_`output_stub'_conditional_M03.png output/figures/rd_heterogeneity/fig_hte_`output_stub'_fuzzy_secondary_age.png"
}

tempname manifest_file
file open `manifest_file' using "${hte_manifest_current}", ///
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
        `""`output_path'","`artifact_type'","${hte_input_basename}","${hte_input_datasignature}","${hte_module_current}","${hte_run_id}","`output_checksum'","generated_unreviewed""' _n
}

file close `manifest_file'

capture program drop _vrd_post_level_hte_iv
capture program drop _vrd_post_level_hte_rdhte
capture program drop _vrd_post_level_hte_na

display as result ///
    "SISFOH 2013 `level' heterogeneity module completed."
display as text ///
    "Common fuzzy interactions passing all gates: `fuzzy_interactions_passing_gate'"
display as text ///
    "Secondary assignment HTE estimates completed: `assignment_hte_estimated'"
display as text ///
    "Interpretation gate: minimum conditional F > ${hte_weak_f_gate}"
display as text "Manifest: ${hte_manifest_current}"
