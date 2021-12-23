library(shellpipes)
library(TMB) ## still need it to operate on TMB objects
library(ggplot2); theme_set(theme_bw() + theme(panel.spacing = grid::unit(0, "lines")))

fit <- rdsRead()
loadEnvironments()
soLoad()

pop_vals <- MASS::mvrnorm(1000,
                          mu = coef(fit),
                          Sigma = vcov(fit))

fit$simulate()

