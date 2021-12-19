library(shellpipes)

loadEnvironments()
saveEnvironment()

if (length(fileSelect(ext=c("rds", "RDS"))) == 1)
	rdsSave(rdsRead())
