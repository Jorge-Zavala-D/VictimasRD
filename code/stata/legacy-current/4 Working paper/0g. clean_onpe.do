/*------------------------------------------------------------------------------*
| Title: 			  Cleaning and preparing dataset							|
| Project: 			  Victimas RD								   				|	  
| Authors:			  Jorge Zavala							                    |
| 					  									                        |
|																				|
|Description:		  This .do imports and cleans raw dataset from ONPE			|
|					  and define candidates for outcomes at community level		|
|                                                           	                |
|Date Created: 11/4/2019				 					                    |										          
|																			    |
| Version: Stata 13/14 	                    							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/

import excel "$input_dir\1 Raw\6 ONPE\BD_ONPE.xlsx", ///
	sheet("ONPE_2006_2016") ///
	cellrange(A2:AE185)///
	firstrow	


	gen a = "0"
	tostring ubigeo_dist, gen(ubigeo2)
	egen ubigeo_a = concat (a ubigeo2)

	replace ubigeo2 = ubigeo_a if ubigeo_dist<=100000
	drop a ubigeo_dist ubigeo_a
	rename ubigeo2 ubigeo_dist
	order ubigeo_dist, first


save "$input_dir\2 Working\onpe_2006_2016.dta", ///
	replace








