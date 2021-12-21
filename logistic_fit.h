template<class Type>
Type baselogis(int tvec, Type loc, Type deltar, Type lodrop, Type logain, Type intercept) {
	Type drop = invlogit(lodrop);
	Type gain = invlogit(logain);
	Type ptrue = invlogit((tvec-loc)*deltar + intercept);
	return (ptrue*(1-gain) + (1-ptrue)*drop);
}

// compute baselogis entirely on the log scale
template<class Type>
Type baselogis_logprob(int tvec, Type loc, Type deltar, Type lodrop, Type logain) {
	// convert input parameters from logit (lo) to log scale (log_, )
	Type log_drop = -logspace_add(Type(0), -lodrop);
	Type log_gain = -logspace_add(Type(0), -logain);
	Type lotrue  = (tvec-loc)*deltar;
	Type log_true = -logspace_add(Type(0), -lotrue);
	return (logspace_add(
											 log_true +
											 logspace_sub(Type(0), log_gain),
											 logspace_sub(Type(0), log_true) +
											 log_drop));
}


template<class Type>
bool notFinite(Type x) {
  return (!R_FINITE(asDouble(x)));
}

template<class Type>
Type dbetabinom(Type y, Type a, Type b, Type n, int give_log=0)
{
	/*
	  Wikipedia:
	  f(k|n,\alpha,\beta) =
	  \frac{\Gamma(n+1)}{\Gamma(k+1)\Gamma(n-k+1)}
		\frac{\Gamma(k+\alpha)\Gamma(n-k+\beta)}{\Gamma(n+\alpha+\beta)}
		\frac{\Gamma(\alpha+\beta)}{\Gamma(\alpha)\Gamma(\beta)}
	*/
	Type logres =
		lgamma(n + 1) - lgamma(y + 1)     - lgamma(n - y + 1) +
		lgamma(y + a) + lgamma(n - y + b) - lgamma(n + a + b) +
		lgamma(a + b) - lgamma(a)         - lgamma(b) ;
	if(!give_log) return exp(logres);
	else return logres;
}

// OLD calculations to use a parameterization where dispersion parameter
//  is approximately proportional to beta precision or variance
// prob = a/(a+b) (= mean of Beta)
// sigma = (a+b)/(prob*(1-prob))
// = (a+b)^3/(a*b)
// (approx = precision of Beta (= (a+b)^2*(a+b+1)/(a*b)))
// sigma*prob*(1-prob) = a+b
// sigma*prob^2*(1-prob) = a
// sigma*prob*(1-prob)^2 = b

// logit(prob) (== eta) to log(prob)
// = -log(exp(0) + exp(-eta)) =  -logspace_add(Type(0), -eta);
template<class Type>
Type dbetabinom_theta(Type y, Type prob, Type theta, Type n, int give_log=0)
{
	Type x = theta; // (prob*(1-prob));
	Type a = x*prob;
	Type b = x*(1-prob);
	return dbetabinom(y, a, b, n, give_log);
}

namespace adaptive {
	template<class T>
	T logspace_gamma(const T &x) {
		/* Tradeoff: The smaller x the better approximation *but* the higher
		   risk of psigamma() overflow */
		if (x < -150)
			return -x;
		else
			return lgamma(exp(x));
	}
}
TMB_BIND_ATOMIC(logspace_gamma, 1, adaptive::logspace_gamma(x[0]))
template<class Type>
Type logspace_gamma(Type x) {
	CppAD::vector<Type> args(2); // Last index reserved for derivative order
	args[0] = x;
	args[1] = 0;
	return logspace_gamma(args)[0];
}

// dbetabinom parameterized in terms of log-shape1 and log-shape2
template<class Type>
Type dbetabinom_robust(Type y, Type loga, Type logb, Type n, int give_log=0)
{
	Type a = exp(loga), b = exp(logb);
	Type logy = log(y), lognmy = log(n - y); // May be -Inf
	Type logres =
		lgamma(n + 1) - lgamma(y + 1) - lgamma(n - y + 1) +
		logspace_gamma(logspace_add(logy, loga)) +
		logspace_gamma(logspace_add(lognmy, logb)) -
		lgamma(n + a + b) +
		lgamma(a + b) - logspace_gamma(loga) - logspace_gamma(logb);
	if(!give_log) return exp(logres);
	else return logres;
}

