library(shellpipes)
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
## pars for random-loc model
## nRE <- 2 ## number of REs per province {deltar and loc}
## tmb_pars_binom <- c(tmb_pars_binom,
##                     list(loc = 20,
##                          b = rep(0, nRE * np),
##                          log_sd = rep(1, nRE),
##                          corr = rep(0, nRE*(nRE-1)/2)))

rdsSave(tt)
