library(shellpipes)
rpcall("tmb_eval.Rout tmb_eval.R tmb_fit.rda logistic_sim.rds tmb_funs.rda")
library(broom.mixed)
library(dplyr)
library(ggplot2); theme_set(theme_bw())
library(TMB) ## still need it to operate on TMB objects
## need to reload the dynamic library as well

startGraphics()

## includes fits, sim data (ss), file name/type info
loadEnvironments()
dyn.load(dynlib(tmb_file))

## predicted probabilities:
summary(tmb_betabinom$report()$prob)
tmb_betabinom_opt$par

rr <- sdreport(tmb_betabinom)
ss <- (ss
  %>% mutate(pred = plogis(rr$value),
             pred_lwr = plogis(rr$value - 1.96*rr$sd),
             pred_upr = plogis(rr$value + 1.96*rr$sd))
)

## predicted probabilities (2)
## deep-copy TMB object, then modify data within it appropriately
## FIXME: modularize/hide
pred_bb <- tmb_betabinom
e2 <- copyEnv(environment(tmb_betabinom$fn))
environment(pred_bb$fn) <- environment(pred_bb$gr) <-
    environment(pred_bb$report) <- pred_bb$env <- e2
newdata0 <- with(e2$data,
                expand.grid(province = unique(province),
                            t = unique(t)))
n <- nrow(newdata0)
newdata <- c(newdata0,
             e2$data[c("debug", "nprov")],
             list(dropouts = rep(NA_real_, n),
                  total_positives = rep(NA_real_, n)))
e2$data <- newdata
rr <- sdreport(pred_bb)

ss2 <- (newdata0
    %>% as_tibble()
    %>% mutate(
            province = levels(ss$province)[province + 1],
            pred = plogis(rr$value),
            pred_lwr = plogis(rr$value - 1.96*rr$sd),
            pred_upr = plogis(rr$value + 1.96*rr$sd))
)

gg1 <- (ggplot(ss, aes(t, colour = province))
  + geom_point(aes(y=dropouts/total_positives, size = total_positives))
  + geom_line(data = ss2, aes(y=pred))
    + geom_ribbon(data = ss2,
                  aes(fill = province, ymin = pred_lwr, ymax = pred_upr),
                  colour = NA, alpha = 0.2)
  + facet_wrap(~province)
)
print(gg1)

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

## log-sd is problematic here (need to regularize!) --
sdr <- suppressWarnings(sdreport(tmb_betabinom))
cc <- coef(tmb_betabinom)
vv <- vcov(tmb_betabinom)
sd_vals <- setNames(
    suppressWarnings(sqrt(diag(vv))),
    colnames(vv))

if (is.na(sd_vals[["log_sd"]])) {
    w <- which(names(cc) == "log_sd")
    cc <- cc[-w]
    vv <- vv[-w, -w]
    sd_vals <- sd_vals[-w]
}

## not expecting any other non-finite values!

stopifnot(all(is.finite(sd_vals)))

ev <- eigen(vv)$values
if (is.complex(vv) || any(ev < 0)) {
    warning("pos-defifying cov matrix")
    vv <- Matrix::nearPD(vv)$mat
}
## get ensemble (MVN sampling distribution)
pop_vals <- MASS::mvrnorm(1000,
                          mu = cc,
                          Sigma = vv)
                          

dev.off() ## do I need this, or is there some other shellpipe-y way?
