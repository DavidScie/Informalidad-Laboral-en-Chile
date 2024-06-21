/*********************************************************************
				      Estudio de Informalidad Laboral 
*estudio realizado en IdeaPaís
                      David Limpe cruz
                          Mayo, 2024.
*******************************************************************************/
*1. BASE DE DATOS --> CASEN 2022
clear all
cd "C:\Users\Home\Documents\@Idea_Pais_2024\ESTUDIOS IP\Informalidad laboral"
*use BD_consolidado.dta
use BD_CASEN22.dta

*******************************************************
*		I. Generación de variable:  *Informalidad
*******************************************************
*en línea con propuesta del INE
*Cotiza salud
g prev_salud=s13
replace prev_salud=9 if s13==-88
g health=.
replace health=1 if prev_salud<=3 | prev_salud==5
replace health=2 if prev_salud==4
replace health=3 if prev_salud==9
label var health "Tiene previsión de salud"
label defin health 1"Si" 2"No" 3"No sabe"
label val health health
*Cotiza AFP
replace o14=9 if o14==-88
replace o31=9 if o31==-88
replace o32=9 if o32==-88
g afp=.
replace afp=1 if o31==2 & edad >=15
replace afp=1 if o32==6 & edad >=15
replace afp=2 if o31==1 & o32<6 & edad >=15
replace afp=3 if o31==9 | o32==9 & edad >=15
replace afp=2 if (o31==2 | o32==6) & (o14<3) & ((sexo==1 & edad>=15 & edad<55) | (sexo==2 & edad>=15 & edad<50)) //identifica cotizantes según Ley Trabajador Honorarios
label define afp 2"Cotiza" 1"No afiliado o no cotiza" 3"Sin dato"
label val afp afp
tab afp
*Categoría ocupacional
gen cat_ocup =.
replace cat_ocup=1 if o15==1
replace cat_ocup=2 if o15==2
replace cat_ocup=3 if inrange(o15,3,5)
replace cat_ocup=4 if inrange(o15,6,7)
replace cat_ocup=5 if o15==9
replace cat_ocup=6 if o15==8
label var cat_ocup "Categoría Ocupacional"
label define cat_ocup 1 "Empleador" 2 "Cuenta Propia" 3 "Asalariado" 4 "Servicio Domestico" 5 "Familiar No Remunerado" 6 "FF.AA"
label value cat_ocup cat_ocup

*Oficio CIUO 08
replace oficio1_08 = 99 if oficio1_08 == 99
replace oficio1_08 = 99 if oficio1_08 == -99
replace oficio1_08 = 99 if oficio1_08 == -88
*label drop oficio1_08  //no corre
replace oficio1_08 = 10 if oficio1_08 == -66
label variable oficio1_08 "Ocupación y oficio"
label define oficio1_08 0 "Ocupaciones de las Fuerzas Armadas" ///
1 "Directores, gerentes y administradores" ///
2 "Profesionales, científicos e intelectuales" ///
3 "Técnicos y profesionales de nivel medio" ///
4 "Personal de apoyo administrativo" ///
5 "Trabajadores de los servicios y vendedores" ///
6 "Agricultores y trabajadores calificados" ///
7 "Artesanos y operarios de oficios" ///
8 "Operadores de instalaciones, máquinas" ///
9 "Ocupaciones elementales" ///
10 "Ocupacion no bien especificada" ///
99 "Sin dato", modify
label values oficio1_08 oficio1_08
codebook cat_ocup
*Ocupación informal
gen ocup_inf=.
replace ocup_inf=2 if (cat_ocup==3 | cat_ocup==4 | cat_ocup==6 ) & (afp==1 | health==2)
replace ocup_inf=2 if cat_ocup==5
replace ocup_inf=2 if cat_ocup==2 & (oficio1_08>=4) & oficio1_08 != .
replace ocup_inf = . if cat_ocup == 2 & oficio1_08 == 0
replace ocup_inf=1 if (cat_ocup==3 | cat_ocup==4 | cat_ocup==6 ) & (afp==2 & health==1)
replace ocup_inf=1 if cat_ocup==2 & inlist(oficio1_08,1,2,3)
replace ocup_inf = . if oficio1_08 == 10 & cat_ocup == 2
label var ocup_inf "Ocupación Informal"
label defin ocup_inf 2 "Si" 1 "No"
label val ocup_inf ocup_inf

codebook ocup_inf
tab ocup_inf
***********************************************************
*		II. Limpieza y transformación de datos
***********************************************************
*variable informalidad
gen inf=.
replace inf=1 if ocup_inf==2 //informal  
replace inf=0 if ocup_inf==1
codebook inf
*drop if inf==.
*variable escolaridad 
*codebook esc
sum esc
****************drop if esc==.
*variable sexo
codebook sexo
drop if sexo==.
gen gender=0
replace gender=1 if sexo==2 //mujer=1
rename gender mujer
tab mujer
*variable edad
gen edad2=edad*edad
sum edad

*variable  ingreso total
codebook ytotcor
*Var quintil de ingreso
codebook qaut
tab qaut ocup_inf [iw=expr], row
tab qaut ocup_inf if sexo==2 [iw=expr], row
tab qaut ocup_inf if sexo==1 [iw=expr], row
tab qaut

*******************************************************
*		III. Generación de la estrucutura familiar
*********************************************************
*1. Estructura de hogar desagregada (nucleares y extendidos)
svyset varunit [pw=expr], strata(varstrat) singleunit(certainty)
gen aux1=.
replace aux1=1 if pco2==1 & nucleo!=0
bys folio: egen nnucleos=count(aux1)
label var nnucleos "N° de nucleos por hogar"
gen auxi=inlist(pco1,2,3)
bys folio: egen conyuge=max(auxi)
label var conyuge "Hogar con conyuge"
gen thogar=.
replace thogar=1 if numper==1
replace thogar=2 if numper>1 & conyuge==0 & nnucleos==1
replace thogar=3 if numper>1 & conyuge==1 & nnucleos==1
replace thogar=4 if numper>1 & conyuge==0 & nnucleos>1
replace thogar=5 if numper>1 & conyuge==1 & nnucleos>1
replace thogar=6 if numper!=1 & numper==nnucleo
label var thogar "Tipo de hogar"
label define thogar 1 "Unipersonal" 2 "Nuclear Monoparental" ///
3 "Nuclear Biparental" 4 "Extenso Monoporental" 5 "Extenso Biparental" ///
6 "Sin nucleo"
label val thogar thogar
tab thogar
*2. Estructura hogar agrupada (Monopar, Bipar, Unipersonal)
codebook thogar
gen thog=.
replace thog=1 if (thogar==3| thogar==5) & pco1==1
replace thog=2 if (thogar==2| thogar==4) & pco1==1
replace thog=3 if thogar==1
replace thog=4 if thogar==6 
label define thog 1 "biparental" 2 "monoparental" 3 "unipersonal" 4 "Sin nucleo"
label val thog thog
tab thog
*3. variable log natural de ingreso para medir cambio porcentual
gen lingreso =ln(yautcorh)
gen lingresop = ln(ytotcor)
*4. variable estado civil agrupada
gen eciv=.
replace eciv=1 if ecivil==1 & pco1==1
replace eciv=2 if (ecivil== 2 | ecivil==3) & pco1==1
replace eciv=3 if (ecivil ==5| ecivil==6 | ecivil==8) & pco1==1
label define eciv 1 "casado" 2 "conviviente" 3 "Soltero, Divorciado, Separado"
label val eciv eciv
*5. Dummy monoparental (binaria)
gen monopar=.
replace monopar =0 if thog==1 & pco1==1
replace monopar =1 if thog==2 & pco1==1
tab monopar
codebook monopar
*6. Monoparental categórica según sexo del jefe de hogar
gen estructura_sexo=.
replace estructura_sexo =0 if thog==1 & pco1==1
replace estructura_sexo =1 if thog==2 & pco1==1 & sexo==1
replace estructura_sexo =2 if thog==2 & pco1==1 & sexo==2
label define estructura_sexo 0 "biparental" 1 "monoparental hombre" 2 "monoparental mujer"
label val estructura_sexo estructura_sexo
tab estructura_sexo
codebook estructura_sexo
**Monoparental Femenino
gen monoparmujer=0
replace monoparmujer=1 if estructura_sexo==2
tab monoparmujer
**Monoparental hombre
gen monoparhombre=0
replace monoparhombre=1 if estructura_sexo==1
tab monoparhombre
*7. Presencia de menores de niños menores de 5 años
gen menores_5=0
replace menores_5=1 if edad <=5
tab menores_5
* menores_5
bys folio: egen nmenores_5= sum(menores_5)
bys folio: gen hog_menores_5 =1 if nmenores_5 >=1
gen monopar_mujer_menor=0
************
tab nmenores_5
gen hmenor5=0
replace hmenor5=1 if (nmenores_5==1 | nmenores_5==2 | nmenores_5==3 | nmenores_5==4)
**********
tab hmenor5
gen mujhmenor5 = mujer*hmenor5
*dprobit inf gender hmenor5 mujhmenor5
tab menores_5
replace monopar_mujer_menor=1 if pco1==1 & estructura_sexo==2 & nmenores_5>=1

tab monopar_mujer_menor

*******************************************************************
*		IV.	Cálculo de variables de interés  para caracterización 
			*del estudio  
********************************************************************
*cruce de informalidad por quintil de ingreso y género 
tab qaut sexo if inf==1, row
// Generar las variables dummies para el nivel socioeconómico
tabulate qaut, generate(qaut_dummy)
********* informalidad y grupo etario ************
gen etario=.
replace etario=1 if edad >=25 & edad <25
replace etario=2 if edad >=25 & edad <35
replace etario=3 if edad >=35 & edad <45
replace etario=4 if edad >=45 & edad <55
replace etario=5 if edad >=55 & edad <65
replace etario=6 if edad >=65
label var etario "Grupo Etario"
label define etario 1 "15 a 24" ///
					2 "25 a 34" ///
					3 "35 a 44" ///
					4 "45 a 54"  ///
					5 "55 a 64"	 ///
					6 "65 y más"        
label values etario etario
codebook etario
tab etario
**************************************************
*2da forma 
gen etario=.
replace etario=1 if edad >=25 & edad <65
replace etario=2 if edad >=15 & edad <25
replace etario=3 if edad >=65
label var etario "Grupo Etario"
label define etario 1 "25 a 64" ///
					2 "15 a 24" ///
					3 "65 y más" 
label values etario etario
codebook etario
tab etario
// Generar las variables dummies para el grupo etario
tabulate etario, generate(etario_dummy)
bys ocup_inf: tab etario [iw=expr] 
tab etario ocup_inf [iw=expr], row

*Población extranjera
codebook r1a //chileno, extranjero, o ambos
g extranjero=.
replace extranjero=1 if r1a==3 //extranjero
replace extranjero=0 if (r1a==1 | r1a==2) // nacional
label var extranjero "extranjero"
label defin extranjero 1"Extranjero" 0"Nacional"
label val extranjero extranjero
tab extranjero
*analisis
bys ocup_inf: tab region extranjero
tab region inf, row
  **********************************************************************
  *** 			IV. Estadísticas Descriptivas **********************************************************************

global descriptivas inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer etario_dummy1 etario_dummy2 etario_dummy3 hmenor5 esc extranjero
tabstat $descriptivas, stat(mean sd p10 p25 median p75 p90) long col(stat) 
*ssc install asdoc
asdoc tabstat $descriptivas, stat(mean sd p10 p25 median p75 p90) long col(stat) replace

*0. Estadisticas descriptivas
sum inf lingreso mujer edad hmenor5 esc extranjero metropolitana

*********************************************************************
/***    V.  MODELO DE PROBALIDAD DE INFORMALIDAD LABORAL*///
*********************************************************************
global controles lingreso mujer etario_dummy2 etario_dummy3 hmenor5 mujhmenor5 esc extranjero

*1. MPL
*modelo MPL
reg inf $controles, r

*2 model NO lineal
*********************************************************************
*          5.1 Modelo Probit con grupo etario
*********************************************************************
*Modelo incorporando variable categórica de edad en modelo probit:
probit inf $controles, robust
*efectos marginales
dprobit inf $controles, robust
eststo efmargin
**Resumen de los resultados*
outreg2 [regresionbase1 efmargin1] using model_prob_inf.xls, nor2 dec(3)title(Regresiones base de informalidad) replace 
**************************************************
*2da forma
probit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer etario_dummy2 etario_dummy3 hmenor5 mujhmenor5 esc extranjero
eststo regresionbase1
dprobit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer etario_dummy2 etario_dummy3 hmenor5 mujhmenor5 esc extranjero
eststo efmargin1
**Resumen de los resultados*
outreg2 [regresionbase1 efmargin1] using model_prob1_inf.xls, nor2 dec(3)title(Regresiones base de informalidad) replace
***************************************************************
*		5.2 comparación efectos marginales del m. probit ****************************************************************
*EFMG1:
qui dprobit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4
eststo efmg1
*EFMG2:
qui dprobit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer 
eststo efmg2
*EFMG3:
qui dprobit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer etario_dummy2 etario_dummy3 
eststo efmg3
*EFMG4:
qui dprobit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer etario_dummy2 etario_dummy3 hmenor5 mujhmenor5 
eststo efmg4
*EFMG5:
qui dprobit inf qaut_dummy1 qaut_dummy2 qaut_dummy3 qaut_dummy4 mujer etario_dummy2 etario_dummy3 hmenor5 mujhmenor5 esc extranjero 
eststo efmg5

outreg2 [efmg1 efmg2 efmg3 efmg4 efmg5] using marginal_effect1_prob.xls, nor2 dec(3)title( Efectos marginales del modelo de Informalidad) replace
*******************************************************************
*             VI. Corrección de sesgo de selección
********************************************************************
*  Corrección por sesgo de selección
*probabilidad de estar trabajando: o1
*Z: variables explicativas de estar trabajando:
tab o1
codebook o1
drop if o1==.
gen work=.
replace work=1 if o1==1 //está trabajando
replace work=0 if o1==2
tab work
*desempleado --- look otra variable
tab o6
codebook o6
drop if o6==.
gen lookjob=.
replace lookjob=1 if o6==1 //busca trabajo
replace lookjob=0 if o6==2
tab lookjob

dprobit work lingreso mujer edad edad2 hmenor5 mujhmenor5 esc extranjero 

lingreso mujer edad edad2 hmenor5 mujhmenor5 esc extranjero 
*modelo probabilistico de correción por heckman
heckprob inf lingreso mujer edad edad2 hmenor5 mujhmenor5 esc extranjero, select(work=lingreso mujer edad edad2 hmenor5 mujhmenor5 esc extranjero)
mfx



