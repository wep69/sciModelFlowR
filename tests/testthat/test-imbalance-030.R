test_that("imbalance operations are blocked on assessment data", {
  d <- data.frame(x=rnorm(20),class=factor(c(rep("major",17),rep("minor",3))))
  expect_error(smf_apply_imbalance(d,"class",smf_imbalance_spec("upsample"),context="test"),class="smf_leakage_error")
})

test_that("class weights are learned from analysis labels only", {
  d <- data.frame(x=1:10,class=factor(c(rep("a",8),rep("b",2))))
  out <- smf_apply_imbalance(d,"class",smf_imbalance_spec("weights"),context="analysis")
  expect_equal(length(out@weights),nrow(d))
  expect_gt(mean(out@weights[d$class=="b"]),mean(out@weights[d$class=="a"]))
})

test_that("threshold optimization returns an explicit validation rule", {
  y <- factor(c("no","no","no","yes","yes","yes"),levels=c("no","yes"))
  p <- c(.1,.2,.55,.4,.7,.9)
  z <- smf_optimize_threshold(y,p,"balanced_accuracy",grid=c(.3,.5,.7),positive_label="yes")
  expect_true(z$threshold %in% c(.3,.5,.7))
  expect_equal(z$positive_label,"yes")
})
