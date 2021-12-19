library(dplyr)
library(haven)

library(shellpipes)

loadEnvironments()

ts <- (rdsRead()
	%>% group_by(prov, date, reinf)
	%>% summarise(
		omicron=sum(sgtf==1), delta=sum(sgtf==0)
		, .groups="drop"
	)
)

summary(ts)

rdsSave(ts)
