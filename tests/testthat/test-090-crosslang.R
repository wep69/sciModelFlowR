test_that("cross-language fixtures parse", { x <- smf_validate_crosslang_fixtures(); expect_equal(nrow(x),25L); expect_true(all(x$passed)) })
