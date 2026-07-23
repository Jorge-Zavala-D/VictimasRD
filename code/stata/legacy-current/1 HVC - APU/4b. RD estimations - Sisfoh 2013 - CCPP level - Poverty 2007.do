/*------------------------------------------------------------------------------*
| Title:			RD Estimations for Sisfoh 2013 outcomes at CCPP level		|
|					Heterogeneous effects by poverty							|
| Project: 			Victimas RD								   					|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		This .do imports cleaned Sisfoh 2013 dataset at CCPP level	|
|					to perform the RD estimations for selected outcomes			|
|                                                                               |
|Date Created: 17/10/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import cleaned dataset at ccpp level and define control variables
	2.	Define program
		2.1.	Program for CCPP with Poverty Index below average
		2.2.	Program for CCPP with Poverty Index above average
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

global	controls altura_coded distancia_capital prop_a13 ///
		pob_ccpp_2007
		
*-------------------------------*
*		Program definition		*
*-------------------------------*

*-----------------------------------------------*
*		Program for low poverty communities		*
*-----------------------------------------------*		
		
	capture program drop rd_ccpp_lowpoverty
	program define rd_ccpp_lowpoverty
putexcel set "$a\3 output\regressions\$table.xls", sheet("Low poverty communities") modify
	putexcel C3 = ("$table")
	sleep 2000
	putexcel D5 = ("RD no/covs. - optimal BW")
	sleep 2000
	putexcel E5 = ("RD w/covs. - optimal BW")
	sleep 2000	
	putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	sleep 2000
	putexcel G5 = ("RD no/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel I5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 2000
	putexcel C5 = ("Control mean")
	sleep 2000

	global cells D E F G H I
	
local bl= 0
local i = 5	
foreach y in $dep_ccpp {	

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

	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), fuzzy(treat_13) ///
		vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular) covs(`2007')

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
	
	*RD including covariates -  Optimal Bandwidth selection	
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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
	
	*RD including covariates - Optimal Bandwidth selection - 2nd grade poly.
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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
	
	*RD not including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007') ///
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
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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

*---------------------------------------------------*
*		Program for high population communities		*
*---------------------------------------------------*		
		
	capture program drop rd_ccpp_highpoverty
	program define rd_ccpp_highpoverty
putexcel set "$a\3 output\regressions\$table.xls", sheet("High poverty communities") modify
	putexcel C3 = ("$table")
	sleep 2000
	putexcel D5 = ("RD no/covs. - optimal BW")
	sleep 2000
	putexcel E5 = ("RD w/covs. - optimal BW")
	sleep 2000	
	putexcel F5 = ("RD w/covs. - optimal BW - Poly.2")
	sleep 2000
	putexcel G5 = ("RD no/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel H5 = ("RD w/covs. - Imposing rand. inf. window")
	sleep 2000	
	putexcel I5 = ("RD w/covs. - Imposing rand. inf. window - Poly.2")
	sleep 2000
	putexcel C5 = ("Control mean")
	sleep 2000

	global cells D E F G H I
	
local bl= 0
local i = 5	
foreach y in $dep_ccpp {	

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

	*RD not including covariates - Optimal Bandwidht selection
	local p=1
		local 2007: word `bl' of $dep_ccpp_2007
		local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), fuzzy(treat_13) ///
		vce(cluster cluster_dist) bwselect(msetwo) kernel(triangular) covs(`2007')

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
	
	*RD including covariates - Optimal Bandwidht selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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
	
	*RD including covariates - Optimal Bandwidth selection - 2nd grade poly.
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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

	*RD not including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007') ///
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
	
	*RD including covariates - Imposing randomization inference window selection
	local p = `p' + 1
	local l: word `p' of $cells	
	
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), covs(`2007' $controls) ///
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


*-----------------------------------*
*		Inputs for estimations		*
*-----------------------------------*

*	For low poverty communities

use "$a\2 data\community_index_treated_sisfohccpp.dta", clear

egen	poverty2007_p50 = median(poverty2007) if dpto=="HUANCAVELICA" | dpto=="APURIMAC" 
keep if poverty2007>poverty2007_p50 & poverty2007_p50!=.

	global	table "\Sisfoh 2013 outcomes at CCPP level - Heterogeneous Effects - Poverty"

	global	dep_ccpp prop_pared_ladrillo prop_pared_piedra prop_pared_adobe		/**
		**/		prop_pared_quincha prop_pared_madera  			/**
		**/		prop_piso_parquet 			/**
		**/		prop_piso_tabla prop_piso_cemento prop_piso_tierra 				/**
		**/		prop_agua_redpubdentro prop_agua_redpubfuera prop_agua_pilon 	/**
		**/		prop_agua_pozo prop_agua_rio 									/**
		**/		prop_saneamiento_redpubdentro 		/**
		**/		prop_saneamiento_pozo prop_saneamiento_letrina 					/**
		**/		prop_saneamiento_rio prop_saneamiento_ninguno 					/**
		**/		prop_combust_gas  							/**
		**/		prop_combust_lea prop_combust_bosta 		/**
		**/		prop_combust_nococina prop_asset_equipsonido prop_asset_tvcolor	/**
		**/		prop_asset_telefonofijo 	/**
		**/		prop_asset_compu prop_asset_cable 			/**
		**/		prop_asset_celular prop_asset_ninguno prop_edad_u1 				/**
		**/		prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 					/**
		**/		prop_edad_45_64 prop_edad_65 edad_15mas prop_edad_15 			/**
		**/		prop_seguro_essalud prop_seguro_sis prop_seguro_ninguno 		/**
		**/		prop_lee_si prop_lee_no prop_educ_ninguno 	/**
		**/		prop_educ_primaria prop_educ_secundaria prop_educ_tecnica 		/**
		**/		prop_educ_universitaria prop_actividad_agricola 				/**
		**/		prop_actividad_minera 					/**
		**/		prop_actividad_comercial prop_actividad_servicios 				/**
		**/		prop_pea_ocupada prop_pea_desocupada

	global	dep_ccpp_2007 prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
		**/		prop_pared_quincha2007 prop_pared_madera2007  			/**
		**/		prop_piso_parquet2007 			/**
		**/		prop_piso_tabla2007 prop_piso_cemento2007 prop_piso_tierra2007 				/**
		**/		prop_agua_redpubdentro2007 prop_agua_redpubfuera2007 prop_agua_pilon2007 	/**
		**/		prop_agua_pozo2007 prop_agua_rio2007 				/**
		**/		prop_saneamiento_redpubdentro07 				/**
		**/		prop_saneamiento_pozo2007 prop_saneamiento_letrina2007 						/**
		**/		prop_saneamiento_rio2007 prop_saneamiento_ninguno2007 						/**
		**/		prop_combust_gas2007  		/**
		**/		prop_combust_lea2007 prop_combust_bosta2007 		/**
		**/		prop_combust_nococina2007 prop_asset_equipsonido2007 prop_asset_tvcolor2007	/**
		**/		prop_asset_telefonofijo2007 	/**
		**/		prop_asset_compu2007 prop_asset_cable2007 			/**
		**/		prop_asset_celular2007 prop_asset_ninguno2007 prop_edad_u12007 				/**
		**/		prop_edad_1_142007 prop_edad_15_292007 prop_edad_30_442007 					/**
		**/		prop_edad_45_642007 prop_edad_652007 edad_15mas2007 prop_edad_152007 		/**
		**/		prop_seguro_essalud2007 prop_seguro_sis2007 prop_seguro_ninguno2007 		/**
		**/		prop_lee_si2007 prop_lee_no2007 prop_educ_ninguno2007 /**
		**/		prop_educ_primaria2007 prop_educ_secundaria2007 prop_educ_tecnica2007 		/**
		**/		prop_educ_universitaria2007 prop_actividad_agricola2007 					/**
		**/		prop_actividad_minera2007 						/**
		**/		prop_actividad_comercial2007 prop_actividad_servicios2007 					/**
		**/		prop_pea_ocupada2007 prop_pea_desocupada2007

	rd_ccpp_lowpoverty

*	For high poverty communities

use "$a\2 data\community_index_treated_sisfohccpp.dta", clear

egen	poverty2007_p50 = median(poverty2007) if dpto=="HUANCAVELICA" | dpto=="APURIMAC" 
keep if poverty2007<=poverty2007_p50 & poverty2007_p50!=.

	global	table "\Sisfoh 2013 outcomes at CCPP level - Heterogeneous Effects - Poverty"

	global	dep_ccpp prop_pared_ladrillo prop_pared_piedra prop_pared_adobe		/**
		**/		prop_pared_quincha prop_pared_madera  			/**
		**/		prop_piso_parquet 			/**
		**/		prop_piso_tabla prop_piso_cemento prop_piso_tierra 				/**
		**/		prop_agua_redpubdentro prop_agua_redpubfuera prop_agua_pilon 	/**
		**/		prop_agua_pozo prop_agua_rio 									/**
		**/		prop_saneamiento_redpubdentro 		/**
		**/		prop_saneamiento_pozo prop_saneamiento_letrina 					/**
		**/		prop_saneamiento_rio prop_saneamiento_ninguno 					/**
		**/		prop_combust_gas  							/**
		**/		prop_combust_lea prop_combust_bosta 		/**
		**/		prop_combust_nococina prop_asset_equipsonido prop_asset_tvcolor	/**
		**/		prop_asset_telefonofijo 	/**
		**/		prop_asset_compu prop_asset_cable 			/**
		**/		prop_asset_celular prop_asset_ninguno prop_edad_u1 				/**
		**/		prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 					/**
		**/		prop_edad_45_64 prop_edad_65 edad_15mas prop_edad_15 			/**
		**/		prop_seguro_essalud prop_seguro_sis prop_seguro_ninguno 		/**
		**/		prop_lee_si prop_lee_no prop_educ_ninguno 	/**
		**/		prop_educ_primaria prop_educ_secundaria prop_educ_tecnica 		/**
		**/		prop_educ_universitaria prop_actividad_agricola 				/**
		**/		prop_actividad_minera 					/**
		**/		prop_actividad_comercial prop_actividad_servicios 				/**
		**/		prop_pea_ocupada prop_pea_desocupada

	global	dep_ccpp_2007 prop_pared_ladrillo2007 prop_pared_piedra2007 prop_pared_adobe2007	/**
		**/		prop_pared_quincha2007 prop_pared_madera2007  			/**
		**/		prop_piso_parquet2007 			/**
		**/		prop_piso_tabla2007 prop_piso_cemento2007 prop_piso_tierra2007 				/**
		**/		prop_agua_redpubdentro2007 prop_agua_redpubfuera2007 prop_agua_pilon2007 	/**
		**/		prop_agua_pozo2007 prop_agua_rio2007 				/**
		**/		prop_saneamiento_redpubdentro07 				/**
		**/		prop_saneamiento_pozo2007 prop_saneamiento_letrina2007 						/**
		**/		prop_saneamiento_rio2007 prop_saneamiento_ninguno2007 						/**
		**/		prop_combust_gas2007  		/**
		**/		prop_combust_lea2007 prop_combust_bosta2007 		/**
		**/		prop_combust_nococina2007 prop_asset_equipsonido2007 prop_asset_tvcolor2007	/**
		**/		prop_asset_telefonofijo2007 	/**
		**/		prop_asset_compu2007 prop_asset_cable2007 			/**
		**/		prop_asset_celular2007 prop_asset_ninguno2007 prop_edad_u12007 				/**
		**/		prop_edad_1_142007 prop_edad_15_292007 prop_edad_30_442007 					/**
		**/		prop_edad_45_642007 prop_edad_652007 edad_15mas2007 prop_edad_152007 		/**
		**/		prop_seguro_essalud2007 prop_seguro_sis2007 prop_seguro_ninguno2007 		/**
		**/		prop_lee_si2007 prop_lee_no2007 prop_educ_ninguno2007 /**
		**/		prop_educ_primaria2007 prop_educ_secundaria2007 prop_educ_tecnica2007 		/**
		**/		prop_educ_universitaria2007 prop_actividad_agricola2007 					/**
		**/		prop_actividad_minera2007 						/**
		**/		prop_actividad_comercial2007 prop_actividad_servicios2007 					/**
		**/		prop_pea_ocupada2007 prop_pea_desocupada2007

	rd_ccpp_highpoverty
