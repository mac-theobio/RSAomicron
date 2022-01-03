library(TMB) ## still need it to operate on TMB objects
library(tidyr)
library(dplyr)

library(shellpipes)

nsim <- 500
set.seed(101)

fit <- rdsRead()
loadEnvironments()
soLoad()

pop_vals <- MASS::mvrnorm(nsim
	, mu = coef(fit, random = TRUE)
	, Sigma = vcov(fit, random =TRUE)
)

dim(pop_vals)
colnames(pop_vals)

rdsSave(pop_vals)
