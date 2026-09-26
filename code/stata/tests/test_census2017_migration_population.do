/* Contract test: approved observed-migration population and retained sensitivity. */
version 19
set more off

foreach required_global in tables_root metadata_root {
    if "${`required_global'}" == "" exit 198
}

import delimited using ///
    "${tables_root}/rd_outcomes/rd_2017_individual_results.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
isid outcome_id spec_id estimator
quietly count if outcome_id == "I03" & ///
    !inlist(spec_id, "complete_case_reduced_form", ///
        "complete_case_fuzzy") & ///
    sample_rule != "selected_bc_linked_adult_migration"
assert r(N) == 0
quietly count if tier == "primary" & outcome_id != "I03" & ///
    sample_rule != "selected_bc_primary_individual"
assert r(N) == 0

quietly count if outcome_id == "I03" & ///
    spec_id == "common_h_fuzzy" & ///
    sample_rule == "selected_bc_linked_adult_migration" & ///
    n_input == 67125 & n_eff_left + n_eff_right == 7157 & ///
    ccpp_left + ccpp_right == 62 & ///
    abs(estimate_bc - 21.856) < .05 & ///
    abs(pvalue - .2698) < .001 & p_holm == 1
assert r(N) == 1

quietly count if outcome_id == "I03" & ///
    spec_id == "common_h_reduced_form" & ///
    sample_rule == "selected_bc_linked_adult_migration" & ///
    n_eff_left + n_eff_right == 7157 & ///
    abs(estimate_bc - 20.904) < .05 & ///
    abs(pvalue - .1180) < .001 & p_holm > .86
assert r(N) == 1

quietly count if outcome_id == "I03" & ///
    spec_id == "parametric_common_h" & ///
    sample_rule == "selected_bc_linked_adult_migration" & ///
    n_input == 7157 & abs(first_stage_f - 20.6546) < .1
assert r(N) == 1

quietly count if outcome_id == "D06" & ///
    spec_id == "common_h_migration_ccpp_equal" & ///
    n_eff_left + n_eff_right == 7157
assert r(N) == 1

quietly count if outcome_id == "I03" & ///
    inlist(spec_id, "complete_case_reduced_form", ///
        "complete_case_fuzzy") & ///
    sample_rule == "selected_bc_eight_outcome_complete_case" & ///
    n_input == 54317 & n_eff_left + n_eff_right == 5453
assert r(N) == 2

quietly count if outcome_id == "I03" & ///
    spec_id == "complete_case_fuzzy" & ///
    abs(estimate_bc - 45.620) < .05
assert r(N) == 1

quietly count if tier == "primary" & spec_id == "common_h_fuzzy" & ///
    multiplicity_family == "primary_2017_individual" & ///
    !missing(p_holm, q_bh)
assert r(N) == 8

import delimited using ///
    "${tables_root}/rd_mechanisms/rd_migration_mechanism_summary.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
quietly count if analysis_id == "M17I_I03" & ///
    sample_rule == "selected_bc_linked_adult_migration" & ///
    n_eff_left + n_eff_right == 7157 & ///
    abs(estimate_bc - 21.856) < .05
assert r(N) == 1

display as result "PASS: approved 2017 observed-migration population is registered end-to-end."
