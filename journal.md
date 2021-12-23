
We need to decide on a final cut date and data set for preprint 2.

On the SG side, I've done some of the archaeology about old fits, and I'm not that worried. It is hard to compare the current tmb fits to analogous mle fits, because the older fits were done by fitting specificity only – when we fit both sensitivity and specificity we don't get a lot of confidence intervals. Actually, maybe I should be worried after poking around a bit with Mike. Maybe Carl can help figure out what happened in the past.

Li: I went back to omike and figured out what we did with Carl and I was able to replicate it. We did not use ssbetabinomial for P1. We used ssbin. To recreate, make ssbin.Rout, ssbintidy.Rout, and ssbinsimplot.Rout 


We need to decide whether to consider using the non-standard beta binomial parameterization, and if we consider it, we need to decide the criteria that will use to pick between it and the standard parameterization.

On the SR side, we additionally need to decide about whether to add a random effect for province by date.

