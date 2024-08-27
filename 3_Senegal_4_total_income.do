*	World Bank Poverty & Gender Assessment
*	Senegal
*	Sergio Rivera 
*	Non-salary income. Enterprises.

*	Following: Author: Sarango-Iturralde Alexander
*	Last modified: May 21, 2024




*-------------------------------------------------------------------------------
*-----------------------------------Loading datasets----------------------------
*-------------------------------------------------------------------------------

	// welfare
	use "${d_raw}\EHCVM\SEN\Dataout\ehcvm_welfare_SEN2021.dta",clear

	*-------------------------------------------------------------------------------
	*-----------------------------------Calculate Poverty---------------------------
	*-------------------------------------------------------------------------------

	//  a. national poverty
	gen poor0 = 100 * (pcexp < zref)
	gen nca = dtot * def_temp

	gen poor1 = 100 * ( nca / (hhsize * def_temp     * def_spa) < zref)
	gen poor2 = 100 * ( nca / (hhsize * def_temp_cpi * def_spa) < zref)
	*gen poor3 = 100 * ( nca / (hhsize * def_temp_adj * def_spa) < zref)

	table (milieu) [aw = hhweight * hhsize] , stat(mean poor0 poor1 poor2 ) nformat(%5.2f) 

	* NOTE : table command does not work as intended. Had to download STATA 18 finally 


	//  b. international poverty
	gen ipoor = 100 * (dtot/hhsize/def_temp_prix/365/cpi2017/icp2017 < 2.15)
	table (milieu) [aw = hhweight * hhsize] ,   stat(mean ipoor) nformat(%5.2f)

	*-------------------------------------------------------------------------------
	*-----------------------------------Merge Databases-----------------------------
	*-------------------------------------------------------------------------------

	// Total income enterprises non-agricultural, agr, livestock and fishing per capita
	// by equivaleces scales adjustment
	merge 1:m grappe menage using "${d_raw}\working\SEN_individual.dta"
	drop if _merge == 2
	drop _merge

	merge m:1 grappe menage using "${d_raw}\working\SEN_self_income.dta", nogen
	merge 1:1 grappe menage s01q00a using "${d_raw}\working\SEN_self_income_individual.dta" // New version
	drop if _merge == 2
	drop _merge

	// salary workers & non-salary
	merge 1:1 grappe menage s01q00a using "${d_raw}\EHCVM\SEN\Datain\Menage\s04b_me_SEN2021.dta"
	ren _merge _merge_a

	merge 1:1 grappe menage s01q00a using "${d_raw}\EHCVM\SEN\Datain\Menage\s04c_me_SEN2021.dta",nogen

	// sociodemographic 
	merge m:1 grappe menage s01q00a using  "${d_raw}\EHCVM\SEN\Datain\Menage\s01_me_SEN2021.dta"
	ren _merge _merge_b
	merge m:1 grappe menage using "${d_raw}\EHCVM\SEN\Datain\Menage\s00_me_SEN2021.dta", ///
	  keepusing(s00q00 s00q01 s00q02 s00q03 s00q04 s00q08 s00q23a s00q27)
	ren _merge _merge_c

	//  Quintiles of expenditures
	egen q5_pcexp = xtile(pcexp), nq(5)
	lab def q5_pcexp 1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5"
	lab val q5_pcexp q5_pcexp


//wage -------------------------------------------------------------------------
	* Annualizing income from wages main job
	foreach x in 43 45 47 49{
	  gen unite`x'=52 if s04q`x'_unite==1
	  replace unite`x'=12 if s04q`x'_unite==2
	  replace unite`x'=4 if s04q`x'_unite==3
	  replace unite`x'=1 if s04q`x'_unite==4
	  gen wage`x'=s04q`x'*unite`x'
	}

	sum wage43 wage45 wage47 wage49
	recode wage43 wage45 wage47 wage49 (9999 =0)  // Replace . by 0	
	egen wage_mj=rowtotal(wage43 wage45 wage47 wage49) , missing // Summing up all sources of wages
	lab var wage_mj "Wage of main job" 	
	sum wage_mj

	
		* Annualizing income from wages secondary job
	foreach x in 58 60 62 64{
	  gen unite`x'=52 if s04q`x'_unite==1
	  replace unite`x'=12 if s04q`x'_unite==2
	  replace unite`x'=4 if s04q`x'_unite==3
	  replace unite`x'=1 if s04q`x'_unite==4
	  gen wage`x'=s04q`x'*unite`x'
	}

	sum wage58 wage60 wage62 wage64
	recode wage58 wage60 wage62 wage64 (9999 =0)  // Replace . by 0	
	egen wage_sj=rowtotal(wage58 wage60 wage62 wage64), missing // Summing up all sources of wages
	lab var wage_sj "Wage of secondary job" 	
	sum wage_sj

	g wage_ann = wage_mj + wage_sj
	
	g wage_h = wage_ann/360/s04q37
	

// Missings?	
sum wage_h wage_ann wage_mj  wage_sj s04q36 s04q37 s04q39 self_incomeV2_pc  

sum wage_h wage_ann wage_mj  wage_sj s04q36 s04q37 s04q39 self_incomeV2_pc  if empstat_==1 | empstat_==3  // Self-employee/own

egen aux1missing = rowtotal(wage_ann self_incomeV2_pc), missing

sum wage_h wage_ann wage_mj  wage_sj s04q36 s04q37 s04q39 self_incomeV2_pc  if empstat_==2 // Employ

sum aux1missing if empstat_ !=.
// missing 4161 = 22154 (workers) - 17993 (obsevations whith income)

bys empstat2_ : sum aux1missing if empstat_ !=.

	
//Total income salary + self_income

g self_income_pc_h = self_income_pc / s04q37

foreach var in wage_h self_income_pc_h {
    replace `var' = 0 if missing(`var')
}

g total_income_h = wage_h + self_income_pc_h   // Just dividing HH level data per N workers

g total_income_hV2 = wage_h + self_incomeV2_pc // Using lab supply provided per individual

count if total_income_hV!=.

replace total_income_h=. if total_income_h==0     // 21,552   to missing out of  41,501!!
replace total_income_hV2=. if total_income_hV2==0   // 17,249  to missing out of  41,501!!


gen adjusted_self_incomeV2=self_incomeV2_pc
sum self_incomeV2_pc, d
replace adjusted_self_incomeV2 = r(p1) if self_incomeV2_pc<r(p1)
replace adjusted_self_incomeV2 = r(p99) if self_incomeV2_pc>r(p99)
sum adjusted_self_incomeV2, d
loc mino=r(min)
gen adjusted_self_incomeFLV2= adjusted_self_incomeV2-`mino'+1

* Deal with the negatives...
gen adjusted_self_income=self_income_pc_h
sum self_income_pc_h, d
replace adjusted_self_income = r(p1) if self_income_pc_h<r(p1)
replace adjusted_self_income = r(p99) if self_income_pc_h>r(p99)
sum adjusted_self_income, d
loc mino=r(min)
gen adjusted_self_incomeFL= adjusted_self_income-`mino'+1


replace year=2021
save "${d_raw}\working\SEN_individualALL_2.dta", replace
keep if _merge_a == 3 // // drop non occupied
keep if _merge_b == 3 // // drop non occupied
keep if _merge_c == 3 // // drop non occupied
save "${d_raw}\working\SEN_individual_2.dta", replace


/* -------------------------------------------------------------------------- */
/*      Mincer model estimation for average household worker               */
/* -------------------------------------------------------------------------- */

collapse (first) nworker hhweight (mean) adjusted_self_incomeFL wage_h hours age female educy sector_* empstat_* rural, by(grappe menage)

gen lnwage_h=ln(wage_h+1)

gen agesq = age^2

global Xind hours female age agesq educy sector_1 sector_2 sector_3 empstat_1 empstat_2 empstat_3
global Xhh rural   // region_* wave_* 
global Xs $Xind $Xhh


//  c. log labor income (self-income) per worker

gen double lnLx=ln(adjusted_self_incomeFL)

sum $Xs
sum lnLx hhweight nworker

//  a. regression
eststo Mincer : regress lnLx $Xs [pw=hhweight*nworker]	
ereturn list
*putexcel V28 = `e(r2)'
predict res if e(sample) , res
gen eresid = exp(res) 
sum eresid [aw=hhweight*nworker]
local duan = r(mean)
		
//  b. label Xs
label var hours "Mean hours worked"
lab var female "Share of female worker"
lab var age "Mean age of workers"
lab var agesq "Mean age squared of workers"
lab var educy "Average years of education of workers"
lab var sector_1 "Share of workers in Agriculture"
lab var sector_2 "Share of workers in Manufacture"
lab var sector_3 "Share of workers in Services"
lab var empstat_1 "Share of self-employee/own boss"
lab var empstat_2 "Share of salaried workers"
lab var empstat_3 "Share of other workers"
lab var rural "Live in rural areas"
*lab var wave_1 "Interviewed during first wave"
		
//  c. estimation table
//esttab Mincer using "$temp\Mincer_${iso3}.tex", ar2 b(3) se(3) replace /*label*/ order ($Xs) keep($Xs) nobaselevels longtable booktabs star(* 0.10 ** 0.05 *** 0.01) title("Mincer equation for labor incomes per employed in $iso3")
		
//  d. estimation plot
qui coefplot Mincer, keep(hoursf female age agesq educy sector_1 sector_2 sector_3 empstat_1 empstat_2 empstat_3 rural) xline(0) title("Mincer regression results") byopts(xrescale) graphregion(col(white)) bgcol(white) eqlabels("labor incomes based", asequations)
*graph export "${logA}\Mincer_$iso3.png", replace
*putexcel Y44 = image("${logA}\Mincer_$iso3.png")

**********************************************
****Multiple imputation
preserve
gen y_imp = adjusted_self_incomeFL
drop if y_imp==.

foreach var in $Xs {
drop if `var'==. 
}
tempfile y_don 
save `y_don'

use "${d_raw}\working\SEN_individual_2.dta", clear
gen y_imp=. 
gen y_res=1
keep $Xs y_imp y_res grappe menage s01q00a
tempfile y_res 
save `y_res'

use `y_don', clear
append using `y_res'

mi set wide
mi register imputed y_imp
mi impute pmm y_imp female, replace knn(5) add(20)
egen y_imp2=rowmean(*_y_imp)
replace y_imp=y_imp2 if y_res==1
keep if y_res==1
keep y_imp y_res grappe menage s01q00a
tempfile y_imputes 
save `y_imputes'
save "${d_raw}\working\SEN_imputes" , replace 
restore

/* -------------------------------------------------------------------------- */
/*      B. Apply estimated coefficients to individual level data              */
/* -------------------------------------------------------------------------- */

/* ---- 1. Predict individual labor income ---------------------------------- */
//  a. indvidual data
* use "${d_raw}\working\SEN_individual_2.dta", clear
use "${d_raw}\working\SEN_individualall_2.dta", clear
merge 1:1 grappe menage s01q00a using "${d_raw}\working\SEN_imputes" , gen(merge_labforce) // `y_imputes'
gen lnwage_h=ln(wage_h+1)
//  b. impute missing values of Xs
sum $Xind

//  d. predict individual level labor income
estimates restore Mincer
predict double li    		// predict individual labor self-income for each individual based on their 
							//characteristics and the coefficients from the average worker regression
replace li = exp(li)*`duan' // Duan's smearing estimator, see https://people.stat.sc.edu/hoyen/STAT704/Notes/Smearing.pdf

g ln_li = ln(li+wage_h) // for the graphs only

replace li = li + `mino'-1 // Restore the scale

sum $Xind li

* For comparison
tw  (kdensity wage_h if wage_h<2000) ///
	(kdensity adjusted_self_income if adjusted_self_income<2000) ///
	(kdensity li if li<2000) ///
	(kdensity adjusted_self_incomeV2 if adjusted_self_incomeV2>-100 & adjusted_self_incomeV2<2000) ///
	, legend(order( 1 "Salaried income" 2 "NSI: Plain sum over N work" 3 "NSI: Smearing imputation" 4 "NSI: Plain sum over hours per indv"  ) pos(6)) xsize(3) ysize(3)
	
		
label var wage_h "Salaried income"		
label var adjusted_self_income "NSI: Plain sum over N work"
label var li "NSI: Smearing imputation"
label var adjusted_self_incomeV2 "NSI: Plain sum over hours per indv"
		
dtable wage_h adjusted_self_income li adjusted_self_incomeV2
tabstat wage_h adjusted_self_income li adjusted_self_incomeV2, stats(mean p50 p1 p99) columns(statistics) long

*-------------------------------------------------------------------------------
*---------------------Regressions------------------------------
*-------------------------------------------------------------------------------

// Productivity -----------------------------------

gen adjusted_tot_income=total_income_hV2
sum total_income_hV2, d
replace adjusted_tot_income = . if total_income_hV2<r(p1) 
replace adjusted_tot_income = . if total_income_hV2>r(p99)

sum adjusted_tot_income, d
loc mino=r(min)
gen adjusted_tot_incomeFL= adjusted_tot_income-`mino'+1
gen ln_total_income_hVFL=ln(adjusted_tot_incomeFL)

egen total_income_h_impAGS = rowtotal(wage_h y_imp), missing 
g ln_total_income_h_impAGS = ln(total_income_h_impAGS)

// Education
recode educ_hi (1=1) (3=2) (4 5 6 7 = 3) (8 9 = 4), gen(educ_def2_)

lab var educ_def2_ "Level of education"
lab def educ_def2_ 1 "Less than basic" 2 "Basic" 3 "Intermediate" 4 "Advanced"
lab val educ_def2_ educ_def2_

tab educ_def2_, gen(educ_def2_)
lab var educ_def2_1  "Educ: Less than basic"
lab var educ_def2_2  "Educ: Basic"
lab var educ_def2_3  "Educ: Intermediate"
lab var educ_def2_4  "Educ: Advanced"

*recode s04q38 (1 = 0) (2 = 1), gen(informal)
*ta informal, gen(informal_)

reg ln_total_income_hVFL educ_2 educ_3 educ_4 empstat2_2 empstat2_3 empstat2_4  sector2_2 sector2_3 sector2_4 sector2_5  female age agesq  rural informal

g productivity = ln_total_income_hVFL

preserve
keep productivity ln_total_income_h_impAGS educ_2 educ_3 educ_4 empstat2_1 empstat2_2 empstat2_3 empstat2_4 sector2_1 sector2_2 sector2_3 sector2_4 sector2_5  female age agesq  rural informal productivity educ_def2_* wage_ann 
g country = "SEN"
save "${d_raw}\working\SEN_individual_reg.dta", replace
restore

// >>> Workers in WAP --------------
g w_wap = .
replace w_wap = 0 if age>=5
replace w_wap = 1 if age>=15 & w_wap < 66

// >>> Income per hour (INPUTED)
cap drop inc_by_hour
gen inc_by_hour_IMP = total_income_h_impAGS
label var inc_by_hour_IMP "Total income per hour"

// >>> Income per hour 

gen inc_by_hour = total_income_hV2
label var inc_by_hour "Total income per hour"

// >>> Total income 
cap drop inc_d_total
egen inc_d_total = rowmax(total_income_hV2 self_income_pc_h) , 
label var inc_d_total "Total income: Salaried and Self-employed"

// >> Self employed income 
cap drop inc_d_selfw
gen inc_d_selfw = self_incomeV2_pc
label var inc_d_selfw "Self-employed income:"

// >> Salaried income inc_d_salw 
gen inc_d_salw = wage_ann/360/s04q37
label var inc_d_salw "Salaried Income:" 
replace inc_d_salw = . if empstat_ != 2 
replace inc_d_salw = 0 if empstat_ ==2 & inc_d_salw == .

count if inc_d_sal > 0 & inc_d_sal !=.

di "Less than " round(100*r(N)/3435 ,0.001) "% reports income even though they are salaried workers"

// >>> Weekly Hours worked  --------------
cap drop week_hour*
gen week_hour_first  = s04q37 * s04q36 / 4 
gen week_hour_second = s04q55 * s04q56 / 4 
egen week_hours = rowtotal(week_hour*) , m

	* >> Neet
	cap drop neet
	gen neet		= 1 if age >= 15 & age < 65 // Working age
	replace neet	= 0 if empstat_ != . & neet == 1 // Works
	replace neet 	= 0 if neet == 1 & s02q03 == 1 // Study
	
	*s02q03:  2.03.[NOM] a-t-il fait ou fait-il des étude actuellement dans une école formell?

	* >> Main activity 
	cap drop main_acti_sar
	gen main_acti_sar = 0 if age >= 5 
	replace main_acti_sar = 11 if empstat_ != . & main_acti_sar == 0
	replace main_acti_sar = 1 if s02q03 == 1 & main_acti_sar == 0
	
	label define main_acti_sar  0 "Outside of LF" 1 "In School / Training" 2 "Help family B/W" 3 "Farm related"  4 "OPG: Gather" 5 "OPG: Hunt" 6 "OPG: Food preparation" 7 "OPG: Construction" 8 "OPG: Making goods for HH" 9 "OPG: Fetch water firewood" 10 "Family responsibilities"  11 "Employed" 12 "Unemployed" , modify 
	label val main_acti_sar main_acti_sar
	
	
	* >> Main activity components
	tab main_acti , gen(macti_)
	
	gen order_mainacti = main_acti_sar
	recode order_mainacti (11 = -2 ) (12 = -1)
	
	* >>  # Number of kids in the household 
	*gen age = m4 
	gen child_d = n_kids 
	
	gen uno = 1
	
	* Drop income for those outside of the LF
	foreach var in wage_h inc_by_hour_IMP  inc_d_salw inc_d_selfw inc_d_total {
		replace `var' = . if merge_labforce == 1
	}
	
	* desc urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw week_hours neet look_last7 look_last30
* Have not found yet the variables pertaining to search for jobs.
	cap drop ln_inc_by_hour
	gen ln_inc_by_hour	= ln(inc_by_hour+1) // The total income used for this variable is total_income_hV2
	gen ln_inc_d_salw	= ln(inc_d_salw + 1)
	gen ln_inc_d_total	= ln(inc_d_total + 1)
	gen ln_inc_d_selfw	= ln(inc_d_selfw + 1)
	gen ln_inc_by_hour_IMP	= ln(inc_by_hour_IMP +1) // This one uses the adjusted_self_incomeFL variable --> y_imp --> total_income_h_impAGS
	
	label var self_incomeV2_pc "Hourly slef income using lab supply provided per individual"
	
save "${d_raw}\working\SEN_individual_reg_FULL.dta", replace



























