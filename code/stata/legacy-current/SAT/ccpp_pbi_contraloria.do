clear all
cls
set more off
set maxvar 7000

dis "`c(hostname)'"

local machine "`c(hostname)'" // anyone who is working could add his/her
	// hostname 

* In one of the next rows you can add your directory

* Setting
	// note tha here every space is a ";" I dont like very big
	// sentence in a row. It looks terrible :)

* Note in who you need to put your initials (e.g: Paulo Matos - PM)


#d ; 

	if "`machine'" == "DESKTOP-B6EVHJM" {;
		local db "D:/Dropbox";
		local who "SAT";
	};

#d cr

local tp "VictimasRD"
local dq "`db'/`tp'"

cd "`dq'"

local data "2 data"
local coded "`data'/3 Coded"
local raw "`data'/1 Raw"
local dos "1 code/1 stata"

/*
import excel using "`raw'/4. PBI_CentrosPoblados_1993-2018.xlsx", first clear

gen ubigeo_ccpp=IDCARTOGR

rename (U AA AE)(a_2007 a_2013 a_2017)

keep a_2007 a_2013 a_2017 ubigeo_ccpp IDDIST IDCARTOGR NOMB_DEP NOMB_PRO NOMB_DIST NOMCCPP

replace ubigeo_ccpp="0809120001" if ubigeo_ccpp=="0809090036"

replace ubigeo_ccpp="0907190014" if ubigeo_ccpp=="0907180042"

replace ubigeo_ccpp="0905070072" if ubigeo_ccpp=="0905030054"

save "`raw'/pbi_ccpp_2007_2013_2017", replace
*/
/*
use "`coded'/community_index_treated_sisfohccpp", clear

merge 1:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)
/*
tab match12 if  (index_cutBC>=-0.02 & index_cutBC<=0.02) & ///
	(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | ///
	prov=="HUANCAYO" | dpto=="SAN MARTIN") 

br if  (index_cutBC>=-0.02 & index_cutBC<=0.02) & ///
	(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | ///
	prov=="HUANCAYO" | dpto=="SAN MARTIN") & match12==1
*/
keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_sisfohccpp_pbi", replace

use "`coded'/community_index_treated_sisfohhogpers", clear

merge m:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_sisfohhogpers_pbi", replace

use "`coded'/community_index_treated_cpv2017ccpp", clear

merge 1:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_cpv2017ccpp_pbi", replace
e
*/
/*
use "`coded'/community_index_treated_cpv2017hog", clear

merge m:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_cpv2017hog_pbi", replace

use "`coded'/community_index_treated_cpv2017ind", clear

merge m:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_cpv2017ind_pbi", replace
e
*/
/*
use "`coded'/community_index_treated_sisfohpers_both", clear

merge m:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_sisfohpers_both_pbi", replace
e
*/
use "`coded'/community_index_treated_cenagroccpp", clear

merge m:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_cenagroccpp_pbi", replace

use "`coded'/community_index_treated_cenagroccpp", clear

merge m:1 ubigeo_ccpp using "`raw'/pbi_ccpp_2007_2013_2017", gen(match1)

keep if match1==3
drop match1

save "`coded'/SAT/community_index_treated_minsaccpp_pbi", replace
e
