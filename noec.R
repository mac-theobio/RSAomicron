library(dplyr)

library(shellpipes)

(rdsRead()
	%>% filter(prov != "EC")
) %>% rdsSave(printSummary=TRUE)

