library(shellpipes)
library(broom.mixed)
if (packageVersion("broom.mixed") < "0.2.9") stop("please install latest version of broom.mixed via remotes::install('bbolker/broom.mixed')")
library(dplyr)
library(TMB) ## still need it to operate on TMB objects

fit <- rdsRead()
loadEnvironments()
soLoad()

cmvec <- c("wald", "profile", "uniroot")
names(cmvec) <- cmvec ## ugh: for purrr::map_dfr .id
## tidy(tmb_betabinom, conf.int = TRUE, conf.method = "wald")
## tidy(tmb_betabinom, conf.int = TRUE, conf.method = "profile")
## tidy(tmb_betabinom, conf.int = TRUE, conf.method = "uniroot")

system.time(
    tt <- purrr::map_dfr(cmvec,
                         ~ tidy(fit,
                                conf.int = TRUE,
                                conf.method = .),
                         .id = "method")
)
rdsSave(tt)

