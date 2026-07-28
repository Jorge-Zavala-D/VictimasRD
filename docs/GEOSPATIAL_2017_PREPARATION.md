# 2017 centro-poblado geospatial preparation

## Purpose and scope

Section 9 of `code/stata/pipeline/01_data_preparation.do` converts the two
supplied CCPP point shapefiles into Stata spatial data, constructs community
and capital-level distance measures, and merges a lean set of geospatial
attributes into the complete RUV analytical registry.

The raw shapefile components remain immutable in Dropbox Raw. Converted map
files, analytical intermediates, and row-level QA stay in Dropbox Working.
The final data product stays in Dropbox Coded. Git contains only code,
documentation, aggregate metadata, and source checksums.

## Source provenance

The two bundles were downloaded from the GeoGPS Peru page:

- <https://www.geogpsperu.com/2017/08/descarga-gratis-centros-poblados-censo.html>

The page describes the layers as INEI CCPP information. Official INEI 2017
census products also document georeferenced urban and rural CCPP directories
and report 94,922 CCPPs:

- <https://censo2017.inei.gob.pe/productos-censales/>
- <https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1806/files/downloads/Libro.pdf>
- <https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1541/presenta.htm>

These local bundles are nevertheless third-party redistributions, not direct
downloads from an official INEI server. Their identity is locked in
`metadata/geospatial-2017/source-checksums.csv`.

Both `.prj` files declare unprojected WGS 1984 longitude-latitude coordinates.
The complete urban-rural layer has 94,922 unique ten-digit `IDCCPP` records.
The category layer has 94,922 points, of which 90,253 carry valid ten-digit
`CODIGO` values and 4,669 are dispersed-population points coded `0`.

The 90,233 category codes that overlap the complete spine agree with its
coordinates within 0.000001 decimal degree. The complete layer therefore
governs identifiers and geometry; the category layer supplies altitude,
natural region, CCPP category, and directory population only through an exact
ten-digit-code merge. The 4,689 spine records without category enrichment are
retained, while 20 valid category-only codes are quarantined in Dropbox QA.

The embedded shapefile XML shows that GeoGPS calculated `TIPO` in ArcGIS in
July 2023. The analytical `urban_2017` variable uses the underlying numeric
INEI `AREA_CP` field instead. The 16 source records in which these fields
disagree are exported to row-level QA and counted in aggregate metadata.

## Spatial conversion

The pipeline uses Stata's official `spshape2dta` translator rather than the
retired user-written `shp2dta` command:

- <https://www.stata.com/manuals/spspshape2dta.pdf>

Each layer becomes a Stata database file and its linked `_shp.dta` coordinate
file. The database is declared as latitude-longitude with kilometer units.
Because Stata stores the coordinate-file relationship by filename, map code
should open these files from their shared Dropbox Working directory.

The pipeline creates:

- `05_geospatial_ccpp_2017_basic_map.dta` and
  `05_geospatial_ccpp_2017_basic_map_shp.dta`;
- `06_geospatial_ccpp_2017_category_map.dta` and
  `06_geospatial_ccpp_2017_category_map_shp.dta`;
- `07_geospatial_ccpp_2017.dta`, the cleaned 94,922-record spatial source;
- `08_district_capitals_2017.dta`;
- `09_province_capitals_2017.dta`;
- `10_department_capitals_2017.dta`; and
- `11_cities_2017.dta`.

These are data products and therefore remain outside Git.

## Capital and distance definitions

The ten-digit CCPP code has the structure `DDPPDDCCCC`: department, province,
district, and CCPP. The source validates one capital under each rule:

- district capital: `CCCC == 0001` (1,874 records);
- province capital: district `01` and CCPP `0001` (196 records); and
- department capital: province `01`, district `01`, and CCPP `0001`
  (25 records).

The category layer identifies 235 points as `CIUDAD`. They form the candidate
set for the nearest-city measure.

`geodist` calculates distance to the capital corresponding to the CCPP's own
district, province, and department. `geonear, ellipsoid` independently finds
the nearest district capital, province capital, department capital, and
`CIUDAD` point. All distances are straight-line geodesic kilometers on the
WGS 84 ellipsoid. They are not road distance, travel time, or accessibility
measures. A nearest capital may lie outside the CCPP's own administrative
unit.

The pipeline retains raw kilometer measures and `ln(1 + kilometers)`
transformations. The latter are defined at zero distance and avoid the legacy
workflow's arbitrary replacement of zero-distance logarithms.

## RUV linkage

The merge begins from
`05_community_registry_census2007.dta` and never overwrites the authoritative
RUV `ubigeo_ccpp`. It assigns a spatial code in this order:

1. exact current verified CCPP UBIGEO;
2. exact valid 2007 Census CCPP UBIGEO;
3. unique exact normalized full department-province-district-CCPP path; and
4. unique exact normalized CCPP name within the verified district.

Current verified codes take precedence over later candidates. Conflicts and
unmatched RUV records are written to Dropbox Working QA. No fuzzy match is
accepted automatically.

The validated sample flow is versioned in
`metadata/geospatial-2017/sample-flow.csv`. The final file is:

`2 data/3 Coded/1 Current analysis datasets/06_community_registry_geospatial.dta`.

It retains all 5,712 RUV observations and only the spatial variables listed in
`metadata/geospatial-2017/variable-dictionary.csv`.

## Interpretation limits

Coordinates and altitude describe physical location, but the supplied layer's
administrative code vintage is 2017. Historical codes, renamed communities,
boundary changes, mergers, and relocations can affect linkage.

The population, CCPP category, and urban classification are explicitly
2017-vintage attributes. Because collective-reparation projects begin before
2017, these fields are not automatically valid pre-treatment controls. Any
causal specification using them must state and defend their role. Geodesic
distance measures capture spatial separation only and should not be
interpreted as transport cost or service access without additional data.
