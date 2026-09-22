version 19
set more off

import delimited using "metadata/rd-outcome-output-manifest.csv", ///
    clear varnames(1) bindquote(strict)
assert _N == 117
isid path

* Publication tables must state the registered KP screen, not the superseded F>=20 rule.
foreach table in ///
    03_main_2013_ccpp 08_main_2013_household 13_main_2013_individual ///
    18_main_2017_ccpp 23_main_2017_household 28_main_2017_individual {
    local body = fileread("output/tables/rd_outcomes/tab_rd_outcomes_`table'.tex")
    assert strpos(`"`body'"', "geq20") == 0
    assert strpos(`"`body'"', "Kleibergen") > 0
}

foreach table in ///
    02_first_stage 07_sample_first_stage_2013_household ///
    12_sample_first_stage_2013_individual 17_first_stage_2017_ccpp ///
    22_sample_first_stage_2017_household ///
    27_sample_first_stage_2017_individual {
    local body = fileread("output/tables/rd_outcomes/tab_rd_outcomes_`table'.tex")
    assert strpos(`"`body'"', "Kleibergen") > 0
    assert strpos(`"`body'"', "F_z>10") == 0
}

* The two 2017 contracts and main tables must use the observed local samples.
foreach level in household individual {
    import delimited using ///
        "output/tables/rd_outcomes/rd_2017_`level'_analysis_contract.csv", ///
        clear varnames(1) bindquote(strict)
    local unit = cond("`level'" == "household", "households", "persons")
    local expected = cond("`level'" == "household", "2706", "5453")
    quietly count if metric == "window_`unit'" & value == "`expected'"
    assert r(N) == 1
    quietly count if metric == "window_ccpp" & value == "61"
    assert r(N) == 1
    local table = cond("`level'" == "household", "23", "28")
    local body = fileread("output/tables/rd_outcomes/tab_rd_outcomes_`table'_main_2017_`level'.tex")
    assert strpos(`"`body'"', "Common first stage") > 0
    assert strpos(`"`body'"', "& 65 ") == 0
}

* Failed dose identification cannot appear as an interpretable effect table.
import delimited using ///
    "output/tables/rd_heterogeneity/rd_hte_2013_ccpp_financing_dose_iv.csv", ///
    clear varnames(1) bindquote(strict)
assert _N == 8
assert gate_pass == 0
local body = fileread("output/tables/rd_heterogeneity/tab_hte_2013_ccpp_08_financing_dose_iv.tex")
assert strpos(`"`body'"', "Log rostered population & --") > 0

import delimited using ///
    "output/tables/rd_heterogeneity/rd_hte_2017_ccpp_financing_dose_iv.csv", ///
    clear varnames(1) bindquote(strict)
assert _N == 8
assert adjusted_pvalue >= .05 if adjusted_pvalue < .

display as result "PASS: publication repair contracts"
