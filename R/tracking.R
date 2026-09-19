.smf_atomic_write_text <- function(text, file) {
  dir.create(dirname(file), recursive=TRUE, showWarnings=FALSE)
  tmp <- tempfile(pattern=".smf-write-", tmpdir=dirname(file))
  on.exit(unlink(tmp, force=TRUE), add=TRUE)
  writeLines(text, tmp, useBytes=TRUE)
  if (!file.rename(tmp, file)) {
    if (!file.copy(tmp, file, overwrite=TRUE)) .smf_abort("ATOMIC_WRITE_FAILED", paste0("Could not write ", file, "."))
    unlink(tmp, force=TRUE)
  }
  invisible(file)
}

.smf_atomic_write_json <- function(x, file, pretty=TRUE) {
  txt <- jsonlite::toJSON(x, auto_unbox=TRUE, null="null", na="null", digits=NA, pretty=pretty, dataframe="columns")
  .smf_atomic_write_text(txt, file)
}

.smf_read_json_list <- function(file) {
  if (!file.exists(file)) return(NULL)
  jsonlite::fromJSON(file, simplifyVector=FALSE, simplifyDataFrame=FALSE, simplifyMatrix=FALSE)
}

#' Create a tracking specification
#' @export
smf_tracking_spec <- function(provider=c("local","none","mlflow"), uri=character(), experiment="default",
                              tags=list(), artifact_mode=c("copy","reference"), parameters=list()) {
  provider <- match.arg(provider); artifact_mode <- match.arg(artifact_mode)
  TrackingSpec(provider=provider, uri=.smf_chr(uri), experiment=.smf_scalar_chr(experiment,"experiment"),
    tags=tags, artifact_mode=artifact_mode, parameters=parameters)
}

#' Create a local experiment tracker
#' @export
smf_tracker_local <- function(path, experiment="default", tags=list()) {
  path <- .smf_scalar_chr(path,"path"); dir.create(path, recursive=TRUE, showWarnings=FALSE)
  smf_tracking_spec("local", normalizePath(path, mustWork=FALSE), experiment, tags)
}

#' Create an optional MLflow tracker specification
#' @export
smf_tracker_mlflow <- function(uri=character(), experiment="default", tags=list()) {
  smf_tracking_spec("mlflow", uri=.smf_chr(uri), experiment=experiment, tags=tags)
}

.smf_local_run_dir <- function(tracker, run_id) file.path(tracker@uri[[1]], tracker@experiment, run_id)

.smf_local_run_record <- function(run) list(
  provider=run@provider, run_id=run@run_id, external_id=run@external_id,
  experiment=run@experiment, path=run@path, status=run@status,
  started_at=run@started_at, ended_at=run@ended_at, tags=run@tags, metadata=run@metadata
)

#' Start or resume a tracked run
#' @export
smf_start_run <- function(tracker, run_name=character(), tags=list(), resume_run_id=character()) {
  if (!S7::S7_inherits(tracker, TrackingSpec)) cli::cli_abort("{.arg tracker} must be a TrackingSpec.")
  merged_tags <- utils::modifyList(tracker@tags %||% list(), tags %||% list())
  if (length(run_name)) merged_tags$run_name <- as.character(run_name[[1]])
  if (tracker@provider == "none") {
    id <- if(length(resume_run_id)) as.character(resume_run_id[[1]]) else .smf_new_run_id()
    return(TrackerRun(provider="none",run_id=id,external_id=character(),experiment=tracker@experiment,path=character(),status="running",started_at=.smf_now(),ended_at=character(),tags=merged_tags,metadata=list(resumed=length(resume_run_id)>0L)))
  }
  if (tracker@provider == "local") {
    id <- if(length(resume_run_id)) as.character(resume_run_id[[1]]) else .smf_new_run_id()
    d <- .smf_local_run_dir(tracker,id); record_file <- file.path(d,"run.json")
    if (length(resume_run_id)) {
      old <- .smf_read_json_list(record_file)
      if (is.null(old)) .smf_abort("TRACK_RUN_NOT_FOUND", paste0("Run '", id, "' is not present in the local tracker."), class="smf_tracking_error")
      if (identical(old$status,"finished")) .smf_abort("TRACK_RUN_FINISHED", "Finished runs cannot be resumed as mutable runs.", class="smf_tracking_error")
      started <- old$started_at %||% .smf_now(); merged_tags <- utils::modifyList(old$tags %||% list(), merged_tags)
    } else {
      if (dir.exists(d)) .smf_abort("TRACK_RUN_COLLISION","Generated run directory already exists.",class="smf_tracking_error")
      dir.create(file.path(d,"artifacts"),recursive=TRUE,showWarnings=FALSE); started <- .smf_now()
    }
    run <- TrackerRun(provider="local",run_id=id,external_id=character(),experiment=tracker@experiment,path=normalizePath(d,mustWork=FALSE),status="running",started_at=started,ended_at=character(),tags=merged_tags,metadata=list(resumed=length(resume_run_id)>0L,tracker_uri=tracker@uri))
    .smf_atomic_write_json(.smf_local_run_record(run), record_file)
    return(run)
  }
  if (!requireNamespace("mlflow",quietly=TRUE)) .smf_abort("MLFLOW_MISSING","Package 'mlflow' is required only for provider='mlflow'. Local tracking remains available.",class="smf_capability_error")
  if (length(tracker@uri)) mlflow::mlflow_set_tracking_uri(tracker@uri[[1]])
  exp_id <- mlflow::mlflow_set_experiment(experiment_name=tracker@experiment)
  mlrun <- if(length(resume_run_id)) mlflow::mlflow_start_run(run_id=as.character(resume_run_id[[1]])) else mlflow::mlflow_start_run(experiment_id=exp_id, tags=merged_tags)
  ext <- tryCatch(as.character(mlflow::mlflow_id(mlrun)), error=function(e) character())
  TrackerRun(provider="mlflow",run_id=if(length(ext))ext else .smf_new_run_id(),external_id=ext,experiment=tracker@experiment,path=character(),status="running",started_at=.smf_now(),ended_at=character(),tags=merged_tags,metadata=list(resumed=length(resume_run_id)>0L,tracker_uri=tracker@uri))
}

#' Log one metric to a tracked run
#' @export
smf_log_metric <- function(run, key, value, step=0L, timestamp=NULL) {
  if(!S7::S7_inherits(run,TrackerRun)) cli::cli_abort("{.arg run} must be a TrackerRun.")
  key <- .smf_scalar_chr(key,"key"); value <- .smf_scalar_num(as.numeric(value),"value")
  if (run@provider=="none") return(invisible(run))
  if (run@provider=="mlflow") { mlflow::mlflow_log_metric(key,value,step=as.integer(step),run_id=run@external_id); return(invisible(run)) }
  rec <- list(key=key,value=value,step=as.integer(step),timestamp=timestamp %||% .smf_now())
  line <- jsonlite::toJSON(rec,auto_unbox=TRUE,null="null",digits=NA)
  cat(as.character(line),"\n",file=file.path(run@path,"metrics.ndjson"),append=TRUE,sep="")
  invisible(run)
}

#' Log named parameters to a tracked run
#' @export
smf_log_params <- function(run, params) {
  if(!S7::S7_inherits(run,TrackerRun)) cli::cli_abort("{.arg run} must be a TrackerRun.")
  if(!is.list(params) || is.null(names(params))) cli::cli_abort("{.arg params} must be a named list.")
  if (run@provider=="none") return(invisible(run))
  if (run@provider=="mlflow") {
    for(nm in names(params)) mlflow::mlflow_log_param(nm,paste(params[[nm]],collapse=","),run_id=run@external_id)
    return(invisible(run))
  }
  file <- file.path(run@path,"params.json"); old <- .smf_read_json_list(file) %||% list()
  .smf_atomic_write_json(utils::modifyList(old,params),file); invisible(run)
}

#' Log a file artifact to a tracked run
#' @export
smf_log_artifact <- function(run, file, name=basename(file)) {
  if(!S7::S7_inherits(run,TrackerRun)) cli::cli_abort("{.arg run} must be a TrackerRun.")
  if(!file.exists(file)) cli::cli_abort("Artifact file does not exist.")
  if(run@provider=="none") return(invisible(run))
  if(run@provider=="mlflow") { mlflow::mlflow_log_artifact(file,run_id=run@external_id); return(invisible(run)) }
  dest <- file.path(run@path,"artifacts",.smf_scalar_chr(name,"name")); dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
  if(!file.copy(file,dest,overwrite=TRUE)) .smf_abort("TRACK_ARTIFACT_COPY_FAILED","Could not copy artifact into local tracker.",class="smf_tracking_error")
  invisible(dest)
}

#' Log a sciModelFlowR result to a tracked run
#' @export
smf_log_result <- function(run, result) {
  if(!S7::S7_inherits(run,TrackerRun)) cli::cli_abort("{.arg run} must be a TrackerRun.")
  if(!S7::S7_inherits(result,ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  if(is.data.frame(result@metrics) && nrow(result@metrics)) {
    for(i in seq_len(nrow(result@metrics))) if(is.numeric(result@metrics$value[[i]]) && is.finite(result@metrics$value[[i]])) smf_log_metric(run,as.character(result@metrics$metric[[i]]),result@metrics$value[[i]])
  }
  smf_log_params(run,list(spec_hash=result@meta@spec_hash,data_hash=result@meta@data_hash,engine=result@spec@model@engine,package_version=result@meta@package_version))
  if(run@provider=="local") {
    .smf_atomic_write_text(smf_to_json(result@manifest,pretty=TRUE),file.path(run@path,"manifest.json"))
    .smf_atomic_write_text(smf_to_json(result@spec,pretty=TRUE),file.path(run@path,"spec.json"))
  }
  invisible(run)
}

#' End a tracked run
#' @export
smf_end_run <- function(run, status=c("finished","failed","interrupted"), message=character()) {
  if(!S7::S7_inherits(run,TrackerRun)) cli::cli_abort("{.arg run} must be a TrackerRun.")
  status <- match.arg(status); ended <- .smf_now()
  if(run@provider=="mlflow") {
    ml_status <- switch(status,finished="FINISHED",failed="FAILED",interrupted="KILLED")
    mlflow::mlflow_end_run(status=ml_status)
  }
  out <- TrackerRun(provider=run@provider,run_id=run@run_id,external_id=run@external_id,experiment=run@experiment,path=run@path,status=status,started_at=run@started_at,ended_at=ended,tags=run@tags,metadata=utils::modifyList(run@metadata,list(message=.smf_chr(message))))
  if(run@provider=="local") .smf_atomic_write_json(.smf_local_run_record(out),file.path(run@path,"run.json"))
  out
}

#' List local tracked runs
#' @export
smf_list_runs <- function(tracker) {
  if(!S7::S7_inherits(tracker,TrackingSpec) || tracker@provider!="local") cli::cli_abort("smf_list_runs() currently requires a local tracker.")
  root <- file.path(tracker@uri[[1]],tracker@experiment); if(!dir.exists(root)) return(data.frame())
  dirs <- list.dirs(root,recursive=FALSE,full.names=TRUE)
  rows <- lapply(dirs,function(d){x<-.smf_read_json_list(file.path(d,"run.json")); if(is.null(x))return(NULL); data.frame(run_id=x$run_id,status=x$status,started_at=x$started_at,ended_at=x$ended_at %||% "",path=d,stringsAsFactors=FALSE)})
  rows <- Filter(Negate(is.null),rows); if(!length(rows)) data.frame() else do.call(rbind,rows)
}

#' Retrieve one local tracked run
#' @export
smf_get_run <- function(tracker, run_id) {
  if(!S7::S7_inherits(tracker,TrackingSpec) || tracker@provider!="local") cli::cli_abort("smf_get_run() currently requires a local tracker.")
  d <- .smf_local_run_dir(tracker,.smf_scalar_chr(run_id,"run_id")); x <- .smf_read_json_list(file.path(d,"run.json"))
  if(is.null(x)) .smf_abort("TRACK_RUN_NOT_FOUND","Tracked run was not found.",class="smf_tracking_error")
  TrackerRun(provider=x$provider,run_id=x$run_id,external_id=.smf_chr(x$external_id),experiment=x$experiment,path=d,status=x$status,started_at=x$started_at,ended_at=.smf_chr(x$ended_at),tags=x$tags %||% list(),metadata=x$metadata %||% list())
}
