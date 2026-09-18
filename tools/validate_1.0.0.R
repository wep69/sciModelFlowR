# sciModelFlowR 1.0.0 — derived validation harness (working-copy fix).
# Origin: tools/validate_1.0.0.R.frozen_orig (single line with literal `\n`
# sequences between statements; see VALIDATION_HARNESS_WORKAROUND.md).
# The frozen ZIP/TAR.GZ artefacts are NOT modified. This file contains the
# semantically identical, line-separated gate from §18.3 of
# sciModelFlowR_VALIDACAO_LOCAL_WINDOWS_0.1.0_A_1.0.0.md, with the S7 slot
# access `audit@n_exports` preserved as in the frozen original.
cat("sciModelFlowR 1.0.0 final validation entry point\n")
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "1.0.0")

api <- sciModelFlowR::smf_api_catalog()
stopifnot(nrow(api) == 246L)

pol <- sciModelFlowR::smf_deprecation_policy()
stopifnot(identical(pol$stable_release, "1.0.0"))

gold <- sciModelFlowR::smf_run_gold_validation(stop_on_failure = FALSE)
stopifnot(all(gold$passed))

ref <- sciModelFlowR::smf_run_reference_validation()
stopifnot(isTRUE(ref$passed))

xl <- sciModelFlowR::smf_run_crosslang_validation()
stopifnot(all(xl$fixtures$passed))

audit <- sciModelFlowR::smf_release_candidate_audit(runtime_certified = FALSE)
stopifnot(audit@n_exports == 246L)

cat("Source/reference contract checks completed.\n")
