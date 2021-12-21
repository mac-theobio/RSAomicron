library(shellpipes)
rpcall("tmb_eval.Rout tmb_eval.R tmb_fit.rds tmb_funs.rda")

library(broom.mixed)
library(dplyr)
library(ggplot2); theme_set(theme_bw())
library(TMB) ## still need it to operate on TMB objects
## need to reload the dynamic library as well

startGraphics()

## includes fits, sim data (ss), file name/type info
fit <- rdsRead()
loadEnvironments()
dyn.load(dynlib(get_tmb_file(fit)))


## predicted probabilities:
summary(fit$report()$prob)
coef(fit)

rr <- sdreport_split(fit)
ss <- get_data(fit)

## simple predictions
ss <- (ss
    %>% mutate(pred = plogis(rr$value$loprob),
               pred_lwr = plogis(rr$value$loprob - 1.96*rr$sd$loprob),
               pred_upr = plogis(rr$value$loprob + 1.96*rr$sd$loprob))
)


## more sophisticated prediction
predvals <- predict.srfit(fit)

gg1 <- (ggplot(ss, aes(time, colour = prov))
    + geom_point(aes(y=omicron/tot, size = tot))
    + geom_line(data = predvals, aes(y=pred))
    + geom_ribbon(data = predvals,
                  aes(fill = prov, ymin = pred_lwr, ymax = pred_upr),
                  colour = NA, alpha = 0.2)
  + facet_wrap(~prov)
)
print(gg1)


## estimate, standard errors, Wald CIs
t1 <- tidy(fit, conf.int = TRUE)

## plot


## better CIs
if (FALSE) {
    ## profiling (22 seconds for one parameter on laptop;
    ##  should parallelize)
    system.time(tmbprofile(tmb_betabinom, name = 1, trace=FALSE))
    ## use root-finding/uniroot instead (15 seconds)
    system.time(tmbroot(tmb_betabinom, name = 1, trace=FALSE))
    ## to do all parameters ... FIXME, put this in a downstream file
    system.time(
        tidy(tmb_betabinom, conf.int = TRUE, conf.method = "profile")
    )
}

## get ensemble (MVN sampling distribution)

pop_vals <- MASS::mvrnorm(1000,
                          mu = coef(fit),
                          Sigma = vcov(fit))
                          

dev.off() ## do I need this, or is there some other shellpipe-y way?
