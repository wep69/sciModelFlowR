.smf_dependency_versions <- function(pkgs=c("S7","rlang","vctrs","tibble","cli","digest","jsonlite","withr","yaml")) {
  out <- vapply(pkgs, function(p) if (requireNamespace(p,quietly=TRUE)) as.character(utils::packageVersion(p)) else NA_character_, character(1))
  as.list(out)
}

#' Build a reproducibility manifest
#' @export
smf_manifest <- function(x) {
  if (S7::S7_inherits(x, ExperimentResult)) return(x@manifest)
  if (!S7::S7_inherits(x, RunManifest)) cli::cli_abort("{.arg x} must be an ExperimentResult or RunManifest.")
  x
}

#' Save a run manifest as JSON or YAML
#' @export
smf_save_manifest <- function(x, file) {
  m <- smf_manifest(x)
  ext <- tolower(tools::file_ext(file))
  txt <- if (ext %in% c("yaml","yml")) smf_to_yaml(m) else smf_to_json(m,pretty=TRUE)
  writeLines(txt,file,useBytes=TRUE); invisible(normalizePath(file,mustWork=FALSE))
}

.smf_hardware_info <- function() {
  si <- Sys.info()
  out <- list(
    sysname=unname(si[["sysname"]] %||% ""), release=unname(si[["release"]] %||% ""),
    machine=unname(si[["machine"]] %||% ""), cpu_model=unname(si[["model"]] %||% ""),
    logical_cores=as.integer(parallel::detectCores(logical=TRUE) %||% NA_integer_),
    physical_cores=as.integer(parallel::detectCores(logical=FALSE) %||% NA_integer_),
    gpu_available=FALSE, cuda_available=FALSE, cuda_runtime=character(), torch_version=character(),
    cuda_visible_devices=Sys.getenv("CUDA_VISIBLE_DEVICES",unset="")
  )
  if(requireNamespace("torch",quietly=TRUE)) {
    out$torch_version <- tryCatch(as.character(utils::packageVersion("torch")),error=function(e)character())
    installed <- tryCatch(torch::torch_is_installed(),error=function(e)FALSE)
    cuda <- if(isTRUE(installed)) tryCatch(torch::cuda_is_available(),error=function(e)FALSE) else FALSE
    out$gpu_available <- isTRUE(cuda); out$cuda_available <- isTRUE(cuda)
    if(isTRUE(cuda)) out$cuda_runtime <- tryCatch(as.character(torch::cuda_runtime_version()),error=function(e)character())
  }
  out
}

#' Return reproducibility-relevant hardware information
#' @export
smf_hardware_info <- function() .smf_hardware_info()
