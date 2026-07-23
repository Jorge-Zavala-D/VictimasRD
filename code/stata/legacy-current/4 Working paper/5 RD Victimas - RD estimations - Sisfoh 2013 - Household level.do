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

*---------------------------------------*
*		Outcomes at Household Level		*
*---------------------------------------*

*use "C:\Users\jzava\Dropbox\VictimasRD/2 data/3 Coded/SAT/community_index_treated_sisfohhogpers_pbi.dta", clear

use "$input_dir/3 Coded/community_index_treated_sisfohhogpers.dta", clear

	
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
/*		
	capture program drop rd_household
	program define rd_household

putexcel set "$a\3 output\regressions\4 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled Households") modify
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
foreach y in $dep_hog {	


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
	sleep 3500
	putexcel B`vname'=("`y'")	
	
	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) 
		
	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 3500
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 3500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 3500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")	
	
	*RD including covariates -  Optimal Bandwidth selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1) masspoints(off)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 3500
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 3500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 3500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
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
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 3500
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 3500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 3500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
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
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(3)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 3500
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 3500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 3500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
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
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(4)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 3500
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 3500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 3500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	mean `y' if index_cutBC<`bw_r1' & index_cutBC>-`bw_l1' & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
}

end
*/

/*
	* OLD ESTIMATIONS
	capture program drop rd_household
	program define rd_household
putexcel set "$output_dir\regressions\6 Working paper\Victimas RD - Outcomes at household level.xlsx", sheet("Pooled CCPP - No baseline") modify
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
foreach y in $dep_hog {	


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
		bwselect(msecomb2) kernel(triangular) covs() p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs(cluster_prov) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs(cluster_prov) p(2)

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
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_prov) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_prov) p(2)

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
		h($medbw_l $medbw_r) kernel(triangular) covs() p(1) masspoints(off)

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
		h($medbw_l $medbw_r) kernel(triangular) covs(cluster_prov) p(1) masspoints(off)

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
		h($medbw_l $medbw_r) kernel(triangular) covs(cluster_prov) p(2)

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
		h($medbw_l $medbw_r) kernel(triangular) covs($controls) p(1) masspoints(off)

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
		h($medbw_l $medbw_r) kernel(triangular) covs($controls cluster_prov) p(1) masspoints(off)

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
		h($medbw_l $medbw_r) kernel(triangular) covs($controls cluster_prov) p(2)

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


	* NEW ESTIMATIONS (OLD + WITH SAN MARTIN)
	capture program drop rd_household2
	program define rd_household2
putexcel set "$output_dir\regressions\6 Working paper\Victimas RD - Outcomes at household level.xlsx", sheet("Pooled CCPP - No baseline") modify


	global cells D E F G H I J K L M N O P Q R S
	
local bl= 0
local vname = 7	
local cmean = 7
foreach y in $dep_hog {	


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
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs() p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs(cluster_prov) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_prov) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs() p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs(cluster_prov) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1) masspoints(off)

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
		bwselect(msecomb2) kernel(triangular) covs($controls cluster_prov) p(1) masspoints(off)

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


*global	table "\Sisfoh 2013 outcomes at Household level - v2 (control IE Estatal 2010)"
global	dep_hog ratio_sexo num_perso prog_1 tiene_prog	/**
	**/		prog_vasoleche_1 prog_comedorpop_1 prog_desalm_1 prog_papyap_1 		/**
	**/		prog_canastaalim_1 prog_juntos_1 prog_techo_1 prog_pension65_1 		/**
	**/		prog_cunamas_1 prog_otro_1 num_prog ratio_prog ocupado_1 ocupado 	/**
	**/		ocupacion_dep_1 ratio_ocupacion_dep ocupacion_indep_1 				/**
	**/		ratio_ocupacion_indep ocupacion_trabhog_1 ratio_ocupacion_trabhog 	/**
	**/		ocupacion_famnorem_1 ratio_ocupacion_famnorem ocupacion_desemp_1 	/**
	**/		ratio_ocupacion_desemp ocupacion_hogar_1 ratio_ocupacion_hogar		/**
	**/		ocupacion_estud_1 ratio_ocupacion_estud ocupacion_jubilado_1 		/**
	**/		ratio_ocupacion_jubilado trabaja_agricola_1							/**
	**/		ratio_trabaja_agricola trabaja_pecuaria_1 ratio_trabaja_pecuaria 	/**
	**/		trabaja_forestal_1 ratio_trabaja_forestal trabaja_pesquera_1 		/**
	**/		ratio_trabaja_pesquera trabaja_minera_1 ratio_trabaja_minera 		/**
	**/		trabaja_artesanal_1 ratio_trabaja_artesanal trabaja_comercial_1 	/**
	**/		ratio_trabaja_comercial trabaja_servicios_1 ratio_trabaja_servicios /**
	**/		trabaja_otro_1 ratio_trabaja_otro trabaja_gobierno_1 				/**
	**/		ratio_trabaja_gobierno noescuela_1 seguro_1 num_seguro tiene_seguro 	/**
	**/		ratio_seguro seguro_essalud_1 seguro_sis_1  		/**
	**/		seguro_privado_1  seguro_ninguno_1 					/**
	**/		nbi1_hogarinadecuado nbi2_hacinamiento nbi3_sindesague 				/**
	**/		nbi4_noescuela nbi5_altadependencia nbi_sum ifh_combust ifh_seguro	/**
	**/		ifh_bienesriqueza ifh_educjefe ifh ratio_hacinamiento 				/**
	**/		ratio_dependencia num_bienesriqueza
	
	
	
	
	
rd_household2



