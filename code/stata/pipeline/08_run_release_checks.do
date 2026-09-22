/*
Project: Victimas RD
Purpose: Audit publication candidates without treating review blockers as errors
Inputs:  Module-07 candidate inventory and module-06 estimand outputs
Outputs: Release audit, compact LaTeX summary, and module manifest
*/

version 19
set more off

foreach required_global in project_root tables_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required master global not defined: `required_global'"
        exit 198
    }
}

local inventory ///
    "${tables_root}/publication/publication_candidate_inventory.csv"
local mechanism_summary ///
    "${tables_root}/rd_mechanisms/rd_migration_mechanism_summary.csv"
local mechanism_associations ///
    "${tables_root}/rd_mechanisms/rd_migration_mechanism_associations.csv"
local table_dir "${tables_root}/release"
local manifest "${metadata_root}/release-audit-manifest.csv"
capture mkdir "`table_dir'"

foreach required_input in ///
    "`inventory'" "`mechanism_summary'" ///
    "`mechanism_associations'" {
    capture confirm file "`required_input'"
    if _rc {
        display as error "Required release-audit input not found:"
        display as error "  `required_input'"
        exit 601
    }
}

* Explicitly prohibit causal-mediation estimands in module-06 products.
foreach estimand_file in ///
    "`mechanism_summary'" "`mechanism_associations'" {
    import delimited using "`estimand_file'", clear varnames(1) ///
        bindquote(strict) encoding(utf8)
    capture confirm variable estimand_label
    if _rc {
        generate str1 estimand_label = ""
    }
    generate strL estimand_scan = lower(estimand + " " + estimand_label)
    assert !regexm(estimand_scan, ///
        "(^|[^a-z])(acme|ade|nie|nde)([^a-z]|$)")
    assert strpos(estimand_scan, "natural_indirect_effect") == 0
    assert strpos(estimand_scan, "natural indirect effect") == 0
    assert strpos(estimand_scan, "proportion_mediated") == 0
    assert strpos(estimand_scan, "proportion mediated") == 0
    assert strpos(estimand_scan, "product_of_coefficients") == 0
    assert strpos(estimand_scan, "product of coefficients") == 0
}

import delimited using "`inventory'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 255

generate byte file_exists = 0
generate byte checksum_match = 0
generate byte safe_path = ///
    strpos(path, "..") == 0 & ///
    !regexm(path, "^[A-Za-z]:") & ///
    substr(path, 1, 1) != "/" & ///
    substr(path, 1, 1) != "\" & ///
    strpos(lower(path), "dropbox") == 0 & ///
    strpos(lower(path), "row_level") == 0 & ///
    missing(overleaf_destination) & ///
    (strpos(path, "output/tables/") == 1 | ///
        strpos(path, "output/figures/") == 1)

generate str8 extension = lower(substr(path, -4, 4))
generate byte safe_extension = ///
    inlist(extension, ".csv", ".tex", ".png", ".pdf")
generate byte generator_present = !missing(generator)
generate byte input_signature_present = !missing(input_datasignature)

forvalues row = 1/`=_N' {
    local candidate_path = path[`row']
    local candidate_absolute "${project_root}/`candidate_path'"
    capture confirm file "`candidate_absolute'"
    if !_rc {
        replace file_exists = 1 in `row'
        quietly checksum "`candidate_absolute'"
        replace checksum_match = ///
            r(checksum) == checksum[`row'] in `row'
    }
}

generate byte technical_error = ///
    !file_exists | !checksum_match | !safe_path | !safe_extension | ///
    !generator_present | !input_signature_present

quietly count if technical_error
if r(N) > 0 {
    display as error ///
        "Release audit found `r(N)' technical artifact failures."
    exit 459
}

generate byte reviewed = ///
    publication_status == "reviewed" & ///
    review_status != "generated_unreviewed"
generate byte release_eligible = ///
    file_exists & checksum_match & safe_path & safe_extension & ///
    generator_present & input_signature_present & reviewed

generate str40 block_reason = ""
replace block_reason = "awaiting artifact review" if !reviewed
generate str8 overall_status = "PASS"
replace overall_status = "BLOCKED" if release_eligible == 0

drop extension
sort source_pipeline artifact_type path
order path source_pipeline artifact_type file_exists checksum_match ///
    safe_path safe_extension generator_present input_signature_present ///
    reviewed release_eligible technical_error block_reason overall_status

tempfile release_audit
save `release_audit'
export delimited using "`table_dir'/release_audit.csv", ///
    replace nolabel

quietly count
local total_candidates = r(N)
quietly count if technical_error == 0
local technically_valid = r(N)
quietly count if reviewed == 1
local reviewed_candidates = r(N)
quietly count if release_eligible == 1
local eligible_candidates = r(N)
quietly count if block_reason != ""
local blocked_candidates = r(N)

tempname release_table
file open `release_table' using ///
    "`table_dir'/tab_release_audit.tex", write replace text
file write `release_table' "\begin{table}[!htbp]" _n
file write `release_table' "\centering\small" _n
file write `release_table' ///
    "\caption{Publication release audit}" _n
file write `release_table' "\label{tab:release_audit}" _n
file write `release_table' "\begin{tabular}{lr}" _n
file write `release_table' "\toprule" _n
file write `release_table' "Audit item & Count \\" _n
file write `release_table' "\midrule" _n
file write `release_table' ///
    "Publication candidates & `total_candidates' \\" _n
file write `release_table' ///
    "Technically valid files & `technically_valid' \\" _n
file write `release_table' ///
    "Reviewed files & `reviewed_candidates' \\" _n
file write `release_table' ///
    "Release-eligible files & `eligible_candidates' \\" _n
file write `release_table' ///
    "Files with review blockers & `blocked_candidates' \\" _n
file write `release_table' "\midrule" _n
file write `release_table' "Overall status & BLOCKED \\" _n
file write `release_table' "\bottomrule\end{tabular}" _n
file write `release_table' ///
    "\parbox{0.97\linewidth}{\footnotesize \textit{Notes:} BLOCKED is the expected analytical status because every technically valid artifact remains generated\_unreviewed. It prevents publication release or Overleaf synchronization but is not a software error. Missing files, unsafe paths or extensions, absent provenance, and checksum mismatches are hard failures. Source: versioned module-07 candidate inventory.}" _n
file write `release_table' "\end{table}" _n
file close `release_table'

quietly checksum "`inventory'"
local inventory_checksum : display %20.0f r(checksum)
local inventory_checksum = strtrim("`inventory_checksum'")
local run_id = subinstr("`c(current_date)'_`c(current_time)'", " ", "", .)
local run_id = subinstr("`run_id'", ":", "", .)
local output_paths ///
    output/tables/release/release_audit.csv ///
    output/tables/release/tab_release_audit.tex

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
        `""`output_path'","table","publication_candidate_inventory.csv","`inventory_checksum'","code/stata/pipeline/08_run_release_checks.do","`run_id'","`output_checksum'","generated_unreviewed""' _n
}
file close `manifest_file'

import delimited using "`manifest'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 2
assert review_status == "generated_unreviewed"

display as result "Completed release audit: BLOCKED pending review."
display as text "Audit:    `table_dir'/release_audit.csv"
display as text "Manifest: `manifest'"
