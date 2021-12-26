## This is RSAomicron (a refactor of mvRt) ## Created Dec 2021

## Weird packages
## https://dushoff.github.io/shellpipes/
## https://dushoff.github.io/dictClean/

current: target
-include target.mk
Ignore = target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt README.md journal.md mle.mk README_TMB.md"

######################################################################

Sources += Makefile $(wildcard *.make)

## <edit> dubzee.make
## dubzee.local:
## /bin/rm -r data
## data:
%.local:
	$(LN) $*.make local.mk

-include local.mk

Ignore += data
data: datadir=$(data)
data: local.mk
	/bin/ln -s $(data) $@

Sources += data.md
pushdir = data/outputs

######################################################################

autopipeR = defined

Sources += $(wildcard *.R *.md)

Sources += content.mk ## stuff from mvRt Makefile
Sources += old.mk ## stuff dropped from here

pipeclean:
	$(RM) *.Rout *.rds *.rda

######################################################################

## Dictionary files (right now just provinces)

Sources += $(wildcard *.dict.tsv)

######################################################################

## Line-list sources and cleaning

## Combined line list merged by CP 9 Dec
## FIXME: does order-only rule do this better than $(MAKE)?
data/%.rds:
	$(MAKE) data

## Legacy rule for the first data set we used in this repo
sgtf_ref.sr.ll.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 
	$(pipeR)
## No other current sources
## Merging code in omike or in osac

######################################################################

## Side branch 2021 Dec 25 (Sat)

## New set seems to have different format?
sgtf_curr.sg.agg.Rout: sgtf_xmas.R data/sgtf_xmas.rds prov.dict.tsv 
	$(pipeR)

sgtf_ref.chop2.sg.agg.Rout:

######################################################################

## Aggregating into time series

impmakeR += sr.agg
## simDates is for zeroDate
%.sr.agg.Rout: sr_agg.R %.sr.ll.rds simDates.rda
	$(pipeR)

impmakeR += sg.agg
%.sg.agg.Rout: sgtf_agg.R %.sr.agg.rds
	$(pipeR)

######################################################################

## Date stuff

impmakeR += chop2.sr.agg
%.chop2.sr.agg.Rout: chop2.R %.sr.agg.rds
	$(pipeR)

######################################################################

## Proportion calculations

impmakeR += ts
%.ts.Rout: ts.R %.agg.rds
	$(pipeR)

## sgtf_ref.chop2.sr.ts.Rout:
main.sr.ts.rds: sgtf_ref.chop2.sr.ts.rds
	$(forcelink)

main.sg.ts.rds: sgtf_ref.chop2.sg.ts.rds
	$(forcelink)

######################################################################

## beta formulations for fake data

## Standard "theta" formulation θ = a + b
.PRECIOUS: %.bt.rds
%.bt.rds: %.rds
	$(forcelink)
.PRECIOUS: %.bt.rda
%.bt.rda: betatheta.rda
	$(forcelink)

## Weird JD formulation σ = ab/(a+b)
.PRECIOUS: %.bs.rds
%.bs.rds: %.rds
	$(forcelink)
.PRECIOUS: %.bs.rda
%.bs.rda: betasigma.rda
	$(forcelink)

######################################################################

## Fake data
## FIXME bsfake should really be .agg; this means changing rules and eliminating calculations (the latter is obviously trivial)

## main.sr.ts.bs.fake.Rout:
pushfake: main.sr.ts.bs.fake.rds.op main.sr.ts.bt.fake.rds.op

impmakeR += fake
%.fake.Rout: bbinfake.R %.rda %.rds
	$(pipeR)

bsfake.sr.agg.rds: outputs/main.sr.ts.bs.fake.rds
	$(forcelink)
btfake.sr.agg.rds: outputs/main.sr.ts.bt.fake.rds
	$(forcelink)

######################################################################

## TMB model

## Compile 

Sources += logistic.cpp logistic_fit.h
Ignore += logistic.so logistic.o
logistic.so: logistic.cpp logistic_fit.h
	touch $<
	Rscript --vanilla -e "TMB::compile('$<')"

######################################################################

## Parameter choices for TMB

## logtheta vs. logsigma fit
impmakeR += ltfit.ts
%.ltfit.ts.Rout: parms.R %.ts.rds logtheta.rda
	$(pipeR)
impmakeR += lsfit.ts
%.lsfit.ts.Rout: parms.R %.ts.rds logsigma.rda
	$(pipeR)

######################################################################

## Fit

## bsfake.sg.ltfit.tmb_fit.Rout: tmb_fit.R
impmakeR += tmb_fit
%.tmb_fit.Rout: tmb_fit.R %.ts.rds %.ts.rda logistic.so tmb_funs.rda
	$(pipeR)

## Evaluate fits

## bsfake.sg.ltfit.tmb_eval.Rout: tmb_eval.R
## bsfake.sg.lsfit.tmb_eval.Rout: tmb_eval.R
## btfake.sg.ltfit.tmb_eval.Rout: tmb_eval.R
## sgtf_ref.chop2.sg.tmb_eval.Rout: tmb_eval.R
%.tmb_eval.Rout: tmb_eval.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

## compare fixed, RE, pooled
%.tmb_fit_compare.Rout: tmb_fit_compare.R %.ts.rds logistic.so tmb_funs.rda
	$(pipeR)

%.tmb_ci.Rout: tmb_ci.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

%.tmb_ci_plot.Rout: tmb_ci_plot.R %.tmb_ci.rds tmb_funs.rda logistic.so
	$(pipeR)

## bsfake.sg.lsfit.tmb_ensemble.Rout: tmb_ensemble.R
%.tmb_ensemble.Rout: tmb_ensemble.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

######################################################################

## Compare beta formulations for tmb_fit's

## bsfake.sg.tmb_betaComp.Rout: tmb_betaComp.R
## btfake.sg.tmb_betaComp.Rout: tmb_betaComp.R
%.tmb_betaComp.Rout: tmb_betaComp.R %.lsfit.tmb_fit.rds %.ltfit.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

######################################################################

## mle pipeline now sidelined

Sources += mle.mk
include mle.mk

######################################################################

### Makestuff

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
