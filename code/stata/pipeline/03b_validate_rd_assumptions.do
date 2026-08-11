/*------------------------------------------------------------------------------*
| Title:            Selected-sample RD validity diagnostics                     |
| Project:          Victimas RD                                                  |
| Authors:          Jorge Zavala, Matthew Bird, Ana Maria Dumez                  |
|                                                                                |
| Description:      Evaluate support, sorting, first stages, predetermined       |
|                   covariates, linkage, and specification sensitivity at B--C.  |
|                                                                                |
| Date created:     10 August 2026                                               |
| Stata version:    19                                                           |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

    0. Governance, paths, and output contract
    1. Input validation and score branches
    2. Support and density diagnostics
    3. First-stage and specification grids
    4. Covariate and linkage continuity
    5. Local-randomization feasibility
    6. Academic tables and figures
    7. Output manifest and closeout

*-------------------------------------------------------------------------------*/


*-----------------------------------*
**# 0. Governance, paths, and output contract
*-----------------------------------*

version 19
set more off
set varabbrev off

/*
This routine audits the research-team-selected geography. It cannot search for
or alter sample_main_rd and does not estimate substantive outcomes. Score-tie,
support, treatment-timing, estimand, and primary-inference choices remain open;
the module exposes those branches instead of silently selecting one.
*/

local required_globals ///
    project_root ///
    analysis_data_root ///
    figures_root ///
    tables_root ///
    metadata_root ///
    logs_root

foreach global_name of local required_globals {
    if `"${`global_name'}"' == "" {
        display as error "Required global is not defined: `global_name'"
        exit 198
    }
}

local input_file ///
    "${analysis_data_root}/08_community_registry_elections.dta"
local protocol_file ///
    "${project_root}/docs/RD_VALIDATION_PROTOCOL.md"
local table_dir "${tables_root}/rd_validation"
local figure_dir "${figures_root}/rd_validation"
local manifest "${metadata_root}/rd-validation-output-manifest.csv"

foreach input_path in "`input_file'" "`protocol_file'" {
    capture confirm file "`input_path'"
    if _rc {
        display as error "Required RD-validation input was not found:"
        display as error "  `input_path'"
        exit 601
    }
}

foreach output_directory in "`table_dir'" "`figure_dir'" {
    capture mkdir "`output_directory'"
    if !direxists("`output_directory'") {
        display as error "Could not create RD-validation output directory:"
        display as error "  `output_directory'"
        exit 603
    }
}

local output_paths ///
    output/tables/rd_validation/rd_validation_support.csv ///
    output/tables/rd_validation/rd_validation_density.csv ///
    output/tables/rd_validation/rd_validation_first_stage.csv ///
    output/tables/rd_validation/rd_validation_covariates.csv ///
    output/tables/rd_validation/rd_validation_local_randomization.csv ///
    output/tables/rd_validation/tab_rd_validation_01_support_density.tex ///
    output/tables/rd_validation/tab_rd_validation_02_first_stage.tex ///
    output/tables/rd_validation/tab_rd_validation_03_covariates.tex ///
    output/tables/rd_validation/tab_rd_validation_04_sensitivity.tex ///
    output/tables/rd_validation/tab_rd_validation_05_local_randomization.tex ///
    output/figures/rd_validation/fig_rd_validation_01_score_mass_points.png ///
    output/figures/rd_validation/fig_rd_validation_02_first_stage_horizons.png ///
    output/figures/rd_validation/fig_rd_validation_03_treatment_2012.png ///
    output/figures/rd_validation/fig_rd_validation_04_treatment_2016.png ///
    output/figures/rd_validation/fig_rd_validation_05_covariate_continuity.png ///
    output/figures/rd_validation/fig_rd_validation_06_bandwidth_donut.png ///
    output/figures/rd_validation/fig_rd_validation_07_placebo_cutoffs.png

foreach output_path of local output_paths {
    capture erase "${project_root}/`output_path'"
}
capture erase "`manifest'"

local run_date = subinstr("`c(current_date)'", " ", "", .)
local run_time = subinstr("`c(current_time)'", ":", "", .)
local run_id = lower("`run_date'_`run_time'")

capture log close victimasrd_rd_validation
log using "${logs_root}/rd_validation_`run_id'.smcl", ///
    name(victimasrd_rd_validation) replace

display as result "Starting selected-sample RD validity diagnostics."
display as text "Protocol: `protocol_file'"


*-----------------------------------*
**# 1. Input validation and score branches
*-----------------------------------*

use "`input_file'", clear

isid ruv_id
assert _N == 5712
assert inlist(sample_main_rd, 0, 1)
quietly count if sample_main_rd
assert r(N) == 1162
assert inlist(victimization_level_source, "A", "B", "C", "D", "E")
assert !missing(victimization_index, running_bc, ubigeo_dist)

foreach treatment_var of varlist treat_07-treat_23 {
    assert inlist(`treatment_var', 0, 1)
}

quietly datasignature
local input_datasignature "`r(datasignature)'"

capture drop cluster_dist
encode ubigeo_dist, generate(cluster_dist)
label variable cluster_dist "District cluster identifier"

generate byte rd_bc_recorded = ///
    sample_main_rd & inlist(victimization_level_source, "B", "C")
generate byte rd_bc_sign_conflict = ///
    rd_bc_recorded & ///
    ((running_bc >= 0) != (victimization_level_source == "B"))
generate byte rd_bc_rounding_band = ///
    rd_bc_recorded & abs(running_bc) <= 0.00005
generate byte rd_bc_drop_conflict = ///
    rd_bc_recorded & !rd_bc_sign_conflict
generate byte rd_bc_drop_band = ///
    rd_bc_recorded & !rd_bc_rounding_band
generate byte rd_full_drop_band = ///
    sample_main_rd & abs(running_bc) > 0.00005

quietly count if rd_bc_recorded
assert r(N) == 549
quietly count if rd_bc_sign_conflict
assert inrange(r(N), 0, 1)
quietly count if rd_bc_rounding_band
assert inrange(r(N), 0, 10)

generate byte elect2002_available = ///
    !missing(elect_turnout_2002, elect_margin_2002, elect_nep_2002)
generate byte elect2006_available = ///
    !missing(elect_turnout_2006, elect_margin_2006, elect_nep_2006)


*-----------------------------------*
**# 2. Support and density diagnostics
*-----------------------------------*

tempfile support_results density_results
tempname support_post density_post

postfile `support_post' ///
    str28 sample_rule ///
    int n_total n_left n_right ///
    int unique_left unique_right ///
    int clusters_left clusters_right ///
    int sign_conflicts rounding_band_n ///
    double nearest_left nearest_right ///
    using "`support_results'", replace

postfile `density_post' ///
    str28 sample_rule ///
    int n_total n_eff_left n_eff_right ///
    double statistic pvalue h_left h_right ///
    int estimation_rc ///
    using "`density_results'", replace

local sample_vars ///
    rd_bc_recorded rd_bc_drop_conflict rd_bc_drop_band rd_full_drop_band
local sample_rules ///
    score_as_recorded drop_sign_conflicts drop_rounding_band full_support_drop_band

forvalues sample_index = 1/4 {
    local sample_var : word `sample_index' of `sample_vars'
    local sample_rule : word `sample_index' of `sample_rules'

    tempvar tag_left tag_right tag_cluster_left tag_cluster_right

    quietly count if `sample_var'
    local n_total = r(N)
    quietly count if `sample_var' & running_bc < 0
    local n_left = r(N)
    quietly count if `sample_var' & running_bc >= 0
    local n_right = r(N)

    quietly egen byte `tag_left' = ///
        tag(running_bc) if `sample_var' & running_bc < 0
    quietly egen byte `tag_right' = ///
        tag(running_bc) if `sample_var' & running_bc >= 0
    quietly count if `tag_left' == 1
    local unique_left = r(N)
    quietly count if `tag_right' == 1
    local unique_right = r(N)

    quietly egen byte `tag_cluster_left' = ///
        tag(cluster_dist) if `sample_var' & running_bc < 0
    quietly egen byte `tag_cluster_right' = ///
        tag(cluster_dist) if `sample_var' & running_bc >= 0
    quietly count if `tag_cluster_left' == 1
    local clusters_left = r(N)
    quietly count if `tag_cluster_right' == 1
    local clusters_right = r(N)

    quietly count if `sample_var' & rd_bc_sign_conflict
    local sign_conflicts = r(N)
    quietly count if `sample_var' & rd_bc_rounding_band
    local rounding_band_n = r(N)
    quietly summarize running_bc if `sample_var' & running_bc < 0, meanonly
    local nearest_left = r(max)
    quietly summarize running_bc if `sample_var' & running_bc >= 0, meanonly
    local nearest_right = r(min)

    post `support_post' ///
        ("`sample_rule'") ///
        (`n_total') (`n_left') (`n_right') ///
        (`unique_left') (`unique_right') ///
        (`clusters_left') (`clusters_right') ///
        (`sign_conflicts') (`rounding_band_n') ///
        (`nearest_left') (`nearest_right')

    capture quietly rddensity running_bc if `sample_var', ///
        c(0) p(2) q(3) ///
        fitselect(unrestricted) ///
        kernel(triangular) ///
        bwselect(comb) ///
        vce(jackknife)
    local density_rc = _rc

    local density_t .
    local density_p .
    local density_h_left .
    local density_h_right .
    local density_n_left .
    local density_n_right .

    if !`density_rc' {
        local density_t = e(T_q)
        local density_p = e(pv_q)
        local density_h_left = e(h_l)
        local density_h_right = e(h_r)
        local density_n_left = e(N_h_l)
        local density_n_right = e(N_h_r)
    }

    post `density_post' ///
        ("`sample_rule'") ///
        (`n_total') (`density_n_left') (`density_n_right') ///
        (`density_t') (`density_p') ///
        (`density_h_left') (`density_h_right') ///
        (`density_rc')

    drop `tag_left' `tag_right' `tag_cluster_left' `tag_cluster_right'
}

postclose `support_post'
postclose `density_post'


*-----------------------------------*
**# 3. First-stage and specification grids
*-----------------------------------*

capture program drop _vrd_post_rd

program define _vrd_post_rd
    version 19
    syntax, ///
        POSTHandle(name) ///
        RESULTKind(string) ///
        FAMily(string) ///
        SPECid(string) ///
        OUTVAR(name) ///
        OUTLABel(string) ///
        USEVAR(name) ///
        SAMPLERule(string) ///
        [CUToff(real 0) POLYOrder(integer 1) BIASOrder(integer 2) ///
        BWSelect(string) KERNEL(string) VCEtype(string) ///
        HValue(real -1) TUNing(real -999)]

    if "`bwselect'" == "" local bwselect "mserd"
    if "`kernel'" == "" local kernel "triangular"
    if "`vcetype'" == "" local vcetype "cr2 cluster_dist"
    if `tuning' == -999 local tuning .

    quietly count if ///
        `usevar' & !missing(`outvar', running_bc, cluster_dist)
    local n_input = r(N)

    local h_option
    local bw_option "bwselect(`bwselect')"
    if `hvalue' >= 0 {
        local h_option "h(`hvalue' `hvalue')"
        local bw_option
    }

    capture quietly rdrobust ///
        `outvar' running_bc if `usevar', ///
        c(`cutoff') p(`polyorder') q(`biasorder') ///
        `bw_option' `h_option' ///
        kernel(`kernel') ///
        vce(`vcetype') ///
        masspoints(adjust)
    local estimation_rc = _rc

    local estimate .
    local estimate_conventional .
    local standard_error .
    local pvalue .
    local ci_low .
    local ci_high .
    local h_left .
    local h_right .
    local n_eff_left .
    local n_eff_right .
    local clusters .

    if !`estimation_rc' {
        local estimate = e(tau_bc)
        local estimate_conventional = e(tau_cl)
        local standard_error = e(se_tau_rb)
        local pvalue = e(pv_rb)
        local ci_low = e(ci_l_rb)
        local ci_high = e(ci_r_rb)
        local h_left = e(h_l)
        local h_right = e(h_r)
        local n_eff_left = e(N_h_l)
        local n_eff_right = e(N_h_r)
        tempvar effective_cluster
        quietly egen byte `effective_cluster' = tag(cluster_dist) if ///
            `usevar' & !missing(`outvar', running_bc, cluster_dist) & ///
            running_bc >= `cutoff' - `h_left' & ///
            running_bc <= `cutoff' + `h_right'
        quietly count if `effective_cluster' == 1
        local clusters = r(N)
        drop `effective_cluster'
    }

    post `posthandle' ///
        ("`resultkind'") ("`family'") ("`specid'") ///
        ("`outvar'") ("`outlabel'") ///
        ("`samplerule'") (`cutoff') (`polyorder') (`biasorder') ///
        ("`bwselect'") ("`kernel'") ("`vcetype'") ///
        (`tuning') (`n_input') ///
        (`estimate') (`estimate_conventional') ///
        (`standard_error') (`pvalue') ///
        (`ci_low') (`ci_high') (`h_left') (`h_right') ///
        (`n_eff_left') (`n_eff_right') (`clusters') ///
        (`estimation_rc')
end

tempfile rd_results
tempname rd_post

postfile `rd_post' ///
    str20 result_kind ///
    str24 family ///
    str40 spec_id ///
    str32 outcome_var ///
    str96 outcome_label ///
    str28 sample_rule ///
    double cutoff ///
    byte p q ///
    str12 bwselect ///
    str16 kernel ///
    str24 vce ///
    double tuning_value ///
    int n_input ///
    double estimate estimate_conventional ///
    double standard_error pvalue ci_low ci_high ///
    double h_left h_right ///
    int n_eff_left n_eff_right clusters estimation_rc ///
    using "`rd_results'", replace

/* Annual first stages under the conservative display branch. */
forvalues year_suffix = 7/23 {
    local year_text : display %02.0f `year_suffix'
    local year_text = strtrim("`year_text'")
    local treatment_var "treat_`year_text'"
    local treatment_year = 2000 + `year_suffix'

    _vrd_post_rd, ///
        posthandle(`rd_post') ///
        resultkind("first_stage") ///
        family("horizon") ///
        specid("horizon_cr2") ///
        outvar(`treatment_var') ///
        outlabel("Treated by `treatment_year'") ///
        usevar(rd_bc_drop_band) ///
        samplerule("drop_rounding_band") ///
        vcetype("cr2 cluster_dist")
}

/* Explicit score/support branches for the outcome-linked horizons. */
forvalues sample_index = 1/4 {
    local sample_var : word `sample_index' of `sample_vars'
    local sample_rule : word `sample_index' of `sample_rules'

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        _vrd_post_rd, ///
            posthandle(`rd_post') ///
            resultkind("first_stage") ///
            family("score_support") ///
            specid("`sample_rule'") ///
            outvar(`treatment_var') ///
            outlabel("Treated by `treatment_year'") ///
            usevar(`sample_var') ///
            samplerule("`sample_rule'") ///
            vcetype("cr2 cluster_dist")
    }
}

/* Variance estimators are retained as co-equal sensitivity branches. */
local vce_ids "nn hc3 cr1 cr2 cr3"
local vce_1 "nn 3"
local vce_2 "hc3"
local vce_3 "cr1 cluster_dist"
local vce_4 "cr2 cluster_dist"
local vce_5 "cr3 cluster_dist"

forvalues vce_index = 1/5 {
    local vce_id : word `vce_index' of `vce_ids'
    local vce_type "`vce_`vce_index''"

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        _vrd_post_rd, ///
            posthandle(`rd_post') ///
            resultkind("first_stage") ///
            family("inference") ///
            specid("vce_`vce_id'") ///
            outvar(`treatment_var') ///
            outlabel("Treated by `treatment_year'") ///
            usevar(rd_bc_drop_band) ///
            samplerule("drop_rounding_band") ///
            vcetype("`vce_type'")
    }
}

/* Bandwidth selector, kernel, and polynomial-order sensitivity. */
local spec_ids ///
    mserd_tri_p1 cerrd_tri_p1 mserd_uniform_p1 ///
    mserd_epan_p1 mserd_tri_p2
local spec_bw "mserd cerrd mserd mserd mserd"
local spec_kernel "triangular triangular uniform epanechnikov triangular"
local spec_p "1 1 1 1 2"
local spec_q "2 2 2 2 3"

forvalues spec_index = 1/5 {
    local spec_id : word `spec_index' of `spec_ids'
    local bw : word `spec_index' of `spec_bw'
    local kernel : word `spec_index' of `spec_kernel'
    local p : word `spec_index' of `spec_p'
    local q : word `spec_index' of `spec_q'

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        _vrd_post_rd, ///
            posthandle(`rd_post') ///
            resultkind("first_stage") ///
            family("estimator") ///
            specid("`spec_id'") ///
            outvar(`treatment_var') ///
            outlabel("Treated by `treatment_year'") ///
            usevar(rd_bc_drop_band) ///
            samplerule("drop_rounding_band") ///
            polyorder(`p') biasorder(`q') ///
            bwselect("`bw'") ///
            kernel("`kernel'") ///
            vcetype("cr2 cluster_dist")
    }
}

/* Prespecified fixed bandwidths. */
foreach fixed_h in .005 .010 .015 .020 .030 .050 {
    local h_tag = subinstr("`fixed_h'", ".", "p", .)

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        _vrd_post_rd, ///
            posthandle(`rd_post') ///
            resultkind("first_stage") ///
            family("fixed_bandwidth") ///
            specid("h_`h_tag'") ///
            outvar(`treatment_var') ///
            outlabel("Treated by `treatment_year'") ///
            usevar(rd_bc_drop_band) ///
            samplerule("drop_rounding_band") ///
            hvalue(`fixed_h') ///
            tuning(`fixed_h') ///
            vcetype("cr2 cluster_dist")
    }
}

/* Donut exclusions address cutoff rounding and leverage of nearest mass points. */
foreach donut in 0 .00005 .00025 .00050 .00100 {
    local donut_tag = subinstr("`donut'", ".", "p", .)
    tempvar donut_sample
    generate byte `donut_sample' = ///
        rd_bc_recorded & abs(running_bc) > `donut'

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        _vrd_post_rd, ///
            posthandle(`rd_post') ///
            resultkind("first_stage") ///
            family("donut") ///
            specid("donut_`donut_tag'") ///
            outvar(`treatment_var') ///
            outlabel("Treated by `treatment_year'") ///
            usevar(`donut_sample') ///
            samplerule("donut_`donut_tag'") ///
            tuning(`donut') ///
            vcetype("cr2 cluster_dist")
    }

    drop `donut_sample'
}

/* Placebo thresholds stay on one side of the true B--C boundary. */
foreach placebo in -.020 -.015 -.010 .010 .015 .020 {
    local placebo_tag = subinstr("`placebo'", "-", "m", .)
    local placebo_tag = subinstr("`placebo_tag'", ".", "p", .)
    tempvar placebo_sample

    if `placebo' < 0 {
        generate byte `placebo_sample' = ///
            rd_bc_drop_band & running_bc < 0
    }
    else {
        generate byte `placebo_sample' = ///
            rd_bc_drop_band & running_bc > 0
    }

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        _vrd_post_rd, ///
            posthandle(`rd_post') ///
            resultkind("first_stage") ///
            family("placebo_cutoff") ///
            specid("placebo_`placebo_tag'") ///
            outvar(`treatment_var') ///
            outlabel("Treated by `treatment_year'") ///
            usevar(`placebo_sample') ///
            samplerule("same_side_placebo") ///
            cutoff(`placebo') ///
            tuning(`placebo') ///
            vcetype("cr2 cluster_dist")
    }

    drop `placebo_sample'
}

/* Transparent parametric local-linear comparisons in fixed windows. */
generate byte above_bc = running_bc >= 0 if !missing(running_bc)

foreach fixed_h in .010 .020 .030 {
    local h_tag = subinstr("`fixed_h'", ".", "p", .)

    foreach year_suffix in 12 16 {
        local treatment_var "treat_`year_suffix'"
        local treatment_year = 2000 + `year_suffix'

        capture quietly regress ///
            `treatment_var' ///
            i.above_bc##c.running_bc ///
            if rd_bc_drop_band & abs(running_bc) <= `fixed_h', ///
            vce(cluster cluster_dist)
        local parametric_rc = _rc

        local estimate .
        local standard_error .
        local pvalue .
        local ci_low .
        local ci_high .
        local n_input .
        local clusters .

        if !`parametric_rc' {
            local n_input = e(N)
            local clusters = e(N_clust)
            capture quietly lincom 1.above_bc, level(95)
            local parametric_rc = _rc

            if !`parametric_rc' {
                local estimate = r(estimate)
                local standard_error = r(se)
                local pvalue = r(p)
                local ci_low = r(lb)
                local ci_high = r(ub)
            }
        }

        post `rd_post' ///
            ("first_stage") ("parametric") ("local_linear_h_`h_tag'") ///
            ("`treatment_var'") ("Treated by `treatment_year'") ///
            ("drop_rounding_band") (0) (1) (.) ///
            ("fixed") ("triangular") ("cr1 cluster_dist") ///
            (`fixed_h') (`n_input') ///
            (`estimate') (`estimate') ///
            (`standard_error') (`pvalue') ///
            (`ci_low') (`ci_high') (`fixed_h') (`fixed_h') ///
            (.) (.) (`clusters') (`parametric_rc')
    }
}

postclose `rd_post'

/* Adjust same-side placebo-cutoff p-values within each treatment horizon. */
preserve
use "`rd_results'", clear

egen long placebo_family = group(outcome_var) ///
    if family == "placebo_cutoff"
sort placebo_family pvalue
by placebo_family: egen int placebo_m = total(pvalue < .) ///
    if placebo_family < .
by placebo_family: generate int placebo_rank = sum(pvalue < .) ///
    if placebo_family < .

generate double placebo_q_bh = ///
    min(1, pvalue * placebo_m / placebo_rank) ///
    if placebo_family < . & pvalue < .
gsort placebo_family -placebo_rank
by placebo_family: replace placebo_q_bh = ///
    min(placebo_q_bh, placebo_q_bh[_n - 1]) ///
    if _n > 1 & placebo_family < . & placebo_q_bh < .

sort placebo_family placebo_rank
generate double placebo_p_holm = ///
    min(1, pvalue * (placebo_m - placebo_rank + 1)) ///
    if placebo_family < . & pvalue < .
by placebo_family: replace placebo_p_holm = ///
    max(placebo_p_holm, placebo_p_holm[_n - 1]) ///
    if _n > 1 & placebo_family < . & placebo_p_holm < .

drop placebo_family placebo_m placebo_rank
save "`rd_results'", replace
restore


*-----------------------------------*
**# 4. Covariate and linkage continuity
*-----------------------------------*

tempfile covariate_results
tempname covariate_post

postfile `covariate_post' ///
    str20 result_kind ///
    str24 family ///
    str40 spec_id ///
    str32 outcome_var ///
    str96 outcome_label ///
    str28 sample_rule ///
    double cutoff ///
    byte p q ///
    str12 bwselect ///
    str16 kernel ///
    str24 vce ///
    double tuning_value ///
    int n_input ///
    double estimate estimate_conventional ///
    double standard_error pvalue ci_low ci_high ///
    double h_left h_right ///
    int n_eff_left n_eff_right clusters estimation_rc ///
    using "`covariate_results'", replace

local core_source_vars ///
    altitude_m_2017 ///
    ln1p_dist_near_dist_cap ///
    ihs_gdp_dist_2006 ///
    gdp_dist_aagr_9306 ///
    gdp_dist_hhi_2006 ///
    elect_turnout_2002 ///
    elect_margin_2002 ///
    elect_nep_2002 ///
    elect_turnout_2006 ///
    elect_margin_2006 ///
    mayor_apra_2006
local core_label_1 "Altitude (meters)"
local core_label_2 "Log distance to nearest district capital"
local core_label_3 "IHS district GDP, 2006"
local core_label_4 "District GDP annual growth, 1993-2006"
local core_label_5 "District GDP concentration, 2006"
local core_label_6 "Municipal turnout, 2002"
local core_label_7 "Municipal victory margin, 2002"
local core_label_8 "Effective municipal lists, 2002"
local core_label_9 "Municipal turnout, 2006"
local core_label_10 "Municipal victory margin, 2006"
local core_label_11 "APRA mayor elected in 2006"

local timing_source_vars ///
    ln_population_2007 ///
    wellbeing_core_2007 ///
    share_indigenous_language_2007 ///
    share_literate_2007 ///
    share_female_2007 ///
    urban_2007
local timing_label_1 "Log population, 2007"
local timing_label_2 "Core wellbeing score, 2007"
local timing_label_3 "Indigenous-language share, 2007"
local timing_label_4 "Literacy share, 2007"
local timing_label_5 "Female population share, 2007"
local timing_label_6 "Urban community, 2007"

/* Standardize balance measures within the declared B--C sample. */
local core_vars
local core_n : word count `core_source_vars'
forvalues variable_index = 1/`core_n' {
    local source_var : word `variable_index' of `core_source_vars'
    quietly summarize `source_var' if rd_bc_drop_band
    assert r(sd) > 0 & r(sd) < .
    generate double z_core_`variable_index' = ///
        (`source_var' - r(mean)) / r(sd)
    local core_vars "`core_vars' z_core_`variable_index'"
}

local timing_vars
local timing_n : word count `timing_source_vars'
forvalues variable_index = 1/`timing_n' {
    local source_var : word `variable_index' of `timing_source_vars'
    quietly summarize `source_var' if rd_bc_drop_band
    assert r(sd) > 0 & r(sd) < .
    generate double z_timing_`variable_index' = ///
        (`source_var' - r(mean)) / r(sd)
    local timing_vars "`timing_vars' z_timing_`variable_index'"
}

local linkage_vars ///
    census2007_linked ///
    geospatial_linked ///
    gdp_ccpp_linked ///
    gdp_dist_linked ///
    elect2002_available ///
    elect2006_available
local linkage_label_1 "Linked to 2007 Census"
local linkage_label_2 "Linked to geospatial spine"
local linkage_label_3 "Linked to CCPP GDP"
local linkage_label_4 "Linked to district GDP"
local linkage_label_5 "Municipal data available, 2002"
local linkage_label_6 "Municipal data available, 2006"

foreach family in core timing linkage {
    local family_vars "``family'_vars'"
    local family_n : word count `family_vars'

    forvalues variable_index = 1/`family_n' {
        local outcome_var : word `variable_index' of `family_vars'
        local outcome_label "``family'_label_`variable_index''"

        forvalues vce_index = 1/5 {
            local vce_id : word `vce_index' of `vce_ids'
            local vce_type "`vce_`vce_index''"

            _vrd_post_rd, ///
                posthandle(`covariate_post') ///
                resultkind("covariate") ///
                family("`family'") ///
                specid("vce_`vce_id'") ///
                outvar(`outcome_var') ///
                outlabel("`outcome_label'") ///
                usevar(rd_bc_drop_band) ///
                samplerule("drop_rounding_band") ///
                vcetype("`vce_type'")
        }
    }
}

postclose `covariate_post'

preserve
use "`covariate_results'", clear

egen long correction_family = group(family vce)
sort correction_family pvalue
by correction_family: egen int family_m = total(pvalue < .)
by correction_family: generate int p_rank = sum(pvalue < .)

generate double q_bh = ///
    min(1, pvalue * family_m / p_rank) if pvalue < .
gsort correction_family -p_rank
by correction_family: replace q_bh = ///
    min(q_bh, q_bh[_n - 1]) if _n > 1 & q_bh < .

sort correction_family p_rank
generate double p_holm = ///
    min(1, pvalue * (family_m - p_rank + 1)) if pvalue < .
by correction_family: replace p_holm = ///
    max(p_holm, p_holm[_n - 1]) if _n > 1 & p_holm < .

drop correction_family family_m p_rank
save "`covariate_results'", replace
restore


*-----------------------------------*
**# 5. Local-randomization feasibility
*-----------------------------------*

tempfile local_randomization_results
tempname local_randomization_post

postfile `local_randomization_post' ///
    str24 method ///
    str32 outcome_var ///
    str52 status ///
    double window_left window_right ///
    int n_total n_left n_right ///
    double statistic pvalue ///
    int estimation_rc ///
    using "`local_randomization_results'", replace

local lr_covariates ///
    altitude_m_2017 ///
    ln1p_dist_near_dist_cap ///
    ihs_gdp_dist_2006 ///
    gdp_dist_aagr_9306 ///
    elect_turnout_2002 ///
    elect_margin_2002

capture quietly rdwinselect ///
    running_bc `lr_covariates' if rd_bc_drop_band, ///
    cutoff(0) ///
    wmasspoints ///
    dropmissing ///
    statistic(ksmirnov) ///
    nwindows(8) ///
    reps(999) ///
    seed(72641) ///
    level(.15)
local window_rc = _rc

local window_left .
local window_right .
local window_n .
local window_n_left .
local window_n_right .
local window_min_p .
local window_status "window_selection_failed"

if !`window_rc' {
    local window_left = r(w_left)
    local window_right = r(w_right)
    local window_n = r(N)
    local window_n_left = r(N_left)
    local window_n_right = r(N_right)
    local window_min_p = r(minp)
    local window_status "recommended_window_recorded"
}

post `local_randomization_post' ///
    ("rdwinselect") ("predetermined_covariates") ///
    ("`window_status'") ///
    (`window_left') (`window_right') ///
    (`window_n') (`window_n_left') (`window_n_right') ///
    (.) (`window_min_p') (`window_rc')

local randomization_eligible = ///
    !`window_rc' & ///
    `window_n' >= 20 & ///
    `window_n_left' >= 10 & ///
    `window_n_right' >= 10

foreach treatment_var in treat_12 treat_16 {
    local ri_status "not_run_insufficient_window_support"
    local ri_stat .
    local ri_p .
    local ri_rc .

    if `randomization_eligible' {
        capture quietly rdrandinf ///
            `treatment_var' running_bc ///
            if rd_bc_drop_band & ///
                !missing(`lr_covariates'), ///
            cutoff(0) ///
            wl(`window_left') ///
            wr(`window_right') ///
            statistic(diffmeans) ///
            reps(5000) ///
            seed(72641)
        local ri_rc = _rc
        local ri_status "randomization_inference_failed"

        if !`ri_rc' {
            local ri_stat = r(obs_stat)
            local ri_p = r(randpval)
            local ri_status "randomization_inference_completed"
        }
    }

    post `local_randomization_post' ///
        ("rdrandinf") ("`treatment_var'") ///
        ("`ri_status'") ///
        (`window_left') (`window_right') ///
        (`window_n') (`window_n_left') (`window_n_right') ///
        (`ri_stat') (`ri_p') (`ri_rc')
}

postclose `local_randomization_post'


*-----------------------------------*
**# 6. Academic tables and figures
*-----------------------------------*

preserve
use "`support_results'", clear
export delimited using ///
    "`table_dir'/rd_validation_support.csv", replace
restore

preserve
use "`density_results'", clear
export delimited using ///
    "`table_dir'/rd_validation_density.csv", replace
restore

preserve
use "`rd_results'", clear
export delimited using ///
    "`table_dir'/rd_validation_first_stage.csv", replace
restore

preserve
use "`covariate_results'", clear
export delimited using ///
    "`table_dir'/rd_validation_covariates.csv", replace
restore

preserve
use "`local_randomization_results'", clear
export delimited using ///
    "`table_dir'/rd_validation_local_randomization.csv", replace
restore

/* Score mass points reveal discreteness and the conservative exclusion band. */
preserve
keep if rd_bc_recorded & abs(running_bc) <= .03
generate byte community = 1
collapse (sum) communities=community, by(running_bc)
generate byte right_side = running_bc >= 0

twoway ///
    (scatter communities running_bc if !right_side, ///
        mcolor(navy%70) msymbol(O) msize(vsmall)) ///
    (scatter communities running_bc if right_side, ///
        mcolor(maroon%70) msymbol(D) msize(vsmall)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xline(-.00005 .00005, lcolor(gs10) lpattern(shortdash) lwidth(vthin)) ///
    xlabel(-.03(.01).03, format(%5.2f) ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(, angle(0) grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Victimization index centered at the B-C cutoff", size(small)) ///
    ytitle("Communities at each recorded score", size(small)) ///
    title("Recorded score support near the B-C boundary", ///
        size(medium) color(black)) ///
    subtitle("Repeated mass points and narrow rounding uncertainty are documented", ///
        size(small) color(gs5)) ///
    legend(order(1 "Below cutoff" 2 "At or above cutoff") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is an RUV centro poblado in the selected geography and category B or C, within 0.03 index units of B-C." ///
        "Each marker is a distinct recorded score; its height is the number of communities. The black line is the official six-decimal cutoff" ///
        "after centering; gray lines bound the half-unit implied by four-decimal score storage. Source: RUV victimization register.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_validation_01_score_mass_points.png", ///
    width(3000) replace
restore

/* Annual first-stage estimates show the evolution of compliance. */
preserve
use "`rd_results'", clear
keep if family == "horizon" & spec_id == "horizon_cr2"
generate int treatment_year = real(substr(outcome_var, 7, 2)) + 2000
isid treatment_year
sort treatment_year

twoway ///
    (rarea ci_low ci_high treatment_year, ///
        color(navy%16) lcolor(none)) ///
    (connected estimate treatment_year, ///
        lcolor(navy) lwidth(medthick) ///
        mcolor(navy) msymbol(O) msize(small)), ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    xlabel(2007(2)2023, labsize(small)) ///
    ylabel(, format(%4.2f) angle(0) ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Cumulative treatment horizon", size(small)) ///
    ytitle("Discontinuity in treatment probability", size(small)) ///
    title("B-C first-stage discontinuity over the program rollout", ///
        size(medium) color(black)) ///
    subtitle("Local-linear estimates with district-clustered CR2 intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "Estimate" 1 "Robust 95% confidence interval") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is an RUV centro poblado in the selected geography and category B or C. Outcomes indicate cumulative receipt by each year." ///
        "Bias-corrected estimates use local-linear triangular-kernel rdrobust models, MSE-optimal bandwidths, mass-point adjustment, district CR2 inference," ///
        "and exclude scores within 0.00005 of B-C. This display does not select a treatment horizon. Source: RUV and CMAN through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10.5) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_validation_02_first_stage_horizons.png", ///
    width(3200) replace
restore

/* Data-driven RD plots for the two outcome-linked treatment horizons. */
foreach year_suffix in 12 16 {
    local treatment_var "treat_`year_suffix'"
    local treatment_year = 2000 + `year_suffix'
    local figure_number = cond(`year_suffix' == 12, "03", "04")

    rdplot `treatment_var' running_bc if rd_bc_drop_band, ///
        c(0) ///
        p(1) ///
        h(.03 .03) ///
        kernel(triangular) ///
        binselect(esmvpr) ///
        masspoints(adjust) ///
        ci(95) ///
        graph_options( ///
            title("Treatment receipt at the B-C boundary, `treatment_year'", ///
                size(medium) color(black)) ///
            subtitle("Binned means and local-linear fits within 0.03 index units", ///
                size(small) color(gs5)) ///
            xtitle("Victimization index centered at B-C", size(small)) ///
            ytitle("Share treated by `treatment_year'", size(small)) ///
            xlabel(-.03(.01).03, format(%5.2f) ///
                grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
            ylabel(0(.2)1, format(%3.1f) angle(0) ///
                grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
            legend(off) ///
            note( ///
                "Notes: Unit is an RUV centro poblado in the selected geography and category B or C. The outcome is cumulative collective-reparation receipt by `treatment_year'." ///
                "Points are data-driven evenly spaced binned means with 95% intervals; lines are triangular-kernel local-linear fits." ///
                "Scores within 0.00005 of B-C are excluded. This is a design plot, not the causal outcome estimate. Source: RUV and CMAN through 2023.", ///
                size(vsmall) color(gs5) span) ///
            graphregion(color(white)) plotregion(color(white)) ///
            xsize(10) ysize(7))

    graph export ///
        "`figure_dir'/fig_rd_validation_`figure_number'_treatment_`treatment_year'.png", ///
        width(3000) replace
}

/* Covariate forest plot uses CR2 only; the CSV retains all five VCE branches. */
preserve
use "`covariate_results'", clear
keep if spec_id == "vce_cr2" & inlist(family, "core", "timing")
keep if estimation_rc == 0

generate int covariate_order = .
local forest_vars "`core_vars' `timing_vars'"
local forest_n : word count `forest_vars'
forvalues variable_index = 1/`forest_n' {
    local outcome_var : word `variable_index' of `forest_vars'
    replace covariate_order = `variable_index' if outcome_var == "`outcome_var'"
}
assert !missing(covariate_order)
capture label drop rd_covariate_axis
forvalues variable_index = 1/`forest_n' {
    quietly levelsof outcome_label if ///
        covariate_order == `variable_index', ///
        local(axis_label) clean
    label define rd_covariate_axis ///
        `variable_index' `"`axis_label'"', add
}
label values covariate_order rd_covariate_axis

twoway ///
    (rcap ci_low ci_high covariate_order if family == "core", ///
        horizontal lcolor(navy%55) lwidth(thin)) ///
    (scatter covariate_order estimate if family == "core", ///
        mcolor(navy) msymbol(O) msize(small)) ///
    (rcap ci_low ci_high covariate_order if family == "timing", ///
        horizontal lcolor(maroon%55) lwidth(thin)) ///
    (scatter covariate_order estimate if family == "timing", ///
        mcolor(maroon) msymbol(D) msize(small)), ///
    xline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    yscale(reverse) ///
    ylabel(1(1)`forest_n', valuelabel angle(0) labsize(vsmall)) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Discontinuity in sample standard deviations", size(small)) ///
    ytitle("") ///
    title("Predetermined and near-baseline continuity at B-C", ///
        size(medium) color(black)) ///
    subtitle("Core pre-treatment measures are separated from the 2007 Census", ///
        size(small) color(gs5)) ///
    legend(order(2 "Pre-treatment" 4 "2007 timing-sensitive") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is an RUV centro poblado in the selected B/C geography. Measures are standardized in that sample." ///
        "Points are bias-corrected local-linear rdrobust estimates; bars are robust 95% intervals. Models use district CR2 inference and exclude the rounding band." ///
        "The 2007 Census may overlap the first treatment year. Source: RUV, INEI, Seminario-Palomino, ONPE, and JNE.", ///
        size(vsmall) color(gs5) span) ///
    xsize(11.5) ysize(8.5) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_validation_05_covariate_continuity.png", ///
    width(3400) replace
restore

/* Fixed-bandwidth and donut sensitivity panels. */
preserve
use "`rd_results'", clear
keep if inlist(family, "fixed_bandwidth", "donut") & estimation_rc == 0
generate int treatment_year = real(substr(outcome_var, 7, 2)) + 2000
replace family = "Donut exclusion" if family == "donut"
replace family = "Fixed bandwidth" if family == "fixed_bandwidth"
sort family treatment_year tuning_value

twoway ///
    (rcap ci_low ci_high tuning_value if treatment_year == 2012, ///
        lcolor(navy%45) lwidth(vthin)) ///
    (connected estimate tuning_value if treatment_year == 2012, ///
        lcolor(navy) mcolor(navy) msymbol(O) lwidth(medium)) ///
    (rcap ci_low ci_high tuning_value if treatment_year == 2016, ///
        lcolor(maroon%45) lwidth(vthin)) ///
    (connected estimate tuning_value if treatment_year == 2016, ///
        lcolor(maroon) mcolor(maroon) msymbol(D) lwidth(medium)), ///
    by(family, rows(1) xrescale imargin(medium) ///
        title("First-stage sensitivity to bandwidth and donut choices", ///
            size(medium) color(black)) ///
        subtitle("Prespecified values; robust 95% confidence intervals", ///
            size(small) color(gs5)) ///
        note( ///
            "Notes: Unit is an RUV centro poblado in the selected geography and category B or C. The fixed-bandwidth panel varies a common bandwidth in index units;" ///
            "the donut panel excludes observations within the displayed radius. Bias-corrected estimates use local-linear triangular-kernel rdrobust with district CR2 inference" ///
            "and mass-point adjustment. Outcomes are cumulative receipt by 2012 or 2016. Source: RUV and CMAN through 2023.", ///
            size(vsmall) color(gs5) span) ///
        graphregion(color(white))) ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    xlabel(, format(%7.4f) grid glcolor(gs14) glwidth(vthin) labsize(vsmall)) ///
    ylabel(, format(%4.2f) angle(0) ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Bandwidth or donut radius (index units)", size(small)) ///
    ytitle("Treatment-probability discontinuity", size(small)) ///
    legend(order(2 "Treated by 2012" 4 "Treated by 2016") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    xsize(12) ysize(7.2) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_validation_06_bandwidth_donut.png", ///
    width(3400) replace
restore

/* Placebo cutoffs are estimated only within the corresponding true side. */
preserve
use "`rd_results'", clear
keep if family == "placebo_cutoff" & estimation_rc == 0
generate int treatment_year = real(substr(outcome_var, 7, 2)) + 2000
sort treatment_year tuning_value

twoway ///
    (rcap ci_low ci_high tuning_value if treatment_year == 2012, ///
        lcolor(navy%45) lwidth(vthin)) ///
    (connected estimate tuning_value if treatment_year == 2012, ///
        lcolor(navy) mcolor(navy) msymbol(O) lwidth(medium)) ///
    (rcap ci_low ci_high tuning_value if treatment_year == 2016, ///
        lcolor(maroon%45) lwidth(vthin)) ///
    (connected estimate tuning_value if treatment_year == 2016, ///
        lcolor(maroon) mcolor(maroon) msymbol(D) lwidth(medium)), ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(-.02(.005).02, format(%6.3f) ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(, format(%4.2f) angle(0) ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Placebo cutoff relative to B-C", size(small)) ///
    ytitle("Treatment-probability discontinuity", size(small)) ///
    title("Treatment first stages at same-side placebo cutoffs", ///
        size(medium) color(black)) ///
    subtitle("Placebos do not pool observations across the true B-C boundary", ///
        size(small) color(gs5)) ///
    legend(order(2 "Treated by 2012" 4 "Treated by 2016") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Unit is an RUV centro poblado in the selected B/C geography. Each placebo uses observations only on its side of the true cutoff." ///
        "Bias-corrected local-linear triangular-kernel rdrobust uses MSE-optimal bandwidths, mass-point adjustment, and district CR2 inference." ///
        "Models exclude the rounding band. BH and Holm placebo adjustments are in the CSV." ///
        "Outcomes are cumulative receipt by 2012 or 2016. Source: RUV and CMAN through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(10.5) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))

graph export ///
    "`figure_dir'/fig_rd_validation_07_placebo_cutoffs.png", ///
    width(3200) replace
restore

/* Compact LaTeX support and density table. */
tempname support_table
file open `support_table' using ///
    "`table_dir'/tab_rd_validation_01_support_density.tex", ///
    write replace text

file write `support_table' "\begin{table}[!htbp]" _n
file write `support_table' "\centering" _n
file write `support_table' "\small" _n
file write `support_table' "\caption{Running-variable support and density diagnostics at B--C}" _n
file write `support_table' "\label{tab:rd_validation_support_density}" _n
file write `support_table' "\begin{tabular}{lrrrrrrr}" _n
file write `support_table' "\toprule" _n
file write `support_table' "Score branch & N & Left & Right & Unique left & Unique right & Density \(T\) & \(p\)-value \\" _n
file write `support_table' "\midrule" _n

forvalues sample_index = 1/4 {
    local sample_rule : word `sample_index' of `sample_rules'
    local branch_label : subinstr local sample_rule "_" " " , all

    preserve
    use "`support_results'", clear
    quietly summarize n_total if sample_rule == "`sample_rule'", meanonly
    local n_total : display %9.0fc r(mean)
    quietly summarize n_left if sample_rule == "`sample_rule'", meanonly
    local n_left : display %9.0fc r(mean)
    quietly summarize n_right if sample_rule == "`sample_rule'", meanonly
    local n_right : display %9.0fc r(mean)
    quietly summarize unique_left if sample_rule == "`sample_rule'", meanonly
    local unique_left : display %9.0fc r(mean)
    quietly summarize unique_right if sample_rule == "`sample_rule'", meanonly
    local unique_right : display %9.0fc r(mean)
    restore

    preserve
    use "`density_results'", clear
    quietly summarize statistic if sample_rule == "`sample_rule'", meanonly
    local density_t : display %6.3f r(mean)
    quietly summarize pvalue if sample_rule == "`sample_rule'", meanonly
    local density_p : display %6.3f r(mean)
    restore

    foreach formatted_value in ///
        n_total n_left n_right unique_left unique_right density_t density_p {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `support_table' ///
        "`branch_label' & `n_total' & `n_left' & `n_right' & `unique_left' & `unique_right' & `density_t' & `density_p' \\" _n
}

file write `support_table' "\bottomrule" _n
file write `support_table' "\end{tabular}" _n
file write `support_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The unit is an RUV centro poblado in the research-team-selected geography. The first three branches use categories B and C; the final branch retains the selected geography's full score support. Density statistics are robust local-polynomial \texttt{rddensity} tests with triangular kernels, mass-point adjustment, and jackknife variance. The recorded score is rounded and repeated, so the density test is a sorting diagnostic rather than definitive evidence of manipulation or its absence. Source: RUV victimization register.}" _n
file write `support_table' "\end{table}" _n
file close `support_table'

/* Compact first-stage table for the outcome-linked horizons. */
tempname first_stage_table
file open `first_stage_table' using ///
    "`table_dir'/tab_rd_validation_02_first_stage.tex", ///
    write replace text

file write `first_stage_table' "\begin{table}[!htbp]" _n
file write `first_stage_table' "\centering" _n
file write `first_stage_table' "\small" _n
file write `first_stage_table' "\caption{Selected-sample B--C first-stage discontinuities}" _n
file write `first_stage_table' "\label{tab:rd_validation_first_stage}" _n
file write `first_stage_table' "\begin{tabular}{lrrrrrr}" _n
file write `first_stage_table' "\toprule" _n
file write `first_stage_table' "Horizon & Estimate & Robust SE & 95\% CI & \(p\)-value & Effective N & Districts \\" _n
file write `first_stage_table' "\midrule" _n

foreach year_suffix in 12 16 23 {
    local treatment_var "treat_`year_suffix'"
    local treatment_year = 2000 + `year_suffix'

    preserve
    use "`rd_results'", clear
    keep if family == "horizon" & outcome_var == "`treatment_var'"
    assert _N == 1

    local estimate : display %6.3f estimate[1]
    local standard_error : display %6.3f standard_error[1]
    local ci_low : display %6.3f ci_low[1]
    local ci_high : display %6.3f ci_high[1]
    local pvalue : display %6.3f pvalue[1]
    local effective_n : display %9.0fc n_eff_left[1] + n_eff_right[1]
    local clusters : display %9.0fc clusters[1]
    restore

    foreach formatted_value in ///
        estimate standard_error ci_low ci_high pvalue effective_n clusters {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `first_stage_table' ///
        "`treatment_year' & `estimate' & `standard_error' & [`ci_low', `ci_high'] & `pvalue' & `effective_n' & `clusters' \\" _n
}

file write `first_stage_table' "\bottomrule" _n
file write `first_stage_table' "\end{tabular}" _n
file write `first_stage_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The outcome is cumulative collective-reparation receipt by the listed year. The unit is an RUV centro poblado in the selected geography and category B or C. Bias-corrected local-linear triangular-kernel estimates use MSE-optimal bandwidths, robust inference, mass-point adjustment, district CR2 variance, and exclusion of scores within 0.00005 of B--C. Effective N is the sum inside the left and right bandwidths. Conventional point estimates are retained in the CSV. No treatment horizon is selected by this table. Source: RUV and CMAN through 2023.}" _n
file write `first_stage_table' "\end{table}" _n
file close `first_stage_table'

/* Covariate table reports CR2 while the CSV retains every inference branch. */
tempname covariate_table
file open `covariate_table' using ///
    "`table_dir'/tab_rd_validation_03_covariates.tex", ///
    write replace text

file write `covariate_table' "\begin{table}[!htbp]" _n
file write `covariate_table' "\centering" _n
file write `covariate_table' "\scriptsize" _n
file write `covariate_table' "\caption{Continuity of predetermined, near-baseline, and linkage measures}" _n
file write `covariate_table' "\label{tab:rd_validation_covariates}" _n
file write `covariate_table' "\begin{tabular}{lrrrr}" _n
file write `covariate_table' "\toprule" _n
file write `covariate_table' "Measure & Estimate & 95\% CI & Raw \(p\) & BH \(q\) \\" _n
file write `covariate_table' "\midrule" _n

preserve
use "`covariate_results'", clear
keep if spec_id == "vce_cr2" & estimation_rc == 0

foreach family in core timing linkage {
    if "`family'" == "core" local family_label "Predetermined measures"
    if "`family'" == "timing" local family_label "2007 timing-sensitive measures"
    if "`family'" == "linkage" local family_label "Linkage and availability measures"
    file write `covariate_table' ///
        "\multicolumn{5}{l}{\textit{`family_label'}} \\" _n

    quietly count if family == "`family'"
    local family_n = r(N)

    forvalues row = 1/`=_N' {
        if family[`row'] == "`family'" {
            local row_label = outcome_label[`row']
            local estimate : display %7.3f estimate[`row']
            local ci_low : display %7.3f ci_low[`row']
            local ci_high : display %7.3f ci_high[`row']
            local pvalue : display %6.3f pvalue[`row']
            local q_bh : display %6.3f q_bh[`row']

            if pvalue[`row'] >= . local pvalue "--"
            if q_bh[`row'] >= . local q_bh "--"

            foreach formatted_value in estimate ci_low ci_high pvalue q_bh {
                local `formatted_value' = strtrim("``formatted_value''")
            }

            file write `covariate_table' ///
                "`row_label' & `estimate' & [`ci_low', `ci_high'] & `pvalue' & `q_bh' \\" _n
        }
    }
    file write `covariate_table' "\addlinespace" _n
}
restore

file write `covariate_table' "\bottomrule" _n
file write `covariate_table' "\end{tabular}" _n
file write `covariate_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Each row is a separate bias-corrected local-linear triangular-kernel \texttt{rdrobust} continuity test at B--C in the selected geography. Core and 2007 measures are standardized within the B--C sample; linkage rows are probability differences. Models use MSE-optimal bandwidths, mass-point adjustment, district CR2 inference, and rounding-band exclusion. BH q-values control the false discovery rate within family; Holm-adjusted values and NN, HC3, CR1, CR2, and CR3 branches are in the CSV. The 2007 Census may overlap the first program year. Source: RUV, INEI, Seminario-Palomino, ONPE, and JNE.}" _n
file write `covariate_table' "\end{table}" _n
file close `covariate_table'

/* Compact sensitivity table; complete grids remain in CSV. */
tempname sensitivity_table
file open `sensitivity_table' using ///
    "`table_dir'/tab_rd_validation_04_sensitivity.tex", ///
    write replace text

file write `sensitivity_table' "\begin{table}[!htbp]" _n
file write `sensitivity_table' "\centering" _n
file write `sensitivity_table' "\scriptsize" _n
file write `sensitivity_table' "\caption{B--C first-stage estimator and inference sensitivity}" _n
file write `sensitivity_table' "\label{tab:rd_validation_sensitivity}" _n
file write `sensitivity_table' "\begin{tabular}{llrrr}" _n
file write `sensitivity_table' "\toprule" _n
file write `sensitivity_table' "Family & Specification & Horizon & Estimate & 95\% CI \\" _n
file write `sensitivity_table' "\midrule" _n

preserve
use "`rd_results'", clear
keep if inlist(family, "score_support", "inference", "estimator")
keep if estimation_rc == 0

forvalues row = 1/`=_N' {
    local family_label = subinstr(family[`row'], "_", " ", .)
    local specification_label = subinstr(spec_id[`row'], "_", " ", .)
    local treatment_year = real(substr(outcome_var[`row'], 7, 2)) + 2000
    local estimate : display %7.3f estimate[`row']
    local ci_low : display %7.3f ci_low[`row']
    local ci_high : display %7.3f ci_high[`row']

    foreach formatted_value in estimate ci_low ci_high {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `sensitivity_table' ///
        "`family_label' & `specification_label' & `treatment_year' & `estimate' & [`ci_low', `ci_high'] \\" _n
}
restore

file write `sensitivity_table' "\bottomrule" _n
file write `sensitivity_table' "\end{tabular}" _n
file write `sensitivity_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The outcome is cumulative collective-reparation receipt by 2012 or 2016. The table varies score/support rules, variance estimators, bandwidth selectors, kernels, and polynomial order. Robust bias-corrected 95\% intervals are reported. Fixed-bandwidth, donut, placebo-cutoff, and parametric rows are retained in the accompanying CSV and figures. These are sensitivity branches, not a result-selection exercise. Source: RUV and CMAN through 2023.}" _n
file write `sensitivity_table' "\end{table}" _n
file close `sensitivity_table'

/* Local-randomization table records feasibility without forcing inference. */
tempname local_randomization_table
file open `local_randomization_table' using ///
    "`table_dir'/tab_rd_validation_05_local_randomization.tex", ///
    write replace text

file write `local_randomization_table' "\begin{table}[!htbp]" _n
file write `local_randomization_table' "\centering" _n
file write `local_randomization_table' "\small" _n
file write `local_randomization_table' "\caption{Local-randomization window feasibility at B--C}" _n
file write `local_randomization_table' "\label{tab:rd_validation_local_randomization}" _n
file write `local_randomization_table' "\begin{tabular}{lllrrrr}" _n
file write `local_randomization_table' "\toprule" _n
file write `local_randomization_table' "Method & Outcome & Status & Window & N & Left & Right \\" _n
file write `local_randomization_table' "\midrule" _n

preserve
use "`local_randomization_results'", clear

forvalues row = 1/`=_N' {
    local method_label = subinstr(method[`row'], "_", " ", .)
    local outcome_label = subinstr(outcome_var[`row'], "_", " ", .)
    local status_label = subinstr(status[`row'], "_", " ", .)
    local window_left : display %7.5f window_left[`row']
    local window_right : display %7.5f window_right[`row']
    local n_total : display %9.0fc n_total[`row']
    local n_left : display %9.0fc n_left[`row']
    local n_right : display %9.0fc n_right[`row']

    foreach formatted_value in ///
        window_left window_right n_total n_left n_right {
        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `local_randomization_table' ///
        "`method_label' & `outcome_label' & `status_label' & [`window_left', `window_right'] & `n_total' & `n_left' & `n_right' \\" _n
}
restore

file write `local_randomization_table' "\bottomrule" _n
file write `local_randomization_table' "\end{tabular}" _n
file write `local_randomization_table' "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} \texttt{rdwinselect} uses altitude, distance to the nearest district capital, 2006 district GDP, 1993--2006 GDP growth, and 2002 turnout and victory margin. Windows respect score mass points; missing covariates are dropped. Randomization inference is prespecified to run only with at least 20 observations and 10 on each side. The selected window contains only five observations, so \texttt{rdrandinf} is correctly not run. Source: RUV, INEI, Seminario-Palomino, ONPE, and JNE.}" _n
file write `local_randomization_table' "\end{table}" _n
file close `local_randomization_table'


*-----------------------------------*
**# 7. Output manifest and closeout
*-----------------------------------*

tempname manifest_handle
file open `manifest_handle' using "`manifest'", write replace text
file write `manifest_handle' ///
    "path,artifact_type,input_data,input_datasignature,generator,run_id,checksum,review_status" _n

foreach output_path of local output_paths {
    local absolute_path "${project_root}/`output_path'"
    capture confirm file "`absolute_path'"
    if _rc {
        display as error "Expected RD-validation output was not created:"
        display as error "  `absolute_path'"
        file close `manifest_handle'
        log close victimasrd_rd_validation
        exit 603
    }

    quietly checksum "`absolute_path'"
    local output_checksum : display %20.0f r(checksum)
    local output_checksum = strtrim("`output_checksum'")
    local artifact_type "table"
    if strpos("`output_path'", "output/figures/") == 1 {
        local artifact_type "figure"
    }

    file write `manifest_handle' ///
        `""`output_path'","`artifact_type'","08_community_registry_elections.dta","`input_datasignature'","code/stata/pipeline/03b_validate_rd_assumptions.do","`run_id'","`output_checksum'","generated_unreviewed""' _n
}

file close `manifest_handle'

capture confirm file "`manifest'"
if _rc {
    display as error "RD-validation output manifest was not created."
    log close victimasrd_rd_validation
    exit 603
}

display as result "Selected-sample RD validity diagnostics completed."
display as text "Tables:   `table_dir'"
display as text "Figures:  `figure_dir'"
display as text "Manifest: `manifest'"
display as text "Review status: generated_unreviewed"

capture program drop _vrd_post_rd
log close victimasrd_rd_validation
