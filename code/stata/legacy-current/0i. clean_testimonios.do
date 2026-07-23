/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from 2017 Census	|
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 09/12/2019				 				                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/

*-----------------------*
*       DIRECTORY       *
*-----------------------*
	clear all
	set more off
	version 13
	
	*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
	*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD\"
	global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
	*global a "C:\Users\jzavala\Dropbox\VictimasRD"
	*global a "/Users/bruno_esposito/Dropbox/Proyectos/Matthew/VictimasRD"


use "$a\2 data\1 Raw\8 Testimonios\Registro Testimonios Defensoria\Data_Testimonios_v2.dta", clear
	

	gen base=1
	merge 1:m nrotestimonio codigoevento using "$a\2 data\1 Raw\8 Testimonios\Data_Testimonios.dta", keepusing(coddepaacto codprovacto coddistacto nroacto codigoacto tipoacto codigogrupo codigorolactor)
	drop if DURACIÓN_Grabacion==""
	
	rename nrotestimonio 				cod_testimonio
	rename codigoevento 				cod_evento
	rename fechatestimonio 				date_testimonio
	rename idiomatestimonio 			idioma
	rename nombreevento 				name_evento
	rename nroacto 						num_acto
	rename codigoacto 					cod_acto
	rename departamentoacto 			dpto_acto
	rename provinciaacto 				prov_acto
	rename distritoacto 				dist_acto
	rename fechinicioacto 				date_acto_inicio
	rename fechfinalacto 				date_acto_fin
	rename tipoacto 					cod_tipoacto
	rename descripcionacto 				desc_tipoacto
	rename codigogrupo 					cod_perpetrador
	rename codigorolactor 				cod_rolactor
	rename descripciongrupo 			name_perpetrador
	rename sexopersona					sex_victima
	rename autorizagrabacion			autoriza_yn
	
	egen ubigeo_dist=concat(coddepaacto codprovacto coddistacto)
	drop coddepaacto codprovacto coddistacto  	///
		paternopersona maternopersona nombrepersona ///
		name_evento
	
	drop if cod_evento==.
	
	replace autoriza_yn ="0" if autoriza_yn=="N"
	replace autoriza_yn ="1" if autoriza_yn=="S"
	destring autoriza_yn, replace
	
	encode idioma, gen(idioma_coded)
	drop idioma
	gen idioma_castellano = 0 
	replace idioma_castellano = 1 if idioma_coded==3
	gen idioma_quechua = 0 
	replace idioma_quechua = 1 if idioma_coded==6	
	
	replace	cod_tipoacto="Desaparicion" 	if cod_tipoacto=="LDS"
	replace cod_tipoacto="Detencion" 		if cod_tipoacto=="LDT"
	replace cod_tipoacto="Reclutamiento" 	if cod_tipoacto=="LRC"
	replace cod_tipoacto="Secuestro" 		if cod_tipoacto=="LSE"
	replace cod_tipoacto="Asesinato" 		if cod_tipoacto=="MAE"
	replace cod_tipoacto="Atentato" 		if cod_tipoacto=="MAT"
	replace cod_tipoacto="Enfrentamiento" 	if cod_tipoacto=="MEF"
	replace cod_tipoacto="SIN TIPO" 		if cod_tipoacto=="RES"
	replace cod_tipoacto="Lesiones" 		if cod_tipoacto=="TLA"
	replace cod_tipoacto="Tortura" 			if cod_tipoacto=="TTR"
	replace cod_tipoacto="Violacion" 		if cod_tipoacto=="TVS"
	
	encode cod_tipoacto, gen(cod_tipoacto2)
	drop cod_tipoacto
	rename cod_tipoacto2 cod_tipoacto
	
	
	gen 	categ_resp=""
	replace categ_resp="PNP" if cod_perpetrador=="B00" | cod_perpetrador=="B01" | cod_perpetrador=="B02" | cod_perpetrador=="B03" | cod_perpetrador=="B04" | cod_perpetrador=="B05" | cod_perpetrador=="B06" |cod_perpetrador=="B07" | cod_perpetrador=="B08" | cod_perpetrador=="B09"
	replace categ_resp="Terroristas" if cod_perpetrador=="AB0" | cod_perpetrador=="E00" | cod_perpetrador=="E01" | cod_perpetrador=="E02" 
	replace categ_resp="Ejercito" if cod_perpetrador=="A00" | cod_perpetrador=="A01" | cod_perpetrador=="A02" | cod_perpetrador=="A03" | cod_perpetrador=="A04"
	replace categ_resp="Paramilitares" if cod_perpetrador=="D00" | cod_perpetrador=="D01" | cod_perpetrador=="D02" | cod_perpetrador=="D03" | cod_perpetrador=="D04" | cod_perpetrador=="D05" | cod_perpetrador=="D06"
	replace categ_resp="Rondas" if cod_perpetrador=="C00" | cod_perpetrador=="C01" | cod_perpetrador=="C02" | cod_perpetrador=="F00"
	replace categ_resp="Otros" if cod_perpetrador=="H00" | cod_perpetrador=="G00"
	replace categ_resp="Victima" if (descripcionrol=="Víctima" | cod_rolactor=="PRI") & categ_resp==""

	bys cod_testimonio categ_resp: gen rep_resp=_N
	bys cod_testimonio categ_resp: gen order_rep_resp=_n
	bys cod_testimonio: egen max_rep_resp=max(rep_resp)	
	keep if rep_resp==max_rep_resp & order_rep_resp==1
	
	bys cod_testimonio: gen order_testimonio=_n
	
	keep if order_testimonio==1
	
	replace dpto="LIMA" if dpto=="CALLAO"
	gen dpto_select=0
	replace dpto_select=1 if dpto_acto=="AYACUCHO" | dpto_acto=="HUANUCO" | 	///
								dpto_acto=="JUNIN" | dpto_acto=="APURIMAC" | 	///
								dpto_acto=="SAN MARTIN" | dpto_acto=="LIMA" | 	///
								dpto_acto=="UCAYALI" | dpto_acto=="HUANCAVELICA" | ///
								dpto_acto=="CUSCO" | dpto_acto=="PUNO" | 		///
								dpto_acto=="PIURA" | dpto_acto=="ANCASH" | 		///
								dpto_acto=="PASCO"
	
	
replace horainicio=substr(horainicio ,-5,5)
replace horafin=substr(horafin ,-5,5)	
destring horainicio , replace
gen double ntime = clock(horainicio , "hm")
gen double ntime2 = clock(horafin , "hm")
gen a = ntime2 - ntime
format a  %tc
format a  %tcHH:MM
br horainicio horafin a
sum a
gen b = a/60
replace b=b/1000	
	
	gen year_inicio=substr(date_acto_inicio,7,4)
	
	
saveold "$a\2 data\2 Working\Data_Testimonios_coded.dta", replace v(13)
	
use "$a\2 data\2 Working\Data_Testimonios_coded.dta", clear
	
set seed 290516
gen rand=runiform()
 egen dpto_resp=group(dpto_acto categ_resp), l
 sort rand
bys dpto_resp: gen n=_n

 gen 		rand_select = 0
 replace 	rand_select = 1 if dpto_acto=="ANCASH" & categ_resp=="Ejercito" & n<=2
 replace 	rand_select = 1 if dpto_acto=="ANCASH" & categ_resp=="Otros" & n<=1
 replace 	rand_select = 1 if dpto_acto=="ANCASH" & categ_resp=="PNP" & n<=9
 replace 	rand_select = 1 if dpto_acto=="ANCASH" & categ_resp=="Rondas" & n<=9
 replace 	rand_select = 1 if dpto_acto=="ANCASH" & categ_resp=="Terroristas" & n<=11
 replace 	rand_select = 1 if dpto_acto=="ANCASH" & categ_resp=="Victima" & n<=11
  
 replace 	rand_select = 1 if dpto_acto=="APURIMAC" & categ_resp=="Ejercito" & n<=24
 replace 	rand_select = 1 if dpto_acto=="APURIMAC" & categ_resp=="Otros" & n<=2
 replace 	rand_select = 1 if dpto_acto=="APURIMAC" & categ_resp=="PNP" & n<=13
 replace 	rand_select = 1 if dpto_acto=="APURIMAC" & categ_resp=="Terroristas" & n<=56 
 replace 	rand_select = 1 if dpto_acto=="APURIMAC" & categ_resp=="Victima" & n<=66

 replace 	rand_select = 1 if dpto_acto=="AYACUCHO" & categ_resp=="Ejercito" & n<=102
 replace 	rand_select = 1 if dpto_acto=="AYACUCHO" & categ_resp=="Otros" & n<=15
 replace 	rand_select = 1 if dpto_acto=="AYACUCHO" & categ_resp=="PNP" & n<=31
 replace 	rand_select = 1 if dpto_acto=="AYACUCHO" & categ_resp=="Rondas" & n<=27
 replace 	rand_select = 1 if dpto_acto=="AYACUCHO" & categ_resp=="Terroristas" & n<=206
 replace 	rand_select = 1 if dpto_acto=="AYACUCHO" & categ_resp=="Victima" & n<=190
 
 replace 	rand_select = 1 if dpto_acto=="CUSCO" & categ_resp=="Ejercito" & n<=3
 replace 	rand_select = 1 if dpto_acto=="CUSCO" & categ_resp=="Otros" & n<=3
 replace 	rand_select = 1 if dpto_acto=="CUSCO" & categ_resp=="PNP" & n<=18
 replace 	rand_select = 1 if dpto_acto=="CUSCO" & categ_resp=="Rondas" & n<=1
 replace 	rand_select = 1 if dpto_acto=="CUSCO" & categ_resp=="Terroristas" & n<=20
 replace 	rand_select = 1 if dpto_acto=="CUSCO" & categ_resp=="Victima" & n<=17
 
 replace 	rand_select = 1 if dpto_acto=="HUANCAVELICA" & categ_resp=="Ejercito" & n<=11
 replace 	rand_select = 1 if dpto_acto=="HUANCAVELICA" & categ_resp=="Otros" & n<=3
 replace 	rand_select = 1 if dpto_acto=="HUANCAVELICA" & categ_resp=="PNP" & n<=3
 replace 	rand_select = 1 if dpto_acto=="HUANCAVELICA" & categ_resp=="Rondas" & n<=3
 replace 	rand_select = 1 if dpto_acto=="HUANCAVELICA" & categ_resp=="Terroristas" & n<=23
 replace 	rand_select = 1 if dpto_acto=="HUANCAVELICA" & categ_resp=="Victima" & n<=19
 
 replace 	rand_select = 1 if dpto_acto=="HUANUCO" & categ_resp=="Ejercito" & n<=85
 replace 	rand_select = 1 if dpto_acto=="HUANUCO" & categ_resp=="Otros" & n<26
 replace 	rand_select = 1 if dpto_acto=="HUANUCO" & categ_resp=="PNP" & n<=10
 replace 	rand_select = 1 if dpto_acto=="HUANUCO" & categ_resp=="Rondas" & n<=3
 replace 	rand_select = 1 if dpto_acto=="HUANUCO" & categ_resp=="Terroristas" & n<=187
 replace 	rand_select = 1 if dpto_acto=="HUANUCO" & categ_resp=="Victima" & n<=109
 
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="Ejercito" & n<=14
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="Otros" & n<=9
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="PNP" & n<=15
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="Paramilitares" & n<=0
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="Rondas" & n<=7
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="Terroristas" & n<=74
 replace 	rand_select = 1 if dpto_acto=="JUNIN" & categ_resp=="Victima" & n<=72
 
 replace 	rand_select = 1 if dpto_acto=="LIMA" & categ_resp=="Ejercito" & n<=11
 replace 	rand_select = 1 if dpto_acto=="LIMA" & categ_resp=="Otros" & n<=5
 replace 	rand_select = 1 if dpto_acto=="LIMA" & categ_resp=="PNP" & n<=55
 replace 	rand_select = 1 if dpto_acto=="LIMA" & categ_resp=="Paramilitares" & n<=3
 replace 	rand_select = 1 if dpto_acto=="LIMA" & categ_resp=="Terroristas" & n<=8
 replace 	rand_select = 1 if dpto_acto=="LIMA" & categ_resp=="Victima" & n<=29
 
 replace 	rand_select = 1 if dpto_acto=="PASCO" & categ_resp=="Ejercito" & n<=4
 replace 	rand_select = 1 if dpto_acto=="PASCO" & categ_resp=="Otros" & n<=3
 replace 	rand_select = 1 if dpto_acto=="PASCO" & categ_resp=="PNP" & n<=3
 replace 	rand_select = 1 if dpto_acto=="PASCO" & categ_resp=="Rondas" & n<=2
 replace 	rand_select = 1 if dpto_acto=="PASCO" & categ_resp=="Terroristas" & n<=31
 replace 	rand_select = 1 if dpto_acto=="PASCO" & categ_resp=="Victima" & n<=21
 
 replace 	rand_select = 1 if dpto_acto=="PIURA" & categ_resp=="Ejercito" & n<=8
 replace 	rand_select = 1 if dpto_acto=="PIURA" & categ_resp=="PNP" & n<=15
 replace 	rand_select = 1 if dpto_acto=="PIURA" & categ_resp=="Terroristas" & n<=6
 replace 	rand_select = 1 if dpto_acto=="PIURA" & categ_resp=="Victima" & n<=10
 
 replace 	rand_select = 1 if dpto_acto=="PUNO" & categ_resp=="Ejercito" & n<=8
 replace 	rand_select = 1 if dpto_acto=="PUNO" & categ_resp=="Otros" & n<=1
 replace 	rand_select = 1 if dpto_acto=="PUNO" & categ_resp=="PNP" & n<=10
 replace 	rand_select = 1 if dpto_acto=="PUNO" & categ_resp=="Rondas" & n<=2
 replace 	rand_select = 1 if dpto_acto=="PUNO" & categ_resp=="Terroristas" & n<=25
 replace 	rand_select = 1 if dpto_acto=="PUNO" & categ_resp=="Victima" & n<=17
 
 replace 	rand_select = 1 if dpto_acto=="SAN MARTIN" & categ_resp=="Ejercito" & n<=35
 replace 	rand_select = 1 if dpto_acto=="SAN MARTIN" & categ_resp=="Otros" & n<=13
 replace 	rand_select = 1 if dpto_acto=="SAN MARTIN" & categ_resp=="PNP" & n<=8
 replace 	rand_select = 1 if dpto_acto=="SAN MARTIN" & categ_resp=="Rondas" & n<=2
 replace 	rand_select = 1 if dpto_acto=="SAN MARTIN" & categ_resp=="Terroristas" & n<=68
 replace 	rand_select = 1 if dpto_acto=="SAN MARTIN" & categ_resp=="Victima" & n<=43
 
 replace 	rand_select = 1 if dpto_acto=="UCAYALI" & categ_resp=="Ejercito" & n<=25
 replace 	rand_select = 1 if dpto_acto=="UCAYALI" & categ_resp=="Otros" & n<=5
 replace 	rand_select = 1 if dpto_acto=="UCAYALI" & categ_resp=="PNP" & n<=8
 replace 	rand_select = 1 if dpto_acto=="UCAYALI" & categ_resp=="Terroristas" & n<=36
 replace 	rand_select = 1 if dpto_acto=="UCAYALI" & categ_resp=="Victima" & n<=18


	keep if rand_select==1

	keep cod_evento cod_acto cod_testimonio idioma_coded
	order cod_evento cod_acto cod_testimonio idioma_coded
	
 format %12.0g cod_evento
	
	*SELECCION SOLO ES CASTELLANO Y QUECHUA, AÑADIR LOS DE OTROS IDIOMAS
	
	
