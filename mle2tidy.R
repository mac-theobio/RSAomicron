library(bbmle)
library(purrr)
library(dplyr)
## library(emdbook)

library(shellpipes)

fitlist <- rdsRead()
loadEnvironments()

coefdf <- (names(fitlist)
	%>% lapply(function(p){
		fit <- fitlist[[p]]
		mod <- fit$m
		cc <- fit$pi
		if(is.null(cc)){
			cc <- fit$wi
			if (is.null(cc)){
				warning("No CI for ", p)
				return(NULL)
			}
			warning("Using Wald CI for ", p)
			
		}

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
) %>% bind_rows

print(coefdf)
rdsSave(coefdf)

warnings()
