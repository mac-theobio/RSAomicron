library(dplyr)
library(TMB)
library(bbmle)

library(shellpipes)

soLoad()

loadEnvironments()
lsfit <- rdsRead("lsfit")
ltfit <- rdsRead("ltfit")

bbmle::AICtab(ltfit, lsfit)
