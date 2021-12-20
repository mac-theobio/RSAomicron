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

if (FALSE) {
  library(tmbstan)
  tt <- tmbstan(tmb_betabinom)

  tmb_pars_bigsd <- tmb_pars
  tmb_pars_bigsd$log_sd[1] <- 10

  tmb1 <- MakeADFun(tmb_data,
                    tmb_pars_bigsd,
                    random = c("b"),
                    map = list(logain = factor(NA), log_sd = factor(c(NA, 1))),
                    silent = TRUE)
  tmb1$fn()

  system.time(
      tmb1_opt <- with(tmb1, optim(par = par, fn = fn, gr = gr, method = "BFGS",
                                   control = list(trace = 10))
                       )
  )
}
