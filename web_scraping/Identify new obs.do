global main "C:\Users\Pablo Uribe\Dropbox\Arlen\DIME-Team"
global data "${main}\1. data\clean"
global data_raw "${main}\1. data\raw\202404 - registration"
global tables "${main}\3. tables"

*** Evolution over time

global dates " "04_04" "04_09" "04_10" "04_11" "04_12" "04_16" "04_17" "04_22" "04_23" "

foreach date in $dates {
	
	import excel "${data_raw}\data_`date'_3pmET.xlsx", sheet("Sheet1") firstrow case(lower) clear
	
	if inlist("`date'", "04_04", "04_09", "04_10"){
		
		gen female_respondent = 1 if gender == "Female"
		replace female_respondent = 0 if gender == "Male"
	
		replace name = strtrim(name)
		replace name = strlower(name)
		
		drop gender
	}
	
	else{
		
		rename (respondentfirstname respondentmiddlename respondentlastname respondentgender respondentage respondentphoneno) (first middle last gender age phone)
		
		gen female_respondent = 1 if gender == "FEMALE"
		replace female_respondent = 0 if gender == "MALE"
		
		gen name = first + " " + middle + " " + last
		replace name = strtrim(name)
		replace name = strlower(name)
		
	}
	
	keep name female_respondent age phone applicationid
	
	destring phone, replace
	
	compress
	
	save "${data_raw}\\`date'.dta", replace
	
}


global dates_new " "04_09" "04_10" "04_11" "04_12" "04_16" "04_17" "04_22" "04_23" "05_21" "

local i = 1
foreach date in $dates_new{
	
	use "${data_raw}\\`date'.dta", clear

	local old: word `i' of $dates
	
	qui merge 1:1 applicationid using "${data_raw}\\`old'.dta", keep(1) nogen
	
	save "${data_raw}\\`date'_new.dta", replace
	
	local ++i
}