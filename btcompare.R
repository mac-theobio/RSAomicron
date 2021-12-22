library(dplyr)
library(TMB)

library(shellpipes)

loadEnvironments()
soLoad()

## Explore parameterizations
btdat <- rdsRead("btfake")
bsdat <- rdsRead("bsfake")
btdat_btfit <- tmb_fit(btdat)
btdat_bsfit <- tmb_fit(btdat, betabinom_param = "log_sigma")

bsdat_btfit <- tmb_fit(bsdat)
bsdat_bsfit <- tmb_fit(bsdat, betabinom_param = "log_sigma")

bbmle::AICtab(btdat_btfit, btdat_bsfit)
bbmle::AICtab(bsdat_btfit, bsdat_bsfit)
