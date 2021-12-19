library(mgcv)
library(tidyr)
library(dplyr)

bbinshape <- 3
set.seed(2117)

library(shellpipes)
loadEnvironments()

sr <- rdsRead()
summary(sr)
nr <- nrow(sr)
sr <- (sr 
	%>% rowwise
	%>% transmute(prov, time, reinf
		, omicron = wraprbetabinom_shape(1, prop, tot, bbinshape)
		, delta = wraprbetabinom_shape(1, 1-prop, tot, bbinshape)
		, tot = omicron+delta
		, prop = omicron/tot
	)
)

summary(sr)

rdsSave(sr)
