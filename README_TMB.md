## Notes on TMB implementation

- `logistic.cpp`: basic fitting machinery; includes reinfection, but reinfection term can be mapped to 0
- `logistic_fit.h`: utilities (dbetabinom parameterizations, logistic-with-error function, etc.)
- `tmb_funs.R`: utilities (TMB methods, general pipeline utils); includes shells for constructing & fitting the models
- `tmb_fit.R`: fit TMB models
- `tmb_eval.R`: basic downstream machinery: predictions, some CIs, etc.
- `tmb_ci.R`: comparative CIs for parameters (Wald, uniroot, profile): slow (5-6 minutes)
- `tmb_ci_plot.R`: comparison plots from previous step

### incomplete

- `gen_funs.R`: more utility functions (not TMB-specific; currently unused)

## Description

- Fits a likelihood model to testing data
- Parameters/priors: 
   - `loc`: midpoint of omicron takeover curve (per-province fixed effect)
   - `log_deltar`: selective advantage of omicron (base + province-level RE; log SD gives a prior range of SD (log-advantage) from 0.01 to 0.3, i.e. a 1% to 30% variation in deltar across provinces)
   - `logsd_logdeltar`: log of cross-province SD of log_deltar
   - `prior_logsd_logdeltar`: vector of mean, SD of prior
   - `lodrop`: log-odds of false negative SGTF (i.e. omicron w/o SGTF)
   - `logain`: log-odds of false positive SGTF (i.e. non-omicron w/ SGTF)
   - `log_theta`: log of size parameter for beta-binomial sampling error
   - `beta_reinf`: log-odds difference of SGTF probability for reinfections
- flags/scalar data:
   - `perfect_tests` (logical): assume perfect sens/specificity for SGTF == omicron?
- stores info on predicted probabilities, estimated deltar by province (in addition to coefficient estimates etc.)
- basic functions (see roxygen comments in `tmb_funs.R`)
   - `fit_tmb(data, ...)`: basic model fitting. Returned objects have class `c("logistfit", "TMB")`
   - ∃ TMB methods: `coef()`, `vcov()`, `logLik()`, `tidy()`, (in `broom.mixed` pkg)
   - ∃ logistfit methods: `predict()` (prediction, expanding prov × time, with or without CIs), `simulate()`
   - TMB built-in functions: `fit$report()`, `TMB::sdreport(fit)`
   - `get_tmb_file(fit)`, `get_prov_names(fit)`, `get_data(fit)` retrieve carried-along info
   - `get_deltar` gets the province-level values of deltar *and* the population-level estimate (`filter` it out if you don't want it ...)

## Perfect testing

- in principle we could simply pass through `-Inf` for `lodrop` and `logain` if we wanted to simulate perfect testing. That causes problems with `sdreport()` though. Instead I have implemented a `perfect_testing` flag that skips the sensitivity/specificity stuff and calls `invlogit()` directly. (I realized later that we don't necessarily need to call `sdreport()` in the current workflow (we are only saving predictions, not CIs/sds, when we generate ensembles), so this might have been unnecessary.)

## Random effects

- at the 'observation' level (i.e. province × day), beta-binomial error and observation-level RE on the logit scale is approximately equivalent. B-B is probably slightly more robust (by analogy with lots of conversations about Gamma vs log-normal in count models, also Harrison 2015 https://peerj.com/articles/1114). Logit-gaussian is better for transition to more sophisticated stuff like random-walk or autocorrelated noise ...
    - JD comments that when we're doing reinfection, there are two observations per day (reinf/no reinf), so we could add another level of random effects
	- does it make more sense to make everything Gaussian (on the appropriate scale) once we have multiple hierarchical scales?
	- could compare goodness-of-fit of logit-Gaussian vs beta-binomial (different parameterizations ...)
- random effects of `deltar` across province make perfect sense
- random effects of `beta_reinf`? (What is the biology?) Should they be correlated with the deltar effects?
- this will all be enough of a nuisance that we should think carefully about what we want/how much it matters before jumping in

## Current status

- reasonable SG-only fits (no reinfection) to fake & real data, although questions remain about the details of the real-data fits [DIAGNOSTICS???]
- fits with reinfection on fake data pass basic sanity checks
- `tmb_ci_plot.Rout.pdf` results look fine for fake data (pipe to real data): uniroot and profile are approximately equally slow (? would expect uniroot to be a bit faster ?), nearly identical (as expected), only differ much from Wald for a few parameters

## Issues/to-do

### high priority

- why are some (but not all) reinf-RE CIs wonky?
- why are Wald/delta-method CIs for EC (with btfake) wonky?
- tmb_fit switch to turn off reinf REs?
- document `tmb_compare.R` (fixed vs pooled vs RE)
- outputs for province-specific beta-reinf values (parallel to deltar)

### cosmetic/cleanup

- fix parameter ordering in predict_logistfit to avoid warnings/messages
- unify shape handling for betabinomial
- improve print method for logistfit objects? (named coeffs, etc.)?
- `get_deltar` method for newparams, w/ and w/o CIs ? (parallel to predict method). Or flag for predict.logistfit?
- refactor predict.logistfit?
- make sure predictions (when confint = TRUE) are arranged by time (after completion/removal of orig data - why is this happening?)

### medium

- explore reinf fits
- importance sampling? 
- `tmbstan`? (will need more priors?)
   - works, sort of, but we probably need priors on deltar, lodrop, logain to keep out of trouble
- write (unit) tests!
- machinery for automatic binom/beta-binom switching/robust fitting
- making loc a fixed effect seemed necessary to get workable answers: can we relax this?
- log-scale/robust machinery
- alternatively try using standard mixed model (also good for comparison of effects of allowing for drop/gain)
- try on an *ensemble* of fake data??

### low

- break up `tmb_funs.R` ? (methods, fitting, etc.)
- list of required packages/versions
- see if we can skip binom fit as a preliminary stage (`two_stage = FALSE`)
- re-introduce possibility of loc random effect (without making code unreadable)???
- power exponential priors as in WNV project?
- *Way* premature, but could parallelize some more of the computations (internally via OpenMP, or by furrr::future_map*?)
 
----

## on using TMB for predictions

- Advantages of using TMB for prediction:
   - unified code base (i.e., the same implementation is used to fit the model as to run the model). Makes for fewer points of failure/easier to keep models in sync
   - allows delta-method computations of any derived quantities desired
- Disadvantages of using TMB for prediction:
   - implementation is more complicated (see below)
   - if we have to use `MakeADFun()` repeatedly, slow (e.g. for ensembles)
   
*Explanation*: we can use `fit$report()` or `sdreport(fit)` to run through the code once and report any values defined inside a `REPORT()` or `SDREPORT()` macro, respectively. 
