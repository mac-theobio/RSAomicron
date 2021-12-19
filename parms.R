library(shellpipes)

loadEnvironments()
objects()
saveEnvironment()

if (length(fileSelect(ext=c("rds", "RDS"))) == 0)
	rdsSave(NULL)

if (length(fileSelect(ext=c("rds", "RDS"))) == 1){
	rdat <- rdsRead()
	print(summary(rdat))
	rdsSave(rdat)
}
