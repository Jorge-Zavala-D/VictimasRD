# Metadata

This directory is for versioned metadata without research observations.

Planned metadata products include:

- a logical data inventory with provenance and canonical-snapshot status;
- public external-source checksums and storage locations;
- variable and identifier crosswalks;
- a CCPP fuzzy-match review ledger;
- a merge ledger with declared cardinality and coverage;
- a sample-flow ledger;
- software and Stata-package versions;
- a specification registry; and
- an output manifest linking each table or figure to its script, logical input
  snapshot, specification, software version, generation date, checksum, and
  manuscript destination.

Do not include restricted filenames, paths, checksums, labels, or counts when
they would reveal confidential content. Never place data observations in this
directory.

The `rd-design/` subdirectory contains the approved cutoff registry, index
formula audit, source inventory and checksums, specification registry inputs,
and the compact documentary ledger for the PRC rollout reassessment. These are
non-observation governance records; the complete specification-level Stata
audit remains in the authorized Dropbox Working QA area.

The `gdp-ccpp/` subdirectory records the source identity, aggregate linkage
flow, and variable contract for the Seminario-Palomino estimated CCPP GDP
series. The annual source, row-level linkage, and unmatched records remain in
Dropbox Working.

The `municipal-elections/` subdirectory records the JNE/INFOgob and ONPE source
and documentation inventory and checksums, the aggregate contest and RUV
linkage flow, and the 52-variable analytical contract. Mesa-level returns,
contest-level reconciliations, and row-level RUV linkage records remain in
Dropbox Working.

The `census-2017/` subdirectory records the public-module and assisted-linkage
source roles, the reviewed 807-source-code to 803-RUV crosswalk, the analytical
variable contract, and the aggregate sample flow. Person-, household-, and
row-level linkage QA remain in Dropbox Working; all analytical observations
remain in Dropbox Coded.
