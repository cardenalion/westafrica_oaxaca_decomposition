/*==============================================================================

Project:			World Bank Poverty & Gender Assessment
					Senegal, The Gambia, Muritania

Author:				Sergio Rivera
Email:				riverad.sergio@gmail.com
Email2:				river@umd.edu
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
	ssc install oaxaca , replace
	

	/* The wage gap decomposition is done country by country using the income measure constructed for an independent study.
	*/
	
	*---------------------------- Rundofiles -------------------------------------*	
	
	* The Gambia 
	
	use "${d_raw}\LFS\GMB\The 2022-23 GLFS DATASET.dta", clear
	
	* Income measures from GMBLFS22_23_individualDataset_v2 
	* Edited by SAR: labels 
	
	/*
	Labor income description:
	Salaried workers -------->		FORMAL 
		The salaried  have three different income types: main, in kind (minus costs), secondary 
	Self employed workers --->		INFORMAL
	
	Both types of incomes have been turned into daily income. 
	*/
	
	
	
*-------------------------------------------------------------------------------
*--------------------------- Variables at individual level ---------------------
*-------------------------------------------------------------------------------

// >>> Workers in WAP --------------

* Working Age Population by ILO 
g w_wap = .
replace w_wap = 1 if ilo_wap == 1 & cm5 !=.
replace w_wap = 0 if ilo_wap == . & cm5 !=.
lab var w_wap  "Workers in:  working age population"
lab def w_wap 1 "In" 0 "Out" 
lab val w_wap w_wap


// >>> Employment status --------------
gen empstat_ = 2 if inlist(cm5,1,4)
replace empstat_ = 1 if inlist(cm5,2)
replace empstat_=3 if inlist(cm5,3,5)
lab def empstat_ 1 "Self-employee/own boss" 2 "Salaried workers" 3 "Other workers"
lab val empstat_ empstat_

tab empstat_, gen(empstat_)

lab var empstat_1 "Self-employee/own boss"
lab var empstat_2 "Salaried workers"
lab var empstat_3 "Other workers"

lab var empstat_ "Employment status" // Three categories 

// >>> Family workers --------------
recode cm5 (1 2 4 = 0) (3 5 = 1)  (. = .) , gen(family_w_)
lab def family_w_ 0 "Non family worker" 1 "Family worker" 
lab val family_w_ family_w_

// >>> Daily Income --------------

// >> For salaried workers:
// > Salary (main job)

replace ei2 = . if ei2 == 9999997 | ei2 == 9999999  // *Outliers and missings
g inc_salw_1 = ei2 if ei3 == 2
replace inc_salw_1 = (ei2*52.1786)/360 if ei3 == 3
replace inc_salw_1 = (ei2*(52.1786/2))/360 if ei3 == 4
replace inc_salw_1 = ei2/30 if ei3 == 5

label var inc_salw_1 "Salaried Income: Main Job" 

// > Salary in kind

replace ei7 = . if ei7 == 9999997 | ei7 == 9999999  // *Outliers and missings
g inc_salw_2 = ei7 if ei3 == 2
replace inc_salw_2 = (ei7*52.1786)/360 if ei3 == 3
replace inc_salw_2 = (ei7*(52.1786/2))/360 if ei3 == 4
replace inc_salw_2 = ei7/30 if ei3 == 5

label var inc_salw_2 "Salaried Income: In kind" 

// > Costs to receive goods

replace ei9 = . if ei9 == 9999997  // *Outliers and missings
g inc_salw_2c = -ei9 if ei3 == 2
replace inc_salw_2c = (-ei9*52.1786)/360 if ei3 == 3
replace inc_salw_2c = (-ei9*(52.1786/2))/360 if ei3 == 4
replace inc_salw_2c = -ei9/30 if ei3 == 5

label var inc_salw_2c "Salaried Income: Costs to receive goods" 


// > Salary (secondary activities)

replace ei10 = . if ei10 == 9999997 | ei10 == 9999999  // *Outliers and missings
g inc_salw_3 = ei10/30 // by 30 since the question says "last month"

label var inc_salw_3 "Salaried Income: Secondary activities" 

// >> Sum for salaried workers:

egen inc_d_salw = rowtotal(inc_salw_1 inc_salw_2 inc_salw_2c inc_salw_3), m

label var inc_d_salw "Salaried Income: TOTAL" 


// >> For Self-employee/own boss:
// > Profit (sales and desducting all expenses, main business or activity)

replace ei11 = . if ei11 == 999999 | ei11 == 9999997 | ei11 == 9999999  // *Outliers and missings
g inc_selfw_1 = ei11/30 // by 30 since the question says "last month"

// > Products for HH own use (main business or activity)

replace ei13 = . if ei13 == 9999997 | ei13 == 9999999   // *Outliers and missings
g inc_selfw_2 = ei13/30 // by 30 since the question says "last month"

// > Income/earnings (secondary activity)

replace ei14 = . if ei14 == 9999997 | ei14 == 9999999   // *Outliers and missings
g inc_selfw_3 = ei14/30 // by 30 since the question says "last month"

// >> Sum for Self-employee/own boss:

egen inc_d_selfw = rowtotal(inc_selfw_1 inc_selfw_2 inc_selfw_3), m


label var inc_selfw_1 "Self-employed income: Sales and desducting all expenses, main business or activity"
label var inc_selfw_2 "Self-employed income: Subsistence production value (In kind)"
label var inc_selfw_3 "Self-employed income: Secondary activities"
label var inc_d_selfw "Self-employed income: Total "

// >>> Sum Income

egen inc_d_total = rowtotal(inc_d_salw inc_d_selfw), m

label var  inc_d_selfw "Total income: Salaried + Self-employed"


// >>> Weekly hours worked: wkt8a

// >>> Income per hours

g inc_by_hour =  inc_d_total / ((wkt8a*52.1786)/360) // wkt8a: total hours usually worked weekly 

replace inc_by_hour = . if inc_by_hour == 0 // since in this section there are only paid workers 
count if inc_by_hour==.
g ln_inc_by_hour = ln(1+inc_by_hour)


// >>> Quintiles of income --------------
*egen q5_inc = xtile(inc_by_hour), nq(5)
xtile q5_inc =inc_by_hour, nq(5)
lab def q5_inc 1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5"
lab val q5_inc q5_inc

// >>> Unpaid workers --------------
g unpaid_w = 1 if inlist(empstat_,1,2,3) & inc_d_total == 0
replace unpaid_w = 0 if inlist(empstat_,1,2,3) & inc_d_total > 0

// >>> Unpaid family workers --------------
g unpaid_f_w = 1 if family_w_ == 1 & inc_d_total == 0
replace unpaid_f_w = 0 if inlist(empstat_,1,2,3) & unpaid_f_w == .

// >>> Sector --------------
egen sector = max(ilo_job1_eco_aggregate), by(cm2b)
replace sector = . if cm2b==.
recode sector (1=1) (2=2) (3 4 5 6 7 = 3), gen(sector_)

tab sector_, gen(sector_)
lab var sector_1  "Sector: Agriculture"
lab var sector_2  "Sector: Manufacture"
lab var sector_3  "Sector: Services"

// Sectors for OAXACA regression decomposition 

tab ilo_job1_eco_aggregate , gen(sector10_)

// >>> Firm size ILO --------------
recode cm26 (1 2 = 1) (3 4 5 = 2) (6 = 3), gen(firm_size_)
lab def firm_size_ 1 "Less than 5" 2 "5-49" 3 "50+"
lab val firm_size_ firm_size_
tab firm_size_, gen(firm_size_)
lab var firm_size_1  "Size: Less than 5"
lab var firm_size_2  "Size: 5-49"
lab var firm_size_3  "Size: 50+"

// >>> Firm size WB --------------
recode cm26 (3 4 = 1) (5 = 2) (6 = 3) (1 2 = .), gen(firm_size_WB_)
lab def firm_size_WB_ 1 "Small: 5-19" 2 "Medium: 20-49" 3 "50+"  // Its not possible small= 5-19; medium = 20-99; large = 100+ since the original variable dont has this categories
lab val firm_size_WB_ firm_size_WB_
tab firm_size_WB_, gen(firm_size_WB_)
lab var firm_size_WB_1  "Size: Small: 5-19"
lab var firm_size_WB_2  "Size: Medium: 20-49"
lab var firm_size_WB_3  "Size: 50+"

// >>> Education --------------
recode ed8l (0 . = 1) (1 2 = 2) (3 4 = 3) (5 6 = 4) (97 = .), gen(educ_)

lab var educ_  "Level of education"
lab def educ_ 1 "Less than basic" 2 "Basic" 3 "Intermediate" 4 "Advanced"
lab val educ_ educ_

tab educ_, gen(educ_)
lab var educ_1  "Educ: Less than basic"
lab var educ_2  "Educ: Basic"
lab var educ_3  "Educ: Intermediate"
lab var educ_4  "Educ: Advanced"

* Sex
gen female = ilo_sex == 2 

* Age 
gen age = hl6
gen age_sq = age^2 
	
	
	* Order to check identifiers
	order hh1 hh2  hl1 hl3 hh6 hh7 hh8 hh9 hh10 hh11  hl3x
	desc  hh1 hh2  hl1 hl3 hh6 hh7 hh8 hh9 hh10 hh11  hl3x
	
	***
	tab emp6  
	
	* Unpaid Family workers // unpaid_w
	sum unpaid_w emp6
	tab unpaid_w emp6 , row  
	tab unpaid_w emp6 , col   
	
	replace inc_by_hour = 0 if inc_d_total == 0 
	foreach var in inc_by_hour inc_d_total inc_d_selfw inc_selfw_3 inc_selfw_2 inc_selfw_1  ///
	inc_d_salw inc_salw_1 inc_salw_2 inc_salw_2c inc_salw_3 {
		cap noi  drop ln_`var'
		gen ln_`var' = ln(`var' + 1)
	}
	
	sum inc_by_hour , d
	
	
	*------------------------------------------------------------------------------*
	*--------------------- Regressions --------------------------------------------*
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
	}
	
	
	/*
	What do I see so far?
	Endowments reduce the gap
	
	*/
	
	cumul wkt8a if female == 0 , gen(cum_hw_m)
	cumul wkt8a if female == 1 , gen(cum_hw_f)
	
	replace cum_hw_f = cum_hw_f*100
	replace cum_hw_m = cum_hw_m*100
	
	 twoway (line cum_hw_m wkt8a , sort lwidth(medthin) ) (line cum_hw_f wkt8a , sort lwidth(medthin) ) ,	 legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )  graphregion(fcolor(white) lcolor(white)) plotregion(lcolor(white)) xtitle(Hours)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	