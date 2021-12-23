library(shellpipes)
## rpcall("btfake.sg.tmb_ensemble.Rout tmb_ensemble.R btfake.sg.tmb_fit.rds tmb_funs.rda logistic.so")

library(TMB) ## still need it to operate on TMB objects
library(ggplot2); theme_set(theme_bw() + theme(panel.spacing = grid::unit(0, "lines")))

fit <- rdsRead()
loadEnvironments()
soLoad()

pop_vals <- MASS::mvrnorm(1000,
                          mu = coef(fit),
                          Sigma = vcov(fit))

s0 <- fit$simulate()

pp <- coef(fit, random = TRUE)
