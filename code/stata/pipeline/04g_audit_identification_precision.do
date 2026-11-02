/* Aggregate-only review of the exact-sample records collected by module 04.
   This does not select results, change multiplicity, or synchronize Overleaf. */
version 19
set more off

tempfile all_models precision_registry
local first_file 1
foreach wave in 2013 2017 {
    foreach level in ccpp household individual {
        import delimited using "${rd_table_dir}/rd_`wave'_`level'_results.csv", ///
            clear varnames(1) bindquote(strict) encoding(utf8) asdouble
        generate int wave = `wave'
        generate str12 level = "`level'"
        if !`first_file' append using "`all_models'"
        save "`all_models'", replace
        local first_file 0
    }
}
isid wave level outcome_id spec_id estimand
assert _N == 1970

import delimited using "${rd_table_dir}/rd_exact_sample_diagnostics.csv", ///
    clear varnames(1) bindquote(strict) encoding(utf8) asdouble
rename (ccpp_left ccpp_right) (audit_ccpp_left audit_ccpp_right)
isid wave level outcome_id spec_id estimand
merge 1:1 wave level outcome_id spec_id estimand using "`all_models'", assert(3) nogen
assert original_rc == estimation_rc
assert eligible_n == n_input if estimator == "rdrobust"
assert n_left == n_eff_left & n_right == n_eff_right ///
    if estimator == "rdrobust" & estimation_rc == 0
assert iv_n == n_input if estimator == "ivreg2" & ///
    estimation_rc == 0 & audit_rc == 0
assert abs(coefficient_gap) < 1e-7 * (1 + abs(estimate_cl)) ///
    if estimator == "ivreg2" & estimation_rc == 0 & audit_rc == 0

generate byte receipt_effect = inlist(estimand, "fuzzy_late", "parametric_late")
generate byte kp_gate = kp_f > 10 & kp_f < . & ///
    audit_rc == 0 & estimation_rc == 0 & !missing(iv_effect, iv_se) & iv_se > 0 ///
    if receipt_effect
generate byte conventional_point_matches = ///
    abs(coefficient_gap) < 1e-7 * (1 + abs(estimate_cl)) ///
    if receipt_effect & audit_rc == 0 & estimation_rc == 0
generate str100 interpretation_boundary = "Not a receipt-effect model"
replace interpretation_boundary = "Original fit failed; retain registered hypothesis" ///
    if receipt_effect & estimation_rc != 0
replace interpretation_boundary = "Own-sample IV diagnostic failed; receipt interpretation held" ///
    if receipt_effect & estimation_rc == 0 & audit_rc != 0
replace interpretation_boundary = "Own-sample KP gate failed; receipt interpretation held" ///
    if receipt_effect & estimation_rc == 0 & audit_rc == 0 & kp_gate == 0
replace interpretation_boundary = ///
    "IV gate passed; RBC validity, selection and instrument assumptions remain conditional" ///
    if receipt_effect & kp_gate == 1
generate str40 ar_scope = "Conventional local-IV analogue only" if receipt_effect
generate str112 window_inference_scope = ///
    "Registered fixed window; inference remains conditional on the local-IV model" ///
    if receipt_effect & bwselect == "manual"
replace window_inference_scope = ///
    "Outcome-adaptive window: diagnostic, not an unconditional post-selection RD confidence set" ///
    if receipt_effect & bwselect != "manual"
sort wave level paper_order spec_id estimand
export delimited using "${rd_table_dir}/rd_identification_precision_registry.csv", replace

preserve
generate byte models = 1
generate byte receipt_models = receipt_effect
generate byte passed = receipt_effect & kp_gate == 1
generate byte held = receipt_effect & kp_gate == 0
generate byte original_failed = estimation_rc != 0
generate byte nonbounded_ar = receipt_effect & ///
    inlist(ar_type, "all_real", "unbounded", "disjoint")
generate byte failed_ar = receipt_effect & ar_type == "failed"
collapse (sum) models receipt_models passed held original_failed nonbounded_ar failed_ar, ///
    by(wave level)
assert _N == 6
assert passed + held == receipt_models
sort wave level
export delimited using "${rd_table_dir}/rd_identification_summary.csv", replace

tempname summary_table
file open `summary_table' using ///
    "${rd_table_dir}/tab_identification_summary.tex", write replace text
file write `summary_table' ///
    "\begin{table}[!htbp]\centering" _n ///
    "\caption{Exact-sample identification audit}\label{tab:exact_sample_audit}" _n ///
    "\begin{tabular}{llrrrrr}\toprule" _n ///
    "Wave & Level & Models & Receipt & KP passes & Held & Nonbounded AR \\" _n ///
    "\midrule" _n
forvalues row = 1/`=_N' {
    local level_label = proper(level[`row'])
    if level[`row'] == "ccpp" local level_label "Community"
    file write `summary_table' ///
        (wave[`row']) " & `level_label' & " ///
        (models[`row']) " & " (receipt_models[`row']) " & " ///
        (passed[`row']) " & " (held[`row']) " & " (nonbounded_ar[`row']) " \\" _n
}
file write `summary_table' "\bottomrule\end{tabular}" _n ///
    "\begin{minipage}{0.98\linewidth}\footnotesize\textit{Notes:} " ///
    "All registered module-04 models, including unsuccessful fits. Counts are " ///
    "specification rows, not independent tests or populations. Receipt models " ///
    "are fuzzy-RD or registered parametric receipt-effect specifications. " ///
    "KP passes require a finite own-sample Kleibergen--Paap F strictly above 10; " ///
    "this is an operational screen, not certification of strong identification. " ///
    "Held includes original failures, diagnostic failures and gate failures. " ///
    "Nonbounded AR counts all-real, one-sided unbounded and disjoint 95\% " ///
    "Anderson--Rubin confidence sets for conventional local-IV analogues. " ///
    "Adaptive-window sets are diagnostics, not established post-selection RD coverage. " ///
    "Original RD samples, weights, windows, inference and multiplicity are unchanged. " ///
    "CCPP denotes centro poblado (community). Sources: the RUV victim register, " ///
    "CMAN reparations records, SISFOH and the INEI-assisted Census linkage; " ///
    "selection and instrument-validity assumptions remain binding." ///
    "\end{minipage}\end{table}" _n
file close `summary_table'
restore

keep if tier == "primary" & spec_id == "common_h_fuzzy"
assert _N == 48
isid wave level outcome_id
bysort wave level: assert _N == 8
generate str24 display_unit = "percentage points" if scale == 100
replace display_unit = "index points" if strpos(outcome_var, "wellbeing") > 0
replace display_unit = "log points" if strpos(outcome_var, "ln_") == 1
replace display_unit = "count units" if display_unit == ""
generate double small_benchmark = 5
generate double large_benchmark = 10
replace small_benchmark = ln(1.05) if display_unit == "log points"
replace large_benchmark = ln(1.10) if display_unit == "log points"
replace small_benchmark = 1 if display_unit == "count units"
replace large_benchmark = 2 if display_unit == "count units"
generate double interval_width = ci_high - ci_low
generate byte negative_small_compatible = ///
    inrange(-small_benchmark, ci_low, ci_high) if !missing(ci_low, ci_high)
generate byte positive_small_compatible = ///
    inrange(small_benchmark, ci_low, ci_high) if !missing(ci_low, ci_high)
generate byte negative_large_compatible = ///
    inrange(-large_benchmark, ci_low, ci_high) if !missing(ci_low, ci_high)
generate byte positive_large_compatible = ///
    inrange(large_benchmark, ci_low, ci_high) if !missing(ci_low, ci_high)
generate byte interval_inside_small = ci_low > -small_benchmark & ///
    ci_high < small_benchmark if !missing(ci_low, ci_high)
generate byte interval_inside_large = ci_low > -large_benchmark & ///
    ci_high < large_benchmark if !missing(ci_low, ci_high)
generate str100 precision_reading = "Uncertain at illustrative benchmark scale"
replace precision_reading = "Both signs of the larger benchmark remain compatible" ///
    if negative_large_compatible == 1 & positive_large_compatible == 1
replace precision_reading = "Ordinary RD interval lies inside larger illustrative bounds" ///
    if interval_inside_large == 1
replace precision_reading = "Ordinary RD interval lies inside smaller illustrative bounds" ///
    if interval_inside_small == 1
generate str100 benchmark_status = ///
    "Illustrative post-results benchmark; not a preregistered minimal important effect"
sort wave level paper_order
export delimited using "${rd_table_dir}/rd_primary_precision.csv", replace
save "`precision_registry'", replace

/* Complete primary families are displayed, never only favorable outcomes. */
tempname primary_table benchmark_table
file open `primary_table' using ///
    "${rd_table_dir}/tab_identification_primary.tex", write replace text
file write `primary_table' ///
    "\begin{longtable}{@{}p{0.30\linewidth}r p{0.19\linewidth}r p{0.22\linewidth}@{}}" _n ///
    "\caption{Primary outcomes: identification and uncertainty}\label{tab:primary_identification_precision}\\" _n ///
    "\toprule Outcome (units) & RD effect & RD 95\% interval & KP F & IV AR 95\% set \\" _n ///
    "\midrule\endfirsthead" _n ///
    "\toprule Outcome (units) & RD effect & RD 95\% interval & KP F & IV AR 95\% set \\" _n ///
    "\midrule\endhead\bottomrule\endfoot" _n
file open `benchmark_table' using ///
    "${rd_table_dir}/tab_precision_benchmarks.tex", write replace text
file write `benchmark_table' ///
    "\begin{longtable}{@{}p{0.41\linewidth}rrcc@{}}" _n ///
    "\caption{Primary outcomes: illustrative effect compatibility}\label{tab:illustrative_precision}\\" _n ///
    "\toprule Outcome & Small & Large & Both large signs? & Inside small? \\" _n ///
    "\midrule\endfirsthead" _n ///
    "\toprule Outcome & Small & Large & Both large signs? & Inside small? \\" _n ///
    "\midrule\endhead\bottomrule\endfoot" _n
local previous_group ""
forvalues row = 1/`=_N' {
    local level_label = proper(level[`row'])
    if level[`row'] == "ccpp" local level_label "Community"
    local group = string(wave[`row']) + " " + "`level_label'"
    local sample_n : display %9.0fc (n_left[`row'] + n_right[`row'])
    local sample_j : display %9.0fc (audit_ccpp_left[`row'] + audit_ccpp_right[`row'])
    local sample_k : display %9.0fc clusters[`row']
    if "`group'" != "`previous_group'" {
        file write `primary_table' ///
            "\multicolumn{5}{l}{\textit{`group': N=`sample_n'; J=`sample_j'; K=`sample_k'}}\\*" _n
        file write `benchmark_table' ///
            "\multicolumn{5}{l}{\textit{`group': N=`sample_n'; J=`sample_j'; K=`sample_k'}}\\*" _n
        local previous_group "`group'"
    }
    local label = subinstr(outcome_label[`row'], "&", "\&", .)
    if wave[`row'] == 2017 & level[`row'] == "individual" & outcome_id[`row'] == "I03" {
        local label "`label' [N=`sample_n'; J=`sample_j'; K=`sample_k']"
    }
    local units = display_unit[`row']
    local effect : display %6.2f estimate_bc[`row']
    local low : display %6.2f ci_low[`row']
    local high : display %6.2f ci_high[`row']
    local kp : display %6.2f kp_f[`row']
    local ar_set = ar_type[`row']
    if ar_type[`row'] == "all_real" local ar_set "All real numbers"
    if ar_type[`row'] == "bounded" {
        local ar_low : display %6.2f ar_low1[`row']
        local ar_high : display %6.2f ar_high1[`row']
        local ar_set "[`ar_low', `ar_high']"
    }
    if ar_type[`row'] == "disjoint" local ar_set "Disjoint; see CSV"
    if ar_type[`row'] == "unbounded" local ar_set "Unbounded; see CSV"
    file write `primary_table' ///
        "`label' (`units') & `effect' & [`low', `high'] & `kp' & `ar_set' \\" _n
    local small : display %6.3f small_benchmark[`row']
    local large : display %6.3f large_benchmark[`row']
    local both "No"
    if negative_large_compatible[`row'] == 1 & positive_large_compatible[`row'] == 1 local both "Yes"
    if missing(negative_large_compatible[`row'], positive_large_compatible[`row']) local both "Unavailable"
    local inside "No"
    if interval_inside_small[`row'] == 1 local inside "Yes"
    if missing(interval_inside_small[`row']) local inside "Unavailable"
    file write `benchmark_table' "`label' & `small' & `large' & `both' & `inside' \\" _n
}
quietly summarize p_holm, meanonly
local holm_min : display %5.3f r(min)
local holm_max : display %5.3f r(max)
file write `primary_table' "\end{longtable}" _n ///
    "\noindent\footnotesize\textit{Notes:} All 48 registered primary outcomes. " ///
    "RD effects and intervals are the original bias-corrected fixed-window fuzzy " ///
    "estimates (h=0.0075, b=0.0135, local linear, triangular kernel, CR2). " ///
    "CCPP means centro poblado (community). District clusters apply at community " ///
    "level; RUV-community clusters apply for " ///
    "households and people. The latter receive CCPP-equal weights. " ///
    "Group counts give local observations (N), assignment communities (J), and " ///
    "inference clusters (K), except the distinct migration sample printed on its row. " ///
    "KP and Anderson--Rubin sets refer to the matching conventional local-IV analogue " ///
    "with clustered CR1 inference, not to bias-corrected RD inference. Sets are " ///
    "95\% marginal confidence sets, not multiplicity-adjusted intervals. " ///
    "A finite KP F above 10 does not establish identification or ignorable " ///
    "linkage. Full sample sizes, score support, reduced forms, original Holm " ///
    "p-values, set endpoints and failures appear in the accompanying registry. " ///
    "Primary Holm-adjusted p-values range from `holm_min' to `holm_max'. " ///
    "SISFOH outcomes use receipt through 2012; linked-cohort Census outcomes " ///
    "use receipt through 2016. The approved observed-adult movement population " ///
    "is retained for 2017 individual migration. Sources: RUV, CMAN, SISFOH and INEI.\normalsize" _n
file write `benchmark_table' "\end{longtable}" _n ///
    "\noindent\footnotesize\textit{Notes:} Benchmarks are in the units reported " ///
    "in the preceding table: 5/10 percentage or index points; log(1.05)/log(1.10) " ///
    "for log counts; one/two units for counts. They are illustrative, selected " ///
    "after results were known, not preregistered minimal important effects. " ///
    "Both signs asks whether the ordinary 95\% RD interval contains both " ///
    "the positive and negative larger benchmark. Inside small asks whether " ///
    "that entire interval lies strictly inside the smaller symmetric bounds; " ///
    "this is not a formal equivalence test. Ordinary intervals remain " ///
    "conditional on identification; no post-hoc observed-effect power is computed. " ///
    "Complete family definitions, multiplicity and selection qualifications " ///
    "are unchanged. Sources: the registered module-04 estimates.\normalsize" _n
file close `primary_table'
file close `benchmark_table'

tempname manifest_file
file open `manifest_file' using ///
    "${metadata_root}/rd-identification-precision-output-manifest.csv", write replace text
file write `manifest_file' "path,artifact_type,generator,run_id,checksum,review_status" _n
foreach output_name in rd_exact_sample_diagnostics.csv ///
    rd_identification_precision_registry.csv rd_identification_summary.csv ///
    rd_primary_precision.csv tab_identification_summary.tex ///
    tab_identification_primary.tex tab_precision_benchmarks.tex {
    quietly checksum "${rd_table_dir}/`output_name'"
    local output_checksum : display %20.0f r(checksum)
    local output_checksum = strtrim("`output_checksum'")
    local generator "code/stata/pipeline/04g_audit_identification_precision.do"
    if "`output_name'" == "rd_exact_sample_diagnostics.csv" ///
        local generator "code/stata/pipeline/04_estimate_main_effects.do"
    file write `manifest_file' ///
        `""output/tables/rd_outcomes/`output_name'","review_table","`generator'","${rd_run_id}","`output_checksum'","generated_unreviewed""' _n
}
file close `manifest_file'
display as result "Identification/precision registry covers 1,970 models and 48 primary outcomes."
display as text "Review-only outputs; no manuscript synchronization or release approval."
