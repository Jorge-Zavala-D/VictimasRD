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
	
	*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
	*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD\"
	*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
	global a "C:\Users\jzavala\Dropbox\VictimasRD"	
	*global a "/Users/bruno_esposito/Dropbox/Proyectos/Matthew/VictimasRD"
		
*---------------------------------------*
*				All 2017 obs	 		*
*---------------------------------------*

	use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear
	
	local target_outcome prop_agua_redpubfuera 
	local outcome_change = 0.3
	local poder = 0.8
	local rho = 0.11
	local obs_clus = 35
	local num_clus = 105
		
	sum `target_outcome' if abs(index_cutBC)<=0.015 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC")
	local target_mean = r(mean)
	local target_sd = r(sd)
	
		rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto == "HUANCAVELICA"	|	///
																		dpto == "APURIMAC")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri) h(0.015)
		mat B = e(b)
		local treat_prob = B[1,1]
		
		local new_mean = `target_mean' + `outcome_change' * `target_sd'
		local fuzzy_mean = `target_mean' + `outcome_change' * `target_sd' * `treat_prob'
		local adjusted_sd_bandwidth = `target_sd' * 3
		local adjusted_sd_sharp = `target_sd' * 2
	
			sampsi `target_mean' `fuzzy_mean', sd1(`adjusted_sd_sharp') p(`poder') 
			sampclus, rho(`rho')  numclus(`num_clus')
		*	sampclus, rho(`rho')  obsclus(`obs_clus')
		
		
			sampsi `target_mean' `fuzzy_mean', sd1(`target_sd') p(`poder') method(ancova) pre(1) r01(.5)
			sampclus, rho(`rho')  numclus(`num_clus')
		*	sampclus, rho(`rho')  obsclus(`obs_clus')			
			
	
	local change = `outcome_change' * `target_sd'
	display `change'
*	rdpower `target_outcome' index_cutBC, vce(cluster cluster_dist) scaleregul(0) kernel(tri) fuzzy(treat_17)
	rdsampsi prop_combust_elect index_cutBC if (Nivel=="B" | Nivel=="C") & ///
	(dpto=="HUANCAVELICA" | dpto=="APURIMAC"), vce(cluster cluster_dist) ///
	 kernel(tri) fuzzy(treat_17) tau(0.005) beta(0.9)
	
	rdpower prop_combust_elect index_cutBC , vce(cluster cluster_dist) ///
	scaleregul(0) kernel(tri) fuzzy(treat_17) 
	

* WINDOW para randomization inference es (-0.015 , 0.015)	
	
	
rdwinselect index_cutBC altura_coded distancia_capital poverty2007_pared-poverty2007_demogra ///
prop_actividad_agricola2007 pob_ccpp urb_rur_ccpp if (dpto=="APURIMAC" | dpto=="HUANCAVELICA"), ///
nw(16) wstep(0.001) level(0.1) reps(500) plot graph_options(graphregion(color(white)) title(Minimum p-value from covariate test) xtitle(Window lenght / 2) yline(0.1, lpattern(shortdash)) ytitle(P-value)) 
	

* RI Window select

**	Huancavelica - Apurimac
rdwinselect index_cutBC altitude_msnm log_distancia_capital poverty2007_caracthh poverty2007_servpub poverty2007_demogra ///
prop_actividad_agricola2007 log_pob_ccpp_2007 urb_rur_ccpp_2007 if (dpto=="APURIMAC" | dpto=="HUANCAVELICA"), ///
nw(30) wstep(0.001) level(0.1) reps(1000) stat(ranksum) plot graph_options(graphregion(color(white)) ///
title(Minimum p-value from covariate test) xtitle(Window lenght / 2) yline(0.1, lpattern(shortdash)) ytitle(P-value)) 
	
** Huancavelica - Apurimac - La Convencion - Huancayo
rdwinselect index_cutBC altitude_msnm log_distancia_capital poverty2007_caracthh poverty2007_servpub poverty2007_demogra ///
prop_actividad_agricola2007 log_pob_ccpp_2007 urb_rur_ccpp_2007 ie_estatal_1_2010 if (dpto=="APURIMAC" | dpto=="HUANCAVELICA" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
nw(30) wstep(0.001) level(0.1) reps(1000) plot stat(ttest) graph_options(graphregion(color(white)) ///
title(Minimum p-value from covariate test) xtitle(Window lenght / 2) yline(0.1, lpattern(shortdash)) ytitle(P-value)) 

** Huancavelica - Apurimac - La Convencion - Huancayo - San Martin
rdwinselect index_cutBC altitude_msnm log_distancia_capital poverty2007_caracthh poverty2007_servpub poverty2007_demogra ///
prop_actividad_agricola2007 log_pob_ccpp_2007 urb_rur_ccpp_2007 if (dpto=="APURIMAC" | dpto=="HUANCAVELICA" | prov=="LA CONVENCION" | prov=="HUANCAYO" | dpto=="SAN MARTIN"), ///
nw(30) wstep(0.001) level(0.1) reps(1000) plot stat(ranksum) graph_options(graphregion(color(white)) ///
title(Minimum p-value from covariate test) xtitle(Window lenght / 2) yline(0.1, lpattern(shortdash)) ytitle(P-value)) 
	
	
	
	
	
	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto == "HUANCAVELICA"	|	///
																		dpto == "APURIMAC" | dpto=="AYACUCHO" | dpto=="HUANUCO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto=="AYACUCHO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)	
	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto=="APURIMAC")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)		
																		
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)	
	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
	
																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (	dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)																		
																	
																	
																															
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="AYACUCHO" | dpto=="APURIMAC")			/// CANDIDATE 20%
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																	
																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="AYACUCHO" | dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="AYACUCHO" | dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="AYACUCHO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
			
			
																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="APURIMAC" | dpto=="HUANCAVELICA")			/// CANDIDATE 1 90%
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		

																																																			

																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="APURIMAC" | dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="APURIMAC" | dpto=="JUNIN")			/// CANDIDATE	21%
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)						
			
	
																	
																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="HUANUCO" | dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="HUANCAVELICA" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)						
			
			
			
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="HUANUCO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)									
			
			
	
	
	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="APURIMAC" | dpto=="HUANCAVELICA" | dpto=="AYACUCHO" | dpto=="JUNIN")			/// CANDIDATE 1 90%
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)		
	
	
	
			rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") 	& (dpto=="APURIMAC" | dpto=="HUANCAVELICA" | dpto=="JUNIN")			/// CANDIDATE 1 90%
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)		
	
	
	
	
			 * CORTE A/B
			 
			rdrobust treat_13 index_cutAB if (Nivel=="A" | Nivel=="B") 	& (	dpto == "HUANCAVELICA"	|	///
																		dpto == "APURIMAC" | dpto=="AYACUCHO" | dpto=="HUANUCO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
	
			rdrobust treat_13 index_cutAB if (Nivel=="A" | Nivel=="B") 	& (	dpto=="AYACUCHO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)	
	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (	dpto=="APURIMAC")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)		
																		
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (	dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)	
	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (	dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
	
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (	dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)																		
																	
																	
																															
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="AYACUCHO" | dpto=="APURIMAC")			/// CANDIDATE
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																	
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="AYACUCHO" | dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="AYACUCHO" | dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="AYACUCHO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
			
			
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="APURIMAC" | dpto=="HUANCAVELICA")			/// CANDIDATE 1
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="APURIMAC" | dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="APURIMAC" | dpto=="JUNIN")			/// CANDIDATE
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)						
			
	
																	
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="HUANUCO" | dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="HUANCAVELICA" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)						
			
			
			
			rdrobust treat_13 index_cutAB if (Nivel=="B" | Nivel=="A") 	& (dpto=="HUANUCO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)				 
	
	
	
		* CORTE CD
		
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	& (	dpto == "HUANCAVELICA"	|	///
																		dpto == "APURIMAC" | dpto=="AYACUCHO" | dpto=="HUANUCO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 		& (	dpto=="AYACUCHO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)	
	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	 	& (	dpto=="APURIMAC")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)		
																		
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	 	& (	dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)	
	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 		 	& (	dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)
	
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	 	& (	dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)																		
																	
																	
																															
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 		 	& (dpto=="AYACUCHO" | dpto=="APURIMAC")			/// CANDIDATE
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																	
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 		 	& (dpto=="AYACUCHO" | dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 			& (dpto=="AYACUCHO" | dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	& (dpto=="AYACUCHO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
			
			
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	& (dpto=="APURIMAC" | dpto=="HUANCAVELICA")			/// CANDIDATE 1
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D")  	& (dpto=="APURIMAC" | dpto=="HUANUCO")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	& (dpto=="APURIMAC" | dpto=="JUNIN")			/// CANDIDATE
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)						
			
	
																	
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 		& (dpto=="HUANUCO" | dpto=="HUANCAVELICA")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)			
																																		
																	
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	& (dpto=="HUANCAVELICA" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)						
			
			
			
		rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") 	 	& (dpto=="HUANUCO" | dpto=="JUNIN")			///
																	, vce(cluster cluster_dist) scaleregul(0) kernel(tri)				 
															
	
	
	
	
	
	
	
	
	
	
	
	