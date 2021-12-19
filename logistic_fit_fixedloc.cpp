// logistic fit with false positive/negative, dbetabinom/sigma param
#include <TMB.hpp>
#include "logistic_fit.h"

template<class Type>
Type objective_function<Type>::operator() ()
{
	
  DATA_FACTOR(province);
  DATA_IVECTOR(t);                // time
  DATA_INTEGER(nprov);            // num provinces: should compute from data?
  DATA_IVECTOR(dropouts);         // number of recorded SGTF dropouts
  DATA_IVECTOR(total_positives);  // number of confirmed cases
	DATA_INTEGER(debug);            // debugging flag
	
  PARAMETER_VECTOR(loc);          // midpoint of takeover curve (fixed effect)
  PARAMETER(deltar);              // takeover rate
  PARAMETER_VECTOR(b);            // random effects vector: {deltar} x nprov
  PARAMETER(lodrop);              // log-odds of false negative for SGTF (universal)
  PARAMETER(logain);              // log-odds of false positive for SGTF (universal)
  PARAMETER(log_theta);           // log of theta (Beta dispersion parameter)
  PARAMETER_VECTOR(log_sd);       // SDs of {loc, deltar} REs
  // PARAMETER_VECTOR(corr);         // correlation among SDs (unused now since only 1 RE per block)

  int nobs = dropouts.size();
  // int blocksize = 2; // two parameters per province (unused)
	Type nll;
  Type res = 0;

	if (debug>0) std::cout << "before RE computations\n";

  // black magic inherited from glmmTMB

  // convert RE vector into an array
  // vector<int> dim(2);
  // dim << blocksize, nprov;
  // array<Type> bseg(b, dim);
  // vector<Type> sd = exp(log_sd);
	// // compute RE component of likelihood
  // density::UNSTRUCTURED_CORR_t<Type> nldens(corr);
  // density::VECSCALE_t<density::UNSTRUCTURED_CORR_t<Type> > scnldens = density::VECSCALE(nldens, sd);
  // for(int i = 0; i < nprov; i++) {
	//   res -= scnldens(bseg.col(i));
	// 	SIMULATE {
	// 		bseg.col(i) = sd * nldens.simulate();
	// 	}
	// }

	// random effect term for deltar (b is spherical/unscaled/standard-Normal)
	for (int i=0; i<nprov; i++) {
		res -= dnorm(b(i), Type(0), Type(1), true);
	}

	if (debug>0) std::cout << "after RE computations\n";

	vector<Type> prob(nobs);
	Type s1, s2, s3;

  for(int i = 0; i < nobs; i++) {
		int j = province(i);
		prob(i) = baselogis(t(i),
												// deltar includes province-specific REs
												loc(j),
												// log_sd is a vector, but we only want the first element!
												deltar + exp(log_sd(0))*b(j),
												lodrop, logain);
		// FIXME: revert to binomial when theta → ∞ (i.e. over a threshold) ?
		if (notFinite(log_theta)) {
			// binomial (log_theta must use `map=` in MakeADFun ...
			nll = -1*dbinom(Type(dropouts(i)), Type(total_positives(i)), prob(i), true);
		} else {
			// beta-binomial

			nll = -1*dbetabinom_theta(Type(dropouts(i)), prob(i), exp(log_theta), Type(total_positives(i)), true);
		}
		// copied from glmmTMB: not yet ...
		// s3 = logit_inverse_linkfun(eta(i), link); // logit(p)
		// s1 = log_inverse_linkfun( s3, logit_link) + log(phi(i)); // s1 = log(mu*phi)
		// s2 = log_inverse_linkfun(-s3, logit_link) + log(phi(i)); // s2 = log((1-mu)*phi)
		// tmp_loglik = glmmtmb::dbetabinom_robust(yobs(i), s1, s2, size(i), true);
		// SIMULATE {
		//   yobs(i) = rbinom(size(i), rbeta(exp(s1), exp(s2)) );
		// }

		res += nll;
		if (debug > 5) {
			std::cout << i << " " << prob(i) << " " << dropouts(i) << " " <<
				total_positives(i) << " " << nll << " " << res << "\n";
		}
  }


	
	REPORT(prob);
	// sdreport() will actually have both value and sd
	// report log-odds of prob so we can get (Wald) CIs on the logit scale
	vector<Type> loprob = logit(prob);

	ADREPORT(loprob);

	if (debug > 1) std::cout << res << "\n";
	
	return res;
}