											*------------------------------------------------------------------------------*
											** Returns to education and gender gap in wages, EUSILC - 2015
											** Paola Buitrago (para Gabriela)
											*------------------------------------------------------------------------------*

clear all
set more off


*------------------------------------------------------------------------------*
* Define directories
*------------------------------------------------------------------------------*


if "`c(username)'"=="wb343606" | "`c(username)'"=="WB343606" | "`c(username)'"=="sbuitragohernand" { //add additional directories
	global in "C:\Users\\`c(username)'\OneDrive - WBG\SILC Bulgaria 2015\input_allEU"
	global out "C:\Users\\`c(username)'\OneDrive - WBG\SILC Bulgaria 2015\output_allEU"
}


use "$in/silc_2015_ready.dta", clear
*NOTE: nopomatch is a semiparametric methodology, I assume there is no need to transform wages into logwages. All $$$ values are in Euro.
* Experience variable not available for some countries
		
	
		*Presence of children - AT LEAST ONE 0-6
		sort code hhid_n
		cap drop children
		egen children=sum(age <= 6 & age>=0), by (code hhid_n)
		gen children_0_6=children>0 
	
		keep if age>=25 & age<=64 
		rename pl051 occupation
		rename pl040 employ_type
		
		*Three countries with incomplete info: ICELAND (no occ, no act), NETHERLANDS & SLOVENIA (no urban)
		
		*Consider ONLY those who are FULL-TIME
		gen full_time=.
		replace full_time=1 if (pl031==1 | pl031==3)
		replace full_time=0 if (pl031==2 | pl031==4)
		tab full_time
		
		*AGGREGATE OCCUPATIONS		 
		rename occupation pl051
		gen occupation=.
		replace occupation=1 if (pl051==1 | (pl051>=11 & pl051<=14))
		replace occupation=2 if (pl051==2 | pl051==3 |(pl051>=21 & pl051<=35))
		replace occupation=3 if (pl051==4 | pl051==5 |(pl051>=41 & pl051<=54))
		replace occupation=4 if (pl051==6 | pl051==7 |(pl051>=61 & pl051<=75))
		replace occupation=5 if (pl051==8 | pl051==9 |(pl051>=81 & pl051<=96))
		label var occupation "Occupation"
		label def occupation 1 "Managers" 2 "P&T" 3 "ss/sales/cleric" 4 "Agr&craft" 5 "Operators/Element" , modify
		label val occupation occupation

		*****WAGE, HOURS WORKED & INCOME FROM MAIN activity ONLY*****
		cap drop jobhr
		egen jobhr=rsum(pl060)
		cap drop wagehr2 wagehr1 wagehr3		
		gen wagehr3=((py010g)/12)
		gen wagehr2=((py010g)/12)/(jobhr*4.25)
		gen wagehr1=py200g/(jobhr*4.25)
		
		* KEEP INDIVIDUALS WITH POSITIVE EARNING AND AT LEAST UPPER SEC, ONLY
		keep if  wagehr2>0 & edu!=0
		


/*
*------------------------------------------------------------------------------*
* FOLLOWING NOPO (2008), GENDER GAPS IN HR LABOR INCOME 
* (based on y/m labor income
*------------------------------------------------------------------------------*
		
		levelsof code, local(lvl)
		foreach  c of local lvl {	
		dis in red "`c'"
		nopomatch age edu urban married children_0_6 employ_type activity if full_time==1 & code=="`c'", outcome(wagehr2) by(male) fact(db090) sd filename("$out/`c'") replace
		*occupation
		}
		
*deleted MLT because has no age variable
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE


		foreach x of local countries {
		set more off
		use "$out/`x'.dta", clear
		replace controls="`x'"
		save, replace
		}


use "$out/AUT.dta", clear
replace controls="AUT"

save, replace
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE
		foreach x of local countries {
		append using "$out/`x'.dta"
		save "$out/nopomatch.dta", replace
		}

rename sdev Std_error_DO
rename controls code
list
order code D DM DF DX D0 Std_error_DO percM percF
sort code
save, replace
exit

+++
*------------------------------------------------------------------------------*
* NOPO MATCH, DEMOGRAPHIC ONLY: 
* age, urban, edu, married, child0to6 
*------------------------------------------------------------------------------*

		
		levelsof code, local(lvl)
		foreach  c of local lvl {	
		dis in red "`c'"
		nopomatch age edu urban married children_0_6 if full_time==1 & code=="`c'", outcome(wagehr2) by(male) fact(db090) sd filename("$out/dem_`c'") replace
		}
		
*deleted MLT because has no age variable
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE


		foreach x of local countries {
		set more off
		use "$out/dem_`x'.dta", clear
		replace controls="`x'"
		save, replace
		}


use "$out/dem_AUT.dta", clear
replace controls="AUT"

save, replace
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE
foreach x of local countries {
append using "$out/dem_`x'.dta"
save "$out/dem_nopomatch.dta", replace
}

rename sdev Std_error_DO
rename controls code
list
order code D DM DF DX D0 Std_error_DO percM percF
sort code
save, replace


merge 1:1 code using "$out/countries.dta"
keep if _merge==3
drop _merge
order country code
save, replace

exit


	
*------------------------------------------------------------------------------*
* NOPO, OCCUPATION ONLY
* (based on y/m labor income, 40 hours assumed)
*------------------------------------------------------------------------------*
		
		levelsof code, local(lvl)
		foreach  c of local lvl {	
		dis in red "`c'"
		nopomatch age edu urban married children_0_6 employ_type occupation if full_time==1 & code=="`c'", outcome(wagehr2) by(male) fact(db090) sd filename("$out/`c'") replace
		*occupation
		}
		
*deleted MLT because has no age variable
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE


		foreach x of local countries {
		set more off
		use "$out/`x'.dta", clear
		replace controls="`x'"
		save, replace
		}


use "$out/AUT.dta", clear
replace controls="AUT"

save, replace
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE
		foreach x of local countries {
		append using "$out/`x'.dta"
		save "$out/nopomatch_occup.dta", replace
		}

rename sdev Std_error_DO
rename controls code
list
order code D DM DF DX D0 Std_error_DO percM percF
sort code
save, replace



*------------------------------------------------------------------------------*
* NOPO, OCCUPATION AND ECONOMIC SECTOR
* (based on y/m labor income, 40 hours assumed)
*------------------------------------------------------------------------------*
		
		levelsof code, local(lvl)
		foreach  c of local lvl {	
		dis in red "`c'"
		nopomatch age edu urban married children_0_6 employ_type occupation activity if full_time==1 & code=="`c'", outcome(wagehr2) by(male) fact(db090) sd filename("$out/`c'") replace
		*occupation
		}
		
*deleted MLT because has no age variable
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE


		foreach x of local countries {
		set more off
		use "$out/`x'.dta", clear
		replace controls="`x'"
		save, replace
		}


use "$out/AUT.dta", clear
replace controls="AUT"

save, replace
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE
		foreach x of local countries {
		append using "$out/`x'.dta"
		save "$out/nopomatch_occup_sector.dta", replace
		}

rename sdev Std_error_DO
rename controls code
list
order code D DM DF DX D0 Std_error_DO percM percF
sort code
save, replace
exit



*------------------------------------------------------------------------------*
* NOPO, EDUCATION ONLY
* (based on y/m labor income, 40 hours assumed)
*------------------------------------------------------------------------------*
		
		levelsof code, local(lvl)
		foreach  c of local lvl {	
		
		dis in red "`c'"
		nopomatch age edu  if full_time==1 & code=="`c'", outcome(wagehr2) by(male) fact(db090) sd filename("$out/`c'") replace
		*occupation
		}
		
*deleted MLT because has no age variable
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE


		foreach x of local countries {
		set more off
		use "$out/`x'.dta", clear
		replace controls="`x'"
		save, replace
		}


use "$out/AUT.dta", clear
replace controls="AUT"

save, replace
local countries BEL BGR CHE CYP CZE DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA NLD NOR POL PRT ROU SRB SVK SVN SWE
		foreach x of local countries {
		append using "$out/`x'.dta"
		save "$out/nopomatch_EDU.dta", replace
		}

rename sdev Std_error_DO
rename controls code
list
order code D DM DF DX D0 Std_error_DO percM percF
sort code
save, replace

*/


*------------------------------------------------------------------------------*
* NOPO, COMPLETE ORIGINAL MODEL REPORTING BY EDUCATION, CHILDREN, ECO ACT
* (based on y/m labor income, 40 hours assumed)
*------------------------------------------------------------------------------*

		
keep if age!=. & edu!=. & urban!=. & married!=. & children_0_6!=. & employ_type!=. & activity!=.
set more off
nopomatch age edu urban married children_0_6 employ_type activity if full_time==1, outcome(wagehr2) by(male) fact(db090) sd reportby(edu) filename("$out/edu") replace
nopomatch age edu urban married children_0_6 employ_type activity if full_time==1, outcome(wagehr2) by(male) fact(db090) sd reportby(children_0_6) filename("$out/children_0_6") replace
nopomatch age edu urban married children_0_6 employ_type activity if full_time==1, outcome(wagehr2) by(male) fact(db090) sd reportby(activity) filename("$out/activity") replace
nopomatch age edu urban married children_0_6 employ_type activity if full_time==1, outcome(wagehr2) by(male) fact(db090) sd filename("$out/full_pooled") replace
exit		

local vars edu children_0_6 activity full_pooled

		foreach x of local vars {
		set more off
		use "$out/`x'.dta", clear
		replace controls="`x'"
		save, replace
		}

use "$out/edu.dta", clear
local vars children_0_6 activity full_pooled
		foreach x of local vars {
		append using "$out/`x'.dta"
		save "$out/boxes.dta", replace
		}

rename sdev Std_error_DO
order controls D DM DF DX D0 Std_error_DO percM percF

replace category="agriculture" if controls=="activity" & category=="0"
replace category="mining/manuf/elec/water" if controls=="activity" & category=="2"
replace category="construction" if controls=="activity" & category=="3"
replace category="wholesale, retail;repair of motor vehic" if controls=="activity" & category=="4"
replace category="transportation and storage" if controls=="activity" & category=="5"
replace category="accommodation and food service activities" if controls=="activity" & category=="6"
replace category="information and communication" if controls=="activity" & category=="7"
replace category="financial and insurance" if controls=="activity" & category=="8"
replace category="real estate, professional, scient and tech, admin/support ss" if controls=="activity" & category=="9"
replace category="public admin and defence; comp. soc sec" if controls=="activity" & category=="10"
replace category="education" if controls=="activity" & category=="11"
replace category="human health and social work" if controls=="activity" & category=="12"
replace category="arts, entertainment, other service, domestic, extrater org" if controls=="activity" & category=="13"

replace category="upper sec+non-tert" if controls=="edu" & category=="1"
replace category="tertiary" if controls=="edu" & category=="2"


replace category="Yes" if controls=="children_0_6" & category=="1"
replace category="No" if controls=="children_0_6" & category=="0"


save, replace

*------------------------------------------------------------------------------*
* OAXACA BLINDER DECOMPOSITION, APPLYING SELECCTION CORRECTION
*------------------------------------------------------------------------------*

	* Firm size
			cap drop firmsize
			gen firmsize=1
			replace firmsize=0 if (pl130<=10 | pl130==14)
			replace firmsize=. if pl130==.
			label var firmsize "Firm size >11"
			label def firmsize 0 "Less than 11" 1 "11+"
			label val firmsize firmsize
	
	*HECKMAN'S CORRECTION FOR SELECTION, MILLS RATIO
		
		gen lwagehr=log(wagehr2)
		qui tabulate controls, gen(activ)
		qui tab	edu, gen(education)
		qui tab occupation, gen(occup)
		*tab db040, gen(region)
		
		
		cap drop employed
		gen employed=0
		replace employed=1 if pl031<=4
		replace employed=. if pl031==.
		*tab employed
		rename hx040 hhsize
		cap drop supervisory
		gen supervisory=pl150
		replace supervisory=0 if pl150==2
		
		keep if code!="ISL"
		keep if code!="NLD"
		keep if code!="SVN"
	
	cap erase "$out/oaxaca_2015.xls"
	cap erase "$out/oaxaca_2015.txt"

		levelsof code, local(lvl)
		foreach  c of local lvl {	
		dis in red "`c'"
		cap drop xb`c'
		xi: probit employed age age2 i.edu  married children_0_6  urban  [pw=db090] if code=="`c'"
		predict xb_`c' if e(sample), xb
		cap drop imills`c'
		generate imills`c' = normalden(-xb_`c') / (1 - normal(-xb_`c'))
		*Gross hourly labor income
		set more off
		*twofold
		oaxaca lwagehr (exp: age age2) (education: edu) (employment: employ_type firmsize) (sector: normalize(activ1-activ13)) /// 
		(occupation: normalize(occup1-occup50)) imills`c'  [pw=db090] if full_time==1 & code=="`c'", by(female) weight(0.5) relax nodetail
		outreg2 using "$out/oaxaca_2015.xls", append label dec(3) stats(coef aster) sideway ctitle("`c'") 
	}
	
	exit
	
		*threefold
		*oaxaca  log_mth_inc  (experience: age agesq) (education: normalize(educ1-educ7))(region: normalize(reg1-reg12)) (sector: normalize(activ1-activ21)) imills [pw=faktor], by(female) threefold noisily relax
		*(region: normalize(region1-region2)

	
