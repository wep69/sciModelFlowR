test_that("1.0.0 keeps the 0.9.0 public API freeze", {
  p09 <- system.file("metadata", "API_FREEZE_0.9.0.csv", package = "sciModelFlowR")
  p10 <- system.file("metadata", "API_FREEZE_1.0.0.csv", package = "sciModelFlowR")
  a <- utils::read.csv(p09, stringsAsFactors = FALSE)
  b <- utils::read.csv(p10, stringsAsFactors = FALSE)
  expect_identical(a$function_name, b$function_name)
  expect_identical(a$signature_prefix, b$signature_prefix)
  expect_equal(nrow(b), 246L)
})

test_that("1.0.0 release metadata are installed", {
  files <- c("API_FREEZE_1.0.0.csv", "FINAL_COMPATIBILITY_MATRIX_1.0.0.csv",
    "GOLD_RELEASE_MANIFEST_1.0.0.csv", "SECURITY_REVIEW_1.0.0.json",
    "BENCHMARK_BASELINES_1.0.0.csv", "RELEASE_MANIFEST_1.0.0.json")
  expect_true(all(nzchar(vapply(files, function(x) system.file("metadata", x, package="sciModelFlowR"), character(1)))))
})
