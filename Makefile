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
sgtf_ref.srll.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 
	$(pipeR)

## No other current sources
## Merging code in omike or in osac

######################################################################

## Aggregating into time series

impmakeR += srts
%.srts.Rout: sr_agg.R %.srll.rds
	$(pipeR)

## Aggregate across reinf for sg
impmakeR += sgts
%.sgts.Rout: sgtf_agg.R %.srts.rds
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

sr_main.rds: sgtf_ref.srts.chop2.props.Rout
	$(forcelink)

sg_main.rds: sgtf_ref.sgts.chop2.props.Rout
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

pushfake: sr_main.bs.fake.rds.op sr_main.bt.fake.rds.op

## sr_main.bs.fake.Rout: bbinfake.R
## sr_main.bt.fake.Rout: bbinfake.R
%.fake.Rout: bbinfake.R %.rda %.rds
	$(pipeR)

bsfake.rds: outputs/sr_main.bs.fake.rds
	$(forcelink)
btfake.rds: outputs/sr_main.bt.fake.rds.op
	$(forcelink)

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
