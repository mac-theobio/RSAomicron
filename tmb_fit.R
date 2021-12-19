library(shellpipes)
rpcall("tmb_fit.Rout tmb_fit.R btfake.sgts.rds logistic_fit.cpp tmb_funs.rda")
library(TMB)
library(dplyr)
library(ggplot2); theme_set(theme_bw())

##
fixedloc <- TRUE
if (!fixedloc) stop("random-effects loc no longer implemented; rescue from mvRt")
tmb_file <- "logistic_fit_fixedloc"

TMB::compile(paste0(tmb_file, ".cpp"))
dyn.load(dynlib(tmb_file))

loadEnvironments()
s0 <- rdsRead()
## make fake sim data use my previous format
## TODO: standardize on something appropriate
ss <- (s0
  %>% mutate(province = factor(prov))
  %>% group_by(province)
    %>% transmute(province,
                  t = time - min(time),
                  dropouts = omicron,
                  total_positives = omicron + delta)
  %>% ungroup()
)


gg0 <- (ggplot(ss, aes(t, dropouts/total_positives))
    + geom_point(aes(size = total_positives), alpha=0.5)
    + facet_wrap(~province)
    + geom_smooth(method = "gam", method.args = list(family = binomial),
                  aes(weight = total_positives))
)
print(gg0)

np <- length(levels(ss$province))
tmb_data <- c(ss, list(nprov = np, debug = 0))
tmb_pars_binom <- list(
    deltar = 0.1,
    log_theta = NA,
    lodrop = -4,
    logain = -7)

## pars for random-loc model
## nRE <- 2 ## number of REs per province {deltar and loc}
## tmb_pars_binom <- c(tmb_pars_binom,
##                     list(loc = 20,
##                          b = rep(0, nRE * np),
##                          log_sd = rep(1, nRE),
##                          corr = rep(0, nRE*(nRE-1)/2)))

nRE <- 1
tmb_pars_binom <- c(tmb_pars_binom,
                    list(loc = rep(20, np),
                         b = rep(0, nRE * np),
                         log_sd = rep(1, nRE)))


binom_args <- list(data = tmb_data,
                   parameters = tmb_pars_binom,
                   random = c("b"),
                   ## inner.method = "BFGS",
                   inner.control = list(maxit = 1000,
                                        fail.action = rep("warning", 3)),
                   map = list(log_theta = factor(NA)),
                   silent = TRUE)
tmb_binom <- do.call(MakeADFun, binom_args)


## Check whether the objective function output looks reasonable to Ben
(r0 <- tmb_binom$fn())
stopifnot(is.finite(r0))
summary(tmb_binom$report()$prob)

## Fit!
## Important to use something derivative-based (optim()'s default is
##  Nelder-Mead, which wastes the effort spent in doing autodiff ...
## TMB folks seem to like nlminb() but not clear why

system.time(
    tmb_binom_opt <- with(tmb_binom, optim(par = par, fn = fn, gr = gr, method = "BFGS",
                                           control = list(trace = 10)))
)
## 0.6 seconds
class(tmb_binom) <- "TMB"
print(tmb_binom_opt)

## inner-optimization failure!
## sdreport(tmb_binom)

## update binomial args for beta-binomial case
betabinom_args <- binom_args
## don't 'map' log_theta (dispersion) any more; set starting value to 0
betabinom_args$map$log_theta <- NULL
betabinom_args$parameters <- splitfun(binom_args$parameters, tmb_binom_opt$par)
betabinom_args$parameters$log_theta <- 0
tmb_betabinom <- do.call(MakeADFun, betabinom_args)

set_trace(tmb_betabinom, FALSE)
tmb_betabinom$fn()
## log-sigma estimate went crazy (=63), inner optimization failed: set upper bound
## (better to set a prior instead ...)
uvec <- tmb_betabinom$par
uvec[] <- Inf ## set all upper bounds to Inf (default/no bound)
uvec[["log_theta"]] <- 20
tmb_betabinom_opt <- with(tmb_betabinom,
                          optim(par = par, fn = fn, gr = gr, method = "L-BFGS-B",
                                control = list(trace = 1),
                                upper = uvec)
                          )
class(tmb_betabinom) <- "TMB"
sdreport(tmb_betabinom)
## log_sd variance is small (NaN SD) but otherwise OK

if (FALSE) {
  library(tmbstan)
  tt <- tmbstan(tmb_betabinom)

  tmb_pars_bigsd <- tmb_pars
  tmb_pars_bigsd$log_sd[1] <- 10

  tmb1 <- MakeADFun(tmb_data,
                    tmb_pars_bigsd,
                    random = c("b"),
                    map = list(log_sd = factor(c(NA, 1))),
                    silent = TRUE)
  tmb1$fn()

  system.time(
      tmb1_opt <- with(tmb1, optim(par = par, fn = fn, gr = gr, method = "BFGS",
                                   control = list(trace = 10))
                       )
  )
}


models <- c("binom", "betabinom")
vars <- c(
    c(outer(models, c("", "_opt"),
            sprintf, fmt = "tmb_%s%s")),
    sprintf("%s_args", models))
## need to know which model we used (must be read back in via dyn.load())
## also save processed data (UGH, fixme, retrieve Make-ily from ssbinfake
vars <- c(vars, c("fixedloc", "tmb_file", "ss"))
saveVars(list = vars)
