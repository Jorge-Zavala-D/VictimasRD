/* Validate separate selection denominators and noncausal feasibility products. */
version 19
set more off
local dir "${tables_root}/rd_mechanisms"
confirm file "`dir'/rd_census2017_selection_flow.csv"
import delimited "`dir'/rd_census2017_selection_flow.csv", clear varnames(1)
isid scope side stage
assert _N == 54
assert denominator_n >= numerator_n & numerator_n >= 0
assert denominator_ccpp >= numerator_ccpp & numerator_ccpp >= 0
assert inrange(rate_ccpp_equal, 0, 1)
assert inlist(scope, "selected_bc", "common_h")
assert inlist(side, "all", "below", "above")
assert numerator_n == 549 if scope == "selected_bc" & side == "all" & stage == "ruv_frame"
assert numerator_n == 71 if scope == "common_h" & side == "all" & stage == "ruv_frame"
assert numerator_n == 67648 if scope == "selected_bc" & side == "all" & stage == "adult_movement"
assert denominator_n == 110906 if scope == "selected_bc" & side == "all" & stage == "person_linkage"
assert denominator_n == 33060 if scope == "selected_bc" & side == "all" & stage == "household_complete"
import delimited "`dir'/rd_census2017_selection_overlap.csv", clear varnames(1)
isid model_id
assert _N == 3
assert estimation_rc == 0
assert inlist(model_status, "estimated", "all_complete_observed")
assert converged == 1 & n_fit == n_covariate_complete if model_status == "estimated"
assert missing(converged) & n_fit == 0 & p_min == 1 & p_max == 1 & ///
    n_selected == n_covariate_complete if model_status == "all_complete_observed"
assert n_parent >= n_covariate_complete
assert inrange(p_min, 0, 1) & inrange(p_max, 0, 1)
assert p_min <= p_p01 & p_p01 <= p_p99 & p_p99 <= p_max
assert ess_ipw > 0 & ess_ipw <= n_selected + 1e-6
assert strpos(interpretation, "diagnostic") > 0
assert causal_adjustment_approved == 0
assert ccpp_baseline_complete >= ccpp_complete_without_selected & ccpp_complete_without_selected >= 0
import delimited "`dir'/rd_census2017_selection_intervals.csv", clear varnames(1) asdouble
isid frame side
assert _N == 6
assert lower <= upper
assert inrange(lower, 0, 1) & inrange(upper, 0, 1) if side != "above_minus_below"
assert inrange(lower, -1, 1) & inrange(upper, -1, 1) if side == "above_minus_below"
assert abs(upper - lower - width) < 1e-8
assert estimand == "finite_source_cohort_description"
assert causal_late_bound == 0
assert primary_adult_target == 0
assert n_parent == n_observed + n_partly_observed + n_unobserved
assert n_partly_observed == 0 if frame == "source_people_all_ages"
* Every unknown member contributes to the source-household share interval.
preserve
use "${analysis_data_root}/13_census_2017_household_analysis.dta", clear
keep if sample_main_rd == 1 & inlist(victimization_level_source, "B", "C") & abs(running_bc) <= 0.0075
count if hh_migration_observed_2017 > 0 & hh_migration_observed_2017 < census2017_cohort_members
assert r(N) > 0
generate double source_low = hh_moved_ccpp_count_2017 / census2017_cohort_members
generate double source_high = (hh_moved_ccpp_count_2017 + census2017_cohort_members - hh_migration_observed_2017) / census2017_cohort_members
bysort ruv_id: generate double parent_weight = 1 / _N
foreach side in below above {
    quietly summarize source_low [aw = parent_weight] if cond("`side'" == "below", running_bc < 0, running_bc >= 0), meanonly
    local lower_`side' = r(mean)
    quietly summarize source_high [aw = parent_weight] if cond("`side'" == "below", running_bc < 0, running_bc >= 0), meanonly
    local upper_`side' = r(mean)
}
restore
foreach side in below above {
    assert abs(lower - `lower_`side'') < 1e-8 if frame == "source_households" & side == "`side'"
    assert abs(upper - `upper_`side'') < 1e-8 if frame == "source_households" & side == "`side'"
}
preserve
clear
input members observed movers
2 1 1
4 4 1
2 0 0
end
generate double low = movers / members
generate double high = (movers + members - observed) / members
assert low == 0.5 & high == 1 in 1
assert low == 0.25 & high == 0.25 in 2
assert low == 0 & high == 1 in 3
restore
foreach artifact in tab_rd_mechanisms_06_selection_flow.tex tab_rd_mechanisms_07_selection_feasibility.tex {
    confirm file "`dir'/`artifact'"
}
confirm file "${figures_root}/rd_mechanisms/fig_rd_mechanisms_04_selection_flow.png"
import delimited "`dir'/rd_migration_mechanism_contract.csv", clear varnames(1) bindquote(strict)
count if contract_item == "cman_year_interpretation" & status == "owner_assumption"
assert r(N) == 1
count if contract_item == "historical_date_acquisition" & value == "closed_not_required"
assert r(N) == 1
display as result "PASS: selection feasibility preserves denominators and causal boundaries."
