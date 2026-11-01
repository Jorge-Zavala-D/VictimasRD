# Standing Stata research-code standards

Adopted from the owner's instructions of 1 November 2026. Applies to Stata programming, review, refactoring, and preparation of this project's replication package. These standards supplement AGENTS.md; they do not override the approved scientific protocols, immutable-source rules, Stata-MCP execution boundary, or publication/release holds.

## Governing standard

A competent social scientist must be able to read the code, identify and challenge the research decisions, trace the analytical data, reproduce reported results, and modify the workflow without learning an unnecessary custom framework. Scientific reliability and clarity take precedence over line count, cosmetic uniformity, or software-engineering novelty.

Apply these standards during development and review them comprehensively at stable major milestones. Do not repeatedly rewrite working code for appearance or displace substantive research with cleanup.

## 1. Learn from actual research code

Before major development or refactoring, start with the current bibliography and literature review. Identify authoritative replication records through the published article, DOI, repository record, or author-maintained repository. Record the published version separately from later working code.

Inspect actual master, preparation, estimation, and output scripts, not only READMEs. Trace selected main and appendix exhibits to the relevant commands. Supplement bibliography examples with methodologically relevant empirical work; prestige is not a code-quality certificate.

Record four distinct achievements: located; files inspected; code-to-exhibit logic traced; successfully executed. Report unavailable, restricted, non-Stata, and unexamined material honestly. Inspect external code before any authorized execution, respect licenses, and do not fetch research data merely to study coding style.

The initial evidence record is [the reference review](STATA_REFERENCE_REVIEW_2026-11-01.md). It is bounded evidence, not an exhaustive review of institutional resources or all literature packages.

## 2. Use guidance selectively

Consult relevant DIME Wiki and Data Handbook/coding-guide sections, DIME standards and World Bank replication resources, J-PAL cleaning/coding/publication guidance, IPA cleaning/practical guides/template/cfout, Higgins's Stata Guide, AEA policies/guidance, and official Stata documentation.

Distinguish journal requirements, institutional recommendations, and project preferences. Neither a DIME template nor an AEA policy automatically binds this World Development-oriented project. Do not import a whole template, install packages, change dependency versions, or copy historical methodological defaults merely because a guide uses them.

## 3. Keep reference review verifiable

For each package actually used as an example, record paper, authoritative source chain, version/access date, exact scripts and read ranges, useful and unsuitable practices, and the particular project decision informed. Consult official help/manuals and the locked implementation when consequential command behavior is uncertain.

## 4. Preserve the research-task architecture

Keep the existing master and understandable task order. Preparation remains one authoritative, source-sectioned entry point, followed by descriptives, fixed design validation, main effects, heterogeneity, migration/mechanisms, publication production, and release checks. The historical exhaustive search remains opt-in and outside routine execution.

Do not introduce a generic dispatcher or new folder architecture. Maintain an explicit map from important datasets and exhibits to their producing scripts, using existing manifests and pipeline documentation.

## 5. Prefer explicit Stata

Use conventional commands, descriptive variable names, consistent indentation, readable line continuations, and explicit variable lists. Avoid variable abbreviations, cryptic positional references, order-dependent ranges, and compressed expressions that conceal consequential transformations. A few clear commands are preferable to a dense one-liner.

## 6. Use macros, loops, and programs where they clarify

Use locals for temporary values and real repeated lists; centralize machine-specific paths in ignored local configuration. Avoid scattered globals, nested macro chains, and unnecessary dynamic names.

Retain clear loops for genuinely consistent repeated operations. Keep scientifically different specifications visibly distinct. Programs are appropriate for coherent, substantially repeated operations with understandable arguments, required inputs, outputs, and side effects. Do not wrap a short command merely to add indirection, or expand a useful loop into hundreds of copied lines.

## 7. Expose construction and sample decisions

Identify the observational unit and keys. Document treatment, outcome, control, index and moderator definitions; transformations, standardization and aggregation; exclusions, duplicate adjudication and missingness; and source-to-analysis sample flow.

Preserve source variables when a transformation changes interpretation. Label units, years, category references and missing meanings. Do not overwrite raw inputs. Explain the population/unit consequences of keep, drop, replace, collapse, reshape and deduplication.

Final analytical data retain only research-integral variables. Temporary construction/QA fields must not accumulate in released analytical datasets; restricted row-level QA stays in configured Dropbox Working.

## 8. Guard consequential data-management boundaries

Use isid before relying on keys. Establish merge cardinality and inspect unmatched records before applying a documented policy. Never use merge m:m or duplicates drop, force to conceal unresolved relationships.

Require known age and finite statistics explicitly when that is the intended universe. In Stata, numeric missing values exceed finite values; positivity comparisons alone do not prove an observed positive value. Preserve distinctions among zero, unknown, refusal and not applicable.

Check aggregation denominators and all-missing groups. Preserve identifier precision, leading zeros and meaningful strings; use appropriate numeric types and sufficient financial precision. Make date units, panel IDs and reshape dimensions explicit. Current sort order is not a persistent identifier.

## 9. Comment consequential reasoning

Use concise section headers and comments explaining purpose, input, assumptions, why a recode/exclusion/model is justified, and the relevant source or decision record. Comment individual lines when otherwise ambiguous. Avoid decorative banners, conversational notes, and comments that simply translate obvious commands.

## 10. Make estimators inspectable

The estimation block must expose outcome, treatment/instruments, controls, fixed effects, weights, sample, clustering and consequential options. Deliberately define factor-variable interactions and reference groups.

Store intended e()/r() results before later commands overwrite them. Generate tables and figures from stored estimates, not hand-transcribed numbers. Show outcome-specific denominators and appropriate first-stage evidence rather than inheriting clearance from a different sample.

## 11. Reproduce the actual environment

Declare Stata version and relevant settings; separately record user-written dependency versions/identities and lawful restoration requirements. Version control does not freeze independently updated ado files.

Separate authorized environment restoration from routine execution. Never reinstall or update packages automatically to get a run to pass. Record seeds and deterministic ordering for stochastic/order-dependent operations. Test the documented entry point from a clean session; do not rely on interactive leftovers. Retain useful, untracked, non-sensitive execution logs.

Describe restricted-data access and executable boundaries honestly. Synthetic tests validate code behavior, not empirical reproduction.

## 12. Retain meaningful checks

Use direct assertions for keys, ranges, counts, merge relationships, missingness, sample composition and constructed-variable consistency. Prefer a few research-relevant checks to repetitive assertions that merely restate the code.

Use capture selectively for optional-object existence or a closed log. Consequential transformation or estimation failure must remain visible. Do not silently switch inputs/methods, alter samples, or discard records to make a run pass.

## 13. Separate refactoring from scientific correction

Before consequential refactoring, establish a preserved baseline of identifiers, data contents and missingness, model samples, coefficients/inference, table contents, and figure source values. Compare exact values where appropriate; declare and justify any tolerance before use.

A style-only change must preserve definitions, samples, weights, specifications, estimators, inference and interpretation. Report genuine bugs and scientific ambiguities separately. Do not hide a substantive correction inside cleanup or weaken checks to retain an old result.

## 14. Prepare a usable package without publishing it

The release README must specify entry point, input provenance/access, script order, output mapping, Stata/dependencies/settings, runtime/hardware where known, and restricted/non-executable steps. Separate exploration from the publication workflow while preserving history.

Exclude credentials, private paths, sensitive records and irrelevant correspondence. Data access permission, code preparation, successful execution, scientific validation and publication authorization are different gates. Verify the final documented package end-to-end; isolated script successes are insufficient.

## 15. Work proportionately and report precisely

Make the smallest complete improvement. Inspect callers, tests, config, exports and downstream consumers of a shared routine. Reuse clear code; avoid wholesale rewrites and new dependencies without concrete benefit.

At completion state: what changed; why; what was verified; whether scientific behavior changed; remaining limitations. Inspect the proposed Git scope, prepare the required local commit-message handoff, and never stage, commit, push, submit or publish without explicit authorization.

## Current audit and next implementation boundary

The [1 November audit](STATA_CODE_AUDIT_2026-11-01.md) records reachable defects, current-output checks, historical-code limits, and the correction sequence. It does not implement the fixes or approve new scientific decisions. A later correction must use its focused tests and preserved empirical baseline; a passing checksum alone cannot establish causal validity.

