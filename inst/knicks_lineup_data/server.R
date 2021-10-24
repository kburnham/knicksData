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
library(reactable)
library(glue)

#authenticate_v2_x(apikey = keyring::key_get('msf_api_key'))

options("tidynbadata.archive_path" = '/srv/shiny-server/tidynbadata_archive') 

authenticate_v2_x(apikey = "ccb96ac1-d36b-482d-ab27-29ffff")

sched <- get_team_schedule(team = 'Knicks')
kgs <- sched %>% filter(status == 'complete') %>% pull(msf_game_id)
pbp_list <- map(kgs, load_pbp, team = 83)
pbps <- bind_rows(pbp_list)

player_data <- msf_get_results(version = '2.0',
                                          league = 'nba',
                                          feed = 'players',
                                          season = getOption('tidynbadata.current_season'))

# 
# lu_dat <- summarize_lineup_performance(pbps, 1, 4, player_data$api_json$players, use_player_initials = TRUE) %>% select(-lineup_vec)

get_game_label <- function(game_id, sched) {
  sched %>% filter(msf_game_id == game_id) %>% 
    glue_data('{format(date, "%m.%d")} {if_else(location == "away", "@", "")}{opponent}')
}

choice_names <- map_chr(kgs, get_game_label, sched = sched)



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  lu_dat <- reactive({summarize_lineup_performance(dat = pbps %>% filter(game_id %in% input$select_game), 
                                                   minimum_minutes = 1,
                                                   player_data = player_data$api_json$players,
                                                   use_player_initials = input$use_initials
                                                   ) %>%
    select(-lineup_vec)}) 
  
  
  ## create a dynamic selector with all completed games, whichever are checked are included in the output
  output$game_selector <- renderUI(
    checkboxGroupInput('select_game', 
                       'choose games to include',
                       choiceNames = choice_names,
                       choiceValues = kgs,
                       selected = tail(kgs, 1)

                       )
  )
  

  output$lu <- renderReactable({reactable(lu_dat())})






})
