/*------------------------------------------------------------------------------*
| Title:			RD Estimations for Sisfoh 2013 outcomes at CCPP level		|
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

	1.	Import cleaned dataset at ccpp level and define control variables
	2.	Define program
	3.	Define inputs for the program and store results

*-------------------------------------------------------------------------------*/


*-----------------------------------*
*		Outcomes at CCPP Level		*
*-----------------------------------*
use "$input_dir/3 Coded/community_index_treated_sisfohccpp.dta", ///
	clear


/* Old set of controls
global	controls altitude_msnm log_distancia_capital poverty2007_caracthh ///
		poverty2007_servpub poverty2007_demogra prop_actividad_agricola2007 ///
		log_pob_ccpp_2007 urb_rur_ccpp_2007 prop_a13	
*/
		
	* New set of controls
global	controls altitude_msnm log_pob_ccpp_2007 poverty2007_demogra		
			
		
*-------------------------------*
*		Program definition		*
*-------------------------------*

global medbw_l = 0.010
global medbw_r = 0.012


/** Program 1 old: For outcomes with 2007 baseline	
	capture program drop rd_ccpp_ancova
	program define rd_ccpp_ancova
putexcel set "$output_dir\regressions\6 Working paper\Victimas RD - Outcomes at CCPP level.xlsx", sheet("Pooled CCPP") modify
	*putexcel C3 = ("$table")
	*sleep 0
	*putexcel D5 = ("RD no/covs. - optimal BW")
	*sleep 0
	*putexcel E5 = ("RD w/covs. - optimal BW - Poly.1")
	*sleep 0	
	*putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	*sleep 0
	*putexcel G5 = ("RD w/covs. - optimal BW - Poly.3")
	*sleep 0
	*putexcel H5 = ("RD w/covs. - optimal BW - Poly.4")
	*sleep 0	

	global cells D E F G H I J K L M N O P Q R S
	
local bl= 0
local vname = 7	
local cmean = 7
foreach y in $dep_ccpp {	


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
	sleep 0
	putexcel B`vname'=("`y'")
	
	/*
	Model 1
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	1	
	*/
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007') p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 2
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007') p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 3
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
		
	/*
	Model 4
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 5
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 6
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 7
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 8
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 9
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007') p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 10
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007') p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 11
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007' cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 12
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007' cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 13
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007' $controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 14
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007' $controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 15
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007' $controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 16
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(`2007' $controls cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
}

end
*/

/** Program 2 old: For outcomes without 2007 baseline
	capture program drop rd_ccpp
	program define rd_ccpp
putexcel set "$output_dir\regressions\6 Working paper\Victimas RD - Outcomes at CCPP level.xlsx", sheet("Pooled CCPP - No baseline") modify
	*putexcel C3 = ("$table")
	*sleep 0
	*putexcel D5 = ("RD no/covs. - optimal BW")
	*sleep 0
	*putexcel E5 = ("RD w/covs. - optimal BW - Poly.1")
	*sleep 0	
	*putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	*sleep 0
	*putexcel G5 = ("RD w/covs. - optimal BW - Poly.3")
	*sleep 0
	*putexcel H5 = ("RD w/covs. - optimal BW - Poly.4")
	*sleep 0	

	global cells D E F G H I J K L M N O P Q R S
	
local bl= 0
local vname = 7	
local cmean = 7
foreach y in $dep_ccpp {	


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
	sleep 0
	putexcel B`vname'=("`y'")
	
	/*
	Model 1
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	1	
	*/
	local p=1
		*local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs() p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 2
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs() p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 3
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
		
	/*
	Model 4
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 5
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 6
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 7
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 8
	
	RD method: 		RDRobust
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 9
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs() p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 10
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs() p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 11
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 12
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs(cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 13
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs($controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 14
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs($controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 15
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs($controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		

	/*
	Model 16
	
	RD method: 		RDRobust
	BW: 			Median MSE-Optimal BW
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	2	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		h($medbw_l $medbw_r) kernel(triangular) covs($controls cluster_dist) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
}

end
*/



** Program 1: For outcomes with 2007 baseline	(NEW ESTIMATIONS)
	capture program drop rd_ccpp_ancova2
	program define rd_ccpp_ancova2
putexcel set "$output_dir\regressions\6 Working paper\Victimas RD - Outcomes at CCPP level.xlsx", sheet("Pooled CCPP") modify

	global cells D E F G H I J K L M N O P Q R S
	
local bl= 0
local vname = 7	
local cmean = 7
foreach y in $dep_ccpp {	


	local vname =`vname'+5
	local cmean = `cmean'+5
	local coef = `cmean' + 1
	local ste = `cmean' + 2
	local obs = `cmean' + 3
	local bw = `cmean' + 4
	local bl = `bl' + 1

	sleep 0
	putexcel B`vname'=("`y'")
	
	/*
	Model 1
	
	RD method: 		RDRobust
	Sample:			Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	1	
	*/
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007') p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	
	/*
	Model 2
	
	RD method: 		RDRobust
	Sample: 		Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
		
	
	/*
	Model 3
	
	RD method: 		RDRobust
	Sample:			Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
		
	
	/*
	Model 5
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007') p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	
	/*
	Model 6
	
	RD method: 		RDRobust
	Sample: 		Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
		
	
	/*
	Model 7
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	
	/*
	Model 8
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
}

end


** Program 2: For outcomes without 2007 baseline (NEW ESTIMATIONS)
	capture program drop rd_ccpp2
	program define rd_ccpp2
putexcel set "$output_dir\regressions\6 Working paper\Victimas RD - Outcomes at CCPP level.xlsx", sheet("Pooled CCPP - No baseline") modify
	*putexcel C3 = ("$table")
	*sleep 0
	*putexcel D5 = ("RD no/covs. - optimal BW")
	*sleep 0
	*putexcel E5 = ("RD w/covs. - optimal BW - Poly.1")
	*sleep 0	
	*putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	*sleep 0
	*putexcel G5 = ("RD w/covs. - optimal BW - Poly.3")
	*sleep 0
	*putexcel H5 = ("RD w/covs. - optimal BW - Poly.4")
	*sleep 0	

	global cells D E F G H I J K L M N O P Q R S
	
local bl= 0
local vname = 7	
local cmean = 7
foreach y in $dep_ccpp {	


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
	sleep 0
	putexcel B`vname'=("`y'")
	
	/*
	Model 1
	
	RD method: 		RDRobust
	Sample:			Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	1	
	*/
	local p=1
		*local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs() p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
		
	/*
	Model 2
	
	RD method: 		RDRobust
	Sample:			Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
			
	/*
	Model 3
	
	RD method: 		RDRobust
	Sample:			Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 4
	
	RD method: 		RDRobust
	Sample:			Sur Andino
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
	

	/*
	Model 5
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	No FE
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs() p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO" | dpto=="SAN MARTIN"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
		
	/*
	Model 6
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		No controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO" | dpto=="SAN MARTIN"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	
			
	/*
	Model 7
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	No FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO" | dpto=="SAN MARTIN"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")		
	
	/*
	Model 8
	
	RD method: 		RDRobust
	Sample:			Sur Andino + San Martin
	BW: 			MSE-Optimal individual BW selection
	Controls: 		With controls
	Geographic FE: 	FE (Province)
	Polynomial: 	1	
	*/
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO" | dpto=="SAN MARTIN"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_dist) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 0
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 0
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 0
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO" | dpto=="SAN MARTIN"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 0
	putexcel `l'`cmean'=("`mean'")	

	
}

end


*-----------------------------------*
*		Inputs for estimations		*
*-----------------------------------*


	*global	table "\Sisfoh 2013 outcomes at CCPP level"
	global	dep_ccpp pob_ccpp_2013 pob_ccpp_2017 log_pob_ccpp_2013 				///
			log_pob_ccpp_2017 hog_ccpp_2013 viv_ccpp_2013 viv_ccpp_2017 		///
			log_hog_ccpp_2013 log_hog_ccpp_2017 prop_mujeres prop_edad_u1 		///
			prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 prop_edad_45_64 		///
			prop_edad_65 prop_edad_15

	global	dep_ccpp_2007 pob_ccpp_2007 pob_ccpp_2007 log_pob_ccpp_2007			///
			log_pob_ccpp_2007 hog_ccpp_2007 viv_ccpp_2007 viv_ccpp_2007			///
			log_hog_ccpp_2007 log_hog_ccpp_2007 prop_mujeres2007 prop_edad_u12007 ///
			prop_edad_1_142007 prop_edad_15_292007 prop_edad_30_442007 prop_edad_45_642007 ///
			prop_edad_652007 prop_edad_152007
	rd_ccpp_ancova2

	
	global dep_ccpp prop_edad_0_5 prop_edad_5_10 prop_edad_10_15 				///
			prop_edad_15_20 prop_edad_20_25 prop_edad_25_30 prop_edad_30_35 	///
			prop_edad_35_40 prop_edad_40_45 prop_edad_45_50 prop_edad_50_55 	///
			prop_edad_55_60 prop_edad_60_65 prop_edad_65_70 prop_edad_70_mas 	///
			sis_pnbi1 sis_pnbi2 sis_pnbi3 sis_pnbi5 		///
			prop_programa_ninguno prop_actividad_pecuaria prop_actividad_estatal
	rd_ccpp2
	
	/*
		
	global	table "\Minedu outcomes at CCPP level"
	global	dep_ccpp tiene_ie num_ie tiene_ie_estatal gestion_estatal 			/**
	**/				tiene_ie_privado gestion_privado prop_ie_estatal 			/**
	**/				alum_ie_2013 alum_ie_2014 alum_ie_2015 alum_ie_estatal_2013 /**
	**/				alum_ie_estatal_2014 alum_ie_estatal_2015 					/**
	**/				alum_ie_privado_2013 alum_ie_privado_2014 					/**
	**/				alum_ie_privado_2015 prop_alum_estatal_2013 				/**
	**/				prop_alum_estatal_2014 prop_alum_estatal_2015 				/**
	**/				score_lengua_2013 score_lengua_2014 score_lengua_2015		/**
	**/				score_mate_2013 score_mate_2014 score_mate_2015 			/**
	**/		ie_1_2013 ie_1_2014 ie_1_2015 num_ie_2013 num_ie_2014 num_ie_2015	/**
	**/		ie_estatal_1_2013 ie_estatal_1_2014 ie_estatal_1_2015				/**
	**/		num_ie_estatal_2013 num_ie_estatal_2014 num_ie_estatal_2015			/**
	**/		ie_privada_1_2013 ie_privada_1_2014 ie_privada_1_2015				/**
	**/		num_ie_privada_2013 num_ie_privada_2014 num_ie_privada_2015			/**
	**/		prop_ie_estatal_2013 prop_ie_estatal_2014 prop_ie_estatal_2015		/**
	**/		ie_primaria_1_2013 ie_primaria_1_2014 ie_primaria_1_2015			/**
	**/		ie_primaria_2013 ie_primaria_2014 ie_primaria_2015		/**
	**/		ie_secundaria_1_2013 ie_secundaria_1_2014 ie_secundaria_1_2015		/**
	**/		ie_secundaria_2013 ie_secundaria_2014 ie_secundaria_2015 /**
	**/		serv_ie_1_2013 serv_ie_1_2014 num_ie_serv_1_2013		/**
	**/		num_ie_serv_1_2014 num_ie_serv_1_2015 prop_ie_serv_2013				/**
	**/		prop_ie_serv_2014 tot_alum_2013 tot_alum_2014		/**
	**/		tot_alum_2015 tot_alum_m_2013 tot_alum_m_2014 tot_alum_m_2015		/**
	**/		tot_alum_h_2013 tot_alum_h_2014 tot_alum_h_2015 prop_alum_m_2013	/**
	**/		prop_alum_m_2014 prop_alum_m_2015 tot_alum_primaria_2013 			/**
	**/		tot_alum_primaria_2014 tot_alum_primaria_2015 						/**
	**/	 	tot_alum_secundaria_2013 tot_alum_secundaria_2014 					/**
	**/		tot_alum_secundaria_2015 tot_alum_estatal_2013 tot_alum_estatal_2014 /**
	**/		tot_alum_estatal_2015 tot_alum_privada_2013 tot_alum_privada_2014	/**
	**/ 	tot_alum_privada_2015 prop_alum_ie_estatal_2013						/**
	**/		prop_alum_ie_estatal_2014 prop_alum_ie_estatal_2015
	
	*rd_ccpp2
	
use "$a\2 data\3 Coded\community_index_treated_cenagroccpp.dta", clear
	
	global	table "\Cenagro outcomes at CCPP level"
	global	dep_ccpp num_productores lee_escribe num_parc area_parc 			/**
	**/		area_agricola num_productor_m riego_aspersion riego_gravedad 		/**
	**/		destinoprod_venta num_cultivos ganaderia total_trab_mujeres 		/**
	**/		total_trab_hombres prop_productor_m prom_parc prom_area_parc 		/**
	**/		prom_area_agricola prom_tamano_hogar prom_edad_productor 			/**
	**/		prom_educ_productor prom_num_cultivos prop_titulo prop_parc_riego 	/**
	**/		prop_miembro_comision prop_riego_reservorio prop_canales_revest 	/**
	**/	prop_derecho_usoagua prop_usa_semillacertif prop_usa_fertorg 			/**
	**/		prop_usa_fertquim prop_usa_insectquim prop_usa_insectnoquim 		/**
	**/		prop_usa_herbicida prop_usa_fungicida prop_usa_controlbio 			/**
	**/		prop_usa_animtrabajo prop_usa_maquintrabajo prop_usa_aradohierro 	/**
	**/		prop_usa_aradopalo prop_usa_cosechadora prop_usa_fumigadoramotor 	/**
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
	**/		prom_num_benef prop_benef_1 prop_hogar_desague prop_productores_alfabeta prop_productores_m
	
	*rd_ccpp2	
	
	
use "$a\2 data\3 Coded\community_index_treated_minsaccpp.dta", clear
	
	global	table "\Minsa outcomes at CCPP level"
	global	dep_ccpp  num_cs_2013 categ_0_2013 categ_i1_2013 categ_i2_2013 categ_i3_2013 /**
	**/		categ_i4_2013  					/**
	**/		tipo_institucion_2013 num_cs_2014 categ_0_2014 categ_i1_2014 		/**
	**/		categ_i2_2014 categ_i3_2014 categ_i4_2014 tipo_institucion_2014 	/**
	**/		num_cs_2015 categ_0_2015 		/**
	**/		categ_i1_2015 categ_i2_2015 categ_i3_2015 categ_i4_2015 			/**
	**/	    tipo_institucion_2015 num_cs_2016 	/**
	**/		categ_0_2016 categ_i1_2016 categ_i2_2016 categ_i3_2016 categ_i4_2016 /**
	**/		tipo_institucion_2016 num_cs_2017 	/**
	**/		categ_0_2017 categ_i1_2017 categ_i2_2017 categ_i3_2017 categ_i4_2017 /**
	**/		tipo_institucion_2017 num_cs_2013_1 /**
	**/		num_cs_2014_1 num_cs_2015_1 num_cs_2016_1 num_cs_2017_1 			/**
	**/		tipo_institucion_2013_1 tipo_institucion_2014_1 					/**
	**/ 	tipo_institucion_2015_1 tipo_institucion_2016_1 tipo_institucion_2017_1
	
	*rd_ccpp2	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
