/*
Project: Victimas RD
Purpose: Merge verified artifacts with the publication-review registry
Inputs: Module 04--06 manifests and versioned review decisions
Outputs: Reviewed candidate inventory, summary table, module manifest
*/

version 19
set more off

foreach required_global in project_root tables_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global not defined: `required_global'"
        exit 198
    }
}

local table_dir "${tables_root}/publication"
local manifest "${metadata_root}/publication-output-manifest.csv"
local review_registry "${metadata_root}/publication-review-registry.csv"
capture mkdir "`table_dir'"

local source_manifests ///
    "rd-outcome-output-manifest.csv rd-heterogeneity-output-manifest-2013-2017.csv rd-mechanism-output-manifest.csv"
local source_pipelines "main_effects heterogeneity mechanisms"
local expected_counts "117 126 12"

capture confirm file "`review_registry'"
if _rc {
    display as error "Publication-review registry not found:"
    display as error "  `review_registry'"
    exit 601
}

tempfile candidate_inventory review_decisions
local first_source 1
local source_signatures ""

forvalues source_index = 1/3 {
    local source_manifest : word `source_index' of `source_manifests'
    local source_pipeline : word `source_index' of `source_pipelines'
    local expected_count : word `source_index' of `expected_counts'
    local manifest_absolute "${metadata_root}/`source_manifest'"

    capture confirm file "`manifest_absolute'"
    if _rc {
        display as error "Required source manifest not found:"
        display as error "  `manifest_absolute'"
        exit 601
    }

    quietly checksum "`manifest_absolute'"
    local manifest_checksum : display %20.0f r(checksum)
    local manifest_checksum = strtrim("`manifest_checksum'")
    local source_signatures ///
        "`source_signatures'`source_pipeline':`manifest_checksum';"

    import delimited "`manifest_absolute'", clear varnames(1) ///
        bindquote(strict) encoding(utf8)
    assert _N == `expected_count'
    isid path
    assert review_status == "generated_unreviewed"
    rename review_status generation_status
    generate str24 source_pipeline = "`source_pipeline'"

    if `first_source' {
        save `candidate_inventory'
        local first_source 0
    }
    else {
        append using `candidate_inventory'
        save `candidate_inventory', replace
    }
}

quietly checksum "`review_registry'"
local registry_checksum : display %20.0f r(checksum)
local registry_checksum = strtrim("`registry_checksum'")
local source_signatures ///
    "`source_signatures'review_registry:`registry_checksum';"

import delimited "`review_registry'", clear varnames(1) ///
    bindquote(strict) encoding(utf8) stringcols(_all)
isid path
assert _N == 255
destring owner_approved, replace
assert inlist(disposition, ///
    "main_text", "appendix", "internal_only", "exclude")
assert inlist(evidence_class, ///
    "primary_causal", "secondary_causal", "assignment_effect", ///
    "descriptive_only", "diagnostic", "source_table", ///
    "not_for_interpretation")
assert scientific_review_status == "preliminary_reviewed"
assert inlist(owner_approved, 0, 1)
assert !missing(review_note)
assert missing(overleaf_destination) if owner_approved == 0
save `review_decisions'

use `candidate_inventory', clear
isid path
assert _N == 255
merge 1:1 path using `review_decisions', assert(match) nogen

generate byte safe_path = ///
    strpos(path, "..") == 0 & ///
    !regexm(path, "^[A-Za-z]:") & ///
    substr(path, 1, 1) != "/" & ///
    substr(path, 1, 1) != "\" & ///
    strpos(lower(path), "dropbox") == 0 & ///
    (strpos(path, "output/tables/") == 1 | ///
     strpos(path, "output/figures/") == 1)
assert safe_path == 1

generate str8 extension = lower(substr(path, -4, 4))
generate byte safe_extension = ///
    inlist(extension, ".csv", ".tex", ".png")
assert safe_extension == 1

generate byte checksum_verified = 0
forvalues row = 1/`=_N' {
    local candidate_path = path[`row']
    local candidate_absolute "${project_root}/`candidate_path'"
    capture confirm file "`candidate_absolute'"
    if _rc {
        display as error "Candidate artifact not found:"
        display as error "  `candidate_absolute'"
        exit 601
    }
    quietly checksum "`candidate_absolute'"
    assert r(checksum) == checksum[`row']
    replace checksum_verified = 1 in `row'
}
assert checksum_verified == 1

generate str24 publication_status = "preliminary_reviewed"
replace publication_status = "owner_approved" if owner_approved == 1
drop safe_path safe_extension extension
sort source_pipeline artifact_type path
order source_pipeline path artifact_type disposition evidence_class ///
    scientific_review_status owner_approved publication_status ///
    overleaf_destination review_note generation_status checksum_verified

export delimited ///
    "`table_dir'/publication_candidate_inventory.csv", ///
    replace nolabel

preserve
generate byte artifact_count = 1
collapse (sum) artifact_count, by(source_pipeline disposition)
sort source_pipeline disposition

tempname inventory_table
file open `inventory_table' using ///
    "`table_dir'/tab_publication_candidate_inventory.tex", ///
    write replace text
file write `inventory_table' "\begin{table}[!htbp]" _n
file write `inventory_table' "\centering\small" _n
file write `inventory_table' ///
    "\caption{Preliminary publication-review registry}" _n
file write `inventory_table' ///
    "\label{tab:publication_candidate_inventory}" _n
file write `inventory_table' "\begin{tabular}{llr}" _n
file write `inventory_table' "\toprule" _n
file write `inventory_table' ///
    "Source pipeline & Proposed disposition & Count \\" _n
file write `inventory_table' "\midrule" _n
forvalues row = 1/`=_N' {
    local row_pipeline = ///
        proper(subinstr(source_pipeline[`row'], "_", " ", .))
    local row_disposition = ///
        proper(subinstr(disposition[`row'], "_", " ", .))
    local row_count : display %4.0f artifact_count[`row']
    local row_count = strtrim("`row_count'")
    file write `inventory_table' ///
        "`row_pipeline' & `row_disposition' & `row_count' \\" _n
}
file write `inventory_table' "\midrule" _n
file write `inventory_table' "All pipelines & All artifacts & 255 \\" _n
file write `inventory_table' "\bottomrule\end{tabular}" _n
file write `inventory_table' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} Proposed dispositions reflect a preliminary scientific audit of module 04--06 outputs. Main-text and appendix selections remain blocked from release until owner approval and a safe Overleaf destination are recorded. Internal-only and excluded artifacts remain reproducible repository outputs but are not publication exhibits.}" _n
file write `inventory_table' "\end{table}" _n
file close `inventory_table'
restore

local run_id = subinstr("`c(current_date)'_`c(current_time)'", " ", "", .)
local run_id = subinstr("`run_id'", ":", "", .)
local output_paths ///
    output/tables/publication/publication_candidate_inventory.csv ///
    output/tables/publication/tab_publication_candidate_inventory.tex

tempname manifest_file
file open `manifest_file' using "`manifest'", write replace text
file write `manifest_file' ///
    "path,artifact_type,input_data,input_datasignature,generator,run_id,checksum,review_status" _n

foreach output_path of local output_paths {
    local absolute_output "${project_root}/`output_path'"
    capture confirm file "`absolute_output'"
    if _rc {
        file close `manifest_file'
        exit 603
    }
    quietly checksum "`absolute_output'"
    local output_checksum : display %20.0f r(checksum)
    local output_checksum = strtrim("`output_checksum'")
    file write `manifest_file' ///
        `""`output_path'","table","module 04-06 manifests and publication review registry","`source_signatures'","code/stata/pipeline/07_build_tables_figures.do","`run_id'","`output_checksum'","generated_unreviewed""' _n
}
file close `manifest_file'

import delimited "`manifest'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 2
assert review_status == "generated_unreviewed"

display as result "Completed publication-review candidate inventory."
display as text "Inventory: `table_dir'/publication_candidate_inventory.csv"
display as text "Manifest: `manifest'"
