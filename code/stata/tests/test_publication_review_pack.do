/*
Project: Victimas RD
Purpose: Catch lost exhibits, altered source cells, or accidental release promotion
*/

version 19
set more off

local registry "${tables_root}/publication/publication_review_exhibits.csv"
local cells "${tables_root}/publication/publication_review_cells.csv"
confirm file "`registry'"
confirm file "`cells'"

import delimited "`registry'", clear varnames(1) bindquote(strict) encoding(utf8) asdouble
isid exhibit_id
isid path
assert _N == 35
assert owner_approved == 0 & release_eligible == 0
assert release_action == "hold_no_sync"
assert review_status == "generated_unreviewed"
assert !missing(source_path, source_checksum, checksum, caption)
assert strpos(path, "..") == 0 & strpos(source_path, "..") == 0
assert strpos(path, "output/") == 1
quietly count if proposed_role == "main_text"
assert r(N) == 6
quietly count if proposed_role == "appendix"
assert r(N) == 29
quietly count if substr(path, -4, 4) == ".png"
local figure_count = r(N)
if `figure_count' != 5 {
    display as error "Expected five review figures; found `figure_count'."
    exit 459
}
forvalues row = 1/`=_N' {
    local artifact = path[`row']
    quietly checksum "${project_root}/`artifact'"
    assert r(checksum) == checksum[`row']
    local source = source_path[`row']
    quietly checksum "${project_root}/`source'"
    assert r(checksum) == source_checksum[`row']
}

import delimited "`cells'", clear varnames(1) bindquote(strict) ///
    encoding(utf8) stringcols(_all)
isid exhibit_id row_order
keep if strpos(source_path, "tab_rd_outcomes_28_main_2017_individual.tex")
assert _N == 10
quietly count if cell1 == "Lives in another CCPP"
assert r(N) == 1
assert cell4 == "21.45" & cell5 == "[-17.24, 60.14]" ///
    & cell7 == "7,680" & cell8 == "63" if cell1 == "Lives in another CCPP"

local manifest "${metadata_root}/publication-output-manifest.csv"
import delimited "`manifest'", clear varnames(1) bindquote(strict) encoding(utf8) asdouble
isid path
assert _N == 41
assert review_status == "generated_unreviewed"
forvalues row = 1/`=_N' {
    local artifact = path[`row']
    quietly checksum "${project_root}/`artifact'"
    assert r(checksum) == checksum[`row']
}

display as result "PASS: 35 review exhibits retain source cells and release holds."
