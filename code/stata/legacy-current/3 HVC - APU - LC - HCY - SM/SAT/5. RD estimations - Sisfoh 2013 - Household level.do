/*------------------------------------------------------------------------------*
| Title:			RD Estimations for Sisfoh 2013 outcomes at Household level	|
| Project: 			Victimas RD								   					|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		This .do imports cleaned Sisfoh 2013 dataset at CCPP level	|
|					to perform the RD estimations for selected outcomes			|
|                                                                               |
|Date Created: 16/10/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import cleaned dataset at household level and define control variables
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
*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"
global a "D:\Dropbox\VictimasRD"

*---------------------------------------*
*		Outcomes at Household Level		*
*---------------------------------------*

use "$a\2 data\3 Coded\SAT\community_index_treated_sisfohhogpers_pbi.dta", clear

gen pbi_2007_pc=a_2007/pob_ccpp_2007
gen pbi_2013_pc=a_2013/pob_ccpp_2013
gen pbi_2017_pc=a_2017/pob_ccpp_2017

global	controls altitude_msnm log_distancia_capital prop_a13 ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra pbi_2007_pc
	
*-------------------------------*
*		Program definition		*
*-------------------------------*	
		
	capture program drop rd_household
	program define rd_household

putexcel set "$a\3 output\regressions\5 Huancavelica-Apurimac-La Convencion-Huancayo-San Martin\$table.xls", sheet("Pooled Households") modify
	putexcel C3 = ("$table")
	sleep 4000
	putexcel D5 = ("RD no/covs. - optimal BW")
	sleep 4000
	putexcel E5 = ("RD w/covs. - optimal BW")
	sleep 4000	
	putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	sleep 4000
	putexcel G5 = ("RD no/covs. - Imposing rand. inf. window")
	sleep 4000	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 4000	
	putexcel I5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 4000
	putexcel C5 = ("Control mean")
	sleep 4000

	global cells D E F G H I
	
local bl= 0
local i = 5	
foreach y in $dep_hog {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 4000
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO" | dpto=="SAN MARTIN"), 				///
	over(treat_13) vce(cl cluster_dist) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 4000
	putexcel C`i'=("`mean'")

	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) 
		
	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates -  Optimal Bandwidth selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) 

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	*RD including covariates - Optimal Bandwidth selection - 2nd grade poly.
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) p(2) kernel(triangular) covs($controls)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	

	*RD not including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) h(0.015)   ///
		kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) h(0.015)	///
		kernel(triangular) covs($controls)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection - 2nd grade Polynomy
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" |	 	///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) 	///
		kernel(triangular) p(2) covs($controls) 

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
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
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
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
	sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4000
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4000
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	*/
}

end


*-----------------------------------*
*		Inputs for estimations		*
*-----------------------------------*


global	table "\Sisfoh 2013 outcomes at Household level"
global	dep_hog sisf_pared_ladrillo sisf_pared_piedra sisf_pared_adobe 			/**
	**/		sisf_pared_quincha sisf_pared_madera sisf_piso_parquet 				/**
	**/		sisf_piso_lamina sisf_piso_tabla sisf_piso_cemento sisf_piso_tierra /**
	**/		sisf_techo_paja sisf_techo_teja sisf_techo_madera 					/**
	**/		sisf_techo_concreto sisf_agua_redpub sisf_agua_redpubdentro sisf_agua_redpubfuera 	/**
	**/		sisf_agua_pilon sisf_agua_pozo sisf_agua_rio 						/**
	**/		sisf_saneamiento_redpub sisf_saneamiento_redpubdentro sisf_saneamiento_redpubfuera 			/**
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
	**/		ratio_ocupacion_jubilado pbi_2013_pc

rd_household




