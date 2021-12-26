library(shellpipes)
if (interactive()) {
    rpcall("bsfake.sg.tmb_predict_test.Rout tmb_ensemble.R bsfake.sg.lsfit.tmb_fit.rds tmb_funs.rda logistic.so")
}

library(TMB) ## still need it to operate on TMB objects
library(testthat)
fit <- rdsRead()
loadEnvironments()
soLoad()

## want all combinations of
## * expand (yes/no)
## * perfect tests (yes/no)
## * CIs (yes/no)
## * newparams (yes/no)
## * reinf?

p0 <- predict(fit, confint = FALSE)
p1 <- predict(fit, confint = TRUE)

expect_equal(length(p0), nrow(p1))

## these don't match: some problem with whether perfect_tests
## is getting implemented properly?

if (FALSE) {
    expect_equal(unname(p0), unname(p1[["pred"]]))

    q0 <- qlogis(p0)
    q1 <- qlogis(p1[["pred"]])
    plot(q0)
    lines(q1)
    
    plot(q0-q1)
}

p2 <- predict(fit, perfect_tests = TRUE, confint = FALSE)
p3 <- predict(fit, perfect_tests = TRUE, confint = TRUE)
expect_equal(length(p2), nrow(p3))

## also don't match yet ...
