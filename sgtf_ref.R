library(dplyr)
library(haven)
library(dictClean)
library(shellpipes)

ll <- (rdsRead()
	%>% mutate(prov = catDict(province, tsvRead("prov")))
)

print(summary(ll))

ll <- (ll
	%>% transmute(NULL
		, prov, sgtf, 
		, date=specreceiveddate, 
		, reinf = (inf > 1)
	) %>% na.omit
)

summary(ll)

rdsSave(ll)
