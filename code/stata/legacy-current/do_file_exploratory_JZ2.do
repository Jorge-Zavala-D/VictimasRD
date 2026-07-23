

	
*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD"

*-----------------------------------*
*		Outcomes at CCPP Level		*
*-----------------------------------*

use "$a\2 data\3 Coded\community_index_treated_sisfohccpp.dta", clear

global	controls altitude_msnm log_distancia_capital prop_a13 ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub poverty2007_demogra ie_estatal_1_2010


***********************************		
gen index_cutBC_l = index_cutBC
replace index_cutBC_l = 0 if index_cutBC>=0
gen index_cutBC_r = index_cutBC
replace index_cutBC_r = 0 if index_cutBC<0

gen index_cutBC2 = index_cutBC*index_cutBC
gen index_cutBC3 = index_cutBC*index_cutBC*index_cutBC

gen	treat_13Xindex_cutBC = treat_13*index_cutBC
gen	treat_13Xindex_cutBC2 = treat_13*index_cutBC2
gen	treat_13Xindex_cutBC3 = treat_13*index_cutBC3

gen	treat_17Xindex_cutBC = treat_17*index_cutBC
gen	treat_17Xindex_cutBC2 = treat_17*index_cutBC2
gen	treat_17Xindex_cutBC3 = treat_17*index_cutBC3

gen t = 0
replace t = 1 if index_cutBC>0
gen	tXindex_victim = t*index_victim
gen tXindex_cutBC = t*index_cutBC
gen tXindex_cutBC2 = t*index_cutBC2

gen 	w_tri = .
replace w_tri = (1-abs(index_cutBC / 0.03)) if index_cutBC< 0 & index_cutBC>=-0.03
replace w_tri = (1-abs(index_cutBC / 0.03)) if index_cutBC>=0 & index_cutBC<=0.03
*************************************




		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) p(1) covs($controls)
		

		rdrobust log_pob_ccpp_2017 index_cutBC if (Nivel=="B" | Nivel=="C")  ///
		, fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)

		preserve
		keep if	(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO") & (Nivel=="B" | Nivel=="C")
		rdob ie_1_2013 index_cutBC, c(0)
		rdob ie_estatal_1_2013 index_cutBC, c(0)
		rdob num_ie_estatal_2013 index_cutBC, c(0)	
		rdob log_pob_ccpp_2017 index_cutBC, c(0)			
		restore
	
		
		reg serv_ie_1_2013 treat_13 index_cutBC index_cutBC2 treat_13Xindex_cutBC treat_13Xindex_cutBC2 $controls ///
		if abs(index_cutBC)<=0.010 & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), cl(cluster_dist)
		predict pob_pred

		reg log_pob_ccpp_2017 t index_cutBC_l index_cutBC_r $controls ///
		if abs(index_cutBC)<=0.015 & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), cl(cluster_dist)
				
		
		ivreg2 log_pob_ccpp_2017 (treat_17 = t   		///
		tXindex_cutBC  $controls) ///
		index_cutBC  $controls  if abs(index_cutBC)<=0.01 & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), cl(cluster_dist)
		predict pob_pred_iv
		
		
		graph twoway scatter pob_pred index_cutBC if index_cutBC<=0.015 & 		///
		index_cutBC>0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | 				///
		prov=="LA CONVENCION" | prov=="HUANCAYO") || scatter pob_pred 			///
		index_cutBC if index_cutBC>-0.015 & index_cutBC<=0 & 					///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO") || qfit pob_pred index_cutBC if index_cutBC<=0.015 & 	///
		index_cutBC>0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | 				///
		prov=="LA CONVENCION" | prov=="HUANCAYO") || qfit pob_pred index_cutBC 	///
		if index_cutBC>-0.015 & index_cutBC<=0 & (dpto=="HUANCAVELICA" | 		///
		dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO")		
		
		graph twoway scatter pob_pred_iv index_cutBC if index_cutBC<=0.015 & 		///
		index_cutBC>0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | 				///
		prov=="LA CONVENCION" | prov=="HUANCAYO") || scatter pob_pred_iv 			///
		index_cutBC if index_cutBC>-0.015 & index_cutBC<=0 & 					///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO") || qfit pob_pred_iv index_cutBC if index_cutBC<=0.015 & 	///
		index_cutBC>0 & (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | 				///
		prov=="LA CONVENCION" | prov=="HUANCAYO") || qfit pob_pred_iv index_cutBC 	///
		if index_cutBC>-0.015 & index_cutBC<=0 & (dpto=="HUANCAVELICA" | 		///
		dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO")		
	
		
		
		
		
		
		
		
		
use "$input_dir/3 Coded/community_index_treated_sisfohccpp.dta", ///
	clear	
	
* MISMA RESTRICCIÓN DE MUESTRA QUE EN EL MODELO
global sample (dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | prov=="HUANCAYO")

		keep if $sample
	
global	controls altitude_msnm log_pob_ccpp_2007 poverty2007_demogra		

		rdrobust log_pob_ccpp_2013 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" ///
		| prov=="HUANCAYO"), fuzzy(treat_13) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls log_pob_ccpp_2007) p(1)	
	
		rdrobust log_pob_ccpp_2017 index_cutBC if ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_16) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs( $controls  log_pob_ccpp_2007 cluster_prov_2 cluster_prov_3 cluster_prov_4 cluster_prov_5 cluster_prov_6 cluster_prov_7 cluster_prov_8 cluster_prov_9 cluster_prov_10 cluster_prov_11 cluster_prov_12 cluster_prov_13 cluster_prov_14 cluster_prov_15 cluster_prov_16) p(1) masspoints(off)
	
		rdrobust log_pob_ccpp_2017 index_cutBC if ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_16) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs( $controls  log_pob_ccpp_2007) p(1) masspoints(off)	
	
	

* 1) PRIMER ESTADIO: PROBABILIDAD DE TRATAMIENTO vs RUNNING VARIABLE
rdplot treat_13 index_cutBC if $sample, ///
    c(0) p(1) kernel(triangular) ///
    binselect(qsmvpr) ///
    ytitle("Probabilidad de tratamiento") ///
    xtitle("Índice de elegibilidad (index_cutBC)") ///
    xline(0, lpattern(dash)) ///
    graph_options( ///
        title("Primer estadio: salto en treat_13") ///
        legend(off) scheme(plotplain)) 

graph export "primer_estadio_treat13.pdf", replace


* 2) FORMA REDUCIDA: OUTCOME vs RUNNING VARIABLE
rdplot log_pob_ccpp_2017 index_cutBC if $sample, ///
    c(0) p(1) kernel(triangular) ///
    binselect(qsmvpr) ci(95) ///
    ytitle("log Población CCPP 2017") ///
    xtitle("Índice de elegibilidad (index_cutBC)") ///
    xline(0, lpattern(dash)) ///
    graph_options( ///
        title("Forma reducida: salto en log población 2017") ///
        legend(off) scheme(plotplain)) covs($controls log_pob_ccpp_2007) masspoints(off)

graph export "reduced_form_logpob2017.pdf", replace
	
	
	
	
			
		
		
		
