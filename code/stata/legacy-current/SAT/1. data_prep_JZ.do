/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports, cleans and prepares data from			|
|					  Victimization Index and Financed communities 				|
|                                                                               |
|Date Created: 23/08/2018			 					                        |										          
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

*-------------------------------------------------------------------------------*/

*-----------------------*
*       DIRECTORY       *
*-----------------------*
	clear all
	set more off
	version 13
	
	*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
	*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD\"
	*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
	*global a "/Users/bruno_esposito/Dropbox/Proyectos/Matthew/VictimasRD"
	global a "D:\Dropbox\VictimasRD"
/*-----------------------------------------------*
*		Import Victimization Index dataset		*
*-----------------------------------------------*

import excel "$a\2 data\1 Raw\Community_index_inscritas.xlsx", sheet("Libro 02") firstrow clear

rename Departamento 		dpto
rename Provincia			prov
rename Distrito				dist
rename CCPP					ccpp
rename UbigeoFinalDistrito	ubigeo_dist
rename NumeroIndice			index_victim

gen idm=_n

gen 	dpto2=subinstr(dpto," ","",.)
replace dpto2=subinstr(dpto2,"Á","A",.)
replace dpto2=subinstr(dpto2,"É","E",.)
replace dpto2=subinstr(dpto2,"Í","I",.)
replace dpto2=subinstr(dpto2,"Ó","O",.)
replace dpto2=subinstr(dpto2,"Ú","U",.)
replace dpto2=subinstr(dpto2,"Ñ","N",.)
replace dpto2=subinstr(dpto2,"Ð","D",.)
gen 	prov2=subinstr(prov," ","",.)
replace prov2=subinstr(prov2,"Á","A",.)
replace prov2=subinstr(prov2,"É","E",.)
replace prov2=subinstr(prov2,"Í","I",.)
replace prov2=subinstr(prov2,"Ó","O",.)
replace prov2=subinstr(prov2,"Ú","U",.)
replace prov2=subinstr(prov2,"Ñ","N",.)
replace prov2=subinstr(prov2,"Ð","D",.)
replace prov2=subinstr(prov2,"-","",.)
replace prov2=subinstr(prov2,"_","",.)
gen 	dist2=subinstr(dist," ","",.)
replace dist2=subinstr(dist2,"Á","A",.)
replace dist2=subinstr(dist2,"É","E",.)
replace dist2=subinstr(dist2,"Í","I",.)
replace dist2=subinstr(dist2,"Ó","O",.)
replace dist2=subinstr(dist2,"Ú","U",.)
replace dist2=subinstr(dist2,"Ñ","N",.)
replace dist2=subinstr(dist2,"Ð","D",.)
replace dist2=subinstr(dist2,"-","",.)
replace dist2=subinstr(dist2,"_","",.)
gen 	ccpp2=subinstr(ccpp," ","",.)
replace ccpp2=subinstr(ccpp2,"Á","A",.)
replace ccpp2=subinstr(ccpp2,"É","E",.)
replace ccpp2=subinstr(ccpp2,"Í","I",.)
replace ccpp2=subinstr(ccpp2,"Ó","O",.)
replace ccpp2=subinstr(ccpp2,"Ú","U",.)
replace ccpp2=subinstr(ccpp2,"Ñ","N",.)
replace ccpp2=subinstr(ccpp2,"Ð","D",.)
replace ccpp2=subinstr(ccpp2,"-","",.)
replace ccpp2=subinstr(ccpp2,"_","",.)

egen dpdc=concat(dpto2 prov2 dist2 ccpp2)
sort dpdc
bysort dpdc: gen rep=_N
bysort dpdc: gen rep2=_n

saveold "$a\2 data\2 Working\SAT\community_index_clean.dta", replace v(13)

*-----------------------------------------------*
*		Import Financed communities dataset		*
*-----------------------------------------------*
clear all
import excel "$a\2 data\1 Raw\comunidades_atendidas_por_ano.xlsx", sheet("Hoja1") firstrow clear

rename REGIÓN				dpto
rename PROVINCIA			prov
rename DISTRITO				dist
rename COMUNIDAD			ccpp
rename NIVEL				Nivel

gen idu_fin=_n

gen 	dpto2=subinstr(dpto," ","",.)
replace dpto2=subinstr(dpto2,"Á","A",.)
replace dpto2=subinstr(dpto2,"É","E",.)
replace dpto2=subinstr(dpto2,"Í","I",.)
replace dpto2=subinstr(dpto2,"Ó","O",.)
replace dpto2=subinstr(dpto2,"Ú","U",.)
replace dpto2=subinstr(dpto2,"Ñ","N",.)
replace dpto2=subinstr(dpto2,"Ð","D",.)
gen 	prov2=subinstr(prov," ","",.)
replace prov2=subinstr(prov2,"Á","A",.)
replace prov2=subinstr(prov2,"É","E",.)
replace prov2=subinstr(prov2,"Í","I",.)
replace prov2=subinstr(prov2,"Ó","O",.)
replace prov2=subinstr(prov2,"Ú","U",.)
replace prov2=subinstr(prov2,"Ñ","N",.)
replace prov2=subinstr(prov2,"Ð","D",.)
replace prov2=subinstr(prov2,"-","",.)
replace prov2=subinstr(prov2,"_","",.)
gen 	dist2=subinstr(dist," ","",.)
replace dist2=subinstr(dist2,"Á","A",.)
replace dist2=subinstr(dist2,"É","E",.)
replace dist2=subinstr(dist2,"Í","I",.)
replace dist2=subinstr(dist2,"Ó","O",.)
replace dist2=subinstr(dist2,"Ú","U",.)
replace dist2=subinstr(dist2,"Ñ","N",.)
replace dist2=subinstr(dist2,"Ð","D",.)
replace dist2=subinstr(dist2,"-","",.)
replace dist2=subinstr(dist2,"_","",.)
gen 	ccpp2=subinstr(ccpp," ","",.)
replace ccpp2=subinstr(ccpp2,"Á","A",.)
replace ccpp2=subinstr(ccpp2,"É","E",.)
replace ccpp2=subinstr(ccpp2,"Í","I",.)
replace ccpp2=subinstr(ccpp2,"Ó","O",.)
replace ccpp2=subinstr(ccpp2,"Ú","U",.)
replace ccpp2=subinstr(ccpp2,"Ñ","N",.)
replace ccpp2=subinstr(ccpp2,"Ð","D",.)
replace ccpp2=subinstr(ccpp2,"-","",.)
replace ccpp2=subinstr(ccpp2,"_","",.)

*	Create full ccpp name to observe repetitions
egen dpdc=concat(dpto2 prov2 dist2 ccpp2)
sort dpdc Financiado
bysort dpdc: gen rep=_N
bysort dpdc: gen rep2=_n
/*	For repeated, keep only the oldest year, as it means that the community
	was treated							 										*/
drop if rep2==2
drop rep*
drop dpdc

saveold "$a\2 data\2 Working\SAT\community_treated.dta", replace v(13)

*-------------------------------------------------------------------*
*		Merge dataset of victimization and financed communities		*
*-------------------------------------------------------------------*

use "$a\2 data\2 Working\community_index_clean.dta", clear

*merge 1:1 dpto2 prov2 dist2 ccpp2 using "$a\2 data\community_treated.dta"
reclink ccpp2 dist2 prov2 dpto2 using "$a\2 data\2 Working\community_treated.dta", idm(idm) idu(idu_fin)  gen(match) wnomatch(7 8 9 10) minscore(.6)
drop U*
/*
	Note: There are 102 financed communities that doesn't appear in victimization
	dataset. We don't have index score for those communities
*/

drop _merge
drop match

gen 	treat_17=0
replace treat_17=1 if Financiado!=.
label var treat_17 "Financed communities until 2017"
gen		treat_16=0
replace treat_16=1 if Financiado<=2016 & Financiado!=.
label var treat_16 "Financed communities until 2016"
gen		treat_15=0
replace treat_15=1 if Financiado<=2015 & Financiado!=.
label var treat_15 "Financed communities until 2015"
gen		treat_14=0
replace treat_14=1 if Financiado<=2014 & Financiado!=.
label var treat_14 "Financed communities until 2014"
gen		treat_13=0
replace treat_13=1 if Financiado<=2013 & Financiado!=.
label var treat_13 "Financed communities until 2013"
gen 	treat_12=0
replace treat_12=1 if Financiado<=2012 & Financiado!=.
label var treat_12 "Financed communities until 2012"
gen		treat_11=0
replace treat_11=1 if Financiado<=2011 & Financiado!=.
label var treat_11 "Financed communities until 2011"
gen		treat_10=0
replace	treat_10=1 if Financiado<=2010 & Financiado!=.
label var treat_10 "Financed communities until 2010"
gen		treat_09=0
replace treat_09=1 if Financiado<=2009 & Financiado!=.
label var treat_09 "Financed communities until 2009"
gen		treat_08=0
replace	treat_08=1 if Financiado<=2008 & Financiado!=.
label var treat_08 "Financed communities until 2008"
gen		treat_07=0
replace treat_07=1 if Financiado==2007
label var treat_07 "Financed communities until 2007"

foreach y in 07 08 09 10 11 12 13 14 15 16 17 {
gen		years_since_treat`y' = 20`y' - Financiado if Financiado<=20`y'
replace years_since_treat`y' = 0 if Financiado==. | Financiado>20`y'
}

gen		treat_13_prod = 1 if (tipo_proyecto=="agricultura" | tipo_proyecto=="artesanal" | ///
		tipo_proyecto=="comercio" | tipo_proyecto=="ganaderia" | tipo_proyecto=="pesca" | ///
		tipo_proyecto=="turismo" | tipo_proyecto=="riego") & treat_13==1
replace treat_13_prod = 0 if treat_13==0

gen		treat_13_infra = 1 if treat_13_prod==.
replace treat_13_infra = 0 if treat_13==0
		
gen		dum_a13=0
replace dum_a13=1 if Nivel=="A" & treat_13==1	

bysort ubigeo_dist: egen	prop_a13=mean(dum_a13)
drop 	dum_a13			

gen		index_cutAB = index_victim - .1538
gen		index_cutBC = index_victim - .0623
gen		index_cutCD = index_victim - .0269
gen		index_cutDE = index_victim - .0152

drop if index_victim>1

drop idu idm
gen idm=_n

*reclink ubigeo_dist ccpp2 using "$a\2 data\ubigeo_reparaciones_inei.dta", idm(idm) idu(idu_ubigeo)  gen(match) wnomatch(6 10) minscore(.9)

gen		sample2 = 0
replace sample2 = 1 if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"

saveold "$a\2 data\2 Working\SAT\community_index_treated.dta", replace v(13)

*-------------------------------------------------------------------*
*		Merge treatment dataset with Sisfoh 2013 at CCPP level		*
*-------------------------------------------------------------------*

*merge 1:1 dpto prov dist ccpp using "$a\2 data\sisfoh2013_cleaned.dta", gen(_merge2)

reclink ccpp2 ubigeo_dist using "$a\2 data\2 Working\sisfoh2013_cleaned.dta", idm(idm) idu(idu_sisfoh)  gen(match) wnomatch(5 10) minscore(.6)
*	Note: 228 unmatched communities

drop if _merge==1
drop _merge

drop rep rep2
bysort ubigeo_ccpp: gen rep=_n
drop if rep==2 | rep==3 | rep==4

encode dist2, gen(cluster_dist)
encode prov2, gen(cluster_prov)
encode dpto2, gen(cluster_dpto)

drop ubigeo_dpto
gen ubigeo_dpto=substr(ubigeo_dist,1,2)
	
save "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", replace

rename pob pob_ccpp_2013
rename hog hog_ccpp_2013
rename viv viv_ccpp_2013

drop sisf_tviv1-ceng_c11p2a_3 sis_ptalum1-sis_psocial ccdd18 ccpp18 ccdi18 codccpp18

*-------------------------------------------*
*		Merge with APRA-mayor dataset		*
*-------------------------------------------*

merge m:1 ubigeo_dist using "$a\2 data\1 Raw\distritos_apristas_hcvapu.dta", gen(_merge_apra)
replace apra_2006 = 0 if _merge_apra==2 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC")
drop if _merge_apra==2
drop _merge_apra

*-------------------------------------------------------*
*		Merge with georeferenced data and distances		*
*-------------------------------------------------------*

merge 1:1 ubigeo_ccpp using "$a\2 data\1 Raw\ccpp_georef_dist.dta", gen(_merge_dist) keepusing(longitude latitude cap_dist longitude_capital latitude_capital distancia_capital cap_reg latitude_capital_region longitude_capital_region distancia_capital_region)
drop if _merge_dist==2
drop _merge_dist

*-----------------------------------------------*
*		Merge with mining districs dataset		*
*-----------------------------------------------*

merge m:1 ubigeo_dist using "$a\2 data\1 Raw\distritos_mineros.dta", keepusing(dist_minero) gen(_merge_minero)
replace dist_minero=0 if _merge_minero!=3
drop if _merge_minero==2
drop _merge_minero

*-------------------------------------------*
*		Merge 2017 population dataset		*
*-------------------------------------------*

merge 1:1 ubigeo_ccpp using "$a\2 data\1 Raw\pob_ccpp_2017.dta", keepusing(pob_ccpp_2017 viv_ccpp_2017 natural_region altitude_msnm)
drop if _merge==2
drop _merge

*---------------------------------------------------------------*
*		Merge with public expenditure exectution dataset		*
*---------------------------------------------------------------*

merge m:1 ubigeo_dist using "$a\2 data\1 Raw\ejecucion_presupuesto.dta"
drop if _merge==2
drop _merge

*-------------------------------------------*
*		Merge with MINEDU's ECE dataset		*
*-------------------------------------------*

merge 1:1 ubigeo_ccpp using "$a\2 data\2 Working\ece_2009_2015.dta", gen(_merge_ece)
drop if _merge==2
replace num_ie = 0 if _merge_ece==1
gen		tiene_ie = 0 if num_ie==0
replace tiene_ie = 1 if num_ie!=0
replace gestion_estatal = 0 if _merge_ece==1
replace gestion_privado = 0 if _merge_ece==1
gen		tiene_ie_estatal = 0
replace tiene_ie_estatal = 1 if gestion_estatal>0 & gestion_estatal!=.
gen		tiene_ie_privado = 0
replace tiene_ie_privado = 1 if gestion_privado>0 & gestion_privado!=.
replace alum_ie_2009 = 0 if _merge_ece==1
replace alum_ie_2010 = 0 if _merge_ece==1
replace alum_ie_2011 = 0 if _merge_ece==1
replace alum_ie_2012 = 0 if _merge_ece==1
replace alum_ie_2013 = 0 if _merge_ece==1
replace alum_ie_2014 = 0 if _merge_ece==1
replace alum_ie_2015 = 0 if _merge_ece==1
replace alum_ie_estatal_2009 = 0 if _merge_ece==1
replace alum_ie_estatal_2010 = 0 if _merge_ece==1
replace alum_ie_estatal_2011 = 0 if _merge_ece==1
replace alum_ie_estatal_2012 = 0 if _merge_ece==1
replace alum_ie_estatal_2013 = 0 if _merge_ece==1
replace alum_ie_estatal_2014 = 0 if _merge_ece==1
replace alum_ie_estatal_2015 = 0 if _merge_ece==1
replace alum_ie_privado_2009 = 0 if _merge_ece==1
replace alum_ie_privado_2010 = 0 if _merge_ece==1
replace alum_ie_privado_2011 = 0 if _merge_ece==1
replace alum_ie_privado_2012 = 0 if _merge_ece==1
replace alum_ie_privado_2013 = 0 if _merge_ece==1
replace alum_ie_privado_2014 = 0 if _merge_ece==1
replace alum_ie_privado_2015 = 0 if _merge_ece==1
replace alum_ece_2009 = 0 if _merge_ece==1
replace alum_ece_2010 = 0 if _merge_ece==1
replace alum_ece_2011 = 0 if _merge_ece==1
replace alum_ece_2012 = 0 if _merge_ece==1
replace alum_ece_2013 = 0 if _merge_ece==1
replace alum_ece_2014 = 0 if _merge_ece==1
replace alum_ece_2015 = 0 if _merge_ece==1
drop _merge_ece


*-----------------------------------------------*
*		Merge with 2010-2015 School Census		*
*-----------------------------------------------*

merge 1:1 ubigeo_ccpp using "$a\2 data\2 Working\CE_2010_2015.dta", gen(_merge_ce)
drop if _merge==2
local vars serv_ie_alim serv_ie_salud serv_ie_otro serv_ie_ninguno num_ie_estatal num_ie_privada tipo_ie_unimulti tipo_ie_polimulti tipo_ie_policomp ie_secundaria ie_primaria num_ie tot_alum tot_alum_m tot_alum_h tot_alum_primaria tot_alum_m_primaria tot_alum_h_primaria tot_alum_secundaria tot_alum_m_secundaria tot_alum_h_secundaria tot_alum_estatal tot_alum_m_estatal tot_alum_h_estatal tot_alum_privada tot_alum_m_privada tot_alum_h_privada
foreach x of local vars {
replace `x'_2010 = 0 if _merge_ce==1
replace `x'_2011 = 0 if _merge_ce==1
replace `x'_2012 = 0 if _merge_ce==1
replace `x'_2013 = 0 if _merge_ce==1
replace `x'_2014 = 0 if _merge_ce==1
replace `x'_2015 = 0 if _merge_ce==1
}

gen		ie_1_2010 = 0
replace ie_1_2010 = 1 if num_ie_2010>0
gen		ie_1_2011 = 0
replace ie_1_2011 = 1 if num_ie_2011>0
gen		ie_1_2012 = 0
replace ie_1_2012 = 1 if num_ie_2012>0
gen		ie_1_2013 = 0
replace ie_1_2013 = 1 if num_ie_2013>0
gen		ie_1_2014 = 0
replace ie_1_2014 = 1 if num_ie_2014>0
gen		ie_1_2015 = 0
replace ie_1_2015 = 1 if num_ie_2015>0

gen		ie_privada_1_2010 = 0
replace ie_privada_1_2010 = 1 if num_ie_privada_2010>0
gen		ie_privada_1_2011 = 0
replace ie_privada_1_2011 = 1 if num_ie_privada_2011>0
gen		ie_privada_1_2012 = 0
replace ie_privada_1_2012 = 1 if num_ie_privada_2012>0
gen		ie_privada_1_2013 = 0
replace ie_privada_1_2013 = 1 if num_ie_privada_2013>0
gen		ie_privada_1_2014 = 0
replace ie_privada_1_2014 = 1 if num_ie_privada_2014>0
gen		ie_privada_1_2015 = 0
replace ie_privada_1_2015 = 1 if num_ie_privada_2015>0

gen		ie_estatal_1_2010 = 0
replace ie_estatal_1_2010 = 1 if num_ie_estatal_2010>0
gen		ie_estatal_1_2011 = 0
replace ie_estatal_1_2011 = 1 if num_ie_estatal_2011>0
gen		ie_estatal_1_2012 = 0
replace ie_estatal_1_2012 = 1 if num_ie_estatal_2012>0
gen		ie_estatal_1_2013 = 0
replace ie_estatal_1_2013 = 1 if num_ie_estatal_2013>0
gen		ie_estatal_1_2014 = 0
replace ie_estatal_1_2014 = 1 if num_ie_estatal_2014>0
gen		ie_estatal_1_2015 = 0
replace ie_estatal_1_2015 = 1 if num_ie_estatal_2015>0

gen		ie_primaria_1_2010 = 0
replace ie_primaria_1_2010 = 1 if ie_primaria_2010>0
gen		ie_primaria_1_2011 = 0
replace ie_primaria_1_2011 = 1 if ie_primaria_2011>0
gen		ie_primaria_1_2012 = 0
replace ie_primaria_1_2012 = 1 if ie_primaria_2012>0
gen		ie_primaria_1_2013 = 0
replace ie_primaria_1_2013 = 1 if ie_primaria_2013>0
gen		ie_primaria_1_2014 = 0
replace ie_primaria_1_2014 = 1 if ie_primaria_2014>0
gen		ie_primaria_1_2015 = 0
replace ie_primaria_1_2015 = 1 if ie_primaria_2015>0

gen		ie_secundaria_1_2010 = 0
replace ie_secundaria_1_2010 = 1 if ie_secundaria_2010>0
gen		ie_secundaria_1_2011 = 0
replace ie_secundaria_1_2011 = 1 if ie_secundaria_2011>0
gen		ie_secundaria_1_2012 = 0
replace ie_secundaria_1_2012 = 1 if ie_secundaria_2012>0
gen		ie_secundaria_1_2013 = 0
replace ie_secundaria_1_2013 = 1 if ie_secundaria_2013>0
gen		ie_secundaria_1_2014 = 0
replace ie_secundaria_1_2014 = 1 if ie_secundaria_2014>0
gen		ie_secundaria_1_2015 = 0
replace ie_secundaria_1_2015 = 1 if ie_secundaria_2015>0

gen		serv_ie_1_2010 = 0
replace serv_ie_1_2010 = 1 if serv_ie_ninguno_2010 == 0
gen		serv_ie_1_2011 = 0
replace serv_ie_1_2011 = 1 if serv_ie_ninguno_2011 == 0
gen		serv_ie_1_2012 = 0
replace serv_ie_1_2012 = 1 if serv_ie_ninguno_2012 == 0
gen		serv_ie_1_2013 = 0
replace serv_ie_1_2013 = 1 if serv_ie_ninguno_2013 == 0
gen		serv_ie_1_2014 = 0
replace serv_ie_1_2014 = 1 if serv_ie_ninguno_2014 == 0
gen		serv_ie_1_2015 = 0
replace serv_ie_1_2015 = 1 if serv_ie_ninguno_2015 == 0

gen		num_ie_serv_1_2010 = 0
replace num_ie_serv_1_2010 = num_ie_2010 - serv_ie_ninguno_2010
gen		num_ie_serv_1_2011 = 0
replace num_ie_serv_1_2011 = num_ie_2011 - serv_ie_ninguno_2011
gen		num_ie_serv_1_2012 = 0
replace num_ie_serv_1_2012 = num_ie_2012 - serv_ie_ninguno_2012
gen		num_ie_serv_1_2013 = 0
replace num_ie_serv_1_2013 = num_ie_2013 - serv_ie_ninguno_2013
gen		num_ie_serv_1_2014 = 0
replace num_ie_serv_1_2014 = num_ie_2014 - serv_ie_ninguno_2014
gen		num_ie_serv_1_2015 = 0
replace num_ie_serv_1_2015 = num_ie_2015 - serv_ie_ninguno_2015

gen		prop_ie_serv_2010 = num_ie_serv_1_2010 / num_ie_2010
gen		prop_ie_serv_2011 = num_ie_serv_1_2011 / num_ie_2011
gen		prop_ie_serv_2012 = num_ie_serv_1_2012 / num_ie_2012
gen		prop_ie_serv_2013 = num_ie_serv_1_2013 / num_ie_2013
gen		prop_ie_serv_2014 = num_ie_serv_1_2014 / num_ie_2014
gen		prop_ie_serv_2015 = num_ie_serv_1_2015 / num_ie_2015

gen		prop_alum_m_2010 = tot_alum_m_2010 / tot_alum_2010
gen		prop_alum_m_2011 = tot_alum_m_2011 / tot_alum_2011
gen		prop_alum_m_2012 = tot_alum_m_2012 / tot_alum_2012
gen		prop_alum_m_2013 = tot_alum_m_2013 / tot_alum_2013
gen		prop_alum_m_2014 = tot_alum_m_2014 / tot_alum_2014
gen		prop_alum_m_2015 = tot_alum_m_2015 / tot_alum_2015

gen		prop_alum_ie_estatal_2010 = tot_alum_estatal_2010 / tot_alum_2010
gen		prop_alum_ie_estatal_2011 = tot_alum_estatal_2011 / tot_alum_2011
gen		prop_alum_ie_estatal_2012 = tot_alum_estatal_2012 / tot_alum_2012
gen		prop_alum_ie_estatal_2013 = tot_alum_estatal_2013 / tot_alum_2013
gen		prop_alum_ie_estatal_2014 = tot_alum_estatal_2014 / tot_alum_2014
gen		prop_alum_ie_estatal_2015 = tot_alum_estatal_2015 / tot_alum_2015


drop _merge_ce
*-------------------------------------------------------------------*
*		Merge treatment dataset with CENSUS 2007 at ccpp level		*
*-------------------------------------------------------------------*

merge 1:1 ubigeo_ccpp using "$a\2 data\2 Working\censo2007_cleaned.dta", gen(_merge_censo)

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                        39,937
        from master                       257  (_merge_censo==1)
        from using                     39,680  (_merge_censo==2)

    matched                             5,204  (_merge_censo==3)
    -----------------------------------------
*/
	
drop if _merge_censo==2
drop _merge_censo
gen 	altura_coded=""
replace altura_coded="1" if altitud1=="Si"
replace altura_coded="2" if altitud2=="Si" & altitud3=="No"
replace altura_coded="3" if altitud3=="Si"
destring altura_coded, replace

gen		log_pob_ccpp_2007=ln(pob_ccpp_2007)
gen		log_pob_ccpp_2013=ln(pob_ccpp_2013)
gen		log_pob_ccpp_2017=ln(pob_ccpp_2017)

gen		log_hog_ccpp_2007=ln(hog_ccpp_2007)
gen		log_hog_ccpp_2013=ln(viv_ccpp_2013)
gen		log_hog_ccpp_2017=ln(viv_ccpp_2017)

replace log_pob_ccpp_2007 = 0 if pob_ccpp_2007==0
replace log_pob_ccpp_2013 = 0 if pob_ccpp_2013==0
replace log_pob_ccpp_2017 = 0 if pob_ccpp_2017==0

replace log_hog_ccpp_2007 = 0 if hog_ccpp_2007==0
replace log_hog_ccpp_2013 = 0 if viv_ccpp_2013==0
replace log_hog_ccpp_2017 = 0 if viv_ccpp_2017==0

gen		log_distancia_capital=ln(distancia_capital)
replace log_distancia_capital = -3 if distancia_capital==0

*-----------------------------------------------------------*
*		Merge with new 2013 age distribution variables		*
*-----------------------------------------------------------*
merge 1:1 ubigeo_ccpp using "$a\2 data\2 Working\new_age_distribution2013.dta", gen(_merge_newage)

drop if _merge_newage==2
drop _merge_newage

encode ubigeo_ccpp, gen(cluster_ccpp)

saveold "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", v(13) replace
*/
*---------------------------------------------------*
*		Merge with Cenagro at producer level 		*
*---------------------------------------------------*
use "$a\2 data\3 Coded\SAT\community_index_treated_sisfohccpp_pbi.dta", clear

//Recuperación de variables sobre programas sociales
	merge 1:m ubigeo_ccpp using "$a\2 data\2 Working\SAT\prog_distribution2013.dta", gen(_merge_sisfoh)
	drop if _merge_sisfoh==2
	drop _merge_sisfoh
	
save "$a\2 data\3 Coded\SAT\community_index_treated_sisfohccpp_pbi_prog.dta", replace
e
/*
//Cenagro
	merge 1:m ubigeo_ccpp using "$a\2 data\2 Working\cenagro_producer.dta", gen(_merge_cenagroprod)
	drop if _merge_cenagroprod==2
	drop _merge_cenagroprod
	
saveold "$a\2 data\3 Coded\community_index_treated_cenagroprod.dta", v(13) replace

*---------------------------------------------------*
*		Merge with Cenagro at community level 		*
*---------------------------------------------------*
use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

	merge 1:1 ubigeo_ccpp using "$a\2 data\2 Working\cenagro_ccpp.dta", gen(_merge_cenagroprod)
	drop if _merge_cenagroprod==2
	replace num_productores = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace num_parc = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace area_parc = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace area_agricola = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace prom_parc = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace num_productor_m = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace riego_aspersion = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace riego_gravedad = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace num_cultivos = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")		
	replace ganaderia = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace total_trab_mujeres = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace total_trab_hombres = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace prom_area_parc = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")		
	replace prom_area_agricola = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace prom_num_cultivos = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")		
	replace prom_num_vacuno = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace prom_num_ovino = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace prom_num_alpaca = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace prom_trab_mujeres = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")	
	replace prom_ratioparticipaagro = 0 if _merge_cenagroprod==1 & (dpto=="HUANCAVELICA" | ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")		
	
saveold "$a\2 data\3 Coded\community_index_treated_cenagroccpp.dta", v(13) replace

*---------------------------------------------------*
*		Merge with Minsa at community level 		*
*---------------------------------------------------*
use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

	merge 1:1 ubigeo_ccpp using "$a\2 data\2 Working\minsa_ccpp", gen(_merge_minsa)
	drop if _merge_minsa==2
	
	local vars num_cs categ_0 categ_i1 categ_i2 categ_i3 categ_i4 categ_ii1 categ_ii2 categ_iie categ_iii1 categ_iii2 categ_iiie tipo_institucion
	foreach x of local vars {
	forvalues y = 2007/2018 {
	replace `x'_`y'=0 if _merge_minsa==1 & (dpto=="HUANCAVELICA" |		 ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	gen 	`x'_`y'_1 = 0 if _merge_minsa==1 & (dpto=="HUANCAVELICA" |		 ///
	dpto=="APURIMAC" | dpto=="CUSCO" | dpto=="JUNIN")
	replace `x'_`y'_1 = 1 if `x'_`y'>0 & `x'_`y'!=.
	}
	}	
	drop _merge_minsa

saveold "$a\2 data\3 Coded\community_index_treated_minsaccpp.dta", v(13) replace

*---------------------------------------------------*
*		Collapsing dataset to district-level 		* 
*---------------------------------------------------* 
*-----------------------------------*
*		With district capitals		*
*-----------------------------------*
* 2007 population dataset
use "$a\2 data\2 Working\censo2007_cleaned.dta", clear
collapse (sum) pob_2007=pob_ccpp_2007 hog_2007=hog_ccpp_2007 (mean) poverty*, by(ubigeo_dist)
saveold "$a\2 data\2 Working\censo2007_distrito.dta", v(13) replace

* 2013 population dataset
*use "$a\2 data\2 Working\sisfoh_hogar_cleaned.dta", clear
*keep sisf_numperso ubigeo_dist
*gen hog_ccpp_2013 = 1
*collapse (sum) pob_2013=sisf_numperso hog_2013=hog_ccpp_2013, by(ubigeo_dist)
*saveold "$a\2 data\2 Working\pob2013_distrito.dta", v(13) replace

* 2017 population and altitude dataset
use "$a\2 data\1 Raw\pob_ccpp_2017.dta", clear
gen ubigeo_dist=substr(ubigeo_ccpp,1,6)
collapse (sum) pob_2017=pob_ccpp_2017 hog_2017=viv_ccpp_2017 (mean) altitude_msnm, by(ubigeo_dist)
saveold "$a\2 data\2 Working\pob2017_distrito.dta", v(13) replace

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

gen num_ccpp_victim=1
gen	num_ccpp_treat07 = 1 if treat_07==1
gen	num_ccpp_treat08 = 1 if treat_08==1
gen	num_ccpp_treat09 = 1 if treat_09==1
gen	num_ccpp_treat10 = 1 if treat_10==1
gen	num_ccpp_treat11 = 1 if treat_11==1
gen	num_ccpp_treat12 = 1 if treat_12==1
gen	num_ccpp_treat13 = 1 if treat_13==1
gen	num_ccpp_treat14 = 1 if treat_14==1
gen	num_ccpp_treat15 = 1 if treat_15==1
gen	num_ccpp_treat16 = 1 if treat_16==1
gen	num_ccpp_treat17 = 1 if treat_17==1

gen	num_pob_treat07 = pob_ccpp_2007 if treat_07==1
gen	num_pob_treat13 = pob_ccpp_2013 if treat_13==1
gen	num_pob_treat17 = pob_ccpp_2017 if treat_17==1

gen	num_hog_treat07 = hog_ccpp_2007 if treat_07==1
gen	num_hog_treat13 = viv_ccpp_2013 if treat_13==1
gen	num_hog_treat17 = viv_ccpp_2017 if treat_17==1

gen	nivel_a = 1 if Nivel=="A"
gen nivel_b = 1 if Nivel=="B"

collapse (firstnm) dpto prov cluster_prov sample2 (max) dist_minero (sum) nivel_* num_ccpp* 		///
num_pob* num_hog* (mean) distancia_capital_region index_cutBC index_victim pim* dev* budget_exec*, 		///
by(ubigeo_dist)

merge 1:1 ubigeo_dist using "$a\2 data\1 Raw\ccpp_xdistrito.dta"
drop if _merge!=3
drop _merge

*	% of victimized and treated communities
gen prop_ccpp_victim = num_ccpp_victim / num_ccpp_2017
gen prop_ccpp_treat07 = num_ccpp_treat07 / num_ccpp_2017
gen prop_ccpp_treat08 = num_ccpp_treat08 / num_ccpp_2017
gen prop_ccpp_treat09 = num_ccpp_treat09 / num_ccpp_2017
gen prop_ccpp_treat10 = num_ccpp_treat10 / num_ccpp_2017
gen prop_ccpp_treat11 = num_ccpp_treat11 / num_ccpp_2017
gen prop_ccpp_treat12 = num_ccpp_treat12 / num_ccpp_2017
gen prop_ccpp_treat13 = num_ccpp_treat13 / num_ccpp_2017
gen prop_ccpp_treat14 = num_ccpp_treat14 / num_ccpp_2017
gen prop_ccpp_treat15 = num_ccpp_treat15 / num_ccpp_2017
gen prop_ccpp_treat16 = num_ccpp_treat16 / num_ccpp_2017
gen prop_ccpp_treat17 = num_ccpp_treat17 / num_ccpp_2017

gen	ubigeo_dpto = substr(ubigeo_dist,1,2)
encode ubigeo_dpto, gen(cluster_dpto)
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\censo2007_distrito.dta"
drop if _merge!=3
drop _merge
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\pob2013_distrito.dta"
drop if _merge!=3
drop _merge
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\pob2017_distrito.dta"
drop if _merge==2
drop _merge

gen		log_pob_2007 = ln(pob_2007)
gen		log_pob_2013 = ln(pob_2013)
gen		log_pob_2017 = ln(pob_2017)

gen		log_hog_2007 = ln(hog_2007)
gen		log_hog_2013 = ln(hog_2013)
gen		log_hog_2017 = ln(hog_2017)

gen 	log_distancia_capital_region=ln(distancia_capital_region)

*	% of treated individuals
gen	prop_pob_treat07 = num_pob_treat07 / pob_2007
gen	prop_pob_treat13 = num_pob_treat13 / pob_2013
gen	prop_pob_treat17 = num_pob_treat17 / pob_2017

*	% of treated households
gen	prop_hog_treat07 = num_hog_treat07 / hog_2007
gen	prop_hog_treat13 = num_hog_treat13 / hog_2013
gen	prop_hog_treat17 = num_hog_treat17 / hog_2017

gen		pim_percapita_2007 = pim_2007 / pob_2007
gen		pim_percapita_2013 = pim_2013 / pob_2013
gen		pim_percapita_2017 = pim_2017 / pob_2017

gen		dev_percapita_2007 = dev_2007 / pob_2007
gen		dev_percapita_2013 = dev_2013 / pob_2013
gen		dev_percapita_2017 = dev_2017 / pob_2017

*	Merge with Cenagro
merge 1:1 ubigeo_dist using "$a\2 Data\2 Working\cenagro_district.dta"
drop if _merge==2
local vars total_trab_mujeres total_trab_hombres riego_gravedad riego_aspersion prom_trab_mujeres prom_parc prom_num_vacuno prom_num_ovino prom_num_cultivos prom_num_alpaca prom_area_parc prom_area_agricola num_productores num_productor_m num_parc num_cultivos ganaderia area_parc area_agricola
foreach x of local vars {
	replace `x'=0 if _merge==1
}
drop _merge

*	Merge with Minsa
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\minsa_district.dta"
drop if _merge==2
drop _merge

*	Merge with Minedu
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\minedu_district.dta"
drop if _merge==2
drop _merge

*	Merge with Social Conflicts dataset
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\conflict_clean.dta"
drop if _merge==2

foreach x in sum_conflict sum_conf_violent sum_resuelto sum_conflict_active		///
					conflict_yn conflict_active_yn {
replace `x'_2007 = 0 if _merge==1
replace `x'_2013 = 0 if _merge==1
replace `x'_2017 = 0 if _merge==1
}
drop _merge

*	Merge with ONPE
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\onpe_2006_2016.dta"
drop _merge

saveold "$a\2 data\3 Coded\community_index_treated_district.dta", v(13) replace


*---------------------------------------*
*		Without district capitals		*
*---------------------------------------*
* 2007 population dataset
use "$a\2 data\2 Working\censo2007_cleaned.dta", clear
gen		cod_cap = substr(ubigeo_ccpp,-4,4)
drop if cod_cap=="0001"
collapse (sum) pob_2007=pob_ccpp_2007 hog_2007=hog_ccpp_2007 (mean) poverty*, by(ubigeo_dist)
saveold "$a\2 data\2 Working\censo2007_distrito_NoCapDist.dta", v(13) replace

* 2013 population dataset
*use "$a\2 data\2 Working\sisfoh_hogar_cleaned.dta", clear
*gen		cod_cap = substr(ubigeo_ccpp,-4,4)
*drop if cod_cap=="0001"
*keep sisf_numperso ubigeo_dist
*gen hog_ccpp_2013 = 1
*collapse (sum) pob_2013=sisf_numperso hog_2013=hog_ccpp_2013, by(ubigeo_dist)
*saveold "$a\2 data\2 Working\pob2013_distrito_NoCapDist.dta", v(13) replace

* 2017 population and altitude dataset
use "$a\2 data\1 Raw\pob_ccpp_2017.dta", clear
gen ubigeo_dist=substr(ubigeo_ccpp,1,6)
gen		cod_cap = substr(ubigeo_ccpp,-4,4)
drop if cod_cap=="0001"
collapse (sum) pob_2017=pob_ccpp_2017 hog_2017=viv_ccpp_2017 (mean) altitude_msnm, by(ubigeo_dist)
saveold "$a\2 data\2 Working\pob2017_distrito_NoCapDist.dta", v(13) replace

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear
drop if cap_dist==1

gen num_ccpp_victim=1
gen	num_ccpp_treat07 = 1 if treat_07==1
gen	num_ccpp_treat08 = 1 if treat_08==1
gen	num_ccpp_treat09 = 1 if treat_09==1
gen	num_ccpp_treat10 = 1 if treat_10==1
gen	num_ccpp_treat11 = 1 if treat_11==1
gen	num_ccpp_treat12 = 1 if treat_12==1
gen	num_ccpp_treat13 = 1 if treat_13==1
gen	num_ccpp_treat14 = 1 if treat_14==1
gen	num_ccpp_treat15 = 1 if treat_15==1
gen	num_ccpp_treat16 = 1 if treat_16==1
gen	num_ccpp_treat17 = 1 if treat_17==1

gen	num_pob_treat07 = pob_ccpp_2007 if treat_07==1
gen	num_pob_treat13 = pob_ccpp_2013 if treat_13==1
gen	num_pob_treat17 = pob_ccpp_2017 if treat_17==1

gen	num_hog_treat07 = hog_ccpp_2007 if treat_07==1
gen	num_hog_treat13 = viv_ccpp_2013 if treat_13==1
gen	num_hog_treat17 = viv_ccpp_2017 if treat_17==1

gen	nivel_a = 1 if Nivel=="A"
gen nivel_b = 1 if Nivel=="B"

collapse (firstnm) dpto prov cluster_prov sample2 (sum) nivel_* num_ccpp* 		///
num_pob* num_hog* (max) dist_minero (mean) distancia_capital_region index_cutBC index_victim pim* dev* budget_exec*, 		///
by(ubigeo_dist)

merge 1:1 ubigeo_dist using "$a\2 data\1 Raw\ccpp_xdistrito.dta"
drop if _merge!=3
drop _merge
replace num_ccpp_2017 = num_ccpp_2017 - 1

*	% of victimized and treated communities
gen prop_ccpp_victim = num_ccpp_victim / num_ccpp_2017
gen prop_ccpp_treat07 = num_ccpp_treat07 / num_ccpp_2017
gen prop_ccpp_treat08 = num_ccpp_treat08 / num_ccpp_2017
gen prop_ccpp_treat09 = num_ccpp_treat09 / num_ccpp_2017
gen prop_ccpp_treat10 = num_ccpp_treat10 / num_ccpp_2017
gen prop_ccpp_treat11 = num_ccpp_treat11 / num_ccpp_2017
gen prop_ccpp_treat12 = num_ccpp_treat12 / num_ccpp_2017
gen prop_ccpp_treat13 = num_ccpp_treat13 / num_ccpp_2017
gen prop_ccpp_treat14 = num_ccpp_treat14 / num_ccpp_2017
gen prop_ccpp_treat15 = num_ccpp_treat15 / num_ccpp_2017
gen prop_ccpp_treat16 = num_ccpp_treat16 / num_ccpp_2017
gen prop_ccpp_treat17 = num_ccpp_treat17 / num_ccpp_2017

gen	ubigeo_dpto = substr(ubigeo_dist,1,2)
encode ubigeo_dpto, gen(cluster_dpto)
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\censo2007_distrito_NoCapDist.dta"
drop if _merge!=3
drop _merge
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\pob2013_distrito_NoCapDist.dta"
drop if _merge!=3
drop _merge
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\pob2017_distrito_NoCapDist.dta"
drop if _merge==2
drop _merge

gen		log_pob_2007 = ln(pob_2007)
gen		log_pob_2013 = ln(pob_2013)
gen		log_pob_2017 = ln(pob_2017)

gen		log_hog_2007 = ln(hog_2007)
gen		log_hog_2013 = ln(hog_2013)
gen		log_hog_2017 = ln(hog_2017)

gen 	log_distancia_capital_region=ln(distancia_capital_region)

*	% of treated individuals
gen	prop_pob_treat07 = num_pob_treat07 / pob_2007
gen	prop_pob_treat13 = num_pob_treat13 / pob_2013
gen	prop_pob_treat17 = num_pob_treat17 / pob_2017

*	% of treated households
gen	prop_hog_treat07 = num_hog_treat07 / hog_2007
gen	prop_hog_treat13 = num_hog_treat13 / hog_2013
gen	prop_hog_treat17 = num_hog_treat17 / hog_2017

gen		pim_percapita_2007 = pim_2007 / pob_2007
gen		pim_percapita_2013 = pim_2013 / pob_2013
gen		pim_percapita_2017 = pim_2017 / pob_2017

gen		dev_percapita_2007 = dev_2007 / pob_2007
gen		dev_percapita_2013 = dev_2013 / pob_2013
gen		dev_percapita_2017 = dev_2017 / pob_2017

*	Merge with Cenagro
merge 1:1 ubigeo_dist using "$a\2 Data\2 Working\cenagro_district_NoCapDist.dta"
drop if _merge==2
local vars total_trab_mujeres total_trab_hombres riego_gravedad riego_aspersion prom_trab_mujeres prom_parc prom_num_vacuno prom_num_ovino prom_num_cultivos prom_num_alpaca prom_area_parc prom_area_agricola num_productores num_productor_m num_parc num_cultivos ganaderia area_parc area_agricola
foreach x of local vars {
	replace `x'=0 if _merge==1
}
drop _merge

*	Merge with Minsa
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\minsa_district.dta"
drop if _merge==2
drop _merge

*	Merge with Minedu
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\minedu_district_NoCapDist.dta"
drop if _merge==2
drop _merge

*	Merge with Social Conflicts dataset
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\conflict_clean.dta"
drop if _merge==2

foreach x in sum_conflict sum_conf_violent sum_resuelto sum_conflict_active		///
					conflict_yn conflict_active_yn {
replace `x'_2007 = 0 if _merge==1
replace `x'_2013 = 0 if _merge==1
replace `x'_2017 = 0 if _merge==1
}
drop _merge

*	Merge with ONPE
merge 1:1 ubigeo_dist using "$a\2 data\2 Working\onpe_2006_2016.dta"
drop if _merge==2
drop _merge

saveold "$a\2 data\3 Coded\community_index_treated_district_NoDistCap.dta", v(13) replace

*-----------------------------------------------------------------------*
*		Merge Victimization dataset with Sisfoh at household level 		*
*-----------------------------------------------------------------------*

*use "$a\2 data\community_index_treated.dta", clear

/*
merge 1:m ubigeo_ccpp using "$a\2 data\sisfoh_hogar_cleaned.dta", gen(_merge_sisf_h)

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                     7,772,348
        from master                       148  (_merge_sisf_h==1)
        from using                  7,772,200  (_merge_sisf_h==2)

    matched                           564,691  (_merge_sisf_h==3)
    -----------------------------------------
*/

drop if _merge_sisf_h!=3
drop _merge_sisf_h
drop if num_hogares==0



saveold "$a\2 data\community_index_treated_sisfohhog.dta", replace v(13)
*/

*-------------------------------------------------------------------------------*
*		Merge Victimization dataset with Sisfoh at HH + Individual level 		*
*-------------------------------------------------------------------------------*

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear
drop num_ie-cod_ccpp
drop serv_ie_alim_2011-rep2
drop prop_ie_serv_2010-prop_alum_ie_estatal_2015
drop serv_ie_alim_2010-prop_ie_estatal_2010
drop ie_1_2011-ie_1_2015 ie_privada_1_2011-ie_privada_1_2015 ie_estatal_1_2011-ie_estatal_1_2015 ie_primaria_1_2011-ie_primaria_1_2015 ie_secundaria_1_2011-ie_secundaria_1_2015 serv_ie_1_2011-serv_ie_1_2015 num_ie_serv_1_2011-num_ie_serv_1_2015
drop pim_* dev*
merge 1:m ubigeo_ccpp using "$a\2 data\2 Working\sisfoh_hogarpersona_cleaned.dta", gen(_merge_sisf_pers)

/*

    Result                           # of obs.
    -----------------------------------------
    not matched                     6,185,288
        from master                       148  (_merge_sisf_pers==1)
        from using                  6,185,140  (_merge_sisf_pers==2)

    matched                           424,430  (_merge_sisf_pers==3)
    -----------------------------------------
*/
	

drop if _merge_sisf_pers!=3
drop _merge_sisf_pers

saveold "$a\2 data\3 Coded\community_index_treated_sisfohhogpers.dta", replace v(13)

*-------------------------------------------------------------------------------*
*		Merge Victimization dataset with full Sisfoh Indivudual dataset 		*
*-------------------------------------------------------------------------------*

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

merge 1:m ubigeo_ccpp using "$a\2 data\2 Working\sisfoh_persona_both.dta", gen(_merge_sisf_both)

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                     1,372,301
        from master                     3,824  (_merge_sisf_both==1)
        from using                  1,368,477  (_merge_sisf_both==2)

    matched                           538,772  (_merge_sisf_both==3)
    -----------------------------------------
*/


drop if _merge_sisf_both!=3
drop _merge_sisf_both

saveold "$a\2 data\3 Coded\community_index_treated_sisfohpers_both.dta", replace v(13)

*-------------------------------------------------------------------------------*
*		Merge Victimization dataset with Sisfoh Women individual dataset 		*
*-------------------------------------------------------------------------------*

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

merge 1:m ubigeo_ccpp using "$a\2 data\2 Working\sisfoh_persona_women.dta", gen(_merge_sisf_women)

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       698,689
        from master                     3,836  (_merge_sisf_women==1)
        from using                    694,853  (_merge_sisf_women==2)

    matched                           270,114  (_merge_sisf_women==3)
    -----------------------------------------
*/


drop if _merge_sisf_women!=3
drop _merge_sisf_women

saveold "$a\2 data\3 Coded\community_index_treated_sisfohpers_women.dta", replace v(13)


*-------------------------------------------------------------------------------*
*		Merge Victimization dataset with Sisfoh Men individual dataset 		*
*-------------------------------------------------------------------------------*

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

merge 1:m ubigeo_ccpp using "$a\2 data\2 Working\sisfoh_persona_men.dta", gen(_merge_sisf_men)

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       677,454
        from master                     3,830  (_merge_sisf_men==1)
        from using                    673,624  (_merge_sisf_men==2)

    matched                           268,658  (_merge_sisf_men==3)
    -----------------------------------------
*/


drop if _merge_sisf_men!=3
drop _merge_sisf_men

saveold "$a\2 data\3 Coded\community_index_treated_sisfohpers_men.dta", replace v(13)





