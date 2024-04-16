#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(leaflet)
library(maps)
library(dplyr)
library(sf)
library(ggplot2)


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
                                        %in% melbourne_suburbs_name, ]

patient_data <- read.csv("data/vic_anxiety.csv")

agg_data <- patient_data %>%
  group_by(Suburb) %>%
  summarize(
    total_patients = n(),
    male_count = sum(GENDER == "M"),
    female_count = sum(GENDER == "F"),
    ratio = sum(INCOME < 40340) / total_patients,
  )

melbourne_suburbs <- left_join(melbourne_suburbs, agg_data,
                               by = c("LOC_NAME" = "Suburb"))

bins <- seq(0, 1, by = 0.1)
pal <-
  colorBin("YlOrRd", domain = melbourne_suburbs$ratio, bins = bins)

function(input, output, session) {
  output$melbourneMap <- renderLeaflet({
    leaflet(data = melbourne_suburbs) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        layerId = ~ LOC_PID,
        fillColor = ~ pal(ratio),
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
        values = ~ ratio,
        opacity = 0.7,
        title = "Ratio of low income to total number of patients",
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
  
  
  update_suburb_info <- function(selected_suburb_LOC_PID) {
    output$suburbInfo <- renderUI({
      if (is.null(selected_suburb_LOC_PID)) {
        return(tags$div(""))
      } else {
        selected_suburb <- melbourne_suburbs[melbourne_suburbs$LOC_PID
                                             == selected_suburb_LOC_PID,]
        return(tags$div(
          tags$strong(selected_suburb$LOC_NAME),
          tags$div(
            paste0(
              "Total number of patients: ",
              selected_suburb$total_patients
            )
          ),
          tags$div(
            paste0(
              "Ratio of low income to total number of patients: ",
              round(selected_suburb$ratio, digits = 2)
            )
          ),
          tags$div(
            paste0("Males: ", selected_suburb$male_count),
            tags$div(paste0(
              "Females: ", selected_suburb$female_count
            ))
          ),
        ))
      }
    })
  }
  
  # Function to update heatmap
  update_heatmap <- function(suburb_id) {
    if (is.null(suburb_id)) {
      return(NULL)
    } else {
      selected_suburb <- melbourne_suburbs[melbourne_suburbs$LOC_PID
                                           == suburb_id,]
      patient_data_selected_suburb <- patient_data[patient_data$Suburb
                                           == selected_suburb$LOC_NAME,]
      
      hm_race_value_aggregated_data <- patient_data_selected_suburb %>%
        dplyr::group_by(ETHNICITY, VALUE) %>%
        tally() %>%
        mutate(Percentage = n / sum(n) * 100)
      
      output$raceValuePlot <- renderPlot({
        ggplot(hm_race_value_aggregated_data,
               aes(
                 x = ETHNICITY,
                 y = VALUE,
                 fill = Percentage
               )) +
          geom_tile() +
          scale_fill_gradient(low = "white",
                              high = "red",
                              name = "%") +
          labs(title = "",
               x = "Ethnicity",
               y = "Value") +
          theme(axis.text.x = element_text(angle = 90, vjust = 0.5))
      })
      
      income_breaks <- c(0, 40000, 50000, 70000, 100000, 999999999)
      
      income_range_labels <- c("0-30k", "30-50k", "50-70k", "70-100k", ">100k")
      
      patient_data_selected_suburb$IncomeRange <- cut(
        patient_data_selected_suburb$INCOME, breaks = income_breaks,
        labels = income_range_labels, 
        right = FALSE, include.lowest = TRUE)
      
      hm_income_range_value_aggregated_data <- patient_data_selected_suburb %>%
        dplyr::group_by(IncomeRange, VALUE) %>%
        tally() %>%
        mutate(Percentage = n / sum(n) * 100)
      
      output$incomeRangeValuePlot <- renderPlot({
        ggplot(hm_income_range_value_aggregated_data,
               aes(
                 x = IncomeRange,
                 y = VALUE,
                 fill = Percentage
               )) +
          geom_tile() +
          scale_fill_gradient(low = "white",
                              high = "red",
                              name = "%") +
          labs(title = "",
               x = "Income range",
               y = "Value") +
          theme(axis.text.x = element_text(angle = 90, vjust = 0.5))
      })
      
      healthcare_expenses_breaks <- c(0, 50000, 100000, 200000,
                                      500000, 1000000, 2000000, 999999999)
      
      healthcare_expenses_labels <- c("0-50k", "50-100k", "100-200k", "200-500k",
                                      "500-1M", "1M-2M",">2M")
      
      patient_data_selected_suburb$HealthcareExpensesRange <- 
        cut(patient_data_selected_suburb$HEALTHCARE_EXPENSES, 
            breaks = healthcare_expenses_breaks, 
            labels = healthcare_expenses_labels, 
            right = FALSE, include.lowest = TRUE)
      
      hm_healthcare_expenses_value_aggregated_data <- 
        patient_data_selected_suburb %>%
        dplyr::group_by(HealthcareExpensesRange, VALUE) %>%
        tally() %>%
        mutate(Percentage = n / sum(n) * 100)
      
      output$healthcareExpensesValuePlot <- renderPlot({
        ggplot(hm_healthcare_expenses_value_aggregated_data,
               aes(
                 x = HealthcareExpensesRange,
                 y = VALUE,
                 fill = Percentage
               )) +
          geom_tile() +
          scale_fill_gradient(low = "white",
                              high = "red",
                              name = "%") +
          labs(title = "",
               x = "Healthcare expenses",
               y = "Value") +
          theme(axis.text.x = element_text(angle = 90, vjust = 0.5))
      })
    }
  }
}
