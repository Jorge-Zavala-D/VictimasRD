/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from 2017 Census	|
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 18/3/2019				 					                        |										          
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
	
	*global a "C:\Users\Jorge Zavala\Dropbox (Personal)Data\Censo 2017"
	*global a "C:\Users\j.zavaladelgado\Dropbox\Data\Censo 2017"
	*global a "C:\Users\jzava\Dropbox (Personal)\Data\Censo 2017"
	global a "C:\Users\jzavala\Dropbox\Data\Censo 2017"

*---------------------------------------*
*		I. Individual-level dataset		*
*---------------------------------------*

*-----------------------------------*
*		1a. Rename variables		*
*-----------------------------------*

use "$a\1-pob.dta", clear

rename hogar_ref_id 	hh_id
rename pnrohog			hh_num
rename pthogar			tot_hog

rename c5p1				relacion_parent
rename c5p2				sexo
rename c5p41			edad
rename c5p5				vive_permanente_dist
rename c5p5bcod			dpto_vive_permanente
rename c5p5ccod 		prov_vive_permanente
rename c5p5acod 		dist_vive_permanente
rename c5p5dcod			pais_vive_permanente
rename c5p6				vivia_5y_dist
rename c5p6bcod			dpto_vivia_5y
rename c5p6ccod			prov_vivia_5y
rename c5p6acod			dist_vivia_5y
rename c5p6dcod			pais_vivia_5y
rename c5p7				madre_vivia_dist_nacimiento
rename c5p7bcod			dpto_madre_vivia_nacimiento
rename c5p7ccod			prov_madre_vivia_nacimiento
rename c5p7acod			dist_madre_vivia_nacimiento
rename c5p7dcod			pais_madre_vivia_nacimiento
rename c5p81			seguro_sis_2017
rename c5p82 			seguro_essalud_2017
rename c5p83 			seguro_ffaa_2017
rename c5p84 			seguro_privado_2017
rename c5p85 			seguro_otro_2017
rename c5p86			seguro_ninguno_2017
rename c5p12			lee_escribe_2017
rename c5p13niv			nivel_educ_2017
rename c5p14			escolar_2017
rename c5p15			escuela_ubicacion_2017
rename c5p16			trabaja_2017
rename c5p21			ocupacion_2017
rename c5p27			num_hijos_2017

drop c5p9* c5p10a c5p11 c5p13gra c5p13aniop c5p13anios c5p13anioe c5p15bcod 	///
	c5p15ccod c5p15acod c5p15dcod c5p17 c5p18 c5p23 c5p23bcod c5p23ccod 		///
	c5p23acod c5p23dcod c5p24 c5p25 c5p26 c5p271 c5p28 c5p281 c5p291 c5p292 	///
	c5p19codi c5p20codi

	label drop c5p20cod
	rename c5p20cod		ciiu_cod
	replace 	ciiu_cod=. if ciiu_cod==0
	tostring 	ciiu_cod, gen(ciiu_categ)
	gen a=0
	egen ciiu_categ2=concat(a ciiu_categ) if  ciiu_cod<1000
	replace ciiu_categ2=ciiu_categ if ciiu_cod>=1000 & ciiu_cod!=.
	replace		ciiu_categ = substr(ciiu_categ2,1,2)
	destring 	ciiu_categ, replace
	drop ciiu_categ2
	
	label def ciiu_lb 1 "Agropecuario" 2 "Forestal" 3 "Pesca" 5 "Ext. Carbon" 	///
				6 "Ext. Petroleo" 7 " Ext. Metal" 8 "Ext. NoMetal" 				///
				9 "Ext. ActApoyo" 10 "Agroindustria" 11 "Fab. Bebidas" 			///
				12 "Fab. Tabaco" 13 "Textil" 14 "Fab. Ropa" 15 "Fab. Cuero" 	///
				16 "Fab. Madera" 17 "Fab. Papel" 18 "Imprenta" 					///
				19 "Refinacion Petroleo" 20 "Quimica" 21 "Farmaceutica" 		///
				22 "Caucho" 23 "Fab. ProdNoMetal" 24 "Fab. Metales" 			///
				25 "Fab. ProdMetal" 26 "Electronica" 27 "Fab. EquipoElectronico" ///
				28 "Maquinaria" 29 "Automotriz" 30 "Fab. Transporte" 			///
				31 "Fab. Muebles" 32 "Otro Manufactura" 						///
				33 "Ss. Reparacion/Instalacion" 35 "Elect., Gas, Vapor, AC."	///
				36 "Agua" 37 "Aguas residuales" 38 "Manejo de residuos"			///
				39 "Descontaminacion" 41 "Construccion edificios" 				///
				42 "Obras publicas" 43 "Act. construccion" 45 "Comercio Vehiculos" ///
				46 "Mayoristas NoVehiculo" 47 "Minoristas NoVehiculo"			///
				49 "Transporte terrestre" 50 "Transporte acuático"				///
				51 "Transporte aereo" 52 "Almacenamiento" 53 "Mensajeria" 		///
				55 "Alojamiento" 56 "Restaurantes" 58 "Edicion" 59 "Cine"		///
				60 "Transmision" 61 "Telecomunicaciones" 62 "Informatica"		///
				63 "Ss. InformacioN" 64 "Banca" 65 "Seguros y Pensiones" 		///
				66 "Act. Financieras" 68 "Inmobiliario" 69 "Notaria/Contable"	///
				70 "Consultoria" 71 "Arquitectura" 72 "Investigacion" 			///
				73 "Marketing" 74 "Otros Profesionales" 75 "Veterinaria" 		///
				77 "Alquiler" 78 "Agencias de empleo" 79 "Agencias de viaje"	///
				80 "Seguridad" 81 "Mantenimiento" 82 "Administracion"			///
				84 "Admin Publica" 85 "Educacion" 86 "Centros de salud" 		///
				87 "Enfermeria" 88 "Asistencia social"
	
*-----------------------------------------------*
*		Create indvidual-level variables		*
*-----------------------------------------------*





*---------------------------------------*
*		II. Household-level datset		*	
*---------------------------------------*

*-----------------------------------*
*		2a. Rename variables		*
*-----------------------------------*

use "$a\2-hog.dta", clear

rename hogar_ref_id 	hh_id
rename vivienda_ref_id	viv_id
rename hnrohog			hh_num

rename c3p11			energia_elect_2017
rename c3p12			energia_gas_2017
rename c3p13 			energia_gasnat_2017
rename c3p14 			energia_carbon_2017
rename c3p15 			energia_lea_2017
rename c3p16 			energia_bosta_2017
rename c3p17 			energia_otro_2017
rename c3p18			energia_nococina_2017

rename c3p21 			asset_equiposonido_2017
rename c3p22			asset_tvcolor_2017
rename c3p23 			asset_cocinagas_2017
rename c3p24 			asset_refri_2017
rename c3p25 			asset_lavadora_2017
rename c3p26 			asset_microondas_2017
rename c3p27 			asset_licuadora_2017
rename c3p28 			asset_plancha_2017
rename c3p29 			asset_compu_2017
rename c3p210 			asset_celular_2017
rename c3p211 			asset_telefonofijo_2017
rename c3p212 			asset_cable_2017
rename c3p213 			asset_internet_2017
rename c3p214 			asset_auto_2017
rename c3p215 			asset_moto_2017
rename c3p216			asset_bote_2017

rename ttotal			tot_perso_2017
rename thombres			tot_hombres_2017
rename tmujeres			tot_mujeres_2017


*---------------------------------------------------*
*		2b. Create household-level variables		*
*---------------------------------------------------*





*---------------------------------------*
*		III. Dweling-level datset		*	
*---------------------------------------*

*-----------------------------------*
*		3a. Rename variables		*
*-----------------------------------*

use "$a\3-viv.dta", clear

rename vivienda_ref_id	viv_id
rename distrito_ref_id	dist_id

rename c2p3		pared_2017
rename c2p4		techo_2017
rename c2p5		piso_2017
rename c2p6		agua_2017
rename c2p7		agua_constante_2017
rename c2p10	saneamiento_2017
rename c2p11	alumbrado_2017
rename c2p12	nro_habitaciones
rename tc4p1	tot_pob_viv_2017


*-----------------------------------------------*
*		3b. Create dweling-level variables		*
*-----------------------------------------------*











