library(TMB) ## still need it to operate on TMB objects
library(ggplot2); theme_set(theme_bw() + theme(panel.spacing = grid::unit(0, "lines")))
library(tidyr)
library(dplyr)

library(shellpipes)
## rpcall("btfake.sg.tmb_ensemble.Rout tmb_ensemble.R btfake.sg.ltfit.tmb_fit.rds tmb_funs.rda logistic.so")
rpcall("btfake.sr.tmb_ensemble.Rout tmb_ensemble.R btfake.sr.ltfit.tmb_fit.rds tmb_funs.rda logistic.so")


startGraphics()

fit <- rdsRead()

pp1 <- predict(fit, perfect_tests = TRUE, confint = TRUE)

base <- (mk_completedata(fit)[c("prov", "time", "reinf")]
    |> tibble::as_tibble()
)
ensemble0 <- list()
pb <- txtProgressBar(style = 3, max = nsim)
for (i in 1:nsim) {
    if (interactive()) setTxtProgressBar(pb, i)
    ensemble0[[i]] <- predict(fit, newparams = pop_vals[i,], perfect_tests = TRUE, confint = FALSE)
}
close(pb)

grp_vars <- intersect(c("prov", "time", "reinf"), names(base))
ensemble <- (ensemble0
    |> setNames(paste0("s",1:nsim))
    |> bind_cols(base)
    |> pivot_longer(matches("s[0-9]"))
    ## !!!syms() magic from https://stackoverflow.com/questions/44169505/grouping-on-multiple-programmatically-specified-vars-in-dplyr-0-6
    |> group_by(!!!syms(grp_vars))
    |> summarise(pred = quantile(value, 0.5),
                 pred_lwr = quantile(value, 0.025),
                 pred_upr = quantile(value, 0.975),
                 .groups = "drop")
)

gg0 <- (ggplot(ensemble, aes(time, pred, ymin = pred_lwr, ymax = pred_upr))
    + geom_line()
    + geom_ribbon(alpha = 0.4, colour = NA, fill = "orange")
    + facet_wrap(~prov)
    + geom_line(data = pp1, colour = "blue")
    + geom_ribbon(data = pp1, alpha = 0.2, colour = NA, fill = "blue")
)

if (uses_reinf(fit)) {
    gg0 <- gg0 + aes(linetype = factor(reinf) )
}

## orange fill (light)/solid black line is ensemble median and quantiles
## blue fill (dark)/dashed blue line is MLE prediction and Wald CIs
print(gg0)

## where did EC Wald CIs go?
## ensemble |> filter(prov == "EC")
## pp1 |> filter(prov == "EC") |> arrange(time)
