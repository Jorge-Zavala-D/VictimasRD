/*
Project: Victimas RD
Purpose: Validate the pointer-only publication candidate inventory
*/

version 19
set more off

foreach required_global in project_root tables_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global not defined: `required_global'"
        exit 198
    }
}

local inventory ///
    "${tables_root}/publication/publication_candidate_inventory.csv"
local manifest "${metadata_root}/publication-output-manifest.csv"
local review_registry "${metadata_root}/publication-review-registry.csv"

foreach required_file in "`inventory'" "`manifest'" "`review_registry'" {
    capture confirm file "`required_file'"
    if _rc {
        exit 601
    }
}

import delimited using "`inventory'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 255
assert inlist(source_pipeline, ///
    "main_effects", "heterogeneity", "mechanisms")
assert generation_status == "generated_unreviewed"
assert scientific_review_status == "preliminary_reviewed"
assert inlist(disposition, ///
    "main_text", "appendix", "internal_only", "exclude")
assert inlist(evidence_class, ///
    "primary_causal", "secondary_causal", "assignment_effect", ///
    "descriptive_only", "diagnostic", "source_table", ///
    "not_for_interpretation")
assert !missing(review_note)
assert owner_approved == 0
assert missing(overleaf_destination)
assert checksum_verified == 1
assert strpos(path, "..") == 0
assert strpos(lower(path), ".dta") == 0
assert strpos(lower(path), ".smcl") == 0
assert strpos(lower(path), ".log") == 0
assert strpos(lower(path), "dropbox") == 0

quietly count if inlist(disposition, "main_text", "appendix")
assert r(N) > 0
quietly count if source_pipeline == "mechanisms" & ///
    evidence_class == "primary_causal"
assert r(N) == 0

import delimited using "`review_registry'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 255
assert scientific_review_status == "preliminary_reviewed"
assert owner_approved == 0

import delimited using "`manifest'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 2
assert review_status == "generated_unreviewed"

forvalues row = 1/`=_N' {
    local relative_path = path[`row']
    local artifact "${project_root}/`relative_path'"
    capture confirm file "`artifact'"
    if _rc {
        exit 601
    }
    quietly checksum "`artifact'"
    assert r(checksum) == checksum[`row']
}

display as result ///
    "PASS: publication candidate inventory satisfies contract."
