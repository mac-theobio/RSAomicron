library(TMB) ## still need it to operate on TMB objects
library(tidyr)
library(dplyr)


library(shellpipes)
rpcall("btfake.sg.tmb_ensemble.Rout tmb_ensemble.R btfake.sg.ltfit.tmb_fit.rds tmb_funs.rda logistic.so")

nsim <- 500
nsim <- 2
mike_hack <- TRUE

fit <- rdsRead()
loadEnvironments()
soLoad()

set.seed(101)
## need covariance matrix/random values for both fixed & random effects
pop_vals <- as.data.frame(MASS::mvrnorm(nsim
	, mu = coef(fit, random = TRUE)
	, Sigma = vcov(fit, random =TRUE)
))

print(pop_vals)
print(dim(pop_vals))


if(mike_hack){
## What we want to do is to recreate pop_vals in the same structure but fixed some parameters and do a multivariate normal using a reduced covariance matrix
## There are two options: keep the current structure (with all PT) vs doing the PT individually


## option 1
	fixed_pars <- c("lodrop","logain","log_theta")

	cc <- coef(fit,random=TRUE)

	fixed_pars_position <- which(names(cc) %in% fixed_pars)

	new_cc <- cc[-fixed_pars_position]

#	print(new_cc)

	new_vcov <- vcov(fit, random = TRUE)[-fixed_pars_position,-fixed_pars_position]

#	print(new_vcov)

	new_pop_vals <- as.data.frame(MASS::mvrnorm(nsim
			, mu = new_cc
			, Sigma = new_vcov
			)
	)

	print(cc[fixed_pars_position])

	fixed_pars_df <- t(as.data.frame(cc[fixed_pars_position]))[rep(1,nsim),]
		
	rownames(fixed_pars_df) <- NULL
	colnames(fixed_pars_df) <- names(cc[fixed_pars_position])
	new_pop_vals <- (bind_cols(new_pop_vals,fixed_pars_df)
	)
	
	## Need to work on the names
	print(new_pop_vals)

	print(dim(new_pop_vals))
}



quit()


## reconstruct deltar for each province
## FIXME: tidy this (rowwise?)
deltar_mat <- t(apply(pop_vals, MARGIN = 1
	, function(x) {
		return(exp(
			exp(x[["logsd_logdeltar"]])*x[names(x) == "b_logdeltar"] 
			+ x[["log_deltar"]]
		))
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

if("beta_reinf" %in% names(pop_vals)){
	reinf_mat <- t(apply(pop_vals, MARGIN = 1
		, function(x) {
			return(
				exp(x[["logsd_reinf"]])*x[names(x) == "b_reinf"] 
				+ x[["beta_reinf"]]
			)
		}
	))
	colnames(reinf_mat) <- get_prov_names(fit)

	reinf_vals <- (reinf_mat
		|> as.data.frame()
		|> mutate(sample_no = 1:n())
		|> pivot_longer(-sample_no
			, names_to = "prov"
			, values_to = "reinf"
		)
	)
	all_vals <- (all_vals
		|> full_join(reinf_vals, by = c("prov", "sample_no"))
		|> mutate(reloc = loc - reinf/deltar)
	)
}

summary(all_vals)

rdsSave(all_vals)
