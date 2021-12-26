library(dplyr)

library(shellpipes)

dataStart <- as.Date("2021-09-24")
dataEnd <- as.Date("2021-12-06")

(rdsRead()
	%>% filter(between(date, dataStart, dataEnd))
) %>% rdsSave(printSummary=TRUE)

