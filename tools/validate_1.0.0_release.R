# sciModelFlowR 1.0.0 — derived release-metadata gate (working-copy fix).
# Origin: tools/validate_1.0.0_release.R.frozen_orig (single line with literal
# `\n` sequences; see VALIDATION_HARNESS_WORKAROUND.md).
# The frozen ZIP/TAR.GZ artefacts are NOT modified. Semantically identical to
# §18.4 of sciModelFlowR_VALIDACAO_LOCAL_WINDOWS_0.1.0_A_1.0.0.md.
cat("sciModelFlowR 1.0.0 release-engineering checks\n")
root <- normalizePath(".", mustWork = TRUE)
required <- c(
  "inst/metadata/API_FREEZE_1.0.0.csv",
  "inst/metadata/API_DIFF_0.9.0_TO_1.0.0.csv",
  "inst/metadata/FINAL_COMPATIBILITY_MATRIX_1.0.0.csv",
  "inst/metadata/GOLD_RELEASE_MANIFEST_1.0.0.csv",
  "inst/metadata/SECURITY_REVIEW_1.0.0.json",
  "inst/metadata/BENCHMARK_BASELINES_1.0.0.csv",
  "inst/metadata/RELEASE_MANIFEST_1.0.0.json"
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
cat("Release metadata contract checks complete. Runtime certification still requires the full local campaign.\n")
