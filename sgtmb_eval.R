library(shellpipes)

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
print(tidy(fit, conf.int = TRUE))

## plot 
v <- rr$value$log_deltar_vec
s <- rr$sd$log_deltar_vec
deltar_data <- (tibble(
    prov = get_prov_names(fit),
    deltar = exp(v),
    lwr = exp(v - 1.96*s),
    upr = exp(v + 1.96*s))
    %>% mutate(across(prov, forcats::fct_reorder, deltar))
)
gg2A <- (ggplot(deltar_data,
                aes(y = prov, x = deltar)))

## print(gg2A + geom_point())

## boring! width of CIs >>  range of values
print(gg2A + geom_pointrange(aes(xmin = lwr, xmax = upr)))

                          
