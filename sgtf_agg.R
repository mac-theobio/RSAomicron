library(dplyr)
library(haven)

library(shellpipes)

loadEnvironments()

ts <- (rdsRead()
	%>% group_by(prov, time)
	%>% summarise(
		omicron=sum(omicron), delta=sum(delta)
		, .groups="drop"
	)
)

summary(ts)

rdsSave(ts)

