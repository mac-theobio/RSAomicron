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

%.R: omike/%.R
	$(copy)

######################################################################

Sources += $(wildcard *.dict.tsv)

######################################################################

## Read summarize and code provinces
sgtf_ref.Rout: sgtf_ref.R data/sgtf_ref.rds prov.dict.tsv 

sr_clean.Rout: sr_clean.R sgtf_ref.rds
	$(pipeR)

sr.Rout: sr_agg.R sr_clean.rds dataDates.rda
	$(pipeR)

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
