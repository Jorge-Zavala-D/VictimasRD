/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from 2007 Census  |
|					  and define candidates for controls at community level		|
|                                                                               |
|Date Created: 20/08/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import communities dataset with index
	2.	Select Regions of interest
	3.	Analyze cutoff significance for each region
	4.	Characterization of non-compliers
		4.1.	High-index districts hypothesis
		

	5.	Analysis with new dataset

*-------------------------------------------------------------------------------*/

*-----------------------*
*       DIRECTORY       *
*-----------------------*
	clear all
	set more off
	version 13
	
*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"

*-------------------------------------------*
*		Import 2007 Census raw dataset		*
*-------------------------------------------*

use "$a\2 data\communities_sisfoh.dta",clear


*	Check relationship between Index' Cutoff and treatment

tab treated_sisfoh_years Nivel

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -5 |         9         17          0          0          0 |        26 
        -4 |        46         22          0          1          0 |        69 
        -3 |        68         22          0          0          1 |        91 
        -2 |        69         26          1          1          0 |        97 
        -1 |        52         27          1          2          0 |        82 
         0 |        66         46         13          6          4 |       135 
         1 |        57         54         34          8          7 |       160 
         2 |        50         51         57         21          5 |       184 
         3 |        85         83         83         39          1 |       291 
         4 |       160        110         71         34          3 |       378 
         5 |       113         71         42         18          1 |       245 
         6 |        96         26         10          1          0 |       133 
-----------+-------------------------------------------------------+----------
     Total |       871        555        312        131         22 |     1,891 

	Note: No hay un claro corte en el cutoff (Nivel B/C)
*/

tabstat NumeroIndice, by(Nivel) stat(min) 

/* 
 Nivel |       min
-------+----------
     A |     .1538
     B |     .0623
     C |     .0269
     D |     .0152
     E |     .0077
*/
gen cutAB=NumeroIndice - .1538
gen cutBC=NumeroIndice - .0623
gen cutCD=NumeroIndice - .0269
gen cutDE=NumeroIndice - .0152

tab treated_sisfoh_years Departamento

/*
treated_si |                                                            Departamento
sfoh_years |    ANCASH   APURIMAC   AYACUCHO  CAJAMARCA      CUSCO  HUANCAV..    HUANUCO      JUNIN  LA LIBE..       LIMA      PASCO      PIURA |     Total
-----------+------------------------------------------------------------------------------------------------------------------------------------+----------
        -5 |         0          0          0          0          0          0          4         17          0          0          5          0 |        26 
        -4 |         1          3         14          0          2          2          6          9          0          0         19          0 |        69 
        -3 |         0         26         31          0          0          6         11          0          0          0          7          0 |        91 
        -2 |         0         16         28          1          7          0         14          6          0          0         12          0 |        97 
        -1 |         0          7         42          0          1          6          4         13          0          0          0          2 |        82 
         0 |         2         22         30          2          5          8         18          9          2          1          3          0 |       135 
         1 |         0         21         68          0          1          5         14         17          0          5          1          0 |       160 
         2 |         0         12         62          0          3          9         39         38          0          0          5          0 |       184 
         3 |         0         24         71          0          6         22         85         45          0          1          8          2 |       291 
         4 |         1         35        153          0          2         51         43         48          0          1          7          0 |       378 
         5 |         0         40         88          0          5         37         37         24          0          0          1          0 |       245 
         6 |         0         23         79          0          0         30          0          0          0          0          0          0 |       133 
-----------+------------------------------------------------------------------------------------------------------------------------------------+----------
     Total |         4        229        666          3         32        176        275        226          2          8         68          4 |     1,891 


treated_si |           Departamento
sfoh_years |      PUNO  SAN MAR..    UCAYALI |     Total
-----------+---------------------------------+----------
        -5 |         0          0          0 |        26 
        -4 |         7          6          0 |        69 
        -3 |         4          5          1 |        91 
        -2 |         7          5          1 |        97 
        -1 |         6          1          0 |        82 
         0 |        15         13          5 |       135 
         1 |         1         23          4 |       160 
         2 |         4          6          6 |       184 
         3 |         6         13          8 |       291 
         4 |         7         24          6 |       378 
         5 |         2         11          0 |       245 
         6 |         0          1          0 |       133 
-----------+---------------------------------+----------
     Total |        59        108         31 |     1,891 

	
	Note: Los departamentos con más centros poblados beneficiados son:
		1.	Apurimac		(229)
		2.	Ayacucho		(666)
		3.	Huancavelica	(176)
		4.	Huanuco			(275)
		5.	Junin			(226)
		6.	San Martín		(108)

*/

tab treated_sisfoh_years Nivel if Departamento=="APURIMAC"

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -4 |         2          1          0          0          0 |         3 
        -3 |        19          7          0          0          0 |        26 
        -2 |        13          3          0          0          0 |        16 
        -1 |         7          0          0          0          0 |         7 
         0 |        15          7          0          0          0 |        22 
         1 |        12          9          0          0          0 |        21 
         2 |         3          3          4          1          1 |        12 
         3 |         8          4          7          5          0 |        24 
         4 |        14         10          7          3          1 |        35 
         5 |        18         14          4          4          0 |        40 
         6 |        16          6          1          0          0 |        23 
-----------+-------------------------------------------------------+----------
     Total |       127         64         23         13          2 |       229 
*/

tab treated_sisfoh_years Nivel if Departamento=="AYACUCHO"

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -4 |         6          8          0          0          0 |        14 
        -3 |        19         11          0          0          1 |        31 
        -2 |        17         11          0          0          0 |        28 
        -1 |        27         15          0          0          0 |        42 
         0 |        20          6          2          2          0 |        30 
         1 |        32         23         12          1          0 |        68 
         2 |        21         24         13          4          0 |        62 
         3 |        33         24         13          1          0 |        71 
         4 |        84         52         15          2          0 |       153 
         5 |        57         25          5          1          0 |        88 
         6 |        64         10          4          1          0 |        79 
-----------+-------------------------------------------------------+----------
     Total |       380        209         64         12          1 |       666 
*/

tab treated_sisfoh_years Nivel if Departamento=="HUANCAVELICA"

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -4 |         0          2          0          0          0 |         2 
        -3 |         6          0          0          0          0 |         6 
        -1 |         3          3          0          0          0 |         6 
         0 |         1          6          1          0          0 |         8 
         1 |         1          2          0          1          1 |         5 
         2 |         0          3          5          1          0 |         9 
         3 |         4          9          8          1          0 |        22 
         4 |        15         15          9         12          0 |        51 
         5 |        10         10         12          5          0 |        37 
         6 |        16         10          4          0          0 |        30 
-----------+-------------------------------------------------------+----------
     Total |        56         60         39         20          1 |       176 
*/

tab treated_sisfoh_years Nivel if Departamento=="HUANUCO"

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -5 |         0          4          0          0          0 |         4 
        -4 |         3          3          0          0          0 |         6 
        -3 |        10          1          0          0          0 |        11 
        -2 |        11          3          0          0          0 |        14 
        -1 |         2          1          0          1          0 |         4 
         0 |         8          9          1          0          0 |        18 
         1 |         2          6          4          1          1 |        14 
         2 |        10          6         16          7          0 |        39 
         3 |        17         19         30         19          0 |        85 
         4 |        12         10         14          7          0 |        43 
         5 |        13         10         13          1          0 |        37 
-----------+-------------------------------------------------------+----------
     Total |        88         72         78         36          1 |       275 
*/

tab treated_sisfoh_years Nivel if Departamento=="JUNIN"

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -5 |         6         11          0          0          0 |        17 
        -4 |         7          1          0          1          0 |         9 
        -2 |         3          2          0          1          0 |         6 
        -1 |         8          5          0          0          0 |        13 
         0 |         2          4          0          1          2 |         9 
         1 |         5          2          6          3          1 |        17 
         2 |         6         10         13          6          3 |        38 
         3 |        11         14         15          5          0 |        45 
         4 |        26          8         12          2          0 |        48 
         5 |         9          9          4          2          0 |        24 
-----------+-------------------------------------------------------+----------
     Total |        83         66         50         21          6 |       226 
*/

tab treated_sisfoh_years Nivel if Departamento=="SAN MARTIN"

/*
treated_si |                         Nivel
sfoh_years |         A          B          C          D          E |     Total
-----------+-------------------------------------------------------+----------
        -4 |         6          0          0          0          0 |         6 
        -3 |         3          2          0          0          0 |         5 
        -2 |         4          1          0          0          0 |         5 
        -1 |         0          0          0          1          0 |         1 
         0 |         3          4          2          2          2 |        13 
         1 |         2          6         10          1          4 |        23 
         2 |         1          1          2          1          1 |         6 
         3 |         1          1          5          5          1 |        13 
         4 |         3          7          6          6          2 |        24 
         5 |         2          1          3          5          0 |        11 
         6 |         0          0          1          0          0 |         1 
-----------+-------------------------------------------------------+----------
     Total |        25         23         29         21         10 |       108 
*/

rdrobust treated_sisfoh cutBC if Departamento=="APURIMAC", kernel(triangular) scaleregul(0)
rdplot treated_sisfoh cutBC if Departamento=="APURIMAC", kernel(triangular) scaleregul(0)

/*
Outcome: treated_sisfoh. Running variable: cutBC.
--------------------------------------------------------------------------------
            Method |   Coef.    Std. Err.    z     P>|z|    [95% Conf. Interval]
-------------------+------------------------------------------------------------
      Conventional |  .39377     .12989   3.0315   0.002    .139186       .64835
            Robust |     -          -     3.8234   0.000    .284133      .881836
--------------------------------------------------------------------------------
*/

rdrobust treated_sisfoh cutBC if Departamento=="AYACUCHO", kernel(triangular) scaleregul(0)
rdplot treated_sisfoh cutBC if Departamento=="AYACUCHO", kernel(triangular) scaleregul(0)

/*
Outcome: treated_sisfoh. Running variable: cutBC.
--------------------------------------------------------------------------------
            Method |   Coef.    Std. Err.    z     P>|z|    [95% Conf. Interval]
-------------------+------------------------------------------------------------
      Conventional |  .02982     .08286   0.3599   0.719   -.132585      .192219
            Robust |     -          -     -0.1062  0.915   -.255843      .229549
--------------------------------------------------------------------------------
*/

rdrobust treated_sisfoh cutBC if Departamento=="HUANCAVELICA", kernel(triangular) scaleregul(0)
rdplot treated_sisfoh cutBC if Departamento=="HUANCAVELICA", kernel(triangular) scaleregul(0)

/*
Outcome: treated_sisfoh. Running variable: cutBC.
--------------------------------------------------------------------------------
            Method |   Coef.    Std. Err.    z     P>|z|    [95% Conf. Interval]
-------------------+------------------------------------------------------------
      Conventional |  .43268     .20808   2.0794   0.038     .02486        .8405
            Robust |     -          -     2.1447   0.032    .045698      1.01539
--------------------------------------------------------------------------------
*/

rdrobust treated_sisfoh cutBC if Departamento=="HUANUCO", kernel(triangular) scaleregul(0)
rdplot treated_sisfoh cutBC if Departamento=="HUANUCO", kernel(triangular) scaleregul(0)

/*
Outcome: treated_sisfoh. Running variable: cutBC.
--------------------------------------------------------------------------------
            Method |   Coef.    Std. Err.    z     P>|z|    [95% Conf. Interval]
-------------------+------------------------------------------------------------
      Conventional | -.13883     .12609   -1.1010  0.271   -.385961       .10831
            Robust |     -          -     -1.2045  0.228   -.528918      .126263
--------------------------------------------------------------------------------
*/

rdrobust treated_sisfoh cutBC if Departamento=="JUNIN", kernel(triangular) scaleregul(0)
rdplot treated_sisfoh cutBC if Departamento=="JUNIN", kernel(triangular) scaleregul(0)

/*
Outcome: treated_sisfoh. Running variable: cutBC.
--------------------------------------------------------------------------------
            Method |   Coef.    Std. Err.    z     P>|z|    [95% Conf. Interval]
-------------------+------------------------------------------------------------
      Conventional | -.46673     .22187   -2.1036  0.035   -.901577     -.031874
            Robust |     -          -     -2.1936  0.028    -1.0292     -.057889
--------------------------------------------------------------------------------
*/

rdrobust treated_sisfoh cutBC if Departamento=="SAN MARTIN", kernel(triangular) scaleregul(0)
rdplot treated_sisfoh cutBC if Departamento=="SAN MARTIN", kernel(triangular) scaleregul(0)

/*
Outcome: treated_sisfoh. Running variable: cutBC.
--------------------------------------------------------------------------------
            Method |   Coef.    Std. Err.    z     P>|z|    [95% Conf. Interval]
-------------------+------------------------------------------------------------
      Conventional |  .10046     .14341   0.7005   0.484   -.180618      .381531
            Robust |     -          -     1.0367   0.300   -.185179      .601005
--------------------------------------------------------------------------------


	Note: Solo en Apurimac, Huancavelica y Junin hay una diferencia significativa
	entre estar a un lado o al otro del cutoff en la probabilidad de recibir el 
	tratamiento.
*/

*	Generate average index score for each district
bysort ubigeo_dist: egen index_mean_dist=mean(NumeroIndice)

*	Create indicator for elegibility
gen 	eligible=0
replace eligible=1 if Nivel=="A" | Nivel=="B"

*	Create indicator for non-eligible treated community
gen		infiltrate=0
replace infiltrate=1 if treated_sisfoh==1 & eligible==0

tabstat eligible infiltrate, by(Departamento) stat(sum)

/*
Departamento |  eligible  infiltrate
-------------+--------------------
      ANCASH |         4         1
    APURIMAC |       303        41		*13%
    AYACUCHO |       954        90		*9%
   CAJAMARCA |         3         0
       CUSCO |        78         5
HUANCAVELICA |       153        66		*43%
     HUANUCO |       305       119		*39%
       JUNIN |       310        86		*28%
 LA LIBERTAD |         0         0
        LIMA |         6         4
       PASCO |       158         4
       PIURA |         8         0
        PUNO |       117         9
  SAN MARTIN |        85        56		*66%
     UCAYALI |        61         8
-------------+--------------------
       Total |      2545       489
----------------------------------
*/

*	Generate indicator for district with at least 1 infiltrated community
preserve
collapse (sum) infiltrate (mean) index_mean_dist, by(Distrito)
gen dist_infiltrate=0
replace dist_infiltrate=1 if infiltrate>0
ttest index_mean_dist, by(dist_infiltrate)

/*
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. Err.   Std. Dev.   [95% Conf. Interval]
---------+--------------------------------------------------------------------
       0 |     407    .1262414    .0075728    .1527757    .1113546    .1411282
       1 |     267    .0911659    .0049948     .081615    .0813316    .1010002
---------+--------------------------------------------------------------------
combined |     674    .1123465    .0050234    .1304148    .1024831    .1222099
---------+--------------------------------------------------------------------
    diff |            .0350755     .010189                .0150694    .0550816
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t =   3.4425
Ho: diff = 0                                     degrees of freedom =      672

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.9997         Pr(|T| > |t|) = 0.0006          Pr(T > t) = 0.0003

 
	Note: En promedio, los distritos con comunidades infiltradas tienen un 
	indice de victimizacion mayor que los distritos sin comunidades infiltradas
 
 */

restore



use "$a\2 data\community_index_treated_sisfoh.dta",clear

* Check for treatment discontinuity around the threshold

rdrobust treat_13 index_cutBC
rdrobust treat_13 index_cutBC, scaleregul(0)

rdrobust treat_13 index_cutBC if Nivel=="B" | Nivel=="C"
rdrobust treat_13 index_cutBC if Nivel=="B" | Nivel=="C", scaleregul(0)

rdrobust treat_17 index_cutBC
rdrobust treat_17 index_cutBC, scaleregul(0)

rdrobust treat_17 index_cutBC if dpto=="APURIMAC"
rdrobust treat_17 index_cutBC if dpto=="AYACUCHO"
rdrobust treat_17 index_cutBC if dpto=="HUANCAVELICA"
rdrobust treat_17 index_cutBC if dpto=="HUANUCO"
rdrobust treat_17 index_cutBC if dpto=="JUNIN"
rdrobust treat_17 index_cutBC if dpto=="SAN MARTIN"

rdrobust prop_seguro_ninguno index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="APURIMAC", fuzzy(treat_13) vce(cluster cluster_dist) scaleregul(0) kernel(tri)
rdrobust prop_seguro_ninguno index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="APURIMAC", vce(cluster cluster_dist) scaleregul(0) kernel(tri)


rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="APURIMAC"
rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="AYACUCHO"
*rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="HUANCAVELICA"
rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="HUANUCO"
rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="JUNIN"
rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto=="SAN MARTIN"

rdrobust treat_17 index_cutBC if Nivel=="B"| Nivel=="C", scaleregul(0)

rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & dpto_selec==1, scaleregul(0)



*---------------------------------------------------*
*		Testing RD with sisfoh hh level 2013		*
*---------------------------------------------------*

rdrobust sisf_alumbrado_elect index_cutBC if (Nivel=="B" | Nivel=="C") & ///
(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), fuzzy(treat_13) vce(cluster cluster_ccpp)


rdrobust sisf_combust_gas index_cutBC if (Nivel=="B" | Nivel=="C") & ///
(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur prop_combust_gas2007) ///
fuzzy(treat_13) vce(cluster cluster_ccpp)

rdrobust sisf_combust_kerosene index_cutBC if (Nivel=="B" | Nivel=="C") & ///
(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur) fuzzy(treat_13) vce(cluster cluster_ccpp)

rdrobust sisf_combust_carbon index_cutBC if (Nivel=="B" | Nivel=="C") & ///
(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur) fuzzy(treat_13) vce(cluster cluster_ccpp)

rdrobust sisf_combust_lea index_cutBC if (Nivel=="B" | Nivel=="C") & ///
(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), fuzzy(treat_13) vce(cluster cluster_ccpp)


rdrobust sisf_piso_tierra index_cutBC if (Nivel=="B" | Nivel=="C") & ///
(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), fuzzy(treat_13) vce(cluster cluster_ccpp)


* Randomization inference

rdrobust sisf_alumbrado_elect index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016)

rdrobust sisf_combust_gas index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016) covs(urb_rur years_sisfoh13_dumout years_sisfoh13_dumout_dum)

rdrobust sisf_combust_kerosene index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016) covs(urb_rur)

rdrobust sisf_combust_carbon index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016) covs(urb_rur)

rdrobust sisf_combust_lea index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016)





rdrobust sisf_combust_bosta index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016)

rdrobust sisf_piso_tierra index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
fuzzy(treat_13) vce(cluster cluster_ccpp) h(0.016)








*	FOR OUTCOMES AT CCPP LEVEL

use "$a\2 data\community_index_treated_sisfohccpp.dta", clear

global	controls altura_coded distancia_capital prop_a13 ///
		pob_ccpp poverty2007_caracthh poverty2007_servpub poverty2007_demogra
		
		
		
global	table "\Sisfoh 2013 outcomes at CCPP level"
global	dep_ccpp prop_pared_ladrillo prop_pared_piedra prop_pared_adobe	/**
	**/		prop_pared_quincha prop_pared_madera prop_pared_estera 			/**
	**/		prop_piso_parquet prop_piso_lamina prop_piso_loseta 			/**
	**/		prop_piso_tabla prop_piso_cemento prop_piso_tierra 				/**
	**/		prop_agua_redpubdentro prop_agua_redpubfuera prop_agua_pilon 	/**
	**/		prop_agua_pozo prop_agua_rio 				/**
	**/		prop_saneamiento_redpubdentro prop_saneamiento_redpubfuera 				/**
	**/		prop_saneamiento_pozo prop_saneamiento_letrina 						/**
	**/		prop_saneamiento_rio prop_saneamiento_ninguno 						/**
	**/		prop_combust_elect prop_combust_gas  		/**
	**/		prop_combust_carbon prop_combust_lea prop_combust_bosta 		/**
	**/		prop_combust_nococina prop_asset_equipsonido prop_asset_tvcolor	/**
	**/		prop_asset_refri prop_asset_telefonofijo prop_asset_lavadora 	/**
	**/		prop_asset_compu prop_asset_internet prop_asset_cable 			/**
	**/		prop_asset_celular prop_asset_ninguno prop_edad_u1 				/**
	**/		prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 					/**
	**/		prop_edad_45_64 prop_edad_65 edad_15mas prop_edad_15 		/**
	**/		prop_seguro_essalud prop_seguro_sis prop_seguro_ninguno 		/**
	**/		prop_lee_si prop_lee_no prop_educ_ninguno prop_educ_inicial /**
	**/		prop_educ_primaria prop_educ_secundaria prop_educ_tecnica 		/**
	**/		prop_educ_universitaria prop_actividad_agricola 					/**
	**/		prop_actividad_pesquera prop_actividad_minera 						/**
	**/		prop_actividad_comercial prop_actividad_servicios 					/**
	**/		prop_pea_ocupada prop_pea_desocupada



global	dep_ccpp_2007 prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
	**/		prop_pared_quincha2007 prop_pared_madera2007 prop_pared_estera2007 			/**
	**/		prop_piso_parquet2007 prop_piso_lamina2007 prop_piso_loseta2007 			/**
	**/		prop_piso_tabla2007 prop_piso_cemento2007 prop_piso_tierra2007 				/**
	**/		prop_agua_redpubdentro2007 prop_agua_redpubfuera2007 prop_agua_pilon2007 	/**
	**/		prop_agua_pozo2007 prop_agua_rio2007 				/**
	**/		prop_saneamiento_redpubdentro07 prop_saneamiento_redpubfuera07 				/**
	**/		prop_saneamiento_pozo2007 prop_saneamiento_letrina2007 						/**
	**/		prop_saneamiento_rio2007 prop_saneamiento_ninguno2007 						/**
	**/		prop_combust_elect2007 prop_combust_gas2007  		/**
	**/		prop_combust_carbon2007 prop_combust_lea2007 prop_combust_bosta2007 		/**
	**/		prop_combust_nococina2007 prop_asset_equipsonido2007 prop_asset_tvcolor2007	/**
	**/		prop_asset_refri2007 prop_asset_telefonofijo2007 prop_asset_lavadora2007 	/**
	**/		prop_asset_compu2007 prop_asset_internet2007 prop_asset_cable2007 			/**
	**/		prop_asset_celular2007 prop_asset_ninguno2007 prop_edad_u12007 				/**
	**/		prop_edad_1_142007 prop_edad_15_292007 prop_edad_30_442007 					/**
	**/		prop_edad_45_642007 prop_edad_652007 edad_15mas2007 prop_edad_152007 		/**
	**/		prop_seguro_essalud2007 prop_seguro_sis2007 prop_seguro_ninguno2007 		/**
	**/		prop_lee_si2007 prop_lee_no2007 prop_educ_ninguno2007 prop_educ_inicial2007 /**
	**/		prop_educ_primaria2007 prop_educ_secundaria2007 prop_educ_tecnica2007 		/**
	**/		prop_educ_universitaria2007 prop_actividad_agricola2007 					/**
	**/		prop_actividad_pesquera2007 prop_actividad_minera2007 						/**
	**/		prop_actividad_comercial2007 prop_actividad_servicios2007 					/**
	**/		prop_pea_ocupada2007 prop_pea_desocupada2007


putexcel set "$a\3 output\regressions\$table.xls", sheet(1) modify
	putexcel C3 = ("$table")
	sleep 2000
	putexcel D5 = ("RD no/covariates")
	sleep 2000
	putexcel E5 = ("RD w/covariates")
	sleep 2000	
	putexcel F5 = ("RD w/covs. - 2nd grade pol.")
	sleep 2000
	putexcel G5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 2000
	putexcel C5 = ("Control mean")
	sleep 2000

	global cells D E F G H
	
local bl= 0
local i = 5	
foreach y in $dep_ccpp {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 2000
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), over(treat_13) vce(cl cluster_dist) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel C`i'=("`mean'")

	*RD not including covariates
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), fuzzy(treat_13) ///
		vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular) covs(`2007')

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	*RD including covariates - 2nd grade polinome
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) p(2) ///
		kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection - 2nd grade Polynomy
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	
	/*
	*RD including covariates - Treatment: Productive proyects
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust prog_1 index_cutBC if  (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur altura_coded 	///
		lengua_nocastellano_1 edad num_hog poverty2007_caracthh poverty2007_servpub ///
		poverty2007_demogra) fuzzy(treat_13_infra) vce(cluster cluster_ccpp) bwselect(msecomb2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Treatment: Infrastructure proyects
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur_ccpp altura_coded 	///
		lengua_nocastellano_1 edad hog_ccpp poverty2007_caracthh poverty2007_servpub ///
		poverty2007_demogra) fuzzy(treat_13_infra) vce(cluster cluster_ccpp) bwselect(msecomb2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	*/
}







*	FOR OUTCOMES AT HOUSEHOLD LEVEL

use "$a\2 data\community_index_treated_sisfohhog.dta", clear

global	table "\Sisfoh 2013 outcomes at Household level"
global	dep_hog sisf_pared_ladrillo sisf_pared_piedra sisf_pared_adobe 			/**
	**/		sisf_pared_quincha sisf_pared_madera sisf_pared_estera 				/**
	**/		sisf_piso_parquet sisf_piso_lamina sisf_piso_tabla /**
	**/		sisf_piso_cemento sisf_piso_tierra sisf_agua_redpubdentro 			/**
	**/		sisf_agua_redpubfuera sisf_agua_pilon sisf_agua_cisterna 			/**
	**/		sisf_agua_pozo sisf_agua_rio sisf_saneamiento_redpubdentro 			/**
	**/		sisf_saneamiento_redpubfuera sisf_saneamiento_pozo 					/**
	**/		sisf_saneamiento_letrina sisf_saneamiento_rio 						/**
	**/		sisf_saneamiento_ninguno sisf_combust_elect sisf_combust_gas 		/**
	**/		sisf_combust_kerosene sisf_combust_carbon sisf_combust_lea 			/**
	**/		sisf_combust_bosta sisf_asset_equiposonido sisf_asset_tvcolor 		/**
	**/		sisf_asset_refri sisf_asset_telefonofijo sisf_asset_lavadora 		/**
	**/		sisf_asset_compu sisf_asset_internet sisf_asset_cable 				/**
	**/		sisf_asset_celular sisf_asset_ninguno


global	dep_ccpp_2007 prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
	**/		prop_pared_quincha2007 prop_pared_madera2007 prop_pared_estera2007 			/**
	**/		prop_piso_parquet2007 prop_piso_lamina2007  			/**
	**/		prop_piso_tabla2007 prop_piso_cemento2007 prop_piso_tierra2007 				/**
	**/		prop_agua_redpubdentro2007 prop_agua_redpubfuera2007 prop_agua_pilon2007 	/**
	**/		prop_agua_cisterna2007 prop_agua_pozo2007 prop_agua_rio2007 				/**
	**/		prop_saneamiento_redpubdentro07 prop_saneamiento_redpubfuera07 				/**
	**/		prop_saneamiento_pozo2007 prop_saneamiento_letrina2007 						/**
	**/		prop_saneamiento_rio2007 prop_saneamiento_ninguno2007 						/**
	**/		prop_combust_elect2007 prop_combust_gas2007 prop_combust_kerosene2007 		/**
	**/		prop_combust_carbon2007 prop_combust_lea2007 prop_combust_bosta2007 		/**
	**/		prop_asset_equipsonido2007 prop_asset_tvcolor2007							/**
	**/		prop_asset_refri2007 prop_asset_telefonofijo2007 prop_asset_lavadora2007 	/**
	**/		prop_asset_compu2007 prop_asset_internet2007 prop_asset_cable2007 			/**
	**/		prop_asset_celular2007 prop_asset_ninguno2007 


putexcel set "$a\3 output\regressions\$table.xls", sheet(1) modify
	putexcel C3 = ("$table")
	putexcel D5 = ("RD w/covariates")

	global cells D
	
local bl= 0
local i = 4	
foreach y in $dep_hog {	
	local p=1
	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bl=`bl'+1
	
	putexcel B`i'=("`y'")	

	local 2007: word `bl' of $dep_ccpp_2007	
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur altura_coded `2007') ///
		fuzzy(treat_13) vce(cluster cluster_ccpp)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	putexcel `l'`obs' = ("`observ'")
		
}



*	For outcomes at household and individual level

use "$a\2 data\community_index_treated_sisfohhogpers.dta", clear

global	controls urb_rur altura_coded distancia_capital prop_a13 ///
		pob_ccpp poverty2007_caracthh poverty2007_servpub poverty2007_demogra sisf_numperso

global	table "\Sisfoh 2013 outcomes at Household level"
global	dep_hog sisf_pared_ladrillo sisf_pared_piedra sisf_pared_adobe 			/**
	**/		sisf_pared_quincha sisf_pared_madera sisf_piso_parquet 				/**
	**/		sisf_piso_lamina sisf_piso_tabla sisf_piso_cemento sisf_piso_tierra /**
	**/		sisf_techo_paja sisf_techo_teja sisf_techo_madera 					/**
	**/		sisf_techo_concreto sisf_agua_redpubdentro sisf_agua_redpubfuera 	/**
	**/		sisf_agua_pilon sisf_agua_pozo sisf_agua_rio 						/**
	**/		sisf_saneamiento_redpubdentro sisf_saneamiento_redpubfuera 			/**
	**/		sisf_saneamiento_pozo sisf_saneamiento_letrina sisf_saneamiento_rio /**
	**/		sisf_saneamiento_ninguno sisf_combust_elect sisf_combust_gas 		/**
	**/		sisf_combust_lea sisf_combust_bosta sisf_asset_equiposonido 		/**
	**/		sisf_asset_tvcolor sisf_asset_refri sisf_asset_telefonofijo 		/**
	**/		sisf_asset_lavadora sisf_asset_compu sisf_asset_internet 			/**
	**/		sisf_asset_cable sisf_asset_celular sisf_asset_licuadora 			/**
	**/		sisf_asset_plancha sisf_asset_ninguno noescuela_1 prog_1 tiene_prog	/**
	**/		prog_vasoleche_1 prog_comedorpop_1 prog_desalm_1 prog_papyap_1 		/**
	**/		prog_canastaalim_1 prog_juntos_1 prog_techo_1 prog_pension65_1 		/**
	**/		prog_cunamas_1 prog_otro_1 num_prog ratio_prog trabaja_agricola_1	/**
	**/		ratio_trabaja_agricola trabaja_pecuaria_1 ratio_trabaja_pecuaria 	/**
	**/		trabaja_forestal_1 ratio_trabaja_forestal trabaja_pesquera_1 		/**
	**/		ratio_trabaja_pesquera trabaja_minera_1 ratio_trabaja_minera 		/**
	**/		trabaja_artesanal_1 ratio_trabaja_artesanal trabaja_comercial_1 	/**
	**/		ratio_trabaja_comercial trabaja_servicios_1 ratio_trabaja_servicios /**
	**/		trabaja_otro_1 ratio_trabaja_otro trabaja_gobierno_1 				/**
	**/		ratio_trabaja_gobierno analfab_1 seguro_1 num_seguro tiene_seguro 	/**
	**/		ratio_seguro seguro_essalud_1 seguro_sis_1 seguro_ffaapnp_1 		/**
	**/		seguro_privado_1 seguro_otro_1 seguro_ninguno_1 					/**
	**/		nbi1_hogarinadecuado nbi2_hacinamiento nbi3_sindesague 				/**
	**/		nbi4_noescuela nbi5_altadependencia nbi_sum ifh_combust ifh_seguro	/**
	**/		ifh_bienesriqueza ifh_educjefe ifh ratio_hacinamiento 				/**
	**/		ratio_dependencia num_bienesriqueza nivel_educ2 ocupado_1 ocupado 	/**
	**/		ocupacion_dep_1 ratio_ocupacion_dep ocupacion_indep_1 				/**
	**/		ratio_ocupacion_indep ocupacion_trabhog_1 ratio_ocupacion_trabhog 	/**
	**/		ocupacion_famnorem_1 ratio_ocupacion_famnorem ocupacion_desemp_1 	/**
	**/		ratio_ocupacion_desemp ocupacion_hogar_1 ratio_ocupacion_hogar		/**
	**/		ocupacion_estud_1 ratio_ocupacion_estud ocupacion_jubilado_1 		/**
	**/		ratio_ocupacion_jubilado

*global	dep_ccpp_2007 prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
	**/		prop_pared_quincha2007 prop_pared_madera2007 prop_pared_estera2007 			/**
	**/		prop_piso_parquet2007 prop_piso_lamina2007  			/**
	**/		prop_piso_tabla2007 prop_piso_cemento2007 prop_piso_tierra2007 				/**
	**/		prop_agua_redpubdentro2007 prop_agua_redpubfuera2007 prop_agua_pilon2007 	/**
	**/		prop_agua_cisterna2007 prop_agua_pozo2007 prop_agua_rio2007 				/**
	**/		prop_saneamiento_redpubdentro07 prop_saneamiento_redpubfuera07 				/**
	**/		prop_saneamiento_pozo2007 prop_saneamiento_letrina2007 						/**
	**/		prop_saneamiento_rio2007 prop_saneamiento_ninguno2007 						/**
	**/		prop_combust_elect2007 prop_combust_gas2007 prop_combust_kerosene2007 		/**
	**/		prop_combust_carbon2007 prop_combust_lea2007 prop_combust_bosta2007 		/**
	**/		prop_asset_equipsonido2007 prop_asset_tvcolor2007							/**
	**/		prop_asset_refri2007 prop_asset_telefonofijo2007 prop_asset_lavadora2007 	/**
	**/		prop_asset_compu2007 prop_asset_internet2007 prop_asset_cable2007 			/**
	**/		prop_asset_celular2007 prop_asset_ninguno2007 


putexcel set "$a\3 output\regressions\$table.xls", sheet(4) modify
	putexcel C3 = ("$table")
	sleep 2000
	putexcel D5 = ("RD no/covariates")
	sleep 2000
	putexcel E5 = ("RD w/covariates")
	sleep 2000	
	putexcel F5 = ("RD w/covs. - 2nd grade pol.")
	sleep 2000
	putexcel G5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 2000
	putexcel C5 = ("Control mean")
	sleep 2000

	global cells D E F G H
	
local bl= 0
local i = 5	
foreach y in $dep_hog {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 2000
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), over(treat_13) vce(cl cluster_dist) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel C`i'=("`mean'")

	*RD not including covariates
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	*RD including covariates - 2nd grade polinome
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) p(2) ///
		kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection - 2nd grade Polynomy
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	
	/*
	*RD including covariates - Treatment: Productive proyects
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust prog_1 index_cutBC if  (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur altura_coded 	///
		lengua_nocastellano_1 edad num_hog poverty2007_caracthh poverty2007_servpub ///
		poverty2007_demogra) fuzzy(treat_13_infra) vce(cluster cluster_ccpp) bwselect(msecomb2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Treatment: Infrastructure proyects
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur_ccpp altura_coded 	///
		lengua_nocastellano_1 edad hog_ccpp poverty2007_caracthh poverty2007_servpub ///
		poverty2007_demogra) fuzzy(treat_13_infra) vce(cluster cluster_ccpp) bwselect(msecomb2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	*/
}




*	For women outcomes at individual level

use "$a\2 data\community_index_treated_sisfohpers_women.dta", clear

global	controls urb_rur altura_coded distancia_capital prop_a13 ///
		pob_ccpp poverty2007_caracthh poverty2007_servpub poverty2007_demogra sisf_numperso

global table "\Sisfoh 2013 outcomes at Individual level"

global	dep_ind nivel_educ2 gestante analfab jefa_hogar ocupado 				/**
	**/	edad_6_12_noescuela trabaja_agricola trabaja_pecuaria 	/**
	**/  trabaja_minera trabaja_artesanal trabaja_comercial		/**
	**/	trabaja_servicios trabaja_otro trabaja_gobierno trabaja_otro2 seg_essalud 			/**
	**/	seg_ffaapnp seg_privado seg_otro2 seg_ninguno		/**
	**/	num_seguro_ind tiene_seguro prog_vasoleche prog_comedorpop prog_desalm	/**
	**/	prog_papyap prog_canastaalim prog_juntos prog_pension65	prog_otro2	/**
	**/ prog_ninguno num_prog_ind tiene_prog 			/**
	**/ ocupacion_dep ocupacion_indep ocupacion_famnorem		/**
	**/ ocupacion_desemp ocupacion_hogar ocupacion_estud ocupacion_otro2

	* trabaja_forestal trabaja_pesquera 
	* prog_techo prog_cunamas prog_otro
	* seg_sis seg_otro 
	* ocupacion_trabhog ocupacion_jubilado
	
putexcel set "$a\3 output\regressions\$table.xls", sheet("Women outcomes") modify
	putexcel C3 = ("$table")
	sleep 2000
	putexcel D5 = ("RD no/covariates")
	sleep 2000
	putexcel E5 = ("RD w/covariates")
	sleep 2000	
	putexcel F5 = ("RD w/covs. - 2nd grade pol.")
	sleep 2000
	putexcel G5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 2000
	putexcel C5 = ("Control mean")
	sleep 2000

	global cells D E F G H
	
local bl= 0
local i = 5	
foreach y in $dep_ind {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 2000
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), over(treat_13) vce(cl cluster_dist) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel C`i'=("`mean'")

	*RD not including covariates
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	*RD including covariates - 2nd grade polinome
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) p(2) ///
		kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection - 2nd grade Polynomy
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	
	/*
	*RD including covariates - Treatment: Productive proyects
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust prog_1 index_cutBC if  (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur altura_coded 	///
		lengua_nocastellano_1 edad num_hog poverty2007_caracthh poverty2007_servpub ///
		poverty2007_demogra) fuzzy(treat_13_infra) vce(cluster cluster_ccpp) bwselect(msecomb2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Treatment: Infrastructure proyects
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(urb_rur_ccpp altura_coded 	///
		lengua_nocastellano_1 edad hog_ccpp poverty2007_caracthh poverty2007_servpub ///
		poverty2007_demogra) fuzzy(treat_13_infra) vce(cluster cluster_ccpp) bwselect(msecomb2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 2000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 2000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	*/
}








