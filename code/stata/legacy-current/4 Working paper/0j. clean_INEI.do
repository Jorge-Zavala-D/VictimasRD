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


	use "$input_dir\1 Raw\9 INEI\CCPP_SISFOH_CPV_ENTREGAOKA.dta", clear
	
	rename c5_p4_1	edad_2017
	rename c5_p2	sex_2017
	rename gesta01	gestante_2017
	rename c5_p8_1 	seg_sis_2017
	rename c5_p8_2 	seg_essalud_2017
	rename c5_p8_3 	seg_ffaa_2017
	rename c5_p8_4 	seg_privado_2017
	rename c5_p8_5 	seg_otro_2017
	rename c5_p8_6	seg_ninguno_2017
	rename c5_p12		lee_escribe_2017
	rename c5_p13_niv	nivel_educ_2017
	rename c5_p16		ocupado_2017
	rename c5_p14		asiste_educacion_2017
	rename c5_p9_7		discap_ninguno_2017
	rename c5_p11		idioma_2017
	rename c5_p27		num_hijos_2017
	rename c2_p12		num_habitaciones_2017
	rename t_c4_p1		num_persvivienda_2017
	rename c4_p1		num_pershogar_2017
		
	egen num_seg_ind_17 = rowtotal(seg_sis_2017 seg_essalud_2017 seg_ffaa_2017 seg_privado_2017 seg_otro_2017)
	recode asiste_educacion_2017 (2=0)
	
	gen edad_6_12_noescuela_17 = 0
	replace edad_6_12_noescuela_17 = 1 if (edad_2017>=6 & edad_2017<=12) & asiste_educacion==0
	
	gen ocupacion_dep_2017 = 0			// Revisar codificacion
	replace ocupacion_dep_2017 = 1 if c5_p21_est==3 | c5_p21_est==4 | c5_p21_est==5 | c5_p21_est==6
	
	gen ocupacion_indep_2017 = 0
	replace ocupacion_indep_2017 = 1 if c5_p21_est==1 | c5_p21_est==2
	
	gen ocupacion_desemp_2017 = 0
	replace ocupacion_desemp_2017 = 1 if c5_p17_est==7
	
	gen ocupacion_hogar_2017 = 0
	replace ocupacion_hogar_2017 = 1 if c5_p17_est==6
	
	gen ocupacion_mype_2017 = 0
	replace ocupacion_mype_2017 = 1 if c5_p22==1 | c5_p22==2
	
	rename c5_p20_cod_est		ciiu_cod
	tostring 	ciiu_cod, gen(ciiu_categ)
	gen a=0
	egen ciiu_categ2=concat(a ciiu_categ) if  ciiu_cod<1000
	replace ciiu_categ2=ciiu_categ if ciiu_cod>=1000 & ciiu_cod!=.
	replace		ciiu_categ = substr(ciiu_categ2,1,2)
	destring 	ciiu_categ, replace
	drop ciiu_categ2	
	
	gen trabaja_agro_2017 = .
	replace trabaja_agro_2017 = 1 if ciiu_categ>=1 & ciiu_categ<=4
	replace trabaja_agro_2017 = 0 if trabaja_agro_2017!=1 & ciiu_categ!=.
	
	gen trabaja_mineria_2017 = .
	replace trabaja_mineria_2017 = 1 if ciiu_categ>=5 & ciiu_categ<=9
	replace trabaja_mineria_2017 = 0 if trabaja_mineria_2017!=1 & ciiu_categ!=.
	
	gen trabaja_manuf_2017 = .
	replace trabaja_manuf_2017 = 1 if ciiu_categ>=10 & ciiu_categ<=33
	replace trabaja_manuf_2017 = 0 if trabaja_manuf_2017!=1 & ciiu_categ!=.
	
	gen trabaja_serv_2017 = .
	replace trabaja_serv_2017 = 1 if ciiu_categ>=35 & ciiu_categ<=39
	replace trabaja_serv_2017 = 0 if trabaja_serv_2017!=1 & ciiu_categ!=.
	
	gen trabaja_constr_2017 = .
	replace trabaja_constr_2017 = 1 if ciiu_categ>=41 & ciiu_categ<=43
	replace trabaja_constr_2017 = 0 if trabaja_constr_2017!=1 & ciiu_categ!=.	
	
	gen trabaja_comercio_2017 = .
	replace trabaja_comercio_2017 = 1 if ciiu_categ>=45 & ciiu_categ<=47
	replace trabaja_comercio_2017 = 0 if trabaja_comercio_2017!=1 & ciiu_categ!=.
	
	gen trabaja_transp_2017 = .
	replace trabaja_transp_2017 = 1 if ciiu_categ>=49 & ciiu_categ<=53
	replace trabaja_transp_2017 = 0 if trabaja_transp_2017!=1 & ciiu_categ!=.
	
	gen trabaja_turismo_2017 = .
	replace trabaja_turismo_2017 = 1 if ciiu_categ>=55 & ciiu_categ<=56
	replace trabaja_turismo_2017 = 0 if trabaja_turismo_2017!=1 & ciiu_categ!=.
	
	gen trabaja_info_2017 = .
	replace trabaja_info_2017 = 1 if ciiu_categ>=58 & ciiu_categ<=63
	replace trabaja_info_2017 = 0 if trabaja_info_2017!=1 & ciiu_categ!=.
	
	gen trabaja_fin_2017 = .
	replace trabaja_fin_2017 = 1 if ciiu_categ>=64 & ciiu_categ<=66
	replace trabaja_fin_2017 = 0 if trabaja_fin_2017!=1 & ciiu_categ!=.
	
	gen trabaja_inmob_2017 = .
	replace trabaja_inmob_2017 = 1 if ciiu_categ>=66 & ciiu_categ<=68
	replace trabaja_inmob_2017 = 0 if trabaja_inmob_2017!=1 & ciiu_categ!=.
	
	gen trabaja_actprof_2017 = .
	replace trabaja_actprof_2017 = 1 if ciiu_categ>=69 & ciiu_categ<=82
	replace trabaja_actprof_2017 = 0 if trabaja_actprof_2017!=1 & ciiu_categ!=.
	
	gen trabaja_gob_2017 = .
	replace trabaja_gob_2017 = 1 if ciiu_categ>=84 & ciiu_categ<=84
	replace trabaja_gob_2017 = 0 if trabaja_gob_2017!=1 & ciiu_categ!=.

	gen trabaja_educ_2017 = .
	replace trabaja_educ_2017 = 1 if ciiu_categ>=85 & ciiu_categ<=85
	replace trabaja_educ_2017 = 0 if trabaja_educ_2017!=1 & ciiu_categ!=.
	
	gen trabaja_salud_2017 = .
	replace trabaja_salud_2017 = 1 if ciiu_categ>=86 & ciiu_categ<=88
	replace trabaja_salud_2017 = 0 if trabaja_salud_2017!=1 & ciiu_categ!=.	
	
	gen trabaja_otro_2017 = .
	replace trabaja_otro_2017 = 1 if ciiu_categ>=90 & ciiu_categ<=99
	replace trabaja_otro_2017 = 0 if trabaja_otro_2017!=1 & ciiu_categ!=.	

		
	gen trabaja_otro2_2017 = .
	replace trabaja_otro2_2017 = 1 if trabaja_serv_2017==1 | trabaja_info_2017==1 | trabaja_fin_2017==1 | trabaja_inmob_2017==1 | trabaja_salud_2017==1
	replace trabaja_otro2_2017 = 0 if trabaja_otro2_2017!=1 & ciiu_categ!=.	
	
	
	
	gen jefe_hogar_2017 = 0
	replace jefe_hogar_2017 = 1 if c5_p1==1
		
	gen		pared_ladrillo_2017 = .
	replace pared_ladrillo_2017 = 1 if c2_p3==1
	replace pared_ladrillo_2017 = 0 if c2_p3!=1 & c2_p3!=.

	gen		pared_piedra_2017 = .
	replace pared_piedra_2017 = 1 if c2_p3==2
	replace pared_piedra_2017 = 0 if c2_p3!=2 & c2_p3!=.	
	
	gen		pared_adobe_2017 = .
	replace pared_adobe_2017 = 1 if c2_p3==3
	replace pared_adobe_2017 = 0 if c2_p3!=3 & c2_p3!=.
	
	gen		pared_quincha_2017 = .
	replace pared_quincha_2017 = 1 if c2_p3==4 | c2_p3==5
	replace pared_quincha_2017 = 0 if c2_p3!=4 & c2_p3!=5 & c2_p3!=.
	
	gen		pared_barro_2017 = .
	replace pared_barro_2017 = 1 if c2_p3==6
	replace pared_barro_2017 = 0 if c2_p3!=6 & c2_p3!=.	
	
	gen		pared_madera_2017 = .
	replace pared_madera_2017 = 1 if c2_p3==7
	replace pared_madera_2017 = 0 if c2_p3!=7 & c2_p3!=.		
	
	gen		pared_estera_2017 = .
	replace pared_estera_2017 = 1 if c2_p3==8
	replace pared_estera_2017 = 0 if c2_p3!=8 & c2_p3!=.	
	
	gen		techo_concreto_2017 = .
	replace techo_concreto_2017 = 1 if c2_p4==1 
	replace techo_concreto_2017 = 0 if c2_p4!=1 & c2_p4!=.
	
	gen		techo_madera_2017 = .
	replace techo_madera_2017 = 1 if c2_p4==2
	replace techo_madera_2017 = 0 if c2_p4!=2 & c2_p4!=.
	
	gen		techo_teja_2017 = .
	replace techo_teja_2017 = 1 if c2_p4==3
	replace techo_teja_2017 = 0 if c2_p4!=3 & c2_p4!=.
	
	gen		techo_calamina_2017 = .
	replace techo_calamina_2017 = 1 if c2_p4==4
	replace techo_calamina_2017 = 0 if c2_p4!=4 & c2_p4!=.
	
	gen		techo_estera_2017 = .
	replace techo_estera_2017 = 1 if c2_p4==5 | c2_p4==6
	replace techo_estera_2017 = 0 if c2_p4!=5 & c2_p4!=6 & c2_p4!=.
	
	gen		techo_paja_2017 = .
	replace techo_paja_2017 = 1 if c2_p4==7
	replace techo_paja_2017 = 0 if c2_p4!=7 & c2_p4!=.

	gen		piso_parquet_2017 = .
	replace piso_parquet_2017 = 1 if c2_p5==1
	replace piso_parquet_2017 = 0 if c2_p5!=1 & c2_p5!=.
	
	gen		piso_lamina_2017 = .
	replace piso_lamina_2017 = 1 if c2_p5==2
	replace piso_lamina_2017 = 0 if c2_p5!=2 & c2_p5!=.
	
	gen		piso_loseta_2017 = .
	replace piso_loseta_2017 = 1 if c2_p5==3
	replace piso_loseta_2017 = 0 if c2_p5!=3 & c2_p5!=.
	
	gen		piso_tabla_2017 = .
	replace piso_tabla_2017 = 1 if c2_p5==4
	replace piso_tabla_2017 = 0 if c2_p5!=4 & c2_p5!=.
	
	gen		piso_cemento_2017 = .
	replace piso_cemento_2017 = 1 if c2_p5==5
	replace piso_cemento_2017 = 0 if c2_p5!=5 & c2_p5!=.
	
	gen		piso_tierra_2017 = .
	replace piso_tierra_2017 = 1 if c2_p5==6
	replace piso_tierra_2017 = 0 if c2_p5!=6 & c2_p5!=.
	
	
	gen 	agua_redpubdentro_2017 = .
	replace agua_redpubdentro_2017 = 1 if c2_p6==1
	replace agua_redpubdentro_2017 = 0 if c2_p6!=1 & c2_p6!=.
	
	gen 	agua_redpubfuera_2017 = .
	replace agua_redpubfuera_2017 = 1 if c2_p6==2
	replace agua_redpubfuera_2017 = 0 if c2_p6!=2 & c2_p6!=.	
	
	gen 	agua_redpub_2017 = .
	replace agua_redpub_2017 = 1 if agua_redpubdentro_2017==1 | agua_redpubfuera_2017==1
	replace agua_redpub_2017 = 0 if agua_redpubdentro_2017!=1 & agua_redpubfuera_2017!=1 & c2_p6!=.		
	
	gen 	agua_pilon_2017 = .
	replace agua_pilon_2017 = 1 if c2_p6==3
	replace agua_pilon_2017 = 0 if c2_p6!=3 & c2_p6!=.	
	
	gen 	agua_cisterna_2017 = .
	replace agua_cisterna_2017 = 1 if c2_p6==4
	replace agua_cisterna_2017 = 0 if c2_p6!=4 & c2_p6!=.
	
	gen 	agua_pozo_2017 = .
	replace agua_pozo_2017 = 1 if c2_p6==5
	replace agua_pozo_2017 = 0 if c2_p6!=5 & c2_p6!=.
	
	gen 	agua_rio_2017 = .
	replace agua_rio_2017 = 1 if c2_p6==7
	replace agua_rio_2017 = 0 if c2_p6!=7 & c2_p6!=.	
	
	gen 	desague_redpubdentro_2017 = .
	replace desague_redpubdentro_2017 = 1 if c2_p10==1
	replace desague_redpubdentro_2017 = 0 if c2_p10!=1 & c2_p10!=.
	
	gen 	desague_redpubfuera_2017 = .
	replace desague_redpubfuera_2017 = 1 if c2_p10==2
	replace desague_redpubfuera_2017 = 0 if c2_p10!=2 & c2_p10!=.
	
	gen 	desague_redpub_2017 = .
	replace desague_redpub_2017 = 1 if desague_redpubdentro_2017==1 | desague_redpubfuera_2017==1
	replace desague_redpub_2017 = 0 if desague_redpubdentro_2017!=1 & desague_redpubfuera_2017!=1 & c2_p10!=.	
	
	gen 	desague_pozo_2017 = .
	replace desague_pozo_2017 = 1 if c2_p10==3
	replace desague_pozo_2017 = 0 if c2_p10!=3 & c2_p10!=.

	gen 	desague_letrina_2017 = .
	replace desague_letrina_2017 = 1 if c2_p10==4
	replace desague_letrina_2017 = 0 if c2_p10!=4 & c2_p10!=.

	gen 	desague_rio_2017 = .
	replace desague_rio_2017 = 1 if c2_p10==6
	replace desague_rio_2017 = 0 if c2_p10!=6 & c2_p10!=.
	
	gen 	desague_ninguno_2017 = .
	replace desague_ninguno_2017 = 1 if c2_p10==7
	replace desague_ninguno_2017 = 0 if c2_p10!=7 & c2_p10!=.
	
	gen		alumbrado_2017 = .
	replace alumbrado_2017 = 1 if c2_p11==1
	replace alumbrado_2017 = 0 if c2_p11==2
	
	gen		combust_elect_2017 = .
	replace combust_elect_2017 = 1 if c3_p1_1==1
	replace combust_elect_2017 = 0 if c3_p1_1==0
	
	gen		combust_gas_2017 = .
	replace combust_gas_2017 = 1 if c3_p1_2==1 | c3_p1_3==1
	replace combust_gas_2017 = 0 if c3_p1_2==0 & c3_p1_3==0	
	
	gen		combust_carbon_2017 = .
	replace combust_carbon_2017 = 1 if c3_p1_4==1
	replace combust_carbon_2017 = 0 if c3_p1_4==0	
	
	gen		combust_lea_2017 = .
	replace combust_lea_2017 = 1 if c3_p1_5==1
	replace combust_lea_2017 = 0 if c3_p1_5==0		
	
	gen		combust_bosta_2017 = .
	replace combust_bosta_2017 = 1 if c3_p1_6==1
	replace combust_bosta_2017 = 0 if c3_p1_6==0		
	
	
	rename c3_p2_1 activo_equiposonido_2017
	recode activo_equiposonido_2017 (2=0)		
	
	rename c3_p2_2 activo_tvcolor_2017
	recode activo_tvcolor_2017 (2=0)		
	
	rename c3_p2_3 activo_cocina_2017
	recode activo_cocina_2017 (2=0)		

	rename c3_p2_4 activo_refri_2017
	recode activo_refri_2017 (2=0)		
	
	rename c3_p2_5 activo_lavadora_2017
	recode activo_lavadora_2017 (2=0)		
	
	rename c3_p2_6 activo_microondas_2017
	recode activo_microondas_2017 (2=0)		
	
	rename c3_p2_7 activo_licuadora_2017
	recode activo_licuadora_2017 (2=0)	
	
	rename c3_p2_8 activo_plancha_2017
	recode activo_plancha_2017 (2=0)		
	
	rename c3_p2_9 activo_compu_2017
	recode activo_compu_2017 (2=0)		
	
	rename c3_p2_10 activo_celular_2017
	recode activo_celular_2017 (2=0)		
	
	rename c3_p2_11 activo_fijo_2017
	recode activo_fijo_2017 (2=0)
	
	rename c3_p2_12 activo_cable_2017
	recode activo_cable_2017 (2=0)		
	
	rename c3_p2_13 activo_internet_2017
	recode activo_internet_2017 (2=0)		
	
	gen		activo_transporte_2017 = .
	replace activo_transporte_2017 = 1 if c3_p2_14==1 | c3_p2_15==1 | c3_p2_16==1
	replace activo_transporte_2017 = 0 if c3_p2_14==2 & c3_p2_15==2 & c3_p2_16==2	
	
	recode sex_2017 (2=1) (1=0)
	recode gestante_2017 (2=0)
	recode lee_escribe_2017 (2=0)
	recode nivel_educ_2017 (5=2) (6=5) (7=6) (8=7) (9=8) (10=9)
	recode ocupado_2017 (2=0)
	recode num_hijos_2017 (99=.r)
	replace num_hijos_2017 = 0 if c5_p27_1==1
	
	gen 	nivel_educ_ninguno_17 = .
	replace nivel_educ_ninguno = 1 if nivel_educ_2017 == 1
	replace nivel_educ_ninguno = 0 if nivel_educ_2017 !=1 & nivel_educ_2017!=.
	
	gen 	nivel_educ_inicial_17 = .
	replace nivel_educ_inicial_17 = 1 if nivel_educ_2017 == 2
	replace nivel_educ_inicial_17 = 0 if nivel_educ_2017 !=2 & nivel_educ_2017!=.	
	
	gen 	nivel_educ_primaria_17 = .
	replace nivel_educ_primaria_17 = 1 if nivel_educ_2017 == 3
	replace nivel_educ_primaria_17 = 0 if nivel_educ_2017 !=3 & nivel_educ_2017!=.	
	
	gen 	nivel_educ_secundaria_17 = .
	replace nivel_educ_secundaria_17 = 1 if nivel_educ_2017 == 4
	replace nivel_educ_secundaria_17 = 0 if nivel_educ_2017 !=4 & nivel_educ_2017!=.	
	
	gen 	nivel_educ_tecnica_17 = .
	replace nivel_educ_tecnica_17 = 1 if nivel_educ_2017 == 5 | nivel_educ_2017 == 6
	replace nivel_educ_tecnica_17 = 0 if nivel_educ_2017 !=5 & nivel_educ_2017!=6 & nivel_educ_2017!=.	
	
	gen 	nivel_educ_universitaria_17 = .
	replace nivel_educ_universitaria_17 = 1 if nivel_educ_2017 == 7 | nivel_educ_2017 == 8
	replace nivel_educ_universitaria_17 = 0 if nivel_educ_2017 !=7 & nivel_educ_2017!=8 & nivel_educ_2017!=.	
	
	gen 	nivel_educ_postgrado_17 = .
	replace nivel_educ_postgrado_17 = 1 if nivel_educ_2017 == 9
	replace nivel_educ_postgrado_17 = 0 if nivel_educ_2017 !=9 & nivel_educ_2017!=.	
	
	
	gen	edad_u1_2017 = 0
	replace edad_u1_2017 = 1 if edad_2017<1
	gen edad_1_14_2017 = 0
	replace edad_1_14_2017 = 1 if edad_2017>=1 & edad_2017<=14
	gen edad_15_29_2017 = 0
	replace edad_15_29_2017 = 1 if edad_2017>=15 & edad_2017<=29
	gen edad_30_44_2017 = 0
	replace edad_30_44_2017 = 1 if edad_2017>=30 & edad_2017<=44
	gen edad_45_64_2017 = 0
	replace edad_45_64_2017 = 1 if edad_2017>=45 & edad_2017<=64
	gen	edad_65_2017 = 0
	replace edad_65_2017 = 1 if edad_2017>=65 & edad_2017!=.
	gen edad_15mas_2017 = 0
	replace edad_15mas_2017 = 1 if edad_2017>=15 & edad_2017!=.
	
	
	gen edad_0_5_2017 		= 0
	replace edad_0_5_2017 	= 1 if edad_2017>=0 & edad_2017<5
	gen edad_5_10_2017		= 0 
	replace edad_5_10_2017 	= 1 if edad_2017>=5 & edad_2017<10
	gen edad_10_15_2017		= 0
	replace edad_10_15_2017	= 1 if edad_2017>=10 & edad_2017<15
	gen edad_15_20_2017		= 0
	replace edad_15_20_2017	= 1 if edad_2017>=15 & edad_2017<20
	gen edad_20_25_2017		= 0
	replace edad_20_25_2017  = 1 if edad_2017>=20 & edad_2017<25
	gen edad_25_30_2017		= 0
	replace edad_25_30_2017	= 1 if edad_2017>=25 & edad_2017<30
	gen edad_30_35_2017		= 0
	replace edad_30_35_2017	= 1 if edad_2017>=30 & edad_2017<35
	gen edad_35_40_2017		= 0
	replace edad_35_40_2017 	= 1 if edad_2017>=35 & edad_2017<40
	gen edad_40_45_2017		= 0
	replace edad_40_45_2017	= 1 if edad_2017>=40 & edad_2017<45
	gen edad_45_50_2017		= 0
	replace edad_45_50_2017 	= 1 if edad_2017>=45 & edad_2017<50
	gen edad_50_55_2017		= 0
	replace edad_50_55_2017	= 1 if edad_2017>=50 & edad_2017<55
	gen edad_55_60_2017		= 0
	replace edad_55_60_2017	= 1 if edad_2017>=55 & edad_2017<60
	gen edad_60_65_2017		= 0
	replace edad_60_65_2017	= 1 if edad_2017>=60 & edad_2017<65
	gen edad_65_70_2017		= 0
	replace edad_65_70_2017	= 1 if edad_2017>=65 & edad_2017<70
	gen edad_70_mas_2017		= 0
	replace edad_70_mas_2017	= 1 if edad_2017>=70 & edad_2017!=.

	gen edad_20_30_2017		= 0
	replace edad_20_30_2017	= 1 if edad_2017>=20 & edad_2017<30
	
	gen	menor_edad_2017 = 0
	replace menor_edad_2017 =1 if edad_2017<=18
	
	gen	menor_15_2017 = 0
	replace menor_15_2017 =1 if edad_2017<=15
	
	gen	mayor_15_2017 = 0
	replace menor_15_2017 =1 if edad_2017<=15
	
	drop a
	gen a = "0"
	destring ubigeo_ccpp, gen(b)
	rename ubigeo_ccpp ubigeo_ccpp2
	egen ubigeo_ccpp=concat(a ubigeo_ccpp2) if b<1000000000
	replace ubigeo_ccpp = ubigeo_ccpp2 if ubigeo_ccpp==""
	drop a b
	
	gen	migracion = .
	replace migracion = 1 if idccpp_sisfoh!=idccpp2019 & idccpp2019!=""
	replace migracion = 0 if idccpp_sisfoh==idccpp2019
	
	gen	desgaste = .
	replace desgaste = 1 if idccpp_sisfoh!="" & idccpp2019==""
	replace desgaste = 0 if idccpp_sisfoh!="" & idccpp2019!=""
	
	gen	ubigeo2017_ccpp=substr(idccpp2019,7,4)
	gen	ubigeo2017_dist=substr(idccpp2019,5,2)
	gen	ubigeo2017_prov=substr(idccpp2019,3,2)
	gen	ubigeo2017_dpto=substr(idccpp2019,1,2)	

	gen	ubigeo2013_ccpp=substr(idccpp_sisfoh,7,4)
	gen	ubigeo2013_dist=substr(idccpp_sisfoh,5,2)
	gen	ubigeo2013_prov=substr(idccpp_sisfoh,3,2)
	gen	ubigeo2013_dpto=substr(idccpp_sisfoh,1,2)
	
	
	gen migracion_escala = .
	replace migracion_escala = 1 if migracion==0
	replace migracion_escala = 2 if migracion==1 & ubigeo2017_dpto==ubigeo2013_dpto & ubigeo2017_prov==ubigeo2013_prov & ubigeo2017_dist==ubigeo2013_dist & ubigeo2017_ccpp!=ubigeo2013_ccpp
	replace migracion_escala = 3 if migracion==1 & ubigeo2017_dpto==ubigeo2013_dpto & ubigeo2017_prov==ubigeo2013_prov & ubigeo2017_dist!=ubigeo2013_dist
	replace migracion_escala = 4 if migracion==1 & ubigeo2017_dpto==ubigeo2013_dpto & ubigeo2017_prov!=ubigeo2013_prov
	replace migracion_escala = 5 if migracion==1 & ubigeo2017_dpto!=ubigeo2013_dpto
	
	gen migracion_escala_ccpp = .
	replace migracion_escala_ccpp = 1 if migracion_escala==2
	replace migracion_escala_ccpp = 0 if migracion_escala_ccpp!=1 & migracion_escala!=.
	
	gen migracion_escala_dist = .
	replace migracion_escala_dist = 1 if migracion_escala==3
	replace migracion_escala_dist = 0 if migracion_escala_dist!=1 & migracion_escala!=.	
	
	gen migracion_escala_prov = .
	replace migracion_escala_prov = 1 if migracion_escala==4
	replace migracion_escala_prov = 0 if migracion_escala_prov!=1 & migracion_escala!=.	
	
	gen migracion_escala_dpto = .
	replace migracion_escala_dpto = 1 if migracion_escala==5
	replace migracion_escala_dpto = 0 if migracion_escala_dpto!=1 & migracion_escala!=.	
	
	gen		analfab_2017 = .
	replace analfab_2017 = 1 if edad_2017>=15 & lee_escribe_2017==0
	replace analfab_2017 = 0 if edad_2017<15 | (edad_2017>=15 & lee_escribe_2017==1)	
	
	gen		nivel_educ2_2017 = .
	replace nivel_educ2_2017 = 1	if nivel_educ_2017==1	// Sin educacion
	replace nivel_educ2_2017 = 2	if nivel_educ_2017==2	// Inicial
	replace nivel_educ2_2017 = 3	if nivel_educ_2017==3 & c5_p13_gra<6	// Primaria incompleta
	replace nivel_educ2_2017 = 4	if nivel_educ_2017==3 & c5_p13_gra==6	// Primaria completa
	replace nivel_educ2_2017 = 5	if nivel_educ_2017==4 & c5_p13_anio_sec<5	// Secundaria incompleta
	replace nivel_educ2_2017 = 6	if nivel_educ_2017==4 & (c5_p13_anio_sec==5 |c5_p13_anio_sec==6) // Secundaria completa
	replace nivel_educ2_2017 = 7	if nivel_educ_2017==5	// Sup. no universitaria incompleta
	replace nivel_educ2_2017 = 8	if nivel_educ_2017==6	// Sup. no universitaria completa
	replace nivel_educ2_2017 = 9 	if nivel_educ_2017==7 	// Sup. universitaria incompleta
	replace nivel_educ2_2017 = 10 	if nivel_educ_2017==8	// Sup. universitaria completa
	replace nivel_educ2_2017 = 11 	if nivel_educ_2017==9	// Post-grado
		
save "$input_dir\2 Working\cpv2017ind.dta",  replace
		
	merge m:1 ubigeo_ccpp using "$input_dir\3 Coded\community_index_treated_sisfohccpp.dta", force
		
save "$input_dir\3 Coded\community_index_treated_cpv2017ind.dta",  replace

*-----------------------*
*		HH-level		*
*-----------------------*
use "$input_dir\2 Working\cpv2017ind.dta", clear
	gen num_perso=1
	
	gen		tiene_seguro_2017 = 0
	replace tiene_seguro_2017 = 1 if num_seg_ind_17>0 & num_seg_ind_17!=.
	
	*	Education Level of the HH head
	gen		educ_jefe_hogar_17 = .
	replace educ_jefe_hogar_17 = nivel_educ2_2017 if jefe_hogar_2017==1	

		collapse 	(max) pared* techo* piso* agua* desague* alumbrado* combust* activo* num_pershogar_2017 num_persvivienda_2017 num_habitaciones_2017 educ_jefe_hogar_17 ///
					(sum) seg_* trabaja* num_perso tiene_seguro_2017 ocupado_2017 ocupacion_* edad_6_12_noescuela_17 analfab_2017 migracion desgaste ///
					(mean) edad_2017 ratio_sexo_2017=sex_2017 nivel_educ_2017 nivel_educ2_2017 (firstnm) ubigeo_ccpp id_viv_imp_f, by(id_hog_imp_f)
	
	gen	prop_migracion=migracion/num_pershogar_2017
	
	
	
	egen num_seguro_2017 = rowtotal(seg_sis_2017 seg_essalud_2017 seg_ffaa_2017 seg_privado_2017 seg_otro_2017)
	
	gen seguro_1_2017 = 0
	replace seguro_1_2017 = 1  if tiene_seguro_2017>0 & tiene_seguro_2017!=.
		
	gen 	ratio_seguro_2017 = 0
	replace ratio_seguro_2017 = tiene_seguro_2017 / num_pershogar_2017
		
	gen		ratio_dependencia_2017 = 0
	replace ratio_dependencia_2017 = ocupado_2017 / num_pershogar_2017
	
	gen		noescuela_1_2017 = 0
	replace noescuela_1_2017 = 1 if edad_6_12_noescuela_17 >0 & edad_6_12_noescuela_17!=.
	
	foreach seguro in seg_sis_2017 seg_essalud_2017 seg_ffaa_2017 seg_privado_2017 seg_otro_2017 seg_ninguno_2017 {
	*	At least 1 household member is affiliated to each type of insurance program
	gen		`seguro'_1 = 0
	replace	`seguro'_1 = 1 if `seguro'>0 & `seguro'!=.
	}	
	
	foreach x in trabaja_agro_2017 trabaja_mineria_2017 trabaja_manuf_2017 trabaja_serv_2017 trabaja_constr_2017 trabaja_comercio_2017 trabaja_transp_2017 trabaja_turismo_2017 trabaja_info_2017 trabaja_fin_2017 trabaja_inmob_2017 trabaja_actprof_2017 trabaja_gob_2017 trabaja_educ_2017 trabaja_salud_2017 trabaja_otro_2017 trabaja_otro2_2017{
	*	At least 1 household member works in each type of economic activity
	gen		`x'_1 = 0
	replace `x'_1 = 1 if `x'>0 & `x'!=.
	*	Number of HH members working in each activity over total HH members
	gen		ratio_`x' = 0
	replace ratio_`x' = `x'/num_pershogar_2017
	}
	
	foreach ocupacion in ocupacion_dep ocupacion_indep ocupacion_desemp ocupacion_hogar ocupacion_mype {
	*	At least 1 household member is occupied in each category
	gen		`ocupacion'_1 = 0
	replace `ocupacion'_1 = 1 if `ocupacion'_2017>0 & `ocupacion'_2017!=.
	*	Number of HH members occupied in each category over total HH members	
	gen 	ratio_`ocupacion'_2017 = 0
	replace ratio_`ocupacion'_2017 = `ocupacion'_2017/num_pershogar_2017
	}	
	
*	At least 1 HH member has a job
	gen		ocupado_1_2017 = 0
	replace ocupado_1_2017 = 1 if ocupado_2017>0 & ocupado_2017!=.	
	
*	At least 1 HH member is illiterate
	gen		analfab_1_2017 = 0
	replace analfab_1_2017 = 1 if analfab_2017>0 & analfab_2017!=.	
	
	
	
	
*-----------------------------------------------------------*
*		4.1.2. INEI's Necesidades Basicas Insatisfechas		*
*-----------------------------------------------------------*
*http://proyectos.inei.gob.pe/web/biblioineipub/bancopub/Est/Lib0068/POB00006.htm

*	Inadecuate house characteristics
gen		nbi1_hogarinadecuado_17 = .

replace nbi1_hogarinadecuado_17 = 1 if pared_estera_2017==1 | (piso_tierra_2017==1 & ///
		(pared_quincha_2017==1 | pared_barro_2017==1 | pared_madera_2017==1 ))
replace nbi1_hogarinadecuado_17 = 0 if nbi1_hogarinadecuado_17!=1
		
*	Overcrowded house
gen		ratio_hacinamiento_17 = num_persvivienda_2017/num_habitaciones_2017
gen		nbi2_hacinamiento_17 = .

replace nbi2_hacinamiento_17 = 1 if ratio_hacinamiento_17>3 & ratio_hacinamiento_17!=.
replace nbi2_hacinamiento_17 = 0 if ratio_hacinamiento_17<=3 & ratio_hacinamiento_17!=.

*	No sewerage
gen		nbi3_sindesague_17 = .

replace nbi3_sindesague_17 = 1 if desague_letrina_2017==1 | desague_rio_2017==1 | desague_ninguno_2017==1
replace nbi3_sindesague_17 = 0 if desague_redpubdentro_2017==1 | desague_redpubfuera_2017==1 | desague_pozo_2017==1

*	Kids out of school
gen		nbi4_noescuela_17 = .
replace nbi4_noescuela_17 = 1 if noescuela_1_2017==1
replace nbi4_noescuela_17 = 0 if noescuela_1_2017==0

*	High economic dependence
gen		nbi5_altadependencia_17 = .
replace nbi5_altadependencia_17 = 1 if ocupado_2017==0 & (educ_jefe_hogar_17<=3)
replace nbi5_altadependencia_17 = 1 if educ_jefe_hogar_17<=3
replace nbi5_altadependencia_17 = 1 if ratio_dependencia_2017<1/3
replace nbi5_altadependencia_17 = 0 if ratio_dependencia_2017>=1/3 & ratio_dependencia_2017!=.
replace nbi5_altadependencia_17 = 0 if (educ_jefe_hogar_17>3 & educ_jefe_hogar_17!=.)

*	Sum of Necesidades Basicas Insatisfechas
egen	nbi_sum_2017=rowtotal(nbi1_hogarinadecuado_17 nbi2_hacinamiento_17 nbi3_sindesague_17 nbi4_noescuela_17 nbi5_altadependencia_17)
replace nbi_sum_2017 = . if nbi1_hogarinadecuado_17==. & nbi2_hacinamiento_17==. & nbi3_sindesague_17==. & nbi4_noescuela_17==. & nbi5_altadependencia_17==.

save "$input_dir\2 Working\cpv2017hog.dta",  replace
	
	merge m:1 ubigeo_ccpp using "$input_dir\3 Coded\community_index_treated_sisfohccpp.dta", force
		
save "$input_dir\3 Coded\community_index_treated_cpv2017hog.dta",  replace
	

*-----------------------*
*		CCPP-level		*	
*-----------------------*
	
use "$input_dir\2 Working\cpv2017hog.dta", clear
	egen missings=rowmiss(*)
	drop if missings>80
	
	collapse (sum) pared* piso* techo* agua* desague* alumbrado* (firstnm) ubigeo_ccpp ,by(id_viv_imp_f)
	gen num_viv_cpv17 = 1
	collapse (sum) pared* piso* techo* agua* desague* alumbrado* num_viv_cpv17, by(ubigeo_ccpp)
		
*-------------------------------------------------------*
*		1.3.	Create outcome variables and ratios		*
*-------------------------------------------------------*

*---------------------------------------------------*
*		1.3.1.	Characteristics of the house		*
*---------------------------------------------------*

	gen		prop_pared_ladrillo17	= pared_ladrillo_2017/num_viv_cpv17
	gen		prop_pared_piedra17		= pared_piedra_2017/num_viv_cpv17
	gen		prop_pared_adobe17		= pared_adobe_2017/num_viv_cpv17
	gen		prop_pared_quincha17	= pared_quincha_2017/num_viv_cpv17
	gen		prop_pared_barro17		= pared_barro_2017/num_viv_cpv17
	gen		prop_pared_madera17		= pared_madera_2017/num_viv_cpv17
	gen		prop_pared_estera17		= pared_estera_2017/num_viv_cpv17

	gen		prop_techo_concreto17 	= techo_concreto_2017/num_viv_cpv17
	gen		prop_techo_madera17		= techo_madera_2017/num_viv_cpv17
	gen		prop_techo_teja17		= techo_teja_2017/num_viv_cpv17
	gen		prop_techo_calamina17	= techo_calamina_2017/num_viv_cpv17
	gen		prop_techo_estera17		= techo_estera_2017/num_viv_cpv17
	gen		prop_techo_paja17		= techo_paja_2017/num_viv_cpv17

	gen		prop_piso_parquet17	= piso_parquet_2017/num_viv_cpv17
	gen		prop_piso_lamina17	= piso_lamina_2017/num_viv_cpv17
	gen		prop_piso_loseta17	= piso_loseta_2017/num_viv_cpv17
	gen		prop_piso_tabla17	= piso_tabla_2017/num_viv_cpv17
	gen		prop_piso_cemento17	= piso_cemento_2017/num_viv_cpv17
	gen		prop_piso_tierra17	= piso_tierra_2017/num_viv_cpv17
	
*-------------------------------------------*
*		1.3.2.	Services in the house		*
*-------------------------------------------*
	
	gen		prop_alumbrado_elect17	= alumbrado_2017/num_viv_cpv17
	
	gen		prop_agua_redpubdentro17	= agua_redpubdentro_2017/num_viv_cpv17
	gen		prop_agua_redpubfuera17		= agua_redpubfuera_2017/num_viv_cpv17
	gen		prop_agua_redpub17			= agua_redpub_2017/num_viv_cpv17
	gen		prop_agua_pilon17			= agua_pilon_2017/num_viv_cpv17
	gen		prop_agua_cisterna17		= agua_cisterna_2017/num_viv_cpv17
	gen		prop_agua_pozo17			= agua_pozo_2017/num_viv_cpv17
	gen		prop_agua_rio17				= agua_rio_2017/num_viv_cpv17

	gen		prop_desague_redpubdentro17	= desague_redpubdentro_2017/num_viv_cpv17
	gen		prop_desague_redpubfuera17	= desague_redpubfuera_2017/num_viv_cpv17
	gen		prop_desague_redpub17		= desague_redpub_2017/num_viv_cpv17
	gen		prop_desague_pozo17			= desague_pozo_2017/num_viv_cpv17
	gen 	prop_desague_letrina17		= desague_letrina_2017/num_viv_cpv17
	gen		prop_desague_rio17			= desague_rio_2017/num_viv_cpv17
	gen		prop_desague_ninguno17		= desague_ninguno_2017/num_viv_cpv17
	
save "$input_dir\2 Working\cpv2017ccpp_aux1.dta",  replace
	
use "$input_dir\2 Working\cpv2017hog.dta", clear
	egen missings=rowmiss(*)
	drop if missings>80
	
	collapse (sum) combust* activo* (firstnm) ubigeo_ccpp ,by(id_hog_imp_f)
	gen num_hog_cpv17 = 1
	collapse (sum) combust* activo* num_hog_cpv17, by(ubigeo_ccpp)	
	
	
	gen		prop_combust_elect17	= combust_elect_2017/num_hog_cpv17
	gen		prop_combust_gas17		= combust_gas_2017/num_hog_cpv17
	gen		prop_combust_carbon17	= combust_carbon_2017/num_hog_cpv17
	gen		prop_combust_lea17		= combust_lea_2017/num_hog_cpv17
	gen		prop_combust_bosta17	= combust_bosta_2017/num_hog_cpv17
	
*---------------------------*
*		1.3.3.	Assets		*
*---------------------------*

	gen		prop_asset_equipsonido17	= activo_equiposonido_2017/num_hog_cpv17
	gen		prop_asset_tvcolor17		= activo_tvcolor_2017/num_hog_cpv17
	gen		prop_asset_licuadora17		= activo_licuadora_2017/num_hog_cpv17
	gen		prop_asset_refri17			= activo_refri_2017/num_hog_cpv17
	gen		prop_asset_cocinagas17		= activo_cocina_2017/num_hog_cpv17
	gen		prop_asset_telefonofijo17	= activo_fijo_2017/num_hog_cpv17
	gen		prop_asset_plancha17		= activo_plancha_2017/num_hog_cpv17
	gen		prop_asset_lavadora17		= activo_lavadora_2017/num_hog_cpv17
	gen		prop_asset_compu17			= activo_compu_2017/num_hog_cpv17
	gen		prop_asset_microondas17		= activo_microondas_2017/num_hog_cpv17
	gen		prop_asset_internet17		= activo_internet_2017/num_hog_cpv17
	gen		prop_asset_cable17			= activo_cable_2017/num_hog_cpv17
	gen		prop_asset_celular17		= activo_celular_2017/num_hog_cpv17
	gen		prop_asset_transporte17		= activo_transporte_2017/num_hog_cpv17
	
save "$input_dir\2 Working\cpv2017ccpp_aux2.dta",  replace
	
use "$input_dir\2 Working\cpv2017ind.dta", clear
	
	drop if migracion==1
	gen num_ind_cpv17 = 1
	collapse (sum) edad* trabaja* seg_* lee_escribe_2017 nivel_educ_ninguno_17 	///
		nivel_educ_inicial_17 nivel_educ_primaria_17 nivel_educ_secundaria_17 	///
		nivel_educ_tecnica_17 nivel_educ_universitaria_17 sex_2017 ocu* 		///
		num_ind_cpv17 nivel_educ_postgrado_17 migracion desgaste, by(ubigeo_ccpp)
	
	
*---------------------------------------*
*		1.3.4.	Age distribution		*
*---------------------------------------*	
		
	gen		prop_edad_u1_17			= edad_u1_2017/num_ind_cpv17
	gen		prop_edad_1_14_17		= edad_1_14_2017/num_ind_cpv17
	gen		prop_edad_15_29_17		= edad_15_29_2017/num_ind_cpv17
	gen		prop_edad_30_44_17		= edad_30_44_2017/num_ind_cpv17
	gen		prop_edad_45_64_17		= edad_45_64_2017/num_ind_cpv17
	gen		prop_edad_65_17			= edad_65_2017/num_ind_cpv17
	gen		prop_edad_15_17			= edad_15mas_2017/num_ind_cpv17	
	
	
	gen		prop_edad_0_5_17 	= edad_0_5_2017/num_ind_cpv17
	gen		prop_edad_5_10_17 	= edad_5_10_2017/num_ind_cpv17
	gen		prop_edad_10_15_17 	= edad_10_15_2017/num_ind_cpv17
	gen		prop_edad_15_20_17 	= edad_15_20_2017/num_ind_cpv17
	gen		prop_edad_20_25_17 	= edad_20_25_2017/num_ind_cpv17
	gen		prop_edad_25_30_17 	= edad_25_30_2017/num_ind_cpv17
	gen		prop_edad_30_35_17 	= edad_30_35_2017/num_ind_cpv17
	gen		prop_edad_35_40_17 	= edad_35_40_2017/num_ind_cpv17
	gen		prop_edad_40_45_17 	= edad_40_45_2017/num_ind_cpv17
	gen		prop_edad_45_50_17 	= edad_45_50_2017/num_ind_cpv17
	gen		prop_edad_50_55_17 	= edad_50_55_2017/num_ind_cpv17
	gen		prop_edad_55_60_17 	= edad_55_60_2017/num_ind_cpv17
	gen		prop_edad_60_65_17 	= edad_60_65_2017/num_ind_cpv17
	gen		prop_edad_65_70_17 	= edad_65_70_2017/num_ind_cpv17
	gen		prop_edad_70_mas_17 = edad_70_mas_2017/num_ind_cpv17
	gen		prop_edad_20_30_17 	= edad_20_30_2017/num_ind_cpv17

*-----------------------------------------------*
*		1.3.5.	Affilitation to insurance		*
*-----------------------------------------------*						 
						 
	gen		prop_seguro_essalud17		= seg_essalud_2017/num_ind_cpv17
	gen		prop_seguro_ffaapnp17		= seg_ffaa_2017/num_ind_cpv17
	gen		prop_seguro_privado17		= seg_privado_2017/num_ind_cpv17
	gen		prop_seguro_sis17			= seg_sis_2017/num_ind_cpv17
	gen		prop_seguro_ninguno17		= seg_ninguno_2017/num_ind_cpv17
	
*-------------------------------*
*		1.3.6.	Education		*
*-------------------------------*

	gen		prop_lee_si_17				= lee_escribe_2017/num_ind_cpv17

	gen		prop_educ_ninguno17			= nivel_educ_ninguno_17/num_ind_cpv17
	gen		prop_educ_inicial17			= nivel_educ_inicial_17/num_ind_cpv17
	gen		prop_educ_primaria17		= nivel_educ_primaria_17/num_ind_cpv17
	gen		prop_educ_secundaria17		= nivel_educ_secundaria_17/num_ind_cpv17
	gen		prop_educ_tecnica17			= nivel_educ_tecnica_17/num_ind_cpv17
	gen		prop_educ_universitaria17	= nivel_educ_universitaria_17/num_ind_cpv17
	gen		prop_educ_postgrado17		= nivel_educ_postgrado_17/num_ind_cpv17
	
*-------------------------------------------------------*
*		1.3.7.	Economic Activity and employment		*
*-------------------------------------------------------*

	gen		prop_actividad_agricola17		= trabaja_agro_2017/num_ind_cpv17
	gen		prop_actividad_pecuaria17		= trabaja_agro_2017/num_ind_cpv17
	gen		prop_actividad_agropec17		= trabaja_agro_2017/num_ind_cpv17
	gen		prop_actividad_minera17			= trabaja_mineria_2017/num_ind_cpv17
	gen		prop_actividad_comercial17		= trabaja_comercio_2017/num_ind_cpv17
	gen		prop_actividad_servicios17		= trabaja_serv_2017/num_ind_cpv17
	gen		prop_actividad_estatal17		= trabaja_gob_2017/num_ind_cpv17	
	gen		prop_actividad_manuf17			= trabaja_manuf_2017/num_ind_cpv17	
	gen		prop_actividad_contr17			= trabaja_constr_2017/num_ind_cpv17
	gen		prop_actividad_turismo17		= trabaja_turismo_2017/num_ind_cpv17
	
	
	gen		prop_ocupado_2017					= ocupado_2017/num_ind_cpv17
	gen 	prop_ocupado_dep_17					= ocupacion_dep_2017/num_ind_cpv17
	gen 	prop_ocupado_indep_17				= ocupacion_indep_2017/num_ind_cpv17
	gen 	prop_ocupado_desemp_17				= ocupacion_desemp_2017/num_ind_cpv17
	gen 	prop_ocupado_hogar_17				= ocupacion_hogar_2017/num_ind_cpv17
	gen 	prop_ocupado_mype_17				= ocupacion_mype_2017/num_ind_cpv17
	
	gen		prop_mujeres_2017 = sex_2017/num_ind_cpv17
	
	
save "$input_dir\2 Working\cpv2017ccpp_aux3.dta",  replace
	
use "$input_dir\2 Working\cpv2017ccpp_aux1.dta", clear
merge 1:1 ubigeo_ccpp using "$input_dir\2 Working\cpv2017ccpp_aux2.dta", nogen
merge 1:1 ubigeo_ccpp using "$input_dir\2 Working\cpv2017ccpp_aux3.dta", nogen
	
	
*-----------------------------------------------------------*
*		1.4.1.	Generate Poverty measure at CCPP level		*
*-----------------------------------------------------------*

*---------------------------*
*		Wall material		*
*---------------------------*	

	gen		poverty2017_pared = 0
	replace poverty2017_pared = (prop_pared_ladrillo17*7 + prop_pared_piedra17*6 + ///
								prop_pared_adobe17*5 + prop_pared_quincha17*4 + ///
								prop_pared_barro17*3 + prop_pared_madera17*2 + ///
								prop_pared_estera17*1)/7
	
	gen		poverty2017_piso = 0
	replace poverty2017_piso = (prop_piso_parquet17*6 + prop_piso_lamina17*5 + ///
								prop_piso_loseta17*4 + prop_piso_tabla17*3 + ///
								prop_piso_cemento17*2 + prop_piso_tierra17*1)/6
	
	gen		poverty2017_agua = 0
	replace poverty2017_agua = (prop_agua_redpubdentro17*6 + prop_agua_redpubfuera17*5 + ///
								prop_agua_pilon17*4 + prop_agua_cisterna17*3 + ///
								prop_agua_pozo17*2 + prop_agua_rio17*1)/6
								
	gen		poverty2017_saneamiento = 0
	replace poverty2017_saneamiento = (prop_desague_redpubdentro17*6 + ///
								prop_desague_redpubfuera17*5 + ///
								prop_desague_pozo17*4 + prop_desague_letrina17*3 + ///
								prop_desague_rio17*2 + prop_desague_ninguno17*1)/6
	

	gen		poverty2017_bienesriqueza = 0
	replace poverty2017_bienesriqueza = (prop_asset_lavadora17 + prop_asset_refri17 + ///
								prop_asset_compu17 + prop_asset_internet17 + prop_asset_cable17)/5
	
	gen		poverty2017_combust = 0
	replace poverty2017_combust = (prop_combust_elect17*5 + prop_combust_gas17*4 + ///
								prop_combust_carbon17*3 + ///
								prop_combust_lea17*2 + prop_combust_bosta17*1)/5
	
	gen		poverty2017_seguro = 0
	replace poverty2017_seguro = 1 - prop_seguro_ninguno17
	
	gen		poverty2017_analfabeta = 0
	replace poverty2017_analfabeta = prop_lee_si_17
	replace poverty2017_analfabeta = 1 if prop_lee_si_17>1 & prop_lee_si_17!=.
	
	gen		poverty2017_educ = 0
	replace poverty2017_educ = (prop_educ_postgrado17*8 + prop_educ_universitaria17*7 + ///
								prop_educ_tecnica17*6 + ///
								prop_educ_secundaria17*4 + prop_educ_primaria17*3 + ///
								prop_educ_inicial17*2 + prop_educ_ninguno17*1)/8
	
	gen		poverty2017_desempleo = 0
	replace poverty2017_desempleo = prop_ocupado_2017
	
	gen		poverty2017_alumbrado = 0
	replace poverty2017_alumbrado = prop_alumbrado_elect17
	
	egen	poverty2017_caracthh = rowmean(poverty2017_pared poverty2017_piso poverty2017_combust poverty2017_bienesriqueza)
	egen	poverty2017_servpub = rowmean(poverty2017_agua poverty2017_saneamiento poverty2017_alumbrado)
	egen	poverty2017_demogra = rowmean(poverty2017_seguro poverty2017_analfabeta poverty2017_educ poverty2017_desempleo)

	egen		poverty2017 = rowmean(poverty2017_caracthh poverty2017_servpub poverty2017_demogra)
		
	merge 1:1 ubigeo_ccpp using "$input_dir\3 Coded\community_index_treated_sisfohccpp.dta", ///
		force
		
		
	gen		prop_migracion_1317 = migracion/pob_ccpp_2013
	gen		prop_desgaste_1317 = desgaste/pob_ccpp_2013
	
	label define sexo_ 0 "hombre" 1 "mujer"
	label values sex_2017 sexo_
	
save "$input_dir\3 Coded\community_index_treated_cpv2017ccpp.dta", ///
	replace

/*
	
global	controls altitude_msnm log_distancia_capital ///
		log_pob_ccpp_2007 poverty2007_caracthh poverty2007_servpub 				///
		poverty2007_demogra ie_estatal_1_2010	
	
		rdrobust nbi1_hogarinadecuado_17 index_cutBC if (Nivel=="B" | Nivel=="C") & ///
		(dpto=="HUANCAVELICA" | dpto=="APURIMAC" | prov=="LA CONVENCION" | 		///
		prov=="HUANCAYO"), fuzzy(treat_17) vce(cluster cluster_dist) 			///
		bwselect(msecomb2) kernel(triangular) covs($controls) p(1)
	
	/// Incluir tabla de balance tratados y no tratados 
	/// drop a tratados en inversion productiva o tratados en inversion en infraestructura
	collapse prop_mujeres_2017=sex_2017 prop_menor_2017=menor_edad_2017  		///
			prop_menor_15_2015=menor_15_2017 prop_ocupado_dep_2017=ocupado_dep
	*/
