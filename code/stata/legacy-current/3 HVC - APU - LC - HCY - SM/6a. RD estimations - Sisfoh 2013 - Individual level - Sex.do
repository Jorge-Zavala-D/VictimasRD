/*------------------------------------------------------------------------------*
| Title:			RD Estimations for Sisfoh 2013 outcomes at Individual level	|
|					Heterogeneous effects by sex								|
| Project: 			Victimas RD								   					|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		This .do imports cleaned Sisfoh 2013 dataset at Individual 	|
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
		2.1.	Program for women outcomes
		2.1.	Program for men outcomes
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

*-------------------------------------------*
*		Outcomes at Individual Level		*
*-------------------------------------------*

global	controls urb_rur altura_coded distancia_capital prop_a13 ///
		pob_ccpp poverty2007_caracthh poverty2007_servpub poverty2007_demogra 	///
		sisf_numperso edad

*-------------------------------*
*		Program definition		*
*-------------------------------*		

*---------------------------------------*
*		Program for Women outcomes		*
*---------------------------------------*			
	
	capture program drop rd_individuals_women
	program define rd_individuals_women
putexcel set "$a\3 output\regressions\$table.xls", sheet("Women outcomes") modify
	putexcel C3 = ("$table")
	sleep 4500
	putexcel D5 = ("RD no/covariates")
	sleep 4500
	putexcel E5 = ("RD w/covariates")
	sleep 4500	
	putexcel F5 = ("RD w/covs. - 2nd grade pol.")
	sleep 4500
	putexcel G5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 4500	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 4500
	putexcel C5 = ("Control mean")
	sleep 4500

	global cells D E F G H
	
local bl= 0
local i = 5	
foreach y in $dep_ind {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 4500
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), over(treat_13) vce(cl cluster_dist) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 4500
	putexcel C`i'=("`mean'")

	*RD not including covariates
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	*RD including covariates - 2nd grade polinome
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) p(2) ///
		kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection - 2nd grade Polynomy
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
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
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
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
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	*/
}
	end

*---------------------------------------*
*		Program for Men outcomes		*
*---------------------------------------*			
	
	capture program drop rd_individuals_men
	program define rd_individuals_men
putexcel set "$a\3 output\regressions\$table.xls", sheet("Men outcomes") modify
	putexcel C3 = ("$table")
	sleep 4500
	putexcel D5 = ("RD no/covariates")
	sleep 4500
	putexcel E5 = ("RD w/covariates")
	sleep 4500	
	putexcel F5 = ("RD w/covs. - 2nd grade pol.")
	sleep 4500
	putexcel G5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 4500	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 4500
	putexcel C5 = ("Control mean")
	sleep 4500

	global cells D E F G H
	
local bl= 0
local i = 5	
foreach y in $dep_ind {	

	local i=`i'+4
	local s=`i'+1
	local obs=`i'+2
	local bw=`i'+3
	local bl=`bl'+1
	sleep 4500
	putexcel B`i'=("`y'")	
	
	mean `y' if abs(index_cutBC)<0.015 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC"), over(treat_13) vce(cl cluster_dist) 
	matrix mean_1=e(b)
	local mean_2=mean_1[1,1]
	local mean=string(`mean_2', "%9.3f")
	sleep 4500
	putexcel C`i'=("`mean'")

	*RD not including covariates
	local p=1
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	
	*RD including covariates - 2nd grade polinome
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) bwselect(msetwo) p(2) ///
		kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")
	
	*RD including covariates - Imposing randomization inference window selection - 2nd grade Polynomy
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs($controls) ///
		fuzzy(treat_13) vce(cluster cluster_dist) h(0.015) kernel(triangular) p(2)

	local pv 	= e(pv_cl)	
	local se_1 	= e(se_tau_cl)
	local c_1 	= e(tau_cl)
	local c = string(`c_1', "%9.3f")		
	local se = string(`se_1', "%9.3f")	
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
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
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
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
	sleep 4500
		if `pv'>0.10 				putexcel `l'`i' = ("`c'") `l'`s'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`i' = ("`c'*") `l'`s'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`i' = ("`c'**") `l'`s'=("(`se')") 
		if `pv'<0.01				putexcel `l'`i' = ("`c'***") `l'`s'=("(`se')")
	local obsl = e(N_h_l)
	local obsr = e(N_h_r)
	local observ_1 = `obsl' + `obsr'
	local observ=string(`observ_1', "%9.0f")
	sleep 4500
	putexcel `l'`obs' = ("`observ'")
	
	local bw_l1 = e(h_l)
	local bw_r1 = e(h_r)
	local bw_l = string(`bw_l1', "%9.3f")
	local bw_r = string(`bw_r1', "%9.3f")
	sleep 4500
	putexcel `l'`bw' = ("[-`bw_l' ; `bw_r']")	
	*/
}
	end

*-------------------------------*
*		Inputs for program		*
*-------------------------------*

*	For women outcomes at individual level

use "$a\2 data\community_index_treated_sisfohpers_women.dta", clear

global table "\Sisfoh 2013 outcomes at Individual level - Heterogeneous Effects - Sex"
global	dep_ind nivel_educ nivel_educ2 nivel_educ3_ninguno nivel_educ3_primaria /**
	**/	nivel_educ3_secundaria nivel_educ3_superior analfab edad_6_12_noescuela /**
	**/	gestante jefe_hogar ocupado trabaja_agricola trabaja_pecuaria 			/**
	**/ trabaja_minera trabaja_artesanal trabaja_comercial trabaja_servicios 	/**
	**/	trabaja_otro trabaja_gobierno trabaja_otro2 ocupacion_dep 				/**
	**/	ocupacion_indep ocupacion_famnorem ocupacion_desemp ocupacion_hogar 	/**
	**/	ocupacion_estud ocupacion_otro2 seg_essalud seg_ffaapnp seg_privado 	/**
	**/	seg_otro2 seg_ninguno num_seguro_ind tiene_seguro prog_vasoleche 		/**
	**/	prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos 	/**
	**/	prog_pension65 prog_otro2 prog_ninguno num_prog_ind tiene_prog 
	
	* trabaja_otro2: trabaja_forestal trabaja_pesquera 
	* prog_otro2: prog_techo prog_cunamas prog_otro
	* seg_otro2: seg_sis seg_otro 
	* ocupacion_otro2: ocupacion_trabhog ocupacion_jubilado
	
rd_individuals_women

use "$a\2 data\community_index_treated_sisfohpers_men.dta", clear

global table "\Sisfoh 2013 outcomes at Individual level - Heterogeneous Effects - Sex"
global	dep_ind nivel_educ nivel_educ2 nivel_educ3_ninguno nivel_educ3_primaria /**
	**/	nivel_educ3_secundaria nivel_educ3_superior analfab edad_6_12_noescuela /**
	**/ jefe_hogar ocupado trabaja_agricola trabaja_pecuaria 	        		/**
	**/ trabaja_minera trabaja_artesanal trabaja_comercial trabaja_servicios 	/**
	**/	trabaja_otro trabaja_gobierno trabaja_otro2 ocupacion_dep 				/**
	**/	ocupacion_indep ocupacion_famnorem ocupacion_desemp ocupacion_hogar 	/**
	**/	ocupacion_estud ocupacion_otro2 seg_essalud seg_ffaapnp seg_privado 	/**
	**/	seg_otro2 seg_ninguno num_seguro_ind tiene_seguro prog_vasoleche 		/**
	**/	prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos 	/**
	**/	prog_pension65 prog_otro2 prog_ninguno num_prog_ind tiene_prog 
	
	* trabaja_otro2: trabaja_forestal trabaja_pesquera 
	* prog_otro2: prog_techo prog_cunamas prog_otro
	* seg_otro2: seg_sis seg_otro 
	* ocupacion_otro2: ocupacion_trabhog ocupacion_jubilado
	
rd_individuals_men
