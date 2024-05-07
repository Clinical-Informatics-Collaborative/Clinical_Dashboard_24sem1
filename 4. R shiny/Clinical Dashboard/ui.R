#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
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