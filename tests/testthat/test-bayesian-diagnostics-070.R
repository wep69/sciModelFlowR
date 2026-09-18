test_that("pathological MCMC diagnostics become structured warnings", {
  sm <- data.frame(variable=c("a","b"),rhat=c(1.12,1.00),ess_bulk=c(55,1200),ess_tail=c(80,1100))
  w <- smf_bayes_diagnostic_flags(sm,divergences=3L,rhat_max=1.01,min_ess=400L)
  codes <- vapply(w,function(x)x@code,character(1))
  expect_true(all(c("MCMC_RHAT_HIGH","MCMC_ESS_LOW","MCMC_DIVERGENCES") %in% codes))
  expect_equal(w[[which(codes=="MCMC_DIVERGENCES")]]@severity,"blocking")
})

test_that("Bayesian approximation method is explicit", {
  d <- smf_load_dataset("gold_bayesian_linear")
  fit <- smf_bayes_fit(y ~ x1 + x2,d[1:100,],backend="conjugate_gaussian")
  expect_equal(fit@approximation,"exact_conjugate_posterior")
  expect_equal(fit@provenance$inference,"closed_form")
})
