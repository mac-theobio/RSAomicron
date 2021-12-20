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

rr <- sdreport(fit)
ss <- get_data(fit)
ss <- (ss
    %>% mutate(pred = plogis(rr$value),
               pred_lwr = plogis(rr$value - 1.96*rr$sd),
               pred_upr = plogis(rr$value + 1.96*rr$sd))
)

## predicted probabilities (2)
## deep-copy TMB object, then modify data within it appropriately
## FIXME: modularize/hide

predict.srfit <- function(fit, newdata = NULL) {
    pred_bb <- fit
    e2 <- copyEnv(environment(pred_bb$fn))
    environment(pred_bb$fn) <- environment(pred_bb$gr) <-
        environment(pred_bb$report) <- pred_bb$env <- e2
    if (is.null(newdata)) {
        newdata0 <- with(get_data(fit),
                         expand.grid(prov = unique(prov),
                                     time = unique(time)))
    }
    n <- nrow(newdata0)
    dd <- fit$env$data ## all data
    for (nm in names(dd)) {
        if (nm %in% names(newdata)) {
            dd[[nm]] <- newdata[[nm]]
        } else {
            L <- length(dd[[nm]])
            if (L > 1 && L < n) {
                dd[[n]] <- rep(NA_real_, n)
            }
        }
    }
    e2$data <- dd
    rr <- sdreport(pred_bb)
    ss2 <- (newdata
        %>% as_tibble()
        %>% mutate(
            prov = levels(ss$province)[province + 1],
            pred = plogis(rr$value),
            pred_lwr = plogis(rr$value - 1.96*rr$sd),
            pred_upr = plogis(rr$value + 1.96*rr$sd))
)

gg1 <- (ggplot(ss, aes(t, colour = province))
  + geom_point(aes(y=dropouts/total_positives, size = total_positives))
  + geom_line(aes(y=pred))
  + geom_ribbon(aes(fill = province, ymin = pred_lwr, ymax = pred_upr),
                colour = NA, alpha = 0.2)
  + facet_wrap(~province)
)
print(gg1)

## tidy coefficients:
class(tmb_betabinom) <- "TMB"

## 

## FIXME: more principled/hidden/upstream ...
ee <- environment(tmb_betabinom$fn)
ee$last.par.best <- fix_province_names(ee$last.par.best)
coef(tmb_betabinom)

## estimate, standard errors, Wald CIs
t1 <- tidy(tmb_betabinom, conf.int = TRUE)

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
                          mu = fixef.TMB(tmb_betabinom),
                          Sigma = vcov.TMB(tmb_betabinom))
                          

dev.off() ## do I need this, or is there some other shellpipe-y way?
