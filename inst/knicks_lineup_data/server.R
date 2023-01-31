#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
library(shiny)
library(tidynbadata)
library(tidyverse)
library(mysportsfeedsR)
library(lubridate)
library(reactable)
library(glue)
library(shinyWidgets)

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


# debugonce(summarize_lineup_performance)
lu_dat <- summarize_lineup_performance(pbp_list[[3]], 1, 4, player_data$api_json$players) %>%
  select(-lineup_vec)


get_game_label <- function(game_id, sched) {
  sched %>% filter(msf_game_id == game_id) %>% 
    glue_data('{format(date, "%m.%d")} {if_else(location == "away", "@", "")}{opponent} [{wins}-{losses}] {toupper(str_sub(result, 1, 1))}')
}

choice_names <- map_chr(kgs, get_game_label, sched = sched)


game_choices <- as.list(kgs) %>% set_names(choice_names)

# define player choices


players <- player_data$api_json$players %>% filter(player.id %in% unique(unlist(pbps$gs_this_pof_vec))) %>% 
  select(player.id, player.firstName, player.lastName, player.primaryPosition, player.jerseyNumber) %>% 
  select(player.lastName, player.id)  %>% deframe()



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  
  plays <- reactive({
    #cat(file=stderr(), input$select_game2)
    pbps %>% filter(game_id %in% input$select_game2)
    })
  
  lu_dat <- reactive({
    req(input$select_game2)
    summarize_lineup_performance(dat = plays(), 
                                 minimum_minutes = input$minimum_minutes,
                                 player_data = player_data$api_json$players,
                                 use_player_initials = input$use_initials
                                 ) %>% 
      filter(tidynbadata:::filter_lineup(lineup_vec, includes = input$select_players2, excludes = c()))}) 
  

  
  
  ## create a dynamic selector with all completed games, whichever are checked are included in the output
  # output$game_selector <- renderUI({
  #   checkboxGroupInput('select_game', 
  #                      'choose games to include',
  #                      choiceNames = choice_names,
  #                      choiceValues = kgs,
  #                      selected = tail(kgs, 1)
  #                      )
  # })
  
  output$game_selector2 <- renderUI({
    
    
    pickerInput(
    inputId = "select_game2",
    label = "choose games to include",
    choices = game_choices,
    options = list(
      `actions-box` = TRUE,
      size = 10 
      #`selected-text-format` = "count > 3"
    ),
    selected = tail(game_choices, 1),
    multiple = TRUE
  )})
  
  
  output$player_selector <- renderUI({
    checkboxGroupInput('select_players', 
                       'choose players to include',
                       choiceNames = names(players),
                       choiceValues = unname(players),
                       selected = c()
    )
  })
  
  
  output$player_selector2 <- renderUI({
    
    
    pickerInput(
      inputId = "select_players2",
      label = "choose players to include",
      choices = players,
      options = list(
        `actions-box` = TRUE,
        size = 10 
        #`selected-text-format` = "count > 3"
      ),
      selected = c(),
      multiple = TRUE
    )})
  
  
  
  
  

  output$lu <- renderReactable({reactable(lu_dat() %>%
                                            select(-lineup_vec))})






})
