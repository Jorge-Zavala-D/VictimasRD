/*------------------------------------------------------------------------------*
| Title:			RD Estimations for Sisfoh 2013 outcomes at Individual level	|
| Project: 			Victimas RD								   					|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		This .do imports cleaned Sisfoh 2013 dataset at Individual	|
|					level to perform the RD estimations for selected outcomes	|
|                                                                               |
|Date Created: 16/10/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import cleaned dataset at individual level and define control variables
	2.	Define program
	3.	Define inputs for the program and store results

*-------------------------------------------------------------------------------*/

*-----------------------*
*       DIRECTORY       *
*-----------------------*
	clear all
	set more off
	version 13
	
*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\jzavala\Dropbox\VictimasRD"
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"
*global a "/Users/matthewbird/Dropbox/VictimasRD"

*-------------------------------------------*
*		Outcomes at Individual Level		*
*-------------------------------------------*

*use "$a\2 data\3 Coded\community_index_treated_sisfohpers_both.dta", clear
*use "$a/2 data/3 Coded/community_index_treated_sisfohpers_both.dta", clear
use "$a/2 data/3 Coded/community_index_treated_cpv2017ind.dta", clear

*global	controls altitude_msnm log_distancia_capital prop_a13 ///
*		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra 	///
*		num_pershogar_2017 edad_2017
		
global	controls altitude_msnm log_distancia_capital prop_a13 ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra 	///
		num_pershogar_2017 edad_2017 ie_estatal_1_2010		

		*	controlar por edad de la mujer y nivel educativo de la mujer (para hombres tambien)
*-------------------------------*
*		Program definition		*
*-------------------------------*		
	
	capture program drop rd_individuals
	program define rd_individuals
*putexcel set "$a\3 output\regressions\2 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled individuals") modify
putexcel set "$a/3 output/regressions/2 Huancavelica-Apurimac-La Convencion-Huancayo/Matthew/$table.xls", sheet("Pooled individuals") modify
	putexcel C3 = ("$table")
	sleep 3500
	putexcel D5 = ("RD no/covs. - optimal BW")
	sleep 3500
	putexcel E5 = ("RD w/covs. - optimal BW - Poly.1")
	sleep 3500	
	putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	sleep 3500
	putexcel G5 = ("RD w/covs. - optimal BW - Poly.3")
	sleep 3500
	putexcel H5 = ("RD w/covs. - optimal BW - Poly.4")
	sleep 3500	

	global cells D E F G H
	
local bl= 0
local vname = 6	
local cmean = 6
foreach y in $dep_ind {	


	local vname =`vname'+5
	local cmean = `cmean'+5
	local coef = `cmean' + 1
	local ste = `cmean' + 2
	local obs = `cmean' + 3
	local bw = `cmean' + 4
	local bl = `bl' + 1

	*local i=`i'+4
	*local s=`i'+1
	*local obs=`i'+2
	*local bw=`i'+3
	*local bl=`bl'+1
	sleep 2000
	putexcel B`vname'=("`y'")	
	
	*mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	*dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	*over(treat_17) vce(cl cluster_dist) 
	*matrix mean_1=e(b)
	*local mean_2=mean_1[1,1]
	*local mean=string(`mean_2', "%9.3f")
	*sleep 2000
	*putexcel D`cmean'=("`mean'")

	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) p(1)

	
	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
		
	*RD including covariates - Optimal Bandwidht selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y'  index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
	*RD including covariates - Optimal Bandwidth selection - 2nd grade poly.
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
	*RD including covariates - Optimal Bandwidth selection - 3rd grade poly.
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(3)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
	*RD including covariates - Optimal Bandwidth selection - 4th grade poly.
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(4)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 2000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_17)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
}
	end

*-------------------------------*
*		Inputs for program		*
*-------------------------------*

*global table "\Censo 2017 outcomes at Individual level - Pooled Individuals"
global table "/Censo 2017 outcomes at Individual level - Pooled Individuals"

global dep_ind sex_2017 nivel_educ_2017 nivel_educ2_2017 nivel_educ_ninguno 	/**
		**/	nivel_educ_inicial nivel_educ_primaria nivel_educ_secundaria 		/**
		**/	nivel_educ_tecnica analfab_2017 edad_6_12_noescuela_17 gestante_2017 /**
		**/	jefe_hogar_2017 ocupado_2017 trabaja_agro_2017 trabaja_mineria_2017 /**
		**/	trabaja_manuf_2017 trabaja_constr_2017 			/**
		**/ trabaja_comercio_2017 trabaja_transp_2017 trabaja_turismo_2017 		/**
		**/	trabaja_actprof_2017 trabaja_gob_2017 trabaja_educ_2017 			/**
		**/	trabaja_otro_2017 trabaja_otro2_2017 ocupacion_dep_2017 			/**
		**/ ocupacion_indep_2017 ocupacion_desemp_2017 ocupacion_hogar_2017		/**
		**/ seg_sis_2017 seg_essalud_2017 seg_ffaa_2017 seg_privado_2017 		/**
		**/ seg_otro_2017 seg_ninguno_2017 num_seg_ind_17 edad_0_5_2017 		/**
		**/ edad_5_10_2017 edad_10_15_2017 edad_15_20_2017 edad_20_25_2017 		/**
		**/ edad_25_30_2017 edad_30_35_2017 edad_35_40_2017 edad_40_45_2017 	/**
		**/ edad_45_50_2017 edad_50_55_2017 edad_55_60_2017 edad_60_65_2017 	/**
		**/ edad_65_70_2017 edad_70_mas_2017 edad_20_30_2017 menor_edad_2017	/***
		**/ migracion migracion_escala migracion_escala_ccpp 					/***
		**/ migracion_escala_dist migracion_escala_prov migracion_escala_dpto

		*trabaja_otro2_2017 =1 if trabaja_serv_2017==1 | trabaja_info_2017==1 | trabaja_fin_2017==1 | trabaja_inmob_2017==1 | trabaja_salud_2017==1
		
rd_individuals		
		
*global table "\Censo 2017 outcomes at Individual level - Non-migrants"
global table "/Censo 2017 outcomes at Individual level - Non-migrants"

	keep if migracion == 0
	
rd_individuals
		

*global	dep_ind nivel_educ nivel_educ2 nivel_educ3_ninguno nivel_educ3_primaria /**
	**/	nivel_educ3_secundaria nivel_educ3_superior analfab edad_6_12_noescuela /**
	**/	gestante jefe_hogar ocupado trabaja_agricola trabaja_pecuaria 			/**
	**/ trabaja_minera trabaja_artesanal trabaja_comercial trabaja_servicios 	/**
	**/	trabaja_otro trabaja_gobierno trabaja_otro2 ocupacion_dep 				/**
	**/	ocupacion_indep ocupacion_famnorem ocupacion_desemp ocupacion_hogar 	/**
	**/	ocupacion_estud ocupacion_otro2 seg_essalud seg_ffaapnp seg_privado 	/**
	**/	seg_otro2 seg_ninguno num_seguro_ind tiene_seguro prog_vasoleche 		/**
	**/	prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos 	/**
	**/	prog_pension65 prog_otro2 prog_ninguno num_prog_ind tiene_prog edad_0_5 /**
	**/	edad_5_10 edad_10_15 edad_15_20 edad_20_25  /**
	**/	edad_25_30 edad_30_35 edad_35_40 edad_40_45 /**
	**/ edad_45_50 edad_50_55 edad_55_60 edad_60_65 /**
	**/	edad_65_70 edad_70_mas trabaja_agropec
	
	* trabaja_otro2: trabaja_forestal trabaja_pesquera 
	* prog_otro2: prog_techo prog_cunamas prog_otro
	* seg_otro2: seg_sis seg_otro 
	* ocupacion_otro2: ocupacion_trabhog ocupacion_jubilado
	
*rd_individuals

