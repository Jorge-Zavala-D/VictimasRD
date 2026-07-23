/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from 2017 ENDES	|
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 26/11/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/

*-------------------------------------------------------*
*		I.	2017 ENDES HH characteristics Module		*
*-------------------------------------------------------*

use "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\RECH0.dta",clear
drop HV000 HV020 HV017 HV018 HV019 HV028 HV030 HV031 HV032 HV033
save "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64_rech0.dta", replace 

use "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\RECH1.dta",clear
drop HV118 HV130 HV131 HV132 HV133 HV134-HV140
save "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64_rech1.dta", replace 

use "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\RECH4.dta",clear
rename IDXH4 HVIDX
save "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64_rech4.dta", replace 

use "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64_rech0.dta", clear
merge 1:m HHID using "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64_rech1.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         2,496
        from master                     2,496  (_merge==1)
        from using                          0  (_merge==2)

    matched                           140,598  (_merge==3)
    -----------------------------------------
	
	Note: unmatched households were not surveyed
*/
keep if _merge==3
drop _merge

merge 1:1 HHID HVIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64_rech4.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           140,598  (_merge==3)
    -----------------------------------------
*/
drop _merge
order HVIDX HV101, after(HHID)

sort HHID HV120 HV105
bys HHID HV120: gen HWIDX=_n
order HWIDX, after(HVIDX)
replace HWIDX=. if HV120==0

rename LAT_CCPP lat_ccpp
*	Dataset at individual level (all household members)
save "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64.dta", replace 

*---------------------------------------------------*
*		II.	2017 ENDES MEF information Module		*
*---------------------------------------------------*

use "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\REC91.dta",clear
drop SVER S229A S229B S229C S229D S229E S229F S229G S229H S229I S229J S229K S229L S229X S229Y S229A1 S229B1 S229CDAY S229CM S229CY S229DA S229DB S229DC S229DD S229DE S229DF S229DX
drop S1028A S1028B S1028X S1028Y

gen HHID=substr(CASEID,1,9)
gen HVIDX=substr(CASEID,11,2)
replace HVIDX=subinstr(HVIDX," ","",.)
destring HVIDX, replace
order HHID HVIDX, before(CASEID)

save "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\endes_mod66_rec91.dta", replace 

use "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\REC0111.dta",clear
drop V028 V029 V030 V031 V032 V033
gen HHID=substr(CASEID,1,9)
rename V003 HVIDX
order HHID HVIDX, before(CASEID)
save "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\endes_mod66_rec0111.dta", replace 

merge 1:1 HHID HVIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\endes_mod66_rec91.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                            34,002  (_merge==3)
    -----------------------------------------
*/
drop _merge

*	Dataset at individual level only for eligible women
save "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\endes_mod66.dta", replace 

*-------------------------------------------------------*
*		III.	2017 ENDES Family Violence Module		*
*-------------------------------------------------------*

use "$input_dir\1 Raw\2 ENDES\2017\Mod 73 - Family violence\REC84DV.dta",clear
drop MMC3 REC84_GROUP_1 REC84_GROUP_2 REC84_GROUP_3 REC84_GROUP_4 REC84_GROUP_5 REC84_GROUP_6
drop D005 D101G D101H D101I D101J D103E D103F D105K D105L D105M D105N D110F D110G D110H
drop D115XI D115XJ D115XK D117A D118XK D119XK D123 D124 D125 D126 D127 D128
gen HHID=substr(CASEID,1,9)
gen HVIDX=substr(CASEID,11,2)
replace HVIDX=subinstr(HVIDX," ","",.)
destring HVIDX, replace
order HHID HVIDX, before(CASEID)

*	Individual dataset only for eligible women surveyed
save "$input_dir\1 Raw\2 ENDES\2017\Mod 73 - Family violence\endes_mod73.dta", replace 

*---------------------------------------------------*
*		IV.	2017 ENDES Height and Weight Module		*
*---------------------------------------------------*

use "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\REC44.dta",clear
gen HHID=substr(CASEID,1,9)
gen HVIDX=substr(CASEID,11,2)
replace HVIDX=subinstr(HVIDX," ","",.)
destring HVIDX, replace
order HHID HVIDX, before(CASEID)
keep if HW55==0
*	In some cases, there are 2 women in household with eligible children to be surveyed
*	We will just keep one mother of each household and her children
bys HHID HWIDX: gen rep_hh=_n
drop if rep_hh!=1
drop rep_hh

*	Individual dataset only for eligible children younger than 5-years-old
save "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\endes_mod74_rec44.dta", replace 

use "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\RECH5.dta",clear
*	Individual dataset only for older women eligible 
rename HA0 HVIDX
save "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\endes_mod74_rech5.dta", replace 


merge 1:m HHID HVIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\endes_mod74_rec44.dta"
/*  
    Result                           # of obs.
    -----------------------------------------
    not matched                        18,334
        from master                    18,334  (_merge==1)
        from using                          0  (_merge==2)

    matched                            19,277  (_merge==3)
    -----------------------------------------
	Note: Unmatched observations form master dataset correspond to women within 
	HH with no eligible children to be surveyed
*/
drop _merge
order HWIDX, after(HVIDX)

*	Individual dataset only for women and eligible children
save "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\endes_mod74.dta", replace 

*-------------------------------*
*		V.	Merge ENDES 2017	*
*-------------------------------*

use "$input_dir\1 Raw\2 ENDES\2017\Mod 64 - HH characteristics\endes_mod64.dta", clear

merge 1:1 HHID HVIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 66 - MEF information\endes_mod66.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       106,596
        from master                   106,596  (_merge==1)
        from using                          0  (_merge==2)

    matched                            34,002  (_merge==3)
    -----------------------------------------
	Note: Unmatched individuals are ineligible women to be surveyed
*/
drop _merge

merge 1:1 HHID HVIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 73 - Family violence\endes_mod73.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       107,430
        from master                   107,430  (_merge==1)
        from using                          0  (_merge==2)

    matched                            33,168  (_merge==3)
    -----------------------------------------
	Note: unmatched observations are ineligible children & women to be surveyed
*/
drop _merge

merge m:1 HHID HWIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\endes_mod74_rec44.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       121,437
        from master                   121,379  (_merge==1)
        from using                         58  (_merge==2)

    matched                            19,219  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

merge m:1 HHID HVIDX using "$input_dir\1 Raw\2 ENDES\2017\Mod 74 - Height and Weight\endes_mod74_rech5.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       105,278
        from master                   105,278  (_merge==1)
        from using                          0  (_merge==2)

    matched                            35,320  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge


save "$input_dir\2 Working\endes_2017.dta", replace 

*-----------------------------------------------*
*		VI.	Prepare Merged ENDES dataset		*
*-----------------------------------------------*

use "$input_dir\2 Working\endes_2017.dta", clear

gen		zero=0
tostring V024, gen(V024_1)
egen 	ubigeo_dpto=concat(zero V024) if V024<=9 & V024!=.
replace ubigeo_dpto=V024_1 if V024>=10 & V024!=.
egen	ubigeo_prov=concat(zero SPROVIN) if SPROVIN<=9 & SPROVIN!=.
tostring SPROVIN, gen(SPROVIN_1)
replace ubigeo_prov=SPROVIN_1 if SPROVIN>=10 & SPROVIN!=.
replace ubigeo_prov=ubigeo_dpto+ubigeo_prov
egen	ubigeo_dist=concat(zero SDISTRI) if SDISTRI<=9 & SDISTRI!=.
tostring SDISTRI, gen(SDISTRI_1)
replace ubigeo_dist=SDISTRI_1 if SDISTRI>=10 & SDISTRI!=.
replace ubigeo_dist=ubigeo_prov+ubigeo_dist
gen		ubigeo_ccpp=ubigeo_dist+codccpp
replace ubigeo_ccpp="" if ubigeo_dist==""
drop zero V024_1 SPROVIN_1 SDISTRI_1

bys long_ccpp lat_ccpp: egen ubigeo_dpto_hh=mode(ubigeo_dpto)
bys long_ccpp lat_ccpp: egen ubigeo_prov_hh=mode(ubigeo_prov)
bys long_ccpp lat_ccpp: egen ubigeo_dist_hh=mode(ubigeo_dist)
bys long_ccpp lat_ccpp: egen ubigeo_ccpp_hh=mode(ubigeo_ccpp)

drop ubigeo_dpto ubigeo_prov ubigeo_dist ubigeo_ccpp
rename ubigeo_dpto_hh ubigeo_dpto
rename ubigeo_prov_hh ubigeo_prov
rename ubigeo_dist_hh ubigeo_dist
rename ubigeo_ccpp_hh ubigeo_ccpp

sort HHID

drop HV004 HV008 HV011 HV012 HV013 HV015 HV016 HV021 HV023 HV027 HV022 HV005 codccpp
drop V001 V002 V004 V006 V007 V008 V009 V010 V011 V012 V014 V015 V016 V017 V018 V019 V019A
drop V020 V021 V023 V027 V040 V000 Q105DD V106 V107 V133 V139 V140 V141 V149 AWFACTT AWFACTU AWFACTR AWFACTE AWFACTW
drop hhid DEPARTAMENTO V022 V005 S108N S108Y S108G S317AC S317AD S317C HA69


*	Average household age
bys HHID: egen avg_hh_age=mean(HV105)

*	Average HH education in years
recode HV108 (98=.)
bys	HHID: egen avg_hh_educ=mean(HV108)

*	Is household head
gen		hh_head = 0
replace hh_head = 1 if HV101==1


keep if HV117==1 | HV120==1


save "$input_dir\2 Working\endes_2017.dta", replace 










