# RD outcome metadata

`outcome-registry.csv`, `outcome-registry-2013-household.csv`, and
`outcome-registry-2013-individual.csv` are the authoritative non-observation
registries for the 2013 modules. Their `outcome-registry-2017-*.csv`
counterparts declare the Census 2017 CCPP, source-household, and person-level
outcomes. Each
row declares one outcome before estimation, including its family, reporting
tier, multiplicity family, transformation, display scale, denominator,
source, and intended paper role.

The Stata module validates every declared variable and generates the LaTeX
registry and result exhibits. Do not add an outcome directly to an estimation
loop: add and document it here first. Quality and linkage indicators are not
substantive outcomes; the 2017 modules report them separately as design and
selection diagnostics rather than mixing them into outcome families.
Post-treatment measures may be outcomes or explicitly labeled mechanisms but
must never enter the ordinary control set. The 2017 household registry fixes
eight primary outcomes, 25 secondary outcomes, and three connectivity
mechanisms. The 2017 CCPP registry contains eight primary outcomes plus 31
secondary, exploratory, and mechanism entries; the 2017 individual registry
contains eight primary outcomes plus 43 secondary, exploratory, and mechanism
entries. Primary household and person models give every eligible RUV
community equal total weight; observation-equal estimates target a different
population and are sensitivities, not substitute main specifications.

The 2017 registries preserve migration as a substantive outcome while keeping
internet and connectivity explicitly in the mechanism tier. They never recode
non-linkage as observed migration. The legacy moved-or-not-linked composite
and its complementary all-unlinked-stay bound are registered only as
exploratory selection sensitivities. Causal mediation and heterogeneity are
outside these main-effect registries and require separate protocols.

The 2013 individual registry fixes eight primary outcomes on one complete sample
of persons age 14 or older and 55 secondary outcomes with explicit age-, sex-,
labor-force-, or item-valid denominators. Its primary models give every
eligible RUV community equal total weight; person-equal estimates are a
different population-weighted sensitivity. The child schooling outcome is an
attainment-based proxy because SISFOH does not report current enrollment.
