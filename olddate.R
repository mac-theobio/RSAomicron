library(dplyr)

library(shellpipes)

dataStart <- as.Date("2021-09-24")
dataEnd <- as.Date("2021-11-27")

(rdsRead()
	%>% filter(between(date, dataStart, dataEnd))
) %>% rdsSave()
## ) %>% rdsSave(printSummary=TRUE)

