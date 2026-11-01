# Preserved legacy-code audit and porting cautions — 1 November 2026

This is historical source evidence supporting the [current-code audit](STATA_CODE_AUDIT_2026-11-01.md), not a second production workflow. **Leave every legacy byte unchanged.** Any future repair belongs in an explicitly authorized derivative with its own baseline, decision record and tests.

## Coverage and interpretation

All 77 research do-files under code/stata/legacy-current were covered:50,328 lines/67 distinct byte contents. The [per-file coverage ledger](../metadata/stata-audit-2026-11-01/review-coverage.csv) records exact names, ranges and references. Modes mean:

- R: sequential text reading.
- P: sequential functional/source-line projection; blank/comment-only material omitted, dormant blocks and comment-closing commands checked. Not a parser proof or full independent comment read.
- T: complete-range comparison after trimming only leading/trailing whitespace; every new/changed target line read; shared lines inherit reference review.
- D: SHA-256 byte-identical to a reviewed source; all such identities checked against the inventory.
- M: explicitly bounded mixed sequential/internal-template review.
- L+P: ordered whitespace-normalized comparison of626 SISFOH label statements, then functional/comment-boundary inspection.

No legacy script, data, testimony record or workbook was executed/opened for numerical verification. Vendor ado/compiled support is separately inventoried, not fully audited. No AnaMaria-named do-file appeared in this repository inventory; this does not establish absence of differently named contributions or external Dropbox code.

All locations below are relative to code/stata/legacy-current. Root1 means 1 HVC - APU; root2 means 2 HVC - APU - LC - HCY; root3 means 3 HVC - APU - LC - HCY - SM. None of these historical findings alone establishes an error in the current analytical data or results.

## Historical source/output lineage

- 4 Working paper/0d. clean_minedu.do:184–203 builds ECE2014 but saves ece_2012.dta with replace after the2012 product at180–181. Running that path can overwrite the derived2012 file with2014 contents.
- SAT/ccpp_pbi_contraloria.do:133–140 loads the CENAGRO-linked community source but saves it under a MINSA-GDP destination.

A future derivative needs explicit source-year/schema markers and output-lineage assertions, not a general importer. Current reintroduction was not established.

## Missingness and observational unit

- Working-paper SISFOH cleaner0b:868,871,873 clips ratios above1 without finite guards; missing ratios also exceed1 in Stata and become1.
- Many historical asset/program indicators default missing to0. These are porting risks, not proven data errors without questionnaire routing/codebooks.
- Subgroup templates use moderator>median without excluding a missing moderator, admitting unknown values into an above-median group.
- Working-paper INEI cleaner0j:649–703 sums dwelling indicators across households before dividing by dwelling count; a two-household dwelling can contribute twice to a dwelling-level binary numerator.

Tests for future reuse should distinguish unknown/inapplicable/true0, guard zero denominators, and include a two-household dwelling. The current known-age issues are separately documented in the main audit; the current primary migration sample is not alleged to inherit these historical problems.

## Historical linkage and duplicates

MINEDU0d:288–299 accepts fuzzy candidates and drops scores;1062–1083 resolves repeatedCCPP without retaining the full conflict evidence. CENAGRO0e:1961–1969 and MINSA0f:94–100 use nearest-CCPP assignment without an explicit distance/administrative gate. Legacy main preparation1:277–292 drops unmatched SISFOH and selects duplicate occurrences.

Preserve candidate scores/distances, boundary consistency and explicit conflict adjudication in any derivative. Nearest or first is not automatically the correct community. Current linkage governance is stronger and must not be replaced with these shortcuts.

## Geographic identifiers are not fixed effects

Working-paper CCPP estimates4:1833–1842,1989–1998,2093–2102 label province fixed effects but pass numeric cluster_dist inside covs(). Household5:1240–1249,1344–1353,1448–1457,1552–1561 and individual6:399–408,501–509,604–613,708–717 similarly use numeric cluster_prov.

One slope on arbitrary encoded numbers is not categorical fixed effects. An authorized derivative must make the intended specification explicit; a renumbering-invariance fixture distinguishes true group indicators from a numeric-code covariate. This was not found to be the current04/05 implementation.

## Handwritten model/export mappings have drifted

- 1 HVC - APU/4. ...CCPP level.do:55–74,129–202,229–323 skips an advertised optimalp2 fit, shifts subsequent spreadsheet columns, and leaves a promised column unwritten.
- The same directory's6. ...Individual level.do:66–75,263–301 advertises more fixed-window variants than are fitted/exported.
- 2 HVC - APU - LC - HCY/4a. ...CCPP level - Population.do:304–312,550–605 omits gas from the high-population outcome list at559 but retains its baseline at587. Positional baseline lookup306 then pairs carbon with gas2007 and shifts later adjustments.

Future reuse needs an explicit outcome-to-baseline/model-to-column map, cleared result destinations and fixture checks. This is a concrete justification for a compact registry, not an invitation to bury scientific decisions in a generic estimator.

## Sample promises and displayed means

The root2 NoCaps individual script6d:1–348 has no capital-exclusion restriction. Seven root3 subgroup scripts are byte-identical to root1 and retain the narrower Huancavelica/Apurimac models/output paths despite their containing directory's larger geographic name.

Working-paper expanded-SanMartin CCPP fits1943–1946,1995–1998,2047–2050,2099–2102 include that region; corresponding displayed control means1972–1974,2024–2026,2076–2078,2128–2130 omit it. Other historical means do not consistently reuse model eligibility/missing-covariate restrictions. Selecting the first over-group result is also not a reliable untreated-group identifier if an anticipated group is absent.

Filenames are not sample contracts. A future derivative must reuse the explicit fitted sample for model summaries or clearly label a separate descriptive population.

## Attrition export state

Root2 X. Attrition Analysis...do:72–89,100–103 accumulates a local controls list without resetting by model family, while coefficient exports reference different global lists. At163–165 and171–173, a no-capitals fit is immediately overwritten by an unrestricted probit before export to a nocaps workbook. The SAT copy is byte-identical.

A future derivative should reset each model's regressor list, export that same list, and place the intended restriction on the final fitted model. The standalone command a at99 was not executed or assumed to resolve in any particular way.

## Method labels, dormant blocks and rejected false positives

Historical fixed windows labeled randomization inference are often ordinary continuity-based rdrobust fits; a fixed h alone is not randomization inference. The Sex interaction script estimates separate groups, not a formal pooled interaction test. Conventional legacy inference does not supply current robust bias correction, weak-IV qualification or multiplicity handling. Search scripts explicitly explore many geographic/cutoff/specification combinations: this records exploration, not a precommitted confirmatory design.

Some sources are unfinished or examples:0h Censo2017 is a partial cleaner; mayersen_graphs retains unadapted Turkish-election examples. Preserve their status.

Comment boundaries matter: working-paper CCPP old programs51–897 and899–1745 are commented; newer programs begin1750 and2143. Household old programs48–303 and305–1153 are commented; newer program starts1157. Individual old estimates51–314 are commented; newer program starts317. Large SAT SISFOH fragments are commented; its distribution branch2082–2087 is active after initialization.

Two preliminary suspicions were rejected rather than reported as defects:

- edad_15mas or hog may resolve by Stata variable abbreviation; they are fragile naming, not proven undefined-variable failures.
- The old poverty index increases with better conditions. An above-index group labeled low poverty is not automatically reversed. Missing-index subgroup inclusion remains a separate concern.

The historical evidence supports targeted correction, explicit mappings and common sample contracts. It does not support modifying the preserved snapshots, choosing a new RD sample/window, or claiming current results invalid without a current-code/data trace.

