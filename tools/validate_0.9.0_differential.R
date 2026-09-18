# sciModelFlowR 0.9.0 differential validation
x <- smf_run_reference_validation()
stopifnot(isTRUE(x$passed))
print(x)
