* World Bank Poverty & Gender Assessment
* The Gambia
* Sergio Rivera 

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

cap noi mkdir "${dir_out}/Tables/GMB"
cap noi mkdir "${dir_out}/Graphs/GMB"


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

label var inc_d_salw "Salaried Income: Total" 


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
	label define sex_fem  0 "Male" 1 "Female" , modify
	label val female sex_fem 
	
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
	gen lfp_sar 		= 0 if age >= 5 
	replace lfp_sar 	= 1 if lfp_sar == 0 & (  salaried == 1 | selfemp ==  1 | tempo_leave == 1 )
	replace lfp_sar		= 2 if d_look4job == 1 & lfp_sar == 0
	
	label define lfp_sar  0 "Outside of LF" 1 "Employed" 2 "Unemployed" , modify 
	label val lfp_sar lfp_sar 
	
		
		
	* >> Main activity 
	cap drop main_acti_sar
	gen main_acti_sar 		= lfp_sar
	
	recode main_acti_sar ( 1 = 11 ) ( 2 = 12 )
	
	replace main_acti_sar	= 11 if ( cm1 == 1 |  cm1 == 2 ) & ( main_acti_sar == 0 | main_acti_sar == .)
	replace main_acti_sar	= 11 if inc_d_total > 10 & inc_d_total != . & ( main_acti_sar == 0 |  main_acti_sar == .) // It is good that no replace takes place. Since we have cover the employment questions. 
	
	* OLF: Reasons  
	replace main_acti_sar	= 1 if js8 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .) // In School / Training
	replace main_acti_sar	= 1 if ed6 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	replace main_acti_sar	= 1 if tr4 != . & ( main_acti_sar == 0 |  main_acti_sar == .)
	
	replace main_acti_sar	= 2 if help_fami == 1 & ( main_acti_sar == 0 |  main_acti_sar == .) // help in a family business or farm?
	replace main_acti_sar	= 3 if temp_farm == 1  & ( main_acti_sar == 0 |   main_acti_sar == .) // work in… ? FARMING /REARING FARM ANIMALS 
	replace main_acti_sar	= 3 if ( emp13a == 1 | emp13b == 1 | emp13c == 1 | emp13d == 1 ) & ( main_acti_sar == 0 |  main_acti_sar == .) // this work that you mentioned in…? FARMING / REARING FARM ANIMALS / [FISHING OR FISH FARMING] / ANOTHER TYPE OF JOB OR BUSINESS
	
	replace main_acti_sar	= 4 if opg1 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	replace main_acti_sar	= 5 if opg3 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	
	replace main_acti_sar	= 6 if opg5 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	replace main_acti_sar	= 7 if opg7 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	replace main_acti_sar	= 8 if opg9 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	replace main_acti_sar	= 9 if ( opg11 == 1 | opg13 == 1 ) & ( main_acti_sar == 0 |  main_acti_sar == .)
	replace main_acti_sar	= 1 if opg15 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	
	replace main_acti_sar	= 10 if ( js8 == 2 | js5 == 5 ) & ( main_acti_sar == 0 |  main_acti_sar == .)

	*replace main_acti_sar	= 8 if opg9 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .)
	
	label define main_acti_sar  0 "Outside of LF" 1 "In School / Training" 2 "Help family B/W" 3 "Farm related"  4 "OPG: Gather" 5 "OPG: Hunt" 6 "OPG: Food preparation" 7 "OPG: Construction" 8 "OPG: Making goods for HH" 9 "OPG: Fetch water firewood" 10 "Family responsibilities"  11 "Employed" 12 "Unemployed" , modify 
	label val main_acti_sar main_acti_sar
	
	* NEET
	cap drop neet
	gen neet = 1 if age >= 15 & age < 66 
	replace neet = 0 if (tr4 != .) & neet == 1
	replace neet = 0 if (ed6 == 1) & neet == 1
	replace neet = 0 if neet == 1 & inlist(main_acti_sar , 1 , 2 , 11  )
	/*
	replace neet = 1 if ( ilo_lfs ==  2 | ilo_lfs == 3 | main_act == 0 ) & (ed6 == 2 ) & (tr4 == .) & neet == 0
	replace neet = 1 if ( main_act == 0 ) & neet == 0
	// & (d_look4job == 0)
	label var neet "Person not employed, in eduaction, or training. Age 15-65"
	replace neet = 0 if neet == 1 & inlist(main_acti_sar , 1 , 2 , 11  )
	*/ 
	tab  main_act neet if age >= 15 & age < 66  // [iw = ilo_wgt] , col nofreq
	
	* Checks 
	tab main_acti_sar
	tab main_acti_sar		if age >= 15 // [iw = ilo_wgt ]
	
	replace lfp_sar		= . if age < 15  // LFP defined for those 15 or older 
	tab lfp_sar				// [iw = ilo_wgt ]	
	
	gen order_mainacti = main_acti_sar
	recode order_mainacti (11 = -2 ) (12 = -1)
	
	
	
	
	
	/* REASONS: OUT OF LABOR FORCE 
	
	JS5. What was the Main reason why you did not seek work or try to start a business during the last 4 weeks?
		FOUND WORK BUT WAITING TO START 1
		AWAITING REPLIES TO EARLIER ENQUIRIES 2→JS7
		AWAITING FOR THE SEASON TO START 3→JS7
		ATTENDED SCHOOL/TRAINING COURSES 4→JS7
		FAMILY RESPONSIBILITIES OR HOUSEWORK 5→JS7
		ILLNESS, INJURY OR DISABILITY 6→JS7
		TOO YOUNG/OLD TO FIND WORK 7→JS7
		DOES NOT KNOW WHERE TO LOOK FOR WORK 8→JS7
		LACKS EMPLOYERS’ REQUIREMENTS (SKILLS, EXPERIENCE, QUALIFICATIONS) 9→JS7
		NO JOBS AVAILABLE IN THE AREA 10→JS7
		RETIRED, PENSIONER, OTHER SOURCES OF INCOME 11 →JS7
		OTHER REASONS (SPECIFY)___ 96→JS7
	
	JS8. What is the main reason why you do not want or you are not available to work?
		IN SCHOOL/ TRAINING 1
		HOUSEWORK/ FAMILY RESPONSIBILITIES 2
		ILLNESS, INJURY, DISABILITY 3
		RETIRED, PENSIONER 4
		TOO OLD FOR WORK 5
		OFF-SEASON 6
		WORKING CONDITIONS NOT ACCEPTABLE 7 OPG1
		ENGAGED IN SUBSISTENCE FARMING/FISHING 8
		DOING VOLUNTARY, COMMUNITY OR CHARITY WORK 9
		ENGAGED IN CULTURAL OR LEISURE ACTIVITIES 10
		OTHER (SPECIFY)___96
	
	
	Comparison of the main_activity I created with the survey vs the one that was included in the survey. 
	I observe missclasification mainly for those reported doing nothing or working only; those working only many tomes do not have jobs, while those doing nothing have reported to be employed or looking for a job. 
	
                      |      Interplay between school and work
        main_acti_sar | work only  study onl  work and     nothing |     Total
----------------------+--------------------------------------------+----------
        Outside of LF |         0          0          0      7,605 |     7,605 
 In School / Training |       966     11,822      3,970      2,746 |    19,504 
      Help family B/W |       321          0         79          0 |       400 
         Farm related |       940          0        172          0 |     1,112 
          OPG: Gather |       462          0        124          0 |       586 
            OPG: Hunt |        46          0          3          0 |        49 
OPG: Food preparation |       336          0         29          0 |       365 
    OPG: Construction |       159          0         11          0 |       170 
OPG: Making goods for |        72          0         12          0 |        84 
OPG: Fetch water fire |     2,459          0        419          0 |     2,878 
Family responsibiliti |         0         75          0      1,583 |     1,658 
             Employed |    15,160          5      1,637        205 |    17,007 
           Unemployed |       273         35         25        527 |       860 
----------------------+--------------------------------------------+----------
                Total |    21,194     11,937      6,481     12,666 |    52,278 

	
	
	
	tab main_acti_sar [iw = ilo_wgt ] if age > 17 & age < 65
	bys female : tab main_acti_sar [iw = ilo_wgt ] if age > 17 & age < 65
	
	bys female : tab js5 [ iw = ilo_wgt ] if age > 17 & age < 65 & main_acti_sar == 0
	bys female : tab js5 if age > 17 & age < 65 & main_acti_sar == 0
	
	bys female : tab js8 [ iw = ilo_wgt ] if age > 17 & age < 65 & main_acti_sar == 0
	bys female : tab js8 if age > 17 & age < 65 & main_acti_sar == 0
	*/ 
	
	
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
	
	OPG1. Last week, did (you/NAME) you gather wild food such as [mushrooms, herbs...]?
	OPG3. Last week, did (you/NAME) go hunting for [bush meat...]?
	OPG5. Last week, did (you/NAME) prepare preserved food or drinks for storage such as [flour, dried fish, butter, cheese...]?
	OPG7. Last week, did (you/NAME) do any construction work to build, renovate or extend the family home or help a family member with similar work?
	OPG9. Last week, did (you/NAME) spend any time making goods for use by your household or family such as [mats, baskets, furniture, clothing,..]?
	OPG11. Last week, did (you/NAME) fetch water from natural or public sources for use by your household or family?
	OPG13. Last week, did (you/NAME) collect any firewood [or other natural products] for use as fuel by your household or family?
	OPG15. In the last 4 weeks from [START DATE] up to [last END DAY/yesterday] did (you/NAME) participate in any unpaid apprenticeship, internship or similar training in a work place?
	
	*/
	
	
	* >>  # Number of kids in the household 
	gen child_d = age <= 17
	bys hh1 hh2 : egen tot_children = total(child_d)
	order tot_children hh1 hh2 hl1 hl6
	
	* >> Formal job dummy 
	gen formal_job =  ilo_job1_ife_nature == 2
	replace formal_job = . if inc_d_total == .
	
	* >> Main activity components
	tab main_acti , gen(macti_)
	
	* >> Informality
	gen informality		= 0 if ilo_job1_ife_prod != .
	replace informality	= 1 if ilo_job1_ife_nat == 2 
	
	* >> Migration
	recode mig3 (2 = 0)
	label define MIG3 0 "NO", modify
	
	gen born_here = mig3
	label val born_here MIG3
	
	label define origin  0 "Foreign" 1 "National"
	label val born_here origin 
	
		recode js1 js2 (2=0) 
	gen obs = 1
	gen uno  =1
	
	gen urban = hh7 == 1
	
	save  "${d_raw}\working\GMB_LFS_work.dta" , replace 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
*------------------------------------------------------------------------------*
*-------------------------------- Outputs -------------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
*-------------------------------- Outputs -------------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
*-------------------------------- Outputs -------------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
*-------------------------------- Outputs -------------------------------------*
*------------------------------------------------------------------------------*
	use "${d_raw}\working\GMB_LFS_work.dta" , clear 
	
	
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
	
		tabstat : This set of variables I am going to export using 
		"tabstat inc_by_hour, stats(mean p25 p50 p75 sd) columns(statistics) long 
		tabstat inc_by_hour, by(female) stats(mean p25 p50 p75 sd) columns(statistics) long
		tabstat inc_by_hour, by(educ_) stats(mean p25 p50 p75 sd) columns(statistics) long
		tabstat inc_by_hour, by(empstat2_) stats(mean p25 p50 p75 sd) columns(statistics) long
		tabstat inc_by_hour, by(sector2_) stats(mean p25 p50 p75 sd) columns(statistics) long
		tabstat inc_by_hour, by(rural) stats(mean p25 p50 p75 sd) columns(statistics) long
		tabstat inc_by_hour, by(informal) stats(mean p25 p50 p75 sd) columns(statistics) long
	*/
	

	
	* Total 
preserve 
	keep if age >= 15 & age < 66 
	recode female neet js1 js2  (1 = 100)
	collapse (mean) urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2    macti_* (sum) uno (rawsum) obs [ iweight = ilo_wgt], 
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("GMB Total" , replace)  firstrow(varl)
restore 

	* By urban
preserve 
	keep if age >= 15 & age < 66 
	recode female neet js1 js2  (1 = 100)
	collapse (mean) w_wap female born_here educ_1 educ_2 educ_3 educ_4  informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2   macti_* (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( urban )
		export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("GMB By area" , replace)  firstrow(varl)
restore 

	* By urban sex 
preserve 
	keep if age >= 15 & age < 66 
	recode female neet js1 js2  (1 = 100)
	collapse (mean) w_wap born_here educ_1 educ_2 educ_3 educ_4  informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2   macti_* (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( urban female)
		export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("GMB By area sex" , replace)  firstrow(varl)
restore 
	
	* By sex 
preserve 
	keep if age >= 15 & age < 66 
	recode female neet js1 js2  (1 = 100)
	collapse (mean) urban w_wap born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2  macti_* (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( female)
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("GMB By sex" , replace)  firstrow(varl)
restore 

	* By migration status  
preserve 
	keep if age >= 15 & age < 66 
	recode female neet js1 js2  (1 = 100)
	collapse (mean) urban w_wap female educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2 macti_* (sum) uno (rawsum) obs  [ iweight = ilo_wgt], by( born_here )
	export excel using "${dir_out}/Tables/Descriptive_statistics.xlsx" ,  sheet("GMB By Migration status" , replace)  firstrow(varl)
restore 

/*
estpost  sum female	[iw = ilo_wgt]
eststo sar1 : sum female	[iw = ilo_wgt]
esttab sar1 , main( mean ) aux(sd) 

esttab using "${dir_out}/Tables/summary_stats_GMB.tex"  , main(mean ) aux(sd) append type
estpost  sum urban	[iw = ilo_wgt]
eststo sard : sum urban	[iw = ilo_wgt]

esttab  sar1 , main( mean ) aux(sd) 
using "${dir_out}/Tables/summary_stats_GMB.tex"  , main(mean ) aux(sd) append type
*/

label define sex_fem 100 "Female" , modify 
label define urban 1 "Urban" 100 "Urban" 0 "Rural" , modify
label define origin  100 "National"  , modify
label val urban urban 

rename educ_ edu_categ

global shares urban w_wap female born_here educ_* neet js1 js2  macti_* informality

quietly {
foreach categ in urban female born_here {
	
	preserve
	* local categ = "urban"
		recode "${shares}" ( 1 = 100 )
		
		rename urban	a_urban
		rename w_wap	b_w_wap
		rename female 	c_female
		rename born_here 	d_born_here
		rename educ_*	e_educ_*
		rename informality	f_informality
		rename inc_*	g_inc_*
		rename wkt*		h_wkt*
		rename neet 	i_neet
		rename js*		j_js*
		rename macti_*	k_macti*
		
		desc *_`categ' , varlist
		di r(varlist)
		
		local byvar = substr("`r(varlist)'" , 3, .)
		di "`byvar'"
			
		tempfile stat1 stat2 `byvar'
		
		
		qui noi tabstat a_urban b_w_wap c_female d_born_here e_educ* f_informality g_inc_d_salw g_inc_d_selfw g_inc_d_total g_inc_by_hour h_wkt1 h_wkt3 h_wkt6 h_wkt8a i_neet j_js1 j_js2 k_macti* ///
		[aw = ilo_wgt ] ///
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
		
		export excel using "${dir_out}/Tables/Z_Descriptive_statistics.xlsx" if type != "obs" , sheet("GMB By `byvar'" , replace)  firstrow(varl)	
		export excel using "${dir_out}/Tables/Z_Descriptive_statistics_obs.xlsx" if type == "obs" , sheet("GMB By `byvar'" , replace)  firstrow(varl)	
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
			
			export excel using "${dir_out}/Tables/Z_Descriptive_statistics.xlsx" if type != "obs"  , sheet("GMB Total" , replace)  firstrow(varl)
			
			export excel using "${dir_out}/Tables/Z_Descriptive_statistics_obs.xlsx" if type == "obs"  , sheet("GMB Total" , replace)  firstrow(varl)	
			
		restore 
}
}	
	
	
	
	
/*

		urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2  macti_* if age >=15 & age <66 , columns(statistics) stats(mean sd) long by(ilo_sex ) save

	matlist r(Stat1)

	
	tabstat female , stats(mean sd) columns(statistics) long save
	tabstat urban , stats(mean sd) columns(statistics) long save
	matlist r(StatTotal)
	
	
	tabstat a_urban b_w_wap c_female d_born_here e_educ* f_informality g_inc_* h_wkt1 h_wkt3 h_wkt6 h_wkt8a i_neet j_js1 j_js2 k_macti* ///
	if age >= 15 & age < 66, columns(statistics) stats(mean sd) long by( edu_categ ) save

	di `r(name1)'
	di `r(name2)'

tabstat  urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2  macti_* , columns(statistics) stats(mean sd) long by(urban) save

tabstat  urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw  wkt1 wkt3 wkt6 wkt8a neet js1 js2  macti_* if age >= 15 & age < 66 , columns(statistics) stats(mean sd) long by() save

	
*/



*------------------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
*------------------------------------------------------------------------------*	
*------------------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
*------------------------------------------------------------------------------*

label var inc_d_salw "Salaried Income" 
label var inc_d_selfw "Self-employed income"
label var inc_d_total "Total income: Salaried and Self-employed"
label var inc_by_hour "Total income per hour"

** Hours worked CDF
	replace wkt8a = 98 if wkt8a >= 98 & wkt8a != .

	sort female wkt8a
	cap drop cum_hw_m cum_hw_f
	cumul wkt8a if female == 0 [aw = ilo_wgt] , gen(cum_hw_m) eq
	cumul wkt8a if female == 1 [aw = ilo_wgt] , gen(cum_hw_f) eq
	
	replace cum_hw_f = cum_hw_f*100
	replace cum_hw_m = cum_hw_m*100
	
	sum wkt8a  [ aweight = ilo_wgt ] if female == 1 
		qui local mu_f = round(`r(mean)', 1)
		qui local vr_f = round(`r(sd)', 1)

	sum wkt8a  [ aweight = ilo_wgt ] if female == 0 
		qui local mu_m = round(`r(mean)', 1)
		qui local vr_m = round(`r(sd)', 1)
		
	twoway	(line cum_hw_m wkt8a if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) ///
			(line cum_hw_f wkt8a , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ///
			,	$grph_reg $y_axis legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )   ytitle("% below # of hours" , size(medsmall)) ylabel( 0(20)100, labsize(medsmall)) xlabel( 0(10)100 , labsize(medsmall)) xtitle("" ) ///
		note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (medsmall) position(11) ring(0) margin(medlarge))
	// xtitle("# Hours worked" )  xtitle(Hours)
	// subti("The Gambia")
	
	 graph export "${dir_out}/Graphs/GMB 1. Hours worked by sex.png",  as(png)    replace width(1995)  height(1452)
	
	
** Income 

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
			
		twoway (line cum_hw_m ln_`inc' if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) (line cum_hw_f ln_`inc' , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ///
		, $grph_reg $y_axis legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )   ytitle("%") ///
		note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (medsmall) position(11) ring(0) margin(medlarge)) xtitle("" ) 
		* subti("The Gambia")  
		* ylabel( 0(20)100, labsize(small)) xlabel( 0(20)180 , labsize(small))
		* xtitle(Hours) xtitle("`vrlab' in logs" )
		
		graph export "${dir_out}/Graphs/GMB 1. `vrlab' by sex.png",  as(png)    replace width(1995)  height(1452)
		
	cap drop fx x fx_f fx_m 
	kdensity ln_`inc'  [ aweight = ilo_wgt ] if uno ==1  `limit', nograph generate(x fx)
	kdensity ln_`inc'  [ aweight = ilo_wgt ] if female == 1 `limit' , nograph generate(fx_f) at(x) `bw'
	kdensity ln_`inc'  [ aweight = ilo_wgt ] if female == 0 `limit' , nograph generate(fx_m) at(x) `bw'
		* local bw = "bw(.19)"
		
		twoway (area fx_m x, fcolor("${color3}%30") lcolor("${color3}%60")) (area fx_f x, fcolor("${color2}%30") lcolor("${color2}%60") ) if uno == 1 `bnd' ///
		,  $grph_reg $y_axis  ytitle(" " ) legend(order( 1 "Males" 2 "Females" )  region(lcolor(white)) size(small)) ylabel(, noticks nolabels) ///
		note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (medsmall) position(11) ring(0) margin(medlarge)) ///
		name(`inc' , replace) xtitle("")
		* subti("The Gambia") 
		* xtitle("`vrlab' in logs", size(small))
		
		graph export "${dir_out}/Graphs/GMB 2. Kernel `vrlab' by sex.png",  as(png)    replace width(1995)  height(1452)
	}
	
	
	graph pie [aweight = ilo_wgt] if age >=15 & female == 1 , over(main_acti)  sort(order_mainacti)    plabel(_all percent, color(white) size( small) format(%3.0f)) line(lcolor(black) lwidth(vvvthin)) intensity(inten90) name(Female , replace)  $grph_reg legend(region(lcolor(none)))
	* subtitle(Females, position(10) ring(0) margin(10-pt))

	graph export "${dir_out}/Graphs/GMB 3. Main activity female.png",   replace width(1995)  height(1452)

	graph pie [aweight = ilo_wgt] if age >=15 & female == 0 , over(main_acti)  sort(order_mainacti)   plabel(_all percent, color(white) size( small) format(%3.0f))  line(lcolor(black) lwidth(vvvthin)) intensity(inten90) name(Male , replace)  $grph_reg legend(region(lcolor(none)))
	* subtitle(Males, position(10) ring(0) margin(10-pt))
	graph export "${dir_out}/Graphs/GMB 3. Main activity Male.png",   replace width(1995)  height(1452)

	
		
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
	glo sector		"`r(varlist)' "
	
	ds educ_2 - educ_4 
	glo edulvl		"`r(varlist)'"
	
	glo hh_charac "tot_children "
	
	ds firm_size_WB_1 - firm_size_WB_3
	glo firmsize	"`r(varlist)'"
	
	****************************************************************************
	*** OAXACA BLINDER DECOMPOSITION 
	****************************************************************************
	
	*cap noi drop _supp _match
	*nopomatch age age_sq  $edulvl  $sector  $firmsize $hh_charac , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd 
	
	*cap noi drop _supp _match
	*nopomatch age age_sq , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd 
	
	
oaxaca ln_inc_by_hour (age: age age_sq) (edulvl: $edulvl) [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of education on male and female income are different 
estimates store OB_1
oaxaca ln_inc_by_hour (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) formal_job $hh_charac [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of selection into economic activity
estimates store OB_2
oaxaca ln_inc_by_hour (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) (firmsize: $firmsize) $hh_charac [iweight = ilo_wgt] , by(female) relax vce(r) // Introducing firms size reduces the available smaple ostensibly 
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
		
		reg `inc' female age age_sq  $edulvl $sector $firmsize $hh_charac
		
		oaxaca `inc' (age: age age_sq) (edulvl: $edulvl)	$hh_charac	`add_control'  [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of education on male and female income are different 
		estimates store OB_1
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector)	$hh_charac	`add_control' [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_2
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) (firmsize: $firmsize) $hh_charac `add_control' [iweight = ilo_wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_3
		
		esttab OB_1 OB_2 OB_3 using "${dir_out}/Tables/GMB/1. OB Decomposition in `vrlab'.csv" ,  stats(N ) label replace addnotes("Group 1 == Males. Group 2 == Females" )  title("Oaxaca Blinder Decomposition") b(3) t(3)
	
	
		/* Nopo common support exercise 
		* I am commenting this part out as Nopo is best run without the transformation 
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$hh_charac `add_control'  , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/GMB OB_N_1_`inc'") replace
		restore
		*
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$hh_charac	`add_control'  , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/GMB OB_N_2_`inc'") replace
		restore
		*
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$firmsize	$hh_charac	`add_control'  , outcome(ln_inc_by_hour) by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/GMB OB_N_3_`inc'") replace
		restore 
		*/
	}
	 
	*** Nopo not in logs
	
	* inc_d_salw
	foreach inc in inc_by_hour inc_d_total inc_d_selfw  inc_d_salw {  
		if "`inc'" != "inc_by_hour" {
		    local add_control = " wkt8a "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		* Nopo common support exercise 
		*	
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$hh_charac	`add_control'	, outcome(`inc') by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/GMB/OB_N_1_`inc'") replace
		*
		restore
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$hh_charac   `add_control'  , outcome(`inc') by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/GMB/OB_N_2_`inc'") replace
		*
		restore
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$firmsize	$hh_charac	`add_control'  , outcome(`inc') by(female) fact(ilo_wgt) sd filename("${dir_out}/Tables/GMB/OB_N_3_`inc'") replace
		restore
	}
	
	
	preserve
		clear
		set obs 0
		gen inc_type = ""
		* ln_inc_by_hour
		foreach inc in  inc_by_hour inc_d_total inc_d_selfw inc_d_salw  {
			append using "${dir_out}/Tables/GMB/OB_N_1_`inc'"
			append using "${dir_out}/Tables/GMB/OB_N_2_`inc'"
			append using "${dir_out}/Tables/GMB/OB_N_3_`inc'"
			replace inc_type = "`inc'" if inc_type == "" 
			
			erase "${dir_out}/Tables\GMB/OB_N_1_`inc'.dta"
			erase "${dir_out}/Tables\GMB/OB_N_2_`inc'.dta"
			erase "${dir_out}/Tables\GMB/OB_N_3_`inc'.dta"
			
		}
		export excel using "${dir_out}/Tables/Z_OB_Decomposition_Nopo_summary.xlsx" ,  sheet("GMB By sex" , replace)  firstrow(varl)	
	restore 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/*
	
	Notes:
	The order in which the item family responsibilities is included in the main_activity variable, affects the share it represents. I decided to leave for last in order to observer exactly what are the underlying tasks of those responsibilities. They main switch in this reponsibilities is fetching water and firewood. 
	
		/* 
	        main_acti_sar |      Freq.     Percent        Cum.
--------------------------+-----------------------------------
            Outside of LF |      8,437       24.00       24.00
     In School / Training |      3,948       11.23       35.23
          Help family B/W |        290        0.82       36.05
             Farm related |        873        2.48       38.53
              OPG: Gather |        300        0.85       39.39
                OPG: Hunt |         33        0.09       39.48
    OPG: Food preparation |        178        0.51       39.99
        OPG: Construction |        132        0.38       40.36
 OPG: Making goods for HH |         51        0.15       40.51
OPG: Fetch water firewood |      1,620        4.61       45.12
  Family responsibilities |      2,492        7.09       52.20
                 Employed |     15,944       45.35       97.55
               Unemployed |        860        2.45      100.00
--------------------------+-----------------------------------
                    Total |     35,158      100.00


            main_acti_sar |      Freq.     Percent        Cum.
--------------------------+-----------------------------------
            Outside of LF |      8,437       24.00       24.00
     In School / Training |      3,948       11.23       35.23
          Help family B/W |        290        0.82       36.05
             Farm related |        873        2.48       38.53
              OPG: Gather |        371        1.06       39.59
                OPG: Hunt |         38        0.11       39.70
    OPG: Food preparation |        352        1.00       40.70
        OPG: Construction |        154        0.44       41.14
 OPG: Making goods for HH |         79        0.22       41.36
OPG: Fetch water firewood |      2,318        6.59       47.95
  Family responsibilities |      1,494        4.25       52.20
                 Employed |     15,944       45.35       97.55
               Unemployed |        860        2.45      100.00
--------------------------+-----------------------------------
                    Total |     35,158      100.00

					
					
	*/
	
	
	
	
	