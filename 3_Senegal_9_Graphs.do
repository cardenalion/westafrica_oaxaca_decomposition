* ------------------------------------------------------------------------------
* World Bank Poverty & Gender Assessment - Senegal
* Author: Sergio Rivera
* Following: Sarango-Iturralde Alexander
* Created: May 13, 2024 | Last modified: May 21, 2024
* Topic: Non-salary income (Enterprises)
* ------------------------------------------------------------------------------

* ------------------------------------------------------------------------------
* Load dataset
* ------------------------------------------------------------------------------
use "${d_raw}\working\SEN_individual_reg_Full.dta", clear

* ------------------------------------------------------------------------------
* Data Cleaning & Transformation
* ------------------------------------------------------------------------------
* Winsorization: Adjust outliers for income-related variables
foreach var in inc_by_hour inc_d_total inc_d_selfw inc_d_salw inc_by_hour_IMP {
    sum `var'_usd , detail
    replace `var'_usd = . if `var'_usd < r(p1) & `var'_usd != .
    replace `var'_usd = . if `var'_usd > r(p95) & `var'_usd != .
    sum `var'_usd , detail
}
	
* Correct missing values for workforce-related variables
replace born_here = 1 if hnation == 13
foreach var in wage_h inc_by_hour_IMP inc_d_salw inc_d_selfw inc_d_total {
    replace `var' = . if merge_labforce == 1
    replace `var' = . if empstat_ == .
}

* Define gender and sectoral adjustments
gen male = female == 0
replace sector2_ = 6 if sector2_ == . & productivity != .
replace sector2_ = 6 if sector2_ == . & inc_by_hour_usd != .

* Variable labels
label var inc_d_salw_usd   "Salaried Income"
label var inc_d_selfw_usd  "Self-employed Income"
label var inc_d_total_usd  "Total Income (Salaried and Self-employed)"
label var inc_by_hour_usd  "Total Income per Hour"
	
*------------------------------------------------------------------------------*
*--------------------------- Descriptive Stats --------------------------------*
*------------------------------------------------------------------------------*

replace week_hours = 110 if week_hours >= 110 & week_hours != .
*gen wgt = hhweight

global shares  urban w_wap female born_here educ_* neet macti_* informality

label define sex_fem 100 "Female" , modify 
	label define urban 1 "Urban" 100 "Urban" 0 "Rural" , modify
	label define origin  100 "National"  , modify
	label val urban urban 
	
	rename educ_ edu_categ
	
	desc urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour_usd inc_d_total inc_d_selfw inc_d_salw week_hours neet
	
	global shares  urban w_wap female born_here educ_* neet macti_* informality
	
	gen wgt = hhweight
	
	rename inc_by_hour_IM imputed_inc_h_usd
	gen ln_imputed_inc_h_usd = ln(imputed_inc_h_usd + 1)
quietly {
foreach categ in urban female born_here {
	
	preserve
	* local categ = "urban"
		recode "${shares}" ( 1 = 100 )
		
		rename urban			a_urban
		rename w_wap			b_w_wap
		rename female 			c_female
		rename born_here 		d_born_here
		rename educ_*			e_educ_*
		rename informality		f_informality
		rename inc_*			g_inc_*
		rename week_hours*		h_week_hours*
		rename neet 			i_neet
		* rename look_last*		j_look_last *
		rename macti_*			k_macti*
		
		desc *_`categ' , varlist
		di r(varlist)
		
		local byvar = substr("`r(varlist)'" , 3, .)
		di "`byvar'"
			
		tempfile stat1 stat2 `byvar'
		
		* j_look *
		qui noi tabstat a_urban b_w_wap c_female d_born_here e_educ* f_informality g_inc_d_salw g_inc_d_selfw g_inc_d_total g_inc_by_hour_usd h_week_hours* i_neet  k_macti* ///
		[aw = wgt ] ///
		if age >= 15 & age < 66 ///
		, columns(statistics) stats(mean sd n) long by( `r(varlist)' )  save
		
		local name1 = "`r(name1)'"
		local name2 = "`r(name2)'"
		
		** in this space I can automate the number of categories 
		clear 
		
		mat stat2_		= r(Stat2)
		mat stat1_		= r(Stat1)
		mat stattot_	= r(StatTotal)
		
		svmat stat1_ , n(matcol)
		gen type = "mean"
		replace type = "sd" if _n == 2
		replace type = "obs" if _n == 3
		 
		
		reshape long stat1_ , i(type) j(var) string
		
		sort var type
		
		save `stat1'
			
		clear 	
		svmat stat2_ , n(matcol)
		gen type = "mean"
		replace type = "sd" if _n == 2
		replace type = "obs" if _n == 3
		reshape long stat2_ , i(type) j(var) string
		
		* Merge Categories
		merge 1:1 type var using `stat1' , nogen 
		sort var type
		
		replace var = substr(var , 3, .)
		rename stat1 `name1'
		rename stat2 `name2'
		
		export excel using "${dir_out}/Tables/Z_Descriptive_statistics.xlsx" if type != "obs" , sheet("SEN By `byvar'" , replace)  firstrow(varl)	
		export excel using "${dir_out}/Tables/Z_Descriptive_statistics_obs.xlsx" if type == "obs" , sheet("SEN By `byvar'" , replace)  firstrow(varl)	
	restore 
	
		* Export the total
		preserve
			clear 	
			svmat stattot_ , n(matcol)
			gen type = "mean"
			replace type = "sd" if _n == 2
			replace type = "obs" if _n == 3
			reshape long stattot_ , i(type) j(var) string
			sort var type
			replace var = substr(var , 3, .)
			
			export excel using "${dir_out}/Tables/Z_Descriptive_statistics.xlsx" if type != "obs"  , sheet("SEN Total" , replace)  firstrow(varl)
			
			export excel using "${dir_out}/Tables/Z_Descriptive_statistics_obs.xlsx" if type == "obs"  , sheet("SEN Total" , replace)  firstrow(varl)	
			
		restore 
}
}	
	
	
*-------------------------------------------------------------------------------
*-------------------------Generating graphs------------------------------
*-------------------------------------------------------------------------------

** Hours worked CDF
	sort female week_hours
	cap drop cum_hw_m cum_hw_f
	cumul week_hours if female == 0 [aw = wgt] , gen(cum_hw_m) eq
	cumul week_hours if female == 1 [aw = wgt] , gen(cum_hw_f) eq
	
	replace cum_hw_f = cum_hw_f*100
	replace cum_hw_m = cum_hw_m*100
	
	sum week_hours  [ aweight = wgt ] if female == 1 
		qui local mu_f = round(`r(mean)', 1)
		qui local vr_f = round(`r(sd)', 1)

	sum week_hours  [ aweight = wgt ] if female == 0 
		qui local mu_m = round(`r(mean)', 1)
		qui local vr_m = round(`r(sd)', 1)
		
	twoway	(line cum_hw_m week_hours if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) ///
			(line cum_hw_f week_hours , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ///
		,	$grph_reg $y_axis legend(pos(6) order( 1 "Males" 2 "Females" )  region(lcolor(none)) )   ytitle("% below # of hours")  ylabel( 0(20)100, labsize(small)) xlabel( 0(10)105 , labsize(small)) ///
	note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (medsmall) position(11) ring(0) margin(medlarge))  xtitle("") $inner_grid
	* subti("")
	* xtitle(Hours) xtitle("# Hours worked" )
	
	 graph export "${dir_out}/Graphs/SEN 1. Hours worked by sex.png",  as(png)    replace width(1995)  height(1452)	
	 
	 
** Income 
label var inc_by_hour_usd "Total income per hour"
label var imputed_inc_h_usd "Total income per hour imputed"
*label var inc_d_total "Total income"

replace inc_by_hour_usd = . if inc_by_hour_usd < 0

	quietly {
		foreach var in imputed_inc_h_usd inc_by_hour_usd inc_d_total inc_d_selfw inc_d_salw {
			sum `var' , d
			replace ln_`var' = . if `var' < r(p1) | `var' > r(p99)
			replace `var' = . if `var' < r(p1) | `var' > r(p99)
		}
	}

	*imputed_inc_h_usd inc_by_hour_usd inc_d_total inc_d_selfw inc_d_salw
	foreach inc in  imputed_inc_h_usd inc_by_hour_usd inc_d_total inc_d_selfw inc_d_salw {
		local vrlab = `"`: var label `inc' '"'
		local vrlab = subinstr("`vrlab'",":","",.)
		
		sort female ln_`inc'
		cap drop cum_hw_m cum_hw_f
		cumul ln_`inc' if female == 0 , gen(cum_hw_m) eq
		cumul ln_`inc' if female == 1 , gen(cum_hw_f) eq
		
		replace cum_hw_f = cum_hw_f*100
		replace cum_hw_m = cum_hw_m*100
		
		sum `inc'  [ aweight = wgt ] if female == 1 
			qui local mu_f = round(`r(mean)',  0.0001) //  floor(`r(mean)' *100) 
			if "`inc'" == "inc_d_salw" {
				di "`inc'"
				qui local mu_f = round(`mu_f'  ,  0.12)
			}
			else {
				qui local mu_f = round(`mu_f'  ,  0.025)
			}
			qui local vr_f = round(`r(sd)',  0.01)

		sum `inc'  [ aweight = wgt ] if female == 0 
			qui local mu_m = round(2*`r(mean)',  0.0025)
			qui local mu_m = round(`mu_m'*(1/2) +.0001 , 0.04)
			qui local vr_m = round(`r(sd)',  0.01)
			
	twoway (line cum_hw_m ln_`inc' if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) (line cum_hw_f ln_`inc' , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ///
	,	$grph_reg $y_axis legend(pos(6) order( 1 "Males" 2 "Females" )  region(lcolor(none)) )   ytitle("%") ///
	note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (medsmall) position(4) ring(0) margin(medlarge))  xtitle("" ) ylabel( 0(20)100, labsize(small)) $inner_grid
		* subti("Mauritania")  
		* ylabel( 0(20)100, labsize(small)) xlabel( 0(20)180 , labsize(small))
		* xtitle(Hours)  xtitle("`vrlab' in logs" )
		graph export "${dir_out}/Graphs/SEN 1. `vrlab' by sex.png",  as(png)    replace width(1995)  height(1452)
	
		cap drop fx x fx_f fx_m 
	kdensity ln_`inc'  [ aweight = wgt ] if uno ==1  `limit', nograph generate(x fx)
	kdensity ln_`inc'  [ aweight = wgt ] if female == 1 `limit' , nograph generate(fx_f) at(x) `bw'
	kdensity ln_`inc'  [ aweight = wgt ] if female == 0 `limit' , nograph generate(fx_m) at(x) `bw'
		* local bw = "bw(.19)"
		
		twoway (area fx_m x, fcolor("${color3}%30") lcolor("${color3}%60")) (area fx_f x, fcolor("${color2}%30") lcolor("${color2}%60") ) if uno == 1 `bnd' ///
		, $inner_grid $grph_reg $y_axis ytitle(" " )    legend(pos(6) order( 1 "Males" 2 "Females" )  region(lcolor(white)) size(small)) ylabel(, noticks nolabels) note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:   {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (medsmall) position(2) ring(0) margin(medlarge)) ///
		name(`inc' , replace)  xtitle("") 
		// subti("Mauritania")  
		* xtitle("`vrlab' in logs", size(small))
		
		graph export "${dir_out}/Graphs/SEN 2. Kernel `vrlab' by sex.png",  as(png)    replace width(1995)  height(1452)
	}
	
	 
	** Pies Main Activity
	graph pie [aweight = wgt] if age >=15 & female == 1 , over(main_acti)  sort(order_mainacti)    plabel(_all percent, color(white) size( small) format(%3.0f)) line(lcolor(black) lwidth(vvvthin)) intensity(inten90) name(Female , replace)  $grph_reg legend(region(lcolor(none))) legend(pos(6) )
	// subtitle(Females, position(10) ring(0) margin(10-pt))
	graph export "${dir_out}/Graphs/SEN 3. Main activity female.png",   replace width(1995)  height(1452)

	graph pie [aweight = wgt] if age >=15 & female == 0 , over(main_acti)  sort(order_mainacti)   plabel(_all percent, color(white) size( small) format(%3.0f))  line(lcolor(black) lwidth(vvvthin)) intensity(inten90) name(Male , replace)  $grph_reg legend(region(lcolor(none))) legend(pos(6) )
	// subtitle(Males, position(10) ring(0) margin(10-pt))
	graph export "${dir_out}/Graphs/SEN 3. Main activity Male.png",   replace width(1995)  height(1452)
 
	 

	* Employment composition 
	graph pie empstat2_1 empstat2_2 empstat2_3 empstat2_4 [aw=hhweight], ///
	plabel(_all percent , color(white) size( small) format(%3.0f)) ///
	legend(lab(1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "SOEs salaried workers") lab(4 "Other workers") pos(6) col(2))
	graph export "${dir_out}/Graphs/SEN 4. Employment composition.png",   replace width(1995)  height(1452)
	
	* Sectorial composition 
	graph pie sector2_1 sector2_2 sector2_3 sector2_4 sector2_5  [aw=hhweight], ///
	plabel(_all percent , color(white) size( small) format(%3.0f) ) ///
	legend(lab(1 "Agriculture") lab(2 "Manufacture") lab(3 "Trade and distribution services") lab(4 "Low-skilled services") lab(5 "High-skilled services")  pos(6) col(2))
	graph export "${dir_out}/Graphs/SEN 5. Sectorial composition.png",   replace width(1995)  height(1452)
	
	

	* Kernel density "ln_inc_by_hour_usd"  By type of contract
	 twoway kdensity ln_inc_by_hour_usd if empstat_1 == 1  || kdensity ln_inc_by_hour_usd if empstat_2==1 || kdensity ln_inc_by_hour_usd if empstat_3==1  , ///
	 legend(lab (1 "Self-employeed") lab(2 "Salaried workers") lab(3 "Other workers")  pos(6) ) $grph_reg xtitle("") $inner_grid $noaxis_tit ylabel(, noticks nolabels)
	 graph export "${dir_out}/Graphs/SEN 2. Kernel by contract.png",  as(png)    replace width(1995)  height(1452)
	 
	 * 	 twoway kdensity ln_inc_by_hour_usd if empstat_1 == 1  || kdensity ln_inc_by_hour_usd if empstat_2==1 || kdensity ln_inc_by_hour_usd if empstat_3==1 || kdensity ln_inc_by_hour_usd if empstat_4==1 ,  legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "SOEs salaried workers") lab(4 "Other workers")  pos(6) ) $grph_reg xtitle("") $inner_grid
	 
	 * Kernel density "ln_inc_by_hour_usd" by SECTOR 
	 twoway kdensity ln_inc_by_hour_usd if sector2_1 == 1  || kdensity ln_inc_by_hour_usd if sector2_2==1 || kdensity ln_inc_by_hour_usd if sector2_3==1  || kdensity ln_inc_by_hour_usd if sector2_4==1  || kdensity ln_inc_by_hour_usd if sector2_5==1  , legend(lab(1 "Agriculture") lab(2 "Manufacture") lab(3 "Trade and distribution services") lab(4 "Low-skilled services") lab(5 "High-skilled services")  pos(6) col(2)) $inner_grid $y_axis ///
	 $noaxis_tit ylabel(, noticks nolabels)
	  graph export "${dir_out}/Graphs/SEN 2. Kernel by sector.png",  as(png)    replace width(1995)  height(1452)
	 
	 twoway ( kdensity ln_inc_by_hour_usd if sector2_1 == 1)  ( kdensity ln_inc_by_hour_usd if sector2_2==1 ) ( kdensity ln_inc_by_hour_usd if sector2_3==1  ) ( kdensity ln_inc_by_hour_usd if sector2_4==1  ) (kdensity ln_inc_by_hour_usd if sector2_5==1 ) (kdensity ln_inc_by_hour_usd if sector2_== 6 , lpattern(dash) ) if female == 0 , legend(order(1 "Agriculture" 2 "Manufacture" 3 "Trade and distribution services" 4 "Low-skilled services" 5 "High-skilled services" 6 "Informal-Other" )  pos(6) col(2)) $inner_grid $y_axis ///
	 $noaxis_tit ylabel(, noticks nolabels) name(male , replace)
	 graph export "${dir_out}/Graphs/SEN 2. Kernel by sector male.png",  as(png)    replace width(1995)  height(1452)
	 
	  twoway ( kdensity ln_inc_by_hour_usd if sector2_1 == 1)  ( kdensity ln_inc_by_hour_usd if sector2_2==1 ) ( kdensity ln_inc_by_hour_usd if sector2_3==1  ) ( kdensity ln_inc_by_hour_usd if sector2_4==1  ) (kdensity ln_inc_by_hour_usd if sector2_5==1 )  (kdensity ln_inc_by_hour_usd if sector2_== 6 , lpattern(dash) ) if female == 1 ,  $inner_grid $y_axis legend( order(1 "Agriculture" 2 "Manufacture" 3 "Trade and distribution services" 4 "Low-skilled services" 5 "High-skilled services" 6 "Informal-Other" )  pos(6) col(2)) ///
	 $noaxis_tit ylabel(, noticks nolabels) name(female , replace)
	 * legend(lab(1 "Agriculture") lab(2 "Manufacture") lab(3 "Trade and distribution services") lab(4 "Low-skilled services") lab(5 "High-skilled services")  pos(6) col(2))
	 graph export "${dir_out}/Graphs/SEN 2. Kernel by sector female.png",  as(png)    replace width(1995)  height(1452)
	 
	 graph hbar (sum) female (sum ) male, over(sector2_ , relabel(1 "Agriculture" 2 "Manufacture" 3 "Trade and distribution services" 4 "Low-skilled services" 5 "High-skilled services" 6 "Informal-Other")) legend(order(1 "Female" 2 "Male"))  ylabel(, nogrid) name(sector_ , replace)
	 graph export "${dir_out}/Graphs/SEN 6. Share sector by sex.png",  as(png)    replace width(1995)  height(1452)
	 
	 graph hbar (sum) female (sum ) male if ln_inc_by_hour_usd != . , over(empstat_ , ) legend(order(1 "Female" 2 "Male"))  ylabel(, nogrid) name(empstat_sex , replace)
	 graph export "${dir_out}/Graphs/SEN 6. Share emp_categ by sex.png",  as(png)    replace width(1995)  height(1452)
	 
	 graph hbar (sum) female (sum ) male if ln_inc_by_hour_usd != . , over(edu_categ , ) legend(order(1 "Female" 2 "Male"))  ylabel(, nogrid) name(educ_sex , replace)
	 graph export "${dir_out}/Graphs/SEN 6. Share educ by sex.png",  as(png)    replace width(1995)  height(1452)
	 
	 
	 tabstat inc_by_hour_usd if female == 0 [aw=hhweight] , by(sector2_) stats(count mean p10 p50 p90 sd) columns(statistics) long 
	 tabstat inc_by_hour_usd if female == 1 [aw=hhweight] , by(sector2_) stats(count mean p10 p50 p90 sd) columns(statistics) long 
	 
	 bys female : sum inc_by_hour_usd if sector2_ != . [aw=hhweight] 
	 sum inc_by_hour_usd  [aw=hhweight] 
	 tabstat inc_by_hour_usd [aw=hhweight] 
	 /* 
	 Tabulations 
	 */
	 
// Productivity -----------------------------------
/*
// Tables -----------------------------------
tabstat ln_total_income_hVFL, stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat ln_total_income_hVFL, by(female) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat ln_total_income_hVFL, by(educ_) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat ln_total_income_hVFL, by(empstat2_) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat ln_total_income_hVFL, by(sector2_) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat ln_total_income_hVFL, by(rural) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat ln_total_income_hVFL, by(informal) stats(mean p25 p50 p75 sd) columns(statistics) long

*At level
tabstat adjusted_tot_income, stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat adjusted_tot_income, by(female) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat adjusted_tot_income, by(educ_) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat adjusted_tot_income, by(empstat2_) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat adjusted_tot_income, by(sector2_) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat adjusted_tot_income, by(rural) stats(mean p25 p50 p75 sd) columns(statistics) long
tabstat adjusted_tot_income, by(informal) stats(mean p25 p50 p75 sd) columns(statistics) long
*/
	 * Sector and type of contract 
	 ta empstat_ sector_  [iw=hhweight] if inlist(sector_,1,2,3), col row 
	 
	 
*------------------------------------------------------------------------------*
*-------------------------------- Regressions ---------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
*-------------------------------- Regressions ---------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
*-------------------------------- Regressions ---------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
*-------------------------------- Regressions ---------------------------------*
*------------------------------------------------------------------------------*
	drop n_kids
	cap drop tot_children 
	gen tot_children = n_kids_
	rename agesq age_sq
	gen agesq =  age_sq
	
	
	ds sector2_1  - sector2_5
	glo sector		"`r(varlist)' "
	
	ds educ_2 - educ_4 
	glo edulvl		"`r(varlist)'"
	
	glo hh_charac "tot_children "

	*ds firm_size_WB_1 - firm_size_WB_3
	glo firmsize	""
	
	
	label var ln_inc_by_hour_usd	"LN total income per hour"
	label var ln_inc_d_total		"LN total daily income"
	label var ln_inc_d_selfw		"LN self employed income"
	label var ln_inc_d_salw			"LN salaried income"
	
	*
	cap noi mkdir "${dir_out}/Tables/SEN/"
	foreach inc in ln_inc_by_hour_usd ln_inc_d_total ln_inc_d_selfw ln_inc_d_salw  {
		if "`inc'" != "ln_inc_by_hour" {
		    local add_control = " week_hours "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		noi di "This is the income variable at work: `inc' "
		count if `inc' != .
		reg `inc' female age age_sq  $edulvl $sector $firmsize $hh_charac
		
		oaxaca `inc' (age: age age_sq) (edulvl: $edulvl)	$hh_charac	`add_control'  [iweight = wgt] , by(female) relax vce(r) // The effect of education on male and female income are different 
		estimates store OB_1
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector)	$hh_charac	`add_control' [iweight = wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_2
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) 	$hh_charac `add_control' [iweight = wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_3
		
		esttab OB_1 OB_2 OB_3 using "${dir_out}/Tables/SEN/1. OB Decomposition in `vrlab'.csv" ,  stats(N ) label replace addnotes("Group 1 == Males. Group 2 == Females" )  title("Oaxaca Blinder Decomposition") b(3) t(3)
	
	
	}
	 
	*** Nopo not in logs
	
	* inc_d_salw
	foreach inc in inc_by_hour inc_d_total inc_d_selfw inc_d_salw  {  
		if "`inc'" != "inc_by_hour" {
		    local add_control = " week_hours "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		* Nopo common support exercise 
		*	
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$hh_charac	`add_control'	, outcome(`inc') by(male) fact(wgt) sd filename("${dir_out}/Tables/SEN/OB_N_1_`inc'") replace
		*
		restore
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$hh_charac   `add_control'  , outcome(`inc') by(male) fact(wgt) sd filename("${dir_out}/Tables/SEN/OB_N_2_`inc'") replace
		*
		restore
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$hh_charac	`add_control'  , outcome(`inc') by(male) fact(wgt) sd filename("${dir_out}/Tables/SEN/OB_N_3_`inc'") replace
		restore
	}
	
	
	preserve
		clear
		set obs 0
		gen inc_type = ""
		* ln_inc_by_hour
		foreach inc in  inc_by_hour inc_d_total inc_d_selfw inc_d_salw  {
			append using "${dir_out}/Tables/SEN/OB_N_1_`inc'"
			append using "${dir_out}/Tables/SEN/OB_N_2_`inc'"
			append using "${dir_out}/Tables/SEN/OB_N_3_`inc'"
			replace inc_type = "`inc'" if inc_type == ""
			
			erase "${dir_out}/Tables/SEN/OB_N_1_`inc'.dta"
			erase "${dir_out}/Tables/SEN/OB_N_2_`inc'.dta"
			erase "${dir_out}/Tables/SEN/OB_N_3_`inc'.dta"
			
		}
		export excel using "${dir_out}/Tables/Z_OB_Decomposition_Nopo_summary.xlsx" ,  sheet("SEN By sex" , replace)  firstrow(varl)
	restore 
	 
	 