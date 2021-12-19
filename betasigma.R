library(shellpipes)

dbetabinom_shape <- function(x, prob, size, shape, log=FALSE){
	return(emdbook::dbetabinom(x, prob, size, log=log
		, theta=shape/(prob*(1-prob)))
	)
}

wraprbetabinom_shape <- function(n, prob, size, shape){
	if (prob==0) return(0);
	if ((prob==1) | (size==0)) return(size);
	return(emdbook::rbetabinom(n, prob, size
		, theta=shape/(prob*(1-prob)))
	)
}

rbetabinom_shape <- function(n, prob, size, shape){
	return(emdbook::rbetabinom(n, prob, size
		, theta=shape/(prob*(1-prob)))
	)
}

sbetabinom_shape <- function(size, prob, shape){
	return(bbmle::sbetabinom(size, prob, theta=shape/(prob*(1-prob))))
}

saveEnvironment()
