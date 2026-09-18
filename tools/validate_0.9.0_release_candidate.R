# sciModelFlowR 0.9.0 release-candidate evidence
a <- smf_release_candidate_audit(FALSE)
stopifnot(a@n_exports == 246L, all(a@gold$passed), all(a@crosslang$passed))
