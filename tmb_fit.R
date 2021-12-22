library(shellpipes)
rpcall("tmb_fit.Rout tmb_fit.R btfake.sgts.rds logistic.so tmb_funs.rda")
library(TMB)
library(dplyr)

loadEnvironments()
soLoad()

## currently using 'sgts' fake data; tmb_fit() wants a `tot` column
s0 <- (rdsRead()
    |> mutate(tot = omicron + delta)
)

## fit (using all defaults)
tt <- tmb_fit(data = s0,
              two_stage = TRUE,
              start = list(log_deltar = log(0.1),
                           lodrop = -4, logain = -7,
                           beta_reinf = 0),
              upper = list(log_theta = 20),
              lower = NULL,
              priors = list(logsd_logdeltar =
                                prior_params(lwr = log(0.01), upr = log(0.3))),
              map = list(),  ## no fixed params
              debug_level = 0
              )

rdsSave(tt)
