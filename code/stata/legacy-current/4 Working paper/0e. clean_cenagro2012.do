/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from CENGRO		|
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 11/1/2019				 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/


*----------------------------*
*      I. HUANCAVELICA       *
*----------------------------*	
{
*-----------------------------------------------------------------------*
*		Mod 229: Location and characteristics of production unit		*
*-----------------------------------------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo229\mod229.dta", clear
	
	drop if RESULTADO!=1 & RESULTADO!=2
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P017				lee_escribe
	rename P019				num_parc
	rename P020_01 			area_parc
	rename WSUP01			area_parc_categ
	rename WSUP03			area_agricola
	rename WSUP03A			area_agricola_riego
	rename WSUP03B			area_agricola_secano
	rename WSUP04			area_noagricola
	rename WSUP05			area_otro
	rename WSUP18			area_cultivada
	rename WP109			tamano_hogar
	rename WP111			sexo_productor
	rename WP112			edad_productor
	rename WP114			educ_productor
	rename WALTITUD			altitud_msnm
	rename LONG_DECI		longitude
	rename LAT_DECI			latitude
	
	
	replace num_parc = 0 if P019_01==1
	
	keep ubigeo* TIPO_REC P007X P008 NPRIN P016 lee_escribe num_parc area_parc area_parc_categ area_agricola area_agricola_riego area_agricola_secano area_noagricola area_otro area_cultivada tamano_hogar sexo_productor edad_productor educ_productor altitud_msnm longitude latitude
	
	gen		area_prom = area_parc / num_parc
	
	
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod229_huancavelica.dta",  replace
	
*-------------------------------------------------------*
*		Mod 231: Land use, production destination		*
*-------------------------------------------------------*	
	
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo231\mod231.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P025		area_sembrada
	gen		riego = 0
	replace riego = 0 if P026 == 2
	replace riego = 1 if P026 == 1
	gen		secano = 0
	replace secano = 0 if P026 == 1
	replace secano = 1 if P026 == 2	
	gen		riego_gravedad = 0
	replace riego_gravedad = 1 if P027 == 1
	gen		riego_aspersion = 0
	replace riego_aspersion = 1 if P027 == 2
	gen		destinoprod_venta = 0
	replace destinoprod_venta = 1 if P028 == 1
	gen		destinoprod_autoconsumo = 0 
	replace destinoprod_autoconsumo = 1 if P028 == 2 | P028 == 3 | P028 == 4
	
	gen		num_cultivos = 1 if P024_01 <=7
	
	collapse (firstnm) ubigeo* P007X P008 (sum) area_sembrada cultivo_riego=riego cultivo_secano=secano riego_gravedad riego_aspersion destinoprod* num_cultivos (max) NPARCX, by(NPRIN)
	
	gen		cultivos_prom = num_cultivos / NPARCX
	
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod231_huancavelica.dta",  replace
	
	
*-----------------------------------*
*		Mod 231: Land ownership		*
*-----------------------------------*	
	
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo232\mod232.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		propietario = 0
	replace propietario = 1 if P037_01_01==1
	
	gen		titulo_propiedad = 0
	replace titulo_propiedad = 1 if P037_01_03==1 | P037_01_03==2
	
	collapse (firstnm) ubigeo* P007X P008 (max) NPARCY (sum) num_parc_propias=propietario num_titulo_propiedad=titulo_propiedad, by(NPRIN)
	
	gen		parc_propias_1 = 0
	replace parc_propias_1 = 1 if num_parc_propias>0
	
	gen		prop_parc_propias = num_parc_propias / NPARCY
	
	gen		titulo_propiedad_1 = 0
	replace titulo_propiedad_1 = 1 if num_titulo_propiedad>0
	
	gen		prop_parc_titulo = num_titulo_propiedad / NPARCY
	
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod232_huancavelica.dta",  replace

*-----------------------------------------------------------------------------------*
*		Mod 235: Irrigation, agricultural practices, use of energy and livestock	*
*-----------------------------------------------------------------------------------*		
	
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo235\mod235.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first	
	
	recode P049 (3=0) (2=0)
	rename P049			pertenece_comision_regantes
	recode P_RIEGO (2=0)
	rename P_RIEGO		parc_riego_1
	
	gen		riego_fuente_reservorio = 0
	replace riego_fuente_reservorio = 1 if P045_05==1 | P045_06==1
	gen		riego_canales_revestidos = 0
	replace riego_canales_revestidos = 1 if  P048==1
	gen		derecho_usoagua = 0
	replace derecho_usoagua = 1 if P050==1 | P050==2 | P050==3
	
	gen		usa_semilla_certif = 0
	replace usa_semilla_certif = 1 if P051 == 1

	gen		usa_fertilizante_org = 0
	replace usa_fertilizante_org = 1 if P052 == 1 | P052 == 2
	gen		usa_fertilizante_quim = 0
	replace usa_fertilizante_quim = 1 if P053 == 1 | P053 == 2
	
	gen		usa_insecticida_quim = 0
	replace usa_insecticida_quim = 1 if P054_01 == 1
	gen		usa_insecticida_noquim = 0
	replace usa_insecticida_noquim = 1 if P054_02 == 1
	gen		usa_herbicida = 0
	replace usa_herbicida = 1 if P054_03 == 1
	gen		usa_fungicida = 0
	replace usa_fungicida = 1 if P054_04 == 1	
	
	gen		usa_controlbio = 0
	replace usa_controlbio = 1 if P056 == 1	
	
	gen		usa_animales_trabajo = 0
	replace usa_animales_trabajo = 1 if P061 == 1
	gen		usa_tractores_trabajo = 0
	replace usa_tractores_trabajo = 1 if P063 == 1
	
	gen		usa_aradohierro = 0
	replace usa_aradohierro = 1 if P065_01_01 == 1
	gen		usa_aradopalo = 0
	replace usa_aradopalo = 1 if P065_02_01 == 1
	gen		usa_cosechadora = 0
	replace usa_cosechadora = 1 if P065_03_01 == 1
	gen		usa_chaquitaclla = 0
	replace usa_chaquitaclla = 1 if P065_04_01 == 1
	gen		usa_fumigadoramotor = 0
	replace usa_fumigadoramotor = 1 if P065_05_01 == 1
	gen		usa_fumigadoramanual = 0
	replace usa_fumigadoramanual = 1 if P065_06_01 == 1
	gen		usa_molino = 0
	replace usa_molino = 1 if P065_07_01 == 1
	gen		usa_picadorapasto = 0
	replace usa_picadorapasto = 1 if P065_08_01 == 1
	gen		usa_trilladora = 0
	replace usa_trilladora = 1 if P065_09_01 == 1
	gen		usa_bombapozo = 0
	replace usa_bombapozo = 1 if P065_10_01 == 1
	gen		usa_motorbombeo = 0
	replace usa_motorbombeo = 1 if P065_11_01 == 1
	
	gen 	tiene_vacuno = 0
	replace tiene_vacuno = 1 if P066 == 1
	gen		num_vacuno = P066_01
	replace num_vacuno = 0 if tiene_vacuno == 0
	gen		tiene_ovino = 0
	replace tiene_ovino = 1 if P069 == 1
	gen		num_ovino = P069_01
	replace num_ovino = 0 if tiene_ovino == 0
	gen		tiene_porcino = 0
	replace tiene_porcino = 1 if P071 == 1
	gen		num_porcino = P071_01
	replace num_porcino = 0 if tiene_porcino == 0
	gen		tiene_alpaca = 0
	replace tiene_alpaca = 1 if P073 == 1 
	gen		num_alpaca = P073_01
	replace num_alpaca = 0 if tiene_alpaca == 0
	
	keep ubigeo* P007X P008 NPRIN parc_riego_1 pertenece_comision_regantes riego_fuente_reservorio riego_canales_revestidos derecho_usoagua usa_semilla_certif usa_fertilizante_org usa_fertilizante_quim usa_insecticida_quim usa_insecticida_noquim usa_herbicida usa_fungicida usa_controlbio usa_animales_trabajo usa_tractores_trabajo usa_aradohierro usa_aradopalo usa_cosechadora usa_chaquitaclla usa_fumigadoramotor usa_fumigadoramanual usa_molino usa_picadorapasto usa_trilladora usa_bombapozo usa_motorbombeo tiene_vacuno num_vacuno tiene_ovino num_ovino tiene_porcino num_porcino tiene_alpaca num_alpaca
	
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod235_huancavelica.dta",  replace

*-------------------------------------------------------------------------------*
*		Mod 237: Livestock characteristics, technical assistance, finance,		*	
*				employment, infrastructure, associativity and perceptions		*
*-------------------------------------------------------------------------------*		
	
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo237\mod237.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		ganaderia = 0
	replace ganaderia = 1 if P_PEC == 1

	gen		vacuna = 0 if P079 == 2
	replace vacuna = 1 if P079 == 1
	gen		desparasita = 0 if P080 == 2
	replace desparasita = 1 if P080 == 1
	gen		dosificaciones = 0 if P081 == 2
	replace dosificaciones = 1 if P081 == 1
	gen		alimentos_balanceados = 0 if P082 == 2
	replace alimentos_balanceados = 1 if P082 == 1
	gen		inseminacion_artificial = 0 if P083 == 2
	replace inseminacion_artificial = 1 if P083 == 1

	gen		recibio_capacitacion = 0
	replace recibio_capacitacion = 1 if P086_01 == 1
	gen		recibio_asistenciatec = 0
	replace recibio_asistenciatec = 1 if P086_02 == 1
	gen		recibio_asesoriaempre = 0
	replace recibio_asesoriaempre = 1 if P086_03 == 1
	
	gen		capacitacion_cultivos = 0
	replace capacitacion_cultivos = 1 if P087_01 == 1
	gen		capacitacion_ganaderia = 0
	replace capacitacion_ganaderia = 1 if P087_02 == 1	
	gen		capacitacion_manejo = 0
	replace capacitacion_manejo = 1 if P087_03 == 1	
	gen		capacitacion_produccion = 0
	replace capacitacion_produccion = 1 if P087_04 == 1	
	gen		capacitacion_negocios = 0
	replace capacitacion_negocios = 1 if P087_05 == 1	
	
	gen		recibio_cap_minagri = 0
	replace recibio_cap_minagri = 1 if P088_01 == 1
	gen		recibio_cap_progsierranorte = 0
	replace recibio_cap_progsierranorte = 1 if P088_02 == 1
	gen		recibio_cap_progsierrasur = 0
	replace recibio_cap_progsierrasur = 1 if P088_03 == 1	
	gen		recibio_cap_progaliados = 0
	replace recibio_cap_progaliados = 1 if P088_04 == 1		
	gen		recibio_cap_progpsi = 0
	replace recibio_cap_progpsi = 1 if P088_05 == 1	
	gen		recibio_cap_agrorural = 0
	replace recibio_cap_agrorural = 1 if P088_06 == 1		
	gen		recibio_cap_inia = 0
	replace recibio_cap_inia = 1 if P088_07 == 1		
	gen		recibio_cap_senasa = 0
	replace recibio_cap_senasa = 1 if P088_08 == 1
	gen		recibio_cap_gobregional = 0
	replace recibio_cap_gobregional = 1 if P088_09 == 1	
	gen		recibio_cap_dra = 0
	replace recibio_cap_dra = 1 if P088_10 == 1	
	gen		recibio_cap_ageagraria = 0
	replace recibio_cap_ageagraria = 1 if P088_11 == 1
	gen		recibio_cap_municipalidad = 0
	replace recibio_cap_municipalidad = 1 if P088_12 == 1	
	gen		recibio_cap_asocproductores = 0
	replace recibio_cap_asocproductores = 1 if P088_13 == 1	
	gen		recibio_cap_eprivada = 0
	replace recibio_cap_eprivada = 1 if P088_14 == 1	
	gen		recibio_cap_ong = 0
	replace recibio_cap_ong = 1 if P088_15 == 1
	
	egen	cap_estatal = rowtotal(recibio_cap_minagri recibio_cap_progsierranorte recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria recibio_cap_municipalidad)
	gen		recibio_cap_estatal = 0
	replace recibio_cap_estatal = 1 if cap_estatal>0
	drop cap_estatal
	gen		recibio_cap_privada = 0
	replace recibio_cap_privada = 1 if recibio_cap_asocproductores==1 | recibio_cap_eprivada==1 | recibio_cap_ong==1
	
	gen		obtuvo_prestamo = 0
	replace obtuvo_prestamo = 1 if P092 == 1
	
	gen		prestamo_comerciante = 0
	replace prestamo_comerciante = 1 if P093_01 == 1
	gen		prestamo_habilitador = 0
	replace prestamo_habilitador = 1 if P093_02 == 1
	gen		prestamo_agrobanco = 0
	replace prestamo_agrobanco = 1 if P093_03 == 1
	gen		prestamo_banco = 0
	replace prestamo_banco = 1 if P093_04 == 1
	gen		prestamo_cmac = 0
	replace prestamo_cmac = 1 if P093_05 == 1	
	gen		prestamo_cooperativa = 0
	replace prestamo_cooperativa = 1 if P093_06 == 1
	gen		prestamo_crac = 0
	replace prestamo_crac = 1 if P093_07 == 1
	gen		prestamo_ong = 0
	replace prestamo_ong = 1 if P093_09 == 1
	gen		prestamo_empresatextil = 0
	replace prestamo_empresatextil = 1 if P093_10 == 1
	gen		prestamo_prestamista = 0
	replace prestamo_prestamista = 1 if P093_11 == 1
	gen		prestamo_edpyme = 0
	replace prestamo_edpyme = 1 if P093_12 == 1

	gen		uso_prestamo_insumos = 0
	replace uso_prestamo_insumos = 1 if P094_01 == 1
	gen		uso_prestamo_maquinaria = 0
	replace uso_prestamo_maquinaria = 1 if P094_02 == 1	
	gen		uso_prestamo_herramientas = 0
	replace uso_prestamo_herramientas = 1 if P094_03 == 1	
	gen		uso_prestamo_venta = 0
	replace uso_prestamo_venta = 1 if P094_04 == 1	
	gen		uso_prestamo_compraganado = 0
	replace uso_prestamo_compraganado = 1 if P094_06 == 1	
	gen		uso_prestamo_infraestructura = 0
	replace uso_prestamo_infraestructura = 1 if P094_07 == 1	
	gen		uso_prestamo_salarios = 0
	replace uso_prestamo_salarios = 1 if P094_08 == 1		
	
	gen		tiene_trab_remunerados = 0
	replace tiene_trab_remunerados = 1 if P098 == 1
	
	egen	total_trab_mujeres = rowtotal(P099_01_03 P099_02_03)
	egen	total_trab_hombres = rowtotal(P099_01_02 P099_02_02)

	gen		tiene_trab_mujeres = 0
	replace tiene_trab_mujeres = 1 if total_trab_mujeres>0
	
	gen		pertenece_asociacion = 0
	replace pertenece_asociacion = 1 if P101 == 1
	
	gen		beneficio_asociacion_1 = 0
	replace beneficio_asociacion_1 = 1 if P103_07 != 1 & pertenece_asociacion == 1
	
	gen		ingresos_agro_suficiente = 0
	replace ingresos_agro_suficiente = 1 if P106 == 1
	
	
	keep ubigeo* P007X P008 NPRIN ganaderia vacuna desparasita dosificaciones 	///
	alimentos_balanceados inseminacion_artificial recibio_capacitacion 			///
	recibio_asistenciatec recibio_asesoriaempre capacitacion_cultivos 			///
	capacitacion_ganaderia capacitacion_manejo capacitacion_produccion 			///
	capacitacion_negocios recibio_cap_minagri recibio_cap_progsierranorte 		///
	recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi 		///
	recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa 					///
	recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria 				///
	recibio_cap_municipalidad recibio_cap_asocproductores recibio_cap_eprivada 	///
	recibio_cap_ong recibio_cap_estatal recibio_cap_privada obtuvo_prestamo 	///
	prestamo_comerciante prestamo_habilitador prestamo_agrobanco prestamo_banco ///
	prestamo_cmac prestamo_cooperativa prestamo_crac prestamo_ong 				///
	prestamo_empresatextil prestamo_prestamista prestamo_edpyme 				///
	uso_prestamo_insumos uso_prestamo_maquinaria uso_prestamo_herramientas 		///
	uso_prestamo_venta uso_prestamo_compraganado uso_prestamo_infraestructura 	///
	uso_prestamo_salarios tiene_trab_remunerados total_trab* tiene_trab* 		///
	pertenece_asociacion beneficio_asociacion_1 ingresos_agro_suficiente
	
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod237_huancavelica.dta",  replace
	
	
*-----------------------------------*
*		Mod 238: Demographics		*
*-----------------------------------*		
	
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo238\mod238.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		participa_agricola = 0
	replace participa_agricola = 1 if P116 == 1 | P110 == 1
	
	gen		sexo = 0
	replace sexo = 1 if P111 == 2
	
	gen		num_perso = 1
	
	gen		edad_6_12 = 0
	replace edad_6_12 = 1 if P112>=6 & P112<=12
	
	gen		edad_6_12_trabaja = 0
	replace edad_6_12_trabaja = 1 if edad_6_12 == 1 & participa_agricola == 1
	
	collapse (firstnm) ubigeo* P007X P008 (sum) edad_6_12_trabaja participa_agricola num_perso (mean) sexo edad_promedio=P112 educ_promedio=P114, by(NPRIN)
	
	gen		edad_6_12_trabaja_1 = 0
	replace edad_6_12_trabaja_1 = 1 if edad_6_12_trabaja>0
	drop edad_6_12_trabaja
	
	gen		prop_participa_agricola = participa_agricola/num_perso
	drop num_perso
	
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod238_huancavelica.dta",  replace

*-----------------------------------------------*
*		Mod 239: Household characteristics		*
*-----------------------------------------------*		
	
use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\345-Modulo239\mod239.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		benef_juntos = 0
	replace benef_juntos = 1 if P117_01 == 1
	gen		benef_vasoleche = 0
	replace benef_vasoleche = 1 if P117_02== 1	
	gen		benef_desalm = 0
	replace benef_desalm = 1 if P117_03 == 1	
	gen		benef_cunamas = 0
	replace benef_cunamas = 1 if P117_04 == 1
	gen		benef_bonograt = 0
	replace benef_bonograt = 1 if P117_05 == 1	
	gen		benef_otro = 0
	replace benef_otro = 1 if P117_06 == 1	
	
	egen	num_prog_benef = rowtotal(benef*)
	gen		benef_1 = 0
	replace benef_1 = 1 if num_prog_benef>0
	
	gen		hogar_tiene_desague = 0
	replace hogar_tiene_desague = 1 if P118!=7
	gen		hogar_desague_redpubdentro = 0
	replace hogar_desague_redpubdentro = 1 if P118 == 1
	gen		hogar_desague_redpubfuera = 0
	replace hogar_desague_redpubfuera = 1 if P118 == 2
	gen		hogar_desague_pozo = 0
	replace hogar_desague_pozo = 1 if P118 == 3
	gen		hogar_desague_letrina = 0
	replace hogar_desague_letrina = 1 if P118 == 4
	gen		hogar_desague_rio = 0
	replace hogar_desague_rio = 1 if P118 == 5

	gen		tiene_cocinamejorada = 0
	replace tiene_cocinamejorada = 1 if P119 == 1
	
	gen		horas_capital = P121
	replace horas_capital = 24 if P121_01 == 1
	replace horas_capital = 0 if P121_01 == 2
	
	keep ubigeo* P007X P008 NPRIN benef_juntos benef_vasoleche benef_desalm benef_cunamas benef_bonograt benef_otro num_prog_benef benef_1 hogar_tiene_desague hogar_desague_redpubdentro hogar_desague_redpubfuera hogar_desague_pozo hogar_desague_letrina hogar_desague_rio tiene_cocinamejorada horas_capital
save "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod239_huancavelica.dta",  replace
	
*---------------------------------------*
*		Merge Huancavelica datasets		*	
*---------------------------------------*

use "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod229_huancavelica.dta", clear

merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod231_huancavelica.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod232_huancavelica.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod235_huancavelica.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod237_huancavelica.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod238_huancavelica.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\1 Huancavelica\mod239_huancavelica.dta"

drop _merge

save "$input_dir\1 Raw\4 Cenagro\cenagro_huancavelica.dta",  replace

}
*-----------------------*
*      II. APURIMAC		*
*-----------------------*	
{	
*-----------------------------------------------------------------------*
*		Mod 229: Location and characteristics of production unit		*
*-----------------------------------------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo229\mod229.dta", clear
	
	drop if RESULTADO!=1 & RESULTADO!=2
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P017				lee_escribe
	rename P019				num_parc
	rename P020_01 			area_parc
	rename WSUP01			area_parc_categ
	rename WSUP03			area_agricola
	rename WSUP03A			area_agricola_riego
	rename WSUP03B			area_agricola_secano
	rename WSUP04			area_noagricola
	rename WSUP05			area_otro
	rename WSUP18			area_cultivada
	rename WP109			tamano_hogar
	rename WP111			sexo_productor
	rename WP112			edad_productor
	rename WP114			educ_productor
	rename WALTITUD			altitud_msnm
	rename LONG_DECI		longitude
	rename LAT_DECI			latitude
	
	
	replace num_parc = 0 if P019_01==1
	
	keep ubigeo* TIPO_REC P007X P008 NPRIN P016 lee_escribe num_parc area_parc area_parc_categ area_agricola area_agricola_riego area_agricola_secano area_noagricola area_otro area_cultivada tamano_hogar sexo_productor edad_productor educ_productor altitud_msnm longitude latitude
	
	bys NPRIN: gen a=_n
	drop if a>1
	
	gen		area_prom = area_parc / num_parc
	
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod229_apurimac.dta",  replace
	
*-------------------------------------------------------*
*		Mod 231: Land use, production destination		*
*-------------------------------------------------------*	
	
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo231\mod231.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P025		area_sembrada
	gen		riego = 0
	replace riego = 0 if P026 == 2
	replace riego = 1 if P026 == 1
	gen		secano = 0
	replace secano = 0 if P026 == 1
	replace secano = 1 if P026 == 2	
	gen		riego_gravedad = 0
	replace riego_gravedad = 1 if P027 == 1
	gen		riego_aspersion = 0
	replace riego_aspersion = 1 if P027 == 2
	gen		destinoprod_venta = 0
	replace destinoprod_venta = 1 if P028 == 1
	gen		destinoprod_autoconsumo = 0 
	replace destinoprod_autoconsumo = 1 if P028 == 2 | P028 == 3 | P028 == 4
	
	gen		num_cultivos = 1 if P024_01 <=7
	
	collapse (firstnm) ubigeo* P007X P008 (sum) area_sembrada cultivo_riego=riego cultivo_secano=secano riego_gravedad riego_aspersion destinoprod* num_cultivos (max) NPARCX, by(NPRIN)
	
	gen		cultivos_prom = num_cultivos / NPARCX
	
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod231_apurimac.dta",  replace
	
*-----------------------------------*
*		Mod 231: Land ownership		*
*-----------------------------------*	
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo232\mod232.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		propietario = 0
	replace propietario = 1 if P037_01_01==1
	
	gen		titulo_propiedad = 0
	replace titulo_propiedad = 1 if P037_01_03==1 | P037_01_03==2
	
	collapse (firstnm) ubigeo* P007X P008 (max) NPARCY (sum) num_parc_propias=propietario num_titulo_propiedad=titulo_propiedad, by(NPRIN)
	
	gen		parc_propias_1 = 0
	replace parc_propias_1 = 1 if num_parc_propias>0
	
	gen		prop_parc_propias = num_parc_propias / NPARCY
	
	gen		titulo_propiedad_1 = 0
	replace titulo_propiedad_1 = 1 if num_titulo_propiedad>0
	
	gen		prop_parc_titulo = num_titulo_propiedad / NPARCY
	
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod232_apurimac.dta",  replace

*-----------------------------------------------------------------------------------*
*		Mod 235: Irrigation, agricultural practices, use of energy and livestock	*
*-----------------------------------------------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo235\mod235.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first	
	
	recode P049 (3=0) (2=0)
	rename P049			pertenece_comision_regantes
	recode P_RIEGO (2=0)
	rename P_RIEGO		parc_riego_1
	
	gen		riego_fuente_reservorio = 0
	replace riego_fuente_reservorio = 1 if P045_05==1 | P045_06==1
	gen		riego_canales_revestidos = 0
	replace riego_canales_revestidos = 1 if  P048==1
	gen		derecho_usoagua = 0
	replace derecho_usoagua = 1 if P050==1 | P050==2 | P050==3
	
	gen		usa_semilla_certif = 0
	replace usa_semilla_certif = 1 if P051 == 1

	gen		usa_fertilizante_org = 0
	replace usa_fertilizante_org = 1 if P052 == 1 | P052 == 2
	gen		usa_fertilizante_quim = 0
	replace usa_fertilizante_quim = 1 if P053 == 1 | P053 == 2
	
	gen		usa_insecticida_quim = 0
	replace usa_insecticida_quim = 1 if P054_01 == 1
	gen		usa_insecticida_noquim = 0
	replace usa_insecticida_noquim = 1 if P054_02 == 1
	gen		usa_herbicida = 0
	replace usa_herbicida = 1 if P054_03 == 1
	gen		usa_fungicida = 0
	replace usa_fungicida = 1 if P054_04 == 1	
	
	gen		usa_controlbio = 0
	replace usa_controlbio = 1 if P056 == 1	
	
	gen		usa_animales_trabajo = 0
	replace usa_animales_trabajo = 1 if P061 == 1
	gen		usa_tractores_trabajo = 0
	replace usa_tractores_trabajo = 1 if P063 == 1
	
	gen		usa_aradohierro = 0
	replace usa_aradohierro = 1 if P065_01_01 == 1
	gen		usa_aradopalo = 0
	replace usa_aradopalo = 1 if P065_02_01 == 1
	gen		usa_cosechadora = 0
	replace usa_cosechadora = 1 if P065_03_01 == 1
	gen		usa_chaquitaclla = 0
	replace usa_chaquitaclla = 1 if P065_04_01 == 1
	gen		usa_fumigadoramotor = 0
	replace usa_fumigadoramotor = 1 if P065_05_01 == 1
	gen		usa_fumigadoramanual = 0
	replace usa_fumigadoramanual = 1 if P065_06_01 == 1
	gen		usa_molino = 0
	replace usa_molino = 1 if P065_07_01 == 1
	gen		usa_picadorapasto = 0
	replace usa_picadorapasto = 1 if P065_08_01 == 1
	gen		usa_trilladora = 0
	replace usa_trilladora = 1 if P065_09_01 == 1
	gen		usa_bombapozo = 0
	replace usa_bombapozo = 1 if P065_10_01 == 1
	gen		usa_motorbombeo = 0
	replace usa_motorbombeo = 1 if P065_11_01 == 1
	
	gen 	tiene_vacuno = 0
	replace tiene_vacuno = 1 if P066 == 1
	gen		num_vacuno = P066_01
	replace num_vacuno = 0 if tiene_vacuno == 0
	gen		tiene_ovino = 0
	replace tiene_ovino = 1 if P069 == 1
	gen		num_ovino = P069_01
	replace num_ovino = 0 if tiene_ovino == 0
	gen		tiene_porcino = 0
	replace tiene_porcino = 1 if P071 == 1
	gen		num_porcino = P071_01
	replace num_porcino = 0 if tiene_porcino == 0
	gen		tiene_alpaca = 0
	replace tiene_alpaca = 1 if P073 == 1 
	gen		num_alpaca = P073_01
	replace num_alpaca = 0 if tiene_alpaca == 0
	
	keep ubigeo* P007X P008 NPRIN parc_riego_1 pertenece_comision_regantes riego_fuente_reservorio riego_canales_revestidos derecho_usoagua usa_semilla_certif usa_fertilizante_org usa_fertilizante_quim usa_insecticida_quim usa_insecticida_noquim usa_herbicida usa_fungicida usa_controlbio usa_animales_trabajo usa_tractores_trabajo usa_aradohierro usa_aradopalo usa_cosechadora usa_chaquitaclla usa_fumigadoramotor usa_fumigadoramanual usa_molino usa_picadorapasto usa_trilladora usa_bombapozo usa_motorbombeo tiene_vacuno num_vacuno tiene_ovino num_ovino tiene_porcino num_porcino tiene_alpaca num_alpaca
	bys NPRIN: gen a=_n
	drop if a>1
	
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod235_apurimac.dta",  replace

*-------------------------------------------------------------------------------*
*		Mod 237: Livestock characteristics, technical assistance, finance,		*	
*				employment, infrastructure, associativity and perceptions		*
*-------------------------------------------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo237\mod237.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		ganaderia = 0
	replace ganaderia = 1 if P_PEC == 1

	gen		vacuna = 0 if P079 == 2
	replace vacuna = 1 if P079 == 1
	gen		desparasita = 0 if P080 == 2
	replace desparasita = 1 if P080 == 1
	gen		dosificaciones = 0 if P081 == 2
	replace dosificaciones = 1 if P081 == 1
	gen		alimentos_balanceados = 0 if P082 == 2
	replace alimentos_balanceados = 1 if P082 == 1
	gen		inseminacion_artificial = 0 if P083 == 2
	replace inseminacion_artificial = 1 if P083 == 1

	gen		recibio_capacitacion = 0
	replace recibio_capacitacion = 1 if P086_01 == 1
	gen		recibio_asistenciatec = 0
	replace recibio_asistenciatec = 1 if P086_02 == 1
	gen		recibio_asesoriaempre = 0
	replace recibio_asesoriaempre = 1 if P086_03 == 1
	
	gen		capacitacion_cultivos = 0
	replace capacitacion_cultivos = 1 if P087_01 == 1
	gen		capacitacion_ganaderia = 0
	replace capacitacion_ganaderia = 1 if P087_02 == 1	
	gen		capacitacion_manejo = 0
	replace capacitacion_manejo = 1 if P087_03 == 1	
	gen		capacitacion_produccion = 0
	replace capacitacion_produccion = 1 if P087_04 == 1	
	gen		capacitacion_negocios = 0
	replace capacitacion_negocios = 1 if P087_05 == 1	
	
	gen		recibio_cap_minagri = 0
	replace recibio_cap_minagri = 1 if P088_01 == 1
	gen		recibio_cap_progsierranorte = 0
	replace recibio_cap_progsierranorte = 1 if P088_02 == 1
	gen		recibio_cap_progsierrasur = 0
	replace recibio_cap_progsierrasur = 1 if P088_03 == 1	
	gen		recibio_cap_progaliados = 0
	replace recibio_cap_progaliados = 1 if P088_04 == 1		
	gen		recibio_cap_progpsi = 0
	replace recibio_cap_progpsi = 1 if P088_05 == 1	
	gen		recibio_cap_agrorural = 0
	replace recibio_cap_agrorural = 1 if P088_06 == 1		
	gen		recibio_cap_inia = 0
	replace recibio_cap_inia = 1 if P088_07 == 1		
	gen		recibio_cap_senasa = 0
	replace recibio_cap_senasa = 1 if P088_08 == 1
	gen		recibio_cap_gobregional = 0
	replace recibio_cap_gobregional = 1 if P088_09 == 1	
	gen		recibio_cap_dra = 0
	replace recibio_cap_dra = 1 if P088_10 == 1	
	gen		recibio_cap_ageagraria = 0
	replace recibio_cap_ageagraria = 1 if P088_11 == 1
	gen		recibio_cap_municipalidad = 0
	replace recibio_cap_municipalidad = 1 if P088_12 == 1	
	gen		recibio_cap_asocproductores = 0
	replace recibio_cap_asocproductores = 1 if P088_13 == 1	
	gen		recibio_cap_eprivada = 0
	replace recibio_cap_eprivada = 1 if P088_14 == 1	
	gen		recibio_cap_ong = 0
	replace recibio_cap_ong = 1 if P088_15 == 1
	
	egen	cap_estatal = rowtotal(recibio_cap_minagri recibio_cap_progsierranorte recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria recibio_cap_municipalidad)
	gen		recibio_cap_estatal = 0
	replace recibio_cap_estatal = 1 if cap_estatal>0
	drop cap_estatal
	gen		recibio_cap_privada = 0
	replace recibio_cap_privada = 1 if recibio_cap_asocproductores==1 | recibio_cap_eprivada==1 | recibio_cap_ong==1
	
	gen		obtuvo_prestamo = 0
	replace obtuvo_prestamo = 1 if P092 == 1
	
	gen		prestamo_comerciante = 0
	replace prestamo_comerciante = 1 if P093_01 == 1
	gen		prestamo_habilitador = 0
	replace prestamo_habilitador = 1 if P093_02 == 1
	gen		prestamo_agrobanco = 0
	replace prestamo_agrobanco = 1 if P093_03 == 1
	gen		prestamo_banco = 0
	replace prestamo_banco = 1 if P093_04 == 1
	gen		prestamo_cmac = 0
	replace prestamo_cmac = 1 if P093_05 == 1	
	gen		prestamo_cooperativa = 0
	replace prestamo_cooperativa = 1 if P093_06 == 1
	gen		prestamo_crac = 0
	replace prestamo_crac = 1 if P093_07 == 1
	gen		prestamo_ong = 0
	replace prestamo_ong = 1 if P093_09 == 1
	gen		prestamo_empresatextil = 0
	replace prestamo_empresatextil = 1 if P093_10 == 1
	gen		prestamo_prestamista = 0
	replace prestamo_prestamista = 1 if P093_11 == 1
	gen		prestamo_edpyme = 0
	replace prestamo_edpyme = 1 if P093_12 == 1

	gen		uso_prestamo_insumos = 0
	replace uso_prestamo_insumos = 1 if P094_01 == 1
	gen		uso_prestamo_maquinaria = 0
	replace uso_prestamo_maquinaria = 1 if P094_02 == 1	
	gen		uso_prestamo_herramientas = 0
	replace uso_prestamo_herramientas = 1 if P094_03 == 1	
	gen		uso_prestamo_venta = 0
	replace uso_prestamo_venta = 1 if P094_04 == 1	
	gen		uso_prestamo_compraganado = 0
	replace uso_prestamo_compraganado = 1 if P094_06 == 1	
	gen		uso_prestamo_infraestructura = 0
	replace uso_prestamo_infraestructura = 1 if P094_07 == 1	
	gen		uso_prestamo_salarios = 0
	replace uso_prestamo_salarios = 1 if P094_08 == 1		
	
	gen		tiene_trab_remunerados = 0
	replace tiene_trab_remunerados = 1 if P098 == 1
	
	egen	total_trab_mujeres = rowtotal(P099_01_03 P099_02_03)
	egen	total_trab_hombres = rowtotal(P099_01_02 P099_02_02)

	gen		tiene_trab_mujeres = 0
	replace tiene_trab_mujeres = 1 if total_trab_mujeres>0
	
	gen		pertenece_asociacion = 0
	replace pertenece_asociacion = 1 if P101 == 1
	
	gen		beneficio_asociacion_1 = 0
	replace beneficio_asociacion_1 = 1 if P103_07 != 1 & pertenece_asociacion == 1
	
	gen		ingresos_agro_suficiente = 0
	replace ingresos_agro_suficiente = 1 if P106 == 1
	
	
	keep ubigeo* P007X P008 NPRIN ganaderia vacuna desparasita dosificaciones 	///
	alimentos_balanceados inseminacion_artificial recibio_capacitacion 			///
	recibio_asistenciatec recibio_asesoriaempre capacitacion_cultivos 			///
	capacitacion_ganaderia capacitacion_manejo capacitacion_produccion 			///
	capacitacion_negocios recibio_cap_minagri recibio_cap_progsierranorte 		///
	recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi 		///
	recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa 					///
	recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria 				///
	recibio_cap_municipalidad recibio_cap_asocproductores recibio_cap_eprivada 	///
	recibio_cap_ong recibio_cap_estatal recibio_cap_privada obtuvo_prestamo 	///
	prestamo_comerciante prestamo_habilitador prestamo_agrobanco prestamo_banco ///
	prestamo_cmac prestamo_cooperativa prestamo_crac prestamo_ong 				///
	prestamo_empresatextil prestamo_prestamista prestamo_edpyme 				///
	uso_prestamo_insumos uso_prestamo_maquinaria uso_prestamo_herramientas 		///
	uso_prestamo_venta uso_prestamo_compraganado uso_prestamo_infraestructura 	///
	uso_prestamo_salarios tiene_trab_remunerados total_trab* tiene_trab* 		///
	pertenece_asociacion beneficio_asociacion_1 ingresos_agro_suficiente
	
	bys NPRIN: gen a=_n
	drop if a>1
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod237_apurimac.dta",  replace

*-----------------------------------*
*		Mod 238: Demographics		*
*-----------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo238\mod238.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		participa_agricola = 0
	replace participa_agricola = 1 if P116 == 1 | P110 == 1
	
	gen		sexo = 0
	replace sexo = 1 if P111 == 2
	
	gen		num_perso = 1
	
	gen		edad_6_12 = 0
	replace edad_6_12 = 1 if P112>=6 & P112<=12
	
	gen		edad_6_12_trabaja = 0
	replace edad_6_12_trabaja = 1 if edad_6_12 == 1 & participa_agricola == 1
	
	collapse (firstnm) ubigeo* P007X P008 (sum) edad_6_12_trabaja participa_agricola num_perso (mean) sexo edad_promedio=P112 educ_promedio=P114, by(NPRIN)
	
	gen		edad_6_12_trabaja_1 = 0
	replace edad_6_12_trabaja_1 = 1 if edad_6_12_trabaja>0
	drop edad_6_12_trabaja
	
	gen		prop_participa_agricola = participa_agricola/num_perso
	drop num_perso
	
	bys NPRIN: gen a=_n
	drop if a>1
	
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod238_apurimac.dta",  replace

*-----------------------------------------------*
*		Mod 239: Household characteristics		*
*-----------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\339-Modulo239\mod239.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		benef_juntos = 0
	replace benef_juntos = 1 if P117_01 == 1
	gen		benef_vasoleche = 0
	replace benef_vasoleche = 1 if P117_02== 1	
	gen		benef_desalm = 0
	replace benef_desalm = 1 if P117_03 == 1	
	gen		benef_cunamas = 0
	replace benef_cunamas = 1 if P117_04 == 1
	gen		benef_bonograt = 0
	replace benef_bonograt = 1 if P117_05 == 1	
	gen		benef_otro = 0
	replace benef_otro = 1 if P117_06 == 1	
	
	egen	num_prog_benef = rowtotal(benef*)
	gen		benef_1 = 0
	replace benef_1 = 1 if num_prog_benef>0
	
	gen		hogar_tiene_desague = 0
	replace hogar_tiene_desague = 1 if P118!=7
	gen		hogar_desague_redpubdentro = 0
	replace hogar_desague_redpubdentro = 1 if P118 == 1
	gen		hogar_desague_redpubfuera = 0
	replace hogar_desague_redpubfuera = 1 if P118 == 2
	gen		hogar_desague_pozo = 0
	replace hogar_desague_pozo = 1 if P118 == 3
	gen		hogar_desague_letrina = 0
	replace hogar_desague_letrina = 1 if P118 == 4
	gen		hogar_desague_rio = 0
	replace hogar_desague_rio = 1 if P118 == 5

	gen		tiene_cocinamejorada = 0
	replace tiene_cocinamejorada = 1 if P119 == 1
	
	gen		horas_capital = P121
	replace horas_capital = 24 if P121_01 == 1
	replace horas_capital = 0 if P121_01 == 2
	
	keep ubigeo* P007X P008 NPRIN benef_juntos benef_vasoleche benef_desalm benef_cunamas benef_bonograt benef_otro num_prog_benef benef_1 hogar_tiene_desague hogar_desague_redpubdentro hogar_desague_redpubfuera hogar_desague_pozo hogar_desague_letrina hogar_desague_rio tiene_cocinamejorada horas_capital
	bys NPRIN: gen a=_n
	drop if a>1
save "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod239_apurimac.dta",  replace
	
*---------------------------------------*
*		Merge Apurimac datasets		*	
*---------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod229_apurimac.dta", clear

merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod231_apurimac.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod232_apurimac.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod235_apurimac.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod237_apurimac.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod238_apurimac.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\2 Apurimac\mod239_apurimac.dta"

drop _merge

save "$input_dir\1 Raw\4 Cenagro\cenagro_apurimac.dta",  replace
}

*-----------------------*
*      III. Cusco		*
*-----------------------*	
{	
*-----------------------------------------------------------------------*
*		Mod 229: Location and characteristics of production unit		*
*-----------------------------------------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo229\mod229.dta", clear
	
	drop if RESULTADO!=1 & RESULTADO!=2
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P017				lee_escribe
	rename P019				num_parc
	rename P020_01 			area_parc
	rename WSUP01			area_parc_categ
	rename WSUP03			area_agricola
	rename WSUP03A			area_agricola_riego
	rename WSUP03B			area_agricola_secano
	rename WSUP04			area_noagricola
	rename WSUP05			area_otro
	rename WSUP18			area_cultivada
	rename WP109			tamano_hogar
	rename WP111			sexo_productor
	rename WP112			edad_productor
	rename WP114			educ_productor
	rename WALTITUD			altitud_msnm
	rename LONG_DECI		longitude
	rename LAT_DECI			latitude
	
	
	replace num_parc = 0 if P019_01==1
	
	keep ubigeo* TIPO_REC P007X P008 NPRIN P016 lee_escribe num_parc area_parc area_parc_categ area_agricola area_agricola_riego area_agricola_secano area_noagricola area_otro area_cultivada tamano_hogar sexo_productor edad_productor educ_productor altitud_msnm longitude latitude
	
	bys NPRIN: gen a=_n
	drop if a>1
	
	gen		area_prom = area_parc / num_parc
	
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod229_cusco.dta",  replace
	
*-------------------------------------------------------*
*		Mod 231: Land use, production destination		*
*-------------------------------------------------------*	
	
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo231\mod231.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P025		area_sembrada
	gen		riego = 0
	replace riego = 0 if P026 == 2
	replace riego = 1 if P026 == 1
	gen		secano = 0
	replace secano = 0 if P026 == 1
	replace secano = 1 if P026 == 2	
	gen		riego_gravedad = 0
	replace riego_gravedad = 1 if P027 == 1
	gen		riego_aspersion = 0
	replace riego_aspersion = 1 if P027 == 2
	gen		destinoprod_venta = 0
	replace destinoprod_venta = 1 if P028 == 1
	gen		destinoprod_autoconsumo = 0 
	replace destinoprod_autoconsumo = 1 if P028 == 2 | P028 == 3 | P028 == 4
	
	gen		num_cultivos = 1 if P024_01 <=7
	
	collapse (firstnm) ubigeo* P007X P008 (sum) area_sembrada cultivo_riego=riego cultivo_secano=secano riego_gravedad riego_aspersion destinoprod* num_cultivos (max) NPARCX, by(NPRIN)
	
	gen		cultivos_prom = num_cultivos / NPARCX
	
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod231_cusco.dta",  replace
	
*-----------------------------------*
*		Mod 231: Land ownership		*
*-----------------------------------*	
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo232\mod232.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		propietario = 0
	replace propietario = 1 if P037_01_01==1
	
	gen		titulo_propiedad = 0
	replace titulo_propiedad = 1 if P037_01_03==1 | P037_01_03==2
	
	collapse (firstnm) ubigeo* P007X P008 (max) NPARCY (sum) num_parc_propias=propietario num_titulo_propiedad=titulo_propiedad, by(NPRIN)
	
	gen		parc_propias_1 = 0
	replace parc_propias_1 = 1 if num_parc_propias>0
	
	gen		prop_parc_propias = num_parc_propias / NPARCY
	
	gen		titulo_propiedad_1 = 0
	replace titulo_propiedad_1 = 1 if num_titulo_propiedad>0
	
	gen		prop_parc_titulo = num_titulo_propiedad / NPARCY
	
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod232_cusco.dta",  replace

*-----------------------------------------------------------------------------------*
*		Mod 235: Irrigation, agricultural practices, use of energy and livestock	*
*-----------------------------------------------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo235\mod235.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first	
	
	recode P049 (3=0) (2=0)
	rename P049			pertenece_comision_regantes
	recode P_RIEGO (2=0)
	rename P_RIEGO		parc_riego_1
	
	gen		riego_fuente_reservorio = 0
	replace riego_fuente_reservorio = 1 if P045_05==1 | P045_06==1
	gen		riego_canales_revestidos = 0
	replace riego_canales_revestidos = 1 if  P048==1
	gen		derecho_usoagua = 0
	replace derecho_usoagua = 1 if P050==1 | P050==2 | P050==3
	
	gen		usa_semilla_certif = 0
	replace usa_semilla_certif = 1 if P051 == 1

	gen		usa_fertilizante_org = 0
	replace usa_fertilizante_org = 1 if P052 == 1 | P052 == 2
	gen		usa_fertilizante_quim = 0
	replace usa_fertilizante_quim = 1 if P053 == 1 | P053 == 2
	
	gen		usa_insecticida_quim = 0
	replace usa_insecticida_quim = 1 if P054_01 == 1
	gen		usa_insecticida_noquim = 0
	replace usa_insecticida_noquim = 1 if P054_02 == 1
	gen		usa_herbicida = 0
	replace usa_herbicida = 1 if P054_03 == 1
	gen		usa_fungicida = 0
	replace usa_fungicida = 1 if P054_04 == 1	
	
	gen		usa_controlbio = 0
	replace usa_controlbio = 1 if P056 == 1	
	
	gen		usa_animales_trabajo = 0
	replace usa_animales_trabajo = 1 if P061 == 1
	gen		usa_tractores_trabajo = 0
	replace usa_tractores_trabajo = 1 if P063 == 1
	
	gen		usa_aradohierro = 0
	replace usa_aradohierro = 1 if P065_01_01 == 1
	gen		usa_aradopalo = 0
	replace usa_aradopalo = 1 if P065_02_01 == 1
	gen		usa_cosechadora = 0
	replace usa_cosechadora = 1 if P065_03_01 == 1
	gen		usa_chaquitaclla = 0
	replace usa_chaquitaclla = 1 if P065_04_01 == 1
	gen		usa_fumigadoramotor = 0
	replace usa_fumigadoramotor = 1 if P065_05_01 == 1
	gen		usa_fumigadoramanual = 0
	replace usa_fumigadoramanual = 1 if P065_06_01 == 1
	gen		usa_molino = 0
	replace usa_molino = 1 if P065_07_01 == 1
	gen		usa_picadorapasto = 0
	replace usa_picadorapasto = 1 if P065_08_01 == 1
	gen		usa_trilladora = 0
	replace usa_trilladora = 1 if P065_09_01 == 1
	gen		usa_bombapozo = 0
	replace usa_bombapozo = 1 if P065_10_01 == 1
	gen		usa_motorbombeo = 0
	replace usa_motorbombeo = 1 if P065_11_01 == 1
	
	gen 	tiene_vacuno = 0
	replace tiene_vacuno = 1 if P066 == 1
	gen		num_vacuno = P066_01
	replace num_vacuno = 0 if tiene_vacuno == 0
	gen		tiene_ovino = 0
	replace tiene_ovino = 1 if P069 == 1
	gen		num_ovino = P069_01
	replace num_ovino = 0 if tiene_ovino == 0
	gen		tiene_porcino = 0
	replace tiene_porcino = 1 if P071 == 1
	gen		num_porcino = P071_01
	replace num_porcino = 0 if tiene_porcino == 0
	gen		tiene_alpaca = 0
	replace tiene_alpaca = 1 if P073 == 1 
	gen		num_alpaca = P073_01
	replace num_alpaca = 0 if tiene_alpaca == 0
	
	keep ubigeo* P007X P008 NPRIN parc_riego_1 pertenece_comision_regantes riego_fuente_reservorio riego_canales_revestidos derecho_usoagua usa_semilla_certif usa_fertilizante_org usa_fertilizante_quim usa_insecticida_quim usa_insecticida_noquim usa_herbicida usa_fungicida usa_controlbio usa_animales_trabajo usa_tractores_trabajo usa_aradohierro usa_aradopalo usa_cosechadora usa_chaquitaclla usa_fumigadoramotor usa_fumigadoramanual usa_molino usa_picadorapasto usa_trilladora usa_bombapozo usa_motorbombeo tiene_vacuno num_vacuno tiene_ovino num_ovino tiene_porcino num_porcino tiene_alpaca num_alpaca
	bys NPRIN: gen a=_n
	drop if a>1
	
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod235_cusco.dta",  replace

*-------------------------------------------------------------------------------*
*		Mod 237: Livestock characteristics, technical assistance, finance,		*	
*				employment, infrastructure, associativity and perceptions		*
*-------------------------------------------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo237\mod237.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		ganaderia = 0
	replace ganaderia = 1 if P_PEC == 1

	gen		vacuna = 0 if P079 == 2
	replace vacuna = 1 if P079 == 1
	gen		desparasita = 0 if P080 == 2
	replace desparasita = 1 if P080 == 1
	gen		dosificaciones = 0 if P081 == 2
	replace dosificaciones = 1 if P081 == 1
	gen		alimentos_balanceados = 0 if P082 == 2
	replace alimentos_balanceados = 1 if P082 == 1
	gen		inseminacion_artificial = 0 if P083 == 2
	replace inseminacion_artificial = 1 if P083 == 1

	gen		recibio_capacitacion = 0
	replace recibio_capacitacion = 1 if P086_01 == 1
	gen		recibio_asistenciatec = 0
	replace recibio_asistenciatec = 1 if P086_02 == 1
	gen		recibio_asesoriaempre = 0
	replace recibio_asesoriaempre = 1 if P086_03 == 1
	
	gen		capacitacion_cultivos = 0
	replace capacitacion_cultivos = 1 if P087_01 == 1
	gen		capacitacion_ganaderia = 0
	replace capacitacion_ganaderia = 1 if P087_02 == 1	
	gen		capacitacion_manejo = 0
	replace capacitacion_manejo = 1 if P087_03 == 1	
	gen		capacitacion_produccion = 0
	replace capacitacion_produccion = 1 if P087_04 == 1	
	gen		capacitacion_negocios = 0
	replace capacitacion_negocios = 1 if P087_05 == 1	
	
	gen		recibio_cap_minagri = 0
	replace recibio_cap_minagri = 1 if P088_01 == 1
	gen		recibio_cap_progsierranorte = 0
	replace recibio_cap_progsierranorte = 1 if P088_02 == 1
	gen		recibio_cap_progsierrasur = 0
	replace recibio_cap_progsierrasur = 1 if P088_03 == 1	
	gen		recibio_cap_progaliados = 0
	replace recibio_cap_progaliados = 1 if P088_04 == 1		
	gen		recibio_cap_progpsi = 0
	replace recibio_cap_progpsi = 1 if P088_05 == 1	
	gen		recibio_cap_agrorural = 0
	replace recibio_cap_agrorural = 1 if P088_06 == 1		
	gen		recibio_cap_inia = 0
	replace recibio_cap_inia = 1 if P088_07 == 1		
	gen		recibio_cap_senasa = 0
	replace recibio_cap_senasa = 1 if P088_08 == 1
	gen		recibio_cap_gobregional = 0
	replace recibio_cap_gobregional = 1 if P088_09 == 1	
	gen		recibio_cap_dra = 0
	replace recibio_cap_dra = 1 if P088_10 == 1	
	gen		recibio_cap_ageagraria = 0
	replace recibio_cap_ageagraria = 1 if P088_11 == 1
	gen		recibio_cap_municipalidad = 0
	replace recibio_cap_municipalidad = 1 if P088_12 == 1	
	gen		recibio_cap_asocproductores = 0
	replace recibio_cap_asocproductores = 1 if P088_13 == 1	
	gen		recibio_cap_eprivada = 0
	replace recibio_cap_eprivada = 1 if P088_14 == 1	
	gen		recibio_cap_ong = 0
	replace recibio_cap_ong = 1 if P088_15 == 1
	
	egen	cap_estatal = rowtotal(recibio_cap_minagri recibio_cap_progsierranorte recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria recibio_cap_municipalidad)
	gen		recibio_cap_estatal = 0
	replace recibio_cap_estatal = 1 if cap_estatal>0
	drop cap_estatal
	gen		recibio_cap_privada = 0
	replace recibio_cap_privada = 1 if recibio_cap_asocproductores==1 | recibio_cap_eprivada==1 | recibio_cap_ong==1
	
	gen		obtuvo_prestamo = 0
	replace obtuvo_prestamo = 1 if P092 == 1
	
	gen		prestamo_comerciante = 0
	replace prestamo_comerciante = 1 if P093_01 == 1
	gen		prestamo_habilitador = 0
	replace prestamo_habilitador = 1 if P093_02 == 1
	gen		prestamo_agrobanco = 0
	replace prestamo_agrobanco = 1 if P093_03 == 1
	gen		prestamo_banco = 0
	replace prestamo_banco = 1 if P093_04 == 1
	gen		prestamo_cmac = 0
	replace prestamo_cmac = 1 if P093_05 == 1	
	gen		prestamo_cooperativa = 0
	replace prestamo_cooperativa = 1 if P093_06 == 1
	gen		prestamo_crac = 0
	replace prestamo_crac = 1 if P093_07 == 1
	gen		prestamo_ong = 0
	replace prestamo_ong = 1 if P093_09 == 1
	gen		prestamo_empresatextil = 0
	replace prestamo_empresatextil = 1 if P093_10 == 1
	gen		prestamo_prestamista = 0
	replace prestamo_prestamista = 1 if P093_11 == 1
	gen		prestamo_edpyme = 0
	replace prestamo_edpyme = 1 if P093_12 == 1

	gen		uso_prestamo_insumos = 0
	replace uso_prestamo_insumos = 1 if P094_01 == 1
	gen		uso_prestamo_maquinaria = 0
	replace uso_prestamo_maquinaria = 1 if P094_02 == 1	
	gen		uso_prestamo_herramientas = 0
	replace uso_prestamo_herramientas = 1 if P094_03 == 1	
	gen		uso_prestamo_venta = 0
	replace uso_prestamo_venta = 1 if P094_04 == 1	
	gen		uso_prestamo_compraganado = 0
	replace uso_prestamo_compraganado = 1 if P094_06 == 1	
	gen		uso_prestamo_infraestructura = 0
	replace uso_prestamo_infraestructura = 1 if P094_07 == 1	
	gen		uso_prestamo_salarios = 0
	replace uso_prestamo_salarios = 1 if P094_08 == 1		
	
	gen		tiene_trab_remunerados = 0
	replace tiene_trab_remunerados = 1 if P098 == 1
	
	egen	total_trab_mujeres = rowtotal(P099_01_03 P099_02_03)
	egen	total_trab_hombres = rowtotal(P099_01_02 P099_02_02)

	gen		tiene_trab_mujeres = 0
	replace tiene_trab_mujeres = 1 if total_trab_mujeres>0
	
	gen		pertenece_asociacion = 0
	replace pertenece_asociacion = 1 if P101 == 1
	
	gen		beneficio_asociacion_1 = 0
	replace beneficio_asociacion_1 = 1 if P103_07 != 1 & pertenece_asociacion == 1
	
	gen		ingresos_agro_suficiente = 0
	replace ingresos_agro_suficiente = 1 if P106 == 1
	
	
	keep ubigeo* P007X P008 NPRIN ganaderia vacuna desparasita dosificaciones 	///
	alimentos_balanceados inseminacion_artificial recibio_capacitacion 			///
	recibio_asistenciatec recibio_asesoriaempre capacitacion_cultivos 			///
	capacitacion_ganaderia capacitacion_manejo capacitacion_produccion 			///
	capacitacion_negocios recibio_cap_minagri recibio_cap_progsierranorte 		///
	recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi 		///
	recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa 					///
	recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria 				///
	recibio_cap_municipalidad recibio_cap_asocproductores recibio_cap_eprivada 	///
	recibio_cap_ong recibio_cap_estatal recibio_cap_privada obtuvo_prestamo 	///
	prestamo_comerciante prestamo_habilitador prestamo_agrobanco prestamo_banco ///
	prestamo_cmac prestamo_cooperativa prestamo_crac prestamo_ong 				///
	prestamo_empresatextil prestamo_prestamista prestamo_edpyme 				///
	uso_prestamo_insumos uso_prestamo_maquinaria uso_prestamo_herramientas 		///
	uso_prestamo_venta uso_prestamo_compraganado uso_prestamo_infraestructura 	///
	uso_prestamo_salarios tiene_trab_remunerados total_trab* tiene_trab* 		///
	pertenece_asociacion beneficio_asociacion_1 ingresos_agro_suficiente
	
	bys NPRIN: gen a=_n
	drop if a>1
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod237_cusco.dta",  replace

*-----------------------------------*
*		Mod 238: Demographics		*
*-----------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo238\mod238.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		participa_agricola = 0
	replace participa_agricola = 1 if P116 == 1 | P110 == 1
	
	gen		sexo = 0
	replace sexo = 1 if P111 == 2
	
	gen		num_perso = 1
	
	gen		edad_6_12 = 0
	replace edad_6_12 = 1 if P112>=6 & P112<=12
	
	gen		edad_6_12_trabaja = 0
	replace edad_6_12_trabaja = 1 if edad_6_12 == 1 & participa_agricola == 1
	
	collapse (firstnm) ubigeo* P007X P008 (sum) edad_6_12_trabaja participa_agricola num_perso (mean) sexo edad_promedio=P112 educ_promedio=P114, by(NPRIN)
	
	gen		edad_6_12_trabaja_1 = 0
	replace edad_6_12_trabaja_1 = 1 if edad_6_12_trabaja>0
	drop edad_6_12_trabaja
	
	gen		prop_participa_agricola = participa_agricola/num_perso
	drop num_perso
	
	bys NPRIN: gen a=_n
	drop if a>1
	
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod238_cusco.dta",  replace

*-----------------------------------------------*
*		Mod 239: Household characteristics		*
*-----------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\344-Modulo239\mod239.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		benef_juntos = 0
	replace benef_juntos = 1 if P117_01 == 1
	gen		benef_vasoleche = 0
	replace benef_vasoleche = 1 if P117_02== 1	
	gen		benef_desalm = 0
	replace benef_desalm = 1 if P117_03 == 1	
	gen		benef_cunamas = 0
	replace benef_cunamas = 1 if P117_04 == 1
	gen		benef_bonograt = 0
	replace benef_bonograt = 1 if P117_05 == 1	
	gen		benef_otro = 0
	replace benef_otro = 1 if P117_06 == 1	
	
	egen	num_prog_benef = rowtotal(benef*)
	gen		benef_1 = 0
	replace benef_1 = 1 if num_prog_benef>0
	
	gen		hogar_tiene_desague = 0
	replace hogar_tiene_desague = 1 if P118!=7
	gen		hogar_desague_redpubdentro = 0
	replace hogar_desague_redpubdentro = 1 if P118 == 1
	gen		hogar_desague_redpubfuera = 0
	replace hogar_desague_redpubfuera = 1 if P118 == 2
	gen		hogar_desague_pozo = 0
	replace hogar_desague_pozo = 1 if P118 == 3
	gen		hogar_desague_letrina = 0
	replace hogar_desague_letrina = 1 if P118 == 4
	gen		hogar_desague_rio = 0
	replace hogar_desague_rio = 1 if P118 == 5

	gen		tiene_cocinamejorada = 0
	replace tiene_cocinamejorada = 1 if P119 == 1
	
	gen		horas_capital = P121
	replace horas_capital = 24 if P121_01 == 1
	replace horas_capital = 0 if P121_01 == 2
	
	keep ubigeo* P007X P008 NPRIN benef_juntos benef_vasoleche benef_desalm benef_cunamas benef_bonograt benef_otro num_prog_benef benef_1 hogar_tiene_desague hogar_desague_redpubdentro hogar_desague_redpubfuera hogar_desague_pozo hogar_desague_letrina hogar_desague_rio tiene_cocinamejorada horas_capital
	bys NPRIN: gen a=_n
	drop if a>1
save "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod239_cusco.dta",  replace
	
*---------------------------------------*
*		Merge Apurimac datasets		*	
*---------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod229_cusco.dta", clear

merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod231_cusco.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod232_cusco.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod235_cusco.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod237_cusco.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod238_cusco.dta"

drop _merge
merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\3 Cusco\mod239_cusco.dta"

drop _merge

save "$input_dir\1 Raw\4 Cenagro\cenagro_cusco.dta",  replace
}

*-----------------------*
*      IV. HUANCAYO		*
*-----------------------*	
{	
*-----------------------------------------------------------------------*
*		Mod 229: Location and characteristics of production unit		*
*-----------------------------------------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo229\mod229.dta", clear
	
	drop if RESULTADO!=1 & RESULTADO!=2
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P017				lee_escribe
	rename P019				num_parc
	rename P020_01 			area_parc
	rename WSUP01			area_parc_categ
	rename WSUP03			area_agricola
	rename WSUP03A			area_agricola_riego
	rename WSUP03B			area_agricola_secano
	rename WSUP04			area_noagricola
	rename WSUP05			area_otro
	rename WSUP18			area_cultivada
	rename WP109			tamano_hogar
	rename WP111			sexo_productor
	rename WP112			edad_productor
	rename WP114			educ_productor
	rename WALTITUD			altitud_msnm
	rename LONG_DECI		longitude
	rename LAT_DECI			latitude
	
	
	replace num_parc = 0 if P019_01==1
	
	keep ubigeo* TIPO_REC P007X P008 NPRIN P016 lee_escribe num_parc area_parc area_parc_categ area_agricola area_agricola_riego area_agricola_secano area_noagricola area_otro area_cultivada tamano_hogar sexo_productor edad_productor educ_productor altitud_msnm longitude latitude
	
	bys NPRIN: gen a=_n
	drop if a>1
	
	gen		area_prom = area_parc / num_parc
	
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod229_junin.dta",  replace
	
*-------------------------------------------------------*
*		Mod 231: Land use, production destination		*
*-------------------------------------------------------*	
	
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo231\mod231.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	rename P025		area_sembrada
	gen		riego = 0
	replace riego = 0 if P026 == 2
	replace riego = 1 if P026 == 1
	gen		secano = 0
	replace secano = 0 if P026 == 1
	replace secano = 1 if P026 == 2	
	gen		riego_gravedad = 0
	replace riego_gravedad = 1 if P027 == 1
	gen		riego_aspersion = 0
	replace riego_aspersion = 1 if P027 == 2
	gen		destinoprod_venta = 0
	replace destinoprod_venta = 1 if P028 == 1
	gen		destinoprod_autoconsumo = 0 
	replace destinoprod_autoconsumo = 1 if P028 == 2 | P028 == 3 | P028 == 4
	
	gen		num_cultivos = 1 if P024_01 <=7
	
	collapse (firstnm) ubigeo* P007X P008 (sum) area_sembrada cultivo_riego=riego cultivo_secano=secano riego_gravedad riego_aspersion destinoprod* num_cultivos (max) NPARCX, by(NPRIN)
	
	gen		cultivos_prom = num_cultivos / NPARCX
	
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod231_junin.dta",  replace
	
*-----------------------------------*
*		Mod 231: Land ownership		*
*-----------------------------------*	
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo232\mod232.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		propietario = 0
	replace propietario = 1 if P037_01_01==1
	
	gen		titulo_propiedad = 0
	replace titulo_propiedad = 1 if P037_01_03==1 | P037_01_03==2
	
	collapse (firstnm) ubigeo* P007X P008 (max) NPARCY (sum) num_parc_propias=propietario num_titulo_propiedad=titulo_propiedad, by(NPRIN)
	
	gen		parc_propias_1 = 0
	replace parc_propias_1 = 1 if num_parc_propias>0
	
	gen		prop_parc_propias = num_parc_propias / NPARCY
	
	gen		titulo_propiedad_1 = 0
	replace titulo_propiedad_1 = 1 if num_titulo_propiedad>0
	
	gen		prop_parc_titulo = num_titulo_propiedad / NPARCY
	
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod232_junin.dta",  replace

*-----------------------------------------------------------------------------------*
*		Mod 235: Irrigation, agricultural practices, use of energy and livestock	*
*-----------------------------------------------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo235\mod235.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first	
	
	recode P049 (3=0) (2=0)
	rename P049			pertenece_comision_regantes
	recode P_RIEGO (2=0)
	rename P_RIEGO		parc_riego_1
	
	gen		riego_fuente_reservorio = 0
	replace riego_fuente_reservorio = 1 if P045_05==1 | P045_06==1
	gen		riego_canales_revestidos = 0
	replace riego_canales_revestidos = 1 if  P048==1
	gen		derecho_usoagua = 0
	replace derecho_usoagua = 1 if P050==1 | P050==2 | P050==3
	
	gen		usa_semilla_certif = 0
	replace usa_semilla_certif = 1 if P051 == 1

	gen		usa_fertilizante_org = 0
	replace usa_fertilizante_org = 1 if P052 == 1 | P052 == 2
	gen		usa_fertilizante_quim = 0
	replace usa_fertilizante_quim = 1 if P053 == 1 | P053 == 2
	
	gen		usa_insecticida_quim = 0
	replace usa_insecticida_quim = 1 if P054_01 == 1
	gen		usa_insecticida_noquim = 0
	replace usa_insecticida_noquim = 1 if P054_02 == 1
	gen		usa_herbicida = 0
	replace usa_herbicida = 1 if P054_03 == 1
	gen		usa_fungicida = 0
	replace usa_fungicida = 1 if P054_04 == 1	
	
	gen		usa_controlbio = 0
	replace usa_controlbio = 1 if P056 == 1	
	
	gen		usa_animales_trabajo = 0
	replace usa_animales_trabajo = 1 if P061 == 1
	gen		usa_tractores_trabajo = 0
	replace usa_tractores_trabajo = 1 if P063 == 1
	
	gen		usa_aradohierro = 0
	replace usa_aradohierro = 1 if P065_01_01 == 1
	gen		usa_aradopalo = 0
	replace usa_aradopalo = 1 if P065_02_01 == 1
	gen		usa_cosechadora = 0
	replace usa_cosechadora = 1 if P065_03_01 == 1
	gen		usa_chaquitaclla = 0
	replace usa_chaquitaclla = 1 if P065_04_01 == 1
	gen		usa_fumigadoramotor = 0
	replace usa_fumigadoramotor = 1 if P065_05_01 == 1
	gen		usa_fumigadoramanual = 0
	replace usa_fumigadoramanual = 1 if P065_06_01 == 1
	gen		usa_molino = 0
	replace usa_molino = 1 if P065_07_01 == 1
	gen		usa_picadorapasto = 0
	replace usa_picadorapasto = 1 if P065_08_01 == 1
	gen		usa_trilladora = 0
	replace usa_trilladora = 1 if P065_09_01 == 1
	gen		usa_bombapozo = 0
	replace usa_bombapozo = 1 if P065_10_01 == 1
	gen		usa_motorbombeo = 0
	replace usa_motorbombeo = 1 if P065_11_01 == 1
	
	gen 	tiene_vacuno = 0
	replace tiene_vacuno = 1 if P066 == 1
	gen		num_vacuno = P066_01
	replace num_vacuno = 0 if tiene_vacuno == 0
	gen		tiene_ovino = 0
	replace tiene_ovino = 1 if P069 == 1
	gen		num_ovino = P069_01
	replace num_ovino = 0 if tiene_ovino == 0
	gen		tiene_porcino = 0
	replace tiene_porcino = 1 if P071 == 1
	gen		num_porcino = P071_01
	replace num_porcino = 0 if tiene_porcino == 0
	gen		tiene_alpaca = 0
	replace tiene_alpaca = 1 if P073 == 1 
	gen		num_alpaca = P073_01
	replace num_alpaca = 0 if tiene_alpaca == 0
	
	keep ubigeo* P007X P008 NPRIN parc_riego_1 pertenece_comision_regantes riego_fuente_reservorio riego_canales_revestidos derecho_usoagua usa_semilla_certif usa_fertilizante_org usa_fertilizante_quim usa_insecticida_quim usa_insecticida_noquim usa_herbicida usa_fungicida usa_controlbio usa_animales_trabajo usa_tractores_trabajo usa_aradohierro usa_aradopalo usa_cosechadora usa_chaquitaclla usa_fumigadoramotor usa_fumigadoramanual usa_molino usa_picadorapasto usa_trilladora usa_bombapozo usa_motorbombeo tiene_vacuno num_vacuno tiene_ovino num_ovino tiene_porcino num_porcino tiene_alpaca num_alpaca
	bys NPRIN: gen a=_n
	drop if a>1
	
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod235_junin.dta",  replace

*-------------------------------------------------------------------------------*
*		Mod 237: Livestock characteristics, technical assistance, finance,		*	
*				employment, infrastructure, associativity and perceptions		*
*-------------------------------------------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo237\mod237.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		ganaderia = 0
	replace ganaderia = 1 if P_PEC == 1

	gen		vacuna = 0 if P079 == 2
	replace vacuna = 1 if P079 == 1
	gen		desparasita = 0 if P080 == 2
	replace desparasita = 1 if P080 == 1
	gen		dosificaciones = 0 if P081 == 2
	replace dosificaciones = 1 if P081 == 1
	gen		alimentos_balanceados = 0 if P082 == 2
	replace alimentos_balanceados = 1 if P082 == 1
	gen		inseminacion_artificial = 0 if P083 == 2
	replace inseminacion_artificial = 1 if P083 == 1

	gen		recibio_capacitacion = 0
	replace recibio_capacitacion = 1 if P086_01 == 1
	gen		recibio_asistenciatec = 0
	replace recibio_asistenciatec = 1 if P086_02 == 1
	gen		recibio_asesoriaempre = 0
	replace recibio_asesoriaempre = 1 if P086_03 == 1
	
	gen		capacitacion_cultivos = 0
	replace capacitacion_cultivos = 1 if P087_01 == 1
	gen		capacitacion_ganaderia = 0
	replace capacitacion_ganaderia = 1 if P087_02 == 1	
	gen		capacitacion_manejo = 0
	replace capacitacion_manejo = 1 if P087_03 == 1	
	gen		capacitacion_produccion = 0
	replace capacitacion_produccion = 1 if P087_04 == 1	
	gen		capacitacion_negocios = 0
	replace capacitacion_negocios = 1 if P087_05 == 1	
	
	gen		recibio_cap_minagri = 0
	replace recibio_cap_minagri = 1 if P088_01 == 1
	gen		recibio_cap_progsierranorte = 0
	replace recibio_cap_progsierranorte = 1 if P088_02 == 1
	gen		recibio_cap_progsierrasur = 0
	replace recibio_cap_progsierrasur = 1 if P088_03 == 1	
	gen		recibio_cap_progaliados = 0
	replace recibio_cap_progaliados = 1 if P088_04 == 1		
	gen		recibio_cap_progpsi = 0
	replace recibio_cap_progpsi = 1 if P088_05 == 1	
	gen		recibio_cap_agrorural = 0
	replace recibio_cap_agrorural = 1 if P088_06 == 1		
	gen		recibio_cap_inia = 0
	replace recibio_cap_inia = 1 if P088_07 == 1		
	gen		recibio_cap_senasa = 0
	replace recibio_cap_senasa = 1 if P088_08 == 1
	gen		recibio_cap_gobregional = 0
	replace recibio_cap_gobregional = 1 if P088_09 == 1	
	gen		recibio_cap_dra = 0
	replace recibio_cap_dra = 1 if P088_10 == 1	
	gen		recibio_cap_ageagraria = 0
	replace recibio_cap_ageagraria = 1 if P088_11 == 1
	gen		recibio_cap_municipalidad = 0
	replace recibio_cap_municipalidad = 1 if P088_12 == 1	
	gen		recibio_cap_asocproductores = 0
	replace recibio_cap_asocproductores = 1 if P088_13 == 1	
	gen		recibio_cap_eprivada = 0
	replace recibio_cap_eprivada = 1 if P088_14 == 1	
	gen		recibio_cap_ong = 0
	replace recibio_cap_ong = 1 if P088_15 == 1
	
	egen	cap_estatal = rowtotal(recibio_cap_minagri recibio_cap_progsierranorte recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria recibio_cap_municipalidad)
	gen		recibio_cap_estatal = 0
	replace recibio_cap_estatal = 1 if cap_estatal>0
	drop cap_estatal
	gen		recibio_cap_privada = 0
	replace recibio_cap_privada = 1 if recibio_cap_asocproductores==1 | recibio_cap_eprivada==1 | recibio_cap_ong==1
	
	gen		obtuvo_prestamo = 0
	replace obtuvo_prestamo = 1 if P092 == 1
	
	gen		prestamo_comerciante = 0
	replace prestamo_comerciante = 1 if P093_01 == 1
	gen		prestamo_habilitador = 0
	replace prestamo_habilitador = 1 if P093_02 == 1
	gen		prestamo_agrobanco = 0
	replace prestamo_agrobanco = 1 if P093_03 == 1
	gen		prestamo_banco = 0
	replace prestamo_banco = 1 if P093_04 == 1
	gen		prestamo_cmac = 0
	replace prestamo_cmac = 1 if P093_05 == 1	
	gen		prestamo_cooperativa = 0
	replace prestamo_cooperativa = 1 if P093_06 == 1
	gen		prestamo_crac = 0
	replace prestamo_crac = 1 if P093_07 == 1
	gen		prestamo_ong = 0
	replace prestamo_ong = 1 if P093_09 == 1
	gen		prestamo_empresatextil = 0
	replace prestamo_empresatextil = 1 if P093_10 == 1
	gen		prestamo_prestamista = 0
	replace prestamo_prestamista = 1 if P093_11 == 1
	gen		prestamo_edpyme = 0
	replace prestamo_edpyme = 1 if P093_12 == 1

	gen		uso_prestamo_insumos = 0
	replace uso_prestamo_insumos = 1 if P094_01 == 1
	gen		uso_prestamo_maquinaria = 0
	replace uso_prestamo_maquinaria = 1 if P094_02 == 1	
	gen		uso_prestamo_herramientas = 0
	replace uso_prestamo_herramientas = 1 if P094_03 == 1	
	gen		uso_prestamo_venta = 0
	replace uso_prestamo_venta = 1 if P094_04 == 1	
	gen		uso_prestamo_compraganado = 0
	replace uso_prestamo_compraganado = 1 if P094_06 == 1	
	gen		uso_prestamo_infraestructura = 0
	replace uso_prestamo_infraestructura = 1 if P094_07 == 1	
	gen		uso_prestamo_salarios = 0
	replace uso_prestamo_salarios = 1 if P094_08 == 1		
	
	gen		tiene_trab_remunerados = 0
	replace tiene_trab_remunerados = 1 if P098 == 1
	
	egen	total_trab_mujeres = rowtotal(P099_01_03 P099_02_03)
	egen	total_trab_hombres = rowtotal(P099_01_02 P099_02_02)

	gen		tiene_trab_mujeres = 0
	replace tiene_trab_mujeres = 1 if total_trab_mujeres>0
	
	gen		pertenece_asociacion = 0
	replace pertenece_asociacion = 1 if P101 == 1
	
	gen		beneficio_asociacion_1 = 0
	replace beneficio_asociacion_1 = 1 if P103_07 != 1 & pertenece_asociacion == 1
	
	gen		ingresos_agro_suficiente = 0
	replace ingresos_agro_suficiente = 1 if P106 == 1
	
	
	keep ubigeo* P007X P008 NPRIN ganaderia vacuna desparasita dosificaciones 	///
	alimentos_balanceados inseminacion_artificial recibio_capacitacion 			///
	recibio_asistenciatec recibio_asesoriaempre capacitacion_cultivos 			///
	capacitacion_ganaderia capacitacion_manejo capacitacion_produccion 			///
	capacitacion_negocios recibio_cap_minagri recibio_cap_progsierranorte 		///
	recibio_cap_progsierrasur recibio_cap_progaliados recibio_cap_progpsi 		///
	recibio_cap_agrorural recibio_cap_inia recibio_cap_senasa 					///
	recibio_cap_gobregional recibio_cap_dra recibio_cap_ageagraria 				///
	recibio_cap_municipalidad recibio_cap_asocproductores recibio_cap_eprivada 	///
	recibio_cap_ong recibio_cap_estatal recibio_cap_privada obtuvo_prestamo 	///
	prestamo_comerciante prestamo_habilitador prestamo_agrobanco prestamo_banco ///
	prestamo_cmac prestamo_cooperativa prestamo_crac prestamo_ong 				///
	prestamo_empresatextil prestamo_prestamista prestamo_edpyme 				///
	uso_prestamo_insumos uso_prestamo_maquinaria uso_prestamo_herramientas 		///
	uso_prestamo_venta uso_prestamo_compraganado uso_prestamo_infraestructura 	///
	uso_prestamo_salarios tiene_trab_remunerados total_trab* tiene_trab* 		///
	pertenece_asociacion beneficio_asociacion_1 ingresos_agro_suficiente
	
	bys NPRIN: gen a=_n
	drop if a>1
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod237_junin.dta",  replace

*-----------------------------------*
*		Mod 238: Demographics		*
*-----------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo238\mod238.dta", clear
	
	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		participa_agricola = 0
	replace participa_agricola = 1 if P116 == 1 | P110 == 1
	
	gen		sexo = 0
	replace sexo = 1 if P111 == 2
	
	gen		num_perso = 1
	
	gen		edad_6_12 = 0
	replace edad_6_12 = 1 if P112>=6 & P112<=12
	
	gen		edad_6_12_trabaja = 0
	replace edad_6_12_trabaja = 1 if edad_6_12 == 1 & participa_agricola == 1
	
	collapse (firstnm) ubigeo* P007X P008 (sum) edad_6_12_trabaja participa_agricola num_perso (mean) sexo edad_promedio=P112 educ_promedio=P114, by(NPRIN)
	
	gen		edad_6_12_trabaja_1 = 0
	replace edad_6_12_trabaja_1 = 1 if edad_6_12_trabaja>0
	drop edad_6_12_trabaja
	
	gen		prop_participa_agricola = participa_agricola/num_perso
	drop num_perso
	
	bys NPRIN: gen a=_n
	drop if a>1
	
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod238_junin.dta",  replace

*-----------------------------------------------*
*		Mod 239: Household characteristics		*
*-----------------------------------------------*		
use "$input_dir\1 Raw\4 Cenagro\4 Junin\348-Modulo239\mod239.dta", clear

	rename 	P001 ubigeo_dpto
	egen	ubigeo_prov=concat(ubigeo_dpto P002)
	egen	ubigeo_dist=concat(ubigeo_prov P003)
	order ubigeo_dpto ubigeo_prov ubigeo_dist, first
	
	gen		benef_juntos = 0
	replace benef_juntos = 1 if P117_01 == 1
	gen		benef_vasoleche = 0
	replace benef_vasoleche = 1 if P117_02== 1	
	gen		benef_desalm = 0
	replace benef_desalm = 1 if P117_03 == 1	
	gen		benef_cunamas = 0
	replace benef_cunamas = 1 if P117_04 == 1
	gen		benef_bonograt = 0
	replace benef_bonograt = 1 if P117_05 == 1	
	gen		benef_otro = 0
	replace benef_otro = 1 if P117_06 == 1	
	
	egen	num_prog_benef = rowtotal(benef*)
	gen		benef_1 = 0
	replace benef_1 = 1 if num_prog_benef>0
	
	gen		hogar_tiene_desague = 0
	replace hogar_tiene_desague = 1 if P118!=7
	gen		hogar_desague_redpubdentro = 0
	replace hogar_desague_redpubdentro = 1 if P118 == 1
	gen		hogar_desague_redpubfuera = 0
	replace hogar_desague_redpubfuera = 1 if P118 == 2
	gen		hogar_desague_pozo = 0
	replace hogar_desague_pozo = 1 if P118 == 3
	gen		hogar_desague_letrina = 0
	replace hogar_desague_letrina = 1 if P118 == 4
	gen		hogar_desague_rio = 0
	replace hogar_desague_rio = 1 if P118 == 5

	gen		tiene_cocinamejorada = 0
	replace tiene_cocinamejorada = 1 if P119 == 1
	
	gen		horas_capital = P121
	replace horas_capital = 24 if P121_01 == 1
	replace horas_capital = 0 if P121_01 == 2
	
	keep ubigeo* P007X P008 NPRIN benef_juntos benef_vasoleche benef_desalm benef_cunamas benef_bonograt benef_otro num_prog_benef benef_1 hogar_tiene_desague hogar_desague_redpubdentro hogar_desague_redpubfuera hogar_desague_pozo hogar_desague_letrina hogar_desague_rio tiene_cocinamejorada horas_capital
	bys NPRIN: gen a=_n
	drop if a>1
save "$input_dir\1 Raw\4 Cenagro\4 Junin\mod239_junin.dta",  replace
	
*---------------------------------------*
*		Merge Apurimac datasets		*	
*---------------------------------------*
use "$input_dir\1 Raw\4 Cenagro\4 Junin\mod229_junin.dta", clear

	merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\4 Junin\mod231_junin.dta"

	drop _merge
	merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\4 Junin\mod232_junin.dta"

	drop _merge
	merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\4 Junin\mod235_junin.dta"

	drop _merge
	merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\4 Junin\mod237_junin.dta"

	drop _merge
	merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\4 Junin\mod238_junin.dta"

	drop _merge
	merge 1:1 NPRIN using "$input_dir\1 Raw\4 Cenagro\4 Junin\mod239_junin.dta"

	drop _merge

save "$input_dir\1 Raw\4 Cenagro\cenagro_junin.dta",  replace
}

*-----------------------------------*
*		Merge to Producer level		*
*-----------------------------------*	
use "$input_dir\1 Raw\4 Cenagro\cenagro_huancavelica.dta", clear

	append using "$input_dir\1 Raw\4 Cenagro\cenagro_apurimac.dta"
	append using "$input_dir\1 Raw\4 Cenagro\cenagro_cusco.dta"
	append using "$input_dir\1 Raw\4 Cenagro\cenagro_junin.dta"
		
	recode sexo_productor (1=0) (2=1)	
	bys NPRIN: gen rep=_n
	drop if rep>1
	drop rep
	gen id=_n
	geonear id latitude longitude using "C:\Users\jzava\Dropbox (Personal)\VictimasRD\2 data\1 Raw\ccpp_georef_dist.dta", n(id latitude longitude) 
	drop id
	rename nid id
	merge m:1 id using "C:\Users\jzava\Dropbox (Personal)\VictimasRD\2 data\1 Raw\ccpp_georef_dist.dta" , keepusing(ubigeo_ccpp)
	drop if _merge!=3
	drop _merge
	drop altitud_msnm
	
save "$input_dir\2 Working\cenagro_producer.dta",  replace

*---------------------------------------*
*		Collapse to community level		*	
*---------------------------------------*
use "$input_dir\2 Working\cenagro_producer.dta", clear

gen		num_productores = 1

	collapse (firstnm) ubigeo_dpto ubigeo_prov ubigeo_dist						///
			(sum) num_productores lee_escribe num_parc area_parc area_agricola ///
			num_productor_m=sexo_productor riego_aspersion riego_gravedad destinoprod_venta		///
			num_cultivos ganaderia total_trab_mujeres total_trab_hombres ///
			(mean) prop_productor_m=sexo_productor prom_parc=num_parc prom_area_parc=area_parc 					///
			prom_area_agricola=area_agricola prom_tamano_hogar=tamano_hogar prop_venta=destinoprod_venta	///
			prom_edad_productor=edad_productor prom_educ_productor=educ_productor ///
			prom_num_cultivos=num_cultivos prop_titulo=titulo_propiedad_1	///
			prop_parc_riego=parc_riego_1 prop_miembro_comision=pertenece_comision_regantes ///
			prop_riego_reservorio=riego_fuente_reservorio prop_canales_revest=riego_canales_revestidos ///
			prop_derecho_usoagua=derecho_usoagua prop_usa_semillacertif=usa_semilla_certif ///
			prop_usa_fertorg=usa_fertilizante_org prop_usa_fertquim=usa_fertilizante_quim ///
			prop_usa_insectquim=usa_insecticida_quim prop_usa_insectnoquim=usa_insecticida_noquim ///
			prop_usa_herbicida=usa_herbicida prop_usa_fungicida=usa_fungicida ///
			prop_usa_controlbio=usa_controlbio prop_usa_animtrabajo=usa_animales_trabajo ///
			prop_usa_maquintrabajo=usa_tractores_trabajo prop_usa_aradohierro=usa_aradohierro ///
			prop_usa_aradopalo=usa_aradopalo prop_usa_cosechadora=usa_cosechadora ///
			prop_usa_fumigadoramotor=usa_fumigadoramotor prop_usa_fumigadoramanual=usa_fumigadoramanual ///
			prop_usa_molino=usa_molino prop_usa_pocadorapasto=usa_picadorapasto ///
			prop_usa_trilladora=usa_trilladora prop_usa_motorbombeo=usa_motorbombeo ///
			prop_tiene_vacuno=tiene_vacuno prom_num_vacuno=num_vacuno prop_tiene_ovino=tiene_ovino ///
			prom_num_ovino=num_ovino prop_tiene_alpaca=tiene_alpaca prom_num_alpaca=num_alpaca ///
			prop_ganaderia=ganaderia prop_usa_vacuna=vacuna prop_usa_desparasita=desparasita ///
			prop_usa_disificacion=dosificaciones prop_usa_alimbal=alimentos_balanceados ///
			prop_usa_insemin=inseminacion_artificial prop_capacitacion=recibio_capacitacion ///
			prop_asistencia=recibio_asistenciatec prop_asesoriaempre=recibio_asesoriaempre ///
			prop_capacitacion_estatal=recibio_cap_estatal prop_capacitacion_privada=recibio_cap_privada ///
			prop_credito=obtuvo_prestamo prop_tiene_trabremun=tiene_trab_remunerados ///
			prop_trab_mujeres=tiene_trab_mujeres prom_trab_mujeres=total_trab_mujeres ///
			prop_asociacion=pertenece_asociacion prop_agro_suficiente=ingresos_agro_suficiente ///
			prom_ratiosexo=sexo prom_ratioparticipaagro=prop_participa_agricola ///
			prop_benef_juntos=benef_juntos prop_benef_vasoleche=benef_vasoleche ///
			prop_benef_desalm=benef_desalm prop_benef_cunamas=benef_cunamas 	///
			prop_benef_bonograt=benef_bonograt prom_num_benef=num_prog_benef 	///
			prop_benef_1=benef_1 prop_hogar_desague=hogar_tiene_desague, by(ubigeo_ccpp)
			
	gen prop_productores_alfabeta = lee_escribe / num_productores
	gen prop_productores_m = num_productor_m / num_productores

save "$input_dir\2 Working\cenagro_ccpp.dta",  replace

*---------------------------------------*
*		Collapse to district level		*	
*---------------------------------------*
*		With District Capitals
use "$input_dir\2 Working\cenagro_producer.dta", clear

gen		num_productores = 1

	collapse (firstnm) ubigeo_dpto ubigeo_prov 						///
			(sum) num_productores lee_escribe num_parc area_parc area_agricola ///
			num_productor_m=sexo_productor riego_aspersion riego_gravedad destinoprod_venta		///
			num_cultivos ganaderia total_trab_mujeres total_trab_hombres ///
			(mean) prop_productor_m=sexo_productor prom_parc=num_parc prom_area_parc=area_parc 					///
			prom_area_agricola=area_agricola prom_tamano_hogar=tamano_hogar prop_venta=destinoprod_venta	///
			prom_edad_productor=edad_productor prom_educ_productor=educ_productor ///
			prom_num_cultivos=num_cultivos prop_titulo=titulo_propiedad_1	///
			prop_parc_riego=parc_riego_1 prop_miembro_comision=pertenece_comision_regantes ///
			prop_riego_reservorio=riego_fuente_reservorio prop_canales_revest=riego_canales_revestidos ///
			prop_derecho_usoagua=derecho_usoagua prop_usa_semillacertif=usa_semilla_certif ///
			prop_usa_fertorg=usa_fertilizante_org prop_usa_fertquim=usa_fertilizante_quim ///
			prop_usa_insectquim=usa_insecticida_quim prop_usa_insectnoquim=usa_insecticida_noquim ///
			prop_usa_herbicida=usa_herbicida prop_usa_fungicida=usa_fungicida ///
			prop_usa_controlbio=usa_controlbio prop_usa_animtrabajo=usa_animales_trabajo ///
			prop_usa_maquintrabajo=usa_tractores_trabajo prop_usa_aradohierro=usa_aradohierro ///
			prop_usa_aradopalo=usa_aradopalo prop_usa_cosechadora=usa_cosechadora ///
			prop_usa_fumigadoramotor=usa_fumigadoramotor prop_usa_fumigadoramanual=usa_fumigadoramanual ///
			prop_usa_molino=usa_molino prop_usa_pocadorapasto=usa_picadorapasto ///
			prop_usa_trilladora=usa_trilladora prop_usa_motorbombeo=usa_motorbombeo ///
			prop_tiene_vacuno=tiene_vacuno prom_num_vacuno=num_vacuno prop_tiene_ovino=tiene_ovino ///
			prom_num_ovino=num_ovino prop_tiene_alpaca=tiene_alpaca prom_num_alpaca=num_alpaca ///
			prop_ganaderia=ganaderia prop_usa_vacuna=vacuna prop_usa_desparasita=desparasita ///
			prop_usa_disificacion=dosificaciones prop_usa_alimbal=alimentos_balanceados ///
			prop_usa_insemin=inseminacion_artificial prop_capacitacion=recibio_capacitacion ///
			prop_asistencia=recibio_asistenciatec prop_asesoriaempre=recibio_asesoriaempre ///
			prop_capacitacion_estatal=recibio_cap_estatal prop_capacitacion_privada=recibio_cap_privada ///
			prop_credito=obtuvo_prestamo prop_tiene_trabremun=tiene_trab_remunerados ///
			prop_trab_mujeres=tiene_trab_mujeres prom_trab_mujeres=total_trab_mujeres ///
			prop_asociacion=pertenece_asociacion prop_agro_suficiente=ingresos_agro_suficiente ///
			prom_ratiosexo=sexo prom_ratioparticipaagro=prop_participa_agricola ///
			prop_benef_juntos=benef_juntos prop_benef_vasoleche=benef_vasoleche ///
			prop_benef_desalm=benef_desalm prop_benef_cunamas=benef_cunamas 	///
			prop_benef_bonograt=benef_bonograt prom_num_benef=num_prog_benef 	///
			prop_benef_1=benef_1 prop_hogar_desague=hogar_tiene_desague, by(ubigeo_dist)
			
	gen prop_productores_alfabeta = lee_escribe / num_productores
	gen prop_productores_m = num_productor_m / num_productores

save "$input_dir\2 Working\cenagro_district.dta",  replace

*		Without District Capitals
use "$input_dir\2 Working\cenagro_producer.dta", clear
gen		cod_cap = substr(ubigeo_ccpp,-4,4)
drop if cod_cap=="0001"
gen		num_productores = 1

	collapse (firstnm) ubigeo_dpto ubigeo_prov 						///
			(sum) num_productores lee_escribe num_parc area_parc area_agricola ///
			num_productor_m=sexo_productor riego_aspersion riego_gravedad destinoprod_venta		///
			num_cultivos ganaderia total_trab_mujeres total_trab_hombres ///
			(mean) prop_productor_m=sexo_productor prom_parc=num_parc prom_area_parc=area_parc 					///
			prom_area_agricola=area_agricola prom_tamano_hogar=tamano_hogar prop_venta=destinoprod_venta	///
			prom_edad_productor=edad_productor prom_educ_productor=educ_productor ///
			prom_num_cultivos=num_cultivos prop_titulo=titulo_propiedad_1	///
			prop_parc_riego=parc_riego_1 prop_miembro_comision=pertenece_comision_regantes ///
			prop_riego_reservorio=riego_fuente_reservorio prop_canales_revest=riego_canales_revestidos ///
			prop_derecho_usoagua=derecho_usoagua prop_usa_semillacertif=usa_semilla_certif ///
			prop_usa_fertorg=usa_fertilizante_org prop_usa_fertquim=usa_fertilizante_quim ///
			prop_usa_insectquim=usa_insecticida_quim prop_usa_insectnoquim=usa_insecticida_noquim ///
			prop_usa_herbicida=usa_herbicida prop_usa_fungicida=usa_fungicida ///
			prop_usa_controlbio=usa_controlbio prop_usa_animtrabajo=usa_animales_trabajo ///
			prop_usa_maquintrabajo=usa_tractores_trabajo prop_usa_aradohierro=usa_aradohierro ///
			prop_usa_aradopalo=usa_aradopalo prop_usa_cosechadora=usa_cosechadora ///
			prop_usa_fumigadoramotor=usa_fumigadoramotor prop_usa_fumigadoramanual=usa_fumigadoramanual ///
			prop_usa_molino=usa_molino prop_usa_pocadorapasto=usa_picadorapasto ///
			prop_usa_trilladora=usa_trilladora prop_usa_motorbombeo=usa_motorbombeo ///
			prop_tiene_vacuno=tiene_vacuno prom_num_vacuno=num_vacuno prop_tiene_ovino=tiene_ovino ///
			prom_num_ovino=num_ovino prop_tiene_alpaca=tiene_alpaca prom_num_alpaca=num_alpaca ///
			prop_ganaderia=ganaderia prop_usa_vacuna=vacuna prop_usa_desparasita=desparasita ///
			prop_usa_disificacion=dosificaciones prop_usa_alimbal=alimentos_balanceados ///
			prop_usa_insemin=inseminacion_artificial prop_capacitacion=recibio_capacitacion ///
			prop_asistencia=recibio_asistenciatec prop_asesoriaempre=recibio_asesoriaempre ///
			prop_capacitacion_estatal=recibio_cap_estatal prop_capacitacion_privada=recibio_cap_privada ///
			prop_credito=obtuvo_prestamo prop_tiene_trabremun=tiene_trab_remunerados ///
			prop_trab_mujeres=tiene_trab_mujeres prom_trab_mujeres=total_trab_mujeres ///
			prop_asociacion=pertenece_asociacion prop_agro_suficiente=ingresos_agro_suficiente ///
			prom_ratiosexo=sexo prom_ratioparticipaagro=prop_participa_agricola ///
			prop_benef_juntos=benef_juntos prop_benef_vasoleche=benef_vasoleche ///
			prop_benef_desalm=benef_desalm prop_benef_cunamas=benef_cunamas 	///
			prop_benef_bonograt=benef_bonograt prom_num_benef=num_prog_benef 	///
			prop_benef_1=benef_1 prop_hogar_desague=hogar_tiene_desague, by(ubigeo_dist)
			
	gen prop_productores_alfabeta = lee_escribe / num_productores
	gen prop_productores_m = num_productor_m / num_productores

save "$input_dir\2 Working\cenagro_district_NoCapDist.dta",  replace
	
	
	
	
	
		*calculo de % de hogares que se dedican a agropecuario

	
	
	
	
	
	
	
	
	
	
	
