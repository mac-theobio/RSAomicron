library(shellpipes)

## Logistic function with imperfect testing
baselogis <- function(tvec, loc, delta_r, lodrop, logain){
	drop <- plogis(lodrop)
	gain <- plogis(logain)

	ptrue <- plogis((tvec-loc)*delta_r)
	return(ptrue*(1-gain) + (1-ptrue)*drop)
}

betabinfit <- function(dat
	, start = list(
		loc = NULL, delta_r = 1 , lodrop=-4, logain=-7 , lbbsize=0
	)
	, betasizemax=100
	, printCoef=FALSE
	, method = "Nelder-Mead"
	, fixList = fixList
	, cList = list(maxit = 5000)
){
	if (is.null(start[["loc"]])) start[["loc"]] <- mean(dat$time)

	m <- mle2(
		omicron ~ dbetabinom_shape(
			prob = baselogis(time, loc, delta_r, lodrop, logain)
			, size = tot
			, shape = exp(lbbsize)
		) 
		, start = start, data = dat, method = method
		, fixed = fixList, control = cList
	)

	if (printCoef) print(coef(m))
	if (
		(!is.null(betasizemax)) & (coef(m)[["lbbsize"]] > log(betasizemax))
	) return(NULL)

	return(m)
}

## Use one method to hopefully get a good estimate and a second to make something more profile-able
doublefit <- function(dat, fun, first="Nelder-Mead", second="BFGS", ...){
	m <- fun(dat=dat, method=first, ...)
	if(is.null(m)) return(m)
	return(update(m, start = as.list(coef(m)), method = second))
}

## Not working bc we can't reverse-engineer the methods
tryCI <- function(m, method="spline", printCI=FALSE){
	ci <- try(confint(m, method=method))
	if (!inherits(ci, "matrix")) return(NULL)
	if (printCI) print(ci)
   if(anyNA(ci["delta_r", ])) return(NULL)
	return(ci=ci)
}

## Can we get legal CIs??
checkCI <- function(m, printCI=FALSE){
	s <- tryCI(m, printCI=printCI)
	if (!is.null(s)) return("profile")
	s <- tryCI(m, printCI, method="quad")
	if (!is.null(s)) return("Wald")
	return(NULL)
}

saveEnvironment()
