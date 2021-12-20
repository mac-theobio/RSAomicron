library(shellpipes)

## Logistic function with imperfect testing
baselogis <- function(tvec, loc, delta_r, lodrop, logain){
    drop <- plogis(lodrop)
    gain <- plogis(logain)

    ptrue <- plogis((tvec-loc)*delta_r)
    return(ptrue*(1-gain) + (1-ptrue)*drop)
}

## copied from R internals
logspace_add <- function(logx,logy) {
    pmax(logx,logy) + log1p(exp(-abs(logx - logy)))
}

R_Log1_Exp <- function(x) {
    ifelse (x > -log(2), log(-expm1(x)),  log1p(-exp(x)))
}
logspace_sub <- function(logx,logy) {
    logx + R_Log1_Exp(logy - logx)
}

stopifnot(all.equal(logspace_add(-3, -2),
                    log(exp(-3) + exp(-2))))
## check vectorization
x <- -3:0
y <-  2:-1
stopifnot(all.equal(logspace_add(x, y),
                    log(exp(x) + exp(y))))

stopifnot(all.equal(logspace_sub(-2, -3),
                    log(exp(-2) - exp(-3))))

## TODO: Rcpp wrappers to call Rf_logspace_add, Rf_logspace_sub ?

baselogis_logprob <- function(tvec, loc, deltar, lodrop, logain) {
    ## convert input parameters directly from logit (lo) to log scale (log_, )
    ##   -logspace_add(0, -lo)
    ## = -log(exp(0) + exp(-lo))
    ## =  log(1/(exp(0) + exp(-lo)))
    ## =  log(1/(1 + exp(-lo)))
    ## =  log(plogis(lo))
    log_drop <- -logspace_add(0, -lodrop)
    log_gain <- -logspace_add(0, -logain)
    lotrue  <- (tvec-loc)*deltar
    log_true <- -logspace_add(0, -lotrue);
    return (logspace_add(
        log_true + logspace_sub(0, log_gain),
        logspace_sub(0, log_true) + log_drop)
        )
}


tvec <- 0:50
loc <- 25
deltar <- 0.2
lodrop <- -3
logain <- -3

stopifnot(all.equal(
    baselogis(tvec, loc, deltar, lodrop, logain),
    exp(baselogis_logprob(tvec, loc, deltar, lodrop, logain))))

saveEnvironment()
