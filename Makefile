## This is RSAomicron (a refactor of mvRt)
## Created Dec 2021

## Weird packages
## https://dushoff.github.io/shellpipes/
## https://dushoff.github.io/dictClean/

current: target
-include target.mk
Ignore = target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

Sources += $(wildcard *.make)
%.local:
	$(LN) $*.make local.mk

-include local.mk

Ignore += data
data: datadir=$(data)
data: local.mk
	/bin/ln -s $(data) $@

pushdir = data/outputs

Sources += data.md

######################################################################

autopipeR = defined

Sources += $(wildcard *.R *.md)

Sources += content.mk ## stuff from mvRt Makefile

######################################################################

## Crib rule

## ln -s ../omike cribdir ##

Ignore += cribdir
%.R: cribdir/%.R
	$(copy)

######################################################################

Sources += $(wildcard *.dict.tsv)

######################################################################

## Line-list sources and cleaning

## Combined line list merged by CP
sgtf_ref.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 

## No other current sources

## Current version
sr_ll.rds: sgtf_ref.rds
	$(forcelink)

######################################################################

## Aggregating into time series

sr_ts.Rout: sr_agg.R sr_ll.rds
	$(pipeR)

sg_ts.Rout: sgtf_agg.R sr_ts.rds
	$(pipeR)

######################################################################

## Date stuff

impmakeR += chop2
%.chop2.Rout: chop2.R %.rds
	$(pipeR)

######################################################################

## Proportion calculations

## simDates is for zeroDate
impmakeR += props
%.props.Rout: props.R %.rds simDates.rda
	$(pipeR)

## sg_ts.chop2.props.Rout:
sg_main.rds: sg_ts.chop2.props.rds
	$(forcelink)

## sr_ts.chop2.props.Rout:
sr_main.rds: sr_ts.chop2.props.rds
	$(forcelink)

######################################################################

## beta formulations

.PRECIOUS: %.bs.rds
%.bs.rds: %.rds
	$(link)
.PRECIOUS: %.bs.rda
%.bs.rda: betasigma.rda
	$(forcelink)

.PRECIOUS: %.bt.rds
%.bt.rds: %.rds
	$(link)
.PRECIOUS: %.bt.rda
%.bt.rda: betatheta.rda
	$(forcelink)

######################################################################

## Fake data

## sr_main.bs.fake.Rout: bbinfake.R
## sr_main.bt.fake.Rout: bbinfake.R
%.fake.Rout: bbinfake.R %.rda %.rds
	$(pipeR)



######################################################################

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

Makefile: makestuff/00.stamp
makestuff/%.stamp:
	- $(RM) makestuff/*.stamp
	(cd makestuff && $(MAKE) pull) || git clone $(msrepo)/makestuff
	touch $@

-include makestuff/os.mk

-include makestuff/pipeR.mk

-include makestuff/git.mk
-include makestuff/visual.mk
