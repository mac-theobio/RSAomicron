
## Legacy rule for the first data set we used in this repo
## Merging code is in omike and in osac
sgtf_ref.sr.ll.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 
	$(pipeR)

## Aggregating into time series
## Currently done in another repo
## simDates is for zeroDate
impmakeR += sr.agg
%.sr.agg.Rout: sr_agg.R %.sr.ll.rds simDates.rda
	$(pipeR)
