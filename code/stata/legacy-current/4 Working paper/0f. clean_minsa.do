/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from MINSA		|
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 17/1/2019				 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/


import delimited "$input_dir\1 Raw\5 Minsa\RENIPRESS_2019_v1.csv", clear	
	

	rename departamento		dpto
	rename provincia		prov
	rename distrito 		dist
	
	gen a=0
	egen ubigeo2=concat(a ubigeo) if ubigeo<100000
	tostring ubigeo, replace
	replace ubigeo2=ubigeo if ubigeo2==""
	replace ubigeo=ubigeo2
	drop ubigeo2 a
	rename ubigeo ubigeo_dist
	
	gen		categ_0 = 0
	replace categ_0 = 1 if categoria=="0"
	gen		categ_i1 = 0
	replace categ_i1 = 1 if categoria=="I-1"
	gen		categ_i2 = 0
	replace categ_i2 = 1 if categoria=="I-2"
	gen		categ_i3 = 0
	replace categ_i3 = 1 if categoria=="I-3"
	gen		categ_i4 = 0
	replace categ_i4 = 1 if categoria=="I-4"
	gen		categ_ii1 = 0
	replace categ_ii1 = 1 if categoria=="II-1"
	gen		categ_ii2 = 0
	replace categ_ii2 = 1 if categoria=="II-2"
	gen		categ_iie = 0
	replace categ_iie = 1 if categoria=="II-E"
	gen		categ_iii1 = 0
	replace categ_iii1 = 1 if categoria=="III-1"
	gen		categ_iii2 = 0
	replace categ_iii2 = 1 if categoria=="III-2"
	gen		categ_iiie = 0
	replace categ_iiie = 1 if categoria=="III-E"	
	
	
	gen year = substr(inicio_actividad,-4,4)
	destring year, replace
	
	gen		tipo_institucion = 0
	replace tipo_institucion = 1 if institucion=="PRIVADO"
	label def tipo_inst_lb 0 Publico 1 Privado, replace
	label val tipo_institucion tipo_inst_lb
	
	rename este longitude
	rename norte latitude
	
	keep ubigeo_dist dpto prov dist nombre categ_* tipo_institucion year direccion longitude latitude
	
	bys dpto prov dist nombre direccion: gen rep=_n
	drop if rep>1
	drop rep
	
	merge 1:1 dpto prov dist nombre direccion using "$input_dir\1 Raw\5 Minsa\minsa_aux.dta", keepusing(lat2 long2)
	drop if _merge==2
	drop _merge
	
	replace longitude = long2 if longitude==.
	replace latitude = lat2 if latitude==.
	
	drop lat2 long2
	
save "$input_dir\1 Raw\5 Minsa\minsa_working.dta",  replace	
	
*-------------------------------------------------------*
*		Recover ubigeo_ccpp from georeferenced data		*
*-------------------------------------------------------*
	
	gen id=_n
	geonear id latitude longitude using "$input_dir\1 Raw\ccpp_georef_dist.dta", n(id latitude longitude) 
	drop id
	rename nid id
	merge m:1 id using "$input_dir\1 Raw\ccpp_georef_dist.dta" , keepusing(ubigeo_ccpp)
	drop if _merge==2
	drop _merge
	drop if ubigeo_ccpp==""
	
	gen		year_until = ""
	replace year_until = "_2007" if year<=2007 & year_until==""
	replace year_until = "_2008" if year<=2008 & year_until==""
	replace year_until = "_2009" if year<=2009 & year_until==""
	replace year_until = "_2010" if year<=2010 & year_until==""
	replace year_until = "_2011" if year<=2011 & year_until==""
	replace year_until = "_2012" if year<=2012 & year_until==""
	replace year_until = "_2013" if year<=2013 & year_until==""
	replace year_until = "_2014" if year<=2014 & year_until==""
	replace year_until = "_2015" if year<=2015 & year_until==""
	replace year_until = "_2016" if year<=2016 & year_until==""
	replace year_until = "_2017" if year<=2017 & year_until==""
	replace year_until = "_2018" if year<=2018 & year_until==""
	
	gen num_cs=1
	collapse (sum) num_cs categ* tipo_institucion, by(ubigeo_ccpp year_until)

	reshape wide num_cs tipo_institucion categ*, i(ubigeo_ccpp) j(year_until) string
	
	local vars num_cs categ_0 categ_i1 categ_i2 categ_i3 categ_i4 categ_ii1 categ_ii2 categ_iie categ_iii1 categ_iii2 categ_iiie tipo_institucion
	
	foreach x of local vars {
	replace `x'_2007 = 0 if `x'_2007==.	
	replace `x'_2008 = 0 if `x'_2008==.
	replace `x'_2008 = `x'_2008 + `x'_2007
	replace `x'_2009 = 0 if `x'_2009==.
	replace `x'_2009 = `x'_2009 + `x'_2008
	replace `x'_2010 = 0 if `x'_2010==.
	replace `x'_2010 = `x'_2010 + `x'_2009
	replace `x'_2011 = 0 if `x'_2011==.
	replace `x'_2011 = `x'_2011 + `x'_2010
	replace `x'_2012 = 0 if `x'_2012==.
	replace `x'_2012 = `x'_2012 + `x'_2011
	replace `x'_2013 = 0 if `x'_2013==.
	replace `x'_2013 = `x'_2013 + `x'_2012
	replace `x'_2014 = 0 if `x'_2014==.
	replace `x'_2014 = `x'_2014 + `x'_2013	
	replace `x'_2015 = 0 if `x'_2015==.
	replace `x'_2015 = `x'_2015 + `x'_2014	
	replace `x'_2016 = 0 if `x'_2016==.
	replace `x'_2016 = `x'_2016 + `x'_2015	
	replace `x'_2017 = 0 if `x'_2017==.
	replace `x'_2017 = `x'_2017 + `x'_2016	
	replace `x'_2018 = 0 if `x'_2018==.
	replace `x'_2018 = `x'_2018 + `x'_2017		
	}

	foreach y = 2007/2018{
	egen num_categ_i_`y' = rowtotal(categ_0_`y' categ_i1_`y' categ_i2_`y' categ_i3_`y' categ_i4_`y')
	egen num_categ_ii_`y' = rowtotal(categ_ii1_`y' categ_ii2_`y' categ_iie_`y')
	egen num_categ_iii_`y' = rowtotal(categ_iii1_`y' categ_iii2_`y' categ_iiie_`y')
	
	gen		categ_i_1_`y' = 0
	replace categ_i_1_`y' = 1 if num_categ_i_`y'>0
	gen		categ_ii_1_`y' = 0
	replace categ_ii_1_`y' = 1 if num_categ_ii_`y'>0
	gen		categ_iii_1_`y' = 0
	replace categ_iii_1_`y' = 1 if num_categ_iii_`y'>0		
	}
	
save "$input_dir\2 Working\minsa_ccpp.dta",  replace	
	
*-----------------------------------------------*
*		Collapse Minsa to district level		*
*-----------------------------------------------*
use "$input_dir\1 Raw\5 Minsa\minsa_working.dta", clear

	gen		year_until = ""
	replace year_until = "_2007" if year<=2007 & year_until==""
	replace year_until = "_2008" if year<=2008 & year_until==""
	replace year_until = "_2009" if year<=2009 & year_until==""
	replace year_until = "_2010" if year<=2010 & year_until==""
	replace year_until = "_2011" if year<=2011 & year_until==""
	replace year_until = "_2012" if year<=2012 & year_until==""
	replace year_until = "_2013" if year<=2013 & year_until==""
	replace year_until = "_2014" if year<=2014 & year_until==""
	replace year_until = "_2015" if year<=2015 & year_until==""
	replace year_until = "_2016" if year<=2016 & year_until==""
	replace year_until = "_2017" if year<=2017 & year_until==""
	replace year_until = "_2018" if year<=2018 & year_until==""
	
	gen num_cs=1

	collapse (sum) num_cs categ* tipo_institucion, by(ubigeo_dist year_until)

	reshape wide num_cs tipo_institucion categ*, i(ubigeo_dist) j(year_until) string
	
	local vars num_cs categ_0 categ_i1 categ_i2 categ_i3 categ_i4 categ_ii1 categ_ii2 categ_iie categ_iii1 categ_iii2 categ_iiie tipo_institucion
	
	foreach x of local vars {
	replace `x'_2007 = 0 if `x'_2007==.	
	replace `x'_2008 = 0 if `x'_2008==.
	replace `x'_2008 = `x'_2008 + `x'_2007
	replace `x'_2009 = 0 if `x'_2009==.
	replace `x'_2009 = `x'_2009 + `x'_2008
	replace `x'_2010 = 0 if `x'_2010==.
	replace `x'_2010 = `x'_2010 + `x'_2009
	replace `x'_2011 = 0 if `x'_2011==.
	replace `x'_2011 = `x'_2011 + `x'_2010
	replace `x'_2012 = 0 if `x'_2012==.
	replace `x'_2012 = `x'_2012 + `x'_2011
	replace `x'_2013 = 0 if `x'_2013==.
	replace `x'_2013 = `x'_2013 + `x'_2012
	replace `x'_2014 = 0 if `x'_2014==.
	replace `x'_2014 = `x'_2014 + `x'_2013	
	replace `x'_2015 = 0 if `x'_2015==.
	replace `x'_2015 = `x'_2015 + `x'_2014	
	replace `x'_2016 = 0 if `x'_2016==.
	replace `x'_2016 = `x'_2016 + `x'_2015	
	replace `x'_2017 = 0 if `x'_2017==.
	replace `x'_2017 = `x'_2017 + `x'_2016	
	replace `x'_2018 = 0 if `x'_2018==.
	replace `x'_2018 = `x'_2018 + `x'_2017		
	}

	foreach y = 2007/2018{
	egen num_categ_i_`y' = rowtotal(categ_0_`y' categ_i1_`y' categ_i2_`y' categ_i3_`y' categ_i4_`y')
	egen num_categ_ii_`y' = rowtotal(categ_ii1_`y' categ_ii2_`y' categ_iie_`y')
	egen num_categ_iii_`y' = rowtotal(categ_iii1_`y' categ_iii2_`y' categ_iiie_`y')
	
	gen		categ_i_1_`y' = 0
	replace categ_i_1_`y' = 1 if num_categ_i_`y'>0
	gen		categ_ii_1_`y' = 0
	replace categ_ii_1_`y' = 1 if num_categ_ii_`y'>0
	gen		categ_iii_1_`y' = 0
	replace categ_iii_1_`y' = 1 if num_categ_iii_`y'>0	
	}
	
save "$input_dir\2 Working\minsa_district.dta",  replace	



	
	
