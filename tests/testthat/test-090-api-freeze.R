test_that("API freeze has 246 exports", { expect_equal(nrow(smf_api_catalog()),246L); expect_true(all(smf_api_catalog()$api_freeze == "0.9.0")) })
