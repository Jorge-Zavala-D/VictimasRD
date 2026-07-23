/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from 2013 Sisfoh  |
|					  and define candidates for outcomes at community level		|
|                                                                               |
|Date Created: 16/08/2018			 					                        |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

I.		Sisfoh CCPP
	1.	Import 2013 Sisfoh raw dataset
	2.	Label variables
	3.	Create outcomes and ratios for HH at CCPP level
	4.	Generate a poverty indicator at CCPP level
	
II.		Sisfoh hogar

III.	Sisfoh persona

IV.		Merge Sisfoh personas with Sisfoh HH

V.		Sisfoh personas - Women dataset

*-------------------------------------------------------------------------------*/

*-----------------------*
*       DIRECTORY       *
*-----------------------*
	clear all
	set more off
	version 13
	
	*global a "C:\Users\Jorge Zavala\Dropbox (Personal)\VictimasRD"
	*global a "C:\Users\j.zavaladelgado\Dropbox\VictimasRD\"
	*global a "C:\Users\jzava\Dropbox (Personal)\VictimasRD"
	*global a "/Users/bruno_esposito/Dropbox/Proyectos/Matthew/VictimasRD"
	global a "D:\Dropbox\VictimasRD"

/*-----------------------------------------------*
*		I.	Import 2013 Sisfoh raw dataset		*
*-----------------------------------------------*

use "$a\2 data\1 Raw\ccpp_sisfoh2013.dta",clear

*-----------------------------------*
*		1.1.	Label variables		*
*-----------------------------------*

label	var	ccpp_user	"Centro Poblado del Usuario"
label	var	ccpp	"Ubigeo del Centro Poblado"
label	var	ccdd18	"código del departamento"
label	var	ccpp18	"Código de la provincia"
label	var	ccdi18	"código del distrito"
label	var	codccpp18	"código del centro poblado"
label	var	departamento	"Nombre del departamento"
label	var	provincia	"Nombre de la provincia"
label	var	distrito	"Nombre del Distrito"
label	var	centropoblado	"Nombre del centro poblado"
label	var	area	"Area"
label	var	pob	"Número total de población residente"
label	var	hog	"Número total de hogar"
label	var	viv	"Número total de viviendas"
label	var	sisf_tviv1	"Tipo de vivienda- Casa independiente"
label	var	sisf_tviv2	"Tipo de vivienda- Departamento en edificio"
label	var	sisf_tviv3	"Tipo de vivienda- Vivienda en quinta"
label	var	sisf_tviv4	"Tipo de vivienda- Vivivenda en casa vecindad (callejón, solar o corralón)"
label	var	sisf_tviv5	"Tipo de vivienda- Choza o cabana"
label	var	sisf_tviv6	"Tipo de vivienda- Vivienda improvisada"
label	var	sisf_tviv7	"Tipo de vivienda- Local no destinado para habitacion humana y otro tipo"
label	var	sisf_tviv8	"Tipo de vivienda- Otro"
label	var	sisf_tenviv1	"Tenencia de vivienda- Alquilada"
label	var	sisf_tenviv2	"Tenencia de vivienda- Propia, pagándola a plazos"
label	var	sisf_tenviv3	"Tenencia de vivienda- Propia, totalmente pagada"
label	var	sisf_tenviv4	"Tenencia de vivienda- Propia, por invasión"
label	var	sisf_tenviv5	"Tenencia de vivienda- Cedida por el centro de trabajo"
label	var	sisf_tenviv6	"Tenencia de vivienda- Cedida por otro hogar o institución"
label	var	sisf_tenviv7	"Tenencia de vivienda- Otro"
label	var	sisf_matpared1	"Material predominante paredes - Ladrillo o bloque de cemento"
label	var	sisf_matpared2	"Material predominante paredes - Piedra o sillar con cal o cemento"
label	var	sisf_matpared3	"Material predominante paredes - Adobe o tapia"
label	var	sisf_matpared4	"Material predominante paredes - Quincha (caña con barro)"
label	var	sisf_matpared5	"Material predominante paredes - Piedra con barro"
label	var	sisf_matpared6	"Material predominante paredes - Madera"
label	var	sisf_matpared7	"Material predominante paredes - Estera"
label	var	sisf_matpared8	"Material predominante paredes - Otro material"
label	var	sisf_matecho1	"Material predominante techos - Concreto armado"
label	var	sisf_matecho2	"Material predominante techos - Madera"
label	var	sisf_matecho3	"Material predominante techos - Tejas"
label	var	sisf_matecho4	"Material predominante techos - Planchas de calamina. Fibra de cemento o similare"
label	var	sisf_matecho5	"Material predominante techos - Caña o estera con torta de barro"
label	var	sisf_matecho6	"Material predominante techos - Estera"
label	var	sisf_matecho7	"Material predominante techos - Paja, hojas de palmera"
label	var	sisf_matecho8	"Material predominante techos - Otro material"
label	var	sisf_matpiso1	"Material predominante pisos - Parquet o madera pulida"
label	var	sisf_matpiso2	"Material predominante pisos - Láminas asfálticas, vinílicos o similares"
label	var	sisf_matpiso3	"Material predominante pisos - Losetas, terrazas o similares"
label	var	sisf_matpiso4	"Material predominante pisos - Madera (Entablados)"
label	var	sisf_matpiso5	"Material predominante pisos - Cemento"
label	var	sisf_matpiso6	"Material predominante pisos - Tierra"
label	var	sisf_matpiso7	"Material predominante pisos - Otro material"
label	var	sisf_alumb1	"Tipo de alumbrado - Electricidad"
label	var	sisf_alumb2	"Tipo de alumbrado - Kerosene (mechero/lamparín)"
label	var	sisf_alumb3	"Tipo de alumbrado - Petróleo / gas (Lámpara)"
label	var	sisf_alumb4	"Tipo de alumbrado - Vela"
label	var	sisf_alumb5	"Tipo de alumbrado - Otro"
label	var	sisf_alumb6	"Tipo de alumbrado - No tiene"
label	var	sisf_abast1	"Tipo de abastecimiento de agua - Red pública dentro de la vivienda"
label	var	sisf_abast2	"Tipo de abastecimiento de agua - Red pública fuera de la viviend, pero dentro de"
label	var	sisf_abast3	"Tipo de abastecimiento de agua - Pilón de uso publico"
label	var	sisf_abast4	"Tipo de abastecimiento de agua - Camión-cisterna u otro similar"
label	var	sisf_abast5	"Tipo de abastecimiento de agua - pozo"
label	var	sisf_abast6	"Tipo de abastecimiento de agua - Río, acequia, manantial o similar"
label	var	sisf_abast7	"Tipo de abastecimiento de agua - Otro tipo"
label	var	sisf_serhig1	"El servicio higienico esta conectado a - Red pública dentro de la vivienda"
label	var	sisf_serhig2	"El servicio higienico esta conectado a - Red pública fuera de la viviend, pero d"
label	var	sisf_serhig3	"El servicio higienico esta conectado a - Pozo séptico"
label	var	sisf_serhig4	"El servicio higienico esta conectado a - Pozo ciego o negro/letrina"
label	var	sisf_serhig5	"El servicio higienico esta conectado a - Río, acequia o canal"
label	var	sisf_serhig6	"El servicio higienico esta conectado a - No tiene"
label	var	sisf_combusa1	"El combustible para cocinar - Electricidad"
label	var	sisf_combusa2	"El combustible para cocinar - Gas"
label	var	sisf_combusa3	"El combustible para cocinar - Kerosene"
label	var	sisf_combusa4	"El combustible para cocinar - Carbón"
label	var	sisf_combusa5	"El combustible para cocinar - Leña"
label	var	sisf_combusa6	"El combustible para cocinar - Bosta o estiercol"
label	var	sisf_combusa7	"El combustible para cocinar - Otro"
label	var	sisf_combusa8	"El combustible para cocinar - No cocina"
label	var	sisf_bien1	"Bienes del hogar- Equipo de sonido"
label	var	sisf_bien2	"Bienes del hogar- Televisor a color"
label	var	sisf_bien3	"Bienes del hogar- DVD"
label	var	sisf_bien4	"Bienes del hogar- Licuadora"
label	var	sisf_bien5	"Bienes del hogar- Refrigeradora/ congeladora"
label	var	sisf_bien6	"Bienes del hogar- Cocina a gas"
label	var	sisf_bien7	"Bienes del hogar- Teléfono fijo"
label	var	sisf_bien8	"Bienes del hogar- Plancha electrica"
label	var	sisf_bien9	"Bienes del hogar- Lavadora"
label	var	sisf_bien10	"Bienes del hogar- Computadora"
label	var	sisf_bien11	"Bienes del hogar- Horno Microondas"
label	var	sisf_bien12	"Bienes del hogar- Internet"
label	var	sisf_bien13	"Bienes del hogar- Cable"
label	var	sisf_bien14	"Bienes del hogar- Celular"
label	var	sisf_bien15	"Bienes del hogar- No tiene ninguno"
label	var	sisf_masc	"Sexo - Población hombre"
label	var	sisf_fem	"Sexo - Población mujer"
label	var	sisf_doc1	"Tipo de documento - DNI"
label	var	sisf_doc2	"Tipo de documento - Partida de nacimiento"
label	var	sisf_doc3	"Tipo de documento - Carnet de extranjeria"
label	var	sisf_doc4	"Tipo de documento - No tiene documento"
label	var	sisf_edad1	"Población - Menores de 1 año"
label	var	sisf_edad2	"Población - De 1 a 14 años"
label	var	sisf_edad3	"Población - De 15 a 29 años"
label	var	sisf_edad4	"Población - De 30 a 44 años"
label	var	sisf_edad5	"Población - De 45 a 64 años"
label	var	sisf_edad6	"Población - De 65 a más años"
label	var	sisf_parent1	"Parentesco - Jefe de Hogar"
label	var	sisf_parent2	"Parentesco - Conyuge"
label	var	sisf_parent3	"Parentesco - Hijo/a"
label	var	sisf_parent4	"Parentesco - Yerno / nuera"
label	var	sisf_parent5	"Parentesco - Nieto/a"
label	var	sisf_parent6	"Parentesco - Padres/ suegros"
label	var	sisf_parent7	"Parentesco - Heramno/ a"
label	var	sisf_parent8	"Parentesco - Trabajador del hogar"
label	var	sisf_parent9	"Parentesco - Pensionista"
label	var	sisf_parent10	"Parentesco - Otros parientes"
label	var	sisf_parent11	"Parentesco - Otros no parientes"
label	var	sisf_civ1	"Estado civil - Soltero/a"
label	var	sisf_civ2	"Estado civil - Casado/a"
label	var	sisf_civ3	"Estado civil - Conviviente"
label	var	sisf_civ4	"Estado civil - Separado/a"
label	var	sisf_civ5	"Estado civil - Divorciado/a"
label	var	sisf_civ6	"Estado civil - Viudo/a"
label	var	sisf_seg1	"Seguro - Essalud"
label	var	sisf_seg2	"Seguro - FFAA PNP"
label	var	sisf_seg3	"Seguro - Seguro privado"
label	var	sisf_seg4	"Seguro - SIS"
label	var	sisf_seg5	"Seguro - Otro"
label	var	sisf_seg6	"Seguro - No tiene"
label	var	sisf_lee1	"Sabe leer (14 a mas) - Si"
label	var	sisf_lee2	"Sabe leer (14 a mas) - No"
label	var	sisf_nivedu1	"Nivel educativo (14 a mas)- Ninguno"
label	var	sisf_nivedu2	"Nivel educativo (14 a mas)- Inicial"
label	var	sisf_nivedu3	"Nivel educativo (14 a mas)- Primaria"
label	var	sisf_nivedu4	"Nivel educativo (14 a mas)- Secundaria"
label	var	sisf_nivedu5	"Nivel educativo (14 a mas)- Superior no universitaria"
label	var	sisf_nivedu6	"Nivel educativo (14 a mas)- Superior universitaria"
label	var	sisf_nivedu7	"Nivel educativo (14 a mas)- Post grado u otro similar"
label	var	sisf_estud1	"Ultimo año o grado de estudios( 14 a mas) - Primer año o grado de estudio"
label	var	sisf_estud2	"Ultimo año o grado de estudios( 14 a mas) - Segundo año o grado de estudio"
label	var	sisf_estud3	"Ultimo año o grado de estudios( 14 a mas) - Tercer año o grado de estudio"
label	var	sisf_estud4	"Ultimo año o grado de estudios( 14 a mas) - Cuarto año o grado de estudio"
label	var	sisf_estud5	"Ultimo año o grado de estudios( 14 a mas) - Quinto año o grado de estudio"
label	var	sisf_estud6	"Ultimo año o grado de estudios( 14 a mas) - Sexto año o grado de estudio"
label	var	sisf_ocupa1	"Ocupacion ultimo mes (14 a mas) - Trabajador dependiente"
label	var	sisf_ocupa2	"Ocupacion ultimo mes (14 a mas) - Trabajador independiente"
label	var	sisf_ocupa3	"Ocupacion ultimo mes (14 a mas) - Empleador"
label	var	sisf_ocupa4	"Ocupacion ultimo mes (14 a mas) - Trabajador del hogar"
label	var	sisf_ocupa5	"Ocupacion ultimo mes (14 a mas) - Trabajador familiar no remunerado"
label	var	sisf_ocupa6	"Ocupacion ultimo mes (14 a mas) - Desempleado"
label	var	sisf_ocupa7	"Ocupacion ultimo mes (14 a mas) - Dedicado a los quehaceres del hogar"
label	var	sisf_ocupa8	"Ocupacion ultimo mes (14 a mas) - Estudiante"
label	var	sisf_ocupa9	"Ocupacion ultimo mes (14 a mas) - Jubilado"
label	var	sisf_ocupa10	"Ocupacion ultimo mes (14 a mas) - Sin actividad"
label	var	sisf_activ1	"Activifad economica (14 a mas) - Agrícola"
label	var	sisf_activ2	"Activifad economica (14 a mas) - Pecuaria"
label	var	sisf_activ3	"Activifad economica (14 a mas) - Forestal"
label	var	sisf_activ4	"Activifad economica (14 a mas) - Pesquera"
label	var	sisf_activ5	"Activifad economica (14 a mas) - Minera"
label	var	sisf_activ6	"Activifad economica (14 a mas) - Artesanal"
label	var	sisf_activ7	"Activifad economica (14 a mas) - Comercial"
label	var	sisf_activ8	"Activifad economica (14 a mas) - Servicios"
label	var	sisf_activ9	"Activifad economica (14 a mas) - Otros"
label	var	sisf_activ10	"Activifad economica (14 a mas) - Estado (gobierno)"
label	var	sisf_disca1	"Discapacidad - Visual"
label	var	sisf_disca2	"Discapacidad - Para oir"
label	var	sisf_disca3	"Discapacidad - Para hablar"
label	var	sisf_disca4	"Discapacidad - Para usar brazos y piernas"
label	var	sisf_disca5	"Discapacidad - Mental o intelectual"
label	var	sisf_disca6	"Discapacidad - No tiene"
label	var	sisf_prog1	"Programa social - Vaso de leche"
label	var	sisf_prog2	"Programa social - Comedor popular"
label	var	sisf_prog3	"Programa social - Desayuno o almuerzo"
label	var	sisf_prog4	"Programa social - Papilla o yapita"
label	var	sisf_prog5	"Programa social - Canasta alimentaria"
label	var	sisf_prog6	"Programa social - Juntos"
label	var	sisf_prog7	"Programa social - Techo propio o Mi vivienda"
label	var	sisf_prog8	"Programa social - Pension 65"
label	var	sisf_prog9	"Programa social - Cuna más"
label	var	sisf_prog10	"Programa social - Otros"
label	var	sisf_prog11	"Programa social - Ninguno"
label	var	sisf_lengua1	"Lengua - Quechua"
label	var	sisf_lengua2	"Lengua - Aymara"
label	var	sisf_lengua3	"Lengua - Ashaninka"
label	var	sisf_lengua4	"Lengua - Catellano"
label	var	sisf_lengua5	"Lengua - Idioma Extranjero"
label	var	sisf_lengua6	"Lengua - Es Sordomudo"
label	var	sisf_lengua7	"Lengua - Otro"
label	var	sisf_pea1	"PEA - Población Económicamente Activa Ocupada"
label	var	sisf_pea2	"PEA - Población Económicamente Activa Desocupada"
label	var	sis_pnbi1	"Porcentaje de hogares con Viviendas inadecuadas"
label	var	sis_pnbi2	"Porcentaje de hogares con vivienda en hacinamiento"
label	var	sis_pnbi3	"Porcentaje de hogares con vivienda sin servicios higienicos"
label	var	sis_pnbi5	"Porcentaje de hogares con alta dependencia economica"
label	var	sis_ptalum1	"Porcentaje de hogares con Alumbrado:  Electrico"
label	var	sis_ptalum2	"Porcentaje de hogares con Alumbrado: Kerocesene (mechero, lamparin)"
label	var	sis_ptalum3	"Porcentaje de hogares con Alumbrado: Ptroleo, gas (lampara)"
label	var	sis_ptalum4	"Porcentaje de hogares con Alumbrado: Vela"
label	var	sis_ptalum5	"Porcentaje de hogares con Alumbrado: Otro"
label	var	sis_ptalum6	"Porcentaje de hogares con Alumbrado: No tiene"
label	var	sis_pabasag1	"Porcentaje de hogares con Abastecimiento agua: Red publica dentro vivienda"
label	var	sis_pabasag2	"Porcentaje de hogares con Abastecimiento agua: Red publica fuera de la vivienda"
label	var	sis_pabasag3	"Porcentaje de hogares con Abastecimiento agua: Pilòn de uso pùblico"
label	var	sis_pabasag4	"Porcentaje de hogares con Abastecimiento agua: Camiòn- cisterna"
label	var	sis_pabasag5	"Porcentaje de hogares con Abastecimiento agua: Pozo"
label	var	sis_pabasag6	"Porcentaje de hogares con Abastecimiento agua: Rio, acequia, manantial"
label	var	sis_pabasag7	"Porcentaje de hogares con Abastecimiento agua: Otro"
label	var	sis_phodecap1	"Porcentaje de hogares con Tiempo en llegar a la capital del distrito: Menos de"
label	var	sis_phodecap2	"Porcentaje de hogares con Tiempo en llegar a la capital del distrito: mas de 24"
label	var	sis_phodecap3	"Porcentaje de hogares con Tiempo en llegar a la capital del distrito: Vive en l"
label	var	sis_nbi1	"Numero de hogares con Viviendas inadecuadas"
label	var	sis_nbi2	"Numero de hogares con vivienda en hacinamiento"
label	var	sis_nbi3	"Numero de hogares con vivienda sin servicios higienicos"
label	var	sis_nbi5	"Numero de hogares con alta dependencia economica"
label	var	sis_talum1	"Numero de hogares con Alumbrado:  Electrico"
label	var	sis_talum2	"Numero de hogares con Alumbrado: Kerocesene (mechero, lamparin)"
label	var	sis_talum3	"Numero de hogares con Alumbrado: Ptroleo, gas (lampara)"
label	var	sis_talum4	"Numero de hogares con Alumbrado: Vela"
label	var	sis_talum5	"Numero de hogares con Alumbrado: Otro"
label	var	sis_talum6	"Numero de hogares con Alumbrado: No tiene"
label	var	sis_abasag1	"Numero de hogares con Abastecimiento agua: Red publica dentro vivienda"
label	var	sis_abasag2	"Numero de hogares con Abastecimiento agua: Red publica fuera de la vivienda"
label	var	sis_abasag3	"Numero de hogares con Abastecimiento agua: Pilòn de uso pùblico"
label	var	sis_abasag4	"Numero de hogares con Abastecimiento agua: Camiòn- cisterna"
label	var	sis_abasag5	"Numero de hogares con Abastecimiento agua: Pozo"
label	var	sis_abasag6	"Numero de hogares con Abastecimiento agua: Rio, acequia, manantial"
label	var	sis_abasag7	"Numero de hogares con Abastecimiento agua: Otro"
label	var	sis_hodecap1	"Numero de hogares por Tiempo en llegar a la capital del distrito: Menos de 24 h"
label	var	sis_hodecap2	"Numero de hogares por Tiempo en llegar a la capital del distrito: mas de 24 hor"
label	var	sis_hodecap3	"Numero de hogares por Tiempo en llegar a la capital del distrito: Vive en la ca"
label	var	sis_trab6_10	"Nro miembros de 6 a 10 años que trabajan"
label	var	sis_trainfan	"Nro miembros de 6 a 14 años que trabajan"
label	var	sis_numocupa	"Nro miembros de miembros del hogar que trabajan"
label	var	sis_ocu1899	"Nro miembros entre 18 y 99 años que trabajan"
label	var	sis_comerci	"Nro miembros entre 15 y 99 años que trbajan en el sector comercio"
label	var	sis_jefeocup	"jefe del hogar ocupado"
label	var	sis_jefeinde	"jefe del hogar ocupado independiente"
label	var	sis_jefedepe	"jefe del hogar ocupado dependiente"
label	var	sis_jefeagric	"jefe del hogar ocupado en actividad agricola"
label	var	sis_jefecomer	"jefe del hogar ocupado en actividad comercial"
label	var	sis_jefeotro	"jefe del hogar ocupado en actividad otros"
label	var	sis_jefearte	"jefe del hogar ocupado en actividad artesanal , manufaturera, construccion, otro"
label	var	sis_jefeserv	"jefe del hogar ocupado en actividad de servicio"
label	var	sis_jefeestad	"jefe del hogar ocupado en actividad estado"
label	var	sis_discap	"Personas con discapacidad en el distrito"
label	var	sis_social	"Personas beneficiarias de algún programa social en el distrito"
label	var	sis_pdiscap	"proporcion por distrito de algún miembro hogar con discapacidad"
label	var	sis_psocial	"proporcion por distrito de algún miembro hogar beneficiaria programa social"
label	var	altitud1	"Altitud de la capital del distrito es menos de 2000 metros"
label	var	altitud2	"Altitud de la capital del distrito es más de 2000 metros"
label	var	altitud3	"Altitud de la capital del distrito es más de 3000 metros"
label	var	co_ua	"total de unidades agropecuarias"
label	var	co_parcelas	"total de parcelas que conduce en este distrito"
label	var	co_sup_total	"superficie total de todas las parcelas o chacras que trabaja o conduce en este d"
label	var	co_sup_agric	"superficie agrícola o superficie de tierras de cultivo (has)"
label	var	co_sup_agric~go	"superficie agrícola o superficie de tierras de cultivo (has) bajo riego"
label	var	co_sup_agric~no	"superficie agrícola o superficie de tierras de cultivo (has) bajo secano"
label	var	co_sup_noagric	"superficie no agrícola (has)"
label	var	co_otraclaset~a	"otra clase de tierras (has)"
label	var	co_sup_labran	"tierras de labranza (has)"
label	var	co_sup_cultit~s	"tierras con cultivos transitorios (has)"
label	var	co_sup_barbe	"tierras en barbecho (has)"
label	var	co_sup_descan	"tierras en descanso (has)"
label	var	co_sup_cultip~a	"tierras con cultivos permanentes (has)"
label	var	co_sup_pastcult	"pastos cultivados (has)"
label	var	co_sup_cultfo~s	"cultivos forestales (has)"
label	var	co_sup_cultas~i	"tierras con cultivos asociados (has)"
label	var	co_sup_pastnatu	"tierras con pastos naturales (has)"
label	var	co_sup_pastma~j	"pastos manejados (has)"
label	var	co_sup_pastno~j	"pastos no manejados (has)"
label	var	co_sup_montbosq	"tierras con montes y bosques (has)"
label	var	co_sup_cultiva	"superficie cultivada (has)"
label	var	co_sup_semcul~s	"superficie sembrada de cultivos transitorios"
label	var	co_parc_desta~m	"total de parcelas que destinan para alimentos de sus animales"
label	var	co_parc_venmerc	"total de parcelas que venden en el mercado"
label	var	co_parc_ventm~c	"total de parcelas que destinan para la venta del mercado nacional"
label	var	co_parc_ventm~e	"total de parcelas para venta del mercado exterior"
label	var	co_parc_agro	"total de parcelas para la agroindustria"
label	var	co_parc_con~ins	"total de parcelas que destinan su produccion para auto insumo"
label	var	co_parc_con~ons	"total de parcelas que destinan su produccion para autoconsumo"
label	var	co_parccomune~s	"total de parcelas que son de comuneros"
label	var	co_parcpropit~u	"total de parcelas que son de propietarios con titulo inscritos en registros públ"
label	var	co_agricola	"total de ua de tipo de actividad: agricola"
label	var	co_ganadovacuno	"total de ganado vacuno"
label	var	co_ganadoovino	"total de ganado ovino"
label	var	co_ganadoporc~o	"total de ganado porcino"
label	var	co_ganadoalpaca	"total de alpaca"
label	var	co_colmenas	"total de colmenas de abeja"
label	var	co_llamas	"tonal de llamas"
label	var	co_aves	"tonal de aves"
label	var	co_burros	"tonal de burros"
label	var	co_caballos	"tonal de caballos"
label	var	co_cabras	"tonal de cabras"
label	var	co_producleche	"total productores agropecuarios que tienen producción de leche"
label	var	co_vendeleche	"total productores agropecuarios que venden leche"
label	var	co_pecuario	"total de ua de tipo de actividad: pecuario"
label	var	co_agropecuario	"total de ua de tipo de actividad: agropecuario"
label	var	co_riego_p~vrio	"total de unidades agropecuarias que el riego proviene de rio"
label	var	co_riego_pro~zo	"total de unidades agropecuarias que el riego proviene de pozo"
label	var	co_riego_pro~na	"total de unidades agropecuarias que el riego proviene de laguna"
label	var	co_riego_prov~l	"total de unidades agropecuarias que el riego proviene de manantial"
label	var	co_riego_pro~sa	"total de unidades agropecuarias que el riego proviene de represa"
label	var	co_riego_p~orio	"total de unidades agropecuarias que el riego proviene de reservorio"
label	var	co_poztajoabi~o	"número de pozos a tajo abierto en las parcelas"
label	var	co_poztajoabi~a	"número de pozos a tajo abierto operativos en las parcelas"
label	var	co_poztubu	"número de pozos tubulares en las parcelas"
label	var	co_poztubuopera	"número de pozos tubulares operativos en las parcelas"
label	var	co_consaguari~t	"productores agropecuarios que consideran que el agua para riego está contaminada"
label	var	co_canalrevest	"total de canales o acequias que son de mampostería o están revestidos de cemento"
label	var	co_comiregantes	"total de productores agropecuarios que pertenece a alguna comisión de regantes"
label	var	co_semilaspla~s	"total de productores agropecuarios que usan semillas y/o plantones"
label	var	co_guanoestie~l	"total de roductores agropecuarios que aplica guano, estiercol u otro abono organ"
label	var	co_fertilizante	"total de productores agropecuarios aplican fertilizante quimico"
label	var	co_insecherbf~g	"total de productores agropecuarios que aplican insecticidas, herbicidas o fungic"
label	var	co_practica_a~a	"total de productores agropecuarios que hacen uso de practicas agricolas"
label	var	co_utilizanim~b	"productores agropecuarios utiliza animales para realizar trabajos agrícolas o pe"
label	var	co_utilizelec~b	"productores agropecuarios utiliza energía eléctrica para realizar trabajos agríc"
label	var	co_utiliztrac~b	"productores agropecuarios utiliza tractores para realizar trabajos agrícolas o p"
label	var	co_vacuna	"total de productores agropecuarios que vacunan sus animales"
label	var	co_bana	"total de productores agropecuarios que baña contra parásitos"
label	var	co_dosifica	"total de productores agropecuarios que efectúa dosificaciones"
label	var	co_alimentosb~n	"total de productores agropecuarios que utiliza alimentos balanceados"
label	var	co_inseminacion	"total de productores agropecuarios que efectúa inseminación artificial"
label	var	co_mejoramiento	"total de productores agropecuarios que utilizan sementales de raza para mejorami"
label	var	co_practica_p~a	"total de productores agropecuarios que hacen uso de prácticas pecuarias"
label	var	co_asesoria	"total de productores agropecuarios que ha recibido: asesoría empresarial"
label	var	co_asistencia	"total de productores agropecuarios que ha recibido: asistencia técnica"
label	var	co_capacitacion	"total de productores agropecuarios que ha recibido: capacitación"
label	var	co_aseasistcapa	"total de productores agropecuarios que recibio capacitación, asistencia técnica"
label	var	co_gesticredito	"total de productores agropecuarios que realizó gestiones para obtener un préstam"
label	var	co_obtucredito	"total de productores agropecuarios que obtuvo el préstamo o crédito que gestion"
label	var	co_trabpermeven	"total trabajadores remunerados permanentes y eventuales"
label	var	co_trabremupe~n	"total trabajadores remunerados permanentes"
label	var	co_famnorem_6~s	"total de trabajadores familiares no remunerado de 6 a mas años"
label	var	co_famnorem_1~s	"total de trabajadores familiares no remunerado de 14 a mas años"
label	var	co_asociacomite	"total de productores agropecuarios que pertenece a alguna asociación, comité o c"
label	var	co_siembramismo	"total de productores agropecuarios que siembra lo mismo"
label	var	co_mercaaseg	"total de productores agropecuarios que tienen mercado asegurado"
label	var	co_otrosingreso	"total de productores agropecuarios que realizan otra actividad que genere ingres"
label	var	co_actiprinc	"total de productores agropecuarios que tienen otra actividad principal que reali"
label	var	co_nummujeres	"numero de mujeres que son productores agropecuarios"
label	var	co_tienedni	"total de productores agropecuarios que cuentan con dni"
label	var	co_edadprom	"edad promedio del productor"
label	var	co_persoparti~o	"total de personas que no sea el productor que participan en las labores agropecu"
label	var	co_lengunativa	"total de productores agropecuarios con lenguan nativa/quechua/aymara/ashaninca/o"
label	var	co_tiempo_2	"total de productores agropecuario que el tiempo de recorrido menor de 2 horas qu"
label	var	co_tiempo_5	"total de productores agropecuario que el tiempo recorrido mayor a 5 horas en lle"
label	var	co_tiempo_3_5	"total de productores agropecuario que el tiempo recorrido de 3 a 5 horas en lleg"
label	var	co_tiempo_prom	"tiempo promedio en horas en llegar de su vivienda a la capital distrital"
label	var	co_tiempo_media	"tiempo mediana en horas en llegar de su vivienda a la capital distrital"
label	var	co_tiempo_2_p~c	"% productores agropecuarios que demoran en llegar menos de 2 horas a la capital"
label	var	co_tiempo_3_5~c	"% productores agropecuarios que demoran en llegar de 3 a 5 horas a la capital di"
label	var	co_tiempo_5_p~c	"% productores agropecuarios que demoran en llegar mas de 5 horas a la capital di"
label	var	in_101_1	"Número de niveles educativos x local escolar"
label	var	in_101_2	"Número de instituciones educativas x local escolar"
label	var	in_101_3	"Número local escolar"
label	var	in_103_t1	"Número de alumnos Educación básica"
label	var	in_103_t2	"Número de alumnos Educación superior no universitaria"
label	var	in_104_t1	"Número de aulas Educación básica"
label	var	in_104_t2	"Número de aulas Educación superior no universitaria"
label	var	in_105_r1	"Ratio-Número de alumnos/Número de aulas(Educación básica)"
label	var	in_105_r2	"Ratio-Número de alumnos/Número de aulas(Educación superior no universitaria)"
label	var	in_105_r3	"Mediana-distrito-Número de alumnos/Número de aulas(Educación básica)"
label	var	in_105_r4	"Mediana-distrito-Número de alumnos/Número de aulas(Educación superior no univers"
label	var	in_p2_trech	"Horas a la capital en el recorrido más accesible"
label	var	in_p2_ttramoh	"Horas a la capital en el tramo más dificultoso"
label	var	in_p2_trecm	"dummy-menos de una hora-recorrido más accesible"
label	var	in_p2_trecs	"dummy-menos de 24 horas-recorrido más accesible"
label	var	in_p2_trect	"dummy-más de 24 horas-recorrido más accesible"
label	var	in_p2_ttramom	"dummy-menos de una hora-tramo dificultoso"
label	var	in_p2_ttramos	"dummy-menos de 24 horas-tramo dificultoso"
label	var	in_p2_ttramot	"dummy-más de 24 horas-tramo dificultoso"
label	var	in_106_1	"dummy-Polidocente completa"
label	var	in_106_2	"dummy-Polidocente multigrado"
label	var	in_106_3	"dummy-Polidocente unidocente"
label	var	in_p1_c1	"dummy-clima calido"
label	var	in_p1_c2	"dummy-clima templado"
label	var	in_p1_c3	"dummy-clima frio"
label	var	in_p1_l1	"dummy-minima intensidad lluvia localidad"
label	var	in_p1_l2	"dummy-moderado intensidad lluvia localidad"
label	var	in_p1_l3	"dummy-torrencial intensidad lluvia localidad"
label	var	in_p1_hel	"dummy-En la localidad se producen heladas/friajes"
label	var	in_p1_gra	"dummy-En esta localidad cae granizada"
label	var	in_p1_vend	"dummy-En esta localidad se forman vendavales"
label	var	in_p3_lluvia	"dummy-peligros naturales en esta localidad? - lluvias"
label	var	in_p3_helada	"dummy-peligros naturales en esta localidad - heladas"
label	var	in_p3_sequia	"dummy-peligros naturales en esta localidad - sequías"
label	var	in_p3_granizo	"dummy-peligros naturales en esta localidad - granizadas"
label	var	in_p3_nevada	"dummy-peligros naturales en esta localidad - nevadas"
label	var	in_p3_vendaval	"dummy-peligros naturales en esta localidad - vendavales"
label	var	in_p3_volcan	"dummy-peligros naturales en esta localidad - actividades volcánicas"
label	var	in_p4_inund	"dummy-peligros socionaturales en esta localidad - inundaciones"
label	var	in_p4_desliz	"dummy-peligros socionaturales en esta localidad -deslizamientos"
label	var	in_p4_huayc	"dummy-peligros socionaturales en esta localidad - huaycos/aluviones/aludes"
label	var	in_p4_derrum	"dummy-peligros socionaturales en esta localidad -derrumbes"
label	var	in_p4_deser	"dummy-peligros socionaturales en esta localidad - desertificaciones"
label	var	in_p4_salin	"dummy-peligros socionaturales en esta localidad -salinización de los suelos"
label	var	in_p5_ener	"dummy-En esta localidad cuentan con servicio de energía eléctrica"
label	var	in_p5_aguap	"dummy-En esta localidad cuentan con servicio de agua potable"
label	var	in_p5_alcant	"dummy-En esta localidad cuentan con servicio de alcantarillado"
label	var	in_p5_telef	"dummy-En esta localidad cuentan con servicio de telefonía fija"
label	var	in_p5_telem	"dummy-En esta localidad cuentan con servicio de telefonía móvil"
label	var	in_p5_inter	"dummy-En esta localidad cuentan con servicio de internet"
label	var	in_p7_ener	"dummy-En este local cuentan con servicio de energía eléctrica"
label	var	in_p7_aguap	"dummy-En este local cuentan con servicio de agua potable"
label	var	in_p7_alcant	"dummy-En este local cuentan con servicio de alcantarillado"
label	var	in_p7_telef	"dummy-En este local cuentan con servicio de telefonía fija"
label	var	in_p7_telem	"dummy-En este local cuentan con servicio de telefonía móvil"
label	var	in_p7_inter	"dummy-En este local cuentan con servicio de internet"
label	var	in_t1_herrad	"dummy-Camino Herradura-Tipo de via que utiliza de la capital del distrito +acces"
label	var	in_t1_trocha	"dummy-Trocha Carrozable-Tipo de vía que utiliza de la capital del distrito + acc"
label	var	in_t1_afirmad	"dummy-Carretera afirmada-Tipo de vía que utiliza de la capital del distrito + ac"
label	var	in_t1_asfalt	"dummy-Vía asfaltada-Tipo de vía que utiliza de la capital del distrito + accesib"
label	var	in_t1_terrest	"dummy-Terrestre-transporte desplazarse de la capital del distrito + accesible al"
label	var	in_t2_flm	"dummy-Fluvial/lacustre/marítimo-transporte capital distrito + accesible al le?"
label	var	in_t3_aereo	"dummy-Aéreo-transporte + capital del distrito+accesible al le?"
label	var	in_p1_01	"dummy-llano topografia terreno local"
label	var	in_p1_02	"dummy-inclinado topografia terreno local"
label	var	in_p1_03	"dummy-muy inclinado topografia terreno local"
label	var	in_p1_04	"dummy-accidentado topografia terreno local"
label	var	ced_int	"Cantidad de instituciones educativas que existe en el local escolar"
label	var	ced_mat	"Cantidad de matriculados en el sistema educativo"
label	var	ced_mat_inicial	"Cantidad de matriculados en el sistema educativo para el nivel inicial"
label	var	ced_mat_prima~a	"Cantidad de matriculados en el sistema educativo para el nivel primaria"
label	var	ced_mat_secun~a	"Cantidad de matriculados en el sistema educativo para el nivel secundaria"
label	var	ced_mat_otros	"Cantidad de matriculados en el sistema educativo para el nivel otros"
label	var	ced_doc	"Cantidad de docentes en el sistema educativo"
label	var	ced_ten_pro	"Cantidad de locales escolares con condicion de tenencia propio"
label	var	ced_lab	"Cantidad de locales escolares con laboratorio"
label	var	ced_bib	"Cantidad de locales escolares con almenos una biblioteca"
label	var	ced_lib	"cantidad de libros aproximado en todas las bibliotecas escolars"
label	var	ced_com_ope	"Cantidad de locales escolares con almenos una computadora operativa"
label	var	ced_com_ope_tot	"cantidad de computadoras operativas en todos los locales escolares"
label	var	ced_com_ope_int	"cantidad de computadoras operativas en todos los locales escolares con conexion"
label	var	ced_sil	"cantidad de sillas en todos los locales escolares"
label	var	ced_aul_piz	"cantidad de aulas sin pizarra o con pizarras en mal estado"
label	var	ced_alu_pub	"Cantidad de locales escolares con alumbrado por red publica"
label	var	ced_alu_sin	"Cantidad de locales escolares sin alumbrado"
label	var	ced_agu_pub	"Cantidad de locales escolares con suministro por red publica"
label	var	ced_ser_agu	"Cantidad de locales escolares con servicios de aguas de lunes a viernes en todo"
label	var	ced_ssh_pub	"Cantidad dfe locales escolares con servicios higiénico conectado a red publica d"
label	var	ced_ele_cp	"Cantidad de locales escolares que declaran tener electricidad en el centro pobla"
label	var	ced_cab_cp	"Cantidad de locales escolares que declaran tener cabina de internet en el centro"
label	var	ced_tie_dis	"Cantidad de tiempo total en horas de demora en llegar a la municipalidad del dis"
label	var	ced_pel_ubi	"Cantidad de locales escolares que declaran tener peligros asociados a la ubicaci"
label	var	ced_pex_lad	"Cantidad de locales escolares cuyo pabellon tiene como material predominante en"
label	var	ced_tec_cal	"Cantidad de locales escolares cuyo pabellon tiene como material predominante en"
label	var	ced_pis_cem	"Cantidad de locales escolares cuyo pabellon tiene como material predominante en"
label	var	ced_aul_fis	"Cantidad de aulas donde se aprecia en las paredes filtraciones, fisuras o grieta"
label	var	ced_cant_esp	"Cantidad de espacios educativos y/o administrativos en todos los locales escolar"
label	var	ced_cant_aul	"Cantidad de aulas que se utilizan en todos los locales escolares"
label	var	ced_num_ejem	"Cantidad de ejemplares recibidos en primaria y secundaria para las areas de comu"
label	var	ced_num_secc	"Número de secciones en primaria y secundaria"
label	var	ced_int_p	"Cantidad de instituciones educativas que existe en el local escolar"
label	var	ced_mat_p	"Cantidad de matriculados en el sistema educativo"
label	var	ced_mat_inici~p	"Cantidad de matriculados en el sistema educativo para el nivel inicial"
label	var	ced_mat_prima~p	"Cantidad de matriculados en el sistema educativo para el nivel primaria"
label	var	ced_mat_secun~p	"Cantidad de matriculados en el sistema educativo para el nivel secundaria"
label	var	ced_mat_otros_p	"Cantidad de matriculados en el sistema educativo para el nivel otros"
label	var	ced_doc_p	"Cantidad de docentes en el sistema educativo"
label	var	ced_ten_pro_p	"Cantidad de locales escolares con condicion de tenencia propio"
label	var	ced_lab_p	"Cantidad de locales escolares con laboratorio"
label	var	ced_bib_p	"Cantidad de locales escolares con almenos una biblioteca"
label	var	ced_lib_p	"cantidad de libros aproximado en todas las bibliotecas escolars"
label	var	ced_com_ope_p	"Cantidad de locales escolares con almenos una computadora operativa"
label	var	ced_com_ope_t~p	"cantidad de computadoras operativas en todos los locales escolares"
label	var	ced_com_ope_i~p	"cantidad de computadoras operativas en todos los locales escolares con conexion"
label	var	ced_sil_p	"cantidad de sillas en todos los locales escolares"
label	var	ced_aul_piz_p	"cantidad de aulas sin pizarra o con pizarras en mal estado"
label	var	ced_alu_pub_p	"Cantidad de locales escolares con alumbrado por red publica"
label	var	ced_alu_sin_p	"Cantidad de locales escolares sin alumbrado"
label	var	ced_agu_pub_p	"Cantidad de locales escolares con suministro por red publica"
label	var	ced_ser_agu_p	"Cantidad de locales escolares con servicios de aguas de lunes a viernes en todo"
label	var	ced_ssh_pub_p	"Cantidad dfe locales escolares con servicios higiénico conectado a red publica d"
label	var	ced_ele_cp_p	"Cantidad de locales escolares que declaran tener electricidad en el centro pobla"
label	var	ced_cab_cp_p	"Cantidad de locales escolares que declaran tener cabina de internet en el centro"
label	var	ced_tie_dis_p	"Cantidad de tiempo total en horas de demora en llegar a la municipalidad del dis"
label	var	ced_pel_ubi_p	"Cantidad de locales escolares que declaran tener peligros asociados a la ubicaci"
label	var	ced_pex_lad_p	"Cantidad de locales escolares cuyo pabellon tiene como material predominante en"
label	var	ced_tec_cal_p	"Cantidad de locales escolares cuyo pabellon tiene como material predominante en"
label	var	ced_pis_cem_p	"Cantidad de locales escolares cuyo pabellon tiene como material predominante en"
label	var	ced_aul_fis_p	"Cantidad de aulas donde se aprecia en las paredes filtraciones, fisuras o grieta"
label	var	ced_cant_esp_p	"Cantidad de espacios educativos y/o administrativos en todos los locales escolar"
label	var	ced_cant_aul_p	"Cantidad de aulas que se utilizan en todos los locales escolares"
label	var	ced_num_ejem_p	"Cantidad de ejemplares recibidos en primaria y secundaria para las areas de comu"
label	var	ced_num_secc_p	"Número de secciones en primaria y secundaria"
label	var	ece_clcantalr~2	"Cantidad de alumnos reportado por SIAGIE"
label	var	ece_clcantale~2	"Cantidad de alumnos evaluados en Comprension lectora"
label	var	ece_clnest~2012	"Total de alumnos En inicio en comprension lectora"
label	var	ece_clpestpr_~2	"Total de alumnos En proceso en comprension lectora"
label	var	ece_clpestsat~2	"Total de alumnos Satisfactorio en comprension lectora"
label	var	ece_clmedp~2012	"Medida promedio de las IE equiparada con 2007 en comprension lectora"
label	var	ece_mtcant~2012	"Cantidad de alumnos evaluados en matematica"
label	var	ece_mtnestin_~2	"Total de alumnos En inicio en matematica"
label	var	ece_mtnestpr_~2	"Total de alumnos En proceso en matematica"
label	var	ece_mtnestsat~2	"Total de alumnos Satisfactorio en matematica"
label	var	ece_mtmedp~2012	"Medida promedio de las IE equiparada con 2007 en matematica"
label	var	ece_clcantalr~3	"Cantidad de alumnos reportado por SIAGIE"
label	var	ece_clcantale~3	"Cantidad de alumnos evaluados en Comprension lectora"
label	var	ece_clnest~2013	"Total de alumnos En inicio en comprension lectora"
label	var	ece_clpestpr_~3	"Total de alumnos En proceso en comprension lectora"
label	var	ece_clpestsat~3	"Total de alumnos Satisfactorio en comprension lectora"
label	var	ece_clmedp~2013	"Medida promedio de las IE equiparada con 2007 en comprension lectora"
label	var	ece_mtcant~2013	"Cantidad de alumnos evaluados en matematica"
label	var	ece_mtnestin_~3	"Total de alumnos En inicio en matematica"
label	var	ece_mtnestpr_~3	"Total de alumnos En proceso en matematica"
label	var	ece_mtnestsat~3	"Total de alumnos Satisfactorio en matematica"
label	var	ece_mtmedp~2013	"Medida promedio de las IE equiparada con 2007 en matematica"
label	var	ren_ten_prop	"Cantidad de locales municipales con condición de propiedad: Propio"
label	var	ren_ten_alq	"Cantidad de locales municipales con condición de propiedad: Alquilado"
label	var	ren_ten_ced	"Cantidad de locales municipales con condición de propiedad: Cedido"
label	var	ren_maq_pes	"Municipalidades que tienen maquinaria pesada"
label	var	ren_veh_equ	"Municipalidades que tienen vehículos y equipos"
label	var	ren_pag_web	"Municipalidades que tienen Página Web"
label	var	ren_tef_fij	"Municipalidades que tienen Telefonía fija"
label	var	ren_fax	"Municipalidades que tienen Fax"
label	var	ren_cel	"Municipalidades que tienen Teléfono celular"
label	var	ren_red	"Municipalidades que disponen de red informática local"
label	var	ren_acc_int	"Municipalidades con acceso a Internet"
label	var	ren_comp_int	"Computadoras conectadas a Internet en la municipalidad"
label	var	ren_sist_inf	"Municipalidades que tienen sistema informático"
label	var	ren_total_trab	"Total de trabajadores en la municipalidad"
label	var	ren_trab_276_~b	"Total de trabajadores contratados bajo Decreto Legislativo N° 276 Nombrado"
label	var	ren_trab_276_~r	"Total de trabajadores contratados bajo Decreto Legislativo N° 276 Contratado"
label	var	ren_trab_728	"Total de trabajadores contratados bajo Decreto Legislativo N° 728"
label	var	ren_trabcas	"Total de trabajadores con Contrato Administrativo de Servicios"
label	var	ren_trab_loc	"Total de trabajadores con contrato de Servicios de Terceros (Locación de Servici"
label	var	ren_pens	"Municipalidades que tienen Pensionistas del (D. L . 20530)"
label	var	ren_ccl	"Municipalidades que tienen constituido el Consejo de Coordinación Local (CCL)"
label	var	ren_ccl_actv	"Municipalidades que informaron que los Consejo de Coordinación Local (CCL) ejecu"
label	var	ren_catast	"Municipalidades que tienen datos de catastro"
label	var	ren_acc_gest_~s	"Municipalidades que implementaron acciones en la gestión para resultados"
label	var	ren_disp_ter_~v	"Municipalidades que disponen de terrenos para vivienda"
label	var	ren_obr_rep	"Municipalidades que realizaron obras de reparación y construcción de pistas, ver"
label	var	ren_rec_res	"Municipalidades que realizaron recojo de residuos sólidos"
label	var	ren_exp_car_san	"Municipalidades que expidieron carnés de sanidad"
label	var	ren_ven_amb_reg	"Municipalidades que tienen vendedores ambulantes registrados"
label	var	ren_ban_pub	"Municipalidades que tienen baños de uso público en el distrito"
label	var	ren_cons_arv	"Municipalidades que realizan conservación de áreas verdes"
label	var	ren_cab_pub	"Municipalidades que brindan servicio de cabinas públicas de Internet"
label	var	ren_bib_mun	"Municipalidades que tienen Biblioteca Municipal"
label	var	ren_ins_dep	"Municipalidades que tienen instalaciones deportivas"
label	var	ren_loc_rec_c~t	"Municipalidades que tienen locales para uso recreacional y cultural"
label	var	ren_demuna	"Municipalidades que tienen Defensoría Municipal del Niño y del Adolescente"
label	var	ren_loc_salud	"Municipalidades que informaron que cuentan con locales para la atención de la sa"
label	var	ren_clu_mad	"Cantidad de Club de madres"
label	var	ren_vas_lec	"Cantidad de Comité del Programa Vaso de Leche"
label	var	ren_com_pop	"Cantidad de Comedores Populares"
label	var	ren_cen_adu_may	"Cantidad de Club y Centro del Adulto Mayor"
label	var	ren_org_juv	"Cantidad de Organizaciones juveniles"
label	var	ren_ben_prog_~c	"Cantidad de Beneficiarios de Programas de Leche"
label	var	ren_prob_seg	"Municipalidades que informaron sobre los problemas que afectan la seguridad"
label	var	ren_acc_prev_~c	"Municipalidades que realizaron acciones para prevenir el consumo de drogas y alc"
label	var	ren_org_seg_vec	"Municipalidades que tienen registradas Organizaciones de Seguridad Vecinal y Com"
label	var	ren_serenz	"Municipalidades que tienen Serenazgo"
label	var	ren_mic_peq_emp	"Municipalidades que registraron Micro y Pequeñas Empresas"
label	var	ren_ofc_prog_~v	"Municipalidades que tienen Oficina de Programación de Inversiones"
label	var	ren_prod_art	"Municipalidades que informaron que existe producción artesanal en el distrito"
label	var	ren_acc_tur	"Municipalidades que realizaron acciones para incentivar el turismo"
label	var	ren_fuen_cont	"Municipalidades que informaron que existen fuentes contaminantes en el distrito"
label	var	ren_alum_pub	"Municipalidades que informaron que tienen cobertura del alumbrado público en el"
label	var	ren_agu_pot	"Municipalidades que informaron que tienen cobertura de la red de agua potable en"
label	var	ren_agu_ser_tra	"Municipalidades que informaron que las aguas servidas reciben tratamiento"
label	var	ren_sis_des	"Municipalidades que informaron sobre la existencia del sistema de desagüe en el"
label	var	imp_re	"Tipo de imputacion en la base de Renamu"
label	var	ceng_c8p1_5	"El Gobierno Municipal cuenta con equipos de cómputo"
label	var	ceng_c8p2a_1	"Cantidad de Pcs que tienen acceso a la Red Informática Local del Municipio"
label	var	ceng_c8p2a_2	"Cantidad de Pcs que tienen acceso a internet en el local municipal"
label	var	ceng_c8p4_2	"El gobierno municipal cuenta con tierras y terrenos"
label	var	ceng_c8p4a_3_1	"Cantidad de camionetas y autos operativos tiene la municipalidad"
label	var	ceng_c8p4_5	"El gobierno municipal cuenta con camiones recolectores de basura"
label	var	ceng_c8p8_1	"Existe problemas de catastro desactualizado en la municipalidad"
label	var	ceng_c8p8_2	"Existe problemas de falta de personal calificado en la municipalidad"
label	var	ceng_c8p8_4	"Existe problemas de evasión, fraude, etc en el proceso de recaudación en la muni"
label	var	ceng_c8p8_5	"Existe problemas de morosidad en la municipalidad"
label	var	ceng_c8p8_7	"Existe problemas de Fiscalización insuficiente en la municipalidad"
label	var	ceng_c8p12_2	"La municipalidad cuenta con Plan de Desarrollo Institucional vigente aprobado"
label	var	ceng_c8p12_3	"La municipalidad cuenta con Plan de Desarrollo Local vigente aprobado"
label	var	ceng_c9p1_1	"El municipio otorgó licencias de apertura a Hoteles, hostales y otros establecim"
label	var	ceng_c9p1a_2	"Cantidad de Restaurantes a los que se le otorgó licencia de apertura"
label	var	ceng_c9p1a_3	"Cantidad de Agencias de viaje a los que se le otorgó licencia de apertura"
label	var	ceng_c9p1a_5	"Cantidad de Peluquerías y salones spa a los que se le otorgó licencia de apertur"
label	var	ceng_c9p1a_7	"Cantidad de Entidades financieras y de seguros a los que se le otorgó licencia d"
label	var	ceng_c9p1a_13	"Cantidad de Bodegas a los que se le otorgó licencia de apertura"
label	var	ceng_c9p1a_14	"Cantidad de Farmacias y boticas a los que se le otorgó licencia de apertura"
label	var	ceng_c9p1a_15	"Cantidad de Panaderías a los que se le otorgó licencia de apertura"
label	var	ceng_c9p1a_16	"Cantidad de Ferreterías a los que se le otorgó licencia de apertura"
label	var	ceng_c9p1a_25	"Cantidad de establecimientos de Transporte a los que se le otorgó licencia de ap"
label	var	ceng_c9p1_26	"La municipalidad otorgó licencias para establecimiento de Cabinas públicas de In"
label	var	ceng_c9p1a_26	"Cantidad de Cabinas públicas de Internet que la municipalidad otorgó licencias"
label	var	ceng_c9p2a_2	"Cantidad de Viviendas unifamiliares a los que se le otorgó licencia de edificaci"
label	var	ceng_c9p2a_3	"Cantidad de Viviendas multifamiliares a los que se le otorgó licencia de edifica"
label	var	ceng_c9p2a_4	"Cantidad de Hoteles, hostales y otros establecimientos de hospedaje a los que se"
label	var	ceng_c9p4a_2	"Cantidad de Restaurantes que están registrados en la municipalidad"
label	var	ceng_c9p4a_3	"Cantidad de Agencias de viaje que están registrados en la municipalidad"
label	var	ceng_c9p4a_6	"Cantidad de Empresas de transporte urbano que están registrados en la municipali"
label	var	ceng_c9p4a_11	"Cantidad de Entidades financieras y de seguros que están registrados en la munic"
label	var	ceng_c9p4a_13	"Cantidad de Discotecas que están registrados en la municipalidad"
label	var	ceng_c9p5a_1	"Cantidad de Centros comunitarios telefónicos y/o locutorios en el distrito"
label	var	ceng_c9p5a_3	"Cantidad de Oficinas de correo en el distrito"
label	var	ceng_c9p5a_4	"Cantidad de Antenas parabólicas con servicio de Internet en el distrito"
label	var	ceng_c9p5a_5	"Cantidad de Antenas parabólicas con servicios de voz (telefonía y radio) en el d"
label	var	ceng_c9p5a_6	"Cantidad de Cabinas públicas de Internet en el distrito"
label	var	ceng_c10p1a_2	"Cantidad de Comités de Base del Programa del Vaso de Leche en el distrito"
label	var	ceng_c10p1b_2	"Cantidad de beneficiarios/afiliados de Comités de Base del Programa del Vaso de"
label	var	ceng_c10p1a_3	"Cantidad de Comedores Populares en el distrito"
label	var	ceng_c10p1b_3	"Cantidad de beneficiarios/afiliados del Comedor Popular en el distrito"
label	var	ceng_c10p2a_1	"Cantidad de Niñas y Niños de 0 a 6 años beneficiarias del programa de vaso de le"
label	var	ceng_c10p2a_2	"Cantidad de Niñas y Niños de 0 a 3 años beneficiarias del programa de vaso de le"
label	var	ceng_c10p2a_3	"Cantidad de Niñas y Niños de 4 a 5 años beneficiarias del programa de vaso de le"
label	var	ceng_c10p2a_4	"Cantidad de Niñas y Niños de 6 años beneficiarias del programa de vaso de leche"
label	var	ceng_c10p2a_5	"Cantidad de Niñas y Niños de 7 a 13 años beneficiarias del programa de vaso de l"
label	var	ceng_c10p2a_6	"Cantidad de Madres gestantes beneficiarias del programa de vaso de leche en el d"
label	var	ceng_c10p2a_7	"Cantidad de Madres en periodo de lactancia beneficiarias del programa de vaso de"
label	var	ceng_c10p2a_8	"Cantidad de Personas afectadas con tuberculosis beneficiarias del programa de va"
label	var	ceng_c10p2a_9	"Cantidad de Adulto Mayor beneficiarias del programa de vaso de leche en el distr"
label	var	ceng_c10p2a_10	"Cantidad de personas con discapacidad y otros casos sociales beneficiarias del p"
label	var	ceng_c10p2a_total	"Cantidad Total de beneficiarios del programa de vaso de leche en el distrito"
label	var	ceng_c10p3a_1	"Cantidad de casos de Pensión de alimentos atendidos en la municipalidad"
label	var	ceng_c11p1a_1	"Cantidad de Estadios que la municipalidad administra"
label	var	ceng_c11p1a_2	"Cantidad de Complejos deportivos que la municipalidad administra"
label	var	ceng_c11p1a_4	"Cantidad de Losas multideportivas que la municipalidad administra"
label	var	ceng_c11p1a_10	"Cantidad de Coliseos deportivos que la municipalidad administra"
label	var	ceng_c11p2a_1	"Área en m2 de Plazas donde la municipalidad realizó conservación de áreas verdes"
label	var	ceng_c11p2a_2	"Área en m2 de Parques (Zonales, zoológicos y otros) donde la municipalidad reali"
label	var	ceng_c11p2a_3	"Área en m2 de Jardines y óvalos donde la municipalidad realizó conservación de á"


*-----------------------------------*
*		1.2.	Clean variables		*
*-----------------------------------*

	rename ccpp ubigeo_ccpp
	rename departamento 	dpto
	rename provincia 		prov
	rename distrito 		dist
	rename centropoblado 	ccpp

*	Ubigeo at district, province and region level
	
	gen ubigeo_dist=substr(ubigeo_ccpp,1,6)
	gen ubigeo_prov=substr(ubigeo_ccpp,1,4)
	gen ubigeo_dpto=substr(ubigeo_ccpp,1,2)

	order ubigeo_dist ubigeo_prov ubigeo_dpto, after(ubigeo_ccpp)

*	Urban/Rural dummy
	rename area urb_rur_ccpp_2013
	replace urb_rur_ccpp_2013="1" if urb_rur=="Urbano"
	replace urb_rur_ccpp_2013="0" if urb_rur=="Rural"
	destring urb_rur_ccpp_2013, replace
	
	label def urb_rur_lb 1 Urbano 0 Rural
	label val urb_rur_ccpp_2013 urb_rur_lb

*merge 1:1 Departamento Provincia Distrito CCPP using "$a\2 data\communities_sisfoh.dta" 
* reclink ubigeo_dist CCPP using "$a\2 data\communities_sisfoh.dta", idm(idm2) idu(idu)  gen(match) minscore(.9)

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

gen idu_sisfoh=_n

*-------------------------------------------------------*
*		1.3.	Create outcome variables and ratios		*
*-------------------------------------------------------*

*---------------------------------------------------*
*		1.3.1.	Characteristics of the house		*
*---------------------------------------------------*

	gen		prop_pared_ladrillo = sisf_matpared1/viv
	gen		prop_pared_piedra	= sisf_matpared2/viv
	gen		prop_pared_adobe	= sisf_matpared3/viv
	gen		prop_pared_quincha	= sisf_matpared4/viv
	gen		prop_pared_barro	= sisf_matpared5/viv
	gen		prop_pared_madera	= sisf_matpared6/viv
	gen		prop_pared_estera	= sisf_matpared7/viv
	gen		prop_pared_otro		= sisf_matpared8/viv

	gen		prop_techo_concreto = sisf_matecho1/viv
	gen		prop_techo_madera	= sisf_matecho2/viv
	gen		prop_techo_teja		= sisf_matecho3/viv
	gen		prop_techo_calamina	= sisf_matecho4/viv
	gen		prop_techo_estera	= sisf_matecho6/viv
	gen		prop_techo_paja		= sisf_matecho7/viv

	gen		prop_piso_parquet	= sisf_matpiso1/viv
	gen		prop_piso_lamina	= sisf_matpiso2/viv
	gen		prop_piso_loseta	= sisf_matpiso3/viv
	gen		prop_piso_tabla		= sisf_matpiso4/viv
	gen		prop_piso_cemento	= sisf_matpiso5/viv
	gen		prop_piso_tierra	= sisf_matpiso6/viv
	gen		prop_piso_otro		= sisf_matpiso7/viv
	
	gen		prop_mujeres		= sisf_fem/pob
*-------------------------------------------*
*		1.3.2.	Services in the house		*
*-------------------------------------------*
	
	gen		prop_alumbrado_elect	= sisf_alumb1/viv
	gen		prop_alumbrado_kerosene = sisf_alumb2/viv
	gen		prop_alumbrado_lampara 	= sisf_alumb3/viv
	gen		prop_alumbrado_vela		= sisf_alumb4/viv
	gen		prop_alumbrado_ninguno	= sisf_alumb6/viv
	
	gen		prop_agua_redpubdentro	= sisf_abast1/viv
	gen		prop_agua_redpubfuera	= sisf_abast2/viv
	gen		prop_agua_pilon			= sisf_abast3/viv
	gen		prop_agua_cisterna		= sisf_abast4/viv
	gen		prop_agua_pozo			= sisf_abast5/viv
	gen		prop_agua_rio			= sisf_abast6/viv
	gen		prop_agua_otro			= sisf_abast7/viv
	
	gen		prop_saneamiento_redpubdentro	= sisf_serhig1/viv
	gen		prop_saneamiento_redpubfuera	= sisf_serhig2/viv
	gen		prop_saneamiento_pozo			= sisf_serhig3/viv
	gen 	prop_saneamiento_letrina		= sisf_serhig4/viv
	gen		prop_saneamiento_rio			= sisf_serhig5/viv
	gen		prop_saneamiento_ninguno		= sisf_serhig6/viv
	
	gen		prop_combust_elect		= sisf_combusa1/hog
	gen		prop_combust_gas		= sisf_combusa2/hog
	gen		prop_combust_kerosene	= sisf_combusa3/hog
	gen		prop_combust_carbon		= sisf_combusa4/hog
	gen		prop_combust_lea		= sisf_combusa5/hog
	gen		prop_combust_bosta		= sisf_combusa6/hog
	gen		prop_combust_otro		= sisf_combusa7/hog
	gen		prop_combust_nococina	= sisf_combusa8/hog
	
*---------------------------*
*		1.3.3.	Assets		*
*---------------------------*

	gen		prop_asset_equipsonido	= sisf_bien1/hog
	gen		prop_asset_tvcolor		= sisf_bien2/hog
	gen		prop_asset_dvd			= sisf_bien3/hog
	gen		prop_asset_licuadora	= sisf_bien4/hog
	gen		prop_asset_refri		= sisf_bien5/hog
	gen		prop_asset_cocinagas	= sisf_bien6/hog
	gen		prop_asset_telefonofijo	= sisf_bien7/hog
	gen		prop_asset_plancha		= sisf_bien8/hog
	gen		prop_asset_lavadora		= sisf_bien9/hog
	gen		prop_asset_compu		= sisf_bien10/hog
	gen		prop_asset_microondas	= sisf_bien11/hog
	gen		prop_asset_internet		= sisf_bien12/hog
	gen		prop_asset_cable		= sisf_bien13/hog
	gen		prop_asset_celular		= sisf_bien14/hog
	gen		prop_asset_ninguno		= sisf_bien15/hog
	
*---------------------------------------*
*		1.3.4.	Age distribution		*
*---------------------------------------*	
	
	gen		prop_edad_u1		= sisf_edad1/pob
	gen		prop_edad_1_14		= sisf_edad2/pob
	gen		prop_edad_15_29		= sisf_edad3/pob
	gen		prop_edad_30_44		= sisf_edad4/pob
	gen		prop_edad_45_64		= sisf_edad5/pob
	gen		prop_edad_65		= sisf_edad6/pob
			
	gen 	edad_15mas			= sisf_edad3 + sisf_edad4 + sisf_edad5 + sisf_edad6
	gen		prop_edad_15		= edad_15mas/pob	
	
*-----------------------------------------------*
*		1.3.5.	Affilitation to insurance		*
*-----------------------------------------------*						 
						 
	gen		prop_seguro_essalud		= sisf_seg1/pob
	gen		prop_seguro_ffaapnp		= sisf_seg2/pob
	gen		prop_seguro_privado		= sisf_seg3/pob
	gen		prop_seguro_sis			= sisf_seg4/pob
	gen		prop_seguro_ninguno		= sisf_seg6/pob
	
*-------------------------------*
*		1.3.6.	Education		*
*-------------------------------*

	gen		prop_lee_si		= sisf_lee1/edad_15mas
	gen		prop_lee_no		= sisf_lee2/edad_15mas

	gen		prop_educ_ninguno		= sisf_nivedu1/edad_15mas
	replace prop_educ_ninguno		= 1 if prop_educ_ninguno>1
	gen		prop_educ_inicial		= sisf_nivedu2/edad_15mas
	gen		prop_educ_primaria		= sisf_nivedu3/edad_15mas
	replace prop_educ_primaria 		= 1 if prop_educ_primaria>1
	gen		prop_educ_secundaria	= sisf_nivedu4/edad_15mas
	replace prop_educ_secundaria	= 1 if prop_educ_secundaria>1
	gen		prop_educ_tecnica		= sisf_nivedu5/edad_15mas
	gen		prop_educ_universitaria = sisf_nivedu6/edad_15mas
	gen		prop_educ_postgrado		= sisf_nivedu7/edad_15mas
	
*-------------------------------------------------------*
*		1.3.7.	Economic Activity and employment		*
*-------------------------------------------------------*

	gen		prop_actividad_agricola		= sisf_activ1/edad_15mas
	gen		prop_actividad_pecuaria		= sisf_activ2/edad_15mas
	gen		prop_actividad_agropec		= (sisf_activ1 + sisf_activ2)/edad_15mas
	gen		prop_actividad_forestal		= sisf_activ3/edad_15mas
	gen		prop_actividad_pesquera		= sisf_activ4/edad_15mas
	gen		prop_actividad_minera		= sisf_activ5/edad_15mas
	gen		prop_actividad_artesanal	= sisf_activ6/edad_15mas
	gen		prop_actividad_comercial	= sisf_activ7/edad_15mas
	gen		prop_actividad_servicios	= sisf_activ8/edad_15mas
	gen		prop_actividad_estatal		= sisf_activ10/edad_15mas

	gen		prop_pea_ocupada			= sisf_pea1/pob
	gen		prop_pea_desocupada			= sisf_pea2/pob
	gen		ratio_pea					= sisf_pea1/sisf_pea2
	
*-----------------------------------------------*
*		1.3.8.	Social Program enrollment 		*
*-----------------------------------------------*	

	gen		prop_programa_ninguno		= sisf_prog11/pob
	
	
*-----------------------------------------------------------*
*		1.4.1.	Generate Poverty measure at CCPP level		*
*-----------------------------------------------------------*

*---------------------------*
*		Wall material		*
*---------------------------*	

	gen		poverty2013_pared = 0
	replace poverty2013_pared = (prop_pared_ladrillo*8 + prop_pared_piedra*7 + ///
								prop_pared_adobe*6 + prop_pared_quincha*5 + ///
								prop_pared_barro*4 + prop_pared_madera*3 + ///
								prop_pared_estera*2 + prop_pared_otro*1)/8
	
	gen		poverty2013_piso = 0
	replace poverty2013_piso = (prop_piso_parquet*7 + prop_piso_lamina*6 + ///
								prop_piso_loseta*5 + prop_piso_tabla*4 + ///
								prop_piso_cemento*3 + prop_piso_tierra*2 + ///
								prop_piso_otro*1)/7
	
	gen		poverty2013_agua = 0
	replace poverty2013_agua = (prop_agua_redpubdentro*8 + prop_agua_redpubfuera*7 + ///
								prop_agua_pilon*6 + prop_agua_cisterna*5 + ///
								prop_agua_pozo*4 + prop_agua_rio*3 + ///
								prop_agua_otro*1)/8
								
	gen		poverty2013_saneamiento = 0
	replace poverty2013_saneamiento = (prop_saneamiento_redpubdentro*6 + ///
								prop_saneamiento_redpubfuera*5 + ///
								prop_saneamiento_pozo*4 + prop_saneamiento_letrina*3 + ///
								prop_saneamiento_rio*2 + prop_saneamiento_ninguno*1)/6
	

	gen		poverty2013_bienesriqueza = 0
	replace poverty2013_bienesriqueza = (prop_asset_lavadora + prop_asset_refri + ///
								prop_asset_compu + prop_asset_internet + prop_asset_cable)/5
	
	gen		poverty2013_combust = 0
	replace poverty2013_combust = (prop_combust_elect*8 + prop_combust_gas*7 + ///
								prop_combust_kerosene*6 + prop_combust_carbon*5 + ///
								prop_combust_lea*4 + prop_combust_bosta*3 + ///
								prop_combust_otro*2 + prop_combust_nococina*1)/8
	
	gen		poverty2013_seguro = 0
	replace poverty2013_seguro = 1 - prop_seguro_ninguno
	
	gen		poverty2013_analfabeta = 0
	replace poverty2013_analfabeta = prop_lee_si
	replace poverty2013_analfabeta = 1 if prop_lee_si>1 & prop_lee_si!=.
	
	gen		poverty2013_educ = 0
	replace poverty2013_educ = (prop_educ_postgrado*8 + prop_educ_universitaria*7 + ///
								prop_educ_tecnica*6 + ///
								prop_educ_secundaria*4 + prop_educ_primaria*3 + ///
								prop_educ_inicial*2 + prop_educ_ninguno*1)/8
	
	gen		poverty2013_desempleo = 0
	replace poverty2013_desempleo = prop_pea_ocupada
	
	gen		poverty2013_alumbrado = 0
	replace poverty2013_alumbrado = prop_alumbrado_elect
	
	gen		poverty2013_caracthh = (1/4)*(poverty2013_pared + poverty2013_piso + poverty2013_combust + poverty2013_bienesriqueza)
	gen		poverty2013_servpub = (1/3)*(poverty2013_agua + poverty2013_saneamiento + poverty2013_alumbrado)
	gen		poverty2013_demogra = (1/4)*(poverty2013_seguro + poverty2013_analfabeta + poverty2013_educ + poverty2013_desempleo)

	gen		poverty2013 = (1/3)*(poverty2013_caracthh + poverty2013_servpub + poverty2013_demogra)

	
save "$a\2 data\2 Working\SAT\sisfoh2013_cleaned.dta", replace

*-------------------------------*
*		II.	Sisfoh hogares		*
*-------------------------------*

use "$a\2 data\1 Raw\sisfoh_hogar.dta", clear

egen ubigeo_dist = concat(DPTO PROV DIST)
egen ubigeo_ccpp = concat(DPTO PROV DIST CODCCPP_N)

drop DPTO PROV DIST 
rename NOMBREDD 		dpto
rename NOMBREPP			prov
rename NOMBREDI			dist
rename CENPOB			ccpp
rename AREA 			urb_rur
rename THOGAR			num_hogares
rename TVIV				sisf_tviv
rename MPARED			sisf_matpared
rename MTECHO			sisf_matecho
rename MATPISO			sisf_matpiso
rename TALUM			sisf_alum
rename ABASAG			sisf_agua
rename SERHIG			sisf_desague
rename HORDEM			sisf_horascapital
rename HORDEMG			sisf_horascapital_24_vive
rename CTAHAB			sisf_numhabitacion
rename COMBUSA			sisf_combust
rename BIEN1			sisf_asset_equiposonido
rename BIEN2			sisf_asset_tvcolor
rename BIEN3			sisf_asset_dvd
rename BIEN4			sisf_asset_licuadora
rename BIEN5			sisf_asset_refri
rename BIEN6			sisf_asset_cocinagas
rename BIEN7			sisf_asset_telefonofijo
rename BIEN8 			sisf_asset_plancha
rename BIEN9			sisf_asset_lavadora
rename BIEN10			sisf_asset_compu
rename BIEN11			sisf_asset_microondas
rename BIEN12			sisf_asset_internet
rename BIEN13			sisf_asset_cable
rename BIEN14			sisf_asset_celular
rename BIEN15			sisf_asset_ninguno
rename TOTAL			sisf_numperso
rename HOMBRES			sisf_hombres
rename MUJERES			sisf_mujeres
rename RESID			sisf_viveperm
rename NPISOS			sisf_numpisos

gen		sisf_pared_ladrillo 	= 0 if sisf_matpared!=.
replace sisf_pared_ladrillo 	= 1 if sisf_matpared==1
gen		sisf_pared_piedra 		= 0 if sisf_matpared!=.
replace sisf_pared_piedra 		= 1 if sisf_matpared==2
gen		sisf_pared_adobe 		= 0 if sisf_matpared!=.
replace sisf_pared_adobe 		= 1 if sisf_matpared==3
gen		sisf_pared_quincha 		= 0 if sisf_matpared!=.
replace sisf_pared_quincha 		= 1 if sisf_matpared==4
gen		sisf_pared_piedrabarro 	= 0 if sisf_matpared!=.
replace sisf_pared_piedrabarro 	= 1 if sisf_matpared==5
gen		sisf_pared_madera 		= 0 if sisf_matpared!=.
replace sisf_pared_madera 		= 1 if sisf_matpared==6
gen		sisf_pared_estera 		= 0 if sisf_matpared!=.
replace sisf_pared_estera 		= 1 if sisf_matpared==7


gen		sisf_techo_concreto 	= 0 if sisf_matecho!=.
replace sisf_techo_concreto 	= 1 if sisf_matecho==1
gen		sisf_techo_madera	 	= 0 if sisf_matecho!=.
replace sisf_techo_madera	 	= 1 if sisf_matecho==2
gen		sisf_techo_teja		 	= 0 if sisf_matecho!=.
replace sisf_techo_teja		 	= 1 if sisf_matecho==3
gen		sisf_techo_calamina 	= 0 if sisf_matecho!=.
replace sisf_techo_calamina 	= 1 if sisf_matecho==4
gen		sisf_techo_cana 		= 0 if sisf_matecho!=.
replace sisf_techo_cana 	 	= 1 if sisf_matecho==5
gen		sisf_techo_estera	 	= 0 if sisf_matecho!=.
replace sisf_techo_estera	 	= 1 if sisf_matecho==6
gen		sisf_techo_paja		 	= 0 if sisf_matecho!=.
replace sisf_techo_paja		 	= 1 if sisf_matecho==7


gen		sisf_piso_parquet 		= 0 if sisf_matpiso!=.
replace sisf_piso_parquet 		= 1 if sisf_matpiso==1
gen		sisf_piso_lamina 		= 0 if sisf_matpiso!=.
replace sisf_piso_lamina 		= 1 if sisf_matpiso==2
gen		sisf_piso_loseta 		= 0 if sisf_matpiso!=.
replace sisf_piso_loseta 		= 1 if sisf_matpiso==3
gen		sisf_piso_tabla 		= 0 if sisf_matpiso!=.
replace sisf_piso_tabla 		= 1 if sisf_matpiso==4
gen		sisf_piso_cemento 		= 0 if sisf_matpiso!=.
replace sisf_piso_cemento 		= 1 if sisf_matpiso==5
gen		sisf_piso_tierra 		= 0 if sisf_matpiso!=.
replace sisf_piso_tierra 		= 1 if sisf_matpiso==6


gen		sisf_alumbrado_elect 		= 0 if sisf_alum!=.
replace sisf_alumbrado_elect 		= 1 if sisf_alum==1
gen		sisf_alumbrado_kerosene		= 0 if sisf_alum!=.
replace sisf_alumbrado_kerosene		= 1 if sisf_alum==2
gen		sisf_alumbrado_lampara 		= 0 if sisf_alum!=.
replace sisf_alumbrado_lampara 		= 1 if sisf_alum==3
gen		sisf_alumbrado_vela 		= 0 if sisf_alum!=.
replace sisf_alumbrado_vela 		= 1 if sisf_alum==4
gen		sisf_alumbrado_ninguno 		= 0 if sisf_alum!=.
replace sisf_alumbrado_ninguno 		= 1 if sisf_alum==6


gen		sisf_agua_redpubdentro 		= 0 if sisf_agua!=.
replace sisf_agua_redpubdentro 		= 1 if sisf_agua==1
gen		sisf_agua_redpubfuera		= 0 if sisf_agua!=.
replace sisf_agua_redpubfuera 		= 1 if sisf_agua==2
gen		sisf_agua_pilon		 		= 0 if sisf_agua!=.
replace sisf_agua_pilon		 		= 1 if sisf_agua==3
gen		sisf_agua_cisterna	 		= 0 if sisf_agua!=.
replace sisf_agua_cisterna	 		= 1 if sisf_agua==4
gen		sisf_agua_pozo 				= 0 if sisf_agua!=.
replace sisf_agua_pozo		 		= 1 if sisf_agua==5
gen		sisf_agua_rio		 		= 0 if sisf_agua!=.
replace sisf_agua_rio		 		= 1 if sisf_agua==6


gen		sisf_saneamiento_redpubdentro 		= 0 if sisf_desague!=.
replace sisf_saneamiento_redpubdentro 		= 1 if sisf_desague==1
gen		sisf_saneamiento_redpubfuera		= 0 if sisf_desague!=.
replace sisf_saneamiento_redpubfuera 		= 1 if sisf_desague==2
gen		sisf_saneamiento_pozo 				= 0 if sisf_desague!=.
replace sisf_saneamiento_pozo		 		= 1 if sisf_desague==3
gen		sisf_saneamiento_letrina	 		= 0 if sisf_desague!=.
replace sisf_saneamiento_letrina	 		= 1 if sisf_desague==4
gen		sisf_saneamiento_rio		 		= 0 if sisf_desague!=.
replace sisf_saneamiento_rio		 		= 1 if sisf_desague==5
gen		sisf_saneamiento_ninguno			= 0 if sisf_desague!=.
replace sisf_saneamiento_ninguno		 	= 1 if sisf_desague==6


gen		sisf_combust_elect		 	= 0 if sisf_combust!=.
replace sisf_combust_elect		 	= 1 if sisf_combust==1
gen		sisf_combust_gas		 	= 0 if sisf_combust!=.
replace sisf_combust_gas		 	= 1 if sisf_combust==2
gen		sisf_combust_kerosene	 	= 0 if sisf_combust!=.
replace sisf_combust_kerosene	 	= 1 if sisf_combust==3
gen		sisf_combust_carbon			= 0 if sisf_combust!=.
replace sisf_combust_carbon		 	= 1 if sisf_combust==4
gen		sisf_combust_lea		 	= 0 if sisf_combust!=.
replace sisf_combust_lea		 	= 1 if sisf_combust==5
gen		sisf_combust_bosta		 	= 0 if sisf_combust!=.
replace sisf_combust_bosta		 	= 1 if sisf_combust==6


replace sisf_asset_equiposonido=1 	if sisf_asset_equiposonido!=.
replace sisf_asset_equiposonido=0 	if sisf_asset_equiposonido==. 
replace sisf_asset_tvcolor=1 		if sisf_asset_tvcolor!=.
replace sisf_asset_tvcolor=0 		if sisf_asset_tvcolor==.
replace sisf_asset_dvd=1 			if sisf_asset_dvd!=.
replace sisf_asset_dvd=0 			if sisf_asset_dvd==.
replace sisf_asset_licuadora=1 		if sisf_asset_licuadora!=.
replace sisf_asset_licuadora=0 		if sisf_asset_licuadora==.
replace sisf_asset_refri=1 			if sisf_asset_refri!=.
replace sisf_asset_refri=0 			if sisf_asset_refri==.
replace sisf_asset_cocinagas=1 		if sisf_asset_cocinagas!=.
replace sisf_asset_cocinagas=0 		if sisf_asset_cocinagas==.
replace sisf_asset_telefonofijo=1 	if sisf_asset_telefonofijo!=.
replace sisf_asset_telefonofijo=0 	if sisf_asset_telefonofijo==.
replace sisf_asset_plancha=1 		if sisf_asset_plancha!=.
replace sisf_asset_plancha=0 		if sisf_asset_plancha==.
replace sisf_asset_lavadora=1 		if sisf_asset_lavadora!=.
replace sisf_asset_lavadora=0 		if sisf_asset_lavadora==.
replace sisf_asset_compu=1 			if sisf_asset_compu!=.
replace sisf_asset_compu=0 			if sisf_asset_compu==.
replace sisf_asset_microondas=1 	if sisf_asset_microondas!=.
replace sisf_asset_microondas=0 	if sisf_asset_microondas==.
replace sisf_asset_internet=1 		if sisf_asset_internet!=.
replace sisf_asset_internet=0 		if sisf_asset_internet==.
replace sisf_asset_cable=1 			if sisf_asset_cable!=.
replace sisf_asset_cable=0 			if sisf_asset_cable==.
replace sisf_asset_celular=1		if sisf_asset_celular!=.
replace sisf_asset_celular=0 		if sisf_asset_celular==.
replace sisf_asset_ninguno=1 		if sisf_asset_ninguno!=.
replace sisf_asset_ninguno=0 		if sisf_asset_ninguno==.


recode urb_rur (1=0) (2=1)
label def urb_rur_lb 1 Urbano 0 Rural, replace
label val urb_rur urb_rur_lb

saveold "$a\2 data\SAT\2 Working\SAT\sisfoh_hogar_cleaned.dta", replace v(13)


*-----------------------------------*
*		III.	Sisfoh personas		*
*-----------------------------------*

use "$a\2 data\2 Working\sisfoh_personas_cleaned.dta", clear


rename EDAD01		edad
rename DPTO			ubigeo_dpto
rename NIV01		nivel_educ
rename SEXO01		sexo
rename LEE01		lee_escribe
rename SEGU01_1		seguro_essalud
rename SEGU01_2		seguro_ffaapnp
rename SEGU01_3		seguro_privado
rename SEGU01_4		seguro_sis
rename SEGU01_5		seguro_otro
rename SEGU01_6		seguro_ninguno
rename PROG01_1		prog_vasoleche
rename PROG01_2 	prog_comedorpop
rename PROG01_3 	prog_desalm
rename PROG01_4 	prog_papyap
rename PROG01_5 	prog_canastaalim
rename PROG01_6 	prog_juntos
rename PROG01_7 	prog_techo
rename PROG01_8 	prog_pension65
rename PROG01_9 	prog_cunamas
rename PROG01_10	prog_otro
rename PROG01_11	prog_ninguno

egen ubigeo_prov=concat(ubigeo_dpto PROV)
egen ubigeo_dist=concat(ubigeo_prov DIST)
egen ubigeo_ccpp=concat(ubigeo_dist CODCCPP_N)

*	Indicator used when collapsing dataset to count HH members
gen num_perso=1

*	Gender dummy (1=Women / 0=Men)
recode sexo (1=0) (2=1)
label def sexo_lb 0 Hombre 1 Mujer
label val sexo sexo_lb

*	Litteracy dummy
recode lee_escribe (2=0)
label def lee_escribe_lb 1 Si 0 No
label val lee_escribe lee_escribe_lb

*	Illiterate indicator (Litteray & age>15)
gen		analfab = .
replace analfab = 1 if edad>=15 & lee_escribe==0
replace analfab = 0 if edad<15 | (edad>=15 & lee_escribe==1)

*	Male head of HH dummy
gen		jefe_hogar = .
replace jefe_hogar = 1 if PTES01==1 & sexo==0
replace jefe_hogar = 0 if PTES01!=1 & PTES01!=. & sexo==0

*	Female head of HH dummy
gen		jefa_hogar = .
replace jefa_hogar = 1 if PTES01==1 & sexo==1
replace jefa_hogar = 0 if PTES01!=1 & PTES01!=. & sexo==1

*	Construction more detailed Education Level variable
gen		nivel_educ2 = .
replace nivel_educ2 = 1	if nivel_educ==1	// Sin educacion
replace nivel_educ2 = 2	if nivel_educ==2	// Inicial
replace nivel_educ2 = 3	if nivel_educ==3 & ULT01<6	// Primaria incompleta
replace nivel_educ2 = 4	if nivel_educ==3 & ULT01==6	// Primaria completa
replace nivel_educ2 = 5	if nivel_educ==4 & ULT01<5	// Secundaria incompleta
replace nivel_educ2 = 6	if nivel_educ==4 & ULT01==5	// Secundaria completa
replace nivel_educ2 = 7	if nivel_educ==5	& ULT01<3	// Sup. no universitaria incompleta
replace nivel_educ2 = 8	if nivel_educ==5 & ULT01>3 & ULT01!=.	// Sup. no universitaria completa
replace nivel_educ2 = 9 if nivel_educ==6 & ULT01<5	// Sup. universitaria incompleta
replace nivel_educ2 = 10 if nivel_educ==6 & ULT01>5 & ULT01!=.	// Sup. universitaria completa
replace nivel_educ2 = 11 if nivel_educ==7	// Post-grado
  
*	Education Level of the Male HH head
gen		nivel_educ_jefe_hogar = .
replace nivel_educ_jefe_hogar = nivel_educ2 if jefe_hogar==1

*	Education Level of the Female HH head
gen		nivel_educ_jefa_hogar = .
replace nivel_educ_jefa_hogar = nivel_educ2 if jefa_hogar==1

*	HH head's husband dummy
gen		conyugue_h = .
replace conyugue_h = 1 if PTES01==2 & sexo==0
replace conyugue_h = 0 if PTES01!=2  & PTES01!=. & sexo==0

*	HH head's wife dummy
gen		conyugue_m = .
replace conyugue_m = 1 if PTES01==2 & sexo==1
replace conyugue_m = 0 if PTES01!=2  & PTES01!=. & sexo==1

*	Education Level of HH head's husband
gen		nivel_educ_conyugue_h = .
replace nivel_educ_conyugue_h = nivel_educ2 if conyugue_h==1

*	Education Level of HH head's wife
gen		nivel_educ_conyugue_m = .
replace nivel_educ_conyugue_m = nivel_educ2 if conyugue_m==1

*	Employed dummy
gen		ocupado = .
replace ocupado = 1 if ERA01>=1 & ERA01<=5
replace ocupado = 0 if ERA01>=6 & ERA01<=10

*	6-12 years old dummy
gen		edad_6_12 = 0
replace edad_6_12 = 1 if edad>=6 & edad<=12

*	Kid out of school dummy
gen		edad_6_12_noescuela = 0
replace edad_6_12_noescuela = 1 if edad_6_12==1 & ERA01!=8 & ERA01!=.

*	Mother tongue different than spanish dummy
gen		lengua_nocastellano = .
replace lengua_nocastellano = 1 if IDIOMA01!=1 & IDIOMA01!=.
replace lengua_nocastellano = 0 if IDIOMA01==4 

*	Construction of individual economic activity variables
gen		trabaja_agricola	= 0
replace	trabaja_agricola	= 1 if SECT01==1
gen		trabaja_pecuaria	= 0
replace trabaja_pecuaria	= 1 if SECT01==2
gen		trabaja_forestal	= 0
replace trabaja_forestal	= 1 if SECT01==3
gen		trabaja_pesquera	= 0
replace trabaja_pesquera	= 1 if SECT01==4
gen		trabaja_minera		= 0
replace trabaja_minera		= 1 if SECT01==5
gen		trabaja_artesanal	= 0
replace trabaja_artesanal	= 1 if SECT01==6
gen		trabaja_comercial	= 0
replace trabaja_comercial	= 1 if SECT01==7
gen		trabaja_servicios	= 0
replace trabaja_servicios	= 1 if SECT01==8
gen		trabaja_otro		= 0
replace trabaja_otro		= 1 if SECT01==9
gen		trabaja_gobierno	= 0
replace trabaja_gobierno	= 1 if SECT01==10

*	Construction of individual insurance program variables
replace seguro_essalud = 0 if seguro_essalud==.
replace seguro_essalud = 1 if seguro_essalud==1
replace seguro_ffaapnp = 0 if seguro_ffaapnp==.
replace seguro_ffaapnp = 1 if seguro_ffaapnp==2
replace seguro_privado = 0 if seguro_privado==.
replace seguro_privado = 1 if seguro_privado==3
replace seguro_sis 		= 0 if seguro_sis==.
replace seguro_sis 		= 1 if seguro_sis==4
replace seguro_otro 	= 0 if seguro_otro==.
replace seguro_otro 	= 1 if seguro_otro==5
replace seguro_ninguno = 0 if seguro_ninguno==.
replace seguro_ninguno = 1 if seguro_ninguno==6

*	Number of insurance programs affiliated to
egen	num_seguro_ind = rowtotal(seguro_essalud seguro_ffaapnp seguro_privado seguro_sis seguro_otro)

*	Indicator for at least 1 insurance program affiliation
gen		tiene_seguro = 0
replace tiene_seguro = 1 if num_seguro_ind>0 & num_seguro_ind!=.

*	Construction of individual social program enrollment
replace prog_vasoleche		= 0 if prog_vasoleche==.
replace prog_vasoleche 		= 1 if prog_vasoleche==1
replace prog_comedorpop 	= 0 if prog_comedorpop==.
replace prog_comedorpop		= 1 if prog_comedorpop==2	
replace prog_desalm 		= 0 if prog_desalm==.
replace prog_desalm			= 1 if prog_desalm==3
replace prog_papyap 		= 0 if prog_papyap==.
replace prog_papyap			= 1 if prog_papyap==4
replace prog_canastaalim 	= 0 if prog_canastaalim==.
replace prog_canastaalim	= 1 if prog_canastaalim==5
replace prog_juntos 		= 0 if prog_juntos==.
replace prog_juntos			= 1 if prog_juntos==6
replace prog_techo 			= 0 if prog_techo==.
replace prog_techo			= 1 if prog_techo==7
replace prog_pension65 		= 0 if prog_pension65==.
replace prog_pension65		= 1 if prog_pension65==8
replace prog_cunamas 		= 0 if prog_cunamas==.
replace prog_cunamas		= 1 if prog_cunamas==9
replace prog_otro 			= 0 if prog_otro==.
replace prog_otro			= 1 if prog_otro==10
replace prog_ninguno		= 0 if prog_ninguno==.
replace prog_ninguno		= 1 if prog_ninguno==11

*	Number of social programs enrroled
egen	num_prog_ind = rowtotal(prog_vasoleche prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos prog_techo prog_pension65 prog_cunamas prog_otro)

*	Indicator for at least enrolled in 1 social program
gen		tiene_prog = 0
replace tiene_prog = 1 if num_prog_ind>0 & num_prog_ind!=.

*	Construction if individual variables for each ocupation status
gen		ocupacion_dep		= 0
replace ocupacion_dep		= 1 if ERA01==1
gen		ocupacion_indep		= 0
replace ocupacion_indep		= 1 if ERA01==2 | ERA01==3
gen		ocupacion_trabhog	= 0
replace ocupacion_trabhog	= 1 if ERA01==4
gen		ocupacion_famnorem	= 0
replace ocupacion_famnorem	= 1 if ERA01==5
gen		ocupacion_desemp	= 0
replace ocupacion_desemp	= 1 if ERA01==6
gen		ocupacion_hogar		= 0
replace ocupacion_hogar		= 1 if ERA01==7
gen		ocupacion_estud		= 0
replace ocupacion_estud		= 1 if ERA01==8
gen		ocupacion_jubilado	= 0
replace ocupacion_jubilado	= 1 if ERA01==9

*	Collapse SISFOH individual dataset to househod level
collapse (sum) num_perso tiene_seguro tiene_prog ocupado ocupacion_* 			///
edad_6_12_noescuela seguro* prog* trabaja* lengua_nocastellano analfab 			///
(max) nivel_educ_jefe_hogar nivel_educ_jefa_hogar nivel_educ_conyugue_h 		///
nivel_educ_conyugue_m nivel_educ nivel_educ2 (mean) edad ratio_sexo=sexo, 		///
by(ubigeo_ccpp SECUENCIA CONG NROVIV NHOGAR)

*	Total number of insurance programs from every household member
egen	num_seguro = rowtotal(seguro_essalud seguro_ffaapnp seguro_privado seguro_sis seguro_otro)

*	At least 1 household member is affiliated to at least 1 insurance program
gen		seguro_1 = 0
replace seguro_1 = 1 if num_seguro>0 & num_seguro!=.

*	HH members affiliated to at least 1 insurance program over total members
gen		ratio_seguro = 0
replace ratio_seguro = tiene_seguro/num_perso

*	Employed hh members over total members
gen		ratio_dependencia = 0
replace ratio_dependencia = ocupado/num_perso

*	At least 1 person in the HH is 6-12 years old and doesn't attend school
gen		noescuela_1 = 0
replace noescuela_1 = 1 if edad_6_12_noescuela>0 & edad_6_12_noescuela!=.

*	Total number of social programs that HH members are affiliated to
egen	num_prog = rowtotal(prog_vasoleche prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos prog_techo prog_pension65 prog_cunamas prog_otro)

*	At least 1 household member is affiliated to at least 1 social program
gen		prog_1 = 0
replace prog_1 = 1 if num_prog>0 & num_prog!=.

*	HH members affiliated to at least 1 social program over total members
gen		ratio_prog = 0
replace ratio_prog = tiene_prog/num_perso

foreach prog in prog_vasoleche prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos prog_techo prog_pension65 prog_cunamas prog_otro prog_ninguno {
*	At least 1 household member is affiliated to each social program
gen		`prog'_1 = 0
replace	`prog'_1 = 1 if `prog'>0 & `prog'!=.
}

foreach seguro in seguro_essalud seguro_ffaapnp seguro_privado seguro_sis seguro_otro seguro_ninguno {
*	At least 1 household member is affiliated to each type of insurance program
gen		`seguro'_1 = 0
replace	`seguro'_1 = 1 if `seguro'>0 & `seguro'!=.
}

foreach x in trabaja_agricola trabaja_pecuaria trabaja_forestal trabaja_pesquera trabaja_minera trabaja_artesanal trabaja_comercial trabaja_servicios trabaja_otro trabaja_gobierno{
*	At least 1 household member works in each type of economic activity
gen		`x'_1 = 0
replace `x'_1 = 1 if `x'>0 & `x'!=.
*	Number of HH members working in each activity over total HH members
gen		ratio_`x' = 0
replace ratio_`x' = `x'/num_perso
}

foreach ocupacion in ocupacion_dep ocupacion_indep ocupacion_trabhog ocupacion_famnorem ocupacion_desemp ocupacion_hogar ocupacion_estud ocupacion_jubilado {
*	At least 1 household member is occupied in each category
gen		`ocupacion'_1 = 0
replace `ocupacion'_1 = 1 if `ocupacion'>0 & `ocupacion'!=.
*	Number of HH members occupied in each category over total HH members	
gen 	ratio_`ocupacion' = 0
replace ratio_`ocupacion' = `ocupacion'/num_perso
}

*	At least 1 HH member speaks other language than spanish as a mother tongue
gen		lengua_nocastellano_1 = 0
replace lengua_nocastellano_1 = 1 if lengua_nocastellano>0 & lengua_nocastellano!=.

*	At least 1 HH member has a job
gen		ocupado_1 = 0
replace ocupado_1 = 1 if ocupado>0 & ocupado!=.

*	At least 1 HH member is illiterate
gen		analfab_1 = 0
replace analfab_1 = 1 if analfab>0 & analfab!=.

label def nivel_educ_lb 1 Ninguno 2 Inicial 3 "Primaria incompleta" 4 "Primaria completa" ///
		5 "Secundaria incompleta" 6 "Secundaria completa" 7 "Sup. no universitaria incompleta" ///
		8 "Sup. no universitaria completa" 9 "Sup. universitaria incompleta" 10 ///
		"Sup. universitaria completa" 11 "Post-grado", replace
label val nivel_educ nivel_educ_lb
label val nivel_educ_jefe_hogar nivel_educ_lb
label val nivel_educ_jefa_hogar nivel_educ_lb
label val nivel_educ_conyugue_h nivel_educ_lb
label val nivel_educ_conyugue_m nivel_educ_lb


saveold "$a\2 data\2 Working\SAT\sisfoh_persona_cleanedcollapse.dta", replace v(13)

*---------------------------------------------------------------------------*
*		IV.	Merge Sisfoh hogares with Sisfoh personas collapsed dataset		*
*---------------------------------------------------------------------------*

merge 1:1 ubigeo_ccpp SECUENCIA CONG NROVIV NHOGAR using "$a\2 data\2 Working\sisfoh_hogar_cleaned.dta", keepusing(_all)

*-----------------------------------------------------------*
*		IV.1	Create poverty indeces from sisfoh data		*
*-----------------------------------------------------------*

*---------------------------------------------------*
*		4.1.1 Indice de focalizacion de hogares		*
*---------------------------------------------------*
gen ubigeo_prov=substr(ubigeo_dist,1,4)
gen 	ambito = .
replace ambito = 1 if (ubigeo_prov == "1501" & urb_rur==1) | (ubigeo_prov=="0701" & urb_rur==1)
replace ambito = 2 if ambito!=1 & urb_rur==1
replace ambito = 3 if urb_rur==2
label def ambito_lb 1 "Lima Metropilitana" 2 "Urbano (sin LM)" 3 "Rural", replace
label val ambito ambito_lb

*	Type of fuel used to cook
gen		ifh_combust = .

replace ifh_combust = -0.49 	if ambito==1 & sisf_combust==8
replace ifh_combust = -0.4 		if ambito==1 & sisf_combust==7
replace ifh_combust = -0.37 	if ambito==1 & sisf_combust_lea==1
replace ifh_combust = -0.33 	if ambito==1 & sisf_combust_carbon==1
replace ifh_combust = -0.29 	if ambito==1 & sisf_combust_kerosene==1
replace ifh_combust = 0.02 		if ambito==1 & sisf_combust_gas==1
replace ifh_combust = 0.43 		if ambito==1 & sisf_combust_elect==1

replace ifh_combust = -0.67 	if ambito==2 & sisf_combust==8
replace ifh_combust = -0.5 		if ambito==2 & sisf_combust==7
replace ifh_combust = -0.33 	if ambito==2 & sisf_combust_lea==1
replace ifh_combust = -0.22 	if ambito==2 & sisf_combust_carbon==1
replace ifh_combust = -0.19 	if ambito==2 & sisf_combust_kerosene==1
replace ifh_combust = 0.12 		if ambito==2 & sisf_combust_gas==1
replace ifh_combust = 0.69 		if ambito==2 & sisf_combust_elect==1

replace ifh_combust = -0.76 	if ambito==3 & sisf_combust==8
replace ifh_combust = -0.38 	if ambito==3 & sisf_combust==7
replace ifh_combust = 0.05 		if ambito==3 & sisf_combust_lea==1
replace ifh_combust = 0.36 		if ambito==3 & sisf_combust_carbon==1
replace ifh_combust = 0.37		if ambito==3 & sisf_combust_kerosene==1
replace ifh_combust = 0.52 		if ambito==3 & sisf_combust_gas==1
replace ifh_combust = 0.52 		if ambito==3 & sisf_combust_elect==1

*	Type of water supply
gen		ifh_agua = .

replace ifh_agua = -0.78	if ambito==1 & sisf_agua==7
replace ifh_agua = -0.65	if ambito==1 & sisf_agua_rio==1
replace ifh_agua = -0.62	if ambito==1 & sisf_agua_pozo==1
replace ifh_agua = -0.51	if ambito==1 & sisf_agua_cisterna==1
replace ifh_agua = -0.41	if ambito==1 & sisf_agua_pilon==1
replace ifh_agua = -0.35	if ambito==1 & sisf_agua_redpubfuera==1
replace ifh_agua = 0.1		if ambito==1 & sisf_agua_redpubdentro==1

replace ifh_agua = -0.58	if ambito==2 & sisf_agua==7
replace ifh_agua = -0.42	if ambito==2 & sisf_agua_rio==1
replace ifh_agua = -0.37	if ambito==2 & sisf_agua_pozo==1
replace ifh_agua = -0.34	if ambito==2 & sisf_agua_cisterna==1
replace ifh_agua = -0.32	if ambito==2 & sisf_agua_pilon==1
replace ifh_agua = -0.25	if ambito==2 & sisf_agua_redpubfuera==1
replace ifh_agua = 0.12		if ambito==2 & sisf_agua_redpubdentro==1

*	Wall material
gen		ifh_pared = .

replace ifh_pared = -0.7	if ambito==1 & sisf_matpared==8
replace ifh_pared = -0.48	if ambito==1 & sisf_pared_estera==1
replace ifh_pared = -0.44 	if ambito==1 & sisf_pared_madera==1
replace ifh_pared = -0.41	if ambito==1 & sisf_pared_piedrabarro==1
replace ifh_pared = -0.39	if ambito==1 & sisf_pared_quincha==1
replace ifh_pared = -0.37	if ambito==1 & sisf_pared_adobe==1
replace ifh_pared = -0.33	if ambito==1 & sisf_pared_piedra==1
replace ifh_pared = 0.1		if ambito==1 & sisf_pared_ladrillo==1

replace ifh_pared = -0.8	if ambito==2 & sisf_matpared==8
replace ifh_pared = -0.55	if ambito==2 & sisf_pared_estera==1
replace ifh_pared = -0.46 	if ambito==2 & sisf_pared_madera==1
replace ifh_pared = -0.43	if ambito==2 & sisf_pared_piedrabarro==1
replace ifh_pared = -0.38	if ambito==2 & sisf_pared_quincha==1
replace ifh_pared = -0.20	if ambito==2 & sisf_pared_adobe==1
replace ifh_pared = -0.07	if ambito==2 & sisf_pared_piedra==1
replace ifh_pared = 0.25	if ambito==2 & sisf_pared_ladrillo==1

*	Drain material
gen		ifh_saneamiento = .

replace ifh_saneamiento = -0.89	if ambito==1 & sisf_saneamiento_ninguno==1
replace ifh_saneamiento = -0.75	if ambito==1 & sisf_saneamiento_rio==1
replace ifh_saneamiento = -0.59	if ambito==1 & sisf_saneamiento_letrina==1
replace ifh_saneamiento = -0.46	if ambito==1 & sisf_saneamiento_pozo==1
replace ifh_saneamiento = -0.39	if ambito==1 & sisf_saneamiento_redpubfuera==1
replace ifh_saneamiento = 0.1	if ambito==1 & sisf_saneamiento_redpubdentro==1

replace ifh_saneamiento = -0.68	if ambito==2 & sisf_saneamiento_ninguno==1
replace ifh_saneamiento = -0.49	if ambito==2 & sisf_saneamiento_rio==1
replace ifh_saneamiento = -0.4	if ambito==2 & sisf_saneamiento_letrina==1
replace ifh_saneamiento = -0.3	if ambito==2 & sisf_saneamiento_pozo==1
replace ifh_saneamiento = -0.21	if ambito==2 & sisf_saneamiento_redpubfuera==1
replace ifh_saneamiento = 0.2	if ambito==2 & sisf_saneamiento_redpubdentro==1

*	Number of afilliates to heath insurance
gen		ifh_seguro = .

replace ifh_seguro = -0.26	if ambito==1 & num_seguro==0
replace ifh_seguro = -0.04	if ambito==1 & num_seguro==1
replace ifh_seguro = 0.06	if ambito==1 & num_seguro==2
replace ifh_seguro = 0.14	if ambito==1 & num_seguro==3
replace ifh_seguro = 0.32	if ambito==1 & num_seguro>3 & num_seguro!=.

replace ifh_seguro = -0.25	if ambito==2 & num_seguro==0
replace ifh_seguro = 0.06	if ambito==2 & num_seguro==1
replace ifh_seguro = 0.17	if ambito==2 & num_seguro==2
replace ifh_seguro = 0.27	if ambito==2 & num_seguro==3
replace ifh_seguro = 0.48	if ambito==2 & num_seguro>3 & num_seguro!=.

replace ifh_seguro = -0.1	if ambito==3 & num_seguro==0
replace ifh_seguro = 0.5	if ambito==3 & num_seguro==1
replace ifh_seguro = 0.59	if ambito==3 & num_seguro==2
replace ifh_seguro = 0.66	if ambito==3 & num_seguro==3
replace ifh_seguro = 0.86	if ambito==3 & num_seguro>3 & num_seguro!=.

*	Wealth assets
egen	num_bienesriqueza = rowtotal(sisf_asset_refri sisf_asset_lavadora ///
									sisf_asset_compu sisf_asset_internet ///
									sisf_asset_cable)
gen	ifh_bienesriqueza = . if sisf_matpared==.

replace ifh_bienesriqueza = -0.47	if ambito==1 & num_bienesriqueza==0
replace ifh_bienesriqueza =	-0.17	if ambito==1 & num_bienesriqueza==1
replace ifh_bienesriqueza =	0.02	if ambito==1 & num_bienesriqueza==2
replace ifh_bienesriqueza = 0.15	if ambito==1 & num_bienesriqueza==3
replace ifh_bienesriqueza = 0.25	if ambito==1 & num_bienesriqueza==4
replace ifh_bienesriqueza = 0.47	if ambito==1 & num_bienesriqueza==5

replace ifh_bienesriqueza = -0.35	if ambito==2 & num_bienesriqueza==0
replace ifh_bienesriqueza =	0.05	if ambito==2 & num_bienesriqueza==1
replace ifh_bienesriqueza =	0.25	if ambito==2 & num_bienesriqueza==2
replace ifh_bienesriqueza = 0.4		if ambito==2 & num_bienesriqueza==3
replace ifh_bienesriqueza = 0.52	if ambito==2 & num_bienesriqueza==4
replace ifh_bienesriqueza = 0.75	if ambito==2 & num_bienesriqueza==5

replace ifh_bienesriqueza = -0.11	if ambito==3 & num_bienesriqueza==0
replace ifh_bienesriqueza =	0.64	if ambito==3 & num_bienesriqueza==1
replace ifh_bienesriqueza =	0.83	if ambito==3 & num_bienesriqueza==2
replace ifh_bienesriqueza = 0.9 	if ambito==3 & num_bienesriqueza==3
replace ifh_bienesriqueza = 1.09	if ambito==3 & num_bienesriqueza==4
replace ifh_bienesriqueza = 1.09	if ambito==3 & num_bienesriqueza==5

*	Owns cellphone
gen		ifh_cellphone = .

replace ifh_cellphone = -0.32	if ambito==1 & sisf_asset_celular==0
replace ifh_cellphone = 0.2		if ambito==1 & sisf_asset_celular==1

*	Roof material
gen		ifh_techo = .

replace ifh_techo = -0.86	if ambito==1 & sisf_matecho==8
replace ifh_techo = -0.74	if ambito==1 & sisf_techo_paja==1
replace ifh_techo = -0.67	if ambito==1 & sisf_techo_estera==1
replace ifh_techo = -0.38	if ambito==1 & sisf_techo_cana==1
replace ifh_techo = -0.23	if ambito==1 & sisf_techo_teja==1
replace ifh_techo = -0.21	if ambito==1 & sisf_techo_madera==1
replace ifh_techo = 0.17	if ambito==1 & sisf_techo_concreto==1

replace ifh_techo = -0.9	if ambito==2 & sisf_matecho==8
replace ifh_techo = -0.72	if ambito==2 & sisf_techo_paja==1
replace ifh_techo = -0.62	if ambito==2 & sisf_techo_estera==1
replace ifh_techo = -0.23	if ambito==2 & sisf_techo_cana==1
replace ifh_techo = 0.03	if ambito==2 & sisf_techo_teja==1
replace ifh_techo = 0.07	if ambito==2 & sisf_techo_madera==1
replace ifh_techo = 0.32	if ambito==2 & sisf_techo_concreto==1

*	Household's head education level
gen		ifh_educjefe = .

replace	ifh_educjefe = -0.51	if ambito==1 & (nivel_educ_jefe_hogar==1 | nivel_educ_jefa_hogar==1)
replace ifh_educjefe = -0.43	if ambito==1 & (nivel_educ_jefe_hogar==2 | nivel_educ_jefa_hogar==2)
replace ifh_educjefe = -0.28	if ambito==1 & (nivel_educ_jefe_hogar==3 | nivel_educ_jefa_hogar==3 | nivel_educ_jefe_hogar==4 | nivel_educ_jefa_hogar==4)
replace ifh_educjefe = -0.06	if ambito==1 & (nivel_educ_jefe_hogar==5 | nivel_educ_jefa_hogar==5 | nivel_educ_jefe_hogar==6 | nivel_educ_jefa_hogar==6)
replace ifh_educjefe = 0.1		if ambito==1 & (nivel_educ_jefe_hogar==7 | nivel_educ_jefa_hogar==7 | nivel_educ_jefe_hogar==8 | nivel_educ_jefa_hogar==8)
replace ifh_educjefe = 0.22		if ambito==1 & (nivel_educ_jefe_hogar==9 | nivel_educ_jefa_hogar==9 | nivel_educ_jefe_hogar==10 | nivel_educ_jefa_hogar==10)
replace ifh_educjefe = 0.4		if ambito==1 & (nivel_educ_jefe_hogar==11 | nivel_educ_jefa_hogar==11)

replace	ifh_educjefe = -0.57	if ambito==2 & (nivel_educ_jefe_hogar==1 | nivel_educ_jefa_hogar==1)
replace ifh_educjefe = -0.25	if ambito==2 & (nivel_educ_jefe_hogar==2 | nivel_educ_jefa_hogar==2)
replace ifh_educjefe = 0.01		if ambito==2 & (nivel_educ_jefe_hogar==3 | nivel_educ_jefa_hogar==3 | nivel_educ_jefe_hogar==4 | nivel_educ_jefa_hogar==4)
replace ifh_educjefe = 0.19		if ambito==2 & (nivel_educ_jefe_hogar==5 | nivel_educ_jefa_hogar==5 | nivel_educ_jefe_hogar==6 | nivel_educ_jefa_hogar==6)
replace ifh_educjefe = 0.33		if ambito==2 & (nivel_educ_jefe_hogar==7 | nivel_educ_jefa_hogar==7 | nivel_educ_jefe_hogar==8 | nivel_educ_jefa_hogar==8)
replace ifh_educjefe = 0.55		if ambito==2 & (nivel_educ_jefe_hogar==9 | nivel_educ_jefa_hogar==9 | nivel_educ_jefe_hogar==10 | nivel_educ_jefa_hogar==10)
replace ifh_educjefe = 0.55		if ambito==2 & (nivel_educ_jefe_hogar==11 | nivel_educ_jefa_hogar==11)

replace	ifh_educjefe = -0.59	if ambito==3 & (nivel_educ_jefe_hogar==1 | nivel_educ_jefa_hogar==1)
replace ifh_educjefe = -0.08	if ambito==3 & (nivel_educ_jefe_hogar==2 | nivel_educ_jefa_hogar==2)
replace ifh_educjefe = 0.35		if ambito==3 & (nivel_educ_jefe_hogar==3 | nivel_educ_jefa_hogar==3 | nivel_educ_jefe_hogar==4 | nivel_educ_jefa_hogar==4)
replace ifh_educjefe = 0.59		if ambito==3 & (nivel_educ_jefe_hogar==5 | nivel_educ_jefa_hogar==5 | nivel_educ_jefe_hogar==6 | nivel_educ_jefa_hogar==6)
replace ifh_educjefe = 0.68		if ambito==3 & (nivel_educ_jefe_hogar==7 | nivel_educ_jefa_hogar==7 | nivel_educ_jefe_hogar==8 | nivel_educ_jefa_hogar==8)
replace ifh_educjefe = 0.88		if ambito==3 & (nivel_educ_jefe_hogar==9 | nivel_educ_jefa_hogar==9 | nivel_educ_jefe_hogar==10 | nivel_educ_jefa_hogar==10)
replace ifh_educjefe = 0.88		if ambito==3 & (nivel_educ_jefe_hogar==11 | nivel_educ_jefa_hogar==11)

*	Floor material
gen		ifh_piso = .

replace ifh_piso = -0.97	if ambito==1 & sisf_matpiso==7
replace ifh_piso = -0.6		if ambito==1 & sisf_piso_tierra==1
replace ifh_piso = -0.16	if ambito==1 & sisf_piso_cemento==1
replace ifh_piso = 0.08		if ambito==1 & sisf_piso_tabla==1
replace ifh_piso = 0.16		if ambito==1 & sisf_piso_loseta==1
replace ifh_piso = 0.28		if ambito==1 & sisf_piso_lamina==1
replace ifh_piso = 0.51		if ambito==1 & sisf_piso_parquet==1

replace ifh_piso = -1.12	if ambito==2 & sisf_matpiso==7
replace ifh_piso = -0.47	if ambito==2 & sisf_piso_tierra==1
replace ifh_piso = -0.01	if ambito==2 & sisf_piso_cemento==1
replace ifh_piso = 0.3		if ambito==2 & sisf_piso_tabla==1
replace ifh_piso = 0.4		if ambito==2 & sisf_piso_loseta==1
replace ifh_piso = 0.51		if ambito==2 & sisf_piso_lamina==1
replace ifh_piso = 0.71		if ambito==2 & sisf_piso_parquet==1

*	Overcrowded house
gen		ifh_hacinamiento = .

gen		ratio_hacinamiento = sisf_numperso/sisf_numhabitacion
replace ifh_hacinamiento = -0.68	if ambito==1 & ratio_hacinamiento>=6 & ratio_hacinamiento!=.
replace ifh_hacinamiento = -0.51	if ambito==1 & ratio_hacinamiento>=4 & ratio_hacinamiento<6
replace ifh_hacinamiento = -0.31	if ambito==1 & ratio_hacinamiento>=2 & ratio_hacinamiento<4
replace ifh_hacinamiento = -0.07	if ambito==1 & ratio_hacinamiento>=1 & ratio_hacinamiento<2
replace ifh_hacinamiento = 0.24		if ambito==1 & ratio_hacinamiento<1 & ratio_hacinamiento!=.

*	Max education level of any household member
gen		ifh_educmax = .

replace ifh_educmax = -0.35	if ambito==3 & nivel_educ==1
replace ifh_educmax = 0.11	if ambito==3 & nivel_educ==2
replace ifh_educmax = 0.41	if ambito==3 & nivel_educ==3
replace ifh_educmax = 0.62	if ambito==3 & nivel_educ==4
replace ifh_educmax = 0.83	if ambito==3 & nivel_educ==5

*	Have electricity
gen		ifh_elect = .

replace ifh_elect = -0.29 	if ambito==3 & sisf_alumbrado_elect==0
replace ifh_elect = 0.22	if ambito==3 & sisf_alumbrado_elect==1

*	Floor made of ground
gen		ifh_pisotierra = .

replace ifh_pisotierra = -0.17	if ambito==3 & sisf_piso_tierra==1
replace ifh_pisotierra = 0.47	if ambito==3 & sisf_piso_tierra==0

*	INDICE DE FOCALIZACION DE HOGARES
egen	ifh=rowtotal(ifh*)


*-----------------------------------------------------------*
*		4.1.2. INEI's Necesidades Basicas Insatisfechas		*
*-----------------------------------------------------------*
*http://proyectos.inei.gob.pe/web/biblioineipub/bancopub/Est/Lib0068/POB00006.htm

*	Inadecuate house characteristics
gen		nbi1_hogarinadecuado = .

replace nbi1_hogarinadecuado = 1 if sisf_pared_estera==1 | (sisf_piso_tierra==1 & ///
		(sisf_pared_quincha==1 | sisf_pared_piedrabarro==1 | sisf_pared_madera==1 | ///
		sisf_matpared==8))
replace nbi1_hogarinadecuado = 0 if nbi1_hogarinadecuado!=1 & sisf_matpared!=.
		
*	Overcrowded house
gen		nbi2_hacinamiento = .

replace nbi2_hacinamiento = 1 if ratio_hacinamiento>3 & ratio_hacinamiento!=.
replace nbi2_hacinamiento = 0 if ratio_hacinamiento<=3 & ratio_hacinamiento!=.

*	No drain
gen		nbi3_sindesague = .

replace nbi3_sindesague = 1 if sisf_saneamiento_letrina==1 | sisf_saneamiento_rio==1 | sisf_saneamiento_ninguno==1
replace nbi3_sindesague = 0 if sisf_saneamiento_redpubdentro==1 | sisf_saneamiento_redpubfuera==1 | sisf_saneamiento_pozo==1

*	Kids out of school
gen		nbi4_noescuela = .
replace nbi4_noescuela = 1 if noescuela_1==1
replace nbi4_noescuela = 0 if noescuela_1==0

*	High economic dependence
gen		nbi5_altadependencia = .
replace nbi5_altadependencia = 1 if ocupado==0 & (nivel_educ_jefe_hogar<=3 | nivel_educ_jefa_hogar<=3)
replace nbi5_altadependencia = 1 if nivel_educ_jefe_hogar<=3 | nivel_educ_jefa_hogar<=3
replace nbi5_altadependencia = 1 if ratio_dependencia<1/3
replace nbi5_altadependencia = 0 if ratio_dependencia>=1/3 & ratio_dependencia!=.
replace nbi5_altadependencia = 0 if (nivel_educ_jefe_hogar>3 & nivel_educ_jefe_hogar!=.) | (nivel_educ_jefa_hogar>3 & nivel_educ_jefa_hogar!=.)

*	Sum of Necesidades Basicas Insatisfechas
egen	nbi_sum=rowtotal(nbi1_hogarinadecuado nbi2_hacinamiento nbi3_sindesague nbi4_noescuela nbi5_altadependencia)
replace nbi_sum = . if nbi1_hogarinadecuado==. & nbi2_hacinamiento==. & nbi3_sindesague==. & nbi4_noescuela==. & nbi5_altadependencia==.

drop if num_hogares==0

gen		sisf_agua_redpub = 0
replace sisf_agua_redpub = 1 if sisf_agua_redpubdentro==1 | sisf_agua_redpubfuera==1

gen		sisf_saneamiento_redpub = 0
replace sisf_saneamiento_redpub = 1 if sisf_saneamiento_redpubdentro==1 | sisf_saneamiento_redpubfuera==1

drop KEY FIRMANO FIRMA SINPINTAR COLOR ResFin1 ResFin SUMINIS TIEABAS ANIOFIN MESFIN DIAFIN RV9 MES9 DIA9 RV8 MES8 DIA8 RV7 MES7 DIA7 RV6 MES6 DIA6 RV5 MES5 DIA5 RV4 MES4 DIA4 RV3 MES3 DIA3 RV2 MES2 DIA2 RV1 MES1 DIA1 TELEF KM LOTE MZA INTERIOR PISO BLOCK NROPTA_ALF NROPTA NOMVIA TIPVIA ORDINF APELNOM FREMZN MANZ_ALF MANZANA ZONA_SUF ZONA_ALF ZONA

saveold "$a\2 data\2 Working\SAT\sisfoh_hogarpersona_cleaned.dta", replace v(13)
*/
/*-----------------------------------------------------------*
*		V.	Sisfoh individual level - Pooled dataset		*
*-----------------------------------------------------------*
use "$a\2 data\2 Working\sisfoh_personas_cleaned.dta", clear

rename EDAD01		edad
rename DPTO			ubigeo_dpto
rename NIV01		nivel_educ
rename SEXO01		sexo
rename LEE01		lee_escribe
rename SEGU01_1		seg_essalud
rename SEGU01_2		seg_ffaapnp
rename SEGU01_3		seg_privado
rename SEGU01_4		seg_sis
rename SEGU01_5		seg_otro
rename SEGU01_6		seg_ninguno
rename PROG01_1		prog_vasoleche
rename PROG01_2 	prog_comedorpop
rename PROG01_3 	prog_desalm
rename PROG01_4 	prog_papyap
rename PROG01_5 	prog_canastaalim
rename PROG01_6 	prog_juntos
rename PROG01_7 	prog_techo
rename PROG01_8 	prog_pension65
rename PROG01_9 	prog_cunamas
rename PROG01_10	prog_otro
rename PROG01_11	prog_ninguno

egen ubigeo_prov=concat(ubigeo_dpto PROV)
egen ubigeo_dist=concat(ubigeo_prov DIST)
egen ubigeo_ccpp=concat(ubigeo_dist CODCCPP_N)

*	Partitioning the dataset to keep only Obs from Huancavelica, Apurimac, San Martin
*	and Huancayo and La Convencion provinces 
*	(storage limit)
keep if (ubigeo_dpto=="03" | ubigeo_dpto=="09" | ubigeo_dpto=="22") | (ubigeo_prov=="0809" | ubigeo_prov=="1201")

recode sexo (1=0) (2=1)
label def sexo_lb 0 Hombre 1 Mujer
label val sexo sexo_lb

gen		gestante = 0
replace gestante = 1 if GESTA01==1

recode lee_escribe (2=0)
label def lee_escribe_lb 1 Si 0 No
label val lee_escribe lee_escribe_lb

gen		analfab = .
replace analfab = 1 if edad>=15 & lee_escribe==0
replace analfab = 0 if edad<15 | (edad>=15 & lee_escribe==1)

gen		jefe_hogar = .
replace jefe_hogar = 1 if PTES01==1
replace jefe_hogar = 0 if PTES01!=1 & PTES01!=.

gen		nivel_educ2 = .
replace nivel_educ2 = 1	if nivel_educ==1	// Sin educacion
replace nivel_educ2 = 2	if nivel_educ==2	// Inicial
replace nivel_educ2 = 3	if nivel_educ==3 & ULT01<6	// Primaria incompleta
replace nivel_educ2 = 4	if nivel_educ==3 & ULT01==6	// Primaria completa
replace nivel_educ2 = 5	if nivel_educ==4 & ULT01<5	// Secundaria incompleta
replace nivel_educ2 = 6	if nivel_educ==4 & ULT01==5	// Secundaria completa
replace nivel_educ2 = 7	if nivel_educ==5 & ULT01<3	// Sup. no universitaria incompleta
replace nivel_educ2 = 8	if nivel_educ==5 & ULT01>3 & ULT01!=.	// Sup. no universitaria completa
replace nivel_educ2 = 9 if nivel_educ==6 & ULT01<5	// Sup. universitaria incompleta
replace nivel_educ2 = 10 if nivel_educ==6 & ULT01>5 & ULT01!=.	// Sup. universitaria completa
replace nivel_educ2 = 11 if nivel_educ==7	// Post-grado

gen		nivel_educ3_ninguno = 0
replace nivel_educ3_ninguno = 1 	if nivel_educ2==1 | nivel_educ2==2
gen		nivel_educ3_primaria = 0
replace nivel_educ3_primaria = 1	if nivel_educ2==3 | nivel_educ2==4
gen		nivel_educ3_secundaria = 0
replace nivel_educ3_secundaria = 1 	if nivel_educ2==5 | nivel_educ2==6
gen		nivel_educ3_superior = 0
replace nivel_educ3_superior = 1 	if nivel_educ2>=7 & nivel_educ2<=11

*gen		nivel_educ_jefa_hogar = .
*replace nivel_educ_jefa_hogar = nivel_educ2 if jefa_hogar==1

gen		conyugue = .
replace conyugue = 1 if PTES01==2
replace conyugue = 0 if PTES01!=2  & PTES01!=.

*gen		nivel_educ_conyugue_m = .
*replace nivel_educ_conyugue_m = nivel_educ2 if conyugue_m==1

gen		ocupado = .
replace ocupado = 1 if ERA01>=1 & ERA01<=5
replace ocupado = 0 if ERA01>=6 & ERA01<=10

gen		edad_6_12 = 0
replace edad_6_12 = 1 if edad>=6 & edad<=12

gen		edad_6_12_noescuela = 0
replace edad_6_12_noescuela = 1 if edad_6_12==1 & ERA01!=8 & ERA01!=.

*gen		lengua_nocastellano = .
*replace lengua_nocastellano = 1 if IDIOMA01!=1 & IDIOMA01!=.
*replace lengua_nocastellano = 0 if IDIOMA01==4 

gen		trabaja_agricola	= 0
replace	trabaja_agricola	= 1 if SECT01==1
gen		trabaja_pecuaria	= 0
replace trabaja_pecuaria	= 1 if SECT01==2
gen		trabaja_agropec		= 0
replace trabaja_agropec		= 1 if trabaja_agricola==1 | trabaja_pecuaria==1
gen		trabaja_forestal	= 0
replace trabaja_forestal	= 1 if SECT01==3
gen		trabaja_pesquera	= 0
replace trabaja_pesquera	= 1 if SECT01==4
gen		trabaja_minera		= 0
replace trabaja_minera		= 1 if SECT01==5
gen		trabaja_artesanal	= 0
replace trabaja_artesanal	= 1 if SECT01==6
gen		trabaja_comercial	= 0
replace trabaja_comercial	= 1 if SECT01==7
gen		trabaja_servicios	= 0
replace trabaja_servicios	= 1 if SECT01==8
gen		trabaja_otro		= 0
replace trabaja_otro		= 1 if SECT01==9
gen		trabaja_gobierno	= 0
replace trabaja_gobierno	= 1 if SECT01==10

gen		trabaja_otro2 = 0
replace trabaja_otro2 = 1 if trabaja_forestal==1 | trabaja_pesquera==1 | trabaja_otro==1

replace seg_essalud = 0 if seg_essalud==.
replace seg_essalud = 1 if seg_essalud==1
replace seg_ffaapnp = 0 if seg_ffaapnp==.
replace seg_ffaapnp = 1 if seg_ffaapnp==2
replace seg_privado = 0 if seg_privado==.
replace seg_privado = 1 if seg_privado==3
replace seg_sis 		= 0 if seg_sis==.
replace seg_sis 		= 1 if seg_sis==4
replace seg_otro 	= 0 if seg_otro==.
replace seg_otro 	= 1 if seg_otro==5
replace seg_ninguno = 0 if seg_ninguno==.
replace seg_ninguno = 1 if seg_ninguno==6

gen		seg_otro2 = 0
replace seg_otro2 = 1 if seg_sis==1 | seg_otro==1

egen	num_seguro_ind = rowtotal(seg_essalud seg_ffaapnp seg_privado seg_sis seg_otro)
gen		tiene_seguro = 0
replace tiene_seguro = 1 if num_seguro_ind>0 & num_seguro_ind!=.

replace prog_vasoleche		= 0 if prog_vasoleche==.
replace prog_vasoleche 		= 1 if prog_vasoleche==1
replace prog_comedorpop 	= 0 if prog_comedorpop==.
replace prog_comedorpop		= 1 if prog_comedorpop==2	
replace prog_desalm 		= 0 if prog_desalm==.
replace prog_desalm			= 1 if prog_desalm==3
replace prog_papyap 		= 0 if prog_papyap==.
replace prog_papyap			= 1 if prog_papyap==4
replace prog_canastaalim 	= 0 if prog_canastaalim==.
replace prog_canastaalim	= 1 if prog_canastaalim==5
replace prog_juntos 		= 0 if prog_juntos==.
replace prog_juntos			= 1 if prog_juntos==6
replace prog_techo 			= 0 if prog_techo==.
replace prog_techo			= 1 if prog_techo==7
replace prog_pension65 		= 0 if prog_pension65==.
replace prog_pension65		= 1 if prog_pension65==8
replace prog_cunamas 		= 0 if prog_cunamas==.
replace prog_cunamas		= 1 if prog_cunamas==9
replace prog_otro 			= 0 if prog_otro==.
replace prog_otro			= 1 if prog_otro==10
replace prog_ninguno		= 0 if prog_ninguno==.
replace prog_ninguno		= 1 if prog_ninguno==11

gen		prog_otro2 = 0
replace prog_otro2 = 1 if prog_techo==1 | prog_cunamas==1 | prog_otro==1

egen	num_prog_ind = rowtotal(prog_vasoleche prog_comedorpop prog_desalm prog_papyap prog_canastaalim prog_juntos prog_techo prog_pension65 prog_cunamas prog_otro)
gen		tiene_prog = 0
replace tiene_prog = 1 if num_prog_ind>0 & num_prog_ind!=.

gen		ocupacion_dep		= 0
replace ocupacion_dep		= 1 if ERA01==1
gen		ocupacion_indep		= 0
replace ocupacion_indep		= 1 if ERA01==2 | ERA01==3
gen		ocupacion_trabhog	= 0
replace ocupacion_trabhog	= 1 if ERA01==4
gen		ocupacion_famnorem	= 0
replace ocupacion_famnorem	= 1 if ERA01==5
gen		ocupacion_desemp	= 0
replace ocupacion_desemp	= 1 if ERA01==6
gen		ocupacion_hogar		= 0
replace ocupacion_hogar		= 1 if ERA01==7
gen		ocupacion_estud		= 0
replace ocupacion_estud		= 1 if ERA01==8
gen		ocupacion_jubilado	= 0
replace ocupacion_jubilado	= 1 if ERA01==9

gen		ocupacion_otro2 = 0
replace ocupacion_otro2 = 1 if ocupacion_trabhog==1 | ocupacion_jubilado==1

gen a=1
bys ubigeo_ccpp: egen pob_ccpp=count(a)

gen edad_0_5 		= 0
replace edad_0_5 	= 1 if edad>=0 & edad<5
gen edad_5_10		= 0 
replace edad_5_10 	= 1 if edad>=5 & edad<10
gen edad_10_15		= 0
replace edad_10_15	= 1 if edad>=10 & edad<15
gen edad_15_20		= 0
replace edad_15_20	= 1 if edad>=15 & edad<20
gen edad_20_25		= 0
replace edad_20_25  = 1 if edad>=20 & edad<25
gen edad_25_30		= 0
replace edad_25_30	= 1 if edad>=25 & edad<30
gen edad_30_35		= 0
replace edad_30_35	= 1 if edad>=30 & edad<35
gen edad_35_40		= 0
replace edad_35_40 	= 1 if edad>=35 & edad<40
gen edad_40_45		= 0
replace edad_40_45	= 1 if edad>=40 & edad<45
gen edad_45_50		= 0
replace edad_45_50 	= 1 if edad>=45 & edad<50
gen edad_50_55		= 0
replace edad_50_55	= 1 if edad>=50 & edad<55
gen edad_55_60		= 0
replace edad_55_60	= 1 if edad>=55 & edad<60
gen edad_60_65		= 0
replace edad_60_65	= 1 if edad>=60 & edad<65
gen edad_65_70		= 0
replace edad_65_70	= 1 if edad>=65 & edad<70
gen edad_70_mas		= 0
replace edad_70_mas	= 1 if edad>=70 & edad!=.

bys ubigeo_ccpp: egen prop_edad_0_5		= total(edad_0_5)
bys ubigeo_ccpp: egen prop_edad_5_10	= total(edad_5_10)
bys ubigeo_ccpp: egen prop_edad_10_15	= total(edad_10_15)
bys ubigeo_ccpp: egen prop_edad_15_20	= total(edad_15_20)
bys ubigeo_ccpp: egen prop_edad_20_25	= total(edad_20_25)
bys ubigeo_ccpp: egen prop_edad_25_30	= total(edad_25_30)
bys ubigeo_ccpp: egen prop_edad_30_35	= total(edad_30_35)
bys ubigeo_ccpp: egen prop_edad_35_40	= total(edad_35_40)
bys ubigeo_ccpp: egen prop_edad_40_45	= total(edad_40_45)
bys ubigeo_ccpp: egen prop_edad_45_50	= total(edad_45_50)
bys ubigeo_ccpp: egen prop_edad_50_55	= total(edad_50_55)
bys ubigeo_ccpp: egen prop_edad_55_60	= total(edad_55_60)
bys ubigeo_ccpp: egen prop_edad_60_65	= total(edad_60_65)
bys ubigeo_ccpp: egen prop_edad_65_70	= total(edad_65_70)
bys ubigeo_ccpp: egen prop_edad_70_mas	= total(edad_70_mas)

replace prop_edad_0_5 = prop_edad_0_5 / pob_ccpp
replace prop_edad_5_10 = prop_edad_5_10 / pob_ccpp
replace prop_edad_10_15 = prop_edad_10_15 / pob_ccpp
replace prop_edad_15_20 = prop_edad_15_20 / pob_ccpp
replace prop_edad_20_25 = prop_edad_20_25 / pob_ccpp
replace prop_edad_25_30 = prop_edad_25_30 / pob_ccpp
replace prop_edad_30_35 = prop_edad_30_35 / pob_ccpp
replace prop_edad_35_40 = prop_edad_35_40 / pob_ccpp
replace prop_edad_40_45 = prop_edad_40_45 / pob_ccpp
replace prop_edad_45_50 = prop_edad_45_50 / pob_ccpp
replace prop_edad_50_55 = prop_edad_50_55 / pob_ccpp
replace prop_edad_55_60 = prop_edad_55_60 / pob_ccpp
replace prop_edad_60_65 = prop_edad_60_65 / pob_ccpp
replace prop_edad_65_70 = prop_edad_65_70 / pob_ccpp
replace prop_edad_70_mas = prop_edad_70_mas / pob_ccpp

drop pob_ccpp a

merge m:1 ubigeo_ccpp SECUENCIA CONG NROVIV NHOGAR using "$a\2 data\2 Working\sisfoh_hogarpersona_cleaned.dta", keepusing(_all) gen(_merge_ind_both)
*/
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                     6,062,203
        from master                         0  (_merge_ind_both==1)
        from using                  6,062,203  (_merge_ind_both==2)

    matched                         1,907,249  (_merge_ind_both==3)
    -----------------------------------------
	Note: unmatched individuals come form HH located in different regions
*/
/*
drop if _merge_ind_both==2
drop _merge_ind_both

saveold "$a\2 data\2 Working\SAT\sisfoh_persona_both.dta", replace v(13)

* Create auziliar dataset with new age distribution variables at ccpp level
keep ubigeo_ccpp prop_edad*
collapse (max) prop_edad*, by(ubigeo_ccpp)
saveold "$a\2 data\2 Working\SAT\new_age_distribution2013.dta", replace v(13)
*/
use "$a\2 data\2 Working\sisfoh_persona_both.dta", clear

keep ubigeo_ccpp prog_*
collapse (sum) prog_*, by(ubigeo_ccpp)
saveold "$a\2 data\2 Working\SAT\prog_distribution2013.dta", replace v(13)
e
/*-------------------------------------------------------*
*		V.1	Sisfoh individual level - Men dataset		*
*-------------------------------------------------------*

use "$a\2 data\2 Working\sisfoh_persona_both.dta", clear
keep if sexo==0
saveold "$a\2 data\2 Working\sisfoh_persona_men.dta", replace v(13)


*-------------------------------------------------------*
*		V.2	Sisfoh individual level - Women dataset		*
*-------------------------------------------------------*

use "$a\2 data\2 Working\sisfoh_persona_both.dta", clear
keep if sexo==1
saveold "$a\2 data\2 Working\sisfoh_persona_women.dta", replace v(13)
*/
