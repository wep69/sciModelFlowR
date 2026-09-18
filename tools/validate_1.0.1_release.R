# sciModelFlowR 1.0.1 — release-engineering gate.
# The frozen 1.0.0 release metadata remain the historical reference; this gate
# additionally requires the 1.0.1 release manifest and confirms that the
# public API freeze (0.9.0 -> 1.0.0 -> 1.0.1) is unchanged.
cat("sciModelFlowR 1.0.1 release-engineering checks\n")
root <- normalizePath(".", mustWork = TRUE)
required <- c(
  "inst/metadata/API_FREEZE_1.0.0.csv",
  "inst/metadata/API_DIFF_0.9.0_TO_1.0.0.csv",
  "inst/metadata/FINAL_COMPATIBILITY_MATRIX_1.0.0.csv",
  "inst/metadata/GOLD_RELEASE_MANIFEST_1.0.0.csv",
  "inst/metadata/SECURITY_REVIEW_1.0.0.json",
  "inst/metadata/BENCHMARK_BASELINES_1.0.0.csv",
  "inst/metadata/RELEASE_MANIFEST_1.0.0.json",
  "inst/metadata/RELEASE_MANIFEST_1.0.1.json"
)
stopifnot(all(file.exists(file.path(root, required))))

api09 <- utils::read.csv(
  file.path(root, "inst/metadata/API_FREEZE_0.9.0.csv"),
  stringsAsFactors = FALSE
)
api10 <- utils::read.csv(
  file.path(root, "inst/metadata/API_FREEZE_1.0.0.csv"),
  stringsAsFactors = FALSE
)
stopifnot(identical(api09$function_name, api10$function_name))
stopifnot(identical(api09$signature_prefix, api10$signature_prefix))

m <- jsonlite::fromJSON(
  file.path(root, "inst/metadata/RELEASE_MANIFEST_1.0.1.json"),
  simplifyVector = TRUE
)
stopifnot(identical(m$version, "1.0.1"))
stopifnot(identical(as.integer(m$api_exports), 246L))
stopifnot(identical(m$api_changed_since_1_0_0, FALSE))
stopifnot(identical(m$base_release, "1.0.0"))

cat("Release metadata contract checks complete for 1.0.1.\n")
