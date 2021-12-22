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

## Logistic function with imperfect testing
baselogis <- function(tvec, loc, delta_r, lodrop, logain){
	drop <- plogis(lodrop)
	gain <- plogis(logain)

	ptrue <- plogis((tvec-loc)*delta_r)
	return(ptrue*(1-gain) + (1-ptrue)*drop)
}

doublefit <- function(
	dat, fun, fixed
	, first="Nelder-Mead", second="BFGS", verbose=FALSE, ...
){
	m <- fun(dat=dat, method=first, fixed=fixed, ...)
	if(verbose){
		print("Base fit")
		print(coef(m))
	}
	if(is.null(m)) return(m)
	return(update(m, start = as.list(coef(m)), method = second))
}

ssbetafit <- function(dat
	, start = list(
		loc = NULL, delta_r = 1 , lodrop=-4, logain=-7 , lbbsize=0
	)
	, method = "Nelder-Mead"
	, printCoef=FALSE
	, fixed
	, cList = list(maxit = 5000)
){
	if (is.null(start[["loc"]])) start[["loc"]] <- mean(dat$time)
	return(mle2(
		omicron ~ dbetabinom_shape(
			prob = baselogis(time, loc, delta_r, lodrop, logain)
			, size = tot
			, shape = exp(lbbsize)
		) 
		, start = start, data = dat, method = method
		, fixed = fixed, control = cList
	))
}


provlist <- dat %>% pull(prov) %>% unique
fitlist <- list()
for (cp in provlist){
	print(c("Starting", cp))
	fitlist[[cp]] <- doublefit(
		dat = dat  %>% filter(prov == cp)
		, fun = ssbetafit
		, fixed=fixList
		, verbose=TRUE
	)
	print(coef(fitlist[[cp]]))
}

saveVars(baselogis, fitlist)


