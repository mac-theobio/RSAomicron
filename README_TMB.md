## Notes on TMB implementation

- `logistic.cpp`: basic fitting machinery; includes reinfection, but reinfection term can be mapped to 0
- `logistic_fit.h`: utilities (dbetabinom parameterizations, logistic-with-error function, etc.)
- `tmb_funs.R`: utilities (TMB methods, general pipeline utils); includes shells for constructing & fitting the models
- `sgtmb.R`: fit TMB models (**misnamed**: does both w/o and with reinfection)
- `sgtmb_eval.R`: basic downstream machinery: predictions, some CIs, etc.

### older/incomplete

- `tmb_fit.R`/`tmb_eval.R`: parallel to `sgtmb*` above, but less piped
- `tmb_ci.R`: comparative CIs for parameters (Wald, uniroot, profile): slow
- `gen_funs.R`: more utility functions (not TMB-specific; currently unused)

## Description

* Fits a likelihood model to testing data
* Parameters/priors: 
   - `loc`: midpoint of omicron takeover curve (per-province fixed effect)
   - `log_deltar`: selective advantage of omicron (base + province-level RE; log SD gives a prior range of SD (log-advantage) from 0.01 to 0.3, i.e. a 1% to 30% variation in deltar across provinces)
   - `logsd_logdeltar`: log of cross-province SD of log_deltar
   - `prior_logsd_logdeltar`: vector of mean, SD of prior
   - `lodrop`: log-odds of false negative SGTF (i.e. omicron w/o SGTF)
   - `logain`: log-odds of false positive SGTF (i.e. non-omicron w/ SGTF)
   - `log_theta`: log of size parameter for beta-binomial sampling error
   - `beta_reinf`: log-odds difference of SGTF probability for reinfections
- stores info on predicted probabilities, estimated deltar by province (in addition to coefficient estimates etc.)
- basic functions (see roxygen comments in `tmb_funs.R`)
   - `fit_tmb(data, ...)`: basic model fitting. Returned objects have class `c("logistfit", "TMB")`
   - ∃ TMB methods: `coef()`, `vcov()`, `logLik()`, `tidy()`, (in `broom.mixed` pkg)
   - ∃ logistfit methods: `predict()` (prediction, expanding prov × time)
   - TMB built-in functions: `fit$report()`, `TMB::sdreport(fit)`
   - `get_tmb_file(fit)`, `get_prov_names(fit)`, `get_data(fit)` retrieve carried-along info

## Random effects

- at the 'observation' level (i.e. province × day), beta-binomial error and observation-level RE on the logit scale is approximately equivalent. B-B is probably slightly more robust (by analogy with lots of conversations about Gamma vs log-normal in count models, also something by Harrison [PeerJ?]). Logit-gaussian is better for transition to more sophisticated stuff like random-walk or autocorrelated noise ...
- random effects of `deltar` across province make perfect sense
- random effects of `beta_reinf`? (What is the biology?) Should they be correlated with the deltar effects?

## Current status

- reasonable SG-only fits (no reinfection) to fake & real data, although questions remain about the details of the real-data fits [DIAGNOSTICS???]
- fits with reinfection on fake data pass basic sanity checks

## Issues/to-do

### high priority

- explore current results more
- explore `tmb_ci.Rout` results (still a bit wonky?)
- comparing fixed vs random vs pooled values. Ideally this could be done by fixing `log_sd` to a small (pooled) or large (fixed) value, but ??? I was previously getting a lot of inner-loop optimization problems when `log_sd` was large. Maybe gone now, maybe interacting with other issues

### cosmetic/cleanup

- better incorporation into Make-style pipeline?

### medium

- importance sampling? `tmbstan`? (will need more priors?)
   - works, sort of, but we probably need priors on deltar, lodrop, logain to keep out of trouble
- write (unit) tests!
- machinery for automatic binom/beta-binom switching/robust fitting
- `SIMULATE` methods
- making loc a fixed effect seemed necessary to get workable answers: can we relax this?
- adjustable beta-binomial parameterizations? Do we really need this?
- log-scale/robust machinery
- alternatively try using standard mixed model (also good for comparison of effects of allowing for drop/gain)
- try on an *ensemble* of fake data??
- get `tmbstan` working (and/or translate to Stan??)
   - get priors for lodrop, logain, log_deltar, ...

### low

- break up `tmb_funs.R` ?
- list of required packages/versions
- see if we can skip binom fit as a preliminary stage
- re-introduce possibility of loc random effect (without making code unreadable)???
- include random effect of date? (alternative to beta-binomial ...) Stepping stone to an autocorrelated random effect
- power exponential priors as in WNV project?
- *Way* premature, but could parallelize some of the computations, both at the CI stage (via parapply) and internally (OpenMP)
 
