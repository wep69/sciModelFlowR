test_that("reference validator returns evidence", { x <- smf_run_reference_validation(); expect_true(is.logical(x$passed)); expect_true(is.data.frame(x$metrics)) })
