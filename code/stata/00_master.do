/*------------------------------------------------------------------------------*
| Title:            Master code                                                 |
| Project:          Victimas RD                                                 |
| Authors:          Jorge Zavala, Matthew Bird, Ana María Dumez                 |
|                                                                               |
| Description:      Configure the project environment, validate paths and       |
|                   dependencies, and optionally run the ordered pipeline.      |
|                                                                               |
| Date created:     27 July 2026                                                |
| Last updated:     29 July 2026                                                |
| Stata version:    19                                                          |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

    0. Session setup
    1. Machine-specific path configuration
    2. Project directories and safety checks
    3. Project-local user-written dependencies
    4. Pipeline switches
    5. Ordered pipeline execution
    6. Session closeout

*-------------------------------------------------------------------------------*/


*-----------------------------------*
**# 0. Session setup
*-----------------------------------*

version 19
clear all
clear mata
capture log close _all
set more off
set varabbrev off
set maxvar 32767
set linesize 255
set rng mt64s
set seed 18092018
set sortseed 18092018


*-----------------------------------*
**# 1. Machine-specific path configuration
*-----------------------------------*

/*
Every collaborator must:

    1. copy config/paths.example.do to config/paths.local.do;
    2. edit only the local copy for that machine; and
    3. keep config/paths.local.do untracked.

Run this master from either the repository root:

    do code/stata/00_master.do

or from code/stata:

    do 00_master.do

The master also searches standard user-specific clone locations, so opening
this file in Stata's Do-file Editor and pressing Execute does not depend on the
current working directory. A nonstandard clone can be exposed through the
VICTIMASRD_PROJECT_ROOT environment variable.
*/

local paths_file
local paths_found 0

/*
First search the current directory and its parents. This covers execution from
any directory inside the repository.
*/

local relative_candidates ///
    "config/paths.local.do" ///
    "../config/paths.local.do" ///
    "../../config/paths.local.do" ///
    "../../../config/paths.local.do" ///
    "../../../../config/paths.local.do" ///
    "../../../../../config/paths.local.do" ///
    "../../../../../../config/paths.local.do"

foreach candidate of local relative_candidates {
    if !`paths_found' {
        capture confirm file "`candidate'"

        if !_rc {
            local paths_file "`candidate'"
            local paths_found 1
        }
    }
}

/*
Next honor an optional explicit project-root environment variable.
*/

if !`paths_found' {
    local environment_root : environment VICTIMASRD_PROJECT_ROOT
    local environment_root = ///
        subinstr("`environment_root'", "\", "/", .)

    if `"`environment_root'"' != "" {
        local candidate ///
            "`environment_root'/config/paths.local.do"
        capture confirm file "`candidate'"

        if !_rc {
            local paths_file "`candidate'"
            local paths_found 1
        }
    }
}

/*
Finally search the standard Windows clone locations without hard-coding a
username. USERPROFILE covers the repository layout used by this project;
OneDrive covers collaborators whose Documents directory is redirected.
*/

if !`paths_found' {
    local user_profile : environment USERPROFILE
    local user_profile = subinstr("`user_profile'", "\", "/", .)
    local candidate ///
        "`user_profile'/Documents/GitHub/VictimasRD/config/paths.local.do"
    capture confirm file "`candidate'"

    if !_rc {
        local paths_file "`candidate'"
        local paths_found 1
    }
}

if !`paths_found' {
    local one_drive : environment OneDrive
    local one_drive = subinstr("`one_drive'", "\", "/", .)

    if `"`one_drive'"' != "" {
        local candidate ///
            "`one_drive'/Documents/GitHub/VictimasRD/config/paths.local.do"
        capture confirm file "`candidate'"

        if !_rc {
            local paths_file "`candidate'"
            local paths_found 1
        }
    }
}

if !`paths_found' {
    display as error "Machine-specific path configuration was not found."
    display as error "Searched parent directories and standard GitHub clone locations."
    display as error "Copy config/paths.example.do, edit the local copy, and rerun the master."
    display as error "For a nonstandard clone, set VICTIMASRD_PROJECT_ROOT to the repository root."
    exit 601
}

quietly do "`paths_file'"

local required_globals ///
    project_root ///
    dropbox_root ///
    overleaf_root ///
    data_root ///
    raw_root ///
    working_root ///
    coded_root ///
    external_raw_root ///
    legacy_working_root ///
    legacy_coded_root ///
    pipeline_working_root ///
    intermediate_root ///
    staging_root ///
    qa_data_root ///
    external_derived_root ///
    analysis_data_root ///
    build_root ///
    output_root ///
    figures_root ///
    tables_root ///
    metadata_root ///
    logs_root

foreach global_name of local required_globals {
    local global_value "${`global_name'}"

    if `"`global_value'"' == "" {
        display as error "Required global is missing from config/paths.local.do:"
        display as error "  `global_name'"
        exit 198
    }
}

capture confirm file "${project_root}/config/paths.local.do"

if _rc {
    display as error "The loaded path file does not agree with project_root."
    display as error "Expected: ${project_root}/config/paths.local.do"
    exit 601
}

cd "${project_root}"


*-----------------------------------*
**# 2. Project directories and safety checks
*-----------------------------------*

global code_root       "${project_root}/code/stata"
global pipeline_root   "${code_root}/pipeline"
global ado_root        "${build_root}/ado"

/*
Dropbox Raw is immutable. Persistent intermediates, staging files, and
row-level QA products belong under Working; final analytical datasets belong
under Coded. Git-local build is only a package/cache area, while reviewed
non-sensitive tables and figures belong under output.
*/

local project_lower          = lower(subinstr("${project_root}", "\", "/", .))
local data_lower             = lower(subinstr("${data_root}", "\", "/", .))
local raw_lower              = lower(subinstr("${raw_root}", "\", "/", .))
local working_lower          = lower(subinstr("${working_root}", "\", "/", .))
local coded_lower            = lower(subinstr("${coded_root}", "\", "/", .))
local pipeline_working_lower = lower(subinstr("${pipeline_working_root}", "\", "/", .))
local intermediate_lower     = lower(subinstr("${intermediate_root}", "\", "/", .))
local staging_lower          = lower(subinstr("${staging_root}", "\", "/", .))
local qa_data_lower          = lower(subinstr("${qa_data_root}", "\", "/", .))
local external_derived_lower = lower(subinstr("${external_derived_root}", "\", "/", .))
local analysis_data_lower    = lower(subinstr("${analysis_data_root}", "\", "/", .))
local external_raw_lower     = lower(subinstr("${external_raw_root}", "\", "/", .))
local legacy_working_lower   = lower(subinstr("${legacy_working_root}", "\", "/", .))
local legacy_coded_lower     = lower(subinstr("${legacy_coded_root}", "\", "/", .))
local build_lower            = lower(subinstr("${build_root}", "\", "/", .))
local output_lower           = lower(subinstr("${output_root}", "\", "/", .))

if strpos("`build_lower'", "`project_lower'/") != 1 {
    display as error "Unsafe build_root: it must be inside project_root."
    display as error "  project_root = ${project_root}"
    display as error "  build_root   = ${build_root}"
    exit 198
}

if strpos("`output_lower'", "`project_lower'/") != 1 {
    display as error "Unsafe output_root: it must be inside project_root."
    display as error "  project_root = ${project_root}"
    display as error "  output_root  = ${output_root}"
    exit 198
}

if strpos("`build_lower'", "`data_lower'/") == 1 {
    display as error "Unsafe build_root: the local dependency cache cannot be under Dropbox data."
    exit 198
}

if strpos("`raw_lower'", "`data_lower'/") != 1 | ///
   strpos("`working_lower'", "`data_lower'/") != 1 | ///
   strpos("`coded_lower'", "`data_lower'/") != 1 {
    display as error "Unsafe Dropbox data contract: Raw, Working, and Coded must be under data_root."
    exit 198
}

if strpos("`working_lower'", "`raw_lower'/") == 1 | ///
   strpos("`coded_lower'", "`raw_lower'/") == 1 {
    display as error "Unsafe Dropbox data contract: Working and Coded cannot be inside Raw."
    exit 198
}

if strpos("`pipeline_working_lower'", "`working_lower'/") != 1 | ///
   strpos("`intermediate_lower'", "`pipeline_working_lower'/") != 1 | ///
   strpos("`staging_lower'", "`pipeline_working_lower'/") != 1 | ///
   strpos("`qa_data_lower'", "`pipeline_working_lower'/") != 1 | ///
   strpos("`external_derived_lower'", "`pipeline_working_lower'/") != 1 {
    display as error "Unsafe Working path contract: current pipeline products must remain under Working."
    exit 198
}

if strpos("`analysis_data_lower'", "`coded_lower'/") != 1 {
    display as error "Unsafe Coded path contract: analysis datasets must remain under Coded."
    exit 198
}

if strpos("`external_raw_lower'", "`raw_lower'/") != 1 {
    display as error "Unsafe external_raw_root: external sources must remain under Raw."
    exit 198
}

if strpos("`legacy_working_lower'", "`working_lower'/") != 1 | ///
   strpos("`legacy_coded_lower'", "`coded_lower'/") != 1 {
    display as error "Unsafe archive path contract: legacy data must remain under Working or Coded."
    exit 198
}

local required_read_globals ///
    project_root ///
    code_root ///
    pipeline_root ///
    dropbox_root ///
    data_root ///
    raw_root ///
    working_root ///
    coded_root ///
    external_raw_root

foreach global_name of local required_read_globals {
    local required_dir "${`global_name'}"

    if !direxists("`required_dir'") {
        display as error "Required project/input directory not found:"
        display as error "  `required_dir'"
        exit 601
    }
}

/*
Create only approved current-pipeline destinations under Dropbox Working and
Coded. The dated archive roots and Raw tree are never modified by the master.
*/

foreach writable_directory in ///
    "${pipeline_working_root}" ///
    "${intermediate_root}" ///
    "${staging_root}" ///
    "${qa_data_root}" ///
    "${external_derived_root}" ///
    "${analysis_data_root}" {

    capture mkdir "`writable_directory'"
    if !direxists("`writable_directory'") {
        display as error "Unable to create approved Dropbox data destination:"
        display as error "  `writable_directory'"
        exit 603
    }
}

local required_write_globals ///
    output_root ///
    figures_root ///
    tables_root ///
    metadata_root ///
    logs_root

foreach global_name of local required_write_globals {
    local required_dir "${`global_name'}"

    if !direxists("`required_dir'") {
        display as error "Required Git-local output directory not found:"
        display as error "  `required_dir'"
        exit 601
    }
}

/*
Create only the Git-ignored dependency/cache directory in the repository.
No dataset may be written below build_root.
*/

capture mkdir "${build_root}"
capture mkdir "${ado_root}"

local build_globals ///
    build_root ///
    ado_root

foreach global_name of local build_globals {
    local build_dir "${`global_name'}"

    if !direxists("`build_dir'") {
        display as error "Unable to create required Git-ignored build directory:"
        display as error "  `build_dir'"
        exit 603
    }
}

local run_date = subinstr("`c(current_date)'", " ", "", .)
local run_time = subinstr("`c(current_time)'", ":", "", .)
local run_id   = lower("`run_date'_`run_time'")

log using "${logs_root}/master_`run_id'.smcl", ///
    name(victimasrd_master) replace

display as text "Victimas RD master started: `c(current_date)' `c(current_time)'"
display as text "Repository root:     ${project_root}"
display as text "Dropbox Raw:         ${raw_root} (read-only)"
display as text "Dropbox Working:     ${pipeline_working_root}"
display as text "Dropbox Coded:       ${analysis_data_root}"
display as text "Local package cache: ${ado_root}"
display as text "Git outputs:         ${output_root}"


*-----------------------------------*
**# 3. Project-local user-written dependencies
*-----------------------------------*

/*
Development bootstrap
---------------------
Missing packages are installed into ${ado_root}, which is under the ignored
build directory. This avoids silently modifying the preserved legacy ado tree.

The package list is intentionally broad enough for the expected data audit,
community matching, spatial work, modern RD methods, inference, and academic
output workflow. Add packages only when a reviewed pipeline module requires
them.

This bootstrap is not the final release environment. Before results are
certified, replace unversioned network installation with a reviewed dependency
manifest or a license-compliant, version-locked package snapshot.
*/

local install_missing_packages 1
assert inlist(`install_missing_packages', 0, 1)

sysdir set PLUS "${ado_root}"
discard

/*
Each adjacent pair is:

    SSC package name    command used to verify installation
*/

local ssc_package_command_pairs ///
    rddensity   rddensity ///
    lpdensity   lpdensity ///
    rdpower     rdpower ///
    reclink     reclink ///
    freqindex   freqindex ///
    matchit     matchit ///
    strdist     strdist ///
    geodist     geodist ///
    geonear     geonear ///
    distinct    distinct ///
    unique      unique ///
    gtools      gtools ///
    ftools      ftools ///
    rangestat   rangestat ///
    rangejoin   rangejoin ///
    carryforward carryforward ///
    labutil2    labvars ///
    fre         fre ///
    ivreg2      ivreg2 ///
    ranktest    ranktest ///
    boottest    boottest ///
    reghdfe     reghdfe ///
    ivreghdfe   ivreghdfe ///
    ritest      ritest ///
    estout      esttab ///
    outreg2     outreg2 ///
    coefplot    coefplot ///
    grc1leg2    grc1leg2 ///
    spmap       spmap ///
    winsor2     winsor2 ///
    sumstats    sumstats ///
    keeporder   keeporder

local pair_count : word count `ssc_package_command_pairs'
assert mod(`pair_count', 2) == 0

local missing_commands

forvalues package_index = 1(2)`pair_count' {
    local command_index = `package_index' + 1
    local package : word `package_index' of `ssc_package_command_pairs'
    local command : word `command_index' of `ssc_package_command_pairs'

    capture which `command'

    if _rc & `install_missing_packages' {
        display as text "Installing missing SSC package: `package'"
        capture noisily ssc install `package', replace
    }

    capture which `command'

    if _rc {
        local missing_commands "`missing_commands' `command'"
    }
}

/*
The current official Stata distributions of these packages are maintained in
their authors' repositories rather than SSC.
*/

local net_specs ///
    rdrobust rdrobust     https://raw.githubusercontent.com/rdpackages/rdrobust/main/stata ///
    rdmulti   rdmc        https://raw.githubusercontent.com/rdpackages/rdmulti/main/stata ///
    rdlocrand rdwinselect https://raw.githubusercontent.com/rdpackages/rdlocrand/main/stata ///
    binsreg   binsreg     https://raw.githubusercontent.com/nppackages/binsreg/main/stata

local triple_count : word count `net_specs'
assert mod(`triple_count', 3) == 0

forvalues package_index = 1(3)`triple_count' {
    local command_index = `package_index' + 1
    local source_index  = `package_index' + 2
    local package : word `package_index' of `net_specs'
    local command : word `command_index' of `net_specs'
    local source  : word `source_index' of `net_specs'

    capture which `command'

    if _rc & `install_missing_packages' {
        display as text "Installing missing official-source package: `package'"
        capture noisily net install `package', from("`source'") replace
    }

    capture which `command'

    if _rc {
        local missing_commands "`missing_commands' `command'"
    }
}

/*
palettes uses colrspace. Install the dependency explicitly because Stata's
package installers do not resolve user-written dependencies automatically.
*/

capture which colorpalette

if _rc & `install_missing_packages' {
    display as text "Installing color-palette dependencies."
    capture noisily ssc install colrspace, replace
    capture noisily ssc install palettes, replace
}

capture which colorpalette

if _rc {
    local missing_commands "`missing_commands' colorpalette"
}

/*
plotplainblind provides a clean colorblind-safe default. Graph-producing
modules must still specify polished titles, subtitles, labels, confidence
intervals, legends, and complete notes.
*/

capture set scheme plotplainblind

if _rc & `install_missing_packages' {
    display as text "Installing Stata Journal graph schemes (gr0070)."
    capture noisily net install gr0070, ///
        from("https://www.stata-journal.com/software/sj17-3") replace
    capture set scheme plotplainblind
}

if _rc {
    capture set scheme stcolor

    if _rc {
        set scheme s2color
        global graph_scheme "s2color"
    }
    else {
        global graph_scheme "stcolor"
    }

    display as text "plotplainblind unavailable; using built-in scheme ${graph_scheme}."
}
else {
    global graph_scheme "plotplainblind"
}

if `"`missing_commands'"' != "" {
    display as error "Required user-written commands remain unavailable:"
    display as error "`missing_commands'"
    display as error "Review network access and the package list before running pipeline modules."
    log close victimasrd_master
    exit 499
}

/*
Confirm that the project-local rdrobust ado and Mata files are mutually
compatible in a cold session. A command-level check alone cannot detect a
partially updated package.
*/

clear
set obs 400
generate double smoke_x = (_n - 200.5) / 200
generate int smoke_cluster = ceil(_n / 2)
generate double smoke_y = ///
    0.4 * (smoke_x >= 0) + ///
    0.2 * smoke_x + ///
    mod(_n, 7) / 50

capture quietly rdrobust ///
    smoke_y ///
    smoke_x, ///
    p(1) q(2) ///
    h(0.4) b(0.6) ///
    kernel(triangular) ///
    vce(cluster smoke_cluster) ///
    masspoints(off)
local rdrobust_smoke_rc = _rc
clear

if `rdrobust_smoke_rc' {
    display as error "Project-local rdrobust failed its cold-session smoke test."
    display as error "Reinstall from the official rdpackages source and rerun."
    display as error "Stata return code: `rdrobust_smoke_rc'"
    log close victimasrd_master
    exit `rdrobust_smoke_rc'
}

display as result "Project paths and user-written dependencies verified."
display as text   "Default graph scheme: ${graph_scheme}"


*-----------------------------------*
**# 4. Pipeline switches
*-----------------------------------*

/*
The implemented data-preparation and national/main-sample descriptive modules are
enabled for push-button reproduction. The main RD geography is now constructed
in data preparation. The exhaustive RD-design search remains available as a
standalone audit but is intentionally excluded from the master because its
96,524-cell grid is computationally intensive. Outcome modules remain disabled
until their treatment timing, tie rule, and estimands are approved.
*/

local run_all                         0
local run_01_data_preparation         1
local run_02_describe_data            1
local run_04_estimate_main_effects    0
local run_05_run_robustness           0
local run_06_analyze_mechanisms       0
local run_07_build_outputs            0
local run_08_run_release_checks       0

local pipeline_switches ///
    run_all ///
    run_01_data_preparation ///
    run_02_describe_data ///
    run_04_estimate_main_effects ///
    run_05_run_robustness ///
    run_06_analyze_mechanisms ///
    run_07_build_outputs ///
    run_08_run_release_checks

foreach pipeline_switch of local pipeline_switches {
    assert inlist(``pipeline_switch'', 0, 1)
}


*-----------------------------------*
**# 5. Ordered pipeline execution
*-----------------------------------*

capture program drop victimasrd_run_step

program define victimasrd_run_step
    version 19
    syntax, File(string) Label(string)

    capture confirm file "`file'"

    if _rc {
        display as error "Selected pipeline module was not found:"
        display as error "  `file'"
        exit 601
    }

    display as text ""
    display as result "Starting pipeline step: `label'"
    display as text   "Program: `file'"

    capture noisily do "`file'"
    local step_error = _rc

    if `step_error' {
        display as error "Pipeline step failed: `label'"
        display as error "Stata return code: `step_error'"
        exit `step_error'
    }

    display as result "Completed pipeline step: `label'"
end

if `run_all' | `run_01_data_preparation' {
    victimasrd_run_step, ///
        file("${pipeline_root}/01_data_preparation.do") ///
        label("Authoritative end-to-end data preparation")
}

if `run_all' | `run_02_describe_data' {
    victimasrd_run_step, ///
        file("${pipeline_root}/02_describe_data.do") ///
        label("Descriptive analysis")
}

/*
The exhaustive search is preserved but deliberately bracketed out of every
push-button master run, including run_all. Regenerate it only as an explicit
standalone Stata MCP task after reviewing docs/RD_DESIGN_AUDIT_PROTOCOL.md.

if `run_03_validate_rd_design' {
    victimasrd_run_step, ///
        file("${pipeline_root}/03_validate_rd_design.do") ///
        label("RD design and validity diagnostics")
}
*/

if `run_all' | `run_04_estimate_main_effects' {
    victimasrd_run_step, ///
        file("${pipeline_root}/04_estimate_main_effects.do") ///
        label("Primary treatment-effect estimation")
}

if `run_all' | `run_05_run_robustness' {
    victimasrd_run_step, ///
        file("${pipeline_root}/05_run_robustness.do") ///
        label("Robustness, placebo, and sensitivity analyses")
}

if `run_all' | `run_06_analyze_mechanisms' {
    victimasrd_run_step, ///
        file("${pipeline_root}/06_analyze_migration_mechanisms.do") ///
        label("Migration and exploratory mechanism analyses")
}

if `run_all' | `run_07_build_outputs' {
    victimasrd_run_step, ///
        file("${pipeline_root}/07_build_tables_figures.do") ///
        label("Reviewed tables, figures, and output manifest")
}

if `run_all' | `run_08_run_release_checks' {
    victimasrd_run_step, ///
        file("${pipeline_root}/08_run_release_checks.do") ///
        label("Disclosure and release checks")
}


*-----------------------------------*
**# 6. Session closeout
*-----------------------------------*

if !`run_all' & ///
   !`run_01_data_preparation' & ///
   !`run_02_describe_data' & ///
   !`run_04_estimate_main_effects' & ///
   !`run_05_run_robustness' & ///
   !`run_06_analyze_mechanisms' & ///
   !`run_07_build_outputs' & ///
   !`run_08_run_release_checks' {

    display as text "All pipeline switches are 0; no downstream do-files were run."
}

display as result "Victimas RD master completed successfully."
display as text   "Completed: `c(current_date)' `c(current_time)'"

capture program drop victimasrd_run_step
log close victimasrd_master
