library(bbmle)
library(dplyr)
library(emdbook)
set.seed(1200)

library(shellpipes)

dat <- rdsRead()
loadEnvironments()

summary(dat)
provlist <- dat %>% pull(prov) %>% unique
fitlist <- list()
for (cp in provlist){
	print(c("Starting", cp))
	fitlist[[cp]] <- doublefit(
		dat = dat  %>% filter(prov == cp)
		, fun = ssbetafit
		, fixed=fixList
		, profile=TRUE, wald=TRUE
	)
}

rdsSave(fitlist)

