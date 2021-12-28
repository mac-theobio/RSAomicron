library(TMB) ## still need it to operate on TMB objects
library(testthat)
library(tidyr)
library(dplyr)

library(shellpipes)
library(ggplot2); theme_set(theme_bw())
rpcall("bsfake.sg.tmb_predict_test.Rout tmb_ensemble.R bsfake.sg.lsfit.tmb_fit.rds tmb_funs.rda logistic.so")
fit <- rdsRead()
loadEnvironments()
soLoad()

## want all combinations of
## * expand (yes/no)
## * perfect tests (yes/no)
## * CIs (yes/no)
## * newparams (yes/no)
## * reinf?

print(cc <- coef(fit, random = TRUE))
print(b_logdeltar_vals <- setNames(cc[names(cc) == "b_logdeltar"],
                              get_prov_names(fit)))
## GP is lowest growth rate (by RE); biggest difference
## between pred and rawpred. Suggests 'pred' is not getting
## the right RE starting value/ineffective?

## hand computation for GP at time == 50:
raw_calc <- with(as.list(cc),
     baselogis(50, loc.GP, exp(log_deltar + b_logdeltar_vals[["GP"]]), lodrop, logain))
## [1] 0.8367799
w <- with(p1, which(prov == "GP" & time == 50)) ## 390
expect_equal(unname(p0)[w], raw_calc)
p1[w,] ## pred = 0.944 !
nore_calc <- with(as.list(cc),
     baselogis(50, loc.GP, exp(log_deltar), lodrop, logain))
## closer to pred but not identical??
## should both be *without* perfect tests
p0 <- predict(fit, confint = FALSE)
p1 <- predict(fit, confint = TRUE)

p1 <- (p1
    |> mutate(rawpred = p0)
)

p1L <- (p1
    |> select(prov, time, pred, rawpred)
    |> pivot_longer(contains("pred"), names_to = "type")
)

ggplot(p1L, aes(time, value, colour = type)) + geom_line() + facet_wrap(~prov)
## weird. REs must not be getting assigned properly in one place or the other?
## (deviation

p0[1] ## 0.02747975 
p1$pred[1] ## 0.02747992

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
