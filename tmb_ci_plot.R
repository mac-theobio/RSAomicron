library(shellpipes)
tt <- rdsRead()
library(ggplot2); theme_set(theme_bw())

startGraphics()

print(tt)

gg1 <- (ggplot(tt,
               aes(y=term, x=estimate, colour = method))
    + geom_pointrange(position=position_dodge(width=0.75),
                      aes(xmin = conf.low, xmax = conf.high ))
    + facet_wrap(~term, scale = "free")
)

print(gg1)

dev.off()


