#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#



#install packages and library
library(mongolite)
library(forcats)
library(tidyr)
library(dplyr)
library(leaflet)
library(maps)
library(sf)
library(ggplot2)
library(shiny)
library(shinydashboard)
library(survival)
# library(survminer)
library(ggfortify)
library(plotly)
library(ggsurvfit)
library(stringr)

# Install yaml package if not already installed
if (!require("yaml", character.only = TRUE)) {
  install.packages("yaml", dependencies = TRUE)
  library(yaml)
}

# Function to load configuration from a YAML file
load_config <- function(file_path) {
  tryCatch({
    config <- yaml::read_yaml(file_path)
    return(config)
  }, error = function(e) {
    stop("Failed to load config file: ", e)
  })
}

# Load the configuration
config <- load_config("data/config.yaml")

# Set up MongoDB connection
mongo_connection <- function(collection) {
  mongolite::mongo(
    collection = collection,
    creds <- config$mongo_credentials,
    url <- sprintf("mongodb://%s:%s@%s:%s/%s?authSource=%s",
                   creds$username, 
                   creds$password, 
                   creds$host_ip, 
                   creds$port, 
                   creds$db_name, 
                   creds$authSource)
  )
}

# Example to fetch data
fetch_data <- function(collection) {
  conn <- mongo_connection(collection)
  data <- conn$find('{}')
  return(data)
}

heart_disease_data <- fetch_data("heartdisease")
diabetes_data<- fetch_data("diabetes")
non_standard_data <- fetch_data("non_standard")
#setup requirements for geomap
melbourne_suburbs_name <- c(
  "Carlton", "Carlton North", "Docklands", "East Melbourne",
  "Flemington", "Kensington", "Melbourne", "North Melbourne",
  "Parkville", "Port Melbourne", "Southbank", "South Wharf",
  "South Yarra", "West Melbourne", "Albert Park", "Balaclava",
  "Elwood", "Middle Park", "Ripponlea", "St Kilda", "St Kilda East",
  "St Kilda West", "South Melbourne", "Abbotsford", "Alphington",
  "Burnley", "Clifton Hill", "Collingwood", "Cremorne", "Fairfield",
  "Fitzroy", "Fitzroy North", "Princes Hill", "Richmond"
)
melbourne_suburbs <- st_read("data/sf/vic_localities.shp")

melbourne_suburbs <- melbourne_suburbs[melbourne_suburbs$LOC_NAME
                                       %in% melbourne_suburbs_name, ] #enable this line to view only melbourne county

#function to tidyup csv and return 3 dataframes for visualization: geomap_data, km_data, and info_data
get_tidy_dataframe <- function(data) {
  
  #split the dataframe into a list of dataframes based on the values in 'redcap_repeat_instrument'
  df_list <- split(data, data$redcap_repeat_instrument)
  
  df_patient <- df_list[[1]]
  df_condition <- df_list[["conditions"]]
  df_medication <- df_list[["medications"]]
  
  #choose a condition (the most popular one)
  observe_condition <- names(table(df_condition$description_condition))[which.max(table(df_condition$description_condition))]
  
  #check whether patient is a survivor
  df_patient$survivor <- ifelse(df_patient$deathdate_patient == "", 0, 1) 
  
  #shorten the name for ethnicity
  df_patient <- df_patient %>%
    mutate(ethnicity_patient = case_when(
      ethnicity_patient == "Aboriginal and Torres Strait Islander" ~ "Aboriginal",
      TRUE ~ ethnicity_patient
    ))
  
  #get basic info TBC
  total_patient <- nrow(df_patient)
  total_medication_record <- nrow(df_medication)
  
  #2. filter out the required column for geo map
  # Intended structure of geo_data
  match_data <- data.frame(
    Id = character(),
    RACE = character(),
    GENDER = character(),
    ETHNICITY = character(),
    INCOME = numeric(),
    HEALTHCARE_EXPENSES = numeric(),
    HEALTHCARE_COVERAGE = numeric(),
    Suburb = character(),
    VALUE = numeric(),
    stringsAsFactors = FALSE
  )
  
  column_mapping <- c(
    id_patient = "Id",
    race_patient = "RACE",
    gender_patient = "GENDER",
    ethnicity_patient = "ETHNICITY",
    income_patient = "INCOME",
    healthcare_expenses_patient = "HEALTHCARE_EXPENSES",
    healthcare_coverage_patient = "HEALTHCARE_COVERAGE",
    county_patient = "Suburb",
    survivor = "VALUE"
  )
  
  geo_data <- df_patient %>%
    select(any_of(names(column_mapping))) %>%
    rename_all(~ column_mapping[.]) %>%
    mutate(INCOME = as.numeric(INCOME),
           HEALTHCARE_EXPENSES = as.numeric(HEALTHCARE_EXPENSES),
           HEALTHCARE_COVERAGE = as.numeric(HEALTHCARE_COVERAGE))
  
  # Add missing columns with all NA values
  missing_columns <- setdiff(names(match_data), names(geo_data))
  for (col in missing_columns) {
    geo_data[[col]] <- NA
  }
  
  
  #3. filter out the required column for Kaplan Meier
  km_data_patient <- df_patient %>%
    select(Id = id_patient, end_date = deathdate_patient, Status = survivor)
  
  km_data_condition <- df_condition %>%
    select(Id = id_patient, condition = description_condition, start_date = start_condition)
  
  km_data_medication <- df_medication %>%
    select(Id = id_patient, group = description_medication)
  
  km_data <- km_data_patient %>%
    full_join(km_data_condition, by = "Id", relationship =
                "many-to-many") %>%
    full_join(km_data_medication, by = "Id", relationship =
                "many-to-many")
  
  #fill missing end_date to today
  km_data$end_date[is.na(km_data$end_date)] <- format(Sys.Date(), format = "%Y-%m-%d")
  
  #calculate survive days by end_date - start_date and assign it to a new column called Times
  km_data$start_date <- as.Date(km_data$start_date, format = "%Y-%m-%d")
  km_data$end_date <- as.Date(km_data$end_date, format = "%Y-%m-%d")
  km_data$Time <- as.integer(km_data$end_date - km_data$start_date)
  
  #filter out two most common group for comperation
  sorted_km_data <- sort(table(km_data$group), decreasing = TRUE)
  drugs_of_interest <- names(sorted_km_data)[1:2]
  filtered_km_data <- km_data[km_data$group %in% drugs_of_interest, ]
  
  #drop repeat info and those Time is negative (dates are entered incorrectly)
  filtered_km_data <- unique(filtered_km_data)
  filtered_km_data <- filtered_km_data[filtered_km_data$Time >= 0, ]
  
  
  #4.output a basic info dataframe
  info_df <- data.frame(
    condition = observe_condition,
    total_patient = total_patient,
    total_medication_record = total_medication_record,
    row.names = NULL
  )
  return(list(geo_data = geo_data, km_data = filtered_km_data, info_df = info_df))
}

#function to get kaplan meier plot
get_kaplan_meier_plot <- function(data, time_unit = "Day") {
  if (time_unit == "Year") {
    data$Time <- data$Time / 365.25  # Convert days to years
  } else if (time_unit == "Month") {
    data$Time <- data$Time / 30.44  # Convert days to months
  }
  
  data = data.frame(Time = data$Time, Status = data$Status,group = data$group)
  km_fit <- surv_fit(Surv(Time, Status) ~ group, data=data)
  # if there is exactly two group then we can use the logrank test 
  whetherlogranktest = (length(unique(data$group))==2)
  pvalue_text = ""
  if(whetherlogranktest){
    pvalue = toString(round(survdiff(Surv(Time, Status) ~ group, data=data)$pvalue,8))
    pvalue_text = paste0("logrank pvalue: \n ",pvalue)
  }
  
  p = autoplot(km_fit, censor.shape = "+", censor.alpha = 0) + 
    labs(x = paste("\n Survival Time in", time_unit) , y = "Survival Probabilities \n", 
         title = paste("Kaplan Meier plot")) + 
    ylim(0, 1) +
    annotate("text", x=max(data$Time)/5, y=0, label= pvalue_text)+
    
    theme(plot.title = element_text(face="bold",hjust = 0.5), 
          axis.title.x = element_text(face="bold", colour="darkgreen", size = 11),
          axis.title.y = element_text(face="bold", colour="darkgreen", size = 11),
          legend.title = element_text(face="bold", size = 10))+
    scale_color_viridis_d()
  
  
  # ggplot do not developed for CI
  ggplotly(p)
}