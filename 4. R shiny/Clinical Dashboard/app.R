#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

#install packages and library
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
library(survminer)
library(ggfortify)
library(plotly)
library(ggsurvfit)
library(stringr)

#read local database
heart_disease_data <- read.csv("data/heart_disease_data.csv")
diabetes_data <- read.csv("data/diabetes_data.csv")
non_standard_data <- read.csv("data/non_standard_data.csv")

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
  #1. split combined csv into three separated df: patient, condition, medication.
  #fill NA values in 'redcap_repeat_instrument' column with "patient"
  data$redcap_repeat_instrument <- dplyr::coalesce(data$redcap_repeat_instrument, "patient")
  
  #split the dataframe into a list of dataframes based on the values in 'redcap_repeat_instrument'
  df_list <- split(data, data$redcap_repeat_instrument)
  
  df_patient <- df_list[["patient"]]
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
    rename_all(~ column_mapping[.])
  
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



# Define UI for application
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Clinical Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Welcome!", tabName = "welcome", icon = icon("home")),
      menuItem("Map & Suburb Info", tabName = "map_suburb_info", icon = icon("dashboard")),
      menuItem("Kaplan-Meier Plot", tabName = "km_plot", icon = icon("th"))
    )
  ),
  dashboardBody(
    tags$head(tags$style(HTML("
    /* CSS styles to apply globally */
    p{
      margin-bottom: 5px;
    }"))),
    tabItems(
      tabItem(tabName = "welcome",
              fluidRow(tags$div(tags$strong("Welcome!"), style = "font-size: 22px;")),
              fluidRow(HTML(r"(
                            <p style="font-size:16px;">This is a Clinical Dashboard offers multiple interactive visualizations.</p>
                            <p style="font-size:16px;">By inputing a standard RedCap project's API, this dashboard automatically generate mutiple visualization to provide user a better understanding of the studied disease.</p>
                            <p style="font-size:16px;">Currently, it allows user to view disease distribution by suburb through a interactive map that supports Melbourne and entire Victora region. 
                            It also provides a Kaplan-Meier Plot that compare the effects of most commonly used two medicine on patient's death rate.</p>
                            <p style="font-size:16px;">You can preview its effect by selecting three defaultly provided database. You can find the original RedCap through link below.
                            Notice that all of these database use stimulated data generated from <a href="https://github.com/synthetichealth/synthea" target="_blank">Synthea<sup>TM</sup></a>, a synthetic patient generator that models the medical history of synthetic patients, for testing purpose.</p>
                            <br></br>
                            <p style="font-size:16px;"><b>Hyperlink to database</b>:</p>
                            <p style="font-size:16px;"><a href="https://redcap.wehi.edu.au/redcap_v14.1.5/ProjectSetup/index.php?pid=658" target="_blank">TEST Ischemic heart disease in melbourne</a></p>
                            <p style="font-size:16px;"><a href="https://redcap.wehi.edu.au/redcap_v14.1.5/ProjectSetup/index.php?pid=656" target="_blank">TEST diabetes in melbourne</a></p>
                            <p style="font-size:16px;"><a href="https://redcap.wehi.edu.au/redcap_v14.1.5/ProjectSetup/index.php?pid=657" target="_blank">TEST Non-standard Dataset</a></p>
                            <br></br>
                            )")),
              fluidRow(
                box(status = "primary", selectInput("databaseSelect", "Select Database to Preview", 
                                   choices = c("Ischemic Heart Disease in Melbourne", "Diabetes in Melbourne", "Non-Standard Database"))
                )
              )
      ),
      tabItem(tabName = "map_suburb_info",
              fluidRow(
                tags$div(tags$strong("Interactive Map for", textOutput("databaseName1", inline = TRUE)), style = "font-size: 22px;")
              ),    
              leafletOutput("melbourneMap"),
              tabsetPanel(
                tabPanel("Suburb Info", 
                         fluidRow(box(status = "primary", uiOutput("suburbInfo"))),
                         fluidRow(HTML(r"(<p>Hover on to preview suburb, click on to select suburb.</p>)"))), 
                tabPanel("Local Heatmaps",
                         fluidRow(uiOutput("suburbNameHeatmap")),
                         fluidRow(
                           column(width = 4, plotOutput("raceSurvivalPlot")),
                           column(width = 4, plotOutput("incomeRangeSurvivalPlot")),
                           column(width = 4, plotOutput("healthcareExpensesSurvivalPlot"))),
                         fluidRow(HTML(r"(
                     <p><b>Note</b>:</p>
                     <p><b>Ethnicity</b>: Individuals are categorized as either "Aboriginal and Torres Strait Islander" or "Others".</p>
                     <p><b>Income</b>: Income levels are grouped into the following bins: "0-30k", "30-50k", "50-70k", "70-100k", and ">100k".</p>
                     <p><b>Healthcare Expenses</b>: Healthcare expenses are categorized into the following bins: "0-50k", "50-100k", "100-200k", "200-500k", "500k-1M", "1M-2M", and ">2M".</p>
                     )"))
                )
              )
      ),
      tabItem(tabName = "km_plot", 
              fluidRow(
                tags$div(tags$strong("Interactive Kaplan-Meier Plot for", textOutput("databaseName2", inline = TRUE)), style = "font-size: 22px;")
              ),
              plotlyOutput("kmPlot"),
              fluidRow(HTML(r"(
              <p><b>Note</b>:</p>
              <p>The Kaplan-Meier Plot displayed above utilizes "Year" as its time unit.</p>
              <p>The logrank p-value indicates whether there is a statistically significant difference in survival curves between the groups being compared. If the p-value is less than 0.05, it suggests that there is a statistically significant difference in survival between the groups. 
If the p-value is greater than or equal to 0.05, it suggests that there is no statistically significant difference in survival between the groups.</p>
                            )"))
      )
    )
  )
)



# Define server logic
server <- function(input, output, session) {
  
  #load local data
  geo_data1 <- get_tidy_dataframe(heart_disease_data)$geo_data
  km_data1 <- get_tidy_dataframe(heart_disease_data)$km_data
  info_df1 <- get_tidy_dataframe(heart_disease_data)$info_df
  
  geo_data2 <- get_tidy_dataframe(diabetes_data)$geo_data
  km_data2 <- get_tidy_dataframe(diabetes_data)$km_data
  info_df2 <- get_tidy_dataframe(diabetes_data)$info_df
  
  geo_data3 <- get_tidy_dataframe(non_standard_data)$geo_data
  km_data3 <- get_tidy_dataframe(non_standard_data)$km_data
  info_df3 <- get_tidy_dataframe(non_standard_data)$info_df
  
  # Reactive values to manage data filtering
  filtered_data <- reactive({
    switch(input$databaseSelect,
           "Ischemic Heart Disease in Melbourne" = km_data1,
           "Diabetes in Melbourne" = km_data2,
           "Non-Standard Database" = km_data3)
  })
  
  patient_data <- reactive({
    switch(input$databaseSelect,
           "Ischemic Heart Disease in Melbourne" = geo_data1,
           "Diabetes in Melbourne" = geo_data2,
           "Non-Standard Database" = geo_data3)
  })
  
  info_df <- reactive({
    switch(input$databaseSelect,
           "Ischemic Heart Disease in Melbourne" = info_df1,
           "Diabetes in Melbourne" = info_df2,
           "Non-Standard Database" = info_df3)
  })

  # Extracting condition from info_df reactive object
  # Define condition as a reactive value
  condition <- reactive({
    info_df()$condition
  })
  
  # Define total_patient as a reactive value
  total_patient <- reactive({
    info_df()$total_patient
  })
  
  melbourne_suburbs <- melbourne_suburbs
  
  # Make agg_data a reactive expression
  agg_data <- reactive({
    patient_data() %>%
      group_by(Suburb) %>%
      summarize(
        all_patients = n(),
        male_count = sum(GENDER == "1"),
        female_count = sum(GENDER == "2"),
        ratio = all_patients / total_patient()
      )
  })
  # Join the data with melbourne_suburbs inside a reactive expression
  melbourne_suburbs_data <- reactive({
    left_join(melbourne_suburbs, agg_data(), by = c("LOC_NAME" = "Suburb"))
  })

  #output
  output$databaseName1 <- renderText({
    condition()
  })
  
  output$databaseName2 <- renderText({
    condition()
  })
  
  output$melbourneMap <- renderLeaflet({
    bins <- seq(0, total_patient() / 10, by = 10)
    pal <- colorBin("YlGn", domain = melbourne_suburbs_data()$all_patients, bins = bins)
    
    leaflet(data = melbourne_suburbs_data()) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        layerId = ~ LOC_PID,
        fillColor = ~ pal(all_patients),
        weight = 2,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlight = highlightOptions(
          weight = 5,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.7,
          bringToFront = TRUE
        ),
        label = ~ LOC_NAME,
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto"
        )
      ) %>%
      addLegend(
        pal = pal,
        values = ~ all_patients,
        opacity = 0.7,
        title = "Number of patients",
        position = "bottomright"
      )
  })
  
  observe({
    # when hover on
    hover_suburb_LOC_PID <- input$melbourneMap_shape_mouseover$id
    update_suburb_info(hover_suburb_LOC_PID)
  })
  
  observeEvent(input$melbourneMap_shape_click, {
    # when click on
    clicked_suburb_LOC_PID <- input$melbourneMap_shape_click$id
    update_heatmap(clicked_suburb_LOC_PID)
  })
  
  # Rendering the Kaplan-Meier plot
  output$kmPlot <- renderPlotly({
    # Use the reactive filtered_data
    plot_data <- filtered_data()
    get_kaplan_meier_plot(plot_data, 'Year')
  })
  
  
  update_suburb_info <- function(selected_suburb_LOC_PID) {
    output$suburbInfo <- renderUI({
      if (is.null(selected_suburb_LOC_PID)) {
        return(tags$div(""))
      } else {
        selected_suburb <- melbourne_suburbs_data()[melbourne_suburbs_data()$LOC_PID == selected_suburb_LOC_PID,]
        return(tags$div(
          tags$strong(selected_suburb$LOC_NAME, style = "font-size: 20px;"),
          tags$div(
            paste0(
              "Total number of patients: ", selected_suburb$all_patients),
            style = "font-size: 16px;"
          ),
          tags$div(
            paste0("Raito of patients: ", selected_suburb$ratio),
            style = "font-size: 16px;"
          ),
          tags$div(
            paste0("Females: ", selected_suburb$female_count),
            style = "font-size: 16px;"
          ),
          tags$div(
            paste0("Males: ", selected_suburb$male_count),
            style = "font-size: 16px;"
          ),
          style = "line-height: 1.5;" 
        ))
      }
    })
  }
  
  # Function to update heatmap
  update_heatmap <- function(suburb_id) {
    output$suburbNameHeatmap <- renderUI({
      if (is.null(suburb_id)) {
        return(HTML(r"(Select one suburb to view heatmaps.)"))
      } else {
        selected_suburb <- melbourne_suburbs_data()[melbourne_suburbs_data()$LOC_PID == suburb_id,]
        return(tags$div(
          tags$strong(
            "Heatmaps for ", selected_suburb$LOC_NAME, style = "font-size: 20px;")
        ))
      }
    })
    
    if (is.null(suburb_id)) {
      return(NULL)
    } else {
      selected_suburb <- melbourne_suburbs_data()[melbourne_suburbs_data()$LOC_PID == suburb_id,]
      patient_data_selected_suburb <- patient_data()[patient_data()$Suburb == selected_suburb$LOC_NAME,]
      
      hm_race_survival_aggregated_data <- patient_data_selected_suburb %>%
        dplyr::group_by(ETHNICITY, VALUE) %>%
        tally()
      
      
      output$raceSurvivalPlot <- renderPlot({
        
        ggplot(hm_race_survival_aggregated_data,
               aes(
                 x = ETHNICITY,
                 y = as.factor(VALUE),
                 fill = n
               )) +
          geom_tile() +
          geom_text(aes(label = n), vjust = -0.3) +
          scale_fill_gradient(low = "#CAE1FF",
                              high = "slateblue4",
                              name = "Count",
                              labels = scales::number_format(accuracy = 1)) +
          labs(title = "Race vs. Survival Heatmap",
               x = "Ethnicity",
               y = "Survival") +
          scale_y_discrete(labels=c("No", "Yes")) +
          theme(
            plot.title = element_text(face="bold"),
            axis.text.x = element_text(angle = 90, vjust = 0.5),
            axis.text.y = element_text(color = "black"))
      })
      
      income_breaks <- c(0, 40000, 50000, 70000, 100000, 999999999)
      income_range_labels <- c("0-30k", "30-50k", "50-70k", "70-100k", ">100k")
      patient_data_selected_suburb$IncomeRange <- cut(patient_data_selected_suburb$INCOME, breaks = income_breaks, labels = income_range_labels, right = FALSE, include.lowest = TRUE)
      
      hm_income_range_survival_aggregated_data <- patient_data_selected_suburb %>%
        dplyr::group_by(IncomeRange, VALUE) %>%
        tally()
      
      output$incomeRangeSurvivalPlot <- renderPlot({
        ggplot(hm_income_range_survival_aggregated_data,
               aes(
                 x = IncomeRange,
                 y = as.factor(VALUE),
                 fill = n
               )) +
          geom_tile() +
          geom_text(aes(label = n), vjust = -0.3) +
          scale_fill_gradient(low = "#CAE1FF",
                              high = "slateblue4",
                              name = "Count",
                              labels = scales::number_format(accuracy = 1)) +
          labs(title = "Income Range vs. Survival Heatmap",
               x = "Income range",
               y = "Survival") +
          scale_y_discrete(labels=c("No", "Yes")) +
          theme(
            plot.title = element_text(face="bold"),
            axis.text.x = element_text(angle = 90, vjust = 0.5),
            axis.text.y = element_text(color = "black"))
      })
      
      healthcare_expenses_breaks <- c(0, 50000, 100000, 200000, 500000, 1000000, 2000000, 999999999)
      healthcare_expenses_labels <- c("0-50k", "50-100k", "100-200k", "200-500k", "500-1M", "1M-2M",">2M")
      patient_data_selected_suburb$HealthcareExpensesRange <- cut(patient_data_selected_suburb$HEALTHCARE_EXPENSES, breaks = healthcare_expenses_breaks, labels = healthcare_expenses_labels, right = FALSE, include.lowest = TRUE)
      
      hm_healthcare_expenses_survival_aggregated_data <- patient_data_selected_suburb %>%
        dplyr::group_by(HealthcareExpensesRange, VALUE) %>%
        tally()
      
      output$healthcareExpensesSurvivalPlot <- renderPlot({
        ggplot(hm_healthcare_expenses_survival_aggregated_data,
               aes(
                 x = HealthcareExpensesRange,
                 y = as.factor(VALUE),
                 fill = n
               )) +
          geom_tile() +
          geom_text(aes(label = n), vjust = -0.3) +
          scale_fill_gradient(low = "#CAE1FF",
                              high = "slateblue4",
                              name = "Count",
                              labels = scales::number_format(accuracy = 1)) +
          labs(title = "Healthcare Expenses vs. Survival Heatmap",
               x = "Healthcare expenses",
               y = "Survival") +
          scale_y_discrete(labels=c("No", "Yes")) +
          theme(
            plot.title = element_text(face="bold"),
            axis.text.x = element_text(angle = 90, vjust = 0.5),
            axis.text.y = element_text(color = "black"))
      })
    }
  }
}

# Run the application 
shinyApp(ui = ui, server = server)
