## Notes on TMB implementation

- `logistic_fit_fixedloc.cpp`: basic fitting machinery
     - name change to `sg.cpp` ?
- `logistic_fit.h`: utilities (dbetabinom parameterizations, logistic-with-error function, etc.)
- `tmb_funs.R`: utilities (TMB methods, general pipeline utils)
- `tmb_fit.R`: construct TMB models, parameters, fit (currently only to fake data)
- `tmb_eval.R`: basic downstream machinery: predictions, some CIs, etc.
- `tmb_ci.R`: comparative CIs for parameters (Wald, uniroot, profile): slow!
- `gen_funs.R`: more utility functions (not TMB-specific)

## Current status

- fits current fake (`btfake.sgts.rds`) data OK (both `logain` and `lodrop` estimates are small but reasonable, around -4), with some issues:
   - `log_sd` of delta-r is small (-4), its SD cannot be recovered
   - cov matrix is non-pos-def even once we exclude `log_sd`
- `tmb_CI.R` currently failing

## Issues/to-do

### high priority

- explore reasons for difficulty in estimating log-sd. Profile; regularize/prior?
- (profile looks like log-sd should be going to zero. Is this just where start running into numerical trouble?)
- what's a reasonable prior for delta-r? if we put it on the log-scale (seems reasonable), then a range of (say) 1% to 30% difference across provinces seems reasonable ... ?
- trouble-shoot `tmb_CI.R`
- set up `sr.cpp` (i.e., add reinfection to data and model)

### cosmetic/cleanup

- move province-name-fixing machinery (i.e. disambiguating `loc` parameters) upstream
- report delta-r at the provincial level

### medium

- machinery for automatic binom/beta-binom switching/robust fitting
- `SIMULATE` methods
- switches for fixed vs random vs pooled values. Ideally this could be done by fixing `log_sd` to a small (pooled) or large (fixed) value, but ??? I was previously getting a lot of inner-loop optimization problems when `log_sd` was large. Maybe gone now, maybe interacting with other issues
    - making loc a fixed effect seemed necessary to get workable answers: can we relax this?
- adjustable beta-binomial parameterizations? Do we really need this?
- log-scale/robust machinery
- work up a similar thing for the re-infection data
- alternatively try using standard mixed model (also good for comparison of effects of allowing for drop/gain)
- also had to put an upper bound on beta-binom precision parameter
- try on an *ensemble* of fake data??
- set up priors/flag for priors?
- get `tmbstan` working (and/or translate to Stan??)

### low

- see if we can skip binom fit as a preliminary stage
- DRY; combine logistic_fit_fixed.cpp and logistic_fit.cpp (without making code unreadable)???
- include random effect of date? (alternative to beta-binomial ...) Stepping stone to an autocorrelated random effect
- try to compute `nprov` (number of provinces) internally rather than passing via data?
- *Way* premature, but could parallelize some of the computations, both at the CI stage (via parapply) and internally (OpenMP)
 
