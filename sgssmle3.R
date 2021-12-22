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

bbfit <- function(dat, curr){
	print(c("Starting", curr))
	provdat <- (dat
		%>% filter(prov==curr)
		%>% select(time, omicron, tot)
	)
	## Initial guesses (do we need to do this by province)
	sbin <- list(loc = mean(provdat$time), delta_r = 1, lodrop=-3, logain=-6)
	sbbin <- c(sbin, lbbsize=0)

	## Preliminary N-M fit
	m0 <- mle2(
		omicron ~ dbetabinom_shape(
			prob = baselogis(time, loc, delta_r, lodrop, logain)
			, size = tot
			, shape = exp(lbbsize)
		) 
		, start = sbbin, data = provdat, method = "Nelder-Mead"
		, fixed = fixList, control = cList
	)

	print("Base fit")
	print(coef(m0))
	if (coef(m0)[["lbbsize"]] > log(bbsizemax)) return(NULL)

	## BFGS is better for profiling (fit should be very similar)
	m <- update(m0, start = as.list(coef(m0)), method = "BFGS")

	print("Final updated fit with CIs)")
	print(coef(m))
	ci <- try(confint(m))
	if (!inherits(ci, "matrix")) return(NULL)
	print(ci)
   if(anyNA(ci["delta_r", ])) return(NULL)
	return(list(m=m, ci=ci))
}

provlist <- dat %>% pull(prov) %>% unique
fitlist <- list()
for (cp in provlist){
	fitlist[[cp]] <- bbfit(dat, cp)
}

saveVars(baselogis, fitlist)

