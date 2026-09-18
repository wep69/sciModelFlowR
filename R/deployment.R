.smf_identity_preprocessing_for_vetiver <- function(result) {
  pre<-result@fit@preprocessing; sp<-pre@spec; st<-pre@state
  isTRUE(sp@impute_numeric=="none") && !isTRUE(sp@center) && !isTRUE(sp@scale) &&
    !length(st$categorical) && is.null(result@fit@features) && is.null(result@fit@training_summary$calibration)
}

#' Create a vetiver model only when inference semantics are preserved
#' @export
smf_vetiver_model <- function(result, model_name, prototype_data) {
  if(!S7::S7_inherits(result,ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  if(!requireNamespace("vetiver",quietly=TRUE)) .smf_abort("VETIVER_MISSING","Package 'vetiver' is required for this optional adapter.",class="smf_capability_error")
  if(!is.data.frame(prototype_data)) cli::cli_abort("{.arg prototype_data} must be a data.frame.")
  if(!.smf_identity_preprocessing_for_vetiver(result)) .smf_abort("VETIVER_PIPELINE_NOT_PORTABLE","The generic vetiver adapter is enabled only when preprocessing is identity, no fitted feature transformation is present, and no probability calibrator must be replayed. Use a sciModelFlowR inference bundle for the complete managed pipeline.",class="smf_capability_error")
  native<-smf_backend_object(result)
  vetiver::vetiver_model(native,.smf_scalar_chr(model_name,"model_name"),prototype_data=prototype_data,metadata=list(sciModelFlowR_version=.smf_version(),run_id=result@meta@run_id,spec_hash=result@meta@spec_hash))
}

#' Write a compatible result to a vetiver/pins model board
#' @export
smf_vetiver_pin_write <- function(board, result, model_name, prototype_data, check_renv=FALSE, ...) {
  if(!requireNamespace("vetiver",quietly=TRUE)) .smf_abort("VETIVER_MISSING","Package 'vetiver' is required for this optional adapter.",class="smf_capability_error")
  v<-smf_vetiver_model(result,model_name,prototype_data)
  vetiver::vetiver_pin_write(board,v,...,check_renv=check_renv)
}

.smf_archive_bundle_zip <- function(bundle_path, file) {
  bundle_path<-normalizePath(bundle_path,mustWork=TRUE); file<-normalizePath(file,mustWork=FALSE)
  old<-getwd(); on.exit(setwd(old),add=TRUE); setwd(bundle_path)
  files<-list.files(".",recursive=TRUE,all.files=TRUE,no..=TRUE,include.dirs=FALSE)
  utils::zip(zipfile=file,files=files)
  if(!file.exists(file)) .smf_abort("BUNDLE_ARCHIVE_FAILED","Could not create ZIP archive for publication.",class="smf_persistence_error")
  file
}

#' Publish an inference bundle to an optional pins board
#' @export
smf_pins_publish_bundle <- function(board, bundle_path, name, tags=character(), ...) {
  if(!requireNamespace("pins",quietly=TRUE)) .smf_abort("PINS_MISSING","Package 'pins' is required for this optional adapter.",class="smf_capability_error")
  smf_validate_bundle(bundle_path)
  zip<-tempfile(fileext=".zip"); on.exit(unlink(zip,force=TRUE),add=TRUE); .smf_archive_bundle_zip(bundle_path,zip)
  pins::pin_upload(board,zip,name=.smf_scalar_chr(name,"name"),...,metadata=list(kind="sciModelFlowR_inference_bundle",bundle_schema=.smf_bundle_schema_version,package_version=.smf_version()),tags=tags)
}

#' Download a pinned bundle archive without loading it
#' @export
smf_pins_fetch_bundle <- function(board, name, version=NULL, destination=tempfile(fileext=".zip"), ...) {
  if(!requireNamespace("pins",quietly=TRUE)) .smf_abort("PINS_MISSING","Package 'pins' is required for this optional adapter.",class="smf_capability_error")
  src<-pins::pin_download(board,.smf_scalar_chr(name,"name"),version=version,...)
  if(length(src)!=1L) .smf_abort("PINS_BUNDLE_AMBIGUOUS","Expected one archived sciModelFlowR bundle from the pin.",class="smf_persistence_error")
  if(!file.copy(src,destination,overwrite=TRUE)) .smf_abort("PINS_BUNDLE_COPY_FAILED","Could not copy downloaded bundle archive.",class="smf_persistence_error")
  normalizePath(destination,mustWork=TRUE)
}

#' Write a minimal Plumber deployment file for a sciModelFlowR bundle
#' @export
smf_write_plumber <- function(bundle_path, file="plumber.R", trusted=FALSE) {
  smf_validate_bundle(bundle_path); bp<-normalizePath(bundle_path,winslash="/",mustWork=TRUE)
  code<-c(
    "library(sciModelFlowR)",
    sprintf("bundle <- smf_load_bundle(%s, trusted = %s)",dQuote(bp),if(isTRUE(trusted))"TRUE" else "FALSE"),
    "#* @post /predict",
    "#* @serializer unboxedJSON",
    "function(req) {",
    "  if (!requireNamespace(\"jsonlite\", quietly = TRUE)) stop(\"jsonlite is required\")",
    "  dat <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = TRUE)",
    "  if (!is.data.frame(dat)) dat <- as.data.frame(dat)",
    "  as.data.frame(smf_predict_bundle(bundle, dat))",
    "}"
  )
  .smf_atomic_write_text(code,file); invisible(normalizePath(file,mustWork=FALSE))
}

#' Guarded ONNX export hook for compatible backends
#' @export
smf_export_onnx <- function(result, file, exporter=NULL) {
  if(is.null(exporter) || !is.function(exporter)) .smf_abort("ONNX_EXPORT_UNAVAILABLE","No package-native ONNX exporter is certified for the fitted pipeline. Supply an explicit exporter function only for a backend/preprocessing combination whose ONNX semantics you have independently validated.",class="smf_capability_error")
  out<-exporter(result,file)
  if(!file.exists(file)) .smf_abort("ONNX_EXPORT_FAILED","The exporter did not create the requested file.",class="smf_persistence_error")
  list(path=normalizePath(file,mustWork=TRUE),sha256=.smf_file_sha256(file),warning="ONNX equivalence is not implied by export alone; validate predictions against the managed sciModelFlowR pipeline.",exporter_result=out)
}
