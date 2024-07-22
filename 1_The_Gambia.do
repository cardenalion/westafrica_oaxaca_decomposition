	use "${d_raw}\LFS\GMB\The 2022-23 GLFS DATASET.dta", clear
	
	* Income measures from GMBLFS22_23_individualDataset_v2 
	* Edited by Sergio Rivera
	
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

label var  inc_d_total "Total income: Salaried and Self-employed"


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

	recode educ_* ( 1 0  = . ) if age < 15 // Education only for those in working age. 

	* >> Sex
	gen female = ilo_sex == 2 

	* >> Age 
	gen age = hl6
	gen age_sq = age^2 
		
	
	* Order to check identifiers
	order hh1 hh2  hl1 hl3 hh6 hh7 hh8 hh9 hh10 hh11  hl3x
	desc  hh1 hh2  hl1 hl3 hh6 hh7 hh8 hh9 hh10 hh11  hl3x
	
	***
	tab emp6  
	
	* >> Unpaid Family workers // unpaid_w
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
	
	* >> Unemployment 	
	cap drop d_look4job
	gen d_look4job = ( js1 == 1 |js2 == 1 ), 
	*replace d_look4job = . if js1 == . & js2 == . 
	tab d_look4job [aw=ilo_wgt] 
	label var  d_look4job "Dummy: Looking for a job"
	
	tab d_look4job ilo_wap
	tab age ilo_wap 
	
	* >> ILO_LFS: Labor force status defined by ILO
	tab ilo_lfs
	sum age if ilo_lfs == 3
	
	* tr4: Attend formal or non-formal training in last 12 months
	* ed6: Currently attending school
	* ilo_lfs: Labour Force Status
	
	cap drop neet
	gen neet = 0 if age >= 15 & age < 65 
	replace neet = 1 if ( ilo_lfs ==  3 | ilo_lfs == 2 ) & (ed6 == 2 ) & neet == 0 & (tr4 == .) & (d_look4job == 0)
	label var neet "Person not employed, in eduaction, or training. Age 15-65"
	
	* >> Define labor force participation  myself (include people producing in their own farms and or family business )
	gen salaried		= emp4 
	gen selfemp			= emp5 
	replace selfemp 	= 1 if emp11 == 1 
	
	gen help_fami		= emp6
	gen tempo_leave		= emp7
	replace tempo_leave = 0 if inlist( emp9 , 2 ,97)
	replace tempo_leave = 1 if emp10  == 1
	
	cap noi drop temp_farm	
	gen temp_farm		= inlist(emp12 , "A" , "AB" , "B" , "C" ) 
	replace temp_farm	= . if emp12 == ""
	replace temp_farm	= 1 if emp13 != "" 
	
	* >> Labor Force Participation (Employed, working at home, looking for a job) 
	cap drop lfp_sar
	gen lfp_sar 		= 0 if age >= 15 
	replace lfp_sar 	= 1 if lfp_sar == 0 & (  salaried == 1 | selfemp ==  1 | tempo_leave == 1 )
	replace lfp_sar		= 2 if d_look4job == 1 & lfp_sar == 0
	
	cap drop lfp_plus_domestic
	gen lfp_plus_domestic 		= lfp_sar
	replace lfp_plus_domestic	= 4 if temp_farm == 1  & ( lfp_plus_domestic == 0 |   lfp_plus_domestic == .)
	replace lfp_plus_domestic	= 4 if ( emp13a == 1 | emp13b == 1 | emp13c == 1 | emp13d == 1 ) & ( lfp_plus_domestic == 0 |  lfp_plus_domestic == .)
	replace lfp_plus_domestic	= 1 if ( cm1 == 1 |  cm1 == 2 ) & ( lfp_plus_domestic == 0 | lfp_plus_domestic == .)
	replace lfp_plus_domestic	= 5 if help_fami == 1 & ( lfp_plus_domestic == 0 |  lfp_plus_domestic == .)
	replace lfp_plus_domestic	= 1 if inc_d_total > 10 & inc_d_total != . & ( lfp_plus_domestic == 0 |  lfp_plus_domestic == .)
	
	replace lfp_plus_domestic	= 6 if opg1 == 1 & ( lfp_plus_domestic == 0 |  lfp_plus_domestic == .)
	replace lfp_plus_domestic	= 7 if opg3 == 1 & ( lfp_plus_domestic == 0 |  lfp_plus_domestic == .)
	
	label define lfp_sar  0 "Outside of LF" 1 "Employed" 2 "Unemployed" 4 "Farm related" 5 "Help family" 6 "OPG: Gather" 7 "OPG: Hunt" , modify 
	label val lfp_sar lfp_sar
	label val lfp_plus_domestic lfp_sar
	
	tab lfp_sar				[iw = ilo_wgt ]
	tab lfp_plus_domestic	[iw = ilo_wgt ]
	
	tab lfp_plus_domestic [iw = ilo_wgt ] if age > 17 & age < 65
	bys female : tab lfp_plus_domestic [iw = ilo_wgt ] if age > 17 & age < 65
	
	bys female : tab js5 [ iw = ilo_wgt ] if age > 17 & age < 65 & lfp_plus_domestic == 0
	bys female : tab js5 if age > 17 & age < 65 & lfp_plus_domestic == 0
	
	bys female : tab js8 [ iw = ilo_wgt ] if age > 17 & age < 65 & lfp_plus_domestic == 0
	bys female : tab js8 if age > 17 & age < 65 & lfp_plus_domestic == 0
	
	/* Employment battery questions:
		EMP4. Last week, from last (Monday) up to (Sunday), did (you/NAME) work for someone else for pay, for one or more hours?
		YES 1 →CM1
		NO 2
		EMP5. Last week, did (you/NAME) run or do any kind of business, farming or other activity to generate income?
		YES 1→ EMP13
		NO 2
		EMP6. Last week, did (you/NAME) help in a family business or farm?
		YES 1→ EMP13
		NO 2
		EMP7. (Do/does) (you/NAME) have a paid job or income generating activity, but (were/was) did not work last week?
		YES 1
		NO 2→EMP12
		EMP8. Why were you absent from your work in the last week?
		EMP9. Including the time that (you/NAME) (have/has) been absent, will (you/he/she) return to that same job or business in 3 months or less?
	(Waiting for a new job to start does not count as temporary
	absences)
		EMP10. (Do/Does) (you/NAME) continue to receive an income from (your/his/her) job or business during this absence? 
		EMP11. During the low or off-season, (do/does) (you/NAME) continue to do some work for that job or business?
		EMP12. Last week, did (you/NAME) do any work in… ? FARMING /REARING FARM ANIMALS / FISHING OR FISH FARMING / NONE OF THE ABOVE
		EMP13. Was this work that you mentioned in…? FARMING / REARING FARM ANIMALS / [FISHING OR FISH FARMING] / ANOTHER TYPE OF JOB OR BUSINESS
		EMP14. Thinking about the work in (farming, rearing animals [and/or fishing]) (you/NAME) (do/does), are the products intended…… ?
		ONLY FOR SALE/EXCHANGE 1→CM1
		MAINLY FOR SALE/EXCHANGE 2→CM1
		MAINLY FOR FAMILY USE 3
		ONLY FOR FAMILY USE 4

		EMP15. (Were/Was) (you/NAME) hired by someone else to do this work?
		EMP16. What are the main products from (farming, rearing animals, [and/or fishing]) that (you/NAME) was/were working on? 
		EMP17. Last week, on how many days did (you/NAME) do this work?
		EMP18. How many hours per day did (you/NAME) spend doing this last week? 
	*/
	
	
	
	
	
	
	
	
	
	
	
	
	
*------------------------------------------------------------------------------*
*--------------------------- Descriptive Stats --------------------------------*
*------------------------------------------------------------------------------*
	
	/* Variables included for descriptive statistics:
	
	inc_by_hour: Total income per hour.  
	inc_d_total: Total income: Salaried + Self-employed 
	inc_d_selfw: Self-employed income: Total
	inc_selfw_3 
	inc_selfw_2 
	inc_selfw_1 
	inc_d_salw: Salaried Income: TOTAL
	inc_salw_1 
	inc_salw_2 
	inc_salw_2c : cost of in kind
	inc_salw_3
	HOURS USUALLY WORKED : wkt1 wkt3 wkt6 wkt8a : main, seconday, other, total
	
	UNEMPLOYMENT: js1 js2
	
	Informality: ilo_job1_ife_prod
	
	Area: hh7 : rural - urban
	
	w_wap: Working age population 
	
	Education: educ_1 educ_2 educ_3 educ_4
	*/
	
	recode js1 js2 (2=0) 
	gen obs = 1
	gen uno  =1
	
	* Total 
preserve 
recode female neet js1 js2  (1 = 100)
	collapse (mean) hh7 w_wap female inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2 educ_1 educ_2 educ_3 educ_4 (sum) uno (rawsum) obs [ iweight = ilo_wgt], 
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("Total" , replace)  firstrow(varl)
restore 

	* By AREA
preserve 
recode female neet js1 js2  (1 = 100)
	collapse (mean) w_wap female inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2 educ_1 educ_2 educ_3 educ_4 (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( hh7 )
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("By area" , replace)  firstrow(varl)
restore 

	* By AREA sex 
preserve 
recode female neet js1 js2  (1 = 100)
	collapse (mean) w_wap inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2 educ_1 educ_2 educ_3 educ_4 (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( hh7 female)
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("By area sex" , replace)  firstrow(varl)
restore 
	
	* By sex 
	preserve 
recode female neet js1 js2  (1 = 100)
	collapse (mean) hh7 w_wap inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2 educ_1 educ_2 educ_3 educ_4 (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( female)
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("By sex" , replace)  firstrow(varl)
restore 










*------------------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
*------------------------------------------------------------------------------*	
*------------------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
*------------------------------------------------------------------------------*

** Hours worked CDF
	sort female wkt8a
	cap drop cum_hw_m cum_hw_f
	cumul wkt8a if female == 0 , gen(cum_hw_m) eq
	cumul wkt8a if female == 1 , gen(cum_hw_f) eq
	
	replace cum_hw_f = cum_hw_f*100
	replace cum_hw_m = cum_hw_m*100
	
	sum wkt8a  [ aweight = ilo_wgt ] if female == 1 
		qui local mu_f = round(`r(mean)', 1)
		qui local vr_f = round(`r(sd)', 1)

	sum wkt8a  [ aweight = ilo_wgt ] if female == 0 
		qui local mu_m = round(`r(mean)', 1)
		qui local vr_m = round(`r(sd)', 1)
		
	twoway (line cum_hw_m wkt8a if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) (line cum_hw_f wkt8a , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ,	 $grph_reg $y_axis legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )  xtitle(Hours) xtitle("# Hours worked" ) ytitle("% below # of hours") note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (vsmall) position(11) ring(0) margin(medlarge)) subti("The Gambia")  ylabel( 0(20)100, labsize(small)) xlabel( 0(20)180 , labsize(small))

	 graph export "${dir_out}/Graphs/1. Hours worked by sex GMB.png",  as(png)    replace width(1995)  height(1452)
	
	
** Income 
label var inc_by_hour "Total income per hour"
*label var inc_d_total "Total income"

	foreach inc in  inc_by_hour inc_d_total inc_d_selfw inc_d_salw {
		local vrlab = `"`: var label `inc' '"'
		local vrlab = subinstr("`vrlab'",":","",.)
		
		sort female ln_`inc'
		cap drop cum_hw_m cum_hw_f
		cumul ln_`inc' if female == 0 , gen(cum_hw_m) eq
		cumul ln_`inc' if female == 1 , gen(cum_hw_f) eq
		
		replace cum_hw_f = cum_hw_f*100
		replace cum_hw_m = cum_hw_m*100
		
		sum `inc'  [ aweight = ilo_wgt ] if female == 1 
			qui local mu_f = round(`r(mean)', 1)
			qui local vr_f = round(`r(sd)', 1)

		sum `inc'  [ aweight = ilo_wgt ] if female == 0 
			qui local mu_m = round(`r(mean)', 1)
			qui local vr_m = round(`r(sd)', 1)
			
		twoway (line cum_hw_m ln_`inc' if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) (line cum_hw_f ln_`inc' , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ,	 $grph_reg $y_axis legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )  xtitle(Hours) xtitle("`vrlab' in logs" ) ytitle("%") note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (vsmall) position(11) ring(0) margin(medlarge)) subti("The Gambia")  
		*ylabel( 0(20)100, labsize(small)) xlabel( 0(20)180 , labsize(small))

		graph export "${dir_out}/Graphs/1. `vrlab' by sex GMB.png",  as(png)    replace width(1995)  height(1452)
		
	cap drop fx x fx_f fx_m 
	kdensity ln_`inc'  [ aweight = ilo_wgt ] if uno ==1  `limit', nograph generate(x fx)
	kdensity ln_`inc'  [ aweight = ilo_wgt ] if female == 1 `limit' , nograph generate(fx_f) at(x) `bw'
	kdensity ln_`inc'  [ aweight = ilo_wgt ] if female == 0 `limit' , nograph generate(fx_m) at(x) `bw'
		* local bw = "bw(.19)"
		
		twoway (area fx_m x, fcolor("${color3}%30") lcolor("${color3}%60")) (area fx_f x, fcolor("${color2}%30") lcolor("${color2}%60") ) if uno == 1 `bnd' , name(`inc' , replace)  $grph_reg $y_axis ytitle(" " )  xtitle("`vrlab' in logs", size(small))  legend(order( 1 "Males" 2 "Females" )  region(lcolor(white)) size(small)) ylabel(, noticks nolabels) note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (vsmall) position(11) ring(0) margin(medlarge))
		
		graph export "${dir_out}/Graphs/2. Kernel `vrlab' by sex GMB.png",  as(png)    replace width(1995)  height(1452)
	}
	
	
	
	
		
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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	