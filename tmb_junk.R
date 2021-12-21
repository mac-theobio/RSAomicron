## junk saved from elsewhere

## pars for random-loc model (when that was still a thing)
nRE <- 2 ## number of REs per province {deltar and loc}
tmb_pars_binom <- c(tmb_pars_binom,
                     list(loc = 20,
                          b = rep(0, nRE * np),
                          log_sd = rep(1, nRE),
                          corr = rep(0, nRE*(nRE-1)/2)))


## trying to force large values of SD (-> fixed effects)
## much of this is obsolete now: value would go in `map` arg
## to tmb_fit()
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

