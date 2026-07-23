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
*global a "D:\Dropbox\VictimasRD"
global a "/Users/matthewbird/Dropbox/VictimasRD"

*-----------------------------------*
*		Outcomes at CCPP Level		*
*-----------------------------------*

*use "$a\2 data\3 Coded\community_index_treated_cpv2017ccpp_pbi.dta", clear
use "$a/2 data/3 Coded/SAT/community_index_treated_cpv2017ccpp_pbi.dta", clear

gen pbi_2007_pc=a_2007/pob_ccpp_2007
gen pbi_2013_pc=a_2013/pob_ccpp_2013
gen pbi_2017_pc=a_2017/pob_ccpp_2017

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
*putexcel set "$a\3 output\regressions\4 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled CCPP") modify
putexcel set "$a/3 output/regressions/4 Huancavelica-Apurimac-La Convencion-Huancayo/$table.xls", sheet("Pooled CCPP") modify
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
	
	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
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
	over(treat_17)
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
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
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
	over(treat_17)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
}

end


** Program 2: For outcomes without 2007 baseline and 2013 midline

	capture program drop rd_ccpp3
	program define rd_ccpp3
*putexcel set "$a\3 output\regressions\4 Huancavelica-Apurimac-La Convencion-Huancayo\$table.xls", sheet("Pooled CCPP") modify
putexcel set "$a/3 output/regressions/4 Huancavelica-Apurimac-La Convencion-Huancayo/$table.xls", sheet("Pooled CCPP") modify
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
local ml = 0
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
	local ml = `ml' + 1

	*local i=`i'+4
	*local s=`i'+1
	*local obs=`i'+2
	*local bw=`i'+3
	*local bl=`bl'+1
	sleep 4000
	putexcel B`vname'=("`y'")
	
	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local 2013: word `ml' of $dep_ccpp_2013
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' `2013') p(1)

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
	over(treat_17)
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
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(`2007' `2013' $controls) p(1)

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
		bwselect(msecomb2) kernel(triangular) covs(`2007' `2013' $controls) p(2)

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
		bwselect(msecomb2) kernel(triangular) covs(`2007' `2013' $controls) p(3)

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
		bwselect(msecomb2) kernel(triangular) covs(`2007' `2013' $controls) p(4)

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
	over(treat_17)
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 2000
	putexcel `l'`cmean'=("`mean'")		
	
}

end

*-----------------------------------*
*		Inputs for estimations		*
*-----------------------------------*


	*global	table "\Censo 2017 outcomes at CCPP level"
	global	table "Censo 2017 outcomes at CCPP level"
	global	dep_ccpp poverty2017_pared poverty2017_piso poverty2017_agua poverty2017_saneamiento poverty2017_bienesriqueza poverty2017_combust poverty2017_seguro poverty2017_analfabeta poverty2017_educ poverty2017_desempleo poverty2017_alumbrado prop_pared_ladrillo17 prop_pared_piedra17 prop_pared_adobe17 /**
		**/		prop_pared_quincha17 prop_pared_madera17 prop_pared_estera17 	/**
		**/		prop_piso_parquet17 prop_piso_lamina17 prop_piso_loseta17		/**
		**/		prop_piso_tabla17 prop_piso_cemento17 prop_piso_tierra17		/**
		**/		prop_agua_redpubdentro17 prop_agua_redpubfuera17 prop_agua_pilon17 	/**
		**/		prop_agua_pozo17 prop_agua_rio17 									/**
		**/		prop_desague_redpubdentro17 prop_desague_redpubfuera17 		/**
		**/		prop_desague_pozo17 prop_desague_letrina17 					/**
		**/		prop_desague_rio17 prop_desague_ninguno17 					/**
		**/		prop_combust_elect17 prop_combust_gas17  							/**
		**/		prop_combust_carbon17 prop_combust_lea17 prop_combust_bosta17 		/**
		**/		prop_asset_equipsonido17 prop_asset_tvcolor17	/**
		**/		prop_asset_refri17 prop_asset_telefonofijo17 prop_asset_lavadora17 	/**
		**/		prop_asset_compu17 prop_asset_internet17 prop_asset_cable17 			/**
		**/		prop_asset_celular17  				/**
		**/		prop_edad_1_14_17 prop_edad_15_29_17 prop_edad_30_44_17 					/**
		**/		prop_edad_45_64_17 prop_edad_65_17 edad_15mas_2017 			/**
		**/		prop_seguro_essalud17 prop_seguro_sis17 prop_seguro_ninguno17 		/**
		**/		prop_lee_si_17 prop_educ_ninguno17 prop_educ_inicial17 	/**
		**/		prop_educ_primaria17 prop_educ_secundaria17 prop_educ_tecnica17 		/**
		**/		prop_educ_universitaria17 prop_actividad_agropec17 prop_actividad_agropec17 				/**
		**/		prop_actividad_minera17 					/**
		**/		prop_actividad_comercial17 prop_actividad_servicios17 				/**
		**/		prop_ocupado_2017 prop_ocupado_desemp_17 prop_mujeres_2017 prop_edad_0_5_17 /**
		**/		prop_edad_5_10_17 prop_edad_10_15_17 prop_edad_15_20_17 prop_edad_20_25_17  /**
		**/		prop_edad_25_30_17 prop_edad_30_35_17 prop_edad_35_40_17 prop_edad_40_45_17 /**
		**/ 	prop_edad_45_50_17 prop_edad_50_55_17 prop_edad_55_60_17 prop_edad_60_65_17 /**
		**/		prop_edad_65_70_17 prop_edad_70_mas_17 pbi_2017_pc

	global	dep_ccpp_2007 poverty2007_pared poverty2007_piso poverty2007_agua poverty2007_saneamiento poverty2007_bienesriqueza poverty2007_combust poverty2007_seguro poverty2007_analfabeta poverty2007_educ poverty2007_desempleo poverty2007_alumbrado prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
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
		**/		prop_asset_equipsonido2007 prop_asset_tvcolor2007	/**
		**/		prop_asset_refri2007 prop_asset_telefonofijo2007 prop_asset_lavadora2007 	/**
		**/		prop_asset_compu2007 prop_asset_internet2007 prop_asset_cable2007 			/**
		**/		prop_asset_celular2007  				/**
		**/		prop_edad_1_142007 prop_edad_15_292007 prop_edad_30_442007 					/**
		**/		prop_edad_45_642007 prop_edad_652007 edad_15mas2007  		/**
		**/		prop_seguro_essalud2007 prop_seguro_sis2007 prop_seguro_ninguno2007 		/**
		**/		prop_lee_si2007 prop_educ_ninguno2007 prop_educ_inicial2007 /**
		**/		prop_educ_primaria2007 prop_educ_secundaria2007 prop_educ_tecnica2007 		/**
		**/		prop_educ_universitaria2007 prop_actividad_agricola2007 prop_actividad_agricola2007 					/**
		**/		prop_actividad_minera2007 						/**
		**/		prop_actividad_comercial2007 prop_actividad_servicios2007 					/**
		**/		prop_pea_ocupada2007 prop_pea_desocupada2007 prop_mujeres2007 prop_edad_u12007 /**
		**/		prop_edad_1_142007 prop_edad_1_142007 prop_edad_15_292007 prop_edad_15_292007  /**
		**/		prop_edad_15_292007 prop_edad_30_442007 prop_edad_30_442007 prop_edad_30_442007 /**
		**/ 	prop_edad_45_642007 prop_edad_45_642007 prop_edad_45_642007 prop_edad_45_642007 /**
		**/		prop_edad_652007 prop_edad_652007 pbi_2007_pc

	rd_ccpp

	

	
	
	*global	table "\Censo 2017 outcomes at CCPP level - 2013 covs"
	global	table "Censo 2017 outcomes at CCPP level - 2013 covs"
	global	dep_ccpp poverty2017_pared poverty2017_piso poverty2017_agua poverty2017_saneamiento poverty2017_bienesriqueza poverty2017_combust poverty2017_seguro poverty2017_analfabeta poverty2017_educ poverty2017_desempleo poverty2017_alumbrado prop_pared_ladrillo17 prop_pared_piedra17 prop_pared_adobe17 /**
		**/		prop_pared_quincha17 prop_pared_madera17 prop_pared_estera17 	/**
		**/		prop_piso_parquet17 prop_piso_lamina17 prop_piso_loseta17		/**
		**/		prop_piso_tabla17 prop_piso_cemento17 prop_piso_tierra17		/**
		**/		prop_agua_redpubdentro17 prop_agua_redpubfuera17 prop_agua_pilon17 	/**
		**/		prop_agua_pozo17 prop_agua_rio17 									/**
		**/		prop_desague_redpubdentro17 prop_desague_redpubfuera17 		/**
		**/		prop_desague_pozo17 prop_desague_letrina17 					/**
		**/		prop_desague_rio17 prop_desague_ninguno17 					/**
		**/		prop_combust_elect17 prop_combust_gas17  							/**
		**/		prop_combust_carbon17 prop_combust_lea17 prop_combust_bosta17 		/**
		**/		prop_asset_equipsonido17 prop_asset_tvcolor17	/**
		**/		prop_asset_refri17 prop_asset_telefonofijo17 prop_asset_lavadora17 	/**
		**/		prop_asset_compu17 prop_asset_internet17 prop_asset_cable17 			/**
		**/		prop_asset_celular17  				/**
		**/		prop_edad_1_14_17 prop_edad_15_29_17 prop_edad_30_44_17 					/**
		**/		prop_edad_45_64_17 prop_edad_65_17 edad_15mas_2017 			/**
		**/		prop_seguro_essalud17 prop_seguro_sis17 prop_seguro_ninguno17 		/**
		**/		prop_lee_si_17 prop_educ_ninguno17 prop_educ_inicial17 	/**
		**/		prop_educ_primaria17 prop_educ_secundaria17 prop_educ_tecnica17 		/**
		**/		prop_educ_universitaria17 prop_actividad_agropec17 prop_actividad_agropec17 				/**
		**/		prop_actividad_minera17 					/**
		**/		prop_actividad_comercial17 prop_actividad_servicios17 				/**
		**/		prop_ocupado_2017 prop_ocupado_desemp_17 prop_mujeres_2017 prop_edad_0_5_17 /**
		**/		prop_edad_5_10_17 prop_edad_10_15_17 prop_edad_15_20_17 prop_edad_20_25_17  /**
		**/		prop_edad_25_30_17 prop_edad_30_35_17 prop_edad_35_40_17 prop_edad_40_45_17 /**
		**/ 	prop_edad_45_50_17 prop_edad_50_55_17 prop_edad_55_60_17 prop_edad_60_65_17 /**
		**/		prop_edad_65_70_17 prop_edad_70_mas_17 pbi_2017_pc

	global	dep_ccpp_2013 poverty2013_pared poverty2013_piso poverty2013_agua 				/**
		**/		poverty2013_saneamiento poverty2013_bienesriqueza poverty2013_combust 		/**
		**/		poverty2013_seguro poverty2013_analfabeta poverty2013_educ 					/**
		**/		poverty2013_desempleo poverty2013_alumbrado prop_pared_ladrillo prop_pared_piedra prop_pared_adobe	/**
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
		**/		prop_asset_equipsonido prop_asset_tvcolor	/**
		**/		prop_asset_refri prop_asset_telefonofijo prop_asset_lavadora 	/**
		**/		prop_asset_compu prop_asset_internet prop_asset_cable 			/**
		**/		prop_asset_celular  				/**
		**/		prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 					/**
		**/		prop_edad_45_64 prop_edad_65 edad_15mas  		/**
		**/		prop_seguro_essalud prop_seguro_sis prop_seguro_ninguno 		/**
		**/		prop_lee_si prop_educ_ninguno prop_educ_inicial /**
		**/		prop_educ_primaria prop_educ_secundaria prop_educ_tecnica 		/**
		**/		prop_educ_universitaria prop_actividad_agricola prop_actividad_agricola 					/**
		**/		prop_actividad_minera 						/**
		**/		prop_actividad_comercial prop_actividad_servicios 					/**
		**/		prop_pea_ocupada prop_pea_desocupada prop_mujeres prop_edad_u1 /**
		**/		prop_edad_1_14 prop_edad_1_14 prop_edad_15_29 prop_edad_15_29  /**
		**/		prop_edad_15_29 prop_edad_30_44 prop_edad_30_44 prop_edad_30_44 /**
		**/ 	prop_edad_45_64 prop_edad_45_64 prop_edad_45_64 prop_edad_45_64 /**
		**/		prop_edad_65 prop_edad_65 pbi_2013_pc
	
	
	global	dep_ccpp_2007 poverty2007_pared poverty2007_piso poverty2007_agua poverty2007_saneamiento poverty2007_bienesriqueza poverty2007_combust poverty2007_seguro poverty2007_analfabeta poverty2007_educ poverty2007_desempleo poverty2007_alumbrado prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
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
		**/		prop_asset_equipsonido2007 prop_asset_tvcolor2007	/**
		**/		prop_asset_refri2007 prop_asset_telefonofijo2007 prop_asset_lavadora2007 	/**
		**/		prop_asset_compu2007 prop_asset_internet2007 prop_asset_cable2007 			/**
		**/		prop_asset_celular2007  				/**
		**/		prop_edad_1_142007 prop_edad_15_292007 prop_edad_30_442007 					/**
		**/		prop_edad_45_642007 prop_edad_652007 edad_15mas2007  		/**
		**/		prop_seguro_essalud2007 prop_seguro_sis2007 prop_seguro_ninguno2007 		/**
		**/		prop_lee_si2007 prop_educ_ninguno2007 prop_educ_inicial2007 /**
		**/		prop_educ_primaria2007 prop_educ_secundaria2007 prop_educ_tecnica2007 		/**
		**/		prop_educ_universitaria2007 prop_actividad_agricola2007 prop_actividad_agricola2007 					/**
		**/		prop_actividad_minera2007 						/**
		**/		prop_actividad_comercial2007 prop_actividad_servicios2007 					/**
		**/		prop_pea_ocupada2007 prop_pea_desocupada2007 prop_mujeres2007 prop_edad_u12007 /**
		**/		prop_edad_1_142007 prop_edad_1_142007 prop_edad_15_292007 prop_edad_15_292007  /**
		**/		prop_edad_15_292007 prop_edad_30_442007 prop_edad_30_442007 prop_edad_30_442007 /**
		**/ 	prop_edad_45_642007 prop_edad_45_642007 prop_edad_45_642007 prop_edad_45_642007 /**
		**/		prop_edad_652007 prop_edad_652007 pbi_2007_pc
	
	rd_ccpp3
	
	
	
	
	
