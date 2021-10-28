library(shiny)
library(shinydashboard)
library(reactable)
library(dashboardthemes)


source('/srv/shiny-server/knicksData/inst/custom_theme.R')
dashboardPage(
  dashboardHeader(title = 'NY Knicks'),
  dashboardSidebar(
   checkboxInput('use_initials', 'use player initials + jersey number', value = TRUE),
   sliderInput('minimum_minutes', 'Minimum minutes played:', 0, 20, 0),
   uiOutput('game_selector2'),
   uiOutput('player_selector2')
   
    ),
  dashboardBody(
    customTheme,
    reactableOutput('lu'))
  )
