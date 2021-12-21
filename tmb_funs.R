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
fix_prov_names <- function(x, names = get_names(ss$prov)) {
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
                            x = coef(x))
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

print.TMB <- function(x) {
    cat("TMB model\n\nParameters:\n",x$par,"\n")
    return(invisible(x))
}

## https://stackoverflow.com/questions/9965577/r-copy-move-one-environment-to-another
cloneEnv <- function(envir, deep = TRUE) {
  if(deep) {
    clone <- list2env(rapply(as.list(envir, all.names = TRUE), cloneEnv, classes = "environment", how = "replace"), parent = parent.env(envir))
  } else {
    clone <- list2env(as.list(envir, all.names = TRUE), parent = parent.env(envir))
  }
  attributes(clone) <- attributes(envir)
  return(clone)
}
copyEnv <- function(e1, debug = FALSE) {
    e2 <- new.env()
    objs <- setdiff(ls(e1, all.names=TRUE), "...")
    for (n in objs) {
        if (debug) cat(n, "\n")
        assign(n, get(n, e1), e2)
    }
    return(e2)
}

## compute mean and SD of Gaussian prior from lower/upper bounds of
## confidence interval
prior_params <- function(lwr, upr, conf = 0.95) {
    m <- (lwr + upr)/2
    s <- (upr-m)/qnorm((1+conf)/2)
    c(mean = m, sd = s)
}

#' @param data data frame containing (at least) columns "prov", "time",
#' "omicron", "tot", "prop", and "reinf" (may be NA if reinf param is mapped to 0)
#' @param two_stage (logical) fit binomial model first?
#' @param start named list of starting values
#' @param upper named list of upper bounds
#' @param lower named list of lower bounds
#' @param priors named list of vectors of mean and sd for independent Gaussian priors on parameters
#' @param map list of parameters to be fixed to starting values (in the form of a factor with NA values for any elements in the vector to be fixed: see \code{map} argument of \code\link{MakeADFun}})
#' @param debug_level numeric specifying level of debugging
tmb_fit <- function(data,
                    two_stage = TRUE,
                    fixed_loc = TRUE,
                    start = list(log_deltar = log(0.1),
                                 lodrop = -4, logain = -7),
                    upper = list(log_theta = 20),
                    lower = list(logsd_logdeltar = -5),
                    priors = list(logsd_logdeltar =
                                      prior_params(log(0.01), log(0.3))),
                    map = list(),
                    debug_level = 0,
                    tmb_file = "sr")
{
    ## FIXME: figure out how to do this externally ...
    TMB::compile(paste0(tmb_file, ".cpp"))
    dyn.load(dynlib(tmb_file))

    ## general (applies to both random- and fixed-loc models)
    ## FIXME:
    tmb_pars_binom <- c(start, list(log_theta = NA_real_))
    ## make sure 'prov' is a factor (TMB doesn't auto-convert)
    data$prov <- factor(data$prov)
    np <- length(levels(data$prov))
    tmb_data <- c(data, list(nprov = np, debug = debug_level))
    if (!is.null(priors)) {
        for (nm in names(priors)) {
            tmb_data[[paste0("prior_",nm)]] <- priors[[nm]]
        }
    }
    loc_start <- mean(data$time)
    if (!fixed_loc) stop("random loc is not currently implemented")
    nRE <- 1
    tmb_pars_binom <- c(tmb_pars_binom,
                        list(loc = rep(loc_start, np),
                             b = rep(0, nRE * np),
                             logsd_logdeltar = rep(-1, nRE)))
    binom_args <- list(data = tmb_data,
                       parameters = tmb_pars_binom,
                       random = c("b"),
                       ## inner.method = "BFGS",
                       inner.control = list(maxit = 1000,
                                            fail.action = rep("warning", 3)),
                       map = c(map, list(log_theta = factor(NA))),
                       silent = TRUE)

    if (two_stage) {
        tmb_binom <- do.call(MakeADFun, binom_args)
        r0 <- tmb_binom$fn()
        stopifnot(is.finite(r0))
        ## Fit!
        ## Important to use something derivative-based (optim()'s default is
        ##  Nelder-Mead, which wastes the effort spent in doing autodiff ...
        ## TMB folks seem to like nlminb() but not clear why
        t1 <- system.time(
            tmb_binom_opt <- with(tmb_binom, optim(par = par, fn = fn, gr = gr, method = "BFGS",
                                                   control = list(trace = 10)))
        )
        ## 0.6 seconds
        class(tmb_binom) <- "TMB"
        ## FIXME: check for inner-optimization failure here, return with meaningful error
    }
    ## update binomial args for beta-binomial case
    betabinom_args <- binom_args
    ## don't 'map' log_theta (dispersion) any more; set starting value to 0
    betabinom_args$map$log_theta <- NULL
    if (two_stage) betabinom_args$parameters <- splitfun(binom_args$parameters, tmb_binom_opt$par)
    betabinom_args$parameters$log_theta <- 0
    tmb_betabinom <- do.call(MakeADFun, betabinom_args)
    uvec <- Inf ## default: optim will replicate as necessary
    if (!is.null(upper)) {
        uvec <- tmb_betabinom$par
        uvec[] <- Inf ## set all upper bounds to Inf (default/no bound)
        for (nm in names(upper)) {
            uvec[[nm]] <- upper[[nm]]
        }
    }
    lvec <- -Inf
    if (!is.null(lower)) {
        lvec <- tmb_betabinom$par
        lvec[] <- -Inf
        for (nm in names(lower)) {
            lvec[[nm]] <- lower[[nm]]
        }
    }
        
    tmb_betabinom_opt <- with(tmb_betabinom,
                              optim(par = par, fn = fn, gr = gr, method = "L-BFGS-B",
                                    control = list(), ## trace = 1),
                                    upper = uvec,
                                    lower = lvec)
                              )
    return(mkTMB(tmb_betabinom, tmb_file, get_names(data$prov)))
}

## extract original data frame from TMB object
get_data <- function(x) {
    dd <- x$env$data
    L <- lengths(dd)
    dd <- (dd[L == max(L)]
        %>% as.data.frame()  ## not tibble (collapsing list)
        %>% mutate(across(prov, factor, labels = get_prov_names(fit)))
        %>% as_tibble()
    )
    return(dd)
}


## add class and file attribute
mkTMB <- function(x, tmb_file, prov_names) {
    attr(x, "tmb_file") <- tmb_file
    attr(x, "prov_names") <- prov_names
    x$env$last.par.best <- fix_prov_names(x$env$last.par.best,
                                              prov_names)
    class(x) <- "TMB"
    return(x)
}

get_tmb_file <- function(x) {
    attr(x, "tmb_file")
}

get_prov_names <- function(x) {
    attr(x, "prov_names")
}

## this is specific to SR fits, not generic TMB machinery
## deep-copy TMB object, then modify data within it appropriately,
## call TMB::sdreport() on the modified object
## by default, expands time x province list and generates
## predicted values (and Wald CIs on the log scale)
predict.srfit <- function(fit, newdata = NULL) {
    e2 <- copyEnv(environment(fit$fn))
    pred_bb <- fit
    environment(pred_bb$fn) <- environment(pred_bb$gr) <-
        environment(pred_bb$report) <- pred_bb$env <- e2
    if (is.null(newdata)) {
        newdata <- with(get_data(fit),
                         expand.grid(prov = unique(prov),
                                     time = unique(time)))
    }
    n <- nrow(newdata)
    dd <- fit$env$data ## all data
    for (nm in names(dd)) {
        if (nm %in% names(newdata)) {
            dd[[nm]] <- newdata[[nm]]
        } else {
            L <- length(dd[[nm]])
            if (L > 1 && L < nrow(newdata)) {
                dd[[nm]] <- rep(NA_real_, nrow(newdata))
            }
        }
    }
    ## set to re-sanitize
    attr(dd, "check.passed") <- FALSE
    e2$data <- dd
    rr <- sdreport_split(pred_bb)
    ss2 <- (newdata
        %>% as_tibble()
        %>% mutate(
                prov = factor(prov,
                              labels = get_prov_names(fit)),
            pred = plogis(rr$value$loprob),
            pred_lwr = plogis(rr$value$loprob - 1.96*rr$sd$loprob),
            pred_upr = plogis(rr$value$loprob + 1.96*rr$sd$loprob))
    )
    return(ss2)
}

## compute sdreport and split by name
sdreport_split <- function(fit) {
    rr <- sdreport(fit)
    nm <- names(rr$value)
    rr$value <- split(rr$value, nm)
    rr$sd <- split(rr$sd, nm)
    return(rr)
}

saveEnvironment()

