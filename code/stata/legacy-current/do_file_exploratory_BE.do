/*------------------------------------------------------------------------------*
| Title: 			  Evaluate RD viability in SISFOH DB						|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Bruno Esposito						                    |
| 					  									                        |
|																				|
|Description:		  Try multiple RD specifications until I find a			    |
|					  valid robust regression discontinuity						|
|                                                                               |
|Date Created: 20/08/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import communities dataset with index
	2.	RD specification:
		2.1 For 2013 sample
		2.2 For 2013 filtered by region
		2.3 For 2017 sample
		2.4 For 2017 filtered by treatment date

*-------------------------------------------------------------------------------*/

*--------------------------*
*     0. Control Panel     *
*--------------------------*
	clear all
	set more off
	*set graphics off
	
*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
global a "/Users/bruno_esposito/Dropbox/Proyectos/Matthew/VictimasRD"
global poly_order = 3
global cutoff = .0623
global wanna_graph = 1

*-----------------------------------------------*
*		1. Import CCPP SISFOH dataset			*
*-----------------------------------------------*

	use "$a/data/communities_sisfoh.dta",clear

*-----------------------------------*
*		2. RD Specficiations		*
*-----------------------------------*

	* TODO: Why there are 266 TREATED observations without sisfoh_years?
	tab treated_sisfoh_years treated_sisfoh, missing

	/**
	
	treated_si |    treated_sisfoh
	sfoh_years |         0          1 |     Total
	-----------+----------------------+----------
			-5 |        26          0 |        26 
			-4 |        69          0 |        69 
			-3 |        91          0 |        91 
			-2 |        97          0 |        97 
			-1 |        82          0 |        82 
			 0 |       135          0 |       135 
			 1 |         0        160 |       160 
			 2 |         0        184 |       184 
			 3 |         0        291 |       291 
			 4 |         0        378 |       378 
			 5 |         0        245 |       245 
			 6 |         0        133 |       133 
			 . |     3,546        266 |     3,812 
	-----------+----------------------+----------
		 Total |     4,046      1,657 |     5,703 

	**/

	* To fix this (if these observations were not treated):
	*replace treated_sisfoh = 0 if treated_sisfoh_years == .

*-----------------------------------*
*		2.1. 2013 sample			*
*-----------------------------------*
	
	local target_var treated_sisfoh
	rdrobust `target_var' NumeroIndice, c($cutoff) p($poly_order)
	rdrobust `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) kernel(epa)
	
	if $wanna_graph == 1 {
		rdplot `target_var' NumeroIndice, c($cutoff) 
		graph export "$a/output/graphs/treatment/sampleALL_2013.pdf", replace 
		
		* Renard's way
		twoway scatter `target_var' NumeroIndice if  Nivel=="B" | Nivel=="C"  , mcolor(*.6) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="B", lcolor(blue) degree($poly_order) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="C", lcolor(red) degree($poly_order) 
		graph export "$a/output/graphs/treatment/sampleBC_2013_renard.pdf", replace 
		 
		* Cattaneo's way 
		rdplot `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) ci(95) shade kernel(epa)
		graph export "$a/output/graphs/treatment/sampleBC_2013_cattaneo.pdf", replace 
		
		* Cattaneo denisty test:
		rddensity NumeroIndice, c($cutoff) plot
		graph export "$a/output/graphs/RD_tests/density_sampleBC_2013.pdf", replace 
	}

	
*-----------------------------------------------*
*		2.2. 2013 filtered by region			*
*-----------------------------------------------*
	use "$a/data/communities_sisfoh.dta",clear
	keep if	Departamento == "APURIMAC"		| ///
			Departamento == "HUANCAVELICA"	| ///
			Departamento == "JUNIN"		
			
	local target_var treated_sisfoh
	rdrobust `target_var' NumeroIndice, c($cutoff) p($poly_order)
	rdrobust `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) kernel(epa)
	
	if $wanna_graph == 1 {
		rdplot `target_var' NumeroIndice, c($cutoff)
		graph export "$a/output/graphs/treatment/sampleALL_2013region.pdf", replace
		
		* Renard's way
		twoway scatter `target_var' NumeroIndice if  Nivel=="B" | Nivel=="C"  , mcolor(*.6) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="B", lcolor(blue) degree($poly_order) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="C", lcolor(red) degree($poly_order) 
		graph export "$a/output/graphs/treatment/sampleBC_2013region_renard.pdf", replace 
		 
		* Cattaneo's way 
		rdplot `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) ci(95) shade kernel(epa)
		graph export "$a/output/graphs/treatment/sampleBC_2013region_cattaneo.pdf", replace 
		
		* Cattaneo denisty test:
		rddensity NumeroIndice, c($cutoff) plot
		graph export "$a/output/graphs/RD_tests/density_sampleBC_2013region.pdf", replace 
	}



*-----------------------------------*
*		2.3. 2017 sample			*
*-----------------------------------*
	use "$a/data/communities_sisfoh.dta",clear
	gen treated_sisfoh_complete = treated_sisfoh
	replace treated_sisfoh_complete = 1 if treated_sisfoh_years != .

	local target_var treated_sisfoh_complete
	rdrobust `target_var' NumeroIndice, c($cutoff)
	rdrobust `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) kernel(epa)
	
	if $wanna_graph == 1 {
		rdplot `target_var' NumeroIndice, c($cutoff) p($poly_order)
		graph export "$a/output/graphs/treatment/sampleALL_2017.pdf", replace
		
		* Renard's way
		twoway scatter `target_var' NumeroIndice if  Nivel=="B" | Nivel=="C"  , mcolor(*.6) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="B", lcolor(blue) degree($poly_order) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="C", lcolor(red) degree($poly_order) 
		graph export "$a/output/graphs/treatment/sampleBC_2017_renard.pdf", replace 
		 
		* Cattaneo's way 
		rdplot `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) ci(95) shade kernel(epa)
		graph export "$a/output/graphs/treatment/sampleBC_2017_cattaneo.pdf", replace 
		
		* Cattaneo denisty test:
		rddensity NumeroIndice, c($cutoff) plot
		graph export "$a/output/graphs/RD_tests/density_sampleBC_2017.pdf", replace 
	}
	

*---------------------------------------------------*
*		2.4. 2013 filtered by treatment date		*
*---------------------------------------------------*

	use "$a/data/communities_sisfoh.dta",clear
	drop if treated_sisfoh_years > 0 & treated_sisfoh_years < 1000
	gen treated_sisfoh_new = 0
	replace treated_sisfoh_new = 1 if treated_sisfoh_years <= 0 & treated_sisfoh_years > -1000

	local target_var treated_sisfoh_new
	rdrobust `target_var' NumeroIndice, c($cutoff)
	rdrobust `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) kernel(epa)
	
	if $wanna_graph == 1 {
		rdplot `target_var' NumeroIndice, c($cutoff) p($poly_order)
		graph export "$a/output/graphs/treatment/sampleALL_2017date.pdf", replace
		
		* Renard's way
		twoway scatter `target_var' NumeroIndice if  Nivel=="B" | Nivel=="C"  , mcolor(*.6) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="B", lcolor(blue) degree($poly_order) ///
			|| lpolyci `target_var' NumeroIndice  if  Nivel=="C", lcolor(red) degree($poly_order) 
		graph export "$a/output/graphs/treatment/sampleBC_2017date_renard.pdf", replace 
		 
		* Cattaneo's way 
		rdplot `target_var' NumeroIndice if Nivel=="B" | Nivel=="C", c($cutoff) p($poly_order) ci(95) shade kernel(epa)
		graph export "$a/output/graphs/treatment/sampleBC_2017date_cattaneo.pdf", replace 

		* Cattaneo denisty test:
		rddensity NumeroIndice, c($cutoff) plot
		graph export "$a/output/graphs/RD_tests/density_sampleBC_2017date.pdf", replace 
		
	}


