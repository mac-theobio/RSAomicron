
## Beta formulations
- `bs`: JD formulation σ = ab/(a+b)
- `bt`: Standard formulation θ = a + b
- Conceptually speaking, if bs and bt look about the same for p ~ 1/2, then we expect bs to have relatively larger "information" (thus narrower distributions) when p is far from 1/2. It would be good to do the calculation

# Data sets

## Input

* sgtf_ref
* bsfake (simulated using sigma formulation)
* btfake (simulated using theta formulation)

## Series types

sr/sg for the data differentiated/not by reinfection
* · ll/agg/ts for linelist/aggregated/aggregated-with-proportions(time series)

## Time points

* chop2 (take the last two days off of the data series)

# sensitivity/specificity mle2 analysis (needs to be re-combined)

## beta binomial paradigm

* bsfit or bsfit

## Parameter assumptions
* ssfix – fix logain and lodrop
* ssfitspec – fix logain
* ssfitboth – fix neither

## Special names (search forcelink in Makefile)

* main.sx.ts.rds is an alias for sgtf_ref.chop2.sx.ts.rds (our current main data set)

* bsfake and btfake (above) are also special names

## Fake data

## What_ever_!!
