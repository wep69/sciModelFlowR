test_that("Pareto front honors objective directions", {
  d <- data.frame(id=letters[1:4], acc=c(.8,.85,.82,.7), time=c(1,3,2,.5))
  p <- smf_pareto_front(d,c("acc","time"),c(acc="maximize",time="minimize"))
  expect_true(all(p$id %in% c("a","b","c","d")))
  expect_false(anyDuplicated(p$id))
  pick <- smf_select_compromise(p,c("acc","time"),c(acc="maximize",time="minimize"),list(type="weighted_sum",weights=c(acc=.8,time=.2)))
  expect_equal(nrow(pick),1)
})
