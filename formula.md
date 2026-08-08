y_i \sim \rm{Distr}(p_i,n_i,d)
\\

\rm{logit}(p_i) = \alpha_i + (\beta + \rho) + (\tau + \nu) 

\\
\alpha_i \sim \rm{N}(loc_i,\sigma_{\alpha;i}^2)

\\
\beta \sim \rm{N}(log(deltar),\sigma_\beta^2)

\\
\rho \sim \rm{N}(sd(log(deltar)),\sigma_\rho^2)

\\
\tau \sim \rm{N}(reinf,\sigma_\tau^2)

\\
\nu \sim \rm{N}(sd(reinf),\sigma_\nu^2)
