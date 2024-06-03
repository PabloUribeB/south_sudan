
# Load necessary libraries
library(rvest)
library(RSelenium)
library(dplyr)
library(XML)
library(stringr)
library("writexl")
library(readxl)
library(xlsx)
library(tidyverse)
library(svDialogs)


nom_sample <- data.frame()

# Set the directory path
path <- "C:/Users/Pablo Uribe/Dropbox/DIME-Team/1. data/raw/202404 - registration/"

positions <- read_xlsx(paste0(path,"positions_vector.xlsx"))

# These are just string objects to be able to loop through HTML positions to extract different pieces of data later on
first <- "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[2]/div/div/div/div/div["
last <- "]/div/div/table/tbody/tr[4]/td"
last2 <- "]/div/div/table/tbody/tr[3]/td"
last3 <- "]/div/div/table/tbody/tr[6]/td"
last4 <- "]/div/div/table/tbody/tr[1]/td"

# These allow to go through the eye icons in the dashboard (clicking on only the ones in the positions wanted)
eye_prefix <- "/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-table/div/div[2]/table/tbody/tr["
eye_suffix <- "]/th/i[1]"

# Open the browser
rD <- rsDriver(browser="firefox", port=4545L, verbose=F) # If error, change the last number in port
remDr <- rD[["client"]]

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

start_time <- Sys.time()



## Loop through each row of the vector of positions
row <- 1
for (i in positions$page_num){
  
  print(paste0("Page: ",i, "; Row: ",positions$position[row], "; Sample obs # ",row))
  
  # Click the paginator button to show 50 observations per page
  remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/p-dropdown/div/div[2]")$clickElement()
  
  remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/p-dropdown/div/p-overlay/div/div/div/div/ul/p-dropdownitem[3]/li")$clickElement()
  
  Sys.sleep(1.7)
  
  page <- XML::htmlParse(remDr$getPageSource()[[1]])
  current_page <- 1 # It always returns to the first page when going back to the list, hence the 1
  
  if (i == current_page) { # If the observation is on the first page, just get the info
    
    page <- XML::htmlParse(remDr$getPageSource()[[1]])
    
  } else if (i > current_page){ # If the observation is in later pages, move to next page
    
    while (i > current_page){ # Keep going to the next page until the current page matches the page where obs. is located
      
      remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/button[3]")$clickElement()
      
      Sys.sleep(2)
      
      page <- XML::htmlParse(remDr$getPageSource()[[1]])
      
      # In the dashboard, the current page is not always displayed in the same position
      if (current_page == 1){ # If it already read the first page and is standing on the second one, simply switch the value to 2
        
        current_page <- 2
        
      } else{ # For pages 3 and above, button is always located in the third position in the following XPath
        
        current_page <- as.numeric(str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-list/div[2]/p-paginator/div/span/button[3]", XML::xmlValue)))
        
      }
    }
    }
  
  # Get the location on the page of the focused-on observation
  location <- positions$position[row]
  
  # Click on the eye to expand its information
  remDr$findElement("xpath",paste0(eye_prefix,location,eye_suffix))$clickElement()
  
  Sys.sleep(11) # Increase this number if internet connection is slow. Decrease if fast
  
  # Gather HTML info
  page <- XML::htmlParse(remDr$getPageSource()[[1]])
  
  
  # Collect the following information from respondent:
  # Age, literacy status, gender, # members 18-35 from respondent, # HH members, income, name, and geographic information
  age <- XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[1]/div/div/div[2]/table/tbody/tr[3]/td[1]
", XML::xmlValue)
  
  literate <- XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[1]/div/div[2]/div/div/table[3]/tbody/tr[4]/td
", XML::xmlValue)
  
  members_18_35 <- str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[1]/div/div[2]/div/div/table[3]/tbody/tr[2]/td[1]
", XML::xmlValue))
  
  female_respondent <- str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[1]/div/div/div[2]/table/tbody/tr[3]/td[2]", XML::xmlValue))
  
  income <- as.numeric(str_trim(str_replace_all(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[1]/div/div[2]/div/div/table[1]/tbody/tr[2]/td", XML::xmlValue), 
                            "SDG", "")))
  
  name <- str_to_lower(str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[1]/div/div/div[2]/table/tbody/tr[2]/td", XML::xmlValue)))
  
  hh_members <- as.numeric(str_trim(str_replace_all(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[1]/div/div[2]/div/div/table[2]/tbody/tr[1]/th", XML::xmlValue), 
                                                    "Total Member: ", "")))
  
  state <- str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[2]/div/div[2]/div/div/table/tbody/tr[1]/td[1]", XML::xmlValue))
    
  county <- str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[2]/div/div[2]/div/div/table/tbody/tr[1]/td[2]", XML::xmlValue))
  
  payam <- str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[2]/div/div[2]/div/div/table/tbody/tr[2]/td[1]", XML::xmlValue))
  
  boma <- str_trim(XML::xpathSApply(page, "/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[2]/p-tabpanel[1]/div/div/div[2]/p-accordion/div/p-accordiontab[2]/div/div[2]/div/div/table/tbody/tr[2]/td[2]", XML::xmlValue))
  
    
  # Go to nominees section
  remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[2]/p-tabview/div/div[1]/div/ul/li[2]/a/span")$clickElement()
  
  Sys.sleep(0.7)
  
  # Parse HTML
  page <- XML::htmlParse(remDr$getPageSource()[[1]])
  
  # Create empty vectors with max 5 values
  n_age <- rep(NA, 5)
  n_gender <- rep(NA, 5)
  n_literacy <- rep(NA, 5)
  n_name <- rep(NA, 5)
  
  # Go through each of the vectors and analyze the nominees site to collect each nominee's info
  # If no nominee, it will be saved as NULL or empty character. If-else condition to leave blank when this happens
  for (number in 1:length(n_age)) {
    
    value <- str_trim(XML::xpathSApply(page, paste0(first,number,last), XML::xmlValue))
    if(is.null(value) | length(value) == 0) n_age[number] <- NA
    else n_age[number] <- value
    
    value2 <- str_trim(XML::xpathSApply(page, paste0(first,number,last2), XML::xmlValue))
    if(is.null(value2) | length(value) == 0) n_gender[number] <- NA
    else n_gender[number] <- value2
    
    value2 <- str_trim(XML::xpathSApply(page, paste0(first,number,last3), XML::xmlValue))
    if(is.null(value2) | length(value) == 0) n_literacy[number] <- NA
    else n_literacy[number] <- value2
    
    value2 <- str_to_lower(str_trim(XML::xpathSApply(page, paste0(first,number,last4), XML::xmlValue)))
    if(is.null(value2) | length(value) == 0) n_name[number] <- NA
    else n_name[number] <- value2
    
  }
  
  # Append the collected data from this household to the main data frame
  nom_sample <- nom_sample |> 
    rbind(data.frame("age" = age, "literacy_main" = literate, "youth" = members_18_35, 
                     "hh_members" = hh_members, "income" = income, "nominee" = 0, 
                     "self" = 0, "female_respondent" = female_respondent, "name" = name,
                     "nominee1age" = n_age[1], "female" = n_gender[1], "literacy1" = n_literacy[1], "name1" = n_name[1],
                     "nominee2age" = n_age[2], "female2" = n_gender[2], "literacy2" = n_literacy[2], "name2" = n_name[2],
                     "nominee3age" = n_age[3], "female3" = n_gender[3], "literacy3" = n_literacy[3], "name3" = n_name[3],
                     "nominee4age" = n_age[4], "female4" = n_gender[4], "literacy4" = n_literacy[4], "name4" = n_name[4],
                     "nominee5age" = n_age[5], "female5" = n_gender[5], "literacy5" = n_literacy[5], "name5" = n_name[5],
                     "state" = state, "county" = county, "payam" = payam, "boma" = boma))
  
  
  # Go back to list of beneficiaries
  remDr$findElement("xpath","/html/body/app-root/app-wrapper/div/app-beneficiary-detail/div[1]/p-breadcrumb/div/ul/li[3]")$clickElement()
  
  Sys.sleep(2)
  
  # Move to the next row in the positions vector
  row <- row + 1
  
}

end_time <- Sys.time()
end_time - start_time


## Additional processing

nom_sample <- nom_sample |> 
  mutate(nominee = case_when(!is.na(nominee1age) ~ 1,
                             is.na(nominee1age) ~ 0),
       female_respondent = case_when(female_respondent == "Female" ~ 1,
                                       female_respondent == "Male" ~ 0),
       female  = case_when(female == "Female" ~ 1,
                           female  == "Male"   ~ 0),
       female2 = case_when(female2 == "Female" ~ 1,
                           female2 == "Male"   ~ 0),
       female3 = case_when(female3 == "Female" ~ 1,
                           female3 == "Male"   ~ 0),
       female4 = case_when(female4 == "Female" ~ 1,
                           female4 == "Male"   ~ 0),
       female5 = case_when(female5 == "Female" ~ 1,
                           female5 == "Male"   ~ 0),
       literacy_main = case_when(literacy_main == "Yes" ~ 1,
                                 literacy_main == "No"  ~ 0),
       literacy1 = case_when(literacy1 == "Yes" ~ 1,
                             literacy1 == "No"  ~ 0),
       literacy2 = case_when(literacy2 == "Yes" ~ 1,
                             literacy2 == "No"  ~ 0),
       literacy3 = case_when(literacy3 == "Yes" ~ 1,
                             literacy3 == "No"  ~ 0),
       literacy4 = case_when(literacy4 == "Yes" ~ 1,
                             literacy4 == "No"  ~ 0),
       literacy5 = case_when(literacy5 == "Yes" ~ 1,
                             literacy5 == "No"  ~ 0)) |> 
  mutate(self    = case_when((female == female_respondent & nominee1age == age) | 
                            (female2 == female_respondent & nominee2age == age) | 
                            (female3 == female_respondent & nominee3age == age) |
                            (female4 == female_respondent & nominee4age == age) |
                            (female5 == female_respondent & nominee5age == age) |
                            (name == name1 | name == name2 | name == name3 | name == name4 | name == name5) ~ 1,
                            nominee == 1 & self == 0 ~ 0)) |> 
  select(!c(name, name1, name2, name3, name4, name5)) |> 
  mutate(age = as.numeric(age),
         youth = as.numeric(youth),
         nominee1age = as.numeric(nominee1age),
         nominee2age = as.numeric(nominee2age),
         nominee3age = as.numeric(nominee3age),
         nominee4age = as.numeric(nominee4age),
         nominee5age = as.numeric(nominee5age))

user.input <- dlgInput("Enter today's date as MM_DD (e.g., April 15 as 04_15)", Sys.info()[""])$res

# Export sample to XSLX for later processing in Stata
write.xlsx(nom_sample, 
           file = paste0(path,'samples.xlsx'), 
           sheetName=paste0(user.input,"_3pm"), append=TRUE, showNA = F)

# Close the Selenium server
remDr$close()
