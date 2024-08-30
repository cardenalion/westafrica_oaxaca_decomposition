*	World Bank Poverty & Gender Assessment
*	Guinea Bisao
*	Sergio Rivera 
*	Non-agricultural income. Enterprises.

*	Following: Author: Sarango-Iturralde Alexander
*	Last modified: May 21, 2024



use "${d_raw}\EHCVM\GNB\Datain\Menage\s10b_me_GNB2021.dta", clear
ren s10q15__0 s01q00a	
merge m:1 grappe menage s01q00a using "${d_raw}\working\GNB_individual_2.dta"

*drop if _merge==2
keep if _merge==3
// daily income  ----------------------------------

foreach var in s10q48 s10q50 s10q49 s10q51 s10q52 s10q53 s10q54 s10q56  s10q57 {
    replace `var' = 0 if missing(`var')
}

g income_noagr_d_2 = ((s10q48 + s10q50) - (s10q49 + s10q51 +s10q52 + s10q53 + s10q54 + (s10q56/12) + (s10q57/12)))/30 // Sales of products and services minus costs (net) Daily


// Number of workers per HH enteprises -----------------------------------

*Correction of owners considered as family workers
forvalues i = 1/20 {
	replace s10q61a_`i' = 0 if s10q61_`i' == s01q00a
}

*Family workers
egen total_fam_workers = rowtotal(s10q61a_*)
replace total_fam_workers = total_fam_workers + 1 // add to owner

*Paid workers
egen total_paid_workers = rowtotal(s10q62a_*)

*Total workers
egen total_workers = rowtotal(total_fam_workers total_paid_workers)

ta total_workers

// Number of hours per HH enteprises -----------------------------------

*Hours of family workers
gen total_h_fam_workers = 0
forvalues i = 1/20 {
    replace total_h_fam_workers = (total_h_fam_workers + (s10q61b_`i' * s10q61c_`i' * s10q61d_`i'))/360 if total_h_fam_workers == 0 
	replace total_h_fam_workers = 0 if total_h_fam_workers == .
}

*Hours of paid workers
gen total_h_paid_workers = 0
forvalues i = 1/4 {
    replace total_h_paid_workers = (total_h_paid_workers + (s10q62b_`i' * s10q62c_`i' ))/30 if total_h_paid_workers == 0
	replace total_h_paid_workers = 0 if total_h_paid_workers == .
}

*Total hours
egen total_hours = rowtotal(total_h_fam_workers total_h_paid_workers)
replace total_hours = hours if total_hours == 0 & s01q00a != .

// Salaries paid per day by HH enterprises -----------------------------------

egen total_d_salary_paid = rowtotal(s10q62d_1 s10q62d_2 s10q62d_3 s10q62d_4)
replace total_d_salary_paid = total_d_salary_paid/30

// Productivity -----------------------------------

sum income_noagr_d, meanonly
local min_income = r(min)

*Number of workers
g productivity_a = ln(1+((income_noagr_d_2 - `min_income') / total_workers))
*Outliers
winsor2 productivity_a, replace cuts(1 99)

*Number of hours
g productivity_b = ln(1+((income_noagr_d_2 - `min_income') / total_hours))
*Outliers
winsor2 productivity_b, replace cuts(1 99)

// Size of enterprises -----------------------------------

g size_enterprise = .
replace size_enterprise = 1 if inlist(total_workers,1)
replace size_enterprise = 2 if inlist(total_workers,2)
replace size_enterprise = 3 if inlist(total_workers,3)
replace size_enterprise = 4 if total_workers > 3

lab def size_enterprise 1 "1 worker" 2 "2 workers" 3 "3 workers" 4 "More than 3 workers" 
lab val size_enterprise size_enterprise


// Gender -----------------------------------
lab var female "Gender"
lab def female 0 "Male" 1 "Female" 
lab val female female

// Employment status -----------------------------------
*lab var empstat_ "Employment status"
*lab def empstat_ 1 "Self-employee/own boss" 2 "Salaried workers" 3 "Other workers" 
*lab val empstat_ empstat_

// Sector -----------------------------------
*lab var sector_ "Sector"
*lab def sector_ 1 "Agriculture" 2 "Manufacture" 3 "Services" 
*lab val sector_ sector_

// Education
recode educ_hi (1 2=1) (3 =2) (4 5 6 = 3) ( 7 8 9 = 4), gen(educ_def2_)

lab var educ_def2_ "Level of education"
lab def educ_def2_ 1 "Less than basic" 2 "Basic" 3 "Intermediate" 4 "Advanced"
lab val educ_def2_ educ_def2_

tab educ_def2_, gen(educ_def2_)
lab var educ_def2_1  "Educ: Less than basic"
lab var educ_def2_2  "Educ: Basic"
lab var educ_def2_3  "Educ: Intermediate"
lab var educ_def2_4  "Educ: Advanced"

// Informality
*"We exclude s10q32 'Les personnes qui travaillent dans cette entreprise sont-elles enregistrées à la CNPS?' because only 25 businesses answered 'yes.' This does not make it possible to measure the informal extensive margin."
g informal = 0 if s10q30 == 1 | s10q31 == 1 
replace informal = 1 if informal == .
tab informal , gen(informal_)
label var informal_2 "Informal enterprise"

g informal2 = 0 if s10q30 == 1 & s10q31 == 1 
replace informal2 = 1 if informal2 == .
tab informal2 , gen(informal2_)
label var informal2_2 "Informal enterprise"

// >>> Workers in WAP --------------
g w_wap = .
replace w_wap = 0 if age>=5
replace w_wap = 1 if age>=15 & w_wap < 66




save "${d_raw}\working\GNB_na_firm2021.dta", replace




