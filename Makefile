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

pipeclean:
	$(RM) *.Rout *.rds *.rda

######################################################################

## Crib rule
## ln -s ../omike cribdir ##

Ignore += cribdir
.PRECIOUS: %.R
%.R: cribdir/%.R
	$(copy)

######################################################################

Sources += $(wildcard *.dict.tsv)

######################################################################

## Line-list sources and cleaning

## Combined line list merged by CP 9 Dec
data/sgtf_ref.rds: data ;
sgtf_ref.srll.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 
	$(pipeR)

## No other current sources
## Merging code in omike or in osac

######################################################################

## Aggregating into time series

impmakeR += srts
## simDates is for zeroDate
%.srts.Rout: sr_agg.R %.srll.rds simDates.rda
	$(pipeR)

## Aggregate across reinf for sg
impmakeR += sgts
%.sgts.Rout: sgtf_agg.R %.srts.rds
	$(pipeR)

######################################################################

## Date stuff

impmakeR += chop2.srts
%.chop2.srts.Rout: chop2.R %.srts.rds
	$(pipeR)

######################################################################

## Proportion calculations

impmakeR += props
%.props.Rout: props.R %.rds
	$(pipeR)

## sgtf_ref.srts.chop2.props.Rout:
main.srts.rds: sgtf_ref.srts.chop2.props.rds
	$(forcelink)

main.sgts.rds: sgtf_ref.sgts.chop2.props.rds
	$(forcelink)

######################################################################

## beta formulations

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

## main.srts.bs.fake.Rout main.srts.bt.fake.Rout
pushfake: main.srts.bs.fake.rds.op main.srts.bt.fake.rds.op

impmakeR += fake
%.fake.Rout: bbinfake.R %.rda %.rds
	$(pipeR)

bsfake.srts.rds: outputs/main.srts.bs.fake.rds
	$(forcelink)
btfake.srts.rds: outputs/main.srts.bt.fake.rds
	$(forcelink)

######################################################################

## (Frozen for Bolker)

## SS mle fit
## bsfake.sgssmle2.Rout: sgssmle2.R bsfake.sgts.rds 
## btfake.sgssmle2.Rout: sgssmle2.R btfake.sgts.rds 
%.sgssmle2.Rout: sgssmle2.R %.sgts.props.rds betatheta.rda ssfix.rda
	$(pipeR)

tmb_fit.Rout: tmb_fit.R btfake.sgts.rds logistic.so tmb_funs.rda

%.sgrtmb.Rout: sgtmb.R %.sgts.props.rds logistic.so tmb_funs.rda
	$(pipeR)


tmb_eval.Rout: tmb_eval.R tmb_fit.rds logistic.so tmb_funs.rda

tmb_diagnose.Rout: tmb_diagnose.R tmb_fit.rda btfake.sgs.rds tmb_funs.rda

tmb_ci.Rout: tmb_ci.R tmb_fit.rds tmb_funs.rda

tmb_ci_plot.Rout: tmb_ci_plot.R tmb_ci.rds

tmb_stan.Rout: tmb_stan.R tmb_fit.rds tmb_funs.rda

######################################################################

## sgtf_ref.chop2.sgssmle2.Rout: sgssmle2.R

######################################################################

## Piping the Bolker stuff

## Compile a TMB model
Ignore += sg.so sg.o
sg.so: sg.cpp logistic_fit.h
	touch $<
	Rscript --vanilla -e "TMB::compile('$<')"

Ignore += logistic.so logistic.o
logistic.so: logistic.cpp logistic_fit.h
	touch $<
	Rscript --vanilla -e "TMB::compile('$<')"

impmakeR += sgtmb
## btfake.sgtmb.Rout: sgtmb.R tmb_funs.R
## sgtf_ref.chop2.sgtmb.Rout: sgtmb.R tmb_funs.R
%.sgtmb.Rout: sgtmb.R %.sgts.props.rds logistic.so tmb_funs.rda
	$(pipeR)

## sgtf_ref.chop2.sgtmb_eval.Rout: sgtmb.R tmb_funs.R
%.sgtmb_eval.Rout: sgtmb_eval.R %.sgtmb.rds tmb_funs.rda logistic.so
	$(pipeR)

%.srtmb.Rout: sgtmb.R %.srts.props.rds logistic.so tmb_funs.rda
	$(pipeR)

%.srtmb_eval.Rout: sgtmb_eval.R %.srtmb.rds logistic.so tmb_funs.rda
	$(pipeR)



## get ensemble (MVN sampling distribution)
## 
## pop_vals <- MASS::mvrnorm(1000,
##  mu = coef(fit),
##  Sigma = vcov(fit))

######################################################################

## Beta fitting

impmakeR += btfit.sgts
%.btfit.sgts.Rout: parms.R %.sgts.props.rds betatheta.rda
	$(pipeR)

impmakeR += bsfit.sgts
%.bsfit.sgts.Rout: parms.R %.sgts.props.rds betasigma.rda
	$(pipeR)

######################################################################

## Parameters to fix
impmakeR += ssfix.sgts
%.ssfix.sgts.Rout: parms.R %.sgts.rda %.sgts.rds ssfix.rda
	$(pipeR)

impmakeR += ssfitspec.sgts
%.ssfitspec.sgts.Rout: parms.R %.sgts.rda %.sgts.rds ssfitspec.rda
	$(pipeR)

impmakeR += ssfitboth.sgts
%.ssfitboth.sgts.Rout: parms.R %.sgts.rda %.sgts.rds ssfitboth.rda
	$(pipeR)

######################################################################

## mle2 fitting

## btfake.btfit.ssfix.sgssindfit.Rout: sgssindfit.R
## bsfake.btfit.ssfitspec.sgssindfit.Rout: sgssindfit.R
## sgtf_ref.btfit.ssfitspec.sgssindfit.Rout: sgssindfit.R

## If this works, merge back into mle2
impmakeR += sgssindfit
%.sgssindfit.Rout: sgssindfit.R %.sgts.rds %.sgts.rda
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
