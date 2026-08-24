/*
Project: Victimas RD
Purpose: Estimate Census 2017 person-level reduced-form and fuzzy-RD effects
Unit:    SISFOH source-cohort person followed in the INEI-assisted 2017 link
Input:   12_census_2017_individual_analysis.dta (Dropbox Coded)
Output:  Aggregate CSV/LaTeX results and publication-formatted figures in Git
*/

version 19
set more off

capture log close victimasrd_rd_2017_individual
log using "${logs_root}/rd_2017_individual_${rd_run_id}.smcl", ///
    name(victimasrd_rd_2017_individual) replace


*-----------------------------------*
**# 1. Input, constructed outcomes, and registry validation
*-----------------------------------*

capture program drop _vrd_prepare_individual_outcomes

program define _vrd_prepare_individual_outcomes
    version 19

    * Narrow age groups complete the harmonized demographic outcome family.
    generate byte age_15_19_outcome_2017 = ///
        inrange(age_2017, 15, 19) if !missing(age_2017)
    generate byte age_20_24_outcome_2017 = ///
        inrange(age_2017, 20, 24) if !missing(age_2017)
    generate byte age_25_29_outcome_2017 = ///
        inrange(age_2017, 25, 29) if !missing(age_2017)

    * CPV codes 1 and 3 identify cohabiting and married respondents.
    generate byte partnered_2017 = ///
        inlist(marital_status_2017, 1, 3) ///
        if age_2017 >= 12 & !missing(marital_status_2017)

    generate double education_years_age14_2017 = ///
        education_years_approx_2017 ///
        if age_2017 >= 14 & !missing(education_years_approx_2017)
    generate byte indigenous_language_age3_2017 = ///
        indigenous_language_2017 ///
        if age_2017 >= 3 & !missing(indigenous_language_2017)

    * Complementary extreme-case migration bound: every unlinked person stays.
    generate byte moved_or_not_linked_zero_2017 = ///
        moved_ccpp_2013_2017 if census2017_linked == 1
    replace moved_or_not_linked_zero_2017 = 0 ///
        if census2017_not_linked == 1
end

use "${rd_input_2017_individual}", clear
quietly datasignature
local input_datasignature "`r(datasignature)'"

assert _N == 193376
isid census2017_cohort_pid

local required_vars ///
    census2017_cohort_pid census2017_baseline_hhid ///
    ruv_id ubigeo_dist ubigeo_ccpp ///
    sample_main_rd victimization_level_source ///
    ${rd_running} ${rd_treatment_2017} ///
    census2017_linked census2017_not_linked age_2017 female_2017 ///
    marital_status_2017 indigenous_language_2017 ///
    education_years_approx_2017 ///
    ${rd_primary_covariates}

foreach required_var of local required_vars {
    confirm variable `required_var'
}

assert regexm(ruv_id, "^S[0-9]{8}$")
assert inlist(${rd_treatment_2017}, 0, 1) ///
    if !missing(${rd_treatment_2017})

_vrd_prepare_individual_outcomes

generate byte rd_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")

quietly count if rd_bc_design
assert r(N) == 110940

quietly count if rd_bc_design & ///
    ((victimization_level_source == "B" & ${rd_running} < 0) | ///
     (victimization_level_source == "C" & ${rd_running} >= 0))
assert r(N) == 0

quietly count if rd_bc_design & ///
    missing(ruv_id, ubigeo_dist, ${rd_running}, ${rd_treatment_2017})
assert r(N) == 0

bysort ruv_id: assert ${rd_running} == ${rd_running}[1] ///
    if rd_bc_design
bysort ruv_id: assert ${rd_treatment_2017} == ///
    ${rd_treatment_2017}[1] if rd_bc_design

encode ruv_id, generate(cluster_ruv)
encode ubigeo_dist, generate(cluster_dist)
egen long cluster_score = group(${rd_running})

egen byte rd_ruv_tag = tag(ruv_id) if rd_bc_design
quietly count if rd_ruv_tag
assert r(N) == 426

local primary_outcomes ///
    female_2017 age_15_29_2017 moved_ccpp_2013_2017 ///
    secondaryplus_age14_2017 employed_age14_2017 ///
    insurance_any_2017 disability_any_2017 wellbeing_core_2017

egen byte primary_missing = rowmiss(`primary_outcomes') ///
    if rd_bc_design & census2017_linked == 1 & age_2017 >= 14
generate byte rd_primary_sample = ///
    rd_bc_design & census2017_linked == 1 & ///
    age_2017 >= 14 & primary_missing == 0

quietly count if rd_primary_sample
assert r(N) == 54317
egen byte rd_primary_ruv_tag = tag(ruv_id) if rd_primary_sample
quietly count if rd_primary_ruv_tag
assert r(N) == 406

quietly count if rd_primary_sample & ///
    abs(${rd_running}) <= ${rd_common_h}
assert r(N) == 5453
egen byte rd_window_ruv_tag = tag(ruv_id) if ///
    rd_primary_sample & abs(${rd_running}) <= ${rd_common_h}
quietly count if rd_window_ruv_tag
assert r(N) == 61

preserve
import delimited using "${rd_registry_2017_ind}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

isid outcome_id
isid paper_order
assert inlist(tier, "primary", "secondary", "mechanism", "exploratory")
assert inlist(scale, 1, 100)
sort paper_order

quietly count
local outcome_count = r(N)
assert `outcome_count' == 51

quietly count if tier == "primary"
assert r(N) == 8

forvalues outcome_index = 1/`outcome_count' {
    local o_order_`outcome_index' = paper_order[`outcome_index']
    local o_id_`outcome_index' = outcome_id[`outcome_index']
    local o_var_`outcome_index' = outcome_var[`outcome_index']
    local o_label_`outcome_index' = outcome_label[`outcome_index']
    local o_family_`outcome_index' = family[`outcome_index']
    local o_tier_`outcome_index' = tier[`outcome_index']
    local o_mult_`outcome_index' = multiplicity_family[`outcome_index']
    local o_transform_`outcome_index' = transform[`outcome_index']
    local o_scale_`outcome_index' = scale[`outcome_index']
    local o_denominator_`outcome_index' = denominator[`outcome_index']
    local o_source_`outcome_index' = source[`outcome_index']
    local o_role_`outcome_index' = paper_role[`outcome_index']
    local o_stub_`outcome_index' = file_stub[`outcome_index']
}
restore

forvalues outcome_index = 1/`outcome_count' {
    local outcome_var "`o_var_`outcome_index''"
    confirm variable `outcome_var'

    if inlist("`o_transform_`outcome_index''", ///
        "binary", "share", "index_0_1") {
        quietly summarize `outcome_var', meanonly
        assert r(min) >= 0 if r(N) > 0
        assert r(max) <= 1 if r(N) > 0
    }
    if "`o_transform_`outcome_index''" == "count" {
        quietly summarize `outcome_var', meanonly
        assert r(min) >= 0 if r(N) > 0
    }
}

* The national file has been validated above; estimation uses only the locked
* B/C design branch. This reduces repeated computation without changing any
* sample rule, weight, bandwidth, or estimand.
keep if rd_bc_design
assert _N == 110940


*-----------------------------------*
**# 2. Design weights and first-stage strength
*-----------------------------------*

generate byte rd_primary_eligible = rd_primary_sample
bysort cluster_ruv: egen long rd_primary_persons = ///
    total(rd_primary_eligible)
generate double rd_weight_ccpp_primary = ///
    rd_primary_eligible / rd_primary_persons ///
    if rd_primary_persons > 0

quietly rdrobust ///
    ${rd_treatment_2017} ${rd_running} if rd_primary_sample, ///
    c(0) p(1) q(2) ///
    h(${rd_common_h} ${rd_common_h}) ///
    b(${rd_common_b} ${rd_common_b}) ///
    kernel(triangular) weights(rd_weight_ccpp_primary) ///
    vce(cr2 cluster_ruv) masspoints(adjust)

local main_first_stage_bc = e(tau_bc)
local main_first_stage_se = e(se_tau_rb)
local main_first_stage_f = ///
    (`main_first_stage_bc' / `main_first_stage_se')^2
local main_first_stage_n = e(N_h_l) + e(N_h_r)
local first_stage_gate = `main_first_stage_f' > ${rd_weak_f_gate}

if !`first_stage_gate' {
    display as error ///
        "WARNING: the person-sample first stage does not meet the gate."
    display as error ///
        "Fuzzy LATEs remain diagnostic; reduced forms and weak-IV inference are required."
}


*-----------------------------------*
**# 3. Reusable weighted continuity-based estimator
*-----------------------------------*

capture program drop _vrd_post_individual_rd

program define _vrd_post_individual_rd
    version 19
    syntax, ///
        POSTHandle(name) ///
        OUTVAR(name) ///
        OUTCOMEID(string) ///
        OUTLABel(string) ///
        FAMily(string) ///
        TIER(string) ///
        MULTIPlicity(string) ///
        PAPEROrder(real) ///
        SPECID(string) ///
        ESTIMAND(string) ///
        USEVAR(name) ///
        SCALE(real) ///
        WEIGHTing(string) ///
        [FUZZY COVariates(varlist) BWSelect(string) ///
        HValue(real -1) BValue(real -1) ///
        POLYOrder(integer 1) BIASOrder(integer 2) ///
        KERNEL(string) VCEType(string) CLUSTERVar(name) ///
        TUNing(real -999) SAMPLERule(string)]

    if "`kernel'" == "" local kernel "triangular"
    if "`vcetype'" == "" local vcetype "cr2 cluster_ruv"
    if "`clustervar'" == "" local clustervar "cluster_ruv"
    if "`bwselect'" == "" local bwselect "mserd"
    if "`samplerule'" == "" local samplerule "selected_bc_individual"
    if `tuning' == -999 local tuning .

    local fuzzy_option
    local estimator_sample ///
        "`usevar' & !missing(`outvar', ${rd_running}, `clustervar')"

    if "`fuzzy'" != "" {
        local fuzzy_option "fuzzy(${rd_treatment_2017})"
        local estimator_sample ///
            "`estimator_sample' & !missing(${rd_treatment_2017})"
    }

    local covariate_option
    if "`covariates'" != "" {
        local covariate_option "covs(`covariates')"
        tempvar covariate_missing
        quietly egen byte `covariate_missing' = rowmiss(`covariates')
        local estimator_sample ///
            "`estimator_sample' & `covariate_missing' == 0"
    }

    tempvar eligible eligible_count analysis_weight
    generate byte `eligible' = `estimator_sample'
    bysort cluster_ruv: egen long `eligible_count' = total(`eligible')

    local weight_option
    if "`weighting'" == "ccpp_equal" {
        generate double `analysis_weight' = ///
            `eligible' / `eligible_count' if `eligible_count' > 0
        local weight_option "weights(`analysis_weight')"
    }
    else if "`weighting'" == "person_equal" {
        generate double `analysis_weight' = 1 if `eligible'
    }
    else {
        display as error "Unknown person weighting rule: `weighting'"
        exit 198
    }

    local bandwidth_option "bwselect(`bwselect')"
    if `hvalue' >= 0 {
        if `bvalue' < 0 local bvalue = `hvalue' / .556
        local bandwidth_option ///
            "h(`hvalue' `hvalue') b(`bvalue' `bvalue')"
        local bwselect "manual"
    }

    quietly count if `estimator_sample'
    local n_input = r(N)

    capture quietly rdrobust ///
        `outvar' ${rd_running} if `estimator_sample', ///
        c(0) p(`polyorder') q(`biasorder') ///
        `bandwidth_option' kernel(`kernel') ///
        `fuzzy_option' `covariate_option' `weight_option' ///
        vce(`vcetype') masspoints(adjust)
    local estimation_rc = _rc

    local h_left .
    local h_right .
    local b_left .
    local b_right .
    local n_eff_left .
    local n_eff_right .
    local ccpp_left .
    local ccpp_right .
    local clusters .
    local estimate_cl .
    local estimate_bc .
    local standard_error .
    local pvalue .
    local ci_low .
    local ci_high .
    local control_mean .
    local control_sd .
    local standardized_estimate .
    local standardized_ci_low .
    local standardized_ci_high .
    local first_stage_cl .
    local first_stage_bc .
    local first_stage_se .
    local first_stage_f .

    if !`estimation_rc' {
        local h_left = e(h_l)
        local h_right = e(h_r)
        local b_left = e(b_l)
        local b_right = e(b_r)
        local n_eff_left = e(N_h_l)
        local n_eff_right = e(N_h_r)
        local estimate_cl = e(tau_cl) * `scale'
        local estimate_bc = e(tau_bc) * `scale'
        local standard_error = e(se_tau_rb) * `scale'
        local pvalue = e(pv_rb)
        local ci_low = e(ci_l_rb) * `scale'
        local ci_high = e(ci_r_rb) * `scale'

        quietly summarize `outvar' [aw = `analysis_weight'] if ///
            `estimator_sample' & ${rd_running} < 0 & ///
            ${rd_running} >= -`h_left'
        local control_mean = r(mean) * `scale'
        local control_sd = r(sd) * `scale'

        if `control_sd' > 0 & `control_sd' < . {
            local standardized_estimate = `estimate_bc' / `control_sd'
            local standardized_ci_low = `ci_low' / `control_sd'
            local standardized_ci_high = `ci_high' / `control_sd'
        }

        tempvar effective_cluster ccpp_left_tag ccpp_right_tag
        quietly egen byte `effective_cluster' = tag(`clustervar') if ///
            `estimator_sample' & ${rd_running} >= -`h_left' & ///
            ${rd_running} <= `h_right'
        quietly count if `effective_cluster' == 1
        local clusters = r(N)

        quietly egen byte `ccpp_left_tag' = tag(cluster_ruv) if ///
            `estimator_sample' & ${rd_running} < 0 & ///
            ${rd_running} >= -`h_left'
        quietly count if `ccpp_left_tag' == 1
        local ccpp_left = r(N)
        quietly egen byte `ccpp_right_tag' = tag(cluster_ruv) if ///
            `estimator_sample' & ${rd_running} >= 0 & ///
            ${rd_running} <= `h_right'
        quietly count if `ccpp_right_tag' == 1
        local ccpp_right = r(N)

        if "`fuzzy'" != "" {
            local first_stage_cl = e(tau_T_cl)
            local first_stage_bc = e(tau_T_bc)
            local first_stage_se = e(se_tau_T_rb)
            if `first_stage_se' > 0 & `first_stage_se' < . {
                local first_stage_f = ///
                    (`first_stage_bc' / `first_stage_se')^2
            }
        }
    }

    post `posthandle' ///
        ("`outcomeid'") ("`outvar'") ("`outlabel'") ///
        ("`family'") ("`tier'") ("`multiplicity'") ///
        (`paperorder') ("`specid'") ("`estimand'") ///
        ("rdrobust") ("`samplerule'") ("`weighting'") ///
        ("`vcetype'") (`polyorder') (`biasorder') ///
        ("`kernel'") ("`bwselect'") (`tuning') ///
        (`h_left') (`h_right') (`b_left') (`b_right') ///
        (`scale') (`n_input') (`n_eff_left') (`n_eff_right') ///
        (`ccpp_left') (`ccpp_right') (`clusters') ///
        (`estimate_cl') (`estimate_bc') (`standard_error') ///
        (`pvalue') (`ci_low') (`ci_high') ///
        (`control_mean') (`control_sd') ///
        (`standardized_estimate') ///
        (`standardized_ci_low') (`standardized_ci_high') ///
        (`first_stage_cl') (`first_stage_bc') ///
        (`first_stage_se') (`first_stage_f') ///
        (.) (.) (.) (`estimation_rc')
end


*-----------------------------------*
**# 4. Continuity-based result grid
*-----------------------------------*

tempfile rd_results_raw rd_results_final
tempname rd_post

postfile `rd_post' ///
    str12 outcome_id ///
    str40 outcome_var ///
    str100 outcome_label ///
    str24 family ///
    str12 tier ///
    str36 multiplicity_family ///
    double paper_order ///
    str40 spec_id ///
    str24 estimand ///
    str16 estimator ///
    str36 sample_rule ///
    str18 weighting ///
    str28 vce ///
    byte p q ///
    str16 kernel ///
    str12 bwselect ///
    double tuning_value ///
    double h_left h_right b_left b_right scale ///
    long n_input n_eff_left n_eff_right ///
    int ccpp_left ccpp_right clusters ///
    double estimate_cl estimate_bc standard_error pvalue ci_low ci_high ///
    double control_mean control_sd ///
    double standardized_estimate standardized_ci_low standardized_ci_high ///
    double first_stage_cl first_stage_bc first_stage_se first_stage_f ///
    double weak_robust_p wild_cluster_p underid_p ///
    int estimation_rc ///
    using "`rd_results_raw'", replace

_vrd_post_individual_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D01") ///
    outlabel("Treatment through 2016: source-cohort universe") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-4) specid("common_h_ccpp_equal") ///
    estimand("first_stage") usevar(rd_bc_design) scale(1) ///
    weighting("ccpp_equal") ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc_individual")

_vrd_post_individual_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D02") ///
    outlabel("Treatment through 2016: complete primary sample") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-3) specid("common_h_primary_ccpp_equal") ///
    estimand("first_stage") usevar(rd_primary_sample) scale(1) ///
    weighting("ccpp_equal") ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc_primary_individual")

_vrd_post_individual_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D03") ///
    outlabel("Treatment through 2016: person-equal sensitivity") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-2) specid("common_h_primary_person_equal") ///
    estimand("first_stage") usevar(rd_primary_sample) scale(1) ///
    weighting("person_equal") ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc_primary_individual")

_vrd_post_individual_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D04") ///
    outlabel("Treatment through 2016: treatment-based MSE selector") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-1) specid("mserd_primary_ccpp_equal") ///
    estimand("first_stage") usevar(rd_primary_sample) scale(1) ///
    weighting("ccpp_equal") bwselect("mserd") ///
    samplerule("selected_bc_primary_individual")

_vrd_post_individual_rd, ///
    posthandle(`rd_post') ///
    outvar(census2017_linked) ///
    outcomeid("D05") ///
    outlabel("Source-cohort person linked to Census 2017") ///
    family("linkage") tier("design") multiplicity("design") ///
    paperorder(-.8) specid("common_h_census_linked") ///
    estimand("selection") usevar(rd_bc_design) scale(100) ///
    weighting("ccpp_equal") ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc_source_cohort")

generate byte rd_primary_donut_005 = ///
    rd_primary_sample & abs(${rd_running}) > .00005
generate byte rd_primary_donut_025 = ///
    rd_primary_sample & abs(${rd_running}) > .00025

forvalues outcome_index = 1/`outcome_count' {
    local outcome_var "`o_var_`outcome_index''"
    local outcome_id "`o_id_`outcome_index''"
    local outcome_label "`o_label_`outcome_index''"
    local outcome_family "`o_family_`outcome_index''"
    local outcome_tier "`o_tier_`outcome_index''"
    local outcome_mult "`o_mult_`outcome_index''"
    local outcome_scale = `o_scale_`outcome_index''
    local outcome_order = `o_order_`outcome_index''

    local outcome_sample "rd_bc_design"
    local sample_rule "selected_bc_individual"
    if "`outcome_tier'" == "primary" {
        local outcome_sample "rd_primary_sample"
        local sample_rule "selected_bc_primary_individual"
    }

    foreach estimand_spec in reduced_form fuzzy {
        local fuzzy_option
        local estimand_name "reduced_form"
        if "`estimand_spec'" == "fuzzy" {
            local fuzzy_option "fuzzy"
            local estimand_name "fuzzy_late"
        }

        _vrd_post_individual_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("common_h_`estimand_spec'") ///
            estimand("`estimand_name'") ///
            usevar(`outcome_sample') scale(`outcome_scale') ///
            weighting("ccpp_equal") `fuzzy_option' ///
            hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
            samplerule("`sample_rule'")
    }

    foreach selector in mserd cerrd {
        _vrd_post_individual_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("outcome_`selector'_fuzzy") ///
            estimand("fuzzy_late") ///
            usevar(`outcome_sample') scale(`outcome_scale') ///
            weighting("ccpp_equal") fuzzy bwselect("`selector'") ///
            samplerule("`sample_rule'")
    }

    if "`outcome_tier'" == "primary" {
        _vrd_post_individual_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("common_h_covariates") estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') ///
            weighting("ccpp_equal") fuzzy ///
            covariates(${rd_primary_covariates}) ///
            hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
            samplerule("selected_bc_primary_individual")

        foreach fixed_window in 005 010 {
            local h_value = ${rd_small_h}
            local b_value = ${rd_small_b}
            if "`fixed_window'" == "010" {
                local h_value = ${rd_large_h}
                local b_value = ${rd_large_b}
            }

            _vrd_post_individual_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") ///
                paperorder(`outcome_order') ///
                specid("fixed_h_`fixed_window'") ///
                estimand("fuzzy_late") ///
                usevar(rd_primary_sample) scale(`outcome_scale') ///
                weighting("ccpp_equal") fuzzy ///
                hvalue(`h_value') bvalue(`b_value') tuning(`h_value') ///
                samplerule("selected_bc_primary_individual")
        }

        _vrd_post_individual_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("common_h_person_equal") ///
            estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') ///
            weighting("person_equal") fuzzy ///
            hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
            samplerule("selected_bc_primary_individual")

        foreach inference_spec in cr1 cr3 {
            _vrd_post_individual_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") ///
                paperorder(`outcome_order') ///
                specid("common_h_`inference_spec'_ccpp") ///
                estimand("fuzzy_late") ///
                usevar(rd_primary_sample) scale(`outcome_scale') ///
                weighting("ccpp_equal") fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                vcetype("`inference_spec' cluster_ruv") ///
                clustervar(cluster_ruv) ///
                samplerule("selected_bc_primary_individual")
        }

        foreach cluster_level in district score {
            local cluster_var "cluster_dist"
            if "`cluster_level'" == "score" ///
                local cluster_var "cluster_score"

            _vrd_post_individual_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") ///
                paperorder(`outcome_order') ///
                specid("common_h_cr2_`cluster_level'") ///
                estimand("fuzzy_late") ///
                usevar(rd_primary_sample) scale(`outcome_scale') ///
                weighting("ccpp_equal") fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                vcetype("cr2 `cluster_var'") ///
                clustervar(`cluster_var') ///
                samplerule("selected_bc_primary_individual")
        }

        foreach kernel_id in uniform epanechnikov {
            _vrd_post_individual_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") ///
                paperorder(`outcome_order') ///
                specid("common_h_`kernel_id'") ///
                estimand("fuzzy_late") ///
                usevar(rd_primary_sample) scale(`outcome_scale') ///
                weighting("ccpp_equal") fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                kernel("`kernel_id'") ///
                samplerule("selected_bc_primary_individual")
        }

        _vrd_post_individual_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("outcome_mserd_p2") estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') ///
            weighting("ccpp_equal") fuzzy ///
            polyorder(2) biasorder(3) bwselect("mserd") ///
            samplerule("selected_bc_primary_individual")

        foreach donut_id in 005 025 {
            local donut_sample "rd_primary_donut_`donut_id'"
            local donut_value = .00005
            if "`donut_id'" == "025" local donut_value = .00025

            _vrd_post_individual_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") ///
                paperorder(`outcome_order') ///
                specid("donut_`donut_id'") estimand("fuzzy_late") ///
                usevar(`donut_sample') scale(`outcome_scale') ///
                weighting("ccpp_equal") fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                tuning(`donut_value') ///
                samplerule("selected_bc_primary_individual")
        }
    }
}

*-----------------------------------*
**# 5. Parametric local-linear IV analogues
*-----------------------------------*

generate byte above_bc = ${rd_running} >= 0 if rd_primary_sample
generate double running_above = ///
    ${rd_running} * above_bc if rd_primary_sample

local kp_f_main .

forvalues outcome_index = 1/`outcome_count' {
    if "`o_tier_`outcome_index''" == "primary" {
        local outcome_var "`o_var_`outcome_index''"
        local outcome_id "`o_id_`outcome_index''"
        local outcome_label "`o_label_`outcome_index''"
        local outcome_family "`o_family_`outcome_index''"
        local outcome_mult "`o_mult_`outcome_index''"
        local outcome_scale = `o_scale_`outcome_index''
        local outcome_order = `o_order_`outcome_index''

        foreach parametric_spec in ///
            parametric_common_h ///
            parametric_covariates ///
            parametric_district ///
            parametric_person_equal {

            local parametric_covariates
            local parametric_cluster "cluster_ruv"
            local parametric_vce "cr1 cluster_ruv"
            local parametric_weighting "ccpp_equal"

            if "`parametric_spec'" == "parametric_covariates" {
                local parametric_covariates ///
                    "${rd_primary_covariates}"
            }
            if "`parametric_spec'" == "parametric_district" {
                local parametric_cluster "cluster_dist"
                local parametric_vce "cr1 cluster_dist"
            }
            if "`parametric_spec'" == "parametric_person_equal" {
                local parametric_weighting "person_equal"
            }

            tempvar parametric_eligible parametric_count ///
                kernel_component parametric_weight ///
                parametric_left_tag parametric_right_tag

            generate byte `parametric_eligible' = ///
                rd_primary_sample & ///
                abs(${rd_running}) <= ${rd_common_h} & ///
                !missing(`outcome_var', ${rd_treatment_2017}, ///
                    above_bc, ${rd_running}, running_above, ///
                    `parametric_cluster')

            if "`parametric_covariates'" != "" {
                tempvar parametric_covariate_missing
                egen byte `parametric_covariate_missing' = ///
                    rowmiss(`parametric_covariates')
                replace `parametric_eligible' = 0 ///
                    if `parametric_covariate_missing' > 0
            }

            bysort cluster_ruv: egen long `parametric_count' = ///
                total(`parametric_eligible')
            generate double `kernel_component' = ///
                1 - abs(${rd_running}) / ${rd_common_h} ///
                if `parametric_eligible'
            replace `kernel_component' = 1e-8 ///
                if `kernel_component' == 0

            generate double `parametric_weight' = `kernel_component' ///
                if `parametric_eligible'
            if "`parametric_weighting'" == "ccpp_equal" {
                replace `parametric_weight' = ///
                    `kernel_component' / `parametric_count' ///
                    if `parametric_eligible' & `parametric_count' > 0
            }

            capture quietly ivreg2 ///
                `outcome_var' ///
                ${rd_running} running_above `parametric_covariates' ///
                (${rd_treatment_2017} = above_bc) ///
                [aw = `parametric_weight'] if `parametric_eligible', ///
                cluster(`parametric_cluster') first
            local estimation_rc = _rc

            local estimate_cl .
            local estimate_bc .
            local standard_error .
            local pvalue .
            local ci_low .
            local ci_high .
            local control_mean .
            local control_sd .
            local standardized_estimate .
            local standardized_ci_low .
            local standardized_ci_high .
            local n_input .
            local n_left .
            local n_right .
            local ccpp_left .
            local ccpp_right .
            local clusters .
            local kp_f .
            local ar_p .
            local wild_p .
            local underid_p .

            if !`estimation_rc' {
                local estimate_cl = ///
                    _b[${rd_treatment_2017}] * `outcome_scale'
                local estimate_bc = `estimate_cl'
                local standard_error = ///
                    _se[${rd_treatment_2017}] * `outcome_scale'
                local pvalue = 2 * normal(-abs( ///
                    _b[${rd_treatment_2017}] / ///
                    _se[${rd_treatment_2017}]))
                local ci_low = `estimate_bc' - 1.96 * `standard_error'
                local ci_high = `estimate_bc' + 1.96 * `standard_error'
                local n_input = e(N)
                local clusters = e(N_clust)

                capture local kp_f = e(rkf)
                capture local ar_p = e(arfp)
                capture local underid_p = e(idp)

                quietly count if e(sample) & ${rd_running} < 0
                local n_left = r(N)
                quietly count if e(sample) & ${rd_running} >= 0
                local n_right = r(N)
                quietly egen byte `parametric_left_tag' = ///
                    tag(cluster_ruv) if e(sample) & ${rd_running} < 0
                quietly count if `parametric_left_tag' == 1
                local ccpp_left = r(N)
                quietly egen byte `parametric_right_tag' = ///
                    tag(cluster_ruv) if e(sample) & ${rd_running} >= 0
                quietly count if `parametric_right_tag' == 1
                local ccpp_right = r(N)

                quietly summarize `outcome_var' ///
                    [aw = `parametric_weight'] if ///
                    e(sample) & ${rd_running} < 0
                local control_mean = r(mean) * `outcome_scale'
                local control_sd = r(sd) * `outcome_scale'

                if `control_sd' > 0 & `control_sd' < . {
                    local standardized_estimate = ///
                        `estimate_bc' / `control_sd'
                    local standardized_ci_low = `ci_low' / `control_sd'
                    local standardized_ci_high = `ci_high' / `control_sd'
                }

                if inlist("`parametric_spec'", ///
                    "parametric_common_h", "parametric_covariates") {
                    capture quietly boottest ${rd_treatment_2017}, ///
                        cluster(`parametric_cluster') reps(4999) ///
                        seed(271828) nograph
                    if !_rc local wild_p = r(p)
                }

                if "`parametric_spec'" == "parametric_common_h" & ///
                    `outcome_order' == 1 {
                    local kp_f_main = `kp_f'
                }
            }

            post `rd_post' ///
                ("`outcome_id'") ("`outcome_var'") ///
                ("`outcome_label'") ("`outcome_family'") ///
                ("primary") ("`outcome_mult'") (`outcome_order') ///
                ("`parametric_spec'") ("parametric_late") ///
                ("ivreg2") ("selected_bc_primary_individual") ///
                ("`parametric_weighting'") ("`parametric_vce'") ///
                (1) (2) ("triangular") ("manual") ///
                (${rd_common_h}) ///
                (${rd_common_h}) (${rd_common_h}) ///
                (${rd_common_b}) (${rd_common_b}) ///
                (`outcome_scale') (`n_input') (`n_left') (`n_right') ///
                (`ccpp_left') (`ccpp_right') (`clusters') ///
                (`estimate_cl') (`estimate_bc') (`standard_error') ///
                (`pvalue') (`ci_low') (`ci_high') ///
                (`control_mean') (`control_sd') ///
                (`standardized_estimate') ///
                (`standardized_ci_low') (`standardized_ci_high') ///
                (.) (.) (.) (`kp_f') (`ar_p') (`wild_p') ///
                (`underid_p') (`estimation_rc')
        }
    }
}

postclose `rd_post'


*-----------------------------------*
**# 6. Multiplicity and machine-readable results
*-----------------------------------*

use "`rd_results_raw'", clear

* Five design/linkage rows, four common rows per registered outcome, and
* seventeen additional robustness rows for each of eight primary outcomes.
local expected_result_rows = 5 + 4 * `outcome_count' + 17 * 8
assert _N == `expected_result_rows'
quietly count if tier == "primary" & ///
    inlist(spec_id, "common_h_reduced_form", "common_h_fuzzy")
assert r(N) == 16

generate double p_holm = .
generate double q_bh = .
egen long correction_group = ///
    group(spec_id estimand multiplicity_family) ///
    if tier != "design" & pvalue < .
generate byte p_missing = missing(pvalue)

sort correction_group p_missing pvalue outcome_id
by correction_group: egen int correction_m = total(pvalue < .) ///
    if correction_group < .
by correction_group: generate int correction_rank = sum(pvalue < .) ///
    if correction_group < . & pvalue < .

replace q_bh = min(1, pvalue * correction_m / correction_rank) ///
    if correction_group < . & pvalue < .
gsort correction_group p_missing -correction_rank outcome_id
by correction_group: replace q_bh = ///
    min(q_bh, q_bh[_n - 1]) ///
    if _n > 1 & correction_group < . & q_bh < .

sort correction_group p_missing correction_rank outcome_id
replace p_holm = ///
    min(1, pvalue * (correction_m - correction_rank + 1)) ///
    if correction_group < . & pvalue < .
by correction_group: replace p_holm = ///
    max(p_holm, p_holm[_n - 1]) ///
    if _n > 1 & correction_group < . & p_holm < .

drop correction_group p_missing correction_m correction_rank
sort paper_order spec_id estimand
save "`rd_results_final'", replace

export delimited using ///
    "${rd_table_dir}/rd_2017_individual_results.csv", ///
    replace nolabel


*-----------------------------------*
**# 7. Analysis-contract audit output
*-----------------------------------*

tempname contract_file
local first_stage_status = cond(`first_stage_gate', "pass", "warning")
local kp_status = cond(`kp_f_main' > ${rd_weak_f_gate}, ///
    "pass", "warning")

file open `contract_file' using ///
    "${rd_table_dir}/rd_2017_individual_analysis_contract.csv", ///
    write replace text

file write `contract_file' ///
    "metric,value,status,interpretation" _n
file write `contract_file' ///
    `""unit","individual","approved","One de-identified Census person linked deterministically to one RUV centro poblado""' _n
file write `contract_file' ///
    `""support","adjacent B/C","approved","Selected legacy geography and recorded RUV categories B or C""' _n
file write `contract_file' ///
    `""treatment","treat_16","approved","Cumulative collective reparations through 2016 for 2017 outcomes""' _n
file write `contract_file' ///
    `""main_weighting","CCPP equal","approved","Each eligible RUV community contributes total weight one; persons are equal within community""' _n
file write `contract_file' ///
    `""weighting_sensitivity","person equal","required","Shows sensitivity to informative Census person counts and changes the population-weighted estimand""' _n
file write `contract_file' ///
    `""common_h","${rd_common_h}","approved","Treatment-design bandwidth used by every main 2017 outcome""' _n
file write `contract_file' ///
    `""common_b","${rd_common_b}","approved","Common bias bandwidth for robust bias correction""' _n
file write `contract_file' ///
    `""linked_persons","141679","validated","Selected B/C linked persons before the age and item-valid primary restriction""' _n
file write `contract_file' ///
    `""primary_persons","54317","validated","Complete eight-outcome sample of persons age 14 or older""' _n
file write `contract_file' ///
    `""primary_ccpp","406","validated","RUV communities represented in the complete primary sample""' _n
file write `contract_file' ///
    `""window_persons","8870","validated","Complete-primary persons inside the common fixed window""' _n
file write `contract_file' ///
    `""window_ccpp","65","validated","RUV communities inside the common fixed window""' _n
file write `contract_file' ///
    `""first_stage_f","`main_first_stage_f'","`first_stage_status'","Squared robust first-stage z statistic under CCPP-equal weighting and CCPP CR2""' _n
file write `contract_file' ///
    `""parametric_kp_f","`kp_f_main'","`kp_status'","CCPP-clustered Kleibergen-Paap F in the weighted local-linear IV model""' _n
file write `contract_file' ///
    `""weak_f_gate","${rd_weak_f_gate}","approved","Conservative interpretation gate; no bandwidth or weighting rule is selected to pass""' _n
file write `contract_file' ///
    `""primary_vce","CCPP CR2","approved","Treatment is assigned at CCPP level; complete ruv_id prevents geographic-code exclusions""' _n
file write `contract_file' ///
    `""cluster_sensitivity","district and score mass point","required","Addresses municipal shocks and repeated running-score values""' _n
file write `contract_file' ///
    `""primary_covariates","${rd_primary_covariates}","sensitivity","Fixed predetermined precision set; unadjusted model remains primary""' _n
file write `contract_file' ///
    `""selection_scope","INEI-assisted source-cohort persons","limitation","Estimates do not automatically generalize to persons absent from Census or unmatched communities""' _n
file close `contract_file'


*-----------------------------------*
**# 8. LaTeX individual outcome registry
*-----------------------------------*

tempname registry_table
file open `registry_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_26_registry_2017_individual.tex", ///
    write replace text

file write `registry_table' "\begingroup" _n
file write `registry_table' "\small" _n
file write `registry_table' "\begin{longtable}{p{0.10\linewidth}p{0.18\linewidth}p{0.24\linewidth}p{0.33\linewidth}}" _n
file write `registry_table' "\caption{Registered Census 2017 individual outcomes and construction rules}" _n
file write `registry_table' "\label{tab:rd_outcome_registry_2017_individual} \\" _n
file write `registry_table' "\toprule" _n
file write `registry_table' "Tier & Family & Outcome & Denominator or construction universe \\" _n
file write `registry_table' "\midrule" _n
file write `registry_table' "\endfirsthead" _n
file write `registry_table' "\multicolumn{4}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `registry_table' "\toprule" _n
file write `registry_table' "Tier & Family & Outcome & Denominator or construction universe \\" _n
file write `registry_table' "\midrule" _n
file write `registry_table' "\endhead" _n

forvalues outcome_index = 1/`outcome_count' {
    local registry_tier = proper("`o_tier_`outcome_index''")
    local registry_family = ///
        proper(subinstr("`o_family_`outcome_index''", "_", " ", .))
    local registry_label "`o_label_`outcome_index''"
    local registry_denominator "`o_denominator_`outcome_index''"

    file write `registry_table' ///
        "`registry_tier' & `registry_family' & `registry_label' & `registry_denominator' \\" _n
}

file write `registry_table' "\bottomrule" _n
file write `registry_table' "\end{longtable}" _n
file write `registry_table' "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} The unit is a de-identified linked Census person. The eight primary outcomes use one complete sample of persons age 14 or older; secondary outcomes use the age, sex, labor-force, or item-valid universe declared in the final column. Binary outcomes are displayed in percentage points and counts remain in natural units. The INEI-assisted file follows a defined SISFOH source cohort into the 2017 Census; it is not the public national Census microdata and has no analysis weight. Estimates therefore describe the linked cohort rather than the full Peruvian population. Source: INEI-assisted Census 2017.\end{minipage}" _n
file write `registry_table' "\endgroup" _n
file close `registry_table'


*-----------------------------------*
**# 9. LaTeX first-stage and main individual tables
*-----------------------------------*

tempname first_stage_table
file open `first_stage_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_27_sample_first_stage_2017_individual.tex", ///
    write replace text

file write `first_stage_table' "\begin{table}[!htbp]" _n
file write `first_stage_table' "\centering" _n
file write `first_stage_table' "\scriptsize" _n
file write `first_stage_table' "\caption{Individual analysis sample and first-stage discontinuity}" _n
file write `first_stage_table' "\label{tab:rd_outcomes_first_stage_2017_individual}" _n
file write `first_stage_table' "\begin{tabular}{p{0.31\linewidth}lrrrrrr}" _n
file write `first_stage_table' "\toprule" _n
file write `first_stage_table' "Analysis sample & Weighting & Estimate & Robust SE & 95\% CI & Persons & CCPP & \(F_z\) \\" _n
file write `first_stage_table' "\midrule" _n

preserve
use "`rd_results_final'", clear
keep if inlist(outcome_id, "D01", "D02", "D03", "D04")
sort paper_order

forvalues result_row = 1/`=_N' {
    local row_label = outcome_label[`result_row']
    local row_weight "CCPP-equal"
    if weighting[`result_row'] == "person_equal" ///
        local row_weight "Person-equal"
    local row_estimate : display %6.3f estimate_bc[`result_row']
    local row_se : display %6.3f standard_error[`result_row']
    local row_ci_low : display %6.3f ci_low[`result_row']
    local row_ci_high : display %6.3f ci_high[`result_row']
    local row_n : display %9.0fc ///
        n_eff_left[`result_row'] + n_eff_right[`result_row']
    local row_ccpp : display %6.0f ///
        ccpp_left[`result_row'] + ccpp_right[`result_row']
    local row_f = ///
        (estimate_bc[`result_row'] / standard_error[`result_row'])^2
    local row_f : display %6.2f `row_f'

    foreach formatted_value in ///
        row_estimate row_se row_ci_low row_ci_high ///
        row_n row_ccpp row_f {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `first_stage_table' ///
        "`row_label' & `row_weight' & `row_estimate' & `row_se' & [`row_ci_low', `row_ci_high'] & `row_n' & `row_ccpp' & `row_f' \\" _n
}
restore

file write `first_stage_table' "\bottomrule" _n
file write `first_stage_table' "\end{tabular}" _n
file write `first_stage_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The outcome is cumulative collective-reparation receipt through 2016. Estimates are robust bias-corrected local-linear triangular-kernel discontinuities at the official B--C cutoff in the selected geography, with mass-point adjustment. The common window is \(h=0.0075\), \(b=0.0135\); the final row uses the treatment-based MSE selector. CCPP-equal weights give each RUV community total weight one and are primary because treatment is assigned at that level; person-equal weights change the target population and are a required sensitivity. Inference is CR2 by complete RUV community ID. \(F_z\) is the squared robust \(z\) statistic and is compared with the strict gate \(F_z>10\). The primary statistic meets that gate; LATEs are still reported with reduced forms and weak-instrument-robust diagnostics. Source: RUV, CMAN, and INEI-assisted Census 2017.}" _n
file write `first_stage_table' "\end{table}" _n
file close `first_stage_table'

tempname linkage_table
file open `linkage_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_33_linkage_2017_individual.tex", ///
    write replace text
file write `linkage_table' "\begin{table}[!htbp]" _n
file write `linkage_table' "\centering" _n
file write `linkage_table' "\small" _n
file write `linkage_table' "\caption{Census 2017 person-linkage diagnostic}" _n
file write `linkage_table' "\label{tab:rd_outcomes_linkage_2017_individual}" _n
file write `linkage_table' "\begin{tabular}{p{0.39\linewidth}rrrrr}" _n
file write `linkage_table' "\toprule" _n
file write `linkage_table' "Linkage outcome & Control mean & Discontinuity & 95\% robust CI & Persons & CCPP \\" _n
file write `linkage_table' "\midrule" _n

preserve
use "`rd_results_final'", clear
keep if outcome_id == "D05"
assert _N == 1
local row_label = outcome_label[1]
local row_mean : display %6.1f control_mean[1]
local row_estimate : display %6.1f estimate_bc[1]
local row_low : display %6.1f ci_low[1]
local row_high : display %6.1f ci_high[1]
local row_n : display %9.0fc n_eff_left[1] + n_eff_right[1]
local row_ccpp = ccpp_left[1] + ccpp_right[1]
local row_ccpp : display %5.0f `row_ccpp'
foreach value in row_mean row_estimate row_low row_high row_n row_ccpp {
    local `value' = strtrim("``value''")
}
file write `linkage_table' ///
    "`row_label' & `row_mean' & `row_estimate' & [`row_low', `row_high'] & `row_n' & `row_ccpp' \\" _n
restore

file write `linkage_table' "\bottomrule" _n
file write `linkage_table' "\end{tabular}" _n
file write `linkage_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The outcome equals one when a SISFOH source-cohort person was linked to the 2017 Census. The estimate uses the common B--C design window, triangular kernels, mass-point adjustment, CCPP-equal weights, and CCPP CR2 inference. The complementary extreme-case migration sensitivities code every unlinked person as moved or as not moved and appear in the secondary table. This is a selection diagnostic, not a program outcome. Sources: RUV, CMAN, SISFOH 2012--2013, and INEI-assisted Census 2017.}" _n
file write `linkage_table' "\end{table}" _n
file close `linkage_table'

tempname main_table
file open `main_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_28_main_2017_individual.tex", ///
    write replace text

file write `main_table' "\begin{table}[!htbp]" _n
file write `main_table' "\centering" _n
file write `main_table' "\scriptsize" _n
file write `main_table' "\caption{Collective reparations and registered Census 2017 individual outcomes}" _n
file write `main_table' "\label{tab:rd_outcomes_main_2017_individual}" _n
file write `main_table' "\begin{tabular}{p{0.28\linewidth}rrrrrrr}" _n
file write `main_table' "\toprule" _n
file write `main_table' "Outcome & Control mean & Reduced form & Fuzzy LATE & 95\% robust CI & Holm \(p\) & Persons & CCPP \\" _n
file write `main_table' "\midrule" _n

forvalues outcome_order = 1/8 {
    preserve
    use "`rd_results_final'", clear
    keep if tier == "primary" & paper_order == `outcome_order' & ///
        inlist(spec_id, "common_h_reduced_form", "common_h_fuzzy")
    assert _N == 2

    local row_label = outcome_label[1]
    quietly summarize control_mean if spec_id == "common_h_fuzzy", meanonly
    local row_mean : display %7.2f r(mean)
    quietly summarize estimate_bc if ///
        spec_id == "common_h_reduced_form", meanonly
    local row_rf : display %7.2f r(mean)
    quietly summarize estimate_bc if spec_id == "common_h_fuzzy", meanonly
    local row_late : display %7.2f r(mean)
    quietly summarize ci_low if spec_id == "common_h_fuzzy", meanonly
    local row_ci_low : display %7.2f r(mean)
    quietly summarize ci_high if spec_id == "common_h_fuzzy", meanonly
    local row_ci_high : display %7.2f r(mean)
    quietly summarize p_holm if spec_id == "common_h_fuzzy", meanonly
    local row_holm : display %6.3f r(mean)
    quietly summarize n_eff_left if spec_id == "common_h_fuzzy", meanonly
    local row_n_left = r(mean)
    quietly summarize n_eff_right if spec_id == "common_h_fuzzy", meanonly
    local row_n : display %9.0fc `row_n_left' + r(mean)
    quietly summarize ccpp_left if spec_id == "common_h_fuzzy", meanonly
    local row_ccpp_left = r(mean)
    quietly summarize ccpp_right if spec_id == "common_h_fuzzy", meanonly
    local row_ccpp : display %6.0f `row_ccpp_left' + r(mean)
    restore

    foreach formatted_value in ///
        row_mean row_rf row_late row_ci_low row_ci_high ///
        row_holm row_n row_ccpp {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `main_table' ///
        "`row_label' & `row_mean' & `row_rf' & `row_late' & [`row_ci_low', `row_ci_high'] & `row_holm' & `row_n' & `row_ccpp' \\" _n
}

file write `main_table' "\midrule" _n
local formatted_first_stage : display %6.3f `main_first_stage_bc'
local formatted_first_stage_n : display %9.0fc `main_first_stage_n'
local formatted_first_stage_low : display %6.3f ///
    `main_first_stage_bc' - 1.96 * `main_first_stage_se'
local formatted_first_stage_high : display %6.3f ///
    `main_first_stage_bc' + 1.96 * `main_first_stage_se'
foreach formatted_value in ///
    formatted_first_stage formatted_first_stage_low ///
    formatted_first_stage_high formatted_first_stage_n {
    local `formatted_value' = strtrim("``formatted_value''")
}
file write `main_table' ///
    "Common first stage & & & `formatted_first_stage' & [`formatted_first_stage_low', `formatted_first_stage_high'] & & `formatted_first_stage_n' & 65 \\" _n
file write `main_table' "\bottomrule" _n
file write `main_table' "\end{tabular}" _n
file write `main_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} All rows use the same complete eight-outcome sample of persons age 14 or older before local-window restriction and the common \(h=0.0075\), \(b=0.0135\) design window. Reduced forms are assignment discontinuities; fuzzy LATEs divide outcome and treatment discontinuities. Every RUV community receives total weight one, with persons equally weighted within community. Estimates are robust bias-corrected local-linear triangular-kernel results with mass-point adjustment and CCPP CR2 inference. All reported effects are percentage points. Holm values adjust across the eight primary outcomes. The local first stage passes the conservative \(F\geq20\) gate; the LATE column must still be read with reduced forms and Anderson--Rubin inference. The assisted linked cohort has no analysis weight and is not the full national Census microdata. Source: RUV, CMAN, and INEI-assisted Census 2017.}" _n
file write `main_table' "\end{table}" _n
file close `main_table'


*-----------------------------------*
**# 10. LaTeX secondary and robustness tables
*-----------------------------------*

tempname secondary_table
file open `secondary_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_29_secondary_2017_individual.tex", ///
    write replace text

file write `secondary_table' "\begingroup" _n
file write `secondary_table' "\scriptsize" _n
file write `secondary_table' "\begin{longtable}{p{0.16\linewidth}p{0.29\linewidth}rrrrrr}" _n
file write `secondary_table' "\caption{Secondary Census 2017 individual fuzzy-RD outcomes}" _n
file write `secondary_table' "\label{tab:rd_outcomes_secondary_2017_individual} \\" _n
file write `secondary_table' "\toprule" _n
file write `secondary_table' "Family & Outcome & Estimate & 95\% robust CI & Raw \(p\) & BH \(q\) & Persons & CCPP \\" _n
file write `secondary_table' "\midrule" _n
file write `secondary_table' "\endfirsthead" _n
file write `secondary_table' "\multicolumn{8}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `secondary_table' "\toprule" _n
file write `secondary_table' "Family & Outcome & Estimate & 95\% robust CI & Raw \(p\) & BH \(q\) & Persons & CCPP \\" _n
file write `secondary_table' "\midrule" _n
file write `secondary_table' "\endhead" _n

preserve
use "`rd_results_final'", clear
keep if tier != "primary" & tier != "design" & ///
    spec_id == "common_h_fuzzy" & estimation_rc == 0
sort paper_order

forvalues result_row = 1/`=_N' {
    local row_family = proper(subinstr(family[`result_row'], "_", " ", .))
    local row_label = outcome_label[`result_row']
    local row_estimate : display %7.2f estimate_bc[`result_row']
    local row_ci_low : display %7.2f ci_low[`result_row']
    local row_ci_high : display %7.2f ci_high[`result_row']
    local row_p : display %6.3f pvalue[`result_row']
    local row_q : display %6.3f q_bh[`result_row']
    local row_n : display %9.0fc ///
        n_eff_left[`result_row'] + n_eff_right[`result_row']
    local row_ccpp : display %6.0f ///
        ccpp_left[`result_row'] + ccpp_right[`result_row']

    foreach formatted_value in ///
        row_estimate row_ci_low row_ci_high row_p row_q row_n row_ccpp {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `secondary_table' ///
        "`row_family' & `row_label' & `row_estimate' & [`row_ci_low', `row_ci_high'] & `row_p' & `row_q' & `row_n' & `row_ccpp' \\" _n
}
restore

file write `secondary_table' "\bottomrule" _n
file write `secondary_table' "\end{longtable}" _n
file write `secondary_table' "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} Each row is a separate fuzzy-RD estimate in the common \(h=0.0075\), \(b=0.0135\) window with CCPP-equal weights, local-linear triangular kernels, mass-point adjustment, and CCPP CR2 inference. Weights are recomputed after applying the outcome-specific eligibility and missing-data rule, so each represented RUV community contributes total weight one. BH values control the false discovery rate within each declared outcome family. Denominators and eligibility rules are reported in Table~\ref{tab:rd_outcome_registry_2017_individual}. The schooling measure is an attainment-based proxy and not observed current enrollment. The first-stage strength safeguard and person-linkage diagnostics apply to every LATE. Source: RUV, CMAN, and INEI-assisted Census 2017.\end{minipage}" _n
file write `secondary_table' "\endgroup" _n
file close `secondary_table'

tempname robustness_table
file open `robustness_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_30_robustness_2017_individual.tex", ///
    write replace text

file write `robustness_table' "\begingroup" _n
file write `robustness_table' "\scriptsize" _n
file write `robustness_table' "\setlength{\tabcolsep}{2.5pt}" _n
file write `robustness_table' "\begin{longtable}{p{0.18\linewidth}p{0.15\linewidth}p{0.10\linewidth}rrrrr}" _n
file write `robustness_table' "\caption{Primary individual outcome specification and weighting sensitivity}" _n
file write `robustness_table' "\label{tab:rd_outcomes_robustness_2017_individual} \\" _n
file write `robustness_table' "\toprule" _n
file write `robustness_table' "Outcome & Specification & Weighting & Estimate & 95\% CI & \(h\) & Robust/AR \(p\) & Persons \\" _n
file write `robustness_table' "\midrule" _n
file write `robustness_table' "\endfirsthead" _n
file write `robustness_table' "\multicolumn{8}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `robustness_table' "\toprule" _n
file write `robustness_table' "Outcome & Specification & Weighting & Estimate & 95\% CI & \(h\) & Robust/AR \(p\) & Persons \\" _n
file write `robustness_table' "\midrule" _n
file write `robustness_table' "\endhead" _n

preserve
use "`rd_results_final'", clear
keep if tier == "primary" & inlist(spec_id, ///
    "common_h_fuzzy", "common_h_covariates", ///
    "common_h_person_equal", ///
    "outcome_mserd_fuzzy", "outcome_cerrd_fuzzy", ///
    "fixed_h_005", "fixed_h_010", ///
    "parametric_common_h", "parametric_district")
generate byte specification_order = .
replace specification_order = 1 if spec_id == "common_h_fuzzy"
replace specification_order = 2 if spec_id == "common_h_covariates"
replace specification_order = 3 if spec_id == "common_h_person_equal"
replace specification_order = 4 if spec_id == "fixed_h_005"
replace specification_order = 5 if spec_id == "fixed_h_010"
replace specification_order = 6 if spec_id == "outcome_mserd_fuzzy"
replace specification_order = 7 if spec_id == "outcome_cerrd_fuzzy"
replace specification_order = 8 if spec_id == "parametric_common_h"
replace specification_order = 9 if spec_id == "parametric_district"
assert specification_order < .
sort paper_order specification_order

forvalues result_row = 1/`=_N' {
    local row_label = outcome_label[`result_row']
    local row_spec "Common window"
    if spec_id[`result_row'] == "common_h_covariates" ///
        local row_spec "Common + covariates"
    if spec_id[`result_row'] == "common_h_person_equal" ///
        local row_spec "Common, person weights"
    if spec_id[`result_row'] == "fixed_h_005" ///
        local row_spec "Fixed (h=0.0050)"
    if spec_id[`result_row'] == "fixed_h_010" ///
        local row_spec "Fixed (h=0.0100)"
    if spec_id[`result_row'] == "outcome_mserd_fuzzy" ///
        local row_spec "Outcome-specific MSE"
    if spec_id[`result_row'] == "outcome_cerrd_fuzzy" ///
        local row_spec "Outcome-specific CER"
    if spec_id[`result_row'] == "parametric_common_h" ///
        local row_spec "2SLS, CCPP SE"
    if spec_id[`result_row'] == "parametric_district" ///
        local row_spec "2SLS, district SE"

    local row_weight "CCPP-equal"
    if weighting[`result_row'] == "person_equal" ///
        local row_weight "Person-equal"
    local row_estimate : display %7.2f estimate_bc[`result_row']
    local row_ci_low : display %7.2f ci_low[`result_row']
    local row_ci_high : display %7.2f ci_high[`result_row']
    local row_h : display %6.4f h_left[`result_row']
    local row_p_value = pvalue[`result_row']
    if estimator[`result_row'] == "ivreg2" & ///
        weak_robust_p[`result_row'] < . {
        local row_p_value = weak_robust_p[`result_row']
    }
    local row_p : display %6.3f `row_p_value'
    local row_n = n_eff_left[`result_row'] + n_eff_right[`result_row']
    if estimator[`result_row'] == "ivreg2" ///
        local row_n = n_input[`result_row']
    local row_n : display %9.0fc `row_n'

    foreach formatted_value in ///
        row_estimate row_ci_low row_ci_high row_h row_p row_n {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `robustness_table' ///
        "`row_label' & `row_spec' & `row_weight' & `row_estimate' & [`row_ci_low', `row_ci_high'] & `row_h' & `row_p' & `row_n' \\" _n
}
restore

file write `robustness_table' "\bottomrule" _n
file write `robustness_table' "\end{longtable}" _n
file write `robustness_table' "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} The common-window CCPP-equal row is primary. Sensitivities add the fixed predetermined covariate set; change to person-equal weighting; use outcome-specific MSE and coverage-error selectors; narrow or widen the fixed window; and fit triangular-weighted local-linear 2SLS analogues. Continuity-based rows report robust bias-corrected inference. Parametric rows report cluster-robust Anderson--Rubin \(p\)-values when available. The machine-readable CSV additionally contains CCPP CR1/CR3, district and score-mass-point CR2, alternative kernels, local quadratic, donut, Kleibergen--Paap, underidentification, and wild-cluster-bootstrap diagnostics. No specification is selected by statistical significance. Source: RUV, CMAN, and INEI-assisted Census 2017.\end{minipage}" _n
file write `robustness_table' "\endgroup" _n
file close `robustness_table'


*-----------------------------------*
**# 11. Weighted first-stage and primary-outcome RD plots
*-----------------------------------*

use "${rd_input_2017_individual}", clear
_vrd_prepare_individual_outcomes

generate byte rd_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")
egen byte primary_missing = rowmiss(`primary_outcomes') ///
    if rd_bc_design & census2017_linked == 1 & age_2017 >= 14
generate byte rd_primary_sample = ///
    rd_bc_design & census2017_linked == 1 & ///
    age_2017 >= 14 & primary_missing == 0
keep if rd_bc_design
encode ruv_id, generate(cluster_ruv)

capture program drop _vrd_make_individual_rdplot

program define _vrd_make_individual_rdplot
    version 19
    syntax, ///
        OUTVAR(name) ///
        OUTLABel(string) ///
        PANELLABel(string) ///
        YTITle(string) ///
        SCALE(real) ///
        SAMPLEVAR(name) ///
        GRAPHNAME(name) ///
        FIGURE(string) ///
        [FIRSTStage]

    tempvar graph_outcome graph_eligible graph_count ///
        graph_weight graph_bin_tag
    generate double `graph_outcome' = `outvar' * `scale' ///
        if `samplevar'
    generate byte `graph_eligible' = ///
        `samplevar' & !missing(`graph_outcome')
    bysort cluster_ruv: egen long `graph_count' = ///
        total(`graph_eligible')
    generate double `graph_weight' = ///
        `graph_eligible' / `graph_count' if `graph_count' > 0

    quietly rdrobust ///
        `graph_outcome' ${rd_running} if `graph_eligible', ///
        c(0) p(1) q(2) ///
        h(${rd_common_h} ${rd_common_h}) ///
        b(${rd_common_b} ${rd_common_b}) ///
        kernel(triangular) weights(`graph_weight') ///
        vce(cr2 cluster_ruv) masspoints(adjust)

    local graph_estimate = e(tau_bc)
    local graph_p = e(pv_rb)
    local graph_n = e(N_h_l) + e(N_h_r)
    local graph_estimate_text : display %6.2f `graph_estimate'
    local graph_p_text : display %5.3f `graph_p'
    local graph_p_phrase "p = `graph_p_text'"
    if `graph_p' < .001 local graph_p_phrase "p < 0.001"
    foreach formatted_value in graph_estimate_text graph_p_text {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    local graph_title_prefix "Assignment discontinuity"
    local graph_effect_label "reduced form"
    local panel_effect_label "RF"
    if "`firststage'" != "" {
        local graph_title_prefix "First-stage discontinuity"
        local graph_effect_label "assignment jump"
        local panel_effect_label "FS"
    }

    capture drop rdplot_*
    quietly rdplot ///
        `graph_outcome' ${rd_running} if ///
            `graph_eligible' & ///
            abs(${rd_running}) <= ${rd_common_h}, ///
        c(0) p(1) h(${rd_common_h} ${rd_common_h}) ///
        kernel(triangular) weights(`graph_weight') ///
        binselect(qsmv) masspoints(adjust) ///
        ci(95) genvars hide

    egen byte `graph_bin_tag' = tag(rdplot_id) if !missing(rdplot_id)
    local full_graph_name = ///
        subinstr("`graphname'", "panel", "full", .)

    twoway ///
        (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x < 0, ///
            lcolor(navy%48) lwidth(vthin)) ///
        (scatter rdplot_mean_y rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x < 0, ///
            mcolor(navy) msymbol(O) msize(small)) ///
        (line rdplot_hat_y ${rd_running} if ///
            `graph_eligible' & ${rd_running} < 0 & ///
            ${rd_running} >= -${rd_common_h}, ///
            sort lcolor(navy) lwidth(medthick)) ///
        (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            lcolor(maroon%48) lwidth(vthin)) ///
        (scatter rdplot_mean_y rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            mcolor(maroon) msymbol(D) msize(small)) ///
        (line rdplot_hat_y ${rd_running} if ///
            `graph_eligible' & ${rd_running} >= 0 & ///
            ${rd_running} <= ${rd_common_h}, ///
            sort lcolor(maroon) lwidth(medthick)), ///
        xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
        xlabel(, format(%6.3f) grid glcolor(gs14) ///
            glwidth(vthin) labsize(small)) ///
        ylabel(, angle(0) grid glcolor(gs14) ///
            glwidth(vthin) labsize(small)) ///
        xtitle("Victimization index centered at B-C", size(small)) ///
        ytitle("`ytitle'", size(small)) ///
        title("`graph_title_prefix': `outlabel'", ///
            size(medium) color(black)) ///
        subtitle("Fixed h = 0.0075; `graph_effect_label' = `graph_estimate_text'; robust `graph_p_phrase'", ///
            size(small) color(gs5)) ///
        legend(order(2 "Below cutoff" 5 "At or above cutoff" ///
            3 "Local-linear fits") rows(1) position(6) ///
            size(small) region(lcolor(none))) ///
        note( ///
            "Notes: Unit is a de-identified Census person age 14 or older in the selected B/C geography; each RUV community has total weight one." ///
            "Points are weighted quantile-spaced binned means; bars are 95% bin confidence intervals." ///
            "Lines are triangular-kernel local-linear fits within h = 0.0075; the subtitle reports the robust bias-corrected `graph_effect_label'." ///
            "Inference is CR2 by RUV community with mass-point adjustment (effective persons = `graph_n')." ///
            "Fuzzy LATE and weak-first-stage diagnostics are reported in the tables. Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
            size(vsmall) color(gs5) span) ///
        xsize(10) ysize(7) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`full_graph_name', replace)

    graph export "`figure'", width(3000) replace

    twoway ///
        (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x < 0, ///
            lcolor(navy%48) lwidth(vthin)) ///
        (scatter rdplot_mean_y rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x < 0, ///
            mcolor(navy) msymbol(O) msize(vsmall)) ///
        (line rdplot_hat_y ${rd_running} if ///
            `graph_eligible' & ${rd_running} < 0 & ///
            ${rd_running} >= -${rd_common_h}, ///
            sort lcolor(navy) lwidth(medium)) ///
        (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            lcolor(maroon%48) lwidth(vthin)) ///
        (scatter rdplot_mean_y rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            mcolor(maroon) msymbol(D) msize(vsmall)) ///
        (line rdplot_hat_y ${rd_running} if ///
            `graph_eligible' & ${rd_running} >= 0 & ///
            ${rd_running} <= ${rd_common_h}, ///
            sort lcolor(maroon) lwidth(medium)), ///
        xline(0, lcolor(black) lpattern(dash) lwidth(vthin)) ///
        xscale(range(-.008 .008)) ///
        xlabel(-.0075 "-.0075" 0 "0" .0075 ".0075", ///
            grid glcolor(gs14) glwidth(vthin) labsize(tiny)) ///
        ylabel(, angle(0) grid glcolor(gs14) ///
            glwidth(vthin) labsize(tiny)) ///
        xtitle("Centered victimization score", size(vsmall)) ///
        ytitle("`ytitle'", size(vsmall)) ///
        title("`panellabel'", size(tiny) color(black)) ///
        subtitle("`panel_effect_label' = `graph_estimate_text'; `graph_p_phrase'", ///
            size(vsmall) color(gs5)) ///
        legend(off) ///
        graphregion(color(white) margin(tiny)) ///
        plotregion(color(white) margin(tiny)) ///
        name(`graphname', replace) nodraw

    drop rdplot_*
end

_vrd_make_individual_rdplot, ///
    outvar(${rd_treatment_2017}) ///
    outlabel("Treatment through 2016") ///
    panellabel("Treatment through 2016") ///
    ytitle("Treatment probability") ///
    scale(1) samplevar(rd_primary_sample) ///
    graphname(rd_ind_panel_1) ///
    figure("${rd_figure_dir}/fig_rd_outcomes_65_first_stage_2016_individual.png") ///
    firststage

forvalues outcome_index = 1/8 {
    local outcome_var "`o_var_`outcome_index''"
    local outcome_label "`o_label_`outcome_index''"
    local outcome_scale = `o_scale_`outcome_index''
    local outcome_stub "`o_stub_`outcome_index''"
    local panel_number = `outcome_index' + 1
    local figure_number = `outcome_index' + 68
    local figure_number : display %02.0f `figure_number'
    local figure_number = strtrim("`figure_number'")
    local outcome_ytitle "Percentage points"
    local panel_label "Female"
    if `outcome_index' == 2 local panel_label "Age 15-29"
    if `outcome_index' == 3 local panel_label "Lives in another CCPP"
    if `outcome_index' == 4 local panel_label "Secondary education"
    if `outcome_index' == 5 local panel_label "Employed"
    if `outcome_index' == 6 local panel_label "Health insurance"
    if `outcome_index' == 7 local panel_label "Disability"
    if `outcome_index' == 8 local panel_label "Core wellbeing"

    _vrd_make_individual_rdplot, ///
        outvar(`outcome_var') ///
        outlabel("`outcome_label'") ///
        panellabel("`panel_label'") ///
        ytitle("`outcome_ytitle'") ///
        scale(`outcome_scale') samplevar(rd_primary_sample) ///
        graphname(rd_ind_panel_`panel_number') ///
        figure("${rd_figure_dir}/fig_rd_outcomes_`figure_number'_`outcome_stub'_individual.png")
}

graph combine ///
    rd_ind_panel_1 rd_ind_panel_2 rd_ind_panel_3 ///
    rd_ind_panel_4 rd_ind_panel_5 rd_ind_panel_6 ///
    rd_ind_panel_7 rd_ind_panel_8 rd_ind_panel_9, ///
    rows(3) imargin(tiny) ///
    title("Primary Census 2017 individual RD plots", ///
        size(small) color(black)) ///
    subtitle("Common B-C design window; CCPP-equal reduced-form fits", ///
        size(vsmall) color(gs5)) ///
    note( ///
        "Notes: Unit is a de-identified Census person age 14 or older in the selected B/C geography; every RUV community receives total weight one." ///
        "All panels use the complete eight-outcome primary sample, h = 0.0075, triangular kernels, and mass-point adjustment." ///
        "Panel subtitles report robust bias-corrected reduced forms with CCPP CR2 inference; binned points include 95% intervals." ///
        "Fuzzy LATE and weak-instrument diagnostics appear in the tables. Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    iscale(.85) xsize(14) ysize(10) ///
    graphregion(color(white) margin(small))

graph export ///
    "${rd_figure_dir}/fig_rd_outcomes_66_primary_panels_2017_individual.png", ///
    width(3600) replace


*-----------------------------------*
**# 12. Fuzzy-LATE and bandwidth summaries
*-----------------------------------*

use "`rd_results_final'", clear
keep if tier == "primary" & ///
    spec_id == "common_h_fuzzy" & estimation_rc == 0
sort paper_order
assert _N == 8
generate byte plot_order = 9 - paper_order

capture label drop rd_individual_primary_axis
forvalues result_row = 1/`=_N' {
    local axis_value = plot_order[`result_row']
    local axis_outcome = outcome_id[`result_row']
    local axis_label "Female"
    if "`axis_outcome'" == "I02" local axis_label "Age 15-29"
    if "`axis_outcome'" == "I03" local axis_label "Moved CCPP"
    if "`axis_outcome'" == "I04" local axis_label "Secondary education"
    if "`axis_outcome'" == "I05" local axis_label "Employed"
    if "`axis_outcome'" == "I06" local axis_label "Health insurance"
    if "`axis_outcome'" == "I07" local axis_label "Disability"
    if "`axis_outcome'" == "I08" local axis_label "Core wellbeing"
    label define rd_individual_primary_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_individual_primary_axis

twoway ///
    (rcap standardized_ci_low standardized_ci_high plot_order, ///
        horizontal lcolor(navy%65) lwidth(medium)) ///
    (scatter plot_order standardized_estimate, ///
        mcolor(maroon) msymbol(D) msize(medium)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(1(1)8, valuelabel angle(0) labsize(small) nogrid) ///
    xtitle("Bias-corrected fuzzy-RD effect (control-side SD units)", ///
        size(small)) ///
    ytitle("") ///
    title("Primary individual fuzzy-RD effects", ///
        size(medium) color(black)) ///
    subtitle("CCPP-equal estimates; common h = 0.0075; robust 95% intervals", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Unit is a linked Census person in the selected B/C geography; each RUV community receives total weight one." ///
        "Effects are scaled by the weighted below-cutoff outcome SD and estimated with local-linear triangular-kernel fuzzy RD." ///
        "Intervals use robust bias correction, mass-point adjustment, and CCPP CR2 inference." ///
        "The first stage exceeds the prespecified strict F > 10 gate; LATEs remain paired with reduced forms and Anderson-Rubin inference." ///
        "Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${rd_figure_dir}/fig_rd_outcomes_67_late_forest_2017_individual.png", ///
    width(3000) replace

use "`rd_results_final'", clear
keep if tier == "primary" & ///
    inlist(spec_id, "fixed_h_005", "common_h_fuzzy", "fixed_h_010") & ///
    estimation_rc == 0
assert _N == 24
generate double bandwidth = h_left
sort outcome_id bandwidth
generate byte plot_order = 9 - paper_order
generate double plot_position = plot_order
replace plot_position = plot_order - .18 if spec_id == "fixed_h_005"
replace plot_position = plot_order + .18 if spec_id == "fixed_h_010"

capture label drop rd_individual_bandwidth_axis
sort paper_order bandwidth
forvalues result_row = 1/`=_N' {
    local axis_value = plot_order[`result_row']
    local axis_outcome = outcome_id[`result_row']
    local axis_label "Female"
    if "`axis_outcome'" == "I02" local axis_label "Age 15-29"
    if "`axis_outcome'" == "I03" local axis_label "Moved CCPP"
    if "`axis_outcome'" == "I04" local axis_label "Secondary education"
    if "`axis_outcome'" == "I05" local axis_label "Employed"
    if "`axis_outcome'" == "I06" local axis_label "Health insurance"
    if "`axis_outcome'" == "I07" local axis_label "Disability"
    if "`axis_outcome'" == "I08" local axis_label "Core wellbeing"
    capture label define rd_individual_bandwidth_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_individual_bandwidth_axis
label values plot_position rd_individual_bandwidth_axis

twoway ///
    (rcap standardized_ci_low standardized_ci_high plot_position ///
        if spec_id == "fixed_h_005", horizontal ///
        lcolor(eltblue%75) lwidth(thin)) ///
    (scatter plot_position standardized_estimate ///
        if spec_id == "fixed_h_005", ///
        mcolor(eltblue) msymbol(O) msize(small)) ///
    (rcap standardized_ci_low standardized_ci_high plot_position ///
        if spec_id == "common_h_fuzzy", horizontal ///
        lcolor(navy%75) lwidth(thin)) ///
    (scatter plot_position standardized_estimate ///
        if spec_id == "common_h_fuzzy", ///
        mcolor(navy) msymbol(D) msize(small)) ///
    (rcap standardized_ci_low standardized_ci_high plot_position ///
        if spec_id == "fixed_h_010", horizontal ///
        lcolor(maroon%65) lwidth(thin)) ///
    (scatter plot_position standardized_estimate ///
        if spec_id == "fixed_h_010", ///
        mcolor(maroon) msymbol(T) msize(small)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(vthin)) ///
    xlabel(, labsize(small) grid glcolor(gs14) glwidth(vthin)) ///
    ylabel(1(1)8, valuelabel angle(0) labsize(small) nogrid) ///
    xtitle("Fuzzy-RD effect (control-side SD units)", size(small)) ///
    ytitle("") ///
    title("Bandwidth sensitivity of primary individual outcomes", ///
        size(medium) color(black)) ///
    subtitle("CCPP-equal estimates with prespecified fixed bandwidths", ///
        size(small) color(gs5)) ///
    legend(order(2 "h = 0.0050" 4 "h = 0.0075 (common)" ///
        6 "h = 0.0100") rows(1) position(6) size(small) ///
        region(lcolor(none))) ///
    note( ///
        "Notes: Unit is a linked Census person; each RUV community receives total weight one." ///
        "All models use local-linear triangular kernels, mass-point adjustment, and CCPP CR2 inference." ///
        "The center point is the common design window; flanking points are prespecified sensitivities." ///
        "No window is selected by an outcome estimate. Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${rd_figure_dir}/fig_rd_outcomes_68_bandwidth_sensitivity_2017_individual.png", ///
    width(3600) replace


*-----------------------------------*
**# 13. Individual output manifest and closeout
*-----------------------------------*

local output_paths ///
    output/tables/rd_outcomes/rd_2017_individual_results.csv ///
    output/tables/rd_outcomes/rd_2017_individual_analysis_contract.csv ///
    output/tables/rd_outcomes/tab_rd_outcomes_26_registry_2017_individual.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_27_sample_first_stage_2017_individual.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_28_main_2017_individual.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_29_secondary_2017_individual.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_30_robustness_2017_individual.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_33_linkage_2017_individual.tex ///
    output/figures/rd_outcomes/fig_rd_outcomes_65_first_stage_2016_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_66_primary_panels_2017_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_67_late_forest_2017_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_68_bandwidth_sensitivity_2017_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_69_female_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_70_age_15_29_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_71_moved_ccpp_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_72_secondary_education_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_73_employment_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_74_health_insurance_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_75_disability_individual.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_76_wellbeing_core_individual.png

tempname manifest_file
file open `manifest_file' using "${rd_2017_individual_manifest}", ///
    write replace text
file write `manifest_file' ///
    "path,artifact_type,input_data,input_datasignature,generator,run_id,checksum,review_status" _n

foreach output_path of local output_paths {
    local absolute_output "${project_root}/`output_path'"
    capture confirm file "`absolute_output'"
    if _rc {
        display as error "Expected 2017 individual output was not created:"
        display as error "  `absolute_output'"
        file close `manifest_file'
        log close victimasrd_rd_2017_individual
        exit 603
    }

    quietly checksum "`absolute_output'"
    local output_checksum : display %20.0f r(checksum)
    local output_checksum = strtrim("`output_checksum'")
    local artifact_type "table"
    if strpos("`output_path'", "output/figures/") == 1 {
        local artifact_type "figure"
    }
    if strpos("`output_path'", "analysis_contract.csv") > 0 {
        local artifact_type "metadata"
    }

    file write `manifest_file' ///
        `""`output_path'","`artifact_type'","12_census_2017_individual_analysis.dta","`input_datasignature'","code/stata/pipeline/04f_census2017_individual.do","${rd_run_id}","`output_checksum'","generated_unreviewed""' _n
}

file close `manifest_file'

capture program drop _vrd_prepare_individual_outcomes
capture program drop _vrd_post_individual_rd
capture program drop _vrd_make_individual_rdplot

display as result "Census 2017 individual outcome module completed."
display as text "Registered outcomes: `outcome_count'"
display as text "Complete primary persons: 54317"
display as text "Primary linked RUV communities: 406"
display as text "Common fixed-window persons: `main_first_stage_n'"
display as text "Robust first-stage F_z: `main_first_stage_f'"
display as text "Parametric Kleibergen-Paap F: `kp_f_main'"
display as text "Review status: generated_unreviewed"

log close victimasrd_rd_2017_individual
exit 0
