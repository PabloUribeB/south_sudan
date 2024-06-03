/*************************************************************************
 *************************************************************************			       	
	        Registration samples analysis
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: April 09, 2024

3) Objective: Analyze the random samples' data from the dashboard and create
			  summary statistics for each of them.

4) Output:	Descriptives_samples.xls
*************************************************************************
*************************************************************************/	

****************************************************************************
*Global directory, parameters and assumptions:
****************************************************************************

global data "C:\Users\Pablo Uribe\Dropbox\DIME-Team\1. data\raw\202404 - registration"

global outcomes nominee age_18_35 over35 members_18_35 self m_only f_only 		///
male_female female_male multiple_nom literacy_main literate_nominate 			///
illiterate_nominate a_18_35_nominated over35_nominated

global dates " "04_03" "04_04" "04_09" "04_10" "04_11" "04_12" "04_16" "04_17" "04_22" "04_23" " // Add the latest download date to the global

local outc : list sizeof global(outcomes)
local ++outc

local day : list sizeof global(dates)


****************************************************************************
*Matrix definition
****************************************************************************

mat def results = J(`outc', `day', .) // Add columns to match number of sheets in Excel

mat rownames results = "Nominated_someone" "Respondents_18_35" "Respondent_over35" 	///
"Members_18_35" "Self_nomination" "Male_only" "Female_only" "Male_Female" 			///
"Female_Male" "More_1_nominee" "Lit_respondent" "Lit_nominated" "Illit_nominated" 	///
"Resp_youth_nominated" "Respondent_35_nominated" "Observations"

mat colnames results = `dates'


****************************************************************************
*Loop through samples and tabulate main statistics
****************************************************************************

local col = 1
foreach date in $dates {
	
	import excel "${data}\samples.xlsx", sheet("`date'_3pm") firstrow case(lower) clear

	egen mean_gender = rowmean(female female2 female3 female4 female5)

	gen m_only 				= (mean_gender == 0)

	gen f_only 				= (mean_gender == 1)

	gen male_female 		= (female == 0 & (female2 == 1 | female3 == 1 | female4 == 1 | female5 == 1))

	gen female_male 		= (female == 1 & (female2 == 0 | female3 == 0 | female4 == 0 | female5 == 0))

	gen multiple_nom 		= (!mi(female) & (!mi(female2) | !mi(female3) | !mi(female4) | !mi(female5)))
	
	gen age_18_35 			= (inrange(age,18,35))
	
	gen a_18_35_nominated 	= (age_18_35 == 1 & nominee == 1)
	
	gen over35 				= (age > 35)
	
	gen over35_nominated 	= (over35 == 1 & nominee == 1)
	
	gen literate_nominate 		= (literacy_main == 1 & nominee == 1)
	replace literate_nominate 	= . if mi(literacy_main)
	
	gen illiterate_nominate 	= (literacy_main == 0 & nominee == 1)
	replace illiterate_nominate = . if mi(literacy_main)

	rename youth members_18_35

	local row = 1
	foreach variable in $outcomes{
		
		sum `variable'
		mat results[`row',`col'] = r(mean)
		
		local ++row
	}
	
	count
	mat results[`row',`col'] = r(N)
	local ++col
}


putexcel set "${data}\Descriptives_samples.xls", sheet("raw", replace) modify
putexcel B2 = mat(results), names