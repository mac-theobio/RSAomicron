library(shellpipes)
rpcall("tmb_fit.Rout tmb_fit.R btfake.sgts.rds sr.cpp logistic_fit.h tmb_funs.rda")
library(TMB)
library(dplyr)
library(ggplot2); theme_set(theme_bw())

startGraphics()
loadEnvironments()
## currently using 'sgts' fake data; tmb_fit() wants a `tot` column
s0 <- (rdsRead()
    |> mutate(tot = omicron + delta)
)

## data exploration: no real fitting, just quasibinomial GAMs by province
gg0 <- (ggplot(s0, aes(time, omicron/tot))
    + geom_point(aes(size = tot), alpha=0.5)
    + facet_wrap(~prov)
    ## could use quasibinomial but CIs from binomial are already very wide ...
    + geom_smooth(method = "gam", method.args = list(family = binomial),
                  aes(weight = tot),
                  formula = y ~ s(x, bs = "cs")) ## avoid message
    + theme(panel.spacing = grid::unit(0, "lines"))
)
print(gg0)

## fit (using all defaults)
tt <- tmb_fit(data = s0,
              two_stage = TRUE,
              fixed_loc = TRUE,
              start = list(log_deltar = log(0.1),
                           lodrop = -4, logain = -7),
              upper = list(log_theta = 20),
              lower = NULL,
              priors = list(logsd_logdeltar =
                                prior_params(log(0.01), log(0.3))),
              map = list(),  ## no fixed params
              debug_level = 0,
              tmb_file = "sr")

## experimentation
if (FALSE) {
    t1 <- tmb_fit(s0, lower = NULL, debug_level = 4)
}

rdsSave(tt)
dev.off()
