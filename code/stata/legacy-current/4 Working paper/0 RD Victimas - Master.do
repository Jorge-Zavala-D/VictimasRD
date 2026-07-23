/*------------------------------------------------------------------------------*
| Title: 			Master code													|
| Project: 			Victimas RD								  					|
| Authors:			Jorge Zavala 												|
| 					  									                        |
|																				|
| Description:		This .do imports, cleans and prepares data for analysis 	|
|                                                                               |
| Date created: 16/09/2023			 					                        |										          
|																			    |
| Version: Stata 16.                        							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

*-------------------------------------------------------------------------------*/

*-----------------------------------*
**#		0. Setup and directory		*
*-----------------------------------*
	clear all
	clear mata
	set more off
	version 16

*-----------------------------------*
**#		1. Define paths				*
*-----------------------------------*

* check what your username is in Stata by typing "di c(username)"
if "`c(username)'" == "jzava"  {
	global root "C:\Users\jzava\Dropbox\VictimasRD"
	}


* globals
global input_dir    	"$root/2 data"
global code_dir    		"$root/1 code\1 stata\4 Working paper"
global output_dir    	"$root/3 output/0 Working Paper"


* ssc install reclink, replace
* ssc install rdrobust, replace

	sysdir set PLUS "${code_dir}/ado"


* Install packages 
	local user_commands	lpdensity rddensity rdrobust colrspace palettes reclink winsor sumstats estout keeporder grc1leg2 outreg2 //Add required user-written commands

	foreach command of local user_commands {
	   capture which `command'
	   if _rc == 111 {
		   ssc install `command'
	   }
	}
	* Install plotplain scheme for graphs formatting
	net install gr0070, from(http://www.stata-journal.com/software/sj17-3)	

*---------------------------*
**#		2. Run do files		*
*---------------------------*

	* Switch to 0/1 to not-run/run do-files 
	if (0) do "${code_dir}/1 RD Victimas - Data Preparation.do"
	if (0) do "${code_dir}/2 RD Victimas - Descriptive.do"
	if (0) do "${code_dir}/3 RD Victimas - RD tests.do"
	if (0) do "${code_dir}/4 RD Victimas - RD estimations - Sisfoh 2013 - CCPP level.do"




