library(dplyr)
library(haven)
library(dictClean)
library(shellpipes)

dat <- (rdsRead()
	%>% mutate(prov = catDict(province, tsvRead("prov")))
)

print(summary(dat))

rdsSave(dat)
