/*==============================================================================
Project:			World Bank Poverty & Gender Assessment
					Senegal, The Gambia, Muritania

Author:				Sergio Rivera
Email:				riverad.sergio@gmail.com
Email:				river@umd.edu
Creation Date:     	June/2024
Dependencies:		World Bank Poverty GP

About: Master Dofile

==============================================================================*/


*-------------------------------- Setting -------------------------------------
	
	clear all
	set more off
	
	dis "`c(username)'"
	
	if "`c(username)'" == "SERGIO" {
		global d_raw	"F:\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\1_Datasets"
		global do_files	"F:\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\2_Dofiles" 
		global dir_out	"F:\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\4_Outputs"	
	}
	
	*------------------- Command installation--------------------------------------*	
	ssc install oaxaca		, replace
	ssc install nopomatch	, replace

	/* The wage gap decomposition is done country by country using the income measure constructed for an independent study.
	*/
	
	cap noi mkdir "${dir_out}/Tables"
	cap noi mkdir "${dir_out}/Graphs"
********************************************************************************
						***** Graph options *****
********************************************************************************
	glo grph_reg	graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))
	glo lgnd_1
	glo y_axis	ylabel(, nogrid angle(horizontal))


	glo color1 "0 67 104"
	glo color2 "red"

	glo color3 "midblue"
	glo color4 "midgreen"

	glo color5 "orange"
	glo color6 "gs11"
	
*---------------------------- Rundofiles -------------------------------------*	
	
	* The Gambia 
	do "$do_files\1_The_Gambia.do"	
	
	
	
	
	
	
	
*---------------------------- Rundofiles -------------------------------------*	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
*------------------------------------------------------------------------------*
*-------------------------------- Regressions ---------------------------------*
*------------------------------------------------------------------------------*
	ds sector10_2 - sector10_7
	glo sector		"`r(varlist)'"
	
	ds educ_2 - educ_4 
	glo edulvl		"`r(varlist)'"
	
	ds firm_size_WB_1 - firm_size_WB_3
	glo firmsize	"`r(varlist)'"
	
	****************************************************************************
	*** OAXACA BLINDER DECOMPOSITION 
	****************************************************************************
	
	cap noi drop _supp _match
	nopomatch age age_sq  $edulvl  $sector  $firmsize, outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd 
	
	cap noi drop _supp _match
	nopomatch age age_sq , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd 
	
	
oaxaca ln_inc_by_hour (age: age age_sq) (edulvl: $edulvl) [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of education on male and female income are different 
estimates store OB_1
oaxaca ln_inc_by_hour (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of selection into economic activity
estimates store OB_2
oaxaca ln_inc_by_hour (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) (firmsize: $firmsize) [iweight = ilo_wgt] , by(female) relax vce(r) // Introducing firms size reduces the available smaple ostensibly 
estimates store OB_3
	
	label var ln_inc_by_hour	"LN total income per hour"
	label var ln_inc_d_total	"LN total daily income"
	label var ln_inc_d_selfw	"LN self employed income"
	label var ln_inc_d_salw		"LN salaried income"
	
	*reg ln_inc_by_hour female i.cm2b  
	foreach inc in ln_inc_by_hour ln_inc_d_total ln_inc_d_selfw ln_inc_d_salw  {
		if "`inc'" != "ln_inc_by_hour" {
		    local add_control = " wkt8a "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		reg `inc' female age age_sq  $edulvl $sector $firmsize
		
		oaxaca `inc' (age: age age_sq) (edulvl: $edulvl) `add_control'  [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of education on male and female income are different 
		estimates store OB_1
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) `add_control' [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_2
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) (firmsize: $firmsize) `add_control' [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_3
		
		esttab OB_1 OB_2 OB_3 using "${dir_out}/Tables/1. OB Decomposition in `vrlab'.csv" ,  stats(N ) label replace addnotes("Group 1 == Males. Group 2 == Females" )  title("Oaxaca Blinder Decomposition") b(3) t(3)
	
	
		* Nopo common support exercise 
		*	
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl  `add_control'  , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/OB_N_1_`inc'") replace
		*
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl  $sector  `add_control'  , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/OB_N_2_`inc'") replace
		*
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl  $sector  $firmsize  `add_control'  , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/OB_N_3_`inc'") replace
			
	}
	 
	*** Nopo not in logs
	preserve
	* inc_d_salw
	foreach inc in inc_by_hour inc_d_total inc_d_selfw   {  
		if "`inc'" != "inc_by_hour" {
		    local add_control = " wkt8a "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		* Nopo common support exercise 
		*	
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl  `add_control'  , outcome(`inc') by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/OB_N_1_`inc'") replace
		*
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl  $sector  `add_control'  , outcome(`inc') by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/OB_N_2_`inc'") replace
		*
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl  $sector  $firmsize  `add_control'  , outcome(`inc') by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/OB_N_3_`inc'") replace
			
	}
	restore 
	
	preserve
	clear
	set obs 0
	gen inc_type = ""
	foreach inc in ln_inc_by_hour inc_by_hour inc_d_total inc_d_selfw   {
		append using "${dir_out}/Tables/OB_N_1_`inc'"
		append using "${dir_out}/Tables/OB_N_2_`inc'"
		append using "${dir_out}/Tables/OB_N_3_`inc'"
		replace inc_type = "`inc'" if inc_type == "" 
	}
	export excel using "${dir_out}/Tables/Z_OB_Decomposition_Nopo_summary.xlsx" ,  sheet("By sex" , replace)  firstrow(varl)
	restore 
	
	
	/*
	What do I see so far?
	Endowments reduce the gap
	
	*/
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	