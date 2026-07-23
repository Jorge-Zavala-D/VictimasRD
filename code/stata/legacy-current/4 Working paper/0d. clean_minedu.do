/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from MINEDU		|
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 5/1/2019				 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/


*---------------------------------------------------*
*		I.	Preparing individual ECE datasets		*
*---------------------------------------------------*

* 2008
use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ECE 2008\ece_mc_2008.dta", ///
	clear

	replace sexo = "0" if sexo=="H"
	replace sexo = "1" if sexo=="M"
	destring sexo, replace
	recode inicial (9=0)
	gen		alums_ece = 1
	collapse (mean) prom_lengua=m500_c_0 prom_mate=m500_m_0 ///
	(max) alum ///
	(sum) num_alum_muj=sexo inicial alums_ece ///
	(firstnm) ubigeo_dist=codgeo dpto=region26 prov=provinci dist=distrito ccpp=cen_pob area gestion, ///
		by(cod_mod7)

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion==1
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion==2
	gen		num_ie = 1
	collapse (firstnm) dpto prov dist (mean) prom_lengua prom_mate ///
	(sum) num_ie alum alums_ece num_alum_muj inicial gestion_estatal gestion_privado, ///
		by(ubigeo_dist ccpp)

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2008.dta", ///
	clear

* 2009
use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ECE 2009\ece_mc_2009.dta", ///
	clear

	recode sexo (2=0)
	label drop sexo
	*recode inicial (9=0)
	gen		alums_ece = 1
	collapse (mean) prom_lengua=m500_c_0 prom_mate=m500_m_0 ///
	(max) alum=alum_pro (sum) num_alum_muj=sexo alums_ece ///
	(firstnm) ubigeo_dist=codgeo dpto=region26 prov=provinci dist=distrito ccpp=cen_pob area gestion, ///
		by(cod_mod7)

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion==1
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion==2
	gen		num_ie = 1
	collapse (firstnm) dpto prov dist (mean) prom_lengua prom_mate ///
	(sum) num_ie alum alums_ece num_alum_muj gestion_estatal gestion_privado, ///
		by(ubigeo_dist ccpp)

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2009.dta", //
	replace

* 2010
use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ECE 2010\ece_mc_2010.dta", ///
	clear

	recode sexo (2=0)
	label drop sexo
	*recode inicial (9=0)
	gen		alums_ece = 1
	collapse (mean) prom_lengua=m500_c_1 prom_mate=m500_m_1 ///
	(max) alum=alum_pro (sum) num_alum_muj=sexo alums_ece ///
	(firstnm) ubigeo_dist=codgeo dpto=region26 prov=provinci dist=distrito ccpp=cen_pob area gestion, ///
		by(cod_mod7)

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion==1
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion==2
	gen		num_ie = 1
	collapse (firstnm) dpto prov dist (mean) prom_lengua prom_mate ///
	(sum) num_ie alum alums_ece num_alum_muj gestion_estatal gestion_privado, ///
		by(ubigeo_dist ccpp)

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2010.dta", ///
	replace

* 2011
use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ECE 2011\ece_mc_2011.dta", ///
	clear

	replace sexo = "0" if sexo=="Hombre"
	replace sexo = "1" if sexo=="Mujer"
	destring sexo, replace
	*recode sexo (2=0)
	*label drop sexo
	*recode inicial (9=0)
	gen		alums_ece = 1

	gen a=0
	egen ubigeo2=concat(a ubigeo) if ubigeo<100000
	tostring ubigeo, replace
	replace ubigeo2=ubigeo if ubigeo2==""
	replace ubigeo=ubigeo2
	drop ubigeo2 a

	format %9.0g cod_mod7
	gen a=0
	egen cod_mod2=concat(a cod_mod7) if cod_mod7<1000000
	tostring cod_mod7, replace
	replace cod_mod2=cod_mod7 if cod_mod2==""
	replace cod_mod7=cod_mod2
	drop cod_mod2 a

	replace m500_c_11="" if m500_c_11=="#NULL!"
	replace m500_m_11="" if m500_m_11=="#NULL!"
	destring m500_c_11 m500_m_11, replace

	collapse (mean) prom_lengua=m500_c_11 prom_mate=m500_m_11 ///
	(max) alum=asisten ///
	(sum) num_alum_muj=sexo alums_ece ///
	(firstnm) ubigeo_dist=ubigeo dpto=region prov=provincia dist=distrito ccpp=centropoblado area gestion, ///
		by(cod_mod7)

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion=="Estatal"
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion=="No Estatal"
	gen		num_ie = 1
	collapse (firstnm) dpto prov dist ///
	(mean) prom_lengua prom_mate ///
	(sum) num_ie alum alums_ece num_alum_muj gestion_estatal gestion_privado, ///
		by(ubigeo_dist ccpp)

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2011.dta", ///
	replace

* 2012
use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ECE 2012\ece_mc_2012.dta", ///
	clear

	replace sexo = "0" if sexo=="Hombre"
	replace sexo = "1" if sexo=="Mujer"
	destring sexo, replace
	*recode sexo (2=0)
	*label drop sexo
	*recode inicial (9=0)
	gen		alums_ece = 1

	collapse (mean) prom_lengua=m500_c prom_mate=m500_m ///
	(sum) num_alum_muj=sexo alums_ece ///
	(firstnm) ubigeo_dist=codgeo dpto=region26 prov=provincia dist=distrito ccpp=cen_pob area gestion, ///
		by(cod_mod7)

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion=="Estatal"
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion=="No estatal"
	gen		num_ie = 1
	collapse (firstnm) dpto prov dist ///
	(mean) prom_lengua prom_mate ///
	(sum) num_ie alums_ece num_alum_muj gestion_estatal gestion_privado, ///
		by(ubigeo_dist ccpp)

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2012.dta", ///
	replace

* 2014
use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ECE 2014\ece_2014.dta", ///
	clear

	drop anexo ie cod_dre dre cod_ugel ugel Característica

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion=="Estatal"
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion=="No estatal"
	gen		num_ie = 1

	rename ubigeo ubigeo_dist

	collapse (firstnm) dpto=region prov=provincia dist=distrito ///
	(mean) prom_lengua=lengua prom_mate=mate ///
	(sum) num_ie alums=asisten alums_ece=alum_ie gestion_estatal gestion_privado, ///
		by(ubigeo_dist ccpp)

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2012.dta", ///
	replace
*---------------------------*
*		ECE 2009-2015		*
*---------------------------*

use "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2009_2015.dta", ///
	clear

	gen		gestion_estatal = 0
	replace gestion_estatal = 1 if gestion=="Estatal"
	gen		gestion_privado = 0
	replace gestion_privado = 1 if gestion=="No Estatal"

	gen		alum_ie_estatal_2009 = alum_ie_2009 if gestion_estatal==1
	gen		alum_ie_privado_2009 = alum_ie_2009 if gestion_estatal==0
	gen		alum_ie_estatal_2010 = alum_ie_2010 if gestion_estatal==1
	gen		alum_ie_privado_2010 = alum_ie_2010 if gestion_estatal==0
	gen		alum_ie_estatal_2011 = alum_ie_2011 if gestion_estatal==1
	gen		alum_ie_privado_2011 = alum_ie_2011 if gestion_estatal==0
	gen		alum_ie_estatal_2012 = alum_ie_2012 if gestion_estatal==1
	gen		alum_ie_privado_2012 = alum_ie_2012 if gestion_estatal==0
	gen		alum_ie_estatal_2013 = alum_ie_2013 if gestion_estatal==1
	gen		alum_ie_privado_2013 = alum_ie_2013 if gestion_estatal==0
	gen		alum_ie_estatal_2014 = alum_ie_2014 if gestion_estatal==1
	gen		alum_ie_privado_2014 = alum_ie_2014 if gestion_estatal==0
	gen		alum_ie_estatal_2015 = alum_ie_2015 if gestion_estatal==1
	gen		alum_ie_privado_2015 = alum_ie_2015 if gestion_estatal==0

	gen num_ie = 1

	collapse (firstnm) dpto prov dist ///
	(sum) num_ie alum_ie* alum_ece* gestion_estatal gestion_privado lengua_niv* mate_niv* ///
	(mean) score_lengua* score_mate* cobertura_*, ///
		by(ubigeo_dist ccpp)

	gen idm_ece=_n

	gen 	dpto2=subinstr(dpto," ","",.)
	replace dpto2=upper(dpto2)
	replace dpto2=subinstr(dpto2,"Á","A",.)
	replace dpto2=subinstr(dpto2,"É","E",.)
	replace dpto2=subinstr(dpto2,"Í","I",.)
	replace dpto2=subinstr(dpto2,"Ó","O",.)
	replace dpto2=subinstr(dpto2,"Ú","U",.)
	replace dpto2=subinstr(dpto2,"Ñ","N",.)
	replace dpto2=subinstr(dpto2,"Ð","D",.)
	gen 	prov2=subinstr(prov," ","",.)
	replace prov2=upper(prov2)
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
	replace dist2=upper(dist2)
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
	replace ccpp2=upper(ccpp2)
	replace ccpp2=subinstr(ccpp2,"Á","A",.)
	replace ccpp2=subinstr(ccpp2,"É","E",.)
	replace ccpp2=subinstr(ccpp2,"Í","I",.)
	replace ccpp2=subinstr(ccpp2,"Ó","O",.)
	replace ccpp2=subinstr(ccpp2,"Ú","U",.)
	replace ccpp2=subinstr(ccpp2,"Ñ","N",.)
	replace ccpp2=subinstr(ccpp2,"Ð","D",.)
	replace ccpp2=subinstr(ccpp2,"-","",.)
	replace ccpp2=subinstr(ccpp2,"_","",.)

	bys ubigeo_dist ccpp2: gen a=_n
	drop if a>1
	drop a

	*merge 1:1 ubigeo_dist ccpp2 using "$input_dir\2 Working\ubigeos_ccpp.dta", keepusing(ubigeo_ccpp)
	reclink ubigeo_dist ccpp2 using "$input_dir\1 Raw\ubigeos_ccpp.dta", ///
		idm(idm_ece) ///
		idu(idu_sisfoh) ///
		gen(match) ///
		wnomatch(10 5) ///
		minscore(.6)
	
	drop Uubigeo_dist idm_ece dpto2 prov2 dist2 ccpp2 Uccpp2 match idu_sisfoh _merge
	drop if ubigeo_ccpp==""
	bys ubigeo_ccpp: gen rep=_n
	drop if rep>1
	drop rep

save "$input_dir\1 Raw\3 Minedu\ECE\ECE datasets\ece_2009_2015_working.dta", ///
	replace

	gen		prop_ie_estatal = gestion_estatal / num_ie
	gen		prop_ie_privado = gestion_privado / num_ie

	gen		prop_alum_estatal_2009 = alum_ie_estatal_2009 / alum_ie_2009
	gen		prop_alum_estatal_2010 = alum_ie_estatal_2010 / alum_ie_2010
	gen		prop_alum_estatal_2011 = alum_ie_estatal_2011 / alum_ie_2011
	gen		prop_alum_estatal_2012 = alum_ie_estatal_2012 / alum_ie_2012
	gen		prop_alum_estatal_2013 = alum_ie_estatal_2013 / alum_ie_2013
	gen		prop_alum_estatal_2014 = alum_ie_estatal_2014 / alum_ie_2014
	gen		prop_alum_estatal_2015 = alum_ie_estatal_2015 / alum_ie_2015

save "$input_dir\2 Working\ece_2009_2015.dta", ///
	replace

*---------------------------*
*		Censo Escolar		*
*---------------------------*

*-------------------*
*		2010		*
*-------------------*

** Dataset A
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\tabgence.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="100"			// Only cuadro 100
rename codgeo ubigeo_dist
keep cod_mod anexo niv_mod ges_dep ubigeo_dist cod_car p106
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\CE_2010_A.dta", replace

** Dataset B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\mat2100.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="301"			// Only cuadro 301
keep cod_mod anexo niv_mod d01-d12
collapse (firstnm) niv_mod (sum) d*, by(cod_mod anexo)
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\CE_2010_B.dta", replace

** Extract Centro Poblado
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\padron.dta", clear
rename codgeo ubigeo_dist
rename codcp_med cod_ccpp
rename cen_pob ccpp
keep cod_mod anexo ubigeo_dist ccpp cod_ccpp
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\CE_2010_C.dta", replace

** Merge A and B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\CE_2010_A.dta", clear
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\CE_2010_B.dta"
drop if _merge!=3
drop _merge
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2010\CE_2010_C.dta"
drop if _merge!=3
drop _merge

** Create variables
gen		serv_ie_alim_2010 = 0 
replace serv_ie_alim_2010 = 1 if p106=="1000" | p106=="1100" | p106=="1110" |	///
								p106=="1010" | p106=="1001"							
gen		serv_ie_salud_2010 = 0
replace serv_ie_salud_2010 = 1 if p106=="0100" | p106=="1100" | p106=="0110" |	///
								p106=="1110" | p106=="0101"					
gen		serv_ie_otro_2010 = 0
replace serv_ie_otro_2010 = 1 if p106=="0010" | p106=="0110" | p106=="1010" |	///
								p106=="1110" | p106=="0011"
gen		serv_ie_ninguno_2010 = 0
replace serv_ie_ninguno_2010 = 1 if p106=="0001"
drop p106

gen		gestion_estatal_2010 = 0 
replace gestion_estatal_2010 = 1 if ges_dep=="A1" | ges_dep=="A2" | 			///
								ges_dep=="A3"
gen		gestion_privada_2010 = 0
replace gestion_privada_2010 = 1 if ges_dep=="A4" | ges_dep=="B1" | 			///
								ges_dep=="B2" | ges_dep=="B3" | ges_dep=="B4" |	///
								ges_dep=="B5" | ges_dep=="B6"
drop ges_dep

gen		tipo_ie_unimulti_2010 = 0
replace tipo_ie_unimulti_2010 = 1 if cod_car=="1"
gen		tipo_ie_polimulti_2010 = 0
replace tipo_ie_polimulti_2010 = 1 if cod_car=="2"
gen		tipo_ie_policomp_2010 = 0
replace tipo_ie_policomp_2010 = 1 if cod_car=="3"
drop cod_car

gen		ie_secundaria_2010 = 0
replace ie_secundaria_2010 = 1 if niv_mod=="F0"
gen		ie_primaria_2010 = 0
replace ie_primaria_2010 = 1 if niv_mod=="B0"
drop niv_mod

gen		num_ie_2010 = 1

egen	tot_alum_2010 = rowtotal(d*)
egen	tot_alum_m_2010 = rowtotal(d02 d04 d06 d08 d10 d12)
egen	tot_alum_h_2010 = rowtotal(d01 d03 d05 d07 d09 d11)
egen	tot_alum_primaria_2010 = rowtotal(d*) if ie_primaria==1
egen	tot_alum_m_primaria_2010 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_primaria==1
egen	tot_alum_h_primaria_2010 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_primaria==1
gen		prop_alum_m_primaria_2010 = tot_alum_m_2010 / tot_alum_2010 if ie_primaria==1
egen	tot_alum_secundaria_2010 = rowtotal(d*) if ie_secundaria==1
egen	tot_alum_m_secundaria_2010 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_secundaria==1
egen	tot_alum_h_secundaria_2010 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_secundaria==1
gen		prop_alum_m_secundaria_2010 = tot_alum_m_2010 / tot_alum_2010 if ie_secundaria==1

egen	tot_alum_estatal_2010 = rowtotal(d*) if gestion_estatal_2010==1
egen	tot_alum_m_estatal_2010 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_estatal_2010==1
egen	tot_alum_h_estatal_2010 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_estatal_2010==1
gen		prop_alum_m_estatal_2010 = tot_alum_m_2010 / tot_alum_2010 if gestion_estatal_2010==1
egen	tot_alum_privada_2010 = rowtotal(d*) if gestion_privada_2010==1
egen	tot_alum_m_privada_2010 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_privada_2010==1
egen	tot_alum_h_privada_2010 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_privada_2010==1
gen		prop_alum_m_privada_2010 = tot_alum_m_2010 / tot_alum_2010 if gestion_privada_2010==1
drop d*

collapse (firstnm) ubigeo_dist ccpp (sum) serv_ie* num_ie_estatal_2010=gestion_estatal num_ie_privada_2010=gestion_privada tipo_ie* ie_* num_ie* tot* (mean) prop*, by(cod_ccpp)

gen		prop_ie_estatal_2010 = num_ie_estatal_2010 / num_ie_2010

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010.dta", replace

*-------------------*
*		2011		*
*-------------------*

** Dataset A
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\tabgence.dta", clear
keep if tiporeg=="1" & nroced=="03"
rename codgeo ubigeo_dist
keep cod_mod anexo niv_mod ges_dep ubigeo_dist cod_car servic_1 servic_2 servic_3 servic_4
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\CE_2011_A.dta", replace

** Dataset B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\mat2100.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="301"			// Only cuadro 301
keep cod_mod anexo niv_mod d01-d12
collapse (firstnm) niv_mod (sum) d*, by(cod_mod anexo)
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\CE_2011_B.dta", replace

** Extract Centro Poblado
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\padron.dta", clear
keep if tiporeg=="1"
rename codgeo ubigeo_dist
rename cen_pob ccpp
rename codcp_med cod_ccpp
keep cod_mod anexo ubigeo_dist ccpp cod_ccpp
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\CE_2011_C.dta", replace

** Merge A and B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\CE_2011_A.dta", clear
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\CE_2011_B.dta"
drop if _merge!=3
drop _merge
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2011\CE_2011_C.dta"
drop if _merge!=3
drop _merge

** Create variables
gen		serv_ie_alim_2011 = 0 
replace serv_ie_alim_2011 = 1 if servic_1=="X"						
gen		serv_ie_salud_2011 = 0
replace serv_ie_salud_2011 = 1 if servic_2=="X"				
gen		serv_ie_otro_2011 = 0
replace serv_ie_otro_2011 = 1 if servic_3=="X"
gen		serv_ie_ninguno_2011 = 0
replace serv_ie_ninguno_2011 = 1 if servic_4=="X"
drop servic*

gen		gestion_estatal_2011 = 0 
replace gestion_estatal_2011 = 1 if ges_dep=="A1" | ges_dep=="A2" | 			///
								ges_dep=="A3"
gen		gestion_privada_2011 = 0
replace gestion_privada_2011 = 1 if ges_dep=="A4" | ges_dep=="B1" | 			///
								ges_dep=="B2" | ges_dep=="B3" | ges_dep=="B4" |	///
								ges_dep=="B5" | ges_dep=="B6"
drop ges_dep

gen		tipo_ie_unimulti_2011 = 0
replace tipo_ie_unimulti_2011 = 1 if cod_car=="1"
gen		tipo_ie_polimulti_2011 = 0
replace tipo_ie_polimulti_2011 = 1 if cod_car=="2"
gen		tipo_ie_policomp_2011 = 0
replace tipo_ie_policomp_2011 = 1 if cod_car=="3"
drop cod_car

gen		ie_secundaria_2011 = 0
replace ie_secundaria_2011 = 1 if niv_mod=="F0"
gen		ie_primaria_2011 = 0
replace ie_primaria_2011 = 1 if niv_mod=="B0"
drop niv_mod

gen		num_ie_2011 = 1

egen	tot_alum_2011 = rowtotal(d*)
egen	tot_alum_m_2011 = rowtotal(d02 d04 d06 d08 d10 d12)
egen	tot_alum_h_2011 = rowtotal(d01 d03 d05 d07 d09 d11)
egen	tot_alum_primaria_2011 = rowtotal(d*) if ie_primaria==1
egen	tot_alum_m_primaria_2011 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_primaria==1
egen	tot_alum_h_primaria_2011 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_primaria==1
gen		prop_alum_m_primaria_2011 = tot_alum_m_2011 / tot_alum_2011 if ie_primaria==1
egen	tot_alum_secundaria_2011 = rowtotal(d*) if ie_secundaria==1
egen	tot_alum_m_secundaria_2011 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_secundaria==1
egen	tot_alum_h_secundaria_2011 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_secundaria==1
gen		prop_alum_m_secundaria_2011 = tot_alum_m_2011 / tot_alum_2011 if ie_secundaria==1

egen	tot_alum_estatal_2011 = rowtotal(d*) if gestion_estatal_2011==1
egen	tot_alum_m_estatal_2011 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_estatal_2011==1
egen	tot_alum_h_estatal_2011 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_estatal_2011==1
gen		prop_alum_m_estatal_2011 = tot_alum_m_2011 / tot_alum_2011 if gestion_estatal_2011==1
egen	tot_alum_privada_2011 = rowtotal(d*) if gestion_privada_2011==1
egen	tot_alum_m_privada_2011 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_privada_2011==1
egen	tot_alum_h_privada_2011 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_privada_2011==1
gen		prop_alum_m_privada_2011 = tot_alum_m_2011 / tot_alum_2011 if gestion_privada_2011==1
drop d*

collapse (firstnm) ubigeo_dist ccpp (sum) serv_ie* num_ie_estatal_2011=gestion_estatal num_ie_privada_2011=gestion_privada tipo_ie* ie_* num_ie* tot* (mean) prop*, by(cod_ccpp)

gen		prop_ie_estatal_2011 = num_ie_estatal_2011 / num_ie_2011

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2011.dta", replace

*-------------------*
*		2012		*
*-------------------*

** Dataset A
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\tabgence.dta", clear
keep if tiporeg=="1"
rename codgeo ubigeo_dist
keep cod_mod anexo niv_mod ges_dep ubigeo_dist cod_car serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_4
bys cod_mod anexo: gen rep=_n
drop if rep>1
drop rep
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\CE_2012_A.dta", replace

** Dataset B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\mat2100.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="301"			// Only cuadro 301
keep cod_mod anexo niv_mod d01-d12
collapse (firstnm) niv_mod (sum) d*, by(cod_mod anexo)
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\CE_2012_B.dta", replace

** Extract Centro Poblado
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\padron.dta", clear
keep if tiporeg=="1"
rename codgeo ubigeo_dist
rename codcp_inei ubigeo_ccpp
rename cen_pob ccpp
rename codccpp cod_ccpp
keep cod_mod anexo ubigeo_dist ubigeo_ccpp ccpp cod_ccpp
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\CE_2012_C.dta", replace

** Merge A and B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\CE_2012_A.dta", clear
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\CE_2012_B.dta"
drop if _merge!=3
drop _merge
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2012\CE_2012_C.dta"
drop if _merge!=3
drop _merge

** Create variables
gen		serv_ie_alim_2012 = 0 
replace serv_ie_alim_2012 = 1 if serv_ie_1=="X"						
gen		serv_ie_salud_2012 = 0
replace serv_ie_salud_2012 = 1 if serv_ie_2=="X" | serv_ie_3=="X"				
gen		serv_ie_otro_2012 = 0
replace serv_ie_otro_2012 = 1 if serv_ie_3=="X"
gen		serv_ie_ninguno_2012 = 0
replace serv_ie_ninguno_2012 = 1 if serv_ie_4=="X"
drop serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_4

gen		gestion_estatal_2012 = 0 
replace gestion_estatal_2012 = 1 if ges_dep=="A1" | ges_dep=="A2" | 			///
								ges_dep=="A3"
gen		gestion_privada_2012 = 0
replace gestion_privada_2012 = 1 if ges_dep=="A4" | ges_dep=="B1" | 			///
								ges_dep=="B2" | ges_dep=="B3" | ges_dep=="B4" |	///
								ges_dep=="B5" | ges_dep=="B6"
drop ges_dep

gen		tipo_ie_unimulti_2012 = 0
replace tipo_ie_unimulti_2012 = 1 if cod_car=="1"
gen		tipo_ie_polimulti_2012 = 0
replace tipo_ie_polimulti_2012 = 1 if cod_car=="2"
gen		tipo_ie_policomp_2012 = 0
replace tipo_ie_policomp_2012 = 1 if cod_car=="3"
drop cod_car

gen		ie_secundaria_2012 = 0
replace ie_secundaria_2012 = 1 if niv_mod=="F0"
gen		ie_primaria_2012 = 0
replace ie_primaria_2012 = 1 if niv_mod=="B0"
drop niv_mod

gen		num_ie_2012 = 1

egen	tot_alum_2012 = rowtotal(d*)
egen	tot_alum_m_2012 = rowtotal(d02 d04 d06 d08 d10 d12)
egen	tot_alum_h_2012 = rowtotal(d01 d03 d05 d07 d09 d11)
egen	tot_alum_primaria_2012 = rowtotal(d*) if ie_primaria==1
egen	tot_alum_m_primaria_2012 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_primaria==1
egen	tot_alum_h_primaria_2012 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_primaria==1
gen		prop_alum_m_primaria_2012 = tot_alum_m_2012 / tot_alum_2012 if ie_primaria==1
egen	tot_alum_secundaria_2012 = rowtotal(d*) if ie_secundaria==1
egen	tot_alum_m_secundaria_2012 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_secundaria==1
egen	tot_alum_h_secundaria_2012 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_secundaria==1
gen		prop_alum_m_secundaria_2012 = tot_alum_m_2012 / tot_alum_2012 if ie_secundaria==1

egen	tot_alum_estatal_2012 = rowtotal(d*) if gestion_estatal_2012==1
egen	tot_alum_m_estatal_2012 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_estatal_2012==1
egen	tot_alum_h_estatal_2012 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_estatal_2012==1
gen		prop_alum_m_estatal_2012 = tot_alum_m_2012 / tot_alum_2012 if gestion_estatal_2012==1
egen	tot_alum_privada_2012 = rowtotal(d*) if gestion_privada_2012==1
egen	tot_alum_m_privada_2012 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_privada_2012==1
egen	tot_alum_h_privada_2012 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_privada_2012==1
gen		prop_alum_m_privada_2012 = tot_alum_m_2012 / tot_alum_2012 if gestion_privada_2012==1
drop d*

collapse (firstnm) ubigeo_ccpp ubigeo_dist ccpp (sum) serv_ie* num_ie_estatal_2012=gestion_estatal num_ie_privada_2012=gestion_privada tipo_ie* ie_* num_ie* tot* (mean) prop*, by(cod_ccpp)
replace ubigeo_ccpp="" if ubigeo_ccpp=="0"
rename ubigeo_ccpp ubigeo_ccpp_2012
gen		prop_ie_estatal_2012 = num_ie_estatal_2012 / num_ie_2012

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2012.dta", replace

*-------------------*
*		2013		*
*-------------------*

** Dataset A
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\tabgence.dta", clear
keep if tiporeg=="1"
rename codgeo ubigeo_dist
keep cod_mod anexo niv_mod ges_dep ubigeo_dist cod_car serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_5
bys cod_mod anexo: gen rep=_n
drop if rep>1
drop rep
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\CE_2013_A.dta", replace

** Dataset B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\mat2100.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="301"			// Only cuadro 301
keep cod_mod anexo niv_mod d01-d12
collapse (firstnm) niv_mod (sum) d*, by(cod_mod anexo)
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\CE_2013_B.dta", replace

** Extract Centro Poblado
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\padron.dta", clear
rename codgeo ubigeo_dist
rename codcp_inei ubigeo_ccpp
rename cen_pob ccpp
rename codcp_med cod_ccpp
keep cod_mod anexo ubigeo_dist ubigeo_ccpp ccpp cod_ccpp
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\CE_2013_C.dta", replace

** Merge A and B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\CE_2013_A.dta", clear
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\CE_2013_B.dta"
drop if _merge!=3
drop _merge
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2013\CE_2013_C.dta"
drop if _merge!=3
drop _merge

** Create variables
gen		serv_ie_alim_2013 = 0 
replace serv_ie_alim_2013 = 1 if serv_ie_1=="X"						
gen		serv_ie_salud_2013 = 0
replace serv_ie_salud_2013 = 1 if serv_ie_2=="X" | serv_ie_3=="X"				
gen		serv_ie_otro_2013 = 0
replace serv_ie_otro_2013 = 1 if serv_ie_3=="X"
gen		serv_ie_ninguno_2013 = 0
replace serv_ie_ninguno_2013 = 1 if serv_ie_5=="X"
drop serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_5

gen		gestion_estatal_2013 = 0 
replace gestion_estatal_2013 = 1 if ges_dep=="A1" | ges_dep=="A2" | 			///
								ges_dep=="A3"
gen		gestion_privada_2013 = 0
replace gestion_privada_2013 = 1 if ges_dep=="A4" | ges_dep=="B1" | 			///
								ges_dep=="B2" | ges_dep=="B3" | ges_dep=="B4" |	///
								ges_dep=="B5" | ges_dep=="B6"
drop ges_dep

gen		tipo_ie_unimulti_2013 = 0
replace tipo_ie_unimulti_2013 = 1 if cod_car=="1"
gen		tipo_ie_polimulti_2013 = 0
replace tipo_ie_polimulti_2013 = 1 if cod_car=="2"
gen		tipo_ie_policomp_2013 = 0
replace tipo_ie_policomp_2013 = 1 if cod_car=="3"
drop cod_car

gen		ie_secundaria_2013 = 0
replace ie_secundaria_2013 = 1 if niv_mod=="F0"
gen		ie_primaria_2013 = 0
replace ie_primaria_2013 = 1 if niv_mod=="B0"
drop niv_mod

gen		num_ie_2013 = 1

egen	tot_alum_2013 = rowtotal(d*)
egen	tot_alum_m_2013 = rowtotal(d02 d04 d06 d08 d10 d12)
egen	tot_alum_h_2013 = rowtotal(d01 d03 d05 d07 d09 d11)
egen	tot_alum_primaria_2013 = rowtotal(d*) if ie_primaria==1
egen	tot_alum_m_primaria_2013 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_primaria==1
egen	tot_alum_h_primaria_2013 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_primaria==1
gen		prop_alum_m_primaria_2013 = tot_alum_m_2013 / tot_alum_2013 if ie_primaria==1
egen	tot_alum_secundaria_2013 = rowtotal(d*) if ie_secundaria==1
egen	tot_alum_m_secundaria_2013 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_secundaria==1
egen	tot_alum_h_secundaria_2013 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_secundaria==1
gen		prop_alum_m_secundaria_2013 = tot_alum_m_2013 / tot_alum_2013 if ie_secundaria==1

egen	tot_alum_estatal_2013 = rowtotal(d*) if gestion_estatal_2013==1
egen	tot_alum_m_estatal_2013 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_estatal_2013==1
egen	tot_alum_h_estatal_2013 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_estatal_2013==1
gen		prop_alum_m_estatal_2013 = tot_alum_m_2013 / tot_alum_2013 if gestion_estatal_2013==1
egen	tot_alum_privada_2013 = rowtotal(d*) if gestion_privada_2013==1
egen	tot_alum_m_privada_2013 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_privada_2013==1
egen	tot_alum_h_privada_2013 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_privada_2013==1
gen		prop_alum_m_privada_2013 = tot_alum_m_2013 / tot_alum_2013 if gestion_privada_2013==1
drop d*

collapse (firstnm) ubigeo_ccpp ubigeo_dist ccpp (sum) serv_ie* num_ie_estatal_2013=gestion_estatal num_ie_privada_2013=gestion_privada tipo_ie* ie_* num_ie* tot* (mean) prop*, by(cod_ccpp)
replace ubigeo_ccpp="" if ubigeo_ccpp=="0"
rename ubigeo_ccpp ubigeo_ccpp_2013
gen		prop_ie_estatal_2013 = num_ie_estatal_2013 / num_ie_2013

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2013.dta", replace

*-------------------*
*		2014		*
*-------------------*

** Dataset A
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\tabgence.dta", clear
rename codgeo ubigeo_dist
keep cod_mod anexo niv_mod ges_dep ubigeo_dist cod_car serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_4
bys cod_mod anexo: gen rep=_n
drop if rep>1
drop rep
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\CE_2014_A.dta", replace

** Dataset B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\mat2100.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="201"			// Only cuadro 301
keep cod_mod anexo niv_mod d01-d12
collapse (firstnm) niv_mod (sum) d*, by(cod_mod anexo)
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\CE_2014_B.dta", replace

** Extract Centro Poblado
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\padron.dta", clear
rename codgeo ubigeo_dist
rename codcp_inei ubigeo_ccpp
rename cen_pob ccpp
rename codcp_med cod_ccpp
keep cod_mod anexo ubigeo_dist ubigeo_ccpp ccpp cod_ccpp
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\CE_2014_C.dta", replace

** Merge A and B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\CE_2014_A.dta", clear
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\CE_2014_B.dta"
drop if _merge!=3
drop _merge
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2014\CE_2014_C.dta"
drop if _merge!=3
drop _merge

** Create variables
gen		serv_ie_alim_2014 = 0 
replace serv_ie_alim_2014 = 1 if serv_ie_1=="X"						
gen		serv_ie_salud_2014 = 0
replace serv_ie_salud_2014 = 1 if serv_ie_2=="X" | serv_ie_3=="X"				
gen		serv_ie_otro_2014 = 0
replace serv_ie_otro_2014 = 1 if serv_ie_3=="X"
gen		serv_ie_ninguno_2014 = 0
replace serv_ie_ninguno_2014 = 1 if serv_ie_4=="X"
drop serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_4

gen		gestion_estatal_2014 = 0 
replace gestion_estatal_2014 = 1 if ges_dep=="A1" | ges_dep=="A2" | 			///
								ges_dep=="A3"
gen		gestion_privada_2014 = 0
replace gestion_privada_2014 = 1 if ges_dep=="A4" | ges_dep=="B1" | 			///
								ges_dep=="B2" | ges_dep=="B3" | ges_dep=="B4" |	///
								ges_dep=="B5" | ges_dep=="B6"
drop ges_dep

gen		tipo_ie_unimulti_2014 = 0
replace tipo_ie_unimulti_2014 = 1 if cod_car=="1"
gen		tipo_ie_polimulti_2014 = 0
replace tipo_ie_polimulti_2014 = 1 if cod_car=="2"
gen		tipo_ie_policomp_2014 = 0
replace tipo_ie_policomp_2014 = 1 if cod_car=="3"
drop cod_car

gen		ie_secundaria_2014 = 0
replace ie_secundaria_2014 = 1 if niv_mod=="F0"
gen		ie_primaria_2014 = 0
replace ie_primaria_2014 = 1 if niv_mod=="B0"
drop niv_mod

gen		num_ie_2014 = 1

egen	tot_alum_2014 = rowtotal(d*)
egen	tot_alum_m_2014 = rowtotal(d02 d04 d06 d08 d10 d12)
egen	tot_alum_h_2014 = rowtotal(d01 d03 d05 d07 d09 d11)
egen	tot_alum_primaria_2014 = rowtotal(d*) if ie_primaria==1
egen	tot_alum_m_primaria_2014 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_primaria==1
egen	tot_alum_h_primaria_2014 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_primaria==1
gen		prop_alum_m_primaria_2014 = tot_alum_m_2014 / tot_alum_2014 if ie_primaria==1
egen	tot_alum_secundaria_2014 = rowtotal(d*) if ie_secundaria==1
egen	tot_alum_m_secundaria_2014 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_secundaria==1
egen	tot_alum_h_secundaria_2014 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_secundaria==1
gen		prop_alum_m_secundaria_2014 = tot_alum_m_2014 / tot_alum_2014 if ie_secundaria==1

egen	tot_alum_estatal_2014 = rowtotal(d*) if gestion_estatal_2014==1
egen	tot_alum_m_estatal_2014 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_estatal_2014==1
egen	tot_alum_h_estatal_2014 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_estatal_2014==1
gen		prop_alum_m_estatal_2014 = tot_alum_m_2014 / tot_alum_2014 if gestion_estatal_2014==1
egen	tot_alum_privada_2014 = rowtotal(d*) if gestion_privada_2014==1
egen	tot_alum_m_privada_2014 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_privada_2014==1
egen	tot_alum_h_privada_2014 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_privada_2014==1
gen		prop_alum_m_privada_2014 = tot_alum_m_2014 / tot_alum_2014 if gestion_privada_2014==1
drop d*

collapse (firstnm) ubigeo_ccpp ubigeo_dist ccpp (sum) serv_ie* num_ie_estatal_2014=gestion_estatal num_ie_privada_2014=gestion_privada tipo_ie* ie_* num_ie* tot* (mean) prop*, by(cod_ccpp)
replace ubigeo_ccpp="" if ubigeo_ccpp=="0"
rename ubigeo_ccpp ubigeo_ccpp_2014
gen		prop_ie_estatal_2014 = num_ie_estatal_2014 / num_ie_2014

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2014.dta", replace

*-------------------*
*		2015		*
*-------------------*

** Dataset A
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\tabgence.dta", clear
keep if tiporeg=="1" & nroced=="03"
rename codgeo ubigeo_dist
keep cod_mod anexo niv_mod ges_dep ubigeo_dist serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_4 serv_ie_5
bys cod_mod anexo: gen rep=_n
drop if rep>1
drop rep
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\CE_2015_A.dta", replace

** Dataset B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\mat2100.dta", clear
keep if tiporeg=="1" & nroced=="03" & cuadro=="201"			// Only cuadro 201
keep cod_mod anexo cod_car niv_mod d01-d12
collapse (firstnm) niv_mod cod_car (sum) d*, by(cod_mod anexo)
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\CE_2015_B.dta", replace

** Extract Centro Poblado
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\padron.dta", clear
rename codgeo ubigeo_dist
rename codcp_inei ubigeo_ccpp
rename cen_pob ccpp
rename codcp_med cod_ccpp
keep cod_mod anexo ubigeo_dist ubigeo_ccpp ccpp cod_ccpp
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\CE_2015_C.dta", replace

** Merge A and B
use "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\CE_2015_A.dta", clear
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\CE_2015_B.dta"
drop if _merge!=3
drop _merge
merge 1:1 cod_mod anexo using "$input_dir\1 Raw\3 Minedu\Censo Escolar\2015\CE_2015_C.dta"
drop if _merge!=3
drop _merge

** Create variables
gen		serv_ie_alim_2015 = 0 
replace serv_ie_alim_2015 = 1 if serv_ie_1=="X"						
gen		serv_ie_salud_2015 = 0
replace serv_ie_salud_2015 = 1 if serv_ie_2=="X" | serv_ie_3=="X"				
gen		serv_ie_otro_2015 = 0
replace serv_ie_otro_2015 = 1 if serv_ie_4=="X"
gen		serv_ie_ninguno_2015 = 0
replace serv_ie_ninguno_2015 = 1 if serv_ie_5=="X"
drop serv_ie_1 serv_ie_2 serv_ie_3 serv_ie_4 serv_ie_5

gen		gestion_estatal_2015 = 0 
replace gestion_estatal_2015 = 1 if ges_dep=="A1" | ges_dep=="A2" | 			///
								ges_dep=="A3"
gen		gestion_privada_2015 = 0
replace gestion_privada_2015 = 1 if ges_dep=="A4" | ges_dep=="B1" | 			///
								ges_dep=="B2" | ges_dep=="B3" | ges_dep=="B4" |	///
								ges_dep=="B5" | ges_dep=="B6"
drop ges_dep

gen		tipo_ie_unimulti_2015 = 0
replace tipo_ie_unimulti_2015 = 1 if cod_car=="1"
gen		tipo_ie_polimulti_2015 = 0
replace tipo_ie_polimulti_2015 = 1 if cod_car=="2"
gen		tipo_ie_policomp_2015 = 0
replace tipo_ie_policomp_2015 = 1 if cod_car=="3"
drop cod_car

gen		ie_secundaria_2015 = 0
replace ie_secundaria_2015 = 1 if niv_mod=="F0"
gen		ie_primaria_2015 = 0
replace ie_primaria_2015 = 1 if niv_mod=="B0"
drop niv_mod

gen		num_ie_2015 = 1

egen	tot_alum_2015 = rowtotal(d*)
egen	tot_alum_m_2015 = rowtotal(d02 d04 d06 d08 d10 d12)
egen	tot_alum_h_2015 = rowtotal(d01 d03 d05 d07 d09 d11)
egen	tot_alum_primaria_2015 = rowtotal(d*) if ie_primaria==1
egen	tot_alum_m_primaria_2015 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_primaria==1
egen	tot_alum_h_primaria_2015 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_primaria==1
gen		prop_alum_m_primaria_2015 = tot_alum_m_2015 / tot_alum_2015 if ie_primaria==1
egen	tot_alum_secundaria_2015 = rowtotal(d*) if ie_secundaria==1
egen	tot_alum_m_secundaria_2015 = rowtotal(d02 d04 d06 d08 d10 d12) if ie_secundaria==1
egen	tot_alum_h_secundaria_2015 = rowtotal(d01 d03 d05 d07 d09 d11) if ie_secundaria==1
gen		prop_alum_m_secundaria_2015 = tot_alum_m_2015 / tot_alum_2015 if ie_secundaria==1

egen	tot_alum_estatal_2015 = rowtotal(d*) if gestion_estatal_2015==1
egen	tot_alum_m_estatal_2015 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_estatal_2015==1
egen	tot_alum_h_estatal_2015 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_estatal_2015==1
gen		prop_alum_m_estatal_2015 = tot_alum_m_2015 / tot_alum_2015 if gestion_estatal_2015==1
egen	tot_alum_privada_2015 = rowtotal(d*) if gestion_privada_2015==1
egen	tot_alum_m_privada_2015 = rowtotal(d02 d04 d06 d08 d10 d12) if gestion_privada_2015==1
egen	tot_alum_h_privada_2015 = rowtotal(d01 d03 d05 d07 d09 d11) if gestion_privada_2015==1
gen		prop_alum_m_privada_2015 = tot_alum_m_2015 / tot_alum_2015 if gestion_privada_2015==1
drop d*

collapse (firstnm) ubigeo_ccpp ubigeo_dist ccpp (sum) serv_ie* num_ie_estatal_2015=gestion_estatal num_ie_privada_2015=gestion_privada tipo_ie* ie_* num_ie* tot* (mean) prop*, by(cod_ccpp)
replace ubigeo_ccpp="" if ubigeo_ccpp=="0"
rename ubigeo_ccpp ubigeo_ccpp_2015
gen		prop_ie_estatal_2015 = num_ie_estatal_2015 / num_ie_2015

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2015.dta", replace

*-----------------------------------*
*		Merge 2010-2015 Census		*
*-----------------------------------*

use "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010.dta", clear

local vars serv_ie_alim serv_ie_salud serv_ie_otro serv_ie_ninguno num_ie_estatal num_ie_privada tipo_ie_unimulti tipo_ie_polimulti tipo_ie_policomp ie_secundaria ie_primaria num_ie tot_alum tot_alum_m tot_alum_h tot_alum_primaria tot_alum_m_primaria tot_alum_h_primaria tot_alum_secundaria tot_alum_m_secundaria tot_alum_h_secundaria tot_alum_estatal tot_alum_m_estatal tot_alum_h_estatal tot_alum_privada tot_alum_m_privada tot_alum_h_privada

merge 1:1  cod_ccpp using "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2011.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         2,674
        from master                     1,045  (_merge==1)
        from using                      1,629  (_merge==2)

    matched                            24,410  (_merge==3)
    -----------------------------------------
*/
foreach x of local vars {
replace `x'_2010 = 0 if `x'_2010==.
replace `x'_2011 = 0 if _merge==1
}
drop _merge
merge 1:1 cod_ccpp using "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2012.dta"
foreach x of local vars {
replace `x'_2010 = 0 if `x'_2010==.
replace `x'_2011 = 0 if `x'_2011==.
replace `x'_2012 = 0 if _merge==1
}
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         1,659
        from master                     1,330  (_merge==1)
        from using                        329  (_merge==2)

    matched                            25,754  (_merge==3)
    -----------------------------------------
*/
drop _merge
merge 1:1 cod_ccpp using "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2013.dta"
foreach x of local vars {
replace `x'_2010 = 0 if `x'_2010==.
replace `x'_2011 = 0 if `x'_2011==.
replace `x'_2012 = 0 if `x'_2012==.
replace `x'_2013 = 0 if _merge==1
}
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         2,630
        from master                     2,317  (_merge==1)
        from using                        313  (_merge==2)

    matched                            25,096  (_merge==3)
    -----------------------------------------
*/
drop _merge
merge 1:1 cod_ccpp using "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2014.dta"
foreach x of local vars {
replace `x'_2010 = 0 if `x'_2010==.
replace `x'_2011 = 0 if `x'_2011==.
replace `x'_2012 = 0 if `x'_2012==.
replace `x'_2013 = 0 if `x'_2013==.
replace `x'_2014 = 0 if _merge==1
}
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         3,407
        from master                     2,629  (_merge==1)
        from using                        778  (_merge==2)

    matched                            25,097  (_merge==3)
    -----------------------------------------
*/
drop _merge
merge 1:1 cod_ccpp using "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2015.dta"
foreach x of local vars {
replace `x'_2010 = 0 if `x'_2010==.
replace `x'_2011 = 0 if `x'_2011==.
replace `x'_2012 = 0 if `x'_2012==.
replace `x'_2013 = 0 if `x'_2013==.
replace `x'_2014 = 0 if `x'_2014==.
replace `x'_2015 = 0 if _merge==1
}
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         3,604
        from master                     3,039  (_merge==1)
        from using                        565  (_merge==2)

    matched                            25,465  (_merge==3)
    -----------------------------------------
*/
drop _merge

gen ubigeo_ccpp = ubigeo_ccpp_2012
replace ubigeo_ccpp = ubigeo_ccpp_2013 if ubigeo_ccpp==""
replace ubigeo_ccpp = ubigeo_ccpp_2014 if ubigeo_ccpp==""
replace ubigeo_ccpp = ubigeo_ccpp_2015 if ubigeo_ccpp==""

save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010_2015.dta", replace

use "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010_2015.dta", clear
bys ubigeo_ccpp: gen rep=_N
keep if rep>1
gen idm_ce=_n
gen 	ccpp2=subinstr(ccpp," ","",.)
replace ccpp2=upper(ccpp2)
replace ccpp2=subinstr(ccpp2,"Á","A",.)
replace ccpp2=subinstr(ccpp2,"É","E",.)
replace ccpp2=subinstr(ccpp2,"Í","I",.)
replace ccpp2=subinstr(ccpp2,"Ó","O",.)
replace ccpp2=subinstr(ccpp2,"Ú","U",.)
replace ccpp2=subinstr(ccpp2,"Ñ","N",.)
replace ccpp2=subinstr(ccpp2,"Ð","D",.)
replace ccpp2=subinstr(ccpp2,"-","",.)
replace ccpp2=subinstr(ccpp2,"_","",.)
drop ubigeo_ccpp
reclink ubigeo_dist ccpp2 using "$input_dir\1 Raw\ubigeos_ccpp.dta", idm(idm_ce) idu(idu_sisfoh)  gen(match) wnomatch(10 5) minscore(.6)
drop Uubigeo_dist idm_ce  ccpp2 Uccpp2 match idu_sisfoh rep _merge
gen		ubigeo_ccpp2 = ubigeo_ccpp_2012
replace ubigeo_ccpp2 = ubigeo_ccpp_2013 if ubigeo_ccpp2==""
replace ubigeo_ccpp2 = ubigeo_ccpp_2014 if ubigeo_ccpp2==""
replace ubigeo_ccpp2 = ubigeo_ccpp_2015 if ubigeo_ccpp2=="" 
replace ubigeo_ccpp = ubigeo_ccpp2 if ubigeo_ccpp==""
drop ubigeo_ccpp2
save "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010_2015_aux.dta", replace


use "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010_2015.dta", clear
bys ubigeo_ccpp: gen rep=_N
keep if rep==1
drop rep
append using "$input_dir\1 Raw\3 Minedu\Censo Escolar\CE_2010_2015_aux.dta"
drop if ubigeo_ccpp==""
egen	contmiss=rowmiss(_all)
sort ubigeo_ccpp contmiss
bys ubigeo_ccpp: gen rep=_N
bys ubigeo_ccpp: gen rep2=_n
keep if rep2==1
drop rep rep2 contmiss
save "$input_dir\2 Working\CE_2010_2015.dta", replace

*-----------------------------------*
*		Merge 2010-2015 Census		*
*-----------------------------------*
*		With District Capitals
use "$input_dir\2 Working\CE_2010_2015.dta", clear

collapse (sum) serv_ie_* num_ie_* tipo_ie_* ie_* tot* ,by(ubigeo_dist)

	foreach y in 2010 2011 2012 2013 2014 2015 {
	gen prop_ie_estatal_`y' = num_ie_estatal_`y' / num_ie_`y'
	gen prop_ie_serv_alim_`y' = serv_ie_alim_`y' / num_ie_`y'
	gen prop_ie_serv_salud_`y' = serv_ie_salud_`y' / num_ie_`y'
	gen prop_ie_serv_ninguno_`y' = serv_ie_ninguno_`y' / num_ie_`y'
	gen prop_ie_policomp_`y' = tipo_ie_policomp_`y' / num_ie_`y'
	gen prop_ie_polimulti_`y' = tipo_ie_polimulti_`y' / num_ie_`y'
	gen prop_ie_unimulti_`y' = tipo_ie_unimulti_`y' / num_ie_`y'
	gen prop_alum_estatal_`y' = tot_alum_estatal_`y' / tot_alum_`y'
	gen prop_alum_m_`y' = tot_alum_m_`y' / tot_alum_`y'
	gen prop_alum_m_estatal_`y' = tot_alum_m_estatal_`y' / tot_alum_estatal_`y'
	gen prop_alum_m_privada_`y' = tot_alum_m_privada_`y' / tot_alum_privada_`y' 
	gen prop_alum_m_primaria_`y' = tot_alum_m_primaria_`y' / tot_alum_primaria_`y'
	gen prop_alum_m_secundaria_`y' = tot_alum_m_secundaria_`y' / tot_alum_secundaria_`y'
	}

save "$input_dir\2 Working\minedu_district.dta", replace

*		Without District Capitals
use "$input_dir\2 Working\CE_2010_2015.dta", clear
gen		cod_cap = substr(ubigeo_ccpp,-4,4)
drop if cod_cap=="0001"
collapse (sum) serv_ie_* num_ie_* tipo_ie_* ie_* tot* ,by(ubigeo_dist)

	foreach y in 2010 2011 2012 2013 2014 2015 {
	gen prop_ie_estatal_`y' = num_ie_estatal_`y' / num_ie_`y'
	gen prop_ie_serv_alim_`y' = serv_ie_alim_`y' / num_ie_`y'
	gen prop_ie_serv_salud_`y' = serv_ie_salud_`y' / num_ie_`y'
	gen prop_ie_serv_ninguno_`y' = serv_ie_ninguno_`y' / num_ie_`y'
	gen prop_ie_policomp_`y' = tipo_ie_policomp_`y' / num_ie_`y'
	gen prop_ie_polimulti_`y' = tipo_ie_polimulti_`y' / num_ie_`y'
	gen prop_ie_unimulti_`y' = tipo_ie_unimulti_`y' / num_ie_`y'
	gen prop_alum_estatal_`y' = tot_alum_estatal_`y' / tot_alum_`y'
	gen prop_alum_m_`y' = tot_alum_m_`y' / tot_alum_`y'
	gen prop_alum_m_estatal_`y' = tot_alum_m_estatal_`y' / tot_alum_estatal_`y'
	gen prop_alum_m_privada_`y' = tot_alum_m_privada_`y' / tot_alum_privada_`y' 
	gen prop_alum_m_primaria_`y' = tot_alum_m_primaria_`y' / tot_alum_primaria_`y'
	gen prop_alum_m_secundaria_`y' = tot_alum_m_secundaria_`y' / tot_alum_secundaria_`y'
	}

save "$input_dir\2 Working\minedu_district_NoCapDist.dta", replace


