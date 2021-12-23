
2021 Dec 22 (Wed)
=================

We need to decide on a final cut date and data set for preprint 2.

On the SG side, I've done some of the archaeology about old fits, and I'm not that worried. It is hard to compare the current tmb fits to analogous mle fits, because the older fits were done by fitting specificity only – when we fit both sensitivity and specificity we don't get a lot of confidence intervals. Actually, maybe I should be worried after poking around a bit with Mike. Maybe Carl can help figure out what happened in the past.

Li: I went back to omike and figured out what we did with Carl and I was able to replicate it. We did not use ssbetabinomial for P1. We used ssbin. To recreate, make ssbin.Rout, ssbintidy.Rout, and ssbinsimplot.Rout 

We need to decide whether to consider using the non-standard beta binomial parameterization, and if we consider it, we need to decide the criteria that will use to pick between it and the standard parameterization.

On the SR side, we additionally need to decide about whether to add a random effect for province by date.

2021 Dec 23 (Thu)
=================

Oops. Possibly more important: we need to decide about a random effect (by province) for the reinfection coefficient itself.

We're not currently worried about reinfection denominators because our model asks about the effect of reinfection status on omicron/delta.

Do we need two Dropboxes? What is the starting data for what?

## Meeting

Data and pipeline
* Carl will work to help the Canadians use his repo

We are not immediately throwing out either beta formulation
* Maybe do an AIC comparison
* Maybe postpone?

What about the ensembles?
* Early ensembles use just binomial 
* If we switch to beta-binomial we should use whatever formulation we've decided to use
* postpone

Random effects
* Current model: sgtf ~ time + prov + (0 + time|prov) + reinf
* Maximal model: . + (1|prov:timef) + (0 + reinf|prov)
   * (available: ??)
* Extra intermediate: replace timef with a spline

Data selection

Ahead by a fixed time is equivalent to ahead by a fixed amount on this scale

## BMB

- what is the (biological) meaning of (omicron ~ reinf + time + (0 + prov|time)) ? Should reinf interact with time, and what would that mean anyway?  What causes variation in the 'reinf' effect, and how likely is it to vary across provinces? (e.g. is it virological or immunological or epidemiological?)

* JD: Somewhat confused. The main thing that might cause reinf to vary would be the observation processes underlying who is observed as "reinf". My fixed-effect for prov is sort of short hand for the fixed temporal "location" parameters that go by province. I am not sure in your question whether you changed time|prov to prov|time on purpose and thus not sure how to interpret your question

## Stats journal

We are ready to compare the two parameterizations on the SG side. Do we have a criterion for what we will do if they are similar? We do not.
