test_that("0.6 Gold fixtures preserve generator truth", {
  d <- smf_load_dataset("gold_dl_nonlinear")
  expect_equal(nrow(d),480L)
  expect_true(all(d$sigma_truth > 0))
  expect_gt(cor(d$y,d$mu_truth),0.8)
  s <- smf_load_dataset("gold_dl_sequence")
  expect_equal(nrow(s),160L)
  expect_equal(sum(grepl("^t[0-9]{2}$",names(s))),24L)
})
