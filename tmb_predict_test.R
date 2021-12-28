library(TMB) ## still need it to operate on TMB objects
library(testthat)
library(tidyr)
library(dplyr)

set.seed(101)

library(shellpipes)
rpcall("bsfake.sg.tmb_predict_test.Rout tmb_ensemble.R bsfake.sg.lsfit.tmb_fit.rds tmb_funs.rda logistic.so")
fit <- rdsRead()
loadEnvironments()
soLoad()

## want all combinations of
## * expand (yes/no)
## * perfect tests (yes/no)
## * CIs (yes/no) [also implies prediction done on R-side vs TMB-side
## * newparams (yes/no)
## * reinf?

print(cc <- coef(fit, random = TRUE))
print(b_logdeltar_vals <- setNames(cc[names(cc) == "b_logdeltar"],
                              get_prov_names(fit)))

## old params, imperfect tests
p1A <- predict(fit, confint = FALSE)
p1B <- predict(fit, confint = TRUE)
expect_equal(length(p1A), nrow(p1B))
expect_equal(unname(p1A), unname(p1B$pred))

## old params, perfect tests
p2A <- predict(fit, perfect_tests = TRUE, confint = FALSE)
p2B <- predict(fit, perfect_tests = TRUE, confint = TRUE)
expect_equal(length(p2A), nrow(p2B))
expect_equal(unname(p2A), unname(p2B$pred))

np <- cc*runif(length(cc), min = 0.5, max = 1.5)
## new params, imperfect tests
p3A <- predict(fit, confint = FALSE,
               newparams = np)
p3B <- predict(fit, confint = TRUE,
               newparams = np)
expect_equal(length(p3A), nrow(p3B))
expect_equal(unname(p3A), unname(p3B$pred))

## new params, perfect tests
p4A <- predict(fit, perfect_tests = TRUE, confint = FALSE,
               newparams = np)
p4B <- predict(fit, perfect_tests = TRUE, confint = TRUE,
               newparams = np)
expect_equal(length(p4A), nrow(p4B))
expect_equal(unname(p4A), unname(p4B$pred))
