library(shellpipes)
rpcall("tmb_ci.Rout tmb_ci.R tmb_fit.rds")
library(TMB)
library(tmbstan)

fit <- rdsRead()
loadEnvironments()
dyn.load(dynlib(get_tmb_file(fit)))
tt <- tmbstan(fit, chains = 2, iter = 500)

rdsSave(tt)
