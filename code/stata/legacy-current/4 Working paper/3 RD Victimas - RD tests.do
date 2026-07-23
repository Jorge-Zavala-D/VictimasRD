/*------------------------------------------------------------------------------*
| Title:			Regression Discontinuity Analysis: Validation & Estimation	|
| Project: 			Victimas RD									   				|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
| Description:		This .do runs validation and falsification tests of the RD	|
|					and performs the estimations of the treatment effects		|
|                                                                               |
| Date Created: 	03/10/2018			 					                    |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/
/*--------------------------*
*           INDEX           *
*---------------------------*

	I.		The search for design ...
	
			1.	Probability of treatment around cutoff	*
			2.	Graphic representation of the chosen design	*
	
	II.		Validation and falsification tests
	
			II-1.	Pre-estimation tests
			
					1.	Density of running variable	*
					2.	Predetermined Covariates	*
					3.	Placebo Outcomes (TBD)
			
			II-2.	Post-estimation tests
				
					1.	Placebo cutoffs
					2.	Sensitivity to Obs. near the Cutoff (Donut-Hole approach)
					3.	Sensitivity to Bandwidth Choise
					4.	Sensitivity to Higher order polynomes
			
	III.	Bandwidth selection selection
	
			1.	Window selection	*
			2.	Descriptive statistics	*
			3.	Formal local-randomization analysis for covariates	*
				
	IV.		Estimation and Sensitivity analysis
	
			1.	Estimations at community level
			2.	Estimations at household level
			3.	Heterogenous Effects
				3.1.	Women outcomes
				3.2.	Population Cut


*-------------------------------------------------------------------------------*/

*-------------------------------------------*
*		I.	The search for design ...		*
*-------------------------------------------*
{
use "$input_dir\3 Coded\community_index_treated_sisfohccpp.dta", ///
	clear

	tab dpto

*	Keep for the analysis only regions with more than 100 communities treated
	global dpto_select APURIMAC AYACUCHO HUANCAVELICA HUANUCO JUNIN "SAN MARTIN"


	*---------------------------------------------------------------*
	*		I.1.	Probability of treatment around the cutoff		*
	*---------------------------------------------------------------*
	
	
	rdrobust treat_13 index_cutAB if (Nivel=="A" | Nivel=="B"), ///
	vce(cluster cluster_dist) scaleregul(0)
	
	rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C"), ///
	vce(cluster cluster_dist) scaleregul(0)
	rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D"), ///
	vce(cluster cluster_dist) scaleregul(0)
	rdrobust treat_13 index_cutDE if (Nivel=="D" | Nivel=="E"), ///
	vce(cluster cluster_dist) scaleregul(0)	
	
	
{

*	For quintile A & B
	matrix define AB = J(18,6,.)
	putexcel set "$output_dir\RD_tests\2 tables\1 Search for design\search_design.xlsx", ///
		sheet("cutAB") ///
		modify
	global cells B C D E F G
	local col = 0
	local row2 = 0
	local row3 = -1
	foreach a of global dpto_select {
	local row = -2
	local row_pv = -1
	local row_obs = 0
	local row3 = `row3' + 3
	local col = `col' + 1
	local cell: word `col' of $cells
	putexcel `cell'1 = ("`a'")
	sleep 0
	putexcel A`row3' = ("`a'")
	sleep 0
	foreach b of global dpto_select {
	local row = `row' + 3
	local row_pv = `row_pv' + 3
	local row_obs = `row_obs' + 3
	quietly: rdrobust treat_13 index_cutAB if (Nivel=="A" | Nivel=="B") & ///
	(dpto=="`a'" | dpto=="`b'"), vce(cluster cluster_dist) scaleregul(0)
		local c_1 	= e(tau_cl)
		local c = string(`c_1', "%9.2f")		
	matrix AB[`row',`col'] = `c'
		local pv_1 	= e(pv_cl)
		local pv = string(`pv_1', "%9.3f")
	matrix AB[`row_pv',`col'] = `pv'
		local obs_1 = e(N)
		local obs = string(`obs_1', "%9.0f")
	matrix AB[`row_obs',`col'] = `obs'
	}
	}
	putexcel B2=matrix(AB)

*	For quintile B & C
	matrix define BC = J(18,6,.)
	putexcel set "$output_dir\RD_tests\2 tables\1 Search for design\search_design.xlsx", ///
		sheet("cutBC") ///
		modify
	global cells B C D E F G
	local col = 0
	local row2 = 0
	local row3 = -1
	foreach a of global dpto_select {
	local row = -2
	local row_pv = -1
	local row_obs = 0
	local row3 = `row3' + 3
	local col = `col' + 1
	local cell: word `col' of $cells
	putexcel `cell'1 = ("`a'")
	sleep 0
	putexcel A`row3' = ("`a'")
	sleep 0
	foreach b of global dpto_select {
	local row = `row' + 3
	local row_pv = `row_pv' + 3
	local row_obs = `row_obs' + 3
	quietly: rdrobust treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
	(dpto=="`a'" | dpto=="`b'"), vce(cluster cluster_dist) scaleregul(0)
		local c_1 	= e(tau_cl)
		local c = string(`c_1', "%9.2f")		
	matrix BC[`row',`col'] = `c'
		local pv_1 	= e(pv_cl)
		local pv = string(`pv_1', "%9.3f")
	matrix BC[`row_pv',`col'] = `pv'
		local obs_1 = e(N)
		local obs = string(`obs_1', "%9.0f")
	matrix BC[`row_obs',`col'] = `obs'
	}
	}
	putexcel B2=matrix(BC)

*	For quintile C & D
	matrix define CD = J(18,6,.)
	putexcel set "$output_dir\RD_tests\2 tables\1 Search for design\search_design.xlsx", ///
		sheet("cutCD") ///
		modify
	global cells B C D E F G
	local col = 0
	local row2 = 0
	local row3 = -1
	foreach a of global dpto_select {
	local row = -2
	local row_pv = -1
	local row_obs = 0
	local row3 = `row3' + 3
	local col = `col' + 1
	local cell: word `col' of $cells
	putexcel `cell'1 = ("`a'")
	sleep 0
	putexcel A`row3' = ("`a'")
	sleep 0
	foreach b of global dpto_select {
	local row = `row' + 3
	local row_pv = `row_pv' + 3
	local row_obs = `row_obs' + 3
	quietly: rdrobust treat_13 index_cutCD if (Nivel=="C" | Nivel=="D") & ///
	(dpto=="`a'" | dpto=="`b'"), vce(cluster cluster_dist) scaleregul(0)
		local c_1 	= e(tau_cl)
		local c = string(`c_1', "%9.2f")		
	matrix CD[`row',`col'] = `c'
		local pv_1 	= e(pv_cl)
		local pv = string(`pv_1', "%9.3f")
	matrix CD[`row_pv',`col'] = `pv'
		local obs_1 = e(N)
		local obs = string(`obs_1', "%9.0f")
	matrix CD[`row_obs',`col'] = `obs'
	}
	}
	putexcel B2=matrix(CD)

*	For quintile D & E
	matrix define DE = J(18,6,.)
	putexcel set "$output_dir\RD_tests\2 tables\1 Search for design\search_design.xlsx", ///
		sheet("cutDE") ///
		modify
	global cells B C D E F G
	local col = 0
	local row2 = 0
	local row3 = -1
	foreach a of global dpto_select {
	local row = -2
	local row_pv = -1
	local row_obs = 0
	local row3 = `row3' + 3
	local col = `col' + 1
	local cell: word `col' of $cells
	putexcel `cell'1 = ("`a'")
	sleep 0
	putexcel A`row3' = ("`a'")
	sleep 0
	foreach b of global dpto_select {
	local row = `row' + 3
	local row_pv = `row_pv' + 3
	local row_obs = `row_obs' + 3
	quietly: rdrobust treat_13 index_cutDE if (Nivel=="D" | Nivel=="E") & ///
	(dpto=="`a'" | dpto=="`b'"), vce(cluster cluster_dist) scaleregul(0)
		local c_1 	= e(tau_cl)
		local c = string(`c_1', "%9.2f")		
	matrix DE[`row',`col'] = `c'
		local pv_1 	= e(pv_cl)
		local pv = string(`pv_1', "%9.3f")
	matrix DE[`row_pv',`col'] = `pv'
		local obs_1 = e(N)
		local obs = string(`obs_1', "%9.0f")
	matrix DE[`row_obs',`col'] = `obs'
	}
	}
	putexcel B2=matrix(DE)
	
}

	*-----------------------------------------------------------*
	*		I.2.	Graphic representation of chosen design		*
	*-----------------------------------------------------------*
{
*	Version 1: Using local polynomial smooth plot
**	Full sample
	graph twoway (lpolyci treat_13 index_cutBC if index_cutBC<0, acol(gs15)) 		///
	(lpolyci treat_13 index_cutBC if index_cutBC>=0, acol(gs15)) if index_victim<=1, 					///
		graphregion(color(white)) ///
		xtitle(Victimization Index (Around cutoff B-C))	///
		legend(off) ///
		ytitle(Estimated Pr(treatment) until 2013)
	graph export "$output_dir\RD_tests\1 graphs\0 Search for design\probtreat_fullsample_v1.png", ///
		replace

**	Restricted sample
* 2013
	graph twoway (lpolyci treat_13 index_cutBC if index_cutBC<0.05 &  index_cutBC>=0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), acol(gs15)) ///
	(lpolyci treat_13 index_cutBC if index_cutBC>=-0.05 & index_cutBC<=0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), acol(gs15)) ///
		if index_victim<=1, ///
		graphregion(color(white)) ///
		xtitle(" " "Victimization Index (Around cutoff B-C)") ///
		legend(off) ///
		ytitle(Estimated Pr(treatment) until 2013)
	graph export "$output_dir\RD_tests\1 graphs\0 Search for design\probtreat13_restricsample_sample2_v1.png", ///
		replace
		
	graph twoway (lpolyci treat_13 index_cutBC if index_cutBC>0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), acol(gs15)) ///
	(lpolyci treat_13 index_cutBC if index_cutBC<=0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), acol(gs15)) ///
		if index_victim<=1, ///
		graphregion(color(white)) ///
		xlab(-0.1(.1)1) ///
		xtitle(" " "Victimization Index (Around cutoff B-C)") ///
		legend(off) ///
		ytitle(Estimated Pr(treatment) until 2013) ///
		scheme(plotplain)
	graph export "$output_dir\probtreat13_restricsample_sample2_v1.jpg", ///
		replace		
			
		
* 2017
	graph twoway (lpolyci treat_17 index_cutBC if index_cutBC<0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), acol(gs15)) ///
	(lpolyci treat_17 index_cutBC if index_cutBC>=0  & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), acol(gs15)) ///
	if index_victim<1, ///
		graphregion(color(white)) ///
		xtitle(" " "Victimization Index (Around cutoff B-C)") ///
		legend(off) ///
		ytitle(Estimated Pr(treatment) until 2017)
	graph export "$output_dir\RD_tests\1 graphs\0 Search for design\probtreat17_restricsample_sample2_v1.png", ///
		replace
		
*	Version 2: Using rdplot
**	Full sample
	rdplot treat_13 index_cutBC if Nivel=="B" | Nivel=="C", ///
		scaleregul(0) ///
		p(4) ///
		binselect(esmvpr) ///
		graph_options(graphregion(color(white)) ///
		legend(off) ///					///
		xtitle(Victimization Index (Around cutoff B-C)) ///
		ytitle(Estimated Pr(treatment) until 2013))
	graph export "$output_dir\RD_tests\1 graphs\0 Search for design\probtreat_fullsample_v2.png", ///
		replace

**	Restricted sample	
* 2013
	rdplot treat_13 index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
		scaleregul(0) ///
		p(4) ///
		binselect(esmvpr) ///
		nbins(20 20) ///
		graph_options(graphregion(color(white)) ///
		legend(off) ///
		xtitle(" " "Victimization Index (Around cutoff B-C)") ///
		ytitle(Estimated Pr(treatment) until 2013))
	graph export "$output_dir\RD_tests\1 graphs\0 Search for design\probtreat13_restricsample_sample2v2.png", ///
		replace

* 2017
	rdplot treat_17 index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
		scaleregul(0) ///
		p(4) ///
		binselect(esmvpr) ///
		nbins(30 30) ///
		graph_options(graphregion(color(white)) ///
		legend(off)	///
		xtitle(" " "Victimization Index (Around cutoff B-C)") ///
		ytitle(Estimated Pr(treatment) until 2017))
	graph export "$output_dir\RD_tests\1 graphs\0 Search for design\probtreat17_restricsample_sample2v2.png", ///
		replace
		
		
		
}

}
*---------------------------------------------------*
*		II. Validation & Falsification tests		*
*---------------------------------------------------*

	*-----------------------------------------------*
	*		II.1.	Density of Running Variable		*
	*-----------------------------------------------*
{
*	For all the sample
	rddensity index_cutBC, ///
		bwselect(each)
	local bandwidth_left = e(h_l)
	local bandwidth_right = e(h_r)
	twoway (histogram index_cutBC if index_cutBC >= -`bandwidth_left' & index_cutBC < 0, freq width(0.0007) color(blue) lc(black) lw(thin)) ///
	(histogram index_cutBC if index_cutBC >= 0 & index_cutBC <= `bandwidth_right', freq width(0.0007) lc(black) lw(thin) color(red)), ///
		xlabel(-0.011(0.01)0.072) ///
		graphregion(color(white)) ///
		xtitle(Victimization Index (Around cutoff B-C)) ///
		ytitle(Number of Observations) ///
		legend(off) ///
		scheme(plotplain)
	graph export "$output_dir\Density of the Index 1.jpg", ///
		replace

	rddensity index_cutBC, ///
		bwselect(each)
	local bandwidth_left = e(h_l)
	local bandwidth_right = e(h_r)
	rddensity index_cutBC, ///
		plot ///
		graph_opt(xtitle(Victimization Index (Around cutoff B-C)) ytitle(Density) title("Estimated density of the Victimization Index -") title("Full sample", suffix) graphregion(color(white))) ///
		plot_range(-`bandwidth_left' `bandwidth_right') ///
		level(95)
	graph export "$output_dir\RD_tests\1 graphs\1 Density of running variable\rddensity_density_fullsample.png", ///
		replace


*	For the restricted sample
	rddensity index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" |dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
		bwselect(each)
	local bandwidth_left = e(h_l)
	local bandwidth_right = e(h_r)
	twoway (histogram index_cutBC if (index_cutBC >= -`bandwidth_left' & index_cutBC < 0) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), freq width(0.001) color(blue) lc(black) lw(thin)) ///
	(histogram index_cutBC if (index_cutBC >= 0 & index_cutBC <= `bandwidth_right') & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"),	freq width(0.001) color(red) lc(black) lw(thin)), ///
		xlabel(-0.015(0.005)0.015) ///
		graphregion(color(white)) ///
		xtitle(Victimization Index (Around cutoff B-C)) ///
		ytitle(Number of Observations) ///
		legend(off) ///
		title("Histogram of the Victimization Index -") ///
		title("Restricted sample", suffix)
	graph export "$output_dir\RD_tests\1 graphs\1 Density of running variable\rddensity_hist_restrictsample_sample2.png", ///
		replace

	rddensity index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
		bwselect(each)
	local bandwidth_left = e(h_l)
	local bandwidth_right = e(h_r)
	rddensity index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
		plot ///
		graph_opt(xtitle(Victimization Index (Around cutoff B-C)) ytitle(Density) title("Estimated density of the Victimization Index -") title("Restricted Sample", suffix) graphregion(color(white))) ///
		plot_range(-`bandwidth_left' `bandwidth_right') ///
		level(95)
	graph export "$output_dir\RD_tests\1 graphs\1 Density of running variable\rddensity_density_restrictsample_sample2.png", ///
		replace
		
		
		* Density of running variables - xnorm
			rddensity index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & index_cutBC<1 & index_cutBC>-0.03, 													///
				plot 															///
				kernel(triangular) 												///
				level(95) 														///
				graph_opt(graphregion(color(white)) scheme(plotplain)	xline(0)							///
				legend(off)														///
				xtitle(Victimization Index (centered around cutoff B-C), height(5)) ///
				title(, height(5))) ///
				plotl_estype(both) 	espl_opt(msize(small) mcolor(red%40)) plotl_citype(region)	cill_opt(lpattern(dash) lwidth(thin) lcolor(red%50))										///
				plotr_estype(both) espr_opt(msize(vsmall) mcolor(blue%40))  plotr_citype(region)	cilr_opt(lpattern(dash) lwidth(thin) lcolor(blue%50))
	graph export "$output_dir\Density of the Index 2.jpg", ///
		replace			
			
			histogram xnorm, graphregion(color(white))	xline(0)  bin(40) ///
				legend(off)														///
				xtitle(Standardized distance to nearest assignment frontier, height(5)) ///
				title(, height(5))
			graph export "$graphs\01-RD tests\Xnorm_histogram.png", replace
			

								
		
		
		
}
	*-----------------------------------------------*
	*		II.2.	Predetermined Covariates 		*
	*-----------------------------------------------*
{
	global pred_covs altitude_msnm log_distancia_capital ///
			log_pob_ccpp_2007 poverty2007_pared poverty2007_piso poverty2007_agua 	///
			poverty2007_saneamiento poverty2007_bienesriqueza poverty2007_combust 	///
			poverty2007_seguro poverty2007_analfabeta poverty2007_educ 				///
			poverty2007_desempleo poverty2007_alumbrado poverty2007_caracthh 		///
			poverty2007_servpub poverty2007_demogra poverty2007  ///
			prop_mujeres2007

*	Rd plots for predetermined covariates
**	For full sample
	foreach y of global pred_covs {
		rdplot `y' index_cutBC if index_victim<=1, ///
			kernel(tri) ///
			graph_options(graphregion(color(white)) xtitle(Victimization Index (Around cutoff B-C)) legend(off)	title("Rd plot `y' -") title("Full sample", suffix)) ///
			ci(95) ///
			shade
	graph export "$output_dir\RD_tests\1 graphs\2 Predetermined covariates\rdplot_covs_fullsample-`y'.png", ///
		replace
	}		

*	Rd plots for predetermined covariates
**	For restricted sample
	foreach y of global pred_covs {
		rdplot `y' index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
			kernel(tri) ///
			graph_options(graphregion(color(white)) xtitle(Victimization Index (Around cutoff B-C)) legend(off)	title("Rd plot `y' -") title("Restricted sample", suffix)) ///
			ci(95) ///
			shade
	graph export "$output_dir\RD_tests\1 graphs\2 Predetermined covariates\rdplot_covs_restrictsample_sample2-`y'.png", ///
		replace
	}		


		
*	Graphical illustration of local linear RD effects for predetermined covariates
**	For full sample
	foreach y of global pred_covs {
		rdrobust `y' index_cutBC, ///
			kernel(triangular) ///
			vce(cluster cluster_dist)
		local bandwidth = e(h_l)
		rdplot `y' index_cutBC if abs(index_cutBC)<=`bandwidth', ///
			p(1) ///
			kernel(triangular) ///
			graph_options(graphregion(color(white)) xtitle(Victimization Index (Around cutoff B-C)) legend(off)	title("Rd plot `y' -") title("Restricted sample", suffix)) ///
			ci(95) ///
			shade
	graph export "$output_dir\RD_tests\1 graphs\2 Predetermined covariates\rdrobust_covs_fullsample-`y'.png", ///
		replace
	}

*	Graphical illustration of local linear RD effects for predetermined covariates
**	For restricted sample
	foreach y of global pred_covs {
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") &	(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
			vce(cluster cluster_dist) 
		local bandwidth = e(h_l) 
		rdplot `y' index_cutBC if abs(index_cutBC)<=`bandwidth' & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
			p(1) ///
			kernel(triangular) ///
			nbins(20 20) ///
			graph_options(graphregion(color(white))	xtitle(Victimization Index (Around cutoff B-C)) legend(off) title("Rd plot `y' -") title("Restricted sample", suffix)) ///
			ci(95) ///
			shade
	graph export "$output_dir\RD_tests\1 graphs\2 Predetermined covariates\rdrobust_covs_restrictsample_sample2-`y'.png", ///
		replace
	}


* Graphical representation of test for continuity on predetermined covariates
	xtile index_cutBC_q20=index_cutBC, n(20)
	bys index_cutBC_q20: gen position=_n				
	foreach x in altitude_msnm log_pob_ccpp_2007 poverty2007_demogra 			///
		poverty2007_caracthh poverty2007_servpub  poverty2007 					///
		distancia_capital ///
			{
		bys index_cutBC_q20: egen `x'_means=mean(`x')
		replace `x'_means=. if position!=1
	}
		
	* altitude_msnm
	graph twoway (lpolyci altitude_msnm index_cutBC if index_cutBC<0 & abs(index_cutBC)<.1, ciplot(rline) lcolor(blue) fcolor(none) alcolor(black%80) alpattern(dash)) ///
	(lpolyci altitude_msnm index_cutBC  if index_cutBC>=0 & abs(index_cutBC)<.1,  ciplot(rline) lcolor(blue) fcolor(none) alcolor(black%80) alpattern(dash) pstyle(ci)) ///
	(scatter altitude_msnm_means index_cutBC if abs(index_cutBC)<.1, msize(small)) ///		
	, xline(0, lw(medium) lcolor(black)) ///
	ytitle(Altitude in meters, height(5))  ///
	graphregion(color(white)) ///
	legend(region(style(none)) span position(6) cols(2) order(2 "Local polinomial" 1 "95% Confidence Interval" )) ///
	xtitle(Victimization Index (Around cutoff B-C), height(5)) ///
	scheme(plotplain)
	graph export "$output_dir\lpolyci_covs_restrictsample_sample2-altitude_msnm.jpg", ///
	replace
	

	
	* log_pob_ccpp_2007
	graph twoway (lpolyci log_pob_ccpp_2007 index_cutBC if index_cutBC<0 & abs(index_cutBC)<.1, ciplot(rline) lcolor(blue) fcolor(none) alcolor(black%80) alpattern(dash)) ///
	(lpolyci log_pob_ccpp_2007 index_cutBC  if index_cutBC>=0 & abs(index_cutBC)<.1,  ciplot(rline) lcolor(blue) fcolor(none) alcolor(black%80) alpattern(dash) pstyle(ci)) ///
	(scatter log_pob_ccpp_2007_means index_cutBC if abs(index_cutBC)<.1, msize(small)) ///		
	, xline(0, lw(medium) lcolor(black)) ///
	ytitle(Population in 2007 (log), height(5)) ///
	graphregion(color(white)) ///
	legend(region(style(none)) span position(6) cols(2) order(2 "Local polinomial" 1 "95% Confidence Interval" )) ///
	xtitle(Victimization Index (Around cutoff B-C), height(5)) ///
	scheme(plotplain)
	graph export "$output_dir\lpolyci_covs_restrictsample_sample2-log_pob_ccpp_2007.jpg", ///
	replace
	
	* poverty2007_demogra
	graph twoway (lpolyci poverty2007_demogra index_cutBC if index_cutBC<0 & abs(index_cutBC)<.1, ciplot(rline) lcolor(blue) fcolor(none) alcolor(black%80) alpattern(dash)) ///
	(lpolyci poverty2007_demogra index_cutBC  if index_cutBC>=0 & abs(index_cutBC)<.1,  ciplot(rline) lcolor(blue) fcolor(none) alcolor(black%80) alpattern(dash) pstyle(ci)) ///
	(scatter poverty2007_demogra_means index_cutBC if abs(index_cutBC)<.1, msize(small)) ///		
	, xline(0, lw(medium) lcolor(black)) ///
	ytitle(Poverty index in 2007 - Demographics pillar, height(5)) ///
	graphregion(color(white)) ///
	legend(region(style(none)) span position(6) cols(2) order(2 "Local polinomial" 1 "95% Confidence Interval" )) ///
	xtitle(Victimization Index (Around cutoff B-C), height(5)) ///
	scheme(plotplain)
	graph export "$output_dir\lpolyci_covs_restrictsample_sample2-poverty2007_demogra.jpg", ///
	replace
	
	
	
	
	
	

*	Formal continuity-based analysis for predetermined covariates
**	For full sample
	putexcel set "$output_dir\RD_tests\2 tables\2 Predetermined covariates\continuity_covs_fullsample.xlsx", ///
		sheet("R1") ///
		modify
	matrix define R1 = J(20, 6, .)
	local r1 = 1
	local r1_v = 3
	foreach y of global pred_covs {
		rdrobust `y' index_cutBC, ///
			all ///
			vce(cluster cluster_dist)
		local label_`r1': variable label `y'
		matrix R1[`r1', 1] = e(h_l)
		matrix R1[`r1', 2] = e(tau_cl)
		matrix R1[`r1', 3] = 2 * normal(-abs(e(tau_bc) / e(se_tau_rb)))
		matrix R1[`r1', 4] = e(tau_bc) - invnormal(0.975) * e(se_tau_rb)
		matrix R1[`r1', 5] = e(tau_bc) + invnormal(0.975) * e(se_tau_rb)
		matrix R1[`r1', 6] = e(N_h_l) + e(N_h_r)
		
		putexcel A`r1_v' = ("`y'")
		
		local r1 = `r1' + 1
		local r1_v = `r1_v' + 1
	}
	putexcel B3=matrix(R1)
	sleep 0
	putexcel B2=("MSE-Optimal Bandwidth")
	sleep 0
	putexcel C2=("RD Estimator")
	sleep 0
	putexcel D1=("Robust Inference")
	sleep 0
	putexcel D2=("p-value")
	sleep 0
	putexcel E2=("Conf. Int.")
	sleep 0
	putexcel G2=("Eff. Number of Observations (communities)")

*	Formal continuity-based analysis for predetermined covariates
**	For the restricted sample
	global pred_covs altitude_msnm log_distancia_capital ///
			log_pob_ccpp_2007 poverty2007 
			
	putexcel set "$output_dir\continuity_covs_restrictsample_sample2.xlsx", ///
		sheet("R2") ///
		modify
	matrix define R2 = J(20, 6, .)
	local r2 = 1
	local r2_v = 3
	foreach y of global pred_covs {
		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
			all ///
			vce(cluster cluster_dist)
		local label_`r2': variable label `y'
		matrix R2[`r2', 1] = e(h_l)
		matrix R2[`r2', 2] = e(tau_cl)
		matrix R2[`r2', 3] = 2 * normal(-abs(e(tau_bc) / e(se_tau_rb)))
		matrix R2[`r2', 4] = e(tau_bc) - invnormal(0.975) * e(se_tau_rb)
		matrix R2[`r2', 5] = e(tau_bc) + invnormal(0.975) * e(se_tau_rb)
		matrix R2[`r2', 6] = e(N_h_l) + e(N_h_r)
		
		putexcel A`r2_v' = ("`y'")
		
		local r2 = `r2' + 1
		local r2_v = `r2_v' + 1
	}
	putexcel B3=matrix(R2)
	sleep 0
	putexcel B2=("MSE-Optimal Bandwidth")
	sleep 0
	putexcel C2=("RD Estimator")
	sleep 0
	putexcel D1=("Robust Inference")
	sleep 0
	putexcel D2=("p-value")
	sleep 0
	putexcel E2=("Conf. Int.")
	sleep 0
	putexcel G2=("Eff. Number of Observations (communities)")
	
	
	
	* .tex output for paper
	global pred_covs altitude_msnm log_distancia_capital ///
			log_pob_ccpp_2007 poverty2007 
			

	* pretty names (or rely on var labels if you prefer)
	label var altitude_msnm           "Height (meters above the sea level)"
	label var log_distancia_capital   "Distance to district capital (log km.)"
	label var log_pob_ccpp_2007       "Population in 2007 (log)"
	label var poverty2007             "Poverty Index 2007"

	local outtex  "$output_dir\Main results - Formal continuity covariates tests.tex"

	file close _all
	file open fh using "`outtex'", write replace text

	file write fh "\begin{table}[H]"
	file write fh "\centering"
	file write fh "\caption{Formal continuity test for predetermined covariates - Restricted sample}"
	file write fh "\label{tab:continuity_covariates}"
	file write fh "\resizebox{17cm}{!}"
	file write fh "{\small" _n
	file write fh "\begin{tabular}{lcccccc}" _n
	file write fh "\toprule" _n
	file write fh "\textbf{Variable} & \textbf{MSE-Optimal Bandwidth} & \textbf{RD Estimator} & \textbf{p-value} & \textbf{Confidence Interval} & \textbf{Eff. Number of Observations (communities)} \\" _n
	file write fh "\midrule" _n

	set seed 12345
	foreach y of global pred_covs {

		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
			(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | ///
			 prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
			all vce(cluster cluster_dist)

		* values to report
		scalar bw     = e(h_l)                               // MSE-optimal h (left)
		scalar rdhat  = e(tau_cl)                            // RD point estimate (conventional)
		scalar pval   = 2*normal(-abs(e(tau_bc)/e(se_tau_rb)))   // robust p-value
		scalar cil    = e(tau_bc) - invnormal(0.975)*e(se_tau_rb)
		scalar ciu    = e(tau_bc) + invnormal(0.975)*e(se_tau_rb)
		scalar effN   = e(N_h_l) + e(N_h_r)

		* pretty variable name (uses var label)
		local lab : variable label `y'
		if "`lab'"=="" local lab "`y'"
		* escape underscores for LaTeX
		local lab = subinstr("`lab'","_","\_",.)

		* format numbers
		local fbw   : display %6.3f bw
		local frd   : display %9.3f rdhat
		local fpv   : display %6.3f pval
		local fcil  : display %9.3f cil
		local fciu  : display %9.3f ciu
		local fN    : display %9.0f effN

		* write one row
		file write fh "`lab' & `fbw' & `frd' & `fpv' & [`fcil' ; `fciu'] & `fN' \\" _n
	}

	file write fh "\midrule" _n
	file write fh "\end{tabular}}" _n
	file write fh "\begin{minipage}{\textwidth}" _n
	file write fh "\footnotesize\textit{Notes:} Each row reports a continuity test for a predetermined community characteristic using a local--linear regression discontinuity specification estimated with \texttt{rdrobust} on the restricted sample of communities around the B--C cutoff of the victimization index. MSE-Optimal Bandwidth is the data-driven bandwidth around the cutoff. The RD estimator is the conventional point estimate of the jump in the covariate at the threshold, while p-values and 95\% confidence intervals are based on bias-corrected estimates and robust standard errors clustered at the district level. Eff. Number of Observations is the total number of communities within the selected bandwidth on both sides of the cutoff." _n
	file write fh "\end{minipage}" _n
	file write fh "\end{table}"
	file close fh

	* .tex output for paper - Appendix
	global pred_covs altitude_msnm log_distancia_capital ///
			log_pob_ccpp_2007 poverty2007_pared poverty2007_piso poverty2007_agua 	///
			poverty2007_saneamiento poverty2007_bienesriqueza poverty2007_combust 	///
			poverty2007_seguro poverty2007_analfabeta poverty2007_educ 				///
			poverty2007_desempleo poverty2007_alumbrado poverty2007_caracthh 		///
			poverty2007_servpub poverty2007_demogra poverty2007  ///
			prop_mujeres2007

	* pretty names (or rely on var labels if you prefer)
	label var altitude_msnm           "Height (meters above the sea level)"
	label var log_distancia_capital   "Distance to district capital (log km.)"
	label var log_pob_ccpp_2007       "Population in 2007 (log)"
	label var poverty2007             "Poverty Index 2007"
	label var poverty2007_pared       "Poverty index 2007 – wall material (housing quality)"
	label var poverty2007_piso        "Poverty index 2007 – floor material (housing quality)"
	label var poverty2007_agua        "Poverty index 2007 – drinking water source"
	label var poverty2007_saneamiento "Poverty index 2007 – sanitation system"
	label var poverty2007_bienesriqueza "Poverty index 2007 – household assets / wealth"
	label var poverty2007_combust     "Poverty index 2007 – cooking fuel / energy source"
	label var poverty2007_seguro      "Poverty index 2007 – health insurance coverage"
	label var poverty2007_analfabeta  "Poverty index 2007 – literacy (share who can read/write)"
	label var poverty2007_educ        "Poverty index 2007 – educational attainment"
	label var poverty2007_desempleo   "Poverty index 2007 – employment (share employed)"
	label var poverty2007_alumbrado   "Poverty index 2007 – access to electric lighting"
	label var poverty2007_caracthh    "Composite poverty index 2007 – housing characteristics"
	label var poverty2007_servpub     "Composite poverty index 2007 – basic public services"
	label var poverty2007_demogra     "Composite poverty index 2007 – demographic \& human capital"
	label var poverty2007             "Overall multidimensional poverty index 2007"
	label var prop_mujeres2007        "Proportion of women in CCPP (2007)"
		

	local outtex  "$output_dir\Appendix - Formal continuity covariates tests.tex"

	file close _all
	file open fh using "`outtex'", write replace text

	file write fh "\begin{table}[H]"
	file write fh "\centering"
	file write fh "\resizebox{17cm}{!}"
	file write fh "{\small" _n
	file write fh "\begin{tabular}{lcccccc}" _n
	file write fh "\toprule" _n
	file write fh "\textbf{Variable} & \textbf{MSE-Optimal Bandwidth} & \textbf{RD Estimator} & \textbf{p-value} & \textbf{Confidence Interval} & \textbf{Eff. Number of Observations (communities)} \\" _n
	file write fh "\midrule" _n

	set seed 12345
	foreach y of global pred_covs {

		rdrobust `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
			(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | ///
			 prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
			all vce(cluster cluster_dist)

		* values to report
		scalar bw     = e(h_l)                               // MSE-optimal h (left)
		scalar rdhat  = e(tau_cl)                            // RD point estimate (conventional)
		scalar pval   = 2*normal(-abs(e(tau_bc)/e(se_tau_rb)))   // robust p-value
		scalar cil    = e(tau_bc) - invnormal(0.975)*e(se_tau_rb)
		scalar ciu    = e(tau_bc) + invnormal(0.975)*e(se_tau_rb)
		scalar effN   = e(N_h_l) + e(N_h_r)

		* pretty variable name (uses var label)
		local lab : variable label `y'
		if "`lab'"=="" local lab "`y'"
		* escape underscores for LaTeX
		local lab = subinstr("`lab'","_","\_",.)

		* format numbers
		local fbw   : display %6.3f bw
		local frd   : display %9.3f rdhat
		local fpv   : display %6.3f pval
		local fcil  : display %9.3f cil
		local fciu  : display %9.3f ciu
		local fN    : display %9.0f effN

		* write one row
		file write fh "`lab' & `fbw' & `frd' & `fpv' & [`fcil' ; `fciu'] & `fN' \\" _n
	}

	file write fh "\midrule" _n
	file write fh "\multicolumn{6}{l}{\textit{Note:} p-values and confidence intervals were calculated from robust inference estimators.} \\" _n
	file write fh "\end{tabular}}" _n
	file write fh "\end{table}"
	file close fh
	
	

}
*---------------------------------------*
*		III.	Bandwidth selection		*
*---------------------------------------*

*---------------------------------------*
*		III.1.	Window selection		*
*---------------------------------------*
/*
rdwinselect index_cutBC altitude_msnm log_distancia_capital poverty2007_caracthh poverty2007_servpub poverty2007_demogra ///
prop_actividad_agricola2007 log_pob_ccpp_2007 urb_rur_ccpp_2007 if (dpto=="APURIMAC" | dpto=="HUANCAVELICA" | prov=="LA CONVENCION" | prov=="HUANCAYO"), ///
nw(25) wstep(0.001) level(0.1) reps(1000) plot stat(ttest) graph_options(graphregion(color(white)) ///
title(Minimum p-value from covariate test) xtitle(Window lenght / 2) yline(0.1, lpattern(shortdash)) ytitle(P-value)) 
graph export "$output_dir\RD_tests\1 graphs\3 Randomization inference\rdwinselect_restrictsample_sample2.png", replace
*/

	global controls altitude_msnm log_distancia_capital poverty2007_caracthh ///
	poverty2007_servpub poverty2007_demogra prop_actividad_agricola2007 ///
	log_pob_ccpp_2007 urb_rur_ccpp_2007 prop_a13

	global outcomes_ccpp pob_ccpp_2013 pob_ccpp_2017 log_pob_ccpp_2013 log_pob_ccpp_2017 hog_ccpp_2013 viv_ccpp_2017 log_hog_ccpp_2013 log_hog_ccpp_2017 ///
		prop_mujeres ///
		prop_edad_u1 prop_edad_1_14 prop_edad_15_29 prop_edad_30_44 prop_edad_45_64 prop_edad_65 prop_edad_15 prop_edad_0_5 prop_edad_5_10 prop_edad_10_15 prop_edad_15_20 prop_edad_20_25 prop_edad_25_30 prop_edad_30_35 prop_edad_35_40 prop_edad_40_45 prop_edad_45_50 prop_edad_50_55 prop_edad_55_60 prop_edad_60_65 prop_edad_65_70 prop_edad_70_mas ///
		prop_educ_ninguno prop_educ_inicial prop_educ_primaria prop_educ_secundaria prop_educ_tecnica prop_educ_universitaria prop_educ_postgrado ///
		prop_lee_si ///
		sis_pnbi1 sis_pnbi2 sis_pnbi3 sis_pnbi5 ///	
		prop_programa_ninguno ///
		prop_seguro_sis prop_seguro_ninguno ///
		prop_actividad_agricola prop_actividad_pecuaria prop_actividad_comercial prop_actividad_servicios prop_actividad_estatal prop_pea_ocupada

	rdbwselect sis_pnbi5 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="APURIMAC"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		all kernel(triangular) covs($controls) p(1)
		
	putexcel set "$output_dir\RD_tests\2 tables\4 Bandwidth selection\BW options outcomes.xlsx", ///
		sheet("Bandwidth") ///
		modify		
		matrix define R2 = J(52, 10, .)	
		local cont = 1
		local cont2 = 3
	foreach y in $outcomes_ccpp {
	rdbwselect `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		all kernel(triangular) covs($controls) p(1)

		local label_`r2': variable label `y'
		matrix R2[`cont', 1] = e(h_msecomb2_l)
		matrix R2[`cont', 2] = e(h_msecomb2_r)
		matrix R2[`cont', 3] = e(h_cercomb2_l)
		matrix R2[`cont', 4] = e(h_cercomb2_r)
		
		count if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO") & index_cutBC>=-e(h_msecomb2_l) & index_cutBC<=e(h_msecomb2_r)
		matrix R2[`cont', 5] = r(N)

	rdbwselect `y' index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		all kernel(triangular) covs($controls) p(2)
		
		matrix R2[`cont', 6] = e(h_msecomb2_l)
		matrix R2[`cont', 7] = e(h_msecomb2_r)
		matrix R2[`cont', 8] = e(h_cercomb2_l)
		matrix R2[`cont', 9] = e(h_cercomb2_r)	
		
		count if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO") & index_cutBC>=-e(h_msecomb2_l) & index_cutBC<=e(h_msecomb2_r)
		matrix R2[`cont', 10] = r(N)		
		
		putexcel A`cont2' = ("`y'")
		
		local cont = `cont' + 1
		local cont2 = `cont2' + 1

	}
	
	putexcel B3=matrix(R2)
	sleep 0
	putexcel B1=("Polynomial degree 1")
	sleep 0	
	putexcel B2=("MSE-Optimal Bandwidth (left)")
	sleep 0
	putexcel C2=("MSE-Optimal Bandwidth (right)")
	sleep 0
	putexcel D2=("CER-Optimal Bandwidth (left)")
	sleep 0
	putexcel E2=("CER-Optimal Bandwidth (right)")
	sleep 0
	putexcel F2=("Number of observations")
	sleep 0
	putexcel G1=("Polynomial degree 2")
	sleep 0
	putexcel G2=("MSE-Optimal Bandwidth (left)")
	sleep 0
	putexcel H2=("MSE-Optimal Bandwidth (right)")
	sleep 0
	putexcel I2=("CER-Optimal Bandwidth (left)")
	sleep 0
	putexcel J2=("CER-Optimal Bandwidth (right)")
	sleep 0
	putexcel K2=("Number of observations")
		
		
		

*-------------------------------------------*
*		III.2.	Descriptive statistics		*
*-------------------------------------------*

global sumstats index_victim index_cutBC treat_13 $pred_covs 
matrix define RI = J(10, 6, .)
putexcel set "$output_dir\RD_tests\2 tables\3 Randomization inference\descriptive.xlsx", sheet("RI") modify
local ri = 1
local ri2 = 3
foreach x of global sumstats {
	quietly summarize `x' if abs(index_cutBC)<=0.02 & (dpto=="HUANCAVELICA" |	///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), detail
	matrix RI[`ri', 1] = r(mean)
	matrix RI[`ri', 2] = r(p50)
	matrix RI[`ri', 3] = r(sd)
	matrix RI[`ri', 4] = r(min)
	matrix RI[`ri', 5] = r(max)
	matrix RI[`ri', 6] = r(N)
	putexcel A`ri2' = ("`x'")
	sleep 0
	local ri = `ri' + 1
	local ri2 = `ri2' + 1
}
putexcel B3=matrix(RI)
sleep 0
putexcel B2=("Mean")
sleep 0
putexcel C2=("Median")
sleep 0
putexcel D2=("Std. Deviation")
sleep 0
putexcel E2=("Min.")
sleep 0
putexcel F2=("Max.")
sleep 0
putexcel G2=("Obs.")

*-----------------------------------------------------------------------*
*		III.3.	Formal local-randomization analysis for covariates		*
*-----------------------------------------------------------------------*

local window = 0.02
matrix define RI2 = J(7, 5, .)
putexcel set "$output_dir\RD_tests\2 tables\3 Randomization inference\rdrandinf_covs.xlsx", sheet("RIcovs") modify
local ri2 = 1
local ri3 = 3
foreach y of global pred_covs {
	ttest `y' if abs(index_cutBC) <= `window' & (dpto=="HUANCAVELICA" | 		///
	dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"), by(treat_13)
	matrix RI2[`ri2', 1] = r(mu_1)
	matrix RI2[`ri2', 2] = r(mu_2)

	rdrandinf `y' index_cutBC if (dpto=="HUANCAVELICA" | dpto=="APURIMAC" |		///
	prov=="LA CONVENCION" | prov=="HUANCAYO"),		///
	wl(-`window') wr(`window') fuzzy(treat_13 tsls)
	matrix RI2[`ri2', 3] = r(obs_stat)
	matrix RI2[`ri2', 4] = r(asy_pval)
	matrix RI2[`ri2', 5] = r(N)
	
	putexcel A`ri3' = ("`y'")
	sleep 0
	local ri2 = `ri2' + 1
	local ri3 = `ri3' + 1
}
putexcel B3=matrix(RI2)
sleep 0
putexcel B2=("Untreated average")
sleep 0
putexcel C2=("Treated average")
sleep 0
putexcel D2=("Observed statistic")
sleep 0
putexcel E2=("p-value")
sleep 0
putexcel F2=("Obs. (# communities)")








