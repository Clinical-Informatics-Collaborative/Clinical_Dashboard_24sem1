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
library(survminer)
library(ggfortify)
library(plotly)
library(ggsurvfit)
library(stringr)


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
