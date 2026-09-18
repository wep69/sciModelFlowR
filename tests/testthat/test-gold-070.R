test_that("version 0.7 Gold fixtures are frozen", {
  expect_true(all(c("gold_bayesian_linear","gold_conformal_regression") %in% smf_list_datasets()))
  b <- smf_load_dataset("gold_bayesian_linear")
  c <- smf_load_dataset("gold_conformal_regression")
  expect_equal(nrow(b),600)
  expect_equal(table(c$partition),c(calibration=500,test=1200,train=500))
})
