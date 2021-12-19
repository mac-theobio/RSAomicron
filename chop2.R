library(dplyr)

library(shellpipes)

dat <- rdsRead()
maxTime <- max(dat$time) - 2

(dat 
	%>% filter(time <= maxTime)
) %>% rdsSave
