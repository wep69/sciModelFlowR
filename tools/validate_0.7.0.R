# sciModelFlowR 0.7.0 runtime validation entry point.
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "0.7.0")
library(sciModelFlowR)

gold <- smf_run_gold_validation()
stopifnot(all(gold$passed))

# Package-native Bayesian reference.
d <- smf_load_dataset("gold_bayesian_linear")
bs <- smf_bayesian_spec(priors=list(beta_mean=c(0,0,0),beta_sd=c(10,10,10),sigma_shape=2,sigma_rate=1),draws=4000L,seed=260917L)
bf <- smf_bayes_fit(y ~ x1 + x2,d,bayesian=bs,backend="conjugate_gaussian")
bsum <- smf_bayes_summary(bf)
stopifnot(abs(bsum$mean[bsum$variable=="(Intercept)"]-1.5) < 0.20)
stopifnot(abs(bsum$mean[bsum$variable=="x1"]-2.0) < 0.15)
stopifnot(abs(bsum$mean[bsum$variable=="x2"]+1.0) < 0.15)
stopifnot(abs(bsum$mean[bsum$variable=="sigma"]-0.8) < 0.10)

# Structured MCMC pathology flags can be checked without compiling Stan.
path <- data.frame(variable=c("a","b"),rhat=c(1.12,1.00),ess_bulk=c(80,1000),ess_tail=c(90,900))
codes <- vapply(smf_bayes_diagnostic_flags(path,divergences=2L),function(x)x@code,character(1))
stopifnot(all(c("MCMC_RHAT_HIGH","MCMC_ESS_LOW","MCMC_DIVERGENCES") %in% codes))

# Split conformal on untouched final test.
cg <- smf_load_dataset("gold_conformal_regression")
tr <- subset(cg,partition=="train"); ca <- subset(cg,partition=="calibration"); te <- subset(cg,partition=="test")
lm0 <- stats::lm(y ~ x1 + x2,data=tr)
cf <- smf_conformal_fit(ca$y,stats::predict(lm0,ca),smf_conformal_spec("split",level=.90),calibration_ids=ca$row_id,final_test_ids=te$row_id)
ci <- smf_conformal_predict(cf,stats::predict(lm0,te))
cov <- smf_conformal_coverage(te$y,ci)
stopifnot(cov$coverage > .86, cov$coverage < .94)

# GP uncertainty decomposition.
gp <- smf_gp_fit(d[1:160,c("x1","x2")],d$y[1:160],noise_variance=.64,optimize=FALSE)
gpp <- smf_gp_predict(gp,d[161:180,c("x1","x2")])
gpd <- smf_uncertainty_from_distribution(gpp)
stopifnot(isTRUE(gpd@identified),max(abs(gpd@total-gpd@aleatoric-gpd@epistemic)) < 1e-8)

# Optional brms/loo smoke tests are executed only when dependencies are available.
if (requireNamespace("brms",quietly=TRUE) && requireNamespace("posterior",quietly=TRUE)) {
  small <- d[1:80,]
  sb <- smf_bayesian_spec(priors=list(),chains=2L,draws=250L,warmup=250L,target_accept=.9,seed=260917L)
  fb <- smf_bayes_fit(y ~ x1 + x2,small,bayesian=sb,backend="brms",refresh=0)
  stopifnot(S7::S7_inherits(fb,sciModelFlowR:::BayesFitResult))
  diag <- smf_bayes_diagnose(fb)
  stopifnot(S7::S7_inherits(diag,sciModelFlowR:::BayesianDiagnosticResult))
  if (requireNamespace("loo",quietly=TRUE)) invisible(smf_bayes_loo(fb))
}

message("sciModelFlowR 0.7.0 runtime validation script completed.")
