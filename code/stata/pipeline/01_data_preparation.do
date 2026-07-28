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
    4. Historical and alternative CCPP directories, 2007--2025

Dropbox Raw inputs are immutable. Persistent intermediates and row-level QA
products are written under Dropbox Working; final analytical datasets are
written under Dropbox Coded. Fuzzy candidates are never accepted silently.
*/

version 19
set more off


*===============================================================================
**# 0. Preconditions, paths, and reusable programs
*===============================================================================

local required_globals ///
    project_root ///
    raw_root ///
    pipeline_working_root ///
    intermediate_root ///
    staging_root ///
    qa_data_root ///
    external_derived_root ///
    analysis_data_root ///
    metadata_root ///
    python_exec ///
    ado_root

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

capture confirm file ///
    "${project_root}/code/python/extract_reporte_ccpp_html.py"
if _rc {
    display as error "ReporteCCPP HTML extractor was not found."
    exit 601
}

local raw_lower              = lower(subinstr("${raw_root}", "\", "/", .))
local pipeline_working_lower = lower(subinstr("${pipeline_working_root}", "\", "/", .))
local intermediate_lower     = lower(subinstr("${intermediate_root}", "\", "/", .))
local staging_lower          = lower(subinstr("${staging_root}", "\", "/", .))
local qa_data_lower          = lower(subinstr("${qa_data_root}", "\", "/", .))
local analysis_data_lower    = lower(subinstr("${analysis_data_root}", "\", "/", .))

if strpos("`intermediate_lower'", "`pipeline_working_lower'/") != 1 | ///
   strpos("`staging_lower'", "`pipeline_working_lower'/") != 1 | ///
   strpos("`qa_data_lower'", "`pipeline_working_lower'/") != 1 {
    display as error "Unsafe path contract: intermediate, staging, and QA data must remain under Dropbox Working."
    exit 198
}

if strpos("`analysis_data_lower'", "`raw_lower'/") == 1 | ///
   strpos("`pipeline_working_lower'", "`raw_lower'/") == 1 {
    display as error "Unsafe path contract: no derived dataset may be written under Dropbox Raw."
    exit 198
}

foreach data_directory in ///
    "${pipeline_working_root}" ///
    "${intermediate_root}" ///
    "${staging_root}" ///
    "${qa_data_root}" ///
    "${analysis_data_root}" {

    if !direxists("`data_directory'") {
        display as error "Required Dropbox pipeline directory is unavailable:"
        display as error "  `data_directory'"
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

/*
Scratch datasets exist only for the life of this Stata run. Only the named
milestone datasets saved under Working and Coded persist across runs.
*/

tempfile ///
    inei_ccpp_unique_exact ///
    inei_district_exact ///
    inei_ccpp_candidate_pool ///
    hist_ccpp_sources ///
    hist_ccpp_name_code_pool ///
    hist_dist_name_code_pool ///
    ruv_assigned_codes ///
    ruv_historical_exact ///
    ruv_unresolved_candidates ///
    ruv_unique_name_path ///
    ruv_unique_id ///
    ruv_unique_ubigeo ///
    cman_unresolved_districts ///
    cman_hist_dist ///
    cman_hist_ccpp ///
    inei_district_candidate_pool ///
    cman_unresolved_ccpp ///
    cman_unresolved_ruv ///
    ruv_candidate_pool ///
    cman_linked_ruv

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
    "${qa_data_root}/cman_projects_2023_extraction_manifest.json"
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
save "${intermediate_root}/01_inei_ccpp_2017.dta", replace

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
    "${qa_data_root}/inei_ccpp_2017_summary_by_department.csv", ///
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
save "`inei_ccpp_unique_exact'", replace
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
save "`inei_district_exact'", replace
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
save "`inei_ccpp_candidate_pool'", replace
restore


*===============================================================================
**# 3. Build the historical and alternative CCPP evidence directory
*===============================================================================

/*
The RUV registry predates the 2017 INEI spine. A community can therefore have
a verifiable historical code even when its name or code disappeared from the
current directory. Build one row-preserving evidence file from every supplied
CCPP source. These sources never overwrite each other; exact matching below is
accepted only when all exact within-district evidence points to one unused
ten-digit code.
*/

local ccpp_source_root ///
    "${raw_root}/11 Centros Poblados"
local reporte_ccpp_csv ///
    "${staging_root}/reporte_ccpp_2016_extracted.csv"
local reporte_ccpp_manifest ///
    "${qa_data_root}/reporte_ccpp_2016_extraction_manifest.json"
local reporte_ccpp_extractor ///
    "${project_root}/code/python/extract_reporte_ccpp_html.py"

foreach required_file in ///
    "`ccpp_source_root'/20161027_CodCentPobRegFormActColectivasFAC.xlsx" ///
    "`ccpp_source_root'/CCPP 2007.xlsx" ///
    "`ccpp_source_root'/4. PBI_CentrosPoblados_1993-2018.xlsx" ///
    "`ccpp_source_root'/Centros_Poblados_INEI_geogpsperu_SuyoPomalia (1)/Centros_Poblados_INEI_geogpsperu_SuyoPomalia.dbf" ///
    "${external_derived_root}/ign_centros_poblados_2025.dta" ///
    "`reporte_ccpp_extractor'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Required historical CCPP source was not found:"
        display as error "  `required_file'"
        exit 601
    }
}

capture erase "`reporte_ccpp_csv'"
capture erase "`reporte_ccpp_manifest'"

local reporte_command ///
    `""${python_exec}" "`reporte_ccpp_extractor'" --input-dir "`ccpp_source_root'" --output "`reporte_ccpp_csv'" --manifest "`reporte_ccpp_manifest'" --expected-departments 25"'

display as text ///
    "Extracting the 25 department ReporteCCPP HTML tables."
shell `reporte_command'

foreach extracted_file in ///
    "`reporte_ccpp_csv'" ///
    "`reporte_ccpp_manifest'" {

    capture confirm file "`extracted_file'"
    if _rc {
        display as error "Expected ReporteCCPP extraction output was not created:"
        display as error "  `extracted_file'"
        exit 603
    }
}

/*
INEI FAC national directory. The workbook embeds the administrative code at
the beginning of each geography string.
*/

import excel ///
    "`ccpp_source_root'/20161027_CodCentPobRegFormActColectivasFAC.xlsx", ///
    sheet("Hoja1") firstrow allstring clear

count
assert r(N) == 65535

generate long source_row = _n
generate str10 ubigeo_ccpp = substr(CENTROPOBLADO, 1, 10)
generate str6 ubigeo_dist = substr(ubigeo_ccpp, 1, 6)
generate str4 ubigeo_prov = substr(ubigeo_ccpp, 1, 4)
generate str2 ubigeo_dpto = substr(ubigeo_ccpp, 1, 2)
generate str244 region_raw = ///
    ustrtrim(substr(DEPARTAMENTO, 4, strlen(DEPARTAMENTO)))
generate str244 province_raw = ///
    ustrtrim(substr(PROVINCIA, 6, strlen(PROVINCIA)))
generate str244 district_raw = ///
    ustrtrim(substr(DISTRITO, 8, strlen(DISTRITO)))
generate str244 source_name_raw = ///
    ustrtrim(substr(CENTROPOBLADO, 12, strlen(CENTROPOBLADO)))
generate str16 rurality_raw = ""
generate str32 source_id = "fac_2016"
generate str32 source_family = "inei_fac_2016"
generate str12 source_vintage = "2016"
generate str80 source_file = ///
    "20161027_CodCentPobRegFormActColectivasFAC.xlsx"
generate byte source_priority = 2

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name source_name_raw, generate(community_norm)

assert ustrregexm(ubigeo_ccpp, "^[0-9]{10}$")
assert substr(ubigeo_ccpp, 1, 6) == ubigeo_dist
isid source_id source_row

keep ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_priority ///
    source_row ///
    ubigeo_dpto ///
    ubigeo_prov ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    region_raw ///
    province_raw ///
    district_raw ///
    source_name_raw ///
    rurality_raw ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm

save "`hist_ccpp_sources'", replace

/*
The 2007 census workbook has a two-row header. With firstrow, its first
observation contains the field labels and its final observations contain a
source note. A ten-digit code identifies the 45,677 valid community rows.
*/

import excel ///
    "`ccpp_source_root'/CCPP 2007.xlsx", ///
    sheet("Hoja1") firstrow allstring clear

generate long source_row = _n
keep if ustrregexm(A, "^[0-9]{10}$")
count
assert r(N) == 45677

generate str10 ubigeo_ccpp = A
generate str6 ubigeo_dist = substr(ubigeo_ccpp, 1, 6)
generate str4 ubigeo_prov = substr(ubigeo_ccpp, 1, 4)
generate str2 ubigeo_dpto = substr(ubigeo_ccpp, 1, 2)
generate str244 region_raw = C
generate str244 province_raw = D
generate str244 district_raw = E
generate str244 source_name_raw = F
generate str16 rurality_raw = G
generate str32 source_id = "census_2007"
generate str32 source_family = "census_2007"
generate str12 source_vintage = "2007"
generate str80 source_file = "CCPP 2007.xlsx"
generate byte source_priority = 1

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name source_name_raw, generate(community_norm)

isid source_id source_row

keep ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_priority ///
    source_row ///
    ubigeo_dpto ///
    ubigeo_prov ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    region_raw ///
    province_raw ///
    district_raw ///
    source_name_raw ///
    rurality_raw ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm

append using "`hist_ccpp_sources'"
save "`hist_ccpp_sources'", replace

/*
The PBI/night-lights panel supplies a broad historical CCPP code-name spine
covering economic activity from 1993 through 2018. Economic measures are not
carried into this identifier-only auxiliary directory.
*/

import excel ///
    "`ccpp_source_root'/4. PBI_CentrosPoblados_1993-2018.xlsx", ///
    sheet("PBI_CP") firstrow allstring clear

generate long source_row = _n
keep if ustrregexm(IDCARTOGR, "^[0-9]{10}$")
count
assert r(N) == 98011

generate str10 ubigeo_ccpp = IDCARTOGR
generate str6 ubigeo_dist = substr(ubigeo_ccpp, 1, 6)
generate str4 ubigeo_prov = substr(ubigeo_ccpp, 1, 4)
generate str2 ubigeo_dpto = substr(ubigeo_ccpp, 1, 2)
generate str244 region_raw = NOMB_DEP
generate str244 province_raw = NOMB_PRO
generate str244 district_raw = NOMB_DIST
generate str244 source_name_raw = NOMCCPP
generate str16 rurality_raw = ""
generate str32 source_id = "pbi_1993_2018"
generate str32 source_family = "pbi_1993_2018"
generate str12 source_vintage = "1993-2018"
generate str80 source_file = ///
    "4. PBI_CentrosPoblados_1993-2018.xlsx"
generate byte source_priority = 4

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name source_name_raw, generate(community_norm)

isid source_id ubigeo_ccpp

keep ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_priority ///
    source_row ///
    ubigeo_dpto ///
    ubigeo_prov ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    region_raw ///
    province_raw ///
    district_raw ///
    source_name_raw ///
    rurality_raw ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm

append using "`hist_ccpp_sources'"
save "`hist_ccpp_sources'", replace

/*
The department ReporteCCPP files are HTML tables carrying a 2016-5 UBIGEO
criterion despite their .xls extensions. The extractor validates all 25
departments and removes one byte-identical duplicate download.
*/

import delimited using "`reporte_ccpp_csv'", ///
    varnames(1) stringcols(_all) clear

count
assert r(N) == 94922

destring source_row_number, generate(source_row)
generate str244 source_name_raw = community_raw
generate str32 source_id = "reporte_ccpp_2016"
generate str32 source_family = "inei_spine_derivative"
generate str12 source_vintage = "2016"
generate str80 source_file_clean = source_file
drop source_file
rename source_file_clean source_file
generate byte source_priority = 3
generate str16 rurality_raw = area_raw

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name source_name_raw, generate(community_norm)

isid source_id ubigeo_ccpp

keep ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_priority ///
    source_row ///
    ubigeo_dpto ///
    ubigeo_prov ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    region_raw ///
    province_raw ///
    district_raw ///
    source_name_raw ///
    rurality_raw ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm

append using "`hist_ccpp_sources'"
save "`hist_ccpp_sources'", replace

/*
The GeoGPS layer reproduces the 94,922-row INEI code spine and adds a spatial
representation. Treat it as corroboration from the same directory family,
not as an independent historical source.
*/

import dbase using ///
    "`ccpp_source_root'/Centros_Poblados_INEI_geogpsperu_SuyoPomalia (1)/Centros_Poblados_INEI_geogpsperu_SuyoPomalia.dbf", ///
    clear

count
assert r(N) == 94922

generate long source_row = _n
generate str10 ubigeo_ccpp = IDCCPP
generate str6 ubigeo_dist = substr(ubigeo_ccpp, 1, 6)
generate str4 ubigeo_prov = substr(ubigeo_ccpp, 1, 4)
generate str2 ubigeo_dpto = substr(ubigeo_ccpp, 1, 2)
generate str244 region_raw = NOMB_DEPAR
generate str244 province_raw = NOMB_PROVI
generate str244 district_raw = NOMB_DISTR
generate str244 source_name_raw = NOMB_CCPP
generate str16 rurality_raw = TIPO
generate str32 source_id = "geogps_inei_2023"
generate str32 source_family = "inei_spine_derivative"
generate str12 source_vintage = "2023"
generate str80 source_file = ///
    "Centros_Poblados_INEI_geogpsperu_SuyoPomalia.dbf"
generate byte source_priority = 5

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name source_name_raw, generate(community_norm)

isid source_id ubigeo_ccpp

keep ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_priority ///
    source_row ///
    ubigeo_dpto ///
    ubigeo_prov ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    region_raw ///
    province_raw ///
    district_raw ///
    source_name_raw ///
    rurality_raw ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm

append using "`hist_ccpp_sources'"
save "`hist_ccpp_sources'", replace

/*
The converted IGN 2025 layer remains in Dropbox Working. Its immutable raw ZIP
and shapefile are recorded under Dropbox Raw external administrative sources.
*/

use ///
    "${external_derived_root}/ign_centros_poblados_2025.dta", ///
    clear

count
assert r(N) == 136587

generate long source_row = _n
generate str10 ubigeo_ccpp = CÓDIGO

/*
The converted IGN file lost the leading zero on 680 Áncash codes. The
department, province, district, and four-digit CCPP components remain present;
restore that formatting loss before validating the ten-digit identifier.
*/

replace ubigeo_ccpp = "0" + ubigeo_ccpp if ///
    DEP == "ANCASH" & ///
    ustrregexm(ubigeo_ccpp, "^[0-9]{9}$")

keep if ustrregexm(ubigeo_ccpp, "^[0-9]{10}$")
count
assert r(N) == 64199

generate str6 ubigeo_dist = substr(ubigeo_ccpp, 1, 6)
generate str4 ubigeo_prov = substr(ubigeo_ccpp, 1, 4)
generate str2 ubigeo_dpto = substr(ubigeo_ccpp, 1, 2)
generate str244 region_raw = DEP
generate str244 province_raw = PROV
generate str244 district_raw = DIST
generate str244 source_name_raw = NOM_POBLAD
generate str16 rurality_raw = ""
generate str32 source_id = "ign_2025"
generate str32 source_family = "ign_2025"
generate str12 source_vintage = "2025"
generate str80 source_file = "ign_centros_poblados_2025"
generate byte source_priority = 6

victimasrd_normalize_name region_raw, generate(region_norm)
victimasrd_normalize_name province_raw, generate(province_norm)
victimasrd_normalize_name district_raw, generate(district_norm)
victimasrd_normalize_name source_name_raw, generate(community_norm)

isid source_id source_row

keep ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_priority ///
    source_row ///
    ubigeo_dpto ///
    ubigeo_prov ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    region_raw ///
    province_raw ///
    district_raw ///
    source_name_raw ///
    rurality_raw ///
    region_norm ///
    province_norm ///
    district_norm ///
    community_norm

append using "`hist_ccpp_sources'"

count
assert r(N) == 463266
local historical_source_rows = r(N)
assert substr(ubigeo_ccpp, 1, 6) == ubigeo_dist

compress
sort source_priority source_id ubigeo_ccpp
save "`hist_ccpp_sources'", replace
save ///
    "${intermediate_root}/01_auxiliary_historical_ccpp_directories.dta", ///
    replace

preserve
contract source_id source_family source_vintage
rename _freq source_rows
sort source_id
export delimited ///
    "${qa_data_root}/historical_ccpp_source_counts.csv", ///
    replace
restore

/*
Create one candidate row for each distinct district-name-code combination.
Source-family counts do not double-count the ReporteCCPP and GeoGPS copies of
the same INEI spine.
*/

preserve
drop if missing(ubigeo_dist, community_norm)

bysort ///
    source_family ///
    ubigeo_dist ///
    community_norm ///
    ubigeo_ccpp: ///
    generate byte tag_source_family = _n == 1

bysort ///
    ubigeo_dist ///
    community_norm ///
    ubigeo_ccpp: ///
    egen byte source_family_n = total(tag_source_family)

bysort ///
    ubigeo_dist ///
    community_norm ///
    ubigeo_ccpp ///
    (source_priority source_id): ///
    keep if _n == 1

merge m:1 ubigeo_ccpp using ///
    "${intermediate_root}/01_inei_ccpp_2017.dta", ///
    keep(master match) ///
    gen(historical_code_inei_merge)

generate byte candidate_in_inei_2017 = ///
    historical_code_inei_merge == 3
drop historical_code_inei_merge

generate str12 candidate_code_vintage = source_vintage
replace candidate_code_vintage = "2017" if ///
    candidate_in_inei_2017

keep ///
    ubigeo_dist ///
    community_norm ///
    ubigeo_ccpp ///
    source_family_n ///
    source_id ///
    source_family ///
    source_vintage ///
    source_file ///
    source_name_raw ///
    candidate_in_inei_2017 ///
    candidate_code_vintage

isid ubigeo_dist community_norm ubigeo_ccpp
save "`hist_ccpp_name_code_pool'", replace
restore

preserve
drop if missing( ///
    region_norm, province_norm, district_norm, ubigeo_dist)

bysort ///
    source_family ///
    region_norm ///
    province_norm ///
    district_norm ///
    ubigeo_dist: ///
    generate byte tag_source_family = _n == 1

bysort ///
    region_norm ///
    province_norm ///
    district_norm ///
    ubigeo_dist: ///
    egen byte source_family_n = total(tag_source_family)

bysort ///
    region_norm ///
    province_norm ///
    district_norm ///
    ubigeo_dist ///
    (source_priority source_id): ///
    keep if _n == 1

keep ///
    region_norm ///
    province_norm ///
    district_norm ///
    ubigeo_dist ///
    source_family_n ///
    source_id ///
    source_vintage ///
    source_file ///
    region_raw ///
    province_raw ///
    district_raw

isid region_norm province_norm district_norm ubigeo_dist
save "`hist_dist_name_code_pool'", replace
restore


*===============================================================================
**# 4. Clean the RUV Libro Segundo victimization-index registry
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
    "`inei_ccpp_unique_exact'", ///
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

generate str12 victim_inei_code_vintage = ///
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
assert inlist( ///
    code_vintage, ///
    "2007", "2016", "2017", "2025", "1993-2018")
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

/*
Search the supplied historical directories only for RUV rows still lacking a
code after the reviewed adjudication ledger. An exact normalized name within
the RUV-supplied district is accepted automatically only when every exact
source occurrence points to one code and that code is not already assigned to
another RUV record. Ambiguous and duplicate-identity cases remain in QA.
*/

preserve
keep if !missing(ubigeo_ccpp)
keep ruv_id ubigeo_ccpp
rename ruv_id assigned_ruv_id
isid ubigeo_ccpp
save "`ruv_assigned_codes'", replace
restore

preserve
keep if missing(ubigeo_ccpp)
keep ///
    ruv_id ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    ubigeo_dist ///
    community_norm

joinby ubigeo_dist community_norm using ///
    "`hist_ccpp_name_code_pool'"

bysort ruv_id ubigeo_ccpp: ///
    generate byte tag_candidate_code = _n == 1
bysort ruv_id: ///
    egen int candidate_code_n = total(tag_candidate_code)

merge m:1 ubigeo_ccpp using ///
    "`ruv_assigned_codes'", ///
    keep(master match) ///
    gen(candidate_code_occupancy_merge)

generate byte candidate_code_already_assigned = ///
    candidate_code_occupancy_merge == 3
drop candidate_code_occupancy_merge

generate str48 candidate_disposition = ///
    "accepted_exact_unique_unused"
replace candidate_disposition = ///
    "review_multiple_exact_codes" if ///
    candidate_code_n > 1
replace candidate_disposition = ///
    "review_code_assigned_to_other_ruv" if ///
    candidate_code_already_assigned

bysort ruv_id: generate byte tag_candidate_ruv = _n == 1
count if tag_candidate_ruv
local victim_hist_candidate_n = r(N)

sort ruv_id ubigeo_ccpp source_id
save ///
    "${qa_data_root}/ruv_multisource_exact_candidates.dta", ///
    replace
export delimited ///
    "${qa_data_root}/ruv_multisource_exact_candidates.csv", ///
    replace

keep if ///
    candidate_code_n == 1 & ///
    !candidate_code_already_assigned
bysort ruv_id ubigeo_ccpp: keep if _n == 1

keep ///
    ruv_id ///
    ubigeo_ccpp ///
    candidate_code_vintage ///
    source_id ///
    source_family ///
    source_file ///
    source_name_raw ///
    source_family_n

rename ubigeo_ccpp historical_ubigeo_ccpp
rename candidate_code_vintage historical_code_vintage

generate str48 historical_match_method = ///
    "exact_multisource_historical_name"

isid ruv_id
isid historical_ubigeo_ccpp
local victim_hist_exact_n = _N
save "`ruv_historical_exact'", replace
restore

merge 1:1 ruv_id using ///
    "`ruv_historical_exact'", ///
    gen(ruv_historical_exact_merge)

count if ruv_historical_exact_merge == 2
assert r(N) == 0

assert missing(ubigeo_ccpp) if ///
    ruv_historical_exact_merge == 3

replace ubigeo_ccpp = historical_ubigeo_ccpp if ///
    ruv_historical_exact_merge == 3
replace victim_inei_code_vintage = ///
    historical_code_vintage if ///
    ruv_historical_exact_merge == 3
replace victim_inei_match_method = ///
    historical_match_method if ///
    ruv_historical_exact_merge == 3

generate byte victim_historical_exact = ///
    ruv_historical_exact_merge == 3

drop ///
    historical_ubigeo_ccpp ///
    historical_code_vintage ///
    historical_match_method ///
    source_id ///
    source_family ///
    source_file ///
    source_name_raw ///
    source_family_n ///
    ruv_historical_exact_merge

merge m:1 ubigeo_ccpp using ///
    "${intermediate_root}/01_inei_ccpp_2017.dta", ///
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
save "`ruv_unresolved_candidates'", replace
save "${qa_data_root}/ruv_ubigeo_unresolved.dta", replace
export delimited ///
    "${qa_data_root}/ruv_ubigeo_unresolved.csv", replace
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
save "${intermediate_root}/02_victimization_registry.dta", replace

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
save "`ruv_unique_name_path'", replace
restore

/*
Reload the canonical stage explicitly before preparing the unresolved-review
pool. This avoids relying on Stata's preserved-data state after the crosswalk
renames above and makes the source of this review extract unambiguous.
*/
use "${intermediate_root}/02_victimization_registry.dta", clear

preserve
keep ruv_id ubigeo_dist ubigeo_ccpp
rename ubigeo_dist victim_ubigeo_dist
rename ubigeo_ccpp victim_ubigeo_ccpp
generate byte victim_inei_linked = ///
    !missing(victim_ubigeo_ccpp)
isid ruv_id
save "`ruv_unique_id'", replace
restore

preserve
keep ruv_id ubigeo_ccpp
drop if missing(ubigeo_ccpp)
rename ruv_id ubigeo_ruv_id
isid ubigeo_ccpp
save "`ruv_unique_ubigeo'", replace
restore

/*
Generate five INEI candidates for every unresolved RUV community, blocked on
the RUV-supplied six-digit district code. Candidate scores support review; they
do not alter ubigeo_ccpp.
*/

use "`ruv_unresolved_candidates'", clear
joinby ubigeo_dist using ///
    "`inei_ccpp_candidate_pool'"

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

save "${qa_data_root}/victimization_inei_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_data_root}/victimization_inei_fuzzy_candidates.csv", ///
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

*===============================================================================
**# 5. Link CMAN independently to the INEI directory
*===============================================================================

merge m:1 region_norm province_norm district_norm using ///
    "`inei_district_exact'", ///
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

/*
Recover historical district codes only when every exact normalized occurrence
across the dated directories points to the same six-digit code.
*/

preserve
keep if cman_inei_district_exact_merge == 1
keep ///
    record_number ///
    region_norm ///
    province_norm ///
    district_norm

joinby ///
    region_norm ///
    province_norm ///
    district_norm using ///
    "`hist_dist_name_code_pool'", unmatched(master)

drop if missing(ubigeo_dist)
bysort record_number ubigeo_dist: keep if _n == 1
bysort record_number: generate int candidate_code_n = _N

sort record_number ubigeo_dist
save ///
    "${qa_data_root}/cman_multisource_district_exact_candidates.dta", ///
    replace
export delimited ///
    "${qa_data_root}/cman_multisource_district_exact_candidates.csv", ///
    replace

keep if candidate_code_n == 1
rename ubigeo_dist historical_ubigeo_dist
rename source_id historical_district_source_id
rename source_vintage historical_district_vintage
keep ///
    record_number ///
    historical_ubigeo_dist ///
    historical_district_source_id ///
    historical_district_vintage
isid record_number
save "`cman_hist_dist'", replace
local cman_historical_district_exact = _N
restore

merge 1:1 record_number using "`cman_hist_dist'", ///
    keep(master match) ///
    gen(cman_historical_district_merge)

generate byte cman_historical_district_exact = ///
    cman_historical_district_merge == 3

replace ubigeo_dist = historical_ubigeo_dist if ///
    cman_historical_district_exact

drop ///
    historical_ubigeo_dist ///
    historical_district_source_id ///
    historical_district_vintage ///
    cman_historical_district_merge

count if missing(ubigeo_dist)
local cman_district_still_unresolved = r(N)

merge m:1 ubigeo_dist community_norm using ///
    "`inei_ccpp_unique_exact'", ///
    keep(master match) ///
    gen(cman_inei_ccpp_exact_merge)

count
assert r(N) == 4433

count if cman_inei_ccpp_exact_merge == 3
local cman_inei_ccpp_exact = r(N)

count if cman_inei_ccpp_exact_merge == 1
local cman_inei_ccpp_unresolved = r(N)
assert ///
    `cman_inei_ccpp_exact' + ///
    `cman_inei_ccpp_unresolved' == 4433

generate str48 cman_inei_match_method = ///
    cond(cman_inei_ccpp_exact_merge == 3, ///
         "exact_hierarchy_and_unique_normalized_name", ///
         "unresolved_review_required")

/*
Apply the same conservative exact-name rule to the historical CCPP pool.
Candidates are retained for audit, but a code is assigned only when every
source occurrence for the exact district-name pair identifies one code.
*/

preserve
keep if ///
    missing(ubigeo_ccpp) & ///
    !missing(ubigeo_dist)
keep ///
    record_number ///
    ubigeo_dist ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw ///
    community_norm

joinby ubigeo_dist community_norm using ///
    "`hist_ccpp_name_code_pool'", unmatched(master)

drop if missing(ubigeo_ccpp)
bysort record_number ubigeo_ccpp: keep if _n == 1
bysort record_number: generate int candidate_code_n = _N

sort record_number ubigeo_ccpp
save ///
    "${qa_data_root}/cman_multisource_ccpp_exact_candidates.dta", ///
    replace
export delimited ///
    "${qa_data_root}/cman_multisource_ccpp_exact_candidates.csv", ///
    replace

keep if candidate_code_n == 1
rename ubigeo_ccpp historical_ubigeo_ccpp
rename source_name_raw historical_ccpp_name
rename source_id historical_ccpp_source_id
rename candidate_code_vintage historical_ccpp_vintage
keep ///
    record_number ///
    historical_ubigeo_ccpp ///
    historical_ccpp_name ///
    historical_ccpp_source_id ///
    historical_ccpp_vintage
isid record_number
save "`cman_hist_ccpp'", replace
local cman_historical_ccpp_exact = _N
restore

merge 1:1 record_number using "`cman_hist_ccpp'", ///
    keep(master match) ///
    gen(cman_historical_ccpp_merge)

generate byte cman_historical_ccpp_exact = ///
    cman_historical_ccpp_merge == 3

replace ubigeo_ccpp = historical_ubigeo_ccpp if ///
    cman_historical_ccpp_exact
replace ccpp_name_inei = historical_ccpp_name if ///
    cman_historical_ccpp_exact & ///
    missing(ccpp_name_inei)
replace cman_inei_match_method = ///
    "exact_multisource_historical_name" if ///
    cman_historical_ccpp_exact

generate byte cman_independent_exact_ubigeo = ///
    cman_inei_ccpp_exact_merge == 3 | ///
    cman_historical_ccpp_exact

drop ///
    historical_ubigeo_ccpp ///
    historical_ccpp_name ///
    historical_ccpp_source_id ///
    historical_ccpp_vintage ///
    cman_historical_ccpp_merge

count if missing(ubigeo_ccpp)
local cman_ccpp_still_unresolved = r(N)

/*
District candidates for the distinct CMAN paths that remain unresolved after
the current and historical exact-name passes. Candidate generation is blocked
on department and scores province plus district.
*/

preserve
keep if missing(ubigeo_dist)
keep region_norm province_norm district_norm
bysort region_norm province_norm district_norm: keep if _n == 1
generate long cman_district_review_id = _n
rename province_norm cman_province_norm
rename district_norm cman_district_norm
save "`cman_unresolved_districts'", replace
restore

preserve
use "`inei_district_exact'", clear
generate long inei_district_candidate_id = _n
rename province_norm inei_province_norm
rename district_norm inei_district_norm
save "`inei_district_candidate_pool'", replace
restore

preserve
use "`cman_unresolved_districts'", clear
joinby region_norm using ///
    "`inei_district_candidate_pool'"

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

save "${qa_data_root}/cman_inei_district_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_data_root}/cman_inei_district_fuzzy_candidates.csv", ///
    replace
restore

/*
CCPP candidates for CMAN records whose district matched exactly but whose
community name did not have a unique exact INEI match.
*/

preserve
keep if ///
    missing(ubigeo_ccpp) & ///
    !missing(ubigeo_dist)
keep ///
    record_number ///
    ubigeo_dist ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw ///
    community_norm
rename community_norm cman_name_norm
save "`cman_unresolved_ccpp'", replace
restore

preserve
use "`cman_unresolved_ccpp'", clear
joinby ubigeo_dist using ///
    "`inei_ccpp_candidate_pool'"

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

save "${qa_data_root}/cman_inei_ccpp_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_data_root}/cman_inei_ccpp_fuzzy_candidates.csv", ///
    replace
restore


*===============================================================================
**# 6. Link CMAN projects directly to the victimization registry
*===============================================================================

merge 1:1 region_norm province_norm district_norm community_norm using ///
    "`ruv_unique_name_path'", ///
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
    "`ruv_unique_ubigeo'", ///
    keep(master match) ///
    gen(cman_victim_ubigeo_merge)

/*
Historical directories occasionally reuse a name that is attached to a
different RUV record's verified code. Preserve those contradictions in QA and
quarantine the historical CMAN code; do not let it override the direct,
unique full-name CMAN-to-RUV link.
*/

generate byte cman_historical_ubigeo_conflict = ///
    cman_historical_ccpp_exact & ///
    !missing(ruv_id, ubigeo_ruv_id) & ///
    ruv_id != ubigeo_ruv_id

count if cman_historical_ubigeo_conflict
local cman_hist_code_conflicts = r(N)

preserve
keep if cman_historical_ubigeo_conflict
keep ///
    record_number ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw ///
    ubigeo_ccpp ///
    cman_inei_match_method ///
    ruv_id ///
    ubigeo_ruv_id
sort record_number
save ///
    "${qa_data_root}/cman_historical_ubigeo_conflicts.dta", ///
    replace
export delimited ///
    "${qa_data_root}/cman_historical_ubigeo_conflicts.csv", ///
    replace
restore

assert ruv_id == ubigeo_ruv_id if ///
    !missing(ruv_id, ubigeo_ruv_id) & ///
    !cman_historical_ubigeo_conflict

replace ubigeo_ccpp = "" if ///
    cman_historical_ubigeo_conflict
replace ccpp_name_inei = "" if ///
    cman_historical_ubigeo_conflict
replace cman_inei_match_method = ///
    "quarantined_historical_code_conflict" if ///
    cman_historical_ubigeo_conflict
replace cman_historical_ccpp_exact = 0 if ///
    cman_historical_ubigeo_conflict
replace cman_independent_exact_ubigeo = 0 if ///
    cman_historical_ubigeo_conflict

count if cman_historical_ccpp_exact
local cman_historical_ccpp_exact = r(N)

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
    "`ruv_unique_id'", ///
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
The direct RUV-ID merge can reveal a second conflict class: a historical CMAN
code differs from the verified code of the same exact-name RUV record. Keep a
separate ledger, quarantine the historical code, and let the verified RUV code
be inherited below.
*/

generate byte cman_hist_ruv_conflict = ///
    cman_historical_ccpp_exact & ///
    !missing(ruv_id) & ///
    victim_inei_linked & ///
    ubigeo_ccpp != victim_ubigeo_ccpp

count if cman_hist_ruv_conflict
local cman_hist_code_conflicts = ///
    `cman_hist_code_conflicts' + r(N)

preserve
keep if cman_hist_ruv_conflict
keep ///
    record_number ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw ///
    ubigeo_ccpp ///
    cman_inei_match_method ///
    ruv_id ///
    victim_ubigeo_ccpp
sort record_number
save ///
    "${qa_data_root}/cman_historical_ruv_code_conflicts.dta", ///
    replace
export delimited ///
    "${qa_data_root}/cman_historical_ruv_code_conflicts.csv", ///
    replace
restore

replace ubigeo_ccpp = "" if ///
    cman_hist_ruv_conflict
replace ccpp_name_inei = "" if ///
    cman_hist_ruv_conflict
replace cman_inei_match_method = ///
    "quarantined_historical_code_conflict" if ///
    cman_hist_ruv_conflict
replace cman_historical_ccpp_exact = 0 if ///
    cman_hist_ruv_conflict
replace cman_independent_exact_ubigeo = 0 if ///
    cman_hist_ruv_conflict

count if cman_historical_ccpp_exact
local cman_historical_ccpp_exact = r(N)

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
    cman_independent_exact_ubigeo & ///
    victim_inei_linked & ///
    ubigeo_ccpp != victim_ubigeo_ccpp
assert r(N) == 0
local exact_ubigeo_conflicts = r(N)

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
save "`cman_unresolved_ruv'", replace
restore

preserve
use "${intermediate_root}/02_victimization_registry.dta", clear
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
save "`ruv_candidate_pool'", replace
restore

preserve
use "`cman_unresolved_ruv'", clear
joinby region_norm using ///
    "`ruv_candidate_pool'"

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

save "${qa_data_root}/cman_victimization_fuzzy_candidates.dta", replace
export delimited ///
    "${qa_data_root}/cman_victimization_fuzzy_candidates.csv", ///
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
save "${qa_data_root}/cman_ubigeo_unresolved.dta", replace
export delimited ///
    "${qa_data_root}/cman_ubigeo_unresolved.csv", replace
restore

count if missing(ruv_id) & !missing(ubigeo_ccpp)
local cman_only_with_ubigeo = r(N)

count
local cman_registry_rows = r(N)

compress
sort record_number
save "${intermediate_root}/03_cman_projects_2023.dta", replace


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
save "`cman_linked_ruv'", replace
restore

use "${intermediate_root}/02_victimization_registry.dta", clear

merge 1:1 ruv_id using ///
    "`cman_linked_ruv'", ///
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
    "${analysis_data_root}/04_foundational_community_registry.dta", ///
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
    ("historical_ccpp_source_rows") ///
    (`historical_source_rows') ///
    ("validated") ///
    ("Rows pooled from six dated or alternative CCPP source families")

post `qa_post' ///
    ("victimization_historical_exact") ///
    (`victim_hist_exact_n') ///
    ("validated") ///
    ("RUV codes recovered by exact unique unused historical name")

post `qa_post' ///
    ("victimization_historical_candidates") ///
    (`victim_hist_candidate_n') ///
    ("reviewed") ///
    ("RUV rows with at least one exact historical name-code candidate")

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
    ("Unresolved after current 2017 directory; historical pass follows")

post `qa_post' ///
    ("cman_historical_district_exact") ///
    (`cman_historical_district_exact') ///
    ("validated") ///
    ("District codes recovered by exact unique multisource name")

post `qa_post' ///
    ("cman_district_still_unresolved") ///
    (`cman_district_still_unresolved') ///
    ("review_required") ///
    ("Unresolved after current and historical exact district passes")

post `qa_post' ///
    ("cman_inei_ccpp_exact") ///
    (`cman_inei_ccpp_exact') ///
    ("partial") ///
    ("Unique exact CCPP name within a resolved current district")

post `qa_post' ///
    ("cman_inei_ccpp_unresolved") ///
    (`cman_inei_ccpp_unresolved') ///
    ("review_required") ///
    ("Unresolved after current CCPP exact-name pass")

post `qa_post' ///
    ("cman_historical_ccpp_exact") ///
    (`cman_historical_ccpp_exact') ///
    ("validated") ///
    ("Historical exact CCPP codes retained after conflict quarantine")

post `qa_post' ///
    ("cman_historical_code_conflicts") ///
    (`cman_hist_code_conflicts') ///
    ("quarantined") ///
    ("Historical CMAN codes contradicting a direct or verified RUV link")

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
    "${qa_data_root}/foundational_data_preparation_metrics.csv", ///
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
display as text   "Historical source rows pooled:  `historical_source_rows'"
display as text   "RUV victimization rows:          `victimization_rows'"
display as text   "Historical exact RUV recoveries: `victim_hist_exact_n'"
display as text   "CMAN project rows:               `cman_project_rows'"
display as text   "Historical exact CMAN codes:     `cman_historical_ccpp_exact'"
display as text   "Historical codes quarantined:    `cman_hist_code_conflicts'"
display as text   "Exact CMAN-to-RUV links:         `cman_victim_exact'"
display as text   "Exact UBIGEO CMAN-to-RUV links:  `cman_victim_exact_ubigeo'"
display as text   "Adjudicated CMAN-to-RUV links:   `cman_adjud_retained'"
display as text   "CMAN rows outside the RUV universe: `cman_victim_unresolved'"
display as text   "RUV rows retained without code:  `victimization_inei_unresolved'"
display as text   "Final victimization-universe rows: `foundational_rows'"
display as text   "All RUV rows retained with complete treatment status."

capture program drop victimasrd_normalize_name
capture program drop victimasrd_score_name_pairs
