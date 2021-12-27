library(TMB)
library(dplyr)

library(shellpipes)
rpcall("btfake.sg.ltfit.tmb_fit.Rout tmb_fit.R btfake.sg.ltfit.ts.rds btfake.sg.ltfit.ts.rda logistic.so tmb_funs.rda")

loadEnvironments()
soLoad()

## fit (using all defaults)
tt <- tmb_fit(data = rdsRead(),
	two_stage = TRUE,
	upper = list(log_theta = 20),
	lower = NULL,
	map = list(),  ## no fixed params
	betabinom_param = betabinom_param,
	debug_level = 0
)

rdsSave(tt)
