/*************************************************************************
 *************************************************************************			       	
	        Registration dashboard analysis
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: April 09, 2024

3) Objective: Identify which observations are new, relative to the last data download.
			  Randomly draw X number of such observations and create a vector in xlsx
			  to feed the web scraping code in R.

4) Output:	positions_vector.xls
*************************************************************************
*************************************************************************/	

****************************************************************************
*Global directory, parameters and assumptions:
****************************************************************************

global data "C:\Users\Pablo Uribe\Dropbox\DIME-Team\1. data\raw\202404 - registration"

* Only change this numbers after running the Initial_scrape.R code
local last_date 04_22 // Input the last date in MM_DD format
local new_date 04_23 // Input today's date in MM_DD

* Import previous most recent data 
import excel "${data}\data_`last_date'_3pmET.xlsx", sheet("Sheet1") firstrow case(lower) clear

* Create the position of each observation in the dashboard (when displaying 50 HHs per page)
gen rows_old = _n

gen page_old = floor((rows - 1) / 50) + 1

bys page_old: replace rows_old = _n

tempfile old
save `old'

* Import new data (updated version)

import excel "${data}\data_`new_date'_3pmET.xlsx", sheet("Sheet1") firstrow case(lower) clear

gen rows = _n

gen page = floor((rows - 1) / 50) + 1

bys page: replace rows = _n

*duplicates drop id_application, force

merge 1:1 applicationid using `old' // Merge to see where the new registrees are being placed in the dashboard

sort page rows

sum page if rows_old == 1 & page_old == 1
local page = r(mean)

sum rows if rows_old == 1 & page_old == 1
local rows = r(mean)

** Randomly draw 50 observations from the new ones.

set seed 1

preserve

	keep if _merge == 1

	sample 150, count
	
	tempfile new_obs
	save `new_obs'
	
restore

* Randomly draw 50 old observations 

keep if _merge == 3

sample 50, count

append using `new_obs' // Append to see all 100 sampled observations

sort page rows

rename (page rows) (page_num position)

keep if _merge == 1

keep page_num position

export excel using "${data}\positions_vector.xlsx", firstrow(variables) replace
