* World Bank Poverty & Gender Assessment
* Guinea Bisao
* Sergio Rivera 


	use "${d_raw}\EHCVM\GNB\Datain\Menage\s01_me_GNB2021.dta", clear
	merge m:1 grappe menage using "${d_raw}\EHCVM\GNB\Datain\Menage\s00_me_GNB2021.dta", ///
	  keepusing(s00q00 s00q01 s00q02 s00q03 s00q04 s00q08 s00q23a s00q27) nogen
	merge 1:1 grappe menage s01q00a using "${d_raw}\EHCVM\GNB\Datain\Menage\s02_me_GNB2021.dta" , nogen // Educ
	merge 1:1 grappe menage s01q00a using "${d_raw}\EHCVM\GNB\Datain\Menage\s04b_me_GNB2021.dta" , nogen // Principal Employment

*** AGE 
*** calcul de l'age utilisant les dates de naissance et celle debut enquete
	rename s01q02 lien
	gen resid=0
	replace resid=1 if (s01q12==1) | (s01q12==2 & s01q13==1)
	rename s01q01 sexe

	cap drop nj na nm
	tab1 s01q03a s01q03b s01q03c, m
	replace s01q03a=15 if (s01q03a==9999 | s01q03a==.) & (s01q03b!=. & s01q03b!=9999) & (s01q03c!=. & s01q03c!=9999) //* impute day=15 if NR, but month and year valid */
	replace s01q03a=1 if (s01q03a==9999 | s01q03a==.) & (s01q03b==. | s01q03b==9999) & (s01q03c!=. & s01q03c!=9999) //* impute day=1 if NR, but year valid */
	replace s01q03b=1 if (s01q03b==9999 | s01q03b==.) & (s01q03c!=. & s01q03c!=9999) //* impute month=1, if NR but year valid */ 
	//
	replace s01q03a=30 if s01q03a==31 & s01q03b==6 /* deux individus nés le 31 juin, on corrige le 30 juin */
	** Convert date of birth in string
	recode s01q03a (9999 .a . =.)
	recode s01q03b (9999 .a . =.)
	recode s01q03c (9999 .a . =.)
	tostring s01q03a, gen(nj) 
	tostring s01q03b, gen(nm) 
	tostring s01q03c, gen(na) 
	*drop dob //nuevo
	egen dob=concat(nm nj na), punc(" ")
	gen ddn=date(dob, "MDY") 
	format ddn %tdMon_DD_CCYY 
	
	
	gen ea=substr(s00q23a,1,4)
	gen em=substr(s00q23a,6,2)
	gen ej=substr(s00q23a,9,2)
	replace em="06" if em=="09" & ea=="2022" /* erreur de mois peut-être, si questionnsires enquêtées en sept., supprimer */
	egen dd1=concat(em ej ea)
	gen dde=date(dd1, "MDY") 
	format dde %tdMon_DD_CCYY 
	lis dde in 1/30
	// ** compute age
	cap drop age2
	gen age=int((dde-ddn)/365) /* 4853 individus (sur 63556) ne connaissent par leur ddn, pas mal */
	replace age=s01q04a if age==. /* Les 4853 individus sont corrigés */
	sum age 
	tab age, m  /* il y a 10 individus de 100 ans ou plus, regarder de près et aviser */
	sum age if lien==1    //* examiner âge des CM, ils doivent avoir au moins 15 ans *//
	sum age 
	tab age if resid==1 , mi
	
	tab age, m  /* There are 7 individuals over 100 years old :: true values */
	lab var age       "Age"
	gen agesq = age^2
	
	
******
******  Caracteristiques de l'education  *********
****** 		Education variables  	**************
****** 
rename *__* *_*

*** Alphabétisation  
tab1 s02q01_1 s02q01_2 s02q01_3 s02q02_1 s02q02_2 s02q02_3, m
tab1 s02q02a_1 s02q02a_2 s02q02a_3, m
gen alfa=(s02q01_1==1 & s02q02_1==1) | ///
         (s02q01_2==1 & s02q02_2==1) | ///
         (s02q01_3==1 & s02q02_3==1) 
gen alfa2=((alfa==1) & (s02q02a_1==1 | s02q02a_2==1 | s02q02a_3==1)) 
lab var alfa "Alphabet. lire/ecrire"
lab var alfa2 "Alphabet. lire/ecrire/comprend."

lab val alfa alfa2 ouinon
tab alfa resid, m
tab alfa if resid==1 & age>=3, m
tab alfa if resid==1 & age<3, m // on doit les mettre missing; code  
tab alfa2 resid, m
tab alfa2 if resid==1 & age>=3, m
tab alfa2 if resid==1 & age<3, m // on doit les mettre missing; code   

tab alfa2 if resid==1 & age>=15, m
*** Education/Scolarisation    
** Fréquentation scolaire en 2020/21 
gen scol=(s02q12==1)
lab var scol "Freq. ecole 2020/21"
lab val scol ouinon 

** Niveau scolaire actuel, ind. scolarises en 2020/21  
clonevar educ_scol=s02q14
tab educ_scol scol, m
lab var educ_scol "Niv. educ. actuel"  
tab educ_scol scol if age>=3 & s02q03==1 & s02q12==1, m 
tab s02q29 if age>=3 & s02q03==1 & s02q12==2, m 

/** Niveau d'etudes le plus éleve: ind. qui n'ont pas fréquente l'ecole 
   2020/21 ou qui n'ont jamais eté à l'ecole */
   

   
recode s02q29 (.a=.)      
gen educ_hi=s02q29+1 if s02q29>=1 & s02q29<. 
replace educ_hi=1 if (s02q29==.) & ((s02q03!=1) | (s02q03==1 & scol==0))  /* n ind. restant en ND, revoir */
replace educ_hi=educ_scol+1 if educ_hi==. & s02q03==1 

/*
         2. Ensino Pre-escolar |        613        6.52        6.52
   3. Ensino primário 1º ciclo |      2,889       30.73       37.26
   4. Ensino primário 2º ciclo |      2,309       24.56       61.82
   5. Ensino Primário 3º ciclo |      1,472       15.66       77.48
6. Ensino Técnico/Profissional |         90        0.96       78.44
          7. Ensino Secundário |      1,286       13.68       92.12
               8. Ensino Médio |        427        4.54       96.66
            9. Ensino Superior |        314        3.34      100.00
 */
	recode educ_hi (1=1) (2=2) (3 4 5 = 3) (7=4)  (8=6) (6=8) (9=9)


	lab var educ_hi "Niv. educ. acheve"
	lab def educ_hi 1"Aucun" 2"Maternelle" 3"Primaire" 4"Second. gl 1" 5"Second. tech. 1" 6"Second. gl 2" ///
				  7"Second. tech. 2" 8"Postsecondaire" 9"Superieur"
	lab val educ_hi educ_hi

	* Diplome
	clonevar diplome=s02q33
	recode diplome (. .a=0)
	lab var diplome "Diplome plus eleve"

	***** Autres variables d'education
	gen telpor=s01q36==1
	gen internet=s01q39_1==1 | s01q39_2==1 | s01q39_3==1 | s01q39_4==1 | s01q39_5==1
	lab var telpor "Individu a telephone portable"
	lab var internet "Individu a acces internet"

	tab1 alfa alfa2 scol educ_scol educ_hi diplome telpor internet

	tab educ_hi diplome // AKind of makes sense
	* Years of education.
	replace s02q31=0 if s02q31==. & educ_hi!=.

	gen     educy = s02q31			if educ_hi==1 | educ_hi==2
	replace educy = s02q31	  		if educ_hi==3									// Primary edycation
	replace educy = 6+s02q31   		if educ_hi==4 | educ_hi==5						// Second gl1 /tech 1 (secondary education)
	replace educy = 6+4+s02q31 		if educ_hi==6 | educ_hi==7 | diplome==5 		// Second gl2 / tech 2 (vocational) 
	replace educy = 6+4+3+s02q31 	if educ_hi==8 									// Postsecondaire (préparation diplômes niveau BAC+2) 
	replace educy = 6+4+3+s02q31 	if educ_hi==9									// Superieur, any level
	replace educy = 6+4+3+4 	if diplome==5 | diplome==6							// Superieur (BAC, DEUG)
	replace educy = 6+4+3+4+2 	if educ_hi==9 | diplome==8 | diplome==9 | diplome==10	// Superieur (Master/PhD)

	lab var educy     "Years of education"

	/*
	Education variables 
	
	educ_ 
	
	*/
	
	
	// >>> Education --------------
	desc educ_* /* educ_scol educ_hi */
	tab educ_hi
	tab educ_s
	tab educ_hi educ_scol , m nolab
	
	lab var educ_scol	"Current education level"
	lab var educ_hi		"Highest education level of education achieved"
	
	recode educ_hi ( 0 1 2 . = 1 ) ( 3 4 = 2) ( 6 = 3 ) ( 8 9 = 4 ), gen(educ_)
	lab def educ_ 1 "Less than basic" 2 "Basic" 3 "Intermediate" 4 "Advanced"
	lab val educ_ educ_
	
	tab  educ_
	
	** >> Number of workers
	egen n_males = count(s01q00a) if sexe == 1 & age >= 15, by(grappe menage)
	egen n_males_ = max(n_males), by(grappe menage)
	egen n_females = count(s01q00a) if sexe == 2 & age >= 15, by(grappe menage)
	egen n_females_ = max(n_females), by(grappe menage)
	egen n_kids = count(s01q00a) if age <= 14, by(grappe menage)
	egen n_kids_ = max(n_kids), by(grappe menage)

	foreach var in n_males_ n_females_ n_kids_ {
		replace `var' = 0 if missing(`var')
	}

	g ES = (n_males_) + (n_females_ * 0.8) + (n_kids_ * 0.5)
	*g nworker = n_males_ + n_females_ + n_kids_   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Reemplazar por el numero de personas que en efecto trabajan
	egen nworker = count(s04q39), by(grappe menage)  // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Reemplazar por el numero de personas que en efecto trabajan, incluye niños
	label var ES      "Equivalised number of workers (OCDE)"
	label var nworker "Total number of workers"
	
	
	* >> Urban : s00q04 : Milieu de résidence
	tab  s00q04 , nolab
	gen urban = s00q04
	recode urban (2 = 0)
	label define area 0 "Rural" 1 "Urban"
	label val urban area 
	tab urban
	
	* >> Female: sexe : 1.01. Quel est le sexe de [NOM]
	recode sexe (2 = 1) (1 = 0), gen(female)
	label define sex_fem  0 "Male" 1 "Female" , modify
	label define sex_fem 100 "Female" , modify 
	label val female sex_fem
	
	* >> Born here / Nationality s01q15 :  1.15. De quelle nationalité est [NOM] ?
	gen born_here = 0
	replace born_here = 1 if s01q15 == 8
	label define origin  0 "Foreign" 1 "National" , modify 
	label val born_here origin 
	
	* >> Contract INFORMAL
	recode s04q38 (1 = 0) (2 = 1), gen(informality)
	label var informality "Informal by investment to retire"
	
	**************************
	* WORK RELATED VARIABLES *
	**************************
	* >>  Hours 
	desc s04q37 //  4.37. Combien d'heures par jour [NOM] consacre habituellement à et emploi?
	gen hours = s04q37
	label var hours  "Hours worked per day usually"
		
	// Salary workers vs. non-salary workers
	g salary_w = 1 if inlist(s04q39, 1,2,3,4,5,6)
	replace salary_w = 0 if inlist(s04q39, 7,8,9,10)
	lab def salary_w 1 "Salary workers" 0 "Non-salary workers"
	lab val salary_w salary_w
	
*	>> Occupational position
	g ocu_pos = s04q39
	lab def ocu_pos 1 "Senior manager" 2 "Middle management/supervisor" 3 "Qualified worker " 4 "Unskilled worker or employee" 5 "Laborer, housekeeper" 6 "Paid trainee or apprentice" 7 "Unpaid trainee " 8 "Family worker" 9 "Own account worker" 10 "Boss/Employer" 
	lab val ocu_pos ocu_pos
	
*	>> Employment status 
	gen     empstat_=2 if salary_w==1
	replace empstat_=1 if inlist(s04q39, 9,10)
	replace empstat_=3 if inlist(s04q39, 7,8)
	tab empstat_, gen(empstat_)
	tab empstat_
	
	lab var empstat_1 "Self-employee/own boss"
	lab var empstat_2 "Salaried workers"
	lab var empstat_3 "Other workers"
	lab def empstat_ 1 "Self-employee/own boss" 2 "Salaried workers" 3 "Other workers"
	lab val empstat_ empstat_
	
*	>>  Occupational position + SOEs
	gen     empstat2_=2 if salary_w==1
	replace empstat2_=1 if inlist(s04q39, 9,10)
	replace empstat2_=3 if empstat2_ == 2 & s04q31 == 2
	replace empstat2_=4 if inlist(s04q39, 7,8)
	tab empstat2_, gen(empstat2_)


	lab var empstat2_1 "Self-employee/own boss"
	lab var empstat2_2 "Salaried workers"
	lab var empstat2_3 "SOEs salaried workers"
	lab var empstat2_4 "Other workers"

*	>> Sector
	g sector = s04q30b
	lab def sector 1 "Agriculture" 2 "Extractive activities" 3 "Manufacturing activities" ///
					4 "Production electricity" 5 "Water distribution" 6 "Construction" ///
					7 "Wholesale retail " 8 "Transportation" 9 "Accommodation" 10 "ICT" ///
					11 "Financial" 12 "Real estate" 13 "Professional" 14 "Administrative activities" ///
					15 "Public administration" 16 "Education" 17 "Health" 18 "Arts/entertainment" ///
					19 "Other service activities" 20 "Activities private households" 
	lab val sector sector
	recode sector (1=1) (3=2) (2 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 = 3), gen(sector_)
	tab sector_, gen(sector_) //  - This is ok
	lab var sector_1  "Sector: Agriculture"
	lab var sector_2  "Sector: Manufacture"
	lab var sector_3  "Sector: Services"
	
*	>> Sector 2: splitting services
	gen s04q30d_str = string(s04q30d)
	replace s04q30d_str = "" if s04q30d_str == "."
	gen s04q30d_4digit = cond(strlen(s04q30d_str) == 1, "000" + s04q30d_str, cond(strlen(s04q30d_str) == 2, "00" + s04q30d_str, cond(strlen(s04q30d_str) == 3, "0" + s04q30d_str, s04q30d_str)))

	gen s04q30d_2digit = substr(s04q30d_4digit, 1, 2)

	g sector2_ = sector_
	replace sector2_ = 4 if sector2_ == 3
	replace sector2_ = 3 if inlist(s04q30d_2digit,"45","46","47") & sector2_ == 4
	replace sector2_ = 5 if (s04q30d_2digit == "64" | s04q30d_2digit == "65" | s04q30d_2digit == "66" | s04q30d_2digit == "68" | s04q30d_2digit == "69" | s04q30d_2digit == "70" | s04q30d_2digit == "71" | s04q30d_2digit == "72" | s04q30d_2digit == "73" | s04q30d_2digit == "74" | s04q30d_2digit == "75" | s04q30d_2digit == "58" | s04q30d_2digit == "59" | s04q30d_2digit == "60" | s04q30d_2digit == "61" | s04q30d_2digit == "62" | s04q30d_2digit == "63" | s04q30d_2digit == "78" | s04q30d_2digit == "80" | s04q30d_2digit == "82" | s04q30d_2digit == "84" | s04q30d_2digit == "85" | s04q30d_2digit == "86" | s04q30d_2digit == "87" | s04q30d_2digit == "88") & sector2_ == 4


	tab sector2_, gen(sector2_)
	lab var sector2_1  "Sector: Agriculture"
	lab var sector2_2  "Sector: Manufacture"
	lab var sector2_3  "Sector: Trade services"
	lab var sector2_4  "Sector: Low-skilled services"
	lab var sector2_5  "Sector: High-skilled services"
	
	
*	>> Sector 3: splitting services (!!! Variables s04q30* are completely different to the 2018 ones)

	g sector3_ = sector_
	replace sector3_ = 4 if sector_ == 3
	replace sector3_ = 3 if inlist(s04q30d_2digit,"45","46","47") & sector3_ == 4

	tab sector3_, gen(sector3_)
	lab var sector3_1  "Sector: Agriculture"
	lab var sector3_2  "Sector: Manufacture"
	lab var sector3_3  "Sector: Trade services"
	lab var sector3_4  "Sector: Other services"

	
*	>> Income 
	desc urban w_wap female born_here educ_1 educ_2 educ_3 educ_4 informality inc_by_hour inc_d_total inc_d_selfw inc_d_salw week_hours neet look_last7 look_last30
	
*	>> Skill-level
recode s04q29c ( 1/399 = 3) ( 400/899 = 2) ( 900/999 = 1) (9011 9021 9031 =.), gen(skillLev)

	
	save  "${d_raw}\working\GNB_individual.dta" , replace 
	
	
	
	/* Notes on DATA
	I cannot find the observation weight 
	
	AUTOCONSUMPTION IS RATHER OWN PRODUCTION OF GOODS for CONSUMPTION
	
	*/

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	