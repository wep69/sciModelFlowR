test_that("RMSE and MAE agree with direct calculations", {
  y <- c(1,2,3,4); p <- c(1.1,1.8,3.2,3.9)
  x <- smf_evaluate(y,p,list(smf_metric_spec("rmse"),smf_metric_spec("mae")))
  expect_equal(x$value[x$metric=="rmse"],sqrt(mean((y-p)^2)))
  expect_equal(x$value[x$metric=="mae"],mean(abs(y-p)))
})
