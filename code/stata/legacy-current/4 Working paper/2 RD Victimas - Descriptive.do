/*------------------------------------------------------------------------------*
| Title:			Descriptive Statistic										|
| Project: 			Victimas RD									   				|	  
| Authors:			Jorge Zavala							                    |
| 					  									                        |
|																				|
| Description:		This .do creates and exports descriptive statistics of the 	|
|                   data to be used in the RD analysis							|
|						                                                        |
| Date Created: 	08/10/2018			 					                    |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/
/*--------------------------*
*           INDEX           *
*---------------------------*

	I.		Victimization Index
	
	II.		Treatment
	
	III.	Summary Statistics

*-------------------------------------------------------------------------------*/

*-----------------------------------*
*		I.	Victimization Index		*
*-----------------------------------*

use "$input_dir\3 Coded\community_index_treated_sisfohccpp.dta", clear

*	Stats for index and components
	global sumstats index_victim Fallecidos Desaparecidos Torturados Discapacitados ///
			Viudos Huerfanos Desplazados AutMuertas AutDesaparecidas 				///
			AutDesplazadas OrgAfectadas DestrucBsFamiliares DestrucBsComunales 		///
			Incursiones
			
	matrix define R = J(16, 6, .)
	putexcel set "$output_dir\Descriptive\1 Victimization index\1 tables\descriptive_index.xlsx", sheet("Stats Index") modify
	local ri = 1
	local ri2 = 3
	foreach x of global sumstats {
		quietly summarize `x', detail
		matrix R[`ri', 1] = r(mean)
		matrix R[`ri', 2] = r(p50)
		matrix R[`ri', 3] = r(sd)
		matrix R[`ri', 4] = r(min)
		matrix R[`ri', 5] = r(max)
		matrix R[`ri', 6] = r(N)
		putexcel A`ri2' = ("`x'")
		sleep 1000
		local ri = `ri' + 1
		local ri2 = `ri2' + 1
	}
	putexcel B3=matrix(R)
	sleep 1000
	putexcel B2=("Mean")
	sleep 1000
	putexcel C2=("Median")
	sleep 1000
	putexcel D2=("Std. Deviation")
	sleep 1000
	putexcel E2=("Min.")
	sleep 1000
	putexcel F2=("Max.")
	sleep 1000
	putexcel G2=("Obs.")

*	Distribution of index
	hist index_victim if index_victim <=1, ///
		bin(100) ///
		xlab(0(.1)1) ///
		percent ///
		xtitle("Victimization Index") ///
		lw(vthin) ///
		graphregion(color(white)) ///
		xline(.1538, lp(dash)) ///
		xline(.0623, lp(dash)) ///
		xline(.0269, lp(dash)) ///
		xline(.0152, lp(dash)) ///
		xline(.0077, lp(dash)) ///
		scheme(plotplain)
	graph export "$output_dir\Distribution of the Victimization Index.jpg", replace


*-------------------------------*
*		II.		Treatment		*
*-------------------------------*

*	Distribution of treatment through the years
	hist Financiado, ///
		discrete ///
		freq ///
		addlabels ///
		ylabel(,grid) ///
		xlabel(2007(1)2017) ///
		width(.5) ///
		xtitle(Year of Financing) ///
		graphregion(color(white)) ///
		fc(gray) lc(black) ///
		lw(vthin) ///
		ytitle(Number of financed communities)
	graph export "$output_dir\Descriptive\1 Victimization index\2 graphs\hist_yearstreated.png", ///
		replace

*	Proportion of treated communities until 2017 by Index Quintile
	encode Nivel, ///
		gen(Nivel_coded)
		replace Nivel_coded = Nivel_coded*-1
	graph twoway lpolyci treat_17 Nivel_coded, clp(longdash) || ///
		lpolyci treat_13 Nivel_coded , ///
		clp(shortdash_dot) ///
		xlabel(-1 "A" -2 "B" -3 "C" -4 "D" -5 "E") ///
		ytitle(Treated communities until 2013 & 2017 (%)) ///
		graphregion(color(white)) ///
		legend(order(4 "2013" 2 "2017") on position(6) cols(2) region(style(none))) ///
		xtitle(Index quintile) ///
		scheme(plotplain)
	graph export "$output_dir\percentage of financed communities.jpg", ///
		replace

		
*	Proportion of treated communities until 2013 by Index Quintile
graph twoway lpolyci treat_13 Nivel_coded, xlabel(1 "A" 2 "B" 3 "C" 4 "D" 5 "E") ///
ytitle(% of treated communities until 2013) graphregion(color(white)) legend(off) ///
xtitle(Index quintile) 
graph export "$output_dir\Descriptive\1 Victimization index\2 graphs\hist_Niveltreated2013.png", replace


*	Maps at region level
	preserve
	destring ubigeo_dpto, ///
		gen(id)
	
	collapse (max) id ///
	(count) N=index_victim ///
	(sum) treat_13 treat_17 ///
	(mean) index_victim ///
	(p50) p50_index_victim=index_victim, ///
		by(dpto)
		
	merge 1:1 id using "$input_dir\data_dpto.dta", ///
		keepusing(id)
	replace N = 0 if _merge==2
	replace treat_13 = 0 if _merge==2
	replace treat_17 = 0 if _merge==2
	replace index_victim = 0 if _merge==2
	replace p50_index_victim = 0 if _merge==2
	drop _merge
	replace index_victim = round( index_victim , 0.001)
	replace p50_index_victim = round( p50_index_victim , 0.001)

**	Number of victimized communities by region
	spmap N using "$input_dir\coor_dpto.dta", ///
		id(id) ///
		clmethod(q) ///
		cln(6) ///
		fcolor(Reds2) ///
		title("Victimized Communities") ///
		note("Peru, 2017" "Source: CMAN") ///
		legend(size(medium) position(7)) 
	graph export "$output_dir\Descriptive\1 Victimization index\2 graphs\map_numbercommunities.png", ///
		replace

**	Number of treated communities until 2013 by region
	spmap treat_13 using "$input_dir\coor_dpto.dta", ///
		id(id) ///
		clmethod(q) ///
		fcolor(Greys) ///
		title("Financed communities until 2013") ///
		note("Source: CMAN") ///
		cln(6) ///
		legend(size(medium) position(7)) 
	graph export "$output_dir\map financed communities 1.jpg", ///
		replace

**	Number of treated communities until 2017 by region
	spmap treat_17 using "$input_dir\coor_dpto.dta", ///
		id(id) ///
		clmethod(q) ///
		fcolor(Reds2) ///
		title("Financed communities until 2017") ///
		note("Peru, 2017" "Source: CMAN") cln(6) ///
		legend(size(medium) position(7)) 
	graph export "$output_dir\Descriptive\1 Victimization index\2 graphs\map_treat17.png", ///
		replace

**	Average victimization index score by region
	spmap index_victim using "$input_dir\coor_dpto.dta", id(id) clmethod(q) fcolor(Greys)	///
	title("Average Victimization Index") note("Source: CMAN") cln(6)	///
	legend(size(medium) position(7)) 
	graph export "$output_dir\average and median victimization 1.jpg", replace

**	Median victimization index score by region
	spmap p50_index_victim using "$input_dir\coor_dpto.dta", id(id) clmethod(q) fcolor(Greys)	///
	title("Median Victimization Index") note("Source: CMAN") cln(4)	///
	legend(size(medium) position(7)) 
	graph export "$output_dir\average and median victimization 2.jpg", replace

**	Percentage of treated communities by region
	gen prop_treat13 = round(treat_13/N,0.01)
	gen prop_treat17 = round(treat_17/N,0.01)
	spmap prop_treat17 using "$input_dir\coor_dpto.dta", id(id) clmethod(q) cln(5)		///
	title("% of financed communities until 2017") note("Peru, 2017" "Source: CMAN") ///
	legend(size(medium) position(7)) ndl("No victimized communities") fcolor(Reds2)
	graph export "$output_dir\Descriptive\1 Victimization index\2 graphs\map_proptreat17.png", replace

	spmap prop_treat13 using "$input_dir\coor_dpto.dta", id(id) clmethod(q) cln(5)		///
	title("% of financed communities until 2013") note("Source: CMAN") ///
	legend(size(medium) position(7)) ndl("No victimized communities")  fcolor(Greys)
	graph export "$output_dir\map financed communities 2.jpg", replace

	restore

** Maps at province level - Selected sample
	preserve
	*drop id
	destring ubigeo_dpto, gen(id_dpto)
	gen sample_rd = 0
	replace sample_rd = 1 if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"
	collapse (firstnm) id_dpto (max) rd_1=sample_rd (count) N=index_victim (sum) sample_rd treat_13 treat_17 (mean) index_victim (p50) p50_index_victim=index_victim, by(dpto prov)
	merge 1:1 prov using "$input_dir\data_prov.dta", keepusing(id)
	replace N = 0 if _merge==2
	*replace sample_rd = 0 if _merge==2
	*replace sample_rd = . if sample_rd==0
	*replace rd_1 = 0 if _merge==2
	replace rd_1 = . if _merge==2
	replace treat_13 = 0 if _merge==2
	replace treat_17 = 0 if _merge==2
	replace index_victim = 0 if _merge==2
	replace p50_index_victim = 0 if _merge==2
	drop _merge
	replace index_victim = round( index_victim , 0.001)
	replace p50_index_victim = round( p50_index_victim , 0.001)

	spmap sample_rd using "$input_dir\coor_prov.dta", id(id) clmethod(c) clb(1 25 50 100 150)		///
	title("Communities in RD sample" " ") note("Source: CMAN") ///
	legend(size(small) position(7)) ndl("No victimized communities") ndo(gs10) fcolor(gs15 gs10 gs6 gs4) moc(gs10) ///
	polygon(data("$input_dir\coor_dpto.dta") ocolor(black)) oc(gs10) mfc(gs10)
	graph export "$output_dir\map financed communities 3.jpg", replace
	restore

	** Maps at district level - Selected sample
	preserve
	drop id
	destring ubigeo_dpto, gen(id_dpto)
	gen sample_rd = 0
	replace sample_rd = 1 if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO"
	
	collapse (firstnm) id_dpto ///
	(max) rd_1=sample_rd ///
	(count) N=index_victim ///
	(sum) sample_rd treat_13 treat_17 ///
	(mean) index_victim (p50) p50_index_victim=index_victim, ///
		by(dpto prov dist)
	
	merge 1:1 dpto prov dist using "$input_dir\data_dist.dta", ///
		keepusing(id_dist)
	
	replace N = 0 if _merge==2
	*replace sample_rd = 0 if _merge==2
	*replace sample_rd = . if sample_rd==0
	*replace rd_1 = 0 if _merge==2
	replace rd_1 = . if _merge==2
	replace treat_13 = 0 if _merge==2
	replace treat_17 = 0 if _merge==2
	replace index_victim = 0 if _merge==2
	replace p50_index_victim = 0 if _merge==2
	drop _merge
	replace index_victim = round( index_victim , 0.001)
	replace p50_index_victim = round( p50_index_victim , 0.001)

	keep if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | dpto=="AYACUCHO" | dpto=="CUSCO" | dpto=="JUNIN"
	spmap sample_rd using "$input_dir\coor_dist.dta", ///
		id(id_dist) ///
		clmethod(c) ///
		clb(0 .9 10 20 50) ///
		title("Communities in RD sample" " ", span) ///
		note("Peru, 2017" "Source: CMAN") ///
		legend(size(small) position(8) ring(0)) ///
		ndl("No victimized communities") ///
		ndo(gs10) ///
		fcolor(gs15 gs10 gs6 gs4) moc(gs10) ///
		polygon(data("$input_dir\coor_dpto_sample2.dta") ocolor(black) osize(medthick)) ///
		oc(gs10) ///
		mfc(gs10)
	graph export "$output_dir\Descriptive\1 Victimization index\2 graphs\map_rdsample_dist.png", ///
		replace

	restore

*-----------------------------------*
*		III. Summary Statistics		*
*-----------------------------------*

global main_stat treat_13 treat_17
global covs_stat altitude_msnm log_distancia_capital log_pob_ccpp_2007 			///
		poverty2007_caracthh poverty2007_servpub poverty2007_demogra poverty2007
global main_outcome log_pob_ccpp_2017 prop_edad_20_25 prop_edad_25_30 prop_educ_inicial ///
		prop_educ_primaria
global index_q1 A B C D
global index_q2 B C D E
global quint_1 A B C D E
global cells_q D E F G H
global cells_dif I J K L

putexcel set "$output_dir\Descriptive\2 Summary Statistics\sum_stats_sample2.xlsx", sheet("Sum Stats") modify

local count_row = 9
foreach var of global main_outcome {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
	sum `var' if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel C`count_row1' = (`mean')
	sleep 1500
	putexcel C`count_row2' = ("(`sd')")

foreach quint of global quint_1{
	local l: word `count_col' of $cells_q	
	sum `var' if Nivel=="`quint'" & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION")
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel `l'`count_row1' = (`mean')
	sleep 1500
	putexcel `l'`count_row2' = ("(`sd')")
	local count_col = `count_col' + 1
	sleep 1500
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 21
foreach var of global main_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
	sum `var' if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel C`count_row1' = (`mean')
	sleep 1500
	putexcel C`count_row2' = ("(`sd')")

foreach quint of global quint_1{
	local l: word `count_col' of $cells_q	
	sum `var' if Nivel=="`quint'" & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION")
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel `l'`count_row1' = (`mean')
	sleep 1500
	putexcel `l'`count_row2' = ("(`sd')")
	local count_col = `count_col' + 1
	sleep 1500
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 26
foreach var of global covs_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
	sum `var' if dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel C`count_row1' = (`mean')
	sleep 1500
	putexcel C`count_row2' = ("(`sd')")

foreach quint of global quint_1{
	local l: word `count_col' of $cells_q	
	sum `var' if Nivel=="`quint'" & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION")
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel `l'`count_row1' = (`mean')
	sleep 1500
	putexcel `l'`count_row2' = ("(`sd')")
	local count_col = `count_col' + 1
	sleep 1500
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 9
foreach var of global main_outcome {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
local count_dif = 1

foreach quint of global index_q1{
	local l: word `count_col' of $cells_dif
	local a: word `count_dif' of $index_q1
	local b: word `count_dif' of $index_q2	
	ttest `var' if (Nivel=="`a'" | Nivel=="`b'") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"), by(Nivel)
	local dif_1 	= r(mu_1) - r(mu_2)
	local dif = string(`dif_1', "%9.3f")
	local se_1 	= r(se)
	local se = string(`se_1', "%9.3f")
	local pv = r(p)
		if `pv'>0.10 				putexcel `l'`count_row1' = ("`dif'") `l'`count_row2'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`count_row1' = ("`dif'*") `l'`count_row2'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`count_row1' = ("`dif'**") `l'`count_row2'=("(`se')") 
		if `pv'<0.01				putexcel `l'`count_row1' = ("`dif'***") `l'`count_row2'=("(`se')")
	sleep 1500
local count_col = `count_col' + 1	
local count_dif = `count_dif' + 1
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 21
foreach var of global main_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
local count_dif = 1

foreach quint of global index_q1{
	local l: word `count_col' of $cells_dif
	local a: word `count_dif' of $index_q1
	local b: word `count_dif' of $index_q2	
	ttest `var' if (Nivel=="`a'" | Nivel=="`b'") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"), by(Nivel)
	local dif_1 	= r(mu_1) - r(mu_2)
	local dif = string(`dif_1', "%9.3f")
	local se_1 	= r(se)
	local se = string(`se_1', "%9.3f")
	local pv = r(p)
		if `pv'>0.10 				putexcel `l'`count_row1' = ("`dif'") `l'`count_row2'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`count_row1' = ("`dif'*") `l'`count_row2'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`count_row1' = ("`dif'**") `l'`count_row2'=("(`se')") 
		if `pv'<0.01				putexcel `l'`count_row1' = ("`dif'***") `l'`count_row2'=("(`se')")
	sleep 1500
local count_col = `count_col' + 1	
local count_dif = `count_dif' + 1
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 26
foreach var of global covs_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
local count_dif = 1

foreach quint of global index_q1{
	local l: word `count_col' of $cells_dif
	local a: word `count_dif' of $index_q1
	local b: word `count_dif' of $index_q2	
	ttest `var' if (Nivel=="`a'" | Nivel=="`b'") & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="HUANCAYO" | prov=="LA CONVENCION"), by(Nivel)
	local dif_1 	= r(mu_1) - r(mu_2)
	local dif = string(`dif_1', "%9.3f")
	local se_1 	= r(se)
	local se = string(`se_1', "%9.3f")
	local pv = r(p)
		if `pv'>0.10 				putexcel `l'`count_row1' = ("`dif'") `l'`count_row2'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`count_row1' = ("`dif'*") `l'`count_row2'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`count_row1' = ("`dif'**") `l'`count_row2'=("(`se')") 
		if `pv'<0.01				putexcel `l'`count_row1' = ("`dif'***") `l'`count_row2'=("(`se')")
	sleep 1500
local count_col = `count_col' + 1	
local count_dif = `count_dif' + 1
}
local count_row = `count_row' + 2
sleep 1500
}

putexcel C5=("Victimization Index Quintile")
sleep 1500
putexcel C6=("All")
sleep 1500
putexcel D6=("A")
sleep 1500
putexcel E6=("B")
sleep 1500
putexcel F6=("C")
sleep 1500
putexcel G6=("D")
sleep 1500
putexcel H6=("E")
sleep 1500
putexcel I6=("A-B")
sleep 1500
putexcel J6=("B-C")
sleep 1500
putexcel K6=("C-D")
sleep 1500
putexcel L6=("D-E")
sleep 1500


** Full sample
putexcel set "$output_dir\Descriptive\2 Summary Statistics\sum_stats_fullsample.xlsx", sheet("Sum Stats") modify

local count_row = 9
foreach var of global main_outcome {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
	sum `var'
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel C`count_row1' = (`mean')
	sleep 1500
	putexcel C`count_row2' = ("(`sd')")

foreach quint of global quint_1{
	local l: word `count_col' of $cells_q	
	sum `var' if Nivel=="`quint'"
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel `l'`count_row1' = (`mean')
	sleep 1500
	putexcel `l'`count_row2' = ("(`sd')")
	local count_col = `count_col' + 1
	sleep 1500
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 21
foreach var of global main_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
	sum `var'
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel C`count_row1' = (`mean')
	sleep 1500
	putexcel C`count_row2' = ("(`sd')")

foreach quint of global quint_1{
	local l: word `count_col' of $cells_q	
	sum `var' if Nivel=="`quint'"
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel `l'`count_row1' = (`mean')
	sleep 1500
	putexcel `l'`count_row2' = ("(`sd')")
	local count_col = `count_col' + 1
	sleep 1500
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 26
foreach var of global covs_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
	sum `var'
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel C`count_row1' = (`mean')
	sleep 1500
	putexcel C`count_row2' = ("(`sd')")

foreach quint of global quint_1{
	local l: word `count_col' of $cells_q	
	sum `var' if Nivel=="`quint'"
	local mean_1 	= r(mean)
	local mean = string(`mean_1', "%9.3f")
	local sd_1 	= r(sd)
	local sd = string(`sd_1', "%9.3f")	
	putexcel `l'`count_row1' = (`mean')
	sleep 1500
	putexcel `l'`count_row2' = ("(`sd')")
	local count_col = `count_col' + 1
	sleep 1500
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 9
foreach var of global main_outcome {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
local count_dif = 1

foreach quint of global index_q1{
	local l: word `count_col' of $cells_dif
	local a: word `count_dif' of $index_q1
	local b: word `count_dif' of $index_q2	
	ttest `var' if (Nivel=="`a'" | Nivel=="`b'"), by(Nivel)
	local dif_1 	= r(mu_1) - r(mu_2)
	local dif = string(`dif_1', "%9.3f")
	local se_1 	= r(se)
	local se = string(`se_1', "%9.3f")
	local pv = r(p)
		if `pv'>0.10 				putexcel `l'`count_row1' = ("`dif'") `l'`count_row2'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`count_row1' = ("`dif'*") `l'`count_row2'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`count_row1' = ("`dif'**") `l'`count_row2'=("(`se')") 
		if `pv'<0.01				putexcel `l'`count_row1' = ("`dif'***") `l'`count_row2'=("(`se')")
	sleep 1500
local count_col = `count_col' + 1	
local count_dif = `count_dif' + 1
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 21
foreach var of global main_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
local count_dif = 1

foreach quint of global index_q1{
	local l: word `count_col' of $cells_dif
	local a: word `count_dif' of $index_q1
	local b: word `count_dif' of $index_q2	
	ttest `var' if (Nivel=="`a'" | Nivel=="`b'"), by(Nivel)
	local dif_1 	= r(mu_1) - r(mu_2)
	local dif = string(`dif_1', "%9.3f")
	local se_1 	= r(se)
	local se = string(`se_1', "%9.3f")
	local pv = r(p)
		if `pv'>0.10 				putexcel `l'`count_row1' = ("`dif'") `l'`count_row2'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`count_row1' = ("`dif'*") `l'`count_row2'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`count_row1' = ("`dif'**") `l'`count_row2'=("(`se')") 
		if `pv'<0.01				putexcel `l'`count_row1' = ("`dif'***") `l'`count_row2'=("(`se')")
	sleep 1500
local count_col = `count_col' + 1	
local count_dif = `count_dif' + 1
}
local count_row = `count_row' + 2
sleep 1500
}

local count_row = 26
foreach var of global covs_stat {
local count_col = 1
local count_row1= `count_row'
local count_row2= `count_row1' + 1
local count_dif = 1

foreach quint of global index_q1{
	local l: word `count_col' of $cells_dif
	local a: word `count_dif' of $index_q1
	local b: word `count_dif' of $index_q2	
	ttest `var' if (Nivel=="`a'" | Nivel=="`b'"), by(Nivel)
	local dif_1 	= r(mu_1) - r(mu_2)
	local dif = string(`dif_1', "%9.3f")
	local se_1 	= r(se)
	local se = string(`se_1', "%9.3f")
	local pv = r(p)
		if `pv'>0.10 				putexcel `l'`count_row1' = ("`dif'") `l'`count_row2'=("(`se')") 
		if `pv'<=0.10&`pv'>0.05 	putexcel `l'`count_row1' = ("`dif'*") `l'`count_row2'=("(`se')") 
		if `pv'<=0.05&`pv'>0.01 	putexcel `l'`count_row1' = ("`dif'**") `l'`count_row2'=("(`se')") 
		if `pv'<0.01				putexcel `l'`count_row1' = ("`dif'***") `l'`count_row2'=("(`se')")
	sleep 1500
local count_col = `count_col' + 1	
local count_dif = `count_dif' + 1
}
local count_row = `count_row' + 2
sleep 1500
}

putexcel C5=("Victimization Index Quintile")
sleep 1500
putexcel C6=("All")
sleep 1500
putexcel D6=("A")
sleep 1500
putexcel E6=("B")
sleep 1500
putexcel F6=("C")
sleep 1500
putexcel G6=("D")
sleep 1500
putexcel H6=("E")
sleep 1500
putexcel I6=("A-B")
sleep 1500
putexcel J6=("B-C")
sleep 1500
putexcel K6=("C-D")
sleep 1500
putexcel L6=("D-E")
sleep 1500




********************************
* EXTRA
*********************************

		rdrobust nivel_educ_inicial_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(educ_ctr13_inicial $controls) p(2)

		rdrobust nivel_educ_ninguno_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(educ_ctr13_ninguno $controls) p(2)	
	
		rdrobust nivel_educ_primaria_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(educ_ctr13_primaria $controls) p(2)	
		
		rdrobust nivel_educ_secundaria_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(educ_ctr13_secundaria $controls) p(2)	
		
		rdrobust nivel_educ_tecnica_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(educ_ctr13_tecnico $controls) p(2)	
			
		rdrobust nivel_educ_universitaria_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs(educ_ctr13_universitaria $controls) p(2)	
			
			
			
	
		gen educ_ctr13_inicial = .
		replace educ_ctr13_inicial = 1 if niv01==2
		replace educ_ctr13_inicial = 0 if niv01!=2 & niv01!=.
	
		gen educ_ctr13_ninguno = .
		replace educ_ctr13_ninguno = 1 if niv01==1
		replace educ_ctr13_ninguno = 0 if niv01!=1 & niv01!=.
		
		gen educ_ctr13_primaria = .
		replace educ_ctr13_primaria = 1 if niv01==3
		replace educ_ctr13_primaria = 0 if niv01!=3 & niv01!=.	
		
		
		gen educ_ctr13_secundaria = .
		replace educ_ctr13_secundaria = 1 if niv01==4
		replace educ_ctr13_secundaria = 0 if niv01!=4 & niv01!=.	
		
		
		gen educ_ctr13_tecnico = .
		replace educ_ctr13_tecnico = 1 if niv01==5
		replace educ_ctr13_tecnico = 0 if niv01!=5 & niv01!=.
		
		
		gen educ_ctr13_universitaria = .
		replace educ_ctr13_universitaria = 1 if niv01==6
		replace educ_ctr13_universitaria = 0 if niv01!=6 & niv01!=.	
		
		
		gen edad12_2 = edad_2017*edad_2017
		
		
		
probit migracion sex_2017 edad_2017 i.treat_17##i.niv01 $controls if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist)
	margins, over(niv01 treat_17)
	marginsplot, ciopts(msize(large) lstyle(p1mark) lwidth(medthick) 			///
	lcolor(maroon)) graphregion(color(white)) 	///
	xlabel(, alt labsize(small)) legend(region(style(none)) order(3 "Comunidades financiadas" 4 "Comunidades no financiadas"))	///
	title("") ytit(" Probabilidad estimada de migración") xtit("") xsize(6)
	graph export "$output_dir\Descriptive\migracion_educ.png", replace		
		
use "$input_dir/3 Coded/community_index_treated_cpv2017ind.dta", clear

label def sex_lb 1 "Mujer" 0 "Hombre"
label val sex_2017 sex_lb

probit migracion edad_2017 i.treat_17##i.sex_2017 i.niv01 $controls if (index_cutBC>-0.015 & index_cutBC<0.015) & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO") & cap_dist==0, cluster(cluster_dist)
	margins, over(sex_2017 treat_17)
	marginsplot, ciopts(msize(large) lstyle(p1mark) lwidth(medthick) 			///
	lcolor(maroon)) graphregion(color(white)) 	///
	xlabel(, alt labsize(small)) legend(region(style(none)) order(3 "Comunidades financiadas" 4 "Comunidades no financiadas"))	///
	title("") ytit(" Probabilidad estimada de migración") xtit("") xsize(6)
	graph export "$output_dir\Descriptive\migracion_sex.png", replace		
		
use "$input_dir/3 Coded/community_index_treated_cpv2017ind.dta", clear

		
	keep if abs(index_cutBC)<=0.015	& (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO")
	collapse (mean) migracion, by(edad_2017 treat_17)
	
graph twoway (scatter migracion edad_2017 if treat_17==0 & edad_2017<=90, 		///
		msize(small) legend(region(style(none)) order(1 "Comunidades financiadas"))) (lpoly migracion edad_2017 if treat_17==0 & edad_2017<=90) ///
		(scatter migracion edad_2017 if treat_17==1 & edad_2017<=90, msize(small) legend(region(style(none)) order(1 "Comunidades financiadas" 3 "Comunidades no financiadas"))) ///
		(lpoly migracion edad_2017 if treat_17==1 & edad_2017<=90),	graphregion(color(white)) ytit("Proporción de migrantes" " ") xtit(" " "Edad")		
	graph export "$output_dir\Descriptive\migracion_age.png", replace		
	
		