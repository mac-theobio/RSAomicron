library(shellpipes)

loadEnvironments()
saveEnvironment()

if (length(fileSelect(ext=c("rds", "RDS"))) == 0)
	rdsSave(NULL)

if (length(fileSelect(ext=c("rds", "RDS"))) == 1)
	rdsSave(rdsRead())
