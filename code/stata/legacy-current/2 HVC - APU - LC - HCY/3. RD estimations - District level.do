/*------------------------------------------------------------------------------*
| Title:			RD Estimations for Sisfoh 2013 outcomes at CCPP level		|
| Project: 			Victimas RD								   					|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		This .do imports cleaned Sisfoh 2013 dataset at district level	|
|					to perform the RD estimations for selected outcomes			|
|                                                                               |
|Date Created: 22/1/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import cleaned dataset at ccpp level and define control variables
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
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"

*-----------------------------------*
*		Outcomes at CCPP Level		*
*-----------------------------------*


global	controls altitude_msnm log_distancia_capital_region ///
		log_pob_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra num_ccpp_2017 index_victim dist_minero
		
		
		
*-------------------------------------------*
*		Regressions with no baseline		*
*-------------------------------------------*
	capture program drop reg_dist
	program define reg_dist	
	global 	independent prop_ccpp_treat13
	global	cells D E F 
putexcel set "$a\3 output\regressions\2 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled Districts") modify
	putexcel C3 = ("$table")
	sleep 4000
	putexcel C5 = ("Control Mean")
	sleep 4000
	putexcel D5 = ("Reg - w/o covs.")
	sleep 4000
	putexcel E5 = ("Reg - w covs.")
	sleep 4000
	local bl=0
	local i=5
	foreach	y in $dep_dist {
	local i=`i'+4
	local s=`i'+1
	local r2=`i'+2
	local obs=`i'+3
	*local bl=`bl'+1
	local lab: variable label `y'
	sleep 4000
	putexcel A`i'=("`lab'")
	sleep 4000
	putexcel B`i'=("`y'")
	mean `y' if sample2==1 & $independent == 0
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 4000
	putexcel C`i'=("`mean'")
	sleep 4000
	* ---- Reg - No covariates ----
	local p=1
		local x: word `p' of $independent
		local l: word `p' of $cells
		reg `y' `x' i.cluster_dpto if sample2==1, r
		matrix b = e(b)
		matrix V = e(V)
		matrix df=e(df_r)
		local c_l = b[1,1]
		local c = string(`c_l', "%9.3f")
		local se_l = sqrt(V[1,1])
		local se = string(`se_l', "%9.3f")
		local d = df[1,1]
		local t = `c_l'/`se_l' 
		local pv = 2*ttail(`d',abs(`t'))
		sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
		sleep 4000
		local rsqrt_1=e(r2_a)
		local rsqrt=string(`rsqrt_1', "%9.3f")
		putexcel `l'`r2' = ("`rsqrt'")
		sleep 4000
		local observ_1=e(N)
		local observ=string(`observ_1', "%9.0f")
		putexcel `l'`obs' = ("`observ'")
		* ---- Reg - w/Covariates ----
	local p = `p'+1
		local l: word `p' of $cells
		reg `y' `x' $controls i.cluster_dpto if sample2==1, r
		matrix b = e(b)
		matrix V = e(V)
		matrix df=e(df_r)
		local c_l = b[1,1]
		local c = string(`c_l', "%9.3f")
		local se_l = sqrt(V[1,1])
		local se = string(`se_l', "%9.3f")
		local d = df[1,1]
		local t = `c_l'/`se_l' 
		local pv = 2*ttail(`d',abs(`t'))
		sleep 3500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")	
		sleep 4000
		local rsqrt_1=e(r2_a)
		local rsqrt=string(`rsqrt_1', "%9.3f")
		putexcel `l'`r2' = ("`rsqrt'")
		sleep 4000
		local observ_1=e(N)
		local observ=string(`observ_1', "%9.0f")
		putexcel `l'`obs' = ("`observ'")
	}	
	end
		
*---------------------------------------*
*		Regressions with baseline		*	
*---------------------------------------*

	capture program drop reg_dist_baseline
	program define reg_dist_baseline
	global 	independent prop_ccpp_treat13
	global	cells D E F 
putexcel set "$a\3 output\regressions\2 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled Districts - baseline") modify
	putexcel C3 = ("$table")
	sleep 4000
	putexcel C5 = ("Control Mean")
	sleep 4000
	putexcel D5 = ("Reg - w/o covs.")
	sleep 4000
	putexcel E5 = ("Reg - w covs.")
	sleep 4000
	local bl=0
	local i=5
	foreach	y in $dep_dist {
	local i=`i'+4
	local s=`i'+1
	local r2=`i'+2
	local obs=`i'+3
	local bl=`bl'+1
	local lab: variable label `y'
	sleep 4000
	putexcel A`i'=("`lab'")
	sleep 4000
	putexcel B`i'=("`y'")
	mean `y' if sample2==1 & $independent == 0
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 4000
	putexcel C`i'=("`mean'")
	sleep 4000
	* ---- Reg - No covariates ----
	local p=1
		local x: word `p' of $independent
		local l: word `p' of $cells

		reg `y' `x' i.cluster_dpto if sample2==1, r
		matrix b = e(b)
		matrix V = e(V)
		matrix df=e(df_r)
		local c_l = b[1,1]
		local c = string(`c_l', "%9.3f")
		local se_l = sqrt(V[1,1])
		local se = string(`se_l', "%9.3f")
		local d = df[1,1]
		local t = `c_l'/`se_l' 
		local pv = 2*ttail(`d',abs(`t'))
		sleep 4000
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
		sleep 4000
		local rsqrt_1=e(r2_a)
		local rsqrt=string(`rsqrt_1', "%9.3f")
		putexcel `l'`r2' = ("`rsqrt'")
		sleep 4000
		local observ_1=e(N)
		local observ=string(`observ_1', "%9.0f")
		putexcel `l'`obs' = ("`observ'")
		* ---- Reg - w/Covariates ----
	local p = `p'+1
		local l: word `p' of $cells
		local b: word `bl' of $baseline
		reg `y' `x' $controls `b' i.cluster_dpto if sample2==1, r
		matrix b = e(b)
		matrix V = e(V)
		matrix df=e(df_r)
		local c_l = b[1,1]
		local c = string(`c_l', "%9.3f")
		local se_l = sqrt(V[1,1])
		local se = string(`se_l', "%9.3f")
		local d = df[1,1]
		local t = `c_l'/`se_l' 
		local pv = 2*ttail(`d',abs(`t'))
		sleep 3500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")	
		sleep 4000
		local rsqrt_1=e(r2_a)
		local rsqrt=string(`rsqrt_1', "%9.3f")
		putexcel `l'`r2' = ("`rsqrt'")
		sleep 4000
		local observ_1=e(N)
		local observ=string(`observ_1', "%9.0f")
		putexcel `l'`obs' = ("`observ'")
	}	
	end

		
		
		
*-----------------------*
*		Regressions		*
*-----------------------*

*	Treat 13 - With districts capitals			
use "$a\2 data\3 Coded\community_index_treated_district.dta", clear
		
	global table "\Outcomes at district level - Dist Cap - Treat 13"
	global dep_dist	budget_exec_2013 budget_exec_2014 budget_exec_2015 			/**
	**/		budget_exec_2016 budget_exec_2017 pim_percapita_2013 pim_percapita_2017 dev_percapita_2013 dev_percapita_2017 num_productores lee_escribe 		/**
	**/		num_parc area_parc area_agricola num_productor_m riego_aspersion 	/**
	**/		riego_gravedad destinoprod_venta num_cultivos ganaderia 			/**
	**/		total_trab_mujeres total_trab_hombres prop_productor_m prom_parc 	/**
	**/		prom_area_parc prom_area_agricola prom_tamano_hogar prop_venta 		/**
	**/		prom_edad_productor prom_educ_productor prom_num_cultivos 			/**
	**/		prop_titulo prop_parc_riego prop_miembro_comision 					/**
	**/		prop_riego_reservorio prop_canales_revest prop_derecho_usoagua 		/**
	**/		prop_usa_semillacertif prop_usa_fertorg prop_usa_fertquim 			/**
	**/		prop_usa_insectquim prop_usa_insectnoquim prop_usa_herbicida 		/**
	**/		prop_usa_fungicida prop_usa_controlbio prop_usa_animtrabajo 		/**
	**/		prop_usa_maquintrabajo prop_usa_aradohierro prop_usa_aradopalo 		/**
	**/		prop_usa_cosechadora prop_usa_fumigadoramotor 						/**
	**/		prop_usa_fumigadoramanual prop_usa_molino prop_usa_pocadorapasto 	/**
	**/		prop_usa_trilladora prop_usa_motorbombeo prop_tiene_vacuno 			/**
	**/		prom_num_vacuno prop_tiene_ovino prom_num_ovino prop_tiene_alpaca 	/**
	**/		prom_num_alpaca prop_ganaderia prop_usa_vacuna prop_usa_desparasita /**
	**/		prop_usa_disificacion prop_usa_alimbal prop_usa_insemin 			/**
	**/		prop_capacitacion prop_asistencia prop_asesoriaempre 				/**
	**/		prop_capacitacion_estatal prop_capacitacion_privada prop_credito 	/**
	**/		prop_tiene_trabremun prop_trab_mujeres prom_trab_mujeres 			/**
	**/		prop_asociacion prop_agro_suficiente prom_ratiosexo 				/**
	**/		prom_ratioparticipaagro prop_benef_juntos prop_benef_vasoleche 		/**
	**/		prop_benef_desalm prop_benef_cunamas prop_benef_bonograt 			/**
	**/		prom_num_benef prop_benef_1 prop_hogar_desague 						/**
	**/		prop_productores_alfabeta prop_productores_m 
		
	reg_dist
		
	global table "\Outcomes at district level - Dist Cap - Treat 13"
	global dep_dist log_pob_2013 num_cs_2013 tipo_institucion_2013 				/**
	**/		sum_conflict_2013 sum_conf_violent_2013 sum_resuelto_2013 			/**
	**/		sum_conflict_active_2013 conflict_yn_2013 conflict_active_yn_2013

	global baseline log_pob_2007 num_cs_2007 tipo_institucion_2007 				/**
	**/		sum_conflict_2007 sum_conf_violent_2007 sum_resuelto_2007 			/**
	**/		sum_conflict_active_2007 sum_conflict_2007 sum_conflict_2007
		
	reg_dist_baseline	
		
*	Treat 13 - Without districts capitals		
use "$a\2 data\3 Coded\community_index_treated_district_NoDistCap.dta", clear	
		
		
	global table "\Outcomes at district level - No Dist Cap - Treat 13"
	global dep_dist	num_productores lee_escribe 		/**
	**/		num_parc area_parc area_agricola num_productor_m riego_aspersion 	/**
	**/		riego_gravedad destinoprod_venta num_cultivos ganaderia 			/**
	**/		total_trab_mujeres total_trab_hombres prop_productor_m prom_parc 	/**
	**/		prom_area_parc prom_area_agricola prom_tamano_hogar prop_venta 		/**
	**/		prom_edad_productor prom_educ_productor prom_num_cultivos 			/**
	**/		prop_titulo prop_parc_riego prop_miembro_comision 					/**
	**/		prop_riego_reservorio prop_canales_revest prop_derecho_usoagua 		/**
	**/		prop_usa_semillacertif prop_usa_fertorg prop_usa_fertquim 			/**
	**/		prop_usa_insectquim prop_usa_insectnoquim prop_usa_herbicida 		/**
	**/		prop_usa_fungicida prop_usa_controlbio prop_usa_animtrabajo 		/**
	**/		prop_usa_maquintrabajo prop_usa_aradohierro prop_usa_aradopalo 		/**
	**/		prop_usa_cosechadora prop_usa_fumigadoramotor 						/**
	**/		prop_usa_fumigadoramanual prop_usa_molino prop_usa_pocadorapasto 	/**
	**/		prop_usa_trilladora prop_usa_motorbombeo prop_tiene_vacuno 			/**
	**/		prom_num_vacuno prop_tiene_ovino prom_num_ovino prop_tiene_alpaca 	/**
	**/		prom_num_alpaca prop_ganaderia prop_usa_vacuna prop_usa_desparasita /**
	**/		prop_usa_disificacion prop_usa_alimbal prop_usa_insemin 			/**
	**/		prop_capacitacion prop_asistencia prop_asesoriaempre 				/**
	**/		prop_capacitacion_estatal prop_capacitacion_privada prop_credito 	/**
	**/		prop_tiene_trabremun prop_trab_mujeres prom_trab_mujeres 			/**
	**/		prop_asociacion prop_agro_suficiente prom_ratiosexo 				/**
	**/		prom_ratioparticipaagro prop_benef_juntos prop_benef_vasoleche 		/**
	**/		prop_benef_desalm prop_benef_cunamas prop_benef_bonograt 			/**
	**/		prom_num_benef prop_benef_1 prop_hogar_desague 						/**
	**/		prop_productores_alfabeta prop_productores_m 
		
	reg_dist
		
	global table "\Outcomes at district level - Dist Cap - Treat 13"
	global dep_dist log_pob_2013 num_cs_2013 tipo_institucion_2013 				/**
	**/		sum_conflict_2013 sum_conf_violent_2013 sum_resuelto_2013 			/**
	**/		sum_conflict_active_2013 conflict_yn_2013 conflict_active_yn_2013

	global baseline log_pob_2007 num_cs_2007 tipo_institucion_2007 				/**
	**/		sum_conflict_2007 sum_conf_violent_2007 sum_resuelto_2007 			/**
	**/		sum_conflict_active_2007 sum_conflict_2007 sum_conflict_2007
		
	reg_dist_baseline	

