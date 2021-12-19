library(mgcv)
library(tidyr)
library(dplyr)

bbinsig <- 3

library(shellpipes)
loadEnvironments()

sr <- rdsRead()
summary(sr)
nr <- nrow(sr)
sr <- (sr 
	%>% rowwise
	%>% transmute(prov, time, reinf
		, omicron = wraprbetabinom_shape(1, prop, tot, bbinsig)
		, delta = wraprbetabinom_shape(1, 1-prop, tot, bbinsig)
		, tot = omicron+delta
		, prop = omicron/tot
	)
)

summary(sr)

rdsSave(sr)
