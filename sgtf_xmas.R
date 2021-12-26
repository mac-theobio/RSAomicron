library(dplyr)
library(haven)
library(dictClean)
library(shellpipes)

ts <- (rdsRead())

print(summary(ts %>% mutate_if(is.character, as.factor)))

ts <- (ts
	%>% transmute(NULL
		, prov, sgtf, 
		, date=specreceiveddate, 
		, reinf = (inf > 1)
	) %>% na.omit
)

summary(ts)

rdsSave(ts)
