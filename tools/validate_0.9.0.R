# sciModelFlowR 0.9.0 local RC validation
stopifnot(as.character(packageVersion("sciModelFlowR")) == "0.9.0")
stopifnot(all(smf_run_gold_validation(TRUE)$passed))
stopifnot(nrow(smf_api_catalog()) == 246L)
stopifnot(all(smf_validate_crosslang_fixtures()$passed))
print(smf_release_candidate_audit(FALSE))
