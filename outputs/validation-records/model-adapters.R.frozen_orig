# Backend adapters introduced in 0.3.0. They return package-standardized
# predictions and keep backend-native objects behind FitResult.

.smf_task_capability <- function(task) {
  switch(task@kind,
    regression="regression", binary="classification", multiclass="multiclass",
    multioutput_regression="multioutput", count="regression", "classification")
}

.smf_standardize_truth <- function(task, y) {
  if (task@kind %in% c("binary","multiclass")) {
    y <- as.factor(y)
    if (task@kind == "binary" && nlevels(y) != 2L) .smf_abort("BINARY_LEVELS", "Binary classification requires exactly two outcome levels.", class="smf_validation_error")
    if (task@kind == "binary" && length(task@positive_label)) {
      pos <- as.character(task@positive_label)[[1]]
      if (!pos %in% levels(y)) .smf_abort("POSITIVE_LABEL_UNKNOWN", "positive_label is absent from the binary outcome levels.", class="smf_validation_error")
      neg <- setdiff(levels(y), pos)
      y <- factor(y, levels=c(neg, pos))
    }
  }
  y
}

.smf_stats_fit <- function(task, model, x, y, weights=NULL) {
  if (task@kind == "multioutput_regression") {
    yy <- as.data.frame(y)
    fits <- lapply(names(yy), function(nm) {
      d <- x; d$.smf_target <- yy[[nm]]
      stats::lm(.smf_target ~ ., data=d, weights=weights)
    })
    names(fits) <- names(yy)
    return(structure(list(models=fits, targets=names(yy)), class="smf_stats_multioutput"))
  }
  y <- .smf_standardize_truth(task,y)
  d <- x; d$.smf_target <- y
  if (task@kind == "regression" && model@family %in% c("linear_regression","lm")) return(stats::lm(.smf_target ~ ., data=d, weights=weights))
  if (task@kind == "binary" && model@family %in% c("logistic_regression","glm_binomial","glm")) return(stats::glm(.smf_target ~ ., data=d, family=stats::binomial(), weights=weights))
  if (task@kind == "count" && model@family %in% c("poisson_regression","glm_poisson","glm")) return(stats::glm(.smf_target ~ ., data=d, family=stats::poisson(), weights=weights))
  .smf_abort("STATS_MODEL_UNSUPPORTED", paste0("stats adapter does not support task=",task@kind," and family=",model@family,"."), class="smf_capability_error")
}

.smf_parsnip_spec <- function(task, model) {
  if (!requireNamespace("parsnip",quietly=TRUE)) .smf_abort("PARsnip_MISSING","Package 'parsnip' is required for the tidymodels adapter.",class="smf_capability_error")
  args <- model@parameters$model_args %||% list()
  mode <- if (task@kind %in% c("binary","multiclass")) "classification" else "regression"
  fam <- model@family
  spec <- switch(fam,
    linear_regression=do.call(parsnip::linear_reg,args),
    logistic_regression=do.call(parsnip::logistic_reg,args),
    multinomial_regression=do.call(parsnip::multinom_reg,args),
    random_forest=do.call(parsnip::rand_forest,c(args,list(mode=mode))),
    boosted_tree=do.call(parsnip::boost_tree,c(args,list(mode=mode))),
    decision_tree=do.call(parsnip::decision_tree,c(args,list(mode=mode))),
    nearest_neighbor=do.call(parsnip::nearest_neighbor,c(args,list(mode=mode))),
    svm_rbf=do.call(parsnip::svm_rbf,c(args,list(mode=mode))),
    poisson_regression=do.call(parsnip::poisson_reg,args),
    .smf_abort("PARsnip_FAMILY_UNSUPPORTED",paste0("No tidymodels mapping for family '",fam,"'."),class="smf_capability_error")
  )
  native_engine <- model@parameters$model_engine %||% switch(fam,
    linear_regression="lm",logistic_regression="glm",poisson_regression="glm",
    decision_tree="rpart",nearest_neighbor="kknn",svm_rbf="kernlab",
    random_forest="ranger",boosted_tree="xgboost",multinomial_regression="nnet",NULL)
  if (is.null(native_engine)) .smf_abort("PARsnip_ENGINE_REQUIRED","Specify model@parameters$model_engine for this tidymodels family.",class="smf_capability_error")
  eng_args <- model@parameters$engine_args %||% list()
  do.call(parsnip::set_engine,c(list(object=spec,engine=native_engine),eng_args))
}

.smf_tidymodels_fit <- function(task, model, x, y, weights=NULL) {
  if (task@kind == "multioutput_regression") .smf_abort("TIDYMODELS_MULTIOUTPUT_UNCERTIFIED","Generic multi-output fitting is not certified for the tidymodels adapter in 0.3.0.",class="smf_capability_error")
  spec <- .smf_parsnip_spec(task,model)
  y <- .smf_standardize_truth(task,y)
  cw <- NULL
  if (!is.null(weights)) {
    if (!requireNamespace("hardhat",quietly=TRUE)) .smf_abort("HARDHAT_MISSING","Package 'hardhat' is required for case weights.",class="smf_capability_error")
    cw <- hardhat::importance_weights(as.numeric(weights))
  }
  parsnip::fit_xy(spec,x=x,y=y,case_weights=cw)
}

.smf_mlr3_fit <- function(task, model, x, y, weights=NULL) {
  if (!requireNamespace("mlr3",quietly=TRUE)) .smf_abort("MLR3_MISSING","Package 'mlr3' is required for the mlr3 adapter.",class="smf_capability_error")
  if (task@kind == "multioutput_regression") .smf_abort("MLR3_MULTIOUTPUT_UNCERTIFIED","Generic multi-output fitting is not certified for the mlr3 adapter in 0.3.0.",class="smf_capability_error")
  y <- .smf_standardize_truth(task,y)
  d <- as.data.frame(x); d$.smf_target <- y
  if (!is.null(weights)) d$.smf_weight <- as.numeric(weights)
  id <- paste0("smf_",task@kind)
  if (task@kind %in% c("regression","count")) tsk <- mlr3::TaskRegr$new(id=id,backend=d,target=".smf_target")
  else tsk <- mlr3::TaskClassif$new(id=id,backend=d,target=".smf_target",positive=if(task@kind=="binary" && length(task@positive_label)) as.character(task@positive_label) else NULL)
  learner_id <- model@parameters$learner_id %||% if(task@kind %in% c("regression","count")) "regr.rpart" else "classif.rpart"
  lrn <- mlr3::lrn(learner_id)
  vals <- model@parameters$learner_params %||% list()
  if (length(vals)) lrn$param_set$values <- vals
  if (task@kind %in% c("binary","multiclass") && "prob" %in% lrn$predict_types) lrn$predict_type <- "prob"
  if (!is.null(weights)) tsk$set_col_roles(".smf_weight",roles="weights_learner")
  lrn$train(tsk)
  structure(list(learner=lrn,task=tsk,class_levels=if(is.factor(y)) levels(y) else character()),class="smf_mlr3_fit")
}

.smf_xgboost_matrix <- function(x) {
  m <- data.matrix(x)
  storage.mode(m) <- "double"
  m
}

.smf_xgboost_fit <- function(task, model, x, y, weights=NULL) {
  if (!requireNamespace("xgboost",quietly=TRUE)) .smf_abort("XGBOOST_MISSING","Package 'xgboost' is required for the xgboost adapter.",class="smf_capability_error")
  if (task@kind == "multioutput_regression") .smf_abort("XGBOOST_MULTIOUTPUT_UNCERTIFIED","Multi-output XGBoost is not certified in 0.3.0.",class="smf_capability_error")
  if (task@kind %in% c("binary", "multiclass")) y <- .smf_standardize_truth(task, y)
  xmat <- .smf_xgboost_matrix(x)
  levels_y <- character()
  if (task@kind == "binary") {
    yf <- as.factor(y); levels_y <- levels(yf); label <- as.integer(yf)-1L; objective <- "binary:logistic"
  } else if (task@kind == "multiclass") {
    yf <- as.factor(y); levels_y <- levels(yf); label <- as.integer(yf)-1L; objective <- "multi:softprob"
  } else if (task@kind == "count") { label <- as.numeric(y); objective <- "count:poisson"
  } else { label <- as.numeric(y); objective <- "reg:squarederror" }
  dm <- xgboost::xgb.DMatrix(xmat,label=label,weight=if(is.null(weights)) NULL else as.numeric(weights))
  params <- model@parameters$params %||% list()
  if (is.null(params$objective)) params$objective <- objective
  if (task@kind == "multiclass" && is.null(params$num_class)) params$num_class <- length(levels_y)
  nrounds <- as.integer(model@parameters$nrounds %||% 100L)
  booster <- xgboost::xgb.train(params=params,data=dm,nrounds=nrounds,verbose=0)
  structure(list(model=booster,class_levels=levels_y,task_kind=task@kind,predictors=colnames(xmat)),class="smf_xgboost_fit")
}

#' Fit a standardized supervised-model adapter
#' @export
smf_fit_model <- function(task, model, x, y, weights=NULL) {
  if (!S7::S7_inherits(task,TaskSpec) || !S7::S7_inherits(model,ModelSpec)) cli::cli_abort("{.arg task} and {.arg model} must be sciModelFlowR specifications.")
  cap <- .smf_task_capability(task); smf_require_capability(model@engine,cap)
  fit <- switch(model@engine,
    stats=.smf_stats_fit(task,model,x,y,weights),
    tidymodels=.smf_tidymodels_fit(task,model,x,y,weights),
    mlr3=.smf_mlr3_fit(task,model,x,y,weights),
    xgboost=.smf_xgboost_fit(task,model,x,y,weights),
    .smf_abort("MODEL_ADAPTER_UNKNOWN",paste0("No model adapter is implemented for engine '",model@engine,"'."),class="smf_capability_error"))
  standardized_levels <- if (task@kind %in% c("binary", "multiclass")) levels(.smf_standardize_truth(task, y)) else character()
  structure(list(object=fit,engine=model@engine,task_kind=task@kind,target=task@target,class_levels=standardized_levels,model_spec=model),class="smf_adapter_fit")
}

.smf_probs_from_tidymodels <- function(object,x) {
  p <- predict(object,new_data=x,type="prob")
  out <- as.matrix(p)
  colnames(out) <- sub("^\\.pred_","",colnames(out))
  out
}


.smf_predict_portable_stats <- function(obj, new_data, want_prob, kind, class_levels) {
  st <- obj$state
  pred_one <- function(ms) {
    cf <- unlist(ms$coefficients, use.names=TRUE)
    if(length(ms$coefficient_names)) names(cf) <- unlist(ms$coefficient_names, use.names=FALSE)
    eta <- rep(unname(cf[["(Intercept)"]] %||% 0), nrow(new_data))
    terms <- setdiff(names(cf), "(Intercept)")
    .smf_abort_missing_columns(new_data, terms, "portable stats model")
    if(length(terms)) eta <- eta + as.numeric(as.matrix(new_data[terms]) %*% as.numeric(cf[terms]))
    link <- as.character(ms$link %||% "identity")
    if(link=="logit") return(stats::plogis(eta))
    if(link=="log") return(exp(eta))
    eta
  }
  if(identical(st$type,"stats_multioutput_portable")) {
    out <- do.call(cbind,lapply(st$models,pred_one)); colnames(out) <- unlist(st$targets,use.names=FALSE); return(out)
  }
  raw <- pred_one(st$model)
  if(kind=="binary") {
    lv <- class_levels; probs <- cbind(1-raw,raw); colnames(probs)<-lv
    if(want_prob) return(probs); return(factor(lv[1L+(raw>=0.5)],levels=lv))
  }
  raw
}

#' Predict through a standardized supervised-model adapter
#' @export
smf_predict_model <- function(fit, task, new_data, type=c("auto","response","prob")) {
  type <- match.arg(type)
  if (!inherits(fit,"smf_adapter_fit")) cli::cli_abort("{.arg fit} must be returned by {.fn smf_fit_model}.")
  kind <- task@kind; obj <- fit$object
  want_prob <- type=="prob" || (type=="auto" && kind %in% c("binary","multiclass"))
  if (fit$engine == "stats") {
    if (inherits(obj,"smf_portable_stats_fit")) return(.smf_predict_portable_stats(obj,new_data,want_prob,kind,fit$class_levels))
    if (inherits(obj,"smf_stats_multioutput")) return(do.call(cbind,lapply(obj$models,function(m) as.numeric(stats::predict(m,newdata=new_data)))))
    if (kind=="regression") return(as.numeric(stats::predict(obj,newdata=new_data)))
    if (kind=="count") return(as.numeric(stats::predict(obj,newdata=new_data,type="response")))
    p <- as.numeric(stats::predict(obj,newdata=new_data,type="response"))
    lv <- fit$class_levels
    probs <- cbind(1-p,p); colnames(probs) <- lv
    if (want_prob) return(probs)
    return(factor(lv[1L+(p>=0.5)],levels=lv))
  }
  if (fit$engine == "tidymodels") {
    if (kind %in% c("binary","multiclass")) {
      if (want_prob) return(.smf_probs_from_tidymodels(obj,new_data))
      return(predict(obj,new_data=new_data,type="class")[[1]])
    }
    return(as.numeric(predict(obj,new_data=new_data,type="numeric")[[1]]))
  }
  if (fit$engine == "mlr3") {
    pr <- obj$learner$predict_newdata(as.data.frame(new_data),task=obj$task)
    if (kind %in% c("binary","multiclass")) return(if(want_prob) pr$prob else pr$response)
    return(as.numeric(pr$response))
  }
  if (fit$engine == "xgboost") {
    raw <- predict(obj$model,xgboost::xgb.DMatrix(.smf_xgboost_matrix(new_data)))
    if (kind=="multiclass") {
      k <- length(obj$class_levels); probs <- if(is.matrix(raw)) raw else matrix(raw,ncol=k,byrow=TRUE); colnames(probs)<-obj$class_levels
      if(want_prob) return(probs); return(factor(obj$class_levels[max.col(probs,ties.method="first")],levels=obj$class_levels))
    }
    if (kind=="binary") {
      p <- as.numeric(raw); probs <- cbind(1-p,p); colnames(probs)<-obj$class_levels
      if(want_prob) return(probs); return(factor(obj$class_levels[1L+(p>=0.5)],levels=obj$class_levels))
    }
    return(as.numeric(raw))
  }
  .smf_abort("MODEL_PREDICT_UNKNOWN","Unknown model adapter.",class="smf_capability_error")
}

#' List supervised adapters implemented by sciModelFlowR
#' @export
smf_available_model_adapters <- function() {
  rec <- smf_capabilities()
  data.frame(engine=names(rec),status=vapply(rec,function(x)x$status,character(1)),validation_tier=vapply(rec,function(x)x$validation_tier,integer(1)),packages=vapply(rec,function(x)paste(x$package,collapse=","),character(1)),row.names=NULL)
}
