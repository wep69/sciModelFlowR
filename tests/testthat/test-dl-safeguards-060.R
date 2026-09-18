test_that("final test data cannot drive neural development validation", {
  expect_error(sciModelFlowR:::.smf_dl_validation_role("final_test"), class="smf_leakage_error")
  expect_error(sciModelFlowR:::.smf_dl_validation_role("external_test"), class="smf_leakage_error")
  expect_equal(sciModelFlowR:::.smf_dl_validation_role("analysis_validation"),"analysis_validation")
})

test_that("mixed16 is not silently enabled on CPU", {
  expect_error(smf_dl_mixed_precision("mixed16","cpu"), class="smf_error")
})
