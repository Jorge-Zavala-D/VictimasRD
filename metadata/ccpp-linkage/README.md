# CCPP linkage adjudication

This directory holds the versioned, disclosure-reviewed identifier crosswalks
needed to reproduce non-exact community linkages. It must contain identifiers
and linkage evidence only—never victimization values, treatment outcomes,
person- or household-level data, testimony, or restricted administrative
content.

## Files

- `ruv-ubigeo-adjudication.csv` maps a public RUV community identifier to an
  adjudicated ten-digit CCPP UBIGEO.
- `cman-ruv-adjudication.csv` maps a CMAN PDF record number to one RUV
  community identifier.

The authoritative Stata preparation program must validate every row before
applying it. At minimum:

- source keys must be unique;
- CCPP codes must contain exactly ten digits;
- a current code must exist in the authoritative INEI spine;
- its six-digit prefix must equal the RUV district code;
- referenced RUV and CMAN records must exist;
- two accepted rows may not produce an unintended many-to-one link; and
- `review_status` must equal `accepted`.

Candidate scores alone are not admissible evidence. `evidence_source` and
`evidence_locator` must identify the official or corroborating source used for
the row-level decision. Historical codes must be labeled with their actual
vintage and must not be presented as current 2017 codes.

