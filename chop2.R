library(dplyr)

library(shellpipes)

dat <- rdsRead()
maxDate <- max(dat$date) - 2

(dat 
	%>% filter(date <= maxDate)
) %>% rdsSave
