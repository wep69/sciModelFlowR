.smf_make_meta <- function(data,spec,split=NULL,backend="core",backend_version=character(),warnings=list()) {
  ResultMeta(run_id=.smf_new_run_id(),created_at=.smf_now(),package_version=.smf_version(),backend=backend,backend_version=.smf_chr(backend_version),data_hash=smf_data_hash(data),split_hash=if(is.null(split)) character() else split@hash,spec_hash=smf_hash(spec),seed=as.integer(spec@reproducibility@seed),warnings=warnings,provenance=list())
}

.smf_target_data <- function(data,task) {
  if(task@kind=="multioutput_regression") return(data[task@target])
  data[[task@target[[1]]]]
}

.smf_apply_feature_state <- function(feature_result,x) {
  if(is.null(feature_result)) return(x)
  if(S7::S7_inherits(feature_result,RepresentationResult)) return(smf_apply_representation(feature_result,x))
  if(S7::S7_inherits(feature_result,FeatureSelectionResult)) {
    .smf_abort_missing_columns(x,feature_result@selected,"feature-selected prediction")
    return(x[feature_result@selected])
  }
  x
}

.smf_feature_fit <- function(spec,x_train,y_train) {
  if(is.null(spec@features) || spec@features@method=="none") return(list(state=NULL,x=x_train))
  if(spec@task@kind=="multioutput_regression") .smf_abort("MULTIOUTPUT_FEATURE_UNCERTIFIED","Feature selection/representation with multi-output targets is deferred until a validated multivariate selection contract is available.",class="smf_capability_error")
  fsdat<-x_train; fsdat$.smf_outcome<-y_train
  if(spec@features@method %in% c("pca","pls")) {
    state<-smf_build_representation(fsdat,".smf_outcome",spec@features,context="training")
    return(list(state=state,x=state@transformed))
  }
  state<-smf_select_features(fsdat,".smf_outcome",spec@features,context="training")
  if(!length(state@selected)) .smf_abort("FEATURE_SELECTION_EMPTY","Feature selection removed all predictors.",class="smf_validation_error")
  list(state=state,x=x_train[state@selected])
}

.smf_calibration_partition <- function(train,spec,calibration_data=NULL,seed=260915L) {
  cal_spec<-spec@calibration
  if(is.null(cal_spec) || cal_spec@method=="none") return(list(model=train,calibration=NULL,split=NULL))
  if(!spec@task@kind %in% c("binary","multiclass")) .smf_abort("CALIBRATION_TASK_UNSUPPORTED","Probability calibration currently requires a classification task.",class="smf_calibration_error")
  if(cal_spec@source=="external_predictions") {
    if(is.null(calibration_data)) .smf_abort("CALIBRATION_DATA_REQUIRED","CalibrationSpec source='external_predictions' requires calibration_data.",class="smf_calibration_error")
    id<-spec@design@id_column
    if(length(id) && id %in% names(train) && id %in% names(calibration_data) && length(intersect(train[[id]],calibration_data[[id]]))) .smf_abort("CALIBRATION_ID_OVERLAP","External calibration data overlap the analysis training IDs.",class="smf_leakage_error")
    return(list(model=train,calibration=calibration_data,split=NULL))
  }
  target<-spec@task@target[[1]]; id<-spec@design@id_column
  sp<-smf_holdout_split(train,train_prop=1-cal_spec@calibration_prop,strata=target,id_column=id,seed=seed+701L)
  list(model=train[sp@train_index,,drop=FALSE],calibration=train[sp@test_index,,drop=FALSE],split=sp)
}

.smf_fit_supervised_partition <- function(spec,train,test,calibration_data=NULL,seed=260915L) {
  cp<-.smf_calibration_partition(train,spec,calibration_data,seed)
  model_train<-cp$model; cal_raw<-cp$calibration
  pre<-smf_fit_preprocessor(model_train,spec@preprocessing,spec@data,role="training")
  x_model<-smf_apply_preprocessor(pre,model_train); x_test<-smf_apply_preprocessor(pre,test)
  y_model<-.smf_target_data(model_train,spec@task); y_test<-.smf_target_data(test,spec@task)
  x_cal<-if(is.null(cal_raw)) NULL else smf_apply_preprocessor(pre,cal_raw)
  y_cal<-if(is.null(cal_raw)) NULL else .smf_target_data(cal_raw,spec@task)

  fs<-.smf_feature_fit(spec,x_model,y_model); feature_result<-fs$state; x_model<-fs$x
  x_test<-.smf_apply_feature_state(feature_result,x_test)
  if(!is.null(x_cal)) x_cal<-.smf_apply_feature_state(feature_result,x_cal)

  imbalance_result<-NULL; weights<-NULL
  if(spec@task@kind %in% c("binary","multiclass")) {
    imb_spec<-spec@imbalance %||% smf_imbalance_spec("none")
    dfit<-x_model; dfit$.smf_target<-y_model
    imbalance_result<-smf_apply_imbalance(dfit,".smf_target",imb_spec,context="analysis",seed=seed+911L)
    weights<-imbalance_result@weights; dfit<-imbalance_result@data
    y_model<-dfit$.smf_target; x_model<-dfit[setdiff(names(dfit),".smf_target")]
  } else if(!is.null(spec@imbalance) && spec@imbalance@method!="none") .smf_abort("IMBALANCE_TASK_UNSUPPORTED","Class-imbalance operations require classification tasks.",class="smf_capability_error")

  adapter_fit<-smf_fit_model(spec@task,spec@model,x_model,y_model,weights=weights)
  calibration_result<-NULL; distribution<-NULL; probabilities<-NULL
  if(spec@task@kind %in% c("binary","multiclass")) {
    raw_test<-smf_predict_model(adapter_fit,spec@task,x_test,type="prob"); .smf_validate_prob_matrix(raw_test)
    probabilities<-raw_test
    if(!is.null(cal_raw)) {
      raw_cal<-smf_predict_model(adapter_fit,spec@task,x_cal,type="prob"); .smf_validate_prob_matrix(raw_cal,y_cal)
      calibration_result<-smf_calibrate(y_cal,raw_cal,spec@calibration,training_data=cal_raw)
      probabilities<-smf_apply_calibration(calibration_result,raw_test); .smf_validate_prob_matrix(probabilities)
    }
    threshold<-(spec@imbalance %||% smf_imbalance_spec("none"))@threshold
    estimate<-.smf_classification_from_prob(probabilities,threshold=threshold,positive=if(length(spec@task@positive_label)) as.character(spec@task@positive_label) else NULL)
    distribution<-smf_prediction_distribution("class_probabilities",list(prob=probabilities,classes=colnames(probabilities)),UncertaintyDescriptor(source="analytical",target="class_probability",interval_type="none",level=NA_real_,conditional_on="fitted supervised model"),list(log_prob=TRUE,calibration=TRUE))
    metrics<-smf_evaluate(y_test,probabilities,spec@metrics,positive_label=if(length(spec@task@positive_label))as.character(spec@task@positive_label) else NULL,threshold=threshold)
  } else {
    estimate<-smf_predict_model(adapter_fit,spec@task,x_test,type="response")
    distribution<-if(spec@task@kind=="multioutput_regression") NULL else smf_prediction_distribution("point",list(mean=as.numeric(estimate)),UncertaintyDescriptor(source="analytical",target="prediction",interval_type="none",level=NA_real_,conditional_on="fitted supervised model"),list(mean=TRUE))
    metrics<-smf_evaluate(y_test,estimate,spec@metrics)
  }
  list(preprocessor=pre,feature_result=feature_result,imbalance=imbalance_result,adapter_fit=adapter_fit,calibration=calibration_result,calibration_split=cp$split,estimate=estimate,probabilities=probabilities,distribution=distribution,truth=y_test,metrics=metrics,predictors=colnames(x_model),model_n=nrow(x_model),calibration_n=if(is.null(cal_raw))0L else nrow(cal_raw))
}

#' Fit a complete managed scientific experiment
#' @export
smf_fit_experiment <- function(spec,data,split=NULL,calibration_data=NULL) {
  started<-proc.time()[[3]]
  smf_validate_schema(data,spec@data)
  design_warnings<-smf_validate_design(data,spec@design,spec@resampling)
  resampling_warnings<-smf_validate_resampling_design(data,spec@resampling,spec@design,override=FALSE)
  audit<-smf_audit_data(data,spec@data,spec@design)
  blocking<-vapply(audit@quality_flags,function(w)identical(w@severity,"blocking"),logical(1))
  if(any(blocking)) .smf_abort("BLOCKING_DATA_AUDIT","Data audit identified a blocking scientific defect.",evidence=list(warnings=audit@quality_flags[blocking]),class="smf_leakage_error")
  if(is.null(split)) {
    if(!spec@resampling@method %in% c("holdout","stratified_holdout")) .smf_abort("MULTI_RESAMPLE_REQUIRES_RESAMPLE_EXPERIMENT","Use smf_resample_experiment() for multi-split resampling.")
    strata<-if(spec@resampling@method=="stratified_holdout")spec@resampling@strata else character()
    split<-smf_holdout_split(data,spec@resampling@train_prop,strata,spec@design@id_column,spec@resampling@seed)
  }
  smf_validate_split(split,nrow(data)); train<-data[split@train_index,,drop=FALSE]; test<-data[split@test_index,,drop=FALSE]
  if (!is.null(calibration_data)) {
    id <- spec@design@id_column
    if (length(id) && id %in% names(calibration_data) && id %in% names(test) && length(intersect(calibration_data[[id]], test[[id]]))) {
      .smf_abort("CALIBRATION_TEST_OVERLAP", "Calibration data overlap the final test IDs.", evidence=list(id_column=id), class="smf_leakage_error")
    }
  }
  smf_require_capability(spec@model@engine,.smf_task_capability(spec@task))
  core<-.smf_fit_supervised_partition(spec,train,test,calibration_data,seed=spec@reproducibility@seed)
  all_warnings<-c(design_warnings,resampling_warnings,audit@quality_flags)
  rec<-smf_backend_capabilities(spec@model@engine)
  meta<-.smf_make_meta(data,spec,split,backend=spec@model@engine,backend_version=if(length(rec$package)&&.smf_package_available(rec$package[[1]]))as.character(utils::packageVersion(rec$package[[1]])) else character(),warnings=all_warnings)
  fit_result<-FitResult(meta=meta,model_spec=spec@model,preprocessing=core$preprocessor,features=core$feature_result,training_summary=list(n=core$model_n,task_kind=spec@task@kind,class_levels=core$adapter_fit$class_levels,imbalance=if(is.null(core$imbalance))NULL else smf_to_list(core$imbalance),calibration=core$calibration,calibration_n=core$calibration_n,calibration_split=if(is.null(core$calibration_split))NULL else smf_split_manifest(core$calibration_split)),backend_object=core$adapter_fit,predictors=core$predictors,target=spec@task@target)
  ids<-if(length(spec@design@id_column))test[[spec@design@id_column]] else split@test_index
  pred_result<-PredictionResult(meta=meta,row_ids=ids,estimate=core$estimate,truth=core$truth,probabilities=core$probabilities,response_scale=if(spec@task@kind %in% c("binary","multiclass"))"class_probability" else "response",intervals=NULL,distribution=core$distribution,calibration=core$calibration)
  diag<-smf_diagnose_fit(fit_result,pred_result); duration<-proc.time()[[3]]-started
  manifest<-RunManifest(run_id=meta@run_id,created_at=meta@created_at,package_version=meta@package_version,R_version=R.version.string,platform=R.version$platform,architecture=R.version$arch,dependency_versions=.smf_dependency_versions(),backend=spec@model@engine,backend_version=meta@backend_version,rng_kind=RNGkind(),seed=as.integer(spec@reproducibility@seed),data_hash=meta@data_hash,schema_hash=smf_hash(list(names=names(data),classes=vapply(data,class,character(1)))),spec_hash=meta@spec_hash,split_hash=split@hash,preprocessing_hash=smf_hash(smf_preprocess_provenance(core$preprocessor)),model_spec=smf_to_list(spec@model),metrics=core$metrics,warnings=all_warnings,hardware=.smf_hardware_info(),duration_seconds=as.numeric(duration))
  ExperimentResult(meta=meta,spec=spec,audit=audit,split=split,fit=fit_result,prediction=pred_result,diagnostics=diag,metrics=core$metrics,manifest=manifest)
}

#' Predict from a fitted result using its training-only preprocessing and calibration state
#' @export
smf_predict <- function(result,new_data) {
  fit<-if(S7::S7_inherits(result,ExperimentResult))result@fit else result
  if(!S7::S7_inherits(fit,FitResult)) cli::cli_abort("{.arg result} must contain a FitResult.")
  x<-smf_apply_preprocessor(fit@preprocessing,new_data); x<-.smf_apply_feature_state(fit@features,x)
  task_kind<-fit@training_summary$task_kind %||% "regression"; task<-smf_task_spec(task_kind,target=fit@target,positive_label=if(length(fit@training_summary$class_levels)==2L)tail(fit@training_summary$class_levels,1) else NULL)
  if(task_kind %in% c("binary","multiclass")) {
    prob<-smf_predict_model(fit@backend_object,task,x,type="prob"); cal<-fit@training_summary$calibration
    if(!is.null(cal)) prob<-smf_apply_calibration(cal,prob)
    .smf_validate_prob_matrix(prob); return(prob)
  }
  smf_predict_model(fit@backend_object,task,x,type="response")
}

#' Explicit escape hatch to the backend-native object
#' @export
smf_backend_object <- function(result) {
  fit<-if(S7::S7_inherits(result,ExperimentResult))result@fit else result
  if(!S7::S7_inherits(fit,FitResult)) cli::cli_abort("No backend fit is available.")
  obj<-fit@backend_object
  if(inherits(obj,"smf_adapter_fit")) obj$object else obj
}
