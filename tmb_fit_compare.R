## compare pooled (SD approx 0); fixed-effect (SD approx ∞); random effect models
library(ggplot2); theme_set(theme_bw(base_size = 16))
library(TMB)
library(dplyr)
library(purrr)

library(shellpipes)
rpcall("btfake.sg.tmb_fit_compare.Rout tmb_fit_compare.R btfake.sg.ts.rds logistic.so tmb_funs.rda")

loadEnvironments()
soLoad()

dd <- rdsRead()

## base fit
tt0 <- tmb_fit(dd)
## craps out between sd = 4 and sd = 5
logsd_logdeltar_vals <- c(-8,4)
names(logsd_logdeltar_vals) <- sprintf("logsd=%1.1f",logsd_logdeltar_vals)
fit_list <- purrr::map(logsd_logdeltar_vals,
           ~ tmb_fit(dd,
                     map = list(logsd_logdeltar = factor(NA)),
                     start = list(log_deltar = log(0.1), lodrop = -4, 
                                  logain = -7, beta_reinf = 0,
                                  logsd_logdeltar = .))
)
fit_list <- c("RE"=list(tt0), fit_list)
delta_est <- fit_list %>%
    purrr::map_dfr(get_prov_params, .id = "model")
gg0 <- (ggplot(delta_est, aes(x = value, y = prov, colour = model)) +
    geom_pointrange(aes(xmin=lwr, xmax = upr),
                    position = position_dodge(width = 0.75)) +
    scale_x_continuous(limits = c(0,0.8), oob = scales::squish)
)
print(gg0)
