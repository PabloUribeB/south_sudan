/*************************************************************************
 *************************************************************************			       	
	        Registration data processing
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: April 24, 2024

3) Objective: Process the raw data from the dashboard for the latest download.

4) Output:	${date}.dta

IMPORTANT NOTE: Run up to line 35 to see whether line 37 should be modified. If new counties are being registered, line 37 has to change to include those counties.
*************************************************************************
*************************************************************************/	

****************************************************************************
*Global directory, parameters and assumptions:
****************************************************************************

global data "C:\Users\Pablo Uribe\Dropbox\Arlen\DIME-Team\1. data"
global date "06-06" // Put the latest date here to generate the dta file


****************************************************************************
*Open raw data
****************************************************************************
	
** Make sure the downloaded Excel has been renamed to contain the date at the end instead of all the random numbers it comes with
import excel "${data}\raw\household_survey_report-${date}-2024.xlsx", sheet("Household Survey") firstrow case(lower) clear

* Drop test data (verify this before running)
ta countyname

drop if inlist(bomaname, "KASSAVA", "KANGO", "MANGALA", "ROKON") | 	///
!inlist(countyname, "JUBA", "MELUTH", "TORIT MUNICIPAL COUNCIL", "TORIT", "YEI", "KAPOTEA EAST", "RAJA")

****************************************************************************
*Respondent and alternate sections
****************************************************************************

** Here, we are reducing the dimensionality of the data by creating new variables with nicer format and dropping the originals

* Respondent's gender
gen name = respondentfirstname + " " + respondentmiddlename + " " + respondentlastname, after(bomaname)

replace name = strtrim(name)

* Respondent's gender, ID and phone dummies
gen female_respondent = (respondentgender == "Female"), after(name)

gen has_id = (doyouhaveanid == "YES"), after(age)

gen has_phone = (!mi(respondentphonenumber)), after(has_id)


* Make sure all alternate information is as strings

foreach var of varlist *1 *2 firstalternate secondalternate{
	replace `var' = "" if inlist(`var', "NOT PRESENT", "NOT GIVEN")
}

* Alternate's name
gen alternate1_name 			= firstname1 + " " + middlename1 + " " + lastname1, after(howmanymembersinthehhareb)

replace alternate1_name 		= strtrim(alternate1_name)


* Alternate's ID, phone, and gender dummies
gen alternate1_has_id 			= (doyouhaveanid1 == "YES"), after(age1)
replace alternate1_has_id 		= . if mi(alternate1_name)

gen alternate1_has_phone 		= (!mi(phonenumber1)), after(alternate1_has_id)
replace alternate1_has_phone 	= . if mi(alternate1_name)

gen alternate1_female 			= (gender1 == "Female"), after(relationship1)
replace alternate1_female 		= . if mi(alternate1_name)


* Same for alternate 2
gen alternate2_name 			= firstname2 + " " + middlename2 + " " + lastname2, after(gender2)

replace alternate2_name 		= strtrim(alternate2_name)

gen alternate2_has_id 			= (doyouhaveanid2 == "YES"), after(age2)
replace alternate2_has_id 		= . if mi(alternate2_name)

gen alternate2_has_phone 		= (!mi(phonenumber2)), after(alternate2_has_id)
replace alternate2_has_phone 	= . if mi(alternate2_name)

gen alternate2_female 			= (gender2 == "Female"), after(relationship2)
replace alternate2_female 		= . if mi(alternate2_name)


** Rename original variables as were imported by Stata

rename (householdmonthlyaverageincome totalmalesbetween02yrs totalmalesbetween35yrs totalmalesbetween617yrs totalmalesbetween1835yrs totalmalesbetween3664yrs totalmalesbetween65yrsorab totalfemalesbetween02yrs totalfemalesbetween35yrs totalfemalesbetween617yrs totalfemalesbetween1835yrs totalfemalesbetween3664yrs totalfemalesbetween65yrsor disabledmalesbetween02yrs disabledmalesbetween35yrs disabledmalesbetween617yrs disabledmalesbetween1835yrs disabledmalesbetween3664yrs disabledmalesbetween65yrsor disabledfemalesbetween02yrs disabledfemalesbetween35yrs disabledfemalesbetween617yr disabledfemalesbetween1835y disabledfemalesbetween3664y disabledfemalesbetween65yrs chronicallyillmalesbetween0 chronicallyillmalesbetween3 chronicallyillmalesbetween6 chronicallyillmalesbetween18 chronicallyillmalesbetween36 chronicallyillmalesbetween65 chronicallyillfemalesbetween bc bd be bf bg bothdisabledandchronicallyil bi bj bk bl bm bn bo bp bq br bs canrespondentreadandwrite howmanymembersinthehhareb age1 age2 respondentrelationshiptotheh relationship1 relationship2 respondentphonenumber) ///
(income males_0_2 males_3_5 males_6_17 males_18_35 males_36_64 males_over_65 females_0_2 females_3_5 females_6_17 females_18_35 females_36_64 females_over_65 disab_males_0_2 disab_males_3_5 disab_males_6_17 disab_males_18_35 disab_males_36_64 disab_males_over_65 disab_females_0_2 disab_females_3_5 disab_females_6_17 disab_females_18_35 disab_females_36_64 disab_females_over_65 chron_ill_males_0_2 chron_ill_males_3_5 chron_ill_males_6_17 chron_ill_males_18_35 chron_ill_males_36_64 chron_ill_males_over_65 chron_ill_females_0_2 chron_ill_females_3_5 chron_ill_females_6_17 chron_ill_females_18_35 chron_ill_females_36_64 chron_ill_females_over_65 dis_chron_males_0_2 dis_chron_males_3_5 dis_chron_males_6_17 dis_chron_males_18_35 dis_chron_males_36_64 dis_chron_males_over_65 dis_chron_females_0_2 dis_chron_females_3_5 dis_chron_females_6_17 dis_chron_females_18_35 dis_chron_females_36_64 dis_chron_females_over_65 literacy_main members_18_35_literate alternate1_age alternate2_age respondent_relationship alternate1_relationship alternate2_relationship phone)

* Drop unnecessary variables
drop respondentfirstname respondentmiddlename respondentlastname respondentnickname respondentgender doyouhaveanid whattypeofid idnumber reasonforsupporttype firstname1 middlename1 lastname1 nickname1 whattypeofid1 idnumber1 phonenumber1 gender1 firstname2 middlename2 lastname2 nickname2 whattypeofid2 idnumber2 phonenumber2 gender2 reasonforwhynot doyouhaveanid2 doyouhaveanid1 firstalternate secondalternate nominees

* Replace to missing when it should be missing
replace alternate1_relationship = "" if mi(alternate1_age)
replace alternate2_relationship = "" if mi(alternate2_age)


replace literacy_main = "1" if literacy_main == "YES"
replace literacy_main = "0" if literacy_main == "NO"
destring literacy_main, replace

****************************************************************************
*Nomination sections
****************************************************************************

* There are a total of five possible nominees in the data that could be nominated

* Loop through the five possible nominees to do renaming and creation of dummies
forval i = 1/5{
	
	gen name`i' 	= nominee_`i'firstname + " " + nominee_`i'middlename + " " + nominee_`i'lastname, after(nominee_`i'lastname)
	replace name`i' = strtrim(name`i')
	
	rename (nominee_`i'relationshiptotheho nominee_`i'age nominee_`i'doesnomineereadand) (relationship`i' nominee`i'age literacy`i')
	
	gen female`i' 		= (nominee_`i'gender == "Female"), after(relationship`i')
	replace female`i' 	= . if mi(name`i')
	
	
	drop nominee_`i'firstname nominee_`i'middlename nominee_`i'lastname nominee_`i'nickname nominee_`i'gender nominee_`i'whatdoesnomineedof
	
}

gen nominee = (wouldanyoneinhouseholdbeint == "YES"), after(wouldanyoneinhouseholdbeint)
drop wouldanyoneinhouseholdbeint

* Homogenize the names across the dataset to avoid matching problems
foreach var of varlist name* alternate1_name alternate2_name{
	replace `var' = strlower(`var')
}


* Fuzzy match for respondent, alternate and nominee names
forval number= 1/5{
	
	qui matchit name name`number', gen(s`number')
	
	replace s`number' = 0 if (age != nominee`number'age | 	///
			female_respondent != female`number') & s`number' >= 0.75
			
}
 
egen smax = rowmax(s?)

drop s?

* Generate dummy for whether a respondent nominated themselves for component 2
gen 	self = 1 if smax >= 0.75
replace self = 0 if nominee == 1 & mi(self)


forval number= 1/5{
	
	qui matchit alternate1_name name`number', gen(s`number')
	
	replace s`number' = 0 if (alternate1_female != female`number' & s`number' >= 0.75) | mi(alternate1_name)
	
}

egen smax1 = rowmax(s?)

drop s?


forval number= 1/5{
	
	qui matchit alternate2_name name`number', gen(s`number')
	
	replace s`number' = 0 if (alternate2_female != female`number' & s`number' >= 0.75) | mi(alternate2_name)
	
}

egen smax2 = rowmax(s?)

drop s?

egen full = rowmax(smax*)

gen 	self2 = 1 if full >= 0.75
replace self2 = 0 if nominee == 1 & mi(self2)

di as err "Nominees have biometric data:"
ta self2

drop name1 name2 name3 name4 name5 phone smax* self2 full


foreach var of varlist age income householdsize-members_18_35_literate *age {
	destring `var', replace
}

foreach var of varlist literacy?{
	replace `var' = "1" if `var' == "true"
	replace `var' = "0" if `var' == "false"
	
	destring `var', replace
}

replace countyname = "TORIT MUNICIPAL COUNCIL" if countyname == "TORIT"
replace payamname = "ILANGI" if payamname == "TORIT"
replace bomaname = "ILANGI BC" if bomaname == "ILANGI"

replace countyname = strproper(countyname)

compress

save "${data}\clean\\household_survey_report_${date}.dta", replace

*************************************************************************************************************************************
*************************************************************************************************************************************
*************************************************************************************************************************************