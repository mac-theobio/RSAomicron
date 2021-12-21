

## Beta formulations
- `bs`: JD formulation σ = ab/(a+b)
- `bt`: Standard formulation θ = a + b

# Data sets

## Input

* sgtf_ref
* bsfake (simulated using sigma formulation)
* btfake (simulated using theta formulation)

## Series types

sr/sg for the data differentiated/not by reinfection
* · ll/ts for linelist or aggregated time series
* Concatenation here might be a mistake; better to say .sg.ts. I think.

## Time points

* chop2 (take the last two days off of the data series)

# sensitivity/specificity mle2 analysis (needs to be re-combined)

## beta binomial paradigm

* bsfit or bsfit

## Parameter assumptions
* ssfix – fix logain and lodrop
* ssfitspec – fix logain
* ssfitboth – fix neither

## Targets (in flux) ⇒ 

* ssmle2
