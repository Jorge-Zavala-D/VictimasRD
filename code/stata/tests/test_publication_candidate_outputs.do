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

foreach required_file in "`inventory'" "`manifest'" {
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
assert publication_status == "candidate_unreviewed"
assert missing(overleaf_destination)
assert checksum_verified == 1
assert strpos(path, "..") == 0
assert strpos(lower(path), ".dta") == 0
assert strpos(lower(path), ".smcl") == 0
assert strpos(lower(path), ".log") == 0
assert strpos(lower(path), "dropbox") == 0

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
