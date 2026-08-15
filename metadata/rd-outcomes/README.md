# RD outcome metadata

`outcome-registry.csv` is the authoritative non-observation registry for the
2013 CCPP outcome module. Each row declares one outcome before estimation,
including its family, reporting tier, multiplicity family, transformation,
display scale, denominator, source, and intended paper role.

The Stata module validates every declared variable and generates the LaTeX
registry and result exhibits. Do not add an outcome directly to an estimation
loop: add and document it here first. Quality and linkage indicators are not
substantive outcomes; their continuity belongs in the RD-validation module.
Post-treatment measures may be outcomes or explicitly labeled mechanisms but
must never enter the ordinary control set.

