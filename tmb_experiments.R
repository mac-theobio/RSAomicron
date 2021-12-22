library(dplyr)
library(TMB)
library(broom.mixed)

library(furrr)
plan(multicore, workers = 3)
load("tmb_funs.rda")

tt0 <- readRDS("tmb_ci.rds")
ff0 <- readRDS("tmb_fit.rds")
dyn.load(dynlib("logistic"))

t1 <- system.time(tt1 <- tidy(ff0, conf.int = TRUE, conf.method = "profile"))
##    user  system elapsed 
## 481.854   0.988 173.597 

t2 <- system.time(tt2 <- tidy(ff0, conf.int = TRUE, conf.method = "uniroot"))
##    user  system elapsed 
## 332.118   1.960 196.060 

btdat <- readRDS("btfake.sgts.props.rds")
bsdat <- readRDS("bsfake.sgts.props.rds")
btdat_btfit <- tmb_fit(btdat)
btdat_bsfit <- tmb_fit(btdat, betabinom_param = "log_sigma")

bsdat_btfit <- tmb_fit(bsdat)
bsdat_bsfit <- tmb_fit(bsdat, betabinom_param = "log_sigma")

bbmle::AICtab(btdat_btfit, btdat_bsfit)
bbmle::AICtab(bsdat_btfit, bsdat_bsfit)
## why is theta fit better either way??

## compare predictions?

tt <- purrr::map_dfr(list(theta=f1, sigma=f2),
               tidy,
               conf.int = TRUE,
               .id = "param")



