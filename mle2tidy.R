library(bbmle)
library(purrr)
library(dplyr)
## library(emdbook)

library(shellpipes)

fitlist <- rdsRead()
loadEnvironments()

coefdf <- (names(fitlist)
	%>% lapply(function(p){
		mod <- fitlist[[p]]$m
		cc <-  fitlist[[p]]$wi
		print(p)
		print(summary(cc))
		return(class(cc))
		if (is.null(cc)) return(NULL)
		dd <- (as.data.frame(cc)
		  %>% mutate(prov = p
			  , param = rownames(.)
		  )
		)
		rownames(dd) <- NULL
		colnames(dd) <- c("lwr","upr","prov","param")
		
		coefdat <- data.frame(prov = p
		  , param = names(coef(mod))
		  , est = coef(mod)
		)
		return(left_join(dd,coefdat))
	})
) ## %>% bind_rows

print(coefdf)
rdsSave(coefdf)

warnings()
