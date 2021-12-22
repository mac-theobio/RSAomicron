library(shellpipes)

## Logistic function with imperfect testing
baselogis <- function(tvec, loc, delta_r, lodrop, logain){
	drop <- plogis(lodrop)
	gain <- plogis(logain)

	ptrue <- plogis((tvec-loc)*delta_r)
	return(ptrue*(1-gain) + (1-ptrue)*drop)
}

doublefit <- function(
	dat, fun, fixed
	, first="Nelder-Mead", second="BFGS", verbose=FALSE
	, wald=FALSE, profile=FALSE
	, ...
){
	m <- fun(dat=dat, method=first, fixed=fixed, ...)
	if(verbose){
		print("Base fit")
		print(coef(m))
	}
	if(is.null(m)) return(m)
	m <- update(m, start = as.list(coef(m)), method = second)
	wi <- NULL
	if(wald){
		wt <- try(confint(m, type="quad"))
		if (inherits(wt, "matrix")) wi <- wt
		wi <- wt
	}
	pi <- NULL
	if(profile){
		pt <- try(confint(m))
		if (inherits(pt, "matrix")) pi <- pt
	}
	return(list(m=m, wi=wi, pi=pi))
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

saveEnvironment()
