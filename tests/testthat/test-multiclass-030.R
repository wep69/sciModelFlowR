test_that("multiclass Gold fixture is frozen and imbalanced", {
  d <- smf_load_dataset("gold_multiclass_imbalanced")
  expect_true("class" %in% names(d)); tab<-table(d$class)
  expect_equal(length(tab),3L); expect_lt(min(tab)/max(tab),.2)
})

test_that("multiclass probability metrics use named normalized columns", {
  y<-factor(c("a","b","c","a"),levels=c("a","b","c"))
  p<-rbind(c(.8,.1,.1),c(.1,.8,.1),c(.1,.2,.7),c(.6,.2,.2));colnames(p)<-levels(y)
  out<-smf_evaluate(y,p,list(smf_metric_spec("accuracy"),smf_metric_spec("log_loss"),smf_metric_spec("brier")))
  expect_equal(nrow(out),3L); expect_true(all(is.finite(out$value)))
})
