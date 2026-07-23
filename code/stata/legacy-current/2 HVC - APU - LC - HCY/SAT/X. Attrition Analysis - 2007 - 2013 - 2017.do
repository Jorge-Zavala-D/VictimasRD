/*------------------------------------------------------------------------------*
| 																				|
| Title: X. Attrition Analysis - 2007 - 2013 - 2017								|
|																				|
| Project: 			RD V’ctimas												    |
| Creator: 			Matthew Bird, 11/11/2020									|
| Last modifier: 	Matthew Bird, 11/11/2020									|
| 																				|
| Data In: 			community_index_treated_cpv2017ind							|
| Data Out: 		Attrition analysis tables									|
|																				|
|																				|
| Description:		Import cleaned and merge dataset to perform an attrition	|
|					analysis. Attrition of baseline and midline data will be 	|
|					explained using the treatment dummy and a set of controls.  |
|					dofile will explore interactions. Two levels of attrition:	|
|					a. Missing 2013 to 2017, b. Migration 2013 to 2017. Third	|
|					level consists of demographcic differences found in 2013	|
*-------------------------------------------------------------------------------*/

version 13
set more off
clear all

*-----------------------*
*       DIRECTORY       *
*-----------------------*

*Setting file path
*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\jzavala\Dropbox\VictimasRD"
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"
*global a "/Users/matthewbird/Dropbox/VictimasRD"

use "$a/2 data/3 Coded/community_index_treated_cpv2017ind.dta", clear

*-------------------------------------------------------------*
*       Generate dummy variables out of factor variables      *
*-------------------------------------------------------------*


*----------------------------------------------*
*       Generate results and export tables     *
*----------------------------------------------*


global controls altitude_msnm log_distancia_capital prop_a13 /**
		**/ log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010 /**
		**/ sex_2017 edad_2017 analfab_2017 nivel_educ_2017 ocupado_2017 jefe_hogar_2017
		
global controls2 altitude_msnm log_distancia_capital prop_a13 /**
		**/ log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010 /**
		**/ sex_2017 edad_2017 analfab_2017 nivel_educ_2017 ocupado_2017 jefe_hogar_2017
		
global controls3 altitude_msnm log_distancia_capital prop_a13 /**
		**/ log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010 /**
		**/ sex_2017 edad_2017 analfab_2017 nivel_educ_2017 ocupado_2017 jefe_hogar_2017
		
global controls4 altitude_msnm log_distancia_capital prop_a13 /**
		**/ log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010 /**
		**/ sex_2017 edad_2017 analfab_2017 nivel_educ_2017 ocupado_2017 jefe_hogar_2017
		
global controls5 altitude_msnm log_distancia_capital prop_a13 /**
		**/ log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010 /**
		**/ sexo01 edad01 niv01
		
global controls6 altitude_msnm log_distancia_capital prop_a13 /**
		**/ log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010 /**
		**/ sexo01 edad01 niv01
	
local cont = 0					
	foreach i of global controls {
		local controles `controles' `i'
		probit migracion treat_17 `controles' if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist) 
		if `cont' == 0 {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015.xls", replace dec(3) label keep(treat_17 $controles) addstat(Pseudo R-squared, `e(r2_p)')
		}
		else {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015.xls", append dec(3) label keep(treat_17 $controles) addstat(Pseudo R-squared, `e(r2_p)')
			sleep 3000
		}
		local cont = `cont' + 1
	}
	
local cont2 = 0					
	foreach i of global controls2 {
		local controles `controles' `i'
		probit migracion treat_17 `controles' if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist) 
		if `cont2' == 0 {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015_nocaps.xls", replace dec(3) label keep(treat_17 $controles2) addstat(Pseudo R-squared, `e(r2_p)')
		}
		else {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015_nocaps.xls", append dec(3) label keep(treat_17 $controles2) addstat(Pseudo R-squared, `e(r2_p)')
			sleep 3000
		}
		local cont2 = `cont2' + 1
	}
	a
	local cont3 = 0					
	foreach i of global controls3 {
		local controles `controles' `i'
		probit migracion treat_17 `controles' if (index_cutBC>-0.010 & index_cutBC<0.010) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist) 
		if `cont3' == 0 {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_010.xls", replace dec(3) label keep(treat_17 $controles3) addstat(Pseudo R-squared, `e(r2_p)')
		}
		else {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_010.xls", append dec(3) label keep(treat_17 $controles3) addstat(Pseudo R-squared, `e(r2_p)')
			sleep 3000
		}
		local cont3 = `cont3' + 1
	}
local cont4 = 0					
	foreach i of global controls4 {
		local controles `controles' `i'
		probit migracion treat_17 `controles' if (index_cutBC>-0.010 & index_cutBC<0.010) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist) 
		if `cont4' == 0 {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_010_nocaps.xls", replace dec(3) label keep(treat_17 $controles4) addstat(Pseudo R-squared, `e(r2_p)')
		}
		else {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_010_nocaps.xls", append dec(3) label keep(treat_17 $controles4) addstat(Pseudo R-squared, `e(r2_p)')
			sleep 3000
		}
		local cont4 = `cont4' + 1
	}
local cont5 = 0					
	foreach i of global controls5 {
		local controles `controles' `i'
		probit desgaste treat_17 `controles' if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist) 
		if `cont5' == 0 {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015_missing.xls", replace dec(3) label keep(treat_17 $controles5) addstat(Pseudo R-squared, `e(r2_p)')
		}
		else {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015_missing.xls", append dec(3) label keep(treat_17 $controles5) addstat(Pseudo R-squared, `e(r2_p)')
			sleep 3000
		}
		local cont5 = `cont5' + 1
	}
local cont6 = 0					
	foreach i of global controls6 {
		local controles `controles' `i'
		probit desgaste treat_17 `controles' if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist) 
		if `cont6' == 0 {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015_missing_nocaps.xls", replace dec(3) label keep(treat_17 $controles6) addstat(Pseudo R-squared, `e(r2_p)')
		}
		else {
			outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_simple_015_missing_nocaps.xls", append dec(3) label keep(treat_17 $controles6) addstat(Pseudo R-squared, `e(r2_p)')
			sleep 3000
		}
		local cont6 = `cont6' + 1
	}
*foreach i of global controls {
*	gen int_`i' = `i' * treat_17
*	global controls_int $controls_int int_`i'
*	}
*logit migracion treat_17 $controls $controls_int if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
*outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_interactions.xls", replace dec(3) label keep(treat_17 `controls_baseline' `controls_int') addstat(Pseudo R-squared, `e(r2_p)')

probit migracion treat_17 $controles if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
xi: probit migracion treat_17 i.treat_17*$controls if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_interactions_015_migration.xls"

probit migracion treat_17 $controles if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist)
xi: probit migracion treat_17 i.treat_17*$controls if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_interactions_015_migration_nocaps.xls"

probit desgaste treat_17 $controles5 if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
xi: probit desgaste treat_17 i.treat_17*$controls5 if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_interactions_015_missing.xls"

probit desgaste treat_17 $controles5 if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist)
xi: probit desgaste treat_17 i.treat_17*$controls5 if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), cluster(cluster_dist)
outreg2 using "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/attrition_interactions_015_missing_nocaps.xls"
