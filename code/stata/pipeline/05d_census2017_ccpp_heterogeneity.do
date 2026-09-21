/*
Project: Victimas RD
Purpose: Estimate prespecified Census 2017 CCPP RD heterogeneity
Unit:    RUV centro poblado represented in the INEI-assisted Census cohort
Input:   14_community_registry_census_2017.dta (Dropbox Coded)
Registry: outcome-registry-2017-ccpp.csv
Outputs: Aggregate CSV/LaTeX results and publication-formatted figures in Git
*/

version 19
set more off

capture log close victimasrd_hte_2017_ccpp
log using "${logs_root}/hte_2017_ccpp_${hte_run_id}.smcl", ///
    name(victimasrd_hte_2017_ccpp) replace


*-----------------------------------*
**# 1. Input and complete primary sample
*-----------------------------------*

use "${hte_input_2017_ccpp}", clear
quietly datasignature
local input_datasignature "`r(datasignature)'"

assert _N == 5712
isid ruv_id

local required_vars ///
    ruv_id ubigeo_dist ubigeo_ccpp ///
    sample_main_rd victimization_level_source ///
    ${hte_running} ${hte_treatment_2017} ///
    census2017_cohort_covered population_2017 ///
    dwellings_occupied_2017 cpv2017_share_moved_ccpp ///
    share_age_15_29_2017 cpv2017_share_secondary_age14 ///
    cpv2017_share_employed_age14 cpv2017_share_insured ///
    wellbeing_core_2017 population_2007 ln_population_2007 ///
    is_dist_capital_2017 deprivation_core_2007 ///
    ln1p_dist_dist_capital ihs_gdp_ccpp_2006 ///
    altitude_m_2017 ${hte_primary_covariates}

foreach required_var of local required_vars {
    confirm variable `required_var'
}

assert regexm(ruv_id, "^S[0-9]{8}$")
assert inlist(${hte_treatment_2017}, 0, 1) ///
    if !missing(${hte_treatment_2017})

generate double ln_population_2017 = ///
    ln(population_2017) if population_2017 > 0
generate double ln_dwellings_occupied_2017 = ///
    ln(dwellings_occupied_2017) if dwellings_occupied_2017 > 0

local primary_outcomes ///
    ln_population_2017 ///
    ln_dwellings_occupied_2017 ///
    cpv2017_share_moved_ccpp ///
    share_age_15_29_2017 ///
    cpv2017_share_secondary_age14 ///
    cpv2017_share_employed_age14 ///
    cpv2017_share_insured ///
    wellbeing_core_2017

generate byte hte_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")

quietly count if hte_bc_design
assert r(N) == 549
quietly count if hte_bc_design & ///
    ((victimization_level_source == "B" & ${hte_running} < 0) | ///
     (victimization_level_source == "C" & ${hte_running} >= 0))
assert r(N) == 0
quietly count if hte_bc_design & ///
    missing(ruv_id, ubigeo_dist, ${hte_running}, ${hte_treatment_2017})
assert r(N) == 0

encode ruv_id, generate(hte_cluster_ruv)
encode ubigeo_dist, generate(hte_cluster_dist)
egen long hte_cluster_score = group(${hte_running})
generate byte hte_assignment = ${hte_running} >= 0 ///
    if !missing(${hte_running})

egen byte hte_primary_missing = rowmiss(`primary_outcomes') ///
    if hte_bc_design & census2017_cohort_covered == 1
generate byte hte_primary_sample = ///
    hte_bc_design & census2017_cohort_covered == 1 & ///
    hte_primary_missing == 0

quietly count if hte_bc_design & census2017_cohort_covered == 1
assert r(N) == 426
quietly count if hte_primary_sample
assert r(N) == 388
quietly count if hte_primary_sample & ///
    abs(${hte_running}) <= ${hte_common_h}
assert r(N) == 59

keep if hte_bc_design
assert _N == 549


*-----------------------------------*
**# 2. CCPP-specific analysis contract
*-----------------------------------*

global hte_level                    "ccpp"
global hte_sort_key                 "ruv_id"
global hte_level_caption            "CCPP-level"
global hte_unit_label               "RUV community"
global hte_unit_plural              "communities"
global hte_observation_weight_id    "community_equal"
global hte_observation_weight_label "Community-equal"
global hte_primary_weighting        "community_equal"
global hte_primary_weighting_label  "Community-equal"
global hte_primary_cluster_var      "hte_cluster_dist"
global hte_primary_cluster_rule     "district"
global hte_primary_cluster_label    "District-clustered"
global hte_primary_sensitivity_specs ///
    "small_h_iv large_h_iv common_h_ccpp_cluster common_h_score_cluster"
global hte_primary_weighting_note ///
    "Each eligible RUV community contributes one observation before triangular kernel weighting."
global hte_primary_inference_note ///
    "Primary IV and rdhte inference clusters by district; RUV-community and score-mass clustering are sensitivities."
global hte_primary_design_note ///
    "One observation per RUV community receives triangular kernel weight; primary inference clusters by district."
global hte_primary_design_note_tex ///
    "One observation per community; inference clusters by district."
global hte_sensitivity_note_tex ///
    "Sensitivities add predetermined covariates, use smaller or larger fixed windows, or cluster by RUV community or score mass point."
global hte_post_treatment_detail ///
    "Project type and financing are excluded from ordinary moderation and handled only as separate implementation extensions."
global hte_treatment                "${hte_treatment_2017}"
global hte_moderator_var_column     "moderator_var_2017"
global hte_wave_label               "Census 2017"
global hte_source_note              "INEI-assisted Census 2017"
global hte_source_note_tex          "INEI-assisted Census 2017"
global hte_treatment_timing_label ///
    "Cumulative collective-reparation receipt through 2016 for Census 2017 outcomes."
global hte_person_source_label      "INEI-assisted Census 2017 records"
global hte_outcome_registry_level   "${hte_outcomes_17_ccpp}"
global hte_applicable_moderators    "M01 M02 S01 S02 S03 S05"
global hte_expected_results         208
global hte_expected_support_rows    14
global hte_input_basename           "14_community_registry_census_2017.dta"
global hte_input_datasignature      "`input_datasignature'"
global hte_module_current           "code/stata/pipeline/05d_census2017_ccpp_heterogeneity.do"
global hte_manifest_current         "${hte_manifest_2017_ccpp}"
global hte_output_stub              "2017_ccpp"
global hte_primary_outcomes         "`primary_outcomes'"

do "${hte_level_engine}"
local engine_rc = _rc

if `engine_rc' {
    capture log close victimasrd_hte_2017_ccpp
    exit `engine_rc'
}


*-----------------------------------*
**# 3. Project implementation through 2016
*-----------------------------------*

/*
Project attributes are post-assignment and undefined for untreated CCPPs.
They are therefore excluded from the moderator grid. This extension reports
composition and assignment discontinuities, plus a clearly exploratory
continuous-dose IV using recorded nominal financing per 2007 resident.
*/

tempfile project_records project_ccpp primary_ids implementation ///
    composition dose_results ccpp_extension_base

use "${hte_project_registry}", clear
confirm variable ruv_id record_number recorded_project_year ///
    prc_project_group prc_total_financing_soles
isid record_number

keep if !missing(ruv_id) & recorded_project_year <= 2016
assert prc_total_financing_soles > 0
assert inrange(prc_project_group, 1, 4)

forvalues project_group = 1/4 {
    generate byte hte_project_group_`project_group' = ///
        prc_project_group == `project_group'
}
generate byte hte_project_record = 1
save `project_records'

collapse ///
    (sum) hte_total_financing_2016=prc_total_financing_soles ///
          hte_project_records_2016=hte_project_record ///
    (max) hte_project_group_1-hte_project_group_4, ///
    by(ruv_id)
isid ruv_id
save `project_ccpp'

use "${hte_input_2017_ccpp}", clear
generate double ln_population_2017 = ///
    ln(population_2017) if population_2017 > 0
generate double ln_dwellings_occupied_2017 = ///
    ln(dwellings_occupied_2017) if dwellings_occupied_2017 > 0

local primary_outcomes ///
    ln_population_2017 ///
    ln_dwellings_occupied_2017 ///
    cpv2017_share_moved_ccpp ///
    share_age_15_29_2017 ///
    cpv2017_share_secondary_age14 ///
    cpv2017_share_employed_age14 ///
    cpv2017_share_insured ///
    wellbeing_core_2017

generate byte hte_bc_design = ///
    sample_main_rd == 1 & ///
    inlist(victimization_level_source, "B", "C")
egen byte hte_primary_missing = rowmiss(`primary_outcomes') ///
    if hte_bc_design & census2017_cohort_covered == 1
generate byte hte_primary_sample = ///
    hte_bc_design & census2017_cohort_covered == 1 & ///
    hte_primary_missing == 0
assert inlist(${hte_treatment_2017}, 0, 1) if hte_bc_design

encode ubigeo_dist, generate(hte_cluster_dist)
generate byte hte_assignment = ${hte_running} >= 0 ///
    if !missing(${hte_running})
generate double hte_running_right = ///
    ${hte_running} * hte_assignment

merge 1:1 ruv_id using `project_ccpp', keep(master match) nogen
replace hte_total_financing_2016 = 0 if ${hte_treatment_2017} == 0
replace hte_project_records_2016 = 0 if ${hte_treatment_2017} == 0
forvalues project_group = 1/4 {
    replace hte_project_group_`project_group' = 0 ///
        if ${hte_treatment_2017} == 0
}

assert hte_total_financing_2016 > 0 if ///
    hte_primary_sample & ${hte_treatment_2017} == 1
assert hte_project_records_2016 >= 1 if ///
    hte_primary_sample & ${hte_treatment_2017} == 1

generate double hte_financing_pc_2016 = ///
    hte_total_financing_2016 / population_2007 ///
    if population_2007 > 0
generate double hte_financing_pc_1000 = ///
    hte_financing_pc_2016 / 1000
label variable hte_financing_pc_1000 ///
    "Thousands of recorded soles through 2016 per 2007 resident"
save `ccpp_extension_base'

keep if hte_primary_sample
keep ruv_id
isid ruv_id
save `primary_ids'


*-----------------------------------*
**# 4. Composition and assignment discontinuities
*-----------------------------------*

use `project_records', clear
merge m:1 ruv_id using `primary_ids', keep(match) nogen
egen byte project_community_tag = tag(prc_project_group ruv_id)

collapse ///
    (sum) project_records=hte_project_record ///
          communities=project_community_tag, ///
    by(prc_project_group)
sort prc_project_group
assert _N == 4
egen long total_records = total(project_records)
generate double record_share_pct = 100 * project_records / total_records

generate str45 project_label = ""
replace project_label = "Productive livelihood" if prc_project_group == 1
replace project_label = "Social and basic services" if prc_project_group == 2
replace project_label = "Community and civic infrastructure" ///
    if prc_project_group == 3
replace project_label = "Management and capacity support" ///
    if prc_project_group == 4

order prc_project_group project_label project_records communities ///
    record_share_pct total_records
save `composition'
export delimited using ///
    "${hte_table_dir}/rd_hte_2017_ccpp_project_composition.csv", ///
    replace nolabel

tempname implementation_post
postfile `implementation_post' ///
    str20 component_id str60 component_label str24 estimand ///
    double scale estimate standard_error pvalue ci_low ci_high ///
    n_left n_right effective_n first_stage_f ///
    str28 status int estimation_rc ///
    using `implementation', replace

use `ccpp_extension_base', clear
local project_group_1 "Productive livelihood"
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
        kernel(triangular) vce(cr2 hte_cluster_dist) ///
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
        ("group_`project_group'") ///
        ("`project_group_`project_group''") ///
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
    kernel(triangular) vce(cr2 hte_cluster_dist) ///
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

use `implementation', clear
assert _N == 5
export delimited using ///
    "${hte_table_dir}/rd_hte_2017_ccpp_project_discontinuities.csv", ///
    replace nolabel


*-----------------------------------*
**# 5. Exploratory recorded-financing dose IV
*-----------------------------------*

preserve
import delimited using "${hte_outcomes_17_ccpp}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if tier == "primary"
sort paper_order
assert _N == 8
forvalues outcome_index = 1/8 {
    local d_order_`outcome_index' = paper_order[`outcome_index']
    local d_id_`outcome_index' = outcome_id[`outcome_index']
    local d_var_`outcome_index' = outcome_var[`outcome_index']
    local d_label_`outcome_index' = outcome_label[`outcome_index']
    local d_scale_`outcome_index' = scale[`outcome_index']
}
restore

tempname dose_post
postfile `dose_post' ///
    double paper_order str8 outcome_id str48 outcome_var ///
    str80 outcome_label double scale estimate standard_error ///
    pvalue ci_low ci_high control_sd standardized_estimate ///
    standardized_ci_low standardized_ci_high kp_f underid_p ///
    byte gate_pass str28 gate_status int estimation_rc ///
    using `dose_results', replace

forvalues outcome_index = 1/8 {
    use `ccpp_extension_base', clear
    local outcome_var "`d_var_`outcome_index''"
    local outcome_scale = `d_scale_`outcome_index''

    tempvar y_scaled kernel_weight
    generate double `y_scaled' = `outcome_var' * `outcome_scale'
    generate double `kernel_weight' = ///
        1 - abs(${hte_running}) / ${hte_common_h} ///
        if hte_primary_sample & ///
        abs(${hte_running}) < ${hte_common_h}

    capture quietly ivreg2 ///
        `y_scaled' ${hte_running} hte_running_right ///
        (hte_financing_pc_1000 = hte_assignment) ///
        [aw=`kernel_weight'] if hte_primary_sample & ///
        abs(${hte_running}) < ${hte_common_h}, ///
        cluster(hte_cluster_dist) first
    local dose_rc = _rc

    local dose_estimate .
    local dose_se .
    local dose_p .
    local dose_low .
    local dose_high .
    local dose_control_sd .
    local dose_std .
    local dose_std_low .
    local dose_std_high .
    local dose_kp .
    local dose_underid .
    local dose_gate 0
    local dose_status "estimation_failed"

    if !`dose_rc' {
        local dose_estimate = _b[hte_financing_pc_1000]
        local dose_se = _se[hte_financing_pc_1000]
        capture quietly test hte_financing_pc_1000
        if !_rc local dose_p = r(p)
        local dose_low = `dose_estimate' - invnormal(.975) * `dose_se'
        local dose_high = `dose_estimate' + invnormal(.975) * `dose_se'
        capture local dose_kp = e(widstat)
        capture local dose_underid = e(idp)

        quietly summarize `y_scaled' [aw=`kernel_weight'] if ///
            hte_primary_sample & abs(${hte_running}) < ${hte_common_h} & ///
            hte_assignment == 0
        local dose_control_sd = r(sd)
        if `dose_control_sd' > 0 & `dose_control_sd' < . {
            local dose_std = `dose_estimate' / `dose_control_sd'
            local dose_std_low = `dose_low' / `dose_control_sd'
            local dose_std_high = `dose_high' / `dose_control_sd'
        }

        local dose_gate = ///
            `dose_kp' > ${hte_weak_f_gate} & ///
            `dose_underid' < .05 & `dose_underid' < .
        local dose_status = cond(`dose_gate', ///
            "exploratory_gate_pass", "exploratory_gate_fail")
    }

    post `dose_post' ///
        (`d_order_`outcome_index'') ///
        ("`d_id_`outcome_index''") ("`outcome_var'") ///
        ("`d_label_`outcome_index''") (`outcome_scale') ///
        (`dose_estimate') (`dose_se') (`dose_p') ///
        (`dose_low') (`dose_high') (`dose_control_sd') ///
        (`dose_std') (`dose_std_low') (`dose_std_high') ///
        (`dose_kp') (`dose_underid') (`dose_gate') ///
        ("`dose_status'") (`dose_rc')
}
postclose `dose_post'

use `dose_results', clear
assert _N == 8
isid outcome_id
sort pvalue
generate int dose_rank = _n if pvalue < .
egen int dose_family_n = total(pvalue < .)
generate double dose_bh_step = ///
    pvalue * dose_family_n / dose_rank if pvalue < .
gsort -pvalue
generate double adjusted_pvalue = min(dose_bh_step, 1)
replace adjusted_pvalue = ///
    min(adjusted_pvalue, adjusted_pvalue[_n - 1]) ///
    if _n > 1 & adjusted_pvalue < .
sort paper_order
drop dose_rank dose_family_n dose_bh_step
export delimited using ///
    "${hte_table_dir}/rd_hte_2017_ccpp_financing_dose_iv.csv", ///
    replace nolabel
save `dose_results', replace


*-----------------------------------*
**# 6. Extension tables and figures
*-----------------------------------*

tempfile project_jumps
use `implementation', clear
keep if strpos(component_id, "group_") == 1
generate byte prc_project_group = ///
    real(subinstr(component_id, "group_", "", .))
keep prc_project_group estimate standard_error
isid prc_project_group
save `project_jumps'

use `composition', clear
merge 1:1 prc_project_group using `project_jumps', ///
    assert(match) nogen
sort prc_project_group

tempname project_tex
file open `project_tex' using ///
    "${hte_table_dir}/tab_hte_2017_ccpp_07_project_implementation.tex", ///
    write replace text
file write `project_tex' "\begin{table}[!htbp]" _n
file write `project_tex' "\centering" _n
file write `project_tex' "\caption{Collective-reparation project implementation through 2016}" _n
file write `project_tex' "\label{tab:hte-2017-ccpp-projects}" _n
file write `project_tex' "\small" _n
file write `project_tex' "\begin{tabular}{lrrrr}" _n
file write `project_tex' "\toprule" _n
file write `project_tex' ///
    "Project group & Records & CCPPs & Share (\%) & Cutoff jump (pp) \\" _n
file write `project_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local row_label "`=project_label[`row']'"
    local row_records : display %8.0fc project_records[`row']
    local row_ccpp : display %8.0fc communities[`row']
    local row_share : display %6.1f record_share_pct[`row']
    local row_jump : display %7.2f estimate[`row']
    foreach formatted in row_records row_ccpp row_share row_jump {
        local `formatted' = strtrim("``formatted''")
    }
    file write `project_tex' ///
        "`row_label' & `row_records' & `row_ccpp' & `row_share' & `row_jump' \\" _n
}
file write `project_tex' "\bottomrule" _n
file write `project_tex' "\end{tabular}" _n
file write `project_tex' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Composition covers CMAN project records through 2016 linked to the 388-community complete Census 2017 CCPP analysis universe. A community may receive projects in more than one group. Cutoff jumps are robust bias-corrected local-linear assignment discontinuities in receipt of at least one group-specific project, using triangular weights, \(h=0.0075\), \(b=0.0135\), mass-point adjustment, and district CR2 inference. Project type is a post-assignment implementation attribute; the table does not estimate causal project-type heterogeneity. Sources: RUV, CMAN, INEI 2007 Census, and INEI-assisted Census 2017.}" _n
file write `project_tex' "\end{table}" _n
file close `project_tex'

use `dose_results', clear
sort paper_order
tempname dose_tex
file open `dose_tex' using ///
    "${hte_table_dir}/tab_hte_2017_ccpp_08_financing_dose_iv.tex", ///
    write replace text
file write `dose_tex' "\begin{table}[!htbp]" _n
file write `dose_tex' "\centering" _n
file write `dose_tex' ///
    "\caption{Exploratory IV estimates using recorded financing per resident}" _n
file write `dose_tex' "\label{tab:hte-2017-ccpp-financing-dose}" _n
file write `dose_tex' "\small" _n
file write `dose_tex' "\begin{tabular}{lrrrrrl}" _n
file write `dose_tex' "\toprule" _n
file write `dose_tex' ///
    "Outcome & Estimate & SE & 95\% CI & BH \(q\) & KP \(F\) & Gate \\" _n
file write `dose_tex' "\midrule" _n
forvalues row = 1/`=_N' {
    local row_label "`=outcome_label[`row']'"
    local row_est : display %8.2f estimate[`row']
    local row_se : display %8.2f standard_error[`row']
    local row_low : display %8.2f ci_low[`row']
    local row_high : display %8.2f ci_high[`row']
    local row_q : display %6.3f adjusted_pvalue[`row']
    local row_kp : display %7.2f kp_f[`row']
    local row_gate = cond(gate_pass[`row'] == 1, "Pass", "Fail")
    foreach formatted in row_est row_se row_low row_high row_q row_kp {
        local `formatted' = strtrim("``formatted''")
    }
    file write `dose_tex' ///
        "`row_label' & `row_est' & `row_se' & [`row_low', `row_high'] & `row_q' & `row_kp' & `row_gate' \\" _n
}
file write `dose_tex' "\bottomrule" _n
file write `dose_tex' "\end{tabular}" _n
file write `dose_tex' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} The endogenous dose is cumulative nominal CMAN financing plus recorded cofinancing through 2016 divided by 2007 CCPP population and expressed in thousands of soles per resident. Cutoff assignment instruments the dose in a triangular-weighted local-linear model with \(h=0.0075\) and district-clustered inference. The strict diagnostic gate requires Kleibergen--Paap \(F>10\) and underidentification rejection at five percent. BH \(q\) applies Benjamini--Hochberg adjustment across the eight exploratory dose outcomes. Even a passing model is exploratory: it additionally assumes a linear dose response and that assignment affects outcomes only through recorded financing, despite unmodeled project content and unverified execution. Sources: RUV, CMAN, INEI 2007 Census, and INEI-assisted Census 2017.}" _n
file write `dose_tex' "\end{table}" _n
file close `dose_tex'

capture set scheme ${graph_scheme}

use `composition', clear
graph hbar (asis) record_share_pct, ///
    over(project_label, sort(1) descending label(labsize(small))) ///
    bar(1, color(navy%82)) ///
    blabel(bar, format(%5.1f) suffix("%") size(small) color(black)) ///
    ytitle("Share of linked project records (%)") ///
    title("Collective-reparation project mix through 2016", ///
        size(medium) color(black)) ///
    subtitle("Projects linked to the complete Census 2017 CCPP analysis universe", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Unit is a CMAN project record through 2016 linked to one of 388 complete-sample RUV communities." ///
        "Categories are assigned by the versioned project-title classifier; communities may receive more than one project." ///
        "This is descriptive implementation evidence, not a causal heterogeneity estimate. Sources: RUV, CMAN, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))
graph export ///
    "${hte_figure_dir}/fig_hte_2017_ccpp_project_composition.png", ///
    width(3000) replace

use `implementation', clear
keep if strpos(component_id, "group_") == 1
sort component_id
generate int plot_y = 5 - _n
local project_ylabels
forvalues row = 1/`=_N' {
    local row_label "`=component_label[`row']'"
    local project_ylabels ///
        `"`project_ylabels' `=plot_y[`row']' "`row_label'""'
}
twoway ///
    (rcap ci_low ci_high plot_y, horizontal ///
        lcolor(navy) lwidth(medthin)) ///
    (scatter plot_y estimate, msymbol(O) mcolor(navy) msize(medsmall)), ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    ylabel(`project_ylabels', angle(horizontal) labsize(small) noticks) ///
    ytitle("") xtitle("Cutoff discontinuity (percentage points)") ///
    title("Cutoff discontinuities in project-group receipt", ///
        size(medium) color(black)) ///
    subtitle("Robust bias-corrected estimates with 95% confidence intervals", ///
        size(small) color(gs5)) ///
    legend(off) ///
    note( ///
        "Notes: Outcomes indicate receipt of at least one CMAN project in each broad group through 2016." ///
        "Local-linear RD uses h = 0.0075, b = 0.0135, triangular weights, mass-point adjustment, and district CR2 inference." ///
        "Project type is post-assignment; these are implementation discontinuities, not causal project-type effects. Sources: RUV and CMAN.", ///
        size(tiny) color(gs5) span) ///
    xsize(10) ysize(7) ///
    graphregion(color(white)) plotregion(color(white))
graph export ///
    "${hte_figure_dir}/fig_hte_2017_ccpp_project_discontinuities.png", ///
    width(3000) replace

use `dose_results', clear
sort paper_order
generate int plot_y = _N - _n + 1
local dose_ylabels
forvalues row = 1/`=_N' {
    local row_label "`=outcome_label[`row']'"
    local dose_ylabels ///
        `"`dose_ylabels' `=plot_y[`row']' "`row_label'""'
}
twoway ///
    (rcap standardized_ci_low standardized_ci_high plot_y ///
        if gate_pass == 1, horizontal lcolor(navy) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate if gate_pass == 1, ///
        msymbol(O) mcolor(navy) msize(medsmall)) ///
    (rcap standardized_ci_low standardized_ci_high plot_y ///
        if gate_pass == 0, horizontal lcolor(gs10) lwidth(medthin)) ///
    (scatter plot_y standardized_estimate if gate_pass == 0, ///
        msymbol(Oh) mcolor(gs7) msize(medsmall)), ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    ylabel(`dose_ylabels', angle(horizontal) labsize(vsmall) noticks) ///
    ytitle("") ///
    xtitle("Effect per 1,000 recorded soles per resident (control SD units)") ///
    title("Exploratory recorded-financing dose IV", ///
        size(medium) color(black)) ///
    subtitle("Local-linear IV estimates with district-clustered 95% intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "Passes diagnostic gate" 4 "Fails diagnostic gate") ///
        rows(1) position(6) size(small) region(lcolor(none))) ///
    note( ///
        "Notes: Cutoff assignment instruments cumulative nominal recorded financing through 2016 per 2007 resident." ///
        "Hollow gray estimates fail KP F > 10 or underidentification rejection and are diagnostic only." ///
        "Even passing estimates require strong linear-dose and exclusion assumptions and remain exploratory. Sources: RUV, CMAN, INEI 2007 Census, and INEI-assisted Census 2017.", ///
        size(tiny) color(gs5) span) ///
    xsize(11) ysize(8) ///
    graphregion(color(white)) plotregion(color(white))
graph export ///
    "${hte_figure_dir}/fig_hte_2017_ccpp_financing_dose_iv.png", ///
    width(3300) replace

use `ccpp_extension_base', clear
rdplot hte_financing_pc_1000 ${hte_running} ///
    if hte_primary_sample & abs(${hte_running}) < ${hte_common_h}, ///
    c(0) p(1) h(${hte_common_h} ${hte_common_h}) ///
    kernel(triangular) ci(95) ///
    graph_options( ///
        title("Assignment and recorded financing intensity", ///
            size(medium) color(black)) ///
        subtitle("Binned means and local-linear fits within the common RD window", ///
            size(small) color(gs5)) ///
        xtitle("Victimization index relative to the B-C cutoff") ///
        ytitle("Thousands of recorded soles per 2007 resident") ///
        xline(0, lcolor(maroon) lpattern(shortdash)) ///
        legend(off) ///
        note( ///
            "Notes: Unit is an RUV community in the 388-community complete Census 2017 CCPP analysis universe." ///
            "The outcome is cumulative nominal CMAN financing plus recorded cofinancing through 2016 divided by 2007 population." ///
            "The plot is a first-stage diagnostic and does not verify disbursement, execution, completion, or cofinancing realization. Sources: RUV, CMAN, and INEI 2007 Census.", ///
            size(tiny) color(gs5) span) ///
        graphregion(color(white)) plotregion(color(white)) ///
        xsize(10) ysize(7) ///
        name(hte_2017_financing_first_stage, replace))
graph export ///
    "${hte_figure_dir}/fig_hte_2017_ccpp_financing_first_stage.png", ///
    width(3000) replace


*-----------------------------------*
**# 7. Extension manifest and closeout
*-----------------------------------*

local extension_outputs ///
    output/tables/rd_heterogeneity/rd_hte_2017_ccpp_project_composition.csv ///
    output/tables/rd_heterogeneity/rd_hte_2017_ccpp_project_discontinuities.csv ///
    output/tables/rd_heterogeneity/rd_hte_2017_ccpp_financing_dose_iv.csv ///
    output/tables/rd_heterogeneity/tab_hte_2017_ccpp_07_project_implementation.tex ///
    output/tables/rd_heterogeneity/tab_hte_2017_ccpp_08_financing_dose_iv.tex ///
    output/figures/rd_heterogeneity/fig_hte_2017_ccpp_project_composition.png ///
    output/figures/rd_heterogeneity/fig_hte_2017_ccpp_project_discontinuities.png ///
    output/figures/rd_heterogeneity/fig_hte_2017_ccpp_financing_dose_iv.png ///
    output/figures/rd_heterogeneity/fig_hte_2017_ccpp_financing_first_stage.png

tempname manifest_append
file open `manifest_append' using "${hte_manifest_2017_ccpp}", ///
    write append text
foreach output_path of local extension_outputs {
    local absolute_output "${project_root}/`output_path'"
    capture confirm file "`absolute_output'"
    if _rc {
        display as error "Expected CCPP extension output was not created:"
        display as error "  `absolute_output'"
        file close `manifest_append'
        capture log close victimasrd_hte_2017_ccpp
        exit 603
    }

    quietly checksum "`absolute_output'"
    local output_checksum : display %20.0f r(checksum)
    local output_checksum = strtrim("`output_checksum'")
    local artifact_type "table"
    if strpos("`output_path'", "output/figures/") == 1 {
        local artifact_type "figure"
    }

    file write `manifest_append' ///
        `""`output_path'","`artifact_type'","14_community_registry_census_2017.dta;03_cman_projects_2023.dta","`input_datasignature'","code/stata/pipeline/05d_census2017_ccpp_heterogeneity.do","${hte_run_id}","`output_checksum'","generated_unreviewed""' _n
}
file close `manifest_append'

import delimited using "${hte_manifest_2017_ccpp}", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
isid path
assert _N == 26

display as result ///
    "Census 2017 CCPP implementation extensions completed."
display as text ///
    "Financing-dose first-stage F: `financing_stage_f'"

log close victimasrd_hte_2017_ccpp
