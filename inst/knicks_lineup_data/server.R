#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidynbadata)
library(tidyverse)
library(mysportsfeedsR)
library(lubridate)


authenticate_v2_x(apikey = keyring::key_get('msf_api_key'))
sched <- get_team_schedule(team = 'Knicks')
kgs <- sched %>% filter(status == 'complete') %>% pull(msf_game_id)
pbp_list <- map(kgs, load_pbp, team = 83)
pbps <- bind_rows(pbp_list)

player_data <- msf_get_results(version = '2.0',
                                          league = 'nba',
                                          feed = 'players',
                                          season = getOption('tidynbadata.current_season'))


lu_dat <- summarize_lineup_performance(pbps, 1, 4, player_data$api_json$players) %>%
  select(-lineup_vec)




# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  output$lu <- renderTable({lu_dat})






})