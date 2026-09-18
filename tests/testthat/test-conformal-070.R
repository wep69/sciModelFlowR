test_that("split conformal uses untouched calibration data", {
  d <- smf_load_dataset("gold_conformal_regression")
  tr <- d[d$partition=="train",]; ca <- d[d$partition=="calibration",]; te <- d[d$partition=="test",]
  m <- lm(y ~ x1 + x2,data=tr)
  obj <- smf_conformal_fit(ca$y,predict(m,ca),spec=smf_conformal_spec("split",level=.90),calibration_ids=ca$row_id,final_test_ids=te$row_id)
  ints <- smf_conformal_predict(obj,prediction=predict(m,te))
  cv <- smf_conformal_coverage(te$y,ints)
  expect_gt(cv$coverage,0.86)
  expect_lt(cv$coverage,0.94)
  expect_true(all(ints$interval_type=="conformal"))
})

test_that("final-test overlap is blocked", {
  expect_error(smf_conformal_fit(c(1,2,3),c(1,2,3),calibration_ids=c("a","b","c"),final_test_ids=c("c","d")),class="smf_leakage_error")
})

test_that("CV+ stores fold identity and returns intervals", {
  y <- c(1,2,3,4,5,6); p <- c(1.1,1.8,3.2,3.9,5.2,5.8); f <- rep(c("F1","F2","F3"),each=2)
  obj <- smf_conformal_fit(y,p,spec=smf_conformal_spec("cv_plus",level=.9,calibration_role="out_of_fold"),fold_id=f)
  fp <- matrix(c(2,2.1,1.9, 4,4.1,3.9),nrow=2,byrow=TRUE,dimnames=list(NULL,c("F1","F2","F3")))
  out <- smf_conformal_predict(obj,fold_predictions=fp)
  expect_equal(nrow(out),2)
  expect_true(all(out$.pred_lower <= out$.pred_upper))
})
