test_that("release candidate evidence is frozen", { expect_equal(nrow(smf_api_catalog()), 246L); expect_true(all(smf_backend_matrix()$release_status == "pending-final-local-certification")) })
