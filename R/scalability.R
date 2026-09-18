#' Plan deterministic row batches
#' @export
smf_chunk_plan <- function(n, chunk_size=1000L) {
  n<-as.integer(n); chunk_size<-as.integer(chunk_size)
  if(length(n)!=1L || is.na(n) || n<0L) cli::cli_abort("{.arg n} must be a non-negative integer.")
  if(length(chunk_size)!=1L || is.na(chunk_size) || chunk_size<1L) cli::cli_abort("{.arg chunk_size} must be at least 1.")
  if(n==0L) return(list())
  split(seq_len(n),ceiling(seq_len(n)/chunk_size))
}

#' Create a resettable data-frame iterator
#' @export
smf_data_iterator <- function(data, chunk_size=1000L) {
  if(!is.data.frame(data)) cli::cli_abort("The core iterator currently accepts a data.frame. File/database adapters can implement the same next/reset contract externally.")
  plan<-smf_chunk_plan(nrow(data),chunk_size); e<-new.env(parent=emptyenv()); e$data<-data; e$plan<-plan; e$position<-0L; e$chunk_size<-as.integer(chunk_size); e$total_rows<-nrow(data); class(e)<-c("smf_data_iterator","environment"); e
}

#' Read the next iterator chunk
#' @export
smf_iterator_next <- function(iterator) {
  if(!inherits(iterator,"smf_data_iterator")) cli::cli_abort("{.arg iterator} must be returned by smf_data_iterator().")
  iterator$position<-iterator$position+1L
  if(iterator$position>length(iterator$plan)) return(NULL)
  idx<-iterator$plan[[iterator$position]]; iterator$data[idx,,drop=FALSE]
}

#' Reset an iterator to its first chunk
#' @export
smf_iterator_reset <- function(iterator) {
  if(!inherits(iterator,"smf_data_iterator")) cli::cli_abort("{.arg iterator} must be returned by smf_data_iterator().")
  iterator$position<-0L; invisible(iterator)
}

.smf_predict_any <- function(object,data,strict_schema=TRUE) {
  if(S7::S7_inherits(object,InferenceBundle)) return(smf_predict_bundle(object,data,strict_schema=strict_schema))
  smf_predict(object,data)
}

.smf_prediction_frame <- function(x) {
  if(is.data.frame(x)) return(x)
  if(is.matrix(x)) return(as.data.frame(x,check.names=FALSE))
  data.frame(.prediction=x,check.names=FALSE)
}

.smf_batch_object_hash <- function(object) {
  if(S7::S7_inherits(object,InferenceBundle)) return(smf_hash(list(source_run_id=object@manifest$source_run_id,spec_hash=object@manifest$spec_hash,schema_hash=object@manifest$schema_hash)))
  if(S7::S7_inherits(object,ExperimentResult)) return(smf_hash(list(run_id=object@meta@run_id,spec_hash=object@meta@spec_hash)))
  if(S7::S7_inherits(object,FitResult)) return(smf_hash(list(run_id=object@meta@run_id,spec_hash=object@meta@spec_hash)))
  .smf_abort("BATCH_OBJECT_UNSUPPORTED","Batch prediction requires an InferenceBundle, ExperimentResult, or FitResult.",class="smf_capability_error")
}

.smf_batch_manifest_file <- function(checkpoint_dir) file.path(checkpoint_dir,"batch_manifest.json")

.smf_read_batch_manifest <- function(checkpoint_dir) .smf_read_json_list(.smf_batch_manifest_file(checkpoint_dir))

.smf_batch_manifest_compatible <- function(m,input_hash,object_hash,n,batch_size) {
  identical(m$input_hash,input_hash) && identical(m$object_hash,object_hash) && as.integer(m$n_rows)==as.integer(n) && as.integer(m$batch_size)==as.integer(batch_size)
}

.smf_batch_checkpoint_write <- function(checkpoint_dir,batch_id,pred) {
  file<-file.path(checkpoint_dir,sprintf("batch-%06d.csv",batch_id)); utils::write.csv(.smf_prediction_frame(pred),file,row.names=FALSE,na="")
  list(batch_id=as.integer(batch_id),file=basename(file),sha256=.smf_file_sha256(file),n=nrow(.smf_prediction_frame(pred)))
}

.smf_batch_checkpoint_read <- function(checkpoint_dir,entry) {
  file<-file.path(checkpoint_dir,entry$file)
  if(!file.exists(file) || !identical(tolower(.smf_file_sha256(file)),tolower(entry$sha256))) .smf_abort("BATCH_CHECKPOINT_CORRUPT",paste0("Checkpoint batch ",entry$batch_id," is missing or corrupted."),class="smf_persistence_error")
  utils::read.csv(file,check.names=FALSE,stringsAsFactors=FALSE)
}

#' Predict large in-memory data in deterministic batches with optional resume
#' @export
smf_batch_predict <- function(object, new_data, batch_size=1000L, workers=1L, strict_schema=TRUE,
                              checkpoint_dir=NULL, resume=FALSE) {
  if(!is.data.frame(new_data)) cli::cli_abort("{.arg new_data} must be a data.frame.")
  plan<-smf_chunk_plan(nrow(new_data),batch_size); object_hash<-.smf_batch_object_hash(object); input_hash<-smf_data_hash(new_data)
  resumed<-FALSE; entries<-list(); completed<-integer(); old<-NULL
  if(!is.null(checkpoint_dir)) {
    dir.create(checkpoint_dir,recursive=TRUE,showWarnings=FALSE)
    old<-.smf_read_batch_manifest(checkpoint_dir)
    if(isTRUE(resume) && !is.null(old)) {
      if(!.smf_batch_manifest_compatible(old,input_hash,object_hash,nrow(new_data),batch_size)) .smf_abort("BATCH_RESUME_MISMATCH","Existing checkpoint metadata does not match the current data/object/batch size.",class="smf_persistence_error")
      entries<-old$batches %||% list(); completed<-as.integer(vapply(entries,function(z)z$batch_id,integer(1))); resumed<-length(completed)>0L
      invisible(lapply(entries,function(e).smf_batch_checkpoint_read(checkpoint_dir,e)))
    }
  }
  todo<-setdiff(seq_along(plan),completed)
  worker_fun<-function(i) .smf_predict_any(object,new_data[plan[[i]],,drop=FALSE],strict_schema)
  if(length(todo) && workers>1L) {
    cl<-parallel::makePSOCKcluster(as.integer(workers)); on.exit(parallel::stopCluster(cl),add=TRUE)
    parallel::clusterEvalQ(cl,library(sciModelFlowR)); parallel::clusterExport(cl,c("object","new_data","plan","strict_schema"),envir=environment())
    vals<-parallel::parLapply(cl,todo,function(i) sciModelFlowR:::.smf_predict_any(object,new_data[plan[[i]],,drop=FALSE],strict_schema))
    names(vals)<-as.character(todo)
  } else vals<-setNames(lapply(todo,worker_fun),as.character(todo))
  if(!is.null(checkpoint_dir)) {
    for(i in todo) entries[[length(entries)+1L]]<-.smf_batch_checkpoint_write(checkpoint_dir,i,vals[[as.character(i)]])
    entries<-entries[order(vapply(entries,function(z)z$batch_id,integer(1)))]
    man<-list(schema_version="1.0.0",created_at=.smf_now(),input_hash=input_hash,object_hash=object_hash,n_rows=nrow(new_data),batch_size=as.integer(batch_size),batches=entries)
    .smf_atomic_write_json(man,.smf_batch_manifest_file(checkpoint_dir)); pieces<-lapply(entries,function(e).smf_batch_checkpoint_read(checkpoint_dir,e))
  } else pieces<-lapply(seq_along(plan),function(i) vals[[as.character(i)]])
  pred<-if(!length(pieces))data.frame() else do.call(rbind,lapply(pieces,.smf_prediction_frame))
  rownames(pred)<-NULL
  BatchPredictionResult(n_rows=as.integer(nrow(new_data)),n_batches=as.integer(length(plan)),prediction=pred,batch_manifest=list(input_hash=input_hash,object_hash=object_hash,batch_size=as.integer(batch_size),checkpoint_dir=checkpoint_dir),resumed=isTRUE(resumed),provenance=list(workers=as.integer(workers),strict_schema=isTRUE(strict_schema),created_at=.smf_now()))
}

#' Apply a function to iterator chunks
#' @export
smf_map_iterator <- function(iterator, FUN, ..., reset=TRUE) {
  if(!inherits(iterator,"smf_data_iterator")) cli::cli_abort("{.arg iterator} must be returned by smf_data_iterator().")
  if(!is.function(FUN)) cli::cli_abort("{.arg FUN} must be a function.")
  if(isTRUE(reset)) smf_iterator_reset(iterator); out<-list(); i<-0L
  repeat { chunk<-smf_iterator_next(iterator); if(is.null(chunk))break; i<-i+1L; out[[i]]<-FUN(chunk,...) }
  out
}
