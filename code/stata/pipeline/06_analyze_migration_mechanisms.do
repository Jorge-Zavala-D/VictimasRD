/*
Project: Victimas RD
Purpose: Synthesize migration and mechanism evidence under the approved protocol
Inputs:  Module-04 aggregate results plus the read-only 2017 CCPP analysis data
Outputs: Aggregate CSV/LaTeX/PNG artifacts and a versioned output manifest
*/

version 19
set more off

foreach required_global in ///
    project_root pipeline_root analysis_data_root figures_root ///
    tables_root metadata_root logs_root {

    if `"${`required_global'}"' == "" {
        display as error "Required master global not defined: `required_global'"
        exit 198
    }
}

local protocol "${project_root}/docs/MIGRATION_MECHANISM_PROTOCOL.md"
local registry "${metadata_root}/rd-mechanisms/analysis-registry.csv"
local input_2017_ccpp ///
    "${analysis_data_root}/14_community_registry_census_2017.dta"
local table_dir "${tables_root}/rd_mechanisms"
local figure_dir "${figures_root}/rd_mechanisms"
local manifest "${metadata_root}/rd-mechanism-output-manifest.csv"

capture mkdir "`table_dir'"
capture mkdir "`figure_dir'"

foreach required_input in "`protocol'" "`registry'" "`input_2017_ccpp'" {
    capture confirm file "`required_input'"
    if _rc {
        display as error "Required migration/mechanism input not found:"
        display as error "  `required_input'"
        exit 601
    }
}

local source_files ///
    "rd_2013_ccpp_results.csv rd_2013_household_results.csv rd_2013_individual_results.csv rd_2017_ccpp_results.csv rd_2017_household_results.csv rd_2017_individual_results.csv"
local source_waves "2013 2013 2013 2017 2017 2017"
local source_levels "ccpp household individual ccpp household individual"
local source_manifests ///
    "rd-outcome-output-manifest.csv rd-outcome-output-manifest-2013-household.csv rd-outcome-output-manifest-2013-individual.csv rd-outcome-output-manifest-2017-ccpp.csv rd-outcome-output-manifest-2017-household.csv rd-outcome-output-manifest-2017-individual.csv"

* Validate every aggregate result against the manifest that generated it.
forvalues source_index = 1/6 {
    local source_file : word `source_index' of `source_files'
    local source_manifest : word `source_index' of `source_manifests'
    local source_relative ///
        "output/tables/rd_outcomes/`source_file'"
    local source_absolute ///
        "${project_root}/`source_relative'"
    local manifest_absolute ///
        "${metadata_root}/`source_manifest'"

    foreach required_file in ///
        "`source_absolute'" "`manifest_absolute'" {
        capture confirm file "`required_file'"
        if _rc {
            display as error "Required module-04 artifact not found:"
            display as error "  `required_file'"
            exit 601
        }
    }

    import delimited using "`manifest_absolute'", clear varnames(1) ///
        bindquote(strict) encoding(utf8)
    keep if path == "`source_relative'"
    assert _N == 1
    assert review_status == "generated_unreviewed"
    capture confirm numeric variable checksum
    if _rc {
        destring checksum, replace
    }
    local expected_checksum = checksum[1]
    quietly checksum "`source_absolute'"
    assert r(checksum) == `expected_checksum'
}

* Enforce the approved non-observation registry before reading estimates.
import delimited using "`registry'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid analysis_id
assert _N == 62
quietly count if evidence_class == "descriptive_association"
assert r(N) == 3
quietly count if evidence_class != "descriptive_association"
assert r(N) == 59
assert predictor_var != "" if evidence_class == "descriptive_association"
assert predictor_var == "" if evidence_class != "descriptive_association"
tempfile registry_all
save `registry_all'


*-----------------------------------*
**# 1. Harmonize existing RD estimates
*-----------------------------------*

tempfile harmonized_results
local first_source 1

forvalues source_index = 1/6 {
    local source_file : word `source_index' of `source_files'
    local source_wave : word `source_index' of `source_waves'
    local source_level : word `source_index' of `source_levels'

    import delimited using ///
        "${tables_root}/rd_outcomes/`source_file'", ///
        clear varnames(1) bindquote(strict) encoding(utf8)

    generate int wave = `source_wave'
    generate str12 level = "`source_level'"
    generate str64 source_result_file = "`source_file'"

    capture confirm variable weighting
    if _rc {
        generate str16 weighting = "ccpp_equal"
    }
    capture confirm variable ccpp_left
    if _rc {
        generate double ccpp_left = .
    }
    capture confirm variable ccpp_right
    if _rc {
        generate double ccpp_right = .
    }
    capture confirm variable underid_p
    if _rc {
        generate double underid_p = .
    }

    if `first_source' {
        save `harmonized_results'
        local first_source 0
    }
    else {
        append using `harmonized_results'
        save `harmonized_results', replace
    }
}

use `harmonized_results', clear
isid wave level outcome_id spec_id estimator
save `harmonized_results', replace


*-----------------------------------*
**# 2. Canonical and supporting evidence
*-----------------------------------*

use `registry_all', clear
keep if evidence_class != "descriptive_association"
rename canonical_spec spec_id

merge 1:1 wave level outcome_id spec_id source_result_file ///
    using `harmonized_results', keep(master match) ///
    keepusing(estimator estimand sample_rule weighting vce p q kernel ///
        bwselect tuning_value h_left h_right b_left b_right scale ///
        n_input n_eff_left n_eff_right ccpp_left ccpp_right clusters ///
        estimate_cl estimate_bc standard_error pvalue ci_low ci_high ///
        control_mean control_sd standardized_estimate ///
        standardized_ci_low standardized_ci_high first_stage_cl ///
        first_stage_bc first_stage_se first_stage_f weak_robust_p ///
        wild_cluster_p underid_p estimation_rc p_holm q_bh)

generate str16 analysis_status = "not_estimable"
replace analysis_status = "estimated" if _merge == 3 & estimation_rc == 0

assert _merge == 3 & estimation_rc == 0 if ///
    inlist(evidence_class, "total_migration_effect", ///
        "linkage_selection", "selection_sensitivity")

generate byte reportable_late = ///
    estimand == "fuzzy_late" & estimation_rc == 0 & ///
    !missing(first_stage_f) & first_stage_f > 10
replace reportable_late = 0 if missing(reportable_late)
assert reportable_late == 0 if estimand == "fuzzy_late" & ///
    (missing(first_stage_f) | first_stage_f <= 10)

drop _merge
sort wave level evidence_class outcome_id
isid analysis_id

order analysis_id wave level outcome_id outcome_var outcome_label ///
    family tier evidence_class timing_role treatment_var spec_id ///
    estimand_label paper_role analysis_status reportable_late ///
    estimator estimand sample_rule weighting vce

tempfile canonical_summary
save `canonical_summary'
export delimited using ///
    "`table_dir'/rd_migration_mechanism_summary.csv", ///
    replace nolabel

use `registry_all', clear
keep if evidence_class != "descriptive_association" & ///
    supporting_specs != ""
expand 2
bysort analysis_id: generate byte supporting_order = _n
generate str24 spec_id = "common_h_reduced_form" ///
    if supporting_order == 1
replace spec_id = "parametric_common_h" if supporting_order == 2

merge 1:1 wave level outcome_id spec_id source_result_file ///
    using `harmonized_results', keep(master match) ///
    keepusing(estimator estimand sample_rule weighting vce p q kernel ///
        bwselect tuning_value h_left h_right b_left b_right scale ///
        n_input n_eff_left n_eff_right ccpp_left ccpp_right clusters ///
        estimate_cl estimate_bc standard_error pvalue ci_low ci_high ///
        first_stage_f weak_robust_p wild_cluster_p underid_p ///
        estimation_rc p_holm q_bh)

replace estimator = "rdrobust" if ///
    spec_id == "common_h_reduced_form" & missing(estimator)
replace estimator = "ivreg2" if ///
    spec_id == "parametric_common_h" & missing(estimator)
assert estimator == "rdrobust" if spec_id == "common_h_reduced_form"
assert estimator == "ivreg2" if spec_id == "parametric_common_h"

generate str16 analysis_status = "not_estimable"
replace analysis_status = "estimated" if _merge == 3 & estimation_rc == 0
drop _merge supporting_order
sort analysis_id spec_id
isid analysis_id spec_id estimator
export delimited using ///
    "`table_dir'/rd_migration_mechanism_supporting.csv", ///
    replace nolabel


*-----------------------------------*
**# 3. Descriptive 2013 predictor associations with 2017 migration
*-----------------------------------*

use `registry_all', clear
keep if evidence_class == "descriptive_association"
sort analysis_id
local association_count = _N

forvalues association_index = 1/`association_count' {
    local association_id_`association_index' = ///
        analysis_id[`association_index']
    local association_predictor_`association_index' = ///
        predictor_var[`association_index']
    local association_label_`association_index' = ///
        outcome_label[`association_index']
}

tempname association_post
tempfile association_results
postfile `association_post' ///
    str16 analysis_id str40 predictor_var str80 outcome_label ///
    str24 spec_id str24 estimand ///
    double estimate standard_error pvalue ci_low ci_high ///
    n ccpp_count clusters estimation_rc ///
    using `association_results', replace

forvalues association_index = 1/`association_count' {
    local association_id "`association_id_`association_index''"
    local predictor "`association_predictor_`association_index''"
    local association_label ///
        "`association_label_`association_index''"

    use "`input_2017_ccpp'", clear
    foreach required_variable in ///
        sample_main_rd victimization_level_source running_bc ///
        census2017_cohort_covered cpv2017_share_moved_ccpp ///
        ubigeo_dist altitude_m_2017 ln_population_2007 ///
        wellbeing_core_2007 `predictor' {
        capture confirm variable `required_variable'
        if _rc {
            display as error ///
                "Required association variable not found: `required_variable'"
            exit 111
        }
    }

    generate byte rd_bc_design = sample_main_rd == 1 & ///
        inlist(victimization_level_source, "B", "C")
    generate byte above_bc = running_bc >= 0 if rd_bc_design
    encode ubigeo_dist, generate(cluster_dist)
    generate byte association_base = rd_bc_design & ///
        census2017_cohort_covered == 1 & ///
        abs(running_bc) <= 0.0075

    tempvar association_sample predictor_z cluster_tag
    generate byte `association_sample' = association_base & ///
        !missing(cpv2017_share_moved_ccpp, `predictor', ///
            running_bc, above_bc, cluster_dist, ///
            altitude_m_2017, ln_population_2007, ///
            wellbeing_core_2007)

    quietly summarize `predictor' if `association_sample'
    if r(N) == 0 | missing(r(sd)) | r(sd) <= 0 {
        display as error ///
            "Association predictor has no usable variation: `predictor'"
        exit 2000
    }
    local predictor_mean = r(mean)
    local predictor_sd = r(sd)
    generate double `predictor_z' = ///
        (`predictor' - `predictor_mean') / `predictor_sd' ///
        if `association_sample'

    quietly count if `association_sample'
    local association_n = r(N)
    local association_ccpp = r(N)
    egen byte `cluster_tag' = tag(cluster_dist) ///
        if `association_sample'
    quietly count if `cluster_tag' == 1
    local association_clusters = r(N)

    forvalues model_index = 1/2 {
        local model_spec "descriptive_unadjusted"
        local controls ""
        if `model_index' == 2 {
            local model_spec "descriptive_adjusted"
            local controls ///
                "altitude_m_2017 ln_population_2007 wellbeing_core_2007"
        }

        capture quietly regress cpv2017_share_moved_ccpp ///
            c.`predictor_z' c.running_bc##i.above_bc ///
            `controls' if `association_sample', ///
            vce(cluster cluster_dist)
        local association_rc = _rc

        local estimate = .
        local standard_error = .
        local pvalue = .
        local ci_low = .
        local ci_high = .

        if !`association_rc' {
            local estimate = _b[`predictor_z']
            local standard_error = _se[`predictor_z']
            local pvalue = 2 * ttail(e(df_r), ///
                abs(`estimate' / `standard_error'))
            local critical_value = invttail(e(df_r), 0.025)
            local ci_low = `estimate' - ///
                `critical_value' * `standard_error'
            local ci_high = `estimate' + ///
                `critical_value' * `standard_error'
        }

        post `association_post' ///
            ("`association_id'") ("`predictor'") ///
            ("`association_label'") ("`model_spec'") ///
            ("noncausal_association") ///
            (`estimate') (`standard_error') (`pvalue') ///
            (`ci_low') (`ci_high') (`association_n') ///
            (`association_ccpp') (`association_clusters') ///
            (`association_rc')
    }
}
postclose `association_post'

use `association_results', clear
assert _N == 6
isid analysis_id spec_id

preserve
keep if spec_id == "descriptive_adjusted" & !missing(pvalue)
assert _N == 3
sort pvalue
generate int bh_rank = _n
generate double q_bh = min(1, pvalue * _N / bh_rank)
gsort -bh_rank
replace q_bh = min(q_bh, q_bh[_n - 1]) if _n > 1
keep analysis_id spec_id q_bh
tempfile adjusted_qvalues
save `adjusted_qvalues'
restore

merge 1:1 analysis_id spec_id using `adjusted_qvalues', nogen
sort analysis_id spec_id
tempfile association_results_final
save `association_results_final'
export delimited using ///
    "`table_dir'/rd_migration_mechanism_associations.csv", ///
    replace nolabel


*-----------------------------------*
**# 4. Analysis contract and publication tables
*-----------------------------------*

tempname contract_file
file open `contract_file' using ///
    "`table_dir'/rd_migration_mechanism_contract.csv", ///
    write replace text
file write `contract_file' "contract_item,value,status,source" _n
file write `contract_file' ///
    `""protocol","approved","locked","docs/MIGRATION_MECHANISM_PROTOCOL.md""' _n
file write `contract_file' ///
    `""support","adjacent B/C","locked","approved protocol""' _n
file write `contract_file' ///
    `""running_variable","running_bc","locked","approved protocol""' _n
file write `contract_file' ///
    `""common_bandwidth","0.0075","locked","approved protocol""' _n
file write `contract_file' ///
    `""bias_bandwidth","0.0135","locked","approved protocol""' _n
file write `contract_file' ///
    `""treatment_2013","treat_12","locked","approved protocol""' _n
file write `contract_file' ///
    `""treatment_2017","treat_16","locked","approved protocol""' _n
file write `contract_file' ///
    `""first_stage_gate","F > 10","locked","approved protocol""' _n
file write `contract_file' ///
    `""primary_estimand","fuzzy RD LATE","locked","approved protocol""' _n
file write `contract_file' ///
    `""inference_ccpp","district clustered","locked","approved protocol""' _n
file write `contract_file' ///
    `""inference_micro","CCPP clustered with CCPP-equal weights","locked","approved protocol""' _n
file write `contract_file' ///
    `""mediation_claim","not estimated","locked","approved protocol""' _n
file write `contract_file' ///
    `""linkage_endpoints","extreme-case coding endpoints not bounds","locked","approved protocol""' _n
file write `contract_file' ///
    `""review_status","generated_unreviewed","pending review","repository policy""' _n
file close `contract_file'

* Evidence map.
use `registry_all', clear
generate byte analyses = 1
collapse (sum) analyses, by(wave level evidence_class)
sort wave level evidence_class
tempname evidence_table
file open `evidence_table' using ///
    "`table_dir'/tab_rd_mechanisms_01_evidence_map.tex", ///
    write replace text
file write `evidence_table' "\begin{table}[!htbp]" _n
file write `evidence_table' "\centering" _n
file write `evidence_table' "\small" _n
file write `evidence_table' ///
    "\caption{Migration and mechanism evidence map}" _n
file write `evidence_table' ///
    "\label{tab:rd_mechanisms_evidence_map}" _n
file write `evidence_table' "\begin{tabular}{lllr}" _n
file write `evidence_table' "\toprule" _n
file write `evidence_table' ///
    "Wave & Unit & Evidence class & Registered analyses \\" _n
file write `evidence_table' "\midrule" _n
forvalues row = 1/`=_N' {
    local row_wave : display %4.0f wave[`row']
    local row_wave = strtrim("`row_wave'")
    local row_level = proper(level[`row'])
    local row_class = ///
        proper(subinstr(evidence_class[`row'], "_", " ", .))
    local row_count : display %4.0f analyses[`row']
    local row_count = strtrim("`row_count'")
    file write `evidence_table' ///
        "`row_wave' & `row_level' & `row_class' & `row_count' \\" _n
}
file write `evidence_table' "\bottomrule" _n
file write `evidence_table' "\end{tabular}" _n
file write `evidence_table' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Registry counts distinguish total migration effects, candidate intermediate outcomes, linkage selection, extreme-case non-linkage sensitivity endpoints, and noncausal descriptive associations. RD rows use the selected adjacent B--C design, treatment through 2012 or 2016, common \(h=0.0075\) and \(b=0.0135\), and the unit-specific weighting and clustering rules. Sources: RUV, CMAN, SISFOH 2012--2013, and the INEI-assisted 2017 Census linkage.}" _n
file write `evidence_table' "\end{table}" _n
file close `evidence_table'

* Total migration effects.
use `canonical_summary', clear
keep if evidence_class == "total_migration_effect"
sort wave level outcome_id
tempname migration_table
file open `migration_table' using ///
    "`table_dir'/tab_rd_mechanisms_02_migration_effects.tex", ///
    write replace text
file write `migration_table' "\begingroup" _n
file write `migration_table' "\scriptsize" _n
file write `migration_table' ///
    "\begin{longtable}{llp{0.30\linewidth}rrrr}" _n
file write `migration_table' ///
    "\caption{Fuzzy-RD estimates of total migration outcomes}" _n
file write `migration_table' ///
    "\label{tab:rd_mechanisms_migration} \\" _n
file write `migration_table' "\toprule" _n
file write `migration_table' ///
    "Wave & Unit & Outcome & Estimate & 95\% CI & \(p\) & \(F\) \\" _n
file write `migration_table' "\midrule" _n
file write `migration_table' "\endfirsthead" _n
file write `migration_table' ///
    "\multicolumn{7}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `migration_table' "\toprule" _n
file write `migration_table' ///
    "Wave & Unit & Outcome & Estimate & 95\% CI & \(p\) & \(F\) \\" _n
file write `migration_table' "\midrule" _n
file write `migration_table' "\endhead" _n
forvalues row = 1/`=_N' {
    local row_wave : display %4.0f wave[`row']
    local row_wave = strtrim("`row_wave'")
    local row_level = proper(level[`row'])
    local row_label = outcome_label[`row']
    local row_estimate : display %7.2f estimate_bc[`row']
    local row_low : display %7.2f ci_low[`row']
    local row_high : display %7.2f ci_high[`row']
    local row_p : display %6.3f pvalue[`row']
    local row_f : display %6.2f first_stage_f[`row']
    foreach formatted_value in ///
        row_estimate row_low row_high row_p row_f {
        local `formatted_value' = strtrim("``formatted_value''")
    }
    file write `migration_table' ///
        "`row_wave' & `row_level' & `row_label' & `row_estimate' & [`row_low', `row_high'] & `row_p' & `row_f' \\" _n
}
file write `migration_table' "\bottomrule" _n
file write `migration_table' "\end{longtable}" _n
file write `migration_table' ///
    "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} Estimates are percentage-point effects. Each row is a bias-corrected local-linear fuzzy-RD estimate at the official B--C cutoff in the selected geography, using common \(h=0.0075\), \(b=0.0135\), triangular kernels, and 95\% confidence intervals. Treatment is receipt by 2012 for SISFOH 2013 and by 2016 for Census 2017. CCPP models cluster by district; household and individual models use CCPP-equal weights and CCPP clustering. Estimates with \(F\leq10\) are not interpreted as LATEs. Sources: RUV, CMAN, SISFOH 2012--2013, and INEI-assisted Census 2017 linkage.\end{minipage}" _n
file write `migration_table' "\endgroup" _n
file close `migration_table'

* Linkage discontinuities.
use `canonical_summary', clear
keep if evidence_class == "linkage_selection"
sort level
tempname linkage_table
file open `linkage_table' using ///
    "`table_dir'/tab_rd_mechanisms_03_linkage_selection.tex", ///
    write replace text
file write `linkage_table' "\begin{table}[!htbp]" _n
file write `linkage_table' "\centering\small" _n
file write `linkage_table' ///
    "\caption{Discontinuities in Census 2017 linkage}" _n
file write `linkage_table' ///
    "\label{tab:rd_mechanisms_linkage}" _n
file write `linkage_table' ///
    "\begin{tabular}{lp{0.42\linewidth}rrr}" _n
file write `linkage_table' "\toprule" _n
file write `linkage_table' ///
    "Unit & Linkage outcome & Estimate & 95\% CI & \(p\) \\" _n
file write `linkage_table' "\midrule" _n
forvalues row = 1/`=_N' {
    local row_level = proper(level[`row'])
    local row_label = outcome_label[`row']
    local row_estimate : display %7.2f estimate_bc[`row']
    local row_low : display %7.2f ci_low[`row']
    local row_high : display %7.2f ci_high[`row']
    local row_p : display %6.3f pvalue[`row']
    foreach formatted_value in row_estimate row_low row_high row_p {
        local `formatted_value' = strtrim("``formatted_value''")
    }
    file write `linkage_table' ///
        "`row_level' & `row_label' & `row_estimate' & [`row_low', `row_high'] & `row_p' \\" _n
}
file write `linkage_table' "\bottomrule" _n
file write `linkage_table' "\end{tabular}" _n
file write `linkage_table' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Estimates are percentage-point discontinuities in inclusion in the INEI-assisted 2017 linked cohort, not migration. Local-linear models use selected adjacent B--C communities, treatment through 2016, common \(h=0.0075\), \(b=0.0135\), triangular kernels, district clustering for CCPPs, CCPP-equal weighting and CCPP clustering for people, and 95\% confidence intervals. Source: RUV, CMAN, and INEI-assisted Census 2017 linkage.}" _n
file write `linkage_table' "\end{table}" _n
file close `linkage_table'

* Candidate intermediate outcomes.
use `canonical_summary', clear
keep if evidence_class == "mechanism_outcome_effect"
sort wave level outcome_id
tempname mechanism_table
file open `mechanism_table' using ///
    "`table_dir'/tab_rd_mechanisms_04_mechanism_outcomes.tex", ///
    write replace text
file write `mechanism_table' "\begingroup\scriptsize" _n
file write `mechanism_table' ///
    "\begin{longtable}{llp{0.30\linewidth}rrrr}" _n
file write `mechanism_table' ///
    "\caption{RD effects on candidate intermediate outcomes}" _n
file write `mechanism_table' ///
    "\label{tab:rd_mechanisms_outcomes} \\" _n
file write `mechanism_table' "\toprule" _n
file write `mechanism_table' ///
    "Wave & Unit & Outcome & Estimate & 95\% CI & \(p\) & \(F\) \\" _n
file write `mechanism_table' "\midrule\endfirsthead" _n
file write `mechanism_table' ///
    "\multicolumn{7}{c}{\tablename\ \thetable{} -- continued} \\" _n
file write `mechanism_table' "\toprule" _n
file write `mechanism_table' ///
    "Wave & Unit & Outcome & Estimate & 95\% CI & \(p\) & \(F\) \\" _n
file write `mechanism_table' "\midrule\endhead" _n
forvalues row = 1/`=_N' {
    local row_wave : display %4.0f wave[`row']
    local row_wave = strtrim("`row_wave'")
    local row_level = proper(level[`row'])
    local row_label = outcome_label[`row']
    local row_estimate : display %7.2f estimate_bc[`row']
    local row_low : display %7.2f ci_low[`row']
    local row_high : display %7.2f ci_high[`row']
    local row_p : display %6.3f pvalue[`row']
    local row_f : display %6.2f first_stage_f[`row']
    foreach formatted_value in ///
        row_estimate row_low row_high row_p row_f {
        local `formatted_value' = strtrim("``formatted_value''")
    }
    file write `mechanism_table' ///
        "`row_wave' & `row_level' & `row_label' & `row_estimate' & [`row_low', `row_high'] & `row_p' & `row_f' \\" _n
}
file write `mechanism_table' "\bottomrule\end{longtable}" _n
file write `mechanism_table' ///
    "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} Estimates are percentage-point effects on share, binary, or zero-to-one index outcomes. Rows are total RD effects on candidate intermediate outcomes, not indirect effects or causal mediation estimates. SISFOH 2013 outcomes follow treatment through 2012; 2017 labor and connectivity outcomes are contemporaneous with migration and may be downstream. Models use the selected adjacent B--C sample, common \(h=0.0075\), \(b=0.0135\), triangular kernels, 95\% intervals, district clustering for CCPPs, and CCPP-equal weights with CCPP clustering for household and person models. Sources: RUV, CMAN, SISFOH 2012--2013, and INEI-assisted Census 2017 linkage.\end{minipage}" _n
file write `mechanism_table' "\endgroup" _n
file close `mechanism_table'

* Noncausal descriptive associations.
use `association_results_final', clear
sort analysis_id spec_id
tempname association_table
file open `association_table' using ///
    "`table_dir'/tab_rd_mechanisms_05_descriptive_associations.tex", ///
    write replace text
file write `association_table' "\begin{table}[!htbp]" _n
file write `association_table' "\centering\small" _n
file write `association_table' ///
    "\caption{Descriptive associations with 2017 CCPP migration}" _n
file write `association_table' ///
    "\label{tab:rd_mechanisms_associations}" _n
file write `association_table' ///
    "\begin{tabular}{p{0.33\linewidth}lrrrr}" _n
file write `association_table' "\toprule" _n
file write `association_table' ///
    "Predictor & Model & Estimate & 95\% CI & \(p\) & BH \(q\) \\" _n
file write `association_table' "\midrule" _n
forvalues row = 1/`=_N' {
    local row_label = outcome_label[`row']
    local row_model = ///
        proper(subinstr(spec_id[`row'], "descriptive_", "", .))
    local row_estimate : display %7.3f estimate[`row']
    local row_low : display %7.3f ci_low[`row']
    local row_high : display %7.3f ci_high[`row']
    local row_p : display %6.3f pvalue[`row']
    local row_q "--"
    if !missing(q_bh[`row']) {
        local row_q : display %6.3f q_bh[`row']
    }
    foreach formatted_value in row_estimate row_low row_high row_p row_q {
        local `formatted_value' = strtrim("``formatted_value''")
    }
    file write `association_table' ///
        "`row_label' & `row_model' & `row_estimate' & [`row_low', `row_high'] & `row_p' & `row_q' \\" _n
}
file write `association_table' "\bottomrule\end{tabular}" _n
file write `association_table' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Coefficients are changes in the 2017 CCPP migration share (zero-to-one units) associated with a one-standard-deviation difference in each 2013 predictor. They are noncausal associations, not indirect effects. Both models use the same complete-case selected B--C Census-covered CCPP sample within \(|running\_bc|\leq0.0075\), district-clustered standard errors, and separate local-linear score slopes. Adjusted models include 2007 altitude, log population, and core wellbeing; BH correction covers the three adjusted associations. Sources: RUV, CMAN, SISFOH 2012--2013, and INEI-assisted Census 2017 linkage.}" _n
file write `association_table' "\end{table}" _n
file close `association_table'


*-----------------------------------*
**# 5. Polished evidence figures
*-----------------------------------*

use `canonical_summary', clear
keep if evidence_class == "total_migration_effect" & ///
    analysis_status == "estimated"
sort wave level outcome_id
generate str80 plot_label = outcome_label
replace plot_label = subinstr(plot_label, ///
    "Residents living in another", "Residents in another", .)
replace plot_label = subinstr(plot_label, ///
    "Members living in another", "Members in another", .)
replace plot_label = subinstr(plot_label, ///
    " five years earlier", " 5 years earlier", .)
replace plot_label = "Source HHs split across destinations" if outcome_id == "S26"
replace plot_label = "Source HH split across destination HHs" if outcome_id == "S09" & level == "household"
replace plot_label = "HH has member abroad" if outcome_id == "S39"
generate int plot_order = _N - _n + 1
capture label drop rd_migration_axis
forvalues row = 1/`=_N' {
    local axis_value = plot_order[`row']
    local row_wave : display %4.0f wave[`row']
    local row_wave = strtrim("`row_wave'")
    local row_level = proper(level[`row'])
    local row_label = plot_label[`row']
    local axis_label "`row_level': `row_label'"
    label define rd_migration_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_migration_axis
local migration_max = _N

twoway ///
    (rcap ci_low ci_high plot_order, horizontal ///
        lcolor(navy%65) lwidth(medium)) ///
    (scatter plot_order estimate_bc if reportable_late == 1, ///
        mcolor(navy) msymbol(D) msize(medium)) ///
    (scatter plot_order estimate_bc if reportable_late == 0, ///
        mcolor(gs7) msymbol(O) msize(medium)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(1(1)`migration_max', valuelabel angle(0) ///
        labsize(tiny) nogrid) ///
    xtitle("Bias-corrected fuzzy-RD effect (percentage points)", ///
        size(small)) ///
    ytitle("") ///
    title("Total migration effects across units", ///
        size(medsmall) color(black)) ///
    subtitle("Census 2017 outcomes; common B-C window and robust 95% confidence intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "F > 10" 3 "F <= 10") cols(1) ///
        position(2) ring(0) size(vsmall) region(lcolor(none))) ///
    note("Notes: Selected B/C sample; treatment through 2016; h=0.0075, b=0.0135." ///
        "CCPP models cluster by district; micro models use CCPP-equal weights and CCPP clustering." ///
        "Sources: RUV, CMAN, INEI-assisted Census 2017 linkage.", ///
        size(tiny) color(gs5) span) ///
    xsize(13) ysize(10) graphregion(color(white)) ///
    plotregion(color(white))
graph export ///
    "`figure_dir'/fig_rd_mechanisms_01_migration_forest.png", ///
    width(3200) replace

use `canonical_summary', clear
keep if level == "individual" & ///
    inlist(outcome_id, "I03", "E01", "E02") & wave == 2017
sort outcome_id
generate str52 plot_label = outcome_label
replace plot_label = "Unlinked coded as moved" if outcome_id == "E01"
replace plot_label = "Unlinked coded as not moved" if outcome_id == "E02"
replace plot_label = "Linked-sample migration" if outcome_id == "I03"
generate int plot_order = _N - _n + 1
capture label drop rd_linkage_axis
forvalues row = 1/`=_N' {
    local axis_value = plot_order[`row']
    local axis_label = plot_label[`row']
    label define rd_linkage_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_linkage_axis
local linkage_max = _N

twoway ///
    (rcap ci_low ci_high plot_order, horizontal ///
        lcolor(gs6%70) lwidth(medium)) ///
    (scatter plot_order estimate_bc ///
        if evidence_class == "total_migration_effect", ///
        mcolor(navy) msymbol(D) msize(large)) ///
    (scatter plot_order estimate_bc ///
        if evidence_class == "selection_sensitivity", ///
        mcolor(orange_red) msymbol(O) msize(medium)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(1(1)`linkage_max', valuelabel angle(0) ///
        labsize(small) nogrid) ///
    xtitle("Bias-corrected fuzzy-RD effect (percentage points)", ///
        size(small)) ///
    ytitle("") ///
    title("Migration estimate and non-linkage sensitivity endpoints", ///
        size(medsmall) color(black)) ///
    subtitle("2017 individual source cohort; robust 95% confidence intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "Linked outcome" 3 "Extreme-case endpoint") ///
        cols(1) position(2) ring(0) ///
        size(vsmall) region(lcolor(none))) ///
    note("Notes: Alternative non-linkage codings, not causal bounds; selected B/C sample." ///
        "Treatment through 2016; h=0.0075, b=0.0135; CCPP-equal weights and CCPP clustering." ///
        "Sources: RUV, CMAN, INEI-assisted Census 2017 linkage.", ///
        size(tiny) color(gs5) span) ///
    xsize(13) ysize(6.5) graphregion(color(white)) ///
    plotregion(color(white))
graph export ///
    "`figure_dir'/fig_rd_mechanisms_02_linkage_sensitivity.png", ///
    width(3200) replace

use `canonical_summary', clear
keep if evidence_class == "mechanism_outcome_effect" & ///
    inlist(tier, "primary", "mechanism") & ///
    analysis_status == "estimated"
sort wave level outcome_id
generate str80 plot_label = outcome_label
replace plot_label = "Households with internet" if outcome_id == "M01" & wave == 2013 & level == "ccpp"
replace plot_label = "Connectivity wellbeing" if outcome_label == "Connectivity wellbeing domain"
replace plot_label = "HH has internet" if inlist(outcome_label, ///
    "Household has internet access", "Household has internet")
replace plot_label = "HH has cable" if outcome_label == "Household has cable service"
replace plot_label = "Residents with HH internet" if outcome_label == "Residents exposed household internet"
replace plot_label = "Employed HH members" if outcome_label == "Employed household members"
replace plot_label = "Members with HH internet" if outcome_label == "Members exposed household internet"
replace plot_label = "Single-destination HH has internet" if outcome_label == "Single-destination household has internet"
generate int plot_order = _N - _n + 1
capture label drop rd_mechanism_axis
forvalues row = 1/`=_N' {
    local axis_value = plot_order[`row']
    local row_wave : display %4.0f wave[`row']
    local row_wave = strtrim("`row_wave'")
    local row_level = proper(level[`row'])
    local row_label = plot_label[`row']
    local axis_label "`row_wave' `row_level': `row_label'"
    label define rd_mechanism_axis ///
        `axis_value' "`axis_label'", add
}
label values plot_order rd_mechanism_axis
local mechanism_max = _N

twoway ///
    (rcap ci_low ci_high plot_order, horizontal ///
        lcolor(gs6%65) lwidth(medium)) ///
    (scatter plot_order estimate_bc if wave == 2013, ///
        mcolor(navy) msymbol(D) msize(medium)) ///
    (scatter plot_order estimate_bc if wave == 2017, ///
        mcolor(maroon) msymbol(O) msize(medium)), ///
    xline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ylabel(1(1)`mechanism_max', valuelabel angle(0) ///
        labsize(tiny) nogrid) ///
    xtitle("Bias-corrected fuzzy-RD effect (percentage points)", ///
        size(small)) ///
    ytitle("") ///
    title("Effects on primary candidate intermediate outcomes", ///
        size(medsmall) color(black)) ///
    subtitle("2013 and 2017 outcomes; robust 95% confidence intervals", ///
        size(small) color(gs5)) ///
    legend(order(2 "2013" 3 "2017") cols(1) ///
        position(2) ring(0) size(vsmall) region(lcolor(none))) ///
    note("Notes: Total effects on candidate intermediate outcomes, not indirect effects; selected B/C sample." ///
        "Common h=0.0075 and b=0.0135; CCPP models cluster by district; micro models use CCPP-equal weights and CCPP clustering." ///
        "Sources: RUV, CMAN, SISFOH, INEI-assisted Census 2017 linkage.", ///
        size(tiny) color(gs5) span) ///
    xsize(13) ysize(10) graphregion(color(white)) ///
    plotregion(color(white))
graph export ///
    "`figure_dir'/fig_rd_mechanisms_03_mechanism_forest.png", ///
    width(3200) replace


*-----------------------------------*
**# 6. Output manifest and closeout checks
*-----------------------------------*

quietly checksum "${metadata_root}/rd-outcome-output-manifest.csv"
local upstream_manifest_checksum : display %20.0f r(checksum)
local upstream_manifest_checksum = ///
    strtrim("`upstream_manifest_checksum'")

use "`input_2017_ccpp'", clear
quietly datasignature
local input_datasignature ///
    "module04:`upstream_manifest_checksum';census2017:`r(datasignature)'"

local run_id = subinstr("`c(current_date)'_`c(current_time)'", " ", "", .)
local run_id = subinstr("`run_id'", ":", "", .)

local output_paths ///
    output/tables/rd_mechanisms/rd_migration_mechanism_summary.csv ///
    output/tables/rd_mechanisms/rd_migration_mechanism_supporting.csv ///
    output/tables/rd_mechanisms/rd_migration_mechanism_associations.csv ///
    output/tables/rd_mechanisms/rd_migration_mechanism_contract.csv ///
    output/tables/rd_mechanisms/tab_rd_mechanisms_01_evidence_map.tex ///
    output/tables/rd_mechanisms/tab_rd_mechanisms_02_migration_effects.tex ///
    output/tables/rd_mechanisms/tab_rd_mechanisms_03_linkage_selection.tex ///
    output/tables/rd_mechanisms/tab_rd_mechanisms_04_mechanism_outcomes.tex ///
    output/tables/rd_mechanisms/tab_rd_mechanisms_05_descriptive_associations.tex ///
    output/figures/rd_mechanisms/fig_rd_mechanisms_01_migration_forest.png ///
    output/figures/rd_mechanisms/fig_rd_mechanisms_02_linkage_sensitivity.png ///
    output/figures/rd_mechanisms/fig_rd_mechanisms_03_mechanism_forest.png

tempname manifest_file
file open `manifest_file' using "`manifest'", write replace text
file write `manifest_file' ///
    "path,artifact_type,input_data,input_datasignature,generator,run_id,checksum,review_status" _n

foreach output_path of local output_paths {
    local absolute_output "${project_root}/`output_path'"
    capture confirm file "`absolute_output'"
    if _rc {
        display as error "Expected migration/mechanism output not created:"
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
        `""`output_path'","`artifact_type'","module-04 aggregate results;14_community_registry_census_2017.dta","`input_datasignature'","code/stata/pipeline/06_analyze_migration_mechanisms.do","`run_id'","`output_checksum'","generated_unreviewed""' _n
}
file close `manifest_file'

import delimited using "`manifest'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 12
assert review_status == "generated_unreviewed"

display as result ///
    "Completed migration and mechanism evidence synthesis."
display as text "Tables:   `table_dir'"
display as text "Figures:  `figure_dir'"
display as text "Manifest: `manifest'"
