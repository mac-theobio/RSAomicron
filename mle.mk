
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

## Tidy (Confidence-interval machine)
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
