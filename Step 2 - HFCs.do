/*************************************************************************
 *************************************************************************			       	
	        Registration data analysis
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: April 24, 2024

3) Objective: Analyze the raw data from the dashboard and create
			  summary statistics for each download.

4) Output:	- Summary.xls
			- payam distribution for each county (png files)
*************************************************************************
*************************************************************************/	

****************************************************************************
*Global directory, parameters and assumptions:
****************************************************************************
global main "C:\Users\Pablo Uribe\Dropbox\Arlen\DIME-Team"
global data "${main}\1. data\clean"
global data_raw "${main}\1. data\raw\202404 - registration"
global tables "${main}\3. tables"

set scheme white_tableau

global outcomes nominee age_18_35 over35 members_18_35 income female_respondent ///
self m_only f_only male_female female_male multiple_nom literacy_main 			///
literate_nominate illiterate_nominate a_18_35_nominated over35_nominated has_id ///
has_phone public_works nominee_age w_18_35 m_18_35 w_18_35_only m_18_35_only 	///
w_18_64 m_18_64 w_18_64_only m_18_64_only youth_older m_w_18_35 m_w_18_64 		///
nominee_18_35 nominee_36_64 nominee_literate nominee_youth_literate

global counties " "Juba" "Meluth" "Torit Municipal Council" "Yei" "Kapotea East" " // Make sure Juba is the first one

global date "02-06"

foreach county in $counties{
	cap mkdir "${tables}\\`county'"
}


set graphics off

****************************************************************************
*Matrix definition
****************************************************************************

local outc : list sizeof global(outcomes) // Count number of outcomes for # rows
local ++outc // Add 1 row for 

mat def results = J(`outc', 3, .)

mat rownames results = "Nominated_someone" "Respondents_18_35" 				///
"Respondent_over35" "Members_18_35" "Household_income" "Female_respondent" 	///
"Self_nomination" "Male_only" "Female_only" "Male_Female" "Female_Male" 	///
"More_1_nominee" "Lit_respondent" "Lit_nominated" "Illit_nominated" 		///
"Resp_youth_nominated" "Respondent_35_nominated" "Has_id" "Has_phone" 		///
"Public_works" "Nominee_age" "Women_18_35" "Men_18_35" "Women_18_35_only" 	///
"Men_18_35_only" "Women_18_64" "Men_18_64" "Women_18_64_only" 				///
"Men_18_64_only" "youth_orolder_w" "Men_Women_18_35" "Men_Women_18_64"		///
"Nominee_18_35" "Nominee_18_64" "Nominee_literate" "Nominee_18_35_literate"	///
"Observations"


****************************************************************************
*Create variables and tabulate summary stats
****************************************************************************
	
use "${data}\\household_survey_report_${date}.dta", clear

replace literacy_main = 0 if mi(literacy_main) // REVISE

tempvar dup
duplicates tag name age female_respondent, gen(`dup')

tempvar n N
bys name age female_respondent (nominee): gen `n' = _n
bys name age female_respondent (nominee): gen `N' = _N

drop if `n' != `N' & `dup' != 0

dis as err "Counties with nominees that should not have any"

ta countyname if countyname != "Juba" & nominee

drop if countyname != "Juba" & nominee == 1

egen mean_gender = rowmean(female1 female2 female3 female4 female5)

gen m_only 				= (mean_gender == 0)
replace m_only 			= . if nominee == 0

gen f_only 				= (mean_gender == 1)
replace f_only 			= . if nominee == 0

gen male_female 		= (female1 == 0 & (female2 == 1 | female3 == 1 |	///
	female4 == 1 | female5 == 1))
replace male_female 	= . if nominee == 0

gen female_male 		= (female1 == 1 & (female2 == 0 | female3 == 0 | 	///
	female4 == 0 | female5 == 0))
replace female_male 	= . if nominee == 0

gen multiple_nom 		= (!mi(female1) & (!mi(female2) | !mi(female3) | 	///
	!mi(female4) | !mi(female5)))
replace multiple_nom 	= . if nominee == 0

gen age_18_35 			= (inrange(age,18,35))

gen w_18_35 			= (females_18_35 > 0)
gen m_18_35 			= (males_18_35 > 0)

gen w_18_64 			= (w_18_35 == 1 | females_36_64 > 0)
gen m_18_64 			= (m_18_35 == 1 | males_36_64 > 0)

gen m_w_18_35 			= (m_18_35 == 1 & w_18_35 == 1)
gen m_w_18_64			= (m_18_64 == 1 & w_18_64 == 1)


gen w_18_35_only 		= (w_18_35 == 1 & females_0_2 == 0 & 			///
	females_3_5 == 0 & females_6_17 == 0 & females_36_64 == 0 & 		///
	females_over_65 == 0)


gen w_18_64_only 		= (w_18_64 == 1 & females_0_2 == 0 & 			///
	females_3_5 == 0 & females_6_17 == 0 & females_over_65 == 0) 


gen m_18_35_only 		= (m_18_35 == 1 & males_0_2 == 0 & 				///
	males_3_5 == 0 & males_6_17 == 0 & males_36_64 == 0 & males_over_65 == 0)


gen m_18_64_only 		= (m_18_64 == 1 & males_0_2 == 0 & 				///
	males_3_5 == 0 & males_6_17 == 0 & males_over_65 == 0)


gen youth_older 			= (m_18_35 == 1 | w_18_35 == 1 | females_over_65 > 0)

gen over35 					= (age > 35)

gen a_18_35_nominated 	= (age_18_35 == 1 & nominee == 1)

*** Nomination variables

gen over35_nominated 		= (over35 == 1 & nominee == 1)

gen literate_nominate 		= (literacy_main == 1 & nominee == 1)
replace literate_nominate 	= . if mi(literacy_main)

gen illiterate_nominate 	= (literacy_main == 0 & nominee == 1)
replace illiterate_nominate = . if mi(literacy_main)

egen members_18_35 			= rowtotal(males_18_35 females_18_35)

gen public_works 			= (supporttype == "LIPW")

/*
drop m_only_males
gen m_only_males = m_only
replace m_only_males = . if nominee == 0 | (males_18_35 == 0 & males_36_64 == 0) | f_only == 1

gen f_only_females = f_only == 1 & w_18_64 == 1

gen male_female_could = (male_female == 1 & )
*/

tempvar n_mean
egen `n_mean' = rowmean(nominee1age nominee2age nominee3age nominee4age nominee5age)

tempvar num_nominee
egen `num_nominee' = rownonmiss(nominee1age nominee2age nominee3age nominee4age nominee5age)
replace `num_nominee' = . if `num_nominee' == 0

bys countyname: asgen nominee_age = `n_mean', w(`num_nominee')
bys countyname: asgen nominee_age_0 = `n_mean' if female_respondent == 0, w(`num_nominee')
bys countyname: asgen nominee_age_1 = `n_mean' if female_respondent == 1, w(`num_nominee')


gen nominee_18_35 = (inrange(nominee1age,18,35) | inrange(nominee2age,18,35) | 	///
	inrange(nominee3age,18,35) | inrange(nominee4age,18,35) |					///
	inrange(nominee5age,18,35))

replace nominee_18_35 = . if nominee == 0


gen nominee_36_64 = (inrange(nominee1age,36,64) | inrange(nominee2age,36,64) |	///
	inrange(nominee3age,36,64) | inrange(nominee4age,36,64) | 					///
	inrange(nominee5age,36,64))
	
replace nominee_36_64 = . if nominee == 0


gen nominee_literate = (literacy1 == 1 | literacy2 == 1 | literacy3 == 1 |		///
	literacy4 == 1 | literacy5 == 1)

replace nominee_literate = . if nominee == 0


gen nominee_youth_literate = (nominee_18_35 == 1 & nominee_literate == 1)
replace nominee_youth_literate = . if nominee == 0

local raw raw
local posi = 2

foreach county in $counties{
	preserve
	
	local row = 1
	foreach variable in $outcomes{
		
		local col = 1
		
		sum `variable' if countyname == "`county'"
		mat results[`row',`col'] = r(mean)
		
		local ++col
		
		if "`variable'" == "nominee_age"{
			forval i = 0/1{
				sum `variable'_`i' if countyname == "`county'"
				mat results[`row',`col'] = r(mean)
				local ++col
			}
		}
		else{
			forval i = 0/1{
				sum `variable' if female_respondent == `i' & countyname == "`county'"
				mat results[`row',`col'] = r(mean)
				local ++col
			}
		}
		
		local ++row
	}

	** Plot the payams
	encode payamname if countyname == "`county'", gen(en_payam)

	graph bar if countyname == "`county'", over(en_payam, sort(1) descending label(angle(45))) ytitle(Percent) subtitle(Distribution of households by Payam in `county', size(medium)) blabel(bar, format(%04.2f))

	graph export "${tables}\\`county'\payams_`date'_`county'_${date}.png", replace

	local col = 1
	count if countyname == "`county'"
	mat results[`row',`col'] = r(N)

	local ++col

	forval i = 0/1{
		count if female_respondent == `i' & countyname == "`county'"
		mat results[`row',`col'] = r(N)
		local ++col
	}

	putexcel set "${tables}\Summary.xls", sheet("`raw'", replace) modify
	putexcel B2 = mat(results), names
	
	local next : word `posi' of ${counties}
	local raw "raw_`next'"
	local ++posi

	replace respondent_relationship = "Other" if !inlist(respondent_relationship, "Household head", "Son/daughter", "Spouse", "Parent", "Sibling", "No relation")

	encode respondent_relationship, gen(en_relationship)

	graph bar if countyname == "`county'", over(female_respondent, label(nolab)) over(en_relationship, sort(1) descending label(labs(vsmall))) legend(r(1) order(1 "Male" 2 "Female") position(bottom)) asy blabel(bar, format(%04.2f)) bargap(20) outergap(10) ytitle(Share of total registered population) bar(1, color(dknavy)) bar(2, color(dkgreen)) subtitle(Relationship of respondent to household head by gender in `county')

	graph export "${tables}\\`county'\relationships_`date'_`county'_${date}.png", replace
	
	restore
}

/*
*  Inconsistent cases
gen f_youth = (age_18_35 == 1 & female_respondent == 1)
gen m_youth = (age_18_35 == 1 & female_respondent == 0)

count if (age_18_35 == 1 & female_respondent == 1 & females_18_35 == 0) | (inrange(age,36,64) & female_respondent == 1 & females_36_64 == 0)
local female = r(N)
count if female_respondent == 1 & inrange(age,18,64)
local ftotal = r(N)
local fshare = `female'/`ftotal'
di as err "Total female age inconsistencies: `fshare'"

count if (age_18_35 == 1 & female_respondent == 0 & males_18_35 == 0) | (inrange(age,36,64) & female_respondent == 0 & males_36_64 == 0)
local male = r(N)
count if female_respondent == 0 & inrange(age,18,64)
local mtotal = r(N)
local mshare = `male'/`mtotal'
di as err "Total male age inconsistencies: `mshare'"
*/

/* Historic trends (old)

keep if countyname == "Juba"

preserve

use "${data_raw}\\04_04.dta", clear

cd "${data_raw}"

append using 04_09_new 04_10_new 04_11_new 04_12_new 04_16_new 04_17_new 04_22_new 04_23_new, gen(date)

replace date = date + 1

label def days 1 "04-04" 2 "04-09" 3 "04-10" 4 "04-11" 5 "04-12" 6 "04-16" 7 "04-17" 8 "04-22" 9 "04-23" 10 "05-21"
label val date days

drop applicationid

tempvar dup
duplicates tag name age female_respondent, gen(`dup')

tempvar n
bys name age female_respondent: gen `n' = _n

drop if `n' == 1 & `dup' != 0

tempfile obs_dates
save `obs_dates'

restore

merge 1:1 name age female_respondent using `obs_dates', keepusing(date) keep(1 3)

replace date = 10 if _merge == 1



egen num_nominee = rownonmiss(nominee1age nominee2age nominee3age nominee4age nominee5age)

collapse (mean) num_nominee self nominee_18_35 nominee_literate nominee, by(date)

tw (connected num_nominee date, color(dknavy)), xtitle(Download date) ytitle(Number of nominees) xlabel(1(1)10, val) ylabel(0(0.25)1.5, format(%04.2f)) subtitle(Average number of nominees)

graph export "${tables}\historic_num_nominee.png", replace


tw (connected self date, color(dknavy)), xtitle(Download date) ytitle(Proportion) xlabel(1(1)10, val) ylabel(.2(.05).7) subtitle(Proportion of nominees who were also the respondents)

graph export "${tables}\historic_self_nominee.png", replace


tw (connected nominee_18_35 date, color(dknavy)), xtitle(Download date) ytitle(Proportion) xlabel(1(1)10, val) ylabel() subtitle(Proportion of nominees between 18-35)

graph export "${tables}\historic_youth_nominee.png", replace


tw (connected nominee_literate date, color(dknavy)), xtitle(Download date) ytitle(Proportion) xlabel(1(1)10, val) ylabel() subtitle(Proportion of literate nominees)

graph export "${tables}\historic_literate_nominee.png", replace

format nominee %7.2f

tw (connected nominee date, color(dknavy)), xtitle(Download date) ytitle(Proportion) xlabel(1(1)10, val) ylabel(.3(.1).8) subtitle(Proportion of respondents nominating someone)

graph export "${tables}\historic_nomination.png", replace

*******************************************************************************
*******************************************************************************
*******************************************************************************