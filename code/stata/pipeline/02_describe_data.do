/*------------------------------------------------------------------------------
| Title:            Full-universe descriptive analysis                         |
| Project:          Victimas RD                                                |
| Unit:             RUV centro poblado                                         |
| Input:            06_community_registry_geospatial.dta                       |
| Outputs:          Aggregate tables, figures, and output manifest             |
| Description:      Describes the complete RUV universe without selecting an   |
|                   RD geography, estimating discontinuities, or testing       |
|                   outcomes.                                                   |
-------------------------------------------------------------------------------*/

version 19
set more off


*-----------------------------------*
**# 1. Input and output contracts
*-----------------------------------*

foreach required_global in ///
    project_root ///
    data_root ///
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
    "${analysis_data_root}/06_community_registry_geospatial.dta"
local figure_dir "${figures_root}/descriptive"
local table_dir  "${tables_root}/descriptive"
local manifest  "${metadata_root}/output-manifest.csv"
local department_map_data   "${data_root}/data_dpto.dta"
local department_map_coords "${data_root}/coor_dpto.dta"

capture confirm file "`input_file'"

if _rc {
    display as error "Canonical descriptive input was not found:"
    display as error "  `input_file'"
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
    output/tables/descriptive/tab_desc_01_sample_coverage.tex ///
    output/tables/descriptive/tab_desc_02_summary_statistics.tex ///
    output/tables/descriptive/tab_desc_03_victimization_categories.tex ///
    output/tables/descriptive/tab_desc_04_treatment_rollout.tex ///
    output/tables/descriptive/tab_desc_05_department_profile.tex

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
    "`department_map_coords'" {

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

use "`input_file'", clear

isid ruv_id
assert _N == 5712
assert !missing(victimization_index)
assert inlist(victimization_level_source, "A", "B", "C", "D", "E")
assert victimization_index >= 0
assert inlist(ubigeo_ccpp_verified, 0, 1)
assert inlist(census2007_linked, 0, 1)
assert inlist(geospatial_linked, 0, 1)

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

assert `n_treated_2023' == 4221
assert `n_not_recorded_2023' == 1491
assert `n_treated_2023' + `n_not_recorded_2023' == `n_ruv'

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
**# 7. Academic descriptive tables
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
**# 8. Output validation and manifest
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
    tab_desc_01 ///
    tab_desc_02 ///
    tab_desc_03 ///
    tab_desc_04 ///
    tab_desc_05
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
    table ///
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
    full_ruv_sample_coverage ///
    full_ruv_summary_statistics ///
    full_ruv_category_profile ///
    full_ruv_treatment_rollout ///
    full_ruv_department_profile
local disclosure_statuses ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    point_map_review_required ///
    boundary_source_review_required ///
    boundary_source_review_required ///
    boundary_source_review_required ///
    boundary_source_review_required ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review ///
    aggregate_internal_review

local output_count : word count `output_paths'
assert `output_count' == 20
assert `output_count' == `: word count `output_ids''
assert `output_count' == `: word count `output_types''
assert `output_count' == `: word count `output_specs''
assert `output_count' == `: word count `disclosure_statuses''

tempname output_manifest
file open `output_manifest' using "`manifest'", write replace text
file write `output_manifest' ///
    "output_id,relative_path,artifact_type,producing_script,input_snapshot,input_datasignature,unit_of_analysis,specification,stata_version,generation_date,stata_checksum,file_bytes,disclosure_status,manuscript_destination" _n

forvalues output_index = 1/`output_count' {
    local output_path : word `output_index' of `output_paths'
    local output_id : word `output_index' of `output_ids'
    local output_type : word `output_index' of `output_types'
    local output_spec : word `output_index' of `output_specs'
    local disclosure_status : word `output_index' of `disclosure_statuses'
    local output_input "06_community_registry_geospatial.dta"

    if inrange(`output_index', 12, 15) {
        local output_input ///
            "06_community_registry_geospatial.dta+locked_legacy_department_geometry"
    }

    quietly checksum "${project_root}/`output_path'"
    local output_checksum : display %20.0f r(checksum)
    local output_bytes : display %20.0f r(filelen)
    local output_checksum = strtrim("`output_checksum'")
    local output_bytes = strtrim("`output_bytes'")

    file write `output_manifest' ///
        `""`output_id'","`output_path'","`output_type'","code/stata/pipeline/02_describe_data.do","`output_input'","`input_datasignature'","RUV centro poblado","`output_spec'","Stata `c(stata_version)'","`c(current_date)'","`output_checksum'","`output_bytes'","`disclosure_status'","not_assigned""' _n
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
