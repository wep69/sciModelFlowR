test_that("GP native adapter separates latent and noise variance", {
  d <- smf_load_dataset("gold_bayesian_linear")
  fit <- smf_gp_fit(d[1:120,c("x1","x2")],d$y[1:120],length_scale=1,noise_variance=0.64,optimize=FALSE)
  pr <- smf_gp_predict(fit,d[121:130,c("x1","x2")])
  expect_true(isTRUE(pr@payload$identified))
  dec <- smf_uncertainty_from_distribution(pr)
  expect_true(dec@identified)
  expect_equal(dec@total,dec@aleatoric+dec@epistemic,tolerance=1e-8)
})

test_that("optional Bayesian backends are explicit capabilities", {
  caps <- smf_capabilities()
  expect_true(all(c("brms","dbarts","DiceKriging") %in% names(caps)))
  expect_true(caps$brms$capabilities@posterior_sampling)
})
