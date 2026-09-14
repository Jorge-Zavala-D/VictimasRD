/*
Project: Victimas RD
Purpose: Guard the shared household/individual heterogeneity engine against
         wave-specific treatment, registry, title, and source assumptions
*/

version 19
set more off

capture confirm file "${project_root}/code/stata/pipeline/_heterogeneity_level_engine.do"
if _rc {
    display as error "Shared heterogeneity engine was not found."
    exit 601
}

local engine_path ///
    "${project_root}/code/stata/pipeline/_heterogeneity_level_engine.do"

mata:
void check_wave_contract(string scalar engine_path)
{
    real scalar handle, index, failed
    string scalar line, source
    string rowvector forbidden, required

    handle = fopen(engine_path, "r")
    if (handle < 0) {
        errprintf("Unable to read shared heterogeneity engine.\n")
        _error(601)
    }

    source = ""
    while ((line = fget(handle)) != J(0, 0, "")) {
        source = source + line + char(10)
    }
    fclose(handle)

    forbidden = (char(36) + "{hte_treatment_2013}", ///
        "moderator_var_2013", "SISFOH 2013", "SISFOH 2012-2013", ///
        "SISFOH 2012--2013", "through 2012", "treat_12", ///
        "SISFOH people")
    required = (char(36) + "{hte_treatment}", ///
        char(36) + "{hte_moderator_var_column}", ///
        char(36) + "{hte_wave_label}", ///
        char(36) + "{hte_source_note}", ///
        char(36) + "{hte_source_note_tex}", ///
        char(36) + "{hte_treatment_timing_label}", ///
        char(36) + "{hte_person_source_label}")

    failed = 0
    for (index = 1; index <= cols(forbidden); index++) {
        if (strpos(source, forbidden[index]) > 0) {
            errprintf("Wave-specific token remains in shared engine: %s\n", ///
                forbidden[index])
            failed = 1
        }
    }
    for (index = 1; index <= cols(required); index++) {
        if (strpos(source, required[index]) == 0) {
            errprintf("Required wave-neutral token is absent: %s\n", ///
                required[index])
            failed = 1
        }
    }

    if (failed) {
        _error(9)
    }
}

check_wave_contract(st_local("engine_path"))
end

display as result "PASS: shared heterogeneity engine is wave-neutral."
