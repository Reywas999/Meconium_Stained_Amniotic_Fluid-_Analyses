cd C:\Users\PATH\TO\DATA
use labour, clear

log using MSAF.log

foreach var in matage epidural pyrexia meconium ethcat breech bmi nullipar multiple abnormalfhr smoke durcat lateterm {
	summarize `var'
}

/* assessing missing */
mdesc

recode bmi . = 999
drop if bmi == 999

/* Recode matage and BMI into appropriate bins */ 
egen agecat = cut(matage), at(13, 20, 27, 35, 52)
label define agecat 13 "13-19" 20 "20-26" 27 "27-34" 35 "35-51"
label values agecat agecat

egen bmi_bin = cut(bmi), at(12.5, 18.5, 25, 30, 35, 64) label
label define bmi_bin 0 "Underweight" 1 "Normal" 2 "Overweight" 3 "Obese" 4 "Extremely Obese"
label values bmi_bin bmi_bin


/* Calculating the Proportion of Black Women and of meconium */ 
tab meconium
tab ethcat

tab meconium ethcat, col

/* Calculating chi squared values of association and then CRUDE OR + 95% c.i. for each exposure to outcome and from each confounder/independent variable to primary exposure */ 
foreach var in agecat epidural pyrexia ethcat breech bmi_bin nullipar multiple abnormalfhr smoke durcat lateterm {
	tab `var' meconium, col chi
}

foreach var in agecat epidural pyrexia ethcat breech bmi_bin nullipar multiple abnormalfhr smoke durcat lateterm {
	logistic meconium `var'
}

foreach var in agecat epidural pyrexia breech bmi_bin nullipar multiple abnormalfhr smoke durcat lateterm {
	tab `var' ethcat, col chi
}

/* Calculating CRUDE OR + 95% c.i. for each stratum of non-binary variables */ 
foreach var in agecat durcat {
	logistic meconium ib0.`var'
}

/* Setting category 2 as reference/baseline in BMI, as that is the "normal" bodyweight group. The lowest group is "underweight" */
logistic meconium ib1.bmi_bin


/* Assessing multicollinearity */
spearman agecat epidural pyrexia ethcat breech bmi_bin nullipar multiple abnormalfhr smoke durcat lateterm

/* Individually adjusting for each potential confounder */
foreach var in bmi_bin nullipar abnormalfhr lateterm {
	logistic meconium ethcat `var'
	est store a
	quietly logistic meconium ethcat
	est store b
	lrtest a b
}

foreach var in bmi_bin nullipar abnormalfhr lateterm {
	logistic meconium `var' ethcat
	est store a
	quietly logistic meconium `var'
	est store b
	lrtest a b
}

/* Test for interaction */
foreach var in epidural pyrexia breech bmi_bin nullipar multiple abnormalfhr durcat lateterm {
	logistic meconium i.ethcat##`var'
	est store a
	quietly logistic meconium i.ethcat i.`var'
	est store b
	lrtest a b
}

/* Assessing the significance of interaction terms in model fit */
foreach var in nullipar abnormalfhr lateterm {
	logistic meconium i.ethcat##`var'
	est store a
	quietly logistic meconium i.ethcat
	est store b
	lrtest a b
}

/* Final Adjusted Regression */
logistic meconium i.ethcat##nullipar i.ethcat##abnormalfhr ib1.bmi_bin i.ethcat##lateterm
/* Calculating Stratum-specific estimated */
/* nullipar stratum */
lincom 1.ethcat + 1.nullipar#1.ethcat
lincom 1.nullipar + 1.nullipar#1.ethcat
/* abnormalfhr stratum */
lincom 1.ethcat + 1.abnormalfhr#1.ethcat
lincom 1.abnormalfhr + 1.abnormalfhr#1.ethcat
/* lateterm stratum */
lincom 1.ethcat + 1.lateterm#1.ethcat
lincom 1.lateterm + 1.lateterm#1.ethcat
