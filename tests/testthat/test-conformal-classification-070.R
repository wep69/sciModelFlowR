test_that("APS produces nonempty prediction sets", {
  p <- rbind(c(A=.8,B=.15,C=.05),c(A=.2,B=.7,C=.1),c(A=.1,B=.2,C=.7),c(A=.55,B=.35,C=.10))
  truth <- c("A","B","C","B")
  obj <- smf_conformal_fit(truth,probabilities=p,spec=smf_conformal_spec("aps",level=.8))
  out <- smf_conformal_predict(obj,probabilities=p)
  expect_true(all(out$set_size>=1))
  expect_equal(ncol(out$membership),3)
})
