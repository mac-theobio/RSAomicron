library(shellpipes)
rpcall("tmb_ci_plot.Rout tmb_ci_plot.R tmb_ci.rds")
library(dplyr)
library(ggplot2); theme_set(theme_bw())
tt <- rdsRead()


startGraphics(width = 12)

tt <- (tt
    %>% as_tibble()
    %>% select(method, term, estimate, conf.low, conf.high)
    %>% mutate(across(term, forcats::fct_inorder))
    %>% arrange(term)
)


## tt <- tt %>% filter(method != "profile")
print(tt, n = Inf)

gg1 <- (ggplot(tt,
               aes(y=term, x=estimate, colour = method))
    + geom_pointrange(position=position_dodge(width=0.75),
                      aes(xmin = conf.low, xmax = conf.high ))
    + facet_wrap(~term, scale = "free")
    + theme(axis.text.y = element_blank())
)

print(gg1)


