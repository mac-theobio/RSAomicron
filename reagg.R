library(dplyr)
library(haven)
library(dictClean)
library(shellpipes)

loadEnvironments()
ts <- (rdsRead())

print(summary(ts %>% mutate_if(is.character, as.factor)))

quit()

ts <- (ts
	%>% transmute(NULL
		, prov, date
		, time = as.numeric(date - zeroDate)
#		, reinf = (infection == "reinfection")
		, reinf
		, omicron = SGTF
		, delta = nonSGTF
	)
)

summary(ts)

rdsSave(ts)
