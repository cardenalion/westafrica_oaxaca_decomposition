*	World Bank Poverty & Gender Assessment
*	Guinea Bisao
*	Author: Sergio Rivera 
* Own production variables

* Builkding on the work of: 
* Autoconsumption items for the HIT model - using the EHCVM 2018
* Author: Bernardo Atuesta
* Lastest update: 5/31/2023

/*
Objective: This dofile creates the autoconsumption aggregates of the autoconsumption 
templates of the HIT model, with some modifications (including the category for bread).

Data: The household survey EHCVM 2018-2019 of Benin (BEN), Burkina Faso (BFA), Chad (TCD),
Cote d'Ivoire (CIV), Guinea (GIN), Guinea-Bissau (GNB), Mali (NLI), Niger (NER),
Senegal (SEN) and Togo (TGO). 
I use the latest version of the file that was created for the consumption 
aggregate for poverty measurement "ehcvm_conso_`cty'2018.dta". This dataset 
has annual expenditure and autoconsumption of food and non-food items per 
household, already cleaned up and without outliers (after a trimming process,
which puts the maximum non-outlier value to outliers). 

Note: I do not do any treatment for outliers given that the data used has already 
treated the outliers.
*/

	** Open the latest version of the consumption file for `cty'
	use "${d_raw}\EHCVM\GNB\Dataout\ehcvm_conso_GNB2021.dta", clear 

	* Each row in this data file represents an agricultural product per household:
	duplicates report grappe menage codpr

	* Correct some errors (less than 0.1% of obs in some countries) of depan variable
	replace depan = 0 if depan<0

	/*
	modep: Mode d'acquisition
	1. Achat
	2. Autoconso
	3. Don
	4. Valeur usage BD
	5. Loyer imputee
	*/

	* Keep only autoconsumption
	keep if modep == 2


	/* Generate a variable with the codes of the HIT autoconsumption template at 
		the 4-digit level, harmonized with the EHCVM product codes - Only 
		agricultural products have 3 digits in the HIT templates */
	gen codaut4d = .

	replace codaut4d =	1113	if codpr ==	1
	replace codaut4d =	1113	if codpr ==	2
	replace codaut4d =	1113	if codpr ==	3
	replace codaut4d =	1113	if codpr ==	4
	replace codaut4d =	1111	if codpr ==	5
	replace codaut4d =	1111	if codpr ==	6
	replace codaut4d =	1114	if codpr ==	7
	replace codaut4d =	1114	if codpr ==	8
	replace codaut4d =	1112	if codpr ==	9
	replace codaut4d =	1114	if codpr ==	10
	replace codaut4d =	1114	if codpr ==	11
	replace codaut4d =	1111	if codpr ==	12
	replace codaut4d =	1114	if codpr ==	13
	replace codaut4d =	1112	if codpr ==	14
	replace codaut4d =	1114	if codpr ==	15
	replace codaut4d =	1282	if codpr ==	16
	replace codaut4d =	1193	if codpr ==	17 // This enters in a new code for products made with wheat (like bread) in the HIT templates
	replace codaut4d =	1193	if codpr ==	18 // This enters in a new code for products made with wheat (like bread) in the HIT templates
	replace codaut4d =	1193	if codpr ==	19 // This enters in a new code for products made with wheat (like bread) in the HIT templates
	replace codaut4d =	1193	if codpr ==	20 // This enters in a new code for products made with wheat (like bread) in the HIT templates
	replace codaut4d =	1193	if codpr ==	21 // This enters in a new code for products made with wheat (like bread) in the HIT templates
	replace codaut4d =	1193	if codpr ==	22 // This enters in a new code for products made with wheat (like bread) in the HIT templates
	replace codaut4d =	1172	if codpr ==	23
	replace codaut4d =	1174	if codpr ==	24
	replace codaut4d =	1174	if codpr ==	25
	replace codaut4d =	1174	if codpr ==	26
	replace codaut4d =	1174	if codpr ==	27
	replace codaut4d =	1171	if codpr ==	28
	replace codaut4d =	1173	if codpr ==	29
	replace codaut4d =	1173	if codpr ==	30
	replace codaut4d =	1173	if codpr ==	31
	replace codaut4d =	1192	if codpr ==	32
	replace codaut4d =	1174	if codpr ==	33
	replace codaut4d =	1174	if codpr ==	34
	replace codaut4d =	1161	if codpr ==	35
	replace codaut4d =	1161	if codpr ==	36
	replace codaut4d =	1161	if codpr ==	37
	replace codaut4d =	1161	if codpr ==	38
	replace codaut4d =	1161	if codpr ==	39
	replace codaut4d =	1161	if codpr ==	40
	replace codaut4d =	1161	if codpr ==	41
	replace codaut4d =	1162	if codpr ==	42
	replace codaut4d =	1192	if codpr ==	43
	replace codaut4d =	1181	if codpr ==	44
	replace codaut4d =	1184	if codpr ==	45
	replace codaut4d =	1181	if codpr ==	46
	replace codaut4d =	1181	if codpr ==	47
	replace codaut4d =	1181	if codpr ==	48
	replace codaut4d =	1183	if codpr ==	49
	replace codaut4d =	1192	if codpr ==	50
	replace codaut4d =	1184	if codpr ==	51
	replace codaut4d =	1182	if codpr ==	52
	replace codaut4d =	1184	if codpr ==	53
	replace codaut4d =	1151	if codpr ==	54
	replace codaut4d =	1151	if codpr ==	55
	replace codaut4d =	1151	if codpr ==	56
	replace codaut4d =	1151	if codpr ==	57
	replace codaut4d =	1151	if codpr ==	58
	replace codaut4d =	1153	if codpr ==	59
	replace codaut4d =	1135	if codpr ==	60
	replace codaut4d =	1135	if codpr ==	61
	replace codaut4d =	1133	if codpr ==	62
	replace codaut4d =	1131	if codpr ==	63
	replace codaut4d =	1133	if codpr ==	64
	replace codaut4d =	1133	if codpr ==	65
	replace codaut4d =	1135	if codpr ==	66
	replace codaut4d =	1135	if codpr ==	67
	replace codaut4d =	1135	if codpr ==	68
	replace codaut4d =	1135	if codpr ==	69
	replace codaut4d =	1144	if codpr ==	70
	replace codaut4d =	1135	if codpr ==	71
	replace codaut4d =	1143	if codpr ==	72
	replace codaut4d =	1144	if codpr ==	73
	replace codaut4d =	1144	if codpr ==	74
	replace codaut4d =	1144	if codpr ==	75
	replace codaut4d =	1144	if codpr ==	76
	replace codaut4d =	1144	if codpr ==	77
	replace codaut4d =	1242	if codpr ==	78
	replace codaut4d =	1141	if codpr ==	79
	replace codaut4d =	1141	if codpr ==	80
	replace codaut4d =	1144	if codpr ==	81
	replace codaut4d =	1144	if codpr ==	82
	replace codaut4d =	1144	if codpr ==	83
	replace codaut4d =	1241	if codpr ==	84
	replace codaut4d =	1143	if codpr ==	85
	replace codaut4d =	1143	if codpr ==	86
	replace codaut4d =	1143	if codpr ==	87
	replace codaut4d =	1143	if codpr ==	88
	replace codaut4d =	1143	if codpr ==	89
	replace codaut4d =	1144	if codpr ==	90
	replace codaut4d =	1141	if codpr ==	91
	replace codaut4d =	1122	if codpr ==	92	// Correction wrt previous version: petit pois (peas), classified as other legumens
	replace codaut4d =	1122	if codpr ==	93	// Correction wrt previous version: petit pois secs (dry peas), classified as other legumens
	replace codaut4d =	1122	if codpr ==	94	// Correction wrt previous version: other dry legumens, classified as other legumens
	replace codaut4d =	1121	if codpr ==	95	// Correction wrt previous version: Niébé/Haricots secs (beans), classified as beans
	replace codaut4d =	1263	if codpr ==	96
	replace codaut4d =	1263	if codpr ==	97
	replace codaut4d =	1263	if codpr ==	98
	replace codaut4d =	1263	if codpr ==	99
	replace codaut4d =	1282	if codpr ==	100
	replace codaut4d =	1232	if codpr ==	101
	replace codaut4d =	1261	if codpr ==	102
	replace codaut4d =	1263	if codpr ==	103
	replace codaut4d =	1144	if codpr ==	104
	replace codaut4d =	1144	if codpr ==	105
	replace codaut4d =	1131	if codpr ==	106
	replace codaut4d =	1142	if codpr ==	107
	replace codaut4d =	1144	if codpr ==	108
	replace codaut4d =	1142	if codpr ==	109
	replace codaut4d =	1144	if codpr ==	110
	replace codaut4d =	1144	if codpr ==	111
	replace codaut4d =	1282	if codpr ==	112
	replace codaut4d =	1282	if codpr ==	113
	replace codaut4d =	1281	if codpr ==	114
	replace codaut4d =	1191	if codpr ==	115
	replace codaut4d =	1282	if codpr ==	116
	replace codaut4d =	1282	if codpr ==	117
	replace codaut4d =	1246	if codpr ==	118
	replace codaut4d =	1242	if codpr ==	119
	replace codaut4d =	1246	if codpr ==	120
	replace codaut4d =	1191	if codpr ==	121
	replace codaut4d =	1192	if codpr ==	122
	replace codaut4d =	1246	if codpr ==	123
	replace codaut4d =	1192	if codpr ==	124
	replace codaut4d =	1282	if codpr ==	125
	replace codaut4d =	1282	if codpr ==	126
	replace codaut4d =	1263	if codpr ==	127
	replace codaut4d =	1282	if codpr ==	128
	replace codaut4d =	1251	if codpr ==	129
	replace codaut4d =	1252	if codpr ==	130
	replace codaut4d =	1253	if codpr ==	131
	replace codaut4d =	1252	if codpr ==	132
	replace codaut4d =	1135	if codpr ==	133
	replace codaut4d =	1191	if codpr ==	134
	replace codaut4d =	1192	if codpr ==	135
	replace codaut4d =	1192	if codpr ==	136
	replace codaut4d =	1211	if codpr ==	137
	replace codaut4d =	1212	if codpr ==	138
	replace codaut4d =	1151	if codpr ==	139 // This code is only in SEN
	replace codaut4d =	1151	if codpr ==	140 // This code is only in SEN	
	replace codaut4d =	1192	if codpr ==	151
	replace codaut4d =	1192	if codpr ==	152
	replace codaut4d =	1191	if codpr ==	161
	replace codaut4d =	1174	if codpr ==	162
	replace codaut4d =	1182	if codpr ==	163
	replace codaut4d =	1161	if codpr ==	164
	replace codaut4d =	1221	if codpr ==	201
	replace codaut4d =	1213	if codpr ==	301
	replace codaut4d =	1211	if codpr ==	302
	replace codaut4d =	1191	if codpr ==	333

	/* GNB has codes 140 to 146 and GIN has code 165, but no label in the codpr variable, so I decided to 
		eliminate those observations until I clarify the products that they represent */
		drop if codaut4d == .

	* Collapse the sum of autoconsumption by codaut4d for each household (including the identifying variables I need in the file)
	collapse (sum) depan, by(grappe menage codaut4d)

	* Reshape to have the file in wide format for the HIT model
	reshape wide depan, i(grappe menage) j(codaut4d)
	
	* Label the values at the 4-digit level
	#delimit ;
	lab def codaut4d
	1111 "Corn"
	1112 "Wheat"
	1113 "Rice"
	1114 "Other_Cereals"
	1121 "Beans"
	1122 "Other_legumens"
	1131 "Banana"
	1132 "Grapes"
	1133 "Citrus"
	1134 "Apples"
	1135 "Other_Fruits"
	1141 "Tomato"
	1142 "Potato"
	1143 "Greens"
	1144 "Other_Vegetables"
	1151 "Vegetable_Oils"
	1152 "Animal_Fats"
	1153 "Other_oils_fats"
	1161 "Fish"
	1162 "Shrimp"
	1163 "Other_Crustacean"
	1171 "Pork_Pig"
	1172 "Beef_Cattle"
	1173 "Poultry_Chicken"
	1174 "Other_meat_animals"
	1181 "Milk"
	1182 "Eggs"
	1183 "Cheese"
	1184 "Other_Dairy"
	1191 "Other_Staple_food"
	1192 "Other_Processedf"
	1193 "Bread" // This is a new code for products made with wheat (like bread) in the HIT templates
	1211 "Wine"
	1212 "Beer"
	1213 "Other_alcohol"
	1221 "Cigarettes"
	1222 "Other_tobacco"
	1231 "Soya"
	1232 "Other_oil_seeds"
	1241 "Cloves"
	1242 "Pepper"
	1243 "Vanilla"
	1244 "Saffron"
	1245 "Qat_chat"
	1246 "Other_spices"
	1251 "Coffee"
	1252 "Tea"
	1253 "Cocoa"
	1261 "Cashew"
	1262 "Coconut"
	1263 "Other_nuts"
	1271 "Cotton"
	1281 "Sugar_any_kind"
	1282 "Other_nonstaple"
	;
	#delimit cr

	
	// Change variable names and label variables at the 4-digit level
	foreach var of varlist depan1111-depan1282{
		local x = substr("`var'",-4,.) // Save in a local x the last 4 digits of each variable of the varlist
		// This is why I just ran the labeling of the codaut4d variable (otherwise it'd've been erased after the reshape command)
		local l`x': label codaut4d `x' // Save in local the value label of the autoconsumption 4-digit code of the product  
		label var `var' "A`x'_s07_Autoconsumption: Agriculture - `l`x''" 
		replace `var' = 0 if `var' == . // Replace . by 0
		rename `var' A`x'_s07_`l`x''
	}

	* Replace . with 0s
	foreach var of varlist _all{	
		replace `var' = 0 if `var' == .
	}

	/* Note: This dataset was built up from the consumption aggregate file for poverty measurement,
	which treated outliers with a trimming process (which puts the maximum non-outlier value to outliers),
	so I do not do any outlier treatment for autoconsumption items in this section. */

	sort grappe menage
	compress
	save "${d_raw}\working\GN_Aut_S07.dta", replace // Save aggregates of templates from section 07


	**////////////////////////////////////////////////////////////////
	**#//	2. Section 16b of the EHCVM - Agriculture (input costs) // 
	**////////////////////////////////////////////////////////////////
	use "${d_raw}\EHCVM\GNB\Datain\Menage\s16b_me_GNB2021.dta" , clear 
	
/* 
	Questions of interest in the EHCVM2018 for each code of the HIT templates:

	Autoconsumption template: A23. Other goods collected for free. A24. Other goods produced and consumed within the household. 
	A23. Fertilizer(in 2. Other goods)
	-	16b.03. Pouvez-vous rappeler la quantité totale de [INTRANT] utilisée durant la saison des pluies 2017/2018?
			(16b.03a: Quantity; 16b.03b: Unit)  	
	-	16b.04. Où avez-vous acquis la plupart de [INTRANT]? (1=Coopérative; 2=Marché/Boutique; 3=Autoproduction; 
					4=Autre paysan ou ménage; 5=Animaux dans le champ; 6= Structure Etatique; 7= Banque céréalière; 
					8=Autre (à préciser))
	- 	16b.06. Auprès de qui avez-vous principalement obtenu de cadeau/don ? (1=Autre ménage; 2=Etat; 3=ONG; 4=Autre (à préciser)				
	-	16b.07. Selon vous, quelle est la quantité en [INTRANT] reçue sous forme de cadeau ou de don?
			(16b.07a: Quantity; 16b.07b: Unit) 
	-	16b.09. Quelles sont la quantité et la valeur totale de [INTRANT] achetées? 
			(16b.09a: Quantity; 16b.09b: Unit; 16b.09c: Amount)  
	*/


	* Identifying missing values (there might be some cases with 9999 and 9998)
		foreach var in s16bq03a s16bq07a s16bq09a s16bq09c{
				tab `var' if `var'==97 | `var'==997 | `var'==9997 | `var'==99997 | `var'==999997 | `var'==9999997 | `var'==99999997 | ///
							 `var'==98 | `var'==998 | `var'==9998 | `var'==99998 | `var'==999998 | `var'==9999998 | `var'==99999998 | ///
							 `var'==99 | `var'==999 | `var'==9999 | `var'==99999 | `var'==999999 | `var'==9999999 | `var'==99999999 		
		}
		* There are no missing finishing in 97, 98 or 99

	// Replace . by 0 of the autoconsumption variables of the agricultural enterprise in inputs
	foreach var in s16bq03a s16bq07a s16bq09a s16bq09c{
		recode `var' (9999 9998 . .a =0)
	}
	
	/* Note: In order to obtain the value of the autoproduction and gifts of agricultural inputs 
		of this section, I need to rescale the quantities so that the total quantity, the quantity of gifts
		and the quantity bought are in the same units (kilograms). For this, I am going 
		to use the following equivalence of units (and assumptions):
	- 1000 grams = 1 kilogram 
	- 1 tone = 1000 kilograms
	- 1 liter = 1 kilogram
	- 1 Charrete = 10 kilograms
	- 1 Sac (or other) = 5 kilograms
	
	However, before generating the equivalence among units of autoconsumption, expenditure and gifts of
	agricultural inputs, it is necesary to clean some typos identified in the data. Specifically, some observations
	report differences between quantity units with the same quantity of the product used and bought, and no gifts.
	I decided to give priority to the unit reported in the quantity bought, which is the one I replace for the unit
	of the quantity used only in this cases. I also follow a trimming process of outliers in order to avoid strange
	very high values in the autoconsumption of these products.
	*/

	* Cleaning data
	replace s16bq03b = s16bq09b if (s16bq03b != s16bq09b & s16bq03a == s16bq09a & s16bq07b == . ) 
		/* There are 183 cases (1.6%) in the data of CIV */ 	
	
	* Generate total quantity, quantity of gifts and transfers and quantity bought of inputs with the same unit (kilograms)
	foreach var in s16bq03 s16bq07 s16bq09{
		gen `var'a_kg = 0  
		replace `var'a_kg = `var'a/1000 if `var'b == 1    
		replace `var'a_kg = `var'a 	   	if `var'b == 2 
		replace `var'a_kg = `var'a*1000 if `var'b == 3    
		replace `var'a_kg = `var'a      if `var'b == 4    
		replace `var'a_kg = `var'a*10   if `var'b == 5	// For a charrete unit I assume equivalence of 10kg    
		replace `var'a_kg = `var'a*5    if `var'b >= 6	// For a sac or other unit I assume equivalence of 5kg    
		replace `var'a_kg = `var'a      if `var'b == .  // I assume missing units are kilograms    		
	}	

	** Generate autoconsumption quantity of agricultural inputs 
	gen autaginput = s16bq03a_kg - s16bq07a_kg - s16bq09a_kg
	** Fix for negatives and missing values, assuming typing errors either of the unit or of the total quantity reported:
	replace autaginput = 0 if (autaginput < 0 | autaginput == . )

	* Generate variable of annual autoconsumption quantity in organic agricultural inputs	
	gen agorgq = autaginput if  (s16bq01 >= 1 & s16bq01 <= 2) | (s16bq01 >= 11 & s16bq01 <= 20)

	* Generate variable of annual autoconsumption quantity in pesticides	
	gen agpestq = autaginput if  (s16bq01 >= 7 & s16bq01 <= 10)
	
	* Generate variable of annual autoconsumption quantity in chemical fertilizer
	gen agfertq = autaginput if  (s16bq01 >= 3 & s16bq01 <= 6)		
	
	* Merge with the welfare file to use the geographic variables 
	merge m:1 grappe menage using "${d_raw}\EHCVM\GNB\Dataout\ehcvm_welfare_GNB2021.dta", nogen keep(match) keepusing(vague zae milieu)

	cap gen area = milieu
	
	* Treatment of outliers for quantity autoconsumed of agricultural input variables (following the same procedure in the consumption aggregate for poverty measurement)
	foreach var of varlist agorgq agpestq agfertq{
		gen l`var' = ln(`var') // Generate log of the variable
		egen med = median(l`var'), by(s16bq01 vague zae area) // Generate median of the log of the variable by product, zone-area
		egen iqr = iqr(l`var'), by(s16bq01 vague zae area) // Generate inter-quantile range of the log of the variable by product, zone-area
		gen lmax = med + (2.5*iqr)	// Generate the maximum value accepted for the log of the variable (median + 2.5*iqr)
		replace `var' = exp(lmax) if (lmax<l`var' & l`var'!=.)	// Replace outliers with the maximum value accepted
		drop l`var' med iqr lmax	// Drop the variable we don't need anymore
	}

	
	* Generate the value per kilogram, per item per household
	gen vkg = s16bq09c / s16bq09a_kg
	sum vkg 
	
	* Impute the vkg for missing values, with the median of the vkg by type of input and geographic variables (as disaggregated as possible)
	egen medvkg = median(vkg), by(s16bq01 milieu vague zae) // Generate median of the value per kilogram by item and zone-area
	egen med2vkg = median(vkg), by(s16bq01 milieu vague) // Generate median of the value per kilogram by item and zone-area
	replace medvkg = med2vkg if medvkg == .	// Replace missing values for zones without median of value per kilogram
 	egen med3vkg = median(vkg), by(s16bq01 milieu) // Generate median of the log of the variable by area
	replace medvkg = med3vkg if medvkg == .	// Replace missing values for areas without median of value per kilogram
 	egen med4vkg = median(vkg), by(s16bq01) // Generate median of the log of the variable
	replace medvkg = med4vkg if medvkg == .	// Replace missing values without median of value per kilogram
	// Due to the heterogeneity of the agro input "Other seeds", I prefer to use the median by product, to avoid unnecessary outliers:
	replace medvkg = med4vkg if s16bq01 == 20 

	replace vkg = medvkg if vkg == . // Impute missing values in vkg using the median of vkg by type of input and geographic variables
	
	sum vkg 
		/* Some households report very high prices of input per kilogram, so to mitigate this I decided to 
			value autoconsumption of agricultural inputs using the median of vkg by type of input and geographic 
			variables, as disaggregated as possible */
	
	* Generate variable of annual autoconsumption in organic agricultural inputs	
	gen A2300_s16b_agorg = agorgq*medvkg if  (s16bq01 >= 1 & s16bq01 <= 2) | (s16bq01 >= 11 & s16bq01 <= 20)

	* Generate variable of annual autoconsumption in pesticides	
	gen A2400_s16b_agpest = agpestq*medvkg if  (s16bq01 >= 7 & s16bq01 <= 10)
	
	* Generate variable of annual autoconsumption in chemical fertilizer
	gen A2500_s16b_agfert = agfertq*medvkg if  (s16bq01 >= 3 & s16bq01 <= 6)
	
	
	collapse (sum) A2300_s16b_agorg-A2500_s16b_agfert, by(grappe menage) // Collapse to obtain the HH value of autoconsuption from those items
	egen t = rowtotal(A2300_s16b_agorg-A2500_s16b_agfert) // Generate total autoconsuption from agricultural inputs to identify HH with value 0
	drop if (t == 0 | t == .) // Drop HH without autoconsuption from at least one of those agricultural autoconsuption sources
	drop t 

	label var A2300_s16b_agorg "A2300 s16b HH Annual autoconsumption in organic agricultural inputs"
	label var A2400_s16b_agpest "A2400 s16b HH Annual autoconsumption in pesticides"
	label var A2500_s16b_agfert "A2500 s16b HH Annual autoconsumption in chemical fertilizer"

	compress
		
	save  "${d_raw}\working\GNB_Aut_S16b.dta", replace // Save autoconsumption aggregates of templates from section 16
		
	
	**////////////////////////////////////////////////
	**//	3. Merge of all autoconsumption sources // 
	**////////////////////////////////////////////////

	* Open file with geographical information for each household	
	use "${d_raw}\EHCVM\GNB\Dataout\ehcvm_welfare_GNB2021.dta", clear	
	
	gen area = milieu
	label var area "Area (urban/rural)"
	
	
	* Merge all data sets with autoconsumption variables that need treatment of outliers
	merge 1:1 grappe menage using "${d_raw}\working\GNB_Aut_S16b.dta", nogen

	// Outliers treatment for individual variables: Winsorizing
	foreach var of varlist A2300_s16b_agorg-A2500_s16b_agfert{
		winsor2 `var' if `var'>0, replace cuts(0 99)
	}
	
	* Merge with the file of section 07, which has already treated ouliers
	merge 1:1 grappe menage using "${d_raw}\working\GN_Aut_S07.dta" , nogen 

	
	****************************************************************************
	****************************************************************************
	* Save autoconsumption file before calculating totals for each 4-digit code
	save "${d_raw}\working\GNB_ehcvm_aut_desag_GNB2021.dta" , replace 
	
		
	** Generate totals at the 4-digit level

	* Label the values at the 4-digit level
	#delimit ;
	lab def codaut4d
	1111 "Corn"
	1112 "Wheat"
	1113 "Rice"
	1114 "Other_Cereals"
	1121 "Beans"
	1122 "Other_legumens"
	1131 "Banana"
	1132 "Grapes"
	1133 "Citrus"
	1134 "Apples"
	1135 "Other_Fruits"
	1141 "Tomato"
	1142 "Potato"
	1143 "Greens"
	1144 "Other_Vegetables"
	1151 "Vegetable_Oils"
	1152 "Animal_Fats"
	1153 "Other_oils_fats"
	1161 "Fish"
	1162 "Shrimp"
	1163 "Other_Crustacean"
	1171 "Pork_Pig"
	1172 "Beef_Cattle"
	1173 "Poultry_Chicken"
	1174 "Other_meat_animals"
	1181 "Milk"
	1182 "Eggs"
	1183 "Cheese"
	1184 "Other_Dairy"
	1191 "Other_Staple_food"
	1192 "Other_Processed_food"
	1193 "Bread" // This is a new code for products made with wheat (like bread) in the HIT templates		
	1211 "Wine"
	1212 "Beer"
	1213 "Other_alcohol"
	1221 "Cigarettes"
	1222 "Other_tobacco"
	1231 "Soya"
	1232 "Other_oil_seeds"
	1241 "Cloves"
	1242 "Pepper"
	1243 "Vanilla"
	1244 "Saffron"
	1245 "Qat_chat"
	1246 "Other_spices"
	1251 "Coffee"
	1252 "Tea"
	1253 "Cocoa"
	1261 "Cashew"
	1262 "Coconut"
	1263 "Other_nuts"
	1271 "Cotton"
	1281 "Sugar_any_kind"
	1282 "Other_nonstaple"
	2100 "Energy" /// Other goods from here
	2200 "Gathering"
	2300 "Other_goods_collected"
	2400 "Other_goods_produced"
	2500 "Fertilizer" // This is a new code for chemical fertilizers in the HIT templates				
	;
	#delimit cr

	* Loop the 4-digit codes to sum up the corresponding 4-digit variables
	forvalues x=1111(1)2500{
		local l`x': label codaut4d `x' // Save in local the value label of the 4-digit code of the product  	
		* capture the following lines to keep runing in case one of the `x' does not exist (like 1212, or example)	
		cap egen A`x't_`l`x'' = rowtotal(A`x'*) // Generate totals at the 4-digit code level
		cap label var A`x't_`l`x'' "A`x'_Autoconsumption: `l`x''" 
		* After checking if the totals were ok, drop the non-total variables
		cap drop A`x'_s* // drop the non-total variables
		cap rename A`x't_`l`x'' A`x'_`l`x'' // Eliminate the t from the totals' variables name	
	}
	
	
	
	** Generate the corresponding variables at the 3-digit level
	* Label the values at the 3-digit level
	#delimit ;
	lab def codaut3d
	111 "Cereals"
	112 "Legumens"
	113 "Fruits"
	114 "Vegetables"
	115 "Oils_Fats"
	116 "Fish"
	117 "Meat_Livestock"
	118 "Dairy_Eggs"
	119 "Other_staple_food"
	121 "Alcohol"
	122 "Tobacco"
	123 "Oil_seeds"
	124 "Spices_herbs"
	125 "Coffee_tea_cocoa"
	126 "Nuts"
	127 "Cotton"
	128 "Other_nonstaple"
	;
	#delimit cr
		
	* Loop the 3-digit codes to sum up the corresponding 4-digit variables (only applicable to agriculture products)
	forvalues x=111(1)128{
		local l`x': label codaut3d `x' // Save in local the value label of the 3-digit code of the product  	
		* capture the following lines to keep runing in case one of the `x' does not exist (like 112, or example)	
		cap egen A`x'_`l`x'' = rowtotal(A`x'*) // Generate totals at the 3-digit code level
		cap label var A`x'_`l`x'' "A`x'_Autoconsumption: `l`x''" 
	}

	** Generate the corresponding variables at the 2-digit level


	* Label the values at the 2-digit level
	#delimit ;
	lab def codaut2d
	11 "StapleFood"
	12 "NonStaple"
	21 "Energy" /// Other goods from here
	22 "Gathering"
	23 "Other_goods_collected"
	24 "Other_goods_produced"
	25 "Fertilizer" // This is a new code for chemical fertilizers in the HIT templates					
	;
	#delimit cr
	
	
	forvalues x = 11(1)46{
		local l`x': label codaut2d `x' // Save in local the value label of the 2-digit code of the product  	
		* capture the following lines to keep runing in case one of the `x' does not exist (like 21, for example)	
		cap egen A`x'_`l`x'' = rowtotal(A`x'??_*) // Generate totals at the 2-digit code level
		cap label var A`x'_`l`x'' "A`x'_Autoconsumption: `l`x''" 
		* This loop drops the 4-digit codes of non-food product and leaves only the 2-digit version
		if `x' > 19 {
			cap drop A`x'00_*
		}
	}
	
	
	
	** Generate the corresponding variables at the 1-digit level

	* Label the values at the 1-digit level
	#delimit ;
	lab def codaut1d
	1 "Agriculture_Food"
	2 "Other_goods", replace
	;
	#delimit cr

	* Loop the 1-digit codes to sum up the corresponding 4-digit variables
	forvalues x=1(1)2{
		local l`x': label codaut1d `x' // Save in local the value label of the 1-digit code of the product  	
		* capture the following lines to keep runing in case one of the `x' does not exist (like 2, for example)	
		cap egen A`x'_`l`x'' = rowtotal(A`x'?_*) // Generate totals at the 1-digit code level
		cap label var A`x'_`l`x'' "A`x'_Autoconsumption: `l`x''" 
	}

	* Total Autoconsumption
	egen A_total = rowtotal(A?_*)
	label var A_total "Total annual autoconsumption"
    
	g income_autocons_d = A_total/360

	* Save autoconsumption file
	save "${d_raw}\working\GNB_ehcvm_aut_GNB2021.dta", replace
	
	
	
	
	
	
	
	
	
	