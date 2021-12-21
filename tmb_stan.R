library(shellpipes)
rpcall("tmb_ci.Rout tmb_ci.R tmb_fit.rds")
library(TMB)
library(tmbstan)
library(rstan)

fit <- rdsRead()
loadEnvironments()
dyn.load(dynlib(get_tmb_file(fit)))
op <- options(mc.cores = min(4, parallel::detectCores() - 1))
tt <- tmbstan(fit, chains = 4, iter = 1000, seed = 101)
summary(tt)

if (FALSE) {
    library(shinystan)
    launch_shinystan(tt)
}

options(op)
rdsSave(tt)
