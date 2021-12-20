library(shellpipes)

## split a vector by (repeated) names and assign
## values to elements of an existing list
## (i.e., update a starting parameter list with the
## results of running optim()
##' @param orig original list of parameters
##' @param pars named vector of parameters (names not necessarily unique)
splitfun <- function(orig, pars) {
	r <- list()
	for (n in unique(names(pars))) {
		orig[[n]] <- unname(pars[names(pars) == n])
	}
	return(orig)
}

## safely get levels *or* unique values of a vector that
## may or may not be a factor
get_names <- function(x) {
    if (!is.null(levels(x))) return(levels(x))
    return(unique(x))
}

## disambiguate locations
fix_province_names <- function(x, names = get_names(ss$province)) {
    if (!is.null(dim(x))) {
        colnames(x)[grepl("^loc", colnames(x))] <- paste0("loc.", names)
    } else {
        names(x)[grepl("^loc", names(x))] <- paste0("loc.",names)
    }
    return(x)
}

##' turn on tracing for a TMB object
##' @param obj a TMB object (result of \code{MakeADFun})
##' @param trace should tracing be enabled?
set_trace <- function(obj, trace = TRUE) {
  environment(obj$fn)$tracepar <- trace
  return(invisible(NULL))
}

coef.TMB <- function(x, random = FALSE) {
    ee <- environment(x$fn)
    r <- ee$last.par.best
    rand <- ee$random
    if (!random && length(rand)>0) {
        r <- r[-rand]
    }
    return(r)
}
vcov.TMB <- function(x) {
    if (!require("numDeriv")) stop('need numDeriv package for TMB vcov')
    H <- numDeriv::jacobian(func = x$gr,
                            x = fixef.TMB(x))
    ## fixme: robustify?
    V <- solve(H)
    nn <- names(fixef.TMB(x))
    dimnames(V) <- list(nn,nn)
    return(V)
}
logLik.TMB <- function(x) {
    ## FIXME: include df? (length(coef(x)))?
    ## is x$fn() safe (uses last.par) or do we need last.par.best ?
    return(-1*x$fn())
}

saveEnvironment()

