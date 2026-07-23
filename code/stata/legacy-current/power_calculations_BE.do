/*------------------------------------------------------------------------------*
| Title: 			  Power Calculation											|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Bruno Esposito						                    |
| 					  									                        |
|																				|
|Description:		  Find the number of observations needed to identify		|
|					  certain change in the outcome variable					|
|                                                                               |
|Date Created: 23/08/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

	clear all
	set more off
	version 13
	
	local target_outcome prop_asset_licuadora
	local outcome_change = 0.4
	local poder = 0.75
	local rho = 0.05
	local obs_clus = 80
	local num_clus = 100
	local sampclus_choice = 2
	* 1 for fixing obs per cluster
	* 2 for fixing number of clusters
	
	
	*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
	*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
	global a "/Users/bruno_esposito/Dropbox/Proyectos/Matthew/VictimasRD"
	
	
*---------------------------------------*
*				All 2017 obs	 		*
*---------------------------------------*

	use "$a/data/community_index_treated_sisfoh.dta", clear
	sum `target_outcome'
	local target_mean = r(mean)
	local target_sd = r(sd)
	
	mat A = J(10,5,.)
	local cont = 1
	
	local change = `outcome_change' * `target_sd'
	rdpower `target_outcome' index_cutBC, vce(cluster cluster_dist) scaleregul(0) kernel(tri) fuzzy(treat_17)
	rdsampsi `target_outcome' index_cutBC, vce(cluster cluster_dist) scaleregul(0) kernel(tri) fuzzy(treat_17)
	
	** TODAS LAS CIUDADES
	forvalues outcome_change = 0.1(0.1)1 {
		
		rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C"), vce(cluster cluster_dist) scaleregul(0) kernel(tri)
		mat B = e(b)
		local treat_prob = B[1,1]
		
		local new_mean = `target_mean' + `outcome_change' * `target_sd'
		local fuzzy_mean = `target_mean' + `outcome_change' * `target_sd' * `treat_prob'
		local adjusted_sd_bandwidth = `target_sd' * 3
		local adjusted_sd_sharp = `target_sd' * 2
		
		display `target_mean'
		display `new_mean'
		display `adjusted_sd'
		
		mat A[`cont',1] = `outcome_change'
		
		sampsi `target_mean' `new_mean', sd1(`adjusted_sd_sharp') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',2] = r(N_1) + r(N_2)
		
		sampsi `target_mean' `fuzzy_mean', sd1(`adjusted_sd_sharp') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',3] = r(N_1) + r(N_2)
		
		sampsi `target_mean' `new_mean', sd1(`adjusted_sd_bandwidth') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',4] = r(N_1) + r(N_2)
		
		sampsi `target_mean' `fuzzy_mean', sd1(`adjusted_sd_bandwidth') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',5] = r(N_1) + r(N_2)
		
		local cont = `cont' + 1
	}
	
	mat list A
	mat END_A = A
	svmat A
	lab var A1 "Outcome change (in est. deviations)"
	lab var A2 "Sharp"
	lab var A3 "Fuzzy"
	lab var A4 "Sharp & bandwidth selection"
	lab var A5 "Fuzzy & bandwidth selection"
	
	twoway connected A2 A3 A4 A5 A1
	graph export "$a/output/graphs/power_tests/all_sample_naive.pdf", replace 
	
	twoway connected A2 A3 A4 A5 A1 in 5/10
	graph export "$a/output/graphs/power_tests/all_sample_naive_reduced.pdf", replace 
	
	** LAS 5 CIUDADES CON MAS TRATADOS
	
	drop A*
	mat A = J(10,5,.)
	local cont = 1
	
		forvalues outcome_change = 0.1(0.1)1 {
		
		rdrobust treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto == "HUANCAVELICA"	|	///
																		dpto == "APURIMAC")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
		mat B = e(b)
		local treat_prob = B[1,1]
		
		local new_mean = `target_mean' + `outcome_change' * `target_sd'
		local fuzzy_mean = `target_mean' + `outcome_change' * `target_sd' * `treat_prob'
		local adjusted_sd_bandwidth = `target_sd' * 3
		local adjusted_sd_sharp = `target_sd' * 2
		
		display `target_mean'
		display `new_mean'
		display `adjusted_sd'
		
		mat A[`cont',1] = `outcome_change'
		
		sampsi `target_mean' `new_mean', sd1(`adjusted_sd_sharp') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',2] = r(N_1) + r(N_2)
		
		sampsi `target_mean' `fuzzy_mean', sd1(`adjusted_sd_sharp') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',3] = r(N_1) + r(N_2)
		
		sampsi `target_mean' `new_mean', sd1(`adjusted_sd_bandwidth') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',4] = r(N_1) + r(N_2)
		
		sampsi `target_mean' `fuzzy_mean', sd1(`adjusted_sd_bandwidth') p(`poder')
		if `sampclus_choice' == 1 {
			sampclus, rho(`rho') obsclus(`obs_clus')
		}
		if `sampclus_choice' == 2 {
			sampclus, rho(`rho')  numclus(`num_clus')
		}
		mat A[`cont',5] = r(N_1) + r(N_2)
		
		local cont = `cont' + 1
	}
	
	mat list A
	mat END_B = A
	svmat A
	lab var A1 "Outcome change (in est. deviations)"
	lab var A2 "Sharp"
	lab var A3 "Fuzzy"
	lab var A4 "Sharp & bandwidth selection"
	lab var A5 "Fuzzy & bandwidth selection"
	
	twoway connected A2 A3 A4 A5 A1
	graph export "$a/output/graphs/power_tests/all_sample_naive_5regiones.pdf", replace 
	
	twoway connected A2 A3 A4 A5 A1 in 5/10
	graph export "$a/output/graphs/power_tests/all_sample_naive_reduced_5regiones.pdf", replace 
	
	mat list END_A
	mat list END_B
