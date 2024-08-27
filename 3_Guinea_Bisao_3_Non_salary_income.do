*	World Bank Poverty & Gender Assessment
*	Guinea Bisao
*	Sergio Rivera 
*	Non-salary income. Enterprises.

*	Following: Sarango-Iturralde Alexander
*	Created: May 13, 2024

	use "${d_raw}\EHCVM\GNB\Datain\Menage\s10b_me_GNB2021.dta", clear

	/* Variables of interest 	
variable name   type    format     label      variable label
--------------------------------------------------------------------------------------------------------------------------------
s10q48          long    %6.0f                 10.48. Mt obt sur vent de prod transfrm par l'entr pdtLeDernMois où etrp a fonct
s10q50          long    %6.0f                 10.50. Mtt obt sur lé serv rendus par l'entrp pdtLeDernMois où l'entrp a fonct
s10q49          long    %6.0f                 10.49. Mt dép en achat d mat 1res pr prod venduspdtLeDernMois où entrp a fonct
s10q51          long    %6.0f                 10.51. Mt dépensé en autres cons intermédiaires pdtLeDernMois où l'entrp a fonct
s10q52          long    %6.0f                 10.52. Mt dépensé en frais d loyer/eau/électric pdtLeDernMois où l'entrp a fonct
s10q53          long    %6.0f                 10.53. Mt dép en frais d serv pr utiliser des équip pdtLeDernMois où entp a fnct
s10q54          long    %6.0f                 10.54. Mtt dép en autres frais et services pdtLeDernMois où l'entrp a fonct
s10q56          long    %6.0f                 10.56. Mtt autres impôts et taxes payés par l'entreprise pdt les 12 dern mois
s10q57          long    %6.0f                 10.57. Mt des frais admin non réglemen payés par l'entrp pdt les 12 dern mois
	*/
	
	
*	>> Daily income  
	foreach var in s10q48 s10q50 s10q49 s10q51 s10q52 s10q53 s10q54 s10q56  s10q57 {
		replace `var' = 0 if missing(`var')
	}

	gen income_noagr_d = ((s10q48 + s10q50) - (s10q49 + s10q51 +s10q52 + s10q53 + s10q54 + (s10q56/12) + (s10q57/12)))/30 
	// Sales of products and services minus costs (net) Daily
	
	collapse (sum) income_noagr_d, by (grappe menage)
	
	save "${d_raw}\working\GNB_income_enter_noagr.dta" , replace
	
*	>> Hours
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s10b_me_GNB2021.dta", clear

	keep grappe menage s10q61a_* s10q61b_* s10q61c_* s10q61d_* s10q61_*
	bys grappe menage: gen idL=_n // Each business within HH

	reshape long s10q61a_ s10q61b_ s10q61c_ s10q61d_ s10q61_ , i(grappe menage idL) j(idInd)
	keep if s10q61a_==1 // Those who work on this

	replace s10q61b_=. if s10q61b_==9999

	collapse (sum) s10q61b_ s10q61c_ s10q61d_ , by(grappe menage s10q61_ )

	rename s10q61b_ nab_months
	rename s10q61c_ nab_days
	rename s10q61d_ nab_hours

	gen nab_tothours=(nab_months*nab_days*nab_hours)/(12*30) // Hours per day
	label var nab_tothours "Total hours in non-agric businesses per day"

	replace nab_tothours=14 if nab_tothours>14 & nab_tothours!=. // Add a cap 


	rename s10q61_ s01q00a

	merge m:1 grappe menage using "${d_raw}\working\GNB_income_enter_noagr.dta"  , nogen

	gen nab_incomepc = income_noagr_d/nab_tothours
	label var nab_incomepc "Income per hour from non-agric businesses, individual"
	
	*winsor2 nab_incomepc, replace cuts(1 99)
	*hist nab_incomepc
	save "${d_raw}\working\GNB_income_enter_noagr_individual.dta", replace



// Section 16. Agriculture -----------------------------------------------------
use "${d_raw}\EHCVM\GNB\Datain\Menage\s16d_me_GNB2021.dta", clear

*	>> Daily income 
	foreach var in s16dq06 s16dq10 {
		replace `var' = 0 if missing(`var')
	}

	gen income_agr_d = (s16dq06 + s16dq10)/360
	collapse (sum) income_agr_d, by (grappe menage )

save "${d_raw}\working\GNB_income_agr.dta", replace

// Hours
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s16a_me_GNB2021.dta", clear

	keep grappe menage ///
				s16aq33b_* s16aq33a_* ///
				s16aq35b_* s16aq35a_* ///
				s16aq37b_* s16aq37a_*
	bys grappe menage: gen idL=_n // Each farm entry within HH

	reshape long s16aq33b_ s16aq33a_ ///
				 s16aq35b_ s16aq35a_ ///
				 s16aq37b_ s16aq37a_ , i(grappe menage idL) j(idInd)

	rename 	s16aq33* s16aq*_P1
	rename 	s16aq35* s16aq*_P2
	rename 	s16aq37* s16aq*_P3
		
	reshape long s16aqa__P s16aqb__P , i(grappe menage idL idInd) j(Preg)
	replace s16aqb__P=. if s16aqb__P==9999
		
	collapse (sum) s16aqb__P , by(grappe menage s16aqa__P)
	drop if s16aqa__P==.

	rename s16aqb__P agb_days
	label var agb_days "Total days in agricultural tasks"
	replace agb_days=360 if agb_days>360 & agb_days!=.

	gen agb_tothours = agb_days*12/360 // Hours per day, set 12 hours per day
	label var agb_tothours "Total hours in agricultural tasks per day"


	rename s16aqa__P s01q00a

	merge m:1 grappe menage using "${d_raw}\working\GNB_income_agr.dta", nogen
	merge m:1 grappe menage using "${d_raw}\working\GNB_ehcvm_aut_GNB2021.dta", nogen

	gen agricY=income_agr_d*360
	egen income_agr_y=rowtotal(agricY A1_Agriculture_Food)
	drop agricY

	gen agb_incomepc = (income_agr_y)/(agb_tothours*360)
	label var agb_incomepc "Income per hour from agric businesses, individual"

	*winsor2 agb_incomepc, replace cuts(1 99)
	*hist agb_incomepc  // Ok!
	save "${d_raw}\working\GNB_income_agr_individual.dta", replace


// Section 17. Livestock -------------------------------------------------------
use "${d_raw}\EHCVM\GNB\Datain\Menage\s17_me_GNB2021.dta", clear

*	>> Daily income 

	foreach var in s17q13 s17q21 s17q26 s17q40 s17q14 s17q24a s17q24b s17q55 s17q57 s17q59 s17q61 s17q35 s17q46 {
		replace `var' = 0 if missing(`var')
	}

	g income_livestock_d = (((s17q13 + s17q21 + s17q26 + s17q40) - (s17q14 + s17q24a + s17q24b + s17q55 + s17q57 + s17q59 + s17q61)) / 360) + s17q35 + (s17q46/30)
	collapse (sum) income_livestock_d, by (grappe menage )

	save "${d_raw}\working\GNB_income_livestock.dta", replace

	* ASK ABOUT INDIVIDUAL income here! 
	// Section 18. Fishing ---------------------------------------------------------
	* Three part answer or sources of fishing income. Cost, sales, 
	// a.
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s18_1_me_GNB2021.dta", clear

	collapse (sum) s18q09 s18q10 s18q11 s18q12 s18q13, /// s18q08__1 s18q08__3 s18q08__4 s18q08__5 s18q08__2
	 by(grappe menage )

	save "${d_raw}\working\\GNB_cost_fish.dta", replace

	// b.
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s18_2_me_GNB2021.dta", clear

	collapse (sum) s18q19, by(grappe menage )

	save "${d_raw}\working\GNB_sales1_fish.dta", replace

	// c.
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s18_3_me_GNB2021.dta", clear

	collapse (sum) s18q25, by(grappe menage )

	merge 1:1 grappe menage using "${d_raw}\working\GNB_cost_fish.dta"
	drop _merge

	merge 1:1 grappe menage using "${d_raw}\working\\GNB_sales1_fish.dta"
	drop _merge

	foreach var in s18q25 s18q10 s18q11 s18q12 s18q13 /// s18q08__1 s18q08__3 s18q08__4 s18q08__5 s18q08__2 
	s18q19 {
		replace `var' = 0 if missing(`var')
	}

	*g income_fishing_d = ((s18q19 + s18q25)/30) - (( s18q10 + s18q11 + s18q12 + s18q13 + s18q08__1 + s18q08__3 + s18q08__4 + s18q08__5 + s18q08__2)/360) 

	g income_fishing_d = ((s18q19 + s18q25)/30) - (( s18q10 + s18q11 + s18q12 + s18q13)/360) 

	keep grappe menage income_fishing_d

	save "${d_raw}\working\GNB_income_fish.dta", replace

// Hours fishing activities 
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s18_1_me_GNB2021.dta", clear
	keep if s18q01==1 // Those who fish

	egen season_high= rowtotal(s18q06_1__*)
	egen season_mid = rowtotal(s18q06_2__*)

	keep grappe menage s18q02__0 s18q02__1 s18q02__2 season_high season_mid

	bys grappe menage: gen idL=_n

	reshape long s18q02__ , i(grappe menage idL) j(idInd)

	gen fish_hours = 14*30*season_high + 7*30*season_mid // Let's assume in high season, 14 hours per day; in mid season, 7 days

	collapse (sum) fish_hours , by(grappe menage s18q02__ )


	gen fish_tothours=(fish_hours)/(12*30) // Hours per day
	label var fish_tothours "Total hours in fishing per day"


	replace fish_tothours=14 if fish_tothours>14 & fish_tothours!=. // Add a cap 

	rename s18q02__ s01q00a

	merge m:1 grappe menage using "${d_raw}\working\GNB_income_fish.dta", nogen
	merge m:1 grappe menage using "${d_raw}\working\GNB_ehcvm_aut_GNB2021.dta", nogen
	 

	gen agricY=income_fishing_d*360
	egen income_fish_y=rowtotal(agricY A116_Fish)
	drop agricY

	gen fish_incomepc = income_fish_y/(fish_tothours*360)
	label var fish_incomepc "Income per hour from fishing, individual"

	winsor2 fish_incomepc, replace cuts(1 99)
	hist fish_incomepc  // Ok!
	save "${d_raw}\working\GNB_income_fish_individual.dta", replace
		
	
	
// Section 19.  Agricultural equipment------------------------------------------
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s19_me_GNB2021.dta", clear

	/* 
	Questions of interest in the EHCVM2018 for each code of the HIT templates:

	Income – Code 42. Profits of investment (rent, interests)
	-	19.11. Quelle somme le ménage a-t-il reçue pour la location de [….]?

	No se toma en cuenta porque no se sabe cada cuanto recibe este ingreso
	*/

	// Replace missings by 0
	foreach var in s19q11{
		recode `var' (9999 9998 . .a =0)
	}
		
	* Collapse the sum of income from rents of agricultural equipment by household
	collapse (sum) s19q11, by(grappe menage)

	ren s19q11 income_fishing_d

	compress
				
	save "${d_raw}\working\GNB_income_agrequip.dta", replace

		
	
	*-------------------------------------------------------------------------------
	*-------------------------------Non-salary Income by household------------------
	*-------------------------------------------------------------------------------
	use "${d_raw}\working\GNB_individual.dta", clear
	collapse (first) ES nworker (mean) hours age female educy sector_* empstat_* rural , by(grappe menage)
	gen agesq = age^2
	save "${d_raw}\working\GNB_eqhh_size.dta", replace


	use "${d_raw}\EHCVM\GNB\Dataout\ehcvm_welfare_GNB2021.dta",clear

	merge 1:1 grappe menage using "${d_raw}\working\GNB_income_enter_noagr.dta", nogen
	merge 1:1 grappe menage using "${d_raw}\working\GNB_income_agr.dta", nogen
	merge 1:1 grappe menage using "${d_raw}\working\GNB_income_livestock.dta", nogen
	merge 1:1 grappe menage using "${d_raw}\working\GNB_income_fish.dta", nogen
	merge 1:1 grappe menage using "${d_raw}\working\GNB_eqhh_size.dta", nogen

	*Agregar el autoconsumo
	merge 1:1 grappe menage using "${d_raw}\working\GNB_ehcvm_aut_GNB2021.dta", nogen

	g self_income = (income_noagr_d + income_agr_d + income_livestock_d + income_fishing_d + income_autocons_d)
	g self_income_pc = self_income/nworker

	save "${d_raw}\working\GNB_self_income.dta", replace

	*-------------------------------------------------------------------------------
	*-------------------------------Non-salary Income by individual-----------------
	*-------------------------------------------------------------------------------
	use "${d_raw}\working\GNB_individual.dta", clear

	merge 1:1 grappe menage s01q00a using "${d_raw}\working\GNB_income_enter_noagr_individual.dta", nogen
	merge 1:1 grappe menage s01q00a using "${d_raw}\working\GNB_income_agr_individual.dta", nogen
	*merge 1:1 grappe menage s01q00a using "${d_raw}\working\GNB_income_livestock_.dta", nogen  // 
	merge 1:1 grappe menage s01q00a using "${d_raw}\working\GNB_income_fish_individual.dta", nogen

	egen self_incomeV2_pc = rowtotal( agb_incomepc nab_incomepc fish_incomepc ), missing
	keep grappe menage s01q00a self_incomeV2_pc ///
			agb_incomepc nab_incomepc fish_incomepc ///
			agb_tothours agb_days fish_tothours nab_tothours

	save "${d_raw}\working\GNB_self_income_individual.dta", replace


	
	
	
	di "${d_raw}\working\"
	di "${d_raw}\EHCVM\GNB\Datain\Menage"
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	