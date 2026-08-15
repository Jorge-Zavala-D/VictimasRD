# RD outcome metadata

`outcome-registry.csv` and `outcome-registry-2013-household.csv` are the
authoritative non-observation registries for the 2013 CCPP and household
outcome modules. Each row declares one outcome before estimation, including
its family, reporting tier, multiplicity family, transformation, display
scale, denominator, source, and intended paper role.

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
