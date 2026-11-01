/*
Private corrective check, not a public-data reproduction test.
Argument: preserved 1-Nov-2026 baseline Coded directory (read-only).
Uses official cf without verbose: variable-level mismatch counts, never rows.
Run only after the master has finished writing all Coded files.
*/
version 19
set more off
args baseline_root
if `"`baseline_root'"' == "" {
    display as error "Supply the preserved baseline Coded directory."
    exit 198
}

* Only the four documented election indices have a bounded roundoff exception.
* Keys, missing codes and every other field remain exact; research files are never changed.
local election_tolerance = 1e-13
local election_fields elect_hhi_2002 elect_nep_2002 elect_hhi_2006 elect_nep_2006

tempname comparison_post roundoff_post
tempfile comparisons baseline_sorted roundoff
postfile `comparison_post' str64 dataset str32 key long rows long variables ///
    int exact_other_fields_rc double exact_other_cells double election_roundoff_cells ///
    double max_election_difference using `comparisons', replace
postfile `roundoff_post' str64 dataset str32 variable long unequal_cells ///
    double max_absolute_difference double tolerance using `roundoff', replace

foreach entry in ///
    "04_foundational_community_registry ruv_id" ///
    "05_community_registry_census2007 ruv_id" ///
    "06_community_registry_geospatial ruv_id" ///
    "07_community_registry_gdp ruv_id" ///
    "08_community_registry_elections ruv_id" ///
    "09_sisfoh_2013_individual_analysis sisfoh_pid" ///
    "10_sisfoh_2013_household_analysis sisfoh_hhid" ///
    "11_community_registry_sisfoh_2013 ruv_id" ///
    "12_census_2017_individual_analysis census2017_cohort_pid" ///
    "13_census_2017_household_analysis census2017_baseline_hhid" ///
    "14_community_registry_census_2017 ruv_id" {
    gettoken dataset key : entry
    local key = strtrim("`key'")
    use "`baseline_root'/`dataset'.dta", clear
    isid `key'
    local baseline_n = _N
    local baseline_k = c(k)
    sort `key'
    local has_elections = real(substr("`dataset'", 1, 2)) >= 8
    if `has_elections' {
        foreach variable of local election_fields {
            rename `variable' baseline_`variable'
        }
    }
    save `baseline_sorted', replace

    use "${analysis_data_root}/`dataset'.dta", clear
    isid `key'
    assert _N == `baseline_n'
    assert c(k) == `baseline_k'
    sort `key'
    local roundoff_cells = 0
    local max_election_difference = .
    local compare_variables "_all"
    if `has_elections' {
        merge 1:1 `key' using `baseline_sorted', ///
            keepusing(baseline_elect_hhi_2002 baseline_elect_nep_2002 ///
                baseline_elect_hhi_2006 baseline_elect_nep_2006) assert(match) nogen
        foreach variable of local election_fields {
            assert `variable' == baseline_`variable' ///
                if missing(`variable') | missing(baseline_`variable')
            generate double election_difference = abs(`variable' - baseline_`variable')
            assert election_difference <= `election_tolerance' ///
                if !missing(election_difference)
            quietly count if `variable' != baseline_`variable'
            local unequal_cells = r(N)
            local roundoff_cells = `roundoff_cells' + `unequal_cells'
            quietly summarize election_difference, meanonly
            local max_difference = r(max)
            local max_election_difference = max(`max_election_difference', `max_difference')
            post `roundoff_post' ("`dataset'") ("`variable'") ///
                (`unequal_cells') (`max_difference') (`election_tolerance')
            drop election_difference baseline_`variable'
        }
        quietly ds `election_fields', not
        local compare_variables "`r(varlist)'"
    }
    capture noisily cf `compare_variables' using `baseline_sorted'
    local comparison_rc = _rc
    local different_cells = real("`r(Nsum)'")
    assert inlist(`comparison_rc', 0, 9)
    if substr("`dataset'", 1, 2) < "12" assert `comparison_rc' == 0
    post `comparison_post' ("`dataset'") ("`key'") ///
        (`baseline_n') (`baseline_k') (`comparison_rc') (`different_cells') ///
        (`roundoff_cells') (`max_election_difference')
}
postclose `comparison_post'
postclose `roundoff_post'
use `comparisons', clear
assert _N == 11
export delimited using ///
    "${metadata_root}/stata-corrections-2026-11-01/dataset-comparison.csv", ///
    replace nolabel
use `roundoff', clear
assert _N == 28
export delimited using ///
    "${metadata_root}/stata-corrections-2026-11-01/election-roundoff.csv", ///
    replace nolabel

* Reconcile every non-roundoff 2017 cell against the documented roster/NBI correction.
tempname nbi_post
tempfile nbi_changes
postfile `nbi_post' str64 dataset str32 variable long changed_cells ///
    long to_missing long from_missing long changed_observed using `nbi_changes', replace
foreach entry in ///
    "12_census_2017_individual_analysis census2017_cohort_pid" ///
    "13_census_2017_household_analysis census2017_baseline_hhid" ///
    "14_community_registry_census_2017 ruv_id" {
    gettoken dataset key : entry
    local key = strtrim("`key'")
    use "${analysis_data_root}/`dataset'.dta", clear
    quietly ds *nbi*, has(type numeric)
    local nbi_candidates "`r(varlist)'"
    local nbi_fields
    foreach variable of local nbi_candidates {
        if strpos("`variable'", "2017") local nbi_fields "`nbi_fields' `variable'"
    }
    if substr("`dataset'", 1, 2) == "12" {
        local nbi_fields "`nbi_fields' cpv2017_roster_complete"
    }
    keep `key' `nbi_fields'
    isid `key'
    tempname before_frame
    tempvar baseline_link old_value
    frame create `before_frame'
    frame `before_frame': use `key' `nbi_fields' using ///
        "`baseline_root'/`dataset'.dta", clear
    frame `before_frame': isid `key'
    quietly frlink 1:1 `key', frame(`before_frame') generate(`baseline_link')
    assert !missing(`baseline_link')
    local dataset_changes = 0
    foreach variable of local nbi_fields {
        quietly frget `old_value' = `variable', from(`baseline_link')
        quietly count if `variable' != `old_value'
        local changed = r(N)
        local dataset_changes = `dataset_changes' + `changed'
        if `changed' {
            if substr("`dataset'", 1, 2) == "12" {
                if "`variable'" == "cpv2017_roster_complete" {
                    assert `variable' == 0 & `old_value' == 1 if `variable' != `old_value'
                }
                else if "`variable'" == "nbi_components_valid_2017" {
                    assert `variable' < `old_value' & !missing(`variable', `old_value') ///
                        if `variable' != `old_value'
                }
                else assert missing(`variable') & !missing(`old_value') ///
                    if `variable' != `old_value'
            }
            quietly count if missing(`variable') & !missing(`old_value')
            local to_missing = r(N)
            quietly count if !missing(`variable') & missing(`old_value')
            local from_missing = r(N)
            quietly count if !missing(`variable', `old_value') & `variable' != `old_value'
            post `nbi_post' ("`dataset'") ("`variable'") ///
                (`changed') (`to_missing') (`from_missing') (r(N))
        }
        drop `old_value'
    }
    drop `baseline_link'
    frame drop `before_frame'
    local expected_changes = cond(substr("`dataset'", 1, 2) == "12", 65, ///
        cond(substr("`dataset'", 1, 2) == "13", 2, 3))
    assert `dataset_changes' == `expected_changes'
    preserve
    use `comparisons', clear
    quietly count if dataset == "`dataset'"
    assert r(N) == 1
    assert exact_other_cells == `dataset_changes' if dataset == "`dataset'"
    restore
}
postclose `nbi_post'
use `nbi_changes', clear
isid dataset variable
assert _N == 12
export delimited using ///
    "${metadata_root}/stata-corrections-2026-11-01/nbi-dataset-changes.csv", ///
    replace nolabel

display as result "Completed keyed comparisons: only four bounded election fields exempt from exact comparison."
display as result "PASS: all non-roundoff 2017 changes reconcile to the documented roster/NBI correction."
