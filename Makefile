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

## Data linking

Sources += Makefile $(wildcard *.make)

local.mk:
	echo 'Make local.mk by creating <user>.make and saying `make <user>.local`'
	false

%.local:
	$(LN) $*.make local.mk

-include local.mk

######################################################################

## input is the big dropbox; data is the small

Ignore += data input
data input: | local.mk
	/bin/ln -fs $($@)

## Copy files from big to small dropbox; not all users have big dropbox
## So the big dropbox (input) should be made manually
.PRECIOUS: data/%
data/%: | data
	$(CP) input/$* $@

data_reset:
	$(RM) data/sgtf_*.rds

data_copy:
	$(CP) input/sgtf_*.rds data/

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
Sources += lines.mk

######################################################################

## New processing branch 2021 Dec 25 (Sat)
## Starting now with pre-aggregated data

sgtf2.sr.agg.Rout: reagg.R data/sgtf_xmas.rds simDates.rda
	$(pipeR)

## Celebrating a new year of COVID!
## ln -fs ~/Dropbox/omicronSA/input/sgtf_trim.rds data ##
sgtf2022.sr.agg.Rout: reagg.R data/sgtf_trim.rds simDates.rda
	$(pipeR)

######################################################################

## No EC

######################################################################

## New year scenarios

scen = 90
scen = 30 60 hold trim
scen = 30 60 90 hold trim

######################################################################

## Aggregate across provinces

impmakeR += multi.sr.agg
## 30.multi.sr.agg.Rout: 
%.multi.sr.agg.Rout: reagg.R data/sgtf_%.rds simDates.rda
	$(pipeR)

######################################################################

## Optionally eliminate Easter Cape

impmakeR += noec.sr.agg
## 90.noec.sr.agg.Rout: noec.R 
%.noec.sr.agg.Rout: noec.R %.multi.sr.agg.rds
	$(pipeR)

######################################################################

impmakeR += sg.agg
%.sg.agg.Rout: sgtf_agg.R %.sr.agg.rds
%.sg.agg.Rout: sgtf_agg.R %.sr.agg.rds
	$(pipeR)

######################################################################

## Date stuff 

## Drop the last two days
impmakeR += chop2.sr.agg
%.chop2.sr.agg.Rout: chop2.R %.sr.agg.rds
	$(pipeR)

## Explicit window for P2
impmakeR += ddate2.sr.agg
## sgtf2.ddate2.sr.agg.Rout: ddate2.R
%.ddate2.sr.agg.Rout: ddate2.R %.sr.agg.rds
	$(pipeR)

## Lookback dates
impmakeR += olddate.sr.agg
## sgtf2.olddate.sr.agg.Rout: olddate.R
%.olddate.sr.agg.Rout: olddate.R %.sr.agg.rds
	$(pipeR)

######################################################################

## Proportion calculations

impmakeR += ts
%.ts.Rout: ts.R %.agg.rds
	$(pipeR)

######################################################################

## Set a "main" date stream; is this good? 2021 Dec 26 (Sun)
## sgtf_ref.chop2.sr.ts.Rout:
## main.sr.ts.rds: sgtf_ref.chop2.sr.ts.rds
main.sr.ts.rds: sgtf2.ddate2.sr.ts.rds
	$(forcelink)

main.sg.ts.rds: sgtf2.ddate2.sg.ts.rds
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

## bsfake.sr.ltfit.tmb_eval.Rout: tmb_eval.R
## bsfake.sg.ltfit.tmb_eval.Rout: tmb_eval.R
## sgtf2.ddate2.sg.ltfit.tmb_eval.Rout: tmb_eval.R
impmakeR += tmb_eval
%.tmb_eval.Rout: tmb_eval.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

## compare fixed, RE, pooled
## bsfake.sg.tmb_fit_compare.Rout: tmb_fit_compare.R
## sgtf2.ddate2.sg.tmb_fit_compare.Rout: tmb_fit_compare.R
impmakeR += tmb_fit_compare
%.tmb_fit_compare.Rout: tmb_fit_compare.R %.ts.rds logistic.so tmb_funs.rda
	$(pipeR)

impmakeR += tmb_ci
%.tmb_ci.Rout: tmb_ci.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

## sgtf2.ddate2.sg.lsfit.tmb_ci_plot.Rout: tmb_eval.R
%.tmb_ci_plot.Rout: tmb_ci_plot.R %.tmb_ci.rds tmb_funs.rda logistic.so
	$(pipeR)

######################################################################

## Split parameter ensemble from downstream stuff 2022 Jan 03 (Mon)
## Not finished!!

## bsfake.sg.ltfit.tmb_params.Rout: tmb_params.R
## bsfake.sr.ltfit.tmb_params.Rout: tmb_params.R
impmakeR += tmb_params
%.tmb_params.Rout: tmb_params.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

## sgtf2.ddate2.sg.ltfit.tmb_ensemble.Rout: tmb_ensemble.R
impmakeR += tmb_ensemble
%.tmb_ensemble.Rout: tmb_ensemble.R %.tmb_params.rds tmb_funs.rda logistic.so
	$(pipeR)

%.tmb_predict_test.Rout: tmb_predict_test.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

######################################################################

## sgtf2.ddate2.sg.ltfit.tmb_params.rds: tmb_params.R
## sgtf2.olddate.sg.ltfit.tmb_params.rds: tmb_params.R
## 60.multi.ddate2.sr.ltfit.tmb_params.rds: tmb_params.R

## Make a lot of scenario ensembles
## scenpush.makevar:
scenpush += $(scen:%=%.multi.ddate2.sr.ltfit.tmb_params.rds.pd.continue)
scenpush += $(scen:%=%.multi.olddate.sr.ltfit.tmb_params.rds.pd.continue)

## exppush.makevar:
exppush += $(scen:%=%.noec.ddate2.sr.ltfit.tmb_params.rds.pd.continue)
exppush += $(scen:%=%.noec.olddate.sr.ltfit.tmb_params.rds.pd.continue)

######################################################################

## NOT a target data/outputs/sgtf2.ddate2.sg.ltfit.tmb_params.rds

## btfake.sr.ltfit.tmb_ensemble.Rout:
## sgtf2.olddate.sr.ltfit.tmb_eval.Rout:
## sgtf2.ddate2.sr.ltfit.tmb_eval.Rout:
## sgtf2.ddate2.sr.ltfit.tmb_ensemble.Rout:
## sgtf2.ddate2.sr.ltfit.tmb_ci.Rout:
## sgtf2.ddate2.sr.ltfit.tmb_ci_plot.Rout:
## sgtf2.ddate2.sr.ltfit.tmb_ci_plot.Rout:

######################################################################

## Compare beta formulations for tmb_fit's

## bsfake.sg.tmb_betaComp.Rout: tmb_betaComp.R
## btfake.sg.tmb_betaComp.Rout: tmb_betaComp.R
## sgtf2.ddate2.sr.tmb_betaComp.Rout: tmb_betaComp.R
## sgtf2.ddate2.sg.tmb_betaComp.Rout: tmb_betaComp.R
## sgtf2.olddate.sg.tmb_betaComp.Rout: tmb_betaComp.R
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
