/*------------------------------------------------------------------------------
| Title:            National and main-sample descriptive analysis              |
| Project:          Victimas RD                                                |
| Unit:             RUV centro poblado                                         |
| Input:            07_community_registry_gdp.dta                              |
| Outputs:          Aggregate tables, figures, and output manifest             |
| Description:      Describes the complete RUV universe and the research-team- |
|                   selected legacy RD geography without estimating effects.   |
-------------------------------------------------------------------------------*/

version 19
set more off


*-----------------------------------*
**# 1. Input and output contracts
*-----------------------------------*

foreach required_global in ///
    project_root ///
    data_root ///
    intermediate_root ///
    analysis_data_root ///
    figures_root ///
    tables_root ///
    metadata_root {

    if `"${`required_global'}"' == "" {
        display as error "Required project global is unavailable: `required_global'"
        display as error "Run this module through code/stata/00_master.do."
        exit 198
    }
}

local input_file ///
    "${analysis_data_root}/07_community_registry_gdp.dta"
local project_input_file ///
    "${intermediate_root}/03_cman_projects_2023.dta"
local figure_dir "${figures_root}/descriptive"
local table_dir  "${tables_root}/descriptive"
local manifest  "${metadata_root}/output-manifest.csv"
local department_map_data   "${data_root}/data_dpto.dta"
local department_map_coords "${data_root}/coor_dpto.dta"
local province_map_data     "${data_root}/data_prov.dta"
local province_map_coords   "${data_root}/coor_prov.dta"

capture confirm file "`input_file'"

if _rc {
    display as error "Canonical descriptive input was not found:"
    display as error "  `input_file'"
    exit 601
}

capture confirm file "`project_input_file'"

if _rc {
    display as error "Canonical CMAN project registry was not found:"
    display as error "  `project_input_file'"
    exit 601
}

foreach output_directory in "`figure_dir'" "`table_dir'" {
    capture mkdir "`output_directory'"

    if !direxists("`output_directory'") {
        display as error "Could not create descriptive output directory:"
        display as error "  `output_directory'"
        exit 603
    }
}

local output_paths ///
    output/figures/descriptive/fig_desc_01_victimization_index.png ///
    output/figures/descriptive/fig_desc_02_victimization_components.png ///
    output/figures/descriptive/fig_desc_03_treatment_rollout.png ///
    output/figures/descriptive/fig_desc_04_treatment_by_category.png ///
    output/figures/descriptive/fig_desc_05_score_treatment_profile.png ///
    output/figures/descriptive/fig_desc_06_department_profile.png ///
    output/figures/descriptive/fig_desc_07_data_coverage.png ///
    output/figures/descriptive/fig_desc_08_baseline_wellbeing.png ///
    output/figures/descriptive/fig_desc_09_wellbeing_by_category.png ///
    output/figures/descriptive/fig_desc_10_geospatial_context.png ///
    output/figures/descriptive/fig_desc_11_spatial_distribution.png ///
    output/figures/descriptive/fig_desc_12_map_victimized_communities.png ///
    output/figures/descriptive/fig_desc_13_map_treated_communities.png ///
    output/figures/descriptive/fig_desc_14_map_treatment_share.png ///
    output/figures/descriptive/fig_desc_15_map_victimization_index.png ///
    output/figures/descriptive/fig_desc_16_project_types.png ///
    output/figures/descriptive/fig_desc_17_project_cofinancing.png ///
    output/figures/descriptive/fig_desc_18_project_financing_over_time.png ///
    output/figures/descriptive/fig_desc_19_project_composition_over_time.png ///
    output/tables/descriptive/tab_desc_01_sample_coverage.tex ///
    output/tables/descriptive/tab_desc_02_summary_statistics.tex ///
    output/tables/descriptive/tab_desc_03_victimization_categories.tex ///
    output/tables/descriptive/tab_desc_04_treatment_rollout.tex ///
    output/tables/descriptive/tab_desc_05_department_profile.tex ///
    output/tables/descriptive/tab_desc_06_project_types_financing.tex ///
    output/tables/descriptive/tab_desc_07_project_financing_by_year.tex ///
    output/tables/descriptive/tab_desc_08_project_composition_periods.tex ///
    output/figures/descriptive/fig_desc_20_treatment_by_category_over_time.png ///
    output/tables/descriptive/rd_rollout_category_year.csv ///
    output/tables/descriptive/tab_desc_09_treatment_by_category_over_time.tex ///
    output/figures/descriptive/fig_desc_21_main_rd_sample_map.png ///
    output/figures/descriptive/fig_desc_22_main_rd_sample_profile.png ///
    output/tables/descriptive/rd_main_sample_geographic_profile.csv ///
    output/tables/descriptive/rd_main_sample_comparison.csv ///
    output/tables/descriptive/tab_desc_10_main_rd_sample_profile.tex ///
    output/tables/descriptive/tab_desc_11_main_rd_sample_comparison.tex

/*
Remove only this module's exact generated products. This prevents an interrupted
run from validating a stale table or figure as a current output.
*/
foreach output_path of local output_paths {
    capture erase "${project_root}/`output_path'"
}
capture erase "`manifest'"

foreach boundary_file in ///
    "`department_map_data'" ///
    "`department_map_coords'" ///
    "`province_map_data'" ///
    "`province_map_coords'" {

    capture confirm file "`boundary_file'"

    if _rc {
        display as error "The preserved department boundary input was not found:"
        display as error "  `boundary_file'"
        exit 601
    }
}

quietly checksum "`department_map_data'"
assert r(checksum) == 2990936360
assert r(filelen) == 5885
quietly checksum "`department_map_coords'"
assert r(checksum) == 3955920608
assert r(filelen) == 4996565
quietly checksum "`province_map_data'"
assert r(checksum) == 3172781531
assert r(filelen) == 27149
quietly checksum "`province_map_coords'"
assert r(checksum) == 2826354662
assert r(filelen) == 11933505

use "`input_file'", clear

isid ruv_id
assert _N == 5712
assert !missing(victimization_index)
assert inlist(victimization_level_source, "A", "B", "C", "D", "E")
assert victimization_index >= 0
assert inlist(ubigeo_ccpp_verified, 0, 1)
assert inlist(census2007_linked, 0, 1)
assert inlist(geospatial_linked, 0, 1)
assert inlist(sample_main_rd, 0, 1)
assert sample_main_rd == ( ///
    inlist(substr(ubigeo_dist, 1, 2), "03", "09") | ///
    inlist(substr(ubigeo_dist, 1, 4), "0809", "1201"))

local previous_treatment

forvalues year = 2007/2023 {
    local yy = substr("`year'", 3, 2)
    confirm variable treat_`yy'
    assert inlist(treat_`yy', 0, 1)

    if `"`previous_treatment'"' != "" {
        assert treat_`yy' >= `previous_treatment'
    }

    local previous_treatment treat_`yy'
}

assert treat_23 == !missing(recorded_project_year)
assert inrange(recorded_project_year, 2007, 2023) ///
    if !missing(recorded_project_year)
assert !missing(prc_project_type, prc_project_group) if ///
    prc_project_observed
assert missing(prc_project_type) & ///
    missing(prc_project_group) if !prc_project_observed
assert inlist(prc_project_multisector, 0, 1) if ///
    prc_project_observed
assert inlist(prc_cofinanced, 0, 1) if ///
    prc_project_observed

foreach cutoff_check in ///
    "running_ab victimization_index 0.153750" ///
    "running_bc victimization_index 0.062320" ///
    "running_cd victimization_index 0.026930" ///
    "running_de victimization_index 0.015220" {

    gettoken running_variable cutoff_check : cutoff_check
    gettoken score_variable cutoff_check : cutoff_check
    gettoken cutoff_value cutoff_check : cutoff_check
    assert abs(`running_variable' - (`score_variable' - `cutoff_value')) < 1e-12
}

quietly datasignature
local input_datasignature "`r(datasignature)'"
local n_ruv = _N

quietly count if ubigeo_ccpp_verified == 1
local n_ubigeo = r(N)
quietly count if prc_project_observed == 1
local n_treated_2023 = r(N)
quietly count if prc_project_observed == 0
local n_not_recorded_2023 = r(N)
quietly count if census2007_linked == 1
local n_census = r(N)
quietly count if !missing(wellbeing_core_2007)
local n_wellbeing = r(N)
quietly count if geospatial_linked == 1
local n_spatial = r(N)
quietly count if !missing(altitude_m_2017)
local n_altitude = r(N)
quietly count if sample_main_rd
local n_main_rd = r(N)
local n_outside_main_rd = `n_ruv' - `n_main_rd'

assert `n_treated_2023' == 4221
assert `n_not_recorded_2023' == 1491
assert `n_treated_2023' + `n_not_recorded_2023' == `n_ruv'
assert `n_main_rd' == 1162
assert `n_outside_main_rd' == 4550

local graph_scheme "${graph_scheme}"

if `"`graph_scheme'"' == "" {
    local graph_scheme "stcolor"
}

capture set scheme `graph_scheme'

if _rc {
    set scheme stcolor
    local graph_scheme "stcolor"
}

/*
Labels are changed only in memory. The analytical dataset is never saved by
this module.
*/
label variable victimization_index      "Victimization index"
label variable deaths                   "Deaths"
label variable disappearances           "Disappearances"
label variable torture                  "Torture"
label variable disabilities             "Disabilities"
label variable widowed                  "Widowed persons"
label variable orphaned                 "Orphaned persons"
label variable undocumented             "Undocumented persons"
label variable displaced                "Displaced persons"
label variable authorities_killed       "Authorities killed"
label variable authorities_disappeared  "Authorities disappeared"
label variable authorities_displaced    "Authorities displaced"
label variable organizations_affected   "Organizations affected"
label variable family_assets_destroyed  "Family assets destroyed"
label variable community_assets_destroyed "Community assets destroyed"
label variable incursions               "Incursions"
label variable population_2007          "Population (2007)"
label variable households_2007          "Households (2007)"
label variable wellbeing_core_2007      "Baseline wellbeing score (2007)"
label variable altitude_m_2017          "Altitude (meters)"
label variable dist_dist_capital_km     "Corresponding district capital"
label variable dist_prov_capital_km     "Corresponding province capital"
label variable dist_dept_capital_km     "Corresponding department capital"
label variable dist_nearest_city_km     "Nearest CCPP categorized as city"

generate byte priority_ab = ///
    inlist(victimization_level_source, "A", "B")
label variable priority_ab "RUV category A or B"


*-----------------------------------*
**# 2. Victimization distributions
*-----------------------------------*

quietly summarize victimization_index, detail
local score_max = ceil(r(max) * 2) / 2

histogram victimization_index, ///
    start(0) width(0.025) frequency ///
    fcolor(navy%65) lcolor(navy) lwidth(vthin) ///
    xscale(range(0 `score_max')) ///
    xlabel(0(0.5)`score_max', format(%3.1f) labsize(small)) ///
    ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Victimization index (observed RUV score)", size(small)) ///
    ytitle("Number of communities", size(small)) ///
    title("Full observed support", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_index_full, replace)

histogram victimization_index if victimization_index <= 0.20, ///
    start(0) width(0.002) frequency ///
    fcolor(teal%65) lcolor(teal) lwidth(vthin) ///
    xline(0.015220 0.026930 0.062320 0.153750, ///
        lcolor(gs7) lpattern(dash) lwidth(thin)) ///
    xlabel(0 "0" 0.015220 "D-E" 0.026930 "C-D" ///
        0.062320 "B-C" 0.153750 "A-B" 0.20 ".20", ///
        angle(45) labsize(vsmall)) ///
    ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Victimization index and official category boundaries", size(small)) ///
    ytitle("Number of communities", size(small)) ///
    title("Policy-threshold detail", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_index_zoom, replace)

graph combine desc_index_full desc_index_zoom, ///
    cols(2) xsize(12) ysize(5.8) ///
    title("Distribution of the victimization index", ///
        size(medium) color(black)) ///
    subtitle("Panel A retains all scores; Panel B magnifies the official thresholds", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado (N = 5,712). Panel A uses the complete, uncropped score support;" ///
        "Panel B is a magnified view through 0.20 and does not alter the underlying data. Dashed lines mark the official A-B, B-C, C-D, and D-E thresholds." ///
        "No model or statistical uncertainty is reported. Source: RUV Libro Segundo and the official government victimization-index methodology.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_01_victimization_index.png", ///
    width(2800) replace
graph drop desc_index_full desc_index_zoom

tempfile component_statistics
tempname component_post
postfile `component_post' ///
    str40 component double share_positive ///
    using "`component_statistics'", replace

local victim_components ///
    deaths ///
    disappearances ///
    torture ///
    disabilities ///
    widowed ///
    orphaned ///
    undocumented ///
    displaced ///
    authorities_killed ///
    authorities_disappeared ///
    authorities_displaced ///
    organizations_affected ///
    family_assets_destroyed ///
    community_assets_destroyed ///
    incursions

foreach component_variable of local victim_components {
    quietly count if `component_variable' > 0 & !missing(`component_variable')
    local component_share = 100 * r(N) / `n_ruv'
    local component_label : variable label `component_variable'
    post `component_post' ("`component_label'") (`component_share')
}
postclose `component_post'

preserve
use "`component_statistics'", clear

graph hbar (asis) share_positive, ///
    over(component, sort(1) descending label(labsize(vsmall))) ///
    bar(1, color(navy%75) lcolor(navy)) ///
    blabel(bar, format(%4.1f) position(outside) size(vsmall) color(gs4)) ///
    yscale(range(0 100)) ///
    ylabel(0(20)100, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Communities reporting a positive value (%)", size(small)) ///
    title("Recorded victimization components", size(medium) color(black)) ///
    subtitle("Prevalence of positive component values in the complete RUV universe", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado (N = 5,712)." ///
        "Each bar is the share with a raw component value greater than zero." ///
        "Component magnitudes are not compared because their units differ." ///
        "These are administrative descriptions with no sampling uncertainty." ///
        "Source: RUV Libro Segundo.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) plotregion(color(white)) ///
    ysize(7.5) xsize(9)

graph export ///
    "`figure_dir'/fig_desc_02_victimization_components.png", ///
    width(2400) replace
restore


*-----------------------------------*
**# 3. Treatment rollout
*-----------------------------------*

preserve
keep if !missing(recorded_project_year)
contract recorded_project_year
rename _freq newly_treated
sort recorded_project_year
generate long cumulative_treated = sum(newly_treated)
generate double cumulative_share = 100 * cumulative_treated / `n_ruv'

twoway ///
    (bar newly_treated recorded_project_year, ///
        color(navy%70) lcolor(navy) barwidth(0.72)), ///
    xlabel(2007(2)2023, angle(45) labsize(small)) ///
    ylabel(0(100)600, angle(horizontal) grid glcolor(gs14) glwidth(vthin) ///
        labsize(small)) ///
    xtitle("Recorded CMAN project year", size(small)) ///
    ytitle("Newly treated communities", size(small)) ///
    title("Annual treatment cohorts", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_rollout_annual, replace)

twoway ///
    (connected cumulative_share recorded_project_year, ///
        sort lcolor(teal) lwidth(medthick) ///
        mcolor(teal) msymbol(O) msize(small)), ///
    xlabel(2007(2)2023, angle(45) labsize(small)) ///
    ylabel(0(10)80, angle(horizontal) grid glcolor(gs14) glwidth(vthin) ///
        labsize(small) format(%3.0f)) ///
    yscale(range(0 80)) ///
    xtitle("Recorded CMAN project year", size(small)) ///
    ytitle("RUV communities treated cumulatively (%)", size(small)) ///
    title("Cumulative treatment coverage", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_rollout_cumulative, replace)

graph combine desc_rollout_annual desc_rollout_cumulative, ///
    cols(2) xsize(12) ysize(5.8) ///
    title("Collective-reparation rollout, 2007-2023", ///
        size(medium) color(black)) ///
    subtitle("First recorded CMAN project year and cumulative coverage of the RUV universe", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado (N = 5,712). Treatment begins in the first project year recorded in the CMAN roster" ///
        "and remains active thereafter. The 1,491 RUV communities not linked to a CMAN project by 2023 are coded untreated under the current rule." ///
        "No sampling uncertainty is reported. Source: CMAN 2023 project roster linked to RUV Libro Segundo.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_03_treatment_rollout.png", ///
    width(2800) replace
graph drop desc_rollout_annual desc_rollout_cumulative
restore

preserve
collapse ///
    (mean) treat_13 treat_17 treat_23 ///
    (count) communities=victimization_index, ///
    by(victimization_level_source)

foreach treatment_variable in treat_13 treat_17 treat_23 {
    replace `treatment_variable' = 100 * `treatment_variable'
}

graph bar (asis) treat_13 treat_17 treat_23, ///
    over(victimization_level_source, label(labsize(small))) ///
    bar(1, color(navy%80) lcolor(navy)) ///
    bar(2, color(teal%80) lcolor(teal)) ///
    bar(3, color(orange_red%75) lcolor(orange_red)) ///
    legend(order(1 "By 2013" 2 "By 2017" 3 "By 2023") ///
        rows(1) position(6) region(lcolor(none)) size(small)) ///
    ylabel(0(20)100, angle(horizontal) grid glcolor(gs14) glwidth(vthin) ///
        labsize(small)) ///
    ytitle("Communities treated (%)", size(small)) ///
    title("Treatment coverage by victimization category", ///
        size(medium) color(black)) ///
    subtitle("Cumulative CMAN project receipt at three administrative dates", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado (N = 5,712). Categories A-E are those supplied in the RUV workbook;" ///
        "bars are unconditional category means of cumulative treatment indicators. No RD sample, model, or statistical uncertainty is used." ///
        "Source: CMAN 2023 project roster linked to RUV Libro Segundo.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(9) ysize(6)

graph export ///
    "`figure_dir'/fig_desc_04_treatment_by_category.png", ///
    width(2400) replace
restore

/*
Annual category coverage distinguishes cumulative saturation from the
composition of each newly recorded treatment cohort. The CMAN year is treated
as the first recorded project year, not as a verified completion date.
*/

tempfile category_rollout category_cohorts category_rollout_complete

preserve
collapse ///
    (count) category_communities=victimization_index ///
    (mean) treat_07-treat_23, ///
    by(victimization_level_source)

forvalues year_suffix = 7/9 {
    rename treat_0`year_suffix' treat_`year_suffix'
}

reshape long treat_, ///
    i(victimization_level_source category_communities) ///
    j(year_suffix)
rename treat_ cumulative_treatment_share
generate int year = 2000 + year_suffix
generate int cumulative_treated = ///
    round(category_communities * cumulative_treatment_share)
replace cumulative_treatment_share = ///
    100 * cumulative_treatment_share
drop year_suffix
isid victimization_level_source year
save "`category_rollout'", replace
restore

preserve
keep if !missing(recorded_project_year)
contract ///
    victimization_level_source ///
    recorded_project_year, ///
    freq(newly_treated)
rename recorded_project_year year
bysort year: egen int annual_newly_treated = total(newly_treated)
generate double new_cohort_share = ///
    100 * newly_treated / annual_newly_treated
isid victimization_level_source year
save "`category_cohorts'", replace
restore

preserve
use "`category_rollout'", clear
merge 1:1 victimization_level_source year ///
    using "`category_cohorts'", ///
    assert(master match) nogen
replace newly_treated = 0 if missing(newly_treated)
replace new_cohort_share = 0 if missing(new_cohort_share)
bysort year: egen int annual_newly_treated_fill = ///
    max(annual_newly_treated)
replace annual_newly_treated = annual_newly_treated_fill if ///
    missing(annual_newly_treated)
drop annual_newly_treated_fill
order ///
    year ///
    victimization_level_source ///
    category_communities ///
    cumulative_treated ///
    cumulative_treatment_share ///
    newly_treated ///
    new_cohort_share ///
    annual_newly_treated
sort year victimization_level_source
save "`category_rollout_complete'", replace
export delimited using ///
    "`table_dir'/rd_rollout_category_year.csv", ///
    replace

twoway ///
    (connected cumulative_treatment_share year ///
        if victimization_level_source == "A", ///
        sort lcolor(navy) lwidth(medthick) ///
        mcolor(navy) msymbol(O) msize(vsmall)) ///
    (connected cumulative_treatment_share year ///
        if victimization_level_source == "B", ///
        sort lcolor(teal) lwidth(medthick) ///
        mcolor(teal) msymbol(D) msize(vsmall)) ///
    (connected cumulative_treatment_share year ///
        if victimization_level_source == "C", ///
        sort lcolor(orange) lwidth(medthick) ///
        mcolor(orange) msymbol(T) msize(vsmall)) ///
    (connected cumulative_treatment_share year ///
        if victimization_level_source == "D", ///
        sort lcolor(maroon) lwidth(medthick) ///
        mcolor(maroon) msymbol(S) msize(vsmall)) ///
    (connected cumulative_treatment_share year ///
        if victimization_level_source == "E", ///
        sort lcolor(forest_green) lwidth(medthick) ///
        mcolor(forest_green) msymbol(Oh) msize(vsmall)), ///
    xlabel(2007(4)2023, angle(45) labsize(vsmall)) ///
    ylabel(0(20)100, ///
        grid glcolor(gs14) glwidth(vthin) labsize(vsmall)) ///
    xtitle("First recorded project year", size(vsmall)) ///
    ytitle("Cumulative coverage (%)", size(vsmall)) ///
    title("Coverage within each category", ///
        size(small) color(black)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(desc_category_coverage_year, replace)

keep year victimization_level_source new_cohort_share
generate byte category_order = ///
    strpos("ABCDE", victimization_level_source)
drop victimization_level_source
reshape wide new_cohort_share, ///
    i(year) j(category_order)

forvalues category = 1/5 {
    replace new_cohort_share`category' = 0 if ///
        missing(new_cohort_share`category')
}

egen double cohort_share_check = ///
    rowtotal(new_cohort_share1-new_cohort_share5)
assert abs(cohort_share_check - 100) < 1e-8

graph bar (asis) ///
    new_cohort_share1 ///
    new_cohort_share2 ///
    new_cohort_share3 ///
    new_cohort_share4 ///
    new_cohort_share5, ///
    over(year, label(angle(45) labsize(small))) ///
    stack ///
    bar(1, color(navy%88) lcolor(white)) ///
    bar(2, color(teal%85) lcolor(white)) ///
    bar(3, color(orange%82) lcolor(white)) ///
    bar(4, color(maroon%78) lcolor(white)) ///
    bar(5, color(forest_green%78) lcolor(white)) ///
    ylabel(0(20)100, ///
        grid glcolor(gs14) glwidth(vthin) labsize(vsmall)) ///
    ytitle("New cohort share (%)", size(vsmall)) ///
    title("Composition of annual cohorts", ///
        size(small) color(black)) ///
    legend( ///
        order(1 "A" 2 "B" 3 "C" 4 "D" 5 "E") ///
        rows(1) position(6) size(vsmall) region(lcolor(none))) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(desc_category_cohort_year, replace)

graph combine ///
    desc_category_coverage_year ///
    desc_category_cohort_year, ///
    cols(1) xsize(11) ysize(8) imargin(tiny) ///
    title("Collective-reparation rollout by victimization category", ///
        size(medsmall) color(black)) ///
    subtitle("Cumulative coverage and annual cohort composition, 2007-2023", ///
        size(vsmall) color(gs5)) ///
    note( ///
        "Notes: RUV centro poblados (N = 5,712). Panel A reports cumulative coverage within each official category;" ///
        "Panel B reports category shares within each newly linked annual cohort. A is the highest victimization tier." ///
        "CMAN year is the first recorded project year, not verified completion. No model or uncertainty is used." ///
        "Source: RUV Libro Segundo linked to the CMAN register through 2023.", ///
        size(tiny) color(gs5)) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_20_treatment_by_category_over_time.png", ///
    width(2800) replace
graph drop ///
    desc_category_coverage_year ///
    desc_category_cohort_year
restore

preserve
use "`category_rollout_complete'", clear
tempname category_year_table
file open `category_year_table' ///
    using "`table_dir'/tab_desc_09_treatment_by_category_over_time.tex", ///
    write replace text

file write `category_year_table' "\begin{table}[!htbp]" _n
file write `category_year_table' "\centering" _n
file write `category_year_table' "\caption{Cumulative collective-reparation coverage by victimization category}" _n
file write `category_year_table' "\label{tab:desc_treatment_category_year}" _n
file write `category_year_table' "\begin{tabular}{lrrrrrrr}" _n
file write `category_year_table' "\toprule" _n
file write `category_year_table' "Category & RUV communities & 2007 & 2010 & 2012 & 2016 & 2020 & 2023 \\" _n
file write `category_year_table' "\midrule" _n

foreach category in A B C D E {
    quietly summarize category_communities if ///
        victimization_level_source == "`category'"
    local category_n : display %9.0fc r(mean)
    local category_n = strtrim("`category_n'")
    local category_row "`category' & `category_n'"

    foreach year in 2007 2010 2012 2016 2020 2023 {
        quietly summarize cumulative_treatment_share if ///
            victimization_level_source == "`category'" & ///
            year == `year'
        assert r(N) == 1
        local coverage : display %5.1f r(mean)
        local coverage = strtrim("`coverage'")
        local category_row "`category_row' & `coverage'"
    }

    file write `category_year_table' "`category_row' \\" _n
}

file write `category_year_table' "\bottomrule" _n
file write `category_year_table' "\end{tabular}" _n
file write `category_year_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} Entries after the community count are percentages of all RUV communities in the indicated official victimization category with a linked CMAN project by the end of the listed recorded year. Category A denotes the highest recorded victimization tier. CMAN year is the first project year in the available roster and is not verified as completion. No RD sample or model is used. Source: RUV Libro Segundo linked to the CMAN register through 2023.}" _n
file write `category_year_table' "\end{table}" _n
file close `category_year_table'
restore

preserve
xtile score_bin = victimization_index, nq(60)
collapse ///
    (mean) mean_score=victimization_index treated_share=treat_23 ///
    (count) communities=victimization_index, ///
    by(score_bin)
replace treated_share = 100 * treated_share
sort mean_score

twoway ///
    (connected treated_share mean_score, ///
        sort lcolor(navy) lwidth(medium) ///
        mcolor(navy) msymbol(O) msize(vsmall)), ///
    xline(0.015220 0.026930 0.062320 0.153750, ///
        lcolor(gs7) lpattern(dash) lwidth(vthin)) ///
    xlabel(0(0.5)`score_max', format(%3.1f) labsize(small)) ///
    ylabel(0(20)100, angle(horizontal) grid glcolor(gs14) glwidth(vthin) ///
        labsize(small)) ///
    xtitle("Mean victimization index within score bin", size(small)) ///
    ytitle("Treated by 2023 (%)", size(small)) ///
    title("Full observed support", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_score_treat_full, replace)

twoway ///
    (connected treated_share mean_score if mean_score <= 0.20, ///
        sort lcolor(teal) lwidth(medium) ///
        mcolor(teal) msymbol(O) msize(vsmall)), ///
    xline(0.015220 0.026930 0.062320 0.153750, ///
        lcolor(gs7) lpattern(dash) lwidth(vthin)) ///
    xlabel(0 "0" 0.015220 "D-E" 0.026930 "C-D" ///
        0.062320 "B-C" 0.153750 "A-B" 0.20 ".20", ///
        angle(45) labsize(vsmall)) ///
    ylabel(0(20)100, angle(horizontal) grid glcolor(gs14) glwidth(vthin) ///
        labsize(small)) ///
    xtitle("Mean victimization index within score bin", size(small)) ///
    ytitle("Treated by 2023 (%)", size(small)) ///
    title("Policy-threshold detail", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_score_treat_zoom, replace)

graph combine desc_score_treat_full desc_score_treat_zoom, ///
    cols(2) xsize(12) ysize(5.8) ///
    title("Raw treatment profile across the victimization score", ///
        size(medium) color(black)) ///
    subtitle("Equal-frequency bins describe the national data; they do not select or estimate an RD design", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado (N = 5,712). Points are means from up to 60 equal-frequency score bins;" ///
        "lines only connect descriptive bin means. Panel A retains the complete score support and Panel B magnifies values through 0.20." ///
        "No fitted discontinuity, bandwidth, geographic restriction, or uncertainty interval is used. Source: RUV and CMAN 2023.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_05_score_treatment_profile.png", ///
    width(2800) replace
graph drop desc_score_treat_full desc_score_treat_zoom
restore


*-----------------------------------*
**# 4. Geography and source coverage
*-----------------------------------*

preserve
collapse ///
    (count) communities=victimization_index ///
    (mean) treated_share=treat_23, ///
    by(dpto_victim_raw)
replace treated_share = 100 * treated_share
generate str20 department = proper(lower(dpto_victim_raw))

graph hbar (asis) communities, ///
    over(department, sort(1) descending label(labsize(vsmall))) ///
    bar(1, color(navy%75) lcolor(navy)) ///
    blabel(bar, format(%6.0fc) position(outside) size(vsmall) color(gs4)) ///
    ylabel(0(250)1500, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("RUV communities", size(small)) ///
    title("Communities in the RUV universe", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_department_count, replace)

graph hbar (asis) treated_share, ///
    over(department, sort(1) descending label(labsize(vsmall))) ///
    bar(1, color(teal%75) lcolor(teal)) ///
    blabel(bar, format(%4.1f) position(outside) size(vsmall) color(gs4)) ///
    yscale(range(0 100)) ///
    ylabel(0(20)100, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Treated by 2023 (%)", size(small)) ///
    title("Cumulative treatment coverage", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_department_treatment, replace)

graph combine desc_department_count desc_department_treatment, ///
    cols(2) xsize(12) ysize(7.5) ///
    title("Geographic composition of the RUV-CMAN registry", ///
        size(medium) color(black)) ///
    subtitle("Department counts and unconditional treatment coverage through 2023", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado (N = 5,712). Departments use the names supplied in the RUV workbook;" ///
        "the right panel reports the mean of the cumulative 2023 treatment indicator. No geographic RD sample or inferential comparison is used." ///
        "Source: RUV Libro Segundo and CMAN 2023.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_06_department_profile.png", ///
    width(2800) replace
graph drop desc_department_count desc_department_treatment
restore

preserve
clear
set obs 5
generate byte display_order = _n
generate str48 coverage_measure = ""
generate double coverage_percent = .
replace coverage_measure = "Verified ten-digit CCPP UBIGEO" in 1
replace coverage_measure = "Linked 2007 Census tabulation" in 2
replace coverage_measure = "Complete 2007 core wellbeing score" in 3
replace coverage_measure = "Linked 2017 CCPP spatial spine" in 4
replace coverage_measure = "2017 altitude attribute available" in 5
replace coverage_percent = 100 * `n_ubigeo' / `n_ruv' in 1
replace coverage_percent = 100 * `n_census' / `n_ruv' in 2
replace coverage_percent = 100 * `n_wellbeing' / `n_ruv' in 3
replace coverage_percent = 100 * `n_spatial' / `n_ruv' in 4
replace coverage_percent = 100 * `n_altitude' / `n_ruv' in 5

graph hbar (asis) coverage_percent, ///
    over(coverage_measure, sort(1) descending label(labsize(small))) ///
    bar(1, color(navy%75) lcolor(navy)) ///
    blabel(bar, format(%4.1f) position(outside) size(small) color(gs4)) ///
    yscale(range(0 100)) ///
    ylabel(0(20)100, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("RUV communities with information available (%)", size(small)) ///
    title("Coverage of linked foundational sources", ///
        size(medium) color(black)) ///
    subtitle("Every denominator is the complete 5,712-community RUV universe", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Bars report nonmissing or validated linkage coverage. Missing downstream links never remove an RUV observation from this accounting." ///
        "Absence from the CMAN roster is not treated as missing data: after exhaustive reconciliation it defines untreated status through 2023." ///
        "Sources: RUV, INEI CCPP directories, 2007 Census tabulation, CMAN 2023, and the 2017 GeoGPS/INEI CCPP layer.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(9) ysize(5.8)

graph export ///
    "`figure_dir'/fig_desc_07_data_coverage.png", ///
    width(2400) replace
restore


*-----------------------------------*
**# 5. Baseline and spatial context
*-----------------------------------*

quietly summarize wellbeing_housing_2007
local mean_wb_housing = r(mean)
quietly summarize wellbeing_services_2007
local mean_wb_services = r(mean)
quietly summarize wellbeing_energy_2007
local mean_wb_energy = r(mean)
quietly summarize wellbeing_human_capital_2007
local mean_wb_human_capital = r(mean)
quietly summarize wellbeing_assets_2007
local mean_wb_assets = r(mean)
quietly summarize wellbeing_connectivity_2007
local mean_wb_connectivity = r(mean)
quietly summarize wellbeing_core_2007
local mean_wb_core = r(mean)

preserve
clear
set obs 7
generate byte display_order = _n
generate str28 domain = ""
generate double mean_wellbeing = .
replace domain = "Housing quality" in 1
replace domain = "Basic services" in 2
replace domain = "Energy" in 3
replace domain = "Human capital" in 4
replace domain = "Durable assets" in 5
replace domain = "Connectivity" in 6
replace domain = "Equal-domain core score" in 7
replace mean_wellbeing = `mean_wb_housing' in 1
replace mean_wellbeing = `mean_wb_services' in 2
replace mean_wellbeing = `mean_wb_energy' in 3
replace mean_wellbeing = `mean_wb_human_capital' in 4
replace mean_wellbeing = `mean_wb_assets' in 5
replace mean_wellbeing = `mean_wb_connectivity' in 6
replace mean_wellbeing = `mean_wb_core' in 7

graph hbar (asis) mean_wellbeing, ///
    over(domain, sort(1) descending label(labsize(small))) ///
    bar(1, color(teal%75) lcolor(teal)) ///
    blabel(bar, format(%4.3f) position(outside) size(small) color(gs4)) ///
    yscale(range(0 1)) ///
    ylabel(0(0.2)1, grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Mean wellbeing score (0-1)", size(small)) ///
    title("Baseline community wellbeing domains", ///
        size(medium) color(black)) ///
    subtitle("Transparent equal-component measures constructed from the 2007 Census tabulation", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the linked RUV centro poblado. Domain-specific sample sizes reflect complete-component rules;" ///
        "the equal-domain core score is available for 4,921 communities. Higher values indicate greater wellbeing." ///
        "These ecological coverage scores are not household poverty headcounts or an official MPI. Source: 2007 Census CCPP tabulation.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(9) ysize(6)

graph export ///
    "`figure_dir'/fig_desc_08_baseline_wellbeing.png", ///
    width(2400) replace
restore

graph box wellbeing_core_2007, ///
    over(victimization_level_source, label(labsize(small))) ///
    box(1, color(navy%35) lcolor(navy)) ///
    marker(1, mcolor(navy%40) msize(tiny)) ///
    ylabel(0(0.2)1, angle(horizontal) grid glcolor(gs14) glwidth(vthin) ///
        labsize(small)) ///
    ytitle("Baseline wellbeing score (0-1)", size(small)) ///
    title("Baseline wellbeing across victimization categories", ///
        size(medium) color(black)) ///
    subtitle("Boxes show the linked 2007 distribution; categories remain those supplied by RUV", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado linked to a complete 2007 core wellbeing score (N = 4,921)." ///
        "Boxes show medians and interquartile ranges; whiskers and plotted points retain the observed distribution." ///
        "This is an unconditional description, not a balance or RD continuity test. Sources: RUV and 2007 Census CCPP tabulation.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(8.5) ysize(6)

graph export ///
    "`figure_dir'/fig_desc_09_wellbeing_by_category.png", ///
    width(2400) replace

histogram altitude_m_2017, ///
    width(200) frequency ///
    fcolor(navy%65) lcolor(navy) lwidth(vthin) ///
    xlabel(0(1000)5000, labsize(small)) ///
    ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Altitude (meters above sea level)", size(small)) ///
    ytitle("Communities", size(small)) ///
    title("Altitude", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_altitude, replace)

graph hbox ///
    dist_dist_capital_km ///
    dist_prov_capital_km ///
    dist_dept_capital_km ///
    dist_nearest_city_km, ///
    box(1, color(navy%45) lcolor(navy)) ///
    box(2, color(maroon%45) lcolor(maroon)) ///
    box(3, color(teal%45) lcolor(teal)) ///
    box(4, color(orange_red%45) lcolor(orange_red)) ///
    ylabel(0(50)350, angle(horizontal) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    ytitle("Straight-line geodesic distance (kilometers)", size(small)) ///
    title("Distance to administrative and city reference points", ///
        size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_distances, replace)

graph combine desc_altitude desc_distances, ///
    cols(2) xsize(12) ysize(5.8) ///
    title("Geospatial context of linked communities", ///
        size(medium) color(black)) ///
    subtitle("Physical location measures from the 2017 CCPP spatial source", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the spatially linked RUV centro poblado. Altitude is available for 4,019 communities and distance measures for 4,707." ///
        "Distances are WGS 84 geodesic kilometers, not road distance, travel time, or service accessibility; all observed values are retained." ///
        "No statistical uncertainty is reported. Source: 2017 GeoGPS redistribution of INEI CCPP information.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_10_geospatial_context.png", ///
    width(2800) replace
graph drop desc_altitude desc_distances

twoway ///
    (scatter latitude_2017 longitude_2017 ///
        if geospatial_linked == 1 & treat_23 == 0, ///
        msymbol(O) msize(tiny) mcolor(gs10%55)) ///
    (scatter latitude_2017 longitude_2017 ///
        if geospatial_linked == 1 & treat_23 == 1, ///
        msymbol(O) msize(tiny) mcolor(teal%45)), ///
    legend(order(1 "No CMAN project recorded by 2023" 2 "Treated by 2023") ///
        rows(2) position(6) region(lcolor(none)) size(small)) ///
    xlabel(-82(2)-68, labsize(small) grid glcolor(gs15) glwidth(vthin)) ///
    ylabel(-20(4)0, angle(horizontal) labsize(small) ///
        grid glcolor(gs15) glwidth(vthin)) ///
    xtitle("Longitude (decimal degrees)", size(small)) ///
    ytitle("Latitude (decimal degrees)", size(small)) ///
    title("Spatial distribution of linked RUV communities", ///
        size(medium) color(black)) ///
    subtitle("Validated 2017 CCPP points by treatment status through 2023", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Each point is a spatially linked RUV centro poblado (N = 4,707)." ///
        "The 1,005 RUV rows without a validated spatial link are not plotted." ///
        "This is not a boundary map and makes no spatial or causal comparison." ///
        "Treatment uses CMAN through 2023; disclosure review is required before release." ///
        "Sources: RUV, CMAN 2023, and the 2017 GeoGPS/INEI CCPP layer.", ///
        size(vsmall) color(gs5) span) ///
    aspectratio(1.25) ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(8.5) ysize(8.5)

graph export ///
    "`figure_dir'/fig_desc_11_spatial_distribution.png", ///
    width(2400) replace


*-----------------------------------*
**# 6. National department maps
*-----------------------------------*

/*
The analytical values below are current pipeline outputs. Department geometry
comes from the checksum-locked files used by the legacy maps. Its acquisition
provenance is unresolved, so every map remains internal-review material until
an official versioned boundary source replaces or verifies it.
*/
tempfile department_map_statistics

preserve
generate byte one = 1
collapse ///
    (sum) ruv_communities=one treated_2023=treat_23 ///
    (mean) treatment_share_2023=treat_23 ///
    (mean) mean_victimization_index=victimization_index ///
    (p50) median_victimization_index=victimization_index, ///
    by(dpto_victim_raw)
rename dpto_victim_raw NOMBDEP
replace treatment_share_2023 = 100 * treatment_share_2023
save "`department_map_statistics'", replace
restore

preserve
use "`department_map_data'", clear
isid id
isid NOMBDEP
merge 1:1 NOMBDEP using "`department_map_statistics'"
quietly count if _merge == 2
assert r(N) == 0

foreach count_variable in ruv_communities treated_2023 {
    replace `count_variable' = 0 if _merge == 1
}
drop _merge

spmap ruv_communities using "`department_map_coords'", ///
    id(id) ///
    clmethod(custom) ///
    clbreaks(0 1 50 100 250 500 1000 1500) ///
    fcolor(Blues2) ///
    ocolor(gs8) ///
    osize(vthin) ///
    legend(position(7) size(small) region(lcolor(none))) ///
    title("Victimized communities by department", ///
        size(medium) color(black)) ///
    subtitle("Complete RUV universe; zero denotes no listed community", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Values are counts of RUV centros poblados (N = 5,712)." ///
        "This is an unconditional description with no RD sample or inference." ///
        "Analytical source: RUV Libro Segundo." ///
        "Boundary geometry is checksum locked; provenance verification is pending.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) ///
    xsize(8.5) ysize(8.5)

graph export ///
    "`figure_dir'/fig_desc_12_map_victimized_communities.png", ///
    width(2400) replace

spmap treated_2023 using "`department_map_coords'", ///
    id(id) ///
    clmethod(custom) ///
    clbreaks(0 1 50 100 200 400 800 1200) ///
    fcolor(BuGn) ///
    ocolor(gs8) ///
    osize(vthin) ///
    legend(position(7) size(small) region(lcolor(none))) ///
    title("Communities treated by 2023", ///
        size(medium) color(black)) ///
    subtitle("Number of RUV communities linked to a CMAN project, by department", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Values count RUV centros poblados first treated by 2023 (4,221 of 5,712)." ///
        "No RD sample or statistical uncertainty is used." ///
        "Analytical sources: RUV and CMAN 2023." ///
        "Boundary geometry is checksum locked; provenance verification is pending.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) ///
    xsize(8.5) ysize(8.5)

graph export ///
    "`figure_dir'/fig_desc_13_map_treated_communities.png", ///
    width(2400) replace

spmap treatment_share_2023 using "`department_map_coords'", ///
    id(id) ///
    clmethod(custom) ///
    clbreaks(0 20 40 60 80 100) ///
    fcolor(PuBuGn) ///
    ndfcolor(gs14) ///
    ndocolor(gs8) ///
    ocolor(gs8) ///
    osize(vthin) ///
    legend(position(7) size(small) region(lcolor(none))) ///
    title("Treatment coverage by department", ///
        size(medium) color(black)) ///
    subtitle("Share of RUV communities treated by 2023", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: The denominator is the number of RUV centros poblados in each department." ///
        "Departments outside the RUV universe are shown as no data." ///
        "Treatment is cumulative through 2023; no RD sample or inference is used." ///
        "Sources: RUV and CMAN 2023. Boundary provenance verification is pending.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) ///
    xsize(8.5) ysize(8.5)

graph export ///
    "`figure_dir'/fig_desc_14_map_treatment_share.png", ///
    width(2400) replace

replace mean_victimization_index = ///
    round(mean_victimization_index, 0.001)
replace median_victimization_index = ///
    round(median_victimization_index, 0.001)

spmap mean_victimization_index using "`department_map_coords'", ///
    id(id) ///
    clmethod(quantile) ///
    clnumber(5) ///
    fcolor(YlOrBr) ///
    ndfcolor(gs14) ///
    ndocolor(gs8) ///
    ocolor(gs8) ///
    osize(vthin) ///
    legend(position(7) size(vsmall) region(lcolor(none))) ///
    title("Mean victimization index", size(medsmall) color(black)) ///
    graphregion(color(white)) ///
    name(desc_map_index_mean, replace)

spmap median_victimization_index using "`department_map_coords'", ///
    id(id) ///
    clmethod(quantile) ///
    clnumber(5) ///
    fcolor(YlOrBr) ///
    ndfcolor(gs14) ///
    ndocolor(gs8) ///
    ocolor(gs8) ///
    osize(vthin) ///
    legend(position(7) size(vsmall) region(lcolor(none))) ///
    title("Median victimization index", size(medsmall) color(black)) ///
    graphregion(color(white)) ///
    name(desc_map_index_median, replace)

graph combine desc_map_index_mean desc_map_index_median, ///
    cols(2) xsize(12) ysize(6.5) ///
    title("Victimization-index profile by department", ///
        size(medium) color(black)) ///
    subtitle("Department means and medians in the complete RUV universe", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Statistics use all RUV centros poblados in each represented department; departments outside the RUV universe are shown as no data." ///
        "Quantile classes are panel-specific and the maps are descriptive, with no RD sample or inference. Analytical source: RUV Libro Segundo." ///
        "Boundary geometry: checksum-locked legacy department files; provenance verification remains pending.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_15_map_victimization_index.png", ///
    width(2800) replace
graph drop desc_map_index_mean desc_map_index_median
restore


*-----------------------------------*
**# 7. Selected main RD geography
*-----------------------------------*

/*
The research team selected the exact legacy geography on 29 July 2026. These
outputs describe that fixed rule; they do not re-run the geographic search,
test an RD first stage, or compare outcomes.
*/

preserve
use "`province_map_data'", clear

isid ubigeo_prov
assert _N == 193

generate byte sample_main_rd = ///
    inlist(substr(ubigeo_prov, 1, 2), "03", "09") | ///
    inlist(ubigeo_prov, "0809", "1201")

count if sample_main_rd
assert r(N) == 16

label define sample_main_rd_map ///
    0 "Outside selected geography" ///
    1 "Selected RD geography"
label values sample_main_rd sample_main_rd_map

spmap sample_main_rd using "`province_map_coords'", ///
    id(id) ///
    clmethod(unique) ///
    fcolor(gs14 navy) ///
    ocolor(white white) ///
    osize(vthin thin) ///
    legorder(lohi) ///
    legend( ///
        order(2 "Outside selected geography" 3 "Selected RD geography") ///
        rows(1) position(6) ring(1) size(small) ///
        region(lcolor(none))) ///
    title("Geographic definition of the selected RD sample", ///
        size(medium) color(black)) ///
    subtitle( ///
        "Apurimac and Huancavelica, plus La Convencion and Huancayo provinces", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Selected geography includes all RUV communities in Apurimac and Huancavelica;" ///
        "La Convencion province (Cusco); and Huancayo province (Junin). N = 1,162." ///
        "Shading identifies the geographic rule, not treatment assignment or an estimate." ///
        "Boundary geometry is the checksum-locked 2018 legacy province file. Publication use" ///
        "requires verification against an official versioned source. Source: RUV Libro Segundo." ///
        "Research-team geographic decision recorded on 29 July 2026.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) ///
    xsize(8.5) ysize(8.5)

graph export ///
    "`figure_dir'/fig_desc_21_main_rd_sample_map.png", ///
    width(2400) replace
restore

preserve
contract sample_main_rd victimization_level_source
bysort sample_main_rd: egen long sample_total = total(_freq)
generate double category_share = 100 * _freq / sample_total
keep sample_main_rd victimization_level_source category_share
reshape wide category_share, ///
    i(victimization_level_source) j(sample_main_rd)
assert !missing(category_share0, category_share1)

graph bar (asis) category_share0 category_share1, ///
    over(victimization_level_source, label(labsize(small))) ///
    bar(1, color(gs10) lcolor(gs8)) ///
    bar(2, color(navy%80) lcolor(navy)) ///
    blabel(bar, format(%4.1f) size(vsmall) color(gs4)) ///
    ylabel(0(5)30, angle(horizontal) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    yscale(range(0 30)) ///
    ytitle("Communities in group (%)", size(small)) ///
    title("Victimization-category composition", ///
        size(medsmall) color(black)) ///
    legend( ///
        order(1 "Remaining RUV universe" 2 "Selected RD geography") ///
        rows(1) size(vsmall) region(lcolor(none))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_main_rd_categories, replace)
restore

preserve
collapse (mean) ///
    coverage2007=treat_07 ///
    coverage2012=treat_12 ///
    coverage2016=treat_16 ///
    coverage2023=treat_23, ///
    by(sample_main_rd)

reshape long coverage, i(sample_main_rd) j(year)
replace coverage = 100 * coverage
reshape wide coverage, i(year) j(sample_main_rd)
assert !missing(coverage0, coverage1)

graph bar (asis) coverage0 coverage1, ///
    over(year, label(labsize(small))) ///
    bar(1, color(gs10) lcolor(gs8)) ///
    bar(2, color(teal%80) lcolor(teal)) ///
    blabel(bar, format(%4.1f) size(vsmall) color(gs4)) ///
    ylabel(0(20)100, angle(horizontal) grid glcolor(gs14) ///
        glwidth(vthin) labsize(small)) ///
    yscale(range(0 100)) ///
    ytitle("Communities with a linked project (%)", size(small)) ///
    title("Cumulative collective-reparation coverage", ///
        size(medsmall) color(black)) ///
    legend( ///
        order(1 "Remaining RUV universe" 2 "Selected RD geography") ///
        rows(1) size(vsmall) region(lcolor(none))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(desc_main_rd_treatment, replace)
restore

graph combine desc_main_rd_categories desc_main_rd_treatment, ///
    cols(2) xsize(12) ysize(6.2) ///
    title("Profile of the selected RD geography", ///
        size(medium) color(black)) ///
    subtitle( ///
        "Composition and cumulative project receipt relative to the remaining RUV universe", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the RUV centro poblado. The selected geography contains 1,162 communities; the remaining universe contains 4,550." ///
        "Panel A reports within-group category shares. Panel B reports cumulative linked CMAN project receipt through each listed year." ///
        "CMAN year is the first project year in the available roster and is not verified as completion. No statistical test or causal comparison is shown." ///
        "Sources: RUV Libro Segundo and CMAN register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_22_main_rd_sample_profile.png", ///
    width(2800) replace
graph drop desc_main_rd_categories desc_main_rd_treatment

quietly summarize census2007_linked if sample_main_rd
local main_rd_census_share = 100 * r(mean)
quietly summarize geospatial_linked if sample_main_rd
local main_rd_spatial_share = 100 * r(mean)
quietly summarize treat_12 if sample_main_rd
local main_rd_treat12_share = 100 * r(mean)
quietly summarize treat_16 if sample_main_rd
local main_rd_treat16_share = 100 * r(mean)
quietly summarize treat_23 if sample_main_rd
local main_rd_treat23_share = 100 * r(mean)

preserve
keep if sample_main_rd

generate byte component_order = .
generate str36 geographic_component = ""

replace component_order = 1 if substr(ubigeo_dist, 1, 2) == "03"
replace geographic_component = "Apurimac (all provinces)" if ///
    component_order == 1
replace component_order = 2 if substr(ubigeo_dist, 1, 2) == "09"
replace geographic_component = "Huancavelica (all provinces)" if ///
    component_order == 2
replace component_order = 3 if substr(ubigeo_dist, 1, 4) == "0809"
replace geographic_component = "La Convencion (Cusco)" if ///
    component_order == 3
replace component_order = 4 if substr(ubigeo_dist, 1, 4) == "1201"
replace geographic_component = "Huancayo (Junin)" if ///
    component_order == 4

assert !missing(component_order, geographic_component)

collapse ///
    (count) communities=sample_main_rd ///
    (mean) census_link_share=census2007_linked ///
           spatial_link_share=geospatial_linked ///
           treated_2012_share=treat_12 ///
           treated_2016_share=treat_16 ///
           treated_2023_share=treat_23, ///
    by(component_order geographic_component)

foreach share_variable in ///
    census_link_share ///
    spatial_link_share ///
    treated_2012_share ///
    treated_2016_share ///
    treated_2023_share {

    replace `share_variable' = 100 * `share_variable'
}

generate double sample_share = 100 * communities / `n_main_rd'

set obs `=_N + 1'
replace component_order = 5 in L
replace geographic_component = "Total selected geography" in L
replace communities = `n_main_rd' in L
replace sample_share = 100 in L
replace census_link_share = `main_rd_census_share' in L
replace spatial_link_share = `main_rd_spatial_share' in L
replace treated_2012_share = `main_rd_treat12_share' in L
replace treated_2016_share = `main_rd_treat16_share' in L
replace treated_2023_share = `main_rd_treat23_share' in L
sort component_order

export delimited ///
    "`table_dir'/rd_main_sample_geographic_profile.csv", ///
    replace

tempname main_rd_profile_table
file open `main_rd_profile_table' ///
    using "`table_dir'/tab_desc_10_main_rd_sample_profile.tex", ///
    write replace text

file write `main_rd_profile_table' "\begin{table}[!htbp]" _n
file write `main_rd_profile_table' "\centering" _n
file write `main_rd_profile_table' "\caption{Composition and coverage of the selected RD geography}" _n
file write `main_rd_profile_table' "\label{tab:desc_main_rd_sample_profile}" _n
file write `main_rd_profile_table' "\begin{tabular}{lrrrrrrr}" _n
file write `main_rd_profile_table' "\toprule" _n
file write `main_rd_profile_table' "Geographic component & Communities & Sample share (\%) & Census 2007 linked (\%) & Spatially linked (\%) & Treated 2012 (\%) & Treated 2016 (\%) & Treated 2023 (\%) \\" _n
file write `main_rd_profile_table' "\midrule" _n

forvalues component_index = 1/`=_N' {
    local component_name "`=geographic_component[`component_index']'"
    local component_n : display %9.0fc communities[`component_index']
    local component_share_fmt : display %5.1f sample_share[`component_index']
    local census_share_fmt : display %5.1f census_link_share[`component_index']
    local spatial_share_fmt : display %5.1f spatial_link_share[`component_index']
    local treat12_share_fmt : display %5.1f treated_2012_share[`component_index']
    local treat16_share_fmt : display %5.1f treated_2016_share[`component_index']
    local treat23_share_fmt : display %5.1f treated_2023_share[`component_index']

    foreach formatted_value in ///
        component_n ///
        component_share_fmt ///
        census_share_fmt ///
        spatial_share_fmt ///
        treat12_share_fmt ///
        treat16_share_fmt ///
        treat23_share_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    if `component_index' == _N {
        file write `main_rd_profile_table' "\midrule" _n
    }

    file write `main_rd_profile_table' ///
        "`component_name' & `component_n' & `component_share_fmt' & `census_share_fmt' & `spatial_share_fmt' & `treat12_share_fmt' & `treat16_share_fmt' & `treat23_share_fmt' \\" _n
}

file write `main_rd_profile_table' "\bottomrule" _n
file write `main_rd_profile_table' "\end{tabular}" _n
file write `main_rd_profile_table' "\parbox{0.99\linewidth}{\footnotesize \textit{Notes:} The selected geography contains all RUV communities in Apurimac and Huancavelica, La Convencion province in Cusco, and Huancayo province in Junin. Linkage columns report the percentage of each component linked to the indicated source. Treatment columns report cumulative CMAN project receipt through the listed recorded year. The CMAN year is not yet verified as project completion. Sources: RUV Libro Segundo, CMAN register through 2023, 2007 Census CCPP tabulation, and 2017 CCPP spatial source.}" _n
file write `main_rd_profile_table' "\end{table}" _n
file close `main_rd_profile_table'
restore

tempname main_rd_comparison_post
tempfile main_rd_comparison

postfile `main_rd_comparison_post' ///
    int row_order ///
    str64 characteristic ///
    double selected_n ///
    double selected_mean ///
    double remaining_n ///
    double remaining_mean ///
    double standardized_difference ///
    using "`main_rd_comparison'", replace

local comparison_variable_1 victimization_index
local comparison_label_1 "Victimization index"
local comparison_scale_1 1
local comparison_variable_2 priority_ab
local comparison_label_2 "RUV category A or B (percent)"
local comparison_scale_2 100
local comparison_variable_3 population_2007
local comparison_label_3 "Population, 2007"
local comparison_scale_3 1
local comparison_variable_4 urban_2007
local comparison_label_4 "Urban centro poblado, 2007 (percent)"
local comparison_scale_4 100
local comparison_variable_5 wellbeing_core_2007
local comparison_label_5 "Baseline wellbeing score, 2007"
local comparison_scale_5 1
local comparison_variable_6 altitude_m_2017
local comparison_label_6 "Altitude (meters)"
local comparison_scale_6 1
local comparison_variable_7 dist_dist_capital_km
local comparison_label_7 "Distance to corresponding district capital (km)"
local comparison_scale_7 1
local comparison_variable_8 census2007_linked
local comparison_label_8 "Linked to Census 2007 (percent)"
local comparison_scale_8 100
local comparison_variable_9 geospatial_linked
local comparison_label_9 "Linked to spatial source (percent)"
local comparison_scale_9 100
local comparison_variable_10 treat_12
local comparison_label_10 "Collective reparations by 2012 (percent)"
local comparison_scale_10 100
local comparison_variable_11 treat_16
local comparison_label_11 "Collective reparations by 2016 (percent)"
local comparison_scale_11 100
local comparison_variable_12 treat_23
local comparison_label_12 "Collective reparations by 2023 (percent)"
local comparison_scale_12 100

forvalues comparison_index = 1/12 {
    local comparison_variable ///
        "`comparison_variable_`comparison_index''"
    local comparison_label ///
        "`comparison_label_`comparison_index''"
    local comparison_scale = ///
        `comparison_scale_`comparison_index''

    quietly summarize `comparison_variable' if sample_main_rd
    local selected_n = r(N)
    local selected_mean = r(mean)
    local selected_sd = r(sd)

    quietly summarize `comparison_variable' if !sample_main_rd
    local remaining_n = r(N)
    local remaining_mean = r(mean)
    local remaining_sd = r(sd)

    local pooled_sd = sqrt( ///
        ((`selected_n' - 1) * `selected_sd'^2 + ///
         (`remaining_n' - 1) * `remaining_sd'^2) / ///
        (`selected_n' + `remaining_n' - 2))
    local standardized_difference = ///
        (`selected_mean' - `remaining_mean') / `pooled_sd'

    post `main_rd_comparison_post' ///
        (`comparison_index') ///
        ("`comparison_label'") ///
        (`selected_n') ///
        (`selected_mean' * `comparison_scale') ///
        (`remaining_n') ///
        (`remaining_mean' * `comparison_scale') ///
        (`standardized_difference')
}
postclose `main_rd_comparison_post'

preserve
use "`main_rd_comparison'", clear
isid row_order
sort row_order

export delimited ///
    "`table_dir'/rd_main_sample_comparison.csv", ///
    replace

tempname main_rd_comparison_table
file open `main_rd_comparison_table' ///
    using "`table_dir'/tab_desc_11_main_rd_sample_comparison.tex", ///
    write replace text

file write `main_rd_comparison_table' "\begin{table}[!htbp]" _n
file write `main_rd_comparison_table' "\centering" _n
file write `main_rd_comparison_table' "\caption{Descriptive comparison of the selected RD geography and remaining RUV universe}" _n
file write `main_rd_comparison_table' "\label{tab:desc_main_rd_sample_comparison}" _n
file write `main_rd_comparison_table' "\begin{tabular}{lrrrrr}" _n
file write `main_rd_comparison_table' "\toprule" _n
file write `main_rd_comparison_table' "Characteristic & Selected N & Selected mean & Remaining N & Remaining mean & Standardized difference \\" _n
file write `main_rd_comparison_table' "\midrule" _n

forvalues comparison_index = 1/`=_N' {
    local characteristic_text ///
        "`=characteristic[`comparison_index']'"
    local selected_n_fmt : display ///
        %9.0fc selected_n[`comparison_index']
    local remaining_n_fmt : display ///
        %9.0fc remaining_n[`comparison_index']
    local mean_format "%7.3f"

    if inlist(row_order[`comparison_index'], 2, 4, 8, 9, 10, 11, 12) {
        local mean_format "%6.1f"
    }
    else if inlist(row_order[`comparison_index'], 3, 6) {
        local mean_format "%9.1f"
    }
    else if row_order[`comparison_index'] == 7 {
        local mean_format "%7.1f"
    }

    local selected_mean_fmt : display `mean_format' ///
        selected_mean[`comparison_index']
    local remaining_mean_fmt : display `mean_format' ///
        remaining_mean[`comparison_index']
    local standardized_difference_fmt : display %6.2f ///
        standardized_difference[`comparison_index']

    foreach formatted_value in ///
        selected_n_fmt ///
        remaining_n_fmt ///
        selected_mean_fmt ///
        remaining_mean_fmt ///
        standardized_difference_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `main_rd_comparison_table' ///
        "`characteristic_text' & `selected_n_fmt' & `selected_mean_fmt' & `remaining_n_fmt' & `remaining_mean_fmt' & `standardized_difference_fmt' \\" _n
}

file write `main_rd_comparison_table' "\bottomrule" _n
file write `main_rd_comparison_table' "\end{tabular}" _n
file write `main_rd_comparison_table' "\parbox{0.99\linewidth}{\footnotesize \textit{Notes:} The selected group is the 1,162-community legacy geography encoded by \texttt{sample\_main\_rd}; the remaining group contains 4,550 RUV communities. Each row uses all nonmissing observations for that characteristic. The standardized difference is the selected-minus-remaining mean divided by the pooled standard deviation. Treatment variables are post-assignment descriptions; this is neither a balance test nor a causal comparison, and no significance tests are reported. Sources: RUV Libro Segundo, CMAN register through 2023, 2007 Census CCPP tabulation, and 2017 CCPP spatial source.}" _n
file write `main_rd_comparison_table' "\end{table}" _n
file close `main_rd_comparison_table'
restore


*-----------------------------------*
**# 8. CMAN project types and financing
*-----------------------------------*

/*
These exhibits use all 4,433 rows in the canonical CMAN project register,
including projects outside the 2018-vintage RUV universe. They describe
implementation content and recorded nominal financing, not treatment effects.
*/

preserve
use "`project_input_file'", clear

isid record_number
assert _N == 4433
assert inrange(recorded_project_year, 2007, 2023)
assert !missing(prc_project_type, prc_project_group)
assert inlist(prc_project_multisector, 0, 1)
assert inlist(prc_project_class_method, 1, 2)
assert inlist(prc_cofinanced, 0, 1)
assert prc_total_financing_soles == ///
    cman_financing_soles + cofinancing_soles
assert abs(prc_cofinancing_share - ///
    cofinancing_soles / prc_total_financing_soles) < 1e-12

quietly count if prc_project_class_method == 2
assert r(N) == 1
quietly count if prc_cofinanced
local n_cman_cofinanced = r(N)
local n_cman_projects = _N

quietly datasignature
local project_input_datasignature "`r(datasignature)'"

tempfile project_registry
save "`project_registry'", replace

collapse ///
    (count) project_count=record_number, ///
    by(prc_project_type)

egen int total_projects = total(project_count)
assert total_projects == `n_cman_projects'
generate double project_share = ///
    100 * project_count / total_projects

graph hbar (asis) project_share, ///
    over(prc_project_type, ///
        sort(1) descending label(labsize(small))) ///
    bar(1, color(navy%78) lcolor(navy)) ///
    blabel(bar, ///
        format(%4.1f) position(outside) size(small) color(gs4)) ///
    yscale(range(0 30)) ///
    ylabel(0(5)30, ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Share of CMAN project records (%)", size(small)) ///
    title("Collective-reparation projects by primary type", ///
        size(medium) color(black)) ///
    subtitle("Transparent text classification of all projects recorded through 2023", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the CMAN project record (N = 4,433). Each normalized Spanish title receives one primary type using the documented" ///
        "dictionary and priority hierarchy; multisector titles retain a separate flag. Percentages sum to 100. No model or statistical uncertainty is used." ///
        "Source: CMAN communities-attended register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_16_project_types.png", ///
    width(2400) replace

use "`project_registry'", clear
generate double positive_cofinancing_thousands = ///
    cofinancing_soles / 1000 if prc_cofinanced

collapse ///
    (mean) cofinanced_percent=prc_cofinanced ///
    (p50) median_positive_cofinancing=positive_cofinancing_thousands, ///
    by(prc_project_type)

replace cofinanced_percent = 100 * cofinanced_percent

graph hbar (asis) cofinanced_percent, ///
    over(prc_project_type, ///
        sort(cofinanced_percent) descending label(labsize(vsmall))) ///
    bar(1, color(navy%78) lcolor(navy)) ///
    blabel(bar, ///
        format(%4.1f) position(outside) size(vsmall) color(gs4)) ///
    yscale(range(0 100)) ///
    ylabel(0(20)100, ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Projects with positive cofinancing (%)", size(small)) ///
    title("Incidence of cofinancing", size(medsmall) color(black)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(desc_project_cofinance_rate, replace)

graph hbar (asis) median_positive_cofinancing, ///
    over(prc_project_type, ///
        sort(cofinanced_percent) descending label(labsize(vsmall))) ///
    bar(1, color(eltblue%85) lcolor(navy)) ///
    blabel(bar, ///
        format(%5.1f) position(outside) size(vsmall) color(gs4)) ///
    yscale(range(0 80)) ///
    ylabel(0(20)80, ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Median cofinancing among positive records (S/ thousands)", ///
        size(small)) ///
    title("Conditional cofinancing amount", ///
        size(medsmall) color(black)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(desc_project_cofinance_amount, replace)

graph combine ///
    desc_project_cofinance_rate ///
    desc_project_cofinance_amount, ///
    cols(2) xsize(13) ysize(7.5) ///
    title("Cofinancing of collective-reparation projects", ///
        size(medium) color(black)) ///
    subtitle("Incidence and conditional median amount by primary project type", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the CMAN project record (N = 4,433). Positive cofinancing is recorded for `n_cman_cofinanced' projects." ///
        "Panel B excludes zero-cofinancing records and reports nominal soles divided by 1,000; amounts are not inflation-adjusted." ///
        "Project types come from the documented title-based classification. Source: CMAN communities-attended register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_17_project_cofinancing.png", ///
    width(3000) replace
graph drop ///
    desc_project_cofinance_rate ///
    desc_project_cofinance_amount

use "`project_registry'", clear
generate double total_financing_thousands = ///
    prc_total_financing_soles / 1000

collapse ///
    (count) project_count=record_number ///
    (mean) cofinanced_percent=prc_cofinanced ///
    (p50) median_total_financing=total_financing_thousands, ///
    by(recorded_project_year)

replace cofinanced_percent = 100 * cofinanced_percent

twoway ///
    (connected cofinanced_percent recorded_project_year, ///
        lcolor(navy) lwidth(medthick) ///
        mcolor(navy) msymbol(O) msize(small)), ///
    xlabel(2007(2)2023, labsize(small)) ///
    ylabel(0(20)100, ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    xtitle("Recorded project year", size(small)) ///
    ytitle("Projects with positive cofinancing (%)", size(small)) ///
    title("Cofinancing incidence", size(medsmall) color(black)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(desc_project_cofinance_year, replace)

twoway ///
    (connected median_total_financing recorded_project_year, ///
        lcolor(forest_green) lwidth(medthick) ///
        mcolor(forest_green) msymbol(D) msize(small)), ///
    xlabel(2007(2)2023, labsize(small)) ///
    ylabel(, ///
        grid glcolor(gs14) glwidth(vthin) ///
        format(%5.0f) labsize(small)) ///
    xtitle("Recorded project year", size(small)) ///
    ytitle("Median total recorded financing (S/ thousands)", size(small)) ///
    title("Combined CMAN and cofinancing amount", ///
        size(medsmall) color(black)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(desc_project_total_year, replace)

graph combine ///
    desc_project_cofinance_year ///
    desc_project_total_year, ///
    cols(2) xsize(12) ysize(6.5) ///
    title("Project financing over the program rollout", ///
        size(medium) color(black)) ///
    subtitle("Recorded cofinancing incidence and median combined financing, 2007-2023", ///
        size(small) color(gs5)) ///
    note( ///
        "Notes: Unit of analysis is the CMAN project record. Annual project counts vary and are reported in the companion table." ///
        "Total financing is CMAN financing plus cofinancing in nominal soles divided by 1,000; no inflation adjustment or causal comparison is applied." ///
        "Source: CMAN communities-attended register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    graphregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_18_project_financing_over_time.png", ///
    width(2800) replace
graph drop ///
    desc_project_cofinance_year ///
    desc_project_total_year

/*
Annual composition is shown with four broad groups so every year remains
readable. The companion period table retains all fourteen primary types.
*/

use "`project_registry'", clear
collapse ///
    (count) project_count=record_number, ///
    by(recorded_project_year prc_project_group)

bysort recorded_project_year: egen int annual_projects = ///
    total(project_count)
generate double project_group_share = ///
    100 * project_count / annual_projects
keep recorded_project_year prc_project_group project_group_share
reshape wide project_group_share, ///
    i(recorded_project_year) j(prc_project_group)

forvalues project_group = 1/4 {
    replace project_group_share`project_group' = 0 if ///
        missing(project_group_share`project_group')
}

egen double annual_share_check = ///
    rowtotal(project_group_share1-project_group_share4)
assert abs(annual_share_check - 100) < 1e-8

graph bar (asis) ///
    project_group_share1 ///
    project_group_share2 ///
    project_group_share3 ///
    project_group_share4, ///
    over(recorded_project_year, ///
        label(angle(45) labsize(small))) ///
    stack ///
    bar(1, color(navy%88) lcolor(white)) ///
    bar(2, color(teal%82) lcolor(white)) ///
    bar(3, color(orange%82) lcolor(white)) ///
    bar(4, color(maroon%78) lcolor(white)) ///
    ylabel(0(20)100, ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    ytitle("Annual share (%)", size(small)) ///
    title("Composition of collective-reparation projects over time", ///
        size(medium) color(black)) ///
    subtitle("Annual shares by broad project group, 2007-2023", ///
        size(small) color(gs5)) ///
    legend( ///
        order( ///
            1 "Productive/livelihood" ///
            2 "Social/basic services" ///
            3 "Community/civic infrastructure" ///
            4 "Management/capacity") ///
        rows(2) position(6) size(vsmall) region(lcolor(none))) ///
    note( ///
        "Notes: Unit of analysis is the CMAN project record (N = 4,433). Bars sum to 100 percent within recorded project year; annual counts vary." ///
        "Broad groups aggregate the fourteen documented title-based primary categories. Recorded year need not equal project completion." ///
        "No model or statistical uncertainty is used. Source: CMAN communities-attended register through 2023.", ///
        size(vsmall) color(gs5) span) ///
    xsize(12) ysize(7) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export ///
    "`figure_dir'/fig_desc_19_project_composition_over_time.png", ///
    width(2800) replace

/*
Project-type table: the median cofinancing amount conditions on a positive
cofinancing record; the total-financing median uses every project.
*/

use "`project_registry'", clear
tempname project_type_table
file open `project_type_table' ///
    using "`table_dir'/tab_desc_06_project_types_financing.tex", ///
    write replace text

file write `project_type_table' "\begin{table}[!htbp]" _n
file write `project_type_table' "\centering" _n
file write `project_type_table' "\caption{Collective-reparation project types and recorded financing}" _n
file write `project_type_table' "\label{tab:desc_project_types_financing}" _n
file write `project_type_table' "\begin{tabular}{lrrrrrr}" _n
file write `project_type_table' "\toprule" _n
file write `project_type_table' "Primary project type & Projects & Share (\%) & Cofinanced (\%) & Median cofinancing & Median total & Mean cofinancing share (\%) \\" _n
file write `project_type_table' " &  &  &  & (S/ thousands) & (S/ thousands) &  \\" _n
file write `project_type_table' "\midrule" _n

forvalues project_type = 1/14 {
    local project_type_label : label (prc_project_type) `project_type'

    quietly count if prc_project_type == `project_type'
    local project_type_n = r(N)
    local project_type_share = ///
        100 * `project_type_n' / `n_cman_projects'

    quietly summarize prc_cofinanced if ///
        prc_project_type == `project_type'
    local project_type_cofinanced = 100 * r(mean)

    quietly summarize cofinancing_soles if ///
        prc_project_type == `project_type' & ///
        prc_cofinanced, detail
    local project_type_cofinance_median = r(p50) / 1000

    quietly summarize prc_total_financing_soles if ///
        prc_project_type == `project_type', detail
    local project_type_total_median = r(p50) / 1000

    quietly summarize prc_cofinancing_share if ///
        prc_project_type == `project_type'
    local project_type_share_mean = 100 * r(mean)

    local type_n_fmt : display %9.0fc `project_type_n'
    local type_share_fmt : display %5.1f `project_type_share'
    local type_cofinanced_fmt : ///
        display %5.1f `project_type_cofinanced'
    local type_cofinance_med_fmt : ///
        display %7.1f `project_type_cofinance_median'
    local type_total_med_fmt : ///
        display %7.1f `project_type_total_median'
    local type_share_mean_fmt : ///
        display %5.1f `project_type_share_mean'

    foreach formatted_value in ///
        type_n_fmt ///
        type_share_fmt ///
        type_cofinanced_fmt ///
        type_cofinance_med_fmt ///
        type_total_med_fmt ///
        type_share_mean_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `project_type_table' ///
        "`project_type_label' & `type_n_fmt' & `type_share_fmt' & `type_cofinanced_fmt' & `type_cofinance_med_fmt' & `type_total_med_fmt' & `type_share_mean_fmt' \\" _n
}

file write `project_type_table' "\bottomrule" _n
file write `project_type_table' "\end{tabular}" _n
file write `project_type_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the CMAN project record (N = 4,433), including projects that do not link to the 2018-vintage RUV extract. Each normalized Spanish title receives one primary category using the versioned dictionary and priority hierarchy. Median cofinancing conditions on a positive value; median total financing uses all records. Amounts are nominal soles divided by 1,000 and are not inflation-adjusted. Source: CMAN communities-attended register through 2023.}" _n
file write `project_type_table' "\end{table}" _n
file close `project_type_table'

tempname project_year_table
file open `project_year_table' ///
    using "`table_dir'/tab_desc_07_project_financing_by_year.tex", ///
    write replace text

file write `project_year_table' "\begin{table}[!htbp]" _n
file write `project_year_table' "\centering" _n
file write `project_year_table' "\caption{Recorded financing of collective-reparation projects by year}" _n
file write `project_year_table' "\label{tab:desc_project_financing_year}" _n
file write `project_year_table' "\begin{tabular}{rrrrrr}" _n
file write `project_year_table' "\toprule" _n
file write `project_year_table' "Year & Projects & Cofinanced (\%) & Median CMAN & Median cofinancing & Median total \\" _n
file write `project_year_table' " &  &  & (S/ thousands) & (S/ thousands) & (S/ thousands) \\" _n
file write `project_year_table' "\midrule" _n

forvalues project_year = 2007/2023 {
    quietly count if recorded_project_year == `project_year'
    local project_year_n = r(N)

    quietly summarize prc_cofinanced if ///
        recorded_project_year == `project_year'
    local project_year_cofinanced = 100 * r(mean)

    quietly summarize cman_financing_soles if ///
        recorded_project_year == `project_year', detail
    local project_year_cman_median = r(p50) / 1000

    quietly summarize cofinancing_soles if ///
        recorded_project_year == `project_year' & ///
        prc_cofinanced, detail
    local project_year_cofinance_median = r(p50) / 1000

    quietly summarize prc_total_financing_soles if ///
        recorded_project_year == `project_year', detail
    local project_year_total_median = r(p50) / 1000

    local year_n_fmt : display %9.0fc `project_year_n'
    local year_cofinanced_fmt : ///
        display %5.1f `project_year_cofinanced'
    local year_cman_med_fmt : ///
        display %7.1f `project_year_cman_median'
    local year_cofinance_med_fmt : ///
        display %7.1f `project_year_cofinance_median'
    local year_total_med_fmt : ///
        display %7.1f `project_year_total_median'

    foreach formatted_value in ///
        year_n_fmt ///
        year_cofinanced_fmt ///
        year_cman_med_fmt ///
        year_cofinance_med_fmt ///
        year_total_med_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `project_year_table' ///
        "`project_year' & `year_n_fmt' & `year_cofinanced_fmt' & `year_cman_med_fmt' & `year_cofinance_med_fmt' & `year_total_med_fmt' \\" _n
}

file write `project_year_table' "\bottomrule" _n
file write `project_year_table' "\end{tabular}" _n
file write `project_year_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the CMAN project record. Cofinanced denotes a positive recorded amount. Median cofinancing conditions on positive values; other medians use all projects in the year. Amounts are nominal soles divided by 1,000 and are not inflation-adjusted. Recorded project year is the pipeline's authoritative treatment year but need not equal construction completion. Source: CMAN communities-attended register through 2023.}" _n
file write `project_year_table' "\end{table}" _n
file close `project_year_table'

/*
This table compares the composition recorded through the end of 2018 with the
composition of projects added from 2019 onward in the current CMAN register.
*/

quietly count if recorded_project_year <= 2018
local n_projects_2007_2018 = r(N)
quietly count if recorded_project_year >= 2019
local n_projects_2019_2023 = r(N)
assert `n_projects_2007_2018' + `n_projects_2019_2023' == ///
    `n_cman_projects'

local n_early_fmt : display %9.0fc `n_projects_2007_2018'
local n_late_fmt : display %9.0fc `n_projects_2019_2023'
local n_early_fmt = strtrim("`n_early_fmt'")
local n_late_fmt = strtrim("`n_late_fmt'")

tempname project_period_table
file open `project_period_table' ///
    using "`table_dir'/tab_desc_08_project_composition_periods.tex", ///
    write replace text

file write `project_period_table' "\begin{table}[!htbp]" _n
file write `project_period_table' "\centering" _n
file write `project_period_table' "\caption{Evolution of collective-reparation project composition}" _n
file write `project_period_table' "\label{tab:desc_project_composition_periods}" _n
file write `project_period_table' "\begin{tabular}{lrrrr}" _n
file write `project_period_table' "\toprule" _n
file write `project_period_table' "Primary project type & 2007--2018 & 2019--2023 & Change & All years \\" _n
file write `project_period_table' " & Share (\%) & Share (\%) & (percentage points) & Share (\%) \\" _n
file write `project_period_table' "\midrule" _n

forvalues project_type = 1/14 {
    local project_type_label : label (prc_project_type) `project_type'

    quietly count if ///
        prc_project_type == `project_type' & ///
        recorded_project_year <= 2018
    local project_type_early = ///
        100 * r(N) / `n_projects_2007_2018'

    quietly count if ///
        prc_project_type == `project_type' & ///
        recorded_project_year >= 2019
    local project_type_late = ///
        100 * r(N) / `n_projects_2019_2023'

    quietly count if prc_project_type == `project_type'
    local project_type_all = ///
        100 * r(N) / `n_cman_projects'
    local project_type_change = ///
        `project_type_late' - `project_type_early'

    local type_early_fmt : display %5.1f `project_type_early'
    local type_late_fmt : display %5.1f `project_type_late'
    local type_change_fmt : display %5.1f `project_type_change'
    local type_all_fmt : display %5.1f `project_type_all'

    foreach formatted_value in ///
        type_early_fmt ///
        type_late_fmt ///
        type_change_fmt ///
        type_all_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `project_period_table' ///
        "`project_type_label' & `type_early_fmt' & `type_late_fmt' & `type_change_fmt' & `type_all_fmt' \\" _n
}

file write `project_period_table' "\midrule" _n
file write `project_period_table' "All project types & 100.0 & 100.0 & 0.0 & 100.0 \\" _n
file write `project_period_table' "\bottomrule" _n
file write `project_period_table' "\end{tabular}" _n
file write `project_period_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the CMAN project record. The 2007--2018 period contains `n_early_fmt' projects and the 2019--2023 period contains `n_late_fmt' projects. This is a retrospective split of the complete current register, not a reproduction of the working paper's older extract. Change is the later-period share minus the earlier-period share. Each title receives one primary category through the documented Stata classification. Recorded year need not equal completion year. Source: CMAN communities-attended register through 2023.}" _n
file write `project_period_table' "\end{table}" _n
file close `project_period_table'
restore


*-----------------------------------*
**# 9. Academic descriptive tables
*-----------------------------------*

tempname coverage_table
file open `coverage_table' ///
    using "`table_dir'/tab_desc_01_sample_coverage.tex", ///
    write replace text

file write `coverage_table' "\begin{table}[!htbp]" _n
file write `coverage_table' "\centering" _n
file write `coverage_table' "\caption{Coverage of the foundational community registry}" _n
file write `coverage_table' "\label{tab:desc_sample_coverage}" _n
file write `coverage_table' "\begin{tabular}{lrr}" _n
file write `coverage_table' "\toprule" _n
file write `coverage_table' "Registry component & Communities & Share of RUV (\%) \\" _n
file write `coverage_table' "\midrule" _n

local coverage_counts ///
    `n_ruv' ///
    `n_ubigeo' ///
    `n_treated_2023' ///
    `n_not_recorded_2023' ///
    `n_census' ///
    `n_wellbeing' ///
    `n_spatial' ///
    `n_altitude'

forvalues coverage_index = 1/8 {
    if `coverage_index' == 1 local coverage_label "Complete RUV universe"
    if `coverage_index' == 2 local coverage_label "Verified ten-digit CCPP UBIGEO"
    if `coverage_index' == 3 local coverage_label "CMAN project linked by 2023"
    if `coverage_index' == 4 local coverage_label "No CMAN project recorded by 2023"
    if `coverage_index' == 5 local coverage_label "Linked 2007 Census tabulation"
    if `coverage_index' == 6 local coverage_label "Complete 2007 core wellbeing score"
    if `coverage_index' == 7 local coverage_label "Linked 2017 CCPP spatial spine"
    if `coverage_index' == 8 local coverage_label "2017 altitude attribute available"
    local coverage_count : word `coverage_index' of `coverage_counts'
    local coverage_count_fmt : display %9.0fc `coverage_count'
    local coverage_count_fmt = strtrim("`coverage_count_fmt'")
    local coverage_percent_fmt : display %5.1f ///
        (100 * `coverage_count' / `n_ruv')
    local coverage_percent_fmt = strtrim("`coverage_percent_fmt'")

    file write `coverage_table' ///
        "`coverage_label' & `coverage_count_fmt' & `coverage_percent_fmt' \\" _n
}

file write `coverage_table' "\bottomrule" _n
file write `coverage_table' "\end{tabular}" _n
file write `coverage_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the RUV centro poblado. All percentages use the complete 5,712-community RUV universe as the denominator. Missing downstream links do not remove an RUV observation. After exhaustive reconciliation, absence from the CMAN roster defines untreated status through 2023 under the current treatment rule. Sources: RUV, CMAN 2023, 2007 Census CCPP tabulation, and 2017 GeoGPS/INEI CCPP information.}" _n
file write `coverage_table' "\end{table}" _n
file close `coverage_table'

tempname summary_table
file open `summary_table' ///
    using "`table_dir'/tab_desc_02_summary_statistics.tex", ///
    write replace text

file write `summary_table' "\begin{table}[!htbp]" _n
file write `summary_table' "\centering" _n
file write `summary_table' "\caption{Summary statistics for the complete RUV universe}" _n
file write `summary_table' "\label{tab:desc_summary_statistics}" _n
file write `summary_table' "\begin{tabular}{lrrrrrr}" _n
file write `summary_table' "\toprule" _n
file write `summary_table' "Variable & N & Mean & SD & P25 & Median & P75 \\" _n
file write `summary_table' "\midrule" _n

local summary_variables ///
    victimization_index ///
    deaths ///
    disappearances ///
    torture ///
    displaced ///
    incursions ///
    population_2007 ///
    households_2007 ///
    wellbeing_core_2007 ///
    altitude_m_2017 ///
    dist_dist_capital_km ///
    dist_prov_capital_km ///
    dist_dept_capital_km ///
    dist_nearest_city_km

foreach summary_variable of local summary_variables {
    quietly summarize `summary_variable', detail
    local summary_label : variable label `summary_variable'
    local summary_n : display %9.0fc r(N)
    local summary_mean : display %9.3f r(mean)
    local summary_sd : display %9.3f r(sd)
    local summary_p25 : display %9.3f r(p25)
    local summary_p50 : display %9.3f r(p50)
    local summary_p75 : display %9.3f r(p75)

    foreach formatted_value in ///
        summary_n ///
        summary_mean ///
        summary_sd ///
        summary_p25 ///
        summary_p50 ///
        summary_p75 {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `summary_table' ///
        "`summary_label' & `summary_n' & `summary_mean' & `summary_sd' & `summary_p25' & `summary_p50' & `summary_p75' \\" _n
}

file write `summary_table' "\bottomrule" _n
file write `summary_table' "\end{tabular}" _n
file write `summary_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the RUV centro poblado. The victimization score and component counts use all 5,712 RUV records. Census and geospatial variables use every linked nonmissing observation and report their exact N. Distance variables are straight-line geodesic kilometers. The baseline wellbeing score ranges from zero to one and is not an official poverty measure. No sample restriction, weighting, or statistical test is applied. Sources: RUV, 2007 Census CCPP tabulation, and 2017 GeoGPS/INEI CCPP information.}" _n
file write `summary_table' "\end{table}" _n
file close `summary_table'

tempname category_table
file open `category_table' ///
    using "`table_dir'/tab_desc_03_victimization_categories.tex", ///
    write replace text

file write `category_table' "\begin{table}[!htbp]" _n
file write `category_table' "\centering" _n
file write `category_table' "\caption{Victimization categories and cumulative treatment coverage}" _n
file write `category_table' "\label{tab:desc_victimization_categories}" _n
file write `category_table' "\begin{tabular}{lrrrrrrrr}" _n
file write `category_table' "\toprule" _n
file write `category_table' "Category & N & Score min. & Score median & Score max. & Treated 2013 (\%) & Treated 2017 (\%) & Treated 2023 (\%) & Wellbeing 2007 \\" _n
file write `category_table' "\midrule" _n

foreach victimization_category in A B C D E {
    quietly count if victimization_level_source == "`victimization_category'"
    local category_n = r(N)
    quietly summarize victimization_index ///
        if victimization_level_source == "`victimization_category'", detail
    local category_min = r(min)
    local category_median = r(p50)
    local category_max = r(max)

    foreach treatment_year in 13 17 23 {
        quietly summarize treat_`treatment_year' ///
            if victimization_level_source == "`victimization_category'"
        local category_treat_`treatment_year' = 100 * r(mean)
    }

    quietly summarize wellbeing_core_2007 ///
        if victimization_level_source == "`victimization_category'"
    local category_wellbeing = r(mean)

    local category_n_fmt : display %9.0fc `category_n'
    local category_min_fmt : display %7.4f `category_min'
    local category_median_fmt : display %7.4f `category_median'
    local category_max_fmt : display %7.4f `category_max'
    local category_treat_13_fmt : display %5.1f `category_treat_13'
    local category_treat_17_fmt : display %5.1f `category_treat_17'
    local category_treat_23_fmt : display %5.1f `category_treat_23'
    local category_wellbeing_fmt : display %5.3f `category_wellbeing'

    foreach formatted_value in ///
        category_n_fmt ///
        category_min_fmt ///
        category_median_fmt ///
        category_max_fmt ///
        category_treat_13_fmt ///
        category_treat_17_fmt ///
        category_treat_23_fmt ///
        category_wellbeing_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `category_table' ///
        "`victimization_category' & `category_n_fmt' & `category_min_fmt' & `category_median_fmt' & `category_max_fmt' & `category_treat_13_fmt' & `category_treat_17_fmt' & `category_treat_23_fmt' & `category_wellbeing_fmt' \\" _n
}

file write `category_table' "\bottomrule" _n
file write `category_table' "\end{tabular}" _n
file write `category_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} Categories A-E and the observed score are supplied by RUV. Treatment percentages are unconditional means of the cumulative CMAN indicators. Baseline wellbeing is the mean equal-domain 2007 score among linked communities with complete components. The rounded RUV score can tie across official six-decimal thresholds; this table does not infer assignment side from the score or conduct adjacent-category tests. Sources: RUV, CMAN 2023, and 2007 Census CCPP tabulation.}" _n
file write `category_table' "\end{table}" _n
file close `category_table'

tempname rollout_table
file open `rollout_table' ///
    using "`table_dir'/tab_desc_04_treatment_rollout.tex", ///
    write replace text

file write `rollout_table' "\begin{table}[!htbp]" _n
file write `rollout_table' "\centering" _n
file write `rollout_table' "\caption{Collective-reparation rollout by recorded project year}" _n
file write `rollout_table' "\label{tab:desc_treatment_rollout}" _n
file write `rollout_table' "\begin{tabular}{rrrr}" _n
file write `rollout_table' "\toprule" _n
file write `rollout_table' "Year & Newly treated & Cumulative treated & Share of RUV (\%) \\" _n
file write `rollout_table' "\midrule" _n

local cumulative_treated = 0

forvalues treatment_year = 2007/2023 {
    quietly count if recorded_project_year == `treatment_year'
    local newly_treated = r(N)
    local cumulative_treated = `cumulative_treated' + `newly_treated'
    local cumulative_percent = 100 * `cumulative_treated' / `n_ruv'
    local newly_treated_fmt : display %9.0fc `newly_treated'
    local cumulative_treated_fmt : display %9.0fc `cumulative_treated'
    local cumulative_percent_fmt : display %5.1f `cumulative_percent'

    foreach formatted_value in ///
        newly_treated_fmt ///
        cumulative_treated_fmt ///
        cumulative_percent_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `rollout_table' ///
        "`treatment_year' & `newly_treated_fmt' & `cumulative_treated_fmt' & `cumulative_percent_fmt' \\" _n
}

assert `cumulative_treated' == `n_treated_2023'

file write `rollout_table' "\bottomrule" _n
file write `rollout_table' "\end{tabular}" _n
file write `rollout_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the RUV centro poblado. A community enters its treatment cohort in the first project year recorded in the CMAN roster and remains treated thereafter. The denominator for the cumulative percentage is all 5,712 RUV communities. The 1,491 communities without a linked CMAN project by 2023 remain untreated under the current rule. Source: CMAN 2023 project roster linked to RUV Libro Segundo.}" _n
file write `rollout_table' "\end{table}" _n
file close `rollout_table'

preserve
collapse ///
    (count) communities=victimization_index ///
    (mean) treated_share=treat_23 ///
    (mean) mean_score=victimization_index ///
    (mean) mean_wellbeing=wellbeing_core_2007, ///
    by(dpto_victim_raw)
replace treated_share = 100 * treated_share
generate str20 department = proper(lower(dpto_victim_raw))
gsort -communities department

tempname department_table
file open `department_table' ///
    using "`table_dir'/tab_desc_05_department_profile.tex", ///
    write replace text

file write `department_table' "\begin{table}[!htbp]" _n
file write `department_table' "\centering" _n
file write `department_table' "\caption{Department composition of the RUV-CMAN registry}" _n
file write `department_table' "\label{tab:desc_department_profile}" _n
file write `department_table' "\begin{tabular}{lrrrr}" _n
file write `department_table' "\toprule" _n
file write `department_table' "Department & Communities & Share treated by 2023 (\%) & Mean victimization score & Mean wellbeing 2007 \\" _n
file write `department_table' "\midrule" _n

forvalues department_index = 1/`=_N' {
    local department_name "`=department[`department_index']'"
    local department_n = communities[`department_index']
    local department_treated = treated_share[`department_index']
    local department_score = mean_score[`department_index']
    local department_wellbeing = mean_wellbeing[`department_index']

    local department_n_fmt : display %9.0fc `department_n'
    local department_treated_fmt : display %5.1f `department_treated'
    local department_score_fmt : display %7.4f `department_score'
    local department_wellbeing_fmt : display %5.3f `department_wellbeing'

    foreach formatted_value in ///
        department_n_fmt ///
        department_treated_fmt ///
        department_score_fmt ///
        department_wellbeing_fmt {

        local `formatted_value' = strtrim("``formatted_value''")
    }

    file write `department_table' ///
        "`department_name' & `department_n_fmt' & `department_treated_fmt' & `department_score_fmt' & `department_wellbeing_fmt' \\" _n
}

file write `department_table' "\bottomrule" _n
file write `department_table' "\end{tabular}" _n
file write `department_table' "\parbox{0.98\linewidth}{\footnotesize \textit{Notes:} The unit is the RUV centro poblado. Departments use the RUV source geography. Treatment is cumulative CMAN project receipt through 2023. Mean baseline wellbeing uses linked 2007 communities with complete core-score components and therefore has a department-specific nonmissing sample. The table is descriptive and does not define, rank, or select an RD geography. Sources: RUV, CMAN 2023, and 2007 Census CCPP tabulation.}" _n
file write `department_table' "\end{table}" _n
file close `department_table'
restore


*-----------------------------------*
**# 10. Output validation and manifest
*-----------------------------------*

foreach output_path of local output_paths {
    capture quietly checksum "${project_root}/`output_path'"

    if _rc {
        /*
        Windows can briefly retain a just-exported PNG handle. Retry the exact
        read-only check before treating the artifact as absent.
        */
        sleep 500
        capture quietly checksum "${project_root}/`output_path'"

        if _rc {
            display as error "Expected descriptive output was not created:"
            display as error "  ${project_root}/`output_path'"
            exit 603
        }
    }

    assert r(filelen) > 100
}

local output_ids ///
    fig_desc_01 ///
    fig_desc_02 ///
    fig_desc_03 ///
    fig_desc_04 ///
    fig_desc_05 ///
    fig_desc_06 ///
    fig_desc_07 ///
    fig_desc_08 ///
    fig_desc_09 ///
    fig_desc_10 ///
    fig_desc_11 ///
    fig_desc_12 ///
    fig_desc_13 ///
    fig_desc_14 ///
    fig_desc_15 ///
    fig_desc_16 ///
    fig_desc_17 ///
    fig_desc_18 ///
    fig_desc_19 ///
    tab_desc_01 ///
    tab_desc_02 ///
    tab_desc_03 ///
    tab_desc_04 ///
    tab_desc_05 ///
    tab_desc_06 ///
    tab_desc_07 ///
    tab_desc_08 ///
    fig_desc_20 ///
    rd_rollout_category_year ///
    tab_desc_09 ///
    fig_desc_21 ///
    fig_desc_22 ///
    rd_main_sample_geographic_profile ///
    rd_main_sample_comparison ///
    tab_desc_10 ///
    tab_desc_11
local output_types ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    figure ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    table ///
    figure ///
    table ///
    table ///
    figure ///
    figure ///
    table ///
    table ///
    table ///
    table
local output_specs ///
    full_ruv_score_distribution ///
    full_ruv_component_prevalence ///
    full_ruv_treatment_rollout ///
    full_ruv_treatment_by_category ///
    full_ruv_binned_treatment_profile ///
    full_ruv_department_profile ///
    full_ruv_linkage_coverage ///
    linked_2007_wellbeing_domains ///
    linked_2007_wellbeing_by_category ///
    linked_2017_geospatial_context ///
    linked_2017_point_distribution ///
    full_ruv_department_count_map ///
    full_ruv_department_treated_map ///
    full_ruv_department_treatment_share_map ///
    full_ruv_department_index_maps ///
    full_cman_project_type_distribution ///
    full_cman_cofinancing_by_project_type ///
    full_cman_project_financing_by_year ///
    full_cman_project_composition_by_year ///
    full_ruv_sample_coverage ///
    full_ruv_summary_statistics ///
    full_ruv_category_profile ///
    full_ruv_treatment_rollout ///
    full_ruv_department_profile ///
    full_cman_project_type_financing_table ///
    full_cman_project_financing_year_table ///
    full_cman_project_composition_period_table ///
    full_ruv_category_rollout_over_time ///
    full_ruv_category_rollout_year_data ///
    full_ruv_category_rollout_year_table ///
    selected_main_rd_geographic_map ///
    selected_main_rd_composition_profile ///
    selected_main_rd_geographic_profile_data ///
    selected_main_rd_comparison_data ///
    selected_main_rd_geographic_profile_table ///
    selected_main_rd_comparison_table
local output_count : word count `output_paths'
assert `output_count' == 36
assert `output_count' == `: word count `output_ids''
assert `output_count' == `: word count `output_types''
assert `output_count' == `: word count `output_specs''

tempname output_manifest
file open `output_manifest' using "`manifest'", write replace text
file write `output_manifest' ///
    "output_id,relative_path,artifact_type,producing_script,input_snapshot,input_datasignature,unit_of_analysis,specification,stata_version,generation_date,stata_checksum,file_bytes,disclosure_status,manuscript_destination" _n

forvalues output_index = 1/`output_count' {
    local output_path : word `output_index' of `output_paths'
    local output_id : word `output_index' of `output_ids'
    local output_type : word `output_index' of `output_types'
    local output_spec : word `output_index' of `output_specs'
    local disclosure_status "aggregate_internal_review"
    local output_input "07_community_registry_gdp.dta"
    local output_datasignature "`input_datasignature'"
    local output_unit "RUV centro poblado"

    if "`output_id'" == "fig_desc_11" {
        local disclosure_status "point_map_review_required"
    }

    if inlist( ///
        "`output_id'", ///
        "fig_desc_12", ///
        "fig_desc_13", ///
        "fig_desc_14", ///
        "fig_desc_15", ///
        "fig_desc_21") {

        local disclosure_status "boundary_source_review_required"
    }

    if inrange(`output_index', 12, 15) {
        local output_input ///
            "07_community_registry_gdp.dta+locked_legacy_department_geometry"
    }

    if "`output_id'" == "fig_desc_21" {
        local output_input ///
            "07_community_registry_gdp.dta+locked_legacy_province_geometry"
    }

    if inrange(`output_index', 16, 19) | ///
       inrange(`output_index', 25, 27) {
        local output_input "03_cman_projects_2023.dta"
        local output_datasignature "`project_input_datasignature'"
        local output_unit "CMAN project record"
    }

    quietly checksum "${project_root}/`output_path'"
    local output_checksum : display %20.0f r(checksum)
    local output_bytes : display %20.0f r(filelen)
    local output_checksum = strtrim("`output_checksum'")
    local output_bytes = strtrim("`output_bytes'")

    file write `output_manifest' ///
        `""`output_id'","`output_path'","`output_type'","code/stata/pipeline/02_describe_data.do","`output_input'","`output_datasignature'","`output_unit'","`output_spec'","Stata `c(stata_version)'","`c(current_date)'","`output_checksum'","`output_bytes'","`disclosure_status'","not_assigned""' _n
}
file close `output_manifest'

capture confirm file "`manifest'"
assert !_rc
quietly checksum "`manifest'"
assert r(filelen) > 500

display as result "Descriptive analysis completed for all `n_ruv' RUV communities."
display as text   "Figures: `figure_dir'"
display as text   "Tables:  `table_dir'"
display as text   "Manifest: `manifest'"
