library(bbmle)
library(dplyr)
library(emdbook)
set.seed(1200)

library(shellpipes)

dat <- rdsRead()
loadEnvironments()

summary(dat)

## We don't need beta-binomial if "size" is big
## Consider: look at other b-b parameterizations

bbsizemax <- 100
## Iterate until convergence
cList = list(maxit = 5000)

## Bringing in but skipping Some QC first
provlist <- dat %>% pull(prov) %>% unique
fitlist <- list()
for (cp in provlist){
	print(cp)
	fit <- doublefit(
		dat = dat %>% filter(prov == cp)
		, fun = betabinfit
		, fixList=fixList
		, verbose = TRUE
	)
	if (!is.null(fit)){
		fitlist[cp] <- fit
	}
}

print(fitlist)

print(names(fitlist))

rdsSave(fitlist)
