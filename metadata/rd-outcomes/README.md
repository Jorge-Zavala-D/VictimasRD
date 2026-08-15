# RD outcome metadata

`outcome-registry.csv`, `outcome-registry-2013-household.csv`, and
`outcome-registry-2013-individual.csv` are the authoritative non-observation
registries for the 2013 CCPP, household, and individual outcome modules. Each
row declares one outcome before estimation, including its family, reporting
tier, multiplicity family, transformation, display scale, denominator,
source, and intended paper role.

The Stata module validates every declared variable and generates the LaTeX
registry and result exhibits. Do not add an outcome directly to an estimation
loop: add and document it here first. Quality and linkage indicators are not
substantive outcomes; their continuity belongs in the RD-validation module.
Post-treatment measures may be outcomes or explicitly labeled mechanisms but
must never enter the ordinary control set. The household registry fixes eight
primary outcomes, 42 secondary outcomes, and three connectivity mechanisms.
Its primary models give every eligible RUV community equal total weight;
household-equal estimates are a different population-weighted sensitivity,
not a substitute main specification.

The individual registry fixes eight primary outcomes on one complete sample
of persons age 14 or older and 55 secondary outcomes with explicit age-, sex-,
labor-force-, or item-valid denominators. Its primary models give every
eligible RUV community equal total weight; person-equal estimates are a
different population-weighted sensitivity. The child schooling outcome is an
attainment-based proxy because SISFOH does not report current enrollment.
