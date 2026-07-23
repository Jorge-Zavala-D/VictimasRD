/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from 2007 Censos  |
|					  and define candidates for controls at community level		|
|                                                                               |
|Date Created: 15/08/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	1.	Import 2007 Census raw dataset
	2.	Rename variables
	3.	Label variables
	4.	Set candidates for controls

*-------------------------------------------------------------------------------*/

*-------------------------------------------*
*		Import 2007 Census raw dataset		*
*-------------------------------------------*

use "$input_dir\1 Raw\ccpp_censo2007.dta",clear

*-------------------------------*
*		Rename variables		*
*-------------------------------*

	rename ubigeo_centropoblado 			ubigeo_ccpp
	rename departamento 					dpto
	rename provincia						prov
	rename distrito							dist
	rename centropoblado					ccpp
	rename area								urb_rur
	rename hogares							hogares_num
	rename Población						pob
	rename casaindependiente				tipo_vivpart_casaindep
	rename departamentoenedificio			tipo_vivpart_dpto
	rename viviendaenquinta					tipo_vivpart_quinta
	rename casavecindad						tipo_vivpart_vecind
	rename chozaocabaña						tipo_vivpart_choza
	rename vivimprovisada					tipo_vivpart_improv
	rename nodestinado						tipo_vivpart_nodestinado
	rename otrotipoparticular				tipo_vivpart_otro
	rename var19							vivpart_num
	rename hotelhospedaje					tipo_vivcol_hotel
	rename casapensión						tipo_vivcol_pension
	rename hospitalclínica					tipo_vivcol_hospital
	rename cárcel							tipo_vivcol_carcel
	rename asilo							tipo_vivcol_asilo
	rename aldeainfantilorfelinato			tipo_vivcol_orfelinato
	rename otrotipocolectiva				tipo_vivcol_otro
	rename var27							vivcol_num
	rename var29							viv_num
	rename ocupadaconpersonaspresentes		ocup_vivpart_ocupadapres
	rename ocupadaconpersonasausentes		ocup_vivpart_ocupadaaus
	rename deusoocasional					ocup_vivpart_ocasional
	rename desocupadaenalquiler				ocup_vivpart_desocupalquiler
	rename desocupadaenconstrucciónóreparac ocup_vivpart_desocupconstruc
	rename abandonadacerrada				ocup_vivpart_abandonada
	rename otracausa						ocup_vivpart_otro
	rename ladrilloobloquedecemento			pared_ladrillo
	rename adobeotapia						pared_adobe
	rename maderaponatornilloetc			pared_madera
	rename quinchacañaconbarro				pared_quincha
	rename estera							pared_estera
	rename piedraconbarro					pared_piedrabarro
	rename piedrasillarconcalocemento		pared_piedracemento
	rename otromaterial						pared_otro
	rename tierra							piso_tierra
	rename cemento							piso_cemento
	rename losetasterrazos					piso_loseta
	rename parquetomaderapulida				piso_parquet
	rename maderaentablados					piso_tabla
	rename laminasasfálticas				piso_lamina
	rename otro								piso_otro
	rename Redpúblicadentroaguapotable		agua_redpub_dentro
	rename redpúblicafuera					agua_redpub_fuera
	rename pilóndeusopúblico				agua_pilon
	rename camióncisterna					agua_cisterna
	rename pozo								agua_pozo
	rename ríoacequia						agua_rio
	rename vecino							agua_vecino
	rename var62							agua_otro
	rename si								abast_agua_247_si
	rename no								abast_agua_247_no
	rename redpublicadedesaguedentrodelaviv desague_redpub_dentro
	rename Redpúblicafueradelaviviendperode desague_redpub_fuera
	rename pozoseptico						desague_pozo
	rename pozociegoonegroletrina			desague_letrina
	rename rioacequiaocanal					desague_rio
	rename notiene							desague_notiene
	rename var74							alumbrado_redpub_si
	rename var75							alumbrado_redpub_no
	rename promedio							hab_prom
	rename alquilada						tenencia_alquilada
	rename propiaporinvasión				tenencia_propiainvasion
	rename propiapagandoaplazos				tenencia_propiacredito
	rename propiatotalmentepagada			tenencia_propiapagada
	rename cedidaporelcentrodetrabajo		tenencia_cedida
	rename otraforma						tenencia_otro
	rename radio							activo_radio
	rename tvcolor							activo_tvcolor
	rename equipodesonido					activo_equiposonido
	rename lavadora							activo_lavadora
	rename refrigeradora					activo_refri
	rename computadora						activo_pc
	rename telefonofijo						activo_telefonofijo
	rename telefonocelular					activo_celular
	rename conexiónainternet				activo_internet
	rename conexióncable					activo_cable
	rename ninguno							activo_ninguno
	rename electricidad						energia_elect
	rename gas								energia_gas
	rename kerosene							energia_kerosene
	rename carbón							energia_carbon
	rename leña								energia_leña
	rename bostaestiércol					energia_bosta
	rename var103							energia_otro
	rename nococinan						energia_nococinan
	rename total							hhmember_otropais_num
	rename paraveraunusandolentes			discap_ver
	rename paraoiraunusandoaudifonodesorder	discap_oir
	rename parahablarentonarvocalizar		discap_hablar
	rename parausarbrazosymanospiernasypies	discap_mover
	rename Algunaotradificultadolimitación	discap_otro
	rename ningunapersonacondiscapacidad	discap_ninguna
	rename jefeojefa						relparent_jefe
	rename Esposaocompañerao				relparent_esposo
	rename hijoahijastroa					relparent_hijo
	rename yernonuera						relparent_yerno
	rename nietoa							relparent_nieto
	rename padressuegros					relparent_padre
	rename otroaparientes					relparent_otropariente
	rename trabajadoradelhogar				relparent_trabajhogar
	rename pensionista						relparent_pensionista
	rename otroanopariente					relparent_otronopariente
	rename noprecisa						relparent_noprecisa
	rename hombre							sexo_h
	rename mujer							sexo_m
	rename menosde1años						edad_u1
	rename a14años							edad_1_14
	rename a29años							edad_15_29
	rename a44años							edad_30_44
	rename a64años							edad_45_64
	rename masde65años						edad_65
	rename var135							partidanac_si
	rename var136							partidanac_no
	rename var137							partidanac_noprecisa
	rename var139							vive_perm_si
	rename var140							vive_perm_no
	rename aunnohabianacido					vivia_5_nonacido
	rename var143							vivia_5_si
	rename var144							vivia_5_no
	rename var146							madre_viviadist_si
	rename var147							madre_viviadist_no
	rename sis								seguro_sis
	rename essalud							seguro_essalud
	rename otroseguro						seguro_otro
	rename var152							seguro_ninguno
	rename quechua							idioma_quechua
	rename aymara							idioma_aymara
	rename ashaninka						idioma_ashaninka
	rename otralenguanativa					idioma_otronativa
	rename castellano						idioma_castellano
	rename idiomaextranjero					idioma_extranjero
	rename essordomudo						idioma_sordomudo
	rename var161							lee_escribe_si
	rename var162							lee_escribe_no
	rename sinnivel							nivel_educ_ninguno
	rename Educacióninicial					nivel_educ_inicial
	rename primaria							nivel_educ_primaria
	rename secundaria						nivel_educ_secundaria
	rename superiornouniversitariaincomplet	nivel_educ_tec_incompleta
	rename superiornouniversitariacompleta	nivel_educ_tec_completa
	rename superioruniversitariaincompleta	nivel_educ_univ_incompleta
	rename superioruniversitariacompleta	nivel_educ_univ_completa
	rename var173							educ_colegio_ninguno
	rename primergradooaño					educ_colegio_primero
	rename segundogradooaño					educ_colegio_segundo
	rename tercergradooaño					educ_colegio_tercero
	rename cuartogradooaño					educ_colegio_cuarto
	rename quintogradooaño					educ_colegio_quinto
	rename sextogradooaño					educ_colegio_sexto
	rename var181							asiste_escuela_si
	rename var182							asiste_escuela_no
	rename var184							trabajo_remunerado_si
	rename var185							trabajo_remunerado_no
	rename notrabajoperoteniatrabajo		trabajo_no_siempleado
	rename aunquenotrabajotienealgunnegocio	trabajo_no_connegocio
	rename realizoalguncachueloporunpagoend	trabajo_cachuelo
	rename estuvoayudandoenlachacratiendaon	trabajo_noremunerado
	rename notrabajo						trabajo_no
	rename estuvobuscandotrabajohabiendotra	desempleado_buscando
	rename estuvobuscandotrabajoporprimerav	desempleado_primertrabajo
	rename estuvoestudiandoynotrabajó		desempleado_estudiante
	rename estuvoviviendodesupensiónojubila	desempleado_jubilado
	rename estuvoviviendodesusrentasynotrab	desempleado_rentas
	rename estuvoalcuidadodesuhogarynotrab  desempleado_hogar
	rename otra								desempleado_otro
	rename porsuedad						desempleado_edad
	rename estuvodeviaje					desempleado_viaje
	rename discapacidad						desempleado_discapacidad
	rename serviciomilitar					desempleado_ssmilitar
	rename miembrosdelpoderejecutivo		ocupacion_poderejecutivo
	rename AdmPúblicosyEmpresas				ocupacion_admin
	rename ProfesiónCientIntelect			ocupacion_cientifico
	rename Técnicosnivelmedio				ocupacion_tecnicomedio
	rename jefesempldeoficina				ocupacion_jefeoficina
	rename trabservvendcomercio				ocupacion_comercio
	rename trabcalificadoagricultor			ocupacion_agricultor
	rename obreroperminasycant				ocupacion_minero
	rename obrerosconstfabinstr				ocupacion_costruccion
	rename TrabnocalifIcadoPeón				ocupacion_nocalificado
	rename var213							ocupacion_otro
	rename OcupaciónnoespecífIca			ocupacion_noespecifica
	rename AgriculturaGanaderíaCaza			actividad_agro
	rename pesca							actividad_pesca
	rename Explotacióndeminasycanteras		actividad_mineria
	rename industriasmanufactureras			actividad_manufactura
	rename Construcción						actividad_construccion
	rename electricidadgasyagua				actividad_elecgasagua
	rename comercio							actividad_comercio
	rename servicios						actividad_servicios
	rename IntermediaciónFinanciera			actividad_finanzas
	rename transpalmacycom					actividad_turismo
	rename actividadnoespecificada			actividad_noespecifica
	rename empleado							tipo_empleo_empleado
	rename obrero							tipo_empleo_obrero
	rename trabajadorindependienteoporpropi	tipo_empleo_indep
	rename empleadoropatrono				tipo_empleo_empleador
	rename trabajadorfamiliarnoremunerado	tipo_empleo_familiar
	rename trabajadordelhogar				tipo_empleo_hogar
	rename de1a5personas					size_empresa_1_5
	rename de6a10personas					size_empresa_6_10
	rename de11a50personas					size_empresa_11_50
	rename de51amaspersonas					size_empresa_51
	rename catolica							religion_catolica
	rename cristianaevangelica				religion_cristevang
	rename var241							religion_otro
	rename ninguna							religion_ninguna
	rename conviviente						estado_civil_conviviente
	rename separado							estado_civil_separado
	rename casado							estado_civil_casado
	rename viudo							estado_civil_viudo
	rename divorciado						estado_civil_divorciado
	rename soltero							estado_civil_soltero
	rename var251							hijos_nacidos_promedio
	rename var252							hijos_vivos_promedio
	rename var253							madres_num
	rename var254							edad_primer_hijo_promedio
	rename var255							tiene_dni_si
	rename var256							tiene_dni_no
	rename peaactiva						pea_activa_num
	rename peanoactiva						pea_no_activa_num
	rename nopea							no_pea_num

*---------------------------*
*		Label variables		*
*---------------------------*



*---------------------------*
*		Clean variables		*
*---------------------------*


	gen 	dpto2=subinstr(dpto," ","",.)
	replace dpto2=subinstr(dpto2,"Á","A",.)
	replace dpto2=subinstr(dpto2,"É","E",.)
	replace dpto2=subinstr(dpto2,"Í","I",.)
	replace dpto2=subinstr(dpto2,"Ó","O",.)
	replace dpto2=subinstr(dpto2,"Ú","U",.)
	replace dpto2=subinstr(dpto2,"Ñ","N",.)
	replace dpto2=subinstr(dpto2,"Ð","D",.)
	gen 	prov2=subinstr(prov," ","",.)
	replace prov2=subinstr(prov2,"Á","A",.)
	replace prov2=subinstr(prov2,"É","E",.)
	replace prov2=subinstr(prov2,"Í","I",.)
	replace prov2=subinstr(prov2,"Ó","O",.)
	replace prov2=subinstr(prov2,"Ú","U",.)
	replace prov2=subinstr(prov2,"Ñ","N",.)
	replace prov2=subinstr(prov2,"Ð","D",.)
	replace prov2=subinstr(prov2,"-","",.)
	replace prov2=subinstr(prov2,"_","",.)
	gen 	dist2=subinstr(dist," ","",.)
	replace dist2=subinstr(dist2,"Á","A",.)
	replace dist2=subinstr(dist2,"É","E",.)
	replace dist2=subinstr(dist2,"Í","I",.)
	replace dist2=subinstr(dist2,"Ó","O",.)
	replace dist2=subinstr(dist2,"Ú","U",.)
	replace dist2=subinstr(dist2,"Ñ","N",.)
	replace dist2=subinstr(dist2,"Ð","D",.)
	replace dist2=subinstr(dist2,"-","",.)
	replace dist2=subinstr(dist2,"_","",.)
	gen 	ccpp2=subinstr(ccpp," ","",.)
	replace ccpp2=subinstr(ccpp2,"Á","A",.)
	replace ccpp2=subinstr(ccpp2,"É","E",.)
	replace ccpp2=subinstr(ccpp2,"Í","I",.)
	replace ccpp2=subinstr(ccpp2,"Ó","O",.)
	replace ccpp2=subinstr(ccpp2,"Ú","U",.)
	replace ccpp2=subinstr(ccpp2,"Ñ","N",.)
	replace ccpp2=subinstr(ccpp2,"Ð","D",.)
	replace ccpp2=subinstr(ccpp2,"-","",.)
	replace ccpp2=subinstr(ccpp2,"_","",.)

	egen dpdc=concat(dpto2 prov2 dist2 ccpp2)
	bysort dpdc: gen rep=_n
	drop if rep>1
	drop dpdc



*	Ubigeo at district, province and region level
	gen ubigeo_dist=substr(ubigeo_ccpp,1,6)
	gen ubigeo_prov=substr(ubigeo_ccpp,1,4)
	gen ubigeo_dpto=substr(ubigeo_ccpp,1,2)

	order ubigeo_dist ubigeo_prov ubigeo_dpto, after(ubigeo_ccpp)

*	Urban/Rural dummy
	replace urb_rur="1" if urb_rur=="Urbano"
	replace urb_rur="0" if urb_rur=="Rural"
	destring urb_rur, replace
	
	label def urb_rur_lb 1 Urbano 0 Rural
	label val urb_rur urb_rur_lb
	


*-----------------------------------*
*		Candidates for controls		*
*-----------------------------------*

*-------------------------------------------*
*		Characteristics of the house		*
*-------------------------------------------*

	gen		prop_pared_ladrillo2007 = pared_ladrillo/var46
	gen		prop_pared_piedra2007	= pared_piedracemento/var46
	gen		prop_pared_adobe2007	= pared_adobe/var46
	gen		prop_pared_quincha2007	= pared_quincha/var46
	gen		prop_pared_madera2007	= pared_madera/var46
	gen		prop_pared_estera2007	= pared_estera/var46
	gen		prop_pared_barro2007	= pared_piedrabarro/var46
	gen		prop_pared_otro2007		= pared_otro/var46

	*gen		prop_techo_concreto2007 = sisf_matecho1/viv
	*gen		prop_techo_madera2007	= sisf_matecho2/viv
	*gen		prop_techo_teja2007		= sisf_matecho3/viv
	*gen		prop_techo_calamina2007	= sisf_matecho4/viv
	*gen		prop_techo_estera2007	= sisf_matecho6/viv
	*gen		prop_techo_paja2007		= sisf_matecho7/viv

	gen		prop_piso_parquet2007	= piso_parquet/var54
	gen		prop_piso_lamina2007	= piso_lamina/var54
	gen		prop_piso_loseta2007	= piso_loseta/var54
	gen		prop_piso_tabla2007		= piso_tabla/var54
	gen		prop_piso_cemento2007	= piso_cemento/var54
	gen		prop_piso_tierra2007	= piso_tierra/var54
	gen		prop_piso_otro2007		= piso_otro/var54

	gen		prop_mujeres2007		= sexo_m/var127
	
*-----------------------------------*
*		Services in the house		*
*-----------------------------------*
	*gen		prop_alumbrado_elect	= sisf_alumb1/viv
	*gen		prop_alumbrado_kerosene = sisf_alumb2/viv
	*gen		prop_alumbrado_lampara 	= sisf_alumb3/viv
	*gen		prop_alumbrado_vela		= sisf_alumb4/viv
	*gen		prop_alumbrado_ninguno	= sisf_alumb6/viv
	
	gen		prop_agua_redpubdentro2007	= agua_redpub_dentro/var63
	gen		prop_agua_redpubfuera2007	= agua_redpub_fuera/var63
	gen		prop_agua_pilon2007			= agua_pilon/var63
	gen		prop_agua_cisterna2007		= agua_cisterna/var63
	gen		prop_agua_pozo2007			= agua_pozo/var63
	gen		prop_agua_rio2007			= agua_rio/var63
	gen		prop_agua_vecino2007		= agua_vecino/var63
	gen		prop_agua_otro2007			= agua_otro/var63
	
	gen		prop_saneamiento_redpubdentro07	= desague_redpub_dentro/var73
	gen		prop_saneamiento_redpubfuera07	= desague_redpub_fuera/var73
	gen		prop_saneamiento_pozo2007			= desague_pozo/var73
	gen 	prop_saneamiento_letrina2007		= desague_letrina/var73
	gen		prop_saneamiento_rio2007			= desague_rio/var73
	gen		prop_saneamiento_ninguno2007		= desague_notiene/var73
	
	gen		prop_combust_elect2007		= energia_elect/var105
	gen		prop_combust_gas2007		= energia_gas/var105
	gen		prop_combust_kerosene2007	= energia_kerosene/var105
	gen		prop_combust_carbon2007		= energia_carbon/var105
	gen		prop_combust_lea2007		= energia_leña/var105
	gen		prop_combust_bosta2007		= energia_bosta/var105
	gen		prop_combust_otro2007		= energia_otro/var105
	gen		prop_combust_nococina2007	= energia_nococinan/var105	
	
	
*-------------------*
*		Assets		*
*-------------------*

	gen		prop_asset_equipsonido2007	= activo_equiposonido/var84
	gen		prop_asset_tvcolor2007		= activo_tvcolor/var84
	*gen		prop_asset_dvd			= sisf_bien3/hog
	*gen		prop_asset_licuadora	= sisf_bien4/hog
	gen		prop_asset_refri2007		= activo_refri/var84
	*gen		prop_asset_cocinagas	= sisf_bien6/hog
	gen		prop_asset_telefonofijo2007	= activo_telefonofijo/var84
	*gen		prop_asset_plancha		= sisf_bien8/hog
	gen		prop_asset_lavadora2007		= activo_lavadora/var84
	gen		prop_asset_compu2007		= activo_pc/var84
	*gen		prop_asset_microondas	= sisf_bien11/hog
	gen		prop_asset_internet2007		= activo_internet/var84
	gen		prop_asset_cable2007		= activo_cable/var84
	gen		prop_asset_celular2007		= activo_celular/var84
	gen		prop_asset_ninguno2007		= activo_ninguno/var84
	
	
*-------------------------------*
*		Age distribution		*
*-------------------------------*	
	
	gen		prop_edad_u12007		= edad_u1/var134
	gen		prop_edad_1_142007		= edad_1_14/var134
	gen		prop_edad_15_292007		= edad_15_29/var134
	gen		prop_edad_30_442007		= edad_30_44/var134
	gen		prop_edad_45_642007		= edad_45_64/var134
	gen		prop_edad_652007		= edad_65/var134
	
	egen 	edad_15mas2007			= rowtotal(edad_15_29 edad_30_44 edad_45_64 edad_65)
	gen		prop_edad_152007		= edad_15mas/var134
	
	
*---------------------------------------*
*		Affilitation to insurance		*
*---------------------------------------*						 
						 
	gen		prop_seguro_essalud2007		= seguro_essalud/pob
	*gen		prop_seguro_ffaapnp		= sisf_seg2/pob
	*gen		prop_seguro_privado		= sisf_seg3/pob
	gen		prop_seguro_sis2007		= seguro_sis/pob
	gen		prop_seguro_ninguno2007		= seguro_ninguno/pob	
	
	
*-----------------------*
*		Education		*
*-----------------------*

	gen		prop_lee_si2007		= lee_escribe_si/var163
	gen		prop_lee_no2007		= lee_escribe_no/var163

	gen		prop_educ_ninguno2007		= nivel_educ_ninguno/var172
	gen		prop_educ_inicial2007		= nivel_educ_inicial/var172
	gen		prop_educ_primaria2007		= nivel_educ_primaria/var172
	gen		prop_educ_secundaria2007	= nivel_educ_secundaria/var172
	gen		prop_educ_tec_incomp2007 	= nivel_educ_tec_incompleta/var172
	gen		prop_educ_tec_comp2007		= nivel_educ_tec_completa/var172
	gen		prop_educ_tecnica2007		= (nivel_educ_tec_incompleta + nivel_educ_tec_completa)/var172
	gen		prop_educ_univ_incomp2007	= nivel_educ_univ_incompleta/var172
	gen		prop_educ_univ_comp2007		= nivel_educ_univ_completa/var172
	gen		prop_educ_universitaria2007 = (nivel_educ_univ_incompleta + nivel_educ_univ_completa)/var172
	*gen		prop_educ_postgrado		= sisf_nivedu7/edad_15mas
	
*-----------------------------------------------*
*		Economic Activity and employment		*
*-----------------------------------------------*

	gen		prop_actividad_agricola2007		= actividad_agro/var227
	gen		prop_actividad_manufactura2007	= actividad_manufactura/var227
	gen		prop_actividad_elecgasagua2007	= actividad_elecgasagua/var227
	gen		prop_actividad_finanzas2007		= actividad_finanzas/var227
	gen		prop_actividad_turismo2007		= actividad_turismo/var227
	*gen		prop_actividad_pecuaria		= sisf_activ2/edad_15mas
	*gen		prop_actividad_forestal		= sisf_activ3/edad_15mas
	gen		prop_actividad_pesquera2007		= actividad_pesca/var227
	gen		prop_actividad_minera2007		= actividad_mineria/var227
	*gen		prop_actividad_artesanal	= sisf_activ6/edad_15mas
	gen		prop_actividad_comercial2007	= actividad_comercio/var227
	gen		prop_actividad_servicios2007	= actividad_servicios/var227
	*gen		prop_actividad_estatal		= sisf_activ10/edad_15mas

	gen		prop_pea_ocupada2007			= pea_activa_num/pob
	gen		prop_pea_desocupada2007			= pea_no_activa_num/pob
	gen		ratio_pea2007					= pea_activa_num/pea_no_activa_num
	
	
	rename pob pob_ccpp_2007
	rename hog hog_ccpp_2007
	rename viv_num viv_ccpp_2007
	rename urb_rur urb_rur_ccpp_2007
		
*-------------------------------------------------------*	
*		Generate a poverty indicator at CCPP level		*	
*-------------------------------------------------------*

*---------------------------*
*		Wall material		*
*---------------------------*	

	gen		poverty2007_pared = 0
	replace poverty2007_pared = (prop_pared_ladrillo2007*8 + prop_pared_piedra2007*7 + ///
								prop_pared_adobe2007*6 + prop_pared_quincha2007*5 + ///
								prop_pared_barro2007*4 + prop_pared_madera2007*3 + ///
								prop_pared_estera2007*2 + prop_pared_otro2007*1)/8
	
	gen		poverty2007_piso = 0
	replace poverty2007_piso = (prop_piso_parquet2007*7 + prop_piso_lamina2007*6 + ///
								prop_piso_loseta2007*5 + prop_piso_tabla2007*4 + ///
								prop_piso_cemento2007*3 + prop_piso_tierra2007*2 + ///
								prop_piso_otro2007*1)/7
	
	gen		poverty2007_agua = 0
	replace poverty2007_agua = (prop_agua_redpubdentro2007*8 + prop_agua_redpubfuera2007*7 + ///
								prop_agua_pilon2007*6 + prop_agua_cisterna2007*5 + ///
								prop_agua_pozo2007*4 + prop_agua_rio2007*3 + ///
								prop_agua_vecino2007*2 + prop_agua_otro2007*1)/8
								
	gen		poverty2007_saneamiento = 0
	replace poverty2007_saneamiento = (prop_saneamiento_redpubdentro07*6 + ///
								prop_saneamiento_redpubfuera07*5 + ///
								prop_saneamiento_pozo2007*4 + prop_saneamiento_letrina2007*3 + ///
								prop_saneamiento_rio2007*2 + prop_saneamiento_ninguno2007*1)/6
	

	gen		poverty2007_bienesriqueza = 0
	replace poverty2007_bienesriqueza = (prop_asset_lavadora2007 + prop_asset_refri2007 + ///
								prop_asset_compu2007 + prop_asset_internet2007 + prop_asset_cable2007)/5
	
	gen		poverty2007_combust = 0
	replace poverty2007_combust = (prop_combust_elect2007*8 + prop_combust_gas2007*7 + ///
								prop_combust_kerosene2007*6 + prop_combust_carbon2007*5 + ///
								prop_combust_lea2007*4 + prop_combust_bosta2007*3 + ///
								prop_combust_otro2007*2 + prop_combust_nococina2007*1)/8
	
	gen		poverty2007_seguro = 0
	replace poverty2007_seguro = 1 - prop_seguro_ninguno2007
	
	gen		poverty2007_analfabeta = 0
	replace poverty2007_analfabeta = prop_lee_si2007
	
	gen		poverty2007_educ = 0
	replace poverty2007_educ = (prop_educ_univ_comp2007*8 + prop_educ_univ_incomp2007*7 + ///
								prop_educ_tec_comp2007*6 + prop_educ_tec_incomp2007*5 + ///
								prop_educ_secundaria2007*4 + prop_educ_primaria2007*3 + ///
								prop_educ_inicial2007*2 + prop_educ_ninguno2007*1)/8
	
	gen		poverty2007_desempleo = 0
	replace poverty2007_desempleo = prop_pea_ocupada2007
	
	gen		poverty2007_alumbrado = 0
	replace poverty2007_alumbrado = alumbrado_redpub_si/var76
	
	egen		poverty2007_caracthh = rowmean(poverty2007_pared  poverty2007_piso poverty2007_combust poverty2007_bienesriqueza)
	egen		poverty2007_servpub = rowmean(poverty2007_agua poverty2007_saneamiento poverty2007_alumbrado)
	egen		poverty2007_demogra = rowmean(poverty2007_seguro poverty2007_analfabeta poverty2007_educ poverty2007_desempleo)

	egen		poverty2007 = rowmean(poverty2007_caracthh poverty2007_servpub poverty2007_demogra)
	
	
	keep ubigeo* dpto prov dist ccpp urb_rur_ccpp_2007 hog_ccpp_2007 			///
		pob_ccpp_2007 viv_ccpp_2007 dpto2 prov2 dist2 ccpp2 prop_pared_ladrillo2007-poverty2007
		
save "$input_dir\2 Working\censo2007_cleaned.dta", ///
	replace
