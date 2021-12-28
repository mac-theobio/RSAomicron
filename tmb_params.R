library(TMB) ## still need it to operate on TMB objects
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

## reconstruct deltar for each province
## FIXME: tidy this (rowwise?)
deltar_mat <- t(apply(as.data.frame(pop_vals),
                      MARGIN = 1,
                      function(x) {
                          exp(exp(x[["logsd_logdeltar"]])*x[names(x) == "b_logdeltar"] + x[["log_deltar"]])
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

shape_regex <- "^log_(theta|sigma)$"
if (sum(grepl(shape_regex,
              colnames(pop_vals))) != 1) {
    stop(sprintf("columns '%s' missing or non-unique",
                 shape_regex))
}
beta_shape <- (pop_vals
    |> as.data.frame()
    |> select(ll = matches(shape_regex))
    ## select & rename
    |> transmute(beta_shape = exp(ll))
    |> mutate(sample_no = 1:n())
)

all_vals <- (deltar_vals
	|> full_join(loc_vals, by = c("prov", "sample_no"))
	|> full_join(beta_shape, by = "sample_no")
)

summary(all_vals)

rdsSave(all_vals)
