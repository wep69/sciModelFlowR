.smf_backend_registry <- new.env(parent=emptyenv())

.smf_capability_defaults <- function() {
  CapabilitySet(regression=FALSE, classification=FALSE, multiclass=FALSE, multioutput=FALSE,
    sample_weights=FALSE, probabilities=FALSE, quantiles=FALSE, distribution=FALSE,
    bootstrap=FALSE, posterior_sampling=FALSE, variational_inference=FALSE,
    conformal=FALSE, gpu=FALSE, explain_global=FALSE, explain_local=FALSE, safe_export=FALSE)
}

#' Register a backend capability record
#' @export
smf_register_backend <- function(name, capabilities=.smf_capability_defaults(), status=c("validated","core","advanced","experimental","quarantined","unavailable"), package=character(), validation_tier=1L, overwrite=FALSE) {
  name <- .smf_scalar_chr(name,"name")
  status <- match.arg(status)
  if (exists(name, envir=.smf_backend_registry, inherits=FALSE) && !overwrite) cli::cli_abort("Backend {.val {name}} is already registered.")
  assign(name, list(name=name, capabilities=capabilities, status=status, package=.smf_chr(package), validation_tier=as.integer(validation_tier)), envir=.smf_backend_registry)
  invisible(name)
}

.smf_optional_backend_status <- function(packages, implemented=TRUE) {
  if (!implemented) return("experimental")
  if (.smf_package_available(packages)) "advanced" else "unavailable"
}

.smf_register_builtin_backends <- function() {
  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multioutput <- TRUE; cap@probabilities <- TRUE; cap@sample_weights <- TRUE; cap@explain_global <- TRUE; cap@explain_local <- TRUE; cap@safe_export <- TRUE
  smf_register_backend("stats", cap, status="core", package="stats", validation_tier=1L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@sample_weights <- TRUE; cap@explain_global <- TRUE; cap@explain_local <- TRUE
  smf_register_backend("tidymodels", cap, status=.smf_optional_backend_status(c("parsnip","hardhat")), package=c("parsnip","hardhat"), validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@sample_weights <- TRUE; cap@explain_global <- TRUE; cap@explain_local <- TRUE
  smf_register_backend("mlr3", cap, status=.smf_optional_backend_status("mlr3"), package="mlr3", validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@sample_weights <- TRUE; cap@explain_global <- TRUE; cap@explain_local <- TRUE; cap@gpu <- TRUE
  smf_register_backend("xgboost", cap, status=.smf_optional_backend_status("xgboost"), package="xgboost", validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@distribution <- TRUE; cap@gpu <- TRUE; cap@explain_local <- TRUE
  smf_register_backend("torch", cap, status=.smf_optional_backend_status("torch"), package="torch", validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@distribution <- TRUE; cap@gpu <- TRUE
  smf_register_backend("luz", cap, status=.smf_optional_backend_status(c("torch","luz")), package=c("torch","luz"), validation_tier=3L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@distribution <- TRUE; cap@gpu <- TRUE
  smf_register_backend("keras3", cap, status=.smf_optional_backend_status("keras3"), package="keras3", validation_tier=3L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@multiclass <- TRUE; cap@probabilities <- TRUE; cap@distribution <- TRUE; cap@posterior_sampling <- TRUE; cap@variational_inference <- TRUE
  smf_register_backend("brms", cap, status=.smf_optional_backend_status(c("brms","posterior")), package=c("brms","posterior"), validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@classification <- TRUE; cap@probabilities <- TRUE; cap@distribution <- TRUE; cap@posterior_sampling <- TRUE
  smf_register_backend("dbarts", cap, status=.smf_optional_backend_status("dbarts"), package="dbarts", validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@distribution <- TRUE; cap@posterior_sampling <- TRUE
  smf_register_backend("DiceKriging", cap, status=.smf_optional_backend_status("DiceKriging"), package="DiceKriging", validation_tier=2L, overwrite=TRUE)

  cap <- .smf_capability_defaults(); cap@regression <- TRUE; cap@conformal <- TRUE; cap@quantiles <- TRUE
  smf_register_backend("probably", cap, status=.smf_optional_backend_status("probably"), package="probably", validation_tier=2L, overwrite=TRUE)
}

#' List registered backends and status
#' @export
smf_capabilities <- function() {
  .smf_register_builtin_backends()
  nms <- ls(.smf_backend_registry)
  out <- lapply(nms, function(nm) get(nm, envir=.smf_backend_registry, inherits=FALSE))
  names(out) <- nms
  out
}

#' Return capabilities for one backend
#' @export
smf_backend_capabilities <- function(name) {
  .smf_register_builtin_backends()
  if (!exists(name, envir=.smf_backend_registry, inherits=FALSE)) {
    aceitos <- ls(.smf_backend_registry)
    .smf_abort("BACKEND_UNKNOWN", paste0("Unknown backend: ", name, ". Accepted engines: ", paste(aceitos, collapse=", "), ". See smf_available_model_adapters() for packages and validation tiers."), evidence=list(engine=name, accepted=aceitos), class="smf_capability_error")
  }
  get(name, envir=.smf_backend_registry, inherits=FALSE)
}

#' Require one backend capability
#' @export
smf_require_capability <- function(name, capability) {
  rec <- smf_backend_capabilities(name)
  if (rec$status %in% c("unavailable","quarantined")) .smf_abort("BACKEND_UNAVAILABLE", paste0("Backend '", name, "' is ", rec$status, " in this environment."), evidence=list(backend=name, packages=rec$package), class="smf_capability_error")
  if (!capability %in% S7::prop_names(rec$capabilities)) .smf_abort("CAPABILITY_UNKNOWN", paste0("Unknown capability: ", capability), class="smf_capability_error")
  ok <- isTRUE(S7::prop(rec$capabilities, capability))
  if (!ok) .smf_abort("CAPABILITY_UNSUPPORTED", paste0("Backend '", name, "' does not support '", capability, "'."), evidence=list(backend=name, capability=capability), class="smf_capability_error")
  invisible(TRUE)
}
