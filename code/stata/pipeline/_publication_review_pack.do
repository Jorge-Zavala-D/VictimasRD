/*
Project: Victimas RD
Purpose: Build portrait-page review derivatives without re-estimating outcomes
Inputs: Verified aggregate outputs and the dated 6-main/22-appendix proposal
Outputs: Review exhibits, source-cell ledger, numerical macros, TeX input list
*/

version 19
set more off
local table_dir "${tables_root}/publication"
local figure_dir "${figures_root}/publication"
* ponytail: eight-column registered formats only; add a tested kind for a new schema.
capture mkdir "`figure_dir'"

* A single formatter retains every source row; only the presentation changes.
capture program drop _vrd_review_table
program define _vrd_review_table, rclass
    syntax using/, OUTput(string) EXhibit(string) KIND(string) ///
        CAPtion(string) CELLHandle(name)
    local columns 6
    local layout "p{0.28\linewidth}rrp{0.24\linewidth}rr"
    local header "Outcome & Mean & RF & Fuzzy estimate / 95\% CI & Holm \(p\) & Local \(N\)"
    if "`kind'" == "micro_main" {
        local header "Outcome & Mean & RF & Fuzzy estimate / 95\% CI & Holm \(p\) & \(N\) / CCPP"
    }
    if "`kind'" == "first_stage" {
        local layout "p{0.34\linewidth}p{0.24\linewidth}rrrr"
        local header "Analysis frame & Estimate / 95\% CI & SE & \(N\) & \(h\) & \(F_z\)"
    }
    if "`kind'" == "micro_first_stage" {
        local columns 5
        local layout "p{0.31\linewidth}p{0.14\linewidth}p{0.24\linewidth}rr"
        local header "Analysis frame & Weight & Estimate / 95\% CI (SE) & \(N\) / CCPP & \(F_z\)"
    }
    if "`kind'" == "diagnostics" {
        local columns 6
        local layout "p{0.27\linewidth}p{0.16\linewidth}rrp{0.10\linewidth}p{0.15\linewidth}"
        local header "Moderator & Left / right / min. & Min. SW \(F\) & KP \(F\) & Support & IV gate"
    }
    if "`kind'" == "diagnostics_pair" {
        local columns 5
        local layout "p{0.28\linewidth}p{0.16\linewidth}p{0.15\linewidth}rp{0.24\linewidth}"
        local header "Moderator & Left / right / min. & SW \(F_D\) / \(F_{D M}\) & KP \(F\) & IV gate"
    }
    if inlist("`kind'", "projects", "projects_point") {
        local columns 4
        local layout "p{0.38\linewidth}rp{0.16\linewidth}p{0.26\linewidth}"
        local header "Project group & Records / CCPP & Share (\%) & Assignment jump (SE), pp"
    }
    if "`kind'" == "linkage" {
        local columns 4
        local layout "p{0.40\linewidth}rp{0.28\linewidth}r"
        local header "Availability measure & Mean (\%) & Jump / 95\% CI, pp & \(N\) / CCPP"
    }
    if "`kind'" == "cohort" {
        local columns 4
        local layout "lp{0.42\linewidth}p{0.29\linewidth}r"
        local header "Unit & Coverage / linkage measure & Jump / 95\% CI, pp & Raw \(p\)"
    }
    if "`kind'" == "registry" {
        local columns 4
        local layout "p{0.10\linewidth}p{0.17\linewidth}p{0.25\linewidth}p{0.36\linewidth}"
        local header "Tier & Family & Outcome & Denominator / construction universe"
    }
    if "`kind'" == "flow" {
        local columns 4
        local layout "p{0.53\linewidth}rrr"
        local header "Selection stage & Observed & Parent \(N\) & CCPP-equal rate (\%)"
    }
    if "`kind'" == "overlap" {
        local columns 5
        local layout "p{0.27\linewidth}rp{0.16\linewidth}p{0.22\linewidth}r"
        local header "Selection stage & Parent \(N\) & Complete baseline & Probability range & ESS / empty CCPP"
    }

    // The 2017 source TeX omits uncertainty available in the validated CSV.
    if "`kind'" == "projects_point" {
        import delimited "${tables_root}/rd_heterogeneity/rd_hte_2017_ccpp_project_discontinuities.csv", ///
            clear varnames(1) bindquote(strict) encoding(utf8) asdouble
        keep if strpos(component_id, "group_") == 1
        assert _N == 4 & status == "estimated" & !missing(standard_error)
        sort component_id
        assert component_id == "group_" + string(_n)
        forvalues project = 1/4 {
            local project_label`project' = component_label[`project']
            local project_se`project' = strtrim(string(standard_error[`project'], "%6.2f"))
        }
    }
    tempname input output_file
    file open `input' using "`using'", read text
    file open `output_file' using "`output'", write replace text
    file write `output_file' "\begingroup\fontsize{9.25}{11.4}\selectfont" _n
    file write `output_file' "\setlength{\tabcolsep}{3pt}\renewcommand{\arraystretch}{1.18}" _n
    file write `output_file' "\begin{longtable}{@{}>`=char(123)'\raggedright\arraybackslash}`layout'@{}}" _n
    file write `output_file' "\caption{`caption'}\label{tab:pub_`exhibit'} \\" _n
    file write `output_file' "\toprule `header' \\ \midrule\endfirsthead" _n
    file write `output_file' "\multicolumn{`columns'}{c}{\tablename\ \thetable{} -- continued} \\" _n
    file write `output_file' "\toprule `header' \\ \midrule\endhead" _n
    local active 0
    local long_source 0
    local row_order 0
    local source_note ""
    file read `input' line
    while r(eof) == 0 {
        if strpos(`"`line'"', "\begin{longtable}") local long_source 1
        if strpos(`"`line'"', "\midrule") & !`long_source' local active 1
        if strpos(`"`line'"', "\endhead") local active 1
        if strpos(`"`line'"', "\bottomrule") local active 0
        if strpos(`"`line'"', "\textit{Notes:}") {
            local source_note `"`line'"'
        }
        if `active' & strpos(`"`line'"', " & ") & ///
            !strpos(`"`line'"', "\multicolumn") {
            local remainder = strtrim(subinstr(`"`line'"', "\\", "", .))
            local fields 0
            forvalues field = 1/8 {
                local cell`field' ""
            }
            while `"`remainder'"' != "" {
                local ++fields
                assert `fields' <= 8
                local separator = strpos(`"`remainder'"', "&")
                if `separator' {
                    local cell`fields' = strtrim(substr(`"`remainder'"', 1, `separator' - 1))
                    local remainder = substr(`"`remainder'"', `separator' + 1, .)
                }
                else {
                    local cell`fields' = strtrim(`"`remainder'"')
                    local remainder ""
                }
            }
            local ++row_order
            local relative_source = subinstr("`using'", "${project_root}/", "", .)
            post `cellhandle' ("`exhibit'") ("`relative_source'") (`row_order') ///
                ("`cell1'") ("`cell2'") ("`cell3'") ("`cell4'") ///
                ("`cell5'") ("`cell6'") ("`cell7'") ("`cell8'")
            local rendered `"`cell1' & `cell2' & `cell3' & `cell4'"'
            if inlist("`kind'", "main", "micro_main") {
                local last `"`cell7'"'
                if "`kind'" == "micro_main" local last `"\shortstack[r]{`cell7' / `cell8'}"'
                local rendered `"`cell1' & `cell2' & `cell3' & \shortstack[r]{`cell4' \\ `cell5'} & `cell6' & `last'"'
            }
            if "`kind'" == "first_stage" {
                local rendered `"`cell1' & \shortstack[r]{`cell2' \\ `cell4'} & `cell3' & `cell5' & `cell6' & `cell7'"'
            }
            if "`kind'" == "micro_first_stage" {
                local rendered `"`cell1' & `cell2' & \shortstack[r]{`cell3' \\ `cell5' \\ (`cell4')} & `cell6' / `cell7' & `cell8'"'
            }
            if inlist("`kind'", "diagnostics", "diagnostics_pair") {
                forvalues field = 2/4 {
                    local cell`field' = strtrim(string(real("`cell`field''"), "%9.0fc"))
                }
                local rendered `"`cell1' & `cell2' / `cell3' / `cell4' & `cell5' / `cell6' & `cell7' & `cell8'"'
                if "`kind'" == "diagnostics" local rendered `"`cell1' & `cell2' / `cell3' / `cell4' & `cell5' & `cell6' & `cell7' & `cell8'"'
            }
            if inlist("`kind'", "projects", "projects_point") {
                local rendered `"`cell1' & `cell2' / `cell3' & `cell4' & `cell5' (`cell6')"'
                if `fields' == 5 {
                    assert `"`cell1'"' == `"`project_label`row_order''"'
                    local rendered `"`cell1' & `cell2' / `cell3' & `cell4' & `cell5' (`project_se`row_order'')"'
                }
            }
            if "`kind'" == "linkage" {
                local rendered `"`cell1' & `cell2' & \shortstack[r]{`cell3' \\ `cell4'} & `cell5' / `cell6'"'
            }
            if "`kind'" == "cohort" {
                local rendered `"`cell1' & `cell2' & \shortstack[r]{`cell3' \\ `cell4'} & `cell5'"'
            }
            if "`kind'" == "overlap" {
                local rendered `"`cell1' & `cell2' & `cell3' & `cell4' & `cell5' / `cell6'"'
            }
            // Braces prevent a leading CI bracket being read as row spacing.
            local rendered = subinstr(`"`rendered'"', "\\ ", "\\{} ", .)
            file write `output_file' `"`rendered' \\"' _n
        }
        file read `input' line
    }
    file close `input'
    assert `row_order' > 0
    assert `"`source_note'"' != ""
    local source_note = subinstr(`"`source_note'"', "prespecified", "registered", .)
    file write `output_file' "\bottomrule\end{longtable}" _n
    file write `output_file' `"`source_note'"' _n
    file write `output_file' "\par\smallskip{\footnotesize\textit{Review boundary:} Conditional local evidence; historical design search and selection remain limitations. RF denotes the assignment reduced form; CCPP denotes a community. In outcome tables, shares, binary outcomes and zero-to-one indices are in percentage points; logarithms remain log points and counts remain counts. A common window is not claimed optimal for every outcome. No artifact-level release approval or manuscript synchronization is implied.}\par\endgroup" _n
    file close `output_file'
    return scalar rows = `row_order'
end

tempname exhibit_post cell_post
tempfile exhibits cells proposal
postfile `exhibit_post' str8 exhibit_id str12 proposed_role str244 path ///
    str244 source_path double source_checksum double checksum str160 caption ///
    byte owner_approved release_eligible str16 release_action ///
    str24 review_status using `exhibits', replace
postfile `cell_post' str8 exhibit_id str244 source_path int row_order ///
    str244 cell1 str160 cell2 str244 cell3 str160 cell4 ///
    str160 cell5 str160 cell6 str160 cell7 str160 cell8 using `cells', replace

import delimited "${metadata_root}/publication-exhibit-review-2026-09-30.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if inlist(proposed_role, "main_text", "appendix")
assert _N == 28
sort proposed_role path
save `proposal'
local main_index 0
local appendix_index 0
forvalues item = 1/28 {
    use `proposal', clear
    local source = path[`item']
    local role = proposed_role[`item']
    local year "2013"
    if strpos("`source'", "2017") local year "2017"
    local unit "community"
    if strpos("`source'", "household") local unit "household"
    if strpos("`source'", "individual") local unit "individual"
    if "`role'" == "main_text" {
        local ++main_index
        local exhibit = "M" + string(`main_index', "%02.0f")
    }
    else {
        local ++appendix_index
        local exhibit = "A" + string(`appendix_index', "%02.0f")
    }
    local name = substr("`source'", strlen("`source'") - strpos(reverse("`source'"), "/") + 2, .)
    local output "output/tables/publication/`exhibit'_`name'"
    local caption "`year' `unit' outcomes near the B/C cutoff"
    local kind "main"
    if "`unit'" != "community" local kind "micro_main"
    if strpos("`name'", "first_stage") {
        local kind "first_stage"
        if "`unit'" != "community" local kind "micro_first_stage"
        local caption "`year' `unit' first stages and analysis frames"
    }
    if strpos("`name'", "design_diagnostics") {
        local kind "diagnostics"
        if "`year'" == "2013" & "`unit'" == "community" local kind "diagnostics_pair"
        local caption "`year' `unit' heterogeneity: support and instrument gates"
    }
    if strpos("`name'", "project_implementation") {
        local kind "projects"
        if "`year'" == "2017" local kind "projects_point"
        local caption "Project composition and assignment jumps through `=real("`year'") - 1'"
    }
    if strpos("`name'", "registry") {
        local kind "registry"
        local caption "`year' `unit' outcome definitions and denominators"
    }
    if strpos("`name'", "32_linkage") {
        local kind "linkage"
        local caption "2017 household analysis availability and member linkage"
    }
    if strpos("`name'", "03_linkage_selection") {
        local kind "cohort"
        local caption "2017 community coverage and person-linkage diagnostics"
    }
    if substr("`source'", -4, 4) == ".tex" {
        _vrd_review_table using "${project_root}/`source'", ///
            output("${project_root}/`output'") exhibit("`exhibit'") ///
            kind("`kind'") caption("`caption'") cellhandle(`cell_post')
    }
    else {
        local output "output/figures/publication/`exhibit'_`name'"
        import delimited "${tables_root}/rd_outcomes/rd_`year'_ccpp_results.csv", ///
            clear varnames(1) bindquote(strict) encoding(utf8)
        keep if tier == "primary" & estimand == "fuzzy_late"
        if strpos("`name'", "late_forest") keep if spec_id == "common_h_fuzzy"
        else keep if inlist(spec_id, "fixed_h_005", "common_h_fuzzy", "fixed_h_010")
        assert estimation_rc == 0
        assert !missing(standardized_estimate, standardized_ci_low, standardized_ci_high)
        local plot_rows 8
        assert _N == cond(strpos("`name'", "late_forest"), 8, 24)
        generate double plot_order = 9 - paper_order
        local axis_labels ""
        forvalues order = 1/8 {
            quietly levelsof outcome_label if paper_order == `order', local(label) clean
            local label = subinstr(`"`label'"', "Households with any unmet basic need", "Any unmet basic need", .)
            local label = subinstr(`"`label'"', "Residents in any social program", "Social-program participation", .)
            local label = subinstr(`"`label'"', "Secondary education or higher", "Secondary education or above", .)
            local axis_labels `"`axis_labels' `=9 - `order'' "`label'""'
        }
        local scheme "s2color"
        capture findfile scheme-plotplainblind.scheme
        if !_rc local scheme "plotplainblind"
        local plots "(rcap standardized_ci_low standardized_ci_high plot_order, horizontal lcolor(navy) lwidth(medthin)) (scatter plot_order standardized_estimate, mcolor(navy) msymbol(D) msize(small))"
        local legend "legend(off)"
        local caption "`year' community outcomes: conditional local estimates"
        local subtitle "Registered primary family; robust 95% intervals"
        if strpos("`name'", "bandwidth") {
            replace plot_order = plot_order + 0.18 if spec_id == "fixed_h_005"
            replace plot_order = plot_order - 0.18 if spec_id == "fixed_h_010"
            local plots ""
            local index 0
            foreach spec in fixed_h_005 common_h_fuzzy fixed_h_010 {
                local ++index
                local color : word `index' of teal navy gs7
                local symbol : word `index' of O D T
                local plots `"`plots' (rcap standardized_ci_low standardized_ci_high plot_order if spec_id == "`spec'", horizontal lcolor(`color') lwidth(thin)) (scatter plot_order standardized_estimate if spec_id == "`spec'", mcolor(`color') msymbol(`symbol') msize(small))"'
            }
            local legend `"legend(order(2 "h=0.0050" 4 "h=0.0075" 6 "h=0.0100") rows(1) size(small) position(6))"'
            local caption "`year' community outcomes: bandwidth sensitivity"
            local subtitle "Registered windows; robust 95% intervals"
        }
        twoway `plots', scheme(`scheme') ///
            ylabel(`axis_labels', angle(0) labsize(small) nogrid) ///
            xlabel(, grid glcolor(gs14) labsize(small)) ///
            xline(0, lcolor(gs5) lpattern(dash)) ytitle("") ///
            xtitle("Fuzzy estimate / below-cutoff outcome SD", size(small)) ///
            title("`caption'", size(medsmall)) subtitle("`subtitle'", size(small)) ///
            `legend' xsize(6.6) ysize(5.2) graphregion(color(white)) ///
            note("Selected adjacent B/C communities; treatment through `=real("`year'")-1'." ///
                "Local-linear triangular-kernel RD; bias window b=0.0135 for the common h=0.0075 model." ///
                "Mass-point adjustment; district CR2 inference. SD is the below-cutoff outcome standard deviation." ///
                "All eight outcomes are shown; no primary common-window result survives its Holm family." ///
                "Conditional identification and linkage limits remain. Sources: RUV, CMAN, `=cond("`year'"=="2013", "SISFOH", "INEI-assisted Census")'.", ///
                size(small) span)
        graph export "${project_root}/`output'", width(2400) replace
    }
    quietly checksum "${project_root}/`source'"
    local source_checksum = r(checksum)
    quietly checksum "${project_root}/`output'"
    post `exhibit_post' ("`exhibit'") ("`role'") ("`output'") ///
        ("`source'") (`source_checksum') (r(checksum)) ("`caption'") ///
        (0) (0) ("hold_no_sync") ("generated_unreviewed")
}

* Two selection tables already exist; retain their source cells and notes.
foreach entry in "23 flow 06_selection_flow" "24 overlap 07_selection_feasibility" {
    gettoken number remainder : entry
    gettoken kind basename : remainder
    local basename = strtrim("`basename'")
    local exhibit "A`number'"
    local source "output/tables/rd_mechanisms/tab_rd_mechanisms_`basename'.tex"
    local output "output/tables/publication/`exhibit'_selection_`kind'.tex"
    local caption "2017 selection stages: distinct source denominators"
    if "`kind'" == "overlap" local caption "Selection-model feasibility, not causal adjustment"
    _vrd_review_table using "${project_root}/`source'", ///
        output("${project_root}/`output'") exhibit("`exhibit'") ///
        kind("`kind'") caption("`caption'") cellhandle(`cell_post')
    quietly checksum "${project_root}/`source'"
    local source_checksum = r(checksum)
    quietly checksum "${project_root}/`output'"
    post `exhibit_post' ("`exhibit'") ("appendix") ("`output'") ///
        ("`source'") (`source_checksum') (r(checksum)) ("`caption'") ///
        (0) (0) ("hold_no_sync") ("generated_unreviewed")
}

* Supplemental displays use aggregate CSVs, never observational datasets.
local assignment_signal_total 0
local assignment_adjusted_total 0
foreach number in 25 26 27 28 {
    local exhibit "A`number'"
    local output "output/tables/publication/`exhibit'_supplement.tex"
    local source "output/tables/rd_mechanisms/rd_census2017_selection_intervals.csv"
    local caption "Finite source-frame movement intervals, not causal bounds"
    local layout "p{0.34\linewidth}lp{0.30\linewidth}r"
    local header "Target frame & Contrast & Support interval (\% / pp) & Parent \(N\)"
    local note "Side intervals: percent; differences: percentage points (pp). Intervals use only zero-to-one outcome support and the fixed delivered source frame. They are not confidence intervals, RD effects, fuzzy LATE bounds or bounds for eligible adults. Household intervals concern the fraction of all source members, not the primary observed-member household outcome. No interval is divided by the first stage. Sources: canonical INEI-assisted linkage and the registered selection audit."
    if `number' == 26 {
        local source "metadata/rd-heterogeneity-output-manifest-2013-2017.csv"
        local caption "Heterogeneity reporting gates across all six outcome families"
        local layout "p{0.23\linewidth}rrrrr"
        local header "Wave / level & IV cells & Pass gate & Adj. / signals & Assignment cells & Adj. / signals"
        local note "IV counts use the registered primary common-window fuzzy interaction specification. A reportable IV contrast must pass rank, support and conditional-instrument-strength checks, including conditional F statistics above 10. Assignment contrasts instead require supported local estimation; the fuzzy-IV gate does not apply. Adj. counts eligible contrasts with available multiplicity-adjusted probabilities; signals count those below 0.05. The correction is Holm for primary moderators and BH for secondary moderators, within original registered families, not one new pooled family. A dash means no adjusted contrast is available, not a negative finding. Separate rdhte assignment contrasts do not identify treatment-receipt heterogeneity. Sources: all six module-05 aggregate result files."
    }
    if `number' == 27 {
        local source "output/tables/rd_mechanisms/rd_migration_mechanism_summary.csv"
        local caption "Candidate intermediate outcomes: separate from causal mediation"
        local layout "p{0.13\linewidth}p{0.32\linewidth}p{0.25\linewidth}rr"
        local header "Wave / level & Outcome & Estimate / 95\% CI, pp & Holm \(p\) & KP \(F\)"
        local note "All registered candidate-intermediate-outcome rows are retained. Values and Holm corrections are carried from their registered outcome families; they are not adjusted over this display as one new family. A missing KP statistic means treatment-receipt interpretation is not cleared; the displayed fuzzy ratio is diagnostic only. Models use adjacent B/C support, h=0.0075, b=0.0135, local-linear triangular kernels, robust bias correction and mass-point adjustment. Community models use district CR2 inference; household/person models use CCPP-equal weights and RUV-community CR2 inference. Contemporaneous 2017 employment and internet cannot establish mediator-before-outcome ordering or an indirect effect. Sources: RUV, CMAN, SISFOH and INEI-assisted Census."
    }
    if `number' == 28 {
        local source "output/tables/rd_mechanisms/rd_migration_mechanism_associations.csv"
        local caption "2013 predictors and 2017 migration: noncausal associations"
        local layout "p{0.32\linewidth}lp{0.26\linewidth}rr"
        local header "2013 predictor & Model & Coefficient / 95\% CI & Raw \(p\) & BH \(q\)"
        local note "Coefficients are zero-to-one changes in the 2017 community migration share per local standard deviation of the 2013 predictor. These are neither fuzzy-RD LATEs nor mediation effects. All models are unweighted OLS on 60 communities with inference clustered by 42 districts and side-specific local-linear score terms. Adjusted models additionally control for 2017-source altitude, 2007 log population and 2007 wellbeing. BH corrections concern the adjusted association family; unadjusted rows are descriptive sensitivities. Sources: RUV, CMAN, SISFOH and INEI-assisted Census."
    }
    tempname table
    file open `table' using "${project_root}/`output'", write replace text
    file write `table' "\begingroup\fontsize{9.25}{11.4}\selectfont\setlength{\tabcolsep}{3pt}" _n
        if `number' == 26 file write `table' "\setlength{\tabcolsep}{5pt}" _n
    file write `table' "\renewcommand{\arraystretch}{1.18}\begin{longtable}{@{}>`=char(123)'\raggedright\arraybackslash}`layout'@{}}" _n
    file write `table' "\caption{`caption'}\label{tab:pub_`exhibit'} \\" _n
    file write `table' "\toprule `header' \\ \midrule\endfirsthead" _n
    file write `table' "\toprule `header' \\ \midrule\endhead" _n
    if `number' == 25 {
        import delimited "${project_root}/`source'", clear varnames(1) bindquote(strict) encoding(utf8)
        assert _N == 6 & causal_late_bound == 0 & primary_adult_target == 0
        sort frame side
        forvalues row = 1/`=_N' {
            local frame "All-age source people"
            if frame[`row'] == "source_households" local frame "All-source-member household share"
            local side = proper(subinstr(side[`row'], "_", " ", .))
            if side[`row'] == "above_minus_below" local side "Difference"
            local interval = "[" + strtrim(string(100*lower[`row'], "%6.2f")) + ", " + strtrim(string(100*upper[`row'], "%6.2f")) + "]"
            local parent = strtrim(string(n_parent[`row'], "%9.0fc"))
            if "`side'" == "Difference" local parent "--"
            file write `table' "`frame' & `side' & `interval' & `parent' \\" _n
        }
    }
    if `number' == 26 {
        foreach year in 2013 2017 {
            foreach level in ccpp household individual {
                import delimited "${tables_root}/rd_heterogeneity/rd_hte_`year'_`level'_results.csv", ///
                    clear varnames(1) bindquote(strict) encoding(utf8)
                generate double adjusted_p = cond(moderator_tier == "primary", p_holm, q_bh)
                generate byte assignment_supported = inlist(gate_status, "assignment_hte_supported", "secondary_assignment_supported") & estimation_rc == 0
                quietly count if spec_id == "common_h_iv" & estimand == "fuzzy_late_interaction"
                local iv_tests = r(N)
                quietly count if spec_id == "common_h_iv" & estimand == "fuzzy_late_interaction" & gate_pass == 1
                local iv_pass = r(N)
                quietly count if spec_id == "common_h_iv" & estimand == "fuzzy_late_interaction" & gate_pass == 1 & adjusted_p < .
                local iv_adjusted = r(N)
                quietly count if spec_id == "common_h_iv" & estimand == "fuzzy_late_interaction" & gate_pass == 1 & adjusted_p < 0.05
                local iv_signals = r(N)
                if `iv_adjusted' == 0 local iv_signals "--"
                quietly count if spec_id == "common_h_rdhte" & estimand == "assignment_hte"
                local assignment_tests = r(N)
                quietly count if spec_id == "common_h_rdhte" & estimand == "assignment_hte" & assignment_supported & adjusted_p < .
                local assignment_adjusted = r(N)
                quietly count if spec_id == "common_h_rdhte" & estimand == "assignment_hte" & assignment_supported & adjusted_p < 0.05
                local assignment_signals = r(N)
                local assignment_signal_total = `assignment_signal_total' + `assignment_signals'
                local assignment_adjusted_total = `assignment_adjusted_total' + `assignment_adjusted'
                if `assignment_adjusted' == 0 local assignment_signals "--"
                local label = proper("`level'")
                if "`level'" == "ccpp" local label "CCPP"
                file write `table' "`year' `label' & `iv_tests' & `iv_pass' & `iv_adjusted' / `iv_signals' & `assignment_tests' & `assignment_adjusted' / `assignment_signals' \\" _n
            }
        }
    }
    if `number' == 27 {
        import delimited "${project_root}/`source'", clear varnames(1) bindquote(strict) encoding(utf8)
        keep if evidence_class == "mechanism_outcome_effect"
        assert _N == 37
        sort wave level outcome_id
        forvalues row = 1/`=_N' {
            local label = outcome_label[`row']
            local unit = proper(level[`row'])
            if "`unit'" == "Ccpp" local unit "CCPP"
            local year = wave[`row']
            local effect = strtrim(string(estimate_bc[`row'], "%6.2f"))
            local interval = "[" + strtrim(string(ci_low[`row'], "%6.2f")) + ", " + strtrim(string(ci_high[`row'], "%6.2f")) + "]"
            local holm = strtrim(string(p_holm[`row'], "%5.3f"))
            local strength = strtrim(string(kp_f[`row'], "%6.2f"))
            if missing(kp_f[`row']) local strength "--"
            file write `table' "`year' `unit' & `label' & \shortstack[r]{`effect' \\{} `interval'} & `holm' & `strength' \\" _n
        }
    }
    if `number' == 28 {
        import delimited "${project_root}/`source'", clear varnames(1) bindquote(strict) encoding(utf8)
        assert _N == 6 & estimand == "noncausal_association"
        sort analysis_id spec_id
        forvalues row = 1/`=_N' {
            local label = subinstr(outcome_label[`row'], "Migration and baseline ", "", .)
            local model = proper(subinstr(spec_id[`row'], "descriptive_", "", .))
            local effect = strtrim(string(estimate[`row'], "%6.3f"))
            local interval = "[" + strtrim(string(ci_low[`row'], "%6.3f")) + ", " + strtrim(string(ci_high[`row'], "%6.3f")) + "]"
            local raw = strtrim(string(pvalue[`row'], "%5.3f"))
            if pvalue[`row'] < 0.001 local raw "\(<0.001\)"
            local bh = strtrim(string(q_bh[`row'], "%5.3f"))
            if missing(q_bh[`row']) local bh "--"
            file write `table' "`label' & `model' & \shortstack[r]{`effect' \\{} `interval'} & `raw' & `bh' \\" _n
        }
    }
    file write `table' "\bottomrule\end{longtable}{\footnotesize\textit{Notes:} `note'}\par\endgroup" _n
    file close `table'
    quietly checksum "${project_root}/`source'"
    local source_checksum = r(checksum)
    quietly checksum "${project_root}/`output'"
    post `exhibit_post' ("`exhibit'") ("appendix") ("`output'") ///
        ("`source'") (`source_checksum') (r(checksum)) ("`caption'") ///
        (0) (0) ("hold_no_sync") ("generated_unreviewed")
}

* Separate parent frames, rather than an apparent single attrition funnel.
import delimited "${tables_root}/rd_mechanisms/rd_census2017_selection_flow.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if scope == "common_h" & side == "all" & ///
    inlist(stage, "source_coverage", "person_linkage", "person_movement", ///
        "adult_movement", "household_linkage", "household_complete")
assert _N == 6
generate double plot_rate = 100*rate_ccpp_equal
generate byte plot_order = .
replace plot_order = 6 if stage == "source_coverage"
replace plot_order = 5 if stage == "person_linkage"
replace plot_order = 4 if stage == "person_movement"
replace plot_order = 3 if stage == "adult_movement"
replace plot_order = 2 if stage == "household_linkage"
replace plot_order = 1 if stage == "household_complete"
generate str40 parent_label = string(numerator_n, "%9.0fc") + " / " + string(denominator_n, "%9.0fc")
local scheme "s2color"
capture findfile scheme-plotplainblind.scheme
if !_rc local scheme "plotplainblind"
twoway (bar plot_rate plot_order, horizontal barwidth(0.55) fcolor(navy%75) lcolor(none)) ///
    (scatter plot_order plot_rate, msymbol(none) mlabel(parent_label) mlabposition(3) mlabsize(small)), ///
    scheme(`scheme') ylabel(1 "All eight household outcomes" 2 "Any linked household member" ///
        3 "Movement: linked known-age adults" 4 "Movement: all source people" ///
        5 "Linkage: all source people" 6 "Community source-cohort entry", ///
        angle(0) labsize(small) nogrid) ///
    xlabel(0(25)100, labsize(small) grid glcolor(gs14)) xscale(range(0 137)) ///
    ytitle("") xtitle("CCPP-equal rate (%)", size(small)) legend(off) ///
    title("Census 2017: distinct observation stages", size(medsmall) span) ///
    subtitle("Fixed RD window; labels show observed / parent counts", size(small) span) ///
    note("Selected B/C geography; h=0.0075. Each represented CCPP has equal weight." ///
        "Parent frames differ: RUV communities; delivered people; source households;" ///
        "and linked known-age adults (age 14+). This is not a sequential attrition funnel." ///
        "Adult movement is conditional on linkage and known age. Household completeness" ///
        "requires all eight primary outcomes. Rates are descriptive, not estimates with" ///
        "sampling confidence intervals or evidence of ignorable selection." ///
        "Sources: RUV, CMAN, SISFOH and INEI-assisted Census 2017.", size(small) span) ///
    xsize(6.6) ysize(5.2) graphregion(color(white))
local output "output/figures/publication/A29_selection_flow.png"
graph export "${project_root}/`output'", width(2400) replace
local source "output/tables/rd_mechanisms/rd_census2017_selection_flow.csv"
quietly checksum "${project_root}/`source'"
local source_checksum = r(checksum)
quietly checksum "${project_root}/`output'"
post `exhibit_post' ("A29") ("appendix") ("`output'") ("`source'") ///
    (`source_checksum') (r(checksum)) ("Census 2017: distinct selection and observation stages") ///
    (0) (0) ("hold_no_sync") ("generated_unreviewed")

postclose `exhibit_post'
postclose `cell_post'
use `cells', clear
sort exhibit_id row_order
export delimited "`table_dir'/publication_review_cells.csv", replace nolabel
use `exhibits', clear
isid exhibit_id
assert _N == 35
sort proposed_role exhibit_id
format source_checksum checksum %21.0f
export delimited "`table_dir'/publication_review_exhibits.csv", replace nolabel datafmt

* Portable input list: compilation is deliberately outside the Stata master.
tempname inputs
file open `inputs' using "`table_dir'/publication_review_exhibits.tex", write replace text
foreach role in main_text appendix {
    local first_exhibit 1
    if "`role'" == "main_text" file write `inputs' "\clearpage\section{Proposed main-text exhibits}" _n
    else file write `inputs' "\clearpage\appendix\section{Supporting exhibits}\setcounter{table}{0}\setcounter{figure}{0}\renewcommand{\thetable}{A\arabic{table}}\renewcommand{\thefigure}{A\arabic{figure}}\renewcommand{\theHtable}{A\arabic{table}}\renewcommand{\theHfigure}{A\arabic{figure}}" _n
    forvalues row = 1/`=_N' {
        if proposed_role[`row'] == "`role'" {
            local path = path[`row']
            local caption = caption[`row']
            local exhibit = exhibit_id[`row']
            if !`first_exhibit' file write `inputs' "\clearpage" _n
            local first_exhibit 0
            if substr("`path'", -4, 4) == ".tex" file write `inputs' "\input{`path'}" _n
            else file write `inputs' "\begin{figure}[!htbp]\centering\includegraphics[width=\linewidth]{`path'}\caption{`caption'}\label{fig:pub_`exhibit'}\end{figure}" _n
        }
    }
}
file close `inputs'

* Narrative numbers are sourced, not retyped into manuscript prose.
tempname values
file open `values' using "`table_dir'/publication_results_values.tex", write replace text
local primary_count 0
local significant_count 0
foreach year in 2013 2017 {
    foreach level in ccpp household individual {
        import delimited "${tables_root}/rd_outcomes/rd_`year'_`level'_results.csv", ///
            clear varnames(1) bindquote(strict) encoding(utf8)
        quietly count if tier == "primary" & spec_id == "common_h_fuzzy" & estimand == "fuzzy_late"
        assert r(N) == 8
        local primary_count = `primary_count' + r(N)
        quietly count if tier == "primary" & spec_id == "common_h_fuzzy" & estimand == "fuzzy_late" & p_holm < 0.05
        local significant_count = `significant_count' + r(N)
    }
}
file write `values' "\newcommand{\PrimaryTests}{`primary_count'}\newcommand{\PrimarySignals}{`significant_count'}" _n
import delimited "${tables_root}/rd_outcomes/rd_2017_individual_results.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
preserve
keep if outcome_id == "I03" & spec_id == "common_h_fuzzy" & estimand == "fuzzy_late"
assert _N == 1
foreach entry in "MigrationEffect estimate_bc" "MigrationLower ci_low" "MigrationUpper ci_high" ///
    "MigrationP pvalue" "MigrationHolm p_holm" {
    gettoken macro variable : entry
    local variable = strtrim("`variable'")
    local format "%6.2f"
    if inlist("`macro'", "MigrationP", "MigrationHolm") local format "%5.3f"
    local value = strtrim(string(`variable'[1], "`format'"))
    file write `values' "\newcommand{" (char(92)) "`macro'}{`value'}" _n
}
local n = strtrim(string(n_eff_left[1]+n_eff_right[1], "%9.0fc"))
local communities = ccpp_left[1]+ccpp_right[1]
file write `values' "\newcommand{\MigrationN}{`n'}\newcommand{\MigrationCCPP}{`communities'}" _n
restore
keep if outcome_id == "I03" & spec_id == "parametric_common_h"
assert _N == 1
local value = strtrim(string(first_stage_f[1], "%6.2f"))
file write `values' "\newcommand{\MigrationF}{`value'}" _n
import delimited "${tables_root}/rd_outcomes/rd_2017_household_results.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8)
keep if outcome_id == "D05" & estimand == "selection"
assert _N == 1
foreach entry in "HouseholdSelectionEffect estimate_bc" "HouseholdSelectionLower ci_low" ///
    "HouseholdSelectionUpper ci_high" "HouseholdSelectionP pvalue" {
    gettoken macro variable : entry
    local variable = strtrim("`variable'")
    local format "%6.2f"
    if "`macro'" == "HouseholdSelectionP" local format "%6.4f"
    local value = strtrim(string(`variable'[1], "`format'"))
    file write `values' "\newcommand{" (char(92)) "`macro'}{`value'}" _n
}
file write `values' "\newcommand{\AssignmentSignals}{`assignment_signal_total'}\newcommand{\AssignmentAdjusted}{`assignment_adjusted_total'}" _n
file close `values'
capture program drop _vrd_review_table
display as result "Built 35 publication-sized review exhibits; no estimates or release roles changed."
