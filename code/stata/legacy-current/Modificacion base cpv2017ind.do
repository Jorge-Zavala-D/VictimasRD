*Modificación base2017

clear all
set more off
cd "C:\Users\anadu\OneDrive - Universidad de los Andes\Universidad\PEG\TESIS\Datos\Bases"

use community_index_treated_cpv2017ind, clear

br llave sexo01 sex_2017

* corregimos el error en la etiqueta de sexo para 2017 considerando que cuando hay una dummie de sexo el menor valor dado a la dummie se le da al hombre y el mayor a la mujer. Así para 2013 sexo01= 1 si es hombre sexo=2 si es mujer y para 2017 sex_2017=0 si es hombre sex_2017=1 si es mujer.

*cambio la etiqueta para que el valor de sexo en 2017 coincida con el de 2013:
 
label define sexo_ 0 "hombre" 1 "mujer"
label values sex_2017 sexo_
br llave sexo01 sex_2017

*guardo la base modificada:
save community_index_treated_cpv2017ind_mod.dta