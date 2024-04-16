#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(leaflet)

fluidPage(
  fluidRow(
    tags$head(tags$style(
      HTML(
        '
             #suburb_info {background-color: rgba(255,255,255,1); margin: 100;}
         '
      )
    )),
    titlePanel("Anxiety Disorder Patients by Suburbs"),
    leafletOutput("melbourneMap", height = 400),
    
    absolutePanel(
      id = "suburb_info",
      top = 100,
      left = 25,
      width = 250,
      class = "panel panel-default",
      draggable = TRUE,
      style = "background-color: white;
            opacity: 1;
            padding: 10px;
            margin: auto;",
      h4("Suburb info"),
      uiOutput("suburbInfo")
    )
  ),
  fluidRow(
    titlePanel("Click on a suburb to see heat maps")
  ),
  fluidRow(
    column(
      4,
      mainPanel(
        id = "raceValue_heatmap_panel",
        top = 400,
        left = 25,
        width = 350,
        height = 350,
        class = "panel panel-default",
        draggable = TRUE,
        style = "background-color: white;
            opacity: 1;
            padding: 10px;
            margin: auto;",
        h4("Heatmap of Race/ Value"),
        plotOutput("raceValuePlot")
      )
    ),
    
    column(
      4,
      mainPanel(
        id = "income_range_value_heatmap_panel",
        top = 400,
        left = 25,
        width = 350,
        height = 350,
        class = "panel panel-default",
        draggable = TRUE,
        style = "background-color: white;
            opacity: 1;
            padding: 10px;
            margin: auto;",
        h4("Heatmap of Income Range/Value"),
        plotOutput("incomeRangeValuePlot")
      )
    ),
    column(
      4,
      mainPanel(
        id = "healthcare_expenses_value_heatmap_panel",
        top = 400,
        left = 25,
        width = 350,
        height = 350,
        class = "panel panel-default",
        draggable = TRUE,
        style = "background-color: white;
            opacity: 1;
            padding: 10px;
            margin: auto;",
        h4("Heatmap of Healthcare Expenses/Value"),
        plotOutput("healthcareExpensesValuePlot")
      )
    )
  )
)
