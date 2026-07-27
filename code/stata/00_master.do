/*------------------------------------------------------------------------------*
| Title:            Master code                                                 |
| Project:          Victimas RD                                                 |
| Authors:          Jorge Zavala, Matthew Bird, Ana María Dumez                 |
|                                                                               |
| Description:      Configure the project environment, validate paths and       |
|                   dependencies, and optionally run the ordered pipeline.      |
|                                                                               |
| Date created:     27 July 2026                                                |
| Last updated:     27 July 2026                                                |
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

The shared master intentionally contains no usernames or absolute paths.
*/

local paths_file "config/paths.local.do"
capture confirm file "`paths_file'"

if _rc {
    local paths_file "../../config/paths.local.do"
    capture confirm file "`paths_file'"
}

if _rc {
    display as error "Machine-specific path configuration was not found."
    display as error "Expected config/paths.local.do relative to the repository root."
    display as error "Copy config/paths.example.do, edit the local copy, and rerun the master."
    exit 601
}

quietly do "`paths_file'"

local required_globals ///
    project_root ///
    dropbox_root ///
    overleaf_root ///
    python_exec ///
    data_root ///
    raw_root ///
    working_input_root ///
    coded_input_root ///
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


*-----------------------------------*
**# 2. Project directories and safety checks
*-----------------------------------*

global code_root       "${project_root}/code/stata"
global pipeline_root   "${code_root}/pipeline"
global derived_root    "${build_root}/derived"
global temporary_root  "${build_root}/temporary"
global qa_root         "${build_root}/qa"
global ado_root        "${build_root}/ado"

/*
Dropbox is an input/archive layer. Only the Git-local build and output roots
are writable destinations for this pipeline.
*/

local project_lower = lower(subinstr("${project_root}", "\", "/", .))
local data_lower    = lower(subinstr("${data_root}", "\", "/", .))
local raw_lower     = lower(subinstr("${raw_root}", "\", "/", .))
local build_lower   = lower(subinstr("${build_root}", "\", "/", .))
local output_lower  = lower(subinstr("${output_root}", "\", "/", .))

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

if strpos("`build_lower'", "`data_lower'/") == 1 | ///
   strpos("`build_lower'", "`raw_lower'/")  == 1 {
    display as error "Unsafe build_root: derived work may not be written under Dropbox data."
    exit 198
}

local required_read_globals ///
    project_root ///
    code_root ///
    pipeline_root ///
    dropbox_root ///
    data_root ///
    raw_root ///
    working_input_root ///
    coded_input_root

foreach global_name of local required_read_globals {
    local required_dir "${`global_name'}"

    if !direxists("`required_dir'") {
        display as error "Required project/input directory not found:"
        display as error "  `required_dir'"
        exit 601
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
Create only Git-ignored, repository-local build directories. Never create,
replace, rename, or delete a Dropbox input directory from this master.
*/

capture mkdir "${build_root}"
capture mkdir "${derived_root}"
capture mkdir "${temporary_root}"
capture mkdir "${qa_root}"
capture mkdir "${ado_root}"

local build_globals ///
    build_root ///
    derived_root ///
    temporary_root ///
    qa_root ///
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
display as text "Repository root: ${project_root}"
display as text "Dropbox inputs: ${data_root} (read-only)"
display as text "Local build:    ${build_root}"
display as text "Git outputs:    ${output_root}"


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
    rdrobust    rdrobust ///
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

display as result "Project paths and user-written dependencies verified."
display as text   "Default graph scheme: ${graph_scheme}"


*-----------------------------------*
**# 4. Pipeline switches
*-----------------------------------*

/*
All switches remain zero while their modules are being designed and audited.
Set run_all to one only after every selected module and its required research
decisions have been reviewed.
*/

local run_all                         0
local run_01_data_preparation         0
local run_02_describe_data            0
local run_03_validate_rd_design       0
local run_04_estimate_main_effects    0
local run_05_run_robustness           0
local run_06_analyze_mechanisms       0
local run_07_build_outputs            0
local run_08_run_release_checks       0

local pipeline_switches ///
    run_all ///
    run_01_data_preparation ///
    run_02_describe_data ///
    run_03_validate_rd_design ///
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
    syntax, File(string asis) Label(string asis)

    capture confirm file `"`file'"'

    if _rc {
        display as error "Selected pipeline module was not found:"
        display as error `"  `file'"'
        exit 601
    }

    display as text ""
    display as result "Starting pipeline step: `label'"
    display as text   `"Program: `file'"'

    capture noisily do `"`file'"'
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

if `run_all' | `run_03_validate_rd_design' {
    victimasrd_run_step, ///
        file("${pipeline_root}/03_validate_rd_design.do") ///
        label("RD design and validity diagnostics")
}

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
   !`run_03_validate_rd_design' & ///
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
