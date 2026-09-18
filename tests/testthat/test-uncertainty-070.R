test_that("canonical interval types remain non-interchangeable", {
  x <- smf_uncertainty_semantics()
  expect_true(all(c("credible","posterior_predictive","bootstrap","conformal") %in% x$interval_type))
  expect_true(all(!x$interchangeable))
  a <- smf_uncertainty_descriptor("bayesian_posterior","parameter","credible",.95,"model and prior")
  b <- smf_uncertainty_descriptor("conformal","future_response","conformal",.95,"exchangeability")
  expect_false(identical(smf_uncertainty_label(a),smf_uncertainty_label(b)))
})

test_that("false uncertainty decomposition is blocked", {
  expect_error(smf_uncertainty_decompose(1,2,method="unknown",identified=FALSE),class="smf_validation_error")
})
