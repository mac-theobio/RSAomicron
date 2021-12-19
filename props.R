library(dplyr)

library(shellpipes)

loadEnvironments()

## Deleted virtual province ALL; see mvRt
ts <- (rdsRead()
	%>% mutate(NULL
		, time = as.numeric(date - zeroDate)
		, tot = omicron + delta
		, prop = omicron/tot
		, datef = factor(date)
	)
)

summary(ts)

rdsSave(ts)
