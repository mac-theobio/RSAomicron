library(shellpipes)
rpcall("tmb_fit.Rout tmb_fit.R btfake.sgts.rds sr.cpp logistic_fit.h tmb_funs.rda")
library(TMB)
library(dplyr)
library(ggplot2); theme_set(theme_bw())

loadEnvironments()
s0 <- (rdsRead()
    |> mutate(tot = omicron + delta)
)
## make fake sim data use my previous format
## TODO: standardize on something appropriate

gg0 <- (ggplot(s0, aes(time, omicron/tot))
    + geom_point(aes(size = tot), alpha=0.5)
    + facet_wrap(~prov)
    + geom_smooth(method = "gam", method.args = list(family = binomial),
                  aes(weight = tot),
                  formula = y ~ s(x, bs = "cs")) ## avoid message
    + theme(panel.spacing = grid::unit(0, "lines"))
)
print(gg0)

tt <- tmb_fit(s0)

if (FALSE) {
    tmb_fit(s0, lower = NULL, debug_level = 4)
}
rdsSave(tt)
