#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(maps)
library(dplyr)
library(sf)
library(ggplot2)
library(REDCapR)
source('token.R',local=T)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  ds <<- redcap_read(redcap_uri=uri, token=token)$data
  
  # a large table, reative to input$show_vars
  output$redcaptable = renderDataTable({
    ds <<- redcap_read(redcap_uri=uri, token=token)$data
    ds
  })
  
  observeEvent(input$upload,{
    upds<-data.frame(matrix(c(max(ds$record_id)+1,input$firstname,input$lastname,input$strcitystname,
                              input$phone,input$email,as.character(input$dob),as.numeric(floor(difftime(Sys.time(),as.character(input$dob))/365)),input$ethn,input$race,
                              input$gen,input$ht,input$wt,((input$wt)/(input$ht*input$ht))*10000,input$comments),nrow=1),2)
    colnames(upds)<-colnames(data.frame(ds))
    print(as.numeric(floor(difftime(Sys.time(),as.character(input$dob))/365)))
    redcap_write(ds=upds,redcap_uri=uri,token=token)
    Sys.sleep(2)
    ds <<- redcap_read(redcap_uri=uri, token=token)$data
  })
  
  output$heighthist=renderPlot({
    hist(ds$height)
  })
  output$agehist=renderPlot({
    hist(ds$age)
  })
})
