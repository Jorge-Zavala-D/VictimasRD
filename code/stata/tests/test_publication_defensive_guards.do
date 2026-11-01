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
        if strpos(strtrim(`"`macval(line)'"'), "`prefix'") == 1 local found 1
        if `found' {
            if "`scalars'" != "" {
                local line = subinstr(`"`macval(line)'"', char(96), "", .)
                local line = subinstr(`"`line'"', char(39), "", .)
            }
            local continued = strpos(`"`macval(line)'"', "///") > 0
            local cleanline = subinstr(`"`macval(line)'"', "///", "", .)
            local statement `"`macval(statement)' `macval(cleanline)'"'
            if !`continued' continue, break
        }
        file read `source' line
    }
    file close `source'
    assert `found' == 1 & strtrim(`"`macval(statement)'"') != ""
    return local statement `"`macval(statement)'"'
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

* A strong diagnostic cannot rescue a failed or undefined interaction fit.
local saved_hte_gate "${hte_weak_f_gate}"
global hte_weak_f_gate 10
foreach module in 05a_sisfoh2013_ccpp_heterogeneity _heterogeneity_level_engine {
    _vrd_guard_command using "${project_root}/code/stata/pipeline/`module'.do", ///
        prefix("local gate_pass =") scalars
    local gate_command `"`r(statement)'"'
    forvalues case = 1/5 {
        scalar support_pass = 1
        scalar min_sw_f = 12
        scalar underid_p = .01
        scalar estimation_rc = cond(`case' == 2, 504, 0)
        scalar estimate = cond(`case' == 3, ., .2)
        scalar standard_error = cond(`case' == 4, 0, .1)
        scalar pvalue = .04
        scalar ci_low = -.1
        scalar ci_high = cond(`case' == 5, .a, .5)
        `gate_command'
        assert `gate_pass' == (`case' == 1)
    }
}
global hte_weak_f_gate "`saved_hte_gate'"
scalar drop support_pass min_sw_f underid_p estimation_rc estimate ///
    standard_error pvalue ci_low ci_high

* Conditional lincom inference must be valid independently of the parent gate.
foreach module in 05a_sisfoh2013_ccpp_heterogeneity _heterogeneity_level_engine {
    _vrd_guard_command using "${project_root}/code/stata/pipeline/`module'.do", ///
        prefix("local conditional_valid =") scalars
    local conditional_command `"`r(statement)'"'
    forvalues case = 1/6 {
        scalar conditional_rc = cond(`case' == 2, 198, 0)
        scalar conditional_estimate = cond(`case' == 3, ., .2)
        scalar conditional_se = cond(`case' == 4, 0, cond(`case' == 6, .a, .1))
        scalar conditional_p = .04
        scalar conditional_low = cond(`case' == 5, .z, -.1)
        scalar conditional_high = .5
        `conditional_command'
        assert `conditional_valid' == (`case' == 1)
    }
}
scalar drop conditional_rc conditional_estimate conditional_se ///
    conditional_p conditional_low conditional_high

* Contracts must not describe a missing ordinary/extended F as a passing gate.
local saved_rd_gate "${rd_weak_f_gate}"
global rd_weak_f_gate 10
foreach module in 04a_sisfoh2013_ccpp 04b_sisfoh2013_household ///
    04c_sisfoh2013_individual 04d_census2017_ccpp ///
    04e_census2017_household 04f_census2017_individual {
    _vrd_guard_command using "${project_root}/code/stata/pipeline/`module'.do", ///
        prefix("local kp_status =") scalars
    local kp_command `"`r(statement)'"'
    foreach value in . .a .z 10 10.01 {
        scalar kp_f_main = `value'
        `kp_command'
        assert "`kp_status'" == cond(!missing(`value') & `value' > 10, "pass", "warning")
    }
}
global rd_weak_f_gate "`saved_rd_gate'"
scalar drop kp_f_main

* The second binary evaluation is the 1 endpoint, not the unused median slot.
local modtype "binary"
local eval1 0
local eval2 .
local eval3 1
forvalues value_index = 1/2 {
    _vrd_guard_command using "${project_root}/code/stata/pipeline/05a_sisfoh2013_ccpp_heterogeneity.do", ///
        prefix("local eval_index =")
    `r(statement)'
    _vrd_guard_command using "${project_root}/code/stata/pipeline/05a_sisfoh2013_ccpp_heterogeneity.do", ///
        prefix("local eval_value =")
    `r(statement)'
    assert `eval_value' == `value_index' - 1
}

* A partially missing financing history must stop before aggregation.
preserve
clear
set obs 3
generate double prc_total_financing_soles = 100000
_vrd_guard_command using "${project_root}/code/stata/pipeline/05a_sisfoh2013_ccpp_heterogeneity.do", ///
    prefix("assert prc_total_financing_soles >")
local financing_assert `"`r(statement)'"'
`financing_assert'
replace prc_total_financing_soles = .a in 2
capture `financing_assert'
assert _rc == 9
restore

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
* Raw items cannot make an unknown-age respondent age-eligible.
preserve
clear
set obs 7
generate int age_2013 = .
replace age_2013 = .a in 2
replace age_2013 = .z in 3
replace age_2013 = 2 in 4
replace age_2013 = 3 in 5
replace age_2013 = 14 in 6
replace age_2013 = 120 in 7
generate int age_2017 = age_2013
generate byte IDIOMA01 = 1
generate byte c5_p11 = 1
generate byte literate_2017 = 1
foreach outcome in language_childhood_2013 language_childhood_2017 literate_age14_2017 {
    _vrd_guard_command using "${project_root}/code/stata/pipeline/01_data_preparation.do", ///
        prefix("generate byte `outcome' =")
    `r(statement)'
    assert missing(`outcome') if missing(age_2013)
    assert !missing(`outcome') in 6/7
}
generate int edad01 = 100 + _n - 1
replace edad01 = 120 in 6
replace edad01 = . in 7
_vrd_guard_command using "${project_root}/code/stata/pipeline/01_data_preparation.do", ///
    prefix("generate int sisfoh_age_key =")
`r(statement)'
assert sisfoh_age_key == edad01
restore

* Same pathname is not evidence that the reviewed contents are unchanged.
preserve
clear
set obs 4
generate double checksum = 100
generate double reviewed_checksum = 100
replace reviewed_checksum = 101 in 2
replace reviewed_checksum = . in 3
replace checksum = .a in 4
_vrd_guard_command using "${project_root}/code/stata/pipeline/07_build_tables_figures.do", ///
    prefix("generate byte review_matches_current =")
`r(statement)'
assert review_matches_current == (_n == 1)

* Stale upstream estimates must fail even when their own files are intact.
local module04_checksum "123"
generate str80 input_datasignature = "module04:123;census2017:fixture"
_vrd_guard_command using "${project_root}/code/stata/pipeline/07_build_tables_figures.do", ///
    prefix("assert strpos(input_datasignature,")
local freshness_assert `"`r(statement)'"'
`freshness_assert'
replace input_datasignature = "module04:124;census2017:fixture" in 1
capture `freshness_assert'
assert _rc == 9

* Invalid approval values must never fall through to a release PASS.
generate byte owner_approved = 0
_vrd_guard_command using "${project_root}/code/stata/pipeline/08_run_release_checks.do", ///
    prefix("assert inlist(owner_approved,")
local approval_assert `"`r(statement)'"'
`approval_assert'
foreach invalid in . .a .z 2 {
    replace owner_approved = `invalid' in 1
    capture `approval_assert'
    assert _rc == 9
}
restore
capture program drop _vrd_guard_command
display as result "PASS: finite-F, age, review-identity, freshness and approval guards."
