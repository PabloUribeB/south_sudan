
# Load necessary libraries
library(rvest)
library(RSelenium)
library(dplyr)
library(XML)
library(stringr)
library("writexl")
library(readxl)
library(svDialogs)


path <- "C:/Users/Pablo Uribe/Dropbox/DIME-Team/1. data/raw/202404 - registration/"

user.input <- dlgInput("Enter today's date as MM_DD (e.g., April 15 as 04_15)", Sys.info()[""])$res

#### BEFORE RUNNING - 

## Specify folder to download all files in Mozilla settings to be the one where they will be stored after running this.
## Follow this Dropbox path: Dropbox/DIME-Team/1. data/raw/202404 - registration/dashboard/

## Delete all files in that folder before running
do.call(file.remove, list(list.files(paste0(path,"dashboard/"), full.names = TRUE)))

# Open the browser
rD <- rsDriver(browser="firefox", port=4546L, verbose=F) 
remDr <- rD[["client"]]

dlgMessage("Only click Ok after you have set your default Downloads path in the browser that will pop up to the Dropbox folder at: Dropbox/DIME-Team/1. data/raw/202404 - registration/dashboard/")

# Open the login page
remDr$navigate("https://snsopafisadmin.southsudansafetynet.info/#/auth/login")

# Fill in the login form with your credentials
remDr$findElement(using = 'id', value = "userName")$sendKeysToElement(list("admin"))
remDr$findElement(using = 'id', value = "password")$sendKeysToElement(list("Abc@123"))

# Click login button
remDr$findElements("xpath", "/html/body/app-root/app-login/div/div/div/form/div[3]/button")[[1]]$clickElement()

Sys.sleep(10)

# Click beneficiary button
remDr$findElements("id", "pn_id_4_0")[[1]]$clickElement()

Sys.sleep(3)

# Click the paginator button to show 50 observations per page
remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/p-dropdown/div/div[2]")$clickElement()

remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/p-dropdown/div/p-overlay/div/div/div/div/ul/p-dropdownitem[3]/li")$clickElement()

Sys.sleep(3)

remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/button[4]")$clickElement()

input_limit <- as.numeric(dlgInput("Scroll to the bottom of the page and enter the page it's currently on.", Sys.info()[""])$res)

remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/button[1]")$clickElement()

Sys.sleep(2)

remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-table/div/div[1]/div/button[1]")$clickElement()


## Loop through all remaining pages

# current iteration 
i <- 2
# max pages to scrape 
limit <- input_limit # MANUALLY CHANGE THIS NUMBER TO THE MAXIMUM NUMBER OF PAGES AVAILABLE

# until there is still a page to scrape 
while (i <= limit) {
  
  # Go to next page
  remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/button[3]")$clickElement()
  Sys.sleep(2)
  
  # Download data as XLSX
  remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-table/div/div[1]/div/button[1]")$clickElement()
  
  # Incrementing the iteration counter 
  i <- i + 1
}

# Look at all the files in this folder
files <- list.files(paste0(path,"dashboard"))

# Place them in a vector
y <- paste0(path,"dashboard/",files)

# Function to read each file
function.read.loop <- function(file = y){
  df <- readxl::read_xlsx(path = file)
  return(df)
}

# Read each file
list.files <- lapply(y, function(x) function.read.loop(file = x))

# Append all files
files.appended <- plyr::rbind.fill(list.files |>  data.table::rbindlist(use.names = T,fill = T))

# Write the data frame to an XSLX 
write_xlsx(files.appended,paste0(path,'data_',user.input,'_3pmET.xlsx'))

# Close the Selenium server
remDr$close()
