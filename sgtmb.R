library(shellpipes)
library(TMB)
library(dplyr)

loadEnvironments()
soLoad()

## fit (using all defaults)
tt <- tmb_fit(data = rdsRead(),
              two_stage = TRUE,
              fixed_loc = TRUE,
              start = list(log_deltar = log(0.1),
                           lodrop = -4, logain = -7),
              upper = list(log_theta = 20),
              lower = NULL,
              priors = list(logsd_logdeltar =
                prior_params(lwr=log(0.01), upr=log(0.3))),
              map = list(),  ## no fixed params
              debug_level = 0
)

rdsSave(tt)
