
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

// Occupational position + SOEs
gen     empstat2_= empstat_
replace empstat2_= 4 if empstat2_ == 3
replace empstat2_= 3 if empstat2_ == 2 & inlist(ap4,1,2,3)
tab empstat2_, gen(empstat2_)


lab var empstat2_1 "Self-employee/own boss"
lab var empstat2_2 "Salaried workers"
lab var empstat2_3 "SOEs salaried workers"
lab var empstat2_4 "Other workers"

// >>> Weekly Hours worked  --------------

**Main activity: ap10c
**Secondary activity: as2b1 as2b2 damaged . as13b1 as13b2 Workers

egen week_hours = rowtotal(ap10c), m

*egen week_hours = rowtotal(ap10c as13b1 as13b2), m
// >>> Daily Income --------------

local vars ap13a2 ap16a2 ap16b2 ap16c2 ap16d2 ap16e2 ap16f2 ap16g2

foreach var of local vars {
    replace `var' = . if `var' == 9999
}

* >> Incomes: inc_by_hour, inc_d_total, inc_d_selfw inc_d_salw

egen inc_d_total = rowtotal(ap13a2 ap16a2 ap16b2 ap16c2 ap16d2 ap16e2 ap16f2 ap16g2),m
replace inc_d_total = inc_d_total/30

// >>> Income per hours

g inc_by_hour =  inc_d_total / ((week_hours*52.1786)/360)
g ln_inc_by_hour = ln(1+inc_by_hour)

count if ln_inc_by_hour==. & empstat2_ != . // missing

bys empstat2_: count if ln_inc_by_hour==. & empstat2_ != . // missing

* >> inc_d_selfw
gen inc_d_selfw		= inc_d_total if empstat_ == 1 | empstat_ == 3

* >> inc_d_salw
gen inc_d_salw		= inc_d_total if empstat_ == 2

// >>> Education --------------
recode m11 (1 . = 1) (2 4 = 2) (5 6 = 3) (3 = 4), gen(educ_)

lab var educ_  "Level of education"
lab def educ_ 1 "Less than basic" 2 "Basic" 3 "Intermediate" 4 "Advanced"
lab val educ_ educ_

// >>> Sector --------------

replace ap2ac = " " if ap2ac == "55" | ap2ac == "99999" | ap2ac == "??" | ap2ac == "A47332"

gen isic_clean = substr(ap2ac, 2, .)

destring isic_clean, replace force

gen sector_ = .

* Agriculture: ISIC codes starting from 0111 to 0322
replace sector_ = 1 if inrange(isic_clean, 111, 322)

* Manufacture: ISIC codes starting from 1010 to 3320
replace sector_ = 2 if inrange(isic_clean, 1010, 3320)

* Services: ISIC codes starting from 3510 to 9900
replace sector_ = 3 if inrange(isic_clean, 3510, 9900)


tab sector_, gen(sector_)
lab var sector_1  "Sector: Agriculture"
lab var sector_2  "Sector: Manufacture"
lab var sector_3  "Sector: Services"

// Sector 2: splitting services
gen isic_clean_str = string(isic_clean)
replace isic_clean_str = "" if isic_clean_str == "."
gen isic_clean_4digit = cond(strlen(isic_clean_str) == 1, "000" + isic_clean_str, cond(strlen(isic_clean_str) == 2, "00" + isic_clean_str, cond(strlen(isic_clean_str) == 3, "0" + isic_clean_str, isic_clean_str)))

gen isic_clean_2digit = substr(isic_clean_4digit, 1, 2)

g sector2_ = sector_
replace sector2_ = 4 if sector2_ == 3
replace sector2_ = 3 if inlist(isic_clean_2digit,"45","46","47") & sector2_ == 4
replace sector2_ = 5 if (isic_clean_2digit == "64" | isic_clean_2digit == "65" | isic_clean_2digit == "66" | isic_clean_2digit == "68" | isic_clean_2digit == "69" | isic_clean_2digit == "70" | isic_clean_2digit == "71" | isic_clean_2digit == "72" | isic_clean_2digit == "73" | isic_clean_2digit == "74" | isic_clean_2digit == "75" | isic_clean_2digit == "58" | isic_clean_2digit == "59" | isic_clean_2digit == "60" | isic_clean_2digit == "61" | isic_clean_2digit == "62" | isic_clean_2digit == "63" | isic_clean_2digit == "78" | isic_clean_2digit == "80" | isic_clean_2digit == "82" | isic_clean_2digit == "84" | isic_clean_2digit == "85" | isic_clean_2digit == "86" | isic_clean_2digit == "87" | isic_clean_2digit == "88") & sector2_ == 4

tab sector2_, gen(sector2_)
lab var sector2_1  "Sector: Agriculture"
lab var sector2_2  "Sector: Manufacture"
lab var sector2_3  "Sector: Trade services"
lab var sector2_4  "Sector: Low-skilled services"
lab var sector2_5  "Sector: High-skilled services"



ta educ_, gen(educ_)

recode m3 (2 = 1) (1 = 0), gen(female_)
ta female_, gen(female_)

ren ln_inc_by_hour productivity
gen ln_inc_by_hour = productivity
gen ln_inc_d_salw	= ln(inc_d_salw + 1)
gen ln_inc_d_total	= ln(inc_d_total + 1)
gen ln_inc_d_selfw	= ln(inc_d_selfw + 1)
 
label var inc_d_salw "Salaried Income: " 
label var inc_d_selfw "Self-employed income:  "
label var  inc_d_total "Total income: Salaried and Self-employed"

* >>  Age and age square 
g age = m4
g agesq = age*age

* >> Urban: Urban rural categories AREA : milieu
gen urban = milieu
recode urban (2 = 0)
label define area 0 "Rural" 1 "Urban"
label val urban area 
tab urban 

// >>> Workers in WAP --------------
g w_wap = .
replace w_wap = 0 if age>=5
replace w_wap = 1 if age>=15 & w_wap < 66

* >> Born here / Nationality m7
	gen born_here = 0
	replace born_here = 1 if m7 == 1 

	label define origin  0 "Foreign" 1 "National" , modify 
	label val born_here origin 
* >>  Define sample weight
gen wgt_all		= pond_allsample
gen wgt			= pond

* >> female
rename female_	female 
	label define sex_fem  0 "Male" 1 "Female" , modify
	label val female sex_fem 
	
* >> Contract INFORMAL 
recode ap8d (3 4 5 . =1) (1 2 = 0), gen(informality)

* >> Neet
	cap drop neet
	gen neet		= 0 if age >= 15 & age < 65 
	replace neet	= 1 if ( empstat_ == . ) & ( m14 == 2 ) & neet == 0 & ( ea6b == 2 )
	bys female : tab neet [iw = wgt]
	* & (tr4 == .) & (d_look4job == 0)
	// ea6a		ea6a.Avez-vous cherch� un emploiau cours des 7 derniers jours?
	// ea6b 	ea6b.Avez-vous cherch� un emploi au cours des 30 derniers jours ?

* >> Looking for a job 
	recode ea6b ea6a (2=0) 
	label define EA6B 0 "Non" , modify 
	label define EA6A 0 "Non" , modify 
	
	rename ea6b look_last7 
	rename ea6a look_last30 
	


	* >> Labor Force Participation (Employed, working at home, looking for a job) 
	cap drop lfp_sar
	gen lfp_sar 		= 0 if age >= 5 
	replace lfp_sar 	= 1 if lfp_sar == 0 & (  empstat_ != . )
	replace lfp_sar		= 2 if look_last30 == 1 & lfp_sar == 0
	
	label define lfp_sar  0 "Outside of LF" 1 "Employed" 2 "Unemployed" , modify 
	label val lfp_sar lfp_sar 
	
	bys female: tab  lfp_sar if w_wap == 1 & age >= 18 & age < 66 [iw = wgt ]
	
	
	* >> Main activity 
	cap drop main_acti_sar
	gen main_acti_sar 		= lfp_sar
	
	recode main_acti_sar ( 1 = 11 ) ( 2 = 12 )
	replace main_acti_sar	= 11 if inc_d_total > 10 & inc_d_total != . & ( main_acti_sar == 0 |  main_acti_sar == .) // It is good that no replace takes place. Since we have cover the employment questions. 
	
	
	* OLF: Reasons ::: EA6C
	replace main_acti_sar	= 1 if m14 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .) // In School / Training
	replace main_acti_sar	= 2 if ea23 == 1 & ( main_acti_sar == 0 |  main_acti_sar == .) // help in a family business or farm?
	// work in… ? FARMING /REARING FARM ANIMALS 
	
	replace main_acti_sar	= 10 if ea7b == 5 & ( main_acti_sar == 0 |  main_acti_sar == .)  // Family responsibilities 
	
	label define main_acti_sar  0 "Outside of LF" 1 "In School / Training" 2 "Help family B/W" 3 "Farm related"  4 "OPG: Gather" 5 "OPG: Hunt" 6 "OPG: Food preparation" 7 "OPG: Construction" 8 "OPG: Making goods for HH" 9 "OPG: Fetch water firewood" 10 "Family responsibilities"  11 "Employed" 12 "Unemployed" , modify 
	label val main_acti_sar main_acti_sar
	
	tab main_acti_sar
	bys female:	tab main_acti_sar		if age >= 15 & age < 66 [iw = wgt ]
	bys female:	tab lfp_sar				if age >= 15 & age < 66 &  m14 != 1 [iw = wgt ]
	
	
	bys female : tab ea6c
	bys female : tab ea6d
	
		
	/*
	Studying: 
	m14		(Nom) poursuit-il toujours ses �tudes ?
	
	Availability:
	ea3		Bien que vous n'ayez pas travaill� les 7 derniers jours, aviez-vous un emploi
	ea6d	Seriez-vous disponible pour travailler ?
	ea7a 	Malgré que vous n’ayez pas cherché un emploi et/ou n’êtes pas disponible pour travailler, accepeteriez-vous un emploi si on vous en propose ?
	
	Reason not to search job:	
	ea6c	Pourquoi n�avez-vous pas cherch� du travail (ou ne d�sirez-vous pas travail
	
	-> female = Female

  ea6c.Pourquoi n�avez-vous pas cherch� |
     du travail (ou ne d�sirez-vous pas |
                                travail |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                Il n'exist pas d'emploi |        795        6.82        6.82
Ne pense pas pouvoir obtenir de trav. s |         86        0.74        7.55
Ne sait pas comment rechercher un emplo |         41        0.35        7.91
Attend la reponse  � une demande d'empl |         24        0.21        8.11
Attend la r�ponse � une demande de fina |          5        0.04        8.15
         Fatigu� de chercher du travail |         23        0.20        8.35
Attend une annonce de recrutement 8. Au |         21        0.18        8.53
              Autre raison involontaire |        298        2.56       11.09
N'en a pas besoin ou n'a pas envie de t |      2,475       21.22       32.31
            Raison sociale ou familiale |      3,615       31.00       63.30
 Trop jeune ou trop �g� pour travailler |      1,791       15.36       78.66
                Autre raison volontaire |      2,489       21.34      100.00
----------------------------------------+-----------------------------------
	
	Reason not to work:	
	ea7b	Vous ne travaillez pas (ou vous n’êtes pas disponible à travailler) parce que vous êtes
	-> female = Female

   ea7b.Vous ne travaillez pas (ou |
   vous n��tes pas disponible pour |
                  travailler) parc |      Freq.     Percent        Cum.
-----------------------------------+-----------------------------------
                          Handicap |        145        1.33        1.33
            Malade de longue dur�e |        311        2.86        4.20
En cours de scolarit�, �tudiant(e) |      2,679       24.66       28.86
                Retrait�/vieillard |        813        7.48       36.34
                    Femme au foyer |      5,478       50.42       86.76
                           Rentier |        412        3.79       90.56
                             Autre |      1,026        9.44      100.00
-----------------------------------+-----------------------------------
                             Total |     10,864      100.00

	
	This set of questions is not available in the survey: 
	
	SE1. Au cours des 7 derniers jours, avez-vous effectué une ou plusieurs des activités suivantes ?
(notez le nombre d'heures correspondantes)
	Own production information cannot be retreived as a result
	
	1. Etudes (scolaires)

	2. Travaux domestiques dans sa propre maison,

	3.  Garde d'enfants, de personnes âgées, 
		de malades, sans  rémunération

	4. Chercher de l'eau ou du bois, 

	5. Faire le marché

	6. Construction de sa propre maison

	7. Prestation de services gratuits à sa communauté

	8. Aucune de ces activités     (écrire 1 dans le bac)

	This set of quesitons are tried to be included in main_acti: 
	ea1 ea21 ea22 ea23 ea24 ea25 ea27 ea26 ea28 ea29
	*/
	
	* >> Main activity components
	tab main_acti , gen(macti_)
	
	gen order_mainacti = main_acti_sar
	recode order_mainacti (11 = -2 ) (12 = -1)
	
	* >>  # Number of kids in the household 
	*gen age = m4 
	gen child_d = age <= 17
	bys i1 i2 : egen tot_children = total(child_d)
	order  i1 i2 ind1 age tot_children 
	
	gen uno = 1
	
	
	// >>> Firm size WB --------------
recode ap5 (1 2 3 4 5 = 1) (6 = 2) (7 8 9 =3 ), gen(firm_size_WB_)
lab def firm_size_WB_ 1 "Small: 5-19" 2 "Medium: 20-49" 3 "50+"  // Its not possible small= 5-19; medium = 20-99; large = 100+ since the original variable dont has this categories
lab val firm_size_WB_ firm_size_WB_
tab firm_size_WB_, gen(firm_size_WB_)
lab var firm_size_WB_1  "Size: Small: 5-19"
lab var firm_size_WB_2  "Size: Medium: 20-49"
lab var firm_size_WB_3  "Size: 50+"
	
	*------------------------------------------------------------------------------*
	*--------------------------- Descriptive Stats --------------------------------*
	*------------------------------------------------------------------------------*
	label define sex_fem 100 "Female" , modify 
	label define urban 1 "Urban" 100 "Urban" 0 "Rural" , modify
	label define origin  100 "National"  , modify
	label val urban urban 
	
	rename educ_ edu_categ
	
	desc urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw week_hours neet look_last7 look_last30
	*global shares urban w_wap female born_here educ_* neet js1 js2  macti_* informality
	global shares  urban w_wap female born_here educ_* neet look_last7 look_last30  macti_* informality
	
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
		rename look_last*		j_look_last*
		rename macti_*			k_macti*
		
		desc *_`categ' , varlist
		di r(varlist)
		
		local byvar = substr("`r(varlist)'" , 3, .)
		di "`byvar'"
			
		tempfile stat1 stat2 `byvar'
		
		
		qui noi tabstat a_urban b_w_wap c_female d_born_here e_educ* f_informality g_inc_d_salw g_inc_d_selfw g_inc_d_total g_inc_by_hour h_week_hours* i_neet j_look* k_macti* ///
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
		
		export excel using "${dir_out}/Tables/Z_Descriptive_statistics.xlsx" if type != "obs" , sheet("MRT By `byvar'" , replace)  firstrow(varl)	
		export excel using "${dir_out}/Tables/Z_Descriptive_statistics_obs.xlsx" if type == "obs" , sheet("MRT By `byvar'" , replace)  firstrow(varl)	
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
			
			export excel using "${dir_out}/Tables/Z_Descriptive_statistics.xlsx" if type != "obs"  , sheet("MRT Total" , replace)  firstrow(varl)
			
			export excel using "${dir_out}/Tables/Z_Descriptive_statistics_obs.xlsx" if type == "obs"  , sheet("MRT Total" , replace)  firstrow(varl)	
			
		restore 
}
}	
	
	
	*---------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
	*---------------------------------------------------------------------*	
	*---------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
	*---------------------------------------------------------------------*
	*---------------------------------------------------------------------*
	*----------------------------- Graphs --------------------------------*
	*---------------------------------------------------------------------*
		
	
** Hours worked CDF
	sort female week_hours
	cap drop cum_hw_m cum_hw_f
	cumul week_hours if female == 0 , gen(cum_hw_m) eq
	cumul week_hours if female == 1 , gen(cum_hw_f) eq
	
	replace cum_hw_f = cum_hw_f*100
	replace cum_hw_m = cum_hw_m*100
	
	sum week_hours  [ aweight = wgt ] if female == 1 
		qui local mu_f = round(`r(mean)', 1)
		qui local vr_f = round(`r(sd)', 1)

	sum week_hours  [ aweight = wgt ] if female == 0 
		qui local mu_m = round(`r(mean)', 1)
		qui local vr_m = round(`r(sd)', 1)
		
	twoway (line cum_hw_m week_hours if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) (line cum_hw_f week_hours , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ,	 $grph_reg $y_axis legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )  xtitle(Hours) xtitle("# Hours worked" ) ytitle("% below # of hours") note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (vsmall) position(11) ring(0) margin(medlarge)) subti("The Gambia")  ylabel( 0(20)100, labsize(small)) xlabel( 0(10)110 , labsize(small))

	 graph export "${dir_out}/Graphs/MRT 1. Hours worked by sex.png",  as(png)    replace width(1995)  height(1452)	
	
	
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
		
		sum `inc'  [ aweight = wgt ] if female == 1 
			qui local mu_f = round(`r(mean)', 1)
			qui local vr_f = round(`r(sd)', 1)

		sum `inc'  [ aweight = wgt ] if female == 0 
			qui local mu_m = round(`r(mean)', 1)
			qui local vr_m = round(`r(sd)', 1)
			
	twoway (line cum_hw_m ln_`inc' if female == 0 , sort lwidth(medthin)  lcolor("${color3}%60") ) (line cum_hw_f ln_`inc' , sort lwidth(medthin)  lcolor("${color2}%90") lpattern(dash) ) ,	 $grph_reg $y_axis legend(order( 1 "Males" 2 "Females" )  region(lcolor(none)) )  xtitle(Hours) xtitle("`vrlab' in logs" ) ytitle("%") note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (vsmall) position(11) ring(0) margin(medlarge)) subti("Mauritania")  
		*ylabel( 0(20)100, labsize(small)) xlabel( 0(20)180 , labsize(small))
		graph export "${dir_out}/Graphs/MRT 1. `vrlab' by sex.png",  as(png)    replace width(1995)  height(1452)
	
		cap drop fx x fx_f fx_m 
	kdensity ln_`inc'  [ aweight = wgt ] if uno ==1  `limit', nograph generate(x fx)
	kdensity ln_`inc'  [ aweight = wgt ] if female == 1 `limit' , nograph generate(fx_f) at(x) `bw'
	kdensity ln_`inc'  [ aweight = wgt ] if female == 0 `limit' , nograph generate(fx_m) at(x) `bw'
		* local bw = "bw(.19)"
		
		twoway (area fx_m x, fcolor("${color3}%30") lcolor("${color3}%60")) (area fx_f x, fcolor("${color2}%30") lcolor("${color2}%60") ) if uno == 1 `bnd' , name(`inc' , replace)  $grph_reg $y_axis ytitle(" " )  xtitle("`vrlab' in logs", size(small))  legend(order( 1 "Males" 2 "Females" )  region(lcolor(white)) size(small)) ylabel(, noticks nolabels) note("Females: {&mu}{subscript:f}= `mu_f' {&sigma}{subscript:f}= `vr_f'" "Males:     {&mu}{subscript:m}= `mu_m' {&sigma}{subscript:m}= `vr_m'" , size (vsmall) position(2) ring(0) margin(medlarge)) subti("Mauritania")  
		
		graph export "${dir_out}/Graphs/MRT 2. Kernel `vrlab' by sex.png",  as(png)    replace width(1995)  height(1452)
	}
	
	graph pie [aweight = wgt] if age >=15 & female == 1 , over(main_acti)  sort(order_mainacti)    plabel(_all percent, color(white) size( tiny) format(%3.0f)) line(lcolor(black) lwidth(vvvthin)) intensity(inten90) name(Female , replace)  $grph_reg legend(region(lcolor(none))) subtitle(Females, position(10) ring(0) margin(10-pt))
	graph export "${dir_out}/Graphs/MRT 3. Main activity female.png",   replace width(1995)  height(1452)

	graph pie [aweight = wgt] if age >=15 & female == 0 , over(main_acti)  sort(order_mainacti)   plabel(_all percent, color(white) size( tiny) format(%3.0f))  line(lcolor(black) lwidth(vvvthin)) intensity(inten90) name(Male , replace)  $grph_reg legend(region(lcolor(none))) subtitle(Males, position(10) ring(0) margin(10-pt))
	graph export "${dir_out}/Graphs/MRT 3. Main activity Male.png",   replace width(1995)  height(1452)

	
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
	
	
	
	ds sector2_1  - sector2_5
	glo sector		"`r(varlist)' "
	
	ds educ_2 - educ_4 
	glo edulvl		"`r(varlist)'"
	
	glo hh_charac "tot_children "

	ds firm_size_WB_1 - firm_size_WB_3
	glo firmsize	"`r(varlist)'"
	
	
	label var ln_inc_by_hour	"LN total income per hour"
	label var ln_inc_d_total	"LN total daily income"
	label var ln_inc_d_selfw	"LN self employed income"
	label var ln_inc_d_salw		"LN salaried income"
	
	rename agesq age_sq
	
	foreach inc in ln_inc_by_hour ln_inc_d_total ln_inc_d_selfw ln_inc_d_salw  {
		if "`inc'" != "ln_inc_by_hour" {
		    local add_control = " week_hours "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		reg `inc' female age age_sq  $edulvl $sector $firmsize $hh_charac
		
		oaxaca `inc' (age: age age_sq) (edulvl: $edulvl)	$hh_charac	`add_control'  [iweight = wgt] , by(female) relax vce(r) // The effect of education on male and female income are different 
		estimates store OB_1
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector)	$hh_charac	`add_control' [iweight = wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_2
		oaxaca `inc' (age: age age_sq)  (edulvl: $edulvl) (sectors: $sector) 	$hh_charac `add_control' [iweight = wgt] , by(female) relax vce(r) // The effect of selection into economic activity
		estimates store OB_3
		
		esttab OB_1 OB_2 OB_3 using "${dir_out}/Tables/MRT 1. OB Decomposition in `vrlab'.csv" ,  stats(N ) label replace addnotes("Group 1 == Males. Group 2 == Females" )  title("Oaxaca Blinder Decomposition") b(3) t(3)
	
	
		* Nopo common support exercise 
		/*
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$hh_charac `add_control'  , outcome(ln_inc_by_hour) by(female) fact(wgt) sd filename("${dir_out}/Tables/MRT OB_N_1_`inc'") replace
		restore
		*
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$hh_charac	`add_control'  , outcome(ln_inc_by_hour) by(female) fact(wgt) sd filename("${dir_out}/Tables/MRT OB_N_2_`inc'") replace
		restore
		*
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$firmsize	$hh_charac	`add_control'  , outcome(ln_inc_by_hour) by(female) fact(wgt) sd filename("${dir_out}/Tables/MRT OB_N_3_`inc'") replace
		restore 
		*/
	}
	 
	*** Nopo not in logs
	
	* inc_d_salw
	foreach inc in inc_by_hour inc_d_total inc_d_selfw   {  
		if "`inc'" != "inc_by_hour" {
		    local add_control = " week_hours "
		}
		
		local vrlab = `"`: var label `inc' '"'
		
		* Nopo common support exercise 
		*	
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$hh_charac	`add_control'	, outcome(`inc') by(female) fact(wgt) sd filename("${dir_out}/Tables/MRT OB_N_1_`inc'") replace
		*
		restore
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$hh_charac   `add_control'  , outcome(`inc') by(female) fact(wgt) sd filename("${dir_out}/Tables/MRT OB_N_2_`inc'") replace
		*
		restore
		
		preserve
		cap noi drop _supp _match
		nopomatch age age_sq  $edulvl	$sector		$firmsize	$hh_charac	`add_control'  , outcome(`inc') by(female) fact(wgt) sd filename("${dir_out}/Tables/MRT OB_N_3_`inc'") replace
		restore
	}
	
	
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
		export excel using "${dir_out}/Tables/Z_OB_Decomposition_Nopo_summary.xlsx" ,  sheet("MRT By sex" , replace)  firstrow(varl)
	restore 
	
	
	
	
	
	
	
// >>> Workers in WAP --------------
/*

This whole chunk of code is from the gambia dofile and does not replicate. 


g w_wap = .
replace w_wap = 0 if age>=5
replace w_wap = 1 if age>=15 & w_wap < 66

// >>> Workers in WAP --------------
g w_wap = .
/*
replace w_wap = 1 if ilo_wap == 1 & cm5 !=.
replace w_wap = 0 if ilo_wap == . & cm5 !=.
lab var w_wap  "Workers in WAP"
lab def w_wap 1 "In" 0 "Out" 
lab val w_wap w_wap

* ilo_wap not available in this survey 
*/
replace w_wap = 0 if age>=5
replace w_wap = 1 if age>=15 & w_wap < 66


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


*/





/*


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

*twoway kdensity ln_inc_by_hour if empstat_1 == 1  || kdensity ln_inc_by_hour if empstat_2==1 || kdensity ln_inc_by_hour if empstat_3==1, legend(lab (1 "Self-employee/own boss") lab(2 "Salaried workers") lab(3 "Other workers")) by(hh7)
*graph export "${dir_out}Outputs\Figures\GMB\kd_estimated_status_area.png", replace
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

