test_that("doctor works without optional backends", {
  d <- smf_doctor()
  expect_true(all(c("component","available","version","status") %in% names(d)))
  expect_true(any(d$component=="R"))
})
