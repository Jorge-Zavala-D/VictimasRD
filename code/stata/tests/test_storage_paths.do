/*
Purpose: Reject unsafe storage contracts without creating directories or data.
Run through Stata MCP after the master defines project_root.
*/
version 19
local source_root "${project_root}"
capture confirm file "`source_root'/code/stata/lib/00_validate_storage.do"
assert _rc == 0
do "`source_root'/code/stata/lib/00_validate_storage.do"

local roots project_root data_root raw_root working_root coded_root ///
    pipeline_working_root intermediate_root staging_root qa_data_root ///
    external_derived_root analysis_data_root external_raw_root ///
    legacy_working_root legacy_coded_root build_root output_root ///
    figures_root tables_root metadata_root logs_root
foreach root of local roots {
    local saved_`root' "${`root'}"
}

forvalues case = 0/14 {
    global project_root "C:/fixture/repository"
    global data_root "C:/fixture/dropbox/data"
    global raw_root "${data_root}/Raw"
    global working_root "${data_root}/Working"
    global coded_root "${data_root}/Coded"
    global pipeline_working_root "${working_root}/Current"
    global analysis_data_root "${coded_root}/Current"
    global legacy_working_root "${working_root}/Archive"
    global legacy_coded_root "${coded_root}/Archive"
    global build_root "${project_root}/build"
    global output_root "${project_root}/output"
    global figures_root "${output_root}/figures"
    global tables_root "${output_root}/tables"
    global metadata_root "${project_root}/metadata"
    global logs_root "${project_root}/logs"
    global external_raw_root "${raw_root}/External"

    if `case' == 1 {
        global working_root "${raw_root}"
        global pipeline_working_root "${working_root}/Current"
        global legacy_working_root "${working_root}/Archive"
    }
    if `case' == 2 global pipeline_working_root "${legacy_working_root}"
    if `case' == 3 global analysis_data_root "${project_root}/datasets"
    if `case' == 4 global pipeline_working_root "${working_root}/Current/../../Raw"
    if `case' == 5 global working_root "${data_root}/working/"
    if `case' == 6 global project_root "${data_root}/repository"
    if `case' == 7 global coded_root "${working_root}"
    if `case' == 8 global build_root "${data_root}/build"
    if `case' == 9 global working_root "${data_root}/raw/"
    if `case' == 10 global working_root "${data_root}//Raw"
    if `case' == 11 global figures_root "${raw_root}/figures"
    if `case' == 12 global working_root "${raw_root}."
    if `case' == 13 global working_root "${raw_root} "
    if inlist(`case', 12, 13) {
        global pipeline_working_root "${working_root}/Current"
        global legacy_working_root "${working_root}/Archive"
    }
    if `case' == 14 {
        global data_root "${project_root}."
        global raw_root "${data_root}/Raw"
        global working_root "${data_root}/Working"
        global coded_root "${data_root}/Coded"
        global pipeline_working_root "${working_root}/Current"
        global analysis_data_root "${coded_root}/Current"
        global legacy_working_root "${working_root}/Archive"
        global legacy_coded_root "${coded_root}/Archive"
        global external_raw_root "${raw_root}/External"
    }

    global intermediate_root "${pipeline_working_root}/intermediate"
    global staging_root "${pipeline_working_root}/staging"
    global qa_data_root "${pipeline_working_root}/qa"
    global external_derived_root "${pipeline_working_root}/external"

    capture noisily victimasrd_validate_storage
    local test_rc = _rc
    if inlist(`case', 0, 5) assert `test_rc' == 0
    else assert `test_rc' == 198
}
foreach root of local roots {
    global `root' "`saved_`root''"
}
capture program drop victimasrd_validate_storage
display as result "PASS: valid paths accepted; Raw/archive/Git/traversal rejected before writes."

