/*
Project: Victimas RD
Purpose: Exercise actual production predicates against missing-value edge cases
Inputs: Versioned Stata commands only; no research observations or outputs
*/
version 19
set more off

* Read one logical command without importing or running an estimation module.
capture program drop _vrd_guard_command
program define _vrd_guard_command, rclass
    syntax using/, PREFIX(string) [SCALARS]
    tempname source
    file open `source' using "`using'", read text
    local statement ""
    local found 0
    file read `source' line
    while r(eof) == 0 {
        if strpos(strtrim(`"`line'"'), "`prefix'") == 1 local found 1
        if `found' {
            if "`scalars'" != "" {
                local line = subinstr(`"`macval(line)'"', char(96), "", .)
                local line = subinstr(`"`line'"', char(39), "", .)
            }
            local continued = strpos(`"`line'"', "///") > 0
            local statement `"`statement' `=subinstr(`"`line'"', "///", "", .)'"'
            if !`continued' continue, break
        }
        file read `source' line
    }
    file close `source'
    assert `found' == 1 & `"`statement'"' != ""
    return local statement `"`statement'"'
end

* A missing conditional F must not inherit the other instrument's strength.
_vrd_guard_command using ///
    "${project_root}/code/stata/pipeline/05a_sisfoh2013_ccpp_heterogeneity.do", ///
    prefix("local min_sw_f =") scalars
local sw_command `"`r(statement)'"'
local f_treat "12 . .a 12 12 10"
local f_interaction "15 15 15 . .z 15"
forvalues test = 1/6 {
    scalar sw_f_treat = real(word("`f_treat'", `test'))
    scalar sw_f_interaction = real(word("`f_interaction'", `test'))
    `sw_command'
    if inrange(`test', 2, 5) assert missing(`min_sw_f')
    else assert `min_sw_f' == cond(`test' == 1, 12, 10)
}
scalar drop sw_f_treat sw_f_interaction

* Ordinary and extended missing ages are not observed adults.
foreach module in 04f_census2017_individual 05f_census2017_individual_heterogeneity {
    local prefix "rd"
    if substr("`module'", 1, 3) == "05f" local prefix "hte"
    _vrd_guard_command using "${project_root}/code/stata/pipeline/`module'.do", ///
        prefix("generate byte `prefix'_migration_sample =")
    local sample_command `"`r(statement)'"'
    preserve
    clear
    set obs 8
    generate double age_2017 = 35
    replace age_2017 = 13 in 1
    replace age_2017 = 14 in 2
    replace age_2017 = . in 4
    replace age_2017 = .a in 5
    replace age_2017 = .z in 6
    generate byte census2017_linked = _n != 7
    generate byte moved_ccpp_2013_2017 = !inlist(_n, 3, 6)
    replace moved_ccpp_2013_2017 = . in 8
    generate byte `prefix'_bc_design = 1
    `sample_command'
    assert `prefix'_migration_sample == inlist(_n, 2, 3)
    restore
}
capture program drop _vrd_guard_command
display as result "PASS: production conditional-F and adult-eligibility missing guards."
