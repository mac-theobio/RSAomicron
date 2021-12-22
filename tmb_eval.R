library(shellpipes)
## rpcall("btfake.sgtmb_eval.Rout sgtmb_eval.R btfake.sgtmb.rds tmb_funs.rda logistic.so")

library(broom.mixed)
library(dplyr)
library(ggplot2); theme_set(theme_bw() + theme(panel.spacing = grid::unit(0, "lines")))
library(TMB) ## still need it to operate on TMB objects

## global graphics preferences
pt_alpha <- 0.5
reinf_colours <- c("black", "red")
## BMB: I know JD likes scale_size_area, but it makes the size range of the points too hard to handle ...
if (FALSE) {
    scale_size <- scale_size_area
}
plot_simple <- FALSE

startGraphics()

## includes fits, sim data (ss), file name/type info
fit <- rdsRead()
loadEnvironments()
soLoad()  ## still need to reload dynamic library

## predicted probabilities:
summary(fit$report()$prob)
coef(fit)

ss0 <- get_data(fit)
if (uses_reinf(fit)) {
    ## ggplot will want reinf to be a factor (for linetype/shape)
    ss0 <- ss0 %>% mutate(across(reinf, factor))
}


## simple predictions (no filling-in of missing time values)
if (plot_simple) {
    rr <- sdreport_split(fit)

    ss1 <- (ss0
        %>% mutate(pred = plogis(rr$value$loprob),
                   pred_lwr = plogis(rr$value$loprob - 1.96*rr$sd$loprob),
                   pred_upr = plogis(rr$value$loprob + 1.96*rr$sd$loprob))
    )

    ## base plot
    gg0 <- (ggplot(ss1, aes(time))
        + geom_point(aes(y=omicron/tot, size = tot), alpha = pt_alpha)
        + geom_line(aes(y=pred))
        + geom_ribbon(aes(ymin = pred_lwr, ymax = pred_upr),
                      colour = NA, alpha = 0.2)
        + facet_wrap(~prov)
        + scale_size()
        + ggtitle("simple prediction (no time-interpolation)")
    )

    ## extend the plot to show effect of reinfection
    if (uses_reinf(fit)) {
        gg0 <- (gg0
            + aes(shape = reinf, linetype = reinf, colour = reinf)
            + scale_colour_manual(values = reinf_colours)
        )
    }

    print(gg0)
}

## more sophisticated prediction
predvals <- predict(fit)
if (uses_reinf(fit)) {
    predvals <- predvals %>% mutate(across(reinf, factor))
}

## FIXME: DRY so much ...
gg1 <- (ggplot(ss0, aes(time))
    + geom_point(aes(y=omicron/tot, size = tot), alpha = pt_alpha)
    + geom_line(data = predvals, aes(y=pred))
    + geom_ribbon(data = predvals,
                  aes(ymin = pred_lwr, ymax = pred_upr),
                  colour = NA, alpha = 0.2)
    + scale_size()
    + facet_wrap(~prov)
)
if (uses_reinf(fit)) {
    gg1 <- (gg1
        + aes(shape = reinf, linetype = reinf, colour = reinf, group = reinf)
        + scale_colour_manual(values = reinf_colours)
    )
}

print(gg1)


## estimate, standard errors, Wald CIs
print(tt <- tidy(fit, conf.int = TRUE))

## prepare for coef plot
tt2 <- (tt
    %>% filter(!grepl("loc", term))
    %>% mutate(across(term, forcats::fct_inorder))
    %>% select(term, estimate, lwr = conf.low, upr = conf.high)
)

## these don't necessarily all make sense together, but at least
## they're all in log or log-odds units
coefplot <- (ggplot(tt2, aes(x = estimate, y = term))
    + geom_pointrange(aes(xmin = lwr, xmax = upr))
)
print(coefplot)

## plot of delta-r by province
deltar_data <- get_deltar(fit)
gg2A <- (ggplot(deltar_data,
                aes(y = prov, x = deltar)))

## boring for fake data! width of CIs >>  range of values
print(gg2A + geom_pointrange(aes(xmin = lwr, xmax = upr)))
