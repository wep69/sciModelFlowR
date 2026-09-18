test_that("0.3.0 specifications construct and serialize", {
  cal <- smf_calibration_spec("isotonic", calibration_prop=.2, bins=8)
  imb <- smf_imbalance_spec("weights", threshold=.4)
  pr <- smf_probabilistic_spec(distribution="categorical", scores=c("log_loss","brier"))
  rep <- smf_reporting_spec()
  expect_true(S7::S7_inherits(cal, sciModelFlowR:::CalibrationSpec))
  expect_true(S7::S7_inherits(imb, sciModelFlowR:::ImbalanceSpec))
  expect_true(S7::S7_inherits(rep, sciModelFlowR:::ReportingSpec))
  expect_identical(smf_hash(cal), smf_hash(smf_from_json(smf_to_json(cal))))
  expect_identical(smf_hash(imb), smf_hash(smf_from_json(smf_to_json(imb))))
  expect_equal(pr@distribution,"categorical")
})

test_that("probabilistic quantiles are validated", {
  expect_error(smf_probabilistic_spec(quantiles=c(0,.5,.9)))
  expect_error(smf_calibration_spec("platt", calibration_prop=.8))
  expect_error(smf_imbalance_spec("weights", threshold=1))
})
