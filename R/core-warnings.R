#' Create a structured scientific warning record
#' @export
smf_warning_record <- function(code, message, severity=c("warning","info","high","blocking"), evidence=list(), suggested_action=character(), override_allowed=TRUE) {
  severity <- match.arg(severity)
  WarningRecord(code=.smf_scalar_chr(code,"code"), severity=severity, message=.smf_scalar_chr(message,"message"), evidence=evidence, suggested_action=.smf_chr(suggested_action), override_allowed=.smf_scalar_lgl(override_allowed,"override_allowed"))
}

.smf_signal_warning <- function(record) {
  cnd <- rlang::warning_cnd(
    class = c(paste0("smf_", tolower(record@code)), "smf_scientific_warning"),
    message = record@message,
    code = record@code,
    severity = record@severity,
    evidence = record@evidence,
    suggested_action = record@suggested_action,
    override_allowed = record@override_allowed
  )
  rlang::cnd_signal(cnd)
  invisible(record)
}

.smf_abort <- function(code, message, evidence=list(), class="smf_validation_error") {
  rlang::abort(message, class=c(class,"smf_error"), code=code, evidence=evidence)
}
