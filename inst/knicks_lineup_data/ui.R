#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)


# Define UI for application that draws a histogram
library(shinydashboard)
library(reactable)

dashboardPage(
  dashboardHeader(title = 'NY Knicks'),
  dashboardSidebar(
   checkboxInput('use_initials', 'use player initials/jersey name', value = TRUE),
   checkboxGroupInput('select_game', 
                      'choose games to include',
                      choiceNames = choice_names,
                      choiceValues = kgs,
                      selected = tail(kgs, 1)
                      
   ),
   uiOutput('select_game')
    ),
  dashboardBody(reactableOutput('lu')))
