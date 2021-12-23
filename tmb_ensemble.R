library(shellpipes)
rpcall("btfake.sg.tmb_ensemble.Rout tmb_ensemble.R btfake.sg.ltfit.tmb_fit.rds tmb_funs.rda logistic.so")

library(TMB) ## still need it to operate on TMB objects
library(ggplot2); theme_set(theme_bw() + theme(panel.spacing = grid::unit(0, "lines")))
library(tidyr)
library(dplyr)

nsim <- 500

fit <- rdsRead()
loadEnvironments()
soLoad()

set.seed(101)
## need covariance matrix/random values for both fixed & random effects
pop_vals <- MASS::mvrnorm(nsim,
                          mu = coef(fit, random = TRUE),
                          Sigma = vcov(fit, random =TRUE))
dim(pop_vals)

ensemble <- list()
pb <- txtProgressBar(style = 3, max = nsim)
for (i in 1:nsim) {
    setTxtProgressBar(pb, i)
    ensemble[[i]] <- predict(fit, newparams = pop_vals[i,], perfect_tests = TRUE, confint = FALSE)
}
close(pb)

ensemble <- do.call(cbind, ensemble)

## now we "just" have to reshape/compute central & quantile values appropriately
## (functional box plots ????)
