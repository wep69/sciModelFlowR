test_that("formal Gold suite is complete", { expect_equal(length(smf_list_datasets()),25L); expect_true(all(smf_run_gold_validation()$passed)) })
