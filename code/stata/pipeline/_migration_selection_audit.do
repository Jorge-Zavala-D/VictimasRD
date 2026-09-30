/* Selection feasibility only: no new primary estimate or causal correction. */
version 19
set more off
local dir "${tables_root}/rd_mechanisms"
local covariates "ln_population_2007 wellbeing_core_2007 ln_gdp_ccpp_2006"
local hh_outcomes "hh_share_female_2017 hh_share_age_15_29_2017 hh_share_moved_ccpp_2017 hh_share_secondary_age14_2017 hh_share_employed_age14_2017 hh_share_insured_2017 hh_share_disability_2017 hh_wellbeing_core_2017"
tempfile flow overlap intervals
tempname flow_post overlap_post interval_post
postfile `flow_post' str16 scope str8 side str24 stage str12 level ///
    str64 denominator str64 stage_label ///
    double denominator_n numerator_n denominator_ccpp numerator_ccpp ///
    rate_ccpp_equal using `flow', double
postfile `overlap_post' str24 model_id str60 denominator ///
    double n_parent n_covariate_complete n_fit n_selected ///
    estimation_rc converged p_min p_p01 p_p99 p_max ///
    n_p_below_005 ess_ipw ccpp_baseline_complete ccpp_complete_without_selected ///
    byte causal_adjustment_approved str28 model_status str48 interpretation using `overlap', double
postfile `interval_post' str24 frame str20 side ///
    double n_parent n_observed n_partly_observed n_unobserved n_ccpp lower upper width ///
    str40 estimand byte causal_late_bound primary_adult_target ///
    using `intervals', double

capture program drop _vrd_selection_flow
program define _vrd_selection_flow
    syntax, HANDLE(name) STAGE(string) LEVEL(string) ///
        PARENT(string) PASS(string) DENOMINATOR(string) LABEL(string)
    tempvar eligible passed parent_count weight tag tag_pass
    foreach scope in selected_bc common_h {
        foreach side in all below above {
            generate byte `eligible' = rd_selection_bc & (`parent')
            if "`scope'" == "common_h" ///
                replace `eligible' = 0 if abs(running_bc) > 0.0075
            if "`side'" == "below" replace `eligible' = 0 if running_bc >= 0
            if "`side'" == "above" replace `eligible' = 0 if running_bc < 0
            generate byte `passed' = `eligible' & (`pass')
            bysort ruv_id: egen long `parent_count' = total(`eligible')
            generate double `weight' = 1 / `parent_count' if `eligible'
            egen byte `tag' = tag(ruv_id) if `eligible'
            egen byte `tag_pass' = tag(ruv_id) if `passed'
            quietly count if `eligible'
            local n = r(N)
            assert `n' > 0
            quietly count if `passed'
            local pass_n = r(N)
            quietly count if `tag' == 1
            local ccpp_n = r(N)
            quietly count if `tag_pass' == 1
            local pass_ccpp = r(N)
            quietly summarize `passed' [aw = `weight'] if `eligible', meanonly
            post `handle' ("`scope'") ("`side'") ("`stage'") ("`level'") ///
                ("`denominator'") ("`label'") (`n') (`pass_n') ///
                (`ccpp_n') (`pass_ccpp') (r(mean))
            drop `eligible' `passed' `parent_count' `weight' `tag' `tag_pass'
        }
    }
end

forvalues file_index = 1/3 {
    local filename "14_community_registry_census_2017.dta"
    if `file_index' == 2 local filename "12_census_2017_individual_analysis.dta"
    if `file_index' == 3 local filename "13_census_2017_household_analysis.dta"
    local source "${analysis_data_root}/`filename'"
    quietly checksum "`source'"
    local source_checksum_`file_index' = r(checksum)
    use "`source'", clear
    generate byte rd_selection_bc = sample_main_rd == 1 & ///
        inlist(victimization_level_source, "B", "C")
    assert !missing(ruv_id, running_bc, treat_16) if rd_selection_bc
    assert (victimization_level_source == "B") == (running_bc >= 0) ///
        if rd_selection_bc
    if `file_index' == 1 {
        assert _N == 5712
        isid ruv_id
        assert inlist(census2017_cohort_covered, 0, 1)
        _vrd_selection_flow, handle(`flow_post') stage("ruv_frame") ///
            level("ccpp") parent("1") pass("1") ///
            denominator("Selected RUV communities") label("RUV community frame")
        _vrd_selection_flow, handle(`flow_post') stage("source_coverage") ///
            level("ccpp") parent("1") pass("census2017_cohort_covered == 1") ///
            denominator("Selected RUV communities") label("CCPP source-cohort entry")
        continue
    }
    encode ruv_id, generate(selection_cluster)
    generate byte above = running_bc >= 0 if rd_selection_bc
    generate double score_above = running_bc * above
    if `file_index' == 2 {
        assert _N == 193342
        isid census2017_cohort_pid
        assert inlist(census2017_linked, 0, 1)
        assert missing(age_2017) if census2017_linked == 0
        assert inlist(moved_ccpp_2013_2017, 0, 1) if !missing(moved_ccpp_2013_2017)
        _vrd_selection_flow, handle(`flow_post') stage("person_linkage") ///
            level("person") parent("1") pass("census2017_linked == 1") ///
            denominator("All source-cohort people") label("Person linkage")
        _vrd_selection_flow, handle(`flow_post') stage("person_movement") ///
            level("person") parent("1") pass("!missing(moved_ccpp_2013_2017)") ///
            denominator("All source-cohort people") label("Person movement observable")
        _vrd_selection_flow, handle(`flow_post') stage("adult_movement") ///
            level("person") parent("census2017_linked == 1 & age_2017 >= 14 & !missing(age_2017)") ///
            pass("!missing(moved_ccpp_2013_2017)") ///
            denominator("Linked known-age adults age 14 or older") label("Adult movement observable")
        _vrd_selection_flow, handle(`flow_post') stage("adult_age_unknown") ///
            level("person") parent("1") pass("missing(age_2017)") ///
            denominator("All source-cohort people") label("2017 age unobserved")
        local outcome "moved_ccpp_2013_2017"
        generate byte selection_observed = !missing(`outcome')
        generate byte selection_partial = 0
        generate double selection_lower = cond(selection_observed, `outcome', 0)
        generate double selection_upper = cond(selection_observed, `outcome', 1)
        local frame "source_people_all_ages"
        local models "person_linkage adult_movement"
    }
    else {
        assert _N == 58015
        isid census2017_baseline_hhid
        egen byte primary_missing = rowmiss(`hh_outcomes')
        generate byte household_complete = primary_missing == 0
        _vrd_selection_flow, handle(`flow_post') stage("household_linkage") ///
            level("household") parent("1") ///
            pass("hh_linked_members_2017 > 0 & !missing(hh_linked_members_2017)") ///
            denominator("All source households") label("Any household member linked")
        _vrd_selection_flow, handle(`flow_post') stage("household_complete") ///
            level("household") parent("1") pass("household_complete == 1") ///
            denominator("All source households") label("Eight-outcome household completeness")
        _vrd_selection_flow, handle(`flow_post') stage("household_movement") ///
            level("household") parent("1") pass("!missing(hh_share_moved_ccpp_2017)") ///
            denominator("All source households") label("Any member movement observed")
        * Bound all source members, not the primary observed-member share.
        assert census2017_cohort_members > 0 & !missing(census2017_cohort_members)
        assert inrange(hh_migration_observed_2017, 0, census2017_cohort_members)
        assert inrange(hh_moved_ccpp_count_2017, 0, hh_migration_observed_2017)
        generate byte selection_observed = hh_migration_observed_2017 == census2017_cohort_members
        generate byte selection_partial = hh_migration_observed_2017 > 0 & !selection_observed
        generate double selection_lower = hh_moved_ccpp_count_2017 / census2017_cohort_members
        generate double selection_upper = (hh_moved_ccpp_count_2017 + ///
            census2017_cohort_members - hh_migration_observed_2017) / census2017_cohort_members
        local frame "source_households"
        local models "household_complete"
    }

    * Binary/fractional support gives descriptive intervals, not causal RD bounds.
    assert inrange(selection_lower, 0, 1) & inrange(selection_upper, selection_lower, 1)
    foreach side in below above {
        tempvar eligible parent_count weight tag
        generate byte `eligible' = rd_selection_bc & abs(running_bc) <= 0.0075 & ///
            cond("`side'" == "below", running_bc < 0, running_bc >= 0)
        bysort ruv_id: egen long `parent_count' = total(`eligible')
        generate double `weight' = 1 / `parent_count' if `eligible'
        egen byte `tag' = tag(ruv_id) if `eligible'
        quietly count if `eligible'
        local n_`side' = r(N)
        quietly count if `eligible' & selection_observed
        local observed_`side' = r(N)
        quietly count if `eligible' & selection_partial
        local partial_`side' = r(N)
        local unobserved_`side' = `n_`side'' - `observed_`side'' - `partial_`side''
        quietly count if `tag' == 1
        local ccpp_`side' = r(N)
        quietly summarize selection_lower [aw = `weight'] if `eligible', meanonly
        local lower_`side' = r(mean)
        quietly summarize selection_upper [aw = `weight'] if `eligible', meanonly
        local upper_`side' = r(mean)
        post `interval_post' ("`frame'") ("`side'") (`n_`side'') ///
            (`observed_`side'') (`partial_`side'') (`unobserved_`side'') ///
            (`ccpp_`side'') (`lower_`side'') (`upper_`side'') ///
            (`upper_`side'' - `lower_`side'') ///
            ("finite_source_cohort_description") (0) (0)
        drop `eligible' `parent_count' `weight' `tag'
    }
    local gap_low = `lower_above' - `upper_below'
    local gap_high = `upper_above' - `lower_below'
    post `interval_post' ("`frame'") ("above_minus_below") ///
        (`n_above' + `n_below') (`observed_above' + `observed_below') ///
        (`partial_above' + `partial_below') (`unobserved_above' + `unobserved_below') ///
        (`ccpp_above' + `ccpp_below') (`gap_low') (`gap_high') ///
        (`gap_high' - `gap_low') ("finite_source_cohort_description") (0) (0)

    * Selection probability is modeled on baseline CCPP covariates only.
    foreach model of local models {
        tempvar parent response covmissing fit count weight probability ipw ///
            weight_squared selected_tag parent_tag selected_count
        generate byte `parent' = rd_selection_bc & abs(running_bc) <= 0.0135
        local denominator "All source-cohort people"
        if `file_index' == 2 generate byte `response' = census2017_linked
        else generate byte `response' = household_complete
        if "`model'" == "adult_movement" {
            replace `parent' = 0 if census2017_linked != 1 | ///
                age_2017 < 14 | missing(age_2017)
            replace `response' = !missing(moved_ccpp_2013_2017)
            local denominator "Linked known-age adults age 14 or older"
        }
        if `file_index' == 3 {
            replace `response' = household_complete
            local denominator "All source households"
        }
        egen byte `covmissing' = rowmiss(`covariates')
        generate byte `fit' = `parent' & `covmissing' == 0
        bysort ruv_id: egen long `count' = total(`fit')
        generate double `weight' = 1 / `count' if `fit'
        quietly count if `parent'
        local n_parent = r(N)
        quietly count if `fit'
        local n_complete = r(N)
        assert `n_complete' > 0
        quietly count if `fit' & `response' == 0
        local model_status "all_complete_observed"
        local converged = .
        local n_fit = 0
        if r(N) == 0 generate double `probability' = 1 if `fit'
        else {
            quietly logit `response' above running_bc score_above `covariates' ///
                [pw = `weight'] if `fit', vce(cluster selection_cluster)
            local model_status "estimated"
            local converged = e(converged)
            local n_fit = e(N)
            assert `converged' == 1 & `n_fit' == `n_complete'
            quietly predict double `probability' if e(sample), pr
            assert `probability' > 0 & `probability' < 1 if `fit'
        }
        quietly summarize `probability' if `fit', detail
        local p_min = r(min)
        local p_p01 = r(p1)
        local p_p99 = r(p99)
        local p_max = r(max)
        quietly count if `fit' & `probability' < 0.05
        local n_small = r(N)
        quietly count if `fit' & `response' == 1
        local n_selected = r(N)
        generate double `ipw' = `weight' / `probability' if `fit' & `response' == 1
        generate double `weight_squared' = `ipw'^2
        quietly summarize `ipw', meanonly
        local weight_sum = r(sum)
        quietly summarize `weight_squared', meanonly
        local ess = `weight_sum'^2 / r(sum)
        egen byte `parent_tag' = tag(ruv_id) if `fit'
        bysort ruv_id: egen long `selected_count' = total(`fit' & `response' == 1)
        quietly count if `parent_tag' == 1
        local ccpp_parent = r(N)
        quietly count if `parent_tag' == 1 & `selected_count' == 0
        local ccpp_zero = r(N)
        post `overlap_post' ("`model'") ("`denominator'") (`n_parent') ///
            (`n_complete') (`n_fit') (`n_selected') (0) (`converged') ///
            (`p_min') (`p_p01') (`p_p99') (`p_max') (`n_small') (`ess') ///
            (`ccpp_parent') (`ccpp_zero') (0) ("`model_status'") ///
            ("baseline-only feasibility diagnostic")
        drop `parent' `response' `covmissing' `fit' `count' `weight' ///
            `probability' `ipw' `weight_squared' `parent_tag' `selected_count'
    }
}
postclose `flow_post'
postclose `overlap_post'
postclose `interval_post'

use `flow', clear
sort scope side level stage
isid scope side stage
assert _N == 54
format denominator_n numerator_n denominator_ccpp numerator_ccpp %12.0f
format rate_ccpp_equal %21.15g
export delimited "`dir'/rd_census2017_selection_flow.csv", replace datafmt
tempname table
file open `table' using "`dir'/tab_rd_mechanisms_06_selection_flow.tex", write replace text
file write `table' "\begin{table}[!htbp]\centering\small" _n ///
    "\caption{Census 2017 selection stages in the fixed RD window}" _n ///
    "\label{tab:rd_mechanisms_selection_flow}" _n ///
    "\begin{tabular}{lrrr}\toprule" _n ///
    "Stage & Observed & Parent frame & CCPP-equal rate (\%) \\" _n ///
    "\midrule" _n
keep if scope == "common_h" & side == "all"
forvalues row = 1/`=_N' {
    local label = stage_label[`row']
    local n : display %9.0fc numerator_n[`row']
    local parent : display %9.0fc denominator_n[`row']
    local rate : display %5.1f 100 * rate_ccpp_equal[`row']
    file write `table' "`label' & `n' & `parent' & `rate' \\" _n
}
file write `table' "\bottomrule\end{tabular}" _n ///
    "\parbox{0.98\linewidth}{\footnotesize\textit{Notes:} Selected B/C geography, score distance at most 0.0075. Counts are unweighted; rates give each RUV community equal weight within the stated parent frame. Community entry uses all RUV communities; person linkage/movement and unknown age use all delivered source people; adult movement uses linked known-age people aged at least 14; household rows use all source households. Household completeness requires all eight registered primary outcomes. These are separate denominators, not a single attrition funnel. Source: RUV, CMAN, SISFOH and INEI-assisted Census 2017.}" _n ///
    "\end{table}" _n
file close `table'

* A single descriptive display avoids conflating measurement with a causal effect.
drop if inlist(stage, "ruv_frame", "adult_age_unknown")
generate double percent = 100 * rate_ccpp_equal
generate byte order = .
local stages "source_coverage person_linkage person_movement adult_movement household_linkage household_movement household_complete"
local labels `""Source CCPPs / RUV CCPPs" "Linked / source people" "Valid movement / source people" "Valid movement / linked adults" "Any linkage / source HH" "Any movement data / source HH" "Complete outcomes / source HH""'
forvalues row = 1/7 {
    local stage : word `row' of `stages'
    local label : word `row' of `labels'
    replace order = `row' if stage == "`stage'"
    label define selection_stage `row' "`label'", add
}
label values order selection_stage
capture findfile scheme-scientific.scheme
local scheme "s2color"
if !_rc local scheme "scientific"
graph hbar (asis) percent, over(order, label(labsize(small))) ///
    bar(1, color("44 103 153")) ///
    blabel(bar, position(inside) color(white) format(%4.1f) size(small)) ///
    ytitle("CCPP-equal proportion (%)") ylabel(0(20)100, grid glcolor(gs14)) ///
    title("Census 2017 coverage and observability", size(medsmall)) ///
    subtitle("Fixed B/C window; each row uses its own parent frame", size(small)) ///
    note("Notes: Legacy B/C geography; |score - cutoff| <= 0.0075. Adults are age 14+ with observed 2017 age." ///
         "Each row has a separate parent frame; rates weight represented RUV communities equally." ///
         "HH = source household; completeness requires all eight primary outcomes. Descriptive rates; no sampling intervals." ///
         "Sources: RUV, CMAN, SISFOH and INEI-assisted Census 2017. CCPP = centro poblado.", size(vsmall)) ///
    legend(off) graphregion(color(white)) plotregion(color(white)) ///
    xsize(10) ysize(6) scheme(`scheme')
graph export "${figures_root}/rd_mechanisms/fig_rd_mechanisms_04_selection_flow.png", width(3000) replace

use `overlap', clear
sort model_id
isid model_id
ds, has(type numeric)
format `r(varlist)' %21.15g
export delimited "`dir'/rd_census2017_selection_overlap.csv", replace datafmt
file open `table' using "`dir'/tab_rd_mechanisms_07_selection_feasibility.tex", write replace text
file write `table' "\begin{table}[!htbp]\centering\small" _n ///
    "\caption{Baseline selection-model feasibility, not causal correction}" _n ///
    "\label{tab:rd_mechanisms_selection_feasibility}" _n ///
    "\begin{tabular}{lrrrrr}\toprule" _n ///
    "Stage & Parent & Baseline complete & Probability range & IPW ESS & Empty CCPPs \\" _n ///
    "\midrule" _n
forvalues row = 1/`=_N' {
    local label "Person linkage"
    if model_id[`row'] == "adult_movement" local label "Linked-adult movement"
    if model_id[`row'] == "household_complete" local label "Household completeness"
    local parent : display %9.0fc n_parent[`row']
    local fit : display %9.0fc n_covariate_complete[`row']
    local min : display %5.3f p_min[`row']
    local max : display %5.3f p_max[`row']
    local ess : display %9.0fc ess_ipw[`row']
    local empty : display %3.0f ccpp_complete_without_selected[`row']
    file write `table' "`label' & `parent' & `fit' & [`min', `max'] & `ess' & `empty' \\" _n
}
file write `table' "\bottomrule\end{tabular}" _n ///
    "\parbox{0.98\linewidth}{\footnotesize\textit{Notes:} Logit feasibility fits use the fixed bias window (0.0135), cutoff side and side-specific linear score slopes, 2007 log population/equal-domain wellbeing and 2006 log GDP, with CCPP-equal weights and CCPP-clustered model uncertainty. Baseline-complete counts exclude missing covariates; no probabilities or weights are trimmed. Where every baseline-complete row is observed, no logit is fitted and the empirical observability probability is one. ESS is the Kish effective observation size of untrimmed CCPP-equal inverse-selection weights among selected rows, not an independent-cluster count. Empty CCPPs have no selected row within the baseline-complete model frame; CCPP counts exclude communities without complete baseline covariates. No weighted RD effect or causal adjustment is reported. Positive fitted probabilities do not prove overlap, MAR or adult transportability. Source: canonical RUV--SISFOH--Census linkage and predetermined covariates.}" _n ///
    "\end{table}" _n
file close `table'

use `intervals', clear
sort frame side
isid frame side
ds, has(type numeric)
format `r(varlist)' %21.15g
export delimited "`dir'/rd_census2017_selection_intervals.csv", replace datafmt
forvalues file_index = 1/3 {
    local filename "14_community_registry_census_2017.dta"
    if `file_index' == 2 local filename "12_census_2017_individual_analysis.dta"
    if `file_index' == 3 local filename "13_census_2017_household_analysis.dta"
    quietly checksum "${analysis_data_root}/`filename'"
    assert r(checksum) == `source_checksum_`file_index''
}
capture program drop _vrd_selection_flow
display as result "Completed Census-2017 selection feasibility; causal correction remains disabled."
