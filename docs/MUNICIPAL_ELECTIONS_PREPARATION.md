# Municipal election data preparation

## Purpose and status

Section 11 of `code/stata/pipeline/01_data_preparation.do` is the canonical
municipal-election preparation block. It converts the 2002 and 2006 JNE/
INFOgob district and provincial modules into local political-context measures,
replaces annulled district contests with the 2003 and 2007 complementary
elections, validates the 2006 ordinary results against official ONPE
mesa-by-list returns, and links the resulting municipal exposures to every row
of the RUV community registry.

The current coded output is stored outside Git at:

`$analysis_data_root/08_community_registry_elections.dta`

It contains all 5,712 RUV rows and 52 retained electoral variables. Row-level
linkage and reconciliation records remain under Dropbox Working. No electoral
microdata or research observations are stored in Git.

## Research interpretation

The election variables describe the municipality governing each community.
They are not centro-poblado-level electoral outcomes. Every community within a
municipal jurisdiction therefore shares the same election values, and any
model using these measures must account for that assignment level.

The main political-alignment measure is `mayor_apra_2006`: whether the mayor
elected for the 2007--2010 municipal term represented the Partido Aprista
Peruano. It is a plausible descriptive correlate of administrative access
during Alan Garcia's national government, but it is not assumed to be random,
an instrument, or a treatment. The pipeline also retains the 2002-cycle APRA
indicator, the broader type of winning political organization, turnout,
competition, candidate and electorate composition, and selected pre-program
municipal-governance measures.

For a province-capital district, the governing contest is the provincial
municipal election; for every other district it is the district municipal
election. This follows the institutional jurisdiction in Article 3 of Peru's
Organic Law of Municipalities: the provincial municipality covers the
province and the district of the *cercado*. The assignment is therefore based
on governing jurisdiction rather than mechanically attaching both election
levels to every community.

## Source contract

### JNE/INFOgob modules

The pipeline requires six modules for each combination of cycle (2002 and
2006) and scope (district and province), for 24 workbooks in total:

- `Resultados`: registered electors, ballots, valid votes, list votes, and
  organization type;
- `Autoridades`: proclaimed mayor and winning organization;
- `Candidatos`: mayoral-candidate roster, sex, and young-candidate flag;
- `Padron`: electorate size and sex, youth, and older-than-70 composition;
- `ISP`: INFOgob political-system indicators and geographic keys; and
- `FPL`: local political and authority-stability indicators.

The proclaimed-authority module is authoritative for the winner. The raw
plurality calculation is retained as a check and does not override an
authority record when top votes are tied. Candidate files are restricted to
mayoral candidates before composition measures are calculated. The `Nativo`
field is not released because it is effectively unpopulated in these source
files.

### ONPE results and documentation

ONPE's official open-data records and dictionaries define the mesa-level
fields used here: election geography, mesa status, political organization,
votes, eligible electors, blank votes, null votes, and challenged votes. The
project-local package metadata and dictionaries are stored under:

`$data_root/0 Support documents/ONPE-JNE municipal elections 1998-2006`

The primary official catalog records are:

- [Municipal district results, 2002](https://www.datosabiertos.gob.pe/dataset/resultados-por-mesa-de-las-elecciones-municipales-distritales-2002-oficina-nacional-de)
- [Municipal provincial results, 2002](https://www.datosabiertos.gob.pe/dataset/resultados-por-mesa-de-las-elecciones-municipales-provinciales-2002-oficina-nacional-de)
- [Municipal district results, 2006](https://www.datosabiertos.gob.pe/dataset/resultados-por-mesa-de-las-elecciones-municipales-distritales-2006-oficina-nacional-de)
- [Municipal provincial results, 2006](https://www.datosabiertos.gob.pe/dataset/resultados-por-mesa-de-las-elecciones-municipales-provinciales-2006-oficina-nacional-de)
- [Complementary municipal results, 2003](https://www.datosabiertos.gob.pe/dataset/resultados-por-mesa-de-las-complementarias-2003-oficina-nacional-de-procesos-electorales)
- [Complementary municipal results, 2007](https://www.datosabiertos.gob.pe/dataset/resultados-por-mesa-de-las-complementarias-2007-oficina-nacional-de-procesos-electorales)

The dedicated 2007 complementary CSV supplied by the research team has the
same mesa-by-list structure and is validated in Stata before use. ONPE's
catalog lists a dedicated dictionary, but it was not present in the acquired
support-document bundle and remains a documented archival gap.
Several ONPE municipal dictionaries also retain a generic boilerplate
description of `TIPO_ELECCION` that mentions presidential and congressional
elections. The observed field values and dataset titles identify the municipal
scope; the pipeline does not use that boilerplate sentence as a classifier.

The official 2006 ZIP files remain immutable in Dropbox Raw. Their extracted
CSVs are synchronized prerequisites in Dropbox Working staging; the Stata
master validates and reads them but never invokes a ZIP extractor, Python,
PowerShell, or another external conversion process.
The official 2002 distributions are already CSV files and are read directly
from immutable Dropbox Raw for a diagnostic reconciliation.

### Geography

Election files use six-digit RENIEC codes. The official `TB_UBIGEOS.csv`
bridge maps them to six-digit INEI district codes. All 1,892 nonmissing bridge
records are unique by RENIEC code. Name-based mappings are used only to connect
INFOgob modules to an official code and are resolved within exact department,
province, and district paths.

Historical exceptions are explicit:

- simple documented name aliases reconcile four INFOgob spellings;
- the 2002 Alto Amazonas districts that later formed Datem del Maranon retain
  their historical contest geography;
- Barranca uses its 2002 district contest because the later province did not
  yet exist; and
- Manantay had no ordinary 2002 or 2006 election, so its four RUV communities
  receive the Calleria exposure for the predecessor municipality.

The predecessor assignment is preserved in
`17_ruv_municipal_election_links.dta`; it is not carried as an auxiliary field
in the final analytical dataset.

## Construction rules

1. Source names are normalized for case, Unicode diacritics, punctuation, and
   repeated whitespace. No fuzzy electoral match is accepted.
2. Organization-level valid votes are aggregated within each contest.
   Winner share, runner-up margin, top-two concentration, HHI, and effective
   number of lists are computed from valid-vote shares.
3. Turnout is ballots cast divided by registered electors. The invalid-vote
   share includes blank, null, and challenged votes.
4. Proclaimed authorities resolve any top-vote tie. Their vote totals must
   equal the computed top vote count.
5. Winning organizations are classified as national party, electoral
   alliance, regional movement, or local political organization. APRA is
   identified only by the normalized official name `PARTIDO APRISTA PERUANO`.
6. The 13 annulled 2002 district contests are replaced by 2003 complementary
   results; the 22 annulled 2006 contests are replaced by 2007 results.
7. Candidate-demographic measures come only from the matching ordinary-cycle
   roster. They are missing for complementary contests rather than being
   imputed from a different year.
8. FPL outcomes for the 2003--2006 term are retained because they precede
   collective-reparation rollout. The analogous 2007--2010 governance outcomes
   are post-treatment for some communities and remain in Working only.
9. Exact district UBIGEO linkage is primary. The final RUV universe is never
   reduced because of election linkage.

## Validation results

The executable checks establish:

- 1,635 district and 194 provincial ordinary contests in 2002;
- 1,637 district and 195 provincial ordinary contests in 2006;
- 13 complementary replacements in 2003 and 22 in 2007;
- all proclaimed-mayor vote totals equal the computed top vote total;
- computed competition measures agree with INFOgob ISP values to the source's
  approximately 0.0005 rounding precision;
- the acquired 2002 ONPE files cover 1,773 non-complementary INFOgob contests,
  omit 43 such contests, and contain the 13 contests replaced by the 2003
  complementary election; four matched contests have at least one differing
  total or statistic and remain explicit source issues;
- all 1,810 non-complementary 2006 contests reproduce ONPE electorate,
  turnout, invalid-vote share, winning share, top-two share, margin, and HHI to
  machine precision (maximum absolute difference `1.11e-16`); and
- all 5,712 RUV rows, including all 1,162 rows in `sample_main_rd`, link to
  both election cycles.

INFOgob contains nine 2002-cycle and eight 2006-cycle cases in which the
normalized proclaimed winner organization is absent from the corresponding
mayoral-candidate roster. These are recorded as source issues; the proclaimed-
authority module remains the winner authority and the inconsistencies do not
change any winner or vote total.

Aggregate results are versioned in
`metadata/municipal-elections/sample-flow.csv`. Source identities and SHA-256
hashes are recorded in `source-checksums.csv`; the reviewed documentation
families and the missing 2007 dictionary are recorded in
`documentation-inventory.csv`. Complete contest-level and RUV linkage QA
remains in Dropbox Working:

- `15_municipal_elections_2002.dta`;
- `16_municipal_elections_2006.dta`;
- `17_ruv_municipal_election_links.dta`;
- `municipal_election_isp_reconciliation.{dta,csv}`;
- `municipal_election_onpe_2002_reconciliation.{dta,csv}`;
- `municipal_election_onpe_2006_reconciliation.{dta,csv}`; and
- `municipal_election_unmatched_ruv.{dta,csv}`.

## Timing and inference cautions

- The 2006 cycle is pre-program for ordinary contests, but the 22 replacement
  results were observed in 2007. Variables based on those replacement results
  must be treated as timing-sensitive; `elect_result_year_2006` and
  `elect_complementary_2006` identify them.
- Municipal fields are repeated across RUV communities. Community-level
  regressions must not treat those repeated values as independently assigned.
- Political alignment may proxy for local political preferences, state
  capacity, conflict history, or administrative access. Its association with
  treatment timing is descriptive unless a separate identification strategy
  is approved.
- The 1998 municipal results and the 2001--2006 revocation or other special
  election files were inspected but are outside the declared comparable
  2002/2006 INFOgob module contract. They remain immutable in Dropbox Raw for
  a future political-economy extension; they are not silently pooled into the
  current paper's covariates.
