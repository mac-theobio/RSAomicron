library(shellpipes)
## rpcall("tmb_diagnose.Rout tmb_diagnose.R tmb_fit.rda btfake.sgts.rds tmb_funs.rda")

library(broom.mixed)
library(dplyr)
library(tidyr)
library(ggplot2); theme_set(theme_bw())
library(bbmle)
library(TMB) ## still need it to operate on TMB objects

fixedloc <- TRUE
tmb_file <- if (fixedloc) "logistic_fit_fixedloc" else "logistic_fit"
## dyn lib must be reloaded!
dyn.load(dynlib(tmb_file))
startGraphics()

## includes fits, sim data (ss), file name/type info
loadEnvironments()
set_trace(tmb_betabinom)
tmb_betabinom$fn()
coef(tmb_betabinom)

## mle can't handle multiple 'loc' names; fix up (should be upstream)
ee <- environment(tmb_betabinom$fn)
ee$last.par.best <- fix_province_names(ee$last.par.best)
coef(tmb_betabinom)

parnames(tmb_betabinom$fn) <- names(coef(tmb_betabinom))

tmb_betabinom$fn(coef(tmb_betabinom))
## use bbmle to fit tmb_betabinom, for finer control of profiling
tmb_betabinom_mle2 <- mle2(minuslogl = tmb_betabinom$fn, gr = tmb_betabinom$gr,
                       start = coef(tmb_betabinom),
                       vecpar = TRUE)
coef(tmb_betabinom_mle2)
pp <- profile(tmb_betabinom_mle2, which = "log_sd")
## too flat

## profile 'by hand'
prof_betabinom_args <- betabinom_args
do_prof <- function(log_sd_val) {
    prof_betabinom_args$map <- list(log_sd = factor(NA))
    prof_betabinom_args$parameters$lodrop <- log_sd_val
    tmb_prof <- do.call(MakeADFun, prof_betabinom_args)
    class(tmb_prof) <- "TMB"
    ## FIXME: continuation method, up/down?
    ## (currently starting from base parameter values every time; if we have instability
    ## problems, this will be bad)
    prof_opt <- with(tmb_prof,
                     optim(par = par, fn = fn, gr = gr, method = "BFGS"
                         , control = list(trace = 10))
                     )
    r <- c(log_sd = log_sd_val, coef(tmb_prof), NLL = -1*logLik(tmb_prof))
    data.frame(rbind(r))
}

log_sd_vec <- seq(-10, 0, by = 0.1)
pp <- purrr::map_dfr(log_sd_vec, do_prof)
pp2 <- (fix_province_names(pp)
    |> tidyr::pivot_longer(-log_sd)
)
ggplot(pp2, aes(log_sd, value)) + geom_point() + geom_line() + facet_wrap(~name, scale = "free")


saveEnvironment()
dev.off()
