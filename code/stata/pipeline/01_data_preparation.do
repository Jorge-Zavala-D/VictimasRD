/*
Project:       Victimas RD
Program:       01_data_preparation.do
Purpose:       Authoritative end-to-end data-preparation program
Current scope: Foundational community sources

This file is the only canonical Stata data-preparation program. New source
families will be added as clearly delimited sections here so that the master
workflow retains one push-button preparation entry point.

Current source families:
    1. INEI 2017 national centro-poblado directory
    2. RUV Libro Segundo victimization-index registry
    3. CMAN communities attended through 2023

Dropbox inputs are immutable. All row-level products are written only to the
Git-ignored build tree. Fuzzy candidates are never accepted silently.
*/

version 19
set more off


*===============================================================================
**# 0. Preconditions, paths, and reusable programs
*===============================================================================

local required_globals ///
    project_root raw_root build_root metadata_root python_exec

foreach global_name of local required_globals {
    local global_value "${`global_name'}"
    if `"`global_value'"' == "" {
        display as error "Required global is missing: `global_name'"
        exit 198
    }
}

capture confirm file "${python_exec}"
if _rc {
    display as error "Configured Python executable was not found:"
    display as error "  ${python_exec}"
    exit 601
}

capture confirm file "${project_root}/code/python/extract_cman_pdf.py"
if _rc {
    display as error "CMAN PDF extractor was not found."
    exit 601
}

global code_root      "${project_root}/code/stata"
global derived_root   "${build_root}/derived"
global temporary_root "${build_root}/temporary"
global qa_root        "${build_root}/qa"
global staging_root   "${build_root}/staging"
global ado_root       "${build_root}/ado"

local project_lower = lower(subinstr("${project_root}", "\", "/", .))
local build_lower   = lower(subinstr("${build_root}", "\", "/", .))

if strpos("`build_lower'", "`project_lower'/") != 1 {
    display as error "Unsafe build_root: it must be inside project_root."
    exit 198
}

foreach build_directory in ///
    "${build_root}" ///
    "${derived_root}" ///
    "${temporary_root}" ///
    "${qa_root}" ///
    "${staging_root}" ///
    "${ado_root}" {

    capture mkdir "`build_directory'"
    if !direxists("`build_directory'") {
        display as error "Required build directory is unavailable:"
        display as error "  `build_directory'"
        exit 603
    }
}

sysdir set PLUS "${ado_root}"
discard

foreach command in freqindex matchit strdist {
    capture which `command'
    if _rc {
        display as error "Required matching command is unavailable: `command'"
        exit 499
    }
}

capture program drop victimasrd_normalize_name
program define victimasrd_normalize_name
    version 19
    syntax varname(string), Generate(name)

    confirm new variable `generate'
    generate str244 `generate' = ustrupper(ustrtrim(`varlist'))
    replace `generate' = ustrregexra( ///
        ustrnormalize(`generate', "nfd"), "\p{M}", "")
    replace `generate' = ustrregexra(`generate', "[^A-Z0-9]+", " ")
    replace `generate' = ustrtrim(itrim(`generate'))
end

capture program drop victimasrd_score_name_pairs
program define victimasrd_score_name_pairs
    version 19
    syntax varlist(min=2 max=2 string), Prefix(name)

    tokenize `varlist'
    local source_name    "`1'"
    local candidate_name "`2'"

    strdist `source_name' `candidate_name', ///
        generate(`prefix'_levenshtein_distance)

    generate double `prefix'_levenshtein = 1 - ///
        `prefix'_levenshtein_distance / ///
        max(strlen(`source_name'), strlen(`candidate_name'))

    matchit `source_name' `candidate_name', ///
        similmethod(bigram) generate(`prefix'_bigram)

    matchit `source_name' `candidate_name', ///
        similmethod(token) generate(`prefix'_token)

    generate byte `prefix'_soundex = ///
        soundex(`source_name') == soundex(`candidate_name')

    generate double `prefix'_composite = ///
        .50 * `prefix'_levenshtein + ///
        .35 * `prefix'_bigram + ///
        .10 * `prefix'_token + ///
        .05 * `prefix'_soundex
end


*===============================================================================
**# 1. Extract the complete CMAN 2023 PDF table
*===============================================================================

local cman_pdf ///
    "${raw_root}/12 CMAN/1604763-listado-de-comunidades-atendidas-28-12-23.pdf"
local cman_csv ///
    "${staging_root}/cman_projects_2023_extracted.csv"
local cman_manifest ///
    "${qa_root}/cman_projects_2023_extraction_manifest.json"
local cman_extractor ///
    "${project_root}/code/python/extract_cman_pdf.py"

foreach required_file in "`cman_pdf'" "`cman_extractor'" {
    capture confirm file "`required_file'"
    if _rc {
        display as error "Required CMAN source/extractor was not found:"
        display as error "  `required_file'"
        exit 601
    }
}

/*
Remove prior ignored staging outputs so a failed extraction cannot be mistaken
for a current successful run. No Dropbox file is changed.
*/

capture erase "`cman_csv'"
capture erase "`cman_manifest'"

local extraction_command ///
    `""${python_exec}" "`cman_extractor'" --input "`cman_pdf'" --output "`cman_csv'" --manifest "`cman_manifest'" --expected-pages 283 --expected-rows 4433"'

display as text "Extracting the CMAN project table from 283 PDF pages."
shell `extraction_command'

foreach extracted_file in "`cman_csv'" "`cman_manifest'" {
    capture confirm file "`extracted_file'"
    if _rc {
        display as error "Expected CMAN extraction output was not created:"
        display as error "  `extracted_file'"
        exit 603
    }
}


*===============================================================================
**# 2. Build the authoritative INEI 2017 centro-poblado directory
*===============================================================================

local inei_ccpp_directory "${raw_root}/11 Centros Poblados"
local inei_ccpp_files : dir "`inei_ccpp_directory'" files "dpto*.xlsx"
local inei_workbook_count : word count `inei_ccpp_files'

assert `inei_workbook_count' == 26

tempfile inei_ccpp_all
local first_inei_file 1

foreach source_file of local inei_ccpp_files {
    quietly import excel ///
        "`inei_ccpp_directory'/`source_file'", allstring clear

    assert c(k) == 10

    rename (A B C D E F G H I J) ///
        (code_raw name_raw natural_region_raw altitude_raw ///
         population_total_raw population_male_raw population_female_raw ///
         dwellings_total_raw dwellings_occupied_raw ///
         dwellings_unoccupied_raw)

    generate str32 source_file = "`source_file'"
    generate long source_row = _n

    foreach variable in ///
        code_raw ///
        name_raw ///
        natural_region_raw ///
        altitude_raw ///
        population_total_raw ///
        population_male_raw ///
        population_female_raw ///
        dwellings_total_raw ///
        dwellings_occupied_raw ///
        dwellings_unoccupied_raw {

        replace `variable' = ustrtrim(itrim(`variable'))
    }

    generate byte code_length = strlen(code_raw)

    generate str2 ubigeo_dpto = code_raw if ///
        code_length == 2 & ///
        ustrregexm(ustrupper(name_raw), "^DEPARTAMENTO")

    generate str4 ubigeo_prov = code_raw if ///
        code_length == 4 & ///
        ustrregexm(ustrupper(name_raw), "^PROVINCIA")

    generate str6 ubigeo_dist = code_raw if ///
        code_length == 6 & ///
        ustrregexm(ustrupper(name_raw), "^DISTRITO")

    generate str80 dpto_inei = ustrregexra( ///
        ustrupper(name_raw), "^DEPARTAMENTO( DE)?[ ]*", "") ///
        if !missing(ubigeo_dpto)

    generate str80 prov_inei = ustrregexra( ///
        ustrupper(name_raw), "^PROVINCIA( DE)?[ ]*", "") ///
        if !missing(ubigeo_prov)

    generate str80 dist_inei = ustrregexra( ///
        ustrupper(name_raw), "^DISTRITO( DE)?[ ]*", "") ///
        if !missing(ubigeo_dist)

    foreach hierarchy_variable in ///
        ubigeo_dpto dpto_inei ///
        ubigeo_prov prov_inei ///
        ubigeo_dist dist_inei {

        replace `hierarchy_variable' = `hierarchy_variable'[_n-1] ///
            if missing(`hierarchy_variable') & _n > 1
    }

    keep if ///
        code_length == 4 & ///
        !missing(ubigeo_dist) & ///
        !ustrregexm(ustrupper(name_raw), "^PROVINCIA")

    rename code_raw ccpp_code_inei
    rename name_raw ccpp_name_inei

    generate str10 ubigeo_ccpp = ubigeo_dist + ccpp_code_inei
    assert strlen(ubigeo_ccpp) == 10

    victimasrd_normalize_name ccpp_name_inei, ///
        generate(ccpp_name_norm)

    foreach numeric_pair in ///
        altitude_raw:altitude_m ///
        population_total_raw:population_2017 ///
        population_male_raw:population_male_2017 ///
        population_female_raw:population_female_2017 ///
        dwellings_total_raw:dwellings_2017 ///
        dwellings_occupied_raw:dwellings_occupied_2017 ///
        dwellings_unoccupied_raw:dwellings_unoccupied_2017 {

        gettoken source_variable target_variable : numeric_pair, parse(":")
        local target_variable = subinstr("`target_variable'", ":", "", .)

        replace `source_variable' = "0" if ///
            inlist(`source_variable', "-", "–", "—")
        replace `source_variable' = ///
            subinstr(`source_variable', " ", "", .)

        rename `source_variable' `target_variable'
        destring `target_variable', replace
    }

    assert population_2017 == ///
        population_male_2017 + population_female_2017

    assert dwellings_2017 == ///
        dwellings_occupied_2017 + dwellings_unoccupied_2017

    keep ///
        source_file ///
        source_row ///
        ubigeo_dpto ///
        dpto_inei ///
        ubigeo_prov ///
        prov_inei ///
        ubigeo_dist ///
        dist_inei ///
        ccpp_code_inei ///
        ubigeo_ccpp ///
        ccpp_name_inei ///
        ccpp_name_norm ///
        natural_region_raw ///
        altitude_m ///
        population_2017 ///
        population_male_2017 ///
        population_female_2017 ///
        dwellings_2017 ///
        dwellings_occupied_2017 ///
        dwellings_unoccupied_2017

    if `first_inei_file' {
        save `inei_ccpp_all', replace
        local first_inei_file 0
    }
    else {
        append using `inei_ccpp_all'
        save `inei_ccpp_all', replace
    }
}

use `inei_ccpp_all', clear

/*
The Callao and Lima publications omit a conventional two-digit department
hierarchy row. Recover the department code from the verified 10-digit UBIGEO
and fill the two documented department names.
*/

replace ubigeo_dpto = substr(ubigeo_ccpp, 1, 2)
replace dpto_inei = "CALLAO" if ///
    ubigeo_dpto == "07" & missing(dpto_inei)
replace dpto_inei = "LIMA" if ///
    ubigeo_dpto == "15" & missing(dpto_inei)

assert !missing( ///
    ubigeo_dpto, dpto_inei, ///
    ubigeo_prov, prov_inei, ///
    ubigeo_dist, dist_inei, ///
    ubigeo_ccpp, ccpp_name_inei)

isid ubigeo_ccpp
count
assert r(N) == 94922
local inei_ccpp_rows = r(N)

egen byte tag_department = tag(ubigeo_dpto)
count if tag_department
assert r(N) == 25
local inei_departments = r(N)
drop tag_department

egen byte tag_district = tag(ubigeo_dist)
count if tag_district
assert r(N) == 1874
local inei_districts = r(N)
drop tag_district

victimasrd_normalize_name dpto_inei, generate(region_norm)
victimasrd_normalize_name prov_inei, generate(province_norm)
victimasrd_normalize_name dist_inei, generate(district_norm)

bysort ubigeo_dist ccpp_name_norm: ///
    generate long inei_ccpp_name_within_district_n = _N

compress
sort ubigeo_ccpp
save "${derived_root}/01_inei_ccpp_2017.dta", replace

/*
These workbooks contain natural region, altitude, population, sex composition,
and dwelling counts. They do not contain an explicit urban/rural field.
Rurality must not be inferred from population or name without an approved
official classification source.
*/

preserve
collapse ///
    (count) ccpp_count=source_row ///
    (sum) population_2017 ///
    (sum) dwellings_2017, ///
    by(ubigeo_dpto dpto_inei)
sort ubigeo_dpto
export delimited ///
    "${qa_root}/inei_ccpp_2017_summary_by_department.csv", ///
    replace
restore

preserve
keep if inei_ccpp_name_within_district_n == 1
rename ccpp_name_norm community_norm
keep ///
    ubigeo_dist ///
    community_norm ///
    ubigeo_ccpp ///
    ccpp_name_inei ///
    natural_region_raw ///
    altitude_m ///
    population_2017 ///
    population_male_2017 ///
    population_female_2017 ///
    dwellings_2017 ///
    dwellings_occupied_2017 ///
    dwellings_unoccupied_2017
isid ubigeo_dist community_norm
save "${temporary_root}/inei_ccpp_unique_exact.dta", replace
restore

preserve
bysort ubigeo_dist: keep if _n == 1
keep ///
    ubigeo_dpto ///
    dpto_inei ///
    ubigeo_prov ///
    prov_inei ///
    ubigeo_dist ///
    dist_inei ///
    region_norm ///
    province_norm ///
    district_norm
isid ubigeo_dist
isid region_norm province_norm district_norm
save "${temporary_root}/inei_district_exact.dta", replace
restore

preserve
generate long inei_candidate_id = _n
keep ///
    inei_candidate_id ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    ccpp_name_inei ///
    ccpp_name_norm ///
    natural_region_raw ///
    altitude_m ///
    population_2017 ///
    population_male_2017 ///
    population_female_2017 ///
    dwellings_2017 ///
    dwellings_occupied_2017 ///
    dwellings_unoccupied_2017
rename ccpp_name_norm inei_name_norm
save "${temporary_root}/inei_ccpp_candidate_pool.dta", replace
restore


*===============================================================================
**# 3. Clean the RUV Libro Segundo victimization-index registry
*===============================================================================

local victimization_source ///
    "${raw_root}/12 CMAN/Community_index_inscritas.xlsx"

confirm file "`victimization_source'"

import excel "`victimization_source'", ///
    sheet("Libro 02") firstrow allstring clear

assert c(k) == 25
count
assert r(N) == 5712
local victimization_rows = r(N)

rename CodRUV ruv_id
rename NroExp expediente_id
rename Departamento dpto_victim_raw
rename Provincia prov_victim_raw
rename Distrito dist_victim_raw
rename CCPP ccpp_victim_raw
rename UbigeoFinalDistrito ubigeo_dist
rename Nivel victimization_level_source
rename NumeroIndice victimization_index_raw
rename Fallecidos deaths_raw
rename Desaparecidos disappearances_raw
rename Torturados torture_raw
rename Discapacitados disabilities_raw
rename Viudos widowed_raw
rename Huerfanos orphaned_raw
rename Indocumentados undocumented_raw
rename Desplazados displaced_raw
rename AutMuertas authorities_killed_raw
rename AutDesaparecidas authorities_disappeared_raw
rename AutDesplazadas authorities_displaced_raw
rename OrgAfectadas organizations_affected_raw
rename DestrucBsFamiliares family_assets_destroyed_raw
rename DestrucBsComunales community_assets_destroyed_raw
rename Incursiones incursions_raw
rename AñoInicioViolencia violence_start_year_raw

generate long victimization_source_row = _n

isid ruv_id
isid expediente_id
assert strlen(ustrtrim(ubigeo_dist)) == 6
assert !missing( ///
    ruv_id, expediente_id, ///
    dpto_victim_raw, prov_victim_raw, ///
    dist_victim_raw, ccpp_victim_raw, ///
    ubigeo_dist, victimization_level_source, ///
    victimization_index_raw)

destring victimization_index_raw, generate(victimization_index)

foreach numeric_pair in ///
    deaths_raw:deaths ///
    disappearances_raw:disappearances ///
    torture_raw:torture ///
    disabilities_raw:disabilities ///
    widowed_raw:widowed ///
    orphaned_raw:orphaned ///
    undocumented_raw:undocumented ///
    displaced_raw:displaced ///
    authorities_killed_raw:authorities_killed ///
    authorities_disappeared_raw:authorities_disappeared ///
    authorities_displaced_raw:authorities_displaced ///
    organizations_affected_raw:organizations_affected ///
    family_assets_destroyed_raw:family_assets_destroyed ///
    community_assets_destroyed_raw:community_assets_destroyed ///
    incursions_raw:incursions {

    gettoken source_variable target_variable : numeric_pair, parse(":")
    local target_variable = subinstr("`target_variable'", ":", "", .)
    destring `source_variable', generate(`target_variable')
}

generate int violence_start_year = real(ustrregexs(0)) if ///
    ustrregexm(violence_start_year_raw, "(19|20)[0-9][0-9]")

assert inrange(violence_start_year, 1980, 2000) if ///
    !missing(violence_start_year)

victimasrd_normalize_name dpto_victim_raw, generate(region_norm)
victimasrd_normalize_name prov_victim_raw, generate(province_norm)
victimasrd_normalize_name dist_victim_raw, generate(district_norm)
victimasrd_normalize_name ccpp_victim_raw, generate(community_norm)

isid region_norm province_norm district_norm community_norm

/*
The methodology note documents six-decimal ranges, while this workbook exposes
rounded scores and source-supplied categories. Preserve the source category and
record, but do not overwrite it with a category reconstructed from rounded
scores.
*/

generate str1 victim_level_documented = ""
replace victim_level_documented = "A" if ///
    inrange(victimization_index, .153750, 1)
replace victim_level_documented = "B" if ///
    inrange(victimization_index, .062320, .153749)
replace victim_level_documented = "C" if ///
    inrange(victimization_index, .026930, .062319)
replace victim_level_documented = "D" if ///
    inrange(victimization_index, .015220, .026929)
replace victim_level_documented = "E" if ///
    inrange(victimization_index, .007740, .015219)

generate byte victim_score_outside_doc_range = ///
    missing(victim_level_documented)

generate byte victim_level_range_disagree = ///
    victimization_level_source != ///
        victim_level_documented & ///
    !missing(victim_level_documented)

count if victim_score_outside_doc_range
assert r(N) == 196
local victim_outside_doc = r(N)

count if victim_level_range_disagree
assert r(N) == 73
local victim_level_disagree_n = r(N)

merge m:1 ubigeo_dist community_norm using ///
    "${temporary_root}/inei_ccpp_unique_exact.dta", ///
    keep(master match) ///
    gen(victim_inei_exact_merge)

count
assert r(N) == 5712

count if victim_inei_exact_merge == 3
assert r(N) == 3986
local victimization_inei_exact = r(N)

count if victim_inei_exact_merge == 1
assert r(N) == 1726

generate str48 victim_inei_match_method = ///
    cond(victim_inei_exact_merge == 3, ///
         "exact_district_and_unique_normalized_name", ///
         "unresolved_review_required")

generate str4 victim_inei_code_vintage = ///
    cond(victim_inei_exact_merge == 3, "2017", "")

/*
Apply only disclosure-reviewed adjudications. The crosswalk is identifier
metadata: it cannot contain outcomes, treatment values, or restricted text.
Accepted codes may use the 2017 INEI spine or a later official administrative
vintage. Every code must remain inside the RUV-supplied district.
*/

tempfile ruv_ubigeo_adjudication

preserve
import delimited using ///
    "${metadata_root}/ccpp-linkage/ruv-ubigeo-adjudication.csv", ///
    varnames(1) stringcols(_all) clear

isid ruv_id
isid ubigeo_ccpp
assert ustrregexm(ubigeo_ccpp, "^[0-9]{10}$")
assert inlist(code_vintage, "2017", "2025")
assert lower(ustrtrim(review_status)) == "accepted"
assert !missing( ///
    match_method, evidence_source, evidence_locator, ///
    reviewer, review_date)

rename ubigeo_ccpp adjudicated_ubigeo_ccpp
rename code_vintage adjudicated_code_vintage
rename match_method adjudicated_match_method
save `ruv_ubigeo_adjudication'
local victimization_inei_adjudicated = _N
restore

merge 1:1 ruv_id using `ruv_ubigeo_adjudication', ///
    gen(ruv_adjudication_merge)

count if ruv_adjudication_merge == 2
assert r(N) == 0

assert ///
    ubigeo_ccpp == adjudicated_ubigeo_ccpp if ///
    ruv_adjudication_merge == 3 & ///
    !missing(ubigeo_ccpp)

replace ubigeo_ccpp = adjudicated_ubigeo_ccpp if ///
    ruv_adjudication_merge == 3 & ///
    missing(ubigeo_ccpp)

assert ///
    victim_inei_code_vintage == adjudicated_code_vintage if ///
    ruv_adjudication_merge == 3 & ///
    !missing(victim_inei_code_vintage)

replace victim_inei_code_vintage = ///
    adjudicated_code_vintage if ///
    ruv_adjudication_merge == 3

replace victim_inei_match_method = ///
    adjudicated_match_method if ///
    ruv_adjudication_merge == 3

generate byte victim_inei_adjudicated = ///
    ruv_adjudication_merge == 3

drop ///
    adjudicated_ubigeo_ccpp ///
    adjudicated_code_vintage ///
    adjudicated_match_method ///
    evidence_source ///
    evidence_locator ///
    review_status ///
    reviewer ///
    review_date ///
    notes ///
    ruv_adjudication_merge

merge m:1 ubigeo_ccpp using ///
    "${derived_root}/01_inei_ccpp_2017.dta", ///
    keepusing( ///
        ccpp_name_inei ///
        natural_region_raw ///
        altitude_m ///
        population_2017 ///
        population_male_2017 ///
        population_female_2017 ///
        dwellings_2017 ///
        dwellings_occupied_2017 ///
        dwellings_unoccupied_2017) ///
    update ///
    gen(victim_inei_code_merge)

drop if victim_inei_code_merge == 2

count if victim_inei_adjudicated & ///
    victim_inei_code_vintage == "2017" & ///
    victim_inei_code_merge == 1
assert r(N) == 0

count if victim_inei_code_vintage == "2025" & ///
    victim_inei_code_merge == 3
assert r(N) == 0

count if victim_inei_code_merge == 5
assert r(N) == 0

assert substr(ubigeo_ccpp, 1, 6) == ubigeo_dist if ///
    !missing(ubigeo_ccpp)

drop victim_inei_code_merge

count if missing(ubigeo_ccpp)
local victimization_inei_unresolved = r(N)

/*
Keep the exhaustive unresolved ledger in the ignored QA area. The RUV workbook
defines the observation universe, so a missing verified CCPP code is a linkage
limitation rather than a reason to remove a community.
*/

preserve
keep if missing(ubigeo_ccpp)
keep ///
    victimization_source_row ///
    ruv_id ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm ///
    ubigeo_dist ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw
generate str52 linkage_status = ///
    "retained_without_verified_ccpp_ubigeo"
rename community_norm victim_name_norm
save "${temporary_root}/victimization_unresolved_for_candidates.dta", replace
save "${qa_root}/ruv_ubigeo_unresolved.dta", replace
export delimited ///
    "${qa_root}/ruv_ubigeo_unresolved.csv", replace
restore

generate byte ubigeo_ccpp_verified = !missing(ubigeo_ccpp)

count
local victimization_analysis_rows = r(N)
assert `victimization_analysis_rows' == `victimization_rows'

count if !ubigeo_ccpp_verified
assert r(N) == `victimization_inei_unresolved'

isid ruv_id

preserve
keep if ubigeo_ccpp_verified
isid ubigeo_ccpp
restore

label variable ubigeo_dist ///
    "Six-digit district UBIGEO supplied by RUV"
label variable ubigeo_ccpp ///
    "Ten-digit CCPP UBIGEO from official linkage"
label variable ubigeo_ccpp_verified ///
    "Verified ten-digit community UBIGEO is available"
label variable victim_inei_code_vintage ///
    "Administrative vintage of linked CCPP UBIGEO"
label variable victimization_index ///
    "Victimization index as observed in RUV workbook"
label variable victimization_level_source ///
    "Victimization category supplied by RUV"
label variable victim_inei_match_method ///
    "Method linking RUV community to INEI CCPP directory"

compress
sort ruv_id
save "${derived_root}/02_victimization_registry.dta", replace

/*
Prepare the exact full-name path crosswalk used later for the independent CMAN
link. Only paths unique in the complete RUV universe are admissible for this
deterministic linkage; duplicate paths remain in the RUV registry.
*/

preserve
keep ///
    victimization_source_row ///
    ruv_id ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    victim_inei_exact_merge ///
    victim_inei_adjudicated

bysort region_norm province_norm district_norm community_norm: ///
    generate int victim_name_path_n = _N
count if victim_name_path_n > 1
local victim_name_path_dupe_rows = r(N)
keep if victim_name_path_n == 1
drop victim_name_path_n

rename ubigeo_dist victim_ubigeo_dist
rename ubigeo_ccpp victim_ubigeo_ccpp
rename victim_inei_exact_merge victim_inei_exact
generate byte victim_inei_linked = ///
    !missing(victim_ubigeo_ccpp)

isid region_norm province_norm district_norm community_norm
save "${temporary_root}/victimization_unique_name_path.dta", replace
restore

/*
Reload the canonical stage explicitly before preparing the unresolved-review
pool. This avoids relying on Stata's preserved-data state after the crosswalk
renames above and makes the source of this review extract unambiguous.
*/
use "${derived_root}/02_victimization_registry.dta", clear

preserve
keep ruv_id ubigeo_dist ubigeo_ccpp
rename ubigeo_dist victim_ubigeo_dist
rename ubigeo_ccpp victim_ubigeo_ccpp
generate byte victim_inei_linked = ///
    !missing(victim_ubigeo_ccpp)
isid ruv_id
save "${temporary_root}/victimization_unique_id.dta", replace
restore

preserve
keep ruv_id ubigeo_ccpp
drop if missing(ubigeo_ccpp)
rename ruv_id ubigeo_ruv_id
isid ubigeo_ccpp
save "${temporary_root}/victimization_unique_ubigeo.dta", replace
restore

/*
Generate five INEI candidates for every unresolved RUV community, blocked on
the RUV-supplied six-digit district code. Candidate scores support review; they
do not alter ubigeo_ccpp.
*/

use "${temporary_root}/victimization_unresolved_for_candidates.dta", clear
joinby ubigeo_dist using ///
    "${temporary_root}/inei_ccpp_candidate_pool.dta"

victimasrd_score_name_pairs victim_name_norm inei_name_norm, ///
    prefix(name)

gsort ///
    victimization_source_row ///
    -name_composite ///
    -name_levenshtein ///
    -name_bigram ///
    ubigeo_ccpp

by victimization_source_row: generate int candidate_rank = _n
by victimization_source_row: generate double top_score = ///
    name_composite[1]
by victimization_source_row: generate double second_score = ///
    name_composite[2]

generate double score_margin = top_score - second_score if ///
    candidate_rank == 1

generate str24 review_priority = "standard"
replace review_priority = "high" if ///
    candidate_rank == 1 & ///
    top_score >= .90 & ///
    score_margin >= .10 & ///
    name_levenshtein >= .85
replace review_priority = "very_high" if ///
    candidate_rank == 1 & ///
    top_score >= .95 & ///
    score_margin >= .15 & ///
    name_levenshtein >= .90

keep if candidate_rank <= 5
sort victimization_source_row candidate_rank

save "${qa_root}/victimization_inei_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_root}/victimization_inei_fuzzy_candidates.csv", ///
    replace


*===============================================================================
**# 4. Clean and validate the complete CMAN project register through 2023
*===============================================================================

import delimited "`cman_csv'", ///
    varnames(1) ///
    encoding(UTF-8) ///
    stringcols(_all) ///
    clear

assert c(k) == 13
count
assert r(N) == 4433
local cman_project_rows = r(N)

destring record_number source_page source_row_on_page, replace
isid record_number
sort record_number
assert record_number == _n

generate int recorded_project_year = real(ustrregexs(0)) if ///
    ustrregexm(recorded_year_raw, "20[0-9][0-9]")
assert inrange(recorded_project_year, 2007, 2023)

generate byte source_year_format_issue = ///
    ustrtrim(recorded_year_raw) != string(recorded_project_year)
count if source_year_format_issue
assert r(N) == 6
local cman_year_format_issues = r(N)

generate str32 cman_financing_clean = ///
    subinstr(cman_financing_raw, ",", "", .)
generate str32 cofinancing_clean = ///
    subinstr(cofinancing_raw, ",", "", .)

generate byte source_money_format_issue = ustrregexm( ///
    cofinancing_clean, ///
    "^[0-9]+[.][0-9][0-9][0-9][.][0-9][0-9]$")

replace cofinancing_clean = ///
    subinstr(cofinancing_clean, ".", "", 1) if ///
    source_money_format_issue

count if source_money_format_issue
assert r(N) == 1
local cman_money_format_issues = r(N)

destring cman_financing_clean, generate(cman_financing_soles)
destring cofinancing_clean, generate(cofinancing_soles)

assert !missing(cman_financing_soles, cofinancing_soles)
assert cman_financing_soles >= 0
assert cofinancing_soles >= 0

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name community_raw, generate(community_norm)

isid region_norm province_norm district_norm community_norm

label variable recorded_project_year ///
    "Year printed in CMAN communities-attended register"
label variable cman_financing_soles ///
    "CMAN financing in soles; parsed from source text"
label variable cofinancing_soles ///
    "Cofinancing in soles; parsed from source text"
label variable source_year_format_issue ///
    "Source year required whitespace or hyphen normalization"
label variable source_money_format_issue ///
    "Source money required documented punctuation normalization"

compress
sort record_number
save "${derived_root}/03_cman_projects_2023_clean.dta", replace


*===============================================================================
**# 5. Link CMAN independently to the INEI directory
*===============================================================================

merge m:1 region_norm province_norm district_norm using ///
    "${temporary_root}/inei_district_exact.dta", ///
    keep(master match) ///
    gen(cman_inei_district_exact_merge)

count
assert r(N) == 4433

count if cman_inei_district_exact_merge == 3
assert r(N) == 4343
local cman_inei_district_exact = r(N)

count if cman_inei_district_exact_merge == 1
assert r(N) == 90
local cman_inei_district_unresolved = r(N)

merge m:1 ubigeo_dist community_norm using ///
    "${temporary_root}/inei_ccpp_unique_exact.dta", ///
    keep(master match) ///
    gen(cman_inei_ccpp_exact_merge)

count
assert r(N) == 4433

count if cman_inei_ccpp_exact_merge == 3
assert r(N) == 3110
local cman_inei_ccpp_exact = r(N)

count if cman_inei_ccpp_exact_merge == 1
assert r(N) == 1323
local cman_inei_ccpp_unresolved = r(N)

generate str48 cman_inei_match_method = ///
    cond(cman_inei_ccpp_exact_merge == 3, ///
         "exact_hierarchy_and_unique_normalized_name", ///
         "unresolved_review_required")

compress
sort record_number
save "${derived_root}/03_cman_projects_2023_inei_link.dta", replace

/*
District candidates for the 32 distinct unresolved CMAN district name paths.
Candidate generation is blocked on department and scores province plus district.
*/

preserve
keep if cman_inei_district_exact_merge == 1
keep region_norm province_norm district_norm
bysort region_norm province_norm district_norm: keep if _n == 1
generate long cman_district_review_id = _n
rename province_norm cman_province_norm
rename district_norm cman_district_norm
save "${temporary_root}/cman_unresolved_districts.dta", replace
restore

preserve
use "${temporary_root}/inei_district_exact.dta", clear
generate long inei_district_candidate_id = _n
rename province_norm inei_province_norm
rename district_norm inei_district_norm
save "${temporary_root}/inei_district_candidate_pool.dta", replace
restore

preserve
use "${temporary_root}/cman_unresolved_districts.dta", clear
joinby region_norm using ///
    "${temporary_root}/inei_district_candidate_pool.dta"

victimasrd_score_name_pairs ///
    cman_province_norm inei_province_norm, prefix(province)
victimasrd_score_name_pairs ///
    cman_district_norm inei_district_norm, prefix(district)

generate double hierarchy_composite = ///
    .30 * province_composite + .70 * district_composite

gsort ///
    cman_district_review_id ///
    -hierarchy_composite ///
    -district_levenshtein ///
    ubigeo_dist

by cman_district_review_id: generate int candidate_rank = _n
by cman_district_review_id: generate double top_score = ///
    hierarchy_composite[1]
by cman_district_review_id: generate double second_score = ///
    hierarchy_composite[2]

generate double score_margin = top_score - second_score if ///
    candidate_rank == 1

generate str24 review_priority = "standard"
replace review_priority = "high" if ///
    candidate_rank == 1 & ///
    top_score >= .90 & ///
    score_margin >= .10 & ///
    district_levenshtein >= .85

keep if candidate_rank <= 5
sort cman_district_review_id candidate_rank

save "${qa_root}/cman_inei_district_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_root}/cman_inei_district_fuzzy_candidates.csv", ///
    replace
restore

/*
CCPP candidates for CMAN records whose district matched exactly but whose
community name did not have a unique exact INEI match.
*/

preserve
keep if ///
    cman_inei_district_exact_merge == 3 & ///
    cman_inei_ccpp_exact_merge == 1
keep ///
    record_number ///
    ubigeo_dist ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw ///
    community_norm
rename community_norm cman_name_norm
save "${temporary_root}/cman_unresolved_ccpp_for_candidates.dta", replace
restore

preserve
use "${temporary_root}/cman_unresolved_ccpp_for_candidates.dta", clear
joinby ubigeo_dist using ///
    "${temporary_root}/inei_ccpp_candidate_pool.dta"

victimasrd_score_name_pairs cman_name_norm inei_name_norm, ///
    prefix(name)

gsort ///
    record_number ///
    -name_composite ///
    -name_levenshtein ///
    -name_bigram ///
    ubigeo_ccpp

by record_number: generate int candidate_rank = _n
by record_number: generate double top_score = name_composite[1]
by record_number: generate double second_score = name_composite[2]

generate double score_margin = top_score - second_score if ///
    candidate_rank == 1

generate str24 review_priority = "standard"
replace review_priority = "high" if ///
    candidate_rank == 1 & ///
    top_score >= .90 & ///
    score_margin >= .10 & ///
    name_levenshtein >= .85
replace review_priority = "very_high" if ///
    candidate_rank == 1 & ///
    top_score >= .95 & ///
    score_margin >= .15 & ///
    name_levenshtein >= .90

keep if candidate_rank <= 5
sort record_number candidate_rank

save "${qa_root}/cman_inei_ccpp_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_root}/cman_inei_ccpp_fuzzy_candidates.csv", ///
    replace
restore


*===============================================================================
**# 6. Link CMAN projects directly to the victimization registry
*===============================================================================

merge 1:1 region_norm province_norm district_norm community_norm using ///
    "${temporary_root}/victimization_unique_name_path.dta", ///
    keep(master match) ///
    gen(cman_victim_exact_merge)

count
assert r(N) == 4433

count if cman_victim_exact_merge == 3
local cman_victim_exact = r(N)

count if cman_victim_exact_merge == 1
assert r(N) == 4433 - `cman_victim_exact'

generate str48 cman_victim_match_method = ///
    cond(cman_victim_exact_merge == 3, ///
         "exact_normalized_full_geographic_name", ///
         "unresolved_review_required")

/*
An independently verified CMAN CCPP code is stronger than a name-only
candidate. Use it to recover RUV links missed by spelling differences.
*/

merge m:1 ubigeo_ccpp using ///
    "${temporary_root}/victimization_unique_ubigeo.dta", ///
    keep(master match) ///
    gen(cman_victim_ubigeo_merge)

assert ruv_id == ubigeo_ruv_id if ///
    !missing(ruv_id, ubigeo_ruv_id)

generate byte cman_victim_linked_by_ubigeo = ///
    missing(ruv_id) & !missing(ubigeo_ruv_id)

replace ruv_id = ubigeo_ruv_id if ///
    cman_victim_linked_by_ubigeo

replace cman_victim_match_method = ///
    "exact_verified_ubigeo" if ///
    cman_victim_linked_by_ubigeo

count if cman_victim_linked_by_ubigeo
local cman_victim_exact_ubigeo = r(N)

drop ubigeo_ruv_id cman_victim_ubigeo_merge

tempfile cman_ruv_adjudication

preserve
import delimited using ///
    "${metadata_root}/ccpp-linkage/cman-ruv-adjudication.csv", ///
    varnames(1) stringcols(_all) clear

destring cman_record_number, replace
isid cman_record_number
assert lower(ustrtrim(review_status)) == "accepted"
assert !missing( ///
    ruv_id, match_method, evidence_source, evidence_locator, ///
    reviewer, review_date)

rename cman_record_number record_number
rename ruv_id adjudicated_ruv_id
save `cman_ruv_adjudication'
local cman_victim_adjudicated = _N
restore

merge 1:1 record_number using `cman_ruv_adjudication', ///
    gen(cman_adjudication_merge)

count if cman_adjudication_merge == 2
assert r(N) == 0

assert ruv_id == adjudicated_ruv_id if ///
    cman_adjudication_merge == 3 & ///
    !missing(ruv_id)

replace ruv_id = adjudicated_ruv_id if ///
    cman_adjudication_merge == 3 & ///
    missing(ruv_id)

replace cman_victim_match_method = ///
    "accepted_manual_adjudication" if ///
    cman_adjudication_merge == 3

generate byte cman_victim_adjudicated = ///
    cman_adjudication_merge == 3

drop ///
    adjudicated_ruv_id ///
    match_method ///
    evidence_source ///
    evidence_locator ///
    review_status ///
    reviewer ///
    review_date ///
    notes ///
    cman_adjudication_merge

merge m:1 ruv_id using ///
    "${temporary_root}/victimization_unique_id.dta", ///
    update ///
    gen(cman_ruv_id_merge)

drop if cman_ruv_id_merge == 2

count if cman_ruv_id_merge == 1 & !missing(ruv_id)
assert r(N) == 0

generate byte cman_link_to_ruv_missing_ubigeo = ///
    !missing(ruv_id) & missing(victim_ubigeo_ccpp)

count if cman_link_to_ruv_missing_ubigeo
local cman_missing_ubigeo_link_n = r(N)

count if cman_ruv_id_merge == 5
assert r(N) == 0

drop cman_ruv_id_merge

/*
When CMAN and RUV are linked but CMAN lacked an independent exact-name code,
inherit the RUV code when one was verified. A CMAN project linked to an RUV
community remains admissible even when neither source has a verified CCPP code.
*/

generate byte cman_ubigeo_inherited_from_ruv = ///
    !missing(ruv_id) & ///
    missing(ubigeo_ccpp) & ///
    !missing(victim_ubigeo_ccpp)

replace ubigeo_ccpp = victim_ubigeo_ccpp if ///
    cman_ubigeo_inherited_from_ruv

replace cman_inei_match_method = ///
    "inherited_from_verified_ruv_link" if ///
    cman_ubigeo_inherited_from_ruv

count if cman_ubigeo_inherited_from_ruv
local cman_ubigeo_inherited = r(N)

preserve
keep if !missing(ruv_id)
bysort ruv_id (ubigeo_ccpp): assert ///
    ubigeo_ccpp == ubigeo_ccpp[1]
bysort ruv_id: generate int cman_rows_per_ruv = _N
count if cman_rows_per_ruv > 1
local cman_repeated_project_rows = r(N)
drop cman_rows_per_ruv
restore

count if missing(ruv_id)
local cman_victim_unresolved = r(N)

count if cman_victim_adjudicated
local cman_adjud_retained = r(N)

count if missing(ubigeo_ccpp)
local cman_ubigeo_unresolved = r(N)

count if ///
    !missing(ruv_id) & ///
    cman_inei_ccpp_exact_merge == 3 & ///
    victim_inei_linked & ///
    ubigeo_ccpp != victim_ubigeo_ccpp
assert r(N) == 0
local exact_ubigeo_conflicts = r(N)

compress
sort record_number
save "${derived_root}/03_cman_projects_2023.dta", replace

/*
Create direct CMAN-to-RUV candidates for unresolved project records.
Department is the blocking field. The score emphasizes community name while
retaining district and province agreement. This expensive review artifact is
optional after adjudication and is not required to rebuild the canonical
registry.
*/

local rebuild_cman_name_candidates = 0
assert inlist(`rebuild_cman_name_candidates', 0, 1)

if `rebuild_cman_name_candidates' {

preserve
keep if missing(ruv_id)
keep ///
    record_number ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw
rename province_norm cman_province_norm
rename district_norm cman_district_norm
rename community_norm cman_community_norm
save "${temporary_root}/cman_unresolved_for_victim_candidates.dta", replace
restore

preserve
use "${derived_root}/02_victimization_registry.dta", clear
keep ///
    victimization_source_row ///
    ruv_id ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    ubigeo_dist ///
    ubigeo_ccpp
rename province_norm victim_province_norm
rename district_norm victim_district_norm
rename community_norm victim_community_norm
rename ubigeo_dist victim_ubigeo_dist
rename ubigeo_ccpp victim_ubigeo_ccpp
save "${temporary_root}/victimization_candidate_pool.dta", replace
restore

preserve
use "${temporary_root}/cman_unresolved_for_victim_candidates.dta", clear
joinby region_norm using ///
    "${temporary_root}/victimization_candidate_pool.dta"

victimasrd_score_name_pairs ///
    cman_province_norm victim_province_norm, prefix(province)
victimasrd_score_name_pairs ///
    cman_district_norm victim_district_norm, prefix(district)
victimasrd_score_name_pairs ///
    cman_community_norm victim_community_norm, prefix(community)

generate double full_place_composite = ///
    .10 * province_composite + ///
    .20 * district_composite + ///
    .70 * community_composite

gsort ///
    record_number ///
    -full_place_composite ///
    -community_levenshtein ///
    -district_levenshtein ///
    ruv_id

by record_number: generate int candidate_rank = _n
by record_number: generate double top_score = full_place_composite[1]
by record_number: generate double second_score = full_place_composite[2]

generate double score_margin = top_score - second_score if ///
    candidate_rank == 1

generate str24 review_priority = "standard"
replace review_priority = "high" if ///
    candidate_rank == 1 & ///
    top_score >= .90 & ///
    score_margin >= .10 & ///
    community_levenshtein >= .85 & ///
    district_levenshtein >= .85
replace review_priority = "very_high" if ///
    candidate_rank == 1 & ///
    top_score >= .95 & ///
    score_margin >= .15 & ///
    community_levenshtein >= .90 & ///
    district_levenshtein >= .90

keep if candidate_rank <= 5
sort record_number candidate_rank

save "${qa_root}/cman_victimization_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_root}/cman_victimization_fuzzy_candidates.csv", ///
    replace
restore
}

/*
Preserve every CMAN source row in its canonical registry. Code-less CMAN rows
remain in the audit dataset; those linked by RUV ID can enter the RUV merge,
whereas CMAN-only rows cannot enter because the RUV file is the master.
*/

count if missing(ubigeo_ccpp) & !missing(ruv_id)
local cman_linked_missing_ubigeo = r(N)

preserve
keep if missing(ubigeo_ccpp)
generate str52 linkage_disposition = cond( ///
    !missing(ruv_id), ///
    "retained_via_ruv_id", ///
    "excluded_from_ruv_master_merge")
count if missing(ruv_id)
local cman_ubigeo_excluded = r(N)
save "${qa_root}/cman_ubigeo_unresolved.dta", replace
export delimited ///
    "${qa_root}/cman_ubigeo_unresolved.csv", replace
restore

count if missing(ruv_id) & !missing(ubigeo_ccpp)
local cman_only_with_ubigeo = r(N)

count
local cman_registry_rows = r(N)

compress
sort record_number
save "${derived_root}/03_cman_projects_2023.dta", replace


*===============================================================================
**# 7. Build the foundational victimization-universe dataset
*===============================================================================

preserve
keep if !missing(ruv_id)

bysort ruv_id: generate int cman_project_count = _N
count
local cman_linked_project_rows = r(N)

sort ruv_id recorded_project_year record_number
by ruv_id: keep if _n == 1

count
local cman_victim_linked = r(N)
local cman_repeat_collapsed = ///
    `cman_linked_project_rows' - `cman_victim_linked'

rename ubigeo_ccpp cman_ubigeo_ccpp_exact
rename ccpp_name_inei cman_ccpp_name_inei_exact

keep ///
    ruv_id ///
    cman_project_count ///
    record_number ///
    recorded_project_year ///
    recorded_year_raw ///
    project_raw ///
    legal_instrument_raw ///
    cman_financing_raw ///
    cofinancing_raw ///
    cman_financing_soles ///
    cofinancing_soles ///
    executing_unit_raw ///
    source_page ///
    source_row_on_page ///
    source_year_format_issue ///
    source_money_format_issue ///
    cman_inei_district_exact_merge ///
    cman_inei_ccpp_exact_merge ///
    cman_ubigeo_ccpp_exact ///
    cman_ccpp_name_inei_exact ///
    cman_inei_match_method ///
    cman_victim_match_method

isid ruv_id
save "${temporary_root}/cman_linked_to_victimization.dta", replace
restore

use "${derived_root}/02_victimization_registry.dta", clear

merge 1:1 ruv_id using ///
    "${temporary_root}/cman_linked_to_victimization.dta", ///
    keep(master match) ///
    gen(foundational_cman_merge)

count
assert r(N) == `victimization_analysis_rows'
local foundational_rows = r(N)

count if foundational_cman_merge == 3
assert r(N) == `cman_victim_linked'

count if foundational_cman_merge == 1
assert r(N) == ///
    `victimization_analysis_rows' - `cman_victim_linked'

generate byte prc_project_observed = ///
    foundational_cman_merge == 3

replace cman_project_count = 0 if ///
    !prc_project_observed

generate str52 prc_project_link_status = ///
    cond(prc_project_observed, ///
         "linked_project", ///
         "not_recorded_in_cman_by_2023")

label variable prc_project_observed ///
    "CMAN collective-reparation project linked to RUV community"
label variable prc_project_link_status ///
    "Status of CMAN project linkage to victimization universe"
label variable recorded_project_year ///
    "Authoritative collective-reparation treatment year from CMAN"
label variable cman_project_count ///
    "CMAN project records linked to the RUV community"

/*
Research-team decision: use the CMAN PDF year as the authoritative treatment
year. Annual indicators are cumulative: a community equals one in the recorded
year and every year thereafter. After exhaustive CMAN reconciliation, every
retained RUV record without a linked CMAN project is coded untreated.
*/

assert inrange(recorded_project_year, 2007, 2023) if ///
    prc_project_observed

forvalues year = 2007/2023 {
    local yy = substr("`year'", 3, 2)

    generate byte treat_`yy' = ///
        recorded_project_year <= `year' if ///
        prc_project_observed

    replace treat_`yy' = 0 if ///
        !prc_project_observed

    label variable treat_`yy' ///
        "Collective reparations received by `year'"

    if `year' > 2007 {
        local prior_year = `year' - 1
        local prior_yy = substr("`prior_year'", 3, 2)
        assert treat_`yy' >= treat_`prior_yy' if ///
            !missing(treat_`yy', treat_`prior_yy')
    }
}

/*
Release-variable contract: keep only substantive identifiers, geographic
fields, research measures, INEI attributes, CMAN project fields that may enter
the analysis, and the two linkage-method fields needed for linkage-sensitivity
checks. Parser helpers, normalized strings, raw numeric copies, merge flags,
candidate scores, and source-layout counters remain in the stage-specific QA
artifacts and are not carried into the polished community registry.
*/

keep ///
    ruv_id ///
    expediente_id ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    ubigeo_ccpp_verified ///
    victim_inei_code_vintage ///
    victim_inei_match_method ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    victimization_level_source ///
    victimization_index ///
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
    incursions ///
    violence_start_year ///
    ccpp_name_inei ///
    natural_region_raw ///
    altitude_m ///
    population_2017 ///
    population_male_2017 ///
    population_female_2017 ///
    dwellings_2017 ///
    dwellings_occupied_2017 ///
    dwellings_unoccupied_2017 ///
    prc_project_observed ///
    prc_project_link_status ///
    cman_victim_match_method ///
    cman_project_count ///
    recorded_project_year ///
    treat_* ///
    record_number ///
    project_raw ///
    legal_instrument_raw ///
    cman_financing_soles ///
    cofinancing_soles ///
    executing_unit_raw

order ///
    ruv_id ///
    expediente_id ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    ubigeo_ccpp_verified ///
    victim_inei_code_vintage ///
    victim_inei_match_method ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    victimization_level_source ///
    victimization_index ///
    prc_project_observed ///
    prc_project_link_status ///
    cman_project_count ///
    recorded_project_year ///
    treat_07-treat_23 ///
    record_number

compress
sort ruv_id
isid ruv_id

count if missing(ubigeo_ccpp)
local foundational_missing_ubigeo = r(N)
assert `foundational_missing_ubigeo' == ///
    `victimization_inei_unresolved'
assert `foundational_rows' == `victimization_rows'

egen byte missing_treatment_indicator = rowmiss(treat_07-treat_23)
assert missing_treatment_indicator == 0
drop missing_treatment_indicator

save ///
    "${derived_root}/04_foundational_community_registry.dta", ///
    replace


*===============================================================================
**# 8. Write aggregate QA metrics and close
*===============================================================================

tempname qa_post
tempfile qa_metrics

postfile `qa_post' ///
    str64 metric ///
    double value ///
    str24 status ///
    str244 note ///
    using `qa_metrics', replace

post `qa_post' ///
    ("inei_ccpp_rows") ///
    (`inei_ccpp_rows') ///
    ("validated") ///
    ("Unique ten-digit INEI CCPP records")

post `qa_post' ///
    ("inei_departments") ///
    (`inei_departments') ///
    ("validated") ///
    ("Two-digit department codes")

post `qa_post' ///
    ("inei_districts") ///
    (`inei_districts') ///
    ("validated") ///
    ("Six-digit district codes")

post `qa_post' ///
    ("victimization_rows") ///
    (`victimization_rows') ///
    ("validated") ///
    ("RUV Libro Segundo victimization universe")

post `qa_post' ///
    ("victimization_inei_exact") ///
    (`victimization_inei_exact') ///
    ("partial") ///
    ("Unique exact name within RUV district")

post `qa_post' ///
    ("victimization_inei_unresolved") ///
    (`victimization_inei_unresolved') ///
    ("retained_unresolved") ///
    ("Retained in RUV universe without a verified CCPP UBIGEO")

post `qa_post' ///
    ("victimization_inei_adjudicated") ///
    (`victimization_inei_adjudicated') ///
    ("validated") ///
    ("Accepted versioned RUV-to-UBIGEO adjudications")

post `qa_post' ///
    ("victimization_analysis_rows") ///
    (`victimization_analysis_rows') ///
    ("validated") ///
    ("All RUV source rows retained regardless of UBIGEO linkage status")

post `qa_post' ///
    ("victimization_score_outside_documented_range") ///
    (`victim_outside_doc') ///
    ("research_decision") ///
    ("Observed score falls outside documented 0.007740 to 1.000000 range")

post `qa_post' ///
    ("victimization_level_range_disagreements") ///
    (`victim_level_disagree_n') ///
    ("research_decision") ///
    ("Source category differs from category reconstructed from rounded score")

post `qa_post' ///
    ("cman_project_rows") ///
    (`cman_project_rows') ///
    ("validated") ///
    ("Consecutive PDF records 1 through 4433")

post `qa_post' ///
    ("cman_year_format_issues") ///
    (`cman_year_format_issues') ///
    ("source_issue") ///
    ("Raw year contains a leading or trailing hyphen")

post `qa_post' ///
    ("cman_money_format_issues") ///
    (`cman_money_format_issues') ///
    ("source_issue") ///
    ("One cofinancing value contains two decimal separators")

post `qa_post' ///
    ("cman_inei_district_exact") ///
    (`cman_inei_district_exact') ///
    ("partial") ///
    ("Exact normalized department-province-district path")

post `qa_post' ///
    ("cman_inei_district_unresolved") ///
    (`cman_inei_district_unresolved') ///
    ("review_required") ///
    ("District candidate ledger written")

post `qa_post' ///
    ("cman_inei_ccpp_exact") ///
    (`cman_inei_ccpp_exact') ///
    ("partial") ///
    ("Unique exact CCPP name within exact INEI district")

post `qa_post' ///
    ("cman_inei_ccpp_unresolved") ///
    (`cman_inei_ccpp_unresolved') ///
    ("review_required") ///
    ("CCPP candidate ledger written where district is exact")

post `qa_post' ///
    ("cman_victimization_exact") ///
    (`cman_victim_exact') ///
    ("partial") ///
    ("Exact normalized full geographic path")

post `qa_post' ///
    ("cman_victimization_unresolved") ///
    (`cman_victim_unresolved') ///
    ("documented_exclusion") ///
    ("CMAN rows not linked to the complete RUV source universe")

post `qa_post' ///
    ("cman_victimization_adjudicated") ///
    (`cman_adjud_retained') ///
    ("validated") ///
    ("Accepted CMAN-to-RUV adjudications retained in the coded RUV universe")

post `qa_post' ///
    ("cman_links_to_ruv_missing_ubigeo") ///
    (`cman_missing_ubigeo_link_n') ///
    ("retained") ///
    ("CMAN rows linked to retained RUV communities without verified CCPP UBIGEO")

post `qa_post' ///
    ("cman_victimization_exact_ubigeo") ///
    (`cman_victim_exact_ubigeo') ///
    ("validated") ///
    ("Additional CMAN-to-RUV links recovered by exact verified CCPP UBIGEO")

post `qa_post' ///
    ("cman_ubigeo_inherited_from_ruv") ///
    (`cman_ubigeo_inherited') ///
    ("validated") ///
    ("CMAN codes inherited through a verified direct RUV link")

post `qa_post' ///
    ("cman_ubigeo_excluded") ///
    (`cman_ubigeo_excluded') ///
    ("documented_exclusion") ///
    ("Code-less CMAN-only rows excluded from the RUV-master merge")

post `qa_post' ///
    ("cman_only_with_ubigeo") ///
    (`cman_only_with_ubigeo') ///
    ("documented_exclusion") ///
    ("Verified CMAN communities absent from the retained RUV universe")

post `qa_post' ///
    ("cman_registry_rows") ///
    (`cman_registry_rows') ///
    ("validated") ///
    ("All CMAN source rows retained in the canonical CMAN registry")

post `qa_post' ///
    ("cman_repeated_projects_collapsed") ///
    (`cman_repeat_collapsed') ///
    ("validated") ///
    ("Later CMAN project rows collapsed after retaining the earliest treatment year")

post `qa_post' ///
    ("exact_ubigeo_conflicts") ///
    (`exact_ubigeo_conflicts') ///
    ("validated") ///
    ("Conflicts when both independent INEI links and direct CMAN-RUV link are exact")

post `qa_post' ///
    ("foundational_registry_rows") ///
    (`foundational_rows') ///
    ("validated") ///
    ("All RUV source rows retained; CMAN-only rows excluded")

post `qa_post' ///
    ("foundational_missing_ubigeo") ///
    (`foundational_missing_ubigeo') ///
    ("retained_unresolved") ///
    ("RUV rows retained without a verified ten-digit CCPP UBIGEO")

postclose `qa_post'

use `qa_metrics', clear
export delimited ///
    "${qa_root}/foundational_data_preparation_metrics.csv", ///
    replace

preserve
generate byte include_sample_flow = inlist( ///
    metric, ///
    "victimization_rows", ///
    "victimization_analysis_rows", ///
    "victimization_inei_unresolved", ///
    "cman_project_rows", ///
    "cman_registry_rows", ///
    "cman_ubigeo_excluded", ///
    "cman_only_with_ubigeo") | inlist( ///
    metric, ///
    "cman_links_to_ruv_missing_ubigeo", ///
    "cman_victimization_unresolved", ///
    "foundational_registry_rows", ///
    "foundational_missing_ubigeo")
keep if include_sample_flow
drop include_sample_flow
export delimited ///
    "${metadata_root}/ccpp-linkage/foundational-sample-flow.csv", ///
    replace
restore

display as result "Foundational data-preparation staging completed."
display as text   "INEI CCPP rows:                  `inei_ccpp_rows'"
display as text   "RUV victimization rows:          `victimization_rows'"
display as text   "CMAN project rows:               `cman_project_rows'"
display as text   "Exact CMAN-to-RUV links:         `cman_victim_exact'"
display as text   "Exact UBIGEO CMAN-to-RUV links:  `cman_victim_exact_ubigeo'"
display as text   "Adjudicated CMAN-to-RUV links:   `cman_adjud_retained'"
display as text   "CMAN rows outside the RUV universe: `cman_victim_unresolved'"
display as text   "RUV rows retained without code:  `victimization_inei_unresolved'"
display as text   "Final victimization-universe rows: `foundational_rows'"
display as text   "All RUV rows retained with complete treatment status."

capture program drop victimasrd_normalize_name
capture program drop victimasrd_score_name_pairs
