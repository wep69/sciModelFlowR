# sciModelFlowR 1.0.2 — final validation entry point.
# Patch release of the 1.0.1 audited-tutorial corrections (see NEWS.md and
# tests/testthat/test-regressions-102.R). The 1.0.0/1.0.1 gates remain the
# historical harness for their artefacts; this file is the 1.0.2 equivalent.
cat("sciModelFlowR 1.0.2 final validation entry point\n")
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "1.0.2")

api <- sciModelFlowR::smf_api_catalog()
stopifnot(nrow(api) == 246L)

pol <- sciModelFlowR::smf_deprecation_policy()
stopifnot(identical(pol$api_freeze, "1.0.0"))
stopifnot(identical(pol$stable_release, "1.0.2"))

gold <- sciModelFlowR::smf_run_gold_validation(stop_on_failure = FALSE)
stopifnot(all(gold$passed))

ref <- sciModelFlowR::smf_run_reference_validation()
stopifnot(isTRUE(ref$passed))

xl <- sciModelFlowR::smf_run_crosslang_validation()
stopifnot(all(xl$fixtures$passed))

audit <- sciModelFlowR::smf_release_candidate_audit(runtime_certified = TRUE)
stopifnot(audit@n_exports == 246L)

cat("Source/reference contract checks completed for 1.0.2.\n")
