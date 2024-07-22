
use "${d_raw}\LFS\MRT\base_ENESI2017\hl.dta", clear
ren M0 IND1 
ren pond pond_allsample
merge 1:1 I1 I2 IND1 using "${d_raw}\LFS\MRT\base_ENESI2017\emploi.dta"
keep if _merge == 3
rename *, lower


*-------------------------------------------------------------------------------
*--------------------------- Verification---------------------
*-------------------------------------------------------------------------------

g pob =1
ta pob [iw=pond_allsample] if m4 >=15 & m4 <=64

ta ap3 [iw=pond_allsample],nol m

*-------------------------------------------------------------------------------
*--------------------------- Variables at individual level ---------------------
*-------------------------------------------------------------------------------

// >>> Employment status --------------
recode ap3 (1 2 3 4 5 = 2) (6 7 = 1) (8 9 10 11 = 3) (. = .) , gen(empstat_)
lab def empstat_ 1 "Self-employee/own boss" 2 "Salaried workers" 3 "Other workers"
lab val empstat_ empstat_


tab empstat_, gen(empstat_)

lab var empstat_1 "Self-employee/own boss"
lab var empstat_2 "Salaried workers"
lab var empstat_3 "Other workers"
// >>> Weekly Hours worked  --------------

**Main activity: ap10c
**Secondary activity: as2b1 as2b2 damaged . as13b1 as13b2 Workers

egen week_hours = rowtotal(ap10c), m

*egen week_hours = rowtotal(ap10c as13b1 as13b2), m
// >>> Daily Income --------------

replace ap13a2 = . if ap13a2==9999
g inc_d_total = ap13a2/30

// >>> Income per hours

g inc_by_hour =  inc_d_total / ((week_hours*52.1786)/360)

replace inc_by_hour = . if inc_by_hour == 0 // since in this section there are only paid workers 

g ln_inc_by_hour = ln(1+inc_by_hour)

// >>> Education --------------
recode m11 (. = 1) (1  = 2) (2 = 3) (6 3 = 4) (4 5 = .), gen(educ_)

lab var educ_  "Level of education"
lab def educ_ 1 "Less than basic" 2 "Basic" 3 "Intermediate" 4 "Advanced"
lab val educ_ educ_

// >>> Sector --------------

replace ap2ac = " " if ap2ac == "55" | ap2ac == "99999" | ap2ac == "??" 

gen isic_clean = substr(ap2ac, 2, .)

destring isic_clean, replace force

gen sector_ = ""

* Agriculture: ISIC codes starting from 0111 to 0322
replace sector_ = "Agriculture" if inrange(isic_clean, 111, 322)

* Manufacture: ISIC codes starting from 1010 to 3320
replace sector_ = "Manufacture" if inrange(isic_clean, 1010, 3320)

* Services: ISIC codes starting from 3510 to 9900
replace sector_ = "Services" if inrange(isic_clean, 3510, 9900)


tab sector_, gen(sector_)
lab var sector_1  "Sector: Agriculture"
lab var sector_2  "Sector: Manufacture"
lab var sector_3  "Sector: Services"

*-------------------------------------------------------------------------------
*--------------------------- Graphs ---------------------
*-------------------------------------------------------------------------------
cap noi mkdir "${dir_out}/Graphs/MRT"

*Employment composition 

*----------
graph pie empstat_1 empstat_2 empstat_3 [aw=pond_allsample], ///
	plabel(_all percent) ///
	legend(lab(1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers") pos(6) col(2))
graph export "${dir_out}/Graphs/MRT\MRT_pie_composition_workers_2021.png", replace
*----------

*Sectoral composition 

*----------
graph pie sector_1 sector_2 sector_3 [aw=pond_allsample], ///
	plabel(_all percent) ///
	legend(lab(1 "Agriculture") lab(2 "Manufacture") lab(3 "Services") pos(6) col(2))
graph export "${dir_out}/Graphs/MRT\\MRT_pie_composition_sector_workers_2021.png", replace
*----------

// Productivity -----------------------------------

sum ln_inc_by_hour, meanonly
local min_income = r(min)

*Number of workers
g productivity = ln(1+(ln_inc_by_hour - `min_income'))
*Outliers
winsor2 productivity, replace cuts(1 99)

*----------
twoway kdensity productivity if empstat_1 == 1  || kdensity productivity if empstat_2==1 || kdensity productivity if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers"))  $grph_reg
graph export "${dir_out}/Graphs/MRT\MRT_kd_estimated_status.png", replace 
*----------

*----------
twoway kdensity productivity if sector_1 == 1  || kdensity productivity if sector_2==1 || kdensity productivity if sector_3==1, legend(lab (1 "Agriculture") lab(2 "Manufacture") lab(3 "Services"))  $grph_reg
graph export "${dir_out}/Graphs/MRT\MRT_kd_estimated_sector.png", replace
*----------


ta empstat_ sector_  [iw=pond_allsample] , col row 


*-------------------------------------------------------------------------------
*---------------------Regressions------------------------------
*-------------------------------------------------------------------------------
/*
ta educ_, gen(educ_)

recode m3 (2 = 1) (1 = 0), gen(female_)
ta female_, gen(female_)

recode cm22 (1 = 0) (2 97 = 1), gen(informal)
ta informal, gen(informal_)

ren ln_inc_by_hour productivity

recode hh7 (1 = 0) (2 = 1), gen(rural)
ta rural, gen(rural_)

recode hl4 (1 = 0) (2 = 1), gen(female)
ta female, gen(female_)

g agesq=ilo_age*ilo_age
ren m4 age
g agesq = age * age

recode ap8d (5 =1) (1 2 3 4 = 0), gen(informal_)
ta informal_, gen(informal_)

reg productivity educ_2 educ_3 educ_4 empstat_2 empstat_3 sector_2 sector_3 i.female_ age agesq  


preserve
ren female_2 female
keep productivity educ_2 educ_3 educ_4 empstat_2 empstat_3 sector_2 sector_3 female age agesq informal_2
g country = "MRT"
save "${root1}Dataout\MRT\individual_reg.dta", replace
restore
*/






* Status of employment
twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers"))
graph export "${dir_out}/Graphs/MRT\kd_estimated_status.png", replace

twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers")) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_status_educ.png", replace

/* Continue from here 
twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers")) by(hh7)
graph export "${root1}Outputs\Figures\GMB\kd_estimated_status_area.png", replace
* SIGNAL MISTAKE for them


*-------------------------------------------------------------------------------
*--------------------------- Variables at individual level ---------------------
*-------------------------------------------------------------------------------

// >>> Workers in WAP --------------

g w_wap = .
replace w_wap = 1 if ilo_wap == 1 & cm5 !=.
replace w_wap = 0 if ilo_wap == . & cm5 !=.
lab var w_wap  "Workers in WAP"
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

// > Salary in kind

replace ei7 = . if ei7 == 9999997 | ei7 == 9999999  // *Outliers and missings
g inc_salw_2 = ei7 if ei3 == 2
replace inc_salw_2 = (ei7*52.1786)/360 if ei3 == 3
replace inc_salw_2 = (ei7*(52.1786/2))/360 if ei3 == 4
replace inc_salw_2 = ei7/30 if ei3 == 5

// > Costs to receive goods

replace ei9 = . if ei9 == 9999997  // *Outliers and missings
g inc_salw_2c = -ei9 if ei3 == 2
replace inc_salw_2c = (-ei9*52.1786)/360 if ei3 == 3
replace inc_salw_2c = (-ei9*(52.1786/2))/360 if ei3 == 4
replace inc_salw_2c = -ei9/30 if ei3 == 5

// > Salary (secondary activities)

replace ei10 = . if ei10 == 9999997 | ei10 == 9999999  // *Outliers and missings
g inc_salw_3 = ei10/30 // by 30 since the question says "last month"

// >> Sum for salaried workers:

egen inc_d_salw = rowtotal(inc_salw_1 inc_salw_2 inc_salw_2c inc_salw_3), m

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

// >>> Sum Income

egen inc_d_total = rowtotal(inc_d_salw inc_d_selfw), m

// >>> Weekly hours worked: wkt8a

// >>> Income per hours

g inc_by_hour =  inc_d_total / ((wkt8a*52.1786)/360)

replace inc_by_hour = . if inc_by_hour == 0 // since in this section there are only paid workers 

g ln_inc_by_hour = ln(1+inc_by_hour)


// >>> Quintiles of income --------------
egen q5_inc = xtile(inc_by_hour), nq(5)
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

// when we tab cross the highest degree with current level of education there is a match between missings in highest degree and ECE. Therefore the construction only needs edl8.

// >>> Informality (pending)





*-------------------------------------------------------------------------------
*--------------------------- Graphs ---------------------
*-------------------------------------------------------------------------------

* Status of employment
twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers"))
graph export "${dir_out}/Graphs/MRT\kd_estimated_status.png", replace

twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers")) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_status_educ.png", replace

twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers")) by(hh7)
graph export "${dir_out}/Graphs/MRT\kd_estimated_status_area.png", replace

** Sector 

twoway kdensity ln_inc_by_hour if sector_1 == 1  || kdensity ln_inc_by_hour if sector_2 == 1 || kdensity ln_inc_by_hour if sector_3 == 1, legend(lab (1 "Agriculture") lab(2 "Manufacture") lab(3 "Services"))
graph export "${dir_out}/Graphs/MRT\kd_estimated_sector.png", replace

twoway kdensity ln_inc_by_hour if sector_1 == 1  || kdensity ln_inc_by_hour if sector_2==1 || kdensity ln_inc_by_hour if sector_3==1, legend(lab (1 "Agriculture") lab(2 "Manufacture") lab(3 "Services")) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_sector_educ.png", replace

twoway kdensity ln_inc_by_hour if sector_1 == 1  || kdensity ln_inc_by_hour if sector_2==1 || kdensity ln_inc_by_hour if sector_3==1, legend(lab (1 "Agriculture") lab(2 "Manufacture") lab(3 "Services")) by(hh7)
graph export "${dir_out}/Graphs/MRT\kd_estimated_sector_area.png", replace

* Firm size

twoway kdensity ln_inc_by_hour if firm_size_1 == 1  || kdensity ln_inc_by_hour if firm_size_2 == 1 || kdensity ln_inc_by_hour if firm_size_3 == 1, legend(lab (1 "Less than 5") lab(2 "5-49") lab(3 "50+"))
graph export "${dir_out}/Graphs/MRT\kd_estimated_size.png", replace

twoway kdensity ln_inc_by_hour if firm_size_1 == 1  || kdensity ln_inc_by_hour if firm_size_2 == 1 || kdensity ln_inc_by_hour if firm_size_3 == 1, legend(lab (1 "Less than 5") lab(2 "5-49") lab(3 "50+")) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_size_educ.png", replace

twoway kdensity ln_inc_by_hour if firm_size_1 == 1  || kdensity ln_inc_by_hour if firm_size_2 == 1 || kdensity ln_inc_by_hour if firm_size_3 == 1, legend(lab (1 "Less than 5") lab(2 "5-49") lab(3 "50+")) by(hh7)
graph export "${dir_out}/Graphs/MRT\kd_estimated_size_area.png", replace

*Informality

twoway kdensity ln_inc_by_hour if ilo_job1_ife_prod == 1  || kdensity ln_inc_by_hour if ilo_job1_ife_prod == 2 || kdensity ln_inc_by_hour if ilo_job1_ife_prod == 3, legend(lab (1 "Informal") lab(2 "Formal") lab(3 "Households "))
graph export "${dir_out}/Graphs/MRT\kd_estimated_inf_unit_prod.png", replace

twoway kdensity ln_inc_by_hour if ilo_job1_ife_prod == 1  || kdensity ln_inc_by_hour if ilo_job1_ife_prod == 2 || kdensity ln_inc_by_hour if ilo_job1_ife_prod == 3, legend(lab (1 "Informal") lab(2 "Formal") lab(3 "Households ")) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_inf_unit_prod_educ.png", replace

twoway kdensity ln_inc_by_hour if ilo_job1_ife_prod == 1  || kdensity ln_inc_by_hour if ilo_job1_ife_prod == 2 || kdensity ln_inc_by_hour if ilo_job1_ife_prod == 3, legend(lab (1 "Informal") lab(2 "Formal") lab(3 "Households ")) by(hh7)
graph export "${dir_out}/Graphs/MRT\kd_estimated_inf_unit_prod_area.png", replace


twoway kdensity ln_inc_by_hour if ilo_job1_ife_nature == 1  || kdensity ln_inc_by_hour if ilo_job1_ife_nature == 2 , legend(lab (1 "Informal") lab(2 "Formal") )
graph export "${dir_out}/Graphs/MRT\kd_estimated_inf_nat_job.png", replace

twoway kdensity ln_inc_by_hour if ilo_job1_ife_nature == 1  || kdensity ln_inc_by_hour if ilo_job1_ife_nature == 2 , legend(lab (1 "Informal") lab(2 "Formal") ) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_inf_nat_job_educ.png", replace

twoway kdensity ln_inc_by_hour if ilo_job1_ife_nature == 1  || kdensity ln_inc_by_hour if ilo_job1_ife_nature == 2 , legend(lab (1 "Informal") lab(2 "Formal") ) by(hh7)
graph export "${dir_out}/Graphs/MRT\kd_estimated_inf_nat_job_area.png", replace

*Area
twoway kdensity ln_inc_by_hour if hh7 == 1  || kdensity ln_inc_by_hour if hh7 == 2 , legend(lab (1 "Urban") lab(2 "Rural") ) 
graph export "${dir_out}/Graphs/MRT\kd_estimated_area.png", replace

twoway kdensity ln_inc_by_hour if hh7 == 1  || kdensity ln_inc_by_hour if hh7 == 2 , legend(lab (1 "Urban") lab(2 "Rural") ) by(educ_)
graph export "${dir_out}/Graphs/MRT\kd_estimated_area_educ.png", replace

**
twoway kdensity ln_inc_by_hour if w_wap == 0  || kdensity ln_inc_by_hour if w_wap == 1 , legend(lab (1 "Out WAP") lab(2 "In WAP") ) 
graph export "${dir_out}/Graphs/MRT\kd_estimated_WAP.png", replace



*-------------------------------------------------------------------------------
*--------------------------- Analysis WAP-No WAP, unpaid family workers---------------------
*-------------------------------------------------------------------------------
**# Bookmark #2

ta w_wap [iw= ilo_wgt ] // 5,02% of workers are out WAP = child labor

ta empstat_ w_wap [iw= ilo_wgt ], col nofreq // Approximately 40% of outside WAP workers are self-employed or salaried, while 94% of WAP workers are

ta educ_ w_wap [iw= ilo_wgt ], col nofreq // 

ta hh7 w_wap [iw= ilo_wgt ], col nofreq

bys sector_: ta unpaid_w hh7 [iw= ilo_wgt ], col row

ta sector_ w_wap [iw= ilo_wgt ], nofreq col // Outside WAP workers are mostly in the agriculture sector, while most WAP workers are in the services sector

ta unpaid_w w_wap [iw= ilo_wgt ], col nofreq // 22.43% of all workers are unpaid  workers. 54.94% of out WAP workers are unpaid workers, while 20.71% are unpaid family workers in WAP. 

ta unpaid_w empstat_ [iw= ilo_wgt ], col nofreq 

ta unpaid_f_w w_wap [iw= ilo_wgt ], col nofreq // 5.03% of all workers are unpaid family workers. 40.38% of out WAP workers are unpaid family workers, while only 3.16% are unpaid family workers in WAP. 

bys w_wap: mdesc inc_d_total
countvalues inc_d_total if w_wap == 1, values(0 .) // 569/1063 = 54% has ceros in income variable 'out' WAP - child labor

