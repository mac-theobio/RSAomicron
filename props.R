library(dplyr)

library(shellpipes)

loadEnvironments()

## Deleted virtual province ALL; see mvRt
ts <- (rdsRead()
	%>% mutate(NULL
		, tot = omicron + delta
		, prop = omicron/tot
	)
)

summary(ts)

rdsSave(ts)
