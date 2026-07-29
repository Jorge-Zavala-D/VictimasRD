# Victimization-index formula audit

**Date:** 2026-07-28  
**Status:** diagnostic reconstruction; the supplied RUV score and category
remain authoritative.

## Purpose

This audit tests whether the variables in the original RUV Libro Segundo
workbook reproduce the victimization-index method described in the government
note `2 data/0 Support documents/Indice_Nivel_Afectacion.pdf`. It is a source
integrity check, not a new index definition.

## Authoritative documented method

The government note describes four standardized pillars:

1. victims;
2. institutional disruption;
3. destroyed family infrastructure; and
4. destroyed communal infrastructure.

Each pillar is min--max standardized, zeros are replaced by the respective
composite's smallest positive value, and the final index is the geometric mean
of the four standardized pillars. The note also discusses z-score
standardization as an alternative, but identifies min--max standardization as
the selected method.

The official category boundaries are:

| Boundary | Threshold |
|---|---:|
| A--B | 0.153750 |
| B--C | 0.062320 |
| C--D | 0.026930 |
| D--E | 0.015220 |

These thresholds are binding for the project. The cutoff registry records the
source and decision.

## Available source fields

The original workbook contains 5,712 observations, 25 columns, and no Excel
formulas. It supplies the final score to four decimal places and the RUV
category. It includes five individual victim counts, three authority counts,
and already-aggregated measures of destroyed family and communal assets.

The workbook does not contain:

- the seven disaggregated family-asset inputs shown in the government note;
- the four disaggregated communal-asset inputs;
- the historical reference population or maxima used to normalize each
  pillar;
- an operational rule for rounding or capping the final score; or
- a calculation sheet or formula provenance.

Those omissions prevent a fully independent, byte-for-byte reconstruction of
the original administrative calculation.

The exact methodology PDF and workbook audited here are identified by SHA-256
checksum in `metadata/rd-design/index-source-checksums.csv`. A future source
replacement must be treated as a new vintage and re-audited, not silently
substituted.

## Empirical reconstruction

The source score is most consistent with the following raw pillars:

- victims = deaths + disappearances + torture + widowed + orphaned;
- institutional disruption = authorities killed + authorities disappeared +
  authorities displaced;
- destroyed family assets = the workbook aggregate; and
- destroyed communal assets = the workbook aggregate.

Among observations with all four pillars positive, a log-linear regression of
the source score on these four pillars has an R-squared of 0.9687 and estimated
elasticities of 0.2375, 0.2248, 0.2388, and 0.2330. These are close to the 0.25
elasticity implied by an equal-weight geometric mean. Adding displaced
persons as a fifth pillar produces an elasticity of approximately 0.003 and
does not improve the fit.

Replacing zero pillars with one is consistent with the note because one is
the smallest positive observed value for each available pillar. The resulting
geometric mean is:

```text
G = [max(victims,1) * max(institutional,1)
     * max(family assets,1) * max(communal assets,1)]^(1/4)
```

The source scores imply a common scale factor of approximately 0.01018123.
This factor is empirically inferred from the workbook; it is not an official
normalization constant and cannot identify the four historical pillar maxima
separately.

Using `min(1, 0.01018123 * G)` reproduces 4,925 of 5,712 supplied scores
(86.22%) to the workbook's four-decimal precision. The uncapped version
reproduces 4,857 scores (85.03%). Seventy-two source scores equal exactly one;
71 of them have an uncapped reconstruction above one, which is strong evidence
of administrative capping for most high-index observations.

Seven supplied scores exceed one. Three match the uncapped reconstruction to
four decimals, while four do not. The mixed behavior suggests different
calculation vintages, later component updates, or manual administrative
corrections; it does not support silently applying one new rule to every row.

## Rounding and category assignment

All supplied scores lie on a four-decimal grid, while the official thresholds
are stated to six decimals. Apparent problems in the earlier range audit are
mostly precision artifacts:

- 189 scores equal 0.0077, the four-decimal representation of the official
  minimum 0.007740;
- 72 apparent source-category disagreements occur at rounded cutoff values;
- the stored value 0.0623 appears in both categories B and C; and
- only one category-score conflict occurs away from a rounding boundary:
  RUV `S09000408`, source category D, supplied score 0.0300.

For that record, the inferred formula yields approximately 0.0228, which is
consistent with category D. The evidence is more consistent with a discrepant
stored score than with an incorrect source category.

Because the rounded numerical score cannot uniquely recover assignment, the
RUV-supplied category is authoritative for category and side-of-boundary
classification. Centered running variables retain the supplied continuous
score and must not be used to overwrite the source category.

## Canonical implementation

The data-preparation pipeline:

- preserves `victimization_index` and `victimization_level_source`;
- creates `running_ab`, `running_bc`, `running_cd`, and `running_de` using the
  exact official thresholds;
- writes row-level formula discrepancies only to Dropbox Working QA;
- records aggregate, non-observation audit counts in Git metadata; and
- drops all formula-reconstruction helpers from released analytical data.

No formula-derived score or category replaces a supplied RUV value.

## Remaining source request

A complete reconstruction requires the operational **Protocolo de Nivel de
Afectación**, including its reference population, pillar maxima, component
aggregation rules, rounding/capping rules, calculation date, and amendment
history. An immutable earlier administrative calculation workbook would also
allow the project to distinguish source-vintage changes from file corruption.
