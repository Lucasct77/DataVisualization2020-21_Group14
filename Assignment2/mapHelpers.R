cities_map <- function(shootings, years){
  # Prepare data
  shootings$city_state <- paste(shootings$city, shootings$state, sep=" ")
  data <-count(shootings[2014 + as.integer(shootings$year) >= years[1] & 2014 + as.integer(shootings$year) <= years[2],], 'city_state')
  data <- merge(data, us.cities, by.x="city_state", by.y="name",no.dups = TRUE, suffixes = c("",""))
  return(data)
}

victims_map <- function(shootings, gender, race, age) {
  
  # Filter data 
  gen <- switch(gender, 
                   "Male and Female" = "male and female",
                   "Male" = "M",
                   "Female" = "F")
  totals <- count(shootings, 'state')
  
  if(gen == "male and female" & race == "All races"){
    data <-count(shootings[shootings$age >= age[1] & shootings$age <= age[2],], 'state')
  }
  else if(gen == "male and female"){
    data <-count(shootings[shootings$race == race & shootings$age >= age[1] & shootings$age <= age[2],], 'state')
  }
  else if(race == "All races"){
    data <-count(shootings[shootings$gender == gen & shootings$age >= age[1] & shootings$age <= age[2],], 'state')
  }
  else {
    data <-count(shootings[shootings$gender == gen & shootings$race == race & shootings$age >= age[1] & shootings$age <= age[2],], 'state')
  }


colnames(data) <- c("region", "n")
data <- rbind(data, subset(data.frame(region = state.abb, n = replicate(length(state.abb), 0)), !(region %in% data$region)))
data <- merge(data, totals, by.x="region", by.y="state",no.dups = TRUE, suffixes = c("",""))
data$name <- state.name[match(data$region,state.abb)]
data$value <- round((data$n / data$freq)*100, digits = 2)
data$hover <- paste( data$name, "<br>", sep = "")
data <- subset(data, select=c(region, name, value, hover))

return(data)
#state_choropleth(data, num_colors = 9, title = paste0("% US police shootings 2015-2020 with victim's profile:\n", race, ", ", gen, ", age between ", age[1], " and ", age[2]), legend = "% of total state shootings")
}

season_map <- function(shootings, season, filt) {
  
  if(season == "Day of the week") {
    day_n <- switch(filt, 
                    "Week days" = "wd",
                    "Weekend" = "we",
                    "Monday" = "1", 
                    "Tuesday" = "2",
                    "Wednesday" = "3",
                    "Thursday" = "4",
                    "Friday" = "5", 
                    "Saturday" = "6",
                    "Sunday" = "7")
     if(day_n == "wd") {
      data <-count(shootings[shootings$day == "1" | shootings$day == "2" | shootings$day == "3" | shootings$day == "4" | shootings$day == "5" , ],"state" )
    } else if (day_n == "we") {
      data <-count(shootings[shootings$day == "6" | shootings$day == "7" ,], "state")
    } else {
      data <-count(shootings[shootings$day == day_n, ], "state")
    }
    
  }
  else if (season == "Month") {
    month_n <- switch(filt, 
                      "January" = "1",
                      "February" = "2",
                      "March" = "3", 
                      "April" = "4",
                      "May" = "5",
                      "June" = "6",
                      "July" = "7", 
                      "August" = "8",
                      "september" = "9", 
                      "October" = "10",
                      "November" = "11", 
                      "December" = "12")
     data <-count(shootings[shootings$month == month_n, ], "state")
  }
  else if (season == "Season") {
    if(filt == "Spring: Mar, Apr, May") {
      data <-count(shootings[shootings$month == "3" | shootings$month == "4" | shootings$month == "5" , ], "state")
    } else if(filt == "Summer: Jun, Jul, Aug") {
      data <-count(shootings[shootings$month == "6" | shootings$month == "7" | shootings$month == "8" , ], "state")
    } else if(filt == "Autumn: Sep, Oct, Nov") {
      data <-count(shootings[shootings$month == "9" | shootings$month == "10" | shootings$month == "11" , ], "state")
    } else {
      data <-count(shootings[shootings$month == "12" | shootings$month == "1" | shootings$month == "2" , ], "state")
    }
  }
  
  else if(season == "Year quarter") {
    if(filt == "Q1: Jan, Feb, Mar") {
      data <-count(shootings[shootings$month == "1" | shootings$month == "2" | shootings$month == "3" , ], "state")
    } else if(filt == "Q2: Apr, May, Jun") {
      data <-count(shootings[shootings$month == "4" | shootings$month == "5" | shootings$month == "6" , ], "state")
    } else if(filt == "Q3: Jul, Aug, Sep") {
      data <-count(shootings[shootings$month == "7" | shootings$month == "8" | shootings$month == "9" , ], "state")
    } else {
      data <-count(shootings[shootings$month == "10" | shootings$month == "11" | shootings$month == "12" , ], "state")
    }
  }
  
  
  colnames(data) <- c("region", "value")
  data$region <- state.name[match(data$region,state.abb)]
  data$region <- tolower(data$region)
  data <- rbind(data, subset(data.frame(region = tolower(state.name), value = replicate(length(state.name), 0)), !(region %in% data$region)))
  sum = sum(data$value)
  state_choropleth(data, num_colors = 9, title = paste0("US police shootings 2015-2020, seasonal patterns:\n Seasonality: ", season, ", filtered to: ", filt), legend = paste0("Total shootings: ", sum))
  
}

GenerateHeatmap <- function(dat, x1, y1, grid1 = "", grid2 = ""){
  if(x1=='age'){
    x2 = x1
    x1 = y1
    y1 <- x2
  }
  
  vars = c(x1,y1)
  if(grid1 != "") {
    #dat <- dat %>% mutate_at(vars(starts_with(grid1)), ~(paste(grid1, "=",.) %>%  as.factor()))
    vars <-  c(vars, grid1)
  }
  if(grid2 != "") {
    #dat <- dat %>% mutate_at(vars(starts_with(grid2)), ~(paste(grid2, "=",.) %>%  as.factor()))
    vars <-  c(vars, grid2)}
  
  if ('age' %in% vars) {
    dat <- dat %>% select(all_of(vars))
    if (length(vars) == 2)  {
      names(dat) <- (c("x", "y"))
    } else if (length(vars) == 3) {
      names(dat) <- (c("x", "y", ifelse(grid1 != "",'g1','g2')))
    } else   {
      names(dat) <- (c("x", "y", 'g1', 'g2'))
    }
    
    p <-
      ggplot(dat, aes(x = reorder(x,y,na.rm = T), y, fill = reorder(x,y,na.rm = T))) +
      geom_boxplot() +  scale_fill_brewer(palette = "Blues") + 
      labs(x = x1, y = y1, fill = x1)
  } else {
    dat <- dat %>% select(all_of(vars)) %>%
      group_by_at(vars) %>% dplyr::summarise(n = dplyr::n())
    
    
    if (length(vars) == 2)  {
      names(dat) <- (c("x", "y", "z"))
    } else if (length(vars) == 3) {
      names(dat) <- (c("x", "y", ifelse(grid1 != "",'g1','g2'), "z"))
    } else   {
      names(dat) <- (c("x", "y", 'g1', 'g2', "z"))
    }
    
    dat$text = paste0("x: ", dat$x, "\n", "y: ", dat$y, "\n", "Value: ", round(dat$z, 2))
    
    
    p <-
      ggplot(dat, aes(x, y, fill = desc(z), text = text)) +
      geom_tile() +  scale_fill_distiller(palette = "Blues") +  
      labs(x = x1, y = y1, fill = 'Count')
  }
  
  p <- p + theme_ipsum() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text.y = element_text(angle = 45))
  if(grid1 != "" | grid2 != "") {
    form <- paste(ifelse(grid1!= "",'g1', '.'), '~', ifelse(grid2!= "",'g2', '.')) %>% as.formula()
    p <- p  + facet_grid(form, scales = "free")
  }
  

  
  return(ggplotly(p, tooltip="text"))
}

GenerateTreemap <- function(data, vars){
  
  data <- data %>% select(any_of(vars)) %>%
    group_by_at(vars) %>% dplyr::summarise(n = dplyr::n())
  
  p <- treemap(data,
               index=vars,
               vSize="n",
               type="index",
               fontsize.labels=c(15,12),
               fontcolor.labels=c("black","grey"),
               fontface.labels=c(2,1),
               palette = "Blues",
               bg.labels=c("transparent"),
               align.labels=list(
                 c("center", "center"), 
                 c("right", "bottom")
               )  
  ) 
  
 return(d3tree2( p ,  rootname = "Shootings" ))
}


GenerateTimeLine <- function(data, time, var){
  vars <- c(time, var)
  data$year_month <- paste0(data$year, '-', data$month)
  data <- data %>% select(any_of(vars)) %>%
    group_by_at(vars) %>% dplyr::summarise(n = dplyr::n())
  names(data) <- c('t', 'g', 'n')
  data$text = paste0("x: ", data$t, "\n", "y: ", data$g, "\n", "Value: ",data$n)
  p <- ggplot(data, aes(x = t, y = n)) +
    geom_point(aes(text= paste0(time,": ", data$t, "\n", var,": ", data$g, "\n", "Count: ",data$n)), color = 'steelblue') +
    geom_line(aes(group = g), color = 'steelblue')+
    labs(x = time, y = 'Count') +
    theme_ipsum() + facet_grid(g~., scales = "free_y")
  
  return(ggplotly(p, tooltip="text"))
}
