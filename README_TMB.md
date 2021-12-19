## Notes on TMB implementation

- `logistic_fit_fixedloc.cpp`: 
- `logistic_fit.h`: utilities 
- RE fit working

## Current status

## Issues/to-do

- switches for fixed vs random vs pooled values. Ideally this could be done by fixing `log_sd` to a small (pooled) or large (fixed) value, but ??? I was previously getting a lot of inner-loop optimization problems when `log_sd` was large. Maybe gone now, maybe interacting with other issues
- `SIMULATE` methods
- bad lodrop/logain predictions; hard to tell at the moment
- adjustable beta-binomial parameterizations? Do we really need this?
- log-scale/robust machinery
- work up a similar thing for the re-infection data
- used binom fit as a preliminary stage (seems OK/harmless, might be unnecessary with additional regularization/robustification)
- could also/alternatively try using standard mixed model (also good for comparison of effects of allowing for drop/gain)
- right now lodrop is converging to a very small value (Wald CIs are ridiculous); is this right?
- making loc a fixed effect seemed necessary to get workable answers
- also had to put an upper bound on beta-binom precision parameter
- try on an *ensemble* of fake data??
- set up priors/flag for priors?
- get `tmbstan` working (and/or translate to Stan??)

## to do (lower priority)

- DRY; combine logistic_fit_fixed.cpp and logistic_fit.cpp (without making code unreadable)???
- robustify beta-binomial machinery, especially for high precision?
- more computation on log scale, robustness (can't clamp away from zero quite as easily as in R)
- include random effect of date? (alternative to beta-binomial ...) Stepping stone to an autocorrelated random effect
- try to compute `nprov` (number of provinces) internally rather than passing via data?
	
- *Way* premature, but could parallelize some of the computations ...
