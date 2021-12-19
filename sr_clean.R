library(dplyr)
library(haven)

library(shellpipes)

ll <- rdsRead()

#ll <- (ll
#	%>% mutate(NULL
#		, colldiff = as.numeric(speccollectiondate.y - speccollectiondate.x)
#		, recdiff = as.numeric(specreceiveddate.y - specreceiveddate.x)
#		, collcount = abs(colldiff) <= 1
#		, reccount = abs(recdiff) <= 1
#		, collzero = colldiff==0
#		, reczero = recdiff==0
#	)
#)

#summary(ll)
#ll %>% pull(caseid_hash) %>% unique %>% length

#ll <- (ll
#	%>% filter(reccount)
#)

#summary(ll)
#ll %>% pull(caseid_hash) %>% unique %>% length

ll <- (ll
	%>% transmute(NULL
		, prov, sgtf, 
		, date=specreceiveddate, 
		, reinf = (inf > 1)
	) %>% na.omit
)

summary(ll)

rdsSave(ll)
