
## Framework for making tsvs (not part of pipeline)
Ignore += $(wildcard *.prov.tsv *.var.tsv)

######################################################################

## Compare old and new sgtf 

sgtf_comp.Rout: sgtf_comp.R sgtf_old.rds sgtf_new.rds
	$(pipeR)

comp_plots.Rout: comp_plots.R sgtf_comp.rds

######################################################################

Sources += $(wildcard *.dict.tsv)

######################################################################

sgtf_ref.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 

sr_clean.Rout: sr_clean.R sgtf_ref.rds
	$(pipeR)

sr.Rout: sr_agg.R sr_clean.rds dataDates.rda
	$(pipeR)

######################################################################

## sgtf pipeline

## sgtf line list by aggregating (everything is extended now)
## (here is where we manually pick the data set)
sgtf.Rout: sgtf_agg.R sr.rds
	$(pipeR)

## sgtf.props.Rout: props.R
## sgtf.pplots.Rout: pplots.R

## Fit our big model
impmakeR += bin quasi
## fitbig.bin.Rout: fitbig.R bin.R
## fitbig.quasi.Rout: fitbig.R quasi.R
.PRECIOUS: fitbig.%.Rout
fitbig.%.Rout: fitbig.R sgtf.props.rds %.rda
	$(pipeR)

## Tidy and coefplot
## tidybig.bin.Rout: tidybig.R
## tidybig.quasi.Rout: tidybig.R
.PRECIOUS: tidybig.%.Rout
tidybig.%.Rout: tidybig.R fitbig.%.rds
	$(pipeR)

## Simulate ensembles from resample parameters
## simbig.quasi.Rout: simbig.R 
## simbig.bin.rds: simbig.R
simbig.%.Rout: simbig.R fitbig.%.rds simDates.rda
	$(pipeR)

impmakeR += simsplot
## simsplot.quasi.Rout: simbigplot.R
simsplot.%.Rout: simbigplot.R simbig.%.rds sgtf.props.rds
	$(pipeR)

######################################################################

## ssfit (Preprint 1)

## Machinery (still rough and should be simplified)
bbmle_overdisp.Rout: bbmle_overdisp.R

test_overdisp.Rout: test_overdisp.R bbmle_overdisp.rda

betaformulation.Rout: betaformulation.R
	$(pipeR)

## Refactoring this into ssfitfuns
ssfit.Rout: ssfit.R sgtf.props.rds betasigma.rda
	$(pipeR)

ssprofile.Rout: ssprofile.R ssfit.rda
	$(pipeRcall)

sstidy.Rout: sstidy.R ssfit.rda
	$(pipeRcall)

## Unfinished!
sstidyPlots.Rout: sstidyPlots.R sstidy.rds
	$(pipeRcall)

## sssims.rds: sssims.R
sssims.Rout: basesims.R ssfit.rda simDates.rda
	$(pipeRcall)

sssimsplot.Rout: simbigplot.R sssims.rds sgtf.props.rds dataDates.rda
	$(pipeRcall)

######################################################################

## Parallel ssbin (could be DRY-ed later)

ssbin.Rout: ssbin.R sgtf.props.rds bbmle_overdisp.rda
	$(pipeR)

ssbinprofile.Rout: ssprofile.R ssbin.rda
	$(pipeRcall)

## Graphics code is hiding here; rescue someday
ssbintidy.Rout: sstidy.R ssbin.rda
	$(pipeRcall)

ssbinsims.Rout: basesims.R ssbin.rda simDates.rda
	$(pipeRcall)

ssbinsimsplot.Rout: simbigplot.R ssbinsims.rds sgtf.props.rds dataDates.rda
	$(pipeRcall)

## ssbinsimfake.rds: simfake.R
ssbinsimfake.Rout: simfake.R ssbinsims.rds sgtf.props.rds betaformulation.rda
	$(pipeRcall)

ssfake.props.rds: outputs/ssbinsimfake.rds
	$(copy)

######################################################################

## Table for 1210 preprint (products.md)

## ssalltidy.Rout.csv: ssalltidy.R
ssalltidy.Rout: ssalltidy.R sstidy.rds ssbintidy.rds
	$(pipeRcall)

######################################################################

## Back to sr pipeline
## Rename this stuff (or directorize)

## sr.props.Rout: props.R
sr.max.Rout: maxmodel.R sr.props.rds
	$(pipeR)

sr.max.check.Rout: checkfit.R sr.max.rds
	$(pipeR)

sr.good.Rout: goodmodel.R sr.props.rds
	$(pipeR)

sr.good.check.Rout: checkfit.R sr.good.rds
	$(pipeR)

## sr.props.Rout: props.R
## sgtf_%.Rout: sr_%.Rout
sr_gauteng.Rout: gpfilter.R sr.props.rds
	$(pipeR)

## Maybe this is superseded by ggpredict stuff
## gauteng_escPlot.Rout: escPlot.R sr_gauteng.rds
impmakeR += escPlot
%_escPlot.Rout: escPlot.R sr_%.rds
	$(pipeR)

## gauteng_mm.Rout: srp_mm.R sr_gauteng.rds
%_mm.Rout: srp_mm.R sr_%.rds
	$(pipeR)

## Rename to diagnosis or something
## gauteng_mm.dharma.Rout: dharma.R sr_gauteng.rds
%.dharma.Rout: dharma.R %.rds
	$(pipeR)

## Rename to diagnosis or something
## gauteng_mm.predict.Rout: predict.R sr_gauteng.rds
## gauteng_mm.predict.Rout: predict.R sr_gauteng.rds
%.predict.Rout: predict.R %.rds dataDates.rda simDates.rda
	$(pipeR)

gauteng.rplot.Rout: rplot.R gauteng_mm.predict.rds sr_gauteng.rds
	$(pipeR)

sr_glm.Rout: sr_glm.R sr_clean.rds

sr_profile.Rout: sr_profile.R sr_fit.rda

######################################################################

## A simple pipeline for faking sr data

sr.fake.Rout: bbinfake.R sr.props.rds betaformulation.rda
	$(pipeR)

## Select out the sucky provinces (using fit stuff below)
sr.currfake.Rout: currfake.R sr.fake.rds rpfits.rda
	$(pipeR)

## Look at sr-style data with gams
## sr.currfake.gamplot.Rout: gamplot.R
%.gamplot.Rout: gamplot.R %.rds
	$(pipeR)

######################################################################

## An ambitious pipeline for faking sr data
## To make a realistic challenge, we should fit the real data separately
## Didn't work, but we did do some good fitting stuff!

# separate fits to reinfection and primary data
rpfits.Rout: rpfits.R sr.props.rds ssbinfuns.rda
	$(pipeR)

## Refactoring 2021 Dec 11 (Sat)
## ssbinfuns.rda: ssbinfuns.R

######################################################################

## post-process omega proportions
impmakeR += props
%.props.Rout: props.R %.rds simDates.rda
	$(pipeR)

## Naive smoothed plots
impmakeR += pplots
%.pplots.Rout: pplots.R %.props.rds
	$(pipeR)

######################################################################
## Alternative version (name controls data stream instead of fit type)

## Fit a big model (embracing for now the quasi default)
impmakeR += fitq
%.fitq.Rout: fitbig.R quasi.rda %.props.rds
	$(pipeR)

## Tidy and coefplot
impmakeR += tidy
%.tidy.Rout: tidybig.R %.fitq.rds
	$(pipeR)

######################################################################

## Merging Lancet pcr with reinfection

phase.Rout: phase.R reinf.rds sgtf.tsv
	$(pipeR)

######################################################################

kappa.Rout: kappa.R
	$(pipeR)

######################################################################

## Experimental

## A short attempt to fit a glmm (doesn't accept quasi) 2021 Dec 07 (Tue)
glmm.Rout: glmm.R bin.rda sgtf.props.rds
	$(pipeR)

## quasify (so far just cribbed from Ben)
quasify.Rout: quasify.R

## Stan from Daniel
Sources += $(wildcard *.stan)
stanfit_newyork_basemodel.Rout: stanfit_newyork_basemodel.R basemodel.stan

##
ssstan.Rout: ssstan.R sslogist.stan


## 
constsim.Rout: constsim.R

######################################################################

## TMB example

Sources += $(wildcard *.cpp)
Ignore += $(wildcard *.o *.so)

tmb_fit.Rout: tmb_fit.R outputs/ssbinsimfake.rds logistic_fit.cpp tmb_funs.rda

tmb_eval.Rout: tmb_eval.R tmb_fit.rda outputs/ssbinsimfake.rds tmb_funs.rda

tmb_ci.Rout: tmb_ci.R tmb_fit.rda

tmb_ci_plot.Rout: tmb_ci_plot.R tmb_ci.rds

######################################################################

## TMB application (developing) 2021 Dec 12 (Sun)

tmb_look.Rout: tmb_look.R logistic_sim.rds

tmb_funs.Rout: tmb_funs.R

## Run once ever; supposed to make things faster
Ignore += precompile.out
precompile.out:
	sudo Rscript --vanilla -e "TMB::precompile()"
	touch $@

## This should also be run once and not piped -- only if you have a sudo installation of TMB
## When I tried precompile alone, it got very confused
## This is not tested 2021 Dec 13 (Mon) but matches something that seems to have worked
## You should be able to sudo make any .so after you do the precompile
Ignore += firstcompile.out
firstcompile.out: base = logistic_fit_fixedloc
firstcompile.out: precompile.out 
	touch $<
	echo sudo Rscript --vanilla -e "TMB::compile('$(base)')" && \
	echo sudo rm $(base).so $(base).o
	touch $@

## Compile a TMB model
Ignore += logistic_fit_fixedloc.so
logistic_fit_fixedloc.so: logistic_fit_fixedloc.cpp logistic_fit.h
	touch $<
	Rscript --vanilla -e "TMB::compile('$<')"

## Fit the SG with fixedloc
## ssfake.mmfit.Rout: mmfit.R
## sgtf.mmfit.Rout: mmfit.R
.PRECIOUS: %.mmfit.Rout
%.mmfit.Rout: mmfit.R %.props.rds tmb_funs.rda logistic_fit_fixedloc.so
	$(pipeR)

## ssfake.mmeval.Rout: mmeval.R
## sgtf.props.mmeval.Rout.pdf: mmeval.R
## sgtf.props.mmeval.Rout: mmeval.R
.PRECIOUS: %.mmeval.Rout
%.mmeval.Rout: mmeval.R %.mmfit.rda tmb_funs.rda logistic_fit_fixedloc.so
	$(pipeR)

ssfake.ssfit.Rout: ssfit.R sgtf.props.rds betaformulation.rda
%.ssfit.Rout: ssfit.R %.props.rds betatheta.rda
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

## -include makestuff/pipeR.mk

-include makestuff/git.mk
-include makestuff/visual.mk
-include makestuff/pipeR.mk

