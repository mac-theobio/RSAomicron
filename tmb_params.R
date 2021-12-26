
library(TMB) ## still need it to operate on TMB objects
library(tidyr)
library(dplyr)
library(MASS)

library(shellpipes)

nsim <- 500

fit <- rdsRead()
loadEnvironments()
soLoad()

set.seed(101)
## need covariance matrix/random values for both fixed & random effects
pop_vals <- MASS::mvrnorm(nsim
	, mu = coef(fit, random = TRUE)
	, Sigma = vcov(fit, random =TRUE)
)

## reconstruct deltar for each province
deltar_mat <- t(apply(as.data.frame(pop_vals),
	1,
	function(x) {
		exp(x[names(x) == "b"] + x[["log_deltar"]])
	}
))
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

(deltar_vals
	|> full_join(loc_vals, by = c("prov", "sample_no"))
	|> full_join(beta_shape, by = "sample_no")
) |> rdsSave()
	
