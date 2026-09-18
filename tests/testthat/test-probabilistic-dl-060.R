test_that("Gaussian distributional head has constrained scale semantics", {
  h <- smf_dl_distributional_head("gaussian")
  expect_equal(h$constraints$sigma,"positive_softplus")
})

test_that("ensemble seeds must be distinct", {
  expect_error(smf_dl_ensemble(fits=list(1,2),seeds=c(1L,1L)),class="smf_validation_error")
})

test_that("uncertainty is not decomposed when components are unidentified", {
  d <- smf_prediction_distribution("samples",list(samples=matrix(rnorm(40),nrow=10)))
  expect_error(smf_dl_uncertainty_decompose(d),class="smf_validation_error")
})
