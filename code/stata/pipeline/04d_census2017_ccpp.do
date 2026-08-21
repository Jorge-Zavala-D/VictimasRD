/*
Project: Victimas RD
Purpose: Estimate Census 2017 CCPP reduced-form and fuzzy-RD effects
Unit:    RUV centro poblado
Input:   14_community_registry_census_2017.dta (Dropbox Coded)
Output:  Aggregate CSV/LaTeX results and publication-formatted figures in Git
*/

version 19
set more off

capture log close victimasrd_rd_2017_ccpp
log using "${logs_root}/rd_2017_ccpp_${rd_run_id}.smcl", ///
    name(victimasrd_rd_2017_ccpp) replace


*-----------------------------------*
**# 1. Input and registry validation
*-----------------------------------*

use "${rd_input_2017_ccpp}", clear
quietly datasignature
local input_datasignature "`r(datasignature)'"

assert _N == 5712

local required_vars ///
    ubigeo_dist ubigeo_ccpp sample_main_rd ///
    victimization_level_source ${rd_running} ///
    ${rd_treatment_2017} census2017_cohort_covered ///
    cpv2017_link_rate population_2017 dwellings_occupied_2017 ///
    ${rd_primary_covariates}

foreach required_var of local required_vars {
    confirm variable `required_var'
}

assert inlist(${rd_treatment_2017}, 0, 1) if !missing(${rd_treatment_2017})

generate byte rd_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")

quietly count if rd_bc_design
assert r(N) == 549

quietly count if rd_bc_design & ///
    ((victimization_level_source == "B" & ${rd_running} < 0) | ///
     (victimization_level_source == "C" & ${rd_running} >= 0))
assert r(N) == 0

quietly count if rd_bc_design & missing(ubigeo_dist, ${rd_running})
assert r(N) == 0

preserve
keep if rd_bc_design & !missing(ubigeo_ccpp)
isid ubigeo_ccpp
restore

generate double ln_population_2017 = ///
    ln(population_2017) if population_2017 > 0
generate double ln_dwellings_occupied_2017 = ///
    ln(dwellings_occupied_2017) if dwellings_occupied_2017 > 0

generate byte rd_census_sample = ///
    rd_bc_design & census2017_cohort_covered == 1

local primary_outcomes ///
    ln_population_2017 ///
    ln_dwellings_occupied_2017 ///
    cpv2017_share_moved_ccpp ///
    share_age_15_29_2017 ///
    cpv2017_share_secondary_age14 ///
    cpv2017_share_employed_age14 ///
    cpv2017_share_insured ///
    wellbeing_core_2017

egen byte primary_missing = rowmiss(`primary_outcomes') ///
    if rd_census_sample
generate byte rd_primary_sample = ///
    rd_census_sample & primary_missing == 0

quietly count if rd_census_sample
assert r(N) == 426
quietly count if rd_primary_sample
assert r(N) == 388

encode ubigeo_dist, generate(cluster_dist)

preserve
import delimited using "${rd_registry_2017_ccpp}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)

isid outcome_id
isid paper_order
assert inlist(tier, "primary", "secondary", "mechanism", "exploratory")
assert inlist(scale, 1, 100)
sort paper_order

quietly count
local outcome_count = r(N)
assert `outcome_count' == 39

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

    if inlist("`o_transform_`outcome_index''", "share", "index_0_1") {
        quietly summarize `outcome_var', meanonly
        assert r(min) >= 0 if r(N) > 0
        assert r(max) <= 1 if r(N) > 0
    }
}


*-----------------------------------*
**# 2. Design-bandwidth and strength checks
*-----------------------------------*

quietly rdrobust ///
    ${rd_treatment_2017} ${rd_running} if rd_bc_design, ///
    c(0) p(1) q(2) bwselect(mserd) ///
    kernel(triangular) ///
    vce(cr2 cluster_dist) ///
    masspoints(adjust)

local selected_h = e(h_l)
local selected_b = e(b_l)

assert abs(`selected_h' - ${rd_common_h}) <= .0015
assert abs(`selected_b' - ${rd_common_b}) <= .0025

quietly rdrobust ///
    ${rd_treatment_2017} ${rd_running} if rd_primary_sample, ///
    c(0) p(1) q(2) ///
    h(${rd_common_h} ${rd_common_h}) ///
    b(${rd_common_b} ${rd_common_b}) ///
    kernel(triangular) ///
    vce(cr2 cluster_dist) ///
    masspoints(adjust)

local main_first_stage_bc = e(tau_bc)
local main_first_stage_se = e(se_tau_rb)
local main_first_stage_f = ///
    (`main_first_stage_bc' / `main_first_stage_se')^2
local main_first_stage_n = e(N_h_l) + e(N_h_r)
local first_stage_gate = `main_first_stage_f' >= ${rd_weak_f_gate}

if !`first_stage_gate' {
    display as error ///
        "WARNING: the conservative weak-first-stage gate is not met."
    display as error ///
        "Fuzzy LATE outputs are diagnostic and interpretation-gated."
}


*-----------------------------------*
**# 3. Reusable continuity-based estimator
*-----------------------------------*

capture program drop _vrd_post_outcome_rd

program define _vrd_post_outcome_rd
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
        [FUZZY COVariates(varlist) BWSelect(string) ///
        HValue(real -1) BValue(real -1) ///
        POLYOrder(integer 1) BIASOrder(integer 2) ///
        KERNEL(string) VCEType(string) ///
        TUNing(real -999) SAMPLERule(string)]

    if "`kernel'" == "" local kernel "triangular"
    if "`vcetype'" == "" local vcetype "cr2 cluster_dist"
    if "`bwselect'" == "" local bwselect "mserd"
    if "`samplerule'" == "" local samplerule "adjacent_bc"
    if `tuning' == -999 local tuning .

    local fuzzy_option
    local estimator_sample ///
        "`usevar' & !missing(`outvar', ${rd_running}, cluster_dist)"

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
        `bandwidth_option' ///
        kernel(`kernel') ///
        `fuzzy_option' ///
        `covariate_option' ///
        vce(`vcetype') ///
        masspoints(adjust)
    local estimation_rc = _rc

    local h_left .
    local h_right .
    local b_left .
    local b_right .
    local n_eff_left .
    local n_eff_right .
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

        quietly summarize `outvar' if ///
            `estimator_sample' & ///
            ${rd_running} < 0 & ///
            ${rd_running} >= -`h_left'
        local control_mean = r(mean) * `scale'
        local control_sd = r(sd) * `scale'

        if `control_sd' > 0 & `control_sd' < . {
            local standardized_estimate = `estimate_bc' / `control_sd'
            local standardized_ci_low = `ci_low' / `control_sd'
            local standardized_ci_high = `ci_high' / `control_sd'
        }

        tempvar effective_cluster
        quietly egen byte `effective_cluster' = tag(cluster_dist) if ///
            `estimator_sample' & ///
            ${rd_running} >= -`h_left' & ///
            ${rd_running} <= `h_right'
        quietly count if `effective_cluster' == 1
        local clusters = r(N)

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
        ("rdrobust") ("`samplerule'") ("`vcetype'") ///
        (`polyorder') (`biasorder') ("`kernel'") ("`bwselect'") ///
        (`tuning') (`h_left') (`h_right') (`b_left') (`b_right') ///
        (`scale') (`n_input') (`n_eff_left') (`n_eff_right') ///
        (`clusters') (`estimate_cl') (`estimate_bc') ///
        (`standard_error') (`pvalue') (`ci_low') (`ci_high') ///
        (`control_mean') (`control_sd') ///
        (`standardized_estimate') ///
        (`standardized_ci_low') (`standardized_ci_high') ///
        (`first_stage_cl') (`first_stage_bc') ///
        (`first_stage_se') (`first_stage_f') ///
        (.) (.) (`estimation_rc')
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
    str32 multiplicity_family ///
    double paper_order ///
    str36 spec_id ///
    str24 estimand ///
    str16 estimator ///
    str28 sample_rule ///
    str28 vce ///
    byte p q ///
    str16 kernel ///
    str12 bwselect ///
    double tuning_value ///
    double h_left h_right b_left b_right scale ///
    int n_input n_eff_left n_eff_right clusters ///
    double estimate_cl estimate_bc standard_error pvalue ci_low ci_high ///
    double control_mean control_sd ///
    double standardized_estimate standardized_ci_low standardized_ci_high ///
    double first_stage_cl first_stage_bc first_stage_se first_stage_f ///
    double weak_robust_p wild_cluster_p ///
    int estimation_rc ///
    using "`rd_results_raw'", replace

_vrd_post_outcome_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D01") ///
    outlabel("Treatment through 2016: full B/C design universe") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-3) specid("common_h_design") ///
    estimand("first_stage") usevar(rd_bc_design) scale(1) ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc")

_vrd_post_outcome_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D02") ///
    outlabel("Treatment through 2016: complete primary sample") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-2) specid("common_h_primary") ///
    estimand("first_stage") usevar(rd_primary_sample) scale(1) ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc_linked")

_vrd_post_outcome_rd, ///
    posthandle(`rd_post') ///
    outvar(${rd_treatment_2017}) ///
    outcomeid("D03") ///
    outlabel("Treatment through 2016: MSE selector") ///
    family("design") tier("design") multiplicity("design") ///
    paperorder(-1) specid("mserd_design") ///
    estimand("first_stage") usevar(rd_bc_design) scale(1) ///
    bwselect("mserd") samplerule("selected_bc")

_vrd_post_outcome_rd, ///
    posthandle(`rd_post') ///
    outvar(census2017_cohort_covered) ///
    outcomeid("D04") ///
    outlabel("Included in the INEI-assisted Census cohort") ///
    family("linkage") tier("design") multiplicity("design") ///
    paperorder(-.8) specid("common_h_census_coverage") ///
    estimand("selection") usevar(rd_bc_design) scale(100) ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc")

_vrd_post_outcome_rd, ///
    posthandle(`rd_post') ///
    outvar(cpv2017_link_rate) ///
    outcomeid("D05") ///
    outlabel("Person linkage rate within covered CCPPs") ///
    family("linkage") tier("design") multiplicity("design") ///
    paperorder(-.7) specid("common_h_census_link_rate") ///
    estimand("selection") usevar(rd_census_sample) scale(100) ///
    hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
    samplerule("selected_bc_census_covered")

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

    local outcome_sample "rd_census_sample"
    local sample_rule "selected_bc_linked"
    if "`outcome_tier'" == "primary" {
        local outcome_sample "rd_primary_sample"
        local sample_rule "selected_bc_primary"
    }
    if inlist("`outcome_id'", "E01", "E02") {
        local outcome_sample "rd_bc_design"
        local sample_rule "selected_bc_gdp"
    }

    _vrd_post_outcome_rd, ///
        posthandle(`rd_post') outvar(`outcome_var') ///
        outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
        family("`outcome_family'") tier("`outcome_tier'") ///
        multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
        specid("common_h_reduced_form") estimand("reduced_form") ///
        usevar(`outcome_sample') scale(`outcome_scale') ///
        hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
        samplerule("`sample_rule'")

    _vrd_post_outcome_rd, ///
        posthandle(`rd_post') outvar(`outcome_var') ///
        outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
        family("`outcome_family'") tier("`outcome_tier'") ///
        multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
        specid("common_h_fuzzy") estimand("fuzzy_late") ///
        usevar(`outcome_sample') scale(`outcome_scale') fuzzy ///
        hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
        samplerule("`sample_rule'")

    _vrd_post_outcome_rd, ///
        posthandle(`rd_post') outvar(`outcome_var') ///
        outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
        family("`outcome_family'") tier("`outcome_tier'") ///
        multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
        specid("outcome_mserd_fuzzy") estimand("fuzzy_late") ///
        usevar(`outcome_sample') scale(`outcome_scale') fuzzy ///
        bwselect("mserd") samplerule("`sample_rule'")

    _vrd_post_outcome_rd, ///
        posthandle(`rd_post') outvar(`outcome_var') ///
        outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
        family("`outcome_family'") tier("`outcome_tier'") ///
        multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
        specid("outcome_cerrd_fuzzy") estimand("fuzzy_late") ///
        usevar(`outcome_sample') scale(`outcome_scale') fuzzy ///
        bwselect("cerrd") samplerule("`sample_rule'")

    if "`outcome_tier'" == "primary" {
        _vrd_post_outcome_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("common_h_covariates") estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') fuzzy ///
            covariates(${rd_primary_covariates}) ///
            hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
            samplerule("selected_bc_primary")

        _vrd_post_outcome_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("fixed_h_005") estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') fuzzy ///
            hvalue(${rd_small_h}) bvalue(${rd_small_b}) ///
            tuning(${rd_small_h}) samplerule("selected_bc_primary")

        _vrd_post_outcome_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("fixed_h_010") estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') fuzzy ///
            hvalue(${rd_large_h}) bvalue(${rd_large_b}) ///
            tuning(${rd_large_h}) samplerule("selected_bc_primary")

        foreach inference_id in nn hc3 cr1 cr3 {
            local inference_vce ""
            if "`inference_id'" == "nn"  local inference_vce "nn 3"
            if "`inference_id'" == "hc3" local inference_vce "hc3"
            if "`inference_id'" == "cr1" local inference_vce ///
                "cr1 cluster_dist"
            if "`inference_id'" == "cr3" local inference_vce ///
                "cr3 cluster_dist"

            _vrd_post_outcome_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
                specid("common_h_`inference_id'") ///
                estimand("fuzzy_late") ///
                usevar(rd_primary_sample) scale(`outcome_scale') fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                vcetype("`inference_vce'") ///
                samplerule("selected_bc_primary")
        }

        foreach kernel_id in uniform epanechnikov {
            _vrd_post_outcome_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
                specid("common_h_`kernel_id'") ///
                estimand("fuzzy_late") ///
                usevar(rd_primary_sample) scale(`outcome_scale') fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                kernel("`kernel_id'") ///
                samplerule("selected_bc_primary")
        }

        _vrd_post_outcome_rd, ///
            posthandle(`rd_post') outvar(`outcome_var') ///
            outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
            family("`outcome_family'") tier("`outcome_tier'") ///
            multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
            specid("outcome_mserd_p2") estimand("fuzzy_late") ///
            usevar(rd_primary_sample) scale(`outcome_scale') fuzzy ///
            polyorder(2) biasorder(3) bwselect("mserd") ///
            samplerule("selected_bc_primary")

        foreach donut_id in 005 025 {
            local donut_sample "rd_primary_donut_`donut_id'"
            local donut_value = .00005
            if "`donut_id'" == "025" local donut_value = .00025

            _vrd_post_outcome_rd, ///
                posthandle(`rd_post') outvar(`outcome_var') ///
                outcomeid("`outcome_id'") outlabel("`outcome_label'") ///
                family("`outcome_family'") tier("`outcome_tier'") ///
                multiplicity("`outcome_mult'") paperorder(`outcome_order') ///
                specid("donut_`donut_id'") estimand("fuzzy_late") ///
                usevar(`donut_sample') scale(`outcome_scale') fuzzy ///
                hvalue(${rd_common_h}) bvalue(${rd_common_b}) ///
                tuning(`donut_value') samplerule("selected_bc_primary")
        }
    }
}


*-----------------------------------*
**# 5. Parametric local-linear IV analogues
*-----------------------------------*

generate byte above_bc = ${rd_running} >= 0 if rd_primary_sample
generate double running_above = ///
    ${rd_running} * above_bc if rd_primary_sample
generate double triangular_weight = ///
    1 - abs(${rd_running}) / ${rd_common_h} ///
    if rd_primary_sample & abs(${rd_running}) <= ${rd_common_h}
replace triangular_weight = 1e-8 if triangular_weight == 0

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

        foreach parametric_spec in parametric_common_h parametric_covariates {
            local parametric_covariates
            if "`parametric_spec'" == "parametric_covariates" {
                local parametric_covariates "${rd_primary_covariates}"
            }

            capture quietly ivreg2 ///
                `outcome_var' ///
                ${rd_running} running_above `parametric_covariates' ///
                (${rd_treatment_2017} = above_bc) ///
                [aw = triangular_weight] ///
                if rd_primary_sample & ///
                    abs(${rd_running}) <= ${rd_common_h}, ///
                cluster(cluster_dist) first
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
            local clusters .
            local kp_f .
            local ar_p .
            local wild_p .

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
                local kp_f = e(rkf)
                local ar_p = e(arfp)

                quietly summarize `outcome_var' if ///
                    e(sample) & ${rd_running} < 0
                local control_mean = r(mean) * `outcome_scale'
                local control_sd = r(sd) * `outcome_scale'

                if `control_sd' > 0 & `control_sd' < . {
                    local standardized_estimate = ///
                        `estimate_bc' / `control_sd'
                    local standardized_ci_low = `ci_low' / `control_sd'
                    local standardized_ci_high = `ci_high' / `control_sd'
                }

                capture quietly boottest ${rd_treatment_2017}, ///
                    cluster(cluster_dist) reps(4999) ///
                    seed(271828) nograph
                if !_rc local wild_p = r(p)

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
                ("ivreg2") ("selected_bc_primary") ///
                ("cr1 cluster_dist") (1) (2) ///
                ("triangular") ("manual") (${rd_common_h}) ///
                (${rd_common_h}) (${rd_common_h}) ///
                (${rd_common_b}) (${rd_common_b}) ///
                (`outcome_scale') (`n_input') (.) (.) (`clusters') ///
                (`estimate_cl') (`estimate_bc') (`standard_error') ///
                (`pvalue') (`ci_low') (`ci_high') ///
                (`control_mean') (`control_sd') ///
                (`standardized_estimate') ///
                (`standardized_ci_low') (`standardized_ci_high') ///
                (.) (.) (.) (`kp_f') (`ar_p') (`wild_p') ///
                (`estimation_rc')
        }
    }
}

postclose `rd_post'


*-----------------------------------*
**# 6. Multiplicity and machine-readable results
*-----------------------------------*

use "`rd_results_raw'", clear

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
    "${rd_table_dir}/rd_2017_ccpp_results.csv", ///
    replace nolabel


*-----------------------------------*
**# 7. Analysis-contract audit output
*-----------------------------------*

tempname contract_file
local first_stage_status = cond(`first_stage_gate', "pass", "warning")
local kp_status = cond(`kp_f_main' >= ${rd_weak_f_gate}, ///
    "pass", "warning")
file open `contract_file' using ///
    "${rd_table_dir}/rd_2017_ccpp_analysis_contract.csv", ///
    write replace text

file write `contract_file' ///
    "metric,value,status,interpretation" _n
file write `contract_file' ///
    `""support","adjacent B/C","approved","Selected legacy geography and recorded RUV categories B or C""' _n
file write `contract_file' ///
    `""treatment","treat_16","approved","Cumulative collective reparations through 2016 for 2017 outcomes""' _n
file write `contract_file' ///
    `""common_h","${rd_common_h}","approved","Treatment-design bandwidth used by every main 2017 outcome""' _n
file write `contract_file' ///
    `""common_b","${rd_common_b}","approved","Common bias bandwidth for robust bias correction""' _n
file write `contract_file' ///
    `""selector_h","`selected_h'","validated","MSE bandwidth selected from treat_16 in the B/C design universe""' _n
file write `contract_file' ///
    `""selector_b","`selected_b'","validated","Bias bandwidth selected from treat_16 in the B/C design universe""' _n
file write `contract_file' ///
    `""first_stage_f","`main_first_stage_f'","`first_stage_status'","Squared robust first-stage z statistic in the linked primary sample""' _n
file write `contract_file' ///
    `""parametric_kp_f","`kp_f_main'","`kp_status'","Cluster-robust Kleibergen-Paap F in the common local-linear IV model""' _n
file write `contract_file' ///
    `""weak_f_gate","${rd_weak_f_gate}","approved","Conservative interpretation gate; bandwidth is never tuned to pass""' _n
file write `contract_file' ///
    `""primary_vce","district CR2","approved","One row per CCPP with municipal implementation and common shocks""' _n
file write `contract_file' ///
    `""primary_covariates","${rd_primary_covariates}","sensitivity","Fixed predetermined precision set; unadjusted model remains primary""' _n
file close `contract_file'


*-----------------------------------*
**# 8. LaTeX outcome registry
*-----------------------------------*

tempname registry_table
file open `registry_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_16_registry_2017_ccpp.tex", ///
    write replace text

file write `registry_table' "\begingroup" _n
file write `registry_table' "\small" _n
file write `registry_table' "\begin{longtable}{p{0.10\linewidth}p{0.18\linewidth}p{0.24\linewidth}p{0.33\linewidth}}" _n
file write `registry_table' "\caption{Registered 2017 CCPP outcomes and construction rules}" _n
file write `registry_table' "\label{tab:rd_outcome_registry} \\" _n
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
file write `registry_table' "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} The unit of analysis is an RUV centro poblado. Primary outcomes form one confirmatory family; secondary outcomes are adjusted within the declared family. Share and zero-to-one index effects are displayed in percentage points; log outcomes are in log points. Population and dwelling counts come from the official 2017 CCPP directory; person-based shares come from the INEI-assisted linked cohort. The wellbeing measure is a transparent equal-domain proxy rather than an official poverty index. Internet access is registered as a mechanism and cannot be used as an ordinary control. Source: INEI-assisted Census 2017 and Seminario--Palomino nightlights GDP estimates.\end{minipage}" _n
file write `registry_table' "\endgroup" _n
file close `registry_table'


*-----------------------------------*
**# 9. LaTeX first-stage and main tables
*-----------------------------------*

tempname first_stage_table
file open `first_stage_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_17_first_stage_2017_ccpp.tex", ///
    write replace text

file write `first_stage_table' "\begin{table}[!htbp]" _n
file write `first_stage_table' "\centering" _n
file write `first_stage_table' "\small" _n
file write `first_stage_table' "\caption{First-stage discontinuity for treatment through 2016}" _n
file write `first_stage_table' "\label{tab:rd_outcomes_first_stage}" _n
file write `first_stage_table' "\begin{tabular}{lrrrrrr}" _n
file write `first_stage_table' "\toprule" _n
file write `first_stage_table' "Analysis sample & Estimate & Robust SE & 95\% CI & Effective N & \(h\) & \(F_z\) \\" _n
file write `first_stage_table' "\midrule" _n

preserve
use "`rd_results_final'", clear
keep if inlist(outcome_id, "D01", "D02", "D03")
sort paper_order

forvalues result_row = 1/`=_N' {
    local row_label = outcome_label[`result_row']
    local row_estimate : display %6.3f estimate_bc[`result_row']
    local row_se : display %6.3f standard_error[`result_row']
    local row_ci_low : display %6.3f ci_low[`result_row']
    local row_ci_high : display %6.3f ci_high[`result_row']
    local row_n : display %9.0fc ///
        n_eff_left[`result_row'] + n_eff_right[`result_row']
    local row_h : display %6.4f h_left[`result_row']
    local row_f = ///
        (estimate_bc[`result_row'] / standard_error[`result_row'])^2
    local row_f : display %6.2f `row_f'

    foreach formatted_value in ///
        row_estimate row_se row_ci_low row_ci_high row_n row_h row_f {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `first_stage_table' ///
        "`row_label' & `row_estimate' & `row_se' & [`row_ci_low', `row_ci_high'] & `row_n' & `row_h' & `row_f' \\" _n
}
restore

file write `first_stage_table' "\bottomrule" _n
file write `first_stage_table' "\end{tabular}" _n
file write `first_stage_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The outcome is cumulative collective-reparation receipt through 2016. Estimates are robust bias-corrected local-linear triangular-kernel discontinuities at the official B--C cutoff in the selected geography, with mass-point adjustment and district CR2 inference. The common design window is \(h=0.0075\) and bias window is \(b=0.0135\); the final row instead reports the treatment-based MSE selector. \(F_z\) is the squared robust bias-corrected \(z\) statistic and is compared with the conservative interpretation gate of 20. The linked primary-sample statistic meets that gate; fuzzy LATE estimates are nevertheless reported with reduced forms and Anderson--Rubin diagnostics. Source: RUV, CMAN, and INEI-assisted Census 2017.}" _n
file write `first_stage_table' "\end{table}" _n
file close `first_stage_table'

tempname linkage_table
file open `linkage_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_31_linkage_2017_ccpp.tex", ///
    write replace text
file write `linkage_table' "\begin{table}[!htbp]" _n
file write `linkage_table' "\centering" _n
file write `linkage_table' "\small" _n
file write `linkage_table' "\caption{Census 2017 cohort coverage and linkage diagnostics}" _n
file write `linkage_table' "\label{tab:rd_outcomes_linkage_2017_ccpp}" _n
file write `linkage_table' "\begin{tabular}{p{0.36\linewidth}rrrrr}" _n
file write `linkage_table' "\toprule" _n
file write `linkage_table' "Linkage outcome & Control mean & Discontinuity & 95\% robust CI & Effective N & Clusters \\" _n
file write `linkage_table' "\midrule" _n

preserve
use "`rd_results_final'", clear
keep if inlist(outcome_id, "D04", "D05")
sort paper_order
assert _N == 2
forvalues result_row = 1/`=_N' {
    local row_label = outcome_label[`result_row']
    local row_mean : display %6.1f control_mean[`result_row']
    local row_estimate : display %6.1f estimate_bc[`result_row']
    local row_low : display %6.1f ci_low[`result_row']
    local row_high : display %6.1f ci_high[`result_row']
    local row_n : display %7.0fc ///
        n_eff_left[`result_row'] + n_eff_right[`result_row']
    local row_clusters : display %5.0f clusters[`result_row']
    foreach value in row_mean row_estimate row_low row_high row_n row_clusters {
        local `value' = strtrim("``value''")
    }
    file write `linkage_table' ///
        "`row_label' & `row_mean' & `row_estimate' & [`row_low', `row_high'] & `row_n' & `row_clusters' \\" _n
}
restore

file write `linkage_table' "\bottomrule" _n
file write `linkage_table' "\end{tabular}" _n
file write `linkage_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Estimates are local-linear discontinuities at the official B--C cutoff in the selected geography, using the common design window, triangular kernels, mass-point adjustment, and district CR2 inference. Outcomes are expressed in percentage points. Coverage records whether an RUV community appears in the INEI-assisted source cohort; the linkage-rate row is conditional on covered communities. These are selection diagnostics, not program outcomes. Sources: RUV, CMAN, and INEI-assisted Census 2017.}" _n
file write `linkage_table' "\end{table}" _n
file close `linkage_table'

tempname main_table
file open `main_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_18_main_2017_ccpp.tex", ///
    write replace text

file write `main_table' "\begin{table}[!htbp]" _n
file write `main_table' "\centering" _n
file write `main_table' "\scriptsize" _n
file write `main_table' "\caption{Collective reparations and registered 2017 CCPP outcomes}" _n
file write `main_table' "\label{tab:rd_outcomes_main_2017_ccpp}" _n
file write `main_table' "\begin{tabular}{p{0.27\linewidth}rrrrrr}" _n
file write `main_table' "\toprule" _n
file write `main_table' "Outcome & Control mean & Reduced form & Fuzzy LATE & 95\% robust CI & Holm \(p\) & Effective N \\" _n
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
    restore

    foreach formatted_value in ///
        row_mean row_rf row_late row_ci_low row_ci_high row_holm row_n {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `main_table' ///
        "`row_label' & `row_mean' & `row_rf' & `row_late' & [`row_ci_low', `row_ci_high'] & `row_holm' & `row_n' \\" _n
}

file write `main_table' "\midrule" _n
local formatted_first_stage : display %6.3f `main_first_stage_bc'
local formatted_first_stage_low : display %6.3f ///
    `main_first_stage_bc' - 1.96 * `main_first_stage_se'
local formatted_first_stage_high : display %6.3f ///
    `main_first_stage_bc' + 1.96 * `main_first_stage_se'
foreach formatted_value in ///
    formatted_first_stage formatted_first_stage_low ///
    formatted_first_stage_high {
    local `formatted_value' = strtrim("``formatted_value''")
}
file write `main_table' ///
    "Common first stage & & & `formatted_first_stage' & [`formatted_first_stage_low', `formatted_first_stage_high'] & & `main_first_stage_n' \\" _n
file write `main_table' "\bottomrule" _n
file write `main_table' "\end{tabular}" _n
file write `main_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Each row uses the same 388-community complete Census-linked B/C analysis sample before local-window restriction and the same \(h=0.0075\), \(b=0.0135\) design window. Reduced forms are assignment discontinuities; fuzzy LATEs divide the outcome and treatment discontinuities using one common bandwidth. Estimates are robust bias-corrected local-linear triangular-kernel results with mass-point adjustment and district CR2 inference. Share and zero-to-one index outcomes are in percentage points; count outcomes are logged. Holm values adjust across the eight primary outcomes. The local first stage passes the conservative \(F\geq20\) gate; reduced forms and weak-instrument-robust diagnostics remain co-primary interpretive safeguards. Population and dwelling counts are official CCPP-directory totals; linked person shares describe the assisted cohort. Source: RUV, CMAN, and INEI-assisted Census 2017.}" _n
file write `main_table' "\end{table}" _n
file close `main_table'


*-----------------------------------*
**# 10. LaTeX secondary and robustness tables
*-----------------------------------*

tempname secondary_table
file open `secondary_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_19_secondary_2017_ccpp.tex", ///
    write replace text

file write `secondary_table' "\begin{longtable}{p{0.17\linewidth}p{0.27\linewidth}rrrrr}" _n
file write `secondary_table' "\caption{Secondary and exploratory 2017 CCPP fuzzy-RD outcomes}" _n
file write `secondary_table' "\label{tab:rd_outcomes_secondary_2017_ccpp} \\" _n
file write `secondary_table' "\toprule" _n
file write `secondary_table' "Family & Outcome & Estimate & 95\% robust CI & Raw \(p\) & BH \(q\) & Effective N \\" _n
file write `secondary_table' "\midrule" _n
file write `secondary_table' "\endfirsthead" _n
file write `secondary_table' "\multicolumn{7}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `secondary_table' "\toprule" _n
file write `secondary_table' "Family & Outcome & Estimate & 95\% robust CI & Raw \(p\) & BH \(q\) & Effective N \\" _n
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

    foreach formatted_value in ///
        row_estimate row_ci_low row_ci_high row_p row_q row_n {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `secondary_table' ///
        "`row_family' & `row_label' & `row_estimate' & [`row_ci_low', `row_ci_high'] & `row_p' & `row_q' & `row_n' \\" _n
}
restore

file write `secondary_table' "\bottomrule" _n
file write `secondary_table' "\end{longtable}" _n
file write `secondary_table' "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} Each row is a separate fuzzy-RD estimate in the common \(h=0.0075\), \(b=0.0135\) window with local-linear triangular kernels, mass-point adjustment, and district CR2 inference. BH values control the false discovery rate within the declared outcome family. The internet row is an exploratory mechanism and is never an ordinary control. The GDP row uses the broader available B/C design sample and Seminario--Palomino estimates; other rows use Census-linked communities. The first-stage strength safeguard in Table~\ref{tab:rd_outcomes_first_stage} applies to every LATE. Source: RUV, CMAN, INEI-assisted Census 2017, and Seminario--Palomino.\end{minipage}" _n
file close `secondary_table'

tempname robustness_table
file open `robustness_table' using ///
    "${rd_table_dir}/tab_rd_outcomes_20_robustness_2017_ccpp.tex", ///
    write replace text

file write `robustness_table' "\begingroup" _n
file write `robustness_table' "\scriptsize" _n
file write `robustness_table' "\begin{longtable}{p{0.22\linewidth}p{0.19\linewidth}rrrrr}" _n
file write `robustness_table' "\caption{Primary-outcome specification and bandwidth sensitivity}" _n
file write `robustness_table' "\label{tab:rd_outcomes_robustness_2017_ccpp} \\" _n
file write `robustness_table' "\toprule" _n
file write `robustness_table' "Outcome & Specification & Estimate & 95\% CI & \(h\) & Robust/AR \(p\) & Effective N \\" _n
file write `robustness_table' "\midrule" _n
file write `robustness_table' "\endfirsthead" _n
file write `robustness_table' "\multicolumn{7}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `robustness_table' "\toprule" _n
file write `robustness_table' "Outcome & Specification & Estimate & 95\% CI & \(h\) & Robust/AR \(p\) & Effective N \\" _n
file write `robustness_table' "\midrule" _n
file write `robustness_table' "\endhead" _n

preserve
use "`rd_results_final'", clear
keep if tier == "primary" & inlist(spec_id, ///
    "common_h_fuzzy", "common_h_covariates", ///
    "outcome_mserd_fuzzy", "outcome_cerrd_fuzzy", ///
    "fixed_h_005", "fixed_h_010", ///
    "parametric_common_h")
sort paper_order spec_id

forvalues result_row = 1/`=_N' {
    local row_label = outcome_label[`result_row']
    local row_spec = spec_id[`result_row']
    local row_spec = subinstr("`row_spec'", "_", " ", .)
    local row_estimate : display %7.2f estimate_bc[`result_row']
    local row_ci_low : display %7.2f ci_low[`result_row']
    local row_ci_high : display %7.2f ci_high[`result_row']
    local row_h : display %6.4f h_left[`result_row']
    local row_p_value = pvalue[`result_row']
    if estimator[`result_row'] == "ivreg2" & weak_robust_p[`result_row'] < . {
        local row_p_value = weak_robust_p[`result_row']
    }
    local row_p : display %6.3f `row_p_value'
    local row_n = n_eff_left[`result_row'] + n_eff_right[`result_row']
    if estimator[`result_row'] == "ivreg2" local row_n = n_input[`result_row']
    local row_n : display %9.0fc `row_n'

    foreach formatted_value in ///
        row_estimate row_ci_low row_ci_high row_h row_p row_n {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `robustness_table' ///
        "`row_label' & `row_spec' & `row_estimate' & [`row_ci_low', `row_ci_high'] & `row_h' & `row_p' & `row_n' \\" _n
}
restore

file write `robustness_table' "\bottomrule" _n
file write `robustness_table' "\end{longtable}" _n
file write `robustness_table' "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} The common-window row is primary. Sensitivities use the same common window with the fixed covariate set, outcome-specific MSE and coverage-error selectors, narrower and wider prespecified windows, and a triangular-weighted local-linear 2SLS analogue. Continuity-based rows report robust bias-corrected CR2 inference. Parametric rows report district-clustered Anderson--Rubin \(p\)-values when available; the machine-readable CSV also contains Kleibergen--Paap and wild-cluster-bootstrap diagnostics, alternative kernels, polynomial order, donuts, and NN/HC3/CR1/CR3 inference. No specification is selected by significance. Source: RUV, CMAN, and INEI-assisted Census 2017.\end{minipage}" _n
file write `robustness_table' "\endgroup" _n
file close `robustness_table'


*-----------------------------------*
**# 11. First-stage and outcome RD plots
*-----------------------------------*

use "${rd_input_2017_ccpp}", clear
generate double ln_population_2017 = ///
    ln(population_2017) if population_2017 > 0
generate double ln_dwellings_occupied_2017 = ///
    ln(dwellings_occupied_2017) if dwellings_occupied_2017 > 0
generate byte rd_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")
generate byte rd_census_sample = ///
    rd_bc_design & census2017_cohort_covered == 1
egen byte primary_missing = rowmiss(`primary_outcomes') ///
    if rd_census_sample
generate byte rd_primary_sample = ///
    rd_census_sample & primary_missing == 0
encode ubigeo_dist, generate(cluster_dist)

capture program drop _vrd_make_outcome_rdplot

program define _vrd_make_outcome_rdplot
    version 19
    syntax, ///
        OUTVAR(name) ///
        OUTLABel(string) ///
        YTITle(string) ///
        SCALE(real) ///
        SAMPLEVAR(name) ///
        GRAPHNAME(name) ///
        FIGURE(string) ///
        SOURCE(string) ///
        [FIRSTStage]

    tempvar graph_outcome graph_bin_tag
    generate double `graph_outcome' = `outvar' * `scale' ///
        if `samplevar'

    quietly rdrobust ///
        `graph_outcome' ${rd_running} if `samplevar', ///
        c(0) p(1) q(2) ///
        h(${rd_common_h} ${rd_common_h}) ///
        b(${rd_common_b} ${rd_common_b}) ///
        kernel(triangular) ///
        vce(cr2 cluster_dist) ///
        masspoints(adjust)

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
    local graph_estimand_note ///
        "The subtitle reports the robust bias-corrected reduced form"

    if "`firststage'" != "" {
        local graph_title_prefix "First-stage discontinuity"
        local graph_effect_label "assignment jump"
        local panel_effect_label "FS"
        local graph_estimand_note ///
            "The subtitle reports the robust bias-corrected first stage"
    }

    capture drop rdplot_*
    quietly rdplot ///
        `graph_outcome' ${rd_running} if ///
            `samplevar' & ///
            abs(${rd_running}) <= ${rd_common_h}, ///
        c(0) p(1) ///
        h(${rd_common_h} ${rd_common_h}) ///
        kernel(triangular) ///
        binselect(qsmv) ///
        masspoints(adjust) ///
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
            `samplevar' & !missing(`graph_outcome') & ///
            ${rd_running} < 0 & ///
            ${rd_running} >= -${rd_common_h}, ///
            sort lcolor(navy) lwidth(medthick) lpattern(solid)) ///
        (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            lcolor(maroon%48) lwidth(vthin)) ///
        (scatter rdplot_mean_y rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            mcolor(maroon) msymbol(D) msize(small)) ///
        (line rdplot_hat_y ${rd_running} if ///
            `samplevar' & !missing(`graph_outcome') & ///
            ${rd_running} >= 0 & ///
            ${rd_running} <= ${rd_common_h}, ///
            sort lcolor(maroon) lwidth(medthick) lpattern(solid)), ///
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
            "Notes: Unit is an RUV centro poblado in the selected B/C geography; Census panels use linked communities." ///
            "Points are quantile-spaced variance-mimicking binned means; bars are 95% bin confidence intervals." ///
            "Lines are triangular-kernel local-linear fits inside the common design bandwidth h = 0.0075." ///
            "`graph_estimand_note' with district CR2 and mass-point adjustment (effective N = `graph_n')." ///
            "This is an assignment plot; fuzzy LATE and weak-first-stage diagnostics are reported in the tables. Sources: RUV and `source'.", ///
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
            `samplevar' & !missing(`graph_outcome') & ///
            ${rd_running} < 0 & ///
            ${rd_running} >= -${rd_common_h}, ///
            sort lcolor(navy) lwidth(medium) lpattern(solid)) ///
        (rcap rdplot_ci_l rdplot_ci_r rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            lcolor(maroon%48) lwidth(vthin)) ///
        (scatter rdplot_mean_y rdplot_mean_x ///
            if `graph_bin_tag' & rdplot_mean_x >= 0, ///
            mcolor(maroon) msymbol(D) msize(vsmall)) ///
        (line rdplot_hat_y ${rd_running} if ///
            `samplevar' & !missing(`graph_outcome') & ///
            ${rd_running} >= 0 & ///
            ${rd_running} <= ${rd_common_h}, ///
            sort lcolor(maroon) lwidth(medium) lpattern(solid)), ///
        xline(0, lcolor(black) lpattern(dash) lwidth(vthin)) ///
        xscale(range(-.008 .008)) ///
        xlabel(-.0075 "-.0075" 0 "0" .0075 ".0075", ///
            grid glcolor(gs14) ///
            glwidth(vthin) labsize(tiny)) ///
        ylabel(, angle(0) grid glcolor(gs14) ///
            glwidth(vthin) labsize(tiny)) ///
        xtitle("Centered victimization score", size(vsmall)) ///
        ytitle("`ytitle'", size(vsmall)) ///
        title("`outlabel'", size(vsmall) color(black)) ///
        subtitle("`panel_effect_label' = `graph_estimate_text'; `graph_p_phrase'", ///
            size(vsmall) color(gs5)) ///
        legend(off) ///
        graphregion(color(white) margin(tiny)) ///
        plotregion(color(white) margin(tiny)) ///
        name(`graphname', replace) nodraw

    drop rdplot_*
end

_vrd_make_outcome_rdplot, ///
    outvar(${rd_treatment_2017}) ///
    outlabel("Treatment through 2016") ///
    ytitle("Treatment probability") ///
    scale(1) samplevar(rd_primary_sample) ///
    graphname(rd_panel_1) ///
    figure("${rd_figure_dir}/fig_rd_outcomes_41_first_stage_2016_ccpp.png") ///
    source("CMAN treatment records") firststage

forvalues outcome_index = 1/8 {
    local outcome_var "`o_var_`outcome_index''"
    local outcome_label "`o_label_`outcome_index''"
    local outcome_scale = `o_scale_`outcome_index''
    local outcome_stub "`o_stub_`outcome_index''"
    local panel_number = `outcome_index' + 1
    local figure_number = `outcome_index' + 44
    local figure_number : display %02.0f `figure_number'
    local figure_number = strtrim("`figure_number'")
    local outcome_ytitle "Outcome level"
    if `outcome_scale' == 100 local outcome_ytitle "Percent or index points"
    if inlist("`outcome_var'", ///
        "ln_population_2017", ///
        "ln_dwellings_occupied_2017", ///
        "ln_gdp_ccpp_2017", ///
        "ihs_gdp_ccpp_2017") {
        local outcome_ytitle "Log roster count"
    }

    _vrd_make_outcome_rdplot, ///
        outvar(`outcome_var') ///
        outlabel("`outcome_label'") ///
        ytitle("`outcome_ytitle'") ///
        scale(`outcome_scale') samplevar(rd_primary_sample) ///
        graphname(rd_panel_`panel_number') ///
        figure("${rd_figure_dir}/fig_rd_outcomes_`figure_number'_`outcome_stub'.png") ///
        source("INEI-assisted Census 2017")
}

graph combine ///
    rd_panel_1 rd_panel_2 rd_panel_3 ///
    rd_panel_4 rd_panel_5 rd_panel_6 ///
    rd_panel_7 rd_panel_8 rd_panel_9, ///
    rows(3) imargin(tiny) ///
    title("Treatment assignment and primary 2017 CCPP outcomes", ///
        size(medsmall) color(black)) ///
    subtitle("Common B-C design window; reduced-form local-linear fits", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit is a Census-linked RUV centro poblado in the selected B/C geography." ///
        "All panels use h = 0.0075, triangular kernels, and the same complete primary sample." ///
        "Panel subtitles report robust bias-corrected reduced forms with district CR2 and mass-point adjustment." ///
        "Binned points include 95% confidence intervals. Fuzzy LATE and weak-instrument diagnostics appear in the tables." ///
        "Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(12) ysize(11) graphregion(color(white))

graph export ///
    "${rd_figure_dir}/fig_rd_outcomes_42_primary_panels_2017_ccpp.png", ///
    width(3600) replace


*-----------------------------------*
**# 12. Fuzzy-LATE and bandwidth summaries
*-----------------------------------*

use "`rd_results_final'", clear
keep if tier == "primary" & ///
    spec_id == "common_h_fuzzy" & estimation_rc == 0
sort paper_order
generate byte plot_order = 9 - paper_order

capture label drop rd_primary_axis
forvalues result_row = 1/`=_N' {
    local axis_value = plot_order[`result_row']
    local axis_label = outcome_label[`result_row']
    label define rd_primary_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_primary_axis

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
    title("Standardized effects on primary 2017 CCPP outcomes", ///
        size(medium) color(black)) ///
    subtitle("Common h = 0.0075; robust 95% confidence intervals", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Unit is a Census-linked RUV centro poblado in the selected B/C geography." ///
        "Each effect is scaled by the below-cutoff outcome SD and estimated with local-linear triangular-kernel fuzzy RD." ///
        "Intervals use robust bias correction, mass-point adjustment, and district CR2 inference." ///
        "The local first stage passes the conservative F >= 20 gate." ///
        "LATE estimates are diagnostic and must be read with reduced forms and Anderson-Rubin inference." ///
        "Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${rd_figure_dir}/fig_rd_outcomes_43_late_forest_2017_ccpp.png", ///
    width(3000) replace

use "`rd_results_final'", clear
keep if tier == "primary" & ///
    inlist(spec_id, "fixed_h_005", "common_h_fuzzy", "fixed_h_010") & ///
    estimation_rc == 0
generate double bandwidth = h_left
sort outcome_id bandwidth
generate byte plot_order = 9 - paper_order
generate double plot_position = plot_order
replace plot_position = plot_order - .18 if spec_id == "fixed_h_005"
replace plot_position = plot_order + .18 if spec_id == "fixed_h_010"

capture label drop rd_bandwidth_axis
sort paper_order bandwidth
forvalues result_row = 1/`=_N' {
    local axis_value = plot_order[`result_row']
    local axis_label = outcome_label[`result_row']
    capture label define rd_bandwidth_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_bandwidth_axis
label values plot_position rd_bandwidth_axis

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
    title("Primary-outcome sensitivity to the common RD window", ///
        size(medium) color(black)) ///
    subtitle("Prespecified fixed bandwidths with robust 95% intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "h = 0.0050" 4 "h = 0.0075 (common)" ///
        6 "h = 0.0100") rows(1) position(6) size(small) ///
        region(lcolor(none))) ///
    note( ///
        "Notes: Unit is a Census-linked RUV centro poblado in the selected B/C geography." ///
        "All models are local linear with triangular kernels, mass-point adjustment, and district CR2 inference." ///
        "The center point is the common design bandwidth; flanking points are prespecified sensitivity windows." ///
        "No bandwidth is selected by the magnitude or significance of an outcome estimate. Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "${rd_figure_dir}/fig_rd_outcomes_44_bandwidth_sensitivity_2017_ccpp.png", ///
    width(3600) replace


*-----------------------------------*
**# 13. Output manifest and closeout
*-----------------------------------*

local output_paths ///
    output/tables/rd_outcomes/rd_2017_ccpp_results.csv ///
    output/tables/rd_outcomes/rd_2017_ccpp_analysis_contract.csv ///
    output/tables/rd_outcomes/tab_rd_outcomes_16_registry_2017_ccpp.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_17_first_stage_2017_ccpp.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_18_main_2017_ccpp.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_19_secondary_2017_ccpp.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_20_robustness_2017_ccpp.tex ///
    output/tables/rd_outcomes/tab_rd_outcomes_31_linkage_2017_ccpp.tex ///
    output/figures/rd_outcomes/fig_rd_outcomes_41_first_stage_2016_ccpp.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_42_primary_panels_2017_ccpp.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_43_late_forest_2017_ccpp.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_44_bandwidth_sensitivity_2017_ccpp.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_45_log_population.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_46_log_occupied_dwellings.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_47_moved_ccpp.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_48_age_15_29.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_49_secondary_education.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_50_employment.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_51_health_insurance.png ///
    output/figures/rd_outcomes/fig_rd_outcomes_52_wellbeing_core.png

tempname manifest_file
file open `manifest_file' using "${rd_2017_ccpp_manifest}", ///
    write replace text
file write `manifest_file' ///
    "path,artifact_type,input_data,input_datasignature,generator,run_id,checksum,review_status" _n

foreach output_path of local output_paths {
    local absolute_output "${project_root}/`output_path'"
    capture confirm file "`absolute_output'"
    if _rc {
        display as error "Expected 2017 CCPP output was not created:"
        display as error "  `absolute_output'"
        file close `manifest_file'
        log close victimasrd_rd_2017_ccpp
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
        `""`output_path'","`artifact_type'","14_community_registry_census_2017.dta","`input_datasignature'","code/stata/pipeline/04d_census2017_ccpp.do","${rd_run_id}","`output_checksum'","generated_unreviewed""' _n
}

file close `manifest_file'

capture program drop _vrd_post_outcome_rd
capture program drop _vrd_make_outcome_rdplot

display as result "Census 2017 CCPP outcome module completed."
display as text "Registered outcomes: `outcome_count'"
display as text "Primary linked B/C communities: 388"
display as text "Common fixed-window effective N: `main_first_stage_n'"
display as text "Robust first-stage F_z: `main_first_stage_f'"
display as text "Parametric Kleibergen-Paap F: `kp_f_main'"
display as text "Review status: generated_unreviewed"

log close victimasrd_rd_2017_ccpp
exit 0
