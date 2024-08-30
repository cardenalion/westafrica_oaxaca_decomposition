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
	
*	if "`c(username)'" == "SERGIO" {
*		global d_raw	"F:\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\1_Datasets"
*		global do_files	"F:\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\2_Dofiles" 
*e		global dir_out	"F:\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\4_Outputs"	
	* }

if "`c(username)'" == "SERGIO" {
	global d_raw	"E:\Sergio_Rivera\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\1_Datasets"
	global do_files	"E:\Sergio_Rivera\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\2_Dofiles" 
	global dir_out	"E:\Sergio_Rivera\Work\World_Bank\Poverty\P4 Africa Oaxaca Decomposition\4_Outputs"	
}
	
	*------------------- Command installation--------------------------------------*	
	*ssc install oaxaca		, replace
	*ssc install nopomatch	, replace
	*ssc install winsor2	, replace 
	*ssc install egenmore	, replace 
	/* The wage gap decomposition is done country by country using the income measure constructed for an independent study.
	*/
	
	cap noi mkdir "${dir_out}/Tables"
	cap noi mkdir "${dir_out}/Graphs"
********************************************************************************
						***** Graph options *****
********************************************************************************
	glo grph_reg	graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white))
	glo lgnd_1
	glo y_axis		ylabel(, nogrid angle(horizontal))
	glo inner_grid	xlabel(, nogrid) ylabel(, nogrid)
	glo noaxis_tit	xtitle("") ytitle("") 
	glo color1 "0 67 104"
	glo color2 "red"

	glo color3 "midblue"
	glo color4 "midgreen"

	glo color5 "orange"
	glo color6 "gs11"
	
*---------------------------- Rundofiles -------------------------------------*	
	
	* The Gambia 
	do "$do_files\1_The_Gambia.do"	
	
	* Mauritania
	do "$do_files\2_Mauritania.do"	
	
	* Guinea Bisao
	do "$do_files\3_Guinea_Bisao.do"
	do "$do_files\3_Guinea_Bisao_2_own_production.do"
	do "$do_files\3_Guinea_Bisao_3_Non_salary_income.do"
	do "$do_files\3_Guinea_Bisao_4_total_income.do"
	
	* do "$do_files\3_Guinea_Bisao.do"
	
	* Senegal
	do "$do_files\3_Senegal.do"
	do "$do_files\3_Senegal_2_own_production.do"
	do "$do_files\3_Senegal_3_Non_salary_income.do"
	
	
	
	
	
*---------------------------- Rundofiles -------------------------------------*	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/*
	What do I see so far?
	Endowments reduce the gap
	
	*/
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	