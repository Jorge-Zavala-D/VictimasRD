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

*-----------------------*
*       DIRECTORY       *
*-----------------------*
	clear all
	set more off
	version 13
	
*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\jzavala\Dropbox\VictimasRD"
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"
global a "/Users/matthewbird/Dropbox/VictimasRD"

*-----------------------------------*
*		Outcomes at CCPP Level		*
*-----------------------------------*

*use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear
use "$a/2 data/3 Coded/community_index_treated_sisfohccpp.dta", clear

*global	controls altitude_msnm log_distancia_capital prop_a13 ///
*		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
*		poverty2007_demogra
		
global	controls altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010
		
*-------------------------------*
*		Program definition		*
*-------------------------------*

** Program 1: For outcomes with 2007 baseline
		
	capture program drop rd_ccpp
	program define rd_ccpp
putexcel set "$a\3 output\regressions\2 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled CCPP") modify
	putexcel C3 = ("$table")
	sleep 4000
	putexcel D5 = ("RD no/covs. - optimal BW")
	sleep 4000
	putexcel E5 = ("RD w/covs. - optimal BW - Poly.1")
	sleep 4000	
	putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	sleep 4000
	putexcel G5 = ("RD w/covs. - optimal BW - Poly.3")
	sleep 4000
	putexcel H5 = ("RD w/covs. - optimal BW - Poly.4")
	sleep 4000	

	global cells D E F G H
	
local bl= 0
local vname = 6	
local cmean = 6
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
	sleep 4000
	putexcel B`vname'=("`y'")
	
	*RD not including covariates - Optimal Bandwidth selection
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
	sleep 4000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(1)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(3)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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
		bwselect(msecomb2) kernel(triangular) covs(`2007' $controls) p(4)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4000
		if `pv'>0.10 				putexcel `l'`coef' = ("`c'") `l'`ste'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`coef' = ("`c'*") `l'`ste'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`coef' = ("`c'**") `l'`ste'=("(`se')") 
		if `pv'<0.01				putexcel `l'`coef' = ("`c'***") `l'`ste'=("(`se')")
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


** Program 2: For outcomes without 2007 baseline

	capture program drop rd_ccpp2
	program define rd_ccpp2
putexcel set "$a\3 output\regressions\2 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled ccpp") modify
	putexcel C3 = ("$table")
	sleep 4000
	putexcel D5 = ("RD no/covs. - optimal BW")
	sleep 4000
	putexcel E5 = ("RD w/covs. - optimal BW - Poly.1")
	sleep 4000	
	putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	sleep 4000
	putexcel G5 = ("RD w/covs. - optimal BW - Poly.3")
	sleep 4000
	putexcel H5 = ("RD w/covs. - optimal BW - Poly.4")
	sleep 4000	

	global cells D E F G H
	
local bl= 0
local i = 5	
foreach y in $dep_ccpp {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 4000
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | 				///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), 				///
	over(treat_13) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 4000
	putexcel C`i'=("`mean'")

	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		*local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) p(1)

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
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)

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
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(2)

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
	
}

end

*-----------------------------------*
*		Inputs for estimations		*
*-----------------------------------*


	global	table "\Sisfoh 2013 outcomes at CCPP level"
	global	dep_ccpp prop_pared_ladrillo prop_pared_piedra prop_pared_adobe		/**
		**/		prop_pared_quincha prop_pared_madera prop_pared_estera 			/**
		**/		prop_piso_parquet prop_piso_lamina prop_piso_loseta 			/**
		**/		prop_piso_tabla prop_piso_cemento prop_piso_tierra 				/**
		**/		prop_agua_redpubdentro prop_agua_redpubfuera prop_agua_pilon 	/**
		**/		prop_agua_pozo prop_agua_rio 									/**
		**/		prop_saneamiento_redpubdentro prop_saneamiento_redpubfuera 		/**
		**/		prop_saneamiento_pozo prop_saneamiento_letrina 					/**
		**/		prop_saneamiento_rio prop_saneamiento_ninguno 					/**
		**/		prop_combust_elect prop_combust_gas  							/**
		**/		prop_combust_carbon prop_combust_lea prop_combust_bosta 		/**
		**/		prop_combust_nococina prop_asset_equipsonido prop_asset_tvcolor	/**
		**/		prop_asset_refri prop_asset_telefonofijo prop_asset_lavadora 	/**
		**/		prop_asset_compu prop_asset_internet prop_asset_cable 			/**
		**/		prop_asset_celular prop_asset_ninguno prop_edad_u1 				/**
		**/		prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 					/**
		**/		prop_edad_45_64 prop_edad_65 edad_15mas prop_edad_15 			/**
		**/		prop_seguro_essalud prop_seguro_sis prop_seguro_ninguno 		/**
		**/		prop_lee_si prop_lee_no prop_educ_ninguno prop_educ_inicial 	/**
		**/		prop_educ_primaria prop_educ_secundaria prop_educ_tecnica 		/**
		**/		prop_educ_universitaria prop_actividad_agopec prop_actividad_agricola 				/**
		**/		prop_actividad_pesquera prop_actividad_minera 					/**
		**/		prop_actividad_comercial prop_actividad_servicios 				/**
		**/		prop_pea_ocupada prop_pea_desocupada prop_mujeres prop_edad_0_5 /**
		**/		prop_edad_5_10 prop_edad_10_15 prop_edad_15_20 prop_edad_20_25  /**
		**/		prop_edad_25_30 prop_edad_30_35 prop_edad_35_40 prop_edad_40_45 /**
		**/ 	prop_edad_45_50 prop_edad_50_55 prop_edad_55_60 prop_edad_60_65 /**
		**/		prop_edad_65_70 prop_edad_70_mas

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
		**/		prop_educ_universitaria2007 prop_actividad_agricola2007 prop_actividad_agricola2007 					/**
		**/		prop_actividad_pesquera2007 prop_actividad_minera2007 						/**
		**/		prop_actividad_comercial2007 prop_actividad_servicios2007 					/**
		**/		prop_pea_ocupada2007 prop_pea_desocupada2007 prop_mujeres2007 prop_edad_u12007 /**
		**/		prop_edad_1_142007 prop_edad_1_142007 prop_edad_15_292007 prop_edad_15_292007  /**
		**/		prop_edad_15_292007 prop_edad_30_442007 prop_edad_30_442007 prop_edad_30_442007 /**
		**/ 	prop_edad_45_642007 prop_edad_45_642007 prop_edad_45_642007 prop_edad_45_642007 /**
		**/		prop_edad_652007 prop_edad_652007

	rd_ccpp

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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
