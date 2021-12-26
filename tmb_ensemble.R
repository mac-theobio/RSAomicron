library(shellpipes)
if (interactive()) {
    rpcall("btfake.sg.tmb_ensemble.Rout tmb_ensemble.R btfake.sg.ltfit.tmb_fit.rds tmb_funs.rda logistic.so")
}

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

head(pop_vals)

## reconstruct deltar for each province
deltar_mat <- t(apply(as.data.frame(pop_vals),
                    1,
                    function(x) {
                        exp(x[names(x) == "b"] + x[["log_deltar"]])
                    }))
colnames(deltar_mat) <- get_prov_names(fit)

deltar_vals <- (deltar_mat
    |> as.data.frame()
    |> mutate(sample_no = 1:n())
    |> pivot_longer(-sample_no,
                    names_to = "prov",
                    values_to = "deltar")
)

loc_vals <- (pop_vals
    |> as.data.frame()
    |> select(starts_with("loc"))
    |> rename_with(stringr::str_remove, pattern = "loc\\.")
    |> mutate(sample_no = 1:n())
    |> pivot_longer(-sample_no,
                    names_to = "prov",
                    values_to = "loc")
)

beta_shape <- (pop_vals
    |> as.data.frame()
    |> select(log_theta)
    ## FIXME: should allow for theta or sigma parameterization
    |> transmute(beta_shape = exp(log_theta))
    |> mutate(sample_no = 1:n())
)

all_vals <- (deltar_vals
    |> full_join(loc_vals, by = c("prov", "sample_no"))
    |> full_join(beta_shape, by = "sample_no")
)

rdsSave(all_vals)
    
## perfect_tests is problematic, but we only want the
## complete data
## this is inefficient, could maybe use mk_completedata directly?

startGraphics()
## FIXME: split into two files?
nrow(pp1 <- predict(fit))

## check that it completes
length(predict(fit, newparams = pop_vals[1,],
               perfect_tests = TRUE, confint = FALSE))

nrow(pp1 <- predict(fit, newparams = pop_vals[1,],
                    perfect_tests = TRUE, confint = TRUE))


base <- (mk_completedata(fit)[c("prov", "time", "reinf")]
    |> tibble::as_tibble()
)
ensemble0 <- list()
pb <- txtProgressBar(style = 3, max = nsim)
for (i in 1:nsim) {
    setTxtProgressBar(pb, i)
    ensemble0[[i]] <- predict(fit, newparams = pop_vals[i,], perfect_tests = TRUE, confint = FALSE)
}
close(pb)

ensemble <- (bind_cols(base, ensemble0)
    |> pivot_longer(-c(prov, time))
    |> group_by(prov, time)
    |> summarise(pred = quantile(value, 0.5),
                 pred_lwr = quantile(value, 0.025),
                 pred_upr = quantile(value, 0.975),
                 .groups = "drop")
)

gg0 <- (ggplot(ensemble, aes(time, pred, ymin = pred_lwr, ymax = pred_upr))
    + geom_line()
    + geom_ribbon(alpha = 0.2, colour = NA)
    + facet_wrap(~prov)
)

print(gg0)

## compare ensemble and Wald.  Not sure why ensemble is so much larger: think it may have to do with whether REs are held fixed during CI calculation in sdreport?

print(gg0
       + geom_line(data = pp1, colour = "blue", lty = 2)
       + geom_ribbon(data = pp1, fill = "blue", alpha = 0.2, colour = NA)
       )
      
    





