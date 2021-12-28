library(TMB) ## still need it to operate on TMB objects
library(ggplot2); theme_set(theme_bw() + theme(panel.spacing = grid::unit(0, "lines")))
library(tidyr)
library(dplyr)

library(shellpipes)
rpcall("btfake.sg.tmb_ensemble.Rout tmb_ensemble.R btfake.sg.ltfit.tmb_fit.rds tmb_funs.rda logistic.so")

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
colnames(pop_vals)

startGraphics()

pp1 <- predict(fit, perfect_tests = TRUE, confint = TRUE)

base <- (mk_completedata(fit)[c("prov", "time", "reinf")]
    |> tibble::as_tibble()
)
ensemble0 <- list()
pb <- txtProgressBar(style = 3, max = nsim)
for (i in 1:nsim) {
    if (interactive()) setTxtProgressBar(pb, i)
    ensemble0[[i]] <- predict(fit, newparams = pop_vals[i,], perfect_tests = TRUE, confint = FALSE)
}
close(pb)

ensemble <- (ensemble0
    |> setNames(paste0("s",1:nsim))
    |> bind_cols(base)
    |> pivot_longer(-c(prov, time))
    |> group_by(prov, time)
    |> summarise(pred = quantile(value, 0.5),
                 pred_lwr = quantile(value, 0.025),
                 pred_upr = quantile(value, 0.975),
                 .groups = "drop")
)

gg0 <- (ggplot(ensemble, aes(time, pred, ymin = pred_lwr, ymax = pred_upr))
    + geom_line()
    + geom_ribbon(alpha = 0.4, colour = NA, fill = "orange")
    + facet_wrap(~prov)
    + geom_line(data = pp1, colour = "blue", lty = 2)
    + geom_ribbon(data = pp1, alpha = 0.2, colour = NA, fill = "blue")
)

## orange fill (light)/solid black line is ensemble median and quantiles
## blue fill (dark)/dashed blue line is MLE prediction and Wald CIs
print(gg0)

## where did EC Wald CIs go?
## ensemble |> filter(prov == "EC")
## pp1 |> filter(prov == "EC") |> arrange(time)
