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

## FIXME: allow to work harder if non-pos-def?
## from ?jacobian: ‘method.args=list(eps=1e-4, d=0.0001,
##   zero.tol=sqrt(.Machine$double.eps/7e-7), r=4, v=2,
##      show.details=FALSE)’ is set as the default.

## from ?grad:
## ‘d’ gives the
##      fraction of ‘x’ to use for the initial numerical approximation.
##      The default means the initial approximation uses ‘0.0001 * x’.
##      ‘eps’ is used instead of ‘d’ for elements of ‘x’ which are zero
##      (absolute value less than zero.tol).  ‘zero.tol’ tolerance used
##      for deciding which elements of ‘x’ are zero.  ‘r’ gives the number
##      of Richardson improvement iterations (repetitions with successly
##      smaller ‘d’. The default ‘4’ general provides good results, but
##      this can be increased to ‘6’ for improved accuracy at the cost of
##      more evaluations.  ‘v’ gives the reduction factor.  ‘show.details’
##      is a logical indicating if detailed calculations should be shown.
default.method.args <- list(eps=1e-4, d=0.0001,
                            zero.tol=sqrt(.Machine$double.eps/7e-7), r=4, v=2,
                            show.details=FALSE)
vcov.TMB <- function(x, method.args = NULL) {
    m.args <- default.method.args
    if (length(method.args) > 0) {
        for (n in names(method.args)) {
            m.args[[n]] <- method.args[[n]]
        }
    }
    if (!require("numDeriv")) stop('need numDeriv package for TMB vcov')
    H <- numDeriv::jacobian(func = x$gr,
                            x = coef(x),
                            method.args = m.args)
    ## fixme: robustify?
    V <- solve(H)
    nn <- names(coef(x))
    dimnames(V) <- list(nn,nn)
    return(V)
}
logLik.TMB <- function(x) {
    ## FIXME: include df? (length(coef(x)))?
    ## is x$fn() safe (uses last.par) or do we need last.par.best ?
    return(-1*x$fn())
}

saveEnvironment()

