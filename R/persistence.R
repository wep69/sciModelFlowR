.smf_bundle_schema_version <- "1.0.0"

#' Create a persistence specification
#' @export
smf_persistence_spec <- function(schema_version=.smf_bundle_schema_version,
                                 mode=c("safe_preferred","portable_only","opaque_allowed"),
                                 checksum="sha256", trusted_required=TRUE, parameters=list()) {
  PersistenceSpec(schema_version=.smf_scalar_chr(schema_version,"schema_version"),mode=match.arg(mode),checksum=.smf_scalar_chr(checksum,"checksum"),trusted_required=.smf_scalar_lgl(trusted_required,"trusted_required"),parameters=parameters)
}

#' Create a deployment specification
#' @export
smf_deployment_spec <- function(adapter=c("local","none","pins","vetiver","onnx"), strict_schema=TRUE,
                                batch_size=1000L, parameters=list()) {
  DeploymentSpec(adapter=match.arg(adapter),strict_schema=.smf_scalar_lgl(strict_schema,"strict_schema"),batch_size=as.integer(batch_size),parameters=parameters)
}

#' Create a scalability specification
#' @export
smf_scalability_spec <- function(chunk_size=1000L, workers=1L, execution=c("sequential","parallel"),
                                 checkpoint_every=1L, parameters=list()) {
  ScalabilitySpec(chunk_size=as.integer(chunk_size),workers=as.integer(workers),execution=match.arg(execution),checkpoint_every=as.integer(checkpoint_every),parameters=parameters)
}

.smf_file_sha256 <- function(path) digest::digest(file=path,algo="sha256",serialize=FALSE)
.smf_relpath <- function(path,root) {
  p<-normalizePath(path,winslash="/",mustWork=FALSE); r<-normalizePath(root,winslash="/",mustWork=FALSE)
  prefix<-paste0(r,"/"); if(startsWith(p,prefix)) substring(p,nchar(prefix)+1L) else basename(p)
}


.smf_write_checksum_manifest <- function(root) {
  files <- list.files(root,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE)
  files <- files[file.info(files)$isdir %in% FALSE]
  files <- files[basename(files)!="checksums.sha256"]
  rel <- vapply(files,.smf_relpath,character(1),root=root)
  ord <- order(rel); files<-files[ord]; rel<-rel[ord]
  lines <- paste(vapply(files,.smf_file_sha256,character(1)),rel,sep="  ")
  .smf_atomic_write_text(lines,file.path(root,"checksums.sha256")); invisible(lines)
}

.smf_read_checksums <- function(path) {
  f<-file.path(path,"checksums.sha256"); if(!file.exists(f)) .smf_abort("BUNDLE_CHECKSUMS_MISSING","Bundle has no checksums.sha256.",class="smf_persistence_error")
  lines<-readLines(f,warn=FALSE); lines<-lines[nzchar(lines)]
  m<-regexec("^([0-9a-fA-F]{64})  (.+)$",lines); parts<-regmatches(lines,m)
  if(any(lengths(parts)!=3L)) .smf_abort("BUNDLE_CHECKSUM_FORMAT","checksums.sha256 has an invalid line.",class="smf_persistence_error")
  data.frame(sha256=vapply(parts,`[[`,character(1),2),file=vapply(parts,`[[`,character(1),3),stringsAsFactors=FALSE)
}

.smf_version_major <- function(x) suppressWarnings(as.integer(strsplit(as.character(x),"\\.",fixed=FALSE)[[1]][1]))

.smf_inference_schema <- function(result) {
  pre<-result@fit@preprocessing; st<-pre@state
  list(schema_version=.smf_bundle_schema_version,required_predictors=st$predictors,numeric=st$numeric,categorical=st$categorical,categorical_levels=st$levels,target=result@spec@task@target,task_kind=result@spec@task@kind,id_column=result@spec@design@id_column)
}

.smf_portable_stats_state <- function(adapter_fit,predictors) {
  if(!inherits(adapter_fit,"smf_adapter_fit") || adapter_fit$engine!="stats") return(NULL)
  obj<-adapter_fit$object
  one <- function(m) {
    if(!inherits(m,c("lm","glm"))) return(NULL)
    cf<-stats::coef(m)
    if(anyNA(cf)) return(NULL)
    needed<-setdiff(names(cf),"(Intercept)")
    if(!all(needed %in% predictors)) return(NULL)
    fam<-if(inherits(m,"glm")) m$family$family else "gaussian"
    link<-if(inherits(m,"glm")) m$family$link else "identity"
    list(coefficients=as.list(unclass(cf)),coefficient_names=names(cf),family=fam,link=link)
  }
  if(inherits(obj,"smf_stats_multioutput")) {
    states<-lapply(obj$models,one); if(any(vapply(states,is.null,logical(1)))) return(NULL)
    return(list(type="stats_multioutput_portable",engine="stats",task_kind=adapter_fit$task_kind,class_levels=adapter_fit$class_levels,predictors=predictors,targets=obj$targets,models=states))
  }
  s<-one(obj); if(is.null(s)) return(NULL)
  list(type="stats_portable",engine="stats",task_kind=adapter_fit$task_kind,class_levels=adapter_fit$class_levels,predictors=predictors,model=s)
}

.smf_portable_features <- function(x) {
  if(is.null(x)) return("none")
  if(S7::S7_inherits(x,FeatureSelectionResult)) return("selection")
  NULL
}

.smf_bundle_mode <- function(result,mode) {
  mode<-match.arg(mode,c("auto","portable","opaque"))
  portable_model<-.smf_portable_stats_state(result@fit@backend_object,result@fit@predictors)
  portable_features<-.smf_portable_features(result@fit@features)
  calibration<-result@fit@training_summary$calibration
  can_portable<-!is.null(portable_model) && !is.null(portable_features) && is.null(calibration)
  if(mode=="portable" && !can_portable) .smf_abort("PORTABLE_BUNDLE_UNSUPPORTED","Portable bundles currently require a stats lm/glm model, numeric post-preprocessing predictors, no opaque representation state, and no fitted probability calibrator. Use mode='opaque' for other fitted states.",class="smf_capability_error")
  if(mode=="auto") mode<-if(can_portable)"portable" else "opaque"
  list(mode=mode,portable_model=portable_model,portable_features=portable_features)
}

.smf_bundle_readme <- function(manifest) paste0(
  "# sciModelFlowR inference bundle\n\n",
  "Bundle schema: `",manifest$bundle_schema_version,"`\n\n",
  "Model storage: `",manifest$model_storage,"`\n\n",
  if(isTRUE(manifest$unsafe)) "This bundle contains opaque serialized R state. Loading the model requires explicit `trusted = TRUE` after checksum validation.\n" else "This bundle uses the portable safe-state path supported by sciModelFlowR.\n",
  "\nChecksums must be validated before any model state is loaded.\n"
)

#' Save a validated inference bundle
#' @export
smf_save_bundle <- function(result, path, mode=c("auto","portable","opaque"), overwrite=FALSE) {
  if(!S7::S7_inherits(result,ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  path<-normalizePath(path,mustWork=FALSE); if(dir.exists(path) && !isTRUE(overwrite)) .smf_abort("BUNDLE_EXISTS","Bundle path already exists; set overwrite=TRUE to replace it.",class="smf_persistence_error")
  choice<-.smf_bundle_mode(result,match.arg(mode)); stage<-tempfile(pattern="smf-bundle-"); dir.create(stage,recursive=TRUE)
  on.exit(unlink(stage,recursive=TRUE,force=TRUE),add=TRUE); dir.create(file.path(stage,"model"),recursive=TRUE)
  schema<-.smf_inference_schema(result); hardware<-.smf_hardware_info()
  manifest<-list(bundle_schema_version=.smf_bundle_schema_version,package="sciModelFlowR",package_version=.smf_version(),created_at=.smf_now(),source_run_id=result@meta@run_id,spec_hash=result@meta@spec_hash,schema_hash=smf_hash(schema),backend=result@spec@model@engine,backend_version=result@meta@backend_version,model_storage=choice$mode,unsafe=identical(choice$mode,"opaque"),hardware=hardware,provenance=list(data_hash=result@meta@data_hash,split_hash=result@meta@split_hash,preprocessing_hash=smf_hash(smf_preprocess_provenance(result@fit@preprocessing))))
  .smf_atomic_write_text(smf_to_json(result@spec,pretty=TRUE),file.path(stage,"spec.json"))
  .smf_atomic_write_json(schema,file.path(stage,"schema.json"))
  .smf_atomic_write_text(smf_to_json(result@fit@preprocessing,pretty=TRUE),file.path(stage,"preprocessing.json"))
  .smf_atomic_write_json(list(class_levels=result@fit@training_summary$class_levels %||% character(),positive_label=result@spec@task@positive_label),file.path(stage,"labels.json"))
  .smf_atomic_write_text(smf_to_json(result@manifest,pretty=TRUE),file.path(stage,"run_manifest.json"))
  if(choice$mode=="portable") {
    .smf_atomic_write_json(choice$portable_model,file.path(stage,"model","model_state.json"))
    if(identical(choice$portable_features,"none")) .smf_atomic_write_json(list(type="none"),file.path(stage,"features.json"))
    else .smf_atomic_write_text(smf_to_json(result@fit@features,pretty=TRUE),file.path(stage,"features.json"))
  } else {
    saveRDS(result@fit@backend_object,file.path(stage,"model","model.rds"),version=3)
    saveRDS(result@fit@features,file.path(stage,"features.rds"),version=3)
    if(!is.null(result@fit@training_summary$calibration)) saveRDS(result@fit@training_summary$calibration,file.path(stage,"calibration.rds"),version=3)
  }
  .smf_atomic_write_json(manifest,file.path(stage,"manifest.json")); .smf_atomic_write_text(.smf_bundle_readme(manifest),file.path(stage,"README.md")); .smf_write_checksum_manifest(stage)
  if(dir.exists(path)) unlink(path,recursive=TRUE,force=TRUE)
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  if(!file.rename(stage,path)) { dir.create(path,recursive=TRUE); ok<-file.copy(list.files(stage,full.names=TRUE,all.files=TRUE,no..=TRUE),path,recursive=TRUE,copy.mode=TRUE); if(!all(ok)) .smf_abort("BUNDLE_FINALIZE_FAILED","Could not finalize the bundle directory.",class="smf_persistence_error") }
  invisible(normalizePath(path,mustWork=TRUE))
}

#' Validate bundle checksums and compatibility before loading
#' @export
smf_validate_bundle <- function(path, strict=TRUE) {
  path<-normalizePath(path,mustWork=TRUE); req<-c("manifest.json","spec.json","schema.json","preprocessing.json","labels.json","run_manifest.json","README.md","checksums.sha256")
  missing<-req[!file.exists(file.path(path,req))]; if(length(missing)) .smf_abort("BUNDLE_FILES_MISSING",paste0("Bundle is missing: ",paste(missing,collapse=", "),"."),class="smf_persistence_error")
  manifest<-.smf_read_json_list(file.path(path,"manifest.json")); cs<-.smf_read_checksums(path)
  actual<-vapply(cs$file,function(rel){p<-file.path(path,rel); if(!file.exists(p))NA_character_ else .smf_file_sha256(p)},character(1)); ok<-!is.na(actual) & tolower(actual)==tolower(cs$sha256)
  if(any(!ok)) .smf_abort("BUNDLE_CHECKSUM_MISMATCH",paste0("Bundle checksum verification failed for: ",paste(cs$file[!ok],collapse=", "),"."),evidence=list(files=cs$file[!ok]),class="smf_persistence_error")
  current_major<-.smf_version_major(.smf_bundle_schema_version); bundle_major<-.smf_version_major(manifest$bundle_schema_version)
  compat<-list(schema_major_compatible=identical(current_major,bundle_major),bundle_schema_version=manifest$bundle_schema_version,current_schema_version=.smf_bundle_schema_version,package_version=manifest$package_version,backend=manifest$backend,backend_version=manifest$backend_version)
  if(!isTRUE(compat$schema_major_compatible) && isTRUE(strict)) .smf_abort("BUNDLE_SCHEMA_MAJOR_INCOMPATIBLE",paste0("Bundle schema ",manifest$bundle_schema_version," is incompatible with reader schema ",.smf_bundle_schema_version,". Use an explicit migration step before loading."),evidence=compat,class="smf_persistence_error")
  unsafe<-if(isTRUE(manifest$unsafe)) c("model/model.rds","features.rds","calibration.rds") else character(); unsafe<-unsafe[file.exists(file.path(path,unsafe))]
  BundleValidationResult(valid=all(ok)&&isTRUE(compat$schema_major_compatible),path=path,manifest=manifest,checksums=data.frame(file=cs$file,expected=cs$sha256,actual=actual,valid=ok,stringsAsFactors=FALSE),compatibility=compat,unsafe_components=unsafe,warnings=list())
}

.smf_read_portable_feature <- function(path) {
  file<-file.path(path,"features.json"); x<-.smf_read_json_list(file)
  if(is.null(x)||identical(x$type,"none")) return(NULL)
  if(identical(x$`__class__`,"FeatureSelectionResult")) return(smf_from_json(file))
  .smf_abort("PORTABLE_FEATURE_UNKNOWN","Unknown portable feature-state type.",class="smf_persistence_error")
}

.smf_make_portable_adapter <- function(state) {
  structure(list(object=structure(list(state=state),class="smf_portable_stats_fit"),engine="stats",task_kind=state$task_kind,target=character(),class_levels=.smf_chr(state$class_levels),model_spec=NULL),class="smf_adapter_fit")
}

#' Load an inference bundle after checksum and trust checks
#' @export
smf_load_bundle <- function(path, trusted=FALSE) {
  val<-smf_validate_bundle(path,strict=TRUE); manifest<-val@manifest
  if(isTRUE(manifest$unsafe) && !isTRUE(trusted)) .smf_abort("UNTRUSTED_BUNDLE","This bundle contains opaque serialized R state. Checksum verification succeeded, but loading requires explicit trusted=TRUE because serialization is not treated as a safe interchange format.",evidence=list(unsafe_components=val@unsafe_components),class="smf_security_error")
  spec<-smf_from_json(file.path(path,"spec.json")); pre<-smf_from_json(file.path(path,"preprocessing.json")); schema<-.smf_read_json_list(file.path(path,"schema.json")); labels<-.smf_read_json_list(file.path(path,"labels.json"))
  if(identical(manifest$model_storage,"portable")) {
    st<-.smf_read_json_list(file.path(path,"model","model_state.json")); model<-.smf_make_portable_adapter(st); features<-.smf_read_portable_feature(path); calibration<-NULL; safe<-TRUE
  } else {
    model<-readRDS(file.path(path,"model","model.rds")); features<-if(file.exists(file.path(path,"features.rds")))readRDS(file.path(path,"features.rds")) else NULL; calibration<-if(file.exists(file.path(path,"calibration.rds")))readRDS(file.path(path,"calibration.rds")) else NULL; safe<-FALSE
  }
  InferenceBundle(path=normalizePath(path,mustWork=TRUE),manifest=manifest,spec=spec,task=spec@task,preprocessing=pre,features=features,model=model,calibration=calibration,schema=schema,labels=labels,safe=safe,provenance=list(validation=smf_to_list(val),trusted=isTRUE(trusted)))
}

.smf_bundle_schema_check <- function(bundle,new_data,strict=TRUE) {
  req<-unlist(bundle@schema$required_predictors,use.names=FALSE); .smf_abort_missing_columns(new_data,req,"inference bundle")
  if(isTRUE(strict)) {
    numeric<-unlist(bundle@schema$numeric,use.names=FALSE); bad<-numeric[numeric %in% names(new_data) & !vapply(new_data[numeric],is.numeric,logical(1))]
    if(length(bad)) .smf_abort("BUNDLE_SCHEMA_TYPE_MISMATCH",paste0("Numeric predictors have incompatible input types: ",paste(bad,collapse=", "),"."),class="smf_validation_error")
  }
  invisible(TRUE)
}

#' Predict from a loaded inference bundle
#' @export
smf_predict_bundle <- function(bundle, new_data, strict_schema=TRUE, type=c("auto","response","prob")) {
  if(!S7::S7_inherits(bundle,InferenceBundle)) cli::cli_abort("{.arg bundle} must be returned by smf_load_bundle().")
  if(!is.data.frame(new_data)) cli::cli_abort("{.arg new_data} must be a data.frame.")
  .smf_bundle_schema_check(bundle,new_data,strict_schema); x<-smf_apply_preprocessor(bundle@preprocessing,new_data); x<-.smf_apply_feature_state(bundle@features,x)
  type<-match.arg(type)
  if(bundle@task@kind %in% c("binary","multiclass")) {
    prob<-smf_predict_model(bundle@model,bundle@task,x,type="prob")
    if(!is.null(bundle@calibration)) prob<-smf_apply_calibration(bundle@calibration,prob)
    .smf_validate_prob_matrix(prob)
    if(type %in% c("auto","prob")) return(prob)
    threshold<-if(!is.null(bundle@spec@imbalance)) bundle@spec@imbalance@threshold else 0.5
    positive<-if(length(bundle@task@positive_label)) as.character(bundle@task@positive_label) else NULL
    return(.smf_classification_from_prob(prob,threshold=threshold,positive=positive))
  }
  smf_predict_model(bundle@model,bundle@task,x,type="response")
}

#' Return concise bundle metadata without loading model state
#' @export
smf_bundle_info <- function(path) {
  val<-smf_validate_bundle(path,strict=FALSE); list(manifest=val@manifest,compatibility=val@compatibility,unsafe_components=val@unsafe_components,valid=val@valid)
}
