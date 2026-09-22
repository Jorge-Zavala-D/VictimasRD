/*
Project: Victimas RD
Purpose: Validate the release audit and its expected review blocker
*/

version 19
set more off

foreach required_global in project_root tables_root metadata_root {
    if `"${`required_global'}"' == "" {
        display as error "Required global not defined: `required_global'"
        exit 198
    }
}

local audit "${tables_root}/release/release_audit.csv"
local manifest "${metadata_root}/release-audit-manifest.csv"

foreach required_file in "`audit'" "`manifest'" {
    capture confirm file "`required_file'"
    if _rc {
        exit 601
    }
}

import delimited using "`audit'", clear varnames(1) ///
    bindquote(strict) encoding(utf8)
isid path
assert _N == 255
assert overall_status == "BLOCKED"
assert file_exists == 1
assert checksum_match == 1
assert safe_path == 1
assert safe_extension == 1
assert technical_error == 0
assert review_resolved == 1
assert owner_approved == 0
quietly count if selected_for_release == 1
assert r(N) > 0
quietly count if release_eligible == 1
assert r(N) == 0
quietly count if selected_for_release == 0 & !missing(block_reason)
assert r(N) == 0
quietly count if selected_for_release == 1 & missing(block_reason)
assert r(N) == 0

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

display as result "PASS: release audit correctly reports BLOCKED."
