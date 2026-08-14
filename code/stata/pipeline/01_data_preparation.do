/*
Project:       Victimas RD
Program:       01_data_preparation.do
Purpose:       Authoritative end-to-end data-preparation program
Current scope: Foundational, Census 2007, spatial, GDP, electoral, SISFOH, and
               Census 2017

This file is the only canonical Stata data-preparation program. New source
families will be added as clearly delimited sections here so that the master
workflow retains one push-button preparation entry point.

Current source families:
    1. INEI 2017 national centro-poblado directory
    2. RUV Libro Segundo victimization-index registry
    3. CMAN communities attended through 2023
    4. Historical and alternative CCPP directories, 2007--2025
    5. INEI 2007 CCPP-level census tabulation
    6. INEI-derived 2017 CCPP point and category shapefiles
    7. Seminario-Palomino estimated CCPP GDP, 1993--2018
    8. JNE/INFOgob and ONPE municipal elections, 2002--2007
    9. INEI SISFOH district enumeration, 2012--2013
    10. INEI 2017 Census public modules and assisted SISFOH--Census linkage

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
    ado_root

foreach global_name of local required_globals {
    local global_value "${`global_name'}"
    if `"`global_value'"' == "" {
        display as error "Required global is missing: `global_name'"
        exit 198
    }
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

foreach command in ///
    freqindex ///
    matchit ///
    strdist ///
    geodist ///
    geonear ///
    spshape2dta {
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
**# 1. Validate the frozen CMAN 2023 extracted table
*===============================================================================

local cman_pdf ///
    "${raw_root}/12 CMAN/1604763-listado-de-comunidades-atendidas-28-12-23.pdf"
local cman_csv ///
    "${staging_root}/cman_projects_2023_extracted.csv"
local cman_manifest ///
    "${qa_data_root}/cman_projects_2023_extraction_manifest.json"

/*
PDF extraction is a one-time source-ingestion task, not part of the routine
Stata replication. The shared Dropbox Working CSV and manifest are frozen
prerequisites. The Stata code below independently validates the complete 4,433
rows and all analytical fields before using them.
*/

foreach required_file in ///
    "`cman_pdf'" ///
    "`cman_csv'" ///
    "`cman_manifest'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Required CMAN source or extracted input was not found:"
        display as error "  `required_file'"
        display as error "Synchronize Dropbox Working before running the master."
        exit 601
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

foreach required_file in ///
    "`ccpp_source_root'/20161027_CodCentPobRegFormActColectivasFAC.xlsx" ///
    "`ccpp_source_root'/CCPP 2007.xlsx" ///
    "`ccpp_source_root'/4. PBI_CentrosPoblados_1993-2018.xlsx" ///
    "`ccpp_source_root'/Centros_Poblados_INEI_geogpsperu_SuyoPomalia (1)/Centros_Poblados_INEI_geogpsperu_SuyoPomalia.dbf" ///
    "${external_derived_root}/ign_centros_poblados_2025.dta" ///
    "`reporte_ccpp_csv'" ///
    "`reporte_ccpp_manifest'" {

    capture confirm file "`required_file'"
    if _rc {
        display as error "Required historical CCPP source or extracted input was not found:"
        display as error "  `required_file'"
        display as error "Synchronize Dropbox Working before running the master."
        exit 601
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
criterion despite their .xls extensions. The frozen ingestion output was
validated across all 25 departments after removing one byte-identical duplicate
download.
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

local cutoff_ab = .153750
local cutoff_bc = .062320
local cutoff_cd = .026930
local cutoff_de = .015220

generate double running_ab = victimization_index - `cutoff_ab'
generate double running_bc = victimization_index - `cutoff_bc'
generate double running_cd = victimization_index - `cutoff_cd'
generate double running_de = victimization_index - `cutoff_de'

assert abs(running_ab - (victimization_index - `cutoff_ab')) < 1e-12
assert abs(running_bc - (victimization_index - `cutoff_bc')) < 1e-12
assert abs(running_cd - (victimization_index - `cutoff_cd')) < 1e-12
assert abs(running_de - (victimization_index - `cutoff_de')) < 1e-12
assert abs(victimization_index - round(victimization_index, .0001)) < 1e-10

preserve
keep victimization_index
duplicates drop
count
assert r(N) == 2072
local victim_score_distinct_n = r(N)
restore

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
Research-team geographic-sample decision, 29 July 2026: the main RD geography
reproduces the exact legacy executable rule. It contains every RUV community
in Apurimac or Huancavelica and every RUV community in La Convencion province
of Cusco or Huancayo province of Junin. The RUV-supplied district UBIGEO makes
the rule deterministic even when a ten-digit CCPP code remains unresolved.
*/

generate byte sample_main_rd = ///
    inlist(substr(ubigeo_dist, 1, 2), "03", "09") | ///
    inlist(substr(ubigeo_dist, 1, 4), "0809", "1201")

assert sample_main_rd == ( ///
    inlist(region_norm, "APURIMAC", "HUANCAVELICA") | ///
    (region_norm == "CUSCO" & province_norm == "LA CONVENCION") | ///
    (region_norm == "JUNIN" & province_norm == "HUANCAYO"))

count if sample_main_rd
assert r(N) == 1162
local main_rd_sample_rows = r(N)

/*
The official thresholds have six decimals, but the workbook stores scores to
four. Preserve the RUV category as the authoritative assignment field. The
score-based reconstruction below distinguishes rounding artifacts from genuine
source conflicts and never overwrites a supplied value.
*/

generate str1 victim_level_from_score = "A" if ///
    victimization_index >= `cutoff_ab' & victimization_index <= 1
replace victim_level_from_score = "B" if ///
    inrange(victimization_index, `cutoff_bc', `cutoff_ab')
replace victim_level_from_score = "C" if ///
    inrange(victimization_index, `cutoff_cd', `cutoff_bc')
replace victim_level_from_score = "D" if ///
    inrange(victimization_index, `cutoff_de', `cutoff_cd')
replace victim_level_from_score = "E" if ///
    victimization_index >= .007740 & ///
    victimization_index < `cutoff_de'

generate byte victim_level_score_disagree = ///
    victimization_level_source != victim_level_from_score & ///
    !missing(victim_level_from_score)

generate byte victim_score_at_rounded_boundary = ///
    abs(victimization_index - `cutoff_ab') <= .00005 + 1e-10 | ///
    abs(victimization_index - `cutoff_bc') <= .00005 + 1e-10 | ///
    abs(victimization_index - `cutoff_cd') <= .00005 + 1e-10 | ///
    abs(victimization_index - `cutoff_de') <= .00005 + 1e-10

generate byte victim_level_rounding_disagree = ///
    victim_level_score_disagree & victim_score_at_rounded_boundary
generate byte victim_level_true_conflict = ///
    victim_level_score_disagree & !victim_score_at_rounded_boundary
generate byte victim_score_rounded_minimum = ///
    victimization_index < .007740 & ///
    abs(victimization_index - .007740) <= .00005 + 1e-10
generate byte victim_score_above_one = victimization_index > 1

count if victim_level_rounding_disagree
assert r(N) == 72
local victim_rounding_disagree_n = r(N)

count if victim_level_true_conflict
assert r(N) == 1
local victim_true_conflict_n = r(N)

count if victim_score_rounded_minimum
assert r(N) == 189
local victim_rounded_min_n = r(N)

count if victim_score_above_one
assert r(N) == 7
local victim_above_one_n = r(N)

/*
Audit the four-pillar geometric-mean structure documented by the government.
The scale is inferred from this workbook and is not an official normalizer.
The reconstruction is a QA diagnostic only.
*/

generate double audit_victims = ///
    deaths + disappearances + torture + widowed + orphaned
generate double audit_institutional = ///
    authorities_killed + authorities_disappeared + authorities_displaced
generate double audit_geometric_mean = ///
    (max(audit_victims, 1) * ///
     max(audit_institutional, 1) * ///
     max(family_assets_destroyed, 1) * ///
     max(community_assets_destroyed, 1)) ^ .25
generate double audit_score_uncapped = ///
    .01018123 * audit_geometric_mean
generate double audit_score_capped = min(1, audit_score_uncapped)
generate byte audit_formula_uncapped_match = ///
    abs(victimization_index - audit_score_uncapped) <= .00005 + 1e-10
generate byte audit_formula_match = ///
    abs(victimization_index - audit_score_capped) <= .00005 + 1e-10

count if audit_formula_uncapped_match
assert r(N) == 4857
local victim_formula_uncapped_n = r(N)

count if audit_formula_match
assert r(N) == 4925
local victim_formula_capped_n = r(N)

count if victimization_index == 1
assert r(N) == 72
local victim_score_one_n = r(N)

count if victimization_index == 1 & audit_score_uncapped > 1
assert r(N) == 71
local victim_cap_consistent_n = r(N)

preserve
keep if !audit_formula_match | ///
    victim_level_true_conflict | victim_score_above_one
keep ///
    ruv_id ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    victimization_level_source ///
    victimization_index ///
    audit_victims ///
    audit_institutional ///
    family_assets_destroyed ///
    community_assets_destroyed ///
    audit_score_uncapped ///
    audit_score_capped ///
    audit_formula_match ///
    victim_level_true_conflict ///
    victim_score_above_one
sort ruv_id
save ///
    "${qa_data_root}/victimization_index_formula_review.dta", ///
    replace
restore

drop ///
    victim_level_from_score ///
    victim_level_score_disagree ///
    victim_score_at_rounded_boundary ///
    victim_level_rounding_disagree ///
    victim_level_true_conflict ///
    victim_score_rounded_minimum ///
    victim_score_above_one ///
    audit_victims ///
    audit_institutional ///
    audit_geometric_mean ///
    audit_score_uncapped ///
    audit_score_capped ///
    audit_formula_uncapped_match ///
    audit_formula_match

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
label variable running_ab ///
    "Victimization index centered at official A-B cutoff 0.153750"
label variable running_bc ///
    "Victimization index centered at official B-C cutoff 0.062320"
label variable running_cd ///
    "Victimization index centered at official C-D cutoff 0.026930"
label variable running_de ///
    "Victimization index centered at official D-E cutoff 0.015220"
label variable victimization_level_source ///
    "Victimization category supplied by RUV"
label variable sample_main_rd ///
    "Selected legacy geographic sample for main RD analysis"
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

/*
Classify every CMAN project from its normalized Spanish title. The dictionaries
encode the categories used in the working paper, with clearer labels for the
combined rare category. Because some titles mention more than one sector, the
order below is the documented primary-project hierarchy. Record 1120 explicitly
combines potable water with sprinkler irrigation; review of the full title
assigns irrigation as its primary type while retaining its multisector flag.
*/

generate strL prc_project_text_norm = ///
    ustrlower(ustrtrim(project_raw))
replace prc_project_text_norm = ustrregexra( ///
    ustrnormalize(prc_project_text_norm, "nfd"), "\p{M}", "")
replace prc_project_text_norm = ustrregexra( ///
    prc_project_text_norm, "[^a-z0-9]+", " ")
replace prc_project_text_norm = ///
    ustrtrim(itrim(prc_project_text_norm))

generate byte prc_theme_fishing = ustrregexm( ///
    prc_project_text_norm, ///
    "pisci|trucha|tilapia|alevin|acuic|pesca|crianza de peces|produccion de peces")

generate byte prc_theme_livestock = ustrregexm( ///
    prc_project_text_norm, ///
    "ganad|vacun|bovin|(^| )ovin[oa]s?( |$)|alpaca|llama|caprin|porcin|cuy|avic|gallina|pollo|establo|corral|pastos|forraje|lechero|produccion de leche|queso|inseminacion|crianza|cobertiz|lechera|vaquer|galpon|vaquill|vicu|pradera|pecuari|animal|queser|lacteo|banadero|(^| )leche( |$)") & ///
    !prc_theme_fishing

generate byte prc_theme_irrigation = ustrregexm( ///
    prc_project_text_norm, ///
    "riego|irrig|regadio|reservorio|represa|bocatoma|aspersion|canal de riego|canal de irrigacion|(^| )canal(es)?( |$)|canal entubado|revestimiento del canal|presa de tierra|cosecha de agua") & ///
    !ustrregexm( ///
        prc_project_text_norm, ///
        "agua potable|saneamiento|alcantarillado|desague")

generate byte prc_theme_community = ustrregexm( ///
    prc_project_text_norm, ///
    "local comunal|casa comunal|salon comunal|centro comunal|local multiuso|local de uso|usos multiples|multiuso|multifuncional|infraestructura comunal|servicios comunales|equipamiento comunal|comedor|centro civico|plaza|parque|losa deportiva|campo deportivo|complejo deportivo|coliseo|cementerio|iglesia|templo|capilla|auditorium|auditorio|casa de la paz|infraestructura de la comunidad|servicio comunitario|coordinacion comunal|anfiteatro|losa multideportiva|casa de la cultura|casa de la juventud|servicio de esparcimiento|local del adulto mayor|desarrollo comunal|servicios institucionales|servicio administrativo y operativo|sistemas comunales multiples|uso multiple|servicios multiples|servicio recreativo|uro comunal|instalaciones exteriores de servicios basicos")

generate byte prc_theme_agriculture = ustrregexm( ///
    prc_project_text_norm, ///
    "agric|agropec|cultiv|semilla|quinua|papa |cacao|cafe |cafetal|frut|hortal|invernadero|vivero|biohuerto|fitotoldo|maiz|arroz|trigo|cebada|habas|palto|granadilla|citric|plantones|chacra|forestal|sementera|forestacion|especies maderables|seguridad alimentaria|agroproduct|cereal|grano|menestra|(^| )tuna( |$)|durazno|azucar|agroindustrial|centro de acopio")

generate byte prc_theme_education = ustrregexm( ///
    prc_project_text_norm, ///
    "educa|escuela|colegio|aula|pronoei|biblioteca|institucion educativa|centro educativo|escolar|pedagog|(^| )cei( |$)|(^| )ie(p)?( |$)|(^| )i e( |$)|cetpro")

generate byte prc_theme_water = ustrregexm( ///
    prc_project_text_norm, ///
    "agua potable|abastecimiento de agua|servicio de agua|sistema de agua|captacion de agua|red de agua|agua segura") & ///
    !ustrregexm(prc_project_text_norm, "riego|irrig")

generate byte prc_theme_management = ustrregexm( ///
    prc_project_text_norm, ///
    "fortalecimiento|capacidades|gestion|asistencia tecnica|capacitacion|equipamiento institucional|implementacion comunal|desarrollo productivo|cadena productiva|apoyo productivo|formacion de recursos humanos|infraestructura productiva")

generate byte prc_theme_roads = ustrregexm( ///
    prc_project_text_norm, ///
    "camino|carretera|trocha|puente|transitabilidad|vial|pista|vereda|pont.n|alcantarilla|acceso vial|vias |calle|paviment|escalinata|(^| )via( |$)|acceso peatonal|empedrado|afirmado|zona urbana")

generate byte prc_theme_health = ustrregexm( ///
    prc_project_text_norm, ///
    "salud|posta|botiquin|ambulancia|centro medico|casa materna|materno|perinatal|gestante|madre y el nino|madre y nino|estimulacion temprana|promocion y vigilancia comunal")

generate byte prc_theme_sanitation = ustrregexm( ///
    prc_project_text_norm, ///
    "saneamiento|alcantarillado|desague|letrina|servicios higienicos|bano|residuos solidos|relleno sanitario|pozo de oxidacion|letrinizacion|servicio higien|duchas|lavaderos|tratamiento de excretas|unidades basicas sanitarias")

generate byte prc_theme_energy = ustrregexm( ///
    prc_project_text_norm, ///
    "electr|energia|alumbrado|panel solar|fotovolta|red electrica|sistema electrico|luz electrica|paneles solares|red primaria|red secundaria|acometidas domiciliarias|cocinas mejoradas")

generate byte prc_theme_commerce = ustrregexm( ///
    prc_project_text_norm, ///
    "comerc|mercado|feria|tienda|panaderia|centro de acopio|transformacion|procesamiento|planta procesadora|procesadora|molino|acopio|mercadillo|centro de abastos|expendio de alimentos")

generate byte prc_theme_culture = ustrregexm( ///
    prc_project_text_norm, ///
    "turis|artesan|textil|tejido|patrimonio|cultural|museo|prevencion|defensa ribere|defensa civil|seguridad ciudadana|muro de contencion|casa de la cultura|casa de la juventud|defensa river|condiciones ambientales")

/*
The source title for record 1120 names both potable water and sprinkler
irrigation. Mark both themes before selecting irrigation as the reviewed
primary category.
*/

replace prc_theme_water = 1 if record_number == 1120
replace prc_theme_irrigation = 1 if record_number == 1120

egen byte prc_project_theme_count = rowtotal( ///
    prc_theme_fishing ///
    prc_theme_livestock ///
    prc_theme_irrigation ///
    prc_theme_community ///
    prc_theme_agriculture ///
    prc_theme_education ///
    prc_theme_water ///
    prc_theme_management ///
    prc_theme_roads ///
    prc_theme_health ///
    prc_theme_sanitation ///
    prc_theme_energy ///
    prc_theme_commerce ///
    prc_theme_culture)

assert prc_project_theme_count >= 1
generate byte prc_project_multisector = ///
    prc_project_theme_count > 1

capture label drop prc_project_type_label
label define prc_project_type_label ///
    1  "Livestock" ///
    2  "Irrigation" ///
    3  "Community facilities" ///
    4  "Agriculture" ///
    5  "Education" ///
    6  "Water supply" ///
    7  "Management and other support" ///
    8  "Road infrastructure" ///
    9  "Health" ///
    10 "Fishing and aquaculture" ///
    11 "Sanitation" ///
    12 "Energy" ///
    13 "Commerce and processing" ///
    14 "Tourism, culture, and prevention"

generate byte prc_project_type = .
replace prc_project_type = 10 if prc_theme_fishing
replace prc_project_type = 6 if ///
    missing(prc_project_type) & prc_theme_water
replace prc_project_type = 11 if ///
    missing(prc_project_type) & prc_theme_sanitation
replace prc_project_type = 2 if ///
    missing(prc_project_type) & prc_theme_irrigation
replace prc_project_type = 9 if ///
    missing(prc_project_type) & prc_theme_health
replace prc_project_type = 5 if ///
    missing(prc_project_type) & prc_theme_education
replace prc_project_type = 12 if ///
    missing(prc_project_type) & prc_theme_energy
replace prc_project_type = 8 if ///
    missing(prc_project_type) & prc_theme_roads
replace prc_project_type = 1 if ///
    missing(prc_project_type) & prc_theme_livestock
replace prc_project_type = 4 if ///
    missing(prc_project_type) & prc_theme_agriculture
replace prc_project_type = 13 if ///
    missing(prc_project_type) & prc_theme_commerce
replace prc_project_type = 14 if ///
    missing(prc_project_type) & prc_theme_culture
replace prc_project_type = 3 if ///
    missing(prc_project_type) & prc_theme_community
replace prc_project_type = 7 if ///
    missing(prc_project_type) & prc_theme_management
replace prc_project_type = 2 if record_number == 1120

assert !missing(prc_project_type)
label values prc_project_type prc_project_type_label

capture label drop prc_project_group_label
label define prc_project_group_label ///
    1 "Productive and livelihood" ///
    2 "Social and basic services" ///
    3 "Community and civic infrastructure" ///
    4 "Management and capacity support"

generate byte prc_project_group = .
replace prc_project_group = 1 if ///
    inlist(prc_project_type, 1, 2, 4, 10, 13)
replace prc_project_group = 2 if ///
    inlist(prc_project_type, 5, 6, 9, 11, 12)
replace prc_project_group = 3 if ///
    inlist(prc_project_type, 3, 8, 14)
replace prc_project_group = 4 if ///
    prc_project_type == 7
assert !missing(prc_project_group)
label values prc_project_group prc_project_group_label

capture label drop prc_project_class_method_label
label define prc_project_class_method_label ///
    1 "Dictionary and priority hierarchy" ///
    2 "Reviewed record-specific override"

generate byte prc_project_class_method = 1
replace prc_project_class_method = 2 if ///
    record_number == 1120
label values ///
    prc_project_class_method ///
    prc_project_class_method_label

generate byte prc_cofinanced = cofinancing_soles > 0
generate double prc_total_financing_soles = ///
    cman_financing_soles + cofinancing_soles
generate double prc_cofinancing_share = ///
    cofinancing_soles / prc_total_financing_soles
generate double prc_cofinancing_ratio = ///
    cofinancing_soles / cman_financing_soles

assert inlist(prc_cofinanced, 0, 1)
assert prc_total_financing_soles > 0
assert inrange(prc_cofinancing_share, 0, 1)
assert prc_cofinancing_ratio >= 0

count if prc_project_multisector
local cman_multisector_projects = r(N)

count if prc_project_class_method == 2
assert r(N) == 1
local cman_project_manual_overrides = r(N)

count if prc_cofinanced
local cman_cofinanced_projects = r(N)

/*
Keep the row-level classification evidence in Dropbox Working QA. Only the
substantive classification, provenance, and financing measures continue into
the canonical project registry.
*/

preserve
keep ///
    record_number ///
    recorded_project_year ///
    region_raw ///
    province_raw ///
    district_raw ///
    community_raw ///
    project_raw ///
    prc_project_text_norm ///
    prc_theme_* ///
    prc_project_theme_count ///
    prc_project_multisector ///
    prc_project_type ///
    prc_project_group ///
    prc_project_class_method ///
    cman_financing_soles ///
    cofinancing_soles ///
    prc_cofinanced ///
    prc_total_financing_soles ///
    prc_cofinancing_share ///
    prc_cofinancing_ratio
sort record_number
save ///
    "${qa_data_root}/cman_project_classification_review.dta", ///
    replace
export delimited ///
    "${qa_data_root}/cman_project_classification_review.csv", ///
    replace
restore

drop ///
    prc_project_text_norm ///
    prc_theme_* ///
    prc_project_theme_count

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
label variable prc_project_type ///
    "Primary CMAN project type classified from project title"
label variable prc_project_group ///
    "Broad CMAN project group classified from project title"
label variable prc_project_multisector ///
    "Project title contains more than one sector theme"
label variable prc_project_class_method ///
    "Method used to assign primary CMAN project type"
label variable prc_cofinanced ///
    "Positive cofinancing recorded in CMAN register"
label variable prc_total_financing_soles ///
    "CMAN financing plus cofinancing; nominal soles"
label variable prc_cofinancing_share ///
    "Cofinancing share of total recorded project financing"
label variable prc_cofinancing_ratio ///
    "Recorded cofinancing divided by CMAN financing"
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
    prc_project_type ///
    prc_project_group ///
    prc_project_multisector ///
    prc_project_class_method ///
    prc_cofinanced ///
    prc_total_financing_soles ///
    prc_cofinancing_share ///
    prc_cofinancing_ratio ///
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
    running_ab ///
    running_bc ///
    running_cd ///
    running_de ///
    sample_main_rd ///
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
    prc_project_type ///
    prc_project_group ///
    prc_project_multisector ///
    prc_project_class_method ///
    prc_cofinanced ///
    prc_total_financing_soles ///
    prc_cofinancing_share ///
    prc_cofinancing_ratio ///
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
    running_ab ///
    running_bc ///
    running_cd ///
    running_de ///
    sample_main_rd ///
    prc_project_observed ///
    prc_project_link_status ///
    cman_project_count ///
    recorded_project_year ///
    prc_project_type ///
    prc_project_group ///
    prc_project_multisector ///
    prc_cofinanced ///
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
assert inlist(sample_main_rd, 0, 1)
count if sample_main_rd
assert r(N) == `main_rd_sample_rows'

egen byte missing_treatment_indicator = rowmiss(treat_07-treat_23)
assert missing_treatment_indicator == 0
drop missing_treatment_indicator

save ///
    "${analysis_data_root}/04_foundational_community_registry.dta", ///
    replace


*===============================================================================
**# 8. Prepare and integrate 2007 census baseline covariates
*===============================================================================

local census2007_source ///
    "${raw_root}/9 INEI/CCPP 2007.xlsx"

capture confirm file "`census2007_source'"
if _rc {
    display as error "Required 2007 census workbook was not found:"
    display as error "  `census2007_source'"
    exit 601
}

/*
The workbook is a CCPP-level aggregate tabulation, not person-level
microdata. Hoja1 contains two header rows, 45,677 keyed records, and two
trailing source-note rows. Hoja2 contains keyless derivatives and is not used.
The source covers 22 departments and is not the complete 98,011-record 2007
national CCPP directory. Its acquisition provenance remains unresolved, so
all source-scope facts are recorded explicitly in versioned documentation.
*/

import excel ///
    "`census2007_source'", ///
    sheet("Hoja1") allstring clear

assert c(k) == 259
count
assert r(N) == 45681

keep if ustrregexm(B, "^[0-9]{10}$")
count
assert r(N) == 45677
local census2007_source_rows = r(N)

keep ///
    B C D E F G ///
    H I J ///
    AL AM AN AO AP AQ AR AS AT ///
    AU AV AW AX AY AZ BA BB ///
    BC BD BE BF BG BH BI BJ BK ///
    BL BM BN ///
    BO BP BQ BR BS BT BU ///
    BV BW BX BY ///
    BZ CA CB CC CD CE CF ///
    CG CH CI CJ CK CL CM CN CO CP CQ CR ///
    CS CT CU CV CW CX CY CZ DA ///
    DC DD DE DF DG DH ///
    DU DV DW ///
    DX DY DZ EA EB EC ED ///
    EE EF EG EH ///
    EL EM EN EO ///
    EP EQ ER ///
    ES ET EU EV ///
    EW EX EY EZ FA FB FC FD ///
    FE FF FG ///
    FH FI FJ FK FL FM FN FO FP ///
    FY FZ GA ///
    HH HI HJ HK HL HM HN HO HP HQ HR HS ///
    IQ IR IS IT ///
    IU IV ///
    IW IX IY

rename ///
    (B C D E F G) ///
    (census2007_ubigeo_ccpp ///
     department_2007 ///
     province_2007 ///
     district_2007 ///
     ccpp_name_2007 ///
     area_2007_raw)

rename ///
    (H I J BY) ///
    (dwellings_occupied_2007 ///
     households_2007 ///
     population_2007 ///
     rooms_per_dwelling_2007)

rename ///
    (AL AM AN AO AP AQ AR AS AT) ///
    (wall_brick_n_2007 ///
     wall_adobe_n_2007 ///
     wall_wood_n_2007 ///
     wall_quincha_n_2007 ///
     wall_mat_n_2007 ///
     wall_stone_mud_n_2007 ///
     wall_stone_cement_n_2007 ///
     wall_other_n_2007 ///
     wall_total_n_2007)

rename ///
    (AU AV AW AX AY AZ BA BB) ///
    (floor_earth_n_2007 ///
     floor_cement_n_2007 ///
     floor_tile_n_2007 ///
     floor_parquet_n_2007 ///
     floor_wood_n_2007 ///
     floor_asphalt_n_2007 ///
     floor_other_n_2007 ///
     floor_total_n_2007)

rename ///
    (BC BD BE BF BG BH BI BJ BK) ///
    (water_inside_n_2007 ///
     water_outside_n_2007 ///
     water_pylon_n_2007 ///
     water_truck_n_2007 ///
     water_well_n_2007 ///
     water_river_n_2007 ///
     water_neighbor_n_2007 ///
     water_other_n_2007 ///
     water_total_n_2007)

rename ///
    (BL BM BN) ///
    (daily_water_yes_n_2007 ///
     daily_water_no_n_2007 ///
     daily_water_total_n_2007)

rename ///
    (BO BP BQ BR BS BT BU) ///
    (sanitation_inside_n_2007 ///
     sanitation_outside_n_2007 ///
     sanitation_septic_n_2007 ///
     sanitation_latrine_n_2007 ///
     sanitation_river_n_2007 ///
     sanitation_none_n_2007 ///
     sanitation_total_n_2007)

rename ///
    (BV BW BX) ///
    (electricity_yes_n_2007 ///
     electricity_no_n_2007 ///
     electricity_total_n_2007)

rename ///
    (BZ CA CB CC CD CE CF) ///
    (tenure_rented_n_2007 ///
     tenure_invasion_n_2007 ///
     tenure_installment_n_2007 ///
     tenure_owned_n_2007 ///
     tenure_employer_n_2007 ///
     tenure_other_n_2007 ///
     tenure_total_n_2007)

rename ///
    (CG CH CI CJ CK CL CM CN CO CP CQ CR) ///
    (asset_radio_n_2007 ///
     asset_tv_n_2007 ///
     asset_stereo_n_2007 ///
     asset_washer_n_2007 ///
     asset_fridge_n_2007 ///
     asset_computer_n_2007 ///
     asset_basic_none_n_2007 ///
     asset_landline_n_2007 ///
     asset_mobile_n_2007 ///
     asset_internet_n_2007 ///
     asset_cable_n_2007 ///
     asset_comms_none_n_2007)

rename ///
    (CS CT CU CV CW CX CY CZ DA) ///
    (fuel_electricity_n_2007 ///
     fuel_gas_n_2007 ///
     fuel_kerosene_n_2007 ///
     fuel_coal_n_2007 ///
     fuel_wood_n_2007 ///
     fuel_dung_n_2007 ///
     fuel_other_n_2007 ///
     fuel_no_cooking_n_2007 ///
     fuel_total_n_2007)

rename ///
    (DC DD DE DF DG DH) ///
    (disability_vision_n_2007 ///
     disability_hearing_n_2007 ///
     disability_speech_n_2007 ///
     disability_mobility_n_2007 ///
     disability_other_n_2007 ///
     disability_none_n_2007)

rename ///
    (DU DV DW) ///
    (male_n_2007 female_n_2007 sex_total_n_2007)

rename ///
    (DX DY DZ EA EB EC ED) ///
    (age_u1_n_2007 ///
     age_1_14_n_2007 ///
     age_15_29_n_2007 ///
     age_30_44_n_2007 ///
     age_45_64_n_2007 ///
     age_65plus_n_2007 ///
     age_total_n_2007)

rename ///
    (EE EF EG EH) ///
    (birth_registered_n_2007 ///
     birth_unregistered_n_2007 ///
     birth_reg_unknown_n_2007 ///
     birth_registration_total_n_2007)

rename ///
    (EL EM EN EO) ///
    (not_born_five_years_ago_n_2007 ///
     same_district_five_years_n_2007 ///
     other_district_five_years_n_2007 ///
     five_year_residence_total_n_2007)

rename ///
    (EP EQ ER) ///
    (born_same_district_n_2007 ///
     born_other_district_n_2007 ///
     birth_district_total_n_2007)

rename ///
    (ES ET EU EV) ///
    (insurance_sis_n_2007 ///
     insurance_essalud_n_2007 ///
     insurance_other_n_2007 ///
     insurance_none_n_2007)

rename ///
    (EW EX EY EZ FA FB FC FD) ///
    (language_quechua_n_2007 ///
     language_aymara_n_2007 ///
     language_ashaninka_n_2007 ///
     language_other_native_n_2007 ///
     language_spanish_n_2007 ///
     language_foreign_n_2007 ///
     language_speech_limit_n_2007 ///
     language_total_n_2007)

rename ///
    (FE FF FG) ///
    (literate_n_2007 ///
     illiterate_n_2007 ///
     literacy_total_n_2007)

rename ///
    (FH FI FJ FK FL FM FN FO FP) ///
    (education_none_n_2007 ///
     education_initial_n_2007 ///
     education_primary_n_2007 ///
     education_secondary_n_2007 ///
     education_technical_inc_n_2007 ///
     education_technical_com_n_2007 ///
     education_university_inc_n_2007 ///
     education_university_com_n_2007 ///
     education_total_n_2007)

rename ///
    (FY FZ GA) ///
    (attendance_yes_n_2007 ///
     attendance_no_n_2007 ///
     attendance_total_n_2007)

rename ///
    (HH HI HJ HK HL HM HN HO HP HQ HR HS) ///
    (sector_agriculture_n_2007 ///
     sector_fishing_n_2007 ///
     sector_mining_n_2007 ///
     sector_manufacturing_n_2007 ///
     sector_construction_n_2007 ///
     sector_utilities_n_2007 ///
     sector_trade_n_2007 ///
     sector_services_n_2007 ///
     sector_finance_n_2007 ///
     sector_transport_n_2007 ///
     sector_unspecified_n_2007 ///
     sector_total_n_2007)

rename ///
    (IQ IR IS IT) ///
    (children_born_avg_2007 ///
     children_alive_avg_2007 ///
     mothers_n_2007 ///
     age_first_birth_avg_2007)

rename ///
    (IU IV) ///
    (dni_yes_n_2007 dni_no_n_2007)

rename ///
    (IW IX IY) ///
    (employed_n_2007 ///
     unemployed_n_2007 ///
     outside_labor_force_n_2007)

recast str10 census2007_ubigeo_ccpp
generate str6 census2007_ubigeo_dist = ///
    substr(census2007_ubigeo_ccpp, 1, 6)
generate str4 census2007_ubigeo_prov = ///
    substr(census2007_ubigeo_ccpp, 1, 4)
generate str2 census2007_ubigeo_dpto = ///
    substr(census2007_ubigeo_ccpp, 1, 2)

assert ustrregexm(census2007_ubigeo_ccpp, "^[0-9]{10}$")
isid census2007_ubigeo_ccpp

local census2007_numeric ///
    dwellings_occupied_2007 ///
    households_2007 ///
    population_2007 ///
    rooms_per_dwelling_2007 ///
    wall_*_n_2007 ///
    floor_*_n_2007 ///
    water_*_n_2007 ///
    daily_water_*_n_2007 ///
    sanitation_*_n_2007 ///
    electricity_*_n_2007 ///
    tenure_*_n_2007 ///
    asset_*_n_2007 ///
    fuel_*_n_2007 ///
    disability_*_n_2007 ///
    male_n_2007 ///
    female_n_2007 ///
    sex_total_n_2007 ///
    age_*_n_2007 ///
    birth_*_n_2007 ///
    born_same_district_n_2007 ///
    born_other_district_n_2007 ///
    not_born_five_years_ago_n_2007 ///
    same_district_five_years_n_2007 ///
    other_district_five_years_n_2007 ///
    five_year_residence_total_n_2007 ///
    birth_district_total_n_2007 ///
    insurance_*_n_2007 ///
    language_*_n_2007 ///
    literate_n_2007 ///
    illiterate_n_2007 ///
    literacy_total_n_2007 ///
    education_*_n_2007 ///
    attendance_*_n_2007 ///
    sector_*_n_2007 ///
    children_born_avg_2007 ///
    children_alive_avg_2007 ///
    mothers_n_2007 ///
    age_first_birth_avg_2007 ///
    dni_*_n_2007 ///
    employed_n_2007 ///
    unemployed_n_2007 ///
    outside_labor_force_n_2007

foreach variable of varlist `census2007_numeric' {
    destring `variable', replace
    assert `variable' >= 0 if !missing(`variable')
}

/*
Validate every mutually exclusive source block used below. The source totals
identify the correct analytical universe, preventing the legacy error of
dividing categories by undocumented columns or by total population.
*/

egen double census2007_check = rowtotal( ///
    wall_brick_n_2007 ///
    wall_adobe_n_2007 ///
    wall_wood_n_2007 ///
    wall_quincha_n_2007 ///
    wall_mat_n_2007 ///
    wall_stone_mud_n_2007 ///
    wall_stone_cement_n_2007 ///
    wall_other_n_2007)
assert census2007_check == wall_total_n_2007
drop census2007_check

egen double census2007_check = rowtotal( ///
    floor_earth_n_2007 ///
    floor_cement_n_2007 ///
    floor_tile_n_2007 ///
    floor_parquet_n_2007 ///
    floor_wood_n_2007 ///
    floor_asphalt_n_2007 ///
    floor_other_n_2007)
assert census2007_check == floor_total_n_2007
drop census2007_check

egen double census2007_check = rowtotal( ///
    water_inside_n_2007 ///
    water_outside_n_2007 ///
    water_pylon_n_2007 ///
    water_truck_n_2007 ///
    water_well_n_2007 ///
    water_river_n_2007 ///
    water_neighbor_n_2007 ///
    water_other_n_2007)
assert census2007_check == water_total_n_2007
drop census2007_check

assert daily_water_yes_n_2007 + ///
    daily_water_no_n_2007 == daily_water_total_n_2007
assert daily_water_total_n_2007 == ///
    water_inside_n_2007 + ///
    water_outside_n_2007 + ///
    water_pylon_n_2007

egen double census2007_check = rowtotal( ///
    sanitation_inside_n_2007 ///
    sanitation_outside_n_2007 ///
    sanitation_septic_n_2007 ///
    sanitation_latrine_n_2007 ///
    sanitation_river_n_2007 ///
    sanitation_none_n_2007)
assert census2007_check == sanitation_total_n_2007
drop census2007_check

assert electricity_yes_n_2007 + ///
    electricity_no_n_2007 == electricity_total_n_2007

egen double census2007_check = rowtotal( ///
    tenure_rented_n_2007 ///
    tenure_invasion_n_2007 ///
    tenure_installment_n_2007 ///
    tenure_owned_n_2007 ///
    tenure_employer_n_2007 ///
    tenure_other_n_2007)
assert census2007_check == tenure_total_n_2007
drop census2007_check

egen double census2007_check = rowtotal( ///
    fuel_electricity_n_2007 ///
    fuel_gas_n_2007 ///
    fuel_kerosene_n_2007 ///
    fuel_coal_n_2007 ///
    fuel_wood_n_2007 ///
    fuel_dung_n_2007 ///
    fuel_other_n_2007 ///
    fuel_no_cooking_n_2007)
assert census2007_check == fuel_total_n_2007
drop census2007_check

assert male_n_2007 + female_n_2007 == sex_total_n_2007

egen double census2007_check = rowtotal( ///
    age_u1_n_2007 ///
    age_1_14_n_2007 ///
    age_15_29_n_2007 ///
    age_30_44_n_2007 ///
    age_45_64_n_2007 ///
    age_65plus_n_2007)
assert census2007_check == age_total_n_2007
drop census2007_check

egen double census2007_check = rowtotal( ///
    birth_registered_n_2007 ///
    birth_unregistered_n_2007 ///
    birth_reg_unknown_n_2007)
assert census2007_check == birth_registration_total_n_2007
drop census2007_check

egen double census2007_check = rowtotal( ///
    not_born_five_years_ago_n_2007 ///
    same_district_five_years_n_2007 ///
    other_district_five_years_n_2007)
assert census2007_check == five_year_residence_total_n_2007
drop census2007_check

assert born_same_district_n_2007 + ///
    born_other_district_n_2007 == birth_district_total_n_2007

egen double census2007_check = rowtotal( ///
    language_quechua_n_2007 ///
    language_aymara_n_2007 ///
    language_ashaninka_n_2007 ///
    language_other_native_n_2007 ///
    language_spanish_n_2007 ///
    language_foreign_n_2007 ///
    language_speech_limit_n_2007)
assert census2007_check == language_total_n_2007
drop census2007_check

assert literate_n_2007 + ///
    illiterate_n_2007 == literacy_total_n_2007

egen double census2007_check = rowtotal( ///
    education_none_n_2007 ///
    education_initial_n_2007 ///
    education_primary_n_2007 ///
    education_secondary_n_2007 ///
    education_technical_inc_n_2007 ///
    education_technical_com_n_2007 ///
    education_university_inc_n_2007 ///
    education_university_com_n_2007)
assert census2007_check == education_total_n_2007
drop census2007_check

assert attendance_yes_n_2007 + ///
    attendance_no_n_2007 == attendance_total_n_2007

egen double census2007_check = rowtotal( ///
    sector_agriculture_n_2007 ///
    sector_fishing_n_2007 ///
    sector_mining_n_2007 ///
    sector_manufacturing_n_2007 ///
    sector_construction_n_2007 ///
    sector_utilities_n_2007 ///
    sector_trade_n_2007 ///
    sector_services_n_2007 ///
    sector_finance_n_2007 ///
    sector_transport_n_2007 ///
    sector_unspecified_n_2007)
assert census2007_check == sector_total_n_2007
drop census2007_check

assert employed_n_2007 + ///
    unemployed_n_2007 + ///
    outside_labor_force_n_2007 == education_total_n_2007

assert dwellings_occupied_2007 == wall_total_n_2007
assert dwellings_occupied_2007 == floor_total_n_2007
assert dwellings_occupied_2007 == water_total_n_2007
assert dwellings_occupied_2007 == sanitation_total_n_2007
assert dwellings_occupied_2007 == electricity_total_n_2007
assert dwellings_occupied_2007 == tenure_total_n_2007
assert households_2007 == fuel_total_n_2007
assert population_2007 == sex_total_n_2007
assert population_2007 == age_total_n_2007
assert population_2007 == birth_registration_total_n_2007
assert population_2007 == five_year_residence_total_n_2007
assert language_total_n_2007 == attendance_total_n_2007
assert literacy_total_n_2007 == education_total_n_2007

levelsof census2007_ubigeo_dpto, local(census2007_departments)
local census2007_department_count : word count `census2007_departments'
assert `census2007_department_count' == 22

assert inlist(area_2007_raw, "Urbano", "Rural")
generate byte urban_2007 = area_2007_raw == "Urbano"

generate double ln_population_2007 = ln(population_2007)
generate double ln_households_2007 = ln(households_2007) if ///
    households_2007 > 0

local wall_counts ///
    wall_brick_n_2007 ///
    wall_adobe_n_2007 ///
    wall_wood_n_2007 ///
    wall_quincha_n_2007 ///
    wall_mat_n_2007 ///
    wall_stone_mud_n_2007 ///
    wall_stone_cement_n_2007 ///
    wall_other_n_2007

local wall_shares ///
    share_wall_brick_2007 ///
    share_wall_adobe_2007 ///
    share_wall_wood_2007 ///
    share_wall_quincha_2007 ///
    share_wall_mat_2007 ///
    share_wall_stone_mud_2007 ///
    share_wall_stone_cement_2007 ///
    share_wall_other_2007

forvalues index = 1/8 {
    local numerator : word `index' of `wall_counts'
    local share : word `index' of `wall_shares'
    generate double `share' = ///
        `numerator' / wall_total_n_2007 if ///
        wall_total_n_2007 > 0
}

local floor_counts ///
    floor_earth_n_2007 ///
    floor_cement_n_2007 ///
    floor_tile_n_2007 ///
    floor_parquet_n_2007 ///
    floor_wood_n_2007 ///
    floor_asphalt_n_2007 ///
    floor_other_n_2007

local floor_shares ///
    share_floor_earth_2007 ///
    share_floor_cement_2007 ///
    share_floor_tile_2007 ///
    share_floor_parquet_2007 ///
    share_floor_wood_2007 ///
    share_floor_asphalt_2007 ///
    share_floor_other_2007

forvalues index = 1/7 {
    local numerator : word `index' of `floor_counts'
    local share : word `index' of `floor_shares'
    generate double `share' = ///
        `numerator' / floor_total_n_2007 if ///
        floor_total_n_2007 > 0
}

generate double share_water_inside_2007 = ///
    water_inside_n_2007 / water_total_n_2007 if ///
    water_total_n_2007 > 0
generate double share_water_public_2007 = ///
    (water_inside_n_2007 + ///
     water_outside_n_2007 + ///
     water_pylon_n_2007) / water_total_n_2007 if ///
    water_total_n_2007 > 0
generate double share_water_well_2007 = ///
    water_well_n_2007 / water_total_n_2007 if ///
    water_total_n_2007 > 0
generate double share_water_river_2007 = ///
    water_river_n_2007 / water_total_n_2007 if ///
    water_total_n_2007 > 0
generate double share_water_daily_2007 = ///
    daily_water_yes_n_2007 / daily_water_total_n_2007 if ///
    daily_water_total_n_2007 > 0
generate double share_water_pubdaily_2007 = ///
    daily_water_yes_n_2007 / water_total_n_2007 if ///
    water_total_n_2007 > 0

generate double share_sanitation_sewer_2007 = ///
    (sanitation_inside_n_2007 + ///
     sanitation_outside_n_2007) / sanitation_total_n_2007 if ///
    sanitation_total_n_2007 > 0
generate double share_sanitation_septic_2007 = ///
    sanitation_septic_n_2007 / sanitation_total_n_2007 if ///
    sanitation_total_n_2007 > 0
generate double share_sanitation_latrine_2007 = ///
    sanitation_latrine_n_2007 / sanitation_total_n_2007 if ///
    sanitation_total_n_2007 > 0
generate double share_sanitation_none_2007 = ///
    sanitation_none_n_2007 / sanitation_total_n_2007 if ///
    sanitation_total_n_2007 > 0
generate double share_sanitation_facility_2007 = ///
    (sanitation_inside_n_2007 + ///
     sanitation_outside_n_2007 + ///
     sanitation_septic_n_2007 + ///
     sanitation_latrine_n_2007) / sanitation_total_n_2007 if ///
    sanitation_total_n_2007 > 0
generate double share_electricity_2007 = ///
    electricity_yes_n_2007 / electricity_total_n_2007 if ///
    electricity_total_n_2007 > 0

generate double share_tenure_rented_2007 = ///
    tenure_rented_n_2007 / tenure_total_n_2007 if ///
    tenure_total_n_2007 > 0
generate double share_tenure_owned_2007 = ///
    (tenure_invasion_n_2007 + ///
     tenure_installment_n_2007 + ///
     tenure_owned_n_2007) / tenure_total_n_2007 if ///
    tenure_total_n_2007 > 0

local asset_counts ///
    asset_radio_n_2007 ///
    asset_tv_n_2007 ///
    asset_washer_n_2007 ///
    asset_fridge_n_2007 ///
    asset_computer_n_2007 ///
    asset_basic_none_n_2007 ///
    asset_landline_n_2007 ///
    asset_mobile_n_2007 ///
    asset_internet_n_2007 ///
    asset_cable_n_2007 ///
    asset_comms_none_n_2007

local asset_shares ///
    share_asset_radio_2007 ///
    share_asset_tv_2007 ///
    share_asset_washer_2007 ///
    share_asset_fridge_2007 ///
    share_asset_computer_2007 ///
    share_asset_basic_none_2007 ///
    share_asset_landline_2007 ///
    share_asset_mobile_2007 ///
    share_asset_internet_2007 ///
    share_asset_cable_2007 ///
    share_asset_comms_none_2007

forvalues index = 1/11 {
    local numerator : word `index' of `asset_counts'
    local share : word `index' of `asset_shares'
    generate double `share' = ///
        `numerator' / households_2007 if ///
        households_2007 > 0
}

generate double share_clean_cooking_2007 = ///
    (fuel_electricity_n_2007 + ///
     fuel_gas_n_2007) / fuel_total_n_2007 if ///
    fuel_total_n_2007 > 0
generate double share_fuel_wood_2007 = ///
    fuel_wood_n_2007 / fuel_total_n_2007 if ///
    fuel_total_n_2007 > 0
generate double share_fuel_dung_2007 = ///
    fuel_dung_n_2007 / fuel_total_n_2007 if ///
    fuel_total_n_2007 > 0

generate double share_female_2007 = ///
    female_n_2007 / sex_total_n_2007 if ///
    sex_total_n_2007 > 0
generate double share_age_0_14_2007 = ///
    (age_u1_n_2007 + age_1_14_n_2007) / age_total_n_2007 if ///
    age_total_n_2007 > 0
generate double share_age_15_29_2007 = ///
    age_15_29_n_2007 / age_total_n_2007 if ///
    age_total_n_2007 > 0
generate double share_age_30_44_2007 = ///
    age_30_44_n_2007 / age_total_n_2007 if ///
    age_total_n_2007 > 0
generate double share_age_45_64_2007 = ///
    age_45_64_n_2007 / age_total_n_2007 if ///
    age_total_n_2007 > 0
generate double share_age_65plus_2007 = ///
    age_65plus_n_2007 / age_total_n_2007 if ///
    age_total_n_2007 > 0
generate double share_any_disability_2007 = ///
    1 - disability_none_n_2007 / population_2007 if ///
    population_2007 > 0
generate double share_birth_registered_2007 = ///
    birth_registered_n_2007 / birth_registration_total_n_2007 if ///
    birth_registration_total_n_2007 > 0
generate double share_moved_five_years_2007 = ///
    other_district_five_years_n_2007 / ///
    (same_district_five_years_n_2007 + ///
     other_district_five_years_n_2007) if ///
    same_district_five_years_n_2007 + ///
    other_district_five_years_n_2007 > 0
generate double share_born_other_district_2007 = ///
    born_other_district_n_2007 / birth_district_total_n_2007 if ///
    birth_district_total_n_2007 > 0

generate double share_insurance_sis_2007 = ///
    insurance_sis_n_2007 / population_2007 if ///
    population_2007 > 0
generate double share_insurance_essalud_2007 = ///
    insurance_essalud_n_2007 / population_2007 if ///
    population_2007 > 0
generate double share_insurance_none_2007 = ///
    insurance_none_n_2007 / population_2007 if ///
    population_2007 > 0

generate double share_indigenous_language_2007 = ///
    (language_quechua_n_2007 + ///
     language_aymara_n_2007 + ///
     language_ashaninka_n_2007 + ///
     language_other_native_n_2007) / language_total_n_2007 if ///
    language_total_n_2007 > 0
generate double share_spanish_language_2007 = ///
    language_spanish_n_2007 / language_total_n_2007 if ///
    language_total_n_2007 > 0
generate double share_literate_2007 = ///
    literate_n_2007 / literacy_total_n_2007 if ///
    literacy_total_n_2007 > 0
generate double share_education_none_2007 = ///
    education_none_n_2007 / education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double share_education_primary_2007 = ///
    education_primary_n_2007 / education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double share_education_secondary_2007 = ///
    education_secondary_n_2007 / education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double share_education_technical_2007 = ///
    (education_technical_inc_n_2007 + ///
     education_technical_com_n_2007) / education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double share_education_university_2007 = ///
    (education_university_inc_n_2007 + ///
     education_university_com_n_2007) / education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double share_educ_secondaryplus_2007 = ///
    (education_secondary_n_2007 + ///
     education_technical_inc_n_2007 + ///
     education_technical_com_n_2007 + ///
     education_university_inc_n_2007 + ///
     education_university_com_n_2007) / education_total_n_2007 if ///
    education_total_n_2007 > 0

/*
Summarize structural wellbeing without claiming an official poverty rate.
The CCPP workbook contains separate marginal totals, so it cannot identify
simultaneous household deprivations required by official NBI or MPI methods.
Indicators receive equal weight within domains and the four core domains
receive equal weight. Scores require every component; missing components never
trigger implicit reweighting.
*/

generate double wellbeing_housing_2007 = ///
    1 - share_floor_earth_2007 if ///
    !missing(share_floor_earth_2007)
generate double wellbeing_services_2007 = ///
    (share_water_pubdaily_2007 + ///
     share_sanitation_facility_2007) / 2 if ///
    !missing(share_water_pubdaily_2007, ///
             share_sanitation_facility_2007)
generate double wellbeing_energy_2007 = ///
    (share_electricity_2007 + ///
     share_clean_cooking_2007) / 2 if ///
    !missing(share_electricity_2007, ///
             share_clean_cooking_2007)
generate double wellbeing_human_capital_2007 = ///
    (share_literate_2007 + ///
     share_educ_secondaryplus_2007) / 2 if ///
    !missing(share_literate_2007, ///
             share_educ_secondaryplus_2007)

generate double wellbeing_assets_2007 = ///
    (share_asset_tv_2007 + ///
     share_asset_washer_2007 + ///
     share_asset_fridge_2007 + ///
     share_asset_computer_2007) / 4 if ///
    !missing(share_asset_tv_2007, ///
             share_asset_washer_2007, ///
             share_asset_fridge_2007, ///
             share_asset_computer_2007)
generate double wellbeing_connectivity_2007 = ///
    (share_asset_mobile_2007 + ///
     share_asset_internet_2007 + ///
     share_asset_cable_2007) / 3 if ///
    !missing(share_asset_mobile_2007, ///
             share_asset_internet_2007, ///
             share_asset_cable_2007)

generate double wellbeing_core_2007 = ///
    (wellbeing_housing_2007 + ///
     wellbeing_services_2007 + ///
     wellbeing_energy_2007 + ///
     wellbeing_human_capital_2007) / 4 if ///
    !missing(wellbeing_housing_2007, ///
             wellbeing_services_2007, ///
             wellbeing_energy_2007, ///
             wellbeing_human_capital_2007)
generate double deprivation_core_2007 = ///
    1 - wellbeing_core_2007 if ///
    !missing(wellbeing_core_2007)

/*
The marginal wall and floor distributions identify bounds, not the exact
joint NBI housing rate. These bounds cover the wall-floor condition only and
exclude the separately defined improvised-dwelling condition.
*/

generate double nbi_wallfloor_lb_2007 = ///
    min(1, ///
        share_wall_mat_2007 + ///
        max(0, ///
            share_floor_earth_2007 + ///
            share_wall_quincha_2007 + ///
            share_wall_stone_mud_2007 + ///
            share_wall_wood_2007 + ///
            share_wall_other_2007 - 1)) if ///
    !missing(share_wall_mat_2007, ///
             share_floor_earth_2007, ///
             share_wall_quincha_2007, ///
             share_wall_stone_mud_2007, ///
             share_wall_wood_2007, ///
             share_wall_other_2007)
generate double nbi_wallfloor_ub_2007 = ///
    min(1, ///
        share_wall_mat_2007 + ///
        min(share_floor_earth_2007, ///
            share_wall_quincha_2007 + ///
            share_wall_stone_mud_2007 + ///
            share_wall_wood_2007 + ///
            share_wall_other_2007)) if ///
    !missing(share_wall_mat_2007, ///
             share_floor_earth_2007, ///
             share_wall_quincha_2007, ///
             share_wall_stone_mud_2007, ///
             share_wall_wood_2007, ///
             share_wall_other_2007)

replace nbi_wallfloor_lb_2007 = ///
    nbi_wallfloor_ub_2007 if ///
    nbi_wallfloor_lb_2007 > nbi_wallfloor_ub_2007 & ///
    nbi_wallfloor_lb_2007 <= nbi_wallfloor_ub_2007 + 1e-12

generate double share_dni_2007 = ///
    dni_yes_n_2007 / (dni_yes_n_2007 + dni_no_n_2007) if ///
    dni_yes_n_2007 + dni_no_n_2007 > 0
generate double labor_force_participation_2007 = ///
    (employed_n_2007 + unemployed_n_2007) / ///
    education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double employment_rate_2007 = ///
    employed_n_2007 / education_total_n_2007 if ///
    education_total_n_2007 > 0
generate double unemployment_rate_2007 = ///
    unemployed_n_2007 / ///
    (employed_n_2007 + unemployed_n_2007) if ///
    employed_n_2007 + unemployed_n_2007 > 0
generate double share_sector_agriculture_2007 = ///
    sector_agriculture_n_2007 / sector_total_n_2007 if ///
    sector_total_n_2007 > 0
generate double share_sector_mining_2007 = ///
    sector_mining_n_2007 / sector_total_n_2007 if ///
    sector_total_n_2007 > 0
generate double share_sector_manufacturing_2007 = ///
    sector_manufacturing_n_2007 / sector_total_n_2007 if ///
    sector_total_n_2007 > 0
generate double share_sector_services_2007 = ///
    (sector_services_n_2007 + ///
     sector_finance_n_2007 + ///
     sector_transport_n_2007) / sector_total_n_2007 if ///
    sector_total_n_2007 > 0

local census2007_shares ///
    share_wall_*_2007 ///
    share_floor_*_2007 ///
    share_water_*_2007 ///
    share_sanitation_*_2007 ///
    share_electricity_2007 ///
    share_tenure_*_2007 ///
    share_asset_*_2007 ///
    share_clean_cooking_2007 ///
    share_fuel_*_2007 ///
    share_female_2007 ///
    share_age_*_2007 ///
    share_any_disability_2007 ///
    share_birth_registered_2007 ///
    share_moved_five_years_2007 ///
    share_born_other_district_2007 ///
    share_insurance_*_2007 ///
    share_indigenous_language_2007 ///
    share_spanish_language_2007 ///
    share_literate_2007 ///
    share_education_*_2007 ///
    share_educ_secondaryplus_2007 ///
    share_dni_2007 ///
    labor_force_participation_2007 ///
    employment_rate_2007 ///
    unemployment_rate_2007 ///
    share_sector_*_2007

foreach variable of varlist `census2007_shares' {
    assert inrange(`variable', 0, 1) if !missing(`variable')
}

local census2007_wellbeing ///
    wellbeing_housing_2007 ///
    wellbeing_services_2007 ///
    wellbeing_energy_2007 ///
    wellbeing_human_capital_2007 ///
    wellbeing_assets_2007 ///
    wellbeing_connectivity_2007 ///
    wellbeing_core_2007 ///
    deprivation_core_2007 ///
    nbi_wallfloor_lb_2007 ///
    nbi_wallfloor_ub_2007

foreach variable of varlist `census2007_wellbeing' {
    assert inrange(`variable', 0, 1) if !missing(`variable')
}

assert nbi_wallfloor_lb_2007 <= ///
    nbi_wallfloor_ub_2007 if ///
    !missing(nbi_wallfloor_lb_2007, nbi_wallfloor_ub_2007)

egen byte census2007_wellbeing_missing = rowmiss( ///
    wellbeing_housing_2007 ///
    wellbeing_services_2007 ///
    wellbeing_energy_2007 ///
    wellbeing_human_capital_2007)
assert missing(wellbeing_core_2007) == ///
    (census2007_wellbeing_missing > 0)
drop census2007_wellbeing_missing

label variable census2007_ubigeo_ccpp ///
    "Ten-digit centro-poblado UBIGEO in 2007 census tabulation"
label variable urban_2007 ///
    "Urban centro poblado in 2007 census tabulation"
label variable population_2007 ///
    "Population in 2007 census tabulation"
label variable households_2007 ///
    "Households in 2007 census tabulation"
label variable dwellings_occupied_2007 ///
    "Occupied dwellings with persons present in 2007"
label variable rooms_per_dwelling_2007 ///
    "Average rooms per dwelling in 2007"
label variable ln_population_2007 ///
    "Natural log of 2007 population"
label variable ln_households_2007 ///
    "Natural log of 2007 households"
label variable share_water_public_2007 ///
    "Share of occupied dwellings using public or pylon water"
label variable share_water_pubdaily_2007 ///
    "Share with public or pylon water available every day"
label variable share_sanitation_sewer_2007 ///
    "Share of occupied dwellings connected to public sewer"
label variable share_sanitation_facility_2007 ///
    "Share using sewer, septic tank, or latrine"
label variable share_electricity_2007 ///
    "Share of occupied dwellings with public electricity"
label variable share_clean_cooking_2007 ///
    "Share of households cooking with gas or electricity"
label variable share_any_disability_2007 ///
    "Share of population with any reported permanent limitation"
label variable share_indigenous_language_2007 ///
    "Share age 3+ whose first language was indigenous"
label variable share_literate_2007 ///
    "Share age 14+ able to read and write"
label variable share_educ_secondaryplus_2007 ///
    "Share age 14+ with secondary or higher education"
label variable wellbeing_housing_2007 ///
    "Housing wellbeing domain (higher is better)"
label variable wellbeing_services_2007 ///
    "Basic-services wellbeing domain (higher is better)"
label variable wellbeing_energy_2007 ///
    "Energy wellbeing domain (higher is better)"
label variable wellbeing_human_capital_2007 ///
    "Human-capital wellbeing domain (higher is better)"
label variable wellbeing_assets_2007 ///
    "Durable-assets coverage score (higher is better)"
label variable wellbeing_connectivity_2007 ///
    "Household-connectivity coverage score (higher is better)"
label variable wellbeing_core_2007 ///
    "Equal-domain ecological wellbeing score (higher is better)"
label variable deprivation_core_2007 ///
    "Equal-domain ecological deprivation score (higher is worse)"
label variable nbi_wallfloor_lb_2007 ///
    "Lower bound for wall-floor part of inadequate-housing NBI"
label variable nbi_wallfloor_ub_2007 ///
    "Upper bound for wall-floor part of inadequate-housing NBI"
label variable labor_force_participation_2007 ///
    "Labor-force participation among population age 14+"
label variable unemployment_rate_2007 ///
    "Unemployment rate among the 2007 labor force"

quietly summarize population_2007, meanonly
local census2007_population_sum = r(sum)
quietly summarize households_2007, meanonly
local census2007_household_sum = r(sum)

/*
Create deterministic secondary linkage maps before removing normalized helper
fields. Exact UBIGEO is authoritative. Exact names are used only when the
source path is unique; they never overwrite an exact-code link.
*/

victimasrd_normalize_name ///
    department_2007, generate(census2007_dpto_norm)
victimasrd_normalize_name ///
    province_2007, generate(census2007_prov_norm)
victimasrd_normalize_name ///
    district_2007, generate(census2007_dist_norm)
victimasrd_normalize_name ///
    ccpp_name_2007, generate(census2007_ccpp_norm)

egen str244 census2007_path_norm = concat( ///
    census2007_dpto_norm ///
    census2007_prov_norm ///
    census2007_dist_norm ///
    census2007_ccpp_norm), ///
    punct("|")

tempfile ///
    census2007_ids ///
    census2007_paths ///
    census2007_district_names ///
    census2007_full

preserve
keep census2007_ubigeo_ccpp
rename census2007_ubigeo_ccpp census2007_assigned_code
isid census2007_assigned_code
save "`census2007_ids'", replace
restore

preserve
keep if ///
    census2007_dpto_norm != "" & ///
    census2007_prov_norm != "" & ///
    census2007_dist_norm != "" & ///
    census2007_ccpp_norm != ""
bysort census2007_path_norm: generate int census2007_path_count = _N
keep if census2007_path_count == 1
keep census2007_path_norm census2007_ubigeo_ccpp
rename census2007_ubigeo_ccpp census2007_path_code
isid census2007_path_norm
save "`census2007_paths'", replace
restore

preserve
keep if ///
    census2007_ubigeo_dist != "" & ///
    census2007_ccpp_norm != ""
bysort census2007_ubigeo_dist census2007_ccpp_norm: ///
    generate int census2007_pair_count = _N
keep if census2007_pair_count == 1
keep ///
    census2007_ubigeo_dist ///
    census2007_ccpp_norm ///
    census2007_ubigeo_ccpp
rename census2007_ubigeo_dist ubigeo_dist
rename census2007_ubigeo_ccpp census2007_pair_code
isid ubigeo_dist census2007_ccpp_norm
save "`census2007_district_names'", replace
restore

compress
sort census2007_ubigeo_ccpp
save ///
    "${intermediate_root}/04_census_2007_ccpp.dta", ///
    replace

generate str10 census2007_assigned_code = ///
    census2007_ubigeo_ccpp
drop ///
    census2007_dpto_norm ///
    census2007_prov_norm ///
    census2007_dist_norm ///
    census2007_ccpp_norm ///
    census2007_path_norm
save "`census2007_full'", replace

use ///
    "${analysis_data_root}/04_foundational_community_registry.dta", ///
    clear

ds
local foundational_release_vars `r(varlist)'

generate str10 census2007_assigned_code = ubigeo_ccpp
merge m:1 census2007_assigned_code using ///
    "`census2007_ids'", ///
    keep(master match) ///
    gen(census2007_code_match)

generate str32 census2007_link_method = cond( ///
    census2007_code_match == 3, ///
    "exact_ubigeo", ///
    "unmatched")

replace census2007_assigned_code = "" if ///
    census2007_code_match == 1

victimasrd_normalize_name ///
    dpto_victim_raw, generate(census2007_dpto_norm)
victimasrd_normalize_name ///
    prov_victim_raw, generate(census2007_prov_norm)
victimasrd_normalize_name ///
    dist_victim_raw, generate(census2007_dist_norm)
victimasrd_normalize_name ///
    ccpp_victim_raw, generate(census2007_ccpp_norm)

egen str244 census2007_path_norm = concat( ///
    census2007_dpto_norm ///
    census2007_prov_norm ///
    census2007_dist_norm ///
    census2007_ccpp_norm), ///
    punct("|")

merge m:1 census2007_path_norm using ///
    "`census2007_paths'", ///
    keep(master match) ///
    gen(census2007_path_match)

replace census2007_assigned_code = ///
    census2007_path_code if ///
    census2007_link_method == "unmatched" & ///
    census2007_path_match == 3

replace census2007_link_method = ///
    "unique_exact_full_path" if ///
    census2007_link_method == "unmatched" & ///
    census2007_path_match == 3

merge m:1 ubigeo_dist census2007_ccpp_norm using ///
    "`census2007_district_names'", ///
    keep(master match) ///
    gen(census2007_pair_match)

replace census2007_assigned_code = ///
    census2007_pair_code if ///
    census2007_link_method == "unmatched" & ///
    census2007_pair_match == 3

replace census2007_link_method = ///
    "unique_exact_district_name" if ///
    census2007_link_method == "unmatched" & ///
    census2007_pair_match == 3

generate byte census2007_name_code_conflict = ///
    census2007_code_match == 3 & ( ///
        (census2007_path_match == 3 & ///
         ubigeo_ccpp != census2007_path_code) | ///
        (census2007_pair_match == 3 & ///
         ubigeo_ccpp != census2007_pair_code))

count if census2007_name_code_conflict
local census2007_name_code_conflicts = r(N)

preserve
keep if census2007_name_code_conflict
keep ///
    ruv_id ///
    ubigeo_ccpp ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    census2007_path_code ///
    census2007_pair_code ///
    census2007_link_method
generate str52 linkage_disposition = ///
    "exact_ubigeo_retained_name_candidate_quarantined"
save ///
    "${qa_data_root}/census2007_name_code_conflicts.dta", ///
    replace
export delimited ///
    "${qa_data_root}/census2007_name_code_conflicts.csv", ///
    replace
restore

count if census2007_link_method == "exact_ubigeo"
local census2007_exact_ubigeo = r(N)
count if census2007_link_method == "unique_exact_full_path"
local census2007_exact_path = r(N)
count if census2007_link_method == "unique_exact_district_name"
local census2007_exact_district_name = r(N)
count if census2007_link_method == "unmatched"
local census2007_unmatched = r(N)

merge m:1 census2007_assigned_code using ///
    "`census2007_full'", ///
    keep(master match) ///
    gen(census2007_data_merge)

generate byte census2007_linked = ///
    census2007_data_merge == 3

count if census2007_linked
local census2007_linked = r(N)
assert `census2007_linked' == ///
    `census2007_exact_ubigeo' + ///
    `census2007_exact_path' + ///
    `census2007_exact_district_name'

count if !census2007_linked
assert r(N) == `census2007_unmatched'

label variable census2007_linked ///
    "RUV community linked to 2007 census CCPP tabulation"
label variable census2007_link_method ///
    "Method linking RUV community to 2007 census tabulation"

preserve
keep if !census2007_linked
keep ///
    ruv_id ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    victim_inei_code_vintage ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    victimization_level_source ///
    census2007_link_method
generate str52 linkage_disposition = ///
    "retained_without_2007_census_covariates"
save ///
    "${qa_data_root}/census2007_unmatched_ruv.dta", ///
    replace
export delimited ///
    "${qa_data_root}/census2007_unmatched_ruv.csv", ///
    replace
restore

local census2007_release_vars ///
    census2007_linked ///
    census2007_link_method ///
    census2007_ubigeo_ccpp ///
    department_2007 ///
    province_2007 ///
    district_2007 ///
    ccpp_name_2007 ///
    urban_2007 ///
    population_2007 ///
    households_2007 ///
    dwellings_occupied_2007 ///
    rooms_per_dwelling_2007 ///
    ln_population_2007 ///
    ln_households_2007 ///
    share_wall_*_2007 ///
    share_floor_*_2007 ///
    share_water_*_2007 ///
    share_sanitation_*_2007 ///
    share_electricity_2007 ///
    share_tenure_*_2007 ///
    share_asset_*_2007 ///
    share_clean_cooking_2007 ///
    share_fuel_*_2007 ///
    share_female_2007 ///
    share_age_*_2007 ///
    share_any_disability_2007 ///
    share_birth_registered_2007 ///
    share_moved_five_years_2007 ///
    share_born_other_district_2007 ///
    share_insurance_*_2007 ///
    share_indigenous_language_2007 ///
    share_spanish_language_2007 ///
    share_literate_2007 ///
    share_education_*_2007 ///
    share_educ_secondaryplus_2007 ///
    wellbeing_*_2007 ///
    deprivation_core_2007 ///
    nbi_wallfloor_*_2007 ///
    share_dni_2007 ///
    labor_force_participation_2007 ///
    employment_rate_2007 ///
    unemployment_rate_2007 ///
    share_sector_*_2007 ///
    children_born_avg_2007 ///
    children_alive_avg_2007 ///
    mothers_n_2007 ///
    age_first_birth_avg_2007

keep ///
    `foundational_release_vars' ///
    `census2007_release_vars'

order ///
    `foundational_release_vars' ///
    census2007_linked ///
    census2007_link_method ///
    census2007_ubigeo_ccpp ///
    department_2007 ///
    province_2007 ///
    district_2007 ///
    ccpp_name_2007 ///
    urban_2007 ///
    population_2007 ///
    households_2007 ///
    dwellings_occupied_2007 ///
    rooms_per_dwelling_2007 ///
    ln_population_2007 ///
    ln_households_2007

compress
sort ruv_id
isid ruv_id
count
local census2007_registry_rows = r(N)
assert `census2007_registry_rows' == `foundational_rows'

save ///
    "${analysis_data_root}/05_community_registry_census2007.dta", ///
    replace


*===============================================================================
**# 9. Prepare and integrate 2017 CCPP geospatial attributes
*===============================================================================

local geospatial_basic_shape ///
    "${raw_root}/11 Centros Poblados/Centros_Poblados_INEI_geogpsperu_SuyoPomalia (1)/Centros_Poblados_INEI_geogpsperu_SuyoPomalia"
local geospatial_category_shape ///
    "${raw_root}/11 Centros Poblados/Centros_Poblados_Categoria_INEI_geogpsperu_SuyoPomalia/Centros_Poblados_Categoria_INEI_geogpsperu_SuyoPomalia"

/*
The two GeoGPS Peru downloads redistribute distinct INEI 2017 point layers.
The urban/rural layer is the 94,922-record CCPP spine with unique ten-digit
codes. The category layer contains 90,253 valid CCPP codes plus 4,669
dispersed-population points coded "0". The complete urban/rural layer is
therefore authoritative for geometry and identifiers; category attributes are
merged only by valid exact CCPP code.
*/

foreach shape_stub in ///
    "`geospatial_basic_shape'" ///
    "`geospatial_category_shape'" {

    foreach extension in shp shx dbf prj {
        capture confirm file "`shape_stub'.`extension'"
        if _rc {
            display as error "Required geospatial source component was not found:"
            display as error "  `shape_stub'.`extension'"
            exit 601
        }
    }
}

local geospatial_basic_map ///
    "${intermediate_root}/05_geospatial_ccpp_2017_basic_map.dta"
local geospatial_basic_coordinates ///
    "${intermediate_root}/05_geospatial_ccpp_2017_basic_map_shp.dta"
local geospatial_category_map ///
    "${intermediate_root}/06_geospatial_ccpp_2017_category_map.dta"
local geospatial_category_coordinates ///
    "${intermediate_root}/06_geospatial_ccpp_2017_category_map_shp.dta"
local geospatial_source ///
    "${intermediate_root}/07_geospatial_ccpp_2017.dta"
local district_capitals ///
    "${intermediate_root}/08_district_capitals_2017.dta"
local province_capitals ///
    "${intermediate_root}/09_province_capitals_2017.dta"
local department_capitals ///
    "${intermediate_root}/10_department_capitals_2017.dta"
local cities_2017 ///
    "${intermediate_root}/11_cities_2017.dta"

/*
Use Stata's official spatial translator rather than the retired user-written
shp2dta command. spshape2dta must write to the current directory, so the
pipeline changes directory only for the conversion and immediately returns.
The two map-ready database/shapefile pairs remain in Dropbox Working.
*/

local geospatial_prior_directory "`c(pwd)'"
cd "${intermediate_root}"

spshape2dta ///
    "`geospatial_basic_shape'", ///
    saving("05_geospatial_ccpp_2017_basic_map") ///
    replace

spshape2dta ///
    "`geospatial_category_shape'", ///
    saving("06_geospatial_ccpp_2017_category_map") ///
    replace

foreach spatial_database in ///
    "05_geospatial_ccpp_2017_basic_map" ///
    "06_geospatial_ccpp_2017_category_map" {

    use "`spatial_database'.dta", clear
    spset, modify coordsys(latlong, kilometers)

    /* Dropbox may briefly lock a newly translated file while synchronizing. */
    local spatial_save_rc = 1
    forvalues spatial_save_attempt = 1/5 {
        capture save "`spatial_database'.dta", replace
        local spatial_save_rc = _rc
        if `spatial_save_rc' == 0 continue, break
        if `spatial_save_attempt' < 5 sleep 2000
    }

    if `spatial_save_rc' {
        cd "`geospatial_prior_directory'"
        display as error "Unable to save the translated spatial database after five attempts:"
        display as error "  `spatial_database'.dta"
        exit `spatial_save_rc'
    }
}

cd "`geospatial_prior_directory'"

foreach converted_file in ///
    "`geospatial_basic_map'" ///
    "`geospatial_basic_coordinates'" ///
    "`geospatial_category_map'" ///
    "`geospatial_category_coordinates'" {

    capture confirm file "`converted_file'"
    if _rc {
        display as error "Expected Stata spatial output was not created:"
        display as error "  `converted_file'"
        exit 603
    }
}

/*
Validate and clean the complete CCPP point layer. Coordinates are WGS 1984
longitude and latitude in signed decimal degrees. Capital status follows the
ten-digit code structure recorded by the research team:

    DDPPDDCCCC
    CCCC == 0001       district capital
    DDCCCC == 010001   province capital
    PPDDCCCC == 01010001 department capital
*/

cd "${intermediate_root}"
use "05_geospatial_ccpp_2017_basic_map.dta", clear

count
assert r(N) == 94922
assert c(k) == 25
assert ustrregexm(IDCCPP, "^[0-9]{10}$")
isid IDCCPP
assert UBIGEO == substr(IDCCPP, 1, 6)
assert inrange(_CX, -82, -68)
assert inrange(_CY, -19, 1)
assert !missing(_CX, _CY)

generate long geospatial_source_id = _ID
generate double longitude_2017 = _CX
generate double latitude_2017 = _CY
spset, modify noshpfile
spset, clear

rename ///
    (IDCCPP ///
     NOMB_CCPP ///
     NOMB_DISTR ///
     NOMB_PROVI ///
     NOMB_DEPAR) ///
    (geospatial_ubigeo_ccpp ///
     ccpp_name_spatial_2017 ///
     district_spatial_2017 ///
     province_spatial_2017 ///
     department_spatial_2017)

generate str6 geospatial_ubigeo_dist = ///
    substr(geospatial_ubigeo_ccpp, 1, 6)
generate str4 geospatial_ubigeo_prov = ///
    substr(geospatial_ubigeo_ccpp, 1, 4)
generate str2 geospatial_ubigeo_dpto = ///
    substr(geospatial_ubigeo_ccpp, 1, 2)

assert inlist(TIPO, "Urbano", "Rural")
generate byte geospatial_area_disagreement = ///
    (AREA_CP == 1 & TIPO != "Urbano") | ///
    (AREA_CP == 2 & TIPO != "Rural")
count if geospatial_area_disagreement
local geospatial_area_disagreements = r(N)
assert `geospatial_area_disagreements' == 16

preserve
keep if geospatial_area_disagreement
keep ///
    geospatial_ubigeo_ccpp ///
    department_spatial_2017 ///
    province_spatial_2017 ///
    district_spatial_2017 ///
    ccpp_name_spatial_2017 ///
    AREA_CP ///
    TIPO
save ///
    "${qa_data_root}/geospatial2017_area_classification_disagreements.dta", ///
    replace
export delimited ///
    "${qa_data_root}/geospatial2017_area_classification_disagreements.csv", ///
    replace
restore

/*
The embedded XML lineage shows that GeoGPS calculated TIPO in ArcGIS in July
2023. AREA_CP is the underlying numeric INEI field and therefore governs the
analytical indicator. The 16 disagreements remain quarantined above.
*/
generate byte urban_2017 = AREA_CP == 1
drop geospatial_area_disagreement

generate byte is_dist_capital_2017 = ///
    substr(geospatial_ubigeo_ccpp, 7, 4) == "0001"
generate byte is_prov_capital_2017 = ///
    substr(geospatial_ubigeo_ccpp, 5, 6) == "010001"
generate byte is_dept_capital_2017 = ///
    substr(geospatial_ubigeo_ccpp, 3, 8) == "01010001"

count if is_dist_capital_2017
local geospatial_district_capitals = r(N)
assert `geospatial_district_capitals' == 1874

count if is_prov_capital_2017
local geospatial_province_capitals = r(N)
assert `geospatial_province_capitals' == 196

count if is_dept_capital_2017
local geospatial_department_capitals = r(N)
assert `geospatial_department_capitals' == 25

preserve
keep if is_dist_capital_2017
isid geospatial_ubigeo_dist
restore

preserve
keep if is_prov_capital_2017
isid geospatial_ubigeo_prov
restore

preserve
keep if is_dept_capital_2017
isid geospatial_ubigeo_dpto
restore

tempfile ///
    geospatial_basic ///
    geospatial_category_attributes ///
    geospatial_category_ids ///
    geospatial_ids ///
    geospatial_census_ids ///
    geospatial_paths ///
    geospatial_district_names ///
    geospatial_full

save "`geospatial_basic'", replace

/*
Validate the category layer separately. The 4,669 code-zero rows represent
dispersed-population locations, not uniquely identified CCPPs, and cannot be
merged to the analytical registry. The 20 valid codes absent from the complete
CCPP spine are retained in Dropbox QA; none match an RUV row.
*/

use "06_geospatial_ccpp_2017_category_map.dta", clear

count
assert r(N) == 94922
assert c(k) == 25
assert inrange(_CX, -82, -68)
assert inrange(_CY, -19, 1)
assert abs(_CX - LONGITUD) < 1e-6
assert abs(_CY - LATITUD) < 1e-6

count if CODIGO == "0"
local geospatial_dispersed_points = r(N)
assert `geospatial_dispersed_points' == 4669

count if ustrregexm(CODIGO, "^[0-9]{10}$")
local geospatial_category_codes = r(N)
assert `geospatial_category_codes' == 90253

preserve
keep if ustrregexm(CODIGO, "^[0-9]{10}$")
rename CODIGO geospatial_ubigeo_ccpp
keep geospatial_ubigeo_ccpp
isid geospatial_ubigeo_ccpp
save "`geospatial_category_ids'", replace
restore

keep if ustrregexm(CODIGO, "^[0-9]{10}$")
rename ///
    (CODIGO ///
     LONGITUD ///
     LATITUD ///
     ALTITUD ///
     REGION_NAT ///
     CATEGORIA ///
     POBLACION ///
     CPV2017_GI) ///
    (geospatial_ubigeo_ccpp ///
     longitude_category_2017 ///
     latitude_category_2017 ///
     altitude_m_2017 ///
     natural_region_2017 ///
     ccpp_category_2017 ///
     population_2017_directory ///
     census_status_2017)

keep ///
    geospatial_ubigeo_ccpp ///
    longitude_category_2017 ///
    latitude_category_2017 ///
    altitude_m_2017 ///
    natural_region_2017 ///
    ccpp_category_2017 ///
    population_2017_directory ///
    census_status_2017

isid geospatial_ubigeo_ccpp
save "`geospatial_category_attributes'", replace

use "`geospatial_category_attributes'", clear
merge 1:1 geospatial_ubigeo_ccpp using ///
    "`geospatial_basic'", ///
    keep(master match) ///
    gen(geospatial_category_basic_merge)

count if geospatial_category_basic_merge == 1
local geospatial_category_only_codes = r(N)
assert `geospatial_category_only_codes' == 20

keep if geospatial_category_basic_merge == 1
keep ///
    geospatial_ubigeo_ccpp ///
    longitude_category_2017 ///
    latitude_category_2017 ///
    altitude_m_2017 ///
    natural_region_2017 ///
    ccpp_category_2017 ///
    population_2017_directory

save ///
    "${qa_data_root}/geospatial2017_category_only_codes.dta", ///
    replace
export delimited ///
    "${qa_data_root}/geospatial2017_category_only_codes.csv", ///
    replace

use "`geospatial_basic'", clear
merge 1:1 geospatial_ubigeo_ccpp using ///
    "`geospatial_category_attributes'", ///
    keep(master match) ///
    gen(geospatial_category_merge)

count if geospatial_category_merge == 3
local geospatial_category_linked = r(N)
assert `geospatial_category_linked' == 90233

count if geospatial_category_merge == 1
local geospatial_basic_only = r(N)
assert `geospatial_basic_only' == 4689

assert abs(longitude_2017 - longitude_category_2017) < 1e-6 if ///
    geospatial_category_merge == 3
assert abs(latitude_2017 - latitude_category_2017) < 1e-6 if ///
    geospatial_category_merge == 3

preserve
keep if geospatial_category_merge == 1
keep ///
    geospatial_ubigeo_ccpp ///
    department_spatial_2017 ///
    province_spatial_2017 ///
    district_spatial_2017 ///
    ccpp_name_spatial_2017 ///
    longitude_2017 ///
    latitude_2017
save ///
    "${qa_data_root}/geospatial2017_basic_without_category.dta", ///
    replace
export delimited ///
    "${qa_data_root}/geospatial2017_basic_without_category.csv", ///
    replace
restore

drop ///
    geospatial_category_merge ///
    longitude_category_2017 ///
    latitude_category_2017

/*
Create the capital and city point files once and calculate straight-line
geodesic distances on the WGS 1984 ellipsoid. "Corresponding" capitals are
defined by the CCPP code hierarchy; "nearest" capitals may lie outside the
observation's own district, province, or department. City status comes from
the category layer's CIUDAD classification.
*/

preserve
keep if is_dist_capital_2017
keep ///
    geospatial_ubigeo_dist ///
    geospatial_ubigeo_ccpp ///
    ccpp_name_spatial_2017 ///
    latitude_2017 ///
    longitude_2017
rename ///
    (geospatial_ubigeo_ccpp ///
     ccpp_name_spatial_2017 ///
     latitude_2017 ///
     longitude_2017) ///
    (dist_capital_code ///
     dist_capital_name ///
     dist_capital_latitude ///
     dist_capital_longitude)
generate long dist_capital_id = _n
isid geospatial_ubigeo_dist
save "`district_capitals'", replace
restore

preserve
keep if is_prov_capital_2017
keep ///
    geospatial_ubigeo_prov ///
    geospatial_ubigeo_ccpp ///
    ccpp_name_spatial_2017 ///
    latitude_2017 ///
    longitude_2017
rename ///
    (geospatial_ubigeo_ccpp ///
     ccpp_name_spatial_2017 ///
     latitude_2017 ///
     longitude_2017) ///
    (prov_capital_code ///
     prov_capital_name ///
     prov_capital_latitude ///
     prov_capital_longitude)
generate long prov_capital_id = _n
isid geospatial_ubigeo_prov
save "`province_capitals'", replace
restore

preserve
keep if is_dept_capital_2017
keep ///
    geospatial_ubigeo_dpto ///
    geospatial_ubigeo_ccpp ///
    ccpp_name_spatial_2017 ///
    latitude_2017 ///
    longitude_2017
rename ///
    (geospatial_ubigeo_ccpp ///
     ccpp_name_spatial_2017 ///
     latitude_2017 ///
     longitude_2017) ///
    (dept_capital_code ///
     dept_capital_name ///
     dept_capital_latitude ///
     dept_capital_longitude)
generate long dept_capital_id = _n
isid geospatial_ubigeo_dpto
save "`department_capitals'", replace
restore

preserve
keep if ccpp_category_2017 == "CIUDAD"
keep ///
    geospatial_ubigeo_ccpp ///
    ccpp_name_spatial_2017 ///
    latitude_2017 ///
    longitude_2017
rename ///
    (geospatial_ubigeo_ccpp ///
     ccpp_name_spatial_2017 ///
     latitude_2017 ///
     longitude_2017) ///
    (city_code ///
     city_name ///
     city_latitude ///
     city_longitude)
generate long city_id = _n
isid city_id
count
assert r(N) == 235
save "`cities_2017'", replace
restore

merge m:1 geospatial_ubigeo_dist using ///
    "`district_capitals'", ///
    assert(match) ///
    nogen
merge m:1 geospatial_ubigeo_prov using ///
    "`province_capitals'", ///
    assert(match) ///
    nogen
merge m:1 geospatial_ubigeo_dpto using ///
    "`department_capitals'", ///
    assert(match) ///
    nogen

geodist ///
    latitude_2017 ///
    longitude_2017 ///
    dist_capital_latitude ///
    dist_capital_longitude, ///
    generate(dist_dist_capital_km)

geodist ///
    latitude_2017 ///
    longitude_2017 ///
    prov_capital_latitude ///
    prov_capital_longitude, ///
    generate(dist_prov_capital_km)

geodist ///
    latitude_2017 ///
    longitude_2017 ///
    dept_capital_latitude ///
    dept_capital_longitude, ///
    generate(dist_dept_capital_km)

geonear ///
    geospatial_source_id ///
    latitude_2017 ///
    longitude_2017 ///
    using "`district_capitals'", ///
    neighbors( ///
        dist_capital_id ///
        dist_capital_latitude ///
        dist_capital_longitude) ///
    genstub(nearest_dist_capital) ///
    ellipsoid ///
    report(60)

rename ///
    km_to_nearest_dist_capital ///
    dist_near_dist_cap_km

geonear ///
    geospatial_source_id ///
    latitude_2017 ///
    longitude_2017 ///
    using "`province_capitals'", ///
    neighbors( ///
        prov_capital_id ///
        prov_capital_latitude ///
        prov_capital_longitude) ///
    genstub(nearest_prov_capital) ///
    ellipsoid ///
    report(60)

rename ///
    km_to_nearest_prov_capital ///
    dist_near_prov_cap_km

geonear ///
    geospatial_source_id ///
    latitude_2017 ///
    longitude_2017 ///
    using "`department_capitals'", ///
    neighbors( ///
        dept_capital_id ///
        dept_capital_latitude ///
        dept_capital_longitude) ///
    genstub(nearest_dept_capital) ///
    ellipsoid ///
    report(60)

rename ///
    km_to_nearest_dept_capital ///
    dist_near_dept_cap_km

geonear ///
    geospatial_source_id ///
    latitude_2017 ///
    longitude_2017 ///
    using "`cities_2017'", ///
    neighbors( ///
        city_id ///
        city_latitude ///
        city_longitude) ///
    genstub(nearest_city) ///
    ellipsoid ///
    report(60)

rename km_to_nearest_city dist_nearest_city_km

local geospatial_distances ///
    dist_dist_capital_km ///
    dist_near_dist_cap_km ///
    dist_prov_capital_km ///
    dist_near_prov_cap_km ///
    dist_dept_capital_km ///
    dist_near_dept_cap_km ///
    dist_nearest_city_km

foreach variable of varlist `geospatial_distances' {
    assert `variable' >= 0 & !missing(`variable')
}

assert dist_near_dist_cap_km <= ///
    dist_dist_capital_km + 1e-6
assert dist_near_prov_cap_km <= ///
    dist_prov_capital_km + 1e-6
assert dist_near_dept_cap_km <= ///
    dist_dept_capital_km + 1e-6

generate double ln1p_dist_dist_capital = ///
    ln(1 + dist_dist_capital_km)
generate double ln1p_dist_near_dist_cap = ///
    ln(1 + dist_near_dist_cap_km)
generate double ln1p_dist_prov_capital = ///
    ln(1 + dist_prov_capital_km)
generate double ln1p_dist_near_prov_cap = ///
    ln(1 + dist_near_prov_cap_km)
generate double ln1p_dist_dept_capital = ///
    ln(1 + dist_dept_capital_km)
generate double ln1p_dist_near_dept_cap = ///
    ln(1 + dist_near_dept_cap_km)
generate double ln1p_dist_nearest_city = ///
    ln(1 + dist_nearest_city_km)

label variable longitude_2017 ///
    "Longitude of 2017 CCPP point (WGS 84 decimal degrees)"
label variable latitude_2017 ///
    "Latitude of 2017 CCPP point (WGS 84 decimal degrees)"
label variable altitude_m_2017 ///
    "Altitude of 2017 CCPP point in meters above sea level"
label variable natural_region_2017 ///
    "Natural region in the 2017 CCPP category layer"
label variable ccpp_category_2017 ///
    "Centro-poblado category in the 2017 category layer"
label variable population_2017_directory ///
    "Population reported in the 2017 CCPP directory"
label variable urban_2017 ///
    "Urban CCPP in underlying INEI AREA_CP field"
label variable is_dist_capital_2017 ///
    "CCPP is the corresponding 2017 district capital"
label variable is_prov_capital_2017 ///
    "CCPP is the corresponding 2017 province capital"
label variable is_dept_capital_2017 ///
    "CCPP is the corresponding 2017 department capital"
label variable dist_dist_capital_km ///
    "Geodesic distance to corresponding district capital (km)"
label variable dist_near_dist_cap_km ///
    "Geodesic distance to nearest district capital (km)"
label variable dist_prov_capital_km ///
    "Geodesic distance to corresponding province capital (km)"
label variable dist_near_prov_cap_km ///
    "Geodesic distance to nearest province capital (km)"
label variable dist_dept_capital_km ///
    "Geodesic distance to corresponding department capital (km)"
label variable dist_near_dept_cap_km ///
    "Geodesic distance to nearest department capital (km)"
label variable dist_nearest_city_km ///
    "Geodesic distance to nearest CCPP categorized as city (km)"
label variable ln1p_dist_dist_capital ///
    "ln(1 + km to corresponding district capital)"
label variable ln1p_dist_near_dist_cap ///
    "ln(1 + km to nearest district capital)"
label variable ln1p_dist_prov_capital ///
    "ln(1 + km to corresponding province capital)"
label variable ln1p_dist_near_prov_cap ///
    "ln(1 + km to nearest province capital)"
label variable ln1p_dist_dept_capital ///
    "ln(1 + km to corresponding department capital)"
label variable ln1p_dist_near_dept_cap ///
    "ln(1 + km to nearest department capital)"
label variable ln1p_dist_nearest_city ///
    "ln(1 + km to nearest CCPP categorized as city)"

victimasrd_normalize_name ///
    department_spatial_2017, generate(geospatial_dpto_norm)
victimasrd_normalize_name ///
    province_spatial_2017, generate(geospatial_prov_norm)
victimasrd_normalize_name ///
    district_spatial_2017, generate(geospatial_dist_norm)
victimasrd_normalize_name ///
    ccpp_name_spatial_2017, generate(geospatial_ccpp_norm)

egen str244 geospatial_path_norm = concat( ///
    geospatial_dpto_norm ///
    geospatial_prov_norm ///
    geospatial_dist_norm ///
    geospatial_ccpp_norm), ///
    punct("|")

preserve
keep geospatial_ubigeo_ccpp
rename geospatial_ubigeo_ccpp geospatial_assigned_code
isid geospatial_assigned_code
save "`geospatial_ids'", replace
restore

preserve
keep geospatial_ubigeo_ccpp
rename geospatial_ubigeo_ccpp geospatial_census_code
isid geospatial_census_code
save "`geospatial_census_ids'", replace
restore

preserve
keep if ///
    geospatial_dpto_norm != "" & ///
    geospatial_prov_norm != "" & ///
    geospatial_dist_norm != "" & ///
    geospatial_ccpp_norm != ""
bysort geospatial_path_norm: generate int geospatial_path_count = _N
keep if geospatial_path_count == 1
keep geospatial_path_norm geospatial_ubigeo_ccpp
rename geospatial_ubigeo_ccpp geospatial_path_code
isid geospatial_path_norm
save "`geospatial_paths'", replace
restore

preserve
keep if ///
    geospatial_ubigeo_dist != "" & ///
    geospatial_ccpp_norm != ""
bysort geospatial_ubigeo_dist geospatial_ccpp_norm: ///
    generate int geospatial_pair_count = _N
keep if geospatial_pair_count == 1
keep ///
    geospatial_ubigeo_dist ///
    geospatial_ccpp_norm ///
    geospatial_ubigeo_ccpp
rename geospatial_ubigeo_dist geospatial_district
rename geospatial_ubigeo_ccpp geospatial_pair_code
isid geospatial_district geospatial_ccpp_norm
save "`geospatial_district_names'", replace
restore

compress
sort geospatial_ubigeo_ccpp
count
local geospatial_source_rows = r(N)
assert `geospatial_source_rows' == 94922
save "`geospatial_source'", replace

generate str10 geospatial_assigned_code = ///
    geospatial_ubigeo_ccpp
drop ///
    geospatial_dpto_norm ///
    geospatial_prov_norm ///
    geospatial_dist_norm ///
    geospatial_ccpp_norm ///
    geospatial_path_norm
save "`geospatial_full'", replace

/*
Link the spatial spine to the complete RUV registry. Current verified UBIGEO is
authoritative. A valid exact 2007 Census code is a secondary historical bridge.
Unique exact names are allowed only after both code rules fail. All RUV rows
remain in the final registry.
*/

use ///
    "${analysis_data_root}/05_community_registry_census2007.dta", ///
    clear

ds
local census_registry_vars `r(varlist)'

generate str10 geospatial_assigned_code = ubigeo_ccpp
merge m:1 geospatial_assigned_code using ///
    "`geospatial_ids'", ///
    keep(master match) ///
    gen(geospatial_current_match)

generate str32 geospatial_link_method = cond( ///
    geospatial_current_match == 3, ///
    "exact_current_ubigeo", ///
    "unmatched")

replace geospatial_assigned_code = "" if ///
    geospatial_current_match == 1

generate str10 geospatial_census_code = ///
    census2007_ubigeo_ccpp
merge m:1 geospatial_census_code using ///
    "`geospatial_census_ids'", ///
    keep(master match) ///
    gen(geospatial_census_match)

replace geospatial_assigned_code = ///
    geospatial_census_code if ///
    geospatial_link_method == "unmatched" & ///
    geospatial_census_match == 3

replace geospatial_link_method = ///
    "exact_census2007_ubigeo" if ///
    geospatial_link_method == "unmatched" & ///
    geospatial_census_match == 3

victimasrd_normalize_name ///
    dpto_victim_raw, generate(geospatial_dpto_norm)
victimasrd_normalize_name ///
    prov_victim_raw, generate(geospatial_prov_norm)
victimasrd_normalize_name ///
    dist_victim_raw, generate(geospatial_dist_norm)
victimasrd_normalize_name ///
    ccpp_victim_raw, generate(geospatial_ccpp_norm)

egen str244 geospatial_path_norm = concat( ///
    geospatial_dpto_norm ///
    geospatial_prov_norm ///
    geospatial_dist_norm ///
    geospatial_ccpp_norm), ///
    punct("|")

merge m:1 geospatial_path_norm using ///
    "`geospatial_paths'", ///
    keep(master match) ///
    gen(geospatial_path_match)

replace geospatial_assigned_code = ///
    geospatial_path_code if ///
    geospatial_link_method == "unmatched" & ///
    geospatial_path_match == 3

replace geospatial_link_method = ///
    "unique_exact_full_path" if ///
    geospatial_link_method == "unmatched" & ///
    geospatial_path_match == 3

generate str6 geospatial_district = ubigeo_dist
merge m:1 geospatial_district geospatial_ccpp_norm using ///
    "`geospatial_district_names'", ///
    keep(master match) ///
    gen(geospatial_pair_match)

replace geospatial_assigned_code = ///
    geospatial_pair_code if ///
    geospatial_link_method == "unmatched" & ///
    geospatial_pair_match == 3

replace geospatial_link_method = ///
    "unique_exact_district_name" if ///
    geospatial_link_method == "unmatched" & ///
    geospatial_pair_match == 3

generate byte geospatial_code_conflict = ///
    geospatial_current_match == 3 & ///
    geospatial_census_match == 3 & ///
    ubigeo_ccpp != geospatial_census_code

generate byte geospatial_name_conflict = ///
    geospatial_current_match == 3 & ( ///
        (geospatial_path_match == 3 & ///
         ubigeo_ccpp != geospatial_path_code) | ///
        (geospatial_pair_match == 3 & ///
         ubigeo_ccpp != geospatial_pair_code))

count if geospatial_code_conflict
local geospatial_code_conflicts = r(N)
assert `geospatial_code_conflicts' == 4

count if geospatial_name_conflict
local geospatial_name_conflicts = r(N)

preserve
keep if geospatial_code_conflict | geospatial_name_conflict
keep ///
    ruv_id ///
    ubigeo_ccpp ///
    census2007_ubigeo_ccpp ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    geospatial_census_code ///
    geospatial_path_code ///
    geospatial_pair_code ///
    geospatial_link_method ///
    geospatial_code_conflict ///
    geospatial_name_conflict
generate str52 linkage_disposition = ///
    "current_ubigeo_retained_alternative_quarantined"
save ///
    "${qa_data_root}/geospatial2017_linkage_conflicts.dta", ///
    replace
export delimited ///
    "${qa_data_root}/geospatial2017_linkage_conflicts.csv", ///
    replace
restore

count if geospatial_link_method == "exact_current_ubigeo"
local geospatial_exact_current = r(N)
count if geospatial_link_method == "exact_census2007_ubigeo"
local geospatial_exact_census = r(N)
count if geospatial_link_method == "unique_exact_full_path"
local geospatial_exact_path = r(N)
count if geospatial_link_method == "unique_exact_district_name"
local geospatial_exact_district_name = r(N)
count if geospatial_link_method == "unmatched"
local geospatial_unmatched = r(N)

merge m:1 geospatial_assigned_code using ///
    "`geospatial_full'", ///
    keep(master match) ///
    gen(geospatial_data_merge)

generate byte geospatial_linked = ///
    geospatial_data_merge == 3

count if geospatial_linked
local geospatial_linked = r(N)
assert `geospatial_linked' == ///
    `geospatial_exact_current' + ///
    `geospatial_exact_census' + ///
    `geospatial_exact_path' + ///
    `geospatial_exact_district_name'

count if !geospatial_linked
assert r(N) == `geospatial_unmatched'

count if geospatial_linked & !missing(altitude_m_2017)
local geospatial_altitude_available = r(N)
count if geospatial_linked & !missing(population_2017_directory)
local geospatial_population_available = r(N)

label variable geospatial_linked ///
    "RUV community linked to the 2017 CCPP spatial spine"
label variable geospatial_link_method ///
    "Method linking RUV community to the 2017 spatial spine"
label variable geospatial_ubigeo_ccpp ///
    "Ten-digit code used for the 2017 geospatial link"

preserve
keep if !geospatial_linked
keep ///
    ruv_id ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    census2007_ubigeo_ccpp ///
    victim_inei_code_vintage ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    victimization_level_source ///
    geospatial_link_method
generate str52 linkage_disposition = ///
    "retained_without_2017_geospatial_attributes"
save ///
    "${qa_data_root}/geospatial2017_unmatched_ruv.dta", ///
    replace
export delimited ///
    "${qa_data_root}/geospatial2017_unmatched_ruv.csv", ///
    replace
restore

local geospatial_release_vars ///
    geospatial_linked ///
    geospatial_link_method ///
    geospatial_ubigeo_ccpp ///
    longitude_2017 ///
    latitude_2017 ///
    altitude_m_2017 ///
    natural_region_2017 ///
    ccpp_category_2017 ///
    urban_2017 ///
    population_2017_directory ///
    is_dist_capital_2017 ///
    is_prov_capital_2017 ///
    is_dept_capital_2017 ///
    dist_dist_capital_km ///
    dist_near_dist_cap_km ///
    dist_prov_capital_km ///
    dist_near_prov_cap_km ///
    dist_dept_capital_km ///
    dist_near_dept_cap_km ///
    dist_nearest_city_km ///
    ln1p_dist_dist_capital ///
    ln1p_dist_near_dist_cap ///
    ln1p_dist_prov_capital ///
    ln1p_dist_near_prov_cap ///
    ln1p_dist_dept_capital ///
    ln1p_dist_near_dept_cap ///
    ln1p_dist_nearest_city

keep ///
    `census_registry_vars' ///
    `geospatial_release_vars'

order ///
    `census_registry_vars' ///
    geospatial_linked ///
    geospatial_link_method ///
    geospatial_ubigeo_ccpp ///
    longitude_2017 ///
    latitude_2017 ///
    altitude_m_2017 ///
    natural_region_2017 ///
    ccpp_category_2017 ///
    urban_2017 ///
    population_2017_directory

compress
sort ruv_id
isid ruv_id
count
local geospatial_registry_rows = r(N)
assert `geospatial_registry_rows' == `census2007_registry_rows'

save ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    replace

cd "`geospatial_prior_directory'"


*===============================================================================
**# 10. Prepare and link Seminario-Palomino CCPP GDP estimates
*===============================================================================

/*
The source estimates real GDP for a fixed 2007 CCPP universe from 1993 to
2018. District GDP is allocated across CCPPs using 2007 population shares, and
the community series then inherits district growth. The full annual source is
kept in Dropbox Working. The analytical registry retains only two
pre-treatment levels, a zero-safe transformation, district pre-treatment
growth, and transparent settlement-concentration measures.

The concentration measures are not income or household-welfare inequality.
They summarize how the source allocates estimated district activity across
its constituent CCPPs. No Gini coefficient is constructed from these totals.
*/

local gdp_source ///
    "${raw_root}/10 Nightlights/4. PBI_CentrosPoblados_1993-2018.xlsx"

capture confirm file "`gdp_source'"
if _rc {
    display as error "Seminario-Palomino CCPP GDP workbook was not found:"
    display as error "  `gdp_source'"
    exit 601
}

tempfile ///
    gdp_ccpp_source ///
    gdp_district_source ///
    gdp_district_names ///
    gdp_ccpp_code_lookup ///
    gdp_ccpp_full_path_lookup ///
    gdp_ccpp_primary_name_lookup ///
    gdp_links ///
    gdp_accepted_ids ///
    gdp_used_codes ///
    gdp_link_values ///
    gdp_district_code_lookup ///
    gdp_district_path_lookup ///
    gdp_district_name_links

import excel using "`gdp_source'", ///
    sheet("PBI_CP") firstrow clear

assert _N == 98012

foreach source_id in IDDIST IDCARTOGR {
    confirm string variable `source_id'
}

local gdp_excel_columns ///
    G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF
local gdp_column_count : word count `gdp_excel_columns'
assert `gdp_column_count' == 26

forvalues year_index = 1/`gdp_column_count' {
    local source_column : word `year_index' of `gdp_excel_columns'
    local source_year = 1992 + `year_index'
    confirm numeric variable `source_column'
    rename `source_column' gdp_ccpp_`source_year'
}

rename ///
    (IDDIST IDCARTOGR NOMB_DEP NOMB_PRO NOMB_DIST NOMCCPP) ///
    (gdp_dist_ubigeo gdp_ccpp_ubigeo gdp_source_department ///
     gdp_source_province gdp_source_district gdp_source_ccpp)

generate byte gdp_national_total = missing(gdp_ccpp_ubigeo)
count if gdp_national_total
local gdp_national_total_rows = r(N)
assert `gdp_national_total_rows' == 1

assert strlen(gdp_dist_ubigeo) == 6 if !gdp_national_total
assert strlen(gdp_ccpp_ubigeo) == 10 if !gdp_national_total
assert substr(gdp_ccpp_ubigeo, 1, 6) == gdp_dist_ubigeo ///
    if !gdp_national_total

forvalues source_year = 1993/2018 {
    assert !missing(gdp_ccpp_`source_year')
    assert gdp_ccpp_`source_year' >= 0

    quietly summarize ///
        gdp_ccpp_`source_year' if gdp_national_total, meanonly
    scalar __gdp_reported_total = r(mean)
    quietly summarize ///
        gdp_ccpp_`source_year' if !gdp_national_total, meanonly
    assert reldif(r(sum), __gdp_reported_total) < 1e-10
}
scalar drop __gdp_reported_total

drop if gdp_national_total
drop gdp_national_total
isid gdp_ccpp_ubigeo

count
local gdp_ccpp_source_rows = r(N)
assert `gdp_ccpp_source_rows' == 98011

preserve
keep gdp_dist_ubigeo
duplicates drop
count
local gdp_district_source_rows = r(N)
assert `gdp_district_source_rows' == 1833
restore

preserve
generate str2 gdp_department_code = substr(gdp_dist_ubigeo, 1, 2)
keep gdp_department_code
duplicates drop
count
local gdp_department_source_rows = r(N)
assert `gdp_department_source_rows' == 25
restore

egen double __gdp_series_max = ///
    rowmax(gdp_ccpp_1993-gdp_ccpp_2018)
generate byte gdp_ccpp_zero_9318 = __gdp_series_max == 0
drop __gdp_series_max

count if gdp_ccpp_zero_9318
local gdp_ccpp_zero_rows = r(N)
assert `gdp_ccpp_zero_rows' == 12141

label variable gdp_dist_ubigeo ///
    "Six-digit district code in the GDP source"
label variable gdp_ccpp_ubigeo ///
    "Ten-digit CCPP code in the GDP source"
label variable gdp_ccpp_zero_9318 ///
    "Estimated CCPP GDP equals zero in every source year, 1993-2018"

forvalues source_year = 1993/2018 {
    label variable gdp_ccpp_`source_year' ///
        "Estimated CCPP GDP, source units, `source_year'"
}

order ///
    gdp_dist_ubigeo ///
    gdp_ccpp_ubigeo ///
    gdp_source_department ///
    gdp_source_province ///
    gdp_source_district ///
    gdp_source_ccpp ///
    gdp_ccpp_1993-gdp_ccpp_2018 ///
    gdp_ccpp_zero_9318

compress
sort gdp_ccpp_ubigeo
save ///
    "${intermediate_root}/12_ccpp_gdp_1993_2018.dta", ///
    replace
save `gdp_ccpp_source'

/*
District totals are exact sums of the source CCPP estimates. The HHI and
largest-CCPP share use the 2006 source allocation, the final strictly
pre-program year. The source methodology makes these shares effectively
time-invariant because community shares originate in 2007 population.
*/

preserve
keep ///
    gdp_dist_ubigeo ///
    gdp_source_department ///
    gdp_source_province ///
    gdp_source_district
bysort gdp_dist_ubigeo: keep if _n == 1
isid gdp_dist_ubigeo
save `gdp_district_names'
restore

bysort gdp_dist_ubigeo: egen double __gdp_dist_2006 = ///
    total(gdp_ccpp_2006)
assert __gdp_dist_2006 > 0

generate double __gdp_ccpp_share_2006 = ///
    gdp_ccpp_2006 / __gdp_dist_2006
generate double __gdp_ccpp_share_sq_2006 = ///
    __gdp_ccpp_share_2006^2
bysort gdp_dist_ubigeo: egen double __gdp_dist_hhi_2006 = ///
    total(__gdp_ccpp_share_sq_2006)
bysort gdp_dist_ubigeo: egen double __gdp_dist_topshare_2006 = ///
    max(__gdp_ccpp_share_2006)
generate byte __gdp_ccpp_record = 1

collapse ///
    (sum) gdp_ccpp_1993-gdp_ccpp_2018 ///
          gdp_dist_ccpp_count=__gdp_ccpp_record ///
    (firstnm) gdp_dist_hhi_2006=__gdp_dist_hhi_2006 ///
              gdp_dist_topshare_2006=__gdp_dist_topshare_2006, ///
    by(gdp_dist_ubigeo)

forvalues source_year = 1993/2018 {
    rename gdp_ccpp_`source_year' gdp_dist_`source_year'
    label variable gdp_dist_`source_year' ///
        "Estimated district GDP, source units, `source_year'"
}

merge 1:1 gdp_dist_ubigeo using `gdp_district_names', ///
    assert(match) nogen

generate double ihs_gdp_dist_2006 = asinh(gdp_dist_2006)
generate double gdp_dist_aagr_9306 = ///
    (gdp_dist_2006 / gdp_dist_1993)^(1 / 13) - 1

assert !missing(gdp_dist_aagr_9306)
assert inrange(gdp_dist_hhi_2006, 0, 1)
assert inrange(gdp_dist_topshare_2006, 0, 1)
assert gdp_dist_topshare_2006^2 <= gdp_dist_hhi_2006 + 1e-12

label variable gdp_dist_ccpp_count ///
    "Number of source CCPPs in the GDP district"
label variable ihs_gdp_dist_2006 ///
    "Inverse-hyperbolic-sine estimated district GDP, 2006"
label variable gdp_dist_aagr_9306 ///
    "Annualized estimated district GDP growth, 1993-2006"
label variable gdp_dist_hhi_2006 ///
    "HHI of estimated district GDP across source CCPPs, 2006"
label variable gdp_dist_topshare_2006 ///
    "Largest CCPP share of estimated district GDP, 2006"

order ///
    gdp_dist_ubigeo ///
    gdp_source_department ///
    gdp_source_province ///
    gdp_source_district ///
    gdp_dist_ccpp_count ///
    gdp_dist_1993-gdp_dist_2018 ///
    ihs_gdp_dist_2006 ///
    gdp_dist_aagr_9306 ///
    gdp_dist_hhi_2006 ///
    gdp_dist_topshare_2006

compress
sort gdp_dist_ubigeo
isid gdp_dist_ubigeo
save ///
    "${intermediate_root}/13_district_gdp_1993_2018.dta", ///
    replace
save `gdp_district_source'

/*
CCPP linkage is deterministic and source-vintage specific. It never replaces
the verified RUV UBIGEO. Current exact codes have priority, followed by unused
and unique exact 2007 Census or spatial codes, unique exact full paths, and a
unique exact primary name within district after removing only a terminal
parenthetical alias. Candidate codes already assigned to another RUV row are
quarantined by construction. No fuzzy candidate is accepted.
*/

use `gdp_ccpp_source', clear
keep gdp_ccpp_ubigeo
generate byte gdp_code_in_source = 1
save `gdp_ccpp_code_lookup'

use ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    clear
keep ruv_id ubigeo_ccpp
drop if missing(ubigeo_ccpp)
rename ubigeo_ccpp gdp_ccpp_ubigeo
merge m:1 gdp_ccpp_ubigeo using `gdp_ccpp_code_lookup', ///
    keep(match) keepusing(gdp_code_in_source) nogen
drop gdp_code_in_source
generate str40 gdp_ccpp_link_method = "exact_current_ubigeo"
isid ruv_id
isid gdp_ccpp_ubigeo
save `gdp_links'

count
local gdp_exact_current = r(N)
assert `gdp_exact_current' == 4992

foreach candidate_code in ///
    census2007_ubigeo_ccpp ///
    geospatial_ubigeo_ccpp {

    use ///
        "${analysis_data_root}/06_community_registry_geospatial.dta", ///
        clear
    keep ruv_id `candidate_code'
    drop if missing(`candidate_code')
    rename `candidate_code' gdp_ccpp_ubigeo
    merge m:1 gdp_ccpp_ubigeo using `gdp_ccpp_code_lookup', ///
        keep(match) keepusing(gdp_code_in_source) nogen
    drop gdp_code_in_source

    preserve
    use `gdp_links', clear
    keep ruv_id
    save `gdp_accepted_ids', replace
    restore
    merge 1:1 ruv_id using `gdp_accepted_ids', ///
        keep(master) nogen

    preserve
    use `gdp_links', clear
    keep gdp_ccpp_ubigeo
    save `gdp_used_codes', replace
    restore
    merge m:1 gdp_ccpp_ubigeo using `gdp_used_codes', ///
        keep(master) nogen

    bysort gdp_ccpp_ubigeo: keep if _N == 1

    if "`candidate_code'" == "census2007_ubigeo_ccpp" {
        generate str40 gdp_ccpp_link_method = ///
            "exact_census2007_ubigeo"
    }
    else {
        generate str40 gdp_ccpp_link_method = ///
            "exact_geospatial_ubigeo"
    }

    append using `gdp_links'
    isid ruv_id
    isid gdp_ccpp_ubigeo
    save `gdp_links', replace
}

use `gdp_links', clear
count if gdp_ccpp_link_method == "exact_census2007_ubigeo"
local gdp_exact_census2007 = r(N)
assert `gdp_exact_census2007' == 10
count if gdp_ccpp_link_method == "exact_geospatial_ubigeo"
local gdp_exact_geospatial = r(N)
assert `gdp_exact_geospatial' == 0

use `gdp_ccpp_source', clear
victimasrd_normalize_name gdp_source_department, ///
    generate(gdp_department_key)
victimasrd_normalize_name gdp_source_province, ///
    generate(gdp_province_key)
victimasrd_normalize_name gdp_source_district, ///
    generate(gdp_district_key)
victimasrd_normalize_name gdp_source_ccpp, ///
    generate(gdp_ccpp_name_key)
bysort ///
    gdp_department_key ///
    gdp_province_key ///
    gdp_district_key ///
    gdp_ccpp_name_key: ///
    keep if _N == 1
keep ///
    gdp_department_key ///
    gdp_province_key ///
    gdp_district_key ///
    gdp_ccpp_name_key ///
    gdp_ccpp_ubigeo
isid ///
    gdp_department_key ///
    gdp_province_key ///
    gdp_district_key ///
    gdp_ccpp_name_key
save `gdp_ccpp_full_path_lookup'

use ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    clear
keep ///
    ruv_id ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw
victimasrd_normalize_name dpto_victim_raw, ///
    generate(gdp_department_key)
victimasrd_normalize_name prov_victim_raw, ///
    generate(gdp_province_key)
victimasrd_normalize_name dist_victim_raw, ///
    generate(gdp_district_key)
victimasrd_normalize_name ccpp_victim_raw, ///
    generate(gdp_ccpp_name_key)
keep ruv_id gdp_department_key gdp_province_key ///
    gdp_district_key gdp_ccpp_name_key
merge m:1 ///
    gdp_department_key ///
    gdp_province_key ///
    gdp_district_key ///
    gdp_ccpp_name_key ///
    using `gdp_ccpp_full_path_lookup', ///
    keep(match) nogen

preserve
use `gdp_links', clear
keep ruv_id
save `gdp_accepted_ids', replace
restore
merge 1:1 ruv_id using `gdp_accepted_ids', ///
    keep(master) nogen

preserve
use `gdp_links', clear
keep gdp_ccpp_ubigeo
save `gdp_used_codes', replace
restore
merge m:1 gdp_ccpp_ubigeo using `gdp_used_codes', ///
    keep(master) nogen
bysort gdp_ccpp_ubigeo: keep if _N == 1
generate str40 gdp_ccpp_link_method = "unique_exact_full_path"
append using `gdp_links'
isid ruv_id
isid gdp_ccpp_ubigeo
save `gdp_links', replace

count if gdp_ccpp_link_method == "unique_exact_full_path"
local gdp_exact_full_path = r(N)
assert `gdp_exact_full_path' == 2

use `gdp_ccpp_source', clear
generate str244 gdp_source_ccpp_primary = ustrregexra( ///
    gdp_source_ccpp, "\s*\([^()]*\)\s*$", "")
victimasrd_normalize_name gdp_source_ccpp_primary, ///
    generate(gdp_ccpp_primary_key)
bysort gdp_dist_ubigeo gdp_ccpp_primary_key: ///
    keep if _N == 1
keep ///
    gdp_dist_ubigeo ///
    gdp_ccpp_primary_key ///
    gdp_ccpp_ubigeo
isid gdp_dist_ubigeo gdp_ccpp_primary_key
save `gdp_ccpp_primary_name_lookup'

use ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    clear
keep ruv_id ubigeo_dist ccpp_victim_raw
rename ubigeo_dist gdp_dist_ubigeo
generate str244 gdp_ruv_ccpp_primary = ustrregexra( ///
    ccpp_victim_raw, "\s*\([^()]*\)\s*$", "")
victimasrd_normalize_name gdp_ruv_ccpp_primary, ///
    generate(gdp_ccpp_primary_key)
keep ruv_id gdp_dist_ubigeo gdp_ccpp_primary_key
merge m:1 ///
    gdp_dist_ubigeo ///
    gdp_ccpp_primary_key ///
    using `gdp_ccpp_primary_name_lookup', ///
    keep(match) nogen

preserve
use `gdp_links', clear
keep ruv_id
save `gdp_accepted_ids', replace
restore
merge 1:1 ruv_id using `gdp_accepted_ids', ///
    keep(master) nogen

preserve
use `gdp_links', clear
keep gdp_ccpp_ubigeo
save `gdp_used_codes', replace
restore
merge m:1 gdp_ccpp_ubigeo using `gdp_used_codes', ///
    keep(master) nogen
bysort gdp_ccpp_ubigeo: keep if _N == 1
generate str40 gdp_ccpp_link_method = "unique_exact_primary_name"
append using `gdp_links'
keep ruv_id gdp_ccpp_ubigeo gdp_ccpp_link_method
isid ruv_id
isid gdp_ccpp_ubigeo
sort ruv_id
save `gdp_links', replace
save ///
    "${intermediate_root}/14_ruv_ccpp_gdp_links.dta", ///
    replace

count if gdp_ccpp_link_method == "unique_exact_primary_name"
local gdp_exact_primary_name = r(N)
assert `gdp_exact_primary_name' == 17

count
local gdp_ccpp_linked = r(N)
assert `gdp_ccpp_linked' == 5021

merge 1:1 ruv_id using ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    keep(match) keepusing(sample_main_rd) nogen
count if sample_main_rd
local gdp_ccpp_main_linked = r(N)
assert `gdp_ccpp_main_linked' == 1045

preserve
keep if inlist( ///
    gdp_ccpp_link_method, ///
    "unique_exact_full_path", ///
    "unique_exact_primary_name")
count
assert r(N) == 19
merge 1:1 ruv_id using ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    keep(match) ///
    keepusing( ///
        ubigeo_ccpp ///
        census2007_ubigeo_ccpp ///
        geospatial_ubigeo_ccpp ///
        dpto_victim_raw ///
        prov_victim_raw ///
        dist_victim_raw ///
        ccpp_victim_raw) ///
    nogen
merge m:1 gdp_ccpp_ubigeo using `gdp_ccpp_source', ///
    keep(match) ///
    keepusing( ///
        gdp_dist_ubigeo ///
        gdp_source_department ///
        gdp_source_province ///
        gdp_source_district ///
        gdp_source_ccpp) ///
    nogen
generate str52 linkage_disposition = ///
    "accepted_unique_exact_source_vintage_name"
order ///
    ruv_id ///
    sample_main_rd ///
    gdp_ccpp_link_method ///
    gdp_ccpp_ubigeo ///
    gdp_dist_ubigeo ///
    ubigeo_ccpp ///
    census2007_ubigeo_ccpp ///
    geospatial_ubigeo_ccpp ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    gdp_source_department ///
    gdp_source_province ///
    gdp_source_district ///
    gdp_source_ccpp ///
    linkage_disposition
sort ruv_id
save ///
    "${qa_data_root}/gdp_ccpp_exact_name_links.dta", ///
    replace
export delimited ///
    "${qa_data_root}/gdp_ccpp_exact_name_links.csv", ///
    replace
restore

use `gdp_links', clear
merge m:1 gdp_ccpp_ubigeo using `gdp_ccpp_source', ///
    keep(match) ///
    keepusing( ///
        gdp_ccpp_1993 ///
        gdp_ccpp_2006 ///
        gdp_ccpp_zero_9318) ///
    nogen
generate double ihs_gdp_ccpp_2006 = asinh(gdp_ccpp_2006)
label variable ihs_gdp_ccpp_2006 ///
    "Inverse-hyperbolic-sine estimated CCPP GDP, 2006"
isid ruv_id
save `gdp_link_values'

/*
District context remains available even when a CCPP-level link is unresolved.
The linked source-vintage district governs first; otherwise the pipeline uses
an exact current, Census, or spatial district code. A unique exact normalized
district path is the final deterministic pass.
*/

use `gdp_district_source', clear
keep gdp_dist_ubigeo
rename gdp_dist_ubigeo gdp_dist_candidate
generate byte gdp_district_in_source = 1
save `gdp_district_code_lookup'

use `gdp_district_source', clear
victimasrd_normalize_name gdp_source_department, ///
    generate(gdp_department_key)
victimasrd_normalize_name gdp_source_province, ///
    generate(gdp_province_key)
victimasrd_normalize_name gdp_source_district, ///
    generate(gdp_district_key)
bysort gdp_department_key gdp_province_key gdp_district_key: ///
    keep if _N == 1
keep ///
    gdp_department_key ///
    gdp_province_key ///
    gdp_district_key ///
    gdp_dist_ubigeo
rename gdp_dist_ubigeo gdp_dist_name_candidate
isid gdp_department_key gdp_province_key gdp_district_key
save `gdp_district_path_lookup'

use ///
    "${analysis_data_root}/06_community_registry_geospatial.dta", ///
    clear
merge 1:1 ruv_id using `gdp_link_values', ///
    generate(gdp_ccpp_data_merge)
assert inlist(gdp_ccpp_data_merge, 1, 3)
generate byte gdp_ccpp_linked = gdp_ccpp_data_merge == 3
drop gdp_ccpp_data_merge

count if !gdp_ccpp_linked
local gdp_ccpp_unmatched = r(N)
assert `gdp_ccpp_unmatched' == 691

label variable gdp_ccpp_linked ///
    "RUV community linked to the Seminario-Palomino CCPP GDP source"
label variable gdp_ccpp_link_method ///
    "Method linking the RUV row to the CCPP GDP source"
label variable gdp_ccpp_ubigeo ///
    "Ten-digit source-vintage code used for the CCPP GDP link"
label variable gdp_ccpp_1993 ///
    "Estimated CCPP GDP, source units, 1993"
label variable gdp_ccpp_2006 ///
    "Estimated CCPP GDP, source units, 2006"
label variable gdp_ccpp_zero_9318 ///
    "Estimated CCPP GDP equals zero in every source year, 1993-2018"

generate str6 gdp_dist_ubigeo = ///
    substr(gdp_ccpp_ubigeo, 1, 6) if gdp_ccpp_linked
generate str40 gdp_dist_link_method = ///
    "linked_ccpp_source_district" if gdp_ccpp_linked

foreach district_candidate in ///
    ubigeo_dist ///
    census2007_ubigeo_ccpp ///
    geospatial_ubigeo_ccpp {

    if "`district_candidate'" == "ubigeo_dist" {
        generate str6 gdp_dist_candidate = `district_candidate'
        local gdp_district_method "exact_current_district"
    }
    else {
        generate str6 gdp_dist_candidate = ///
            substr(`district_candidate', 1, 6)

        if "`district_candidate'" == "census2007_ubigeo_ccpp" {
            local gdp_district_method "exact_census2007_district"
        }
        else {
            local gdp_district_method "exact_geospatial_district"
        }
    }

    replace gdp_dist_candidate = "" ///
        if strlen(gdp_dist_candidate) != 6
    merge m:1 gdp_dist_candidate using `gdp_district_code_lookup', ///
        keep(master match) keepusing(gdp_district_in_source) nogen
    replace gdp_dist_ubigeo = gdp_dist_candidate ///
        if missing(gdp_dist_ubigeo) & gdp_district_in_source == 1
    replace gdp_dist_link_method = "`gdp_district_method'" ///
        if missing(gdp_dist_link_method) & gdp_district_in_source == 1
    drop gdp_dist_candidate gdp_district_in_source
}

preserve
keep if missing(gdp_dist_ubigeo)
keep ///
    ruv_id ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw
victimasrd_normalize_name dpto_victim_raw, ///
    generate(gdp_department_key)
victimasrd_normalize_name prov_victim_raw, ///
    generate(gdp_province_key)
victimasrd_normalize_name dist_victim_raw, ///
    generate(gdp_district_key)
keep ruv_id gdp_department_key gdp_province_key gdp_district_key
merge m:1 ///
    gdp_department_key ///
    gdp_province_key ///
    gdp_district_key ///
    using `gdp_district_path_lookup', ///
    keep(match) nogen
keep ruv_id gdp_dist_name_candidate
save `gdp_district_name_links'
restore

merge 1:1 ruv_id using `gdp_district_name_links', ///
    keep(master match) nogen
replace gdp_dist_ubigeo = gdp_dist_name_candidate ///
    if missing(gdp_dist_ubigeo) & !missing(gdp_dist_name_candidate)
replace gdp_dist_link_method = "unique_exact_district_path" ///
    if missing(gdp_dist_link_method) & !missing(gdp_dist_name_candidate)
drop gdp_dist_name_candidate

merge m:1 gdp_dist_ubigeo using `gdp_district_source', ///
    keep(master match) ///
    keepusing( ///
        gdp_dist_ccpp_count ///
        gdp_dist_1993 ///
        gdp_dist_2006 ///
        ihs_gdp_dist_2006 ///
        gdp_dist_aagr_9306 ///
        gdp_dist_hhi_2006 ///
        gdp_dist_topshare_2006) ///
    generate(gdp_district_data_merge)
assert inlist(gdp_district_data_merge, 1, 3)
generate byte gdp_dist_linked = gdp_district_data_merge == 3
drop gdp_district_data_merge

count if gdp_dist_linked
local gdp_district_linked = r(N)
assert `gdp_district_linked' == 5695
count if !gdp_dist_linked
local gdp_district_unmatched = r(N)
assert `gdp_district_unmatched' == 17
count if gdp_dist_linked & sample_main_rd
local gdp_district_main_linked = r(N)
assert `gdp_district_main_linked' == 1162

label variable gdp_dist_linked ///
    "RUV row linked to a district in the CCPP GDP source"
label variable gdp_dist_link_method ///
    "Method linking the RUV row to the GDP-source district"
label variable gdp_dist_ubigeo ///
    "Six-digit source-vintage district code for GDP measures"
label variable gdp_dist_ccpp_count ///
    "Number of source CCPPs in the GDP district"
label variable gdp_dist_1993 ///
    "Estimated district GDP, source units, 1993"
label variable gdp_dist_2006 ///
    "Estimated district GDP, source units, 2006"
label variable ihs_gdp_dist_2006 ///
    "Inverse-hyperbolic-sine estimated district GDP, 2006"
label variable gdp_dist_aagr_9306 ///
    "Annualized estimated district GDP growth, 1993-2006"
label variable gdp_dist_hhi_2006 ///
    "HHI of estimated district GDP across source CCPPs, 2006"
label variable gdp_dist_topshare_2006 ///
    "Largest CCPP share of estimated district GDP, 2006"

preserve
keep if !gdp_ccpp_linked
keep ///
    ruv_id ///
    ubigeo_dist ///
    ubigeo_ccpp ///
    census2007_ubigeo_ccpp ///
    geospatial_ubigeo_ccpp ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    sample_main_rd
generate str52 linkage_disposition = ///
    "retained_without_verified_ccpp_gdp_link"
save ///
    "${qa_data_root}/gdp_ccpp_unmatched_ruv.dta", ///
    replace
export delimited ///
    "${qa_data_root}/gdp_ccpp_unmatched_ruv.csv", ///
    replace
restore

preserve
keep if !gdp_dist_linked
keep ///
    ruv_id ///
    ubigeo_dist ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    sample_main_rd
generate str52 linkage_disposition = ///
    "retained_without_verified_district_gdp_link"
save ///
    "${qa_data_root}/gdp_district_unmatched_ruv.dta", ///
    replace
export delimited ///
    "${qa_data_root}/gdp_district_unmatched_ruv.csv", ///
    replace
restore

local gdp_release_vars ///
    gdp_ccpp_linked ///
    gdp_ccpp_link_method ///
    gdp_ccpp_ubigeo ///
    gdp_ccpp_1993 ///
    gdp_ccpp_2006 ///
    ihs_gdp_ccpp_2006 ///
    gdp_ccpp_zero_9318 ///
    gdp_dist_linked ///
    gdp_dist_link_method ///
    gdp_dist_ubigeo ///
    gdp_dist_ccpp_count ///
    gdp_dist_1993 ///
    gdp_dist_2006 ///
    ihs_gdp_dist_2006 ///
    gdp_dist_aagr_9306 ///
    gdp_dist_hhi_2006 ///
    gdp_dist_topshare_2006

order `gdp_release_vars', after(ln1p_dist_nearest_city)

compress
sort ruv_id
isid ruv_id
count
local gdp_registry_rows = r(N)
assert `gdp_registry_rows' == `geospatial_registry_rows'
assert `gdp_registry_rows' == 5712

save ///
    "${analysis_data_root}/07_community_registry_gdp.dta", ///
    replace


*===============================================================================
**# 11. Municipal elections, local political context, and RUV linkage
*===============================================================================

/*
JNE/INFOgob supplies the candidate, result, electorate, elected-authority,
political-system, and local-political-factor modules. Proclaimed authorities
resolve plurality ties. ONPE mesa returns independently validate the 2006
ordinary results and supply the 2003/2007 complementary-election replacements.

The municipal jurisdiction governing a province-capital district is the
provincial municipality; other districts use the district contest. Barranca
in 2002 is treated as a district contest because Datem del Maranon had not yet
been created. Manantay is linked to its predecessor Calleria municipality in
both cycles because it held no ordinary 2002 or 2006 municipal election.
*/

local election_root "${raw_root}/6 ONPE"
local election_official_stage ///
    "${staging_root}/official_elections_1998_2006"
local election_crosswalk ///
    "`election_root'/Official municipal electoral sources 1998-2006/17_reniec_inei_ubigeo_crosswalk/TB_UBIGEOS.csv"
local election_emc_2003 ///
    "`election_root'/Resultados por mesa  de las EMC2003 Distrital.csv"
local election_emc_2007 ///
    "`election_root'/Resultados por mesa EMC2007.csv"
local election_onpe_2002_district ///
    "`election_root'/Official municipal electoral sources 1998-2006/05_2002_municipal_district/ERM2002_Municipal_Distrital.csv"
local election_onpe_2002_province ///
    "`election_root'/Official municipal electoral sources 1998-2006/06_2002_municipal_provincial/ERM2002_Municipal_Provincial.csv"
local election_onpe_2006_district ///
    "`election_official_stage'/13_2006_municipal_district/ERM2006_Municipal_Distrital.csv"
local election_onpe_2006_province ///
    "`election_official_stage'/14_2006_municipal_provincial/ERM2006_Municipal_Provincial.csv"

capture label drop municipal_org_type
label define municipal_org_type ///
    1 "National party" ///
    2 "Electoral alliance" ///
    3 "Regional movement" ///
    4 "Local political organization"

foreach election_file in ///
    "`election_crosswalk'" ///
    "`election_emc_2003'" ///
    "`election_emc_2007'" ///
    "`election_onpe_2002_district'" ///
    "`election_onpe_2002_province'" ///
    "`election_onpe_2006_district'" ///
    "`election_onpe_2006_province'" {

    capture confirm file "`election_file'"
    if _rc {
        display as error "Required electoral source is unavailable:"
        display as error "  `election_file'"
        exit 601
    }
}

foreach election_year in 2002 2006 {
    foreach election_scope in Distrital Provincial {
        local election_directory = upper("`election_scope'")

        foreach election_module in ///
            Autoridades ///
            Candidatos ///
            FPL ///
            ISP ///
            Padron ///
            Resultados {

            local election_file ///
                "`election_root'/MUNICIPAL `election_directory' `election_year'/ERM`election_year'_`election_module'_`election_scope'.xlsx"
            capture confirm file "`election_file'"
            if _rc {
                display as error "Required INFOgob module is unavailable:"
                display as error "  `election_file'"
                exit 601
            }
        }
    }
}

tempfile ///
    election_code_bridge ///
    election_province_bridge ///
    election_name_bridge ///
    election_comp_2002 ///
    election_comp_2006 ///
    election_cycle_2002 ///
    election_cycle_2006

import delimited ///
    "`election_crosswalk'", ///
    clear ///
    varnames(1) ///
    encoding(utf8) ///
    stringcols(_all)

assert _N == 1893
keep ///
    ubigeo_reniec ///
    ubigeo_inei ///
    departamento ///
    provincia ///
    distrito
drop if missing(ubigeo_reniec) | missing(ubigeo_inei)
rename ///
    (ubigeo_reniec ubigeo_inei) ///
    (reniec_code ubigeo_dist)
assert ustrregexm(reniec_code, "^[0-9]{6}$")
assert ustrregexm(ubigeo_dist, "^[0-9]{6}$")
isid reniec_code

preserve
keep reniec_code ubigeo_dist
save `election_code_bridge', replace
restore

preserve
generate str6 reniec_province = substr(reniec_code, 1, 4) + "00"
generate str4 inei_province = substr(ubigeo_dist, 1, 4)
keep reniec_province inei_province
duplicates drop
isid reniec_province
rename reniec_province reniec_code
save `election_province_bridge', replace
restore

victimasrd_normalize_name departamento, generate(elect_dep_key)
victimasrd_normalize_name provincia, generate(elect_prov_key)
victimasrd_normalize_name distrito, generate(elect_dist_key)
keep ///
    ubigeo_dist ///
    elect_dep_key ///
    elect_prov_key ///
    elect_dist_key
isid ubigeo_dist
isid elect_dep_key elect_prov_key elect_dist_key
save `election_name_bridge', replace

/*
Convert each complementary election from mesa-by-list returns to one district
record. Mesa totals are counted once; party votes remain list-specific until
the contest statistics and winning organization are calculated.
*/

foreach result_year in 2003 2007 {
    local election_cycle = `result_year' - 1
    if `result_year' == 2003 {
        local complementary_file "`election_emc_2003'"
    }
    else {
        local complementary_file "`election_emc_2007'"
    }

    import delimited ///
        "`complementary_file'", ///
        clear ///
        varnames(1) ///
        encoding(utf8)

    tostring ubigeo, generate(reniec_code) format(%06.0f)
    merge m:1 reniec_code using `election_code_bridge', ///
        keep(master match) ///
        generate(_merge_election_code)
    assert _merge_election_code == 3
    drop _merge_election_code

    tempfile complementary_turnout
    preserve
    bysort ubigeo_dist mesa: keep if _n == 1
    collapse ///
        (sum) elect_registered = electores_habiles ///
        (sum) comp_blank = votos_blancos ///
        (sum) comp_null = votos_nulos ///
        (sum) comp_challenged = votos_impug, ///
        by(ubigeo_dist)
    save `complementary_turnout', replace
    restore

    collapse ///
        (sum) list_votes = votos_obtenidos, ///
        by(ubigeo_dist agrupacion_politica tipo_agrupacion)
    merge m:1 ubigeo_dist using `complementary_turnout', ///
        assert(match) ///
        nogen

    bysort ubigeo_dist: egen double comp_valid_votes = ///
        total(list_votes)
    generate double list_share = ///
        list_votes / comp_valid_votes
    generate double list_share_sq = list_share^2
    bysort ubigeo_dist: egen double elect_hhi = ///
        total(list_share_sq)
    generate double elect_nep = 1 / elect_hhi
    bysort ubigeo_dist: egen long top_votes = max(list_votes)
    bysort ubigeo_dist: egen byte top_ties = ///
        total(list_votes == top_votes)
    assert top_ties == 1

    gsort ubigeo_dist -list_votes agrupacion_politica
    by ubigeo_dist: generate double elect_runner_share = ///
        list_share[2]
    by ubigeo_dist: generate double elect_top2_share = ///
        list_share[1] + list_share[2]
    by ubigeo_dist: generate int elect_candidate_count = _N
    by ubigeo_dist: keep if _n == 1

    generate long comp_ballots = ///
        comp_valid_votes + comp_blank + comp_null + comp_challenged
    generate double elect_turnout = ///
        comp_ballots / elect_registered
    generate double elect_invalid_share = ///
        (comp_blank + comp_null + comp_challenged) / comp_ballots
    generate double elect_winner_share = list_share
    generate double elect_margin = ///
        elect_winner_share - elect_runner_share
    generate str90 elect_winner_org = agrupacion_politica
    generate str32 elect_winner_type_raw = tipo_agrupacion
    generate int elect_result_year = `result_year'

    keep ///
        ubigeo_dist ///
        elect_result_year ///
        elect_registered ///
        elect_turnout ///
        elect_invalid_share ///
        elect_winner_share ///
        elect_runner_share ///
        elect_margin ///
        elect_hhi ///
        elect_nep ///
        elect_top2_share ///
        elect_candidate_count ///
        elect_winner_org ///
        elect_winner_type_raw
    isid ubigeo_dist
    count
    local emc_`election_cycle'_contests = r(N)

    foreach complementary_variable in ///
        elect_result_year ///
        elect_registered ///
        elect_turnout ///
        elect_invalid_share ///
        elect_winner_share ///
        elect_runner_share ///
        elect_margin ///
        elect_hhi ///
        elect_nep ///
        elect_top2_share ///
        elect_candidate_count ///
        elect_winner_org ///
        elect_winner_type_raw {
        rename `complementary_variable' comp_`complementary_variable'
    }

    if `election_cycle' == 2002 {
        save `election_comp_2002', replace
    }
    else {
        save `election_comp_2006', replace
    }
}


/*
Build one clean contest file per election cycle. The loop uses the same
construction contract for district and provincial contests while respecting
their different workbook layouts and municipal jurisdictions.
*/

foreach election_year in 2002 2006 {
    tempfile election_cycle_work
    local first_election_scope = 1

    foreach scope_key in district province {
        local scope_suffix = cond( ///
            "`scope_key'" == "district", ///
            "Distrital", ///
            "Provincial")
        local scope_directory = upper("`scope_suffix'")
        local election_prefix ///
            "`election_root'/MUNICIPAL `scope_directory' `election_year'/ERM`election_year'_"

        tempfile ///
            election_isp ///
            election_contest_lookup ///
            election_result_metrics ///
            election_authority ///
            election_candidate_orgs ///
            election_candidate_stats ///
            election_padron ///
            election_fpl

        * INFOgob political-system indicators also provide the RENIEC code key.
        import excel ///
            "`election_prefix'ISP_`scope_suffix'.xlsx", ///
            sheet("Hoja1") ///
            clear ///
            allstring

        if "`scope_key'" == "district" {
            rename (A B C D) ///
                (reniec_code source_department source_province source_district)
        }
        else {
            rename (A B C) ///
                (reniec_code source_department source_province)
        }
        keep if ustrregexm(reniec_code, "^[0-9]{6}$")

        if "`scope_key'" == "district" & `election_year' == 2002 {
            rename ///
                (E H I J) ///
                (isp_nep isp_top2_share isp_hhi isp_margin)
            generate double isp_volatility = .
        }
        if "`scope_key'" == "province" & `election_year' == 2002 {
            rename ///
                (D G H I) ///
                (isp_nep isp_top2_share isp_hhi isp_margin)
            generate double isp_volatility = .
        }
        if "`scope_key'" == "district" & `election_year' == 2006 {
            rename ///
                (E H I J K) ///
                (isp_nep isp_volatility isp_top2_share isp_hhi isp_margin)
        }
        if "`scope_key'" == "province" & `election_year' == 2006 {
            rename ///
                (D G H I J) ///
                (isp_nep isp_volatility isp_top2_share isp_hhi isp_margin)
        }

        foreach isp_variable in ///
            isp_nep ///
            isp_volatility ///
            isp_top2_share ///
            isp_hhi ///
            isp_margin {
            destring `isp_variable', replace force
        }

        victimasrd_normalize_name ///
            source_department, ///
            generate(map_dep_key)
        victimasrd_normalize_name ///
            source_province, ///
            generate(map_prov_key)

        if "`scope_key'" == "district" {
            victimasrd_normalize_name ///
                source_district, ///
                generate(map_dist_key)
            merge m:1 reniec_code using `election_code_bridge', ///
                keep(master match) ///
                generate(_merge_election_code)
            assert _merge_election_code == 3
            drop _merge_election_code
            keep ///
                map_dep_key ///
                map_prov_key ///
                map_dist_key ///
                reniec_code ///
                ubigeo_dist ///
                isp_*
            isid map_dep_key map_prov_key map_dist_key
        }
        else {
            merge m:1 reniec_code using `election_province_bridge', ///
                keep(master match) ///
                generate(_merge_election_code)
            assert _merge_election_code == 3
            drop _merge_election_code
            generate str6 ubigeo_dist = inei_province + "01"
            keep ///
                map_dep_key ///
                map_prov_key ///
                reniec_code ///
                ubigeo_dist ///
                isp_*
            isid map_dep_key map_prov_key
        }
        isid ubigeo_dist
        save `election_isp', replace

        * List-level results determine participation and competition measures.
        import excel ///
            "`election_prefix'Resultados_`scope_suffix'.xlsx", ///
            sheet("Sheet 1") ///
            firstrow ///
            clear
        unab raw_result_variables : _all

        if "`scope_key'" == "district" {
            rename (`raw_result_variables') ///
                (source_department ///
                 source_province ///
                 source_district ///
                 source_registered ///
                 source_turnout ///
                 source_ballots ///
                 source_valid_votes ///
                 source_organization ///
                 source_org_type ///
                 source_votes ///
                 source_vote_share)
        }
        else {
            rename (`raw_result_variables') ///
                (source_department ///
                 source_province ///
                 source_registered ///
                 source_turnout ///
                 source_ballots ///
                 source_valid_votes ///
                 source_organization ///
                 source_org_type ///
                 source_votes ///
                 source_vote_share)
        }

        foreach numeric_result in ///
            source_registered ///
            source_turnout ///
            source_ballots ///
            source_valid_votes ///
            source_votes ///
            source_vote_share {
            capture confirm numeric variable `numeric_result'
            if _rc {
                destring `numeric_result', replace ignore(",%") force
            }
        }

        victimasrd_normalize_name ///
            source_department, ///
            generate(join_dep_key)
        victimasrd_normalize_name ///
            source_province, ///
            generate(join_prov_key)
        clonevar map_dep_key = join_dep_key
        clonevar map_prov_key = join_prov_key
        generate str40 contest_code_method = ///
            "infogob_name_to_official_code"

        if "`scope_key'" == "district" {
            victimasrd_normalize_name ///
                source_district, ///
                generate(join_dist_key)
            clonevar map_dist_key = join_dist_key

            replace contest_code_method = "documented_name_alias" if ///
                (map_dep_key == "ANCASH" & ///
                 map_prov_key == "HUARAZ" & ///
                 map_dist_key == "PAMPAS") | ///
                (map_dep_key == "APURIMAC" & ///
                 map_prov_key == "AYMARAES" & ///
                 map_dist_key == "IHUAYLLO") | ///
                (map_dep_key == "LIMA" & ///
                 map_prov_key == "HUAROCHIRI" & ///
                 inlist(map_dist_key, "CUENCA", "SAN PEDRO DE CASTA"))

            replace map_dist_key = "PAMPAS GRANDE" if ///
                map_dep_key == "ANCASH" & ///
                map_prov_key == "HUARAZ" & ///
                map_dist_key == "PAMPAS"
            replace map_dist_key = "HUAYLLO" if ///
                map_dep_key == "APURIMAC" & ///
                map_prov_key == "AYMARAES" & ///
                map_dist_key == "IHUAYLLO"
            replace map_dist_key = ///
                "SAN JOSE DE LOS CHORRILLOS CUENCA" if ///
                map_dep_key == "LIMA" & ///
                map_prov_key == "HUAROCHIRI" & ///
                map_dist_key == "CUENCA"
            replace map_dist_key = ///
                "CASTA SAN PEDRO DE CASTA" if ///
                map_dep_key == "LIMA" & ///
                map_prov_key == "HUAROCHIRI" & ///
                map_dist_key == "SAN PEDRO DE CASTA"

            replace contest_code_method = ///
                "historical_province_reassignment" if ///
                `election_year' == 2002 & ///
                map_dep_key == "LORETO" & ///
                map_prov_key == "ALTO AMAZONAS" & ///
                inlist( ///
                    map_dist_key, ///
                    "BARRANCA", ///
                    "CAHUAPANAS", ///
                    "MANSERICHE", ///
                    "MORONA", ///
                    "PASTAZA")
            replace map_prov_key = "DATEM DEL MARANON" if ///
                contest_code_method == ///
                    "historical_province_reassignment"

            merge m:1 ///
                map_dep_key ///
                map_prov_key ///
                map_dist_key ///
                using `election_isp', ///
                keep(master match) ///
                generate(_merge_isp)

            replace ubigeo_dist = "160701" if ///
                `election_year' == 2002 & ///
                map_dep_key == "LORETO" & ///
                map_prov_key == "DATEM DEL MARANON" & ///
                map_dist_key == "BARRANCA" & ///
                _merge_isp == 1
            replace contest_code_method = ///
                "official_crosswalk_historical_code" if ///
                `election_year' == 2002 & ///
                map_dep_key == "LORETO" & ///
                map_prov_key == "DATEM DEL MARANON" & ///
                map_dist_key == "BARRANCA"
            assert _merge_isp == 3 | ///
                (`election_year' == 2002 & ubigeo_dist == "160701")
        }
        else {
            merge m:1 ///
                map_dep_key ///
                map_prov_key ///
                using `election_isp', ///
                keep(master match) ///
                generate(_merge_isp)
            assert _merge_isp == 3
        }
        drop _merge_isp

        merge m:1 ubigeo_dist using `election_name_bridge', ///
            generate(_merge_election_name_bridge)
        assert _merge_election_name_bridge != 1
        keep if _merge_election_name_bridge == 3
        drop _merge_election_name_bridge

        preserve
        if "`scope_key'" == "district" {
            keep ///
                join_dep_key ///
                join_prov_key ///
                join_dist_key ///
                ubigeo_dist ///
                elect_dep_key ///
                elect_prov_key ///
                elect_dist_key ///
                contest_code_method
            duplicates drop
            isid join_dep_key join_prov_key join_dist_key
        }
        else {
            keep ///
                join_dep_key ///
                join_prov_key ///
                ubigeo_dist ///
                elect_dep_key ///
                elect_prov_key ///
                elect_dist_key ///
                contest_code_method
            duplicates drop
            isid join_dep_key join_prov_key
        }
        save `election_contest_lookup', replace
        restore

        generate byte valid_organization_row = ///
            ustrtrim(source_org_type) != ""
        bysort ubigeo_dist: egen double result_invalid_sum = ///
            total(cond(!valid_organization_row, source_votes, 0))
        assert abs( ///
            result_invalid_sum - ///
            (source_ballots - source_valid_votes)) < .5
        keep if valid_organization_row

        bysort ubigeo_dist: egen double result_valid_sum = ///
            total(source_votes)
        assert abs(result_valid_sum - source_valid_votes) < .5
        generate double computed_list_share = ///
            source_votes / source_valid_votes
        assert abs(computed_list_share - source_vote_share) < .0002 if ///
            source_valid_votes > 0 & !missing(source_vote_share)
        generate double computed_share_sq = computed_list_share^2
        bysort ubigeo_dist: egen double elect_hhi = ///
            total(computed_share_sq)
        generate double elect_nep = 1 / elect_hhi
        bysort ubigeo_dist: egen long result_top_votes = ///
            max(source_votes)
        bysort ubigeo_dist: egen byte result_top_ties = ///
            total(source_votes == result_top_votes)

        gsort ubigeo_dist -source_votes source_organization
        by ubigeo_dist: generate double elect_runner_share = ///
            computed_list_share[2]
        by ubigeo_dist: generate double elect_top2_share = ///
            computed_list_share[1] + computed_list_share[2]
        by ubigeo_dist: generate int elect_candidate_count = _N
        by ubigeo_dist: keep if _n == 1

        generate double elect_registered = source_registered
        generate double elect_turnout = ///
            source_ballots / source_registered
        generate double elect_invalid_share = ///
            (source_ballots - source_valid_votes) / source_ballots
        generate double elect_winner_share = computed_list_share
        generate double elect_margin = ///
            elect_winner_share - elect_runner_share
        generate str90 plurality_org = source_organization
        generate str32 plurality_type = source_org_type
        generate str10 elect_scope = "`scope_key'"
        generate int elect_result_year = `election_year'

        keep ///
            ubigeo_dist ///
            elect_dep_key ///
            elect_prov_key ///
            elect_dist_key ///
            contest_code_method ///
            elect_scope ///
            elect_result_year ///
            elect_registered ///
            elect_turnout ///
            elect_invalid_share ///
            elect_winner_share ///
            elect_runner_share ///
            elect_margin ///
            elect_hhi ///
            elect_nep ///
            elect_top2_share ///
            elect_candidate_count ///
            result_top_votes ///
            result_top_ties ///
            plurality_org ///
            plurality_type ///
            isp_*
        isid ubigeo_dist
        count
        local election_`election_year'_`scope_key'_contests = r(N)
        save `election_result_metrics', replace

        * Elected mayors are the authoritative winner source, including ties.
        import excel ///
            "`election_prefix'Autoridades_`scope_suffix'.xlsx", ///
            sheet("Sheet 1") ///
            firstrow ///
            clear
        unab raw_authority_variables : _all

        if "`scope_key'" == "district" {
            rename (`raw_authority_variables') ///
                (source_department ///
                 source_province ///
                 source_district ///
                 elected_office ///
                 surname_1 ///
                 surname_2 ///
                 given_names ///
                 elect_winner_org ///
                 elect_winner_type_raw ///
                 mayor_sex ///
                 mayor_young_raw ///
                 mayor_native_raw ///
                 authority_votes ///
                 authority_vote_share)
        }
        else {
            rename (`raw_authority_variables') ///
                (source_department ///
                 source_province ///
                 elected_office ///
                 surname_1 ///
                 surname_2 ///
                 given_names ///
                 elect_winner_org ///
                 elect_winner_type_raw ///
                 mayor_sex ///
                 mayor_young_raw ///
                 mayor_native_raw ///
                 authority_votes ///
                 authority_vote_share)
        }
        keep if ustrupper(elected_office) == ///
            ustrupper("ALCALDE `scope_suffix'")

        victimasrd_normalize_name ///
            source_department, ///
            generate(join_dep_key)
        victimasrd_normalize_name ///
            source_province, ///
            generate(join_prov_key)

        if "`scope_key'" == "district" {
            victimasrd_normalize_name ///
                source_district, ///
                generate(join_dist_key)
            merge m:1 ///
                join_dep_key ///
                join_prov_key ///
                join_dist_key ///
                using `election_contest_lookup', ///
                keep(master match) ///
                generate(_merge_authority_code)
        }
        else {
            merge m:1 ///
                join_dep_key ///
                join_prov_key ///
                using `election_contest_lookup', ///
                keep(master match) ///
                generate(_merge_authority_code)
        }
        assert _merge_authority_code == 3
        drop _merge_authority_code

        victimasrd_normalize_name ///
            elect_winner_org, ///
            generate(winner_org_key)
        generate byte mayor_female = ///
            ustrupper(ustrtrim(mayor_sex)) == "FEMENINO"
        generate byte mayor_young = ///
            ustrtrim(mayor_young_raw) != ""

        keep ///
            ubigeo_dist ///
            elect_winner_org ///
            elect_winner_type_raw ///
            winner_org_key ///
            mayor_female ///
            mayor_young ///
            authority_votes ///
            authority_vote_share
        isid ubigeo_dist
        count
        local election_`election_year'_`scope_key'_mayors = r(N)
        save `election_authority', replace

        * Candidate rosters yield transparent representation measures.
        import excel ///
            "`election_prefix'Candidatos_`scope_suffix'.xlsx", ///
            sheet("Sheet 1") ///
            firstrow ///
            clear
        unab raw_candidate_variables : _all

        if "`scope_key'" == "district" {
            rename (`raw_candidate_variables') ///
                (source_department ///
                 source_province ///
                 source_district ///
                 candidate_org ///
                 candidate_org_type ///
                 candidate_office ///
                 candidate_position ///
                 surname_1 ///
                 surname_2 ///
                 given_names ///
                 candidate_sex ///
                 candidate_young_raw ///
                 candidate_native_raw)
        }
        else {
            rename (`raw_candidate_variables') ///
                (source_department ///
                 source_province ///
                 candidate_org ///
                 candidate_org_type ///
                 candidate_office ///
                 candidate_position ///
                 surname_1 ///
                 surname_2 ///
                 given_names ///
                 candidate_sex ///
                 candidate_young_raw ///
                 candidate_native_raw)
        }
        keep if ustrupper(candidate_office) == ///
            ustrupper("ALCALDE `scope_suffix'")

        victimasrd_normalize_name ///
            source_department, ///
            generate(join_dep_key)
        victimasrd_normalize_name ///
            source_province, ///
            generate(join_prov_key)

        if "`scope_key'" == "district" {
            victimasrd_normalize_name ///
                source_district, ///
                generate(join_dist_key)
            merge m:1 ///
                join_dep_key ///
                join_prov_key ///
                join_dist_key ///
                using `election_contest_lookup', ///
                keep(master match) ///
                generate(_merge_candidate_code)
        }
        else {
            merge m:1 ///
                join_dep_key ///
                join_prov_key ///
                using `election_contest_lookup', ///
                keep(master match) ///
                generate(_merge_candidate_code)
        }
        assert _merge_candidate_code == 3
        drop _merge_candidate_code

        victimasrd_normalize_name ///
            candidate_org, ///
            generate(candidate_org_key)
        generate byte candidate_female = ///
            ustrupper(ustrtrim(candidate_sex)) == "FEMENINO"
        generate byte candidate_young = ///
            ustrtrim(candidate_young_raw) != ""

        preserve
        keep ubigeo_dist candidate_org_key
        duplicates drop
        rename candidate_org_key winner_org_key
        isid ubigeo_dist winner_org_key
        save `election_candidate_orgs', replace
        restore

        generate byte candidate_record = 1
        collapse ///
            (sum) candidate_roster_count = candidate_record ///
            (mean) elect_candidate_female = candidate_female ///
            (mean) elect_candidate_young = candidate_young, ///
            by(ubigeo_dist)
        isid ubigeo_dist
        save `election_candidate_stats', replace

        preserve
        use `election_authority', clear
        merge 1:1 ///
            ubigeo_dist ///
            winner_org_key ///
            using `election_candidate_orgs', ///
            keep(master match) ///
            generate(_merge_authority_candidate)
        count if _merge_authority_candidate == 1
        local authority_candidate_unmatched = r(N)
        local elect_`election_year'_`scope_key'_authmiss = ///
            `authority_candidate_unmatched'
        restore

        * Electorate composition comes from the district-level register rows.
        import excel ///
            "`election_prefix'Padron_`scope_suffix'.xlsx", ///
            sheet("Sheet 1") ///
            firstrow ///
            clear
        unab raw_padron_variables : _all
        rename (`raw_padron_variables') ///
            (source_department ///
             source_province ///
             source_district ///
             padron_registered ///
             padron_male ///
             padron_male_share_raw ///
             padron_female ///
             padron_female_share_raw ///
             padron_young ///
             padron_young_share_raw ///
             padron_senior ///
             padron_senior_share_raw)

        foreach padron_count in ///
            padron_registered ///
            padron_male ///
            padron_female ///
            padron_young ///
            padron_senior {
            capture confirm numeric variable `padron_count'
            if _rc {
                destring `padron_count', replace ignore(",") force
            }
        }

        victimasrd_normalize_name ///
            source_department, ///
            generate(join_dep_key)
        victimasrd_normalize_name ///
            source_province, ///
            generate(join_prov_key)

        if "`scope_key'" == "district" {
            victimasrd_normalize_name ///
                source_district, ///
                generate(join_dist_key)
            merge m:1 ///
                join_dep_key ///
                join_prov_key ///
                join_dist_key ///
                using `election_contest_lookup', ///
                keep(match) ///
                nogen
            collapse ///
                (sum) padron_registered ///
                (sum) padron_female ///
                (sum) padron_young ///
                (sum) padron_senior, ///
                by(ubigeo_dist)
        }
        else {
            collapse ///
                (sum) padron_registered ///
                (sum) padron_female ///
                (sum) padron_young ///
                (sum) padron_senior, ///
                by(join_dep_key join_prov_key)
            merge 1:1 ///
                join_dep_key ///
                join_prov_key ///
                using `election_contest_lookup', ///
                keep(match) ///
                nogen
        }

        generate double elect_voter_female = ///
            padron_female / padron_registered
        generate double elect_voter_young = ///
            padron_young / padron_registered
        generate double elect_voter_senior = ///
            padron_senior / padron_registered
        keep ///
            ubigeo_dist ///
            elect_voter_female ///
            elect_voter_young ///
            elect_voter_senior
        isid ubigeo_dist
        save `election_padron', replace

        * Local-political factors are retained in Working; only pre-treatment
        * fields enter the final RUV analytical registry.
        import excel ///
            "`election_prefix'FPL_`scope_suffix'.xlsx", ///
            sheet("Hoja1") ///
            clear ///
            allstring

        if "`scope_key'" == "district" {
            rename (A B C D) ///
                (reniec_code source_department source_province source_district)
            rename ///
                (E F G H I L M) ///
                (fpl_vacancies ///
                 fpl_recall_processes ///
                 fpl_recalled_authorities ///
                 fpl_nullified ///
                 fpl_list_count ///
                 fpl_ccl_early ///
                 fpl_ccl_late)

            if `election_year' == 2002 {
                rename ///
                    (J K) ///
                    (fpl_council_female fpl_council_young)
            }
            else {
                rename ///
                    (J K) ///
                    (fpl_council_young fpl_council_female)
            }
        }
        else {
            rename (A B C) ///
                (reniec_code source_department source_province)
            rename ///
                (D E F G H I J K L) ///
                (fpl_vacancies ///
                 fpl_recall_processes ///
                 fpl_recalled_authorities ///
                 fpl_nullified ///
                 fpl_list_count ///
                 fpl_council_female ///
                 fpl_council_young ///
                 fpl_ccl_early ///
                 fpl_ccl_late)
        }
        keep if ustrregexm(reniec_code, "^[0-9]{6}$")

        foreach fpl_variable in ///
            fpl_vacancies ///
            fpl_recall_processes ///
            fpl_recalled_authorities ///
            fpl_nullified ///
            fpl_list_count ///
            fpl_council_female ///
            fpl_council_young ///
            fpl_ccl_early ///
            fpl_ccl_late {
            destring `fpl_variable', replace force
        }

        if "`scope_key'" == "district" {
            merge m:1 reniec_code using `election_code_bridge', ///
                keep(master match) ///
                generate(_merge_fpl_code)
            assert _merge_fpl_code == 3
            drop _merge_fpl_code
        }
        else {
            merge m:1 reniec_code using `election_province_bridge', ///
                keep(master match) ///
                generate(_merge_fpl_code)
            assert _merge_fpl_code == 3
            drop _merge_fpl_code
            generate str6 ubigeo_dist = inei_province + "01"
        }

        keep ///
            ubigeo_dist ///
            fpl_*
        isid ubigeo_dist
        save `election_fpl', replace

        * Reconcile the modules and replace annulled contests with EMC returns.
        use `election_result_metrics', clear
        merge 1:1 ubigeo_dist using `election_authority', ///
            keep(master match) ///
            generate(_merge_authority)
        assert _merge_authority != 2
        merge 1:1 ubigeo_dist using `election_candidate_stats', ///
            assert(match) ///
            nogen
        merge 1:1 ubigeo_dist using `election_padron', ///
            keep(master match) ///
            generate(_merge_padron)
        assert _merge_padron != 2
        drop _merge_padron
        merge 1:1 ubigeo_dist using `election_fpl', ///
            keep(master match) ///
            generate(_merge_fpl)
        assert _merge_fpl != 2
        drop _merge_fpl

        victimasrd_normalize_name ///
            plurality_org, ///
            generate(plurality_org_key)
        assert authority_votes == result_top_votes if ///
            _merge_authority == 3
        assert winner_org_key == plurality_org_key | ///
            result_top_ties > 1 if _merge_authority == 3

        if `election_year' == 2002 {
            merge 1:1 ubigeo_dist using `election_comp_2002', ///
                keep(master match) ///
                generate(_merge_complementary)
        }
        else {
            merge 1:1 ubigeo_dist using `election_comp_2006', ///
                keep(master match) ///
                generate(_merge_complementary)
        }

        generate byte elect_complementary = ///
            _merge_complementary == 3
        assert _merge_authority == 1 if elect_complementary
        assert _merge_authority == 3 if !elect_complementary
        assert fpl_nullified > 0 if elect_complementary

        foreach result_variable in ///
            elect_result_year ///
            elect_registered ///
            elect_turnout ///
            elect_invalid_share ///
            elect_winner_share ///
            elect_runner_share ///
            elect_margin ///
            elect_hhi ///
            elect_nep ///
            elect_top2_share ///
            elect_candidate_count ///
            elect_winner_org ///
            elect_winner_type_raw {
            replace `result_variable' = ///
                comp_`result_variable' if elect_complementary
            drop comp_`result_variable'
        }

        replace mayor_female = . if elect_complementary
        replace mayor_young = . if elect_complementary
        replace elect_candidate_female = . if elect_complementary
        replace elect_candidate_young = . if elect_complementary
        replace isp_volatility = . if elect_complementary

        victimasrd_normalize_name ///
            elect_winner_org, ///
            generate(elect_winner_org_key)
        victimasrd_normalize_name ///
            elect_winner_type_raw, ///
            generate(elect_winner_type_key)
        generate str20 elect_winner_type = ""
        replace elect_winner_type = "electoral_alliance" if ///
            strpos(elect_winner_type_key, "ALIANZA")
        replace elect_winner_type = "regional_movement" if ///
            elect_winner_type == "" & ///
            (strpos(elect_winner_type_key, "MOVIMIENTO") | ///
             elect_winner_type_key == "REGIONAL")
        replace elect_winner_type = "local_organization" if ///
            elect_winner_type == "" & ///
            (strpos(elect_winner_type_key, "LOCAL") | ///
             strpos(elect_winner_type_key, "LISTA INDEPENDIENTE") | ///
             inlist(elect_winner_type_key, "PROVINCIAL", "DISTRITAL"))
        replace elect_winner_type = "national_party" if ///
            elect_winner_type == "" & ///
            (strpos(elect_winner_type_key, "PARTIDO") | ///
             elect_winner_type_key == "NACIONAL")
        assert elect_winner_type != ""

        generate byte mayor_org_type = ///
            cond(elect_winner_type == "national_party", 1, ///
            cond(elect_winner_type == "electoral_alliance", 2, ///
            cond(elect_winner_type == "regional_movement", 3, 4)))
        label values mayor_org_type municipal_org_type

        generate byte mayor_apra = ///
            elect_winner_org_key == "PARTIDO APRISTA PERUANO"
        generate double elect_volatility = isp_volatility
        generate byte elect_nullified = elect_complementary

        generate double isp_nep_diff = ///
            abs(elect_nep - isp_nep) if !elect_complementary
        generate double isp_hhi_diff = ///
            abs(elect_hhi - isp_hhi) if !elect_complementary
        generate double isp_top2_diff = ///
            abs(elect_top2_share - isp_top2_share) if ///
            !elect_complementary
        generate double isp_margin_diff = ///
            abs(elect_margin - isp_margin) if !elect_complementary

        drop ///
            _merge_authority ///
            _merge_complementary ///
            plurality_org_key ///
            elect_winner_org_key ///
            elect_winner_type_key ///
            elect_winner_type_raw

        order ///
            ubigeo_dist ///
            elect_scope ///
            elect_result_year ///
            elect_complementary ///
            elect_winner_org ///
            elect_winner_type ///
            mayor_apra
        isid ubigeo_dist

        if `first_election_scope' {
            save `election_cycle_work', replace
            local first_election_scope = 0
        }
        else {
            append using `election_cycle_work'
            save `election_cycle_work', replace
        }
    }

    use `election_cycle_work', clear
    isid ubigeo_dist
    sort ubigeo_dist
    compress

    if `election_year' == 2002 {
        save ///
            "${intermediate_root}/15_municipal_elections_2002.dta", ///
            replace
        save `election_cycle_2002', replace
    }
    else {
        save ///
            "${intermediate_root}/16_municipal_elections_2006.dta", ///
            replace
        save `election_cycle_2006', replace
    }
}

assert `election_2002_district_contests' == 1635
assert `election_2002_province_contests' == 194
assert `election_2006_district_contests' == 1637
assert `election_2006_province_contests' == 195
assert `election_2002_district_mayors' == 1622
assert `election_2002_province_mayors' == 194
assert `election_2006_district_mayors' == 1615
assert `election_2006_province_mayors' == 195
assert `emc_2002_contests' == 13
assert `emc_2006_contests' == 22


/*
The official 2002 ONPE files provide a diagnostic rather than a complete
validation gate. They omit 43 INFOgob contests and disagree on at least one
reported total in four matched contests. Preserve those discrepancies instead
of altering the cycle-specific INFOgob construction.
*/

tempfile election_onpe_2002
local first_official_scope = 1

foreach official_scope in district province {
    if "`official_scope'" == "district" {
        local official_file "`election_onpe_2002_district'"
    }
    else {
        local official_file "`election_onpe_2002_province'"
    }

    import delimited ///
        "`official_file'", ///
        clear ///
        delimiter(";") ///
        varnames(1) ///
        encoding(utf8) ///
        stringcols(_all)

    destring ///
        votos_obtenidos ///
        electores_habiles ///
        votos_blancos ///
        votos_nulos ///
        votos_impugnados, ///
        replace

    if "`official_scope'" == "district" {
        rename ubigeo reniec_code
        merge m:1 reniec_code using `election_code_bridge', ///
            keep(master match) ///
            generate(_merge_onpe_code)

        replace ubigeo_dist = "160701" if ///
            reniec_code == "150203" & _merge_onpe_code == 1
        replace ubigeo_dist = "160702" if ///
            reniec_code == "150204" & _merge_onpe_code == 1
        replace ubigeo_dist = "160703" if ///
            reniec_code == "150207" & _merge_onpe_code == 1
        replace ubigeo_dist = "160704" if ///
            reniec_code == "150208" & _merge_onpe_code == 1
        replace ubigeo_dist = "160705" if ///
            reniec_code == "150209" & _merge_onpe_code == 1
        assert !missing(ubigeo_dist)
        drop _merge_onpe_code
        clonevar official_ubigeo = ubigeo_dist
    }
    else {
        generate str6 reniec_code = substr(ubigeo, 1, 4) + "00"
        merge m:1 reniec_code using `election_province_bridge', ///
            keep(master match) ///
            generate(_merge_onpe_code)
        assert _merge_onpe_code == 3
        drop _merge_onpe_code
        generate str6 official_ubigeo = inei_province + "01"
    }

    tempfile official_party_stats_2002
    preserve
    collapse ///
        (sum) official_org_votes = votos_obtenidos, ///
        by(official_ubigeo codigo_agrupacion)
    bysort official_ubigeo: egen double official_valid_votes = ///
        total(official_org_votes)
    generate double official_share = ///
        official_org_votes / official_valid_votes
    generate double official_share_sq = official_share^2
    bysort official_ubigeo: egen double official_hhi = ///
        total(official_share_sq)
    gsort official_ubigeo -official_org_votes codigo_agrupacion
    by official_ubigeo: generate double official_winner_share = ///
        official_share[1]
    by official_ubigeo: generate double official_top2_share = ///
        official_share[1] + official_share[2]
    by official_ubigeo: generate double official_margin = ///
        official_share[1] - official_share[2]
    by official_ubigeo: keep if _n == 1
    keep ///
        official_ubigeo ///
        official_valid_votes ///
        official_hhi ///
        official_winner_share ///
        official_top2_share ///
        official_margin
    save `official_party_stats_2002', replace
    restore

    bysort official_ubigeo mesa: keep if _n == 1
    generate double official_invalid_votes = ///
        votos_blancos + votos_nulos + votos_impugnados
    collapse ///
        (sum) official_registered = electores_habiles ///
              official_invalid_votes, ///
        by(official_ubigeo)
    merge 1:1 official_ubigeo using `official_party_stats_2002', ///
        assert(match) ///
        nogen
    generate double official_ballots = ///
        official_valid_votes + official_invalid_votes
    generate double official_turnout = ///
        official_ballots / official_registered
    generate double official_invalid_share = ///
        official_invalid_votes / official_ballots
    generate str8 elect_scope = "`official_scope'"
    rename official_ubigeo ubigeo_dist

    if `first_official_scope' {
        save `election_onpe_2002', replace
        local first_official_scope = 0
    }
    else {
        append using `election_onpe_2002'
        save `election_onpe_2002', replace
    }
}

tempfile election_comp_codes_2002
use `election_cycle_2002', clear
preserve
keep if elect_complementary
keep ubigeo_dist elect_scope
isid ubigeo_dist elect_scope
save `election_comp_codes_2002', replace
restore
keep if !elect_complementary
merge 1:1 ///
    ubigeo_dist ///
    elect_scope ///
    using `election_onpe_2002', ///
    generate(_merge_onpe_2002)

merge m:1 ///
    ubigeo_dist ///
    elect_scope ///
    using `election_comp_codes_2002', ///
    keep(master match) ///
    generate(_merge_onpe_2002_comp)
assert _merge_onpe_2002_comp == 3 if _merge_onpe_2002 == 2
assert _merge_onpe_2002_comp == 1 if _merge_onpe_2002 != 2
drop _merge_onpe_2002_comp

count if _merge_onpe_2002 == 1
local onpe_2002_infogob_only_n = r(N)
assert `onpe_2002_infogob_only_n' == 43
count if _merge_onpe_2002 == 2
local onpe_2002_emc_excluded_n = r(N)
assert `onpe_2002_emc_excluded_n' == `emc_2002_contests'
count if _merge_onpe_2002 == 3
local onpe_2002_match_n = r(N)
assert `onpe_2002_match_n' == 1773

foreach metric in ///
    registered ///
    turnout ///
    invalid_share ///
    winner_share ///
    top2_share ///
    margin ///
    hhi {

    generate double onpe_`metric'_diff = ///
        abs(elect_`metric' - official_`metric') if ///
        _merge_onpe_2002 == 3
}

egen double onpe_2002_stats_diff = rowmax( ///
    onpe_turnout_diff ///
    onpe_invalid_share_diff ///
    onpe_winner_share_diff ///
    onpe_top2_share_diff ///
    onpe_margin_diff ///
    onpe_hhi_diff)
generate byte onpe_2002_any_difference = ///
    max(onpe_registered_diff, onpe_2002_stats_diff) > 1e-10 if ///
    _merge_onpe_2002 == 3
count if onpe_2002_any_difference == 1
local onpe_2002_diff_n = r(N)
assert `onpe_2002_diff_n' == 4
quietly summarize onpe_registered_diff, meanonly
local onpe_2002_reg_max = r(max)
quietly summarize onpe_2002_stats_diff, meanonly
local onpe_2002_stats_max = r(max)

generate str16 reconciliation_status = ///
    cond(_merge_onpe_2002 == 1, "infogob_only", ///
    cond(_merge_onpe_2002 == 2, "onpe_only", "matched"))
keep ///
    ubigeo_dist ///
    elect_scope ///
    reconciliation_status ///
    onpe_*_diff ///
    onpe_2002_any_difference
save ///
    "${qa_data_root}/municipal_election_onpe_2002_reconciliation.dta", ///
    replace
export delimited ///
    "${qa_data_root}/municipal_election_onpe_2002_reconciliation.csv", ///
    replace


/*
Independently reconcile all non-complementary 2006 contests to ONPE's
mesa-by-list returns. The 22 ordinary district contests annulled in 2006 are
retained in ONPE but excluded here because the cycle file correctly replaces
them with their 2007 complementary-election results.
*/

tempfile election_onpe_2006
local first_official_scope = 1

foreach official_scope in district province {
    if "`official_scope'" == "district" {
        local official_file "`election_onpe_2006_district'"
    }
    else {
        local official_file "`election_onpe_2006_province'"
    }

    import delimited ///
        "`official_file'", ///
        clear ///
        delimiter(";") ///
        varnames(1) ///
        encoding(utf8) ///
        stringcols(_all)

    destring ///
        votos_obtenidos ///
        electores_habiles ///
        votos_blancos ///
        votos_nulos ///
        votos_impug, ///
        replace

    rename ubigeo reniec_code
    merge m:1 reniec_code using `election_code_bridge', ///
        keep(master match) ///
        generate(_merge_onpe_code)
    assert _merge_onpe_code == 3
    drop _merge_onpe_code

    generate str6 official_ubigeo = ubigeo_dist
    if "`official_scope'" == "province" {
        replace official_ubigeo = ///
            substr(ubigeo_dist, 1, 4) + "01"
    }

    tempfile official_party_stats
    preserve
    collapse ///
        (sum) official_org_votes = votos_obtenidos, ///
        by(official_ubigeo codigo_agrupacion)
    bysort official_ubigeo: egen double official_valid_votes = ///
        total(official_org_votes)
    generate double official_share = ///
        official_org_votes / official_valid_votes
    generate double official_share_sq = official_share^2
    bysort official_ubigeo: egen double official_hhi = ///
        total(official_share_sq)
    gsort official_ubigeo -official_org_votes codigo_agrupacion
    by official_ubigeo: generate double official_winner_share = ///
        official_share[1]
    by official_ubigeo: generate double official_top2_share = ///
        official_share[1] + official_share[2]
    by official_ubigeo: generate double official_margin = ///
        official_share[1] - official_share[2]
    by official_ubigeo: keep if _n == 1
    keep ///
        official_ubigeo ///
        official_valid_votes ///
        official_hhi ///
        official_winner_share ///
        official_top2_share ///
        official_margin
    save `official_party_stats', replace
    restore

    bysort official_ubigeo mesa: keep if _n == 1
    generate double official_invalid_votes = ///
        votos_blancos + votos_nulos + votos_impug
    collapse ///
        (sum) official_registered = electores_habiles ///
              official_invalid_votes, ///
        by(official_ubigeo)
    merge 1:1 official_ubigeo using `official_party_stats', ///
        assert(match) ///
        nogen
    generate double official_ballots = ///
        official_valid_votes + official_invalid_votes
    generate double official_turnout = ///
        official_ballots / official_registered
    generate double official_invalid_share = ///
        official_invalid_votes / official_ballots
    generate str8 elect_scope = "`official_scope'"
    rename official_ubigeo ubigeo_dist

    if `first_official_scope' {
        save `election_onpe_2006', replace
        local first_official_scope = 0
    }
    else {
        append using `election_onpe_2006'
        save `election_onpe_2006', replace
    }
}

use `election_cycle_2006', clear
keep if !elect_complementary
merge 1:1 ///
    ubigeo_dist ///
    elect_scope ///
    using `election_onpe_2006', ///
    generate(_merge_onpe_2006)
count if _merge_onpe_2006 == 2
local onpe_emc_excluded_n = r(N)
assert `onpe_emc_excluded_n' == `emc_2006_contests'
assert _merge_onpe_2006 != 1
keep if _merge_onpe_2006 == 3
drop _merge_onpe_2006
count
local onpe_ordinary_n = r(N)
assert `onpe_ordinary_n' == 1810

foreach metric in ///
    registered ///
    turnout ///
    invalid_share ///
    winner_share ///
    top2_share ///
    margin ///
    hhi {

    generate double onpe_`metric'_diff = ///
        abs(elect_`metric' - official_`metric')
    assert onpe_`metric'_diff < 1e-10
}

quietly summarize onpe_registered_diff, meanonly
local onpe_reg_max = r(max)
quietly summarize onpe_turnout_diff, meanonly
local onpe_turn_max = r(max)
quietly summarize onpe_invalid_share_diff, meanonly
local onpe_inv_max = r(max)
quietly summarize onpe_winner_share_diff, meanonly
local onpe_win_max = r(max)
quietly summarize onpe_top2_share_diff, meanonly
local onpe_top2_max = r(max)
quietly summarize onpe_margin_diff, meanonly
local onpe_margin_max = r(max)
quietly summarize onpe_hhi_diff, meanonly
local onpe_hhi_max = r(max)
local onpe_stats_max = max( ///
    `onpe_turn_max', ///
    `onpe_inv_max', ///
    `onpe_win_max', ///
    `onpe_top2_max', ///
    `onpe_margin_max', ///
    `onpe_hhi_max')

keep ///
    ubigeo_dist ///
    elect_scope ///
    onpe_*_diff
save ///
    "${qa_data_root}/municipal_election_onpe_2006_reconciliation.dta", ///
    replace
export delimited ///
    "${qa_data_root}/municipal_election_onpe_2006_reconciliation.csv", ///
    replace


/*
The contest-level reconciliation is retained in Dropbox Working. These fields
show that the transparent vote-share calculations agree with INFOgob's ISP
indicators without placing row-level QA in Git.
*/

use `election_cycle_2002', clear
generate int election_cycle = 2002
append using `election_cycle_2006', generate(_appended_cycle)
replace election_cycle = 2006 if _appended_cycle
drop _appended_cycle

preserve
keep ///
    election_cycle ///
    ubigeo_dist ///
    elect_scope ///
    elect_complementary ///
    isp_nep_diff ///
    isp_hhi_diff ///
    isp_top2_diff ///
    isp_margin_diff
save ///
    "${qa_data_root}/municipal_election_isp_reconciliation.dta", ///
    replace
export delimited ///
    "${qa_data_root}/municipal_election_isp_reconciliation.csv", ///
    replace
restore

quietly summarize isp_nep_diff, meanonly
local election_isp_nep_max_diff = r(max)
quietly summarize isp_hhi_diff, meanonly
local election_isp_hhi_max_diff = r(max)
quietly summarize isp_top2_diff, meanonly
local election_isp_top2_max_diff = r(max)
quietly summarize isp_margin_diff, meanonly
local election_isp_margin_max_diff = r(max)
local election_isp_max_diff = max( ///
    `election_isp_nep_max_diff', ///
    `election_isp_hhi_max_diff', ///
    `election_isp_top2_max_diff', ///
    `election_isp_margin_max_diff')


/*
Merge each cycle to all RUV rows. Exact district UBIGEO is primary. A unique
exact current geographic path is used only when the RUV district code is not
linked. Manantay receives the Calleria municipal exposure that governed its
territory before Manantay's first municipal election.
*/

use ///
    "${analysis_data_root}/07_community_registry_gdp.dta", ///
    clear
count
assert r(N) == `gdp_registry_rows'

foreach election_year in 2002 2006 {
    tempfile ///
        election_cycle_link_source ///
        election_link_file ///
        election_name_file ///
        election_name_recovery

    if `election_year' == 2002 {
        preserve
        use `election_cycle_2002', clear
    }
    else {
        preserve
        use `election_cycle_2006', clear
    }

    local election_release_variables ///
        elect_result_year ///
        elect_complementary ///
        elect_scope ///
        elect_winner_org ///
        mayor_org_type ///
        mayor_apra ///
        mayor_female ///
        mayor_young ///
        elect_registered ///
        elect_turnout ///
        elect_invalid_share ///
        elect_winner_share ///
        elect_margin ///
        elect_nep ///
        elect_hhi ///
        elect_top2_share ///
        elect_candidate_count ///
        elect_candidate_female ///
        elect_candidate_young ///
        elect_voter_female ///
        elect_voter_young ///
        elect_voter_senior

    if `election_year' == 2006 {
        local election_release_variables ///
            `election_release_variables' ///
            elect_volatility
    }

    if `election_year' == 2002 {
        local election_release_variables ///
            `election_release_variables' ///
            fpl_vacancies ///
            fpl_recall_processes ///
            fpl_recalled_authorities ///
            fpl_council_female ///
            fpl_council_young ///
            fpl_ccl_early ///
            fpl_ccl_late
    }

    save `election_cycle_link_source', replace
    keep ///
        elect_dep_key ///
        elect_prov_key ///
        elect_dist_key ///
        `election_release_variables'
    isid elect_dep_key elect_prov_key elect_dist_key
    foreach release_variable of local election_release_variables {
        rename `release_variable' `release_variable'_`election_year'
    }
    save `election_name_file', replace

    use `election_cycle_link_source', clear
    keep ubigeo_dist `election_release_variables'
    generate str40 elect_link_method = "exact_district_ubigeo"
    generate byte elect_predecessor = 0

    count if ubigeo_dist == "250101"
    assert r(N) == 1
    expand 2 if ubigeo_dist == "250101", ///
        generate(manantay_predecessor_copy)
    replace ubigeo_dist = "250107" if manantay_predecessor_copy
    replace elect_link_method = ///
        "historical_predecessor_municipality" if ///
        manantay_predecessor_copy
    replace elect_predecessor = 1 if manantay_predecessor_copy
    drop manantay_predecessor_copy
    isid ubigeo_dist

    local election_release_variables ///
        `election_release_variables' ///
        elect_link_method ///
        elect_predecessor
    foreach release_variable of local election_release_variables {
        rename `release_variable' `release_variable'_`election_year'
    }
    save `election_link_file', replace
    restore

    merge m:1 ubigeo_dist using `election_link_file', ///
        keep(master match) ///
        generate(_merge_election_`election_year')
    generate byte elect_linked_`election_year' = ///
        _merge_election_`election_year' == 3

    count if !elect_linked_`election_year'
    local election_name_recovery_needed = r(N)

    if `election_name_recovery_needed' {
        preserve
        keep if !elect_linked_`election_year'
        keep ///
            ruv_id ///
            dpto_victim_raw ///
            prov_victim_raw ///
            dist_victim_raw
        victimasrd_normalize_name ///
            dpto_victim_raw, ///
            generate(elect_dep_key)
        victimasrd_normalize_name ///
            prov_victim_raw, ///
            generate(elect_prov_key)
        victimasrd_normalize_name ///
            dist_victim_raw, ///
            generate(elect_dist_key)

        replace elect_prov_key = "NAZCA" if ///
            elect_dep_key == "ICA" & elect_prov_key == "NASCA"
        replace elect_dist_key = "NAZCA" if ///
            elect_dep_key == "ICA" & ///
            elect_prov_key == "NAZCA" & ///
            elect_dist_key == "NASCA"
        replace elect_dist_key = "SAN PEDRO DE LARAOS" if ///
            elect_dep_key == "LIMA" & ///
            elect_prov_key == "HUAROCHIRI" & ///
            elect_dist_key == "LARAOS"

        merge m:1 ///
            elect_dep_key ///
            elect_prov_key ///
            elect_dist_key ///
            using `election_name_file', ///
            keep(master match) ///
            generate(_merge_election_name)
        keep if _merge_election_name == 3
        drop _merge_election_name

        foreach release_variable of local election_release_variables {
            capture confirm variable `release_variable'_`election_year'
            if !_rc {
                rename ///
                    `release_variable'_`election_year' ///
                    fb_`release_variable'_`election_year'
            }
        }
        generate str40 fb_elect_link_method_`election_year' = ///
            "unique_exact_geographic_path"
        generate byte fb_elect_predecessor_`election_year' = 0
        keep ruv_id fb_*
        isid ruv_id
        save `election_name_recovery', replace
        restore

        merge 1:1 ruv_id using `election_name_recovery', ///
            keep(master match) ///
            generate(_merge_election_recovery)

        foreach release_variable of local election_release_variables {
            capture confirm variable fb_`release_variable'_`election_year'
            if !_rc {
                replace `release_variable'_`election_year' = ///
                    fb_`release_variable'_`election_year' if ///
                    _merge_election_recovery == 3
                drop fb_`release_variable'_`election_year'
            }
        }
        replace elect_link_method_`election_year' = ///
            fb_elect_link_method_`election_year' if ///
            _merge_election_recovery == 3
        replace elect_predecessor_`election_year' = ///
            fb_elect_predecessor_`election_year' if ///
            _merge_election_recovery == 3
        drop ///
            fb_elect_link_method_`election_year' ///
            fb_elect_predecessor_`election_year'
        replace elect_linked_`election_year' = 1 if ///
            _merge_election_recovery == 3
        drop _merge_election_recovery
    }

    drop _merge_election_`election_year'

    count if elect_linked_`election_year'
    local electoral_`election_year'_linked = r(N)
    count if !elect_linked_`election_year'
    local electoral_`election_year'_unmatched = r(N)
    count if elect_linked_`election_year' & sample_main_rd
    local electoral_`election_year'_main_linked = r(N)
}

generate byte elect_linked_both = ///
    elect_linked_2002 & elect_linked_2006
count if elect_linked_both
local electoral_both_linked = r(N)

preserve
keep if !elect_linked_both
keep ///
    ruv_id ///
    ubigeo_dist ///
    dpto_victim_raw ///
    prov_victim_raw ///
    dist_victim_raw ///
    ccpp_victim_raw ///
    sample_main_rd ///
    elect_linked_2002 ///
    elect_linked_2006
generate str52 linkage_disposition = ///
    "retained_without_both_municipal_election_cycles"
save ///
    "${qa_data_root}/municipal_election_unmatched_ruv.dta", ///
    replace
export delimited ///
    "${qa_data_root}/municipal_election_unmatched_ruv.csv", ///
    replace
restore

preserve
keep ///
    ruv_id ///
    ubigeo_dist ///
    sample_main_rd ///
    elect_linked_2002 ///
    elect_link_method_2002 ///
    elect_predecessor_2002 ///
    elect_scope_2002 ///
    elect_result_year_2002 ///
    elect_linked_2006 ///
    elect_link_method_2006 ///
    elect_predecessor_2006 ///
    elect_scope_2006 ///
    elect_result_year_2006
save ///
    "${intermediate_root}/17_ruv_municipal_election_links.dta", ///
    replace
restore

capture label drop municipal_org_type
label define municipal_org_type ///
    1 "National party" ///
    2 "Electoral alliance" ///
    3 "Regional movement" ///
    4 "Local political organization"
label values mayor_org_type_2002 municipal_org_type
label values mayor_org_type_2006 municipal_org_type

foreach election_year in 2002 2006 {
    label variable elect_scope_`election_year' ///
        "Governing municipal jurisdiction scope, `election_year' cycle"
    label variable elect_result_year_`election_year' ///
        "Actual municipal election result year, `election_year' cycle"
    label variable elect_complementary_`election_year' ///
        "Result comes from the next-year complementary election"
    label variable elect_winner_org_`election_year' ///
        "Winning mayoral political organization, `election_year' cycle"
    label variable mayor_org_type_`election_year' ///
        "Winning mayoral organization type, `election_year' cycle"
    label variable mayor_apra_`election_year' ///
        "Governing mayor elected by the Peruvian Aprista Party"
    label variable mayor_female_`election_year' ///
        "Governing mayor is female, `election_year' cycle"
    label variable mayor_young_`election_year' ///
        "Governing mayor meets INFOgob's young-candidate criterion"
    label variable elect_registered_`election_year' ///
        "Registered municipal electors, `election_year' cycle"
    label variable elect_turnout_`election_year' ///
        "Municipal election turnout share, `election_year' cycle"
    label variable elect_invalid_share_`election_year' ///
        "Blank, null, or challenged votes as share of ballots cast"
    label variable elect_winner_share_`election_year' ///
        "Winning list share of valid votes, `election_year' cycle"
    label variable elect_margin_`election_year' ///
        "Winner-runner-up valid-vote share margin, `election_year' cycle"
    label variable elect_nep_`election_year' ///
        "Effective number of municipal lists, `election_year' cycle"
    label variable elect_hhi_`election_year' ///
        "Municipal list vote-share Herfindahl index, `election_year' cycle"
    label variable elect_top2_share_`election_year' ///
        "Top-two municipal lists' combined valid-vote share"
    label variable elect_candidate_count_`election_year' ///
        "Mayoral lists receiving votes, `election_year' cycle"
    label variable elect_candidate_female_`election_year' ///
        "Female share of mayoral candidates, `election_year' cycle"
    label variable elect_candidate_young_`election_year' ///
        "Young share of mayoral candidates, `election_year' cycle"
    label variable elect_voter_female_`election_year' ///
        "Female share of registered municipal electors"
    label variable elect_voter_young_`election_year' ///
        "Young share of registered municipal electors"
    label variable elect_voter_senior_`election_year' ///
        "Share of registered municipal electors older than 70"
}

label variable elect_volatility_2006 ///
    "INFOgob total electoral volatility for the ordinary 2006 contest"
label variable fpl_vacancies_2002 ///
    "Municipal authorities vacated during the 2003-2006 term"
label variable fpl_recall_processes_2002 ///
    "Municipal recall processes convened during the 2003-2006 term"
label variable fpl_recalled_authorities_2002 ///
    "Municipal authorities recalled during the 2003-2006 term"
label variable fpl_council_female_2002 ///
    "Women elected to the municipal council, 2002 cycle"
label variable fpl_council_young_2002 ///
    "Young members elected to the municipal council, 2002 cycle"
label variable fpl_ccl_early_2002 ///
    "Local Coordination Council election held in 2003-2004"
label variable fpl_ccl_late_2002 ///
    "Local Coordination Council election held in 2005-2006"

drop ///
    elect_linked_2002 ///
    elect_linked_2006 ///
    elect_linked_both ///
    elect_link_method_2002 ///
    elect_predecessor_2002 ///
    elect_link_method_2006 ///
    elect_predecessor_2006

order elect_scope_2002, after(gdp_dist_topshare_2006)

compress
sort ruv_id
isid ruv_id
count
local electoral_registry_rows = r(N)
assert `electoral_registry_rows' == `gdp_registry_rows'
assert `electoral_registry_rows' == 5712

save ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    replace


*===============================================================================
**# 12. Prepare SISFOH 2012-2013 at person, household, and CCPP levels
*===============================================================================

local sisfoh_person_raw ///
    "${raw_root}/15 SISFOH/sisfoh_persona.dta"
local sisfoh_household_raw ///
    "${raw_root}/15 SISFOH/sisfoh_hogar.dta"
local sisfoh_legacy_ccpp_raw ///
    "${raw_root}/15 SISFOH/ccpp_sisfoh2013.dta"

foreach sisfoh_source in ///
    "`sisfoh_person_raw'" ///
    "`sisfoh_household_raw'" ///
    "`sisfoh_legacy_ccpp_raw'" {

    capture confirm file "`sisfoh_source'"
    if _rc {
        display as error "Required SISFOH source is unavailable:"
        display as error "  `sisfoh_source'"
        exit 601
    }
}

tempfile ///
    sisfoh_household_keys ///
    sisfoh_ccpp_directory ///
    sisfoh_source_codes ///
    sisfoh_link_candidates ///
    sisfoh_code_links ///
    sisfoh_used_source_codes ///
    sisfoh_name_links ///
    sisfoh_ruv_links ///
    sisfoh_ccpp_linked ///
    sisfoh_person_link_keys


*-------------------------------------------------------------------------------
**# 12.1 Validate household keys and build a de-identified key spine
*-------------------------------------------------------------------------------

use ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR ///
    RV10 DIAFIN MESFIN ANIOFIN ///
    using "`sisfoh_household_raw'", clear

count
local sisfoh2013_household_records = r(N)
assert `sisfoh2013_household_records' == 8336891

isid ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR

generate str10 ubigeo_ccpp_sisfoh = ///
    DPTO + PROV + DIST + CODCCPP_N
assert regexm(ubigeo_ccpp_sisfoh, "^[0-9]{10}$")

count if RV10 == 1
local sisfoh2013_complete_households = r(N)
assert `sisfoh2013_complete_households' == 6163201

count if RV10 == 2
local sisfoh2013_incomplete_hh = r(N)
assert `sisfoh2013_incomplete_hh' == 446369

count if inlist(RV10, 1, 2)
local sisfoh2013_households_info = r(N)
assert `sisfoh2013_households_info' == 6609570

count if inlist(RV10, 1, 2) & !inrange(ANIOFIN, 2012, 2013)
local sisfoh2013_invalid_year = r(N)

count if inlist(RV10, 1, 2) & !inrange(MESFIN, 1, 12)
local sisfoh2013_invalid_month = r(N)

count if inlist(RV10, 1, 2) & !inrange(DIAFIN, 1, 31)
local sisfoh2013_invalid_day = r(N)

sort ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR
generate long sisfoh_hhid = _n

keep if inlist(RV10, 1, 2)
rename RV10 sisfoh_interview_result_2013
rename DIAFIN sisfoh_interview_day_raw
rename MESFIN sisfoh_interview_month_raw
rename ANIOFIN sisfoh_interview_year_raw

keep ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR ///
    sisfoh_hhid ///
    sisfoh_interview_result_2013 ///
    sisfoh_interview_day_raw ///
    sisfoh_interview_month_raw ///
    sisfoh_interview_year_raw

isid ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR
isid sisfoh_hhid
save `sisfoh_household_keys'

use ///
    DPTO PROV DIST CODCCPP_N ///
    NOMBREDD NOMBREPP NOMBREDI CENPOB ///
    AREA CATEG1 RV10 ///
    using "`sisfoh_household_raw'", clear

keep if inlist(RV10, 1, 2)
generate str10 ubigeo_ccpp_sisfoh = ///
    DPTO + PROV + DIST + CODCCPP_N

contract ///
    ubigeo_ccpp_sisfoh ///
    NOMBREDD NOMBREPP NOMBREDI CENPOB ///
    AREA CATEG1, ///
    freq(directory_record_count)

bysort ubigeo_ccpp_sisfoh: ///
    generate int directory_distinct_records = _N
gsort ///
    ubigeo_ccpp_sisfoh ///
    -directory_record_count ///
    NOMBREDD NOMBREPP NOMBREDI CENPOB ///
    AREA CATEG1
by ubigeo_ccpp_sisfoh: generate byte directory_selected = _n == 1
by ubigeo_ccpp_sisfoh: generate byte directory_top_tie = ///
    directory_record_count == directory_record_count[1] & _N > 1
by ubigeo_ccpp_sisfoh: egen int directory_top_tie_count = ///
    total(directory_top_tie)

count if directory_selected & directory_distinct_records > 1
local sisfoh2013_ccpp_attr_conflict = r(N)
count if directory_selected & directory_top_tie_count > 1
local sisfoh2013_ccpp_modal_ties = r(N)

rename NOMBREDD department_name_sisfoh2013
rename NOMBREPP province_name_sisfoh2013
rename NOMBREDI district_name_sisfoh2013
rename CENPOB ccpp_name_sisfoh2013
rename AREA area_sisfoh2013
rename CATEG1 ccpp_category_sisfoh2013

preserve
keep if directory_distinct_records > 1
save ///
    "${qa_data_root}/sisfoh2013_ccpp_directory_disagreements.dta", ///
    replace
export delimited ///
    "${qa_data_root}/sisfoh2013_ccpp_directory_disagreements.csv", ///
    replace
restore

keep if directory_selected
drop ///
    directory_record_count ///
    directory_distinct_records ///
    directory_selected ///
    directory_top_tie ///
    directory_top_tie_count
isid ubigeo_ccpp_sisfoh

count
local sisfoh2013_source_ccpp = r(N)
assert `sisfoh2013_source_ccpp' == 81220
save `sisfoh_ccpp_directory'


*-------------------------------------------------------------------------------
**# 12.2 Clean and de-identify the national person roster
*-------------------------------------------------------------------------------

use ///
    DPTO PROV DIST CODCCPP_N ///
    AREA CATEG1 ///
    SECUENCIA CONG NROVIV NHOGAR ///
    NRO NRO_ORD ///
    EDAD01 PTES01 SEXO01 GESTA01 ESTA01 ///
    SEGU01_1-SEGU01_6 ///
    IDIOMA01 LEE01 NIV01 ULT01 ///
    ERA01 SECT01 ///
    DISCA01_1-DISCA01_6 ///
    PROG01_1-PROG01_11 ///
    using "`sisfoh_person_raw'", clear

count
local sisfoh2013_person_records = r(N)
assert `sisfoh2013_person_records' == 24009026

merge m:1 ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR ///
    using `sisfoh_household_keys', ///
    keep(master match) ///
    keepusing( ///
        sisfoh_hhid ///
        sisfoh_interview_result_2013 ///
        sisfoh_interview_day_raw ///
        sisfoh_interview_month_raw ///
        sisfoh_interview_year_raw)

assert _merge == 3
drop _merge
assert inlist(sisfoh_interview_result_2013, 1, 2)

isid sisfoh_hhid NRO
count if NRO != NRO_ORD
local sisfoh2013_person_order_diff = r(N)

sort sisfoh_hhid NRO
generate long sisfoh_pid = _n
rename NRO sisfoh_person_number

generate str10 ubigeo_ccpp_sisfoh = ///
    DPTO + PROV + DIST + CODCCPP_N
assert regexm(ubigeo_ccpp_sisfoh, "^[0-9]{10}$")

/*
The INEI-assisted Census linkage retained the source roster coordinates but
not the pipeline's de-identified SISFOH IDs. This restricted Working key spine
allows the Census cohort to recover those IDs without persisting names,
document numbers, or open text.
*/
preserve
keep ///
    DPTO PROV DIST NROVIV NHOGAR ///
    ubigeo_ccpp_sisfoh sisfoh_person_number ///
    EDAD01 SEXO01 sisfoh_pid sisfoh_hhid
rename NROVIV sisfoh_dwelling_number
rename NHOGAR sisfoh_household_number
rename EDAD01 sisfoh_age_key
rename SEXO01 sisfoh_sex_key
generate str6 ubigeo_district_sisfoh = ///
    DPTO + PROV + DIST
drop DPTO PROV DIST
isid ///
    ubigeo_ccpp_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number
save `sisfoh_person_link_keys'
save ///
    "${intermediate_root}/25_sisfoh_2013_person_linkage_keys.dta", ///
    replace
restore

generate byte sisfoh_area_2013 = AREA if inlist(AREA, 1, 2)
generate str2 sisfoh_ccpp_category_2013 = CATEG1
generate byte sisfoh_interview_complete = ///
    sisfoh_interview_result_2013 == 1

generate double interview_date_sisfoh2013 = mdy( ///
    sisfoh_interview_month_raw, ///
    sisfoh_interview_day_raw, ///
    sisfoh_interview_year_raw) ///
    if inrange(sisfoh_interview_year_raw, 2012, 2013)
format interview_date_sisfoh2013 %td

assert inrange(EDAD01, 0, 120) | missing(EDAD01)
generate int age_2013 = EDAD01 if inrange(EDAD01, 0, 120)
count if missing(age_2013)
local sisfoh2013_person_age_missing = r(N)

assert inlist(SEXO01, 1, 2)
generate byte female_2013 = SEXO01 == 2
generate byte household_head_2013 = PTES01 == 1
generate byte relation_head_2013 = PTES01
label values relation_head_2013 PTES01

generate byte pregnant_2013 = .
replace pregnant_2013 = GESTA01 == 1 ///
    if female_2013 & age_2013 >= 12 & inlist(GESTA01, 1, 2)

generate byte marital_status_2013 = ESTA01 ///
    if age_2013 >= 12 & inrange(ESTA01, 1, 6)
label values marital_status_2013 ESTA01

egen byte insurance_selected = ///
    anycount(SEGU01_1-SEGU01_5), values(1 2 3 4 5)
generate byte insurance_none = SEGU01_6 == 6
assert insurance_selected > 0 | insurance_none
assert !(insurance_selected > 0 & insurance_none)

generate byte insurance_any_2013 = insurance_selected > 0
generate byte insurance_essalud_2013 = SEGU01_1 == 1
generate byte insurance_armed_forces_2013 = SEGU01_2 == 2
generate byte insurance_private_2013 = SEGU01_3 == 3
generate byte insurance_sis_2013 = SEGU01_4 == 4
generate byte insurance_other_2013 = SEGU01_5 == 5

generate byte language_childhood_2013 = IDIOMA01 ///
    if age_2013 >= 3 & inrange(IDIOMA01, 1, 7)
capture label drop sisfoh_language_2013
label define sisfoh_language_2013 ///
    1 "Quechua" ///
    2 "Aymara" ///
    3 "Ashaninka" ///
    4 "Spanish" ///
    5 "Foreign language" ///
    6 "Unable to speak" ///
    7 "Other"
label values language_childhood_2013 sisfoh_language_2013

generate byte spanish_childhood_2013 = ///
    language_childhood_2013 == 4 ///
    if !missing(language_childhood_2013)
generate byte named_indigenous_language_2013 = ///
    inlist(language_childhood_2013, 1, 2, 3) ///
    if !missing(language_childhood_2013)
generate byte nonspanish_language_2013 = ///
    language_childhood_2013 != 4 ///
    if !missing(language_childhood_2013)

count if age_2013 >= 3
local sisfoh2013_language_eligible = r(N)
count if age_2013 >= 3 & !missing(language_childhood_2013)
local sisfoh2013_language_valid = r(N)

generate byte literate_2013 = LEE01 == 1 ///
    if age_2013 >= 3 & inlist(LEE01, 1, 2)
generate byte education_level_2013 = NIV01 ///
    if age_2013 >= 3 & inrange(NIV01, 1, 7)
label values education_level_2013 NIV01
generate byte last_grade_2013 = ULT01 ///
    if inrange(education_level_2013, 3, 7) & ///
       inrange(ULT01, 1, 6)

generate byte primary_complete_2013 = .
replace primary_complete_2013 = 0 ///
    if inlist(education_level_2013, 1, 2)
replace primary_complete_2013 = last_grade_2013 == 6 ///
    if education_level_2013 == 3 & !missing(last_grade_2013)
replace primary_complete_2013 = 1 ///
    if inrange(education_level_2013, 4, 7)

generate byte secondaryplus_2013 = ///
    education_level_2013 >= 4 ///
    if !missing(education_level_2013)

generate byte education_years_approx_2013 = .
replace education_years_approx_2013 = 0 ///
    if inlist(education_level_2013, 1, 2)
replace education_years_approx_2013 = last_grade_2013 ///
    if education_level_2013 == 3
replace education_years_approx_2013 = 6 + last_grade_2013 ///
    if education_level_2013 == 4
replace education_years_approx_2013 = 11 + last_grade_2013 ///
    if inlist(education_level_2013, 5, 6)
replace education_years_approx_2013 = 16 + last_grade_2013 ///
    if education_level_2013 == 7

generate byte labor_status_2013 = ERA01 ///
    if age_2013 >= 6 & inrange(ERA01, 1, 10)
label values labor_status_2013 ERA01
generate byte employed_2013 = ///
    inrange(labor_status_2013, 1, 5) ///
    if !missing(labor_status_2013)
generate byte labor_force_2013 = ///
    inrange(labor_status_2013, 1, 6) ///
    if !missing(labor_status_2013)
generate byte unemployed_2013 = ///
    labor_status_2013 == 6 ///
    if !missing(labor_status_2013)

generate byte employment_sector_2013 = SECT01 ///
    if employed_2013 == 1 & inrange(SECT01, 1, 10)
label values employment_sector_2013 SECT01

generate byte employed_agriculture_2013 = ///
    employment_sector_2013 == 1 if !missing(employed_2013)
generate byte employed_livestock_2013 = ///
    employment_sector_2013 == 2 if !missing(employed_2013)
generate byte employed_forestry_2013 = ///
    employment_sector_2013 == 3 if !missing(employed_2013)
generate byte employed_fishing_2013 = ///
    employment_sector_2013 == 4 if !missing(employed_2013)
generate byte employed_mining_2013 = ///
    employment_sector_2013 == 5 if !missing(employed_2013)
generate byte employed_handicraft_2013 = ///
    employment_sector_2013 == 6 if !missing(employed_2013)
generate byte employed_commerce_2013 = ///
    employment_sector_2013 == 7 if !missing(employed_2013)
generate byte employed_services_2013 = ///
    employment_sector_2013 == 8 if !missing(employed_2013)
generate byte employed_other_2013 = ///
    employment_sector_2013 == 9 if !missing(employed_2013)
generate byte employed_government_2013 = ///
    employment_sector_2013 == 10 if !missing(employed_2013)

egen byte disability_selected = ///
    anycount(DISCA01_1-DISCA01_5), values(1 2 3 4 5)
generate byte disability_none = DISCA01_6 == 6
assert disability_selected > 0 | disability_none
assert !(disability_selected > 0 & disability_none)

generate byte disability_any_2013 = disability_selected > 0
generate byte disability_visual_2013 = DISCA01_1 == 1
generate byte disability_hearing_2013 = DISCA01_2 == 2
generate byte disability_speech_2013 = DISCA01_3 == 3
generate byte disability_mobility_2013 = DISCA01_4 == 4
generate byte disability_cognitive_2013 = DISCA01_5 == 5

egen byte program_selected = ///
    anycount(PROG01_1-PROG01_10), ///
    values(1 2 3 4 5 6 7 8 9 10)
generate byte program_none = PROG01_11 == 11
assert program_selected > 0 | program_none
assert !(program_selected > 0 & program_none)

generate byte program_any_2013 = program_selected > 0
generate byte program_milk_2013 = PROG01_1 == 1
generate byte program_soup_kitchen_2013 = PROG01_2 == 2
generate byte program_school_meal_2013 = PROG01_3 == 3
generate byte program_supplement_2013 = PROG01_4 == 4
generate byte program_food_basket_2013 = PROG01_5 == 5
generate byte program_juntos_2013 = PROG01_6 == 6
generate byte program_housing_2013 = PROG01_7 == 7
generate byte program_pension65_2013 = PROG01_8 == 8
generate byte program_cunamas_2013 = PROG01_9 == 9
generate byte program_other_2013 = PROG01_10 == 10

label variable sisfoh_hhid ///
    "De-identified national SISFOH household identifier"
label variable sisfoh_pid ///
    "De-identified national SISFOH person identifier"
label variable interview_date_sisfoh2013 ///
    "Valid final SISFOH interview date, 2012-2013"
label variable education_years_approx_2013 ///
    "Approximate completed education years from level and grade"
label variable named_indigenous_language_2013 ///
    "Childhood language is Quechua, Aymara, or Ashaninka"
label variable age_2013 "Age at SISFOH enumeration"
label variable female_2013 "Female"
label variable household_head_2013 "Household head"
label variable pregnant_2013 "Pregnant; females age 12 or older"
label variable literate_2013 "Can read and write; age three or older"
label variable education_level_2013 "Highest education level"
label variable primary_complete_2013 "Completed primary education"
label variable secondaryplus_2013 "Secondary or higher education"
label variable insurance_any_2013 "Reports any health insurance"
label variable insurance_sis_2013 "Reports SIS health insurance"
label variable employed_2013 "Employed in the preceding month"
label variable labor_force_2013 "In the labor force"
label variable unemployed_2013 "Unemployed and in the labor force"
label variable employment_sector_2013 "Employment sector"
label variable disability_any_2013 "Reports any permanent limitation"
label variable program_any_2013 "Current beneficiary of a listed program"
label variable program_juntos_2013 "Current beneficiary of Juntos"

keep ///
    sisfoh_pid sisfoh_hhid sisfoh_person_number ///
    ubigeo_ccpp_sisfoh ///
    sisfoh_area_2013 sisfoh_ccpp_category_2013 ///
    sisfoh_interview_result_2013 ///
    sisfoh_interview_complete ///
    interview_date_sisfoh2013 ///
    age_2013 female_2013 ///
    household_head_2013 relation_head_2013 ///
    pregnant_2013 marital_status_2013 ///
    language_childhood_2013 ///
    spanish_childhood_2013 ///
    named_indigenous_language_2013 ///
    nonspanish_language_2013 ///
    literate_2013 education_level_2013 last_grade_2013 ///
    education_years_approx_2013 ///
    primary_complete_2013 secondaryplus_2013 ///
    insurance_any_2013 insurance_essalud_2013 ///
    insurance_armed_forces_2013 insurance_private_2013 ///
    insurance_sis_2013 insurance_other_2013 ///
    labor_status_2013 employed_2013 ///
    labor_force_2013 unemployed_2013 ///
    employment_sector_2013 ///
    employed_agriculture_2013 employed_livestock_2013 ///
    employed_forestry_2013 employed_fishing_2013 ///
    employed_mining_2013 employed_handicraft_2013 ///
    employed_commerce_2013 employed_services_2013 ///
    employed_other_2013 employed_government_2013 ///
    disability_any_2013 disability_visual_2013 ///
    disability_hearing_2013 disability_speech_2013 ///
    disability_mobility_2013 disability_cognitive_2013 ///
    program_any_2013 program_milk_2013 ///
    program_soup_kitchen_2013 program_school_meal_2013 ///
    program_supplement_2013 program_food_basket_2013 ///
    program_juntos_2013 program_housing_2013 ///
    program_pension65_2013 program_cunamas_2013 ///
    program_other_2013

compress
sort sisfoh_hhid sisfoh_person_number
isid sisfoh_pid
isid sisfoh_hhid sisfoh_person_number
save ///
    "${intermediate_root}/18_sisfoh_2013_person_clean.dta", ///
    replace


*-------------------------------------------------------------------------------
**# 12.3 Aggregate person information to households and CCPPs
*-------------------------------------------------------------------------------

generate byte person_one = 1
generate byte age_valid_aux = !missing(age_2013)
generate byte age_0_14_aux = inrange(age_2013, 0, 14)
generate byte age_15_29_aux = inrange(age_2013, 15, 29)
generate byte age_30_44_aux = inrange(age_2013, 30, 44)
generate byte age_45_64_aux = inrange(age_2013, 45, 64)
generate byte age_65p_aux = age_2013 >= 65 & !missing(age_2013)

generate byte literacy_eligible_aux = age_2013 >= 14 & !missing(age_2013)
generate byte literacy_valid_aux = ///
    literacy_eligible_aux & !missing(literate_2013)
generate byte literate_age14_aux = ///
    literacy_eligible_aux & literate_2013 == 1

generate byte education_eligible_aux = ///
    age_2013 >= 14 & !missing(age_2013)
generate byte education_valid_aux = ///
    education_eligible_aux & !missing(education_level_2013)
generate byte secondaryplus_age14_aux = ///
    education_eligible_aux & secondaryplus_2013 == 1

generate byte language_eligible_aux = age_2013 >= 3 & !missing(age_2013)
generate byte language_valid_aux = ///
    language_eligible_aux & !missing(language_childhood_2013)
generate byte nonspanish_aux = ///
    language_eligible_aux & nonspanish_language_2013 == 1
generate byte indigenous_aux = ///
    language_eligible_aux & named_indigenous_language_2013 == 1

generate byte labor_eligible_aux = age_2013 >= 14 & !missing(age_2013)
generate byte labor_valid_aux = ///
    labor_eligible_aux & !missing(labor_status_2013)
generate byte labor_force_aux = ///
    labor_eligible_aux & labor_force_2013 == 1
generate byte employed_age14_aux = ///
    labor_eligible_aux & employed_2013 == 1
generate byte unemployed_age14_aux = ///
    labor_eligible_aux & unemployed_2013 == 1

generate byte sector_agriculture_aux = ///
    labor_eligible_aux & employment_sector_2013 == 1
generate byte sector_livestock_aux = ///
    labor_eligible_aux & employment_sector_2013 == 2
generate byte sector_forestry_aux = ///
    labor_eligible_aux & employment_sector_2013 == 3
generate byte sector_fishing_aux = ///
    labor_eligible_aux & employment_sector_2013 == 4
generate byte sector_mining_aux = ///
    labor_eligible_aux & employment_sector_2013 == 5
generate byte sector_handicraft_aux = ///
    labor_eligible_aux & employment_sector_2013 == 6
generate byte sector_commerce_aux = ///
    labor_eligible_aux & employment_sector_2013 == 7
generate byte sector_services_aux = ///
    labor_eligible_aux & employment_sector_2013 == 8
generate byte sector_other_aux = ///
    labor_eligible_aux & employment_sector_2013 == 9
generate byte sector_government_aux = ///
    labor_eligible_aux & employment_sector_2013 == 10

generate byte child_labor_eligible_aux = ///
    inrange(age_2013, 6, 14) & !missing(labor_status_2013)
generate byte child_employed_aux = ///
    child_labor_eligible_aux & employed_2013 == 1

generate byte nbi_school_risk_aux = 0 if !missing(age_2013)
replace nbi_school_risk_aux = ///
    inlist(education_level_2013, 1, 2) ///
    if inrange(age_2013, 7, 12) & !missing(education_level_2013)
replace nbi_school_risk_aux = . ///
    if inrange(age_2013, 7, 12) & missing(education_level_2013)
generate byte nbi_school_unknown_aux = ///
    missing(age_2013) | ///
    (inrange(age_2013, 7, 12) & missing(education_level_2013))

generate byte nbi_employed_aux = .
replace nbi_employed_aux = 0 if inrange(age_2013, 0, 5)
replace nbi_employed_aux = employed_2013 if age_2013 >= 6
generate byte employment_valid_aux = !missing(nbi_employed_aux)

generate int head_age_aux = age_2013 if household_head_2013
generate byte head_female_aux = female_2013 if household_head_2013
generate byte head_education_aux = ///
    education_level_2013 if household_head_2013
generate byte head_employed_aux = employed_2013 if household_head_2013
generate byte head_primary2less_aux = .
replace head_primary2less_aux = 1 ///
    if household_head_2013 & inlist(education_level_2013, 1, 2)
replace head_primary2less_aux = 1 ///
    if household_head_2013 & education_level_2013 == 3 & ///
       inrange(last_grade_2013, 1, 2)
replace head_primary2less_aux = 0 ///
    if household_head_2013 & education_level_2013 == 3 & ///
       inrange(last_grade_2013, 3, 6)
replace head_primary2less_aux = 0 ///
    if household_head_2013 & ///
       inrange(education_level_2013, 4, 7)

collapse ///
    (sum) ///
        hh_members_2013=person_one ///
        hh_age_valid_2013=age_valid_aux ///
        hh_female_2013=female_2013 ///
        hh_age_0_14_2013=age_0_14_aux ///
        hh_age_15_29_2013=age_15_29_aux ///
        hh_age_30_44_2013=age_30_44_aux ///
        hh_age_45_64_2013=age_45_64_aux ///
        hh_age_65p_2013=age_65p_aux ///
        hh_literacy_eligible_2013=literacy_eligible_aux ///
        hh_literacy_valid_2013=literacy_valid_aux ///
        hh_literate_2013=literate_age14_aux ///
        hh_education_eligible_2013=education_eligible_aux ///
        hh_education_valid_2013=education_valid_aux ///
        hh_secondaryplus_2013=secondaryplus_age14_aux ///
        hh_language_eligible_2013=language_eligible_aux ///
        hh_language_valid_2013=language_valid_aux ///
        hh_nonspanish_2013=nonspanish_aux ///
        hh_named_indigenous_2013=indigenous_aux ///
        hh_insured_2013=insurance_any_2013 ///
        hh_disability_2013=disability_any_2013 ///
        hh_program_any_2013=program_any_2013 ///
        hh_juntos_2013=program_juntos_2013 ///
        hh_labor_eligible_2013=labor_eligible_aux ///
        hh_labor_valid_2013=labor_valid_aux ///
        hh_labor_force_2013=labor_force_aux ///
        hh_employed_age14_2013=employed_age14_aux ///
        hh_unemployed_age14_2013=unemployed_age14_aux ///
        hh_sector_agriculture_2013=sector_agriculture_aux ///
        hh_sector_livestock_2013=sector_livestock_aux ///
        hh_sector_forestry_2013=sector_forestry_aux ///
        hh_sector_fishing_2013=sector_fishing_aux ///
        hh_sector_mining_2013=sector_mining_aux ///
        hh_sector_handicraft_2013=sector_handicraft_aux ///
        hh_sector_commerce_2013=sector_commerce_aux ///
        hh_sector_services_2013=sector_services_aux ///
        hh_sector_other_2013=sector_other_aux ///
        hh_sector_government_2013=sector_government_aux ///
        hh_child_labor_eligible_2013=child_labor_eligible_aux ///
        hh_child_employed_2013=child_employed_aux ///
        hh_school_unknown_2013=nbi_school_unknown_aux ///
        hh_employment_valid_2013=employment_valid_aux ///
        hh_employed_all_2013=nbi_employed_aux ///
    (max) ///
        hh_nbi4_school_proxy_2013=nbi_school_risk_aux ///
        hh_head_age_2013=head_age_aux ///
        hh_head_female_2013=head_female_aux ///
        hh_head_education_2013=head_education_aux ///
        hh_head_employed_2013=head_employed_aux ///
        hh_head_primary2less_2013=head_primary2less_aux, ///
    by(sisfoh_hhid ubigeo_ccpp_sisfoh)

replace hh_nbi4_school_proxy_2013 = . ///
    if hh_nbi4_school_proxy_2013 == 0 & hh_school_unknown_2013 > 0

generate double hh_share_female_2013 = ///
    hh_female_2013 / hh_members_2013
generate double hh_share_literate_2013 = ///
    hh_literate_2013 / hh_literacy_valid_2013 ///
    if hh_literacy_valid_2013 > 0
generate double hh_share_secondaryplus_2013 = ///
    hh_secondaryplus_2013 / hh_education_valid_2013 ///
    if hh_education_valid_2013 > 0
generate double hh_share_nonspanish_2013 = ///
    hh_nonspanish_2013 / hh_language_valid_2013 ///
    if hh_language_valid_2013 > 0
generate double hh_share_insured_2013 = ///
    hh_insured_2013 / hh_members_2013
generate double hh_share_disability_2013 = ///
    hh_disability_2013 / hh_members_2013
generate double hh_share_program_any_2013 = ///
    hh_program_any_2013 / hh_members_2013

compress
sort sisfoh_hhid
isid sisfoh_hhid
count
assert r(N) == `sisfoh2013_households_info'
save ///
    "${intermediate_root}/19_sisfoh_2013_person_household.dta", ///
    replace

generate byte household_one = 1
collapse ///
    (sum) ///
        sisfoh2013_person_households=household_one ///
        sisfoh2013_population=hh_members_2013 ///
        sisfoh2013_age_valid=hh_age_valid_2013 ///
        sisfoh2013_female=hh_female_2013 ///
        sisfoh2013_age_0_14=hh_age_0_14_2013 ///
        sisfoh2013_age_15_29=hh_age_15_29_2013 ///
        sisfoh2013_age_30_44=hh_age_30_44_2013 ///
        sisfoh2013_age_45_64=hh_age_45_64_2013 ///
        sisfoh2013_age_65p=hh_age_65p_2013 ///
        sisfoh2013_lit_eligible=hh_literacy_eligible_2013 ///
        sisfoh2013_lit_valid=hh_literacy_valid_2013 ///
        sisfoh2013_literate=hh_literate_2013 ///
        sisfoh2013_edu_eligible=hh_education_eligible_2013 ///
        sisfoh2013_edu_valid=hh_education_valid_2013 ///
        sisfoh2013_secondaryplus=hh_secondaryplus_2013 ///
        sisfoh2013_lang_eligible=hh_language_eligible_2013 ///
        sisfoh2013_lang_valid=hh_language_valid_2013 ///
        sisfoh2013_nonspanish=hh_nonspanish_2013 ///
        sisfoh2013_indigenous=hh_named_indigenous_2013 ///
        sisfoh2013_insured=hh_insured_2013 ///
        sisfoh2013_disability=hh_disability_2013 ///
        sisfoh2013_program_any=hh_program_any_2013 ///
        sisfoh2013_juntos=hh_juntos_2013 ///
        sisfoh2013_labor_eligible=hh_labor_eligible_2013 ///
        sisfoh2013_labor_valid=hh_labor_valid_2013 ///
        sisfoh2013_labor_force=hh_labor_force_2013 ///
        sisfoh2013_employed=hh_employed_age14_2013 ///
        sisfoh2013_unemployed=hh_unemployed_age14_2013 ///
        sisfoh2013_sector_agri=hh_sector_agriculture_2013 ///
        sisfoh2013_sector_livestock=hh_sector_livestock_2013 ///
        sisfoh2013_sector_forestry=hh_sector_forestry_2013 ///
        sisfoh2013_sector_fishing=hh_sector_fishing_2013 ///
        sisfoh2013_sector_mining=hh_sector_mining_2013 ///
        sisfoh2013_sector_handicraft=hh_sector_handicraft_2013 ///
        sisfoh2013_sector_commerce=hh_sector_commerce_2013 ///
        sisfoh2013_sector_services=hh_sector_services_2013 ///
        sisfoh2013_sector_other=hh_sector_other_2013 ///
        sisfoh2013_sector_government=hh_sector_government_2013 ///
        sisfoh2013_child_labor_eligible=hh_child_labor_eligible_2013 ///
        sisfoh2013_child_employed=hh_child_employed_2013, ///
    by(ubigeo_ccpp_sisfoh)

generate double share_female_2013 = ///
    sisfoh2013_female / sisfoh2013_population
generate double share_age_0_14_2013 = ///
    sisfoh2013_age_0_14 / sisfoh2013_age_valid ///
    if sisfoh2013_age_valid > 0
generate double share_age_15_29_2013 = ///
    sisfoh2013_age_15_29 / sisfoh2013_age_valid ///
    if sisfoh2013_age_valid > 0
generate double share_age_30_44_2013 = ///
    sisfoh2013_age_30_44 / sisfoh2013_age_valid ///
    if sisfoh2013_age_valid > 0
generate double share_age_45_64_2013 = ///
    sisfoh2013_age_45_64 / sisfoh2013_age_valid ///
    if sisfoh2013_age_valid > 0
generate double share_age_65p_2013 = ///
    sisfoh2013_age_65p / sisfoh2013_age_valid ///
    if sisfoh2013_age_valid > 0
generate double share_literate_2013 = ///
    sisfoh2013_literate / sisfoh2013_lit_valid ///
    if sisfoh2013_lit_valid > 0
generate double share_educ_secondaryplus_2013 = ///
    sisfoh2013_secondaryplus / sisfoh2013_edu_valid ///
    if sisfoh2013_edu_valid > 0
generate double share_nonspanish_2013 = ///
    sisfoh2013_nonspanish / sisfoh2013_lang_valid ///
    if sisfoh2013_lang_valid > 0
generate double share_indigenous_language_2013 = ///
    sisfoh2013_indigenous / sisfoh2013_lang_valid ///
    if sisfoh2013_lang_valid > 0
generate double language_coverage_2013 = ///
    sisfoh2013_lang_valid / sisfoh2013_lang_eligible ///
    if sisfoh2013_lang_eligible > 0
generate double share_any_insurance_2013 = ///
    sisfoh2013_insured / sisfoh2013_population
generate double share_any_disability_2013 = ///
    sisfoh2013_disability / sisfoh2013_population
generate double share_any_program_2013 = ///
    sisfoh2013_program_any / sisfoh2013_population
generate double share_juntos_2013 = ///
    sisfoh2013_juntos / sisfoh2013_population
generate double labor_force_participation_2013 = ///
    sisfoh2013_labor_force / sisfoh2013_labor_valid ///
    if sisfoh2013_labor_valid > 0
generate double employment_rate_2013 = ///
    sisfoh2013_employed / sisfoh2013_labor_force ///
    if sisfoh2013_labor_force > 0
generate double unemployment_rate_2013 = ///
    sisfoh2013_unemployed / sisfoh2013_labor_force ///
    if sisfoh2013_labor_force > 0
generate double child_employment_rate_2013 = ///
    sisfoh2013_child_employed / sisfoh2013_child_labor_eligible ///
    if sisfoh2013_child_labor_eligible > 0

compress
sort ubigeo_ccpp_sisfoh
isid ubigeo_ccpp_sisfoh
count
assert r(N) == `sisfoh2013_source_ccpp'
save ///
    "${intermediate_root}/20_sisfoh_2013_person_ccpp.dta", ///
    replace


*-------------------------------------------------------------------------------
**# 12.4 Clean household and dwelling information
*-------------------------------------------------------------------------------

use ///
    DPTO PROV DIST CODCCPP_N ///
    AREA CATEG1 ///
    SECUENCIA CONG NROVIV NHOGAR ///
    RV10 DIAFIN MESFIN ANIOFIN ///
    TVIV VIVES MPARED MTECHO MATPISO ///
    TALUM ABASAG SERHIG CTAHAB COMBUSA ///
    BIEN1-BIEN15 ///
    TOTAL HOMBRES MUJERES ///
    using "`sisfoh_household_raw'", clear

keep if inlist(RV10, 1, 2)
merge 1:1 ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR ///
    using `sisfoh_household_keys', ///
    keep(master match) keepusing(sisfoh_hhid)
assert _merge == 3
drop _merge

generate str10 ubigeo_ccpp_sisfoh = ///
    DPTO + PROV + DIST + CODCCPP_N
assert regexm(ubigeo_ccpp_sisfoh, "^[0-9]{10}$")

merge 1:1 sisfoh_hhid using ///
    "${intermediate_root}/19_sisfoh_2013_person_household.dta"
assert _merge == 3
drop _merge

count if TOTAL != hh_members_2013
local sisfoh2013_roster_total_diff = r(N)
generate byte roster_total_matches_2013 = ///
    TOTAL == hh_members_2013

assert inrange(TVIV, 1, 8) | missing(TVIV)
assert inrange(VIVES, 1, 7) | missing(VIVES)
assert inrange(MPARED, 1, 8) | missing(MPARED)
assert inrange(MTECHO, 1, 8) | missing(MTECHO)
assert inrange(MATPISO, 1, 7) | missing(MATPISO)
assert inrange(TALUM, 1, 6) | missing(TALUM)
assert inrange(ABASAG, 1, 7) | missing(ABASAG)
assert inrange(SERHIG, 1, 6) | missing(SERHIG)
assert inrange(COMBUSA, 1, 8)
assert CTAHAB > 0 & !missing(CTAHAB)

generate byte household_items_valid_2013 = ///
    !missing(TVIV, VIVES, MPARED, MTECHO, MATPISO, ///
             TALUM, ABASAG, SERHIG)
count if !household_items_valid_2013
local sisfoh2013_hh_items_missing = r(N)

rename RV10 sisfoh_interview_result_2013
generate byte sisfoh_interview_complete = ///
    sisfoh_interview_result_2013 == 1
generate double interview_date_sisfoh2013 = ///
    mdy(MESFIN, DIAFIN, ANIOFIN) ///
    if inrange(ANIOFIN, 2012, 2013)
format interview_date_sisfoh2013 %td
count if missing(interview_date_sisfoh2013)
local sisfoh2013_bad_calendar_date = r(N)

rename AREA sisfoh_area_2013
rename CATEG1 sisfoh_ccpp_category_2013
rename TVIV dwelling_type_2013
rename VIVES housing_tenure_2013
rename MPARED wall_material_2013
rename MTECHO roof_material_2013
rename MATPISO floor_material_2013
rename TALUM lighting_source_2013
rename ABASAG water_source_2013
rename SERHIG sanitation_source_2013
rename CTAHAB occupied_rooms_2013
rename COMBUSA cooking_fuel_2013
rename TOTAL source_person_total_2013
rename HOMBRES source_male_total_2013
rename MUJERES source_female_total_2013

egen byte asset_selected = ///
    anycount(BIEN1-BIEN14), ///
    values(1 2 3 4 5 6 7 8 9 10 11 12 13 14)
generate byte asset_none = BIEN15 == 15
assert asset_selected > 0 | asset_none
assert !(asset_selected > 0 & asset_none)

generate byte asset_sound_2013 = BIEN1 == 1
generate byte asset_tv_2013 = BIEN2 == 2
generate byte asset_dvd_2013 = BIEN3 == 3
generate byte asset_blender_2013 = BIEN4 == 4
generate byte asset_refrigerator_2013 = BIEN5 == 5
generate byte asset_gas_stove_2013 = BIEN6 == 6
generate byte asset_fixed_phone_2013 = BIEN7 == 7
generate byte asset_iron_2013 = BIEN8 == 8
generate byte asset_washing_machine_2013 = BIEN9 == 9
generate byte asset_computer_2013 = BIEN10 == 10
generate byte asset_microwave_2013 = BIEN11 == 11
generate byte asset_internet_2013 = BIEN12 == 12
generate byte asset_cable_2013 = BIEN13 == 13
generate byte asset_mobile_2013 = BIEN14 == 14
generate byte asset_any_2013 = asset_selected > 0

generate byte earth_floor_2013 = ///
    floor_material_2013 == 6 if !missing(floor_material_2013)
generate byte public_pylon_water_2013 = ///
    inlist(water_source_2013, 1, 2, 3) ///
    if !missing(water_source_2013)
generate byte improved_sanitation_2013 = ///
    inlist(sanitation_source_2013, 1, 2, 3, 4) ///
    if !missing(sanitation_source_2013)
generate byte electricity_2013 = ///
    lighting_source_2013 == 1 if !missing(lighting_source_2013)
generate byte clean_cooking_2013 = ///
    inlist(cooking_fuel_2013, 1, 2) if !missing(cooking_fuel_2013)

generate byte nbi1_housing_2013 = .
replace nbi1_housing_2013 = ///
    dwelling_type_2013 == 6 | ///
    wall_material_2013 == 7 | ///
    (floor_material_2013 == 6 & ///
     inlist(wall_material_2013, 4, 5, 6, 8)) ///
    if !missing( ///
        dwelling_type_2013, wall_material_2013, floor_material_2013)

generate double persons_per_room_2013 = ///
    hh_members_2013 / occupied_rooms_2013
generate byte nbi2_overcrowding_2013 = ///
    persons_per_room_2013 > 3.4 ///
    if !missing(persons_per_room_2013)
generate byte nbi3_sanitation_2013 = ///
    inlist(sanitation_source_2013, 5, 6) ///
    if !missing(sanitation_source_2013)
rename hh_nbi4_school_proxy_2013 nbi4_school_proxy_2013

generate byte nbi5_dependency_2013 = .
replace nbi5_dependency_2013 = 0 ///
    if hh_head_primary2less_2013 == 0
replace nbi5_dependency_2013 = 1 ///
    if hh_head_primary2less_2013 == 1 & ///
       hh_employment_valid_2013 == hh_members_2013 & ///
       (hh_employed_all_2013 == 0 | ///
        hh_members_2013 / hh_employed_all_2013 >= 4)
replace nbi5_dependency_2013 = 0 ///
    if hh_head_primary2less_2013 == 1 & ///
       hh_employment_valid_2013 == hh_members_2013 & ///
       hh_employed_all_2013 > 0 & ///
       hh_members_2013 / hh_employed_all_2013 < 4

egen byte nbi_count_2013 = rowtotal( ///
    nbi1_housing_2013 ///
    nbi2_overcrowding_2013 ///
    nbi3_sanitation_2013 ///
    nbi4_school_proxy_2013 ///
    nbi5_dependency_2013)
egen byte nbi_components_valid_2013 = rownonmiss( ///
    nbi1_housing_2013 ///
    nbi2_overcrowding_2013 ///
    nbi3_sanitation_2013 ///
    nbi4_school_proxy_2013 ///
    nbi5_dependency_2013)
replace nbi_count_2013 = . if nbi_components_valid_2013 < 5
generate byte nbi_any_2013 = nbi_count_2013 >= 1 ///
    if !missing(nbi_count_2013)
generate byte nbi_two_plus_2013 = nbi_count_2013 >= 2 ///
    if !missing(nbi_count_2013)

generate double wellbeing_housing_2013 = ///
    1 - earth_floor_2013 if !missing(earth_floor_2013)
generate double wellbeing_services_proxy_2013 = ///
    (public_pylon_water_2013 + improved_sanitation_2013) / 2 ///
    if !missing(public_pylon_water_2013, improved_sanitation_2013)
generate double wellbeing_energy_2013 = ///
    (electricity_2013 + clean_cooking_2013) / 2 ///
    if !missing(electricity_2013, clean_cooking_2013)
generate double wellbeing_humancapital_2013 = ///
    (hh_share_literate_2013 + hh_share_secondaryplus_2013) / 2 ///
    if !missing(hh_share_literate_2013, hh_share_secondaryplus_2013)
generate double wellbeing_assets_2013 = ///
    (asset_tv_2013 + asset_refrigerator_2013 + ///
     asset_washing_machine_2013 + asset_computer_2013) / 4
generate double wellbeing_connectivity_2013 = ///
    (asset_mobile_2013 + asset_internet_2013 + asset_cable_2013) / 3
generate double wellbeing_core_proxy_2013 = ///
    (wellbeing_housing_2013 + ///
     wellbeing_services_proxy_2013 + ///
     wellbeing_energy_2013 + ///
     wellbeing_humancapital_2013) / 4 ///
    if !missing( ///
        wellbeing_housing_2013, ///
        wellbeing_services_proxy_2013, ///
        wellbeing_energy_2013, ///
        wellbeing_humancapital_2013)
generate double deprivation_core_proxy_2013 = ///
    1 - wellbeing_core_proxy_2013 ///
    if !missing(wellbeing_core_proxy_2013)

label variable nbi4_school_proxy_2013 ///
    "INEI SISFOH proxy: child age 7-12 with no/initial education"
label variable nbi5_dependency_2013 ///
    "Official NBI high economic dependency indicator"
label variable roster_total_matches_2013 ///
    "Household total equals linked person-roster count"
label variable persons_per_room_2013 ///
    "Rostered people per occupied room"
label variable nbi1_housing_2013 ///
    "Official NBI inadequate-housing indicator"
label variable nbi2_overcrowding_2013 ///
    "Official NBI overcrowding indicator"
label variable nbi3_sanitation_2013 ///
    "Official NBI inadequate-sanitation indicator"
label variable nbi_any_2013 "Household has at least one NBI"
label variable nbi_two_plus_2013 "Household has at least two NBIs"
label variable earth_floor_2013 "Dwelling has an earth floor"
label variable public_pylon_water_2013 ///
    "Water from public network or public pylon"
label variable improved_sanitation_2013 ///
    "Sanitation is sewer, septic system, or latrine"
label variable electricity_2013 "Dwelling has electric lighting"
label variable clean_cooking_2013 "Household cooks with gas or electricity"
label variable wellbeing_services_proxy_2013 ///
    "Services proxy; SISFOH lacks daily water-availability item"
label variable wellbeing_core_proxy_2013 ///
    "Equal-domain 2013 wellbeing proxy; higher is better"
label variable deprivation_core_proxy_2013 ///
    "Equal-domain 2013 deprivation proxy; higher is worse"

drop ///
    DPTO PROV DIST CODCCPP_N ///
    SECUENCIA CONG NROVIV NHOGAR ///
    DIAFIN MESFIN ANIOFIN ///
    BIEN1-BIEN15 ///
    asset_selected asset_none

compress
sort sisfoh_hhid
isid sisfoh_hhid
count
assert r(N) == `sisfoh2013_households_info'
save ///
    "${intermediate_root}/21_sisfoh_2013_household_clean.dta", ///
    replace


*-------------------------------------------------------------------------------
**# 12.5 Aggregate households and assemble the national SISFOH CCPP file
*-------------------------------------------------------------------------------

generate byte household_one = 1
generate byte nbi_complete_aux = !missing(nbi_count_2013)
generate byte wellbeing_core_valid_aux = ///
    !missing(wellbeing_core_proxy_2013)
generate byte interview_date_valid_aux = ///
    !missing(interview_date_sisfoh2013)
generate byte household_any_program_aux = hh_program_any_2013 > 0
generate byte household_juntos_aux = hh_juntos_2013 > 0
generate byte household_any_insured_aux = hh_insured_2013 > 0

generate byte nbi1_count_aux = nbi1_housing_2013
generate byte nbi2_count_aux = nbi2_overcrowding_2013
generate byte nbi3_count_aux = nbi3_sanitation_2013
generate byte nbi4_count_aux = nbi4_school_proxy_2013
generate byte nbi5_count_aux = nbi5_dependency_2013
generate byte nbi_any_count_aux = nbi_any_2013
generate byte nbi_two_count_aux = nbi_two_plus_2013

collapse ///
    (sum) ///
        sisfoh2013_households=household_one ///
        sisfoh2013_complete_hh=sisfoh_interview_complete ///
        sisfoh2013_population_hh=hh_members_2013 ///
        sisfoh2013_dwelling_valid=household_items_valid_2013 ///
        sisfoh2013_nbi_complete=nbi_complete_aux ///
        sisfoh2013_core_valid=wellbeing_core_valid_aux ///
        sisfoh2013_date_valid=interview_date_valid_aux ///
        sisfoh2013_nbi1_count=nbi1_count_aux ///
        sisfoh2013_nbi2_count=nbi2_count_aux ///
        sisfoh2013_nbi3_count=nbi3_count_aux ///
        sisfoh2013_nbi4_count=nbi4_count_aux ///
        sisfoh2013_nbi5_count=nbi5_count_aux ///
        sisfoh2013_nbi_any_count=nbi_any_count_aux ///
        sisfoh2013_nbi_two_count=nbi_two_count_aux ///
    (mean) ///
        mean_household_size_2013=hh_members_2013 ///
        mean_persons_per_room_2013=persons_per_room_2013 ///
        share_interview_complete_2013=sisfoh_interview_complete ///
        share_household_items_valid_2013=household_items_valid_2013 ///
        share_nbi_complete_2013=nbi_complete_aux ///
        share_nbi1_housing_2013=nbi1_housing_2013 ///
        share_nbi2_overcrowding_2013=nbi2_overcrowding_2013 ///
        share_nbi3_sanitation_2013=nbi3_sanitation_2013 ///
        share_nbi4_school_proxy_2013=nbi4_school_proxy_2013 ///
        share_nbi5_dependency_2013=nbi5_dependency_2013 ///
        share_nbi_any_2013=nbi_any_2013 ///
        share_nbi_two_plus_2013=nbi_two_plus_2013 ///
        mean_nbi_count_2013=nbi_count_2013 ///
        share_earth_floor_2013=earth_floor_2013 ///
        share_water_public_pylon_2013=public_pylon_water_2013 ///
        share_sanitation_improved_2013=improved_sanitation_2013 ///
        share_electricity_2013=electricity_2013 ///
        share_clean_cooking_2013=clean_cooking_2013 ///
        share_asset_tv_2013=asset_tv_2013 ///
        share_asset_refrigerator_2013=asset_refrigerator_2013 ///
        share_asset_washing_machine_2013=asset_washing_machine_2013 ///
        share_asset_computer_2013=asset_computer_2013 ///
        share_asset_mobile_2013=asset_mobile_2013 ///
        share_asset_internet_2013=asset_internet_2013 ///
        share_asset_cable_2013=asset_cable_2013 ///
        share_household_any_insured_2013=household_any_insured_aux ///
        share_household_any_program_2013=household_any_program_aux ///
        share_household_juntos_2013=household_juntos_aux ///
        share_head_female_2013=hh_head_female_2013 ///
        mean_head_age_2013=hh_head_age_2013 ///
        wellbeing_housing_2013=wellbeing_housing_2013 ///
        wellbeing_services_proxy_2013=wellbeing_services_proxy_2013 ///
        wellbeing_energy_2013=wellbeing_energy_2013 ///
        wellbeing_humancapital_2013=wellbeing_humancapital_2013 ///
        wellbeing_assets_2013=wellbeing_assets_2013 ///
        wellbeing_connectivity_2013=wellbeing_connectivity_2013 ///
        wellbeing_core_proxy_2013=wellbeing_core_proxy_2013 ///
        deprivation_core_proxy_2013=deprivation_core_proxy_2013 ///
    (min) ///
        sisfoh2013_fieldwork_start=interview_date_sisfoh2013 ///
    (max) ///
        sisfoh2013_fieldwork_end=interview_date_sisfoh2013, ///
    by(ubigeo_ccpp_sisfoh)

format ///
    sisfoh2013_fieldwork_start ///
    sisfoh2013_fieldwork_end %td

compress
sort ubigeo_ccpp_sisfoh
isid ubigeo_ccpp_sisfoh
count
assert r(N) == `sisfoh2013_source_ccpp'
save ///
    "${intermediate_root}/22_sisfoh_2013_household_ccpp.dta", ///
    replace

use ///
    "${intermediate_root}/20_sisfoh_2013_person_ccpp.dta", ///
    clear
merge 1:1 ubigeo_ccpp_sisfoh using ///
    "${intermediate_root}/22_sisfoh_2013_household_ccpp.dta"
assert _merge == 3
drop _merge

assert sisfoh2013_population == sisfoh2013_population_hh
assert sisfoh2013_person_households == sisfoh2013_households
drop ///
    sisfoh2013_population_hh ///
    sisfoh2013_person_households

merge 1:1 ubigeo_ccpp_sisfoh using `sisfoh_ccpp_directory'
assert _merge == 3
drop _merge

label variable sisfoh2013_population ///
    "Rostered SISFOH population with household information"
label variable sisfoh2013_households ///
    "SISFOH households with complete or incomplete information"
label variable language_coverage_2013 ///
    "Valid childhood-language responses among eligible people"
label variable share_literate_2013 ///
    "Share of valid people age 14+ who can read and write"
label variable share_educ_secondaryplus_2013 ///
    "Share of valid people age 14+ with secondary or higher education"
label variable share_any_insurance_2013 ///
    "Share of rostered people reporting any health insurance"
label variable share_any_disability_2013 ///
    "Share of rostered people reporting a permanent limitation"
label variable labor_force_participation_2013 ///
    "Labor-force share among valid people age 14+"
label variable employment_rate_2013 ///
    "Employment share of the labor force age 14+"
label variable unemployment_rate_2013 ///
    "Unemployment share of the labor force age 14+"
label variable share_nbi4_school_proxy_2013 ///
    "Share of households meeting INEI SISFOH school proxy NBI"
label variable wellbeing_core_proxy_2013 ///
    "Mean household equal-domain 2013 wellbeing proxy"

compress
sort ubigeo_ccpp_sisfoh
isid ubigeo_ccpp_sisfoh
count
local sisfoh2013_ccpp_rows = r(N)
assert `sisfoh2013_ccpp_rows' == `sisfoh2013_source_ccpp'
save ///
    "${intermediate_root}/23_sisfoh_2013_ccpp.dta", ///
    replace


*-------------------------------------------------------------------------------
**# 12.6 Reconcile the legacy CCPP compilation without using it as an input
*-------------------------------------------------------------------------------

use ///
    ccpp pob hog viv ///
    sis_nbi1 sis_nbi2 sis_nbi3 sis_nbi5 ///
    using "`sisfoh_legacy_ccpp_raw'", clear

rename ccpp ubigeo_ccpp_sisfoh
rename pob legacy_population_2013
rename hog legacy_households_2013
rename viv legacy_dwellings_2013
rename sis_nbi1 legacy_nbi1_count_2013
rename sis_nbi2 legacy_nbi2_count_2013
rename sis_nbi3 legacy_nbi3_count_2013
rename sis_nbi5 legacy_nbi5_count_2013

isid ubigeo_ccpp_sisfoh
merge 1:1 ubigeo_ccpp_sisfoh using ///
    "${intermediate_root}/23_sisfoh_2013_ccpp.dta", ///
    keep(master match) ///
    keepusing( ///
        sisfoh2013_population ///
        sisfoh2013_households ///
        sisfoh2013_nbi1_count ///
        sisfoh2013_nbi2_count ///
        sisfoh2013_nbi3_count ///
        sisfoh2013_nbi5_count)

count if _merge == 3
local sisfoh2013_legacy_ccpp_matched = r(N)

generate double population_difference = ///
    sisfoh2013_population - legacy_population_2013 ///
    if _merge == 3
generate double household_difference = ///
    sisfoh2013_households - legacy_households_2013 ///
    if _merge == 3
generate double nbi1_difference = ///
    sisfoh2013_nbi1_count - legacy_nbi1_count_2013 ///
    if _merge == 3
generate double nbi2_difference = ///
    sisfoh2013_nbi2_count - legacy_nbi2_count_2013 ///
    if _merge == 3
generate double nbi3_difference = ///
    sisfoh2013_nbi3_count - legacy_nbi3_count_2013 ///
    if _merge == 3
generate double nbi5_difference = ///
    sisfoh2013_nbi5_count - legacy_nbi5_count_2013 ///
    if _merge == 3

count if _merge == 3 & population_difference == 0
local sisfoh2013_legacy_pop_exact = r(N)
count if _merge == 3 & household_difference == 0
local sisfoh2013_legacy_hh_exact = r(N)
count if _merge == 3 & nbi1_difference == 0
local sisfoh2013_legacy_nbi1_exact = r(N)
count if _merge == 3 & nbi2_difference == 0
local sisfoh2013_legacy_nbi2_exact = r(N)
count if _merge == 3 & nbi3_difference == 0
local sisfoh2013_legacy_nbi3_exact = r(N)
count if _merge == 3 & nbi5_difference == 0
local sisfoh2013_legacy_nbi5_exact = r(N)

generate str28 reconciliation_status = cond( ///
    _merge == 1, ///
    "legacy_code_absent_microdata", ///
    "matched_for_reconciliation")
drop _merge

save ///
    "${qa_data_root}/sisfoh2013_legacy_ccpp_reconciliation.dta", ///
    replace
export delimited ///
    "${qa_data_root}/sisfoh2013_legacy_ccpp_reconciliation.csv", ///
    replace


*-------------------------------------------------------------------------------
**# 12.7 Link SISFOH CCPPs to the RUV universe without fuzzy acceptance
*-------------------------------------------------------------------------------

use ubigeo_ccpp_sisfoh using ///
    "${intermediate_root}/23_sisfoh_2013_ccpp.dta", ///
    clear
rename ubigeo_ccpp_sisfoh link_code
isid link_code
save `sisfoh_source_codes'

use ruv_id ubigeo_ccpp using ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear
rename ubigeo_ccpp link_code
drop if missing(link_code)
generate byte link_priority = 1
generate str28 sisfoh2013_link_method = "current_ubigeo_exact"
save `sisfoh_link_candidates'

use ruv_id census2007_ubigeo_ccpp using ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear
rename census2007_ubigeo_ccpp link_code
drop if missing(link_code)
generate byte link_priority = 2
generate str28 sisfoh2013_link_method = "census2007_code_exact"
append using `sisfoh_link_candidates'
save `sisfoh_link_candidates', replace

use ruv_id geospatial_ubigeo_ccpp using ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear
rename geospatial_ubigeo_ccpp link_code
drop if missing(link_code)
generate byte link_priority = 3
generate str28 sisfoh2013_link_method = "geospatial_code_exact"
append using `sisfoh_link_candidates'
save `sisfoh_link_candidates', replace

use ruv_id gdp_ccpp_ubigeo using ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear
rename gdp_ccpp_ubigeo link_code
drop if missing(link_code)
generate byte link_priority = 4
generate str28 sisfoh2013_link_method = "gdp_source_code_exact"
append using `sisfoh_link_candidates'

bysort ruv_id link_code (link_priority): keep if _n == 1
merge m:1 link_code using `sisfoh_source_codes', ///
    keep(match) nogen

bysort link_code: egen byte minimum_priority = min(link_priority)
keep if link_priority == minimum_priority
bysort link_code: generate byte best_priority_candidates = _N

preserve
keep if best_priority_candidates > 1
save ///
    "${qa_data_root}/sisfoh2013_ambiguous_code_candidates.dta", ///
    replace
export delimited ///
    "${qa_data_root}/sisfoh2013_ambiguous_code_candidates.csv", ///
    replace
restore

count if best_priority_candidates > 1
local sisfoh2013_ambiguous_code_rows = r(N)
keep if best_priority_candidates == 1

bysort ruv_id (link_priority link_code): keep if _n == 1
rename link_code ubigeo_ccpp_sisfoh
keep ///
    ruv_id ubigeo_ccpp_sisfoh ///
    sisfoh2013_link_method link_priority
isid ruv_id
isid ubigeo_ccpp_sisfoh
save `sisfoh_code_links'

keep ubigeo_ccpp_sisfoh
isid ubigeo_ccpp_sisfoh
save `sisfoh_used_source_codes'

use ///
    ubigeo_ccpp_sisfoh ///
    department_name_sisfoh2013 ///
    province_name_sisfoh2013 ///
    district_name_sisfoh2013 ///
    ccpp_name_sisfoh2013 ///
    using "${intermediate_root}/23_sisfoh_2013_ccpp.dta", ///
    clear

victimasrd_normalize_name ///
    department_name_sisfoh2013, generate(dpto_norm)
victimasrd_normalize_name ///
    province_name_sisfoh2013, generate(prov_norm)
victimasrd_normalize_name ///
    district_name_sisfoh2013, generate(dist_norm)
victimasrd_normalize_name ///
    ccpp_name_sisfoh2013, generate(ccpp_norm)

bysort dpto_norm prov_norm dist_norm ccpp_norm: ///
    generate int source_path_count = _N
keep if source_path_count == 1
keep ///
    ubigeo_ccpp_sisfoh ///
    dpto_norm prov_norm dist_norm ccpp_norm
isid dpto_norm prov_norm dist_norm ccpp_norm
save `sisfoh_name_links'

use ///
    ruv_id ///
    dpto_victim_raw prov_victim_raw ///
    dist_victim_raw ccpp_victim_raw ///
    using "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear

merge 1:1 ruv_id using `sisfoh_code_links'
keep if _merge == 1
drop _merge ubigeo_ccpp_sisfoh sisfoh2013_link_method link_priority

victimasrd_normalize_name dpto_victim_raw, generate(dpto_norm)
victimasrd_normalize_name prov_victim_raw, generate(prov_norm)
victimasrd_normalize_name dist_victim_raw, generate(dist_norm)
victimasrd_normalize_name ccpp_victim_raw, generate(ccpp_norm)

drop if missing(dpto_norm, prov_norm, dist_norm, ccpp_norm)
bysort dpto_norm prov_norm dist_norm ccpp_norm: ///
    generate int ruv_path_count = _N
keep if ruv_path_count == 1

merge 1:1 ///
    dpto_norm prov_norm dist_norm ccpp_norm ///
    using `sisfoh_name_links', keep(match) nogen

merge m:1 ubigeo_ccpp_sisfoh using ///
    `sisfoh_used_source_codes'
keep if _merge == 1
drop _merge

generate str28 sisfoh2013_link_method = "unique_exact_full_path"
generate byte link_priority = 5
keep ///
    ruv_id ubigeo_ccpp_sisfoh ///
    sisfoh2013_link_method link_priority
isid ruv_id
isid ubigeo_ccpp_sisfoh
save `sisfoh_name_links', replace

append using `sisfoh_code_links'
sort ruv_id
isid ruv_id
isid ubigeo_ccpp_sisfoh

count if sisfoh2013_link_method == "current_ubigeo_exact"
local sisfoh2013_exact_current = r(N)
count if sisfoh2013_link_method == "census2007_code_exact"
local sisfoh2013_exact_census = r(N)
count if sisfoh2013_link_method == "geospatial_code_exact"
local sisfoh2013_exact_geospatial = r(N)
count if sisfoh2013_link_method == "gdp_source_code_exact"
local sisfoh2013_exact_gdp = r(N)
count if sisfoh2013_link_method == "unique_exact_full_path"
local sisfoh2013_exact_name = r(N)
count
local sisfoh2013_ruv_linked = r(N)
local sisfoh2013_ruv_unmatched = 5712 - `sisfoh2013_ruv_linked'

save `sisfoh_ruv_links'
save ///
    "${intermediate_root}/24_ruv_sisfoh_2013_links.dta", ///
    replace

use ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear
merge 1:1 ruv_id using `sisfoh_ruv_links'
keep if _merge == 1
drop _merge
generate str52 linkage_disposition = ///
    "retained_ruv_without_deterministic_sisfoh_link"
save ///
    "${qa_data_root}/sisfoh2013_unmatched_ruv.dta", ///
    replace
export delimited ///
    "${qa_data_root}/sisfoh2013_unmatched_ruv.csv", ///
    replace


*-------------------------------------------------------------------------------
**# 12.8 Create linked analysis files at all three levels
*-------------------------------------------------------------------------------

use ///
    "${intermediate_root}/18_sisfoh_2013_person_clean.dta", ///
    clear
merge m:1 ubigeo_ccpp_sisfoh using `sisfoh_ruv_links', ///
    keep(match)
assert _merge == 3
drop _merge link_priority

merge m:1 ruv_id using ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    keep(match)
assert _merge == 3
drop _merge

compress
sort sisfoh_pid
isid sisfoh_pid
count
local sisfoh2013_indiv_rows = r(N)
save ///
    "${analysis_data_root}/09_sisfoh_2013_individual_analysis.dta", ///
    replace

use ///
    "${intermediate_root}/21_sisfoh_2013_household_clean.dta", ///
    clear
merge m:1 ubigeo_ccpp_sisfoh using `sisfoh_ruv_links', ///
    keep(match)
assert _merge == 3
drop _merge link_priority

merge m:1 ruv_id using ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    keep(match)
assert _merge == 3
drop _merge

compress
sort sisfoh_hhid
isid sisfoh_hhid
count
local sisfoh2013_hh_analysis_rows = r(N)
save ///
    "${analysis_data_root}/10_sisfoh_2013_household_analysis.dta", ///
    replace

use ///
    "${intermediate_root}/23_sisfoh_2013_ccpp.dta", ///
    clear
merge 1:1 ubigeo_ccpp_sisfoh using `sisfoh_ruv_links', ///
    keep(match)
assert _merge == 3
drop _merge link_priority
isid ruv_id
save `sisfoh_ccpp_linked'

use ///
    "${analysis_data_root}/08_community_registry_elections.dta", ///
    clear
merge 1:1 ruv_id using `sisfoh_ccpp_linked'
generate byte sisfoh2013_linked = _merge == 3
drop _merge

label variable sisfoh2013_linked ///
    "RUV community linked deterministically to SISFOH 2012-2013"
label variable sisfoh2013_link_method ///
    "Deterministic method linking RUV and SISFOH CCPP"

count if sisfoh2013_linked
assert r(N) == `sisfoh2013_ruv_linked'
count if sample_main_rd & sisfoh2013_linked
local sisfoh2013_main_sample_linked = r(N)

compress
sort ruv_id
isid ruv_id
count
local sisfoh2013_registry_rows = r(N)
assert `sisfoh2013_registry_rows' == `electoral_registry_rows'
assert `sisfoh2013_registry_rows' == 5712
save ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta", ///
    replace

*===============================================================================
**# 13. Prepare Census 2017 at person, household, and CCPP levels
*===============================================================================

local census2017_person_public ///
    "${raw_root}/16 Censo 2017/1-pob.dta"
local census2017_household_public ///
    "${raw_root}/16 Censo 2017/2-hog.dta"
local census2017_dwelling_public ///
    "${raw_root}/16 Censo 2017/3-viv.dta"
local census2017_linked_raw ///
    "${raw_root}/16 Censo 2017/CCPP_SISFOH_CPV_ENTREGAOKA.dta"
local census2017_source_crosswalk ///
    "${metadata_root}/census-2017/source-ccpp-crosswalk.csv"

foreach census2017_source in ///
    "`census2017_person_public'" ///
    "`census2017_household_public'" ///
    "`census2017_dwelling_public'" ///
    "`census2017_linked_raw'" ///
    "`census2017_source_crosswalk'" {

    capture confirm file "`census2017_source'"
    if _rc {
        display as error "Required Census 2017 source is unavailable:"
        display as error "  `census2017_source'"
        exit 601
    }
}

tempfile ///
    census2017_source_links ///
    census2017_person_key_map ///
    census2017_district_key_map ///
    census2017_person_clean ///
    census2017_household_keys ///
    census2017_household_clean ///
    census2017_ccpp_person ///
    census2017_ccpp_household ///
    census2017_ccpp_linked


*-------------------------------------------------------------------------------
**# 13.1 Validate the national public modules and their geography limit
*-------------------------------------------------------------------------------

quietly describe using "`census2017_person_public'"
local census2017_public_person_rows = r(N)
local census2017_public_person_vars = r(k)
assert `census2017_public_person_rows' == 29381884
assert `census2017_public_person_vars' == 74
capture quietly describe ///
    poblacio_ref_id hogar_ref_id ///
    using "`census2017_person_public'"
if _rc {
    display as error "The public Census person-module key contract changed."
    exit 459
}

quietly describe using "`census2017_household_public'"
local census2017_public_hh_rows = r(N)
local census2017_public_hh_vars = r(k)
assert `census2017_public_hh_rows' == 8283285
assert `census2017_public_hh_vars' == 36
capture quietly describe ///
    hogar_ref_id vivienda_ref_id ///
    using "`census2017_household_public'"
if _rc {
    display as error "The public Census household-module key contract changed."
    exit 459
}

quietly describe using "`census2017_dwelling_public'"
local cpv2017_public_dwelling_rows = r(N)
local census2017_public_dwelling_vars = r(k)
assert `cpv2017_public_dwelling_rows' == 10133850
assert `census2017_public_dwelling_vars' == 22
capture quietly describe ///
    vivienda_ref_id distrito_ref_id ///
    using "`census2017_dwelling_public'"
if _rc {
    display as error "The public Census dwelling-module key contract changed."
    exit 459
}

/*
The national public modules identify districts but not source CCPPs. They
therefore validate official national schemas and counts but cannot replace the
INEI-assisted CCPP linkage used below.
*/


*-------------------------------------------------------------------------------
**# 13.2 Validate the frozen source-CCPP-to-RUV crosswalk
*-------------------------------------------------------------------------------

import delimited ///
    using "`census2017_source_crosswalk'", ///
    varnames(1) ///
    stringcols(_all) ///
    encoding(utf8) ///
    clear

keep source_ccpp_code ruv_id match_method validation review_status
assert regexm(source_ccpp_code, "^[0-9]{10}$")
assert regexm(ruv_id, "^S[0-9]{8}$")
assert review_status == "accepted"
assert validation != ""
isid source_ccpp_code

count
local census2017_source_ccpp_rows = r(N)
assert `census2017_source_ccpp_rows' == 807

egen byte census2017_ruv_tag = tag(ruv_id)
count if census2017_ruv_tag
local census2017_source_ruv_rows = r(N)
assert `census2017_source_ruv_rows' == 803
drop census2017_ruv_tag review_status validation
rename match_method census2017_ccpp_link_method
save `census2017_source_links'


*-------------------------------------------------------------------------------
**# 13.3 Recover canonical SISFOH person and household keys
*-------------------------------------------------------------------------------

use ///
    ubigeo_ccpp idccpp_sisfoh idccpp2019 etapa ///
    id_hogar_m nroviv3 nhogar nro llave ///
    id_viv_imp_f id_hog_imp_f id_pob_imp_f ///
    edad01 ptes01 sexo01 gesta01 esta01 ///
    segu01_1-segu01_6 ///
    idioma01 lee01 niv01 ult01 era01 sect01 ///
    disca01_1-disca01_6 prog01_1-prog01_11 ///
    c5_p1 c5_p2 c5_p4_1 c5_p5 c5_p6 ///
    c5_p8_1-c5_p8_6 c5_p9_1-c5_p9_7 ///
    c5_p11 c5_p12 ///
    c5_p13_niv c5_p13_gra ///
    c5_p13_anio_pri c5_p13_anio_sec ///
    c5_p14 c5_p16 c5_p17 c5_p18 ///
    c5_p19_cod c5_p20_cod c5_p21 c5_p22 ///
    c5_p24 c5_p25_i_mc ///
    c2_p1 c2_p3 c2_p4 c2_p5 c2_p6 c2_p7 ///
    c2_p10 c2_p11 c2_p12 c2_p13 t_c4_p1 ///
    c3_p1_1-c3_p1_8 c3_p2_1-c3_p2_16 ///
    c3_p3 c3_p3a c4_p1 ///
    using "`census2017_linked_raw'", clear

count
local census2017_cohort_rows = r(N)
assert `census2017_cohort_rows' == 193376
isid llave

rename ubigeo_ccpp source_ccpp_code
rename idccpp_sisfoh source_ccpp_inei
rename idccpp2019 destination_ccpp_code
rename etapa census2017_link_stage
rename nroviv3 sisfoh_dwelling_number
rename nhogar sisfoh_household_number
rename nro sisfoh_person_number

foreach string_key in ///
    source_ccpp_code ///
    source_ccpp_inei ///
    sisfoh_dwelling_number {
    replace `string_key' = ustrtrim(`string_key')
}
destring ///
    sisfoh_household_number sisfoh_person_number, ///
    replace

replace source_ccpp_code = ///
    string(real(source_ccpp_code), "%010.0f") ///
    if source_ccpp_code != ""
replace source_ccpp_inei = ///
    string(real(source_ccpp_inei), "%010.0f") ///
    if source_ccpp_inei != ""
replace destination_ccpp_code = ///
    string(real(destination_ccpp_code), "%010.0f") ///
    if destination_ccpp_code != ""

assert regexm(source_ccpp_code, "^[0-9]{10}$")
assert regexm(source_ccpp_inei, "^[0-9]{10}$")
assert regexm(destination_ccpp_code, "^[0-9]{10}$") | ///
    destination_ccpp_code == ""

sort llave
generate long census2017_cohort_pid = _n
egen long census2017_baseline_hhid = group(id_hogar_m)
egen long cpv2017_destination_hhid = group(id_hog_imp_f) ///
    if !missing(id_hog_imp_f)

egen byte census2017_baseline_hh_tag = ///
    tag(census2017_baseline_hhid)
count if census2017_baseline_hh_tag
local census2017_baseline_hh_rows = r(N)
assert `census2017_baseline_hh_rows' == 58021
drop census2017_baseline_hh_tag

generate byte census2017_linked = ///
    inrange(census2017_link_stage, 0, 3) & ///
    destination_ccpp_code != ""
assert census2017_linked == (destination_ccpp_code != "")
generate byte census2017_not_linked = !census2017_linked

count if census2017_linked
local census2017_linked_rows = r(N)
assert `census2017_linked_rows' == 150864
count if census2017_not_linked
local census2017_not_linked_rows = r(N)
assert `census2017_not_linked_rows' == 42512

forvalues stage = 0/3 {
    count if census2017_link_stage == `stage'
    local census2017_stage`stage'_rows = r(N)
}
assert `census2017_stage0_rows' == 128908
assert `census2017_stage1_rows' == 7433
assert `census2017_stage2_rows' == 10530
assert `census2017_stage3_rows' == 3993

merge m:1 source_ccpp_code using `census2017_source_links'
assert _merge == 3
drop _merge

merge m:1 ruv_id using ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta", ///
    keep(master match) ///
    keepusing(ubigeo_ccpp)
assert _merge == 3
drop _merge

use ///
    "${intermediate_root}/25_sisfoh_2013_person_linkage_keys.dta", ///
    clear
keep ///
    ubigeo_ccpp_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    sisfoh_pid sisfoh_hhid
rename sisfoh_pid sisfoh_pid_candidate
rename sisfoh_hhid sisfoh_hhid_candidate
isid ///
    ubigeo_ccpp_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number
save `census2017_person_key_map'

use ///
    "${intermediate_root}/25_sisfoh_2013_person_linkage_keys.dta", ///
    clear
keep ///
    ubigeo_district_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    sisfoh_age_key sisfoh_sex_key ///
    sisfoh_pid sisfoh_hhid
drop if missing(sisfoh_age_key, sisfoh_sex_key)
bysort ///
    ubigeo_district_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    sisfoh_age_key sisfoh_sex_key: ///
    generate byte district_key_count = _N
keep if district_key_count == 1
drop district_key_count
rename sisfoh_pid sisfoh_pid_candidate
rename sisfoh_hhid sisfoh_hhid_candidate
isid ///
    ubigeo_district_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    sisfoh_age_key sisfoh_sex_key
save `census2017_district_key_map'

use "`census2017_linked_raw'", clear
keep ///
    ubigeo_ccpp idccpp_sisfoh idccpp2019 etapa ///
    id_hogar_m nroviv3 nhogar nro llave ///
    id_viv_imp_f id_hog_imp_f id_pob_imp_f ///
    edad01 ptes01 sexo01 gesta01 esta01 ///
    segu01_1-segu01_6 ///
    idioma01 lee01 niv01 ult01 era01 sect01 ///
    disca01_1-disca01_6 prog01_1-prog01_11 ///
    c5_p1 c5_p2 c5_p4_1 c5_p5 c5_p6 ///
    c5_p8_1-c5_p8_6 c5_p9_1-c5_p9_7 ///
    c5_p11 c5_p12 ///
    c5_p13_niv c5_p13_gra ///
    c5_p13_anio_pri c5_p13_anio_sec ///
    c5_p14 c5_p16 c5_p17 c5_p18 ///
    c5_p19_cod c5_p20_cod c5_p21 c5_p22 ///
    c5_p24 c5_p25_i_mc ///
    c2_p1 c2_p3 c2_p4 c2_p5 c2_p6 c2_p7 ///
    c2_p10 c2_p11 c2_p12 c2_p13 t_c4_p1 ///
    c3_p1_1-c3_p1_8 c3_p2_1-c3_p2_16 ///
    c3_p3 c3_p3a c4_p1

rename ubigeo_ccpp source_ccpp_code
rename idccpp_sisfoh source_ccpp_inei
rename idccpp2019 destination_ccpp_code
rename etapa census2017_link_stage
rename nroviv3 sisfoh_dwelling_number
rename nhogar sisfoh_household_number
rename nro sisfoh_person_number

foreach string_key in ///
    source_ccpp_code ///
    source_ccpp_inei ///
    sisfoh_dwelling_number {
    replace `string_key' = ustrtrim(`string_key')
}
destring ///
    sisfoh_household_number sisfoh_person_number, ///
    replace

replace source_ccpp_code = ///
    string(real(source_ccpp_code), "%010.0f") ///
    if source_ccpp_code != ""
replace source_ccpp_inei = ///
    string(real(source_ccpp_inei), "%010.0f") ///
    if source_ccpp_inei != ""
replace destination_ccpp_code = ///
    string(real(destination_ccpp_code), "%010.0f") ///
    if destination_ccpp_code != ""

sort llave
generate long census2017_cohort_pid = _n
egen long census2017_baseline_hhid = group(id_hogar_m)
egen long cpv2017_destination_hhid = group(id_hog_imp_f) ///
    if !missing(id_hog_imp_f)
generate byte census2017_linked = ///
    inrange(census2017_link_stage, 0, 3) & ///
    destination_ccpp_code != ""
generate byte census2017_not_linked = !census2017_linked

merge m:1 source_ccpp_code using `census2017_source_links'
assert _merge == 3
drop _merge
merge m:1 ruv_id using ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta", ///
    keep(master match) ///
    keepusing(ubigeo_ccpp)
assert _merge == 3
drop _merge

generate str10 ubigeo_ccpp_sisfoh = source_ccpp_code
merge m:1 ///
    ubigeo_ccpp_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    using `census2017_person_key_map', ///
    keep(master match)
generate long sisfoh_pid = sisfoh_pid_candidate if _merge == 3
generate long sisfoh_hhid = sisfoh_hhid_candidate if _merge == 3
generate str28 census2017_person_link_method = ///
    "source_ccpp_roster_exact" if _merge == 3
count if _merge == 3
local census2017_person_key_source = r(N)
assert `census2017_person_key_source' == 191832
drop _merge sisfoh_pid_candidate sisfoh_hhid_candidate

replace ubigeo_ccpp_sisfoh = source_ccpp_inei
merge m:1 ///
    ubigeo_ccpp_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    using `census2017_person_key_map', ///
    keep(master match)
count if missing(sisfoh_pid) & _merge == 3
local census2017_person_key_inei = r(N)
assert `census2017_person_key_inei' == 442
replace sisfoh_pid = sisfoh_pid_candidate ///
    if missing(sisfoh_pid) & _merge == 3
replace sisfoh_hhid = sisfoh_hhid_candidate ///
    if missing(sisfoh_hhid) & _merge == 3
replace census2017_person_link_method = ///
    "inei_ccpp_roster_exact" ///
    if census2017_person_link_method == "" & _merge == 3
drop _merge sisfoh_pid_candidate sisfoh_hhid_candidate

generate str6 ubigeo_district_sisfoh = substr(source_ccpp_inei, 1, 6)
generate byte sisfoh_age_key = edad01
generate byte sisfoh_sex_key = sexo01
merge m:1 ///
    ubigeo_district_sisfoh ///
    sisfoh_dwelling_number ///
    sisfoh_household_number ///
    sisfoh_person_number ///
    sisfoh_age_key sisfoh_sex_key ///
    using `census2017_district_key_map', ///
    keep(master match)
count if missing(sisfoh_pid) & _merge == 3
local census2017_person_key_district = r(N)
assert `census2017_person_key_district' == 165
replace sisfoh_pid = sisfoh_pid_candidate ///
    if missing(sisfoh_pid) & _merge == 3
replace sisfoh_hhid = sisfoh_hhid_candidate ///
    if missing(sisfoh_hhid) & _merge == 3
replace census2017_person_link_method = ///
    "unique_district_roster_demo" ///
    if census2017_person_link_method == "" & _merge == 3
drop _merge sisfoh_pid_candidate sisfoh_hhid_candidate

generate byte census2017_person_key_linked = !missing(sisfoh_pid)
count if !census2017_person_key_linked
local cpv2017_person_key_unresolved = r(N)
assert `cpv2017_person_key_unresolved' == 937

bysort census2017_baseline_hhid: ///
    egen long sisfoh_hhid_min = min(sisfoh_hhid)
bysort census2017_baseline_hhid: ///
    egen long sisfoh_hhid_max = max(sisfoh_hhid)
count if ///
    !missing(sisfoh_hhid_min) & ///
    sisfoh_hhid_min != sisfoh_hhid_max
local cpv2017_hh_conflict_persons = r(N)
assert `cpv2017_hh_conflict_persons' == 25
generate byte census2017_hh_key_conflict = ///
    !missing(sisfoh_hhid_min, sisfoh_hhid_max) & ///
    sisfoh_hhid_min != sisfoh_hhid_max
egen byte census2017_hh_conflict_tag = ///
    tag(census2017_baseline_hhid) ///
    if census2017_hh_key_conflict
count if census2017_hh_conflict_tag
local cpv2017_hh_key_conflicts = r(N)
assert `cpv2017_hh_key_conflicts' == 5
replace sisfoh_hhid = . if census2017_hh_key_conflict
replace sisfoh_hhid = sisfoh_hhid_min ///
    if missing(sisfoh_hhid) & !census2017_hh_key_conflict
drop ///
    sisfoh_hhid_min sisfoh_hhid_max ///
    census2017_hh_conflict_tag
generate byte census2017_hh_key_linked = !missing(sisfoh_hhid)

preserve
keep if !census2017_person_key_linked
keep ///
    census2017_cohort_pid census2017_baseline_hhid ///
    ruv_id census2017_ccpp_link_method ///
    census2017_person_link_method
sort ruv_id census2017_cohort_pid
save ///
    "${qa_data_root}/census2017_person_key_unresolved.dta", ///
    replace
restore

merge m:1 sisfoh_pid using ///
    "${intermediate_root}/18_sisfoh_2013_person_clean.dta", ///
    keep(master match)
generate byte cpv2017_sisfoh_person_match = _merge == 3
count if ///
    cpv2017_sisfoh_person_match & ///
    !missing(age_2013, edad01) & age_2013 != edad01
local cpv2017_sisfoh_age_disagree = r(N)
count if ///
    cpv2017_sisfoh_person_match & ///
    !missing(female_2013, sexo01) & ///
    female_2013 != (sexo01 == 2)
local cpv2017_sisfoh_sex_disagree = r(N)
drop _merge

replace age_2013 = edad01 ///
    if missing(age_2013) & inrange(edad01, 0, 120)
replace female_2013 = sexo01 == 2 ///
    if missing(female_2013) & inlist(sexo01, 1, 2)
replace household_head_2013 = ptes01 == 1 ///
    if missing(household_head_2013) & inrange(ptes01, 1, 14)
replace relation_head_2013 = ptes01 ///
    if missing(relation_head_2013) & inrange(ptes01, 1, 14)
replace language_childhood_2013 = idioma01 ///
    if missing(language_childhood_2013) & ///
       age_2013 >= 3 & inrange(idioma01, 1, 7)
replace spanish_childhood_2013 = language_childhood_2013 == 4 ///
    if missing(spanish_childhood_2013) & ///
       !missing(language_childhood_2013)
replace named_indigenous_language_2013 = ///
    inlist(language_childhood_2013, 1, 2, 3) ///
    if missing(named_indigenous_language_2013) & ///
       !missing(language_childhood_2013)
replace nonspanish_language_2013 = language_childhood_2013 != 4 ///
    if missing(nonspanish_language_2013) & ///
       !missing(language_childhood_2013)
replace literate_2013 = lee01 == 1 ///
    if missing(literate_2013) & age_2013 >= 3 & inlist(lee01, 1, 2)
replace education_level_2013 = niv01 ///
    if missing(education_level_2013) & ///
       age_2013 >= 3 & inrange(niv01, 1, 7)
replace last_grade_2013 = ult01 ///
    if missing(last_grade_2013) & ///
       inrange(education_level_2013, 3, 7) & ///
       inrange(ult01, 1, 6)
replace secondaryplus_2013 = education_level_2013 >= 4 ///
    if missing(secondaryplus_2013) & !missing(education_level_2013)
replace primary_complete_2013 = 0 ///
    if missing(primary_complete_2013) & ///
       inlist(education_level_2013, 1, 2)
replace primary_complete_2013 = last_grade_2013 == 6 ///
    if missing(primary_complete_2013) & ///
       education_level_2013 == 3 & !missing(last_grade_2013)
replace primary_complete_2013 = 1 ///
    if missing(primary_complete_2013) & ///
       inrange(education_level_2013, 4, 7)
replace labor_status_2013 = era01 ///
    if missing(labor_status_2013) & ///
       age_2013 >= 6 & inrange(era01, 1, 10)
replace employed_2013 = inrange(labor_status_2013, 1, 5) ///
    if missing(employed_2013) & !missing(labor_status_2013)
replace labor_force_2013 = inrange(labor_status_2013, 1, 6) ///
    if missing(labor_force_2013) & !missing(labor_status_2013)
replace unemployed_2013 = labor_status_2013 == 6 ///
    if missing(unemployed_2013) & !missing(labor_status_2013)
replace employment_sector_2013 = sect01 ///
    if missing(employment_sector_2013) & ///
       employed_2013 == 1 & inrange(sect01, 1, 10)


*-------------------------------------------------------------------------------
**# 13.4 Construct linked-person and migration measures
*-------------------------------------------------------------------------------

egen byte source_insurance_count_aux = ///
    anycount(segu01_1-segu01_5), values(1 2 3 4 5)
replace insurance_any_2013 = source_insurance_count_aux > 0 ///
    if missing(insurance_any_2013) & ///
       (source_insurance_count_aux > 0 | segu01_6 == 6)
replace insurance_essalud_2013 = segu01_1 == 1 ///
    if missing(insurance_essalud_2013) & ///
       (source_insurance_count_aux > 0 | segu01_6 == 6)
replace insurance_private_2013 = segu01_3 == 3 ///
    if missing(insurance_private_2013) & ///
       (source_insurance_count_aux > 0 | segu01_6 == 6)
replace insurance_sis_2013 = segu01_4 == 4 ///
    if missing(insurance_sis_2013) & ///
       (source_insurance_count_aux > 0 | segu01_6 == 6)

egen byte source_disability_count_aux = ///
    anycount(disca01_1-disca01_5), values(1 2 3 4 5)
replace disability_any_2013 = source_disability_count_aux > 0 ///
    if missing(disability_any_2013) & ///
       (source_disability_count_aux > 0 | disca01_6 == 6)

egen byte source_program_count_aux = ///
    anycount(prog01_1-prog01_10), ///
    values(1 2 3 4 5 6 7 8 9 10)
replace program_any_2013 = source_program_count_aux > 0 ///
    if missing(program_any_2013) & ///
       (source_program_count_aux > 0 | prog01_11 == 11)
replace program_juntos_2013 = prog01_6 == 6 ///
    if missing(program_juntos_2013) & ///
       (source_program_count_aux > 0 | prog01_11 == 11)
replace program_pension65_2013 = prog01_8 == 8 ///
    if missing(program_pension65_2013) & ///
       (source_program_count_aux > 0 | prog01_11 == 11)

generate int age_2017 = c5_p4_1 ///
    if census2017_linked & inrange(c5_p4_1, 0, 120)
generate byte female_2017 = c5_p2 == 2 ///
    if census2017_linked & inlist(c5_p2, 1, 2)
generate byte age_0_14_2017 = inrange(age_2017, 0, 14) ///
    if !missing(age_2017)
generate byte age_15_29_2017 = inrange(age_2017, 15, 29) ///
    if !missing(age_2017)
generate byte age_30_44_2017 = inrange(age_2017, 30, 44) ///
    if !missing(age_2017)
generate byte age_45_64_2017 = inrange(age_2017, 45, 64) ///
    if !missing(age_2017)
generate byte age_65plus_2017 = age_2017 >= 65 ///
    if !missing(age_2017)
generate byte household_head_2017 = c5_p1 == 1 ///
    if census2017_linked & inrange(c5_p1, 1, 11)
generate byte relation_head_2017 = c5_p1 ///
    if census2017_linked & inrange(c5_p1, 1, 11)
generate byte permanent_district_2017 = c5_p5 == 1 ///
    if census2017_linked & inlist(c5_p5, 1, 2)
generate byte moved_district_2012_2017 = c5_p6 == 3 ///
    if age_2017 >= 5 & inlist(c5_p6, 2, 3)

egen byte insurance_count_2017_aux = ///
    rowtotal(c5_p8_1-c5_p8_5)
egen byte insurance_valid_2017_aux = ///
    rownonmiss(c5_p8_1-c5_p8_5)
generate byte insurance_any_2017 = insurance_count_2017_aux > 0 ///
    if census2017_linked & insurance_valid_2017_aux == 5
generate byte insurance_sis_2017 = c5_p8_1 == 1 ///
    if census2017_linked & inlist(c5_p8_1, 0, 1)
generate byte insurance_essalud_2017 = c5_p8_2 == 1 ///
    if census2017_linked & inlist(c5_p8_2, 0, 1)
generate byte insurance_armed_forces_2017 = c5_p8_3 == 1 ///
    if census2017_linked & inlist(c5_p8_3, 0, 1)
generate byte insurance_private_2017 = c5_p8_4 == 1 ///
    if census2017_linked & inlist(c5_p8_4, 0, 1)
generate byte insurance_other_2017 = c5_p8_5 == 1 ///
    if census2017_linked & inlist(c5_p8_5, 0, 1)

egen byte disability_count_2017_aux = ///
    rowtotal(c5_p9_1-c5_p9_6)
egen byte disability_valid_2017_aux = ///
    rownonmiss(c5_p9_1-c5_p9_6)
generate byte disability_any_2017 = disability_count_2017_aux > 0 ///
    if census2017_linked & disability_valid_2017_aux == 6
generate byte disability_visual_2017 = c5_p9_1 == 1 ///
    if census2017_linked & inlist(c5_p9_1, 0, 1)
generate byte disability_hearing_2017 = c5_p9_2 == 1 ///
    if census2017_linked & inlist(c5_p9_2, 0, 1)
generate byte disability_speech_2017 = c5_p9_3 == 1 ///
    if census2017_linked & inlist(c5_p9_3, 0, 1)
generate byte disability_mobility_2017 = c5_p9_4 == 1 ///
    if census2017_linked & inlist(c5_p9_4, 0, 1)
generate byte disability_cognitive_2017 = c5_p9_5 == 1 ///
    if census2017_linked & inlist(c5_p9_5, 0, 1)
generate byte disability_social_2017 = c5_p9_6 == 1 ///
    if census2017_linked & inlist(c5_p9_6, 0, 1)

generate byte language_childhood_2017 = c5_p11 ///
    if age_2017 >= 3 & inrange(c5_p11, 1, 46)
generate byte spanish_childhood_2017 = c5_p11 == 10 ///
    if age_2017 >= 3 & inrange(c5_p11, 1, 45)
generate byte indigenous_language_2017 = ///
    (inrange(c5_p11, 1, 9) | inrange(c5_p11, 15, 45)) ///
    if age_2017 >= 3 & inrange(c5_p11, 1, 45)
generate byte literate_2017 = c5_p12 == 1 ///
    if age_2017 >= 3 & inlist(c5_p12, 1, 2)
generate byte education_level_2017 = c5_p13_niv ///
    if age_2017 >= 3 & inrange(c5_p13_niv, 1, 10)
generate byte primary_grade_2017 = c5_p13_gra ///
    if education_level_2017 == 3 & inrange(c5_p13_gra, 1, 6)
replace primary_grade_2017 = c5_p13_anio_pri ///
    if education_level_2017 == 3 & ///
       missing(primary_grade_2017) & ///
       inrange(c5_p13_anio_pri, 1, 6)
generate byte primary_complete_2017 = 0 ///
    if inlist(education_level_2017, 1, 2)
replace primary_complete_2017 = primary_grade_2017 == 6 ///
    if education_level_2017 == 3 & !missing(primary_grade_2017)
replace primary_complete_2017 = 1 ///
    if inlist(education_level_2017, 4, 6, 7, 8, 9, 10)
generate byte secondaryplus_2017 = ///
    inlist(education_level_2017, 4, 6, 7, 8, 9, 10) ///
    if !missing(education_level_2017)
generate byte attending_education_2017 = c5_p14 == 1 ///
    if age_2017 >= 3 & inlist(c5_p14, 1, 2)
generate byte literate_age14_2017 = literate_2017 ///
    if age_2017 >= 14
generate byte primary_complete_age14_2017 = primary_complete_2017 ///
    if age_2017 >= 14
generate byte secondaryplus_age14_2017 = secondaryplus_2017 ///
    if age_2017 >= 14
generate byte attending_age6_17_2017 = attending_education_2017 ///
    if inrange(age_2017, 6, 17)

generate byte education_years_approx_2017 = .
replace education_years_approx_2017 = 0 ///
    if inlist(education_level_2017, 1, 2)
replace education_years_approx_2017 = primary_grade_2017 ///
    if education_level_2017 == 3
replace education_years_approx_2017 = 6 + c5_p13_anio_sec ///
    if education_level_2017 == 4 & inrange(c5_p13_anio_sec, 1, 5)
replace education_years_approx_2017 = 11 ///
    if inlist(education_level_2017, 6, 8)
replace education_years_approx_2017 = 14 ///
    if education_level_2017 == 7
replace education_years_approx_2017 = 16 ///
    if education_level_2017 == 9
replace education_years_approx_2017 = 18 ///
    if education_level_2017 == 10

generate byte employed_2017 = .
replace employed_2017 = 1 ///
    if age_2017 >= 5 & ///
       (c5_p16 == 1 | inrange(c5_p17, 1, 5))
replace employed_2017 = 0 ///
    if age_2017 >= 5 & c5_p16 == 2 & inlist(c5_p17, 6, 7)
generate byte unemployed_2017 = .
replace unemployed_2017 = 0 if employed_2017 == 1
replace unemployed_2017 = c5_p18 == 1 ///
    if employed_2017 == 0 & inlist(c5_p18, 1, 2)
generate byte labor_force_2017 = ///
    employed_2017 == 1 | unemployed_2017 == 1 ///
    if !missing(employed_2017, unemployed_2017)
generate byte employed_age14_2017 = employed_2017 ///
    if age_2017 >= 14
generate byte labor_force_age14_2017 = labor_force_2017 ///
    if age_2017 >= 14
generate byte unemployed_laborforce_2017 = unemployed_2017 ///
    if age_2017 >= 14 & labor_force_2017 == 1
generate byte employment_position_2017 = c5_p21 ///
    if employed_2017 == 1 & inrange(c5_p21, 1, 7)
generate str4 occupation_code_2017 = c5_p19_cod ///
    if employed_2017 == 1 & c5_p19_cod != ""
generate str4 industry_code_2017 = c5_p20_cod ///
    if employed_2017 == 1 & c5_p20_cod != ""
generate byte marital_status_2017 = c5_p24 ///
    if age_2017 >= 12 & inrange(c5_p24, 1, 6)
generate byte indigenous_selfid_2017 = ///
    inlist(c5_p25_i_mc, 1, 2, 3, 4, 11, 12, 13) ///
    if age_2017 >= 12 & inrange(c5_p25_i_mc, 1, 16) & ///
       c5_p25_i_mc != 9

generate byte moved_ccpp_2013_2017 = ///
    destination_ccpp_code != ubigeo_ccpp ///
    if census2017_linked & ///
       regexm(destination_ccpp_code, "^[0-9]{10}$") & ///
       regexm(ubigeo_ccpp, "^[0-9]{10}$")
generate byte moved_district_2013_2017 = ///
    substr(destination_ccpp_code, 1, 6) != ///
    substr(ubigeo_ccpp, 1, 6) ///
    if !missing(moved_ccpp_2013_2017)
generate byte moved_province_2013_2017 = ///
    substr(destination_ccpp_code, 1, 4) != ///
    substr(ubigeo_ccpp, 1, 4) ///
    if !missing(moved_ccpp_2013_2017)
generate byte moved_department_2013_2017 = ///
    substr(destination_ccpp_code, 1, 2) != ///
    substr(ubigeo_ccpp, 1, 2) ///
    if !missing(moved_ccpp_2013_2017)
generate byte moved_or_not_linked_sens_2017 = ///
    census2017_not_linked | moved_ccpp_2013_2017 == 1

bysort census2017_baseline_hhid cpv2017_destination_hhid: ///
    generate byte baseline_dest_hh_tag_aux = ///
    _n == 1 if !missing(cpv2017_destination_hhid)
bysort census2017_baseline_hhid: ///
    egen int baseline_dest_hh_count_2017 = ///
    total(baseline_dest_hh_tag_aux)
bysort census2017_baseline_hhid destination_ccpp_code: ///
    generate byte baseline_dest_ccpp_tag_aux = ///
    _n == 1 if destination_ccpp_code != ""
bysort census2017_baseline_hhid: ///
    egen int baseline_dest_ccpp_count_2017 = ///
    total(baseline_dest_ccpp_tag_aux)
generate byte baseline_split_destination_2017 = ///
    baseline_dest_hh_count_2017 > 1


*-------------------------------------------------------------------------------
**# 13.5 Construct current-household conditions and official NBI diagnostics
*-------------------------------------------------------------------------------

generate byte dwelling_type_2017 = c2_p1 ///
    if inrange(c2_p1, 1, 18) & !missing(cpv2017_destination_hhid)
generate byte wall_material_2017 = c2_p3 ///
    if inrange(c2_p3, 1, 9) & !missing(cpv2017_destination_hhid)
generate byte roof_material_2017 = c2_p4 ///
    if inrange(c2_p4, 1, 8) & !missing(cpv2017_destination_hhid)
generate byte floor_material_2017 = c2_p5 ///
    if inrange(c2_p5, 1, 7) & !missing(cpv2017_destination_hhid)
generate byte water_source_2017 = c2_p6 ///
    if inrange(c2_p6, 1, 10) & c2_p6 != 9 & ///
       !missing(cpv2017_destination_hhid)
generate byte water_daily_2017 = c2_p7 == 1 ///
    if inlist(c2_p7, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte sanitation_type_2017 = c2_p10 ///
    if inrange(c2_p10, 1, 8) & !missing(cpv2017_destination_hhid)
generate byte electricity_2017 = c2_p11 == 1 ///
    if inlist(c2_p11, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte rooms_2017 = c2_p12 ///
    if inrange(c2_p12, 1, 15) & !missing(cpv2017_destination_hhid)
generate byte housing_tenure_2017 = c2_p13 ///
    if inrange(c2_p13, 1, 5) & !missing(cpv2017_destination_hhid)

egen byte clean_cooking_2017_aux = ///
    rowmax(c3_p1_1 c3_p1_2 c3_p1_3)
generate byte clean_cooking_2017 = clean_cooking_2017_aux ///
    if inlist(clean_cooking_2017_aux, 0, 1) & ///
       !missing(cpv2017_destination_hhid)
generate byte cooks_with_wood_2017 = c3_p1_5 == 1 ///
    if inlist(c3_p1_5, 0, 1) & !missing(cpv2017_destination_hhid)
generate byte cooks_with_dung_2017 = c3_p1_6 == 1 ///
    if inlist(c3_p1_6, 0, 1) & !missing(cpv2017_destination_hhid)

generate byte asset_tv_2017 = c3_p2_2 == 1 ///
    if inlist(c3_p2_2, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte asset_refrigerator_2017 = c3_p2_4 == 1 ///
    if inlist(c3_p2_4, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte asset_washing_machine_2017 = c3_p2_5 == 1 ///
    if inlist(c3_p2_5, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte asset_computer_2017 = c3_p2_9 == 1 ///
    if inlist(c3_p2_9, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte mobile_phone_2017 = c3_p2_10 == 1 ///
    if inlist(c3_p2_10, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte fixed_phone_2017 = c3_p2_11 == 1 ///
    if inlist(c3_p2_11, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte cable_tv_2017 = c3_p2_12 == 1 ///
    if inlist(c3_p2_12, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte internet_2017 = c3_p2_13 == 1 ///
    if inlist(c3_p2_13, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte car_2017 = c3_p2_14 == 1 ///
    if inlist(c3_p2_14, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte motorcycle_2017 = c3_p2_15 == 1 ///
    if inlist(c3_p2_15, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte motorboat_2017 = c3_p2_16 == 1 ///
    if inlist(c3_p2_16, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte household_member_abroad_2017 = c3_p3 == 1 ///
    if inlist(c3_p3, 1, 2) & !missing(cpv2017_destination_hhid)
generate byte household_members_abroad_2017 = c3_p3a ///
    if household_member_abroad_2017 == 1 & inrange(c3_p3a, 1, 30)
replace household_members_abroad_2017 = 0 ///
    if household_member_abroad_2017 == 0

local census2017_hh_constant_vars ///
    c4_p1 c2_p1 c2_p3 c2_p4 c2_p5 c2_p6 c2_p7 ///
    c2_p10 c2_p11 c2_p12 c2_p13 ///
    c3_p1_1 c3_p1_2 c3_p1_3 c3_p1_4 ///
    c3_p1_5 c3_p1_6 c3_p1_7 c3_p1_8 ///
    c3_p2_1 c3_p2_2 c3_p2_3 c3_p2_4 ///
    c3_p2_5 c3_p2_6 c3_p2_7 c3_p2_8 ///
    c3_p2_9 c3_p2_10 c3_p2_11 c3_p2_12 ///
    c3_p2_13 c3_p2_14 c3_p2_15 c3_p2_16

foreach household_var of local census2017_hh_constant_vars {
    bysort cpv2017_destination_hhid: ///
        egen double `household_var'_min_aux = min(`household_var')
    bysort cpv2017_destination_hhid: ///
        egen double `household_var'_max_aux = max(`household_var')
    count if ///
        !missing(cpv2017_destination_hhid) & ///
        `household_var'_min_aux != `household_var'_max_aux
    assert r(N) == 0
    drop `household_var'_min_aux `household_var'_max_aux
}

bysort cpv2017_destination_hhid: ///
    generate int cpv2017_delivery_members = _N ///
    if !missing(cpv2017_destination_hhid)
generate byte cpv2017_roster_complete = ///
    cpv2017_delivery_members == c4_p1 ///
    if !missing(cpv2017_destination_hhid, c4_p1)

egen byte cpv2017_dest_hh_tag_aux = ///
    tag(cpv2017_destination_hhid)
replace cpv2017_dest_hh_tag_aux = 0 ///
    if missing(cpv2017_destination_hhid)
count if cpv2017_dest_hh_tag_aux
local census2017_destination_hh_rows = r(N)
assert `census2017_destination_hh_rows' == 66436
count if cpv2017_dest_hh_tag_aux & missing(c4_p1)
local cpv2017_dest_hh_no_roster = r(N)
assert `cpv2017_dest_hh_no_roster' == 1223
count if ///
    cpv2017_dest_hh_tag_aux & ///
    cpv2017_delivery_members < c4_p1 & !missing(c4_p1)
local cpv2017_dest_hh_partial = r(N)
assert `cpv2017_dest_hh_partial' == 37933
count if ///
    cpv2017_dest_hh_tag_aux & cpv2017_roster_complete == 1
local cpv2017_dest_hh_complete = r(N)
assert `cpv2017_dest_hh_complete' == 27276
count if ///
    cpv2017_dest_hh_tag_aux & ///
    cpv2017_delivery_members > c4_p1 & !missing(c4_p1)
local cpv2017_dest_hh_overfull = r(N)
assert `cpv2017_dest_hh_overfull' == 4

generate byte nbi_inadequate_housing_2017 = 1 ///
    if !missing(cpv2017_destination_hhid) & ///
       (inlist(c2_p1, 6, 7) | c2_p3 == 8 | ///
       (inlist(c2_p3, 5, 6, 7, 9) & c2_p5 == 6))
replace nbi_inadequate_housing_2017 = 0 ///
    if missing(nbi_inadequate_housing_2017) & ///
       !missing(cpv2017_destination_hhid, c2_p1, c2_p3, c2_p5)
generate byte nbi_overcrowding_2017 = ///
    c4_p1 / c2_p12 > 3.4 ///
    if !missing(cpv2017_destination_hhid, c4_p1, c2_p12) & ///
       c2_p12 > 0
generate byte nbi_no_sanitation_2017 = ///
    inlist(c2_p10, 6, 7, 8) ///
    if !missing(cpv2017_destination_hhid) & inrange(c2_p10, 1, 8)

generate byte child_6_12_aux = inrange(age_2017, 6, 12)
generate byte child_not_attending_aux = ///
    child_6_12_aux & attending_education_2017 == 0
generate byte child_attendance_missing_aux = ///
    child_6_12_aux & missing(attending_education_2017)
bysort cpv2017_destination_hhid: ///
    egen byte cpv2017_child_not_attend_aux = ///
    max(child_not_attending_aux)
bysort cpv2017_destination_hhid: ///
    egen byte cpv2017_child_attend_miss_aux = ///
    max(child_attendance_missing_aux)
generate byte nbi_child_not_school_2017 = ///
    cpv2017_child_not_attend_aux ///
    if cpv2017_roster_complete == 1 & ///
       cpv2017_child_attend_miss_aux == 0

generate byte head_primary2less_aux = .
replace head_primary2less_aux = 1 ///
    if household_head_2017 == 1 & ///
       inlist(education_level_2017, 1, 2)
replace head_primary2less_aux = 1 ///
    if household_head_2017 == 1 & ///
       education_level_2017 == 3 & ///
       inrange(primary_grade_2017, 1, 2)
replace head_primary2less_aux = 0 ///
    if household_head_2017 == 1 & ///
       education_level_2017 == 3 & ///
       inrange(primary_grade_2017, 3, 6)
replace head_primary2less_aux = 0 ///
    if household_head_2017 == 1 & ///
       inlist(education_level_2017, 4, 6, 7, 8, 9, 10)
generate byte employed_count_aux = employed_2017 == 1
generate byte labor_unknown_aux = ///
    age_2017 >= 5 & missing(employed_2017)
bysort cpv2017_destination_hhid: ///
    egen byte cpv2017_head_count_aux = total(household_head_2017 == 1)
bysort cpv2017_destination_hhid: ///
    egen byte cpv2017_head_lowedu_aux = max(head_primary2less_aux)
bysort cpv2017_destination_hhid: ///
    egen int cpv2017_employed_aux = total(employed_count_aux)
bysort cpv2017_destination_hhid: ///
    egen byte cpv2017_labor_unknown_aux = max(labor_unknown_aux)
generate double dependency_ratio_2017 = ///
    c4_p1 / cpv2017_employed_aux ///
    if cpv2017_employed_aux > 0 & !missing(c4_p1)
generate byte nbi_high_dependency_2017 = 0 ///
    if cpv2017_roster_complete == 1 & ///
       cpv2017_head_count_aux == 1 & ///
       cpv2017_labor_unknown_aux == 0 & ///
       !missing(cpv2017_head_lowedu_aux)
replace nbi_high_dependency_2017 = 1 ///
    if cpv2017_roster_complete == 1 & ///
       cpv2017_head_count_aux == 1 & ///
       cpv2017_labor_unknown_aux == 0 & ///
       cpv2017_head_lowedu_aux == 1 & ///
       (cpv2017_employed_aux == 0 | dependency_ratio_2017 >= 4)

egen byte nbi_count_2017 = rowtotal( ///
    nbi_inadequate_housing_2017 ///
    nbi_overcrowding_2017 ///
    nbi_no_sanitation_2017 ///
    nbi_child_not_school_2017 ///
    nbi_high_dependency_2017)
egen byte nbi_components_valid_2017 = rownonmiss( ///
    nbi_inadequate_housing_2017 ///
    nbi_overcrowding_2017 ///
    nbi_no_sanitation_2017 ///
    nbi_child_not_school_2017 ///
    nbi_high_dependency_2017)
replace nbi_count_2017 = . if nbi_components_valid_2017 != 5
generate byte nbi_any_2017 = nbi_count_2017 >= 1 ///
    if !missing(nbi_count_2017)
generate byte nbi_two_plus_2017 = nbi_count_2017 >= 2 ///
    if !missing(nbi_count_2017)

generate byte water_public_daily_2017 = ///
    inlist(c2_p6, 1, 2, 3) & c2_p7 == 1 ///
    if !missing(c2_p6, c2_p7) & !missing(cpv2017_destination_hhid)
generate byte sanitation_facility_2017 = ///
    inrange(c2_p10, 1, 4) ///
    if inrange(c2_p10, 1, 8) & !missing(cpv2017_destination_hhid)
generate double wellbeing_housing_2017 = 1 - (c2_p5 == 6) ///
    if inrange(c2_p5, 1, 7) & !missing(cpv2017_destination_hhid)
generate double wellbeing_services_2017 = ///
    (water_public_daily_2017 + sanitation_facility_2017) / 2 ///
    if !missing(water_public_daily_2017, sanitation_facility_2017)
generate double wellbeing_energy_2017 = ///
    (electricity_2017 + clean_cooking_2017) / 2 ///
    if !missing(electricity_2017, clean_cooking_2017)

egen byte asset_count_2017 = rowtotal( ///
    asset_tv_2017 asset_washing_machine_2017 ///
    asset_refrigerator_2017 asset_computer_2017)
egen byte asset_valid_2017_aux = rownonmiss( ///
    asset_tv_2017 asset_washing_machine_2017 ///
    asset_refrigerator_2017 asset_computer_2017)
replace asset_count_2017 = . if asset_valid_2017_aux != 4
generate double wellbeing_assets_2017 = asset_count_2017 / 4 ///
    if !missing(asset_count_2017)

egen byte connectivity_count_2017 = rowtotal( ///
    mobile_phone_2017 internet_2017 cable_tv_2017)
egen byte connectivity_valid_2017_aux = rownonmiss( ///
    mobile_phone_2017 internet_2017 cable_tv_2017)
replace connectivity_count_2017 = . ///
    if connectivity_valid_2017_aux != 3
generate double wellbeing_connectivity_2017 = ///
    connectivity_count_2017 / 3 ///
    if !missing(connectivity_count_2017)

generate double wellbeing_humancapital_2017 = ///
    (literate_2017 + secondaryplus_2017) / 2 ///
    if age_2017 >= 14 & !missing(literate_2017, secondaryplus_2017)
generate double wellbeing_core_2017 = ///
    (wellbeing_housing_2017 + wellbeing_services_2017 + ///
     wellbeing_energy_2017 + wellbeing_humancapital_2017) / 4 ///
    if !missing( ///
        wellbeing_housing_2017, ///
        wellbeing_services_2017, ///
        wellbeing_energy_2017, ///
        wellbeing_humancapital_2017)
generate double deprivation_core_2017 = 1 - wellbeing_core_2017 ///
    if !missing(wellbeing_core_2017)

preserve
keep if !missing(cpv2017_destination_hhid)
keep ///
    cpv2017_destination_hhid ///
    cpv2017_delivery_members cpv2017_roster_complete ///
    dwelling_type_2017 wall_material_2017 roof_material_2017 ///
    floor_material_2017 water_source_2017 water_daily_2017 ///
    sanitation_type_2017 electricity_2017 rooms_2017 ///
    housing_tenure_2017 clean_cooking_2017 ///
    cooks_with_wood_2017 cooks_with_dung_2017 ///
    asset_tv_2017 asset_refrigerator_2017 ///
    asset_washing_machine_2017 asset_computer_2017 ///
    mobile_phone_2017 fixed_phone_2017 cable_tv_2017 ///
    internet_2017 car_2017 motorcycle_2017 motorboat_2017 ///
    household_member_abroad_2017 household_members_abroad_2017 ///
    nbi_inadequate_housing_2017 nbi_overcrowding_2017 ///
    nbi_no_sanitation_2017 nbi_child_not_school_2017 ///
    nbi_high_dependency_2017 nbi_count_2017 ///
    nbi_components_valid_2017 nbi_any_2017 nbi_two_plus_2017 ///
    dependency_ratio_2017 ///
    wellbeing_housing_2017 wellbeing_services_2017 ///
    wellbeing_energy_2017 wellbeing_assets_2017 ///
    wellbeing_connectivity_2017
bysort cpv2017_destination_hhid: keep if _n == 1
isid cpv2017_destination_hhid
count
assert r(N) == `census2017_destination_hh_rows'
compress
save ///
    "${intermediate_root}/26_census_2017_destination_household.dta", ///
    replace
restore

preserve
keep if ///
    cpv2017_dest_hh_tag_aux & ///
    cpv2017_delivery_members > c4_p1 & !missing(c4_p1)
keep ///
    cpv2017_destination_hhid ///
    cpv2017_delivery_members c4_p1
rename c4_p1 cpv2017_reported_members
save ///
    "${qa_data_root}/census2017_destination_household_overfull.dta", ///
    replace
restore

label variable census2017_cohort_pid ///
    "De-identified person ID in the INEI-assisted cohort"
label variable census2017_baseline_hhid ///
    "De-identified 2013 source-household ID"
label variable cpv2017_destination_hhid ///
    "De-identified 2017 destination-household ID"
label variable census2017_linked ///
    "Person linked by INEI to a 2017 Census record"
label variable census2017_not_linked ///
    "Person not linked to a 2017 Census record; not migration"
label variable census2017_person_key_linked ///
    "Cohort record linked to the canonical SISFOH person key"
label variable census2017_hh_key_conflict ///
    "Source household has conflicting recovered SISFOH household IDs"
label variable age_2017 "Age at the 2017 Census"
label variable age_0_14_2017 "Age 0 to 14 at the 2017 Census"
label variable age_15_29_2017 "Age 15 to 29 at the 2017 Census"
label variable age_30_44_2017 "Age 30 to 44 at the 2017 Census"
label variable age_45_64_2017 "Age 45 to 64 at the 2017 Census"
label variable age_65plus_2017 "Age 65 or older at the 2017 Census"
label variable moved_ccpp_2013_2017 ///
    "Linked person lives in a different CCPP in 2017"
label variable moved_or_not_linked_sens_2017 ///
    "Sensitivity only: moved CCPP or not linked"
label variable moved_district_2012_2017 ///
    "Census respondent lived in another district five years earlier"
label variable internet_2017 ///
    "Current 2017 Census household has internet"
label variable nbi_count_2017 ///
    "Official-compatible NBI count; complete destination rosters only"
label variable wellbeing_core_2017 ///
    "Equal-weight harmonized wellbeing score, 0-1"
label variable deprivation_core_2017 ///
    "Reverse-coded harmonized wellbeing score, 0-1"

drop ///
    llave id_hogar_m id_viv_imp_f id_hog_imp_f id_pob_imp_f ///
    source_ccpp_code source_ccpp_inei destination_ccpp_code ///
    ubigeo_ccpp_sisfoh ubigeo_district_sisfoh ///
    sisfoh_dwelling_number sisfoh_household_number ///
    sisfoh_age_key sisfoh_sex_key ///
    edad01 ptes01 sexo01 gesta01 esta01 ///
    segu01_1-segu01_6 idioma01 lee01 niv01 ult01 era01 sect01 ///
    disca01_1-disca01_6 prog01_1-prog01_11 ///
    c5_p1 c5_p2 c5_p4_1 c5_p5 c5_p6 ///
    c5_p8_1-c5_p8_6 c5_p9_1-c5_p9_7 ///
    c5_p11 c5_p12 c5_p13_niv c5_p13_gra ///
    c5_p13_anio_pri c5_p13_anio_sec ///
    c5_p14 c5_p16 c5_p17 c5_p18 ///
    c5_p19_cod c5_p20_cod c5_p21 c5_p22 c5_p24 c5_p25_i_mc ///
    c2_p1 c2_p3 c2_p4 c2_p5 c2_p6 c2_p7 ///
    c2_p10 c2_p11 c2_p12 c2_p13 t_c4_p1 ///
    c3_p1_1-c3_p1_8 c3_p2_1-c3_p2_16 c3_p3 c3_p3a c4_p1
capture drop *_aux

compress
sort census2017_cohort_pid
isid census2017_cohort_pid
count
assert r(N) == `census2017_cohort_rows'
save `census2017_person_clean'

merge m:1 ruv_id using ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta", ///
    keep(match)
assert _merge == 3
drop _merge
compress
sort census2017_cohort_pid
isid census2017_cohort_pid
count
local census2017_person_analysis_rows = r(N)
assert `census2017_person_analysis_rows' == 193376
save ///
    "${analysis_data_root}/12_census_2017_individual_analysis.dta", ///
    replace


*-------------------------------------------------------------------------------
**# 13.6 Aggregate the source cohort to baseline households
*-------------------------------------------------------------------------------

use `census2017_person_clean', clear
bysort census2017_baseline_hhid: assert ruv_id == ruv_id[1]
bysort census2017_baseline_hhid: assert sisfoh_hhid == sisfoh_hhid[1]

preserve
keep ///
    census2017_baseline_hhid ruv_id sisfoh_hhid ///
    census2017_hh_key_conflict ///
    baseline_dest_hh_count_2017 ///
    baseline_dest_ccpp_count_2017 ///
    baseline_split_destination_2017
bysort census2017_baseline_hhid: keep if _n == 1
isid census2017_baseline_hhid
save `census2017_household_keys'
restore

generate byte cohort_member_aux = 1
generate byte linked_member_aux = census2017_linked
generate byte person_key_member_aux = census2017_person_key_linked
generate byte migration_observed_aux = !missing(moved_ccpp_2013_2017)
generate byte moved_ccpp_aux = moved_ccpp_2013_2017 == 1 ///
    if !missing(moved_ccpp_2013_2017)
generate byte moved_district_aux = moved_district_2013_2017 == 1 ///
    if !missing(moved_district_2013_2017)
generate byte moved_province_aux = moved_province_2013_2017 == 1 ///
    if !missing(moved_province_2013_2017)
generate byte moved_department_aux = moved_department_2013_2017 == 1 ///
    if !missing(moved_department_2013_2017)
generate byte internet_observed_aux = !missing(internet_2017)
generate byte employed_observed_aux = !missing(employed_2017)
generate byte nbi_observed_aux = !missing(nbi_any_2017)

collapse ///
    (sum) ///
        census2017_cohort_members=cohort_member_aux ///
        hh_linked_members_2017=linked_member_aux ///
        hh_person_keys_2013=person_key_member_aux ///
        hh_migration_observed_2017=migration_observed_aux ///
        hh_moved_ccpp_count_2017=moved_ccpp_aux ///
        hh_moved_district_count_2017=moved_district_aux ///
        hh_moved_province_count_2017=moved_province_aux ///
        hh_moved_department_count_2017=moved_department_aux ///
        hh_internet_observed_2017=internet_observed_aux ///
        hh_employed_observed_2017=employed_observed_aux ///
        hh_nbi_observed_2017=nbi_observed_aux ///
    (mean) ///
        hh_mean_age_2017=age_2017 ///
        hh_share_female_2017=female_2017 ///
        hh_share_age_0_14_2017=age_0_14_2017 ///
        hh_share_age_15_29_2017=age_15_29_2017 ///
        hh_share_age_30_44_2017=age_30_44_2017 ///
        hh_share_age_45_64_2017=age_45_64_2017 ///
        hh_share_age_65plus_2017=age_65plus_2017 ///
        hh_share_literate_2017=literate_2017 ///
        hh_share_secondaryplus_2017=secondaryplus_2017 ///
        hh_share_literate_age14_2017=literate_age14_2017 ///
        hh_share_primary_age14_2017=primary_complete_age14_2017 ///
        hh_share_secondary_age14_2017=secondaryplus_age14_2017 ///
        hh_share_attending_6_17_2017=attending_age6_17_2017 ///
        hh_share_employed_2017=employed_2017 ///
        hh_share_labor_force_2017=labor_force_2017 ///
        hh_share_employed_age14_2017=employed_age14_2017 ///
        hh_share_laborforce_age14_2017=labor_force_age14_2017 ///
        hh_unemployment_rate_2017=unemployed_laborforce_2017 ///
        hh_share_insured_2017=insurance_any_2017 ///
        hh_share_insurance_sis_2017=insurance_sis_2017 ///
        hh_share_insurance_essalud_2017=insurance_essalud_2017 ///
        hh_share_disability_2017=disability_any_2017 ///
        hh_share_indig_language_2017=indigenous_language_2017 ///
        hh_share_moved_five_years_2017=moved_district_2012_2017 ///
        hh_share_internet_2017=internet_2017 ///
        hh_member_share_nbi_2017=nbi_any_2017 ///
        hh_wellbeing_housing_2017=wellbeing_housing_2017 ///
        hh_wellbeing_services_2017=wellbeing_services_2017 ///
        hh_wellbeing_energy_2017=wellbeing_energy_2017 ///
        hh_wellbeing_humancap_2017=wellbeing_humancapital_2017 ///
        hh_wellbeing_assets_2017=wellbeing_assets_2017 ///
        hh_wellbeing_connect_2017=wellbeing_connectivity_2017 ///
    (max) ///
        hh_single_dest_internet_2017=internet_2017 ///
        hh_single_dest_nbi_any_2017=nbi_any_2017, ///
    by(census2017_baseline_hhid)

generate double hh_wellbeing_core_2017 = ///
    (hh_wellbeing_housing_2017 + hh_wellbeing_services_2017 + ///
     hh_wellbeing_energy_2017 + hh_wellbeing_humancap_2017) / 4 ///
    if !missing( ///
        hh_wellbeing_housing_2017, ///
        hh_wellbeing_services_2017, ///
        hh_wellbeing_energy_2017, ///
        hh_wellbeing_humancap_2017)
generate double hh_deprivation_core_2017 = ///
    1 - hh_wellbeing_core_2017 ///
    if !missing(hh_wellbeing_core_2017)

merge 1:1 census2017_baseline_hhid using ///
    `census2017_household_keys'
assert _merge == 3
drop _merge

generate double hh_link_rate_2017 = ///
    hh_linked_members_2017 / census2017_cohort_members
generate double hh_person_key_rate_2013 = ///
    hh_person_keys_2013 / census2017_cohort_members
generate double hh_share_moved_ccpp_2017 = ///
    hh_moved_ccpp_count_2017 / hh_migration_observed_2017 ///
    if hh_migration_observed_2017 > 0
generate double hh_share_moved_district_2017 = ///
    hh_moved_district_count_2017 / hh_migration_observed_2017 ///
    if hh_migration_observed_2017 > 0
generate double hh_share_moved_province_2017 = ///
    hh_moved_province_count_2017 / hh_migration_observed_2017 ///
    if hh_migration_observed_2017 > 0
generate double hh_share_moved_department_2017 = ///
    hh_moved_department_count_2017 / hh_migration_observed_2017 ///
    if hh_migration_observed_2017 > 0
replace hh_single_dest_internet_2017 = . ///
    if baseline_dest_hh_count_2017 != 1
replace hh_single_dest_nbi_any_2017 = . ///
    if baseline_dest_hh_count_2017 != 1

label variable hh_link_rate_2017 ///
    "Share of source-household members linked to Census 2017"
label variable hh_share_moved_ccpp_2017 ///
    "Share of linked members living in another CCPP in 2017"
label variable baseline_split_destination_2017 ///
    "Source household links to multiple 2017 destination households"
label variable hh_share_internet_2017 ///
    "Share of linked members in a household with internet"
label variable hh_member_share_nbi_2017 ///
    "Share of linked members in a destination household with any NBI"

merge m:1 sisfoh_hhid using ///
    "${intermediate_root}/21_sisfoh_2013_household_clean.dta", ///
    keep(master match)
generate byte census2017_sisfoh_hh_recovered = _merge == 3
drop _merge
count if census2017_sisfoh_hh_recovered
local census2017_sisfoh_hh_rows = r(N)
assert `census2017_sisfoh_hh_rows' == 57740

compress
sort census2017_baseline_hhid
isid census2017_baseline_hhid
count
local census2017_household_rows = r(N)
assert `census2017_household_rows' == 58021
save `census2017_household_clean'

merge m:1 ruv_id using ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta", ///
    keep(match)
assert _merge == 3
drop _merge
compress
sort census2017_baseline_hhid
isid census2017_baseline_hhid
save ///
    "${analysis_data_root}/13_census_2017_household_analysis.dta", ///
    replace


*-------------------------------------------------------------------------------
**# 13.7 Aggregate cohort outcomes to source CCPPs
*-------------------------------------------------------------------------------

use `census2017_person_clean', clear
generate byte cohort_person_aux = 1
generate byte linked_person_aux = census2017_linked
generate byte migration_observed_aux = !missing(moved_ccpp_2013_2017)
generate byte moved_ccpp_aux = moved_ccpp_2013_2017 == 1 ///
    if !missing(moved_ccpp_2013_2017)
generate byte moved_district_aux = moved_district_2013_2017 == 1 ///
    if !missing(moved_district_2013_2017)
generate byte moved_province_aux = moved_province_2013_2017 == 1 ///
    if !missing(moved_province_2013_2017)
generate byte moved_department_aux = moved_department_2013_2017 == 1 ///
    if !missing(moved_department_2013_2017)
generate byte internet_observed_aux = !missing(internet_2017)
generate byte nbi_observed_aux = !missing(nbi_any_2017)

collapse ///
    (sum) ///
        cpv2017_cohort_persons=cohort_person_aux ///
        cpv2017_linked_persons=linked_person_aux ///
        cpv2017_migration_observed=migration_observed_aux ///
        cpv2017_moved_ccpp_count=moved_ccpp_aux ///
        cpv2017_moved_district_count=moved_district_aux ///
        cpv2017_moved_province_count=moved_province_aux ///
        cpv2017_moved_dept_count=moved_department_aux ///
        cpv2017_internet_observed=internet_observed_aux ///
        cpv2017_nbi_observed=nbi_observed_aux ///
    (mean) ///
        cpv2017_mean_age=age_2017 ///
        cpv2017_share_female=female_2017 ///
        share_age_0_14_2017=age_0_14_2017 ///
        share_age_15_29_2017=age_15_29_2017 ///
        share_age_30_44_2017=age_30_44_2017 ///
        share_age_45_64_2017=age_45_64_2017 ///
        share_age_65plus_2017=age_65plus_2017 ///
        cpv2017_share_literate=literate_2017 ///
        cpv2017_share_secondary=secondaryplus_2017 ///
        cpv2017_share_literate_age14=literate_age14_2017 ///
        cpv2017_share_primary_age14=primary_complete_age14_2017 ///
        cpv2017_share_secondary_age14=secondaryplus_age14_2017 ///
        cpv2017_share_attending_6_17=attending_age6_17_2017 ///
        cpv2017_share_employed=employed_2017 ///
        cpv2017_share_labor_force=labor_force_2017 ///
        cpv2017_share_employed_age14=employed_age14_2017 ///
        cpv2017_share_laborforce_age14=labor_force_age14_2017 ///
        cpv2017_unemployment_rate=unemployed_laborforce_2017 ///
        cpv2017_share_insured=insurance_any_2017 ///
        cpv2017_share_insurance_sis=insurance_sis_2017 ///
        cpv2017_share_insurance_essalud=insurance_essalud_2017 ///
        cpv2017_share_disability=disability_any_2017 ///
        cpv2017_share_indig_lang=indigenous_language_2017 ///
        cpv2017_share_moved_five_years=moved_district_2012_2017 ///
        cpv2017_share_internet=internet_2017 ///
        cpv2017_share_nbi_any=nbi_any_2017 ///
        cpv2017_member_wb_housing=wellbeing_housing_2017 ///
        cpv2017_member_wb_services=wellbeing_services_2017 ///
        cpv2017_member_wb_energy=wellbeing_energy_2017 ///
        wellbeing_human_capital_2017=wellbeing_humancapital_2017 ///
        cpv2017_member_wb_assets=wellbeing_assets_2017 ///
        cpv2017_member_wb_connect=wellbeing_connectivity_2017 ///
        cpv2017_member_wb_core=wellbeing_core_2017, ///
    by(ruv_id)

generate double cpv2017_link_rate = ///
    cpv2017_linked_persons / cpv2017_cohort_persons
generate double cpv2017_share_moved_ccpp = ///
    cpv2017_moved_ccpp_count / cpv2017_migration_observed ///
    if cpv2017_migration_observed > 0
generate double cpv2017_share_moved_district = ///
    cpv2017_moved_district_count / cpv2017_migration_observed ///
    if cpv2017_migration_observed > 0
generate double cpv2017_share_moved_province = ///
    cpv2017_moved_province_count / cpv2017_migration_observed ///
    if cpv2017_migration_observed > 0
generate double cpv2017_share_moved_dept = ///
    cpv2017_moved_dept_count / cpv2017_migration_observed ///
    if cpv2017_migration_observed > 0

label variable cpv2017_cohort_persons ///
    "People in the 2013 source cohort"
label variable cpv2017_linked_persons ///
    "Source-cohort people linked to Census 2017"
label variable cpv2017_link_rate ///
    "Share of source-cohort people linked to Census 2017"
label variable cpv2017_share_moved_ccpp ///
    "Share of linked source-cohort people living in another CCPP"
label variable cpv2017_member_wb_core ///
    "Person-weighted linked-cohort wellbeing score, 0-1"

isid ruv_id
count
assert r(N) == `census2017_source_ruv_rows'
save `census2017_ccpp_person'

use `census2017_household_clean', clear
generate byte source_household_aux = 1
collapse ///
    (sum) ///
        cpv2017_source_households=source_household_aux ///
    (mean) ///
        cpv2017_hh_mean_link_rate=hh_link_rate_2017 ///
        cpv2017_hh_share_split=baseline_split_destination_2017 ///
        cpv2017_hh_share_moved=hh_share_moved_ccpp_2017 ///
        cpv2017_hh_share_internet=hh_share_internet_2017 ///
        cpv2017_hh_share_nbi=hh_member_share_nbi_2017 ///
        wellbeing_housing_2017=hh_wellbeing_housing_2017 ///
        wellbeing_services_2017=hh_wellbeing_services_2017 ///
        wellbeing_energy_2017=hh_wellbeing_energy_2017 ///
        wellbeing_assets_2017=hh_wellbeing_assets_2017 ///
        wellbeing_connectivity_2017=hh_wellbeing_connect_2017 ///
        cpv2017_hh_wellbeing_core=hh_wellbeing_core_2017 ///
        cpv2017_hh_deprivation_core=hh_deprivation_core_2017, ///
    by(ruv_id)
isid ruv_id
count
assert r(N) == `census2017_source_ruv_rows'
save `census2017_ccpp_household'

use `census2017_ccpp_person', clear
merge 1:1 ruv_id using `census2017_ccpp_household'
assert _merge == 3
drop _merge

generate double wellbeing_core_2017 = ///
    (wellbeing_housing_2017 + wellbeing_services_2017 + ///
     wellbeing_energy_2017 + wellbeing_human_capital_2017) / 4 ///
    if !missing( ///
        wellbeing_housing_2017, ///
        wellbeing_services_2017, ///
        wellbeing_energy_2017, ///
        wellbeing_human_capital_2017)
generate double deprivation_core_2017 = 1 - wellbeing_core_2017 ///
    if !missing(wellbeing_core_2017)
assert inrange(wellbeing_core_2017, 0, 1) ///
    if !missing(wellbeing_core_2017)
save `census2017_ccpp_linked'

use ///
    "${analysis_data_root}/11_community_registry_sisfoh_2013.dta", ///
    clear
merge 1:1 ruv_id using `census2017_ccpp_linked'
generate byte census2017_cohort_covered = _merge == 3
drop _merge

count if census2017_cohort_covered
local census2017_ccpp_covered = r(N)
assert `census2017_ccpp_covered' == `census2017_source_ruv_rows'
count if sample_main_rd & census2017_cohort_covered
local census2017_main_sample_covered = r(N)

quietly summarize cpv2017_migration_observed, meanonly
local cpv2017_migration_observed = r(sum)
quietly summarize cpv2017_moved_ccpp_count, meanonly
local cpv2017_moved_ccpp_rows = r(sum)
quietly summarize cpv2017_moved_district_count, meanonly
local cpv2017_moved_district_rows = r(sum)

label variable census2017_cohort_covered ///
    "RUV community represented in the INEI-assisted Census cohort"
label variable cpv2017_hh_share_split ///
    "Share of source households split across 2017 households"
label variable cpv2017_hh_share_internet ///
    "Mean member-weighted internet exposure across source households"
label variable wellbeing_core_2017 ///
    "Harmonized linked-cohort CCPP wellbeing score, 0-1"
label variable deprivation_core_2017 ///
    "Reverse-coded linked-cohort CCPP wellbeing score, 0-1"

compress
sort ruv_id
isid ruv_id
count
local census2017_registry_rows = r(N)
assert `census2017_registry_rows' == `sisfoh2013_registry_rows'
assert `census2017_registry_rows' == 5712
save ///
    "${analysis_data_root}/14_community_registry_census_2017.dta", ///
    replace


*===============================================================================
**# 14. Write aggregate QA metrics and close
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
    ("victimization_score_distinct_values") ///
    (`victim_score_distinct_n') ///
    ("validated") ///
    ("Distinct supplied values on the four-decimal score grid")

post `qa_post' ///
    ("victimization_score_rounded_minimum") ///
    (`victim_rounded_min_n') ///
    ("explained") ///
    ("Stored 0.0077 is the four-decimal representation of 0.007740")

post `qa_post' ///
    ("victimization_score_above_one") ///
    (`victim_above_one_n') ///
    ("source_review") ///
    ("Supplied score exceeds the government's nominal maximum of one")

post `qa_post' ///
    ("victimization_level_rounding_disagreements") ///
    (`victim_rounding_disagree_n') ///
    ("explained") ///
    ("Four-decimal score cannot recover six-decimal category assignment")

post `qa_post' ///
    ("victimization_level_true_conflicts") ///
    (`victim_true_conflict_n') ///
    ("source_review") ///
    ("Source category conflicts with score away from rounded boundaries")

post `qa_post' ///
    ("victimization_formula_matches_uncapped") ///
    (`victim_formula_uncapped_n') ///
    ("diagnostic") ///
    ("Inferred uncapped four-pillar formula matches to four decimals")

post `qa_post' ///
    ("victimization_formula_matches_capped") ///
    (`victim_formula_capped_n') ///
    ("diagnostic") ///
    ("Inferred four-pillar formula matches supplied score to four decimals")

post `qa_post' ///
    ("victimization_score_equal_one") ///
    (`victim_score_one_n') ///
    ("validated") ///
    ("Supplied scores exactly equal to one")

post `qa_post' ///
    ("victimization_score_cap_consistent") ///
    (`victim_cap_consistent_n') ///
    ("diagnostic") ///
    ("Score equals one and inferred uncapped formula exceeds one")

post `qa_post' ///
    ("victimization_inferred_common_scale") ///
    (.01018123) ///
    ("diagnostic") ///
    ("Empirically inferred scale; not an official normalization constant")

post `qa_post' ///
    ("cman_project_rows") ///
    (`cman_project_rows') ///
    ("validated") ///
    ("Consecutive PDF records 1 through 4433")

post `qa_post' ///
    ("cman_multisector_projects") ///
    (`cman_multisector_projects') ///
    ("descriptive") ///
    ("Project title contains terms from more than one documented sector")

post `qa_post' ///
    ("cman_project_manual_overrides") ///
    (`cman_project_manual_overrides') ///
    ("validated") ///
    ("Reviewed primary category for the single water-irrigation title")

post `qa_post' ///
    ("cman_cofinanced_projects") ///
    (`cman_cofinanced_projects') ///
    ("descriptive") ///
    ("CMAN project rows with positive recorded cofinancing")

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
    ("main_rd_sample_rows") ///
    (`main_rd_sample_rows') ///
    ("team_selected") ///
    ("Exact legacy geography: Apurimac, Huancavelica, La Convencion, and Huancayo")

post `qa_post' ///
    ("foundational_missing_ubigeo") ///
    (`foundational_missing_ubigeo') ///
    ("retained_unresolved") ///
    ("RUV rows retained without a verified ten-digit CCPP UBIGEO")

post `qa_post' ///
    ("census2007_source_rows") ///
    (`census2007_source_rows') ///
    ("validated") ///
    ("Unique keyed rows in the supplied CCPP-level 2007 census tabulation")

post `qa_post' ///
    ("census2007_departments") ///
    (`census2007_department_count') ///
    ("source_scope") ///
    ("Departments represented in the supplied workbook; not national coverage")

post `qa_post' ///
    ("census2007_population_sum") ///
    (`census2007_population_sum') ///
    ("source_scope") ///
    ("Population represented in supplied workbook; not the national census total")

post `qa_post' ///
    ("census2007_household_sum") ///
    (`census2007_household_sum') ///
    ("source_scope") ///
    ("Households represented in supplied workbook; not the national census total")

post `qa_post' ///
    ("census2007_exact_ubigeo") ///
    (`census2007_exact_ubigeo') ///
    ("validated") ///
    ("RUV records linked by exact ten-digit CCPP UBIGEO")

post `qa_post' ///
    ("census2007_unique_exact_path") ///
    (`census2007_exact_path') ///
    ("validated") ///
    ("Additional RUV records linked by a unique exact normalized full path")

post `qa_post' ///
    ("census2007_unique_district_name") ///
    (`census2007_exact_district_name') ///
    ("validated") ///
    ("Additional RUV records linked by unique exact district-code and CCPP name")

post `qa_post' ///
    ("census2007_name_code_conflicts") ///
    (`census2007_name_code_conflicts') ///
    ("quarantined") ///
    ("Exact UBIGEO retained when an exact-name candidate identified another code")

post `qa_post' ///
    ("census2007_linked") ///
    (`census2007_linked') ///
    ("validated") ///
    ("RUV records with 2007 census covariates")

post `qa_post' ///
    ("census2007_unmatched") ///
    (`census2007_unmatched') ///
    ("retained_unmatched") ///
    ("RUV records retained without 2007 census covariates")

post `qa_post' ///
    ("census2007_registry_rows") ///
    (`census2007_registry_rows') ///
    ("validated") ///
    ("All foundational RUV records retained after the 2007 census merge")

post `qa_post' ///
    ("geospatial_source_rows") ///
    (`geospatial_source_rows') ///
    ("validated") ///
    ("Unique 2017 CCPP points in the complete urban-rural spatial spine")

post `qa_post' ///
    ("geospatial_category_codes") ///
    (`geospatial_category_codes') ///
    ("validated") ///
    ("Valid ten-digit CCPP codes in the category point layer")

post `qa_post' ///
    ("geospatial_dispersed_points") ///
    (`geospatial_dispersed_points') ///
    ("documented_exclusion") ///
    ("Category-layer dispersed-population points coded zero and not CCPP-linkable")

post `qa_post' ///
    ("geospatial_category_linked") ///
    (`geospatial_category_linked') ///
    ("validated") ///
    ("Complete-spine CCPPs enriched by exact category-layer code")

post `qa_post' ///
    ("geospatial_basic_only") ///
    (`geospatial_basic_only') ///
    ("retained") ///
    ("Complete-spine CCPPs retained without category-layer enrichment")

post `qa_post' ///
    ("geospatial_category_only_codes") ///
    (`geospatial_category_only_codes') ///
    ("quarantined") ///
    ("Valid category-layer codes absent from the complete 94922-record spine")

post `qa_post' ///
    ("geospatial_area_disagreements") ///
    (`geospatial_area_disagreements') ///
    ("quarantined") ///
    ("GeoGPS-derived TIPO disagrees with underlying INEI AREA_CP classification")

post `qa_post' ///
    ("geospatial_district_capitals") ///
    (`geospatial_district_capitals') ///
    ("validated") ///
    ("One suffix-0001 capital for each 2017 district")

post `qa_post' ///
    ("geospatial_province_capitals") ///
    (`geospatial_province_capitals') ///
    ("validated") ///
    ("One district-01 CCPP-0001 capital for each province")

post `qa_post' ///
    ("geospatial_department_capitals") ///
    (`geospatial_department_capitals') ///
    ("validated") ///
    ("One province-01 district-01 CCPP-0001 capital for each department")

post `qa_post' ///
    ("geospatial_exact_current") ///
    (`geospatial_exact_current') ///
    ("validated") ///
    ("RUV records linked by exact current verified CCPP UBIGEO")

post `qa_post' ///
    ("geospatial_exact_census2007") ///
    (`geospatial_exact_census') ///
    ("validated") ///
    ("Additional RUV records linked by exact 2007 Census CCPP UBIGEO")

post `qa_post' ///
    ("geospatial_unique_exact_path") ///
    (`geospatial_exact_path') ///
    ("validated") ///
    ("Additional RUV records linked by unique exact normalized full path")

post `qa_post' ///
    ("geospatial_unique_district_name") ///
    (`geospatial_exact_district_name') ///
    ("validated") ///
    ("Additional RUV records linked by unique exact district-code and CCPP name")

post `qa_post' ///
    ("geospatial_code_conflicts") ///
    (`geospatial_code_conflicts') ///
    ("quarantined") ///
    ("Current verified CCPP code retained over a different valid 2007 Census code")

post `qa_post' ///
    ("geospatial_name_conflicts") ///
    (`geospatial_name_conflicts') ///
    ("quarantined") ///
    ("Current verified CCPP code retained over a different exact-name candidate")

post `qa_post' ///
    ("geospatial_linked") ///
    (`geospatial_linked') ///
    ("validated") ///
    ("RUV records linked to the 2017 geospatial spine")

post `qa_post' ///
    ("geospatial_altitude_available") ///
    (`geospatial_altitude_available') ///
    ("validated") ///
    ("Linked RUV records with category-layer altitude")

post `qa_post' ///
    ("geospatial_population_available") ///
    (`geospatial_population_available') ///
    ("validated") ///
    ("Linked RUV records with category-layer 2017 population")

post `qa_post' ///
    ("geospatial_unmatched") ///
    (`geospatial_unmatched') ///
    ("retained_unmatched") ///
    ("RUV records retained without 2017 geospatial attributes")

post `qa_post' ///
    ("geospatial_registry_rows") ///
    (`geospatial_registry_rows') ///
    ("validated") ///
    ("All RUV records retained after the geospatial merge")

post `qa_post' ///
    ("gdp_ccpp_source_rows") ///
    (`gdp_ccpp_source_rows') ///
    ("validated") ///
    ("Unique keyed CCPP rows in the Seminario-Palomino workbook")

post `qa_post' ///
    ("gdp_district_source_rows") ///
    (`gdp_district_source_rows') ///
    ("validated") ///
    ("Unique six-digit districts represented in the GDP source")

post `qa_post' ///
    ("gdp_department_source_rows") ///
    (`gdp_department_source_rows') ///
    ("validated") ///
    ("Two-digit departments represented in the GDP source")

post `qa_post' ///
    ("gdp_national_total_rows") ///
    (`gdp_national_total_rows') ///
    ("validated") ///
    ("Workbook total rows reconciled exactly to keyed annual sums")

post `qa_post' ///
    ("gdp_ccpp_zero_1993_2018") ///
    (`gdp_ccpp_zero_rows') ///
    ("source_feature") ///
    ("Source CCPPs with zero estimated GDP in every annual column")

post `qa_post' ///
    ("gdp_exact_current_ubigeo") ///
    (`gdp_exact_current') ///
    ("validated") ///
    ("RUV rows linked by exact current ten-digit CCPP UBIGEO")

post `qa_post' ///
    ("gdp_exact_census2007_ubigeo") ///
    (`gdp_exact_census2007') ///
    ("validated") ///
    ("Additional rows linked by unique unused exact Census 2007 UBIGEO")

post `qa_post' ///
    ("gdp_exact_geospatial_ubigeo") ///
    (`gdp_exact_geospatial') ///
    ("validated") ///
    ("Additional rows linked by unique unused exact spatial UBIGEO")

post `qa_post' ///
    ("gdp_unique_exact_full_path") ///
    (`gdp_exact_full_path') ///
    ("validated") ///
    ("Additional rows linked by a unique exact normalized full path")

post `qa_post' ///
    ("gdp_unique_exact_primary_name") ///
    (`gdp_exact_primary_name') ///
    ("validated") ///
    ("Additional rows linked by unique exact primary name within district")

post `qa_post' ///
    ("gdp_ccpp_linked") ///
    (`gdp_ccpp_linked') ///
    ("validated") ///
    ("RUV rows linked to a CCPP in the GDP source")

post `qa_post' ///
    ("gdp_ccpp_unmatched") ///
    (`gdp_ccpp_unmatched') ///
    ("retained_unmatched") ///
    ("RUV rows retained without a verified CCPP-level GDP link")

post `qa_post' ///
    ("gdp_ccpp_main_sample_linked") ///
    (`gdp_ccpp_main_linked') ///
    ("validated") ///
    ("Selected-sample RUV rows linked to a CCPP in the GDP source")

post `qa_post' ///
    ("gdp_district_linked") ///
    (`gdp_district_linked') ///
    ("validated") ///
    ("RUV rows linked to a district in the GDP source")

post `qa_post' ///
    ("gdp_district_unmatched") ///
    (`gdp_district_unmatched') ///
    ("retained_unmatched") ///
    ("RUV rows retained without verified GDP-district context")

post `qa_post' ///
    ("gdp_district_main_sample_linked") ///
    (`gdp_district_main_linked') ///
    ("validated") ///
    ("All selected-sample RUV rows linked to GDP-district context")

post `qa_post' ///
    ("gdp_registry_rows") ///
    (`gdp_registry_rows') ///
    ("validated") ///
    ("All RUV records retained after the GDP-source merge")

post `qa_post' ///
    ("electoral_2002_district_contests") ///
    (`election_2002_district_contests') ///
    ("validated") ///
    ("INFOgob ordinary municipal district contests in the 2002 cycle")

post `qa_post' ///
    ("electoral_2002_province_contests") ///
    (`election_2002_province_contests') ///
    ("validated") ///
    ("INFOgob ordinary municipal provincial contests in the 2002 cycle")

post `qa_post' ///
    ("electoral_2006_district_contests") ///
    (`election_2006_district_contests') ///
    ("validated") ///
    ("INFOgob ordinary municipal district contests in the 2006 cycle")

post `qa_post' ///
    ("electoral_2006_province_contests") ///
    (`election_2006_province_contests') ///
    ("validated") ///
    ("INFOgob ordinary municipal provincial contests in the 2006 cycle")

post `qa_post' ///
    ("electoral_2003_complementary_contests") ///
    (`emc_2002_contests') ///
    ("validated") ///
    ("Annulled 2002 district contests replaced by ONPE 2003 results")

post `qa_post' ///
    ("electoral_2007_complementary_contests") ///
    (`emc_2006_contests') ///
    ("validated") ///
    ("Annulled 2006 district contests replaced by ONPE 2007 results")

post `qa_post' ///
    ("electoral_2002_authority_candidate_mismatches") ///
    (`elect_2002_district_authmiss' + ///
     `elect_2002_province_authmiss') ///
    ("source_issue") ///
    ("Proclaimed winner organizations absent from the INFOgob candidate roster")

post `qa_post' ///
    ("electoral_2006_authority_candidate_mismatches") ///
    (`elect_2006_district_authmiss' + ///
     `elect_2006_province_authmiss') ///
    ("source_issue") ///
    ("Proclaimed winner organizations absent from the INFOgob candidate roster")

post `qa_post' ///
    ("electoral_isp_max_rounding_difference") ///
    (`election_isp_max_diff') ///
    ("validated") ///
    ("Maximum absolute difference from INFOgob's rounded ISP indicators")

post `qa_post' ///
    ("electoral_onpe_2002_matched_contests") ///
    (`onpe_2002_match_n') ///
    ("partial_validation") ///
    ("Non-complementary 2002 INFOgob contests represented in ONPE mesa returns")

post `qa_post' ///
    ("electoral_onpe_2002_infogob_only") ///
    (`onpe_2002_infogob_only_n') ///
    ("source_issue") ///
    ("Non-complementary INFOgob contests absent from the acquired ONPE file")

post `qa_post' ///
    ("electoral_onpe_2002_complementary_excluded") ///
    (`onpe_2002_emc_excluded_n') ///
    ("validated") ///
    ("Annulled ordinary contests replaced by the 2003 complementary results")

post `qa_post' ///
    ("electoral_onpe_2002_differing_contests") ///
    (`onpe_2002_diff_n') ///
    ("source_issue") ///
    ("Matched contests with at least one INFOgob-ONPE difference above 1e-10")

post `qa_post' ///
    ("electoral_onpe_2002_registered_max_difference") ///
    (`onpe_2002_reg_max') ///
    ("source_issue") ///
    ("Maximum absolute electorate difference among matched 2002 contests")

post `qa_post' ///
    ("electoral_onpe_2002_statistics_max_difference") ///
    (`onpe_2002_stats_max') ///
    ("source_issue") ///
    ("Maximum turnout, invalid-vote, vote-share, margin, or HHI difference")

post `qa_post' ///
    ("electoral_onpe_2006_ordinary_reconciled") ///
    (`onpe_ordinary_n') ///
    ("validated") ///
    ("Non-complementary 2006 contests reproduced from official ONPE mesa returns")

post `qa_post' ///
    ("electoral_onpe_2006_complementary_excluded") ///
    (`onpe_emc_excluded_n') ///
    ("validated") ///
    ("Annulled ordinary contests replaced by the 2007 complementary results")

post `qa_post' ///
    ("electoral_onpe_2006_registered_max_difference") ///
    (`onpe_reg_max') ///
    ("validated") ///
    ("Maximum absolute electorate difference between INFOgob and ONPE")

post `qa_post' ///
    ("electoral_onpe_2006_statistics_max_difference") ///
    (`onpe_stats_max') ///
    ("validated") ///
    ("Maximum absolute turnout, invalid-vote, vote-share, margin, or HHI difference")

post `qa_post' ///
    ("electoral_2002_ruv_linked") ///
    (`electoral_2002_linked') ///
    ("validated") ///
    ("RUV rows linked to their governing municipality in the 2002 cycle")

post `qa_post' ///
    ("electoral_2002_ruv_unmatched") ///
    (`electoral_2002_unmatched') ///
    ("validated") ///
    ("RUV rows retained without a governing-election link in the 2002 cycle")

post `qa_post' ///
    ("electoral_2002_main_sample_linked") ///
    (`electoral_2002_main_linked') ///
    ("validated") ///
    ("Selected-sample RUV rows linked to the 2002 municipal cycle")

post `qa_post' ///
    ("electoral_2006_ruv_linked") ///
    (`electoral_2006_linked') ///
    ("validated") ///
    ("RUV rows linked to their governing municipality in the 2006 cycle")

post `qa_post' ///
    ("electoral_2006_ruv_unmatched") ///
    (`electoral_2006_unmatched') ///
    ("validated") ///
    ("RUV rows retained without a governing-election link in the 2006 cycle")

post `qa_post' ///
    ("electoral_2006_main_sample_linked") ///
    (`electoral_2006_main_linked') ///
    ("validated") ///
    ("Selected-sample RUV rows linked to the 2006 municipal cycle")

post `qa_post' ///
    ("electoral_both_cycles_ruv_linked") ///
    (`electoral_both_linked') ///
    ("validated") ///
    ("RUV rows linked to both pre-program municipal election cycles")

post `qa_post' ///
    ("electoral_registry_rows") ///
    (`electoral_registry_rows') ///
    ("validated") ///
    ("All RUV records retained after the municipal-election merge")

post `qa_post' ///
    ("sisfoh2013_person_records") ///
    (`sisfoh2013_person_records') ///
    ("validated") ///
    ("National person records; exactly matches INEI's published fieldwork total")

post `qa_post' ///
    ("sisfoh2013_household_records") ///
    (`sisfoh2013_household_records') ///
    ("validated") ///
    ("All household-file records, including noninterviews and vacant dwellings")

post `qa_post' ///
    ("sisfoh2013_households_with_information") ///
    (`sisfoh2013_households_info') ///
    ("validated") ///
    ("Complete or incomplete interviews; exactly matches INEI's published total")

post `qa_post' ///
    ("sisfoh2013_complete_households") ///
    (`sisfoh2013_complete_households') ///
    ("validated") ///
    ("Households with final interview result complete")

post `qa_post' ///
    ("sisfoh2013_incomplete_households") ///
    (`sisfoh2013_incomplete_hh') ///
    ("retained") ///
    ("Households with partial information retained with item-specific missingness")

post `qa_post' ///
    ("sisfoh2013_source_ccpp") ///
    (`sisfoh2013_source_ccpp') ///
    ("validated") ///
    ("Unique ten-digit CCPP codes represented by households with information")

post `qa_post' ///
    ("sisfoh2013_ccpp_attribute_conflicts") ///
    (`sisfoh2013_ccpp_attr_conflict') ///
    ("resolved_modal_record") ///
    ("CCPP codes with multiple descriptive records; modal record selected deterministically")

post `qa_post' ///
    ("sisfoh2013_ccpp_modal_ties") ///
    (`sisfoh2013_ccpp_modal_ties') ///
    ("resolved_lexical_tie") ///
    ("CCPP codes whose most frequent descriptive record tied; lexical order selected")

post `qa_post' ///
    ("sisfoh2013_person_age_missing") ///
    (`sisfoh2013_person_age_missing') ///
    ("source_missingness") ///
    ("Rostered person records without a valid reported age")

post `qa_post' ///
    ("sisfoh2013_person_order_disagreements") ///
    (`sisfoh2013_person_order_diff') ///
    ("source_issue") ///
    ("NRO differs from NRO_ORD; unique canonical person order uses NRO")

post `qa_post' ///
    ("sisfoh2013_language_eligible") ///
    (`sisfoh2013_language_eligible') ///
    ("denominator") ///
    ("People age three or older with valid age")

post `qa_post' ///
    ("sisfoh2013_language_valid") ///
    (`sisfoh2013_language_valid') ///
    ("source_missingness") ///
    ("Eligible people with a valid childhood-language response")

post `qa_post' ///
    ("sisfoh2013_household_items_missing") ///
    (`sisfoh2013_hh_items_missing') ///
    ("source_missingness") ///
    ("Households missing the main dwelling and services block")

post `qa_post' ///
    ("sisfoh2013_fieldwork_year_invalid") ///
    (`sisfoh2013_invalid_year') ///
    ("source_issue") ///
    ("Households with information whose recorded final year is outside 2012-2013")

post `qa_post' ///
    ("sisfoh2013_fieldwork_month_invalid") ///
    (`sisfoh2013_invalid_month') ///
    ("source_issue") ///
    ("Households with information whose recorded final month is invalid")

post `qa_post' ///
    ("sisfoh2013_fieldwork_day_invalid") ///
    (`sisfoh2013_invalid_day') ///
    ("source_issue") ///
    ("Households with information whose recorded final day is invalid")

post `qa_post' ///
    ("sisfoh2013_calendar_date_invalid") ///
    (`sisfoh2013_bad_calendar_date') ///
    ("source_issue") ///
    ("Households whose final day-month-year combination is not a valid calendar date")

post `qa_post' ///
    ("sisfoh2013_roster_total_mismatches") ///
    (`sisfoh2013_roster_total_diff') ///
    ("source_issue") ///
    ("Household source total differs from exact linked person-roster count")

post `qa_post' ///
    ("sisfoh2013_legacy_ccpp_matched") ///
    (`sisfoh2013_legacy_ccpp_matched') ///
    ("reconciliation") ///
    ("Legacy-derived CCPP rows found in the national microdata aggregation")

post `qa_post' ///
    ("sisfoh2013_legacy_population_exact") ///
    (`sisfoh2013_legacy_pop_exact') ///
    ("reconciliation") ///
    ("Matched legacy CCPP rows reproducing the roster population exactly")

post `qa_post' ///
    ("sisfoh2013_legacy_households_exact") ///
    (`sisfoh2013_legacy_hh_exact') ///
    ("reconciliation") ///
    ("Matched legacy CCPP rows reproducing household counts exactly")

post `qa_post' ///
    ("sisfoh2013_legacy_nbi1_exact") ///
    (`sisfoh2013_legacy_nbi1_exact') ///
    ("reconciliation") ///
    ("Matched legacy CCPP rows reproducing NBI1 counts exactly")

post `qa_post' ///
    ("sisfoh2013_legacy_nbi2_exact") ///
    (`sisfoh2013_legacy_nbi2_exact') ///
    ("reconciliation") ///
    ("Matched legacy CCPP rows reproducing NBI2 counts exactly")

post `qa_post' ///
    ("sisfoh2013_legacy_nbi3_exact") ///
    (`sisfoh2013_legacy_nbi3_exact') ///
    ("reconciliation") ///
    ("Matched legacy CCPP rows reproducing NBI3 counts exactly")

post `qa_post' ///
    ("sisfoh2013_legacy_nbi5_exact") ///
    (`sisfoh2013_legacy_nbi5_exact') ///
    ("reconciliation") ///
    ("Matched legacy CCPP rows reproducing NBI5 counts exactly")

post `qa_post' ///
    ("sisfoh2013_ambiguous_code_candidates") ///
    (`sisfoh2013_ambiguous_code_rows') ///
    ("quarantined") ///
    ("Same-priority code candidates excluded from deterministic linkage")

post `qa_post' ///
    ("sisfoh2013_exact_current_code") ///
    (`sisfoh2013_exact_current') ///
    ("validated") ///
    ("RUV rows linked by the verified canonical CCPP code")

post `qa_post' ///
    ("sisfoh2013_exact_census2007_code") ///
    (`sisfoh2013_exact_census') ///
    ("validated") ///
    ("Additional RUV rows linked by the 2007 Census CCPP code")

post `qa_post' ///
    ("sisfoh2013_exact_geospatial_code") ///
    (`sisfoh2013_exact_geospatial') ///
    ("validated") ///
    ("Additional RUV rows linked by the 2017 geospatial CCPP code")

post `qa_post' ///
    ("sisfoh2013_exact_gdp_code") ///
    (`sisfoh2013_exact_gdp') ///
    ("validated") ///
    ("Additional RUV rows linked by the GDP-source CCPP code")

post `qa_post' ///
    ("sisfoh2013_unique_exact_path") ///
    (`sisfoh2013_exact_name') ///
    ("validated") ///
    ("Additional RUV rows linked by a unique normalized full geographic path")

post `qa_post' ///
    ("sisfoh2013_ruv_linked") ///
    (`sisfoh2013_ruv_linked') ///
    ("validated") ///
    ("RUV communities linked deterministically to SISFOH CCPPs")

post `qa_post' ///
    ("sisfoh2013_ruv_unmatched") ///
    (`sisfoh2013_ruv_unmatched') ///
    ("retained_unmatched") ///
    ("RUV communities retained without a deterministic SISFOH link")

post `qa_post' ///
    ("sisfoh2013_main_sample_linked") ///
    (`sisfoh2013_main_sample_linked') ///
    ("validated") ///
    ("Selected main-RD sample rows linked to SISFOH")

post `qa_post' ///
    ("sisfoh2013_individual_analysis_rows") ///
    (`sisfoh2013_indiv_rows') ///
    ("validated") ///
    ("RUV-linked person records in the coded individual analysis file")

post `qa_post' ///
    ("sisfoh2013_household_analysis_rows") ///
    (`sisfoh2013_hh_analysis_rows') ///
    ("validated") ///
    ("RUV-linked household records in the coded household analysis file")

post `qa_post' ///
    ("sisfoh2013_registry_rows") ///
    (`sisfoh2013_registry_rows') ///
    ("validated") ///
    ("All RUV rows retained after adding CCPP-level SISFOH outcomes")

post `qa_post' ///
    ("census2017_public_person_rows") ///
    (`census2017_public_person_rows') ///
    ("validated") ///
    ("Official national public Census person-module rows; district geography only")

post `qa_post' ///
    ("census2017_public_household_rows") ///
    (`census2017_public_hh_rows') ///
    ("validated") ///
    ("Official national public Census household-module rows; district geography only")

post `qa_post' ///
    ("census2017_public_dwelling_rows") ///
    (`cpv2017_public_dwelling_rows') ///
    ("validated") ///
    ("Official national public Census dwelling-module rows; district geography only")

post `qa_post' ///
    ("census2017_source_ccpp_codes") ///
    (`census2017_source_ccpp_rows') ///
    ("validated") ///
    ("INEI-assisted source CCPP codes accepted in the frozen crosswalk")

post `qa_post' ///
    ("census2017_source_ruv_rows") ///
    (`census2017_source_ruv_rows') ///
    ("validated") ///
    ("Canonical RUV communities represented by the 807 source codes")

post `qa_post' ///
    ("census2017_cohort_rows") ///
    (`census2017_cohort_rows') ///
    ("validated") ///
    ("All people in the INEI-assisted SISFOH-to-Census cohort retained")

post `qa_post' ///
    ("census2017_linked_rows") ///
    (`census2017_linked_rows') ///
    ("validated") ///
    ("Cohort people linked by INEI to a 2017 Census record")

post `qa_post' ///
    ("census2017_not_linked_rows") ///
    (`census2017_not_linked_rows') ///
    ("retained_missing") ///
    ("Cohort people retained with Census outcomes missing; never coded as migration")

forvalues stage = 0/3 {
    post `qa_post' ///
        ("census2017_link_stage_`stage'") ///
        (`census2017_stage`stage'_rows') ///
        ("validated") ///
        ("INEI linkage-stage count reproduced from the technical handoff")
}

post `qa_post' ///
    ("census2017_person_key_source") ///
    (`census2017_person_key_source') ///
    ("validated") ///
    ("Canonical SISFOH persons recovered by source CCPP and roster coordinates")

post `qa_post' ///
    ("census2017_person_key_inei") ///
    (`census2017_person_key_inei') ///
    ("validated") ///
    ("Additional persons recovered by INEI CCPP and roster coordinates")

post `qa_post' ///
    ("census2017_person_key_district") ///
    (`census2017_person_key_district') ///
    ("validated") ///
    ("Additional persons recovered by a unique district-roster-age-sex key")

post `qa_post' ///
    ("census2017_person_key_unresolved") ///
    (`cpv2017_person_key_unresolved') ///
    ("retained_unresolved") ///
    ("Cohort people retained without a forced canonical SISFOH person match")

post `qa_post' ///
    ("census2017_household_key_conflicts") ///
    (`cpv2017_hh_key_conflicts') ///
    ("quarantined") ///
    ("Source households whose recovered members imply multiple canonical SISFOH households")

post `qa_post' ///
    ("census2017_household_conflict_persons") ///
    (`cpv2017_hh_conflict_persons') ///
    ("quarantined") ///
    ("People in source households with conflicting canonical SISFOH household IDs")

post `qa_post' ///
    ("census2017_sisfoh_age_disagreements") ///
    (`cpv2017_sisfoh_age_disagree') ///
    ("diagnostic") ///
    ("Recovered SISFOH person keys whose source and canonical ages differ")

post `qa_post' ///
    ("census2017_sisfoh_sex_disagreements") ///
    (`cpv2017_sisfoh_sex_disagree') ///
    ("diagnostic") ///
    ("Recovered SISFOH person keys whose source and canonical sex values differ")

post `qa_post' ///
    ("census2017_baseline_households") ///
    (`census2017_baseline_hh_rows') ///
    ("validated") ///
    ("De-identified 2013 source households in the INEI-assisted cohort")

post `qa_post' ///
    ("census2017_sisfoh_households_recovered") ///
    (`census2017_sisfoh_hh_rows') ///
    ("validated") ///
    ("Source households recovered in the canonical SISFOH household file")

post `qa_post' ///
    ("census2017_destination_households") ///
    (`census2017_destination_hh_rows') ///
    ("validated") ///
    ("Distinct 2017 destination households represented by linked people")

post `qa_post' ///
    ("census2017_destination_roster_complete") ///
    (`cpv2017_dest_hh_complete') ///
    ("validated") ///
    ("Destination households whose full Census roster is present in the delivery")

post `qa_post' ///
    ("census2017_destination_roster_partial") ///
    (`cpv2017_dest_hh_partial') ///
    ("restricted") ///
    ("Destination households represented by only part of their Census roster")

post `qa_post' ///
    ("census2017_destination_roster_missing") ///
    (`cpv2017_dest_hh_no_roster') ///
    ("restricted") ///
    ("Destination household IDs without a reported Census household size")

post `qa_post' ///
    ("census2017_destination_roster_overfull") ///
    (`cpv2017_dest_hh_overfull') ///
    ("quarantined") ///
    ("Destination households with delivery rows exceeding the reported roster")

post `qa_post' ///
    ("census2017_migration_observed") ///
    (`cpv2017_migration_observed') ///
    ("validated") ///
    ("Linked people with valid source and destination CCPP codes")

post `qa_post' ///
    ("census2017_moved_ccpp_rows") ///
    (`cpv2017_moved_ccpp_rows') ///
    ("descriptive") ///
    ("Linked people living in a different CCPP in 2017")

post `qa_post' ///
    ("census2017_moved_district_rows") ///
    (`cpv2017_moved_district_rows') ///
    ("descriptive") ///
    ("Linked people living in a different district in 2017")

post `qa_post' ///
    ("census2017_individual_analysis_rows") ///
    (`census2017_person_analysis_rows') ///
    ("validated") ///
    ("All source-cohort people in the coded individual analysis file")

post `qa_post' ///
    ("census2017_household_analysis_rows") ///
    (`census2017_household_rows') ///
    ("validated") ///
    ("All source households in the coded household analysis file")

post `qa_post' ///
    ("census2017_main_sample_covered") ///
    (`census2017_main_sample_covered') ///
    ("validated") ///
    ("Selected main-RD sample communities represented in the linked cohort")

post `qa_post' ///
    ("census2017_registry_rows") ///
    (`census2017_registry_rows') ///
    ("validated") ///
    ("All RUV rows retained after adding linked-cohort Census outcomes")

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

preserve
keep if strpos(metric, "census2007_") == 1
export delimited ///
    "${metadata_root}/census-2007/sample-flow.csv", ///
    replace
restore

preserve
keep if strpos(metric, "geospatial_") == 1
export delimited ///
    "${metadata_root}/geospatial-2017/sample-flow.csv", ///
    replace
restore

preserve
keep if strpos(metric, "gdp_") == 1
export delimited ///
    "${metadata_root}/gdp-ccpp/sample-flow.csv", ///
    replace
restore

preserve
keep if strpos(metric, "electoral_") == 1
export delimited ///
    "${metadata_root}/municipal-elections/sample-flow.csv", ///
    replace
restore

preserve
keep if strpos(metric, "sisfoh2013_") == 1
export delimited ///
    "${metadata_root}/sisfoh-2013/sample-flow.csv", ///
    replace
restore

preserve
keep if strpos(metric, "census2017_") == 1
export delimited ///
    "${metadata_root}/census-2017/sample-flow.csv", ///
    replace
restore

preserve
keep if inlist( ///
    metric, ///
    "victimization_rows", ///
    "victimization_score_distinct_values", ///
    "victimization_score_rounded_minimum", ///
    "victimization_score_above_one", ///
    "victimization_level_rounding_disagreements") | ///
    inlist( ///
    metric, ///
    "victimization_level_true_conflicts", ///
    "victimization_formula_matches_uncapped", ///
    "victimization_formula_matches_capped", ///
    "victimization_score_equal_one", ///
    "victimization_score_cap_consistent") | ///
    metric == "victimization_inferred_common_scale"
export delimited ///
    "${metadata_root}/rd-design/index-formula-audit.csv", ///
    replace
restore

display as result "Data-preparation staging completed."
display as text   "INEI CCPP rows:                  `inei_ccpp_rows'"
display as text   "Historical source rows pooled:  `historical_source_rows'"
display as text   "RUV victimization rows:          `victimization_rows'"
display as text   "Historical exact RUV recoveries: `victim_hist_exact_n'"
display as text   "CMAN project rows:               `cman_project_rows'"
display as text   "CMAN multisector project titles: `cman_multisector_projects'"
display as text   "CMAN projects with cofinancing:  `cman_cofinanced_projects'"
display as text   "CMAN taxonomy manual overrides:  `cman_project_manual_overrides'"
display as text   "Historical exact CMAN codes:     `cman_historical_ccpp_exact'"
display as text   "Historical codes quarantined:    `cman_hist_code_conflicts'"
display as text   "Exact CMAN-to-RUV links:         `cman_victim_exact'"
display as text   "Exact UBIGEO CMAN-to-RUV links:  `cman_victim_exact_ubigeo'"
display as text   "Adjudicated CMAN-to-RUV links:   `cman_adjud_retained'"
display as text   "CMAN rows outside the RUV universe: `cman_victim_unresolved'"
display as text   "RUV rows retained without code:  `victimization_inei_unresolved'"
display as text   "Final victimization-universe rows: `foundational_rows'"
display as text   "2007 census source rows:         `census2007_source_rows'"
display as text   "2007 census exact-code links:    `census2007_exact_ubigeo'"
display as text   "2007 census exact-name links:    " ///
    `census2007_exact_path' + `census2007_exact_district_name'
display as text   "RUV rows with 2007 covariates:   `census2007_linked'"
display as text   "RUV rows without 2007 covariates: `census2007_unmatched'"
display as text   "2017 geospatial source rows:     `geospatial_source_rows'"
display as text   "RUV rows with spatial attributes: `geospatial_linked'"
display as text   "RUV rows without spatial attributes: `geospatial_unmatched'"
display as text   "RUV rows with altitude:          `geospatial_altitude_available'"
display as text   "CCPP GDP source rows:            `gdp_ccpp_source_rows'"
display as text   "RUV rows with CCPP GDP:          `gdp_ccpp_linked'"
display as text   "RUV rows without CCPP GDP:       `gdp_ccpp_unmatched'"
display as text   "RUV rows with district GDP:      `gdp_district_linked'"
display as text   "Selected rows with CCPP GDP:     `gdp_ccpp_main_linked'"
display as text   "Main RD geographic sample rows: `main_rd_sample_rows'"
display as text   "SISFOH person source rows:       `sisfoh2013_person_records'"
display as text   "SISFOH households with information: `sisfoh2013_households_info'"
display as text   "SISFOH source CCPPs:             `sisfoh2013_source_ccpp'"
display as text   "RUV rows linked to SISFOH:       `sisfoh2013_ruv_linked'"
display as text   "RUV rows without SISFOH link:    `sisfoh2013_ruv_unmatched'"
display as text   "SISFOH individual analysis rows: `sisfoh2013_indiv_rows'"
display as text   "SISFOH household analysis rows:  `sisfoh2013_hh_analysis_rows'"
display as text   "Census 2017 source-cohort rows:   `census2017_cohort_rows'"
display as text   "Census-linked cohort rows:        `census2017_linked_rows'"
display as text   "Census-unlinked rows retained:    `census2017_not_linked_rows'"
display as text   "Census source households:         `census2017_household_rows'"
display as text   "Census cohort RUV communities:    `census2017_ccpp_covered'"
display as text   "Census CCPP registry rows:         `census2017_registry_rows'"
display as text   "All RUV rows retained with complete treatment status."

capture program drop victimasrd_normalize_name
capture program drop victimasrd_score_name_pairs
