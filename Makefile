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

## Crib rule Get rid of this soon 2021 Dec 21 (Tue)
## ln -s ../omike cribdir ##

Ignore += cribdir
.PRECIOUS: %.R
%.R: cribdir/%.R
	$(copy)

######################################################################

## Dictionary files (right now just provinces)

Sources += $(wildcard *.dict.tsv)

######################################################################

## Line-list sources and cleaning

## Combined line list merged by CP 9 Dec
## FIXME: does order-only rule do this better than $(MAKE)?
data/sgtf_ref.rds:
	$(MAKE) data
sgtf_ref.sr.ll.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 
	$(pipeR)

## No other current sources
## Merging code in omike or in osac

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

## Fit

impmakeR += tmb_fit
%.tmb_fit.Rout: tmb_fit.R %.ts.rds logistic.so tmb_funs.rda
	$(pipeR)

## Evaluate fits

## bsfake.sg.tmb_eval.Rout: tmb_eval.R
## bsfake.sr.tmb_eval.Rout: tmb_eval.R
## sgtf_ref.chop2.sg.tmb_eval.Rout: tmb_eval.R
%.tmb_eval.Rout: tmb_eval.R %.tmb_fit.rds tmb_funs.rda logistic.so
	$(pipeR)

## get ensemble (MVN sampling distribution)
## 
## pop_vals <- MASS::mvrnorm(1000,
##  mu = coef(fit),
##  Sigma = vcov(fit))

######################################################################

## Beta fitting choice for mle pipeline

impmakeR += btfit.sg.ts
%.btfit.sg.ts.Rout: parms.R %.sg.ts.rds betatheta.rda
	$(pipeR)

impmakeR += bsfit.sg.ts
%.bsfit.sg.ts.Rout: parms.R %.sg.ts.rds betasigma.rda
	$(pipeR)

######################################################################

## Choosing fixed params for mle pipeline
impmakeR += ssfix.sg.ts
%.ssfix.sg.ts.Rout: parms.R %.sg.ts.rda %.sg.ts.rds ssfix.rda
	$(pipeR)

impmakeR += ssfitspec.sg.ts
%.ssfitspec.sg.ts.Rout: parms.R %.sg.ts.rda %.sg.ts.rds ssfitspec.rda
	$(pipeR)

impmakeR += ssfitboth.sg.ts
%.ssfitboth.sg.ts.Rout: parms.R %.sg.ts.rda %.sg.ts.rds ssfitboth.rda
	$(pipeR)

######################################################################

## mle2 fitting

## btfake.btfit.ssfix.sgssmle2.Rout: sgssmle2.R
## 'btfake' = simulate with theta;
## 'btfit' = fit with theta;
## 'ssfitboth' = fit both drop and gain
## bsfake.btfit.ssfitspec.sgssmle2.Rout: sgssmle2.R
## main.btfit.ssfitboth.sgssmle2.Rout: sgssmle2.R
## main.bsfit.ssfitboth.sgssmle2.Rout: sgssmle2.R
impmakeR += sgssmle2
%.sgssmle2.Rout: sgssmle2.R %.sg.ts.rds %.sg.ts.rda ssfitfuns.rda
	$(pipeR)

######################################################################

## Tidy (Confidence-interval machien)
## main.bsfit.ssfitboth.mle2tidy.Rout: mle2tidy.R
## main.bsfit.ssfitspec.mle2tidy.Rout: mle2tidy.R
## main.btfit.ssfitboth.mle2tidy.Rout: mle2tidy.R
## main.btfit.ssfitspec.mle2tidy.Rout: mle2tidy.R
%.mle2tidy.Rout: mle2tidy.R %.sgssmle2.rds ssfitfuns.rda
	$(pipeR)

######################################################################

## Experiments

## each of bt/bs paradigm fits its own fake data better 2021 Dec 22 (Wed)
btcompare.Rout: btcompare.R btfake.sg.ts.rds bsfake.sg.ts.rds tmb_funs.rda logistic.so

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
