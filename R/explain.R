# Model-agnostic explainability with explicit scientific safeguards (0.5.0).

.smf_explain_fit <- function(x) {
  if (S7::S7_inherits(x, ExperimentResult)) return(x@fit)
  if (S7::S7_inherits(x, FitResult)) return(x)
  .smf_abort("EXPLAIN_FIT_REQUIRED", "Explainability requires an ExperimentResult or FitResult.", class="smf_explain_error")
}

.smf_explain_task <- function(x) {
  if (S7::S7_inherits(x, ExperimentResult)) return(x@spec@task)
  fit <- .smf_explain_fit(x)
  kind <- fit@training_summary$task_kind %||% "regression"
  lev <- fit@training_summary$class_levels %||% character()
  smf_task_spec(kind=kind, target=fit@target, positive_label=if(length(lev)==2L) lev[[2L]] else NULL)
}

.smf_explain_response <- function(x, newdata, class=NULL) {
  task <- .smf_explain_task(x); pr <- smf_predict(x, newdata)
  if (task@kind %in% c("binary","multiclass")) {
    p <- as.matrix(pr)
    cl <- class %||% if(length(task@positive_label)) as.character(task@positive_label) else colnames(p)[[ncol(p)]]
    if (!cl %in% colnames(p)) .smf_abort("EXPLAIN_CLASS_UNKNOWN", paste0("Requested explanation class is not available: ", cl), class="smf_explain_error")
    return(as.numeric(p[,cl]))
  }
  if (is.matrix(pr) || is.data.frame(pr)) {
    if (ncol(pr)!=1L) .smf_abort("EXPLAIN_MULTIOUTPUT_REQUIRES_TARGET", "Local scalar explanations require an explicit output target for multi-output prediction.", class="smf_explain_error")
    return(as.numeric(pr[,1L]))
  }
  as.numeric(pr)
}

.smf_explain_metric <- function(result, truth, pred, metric) {
  task <- .smf_explain_task(result)
  if (task@kind %in% c("binary","multiclass")) {
    if (is.vector(pred)) {
      lev <- if (is.factor(truth)) levels(truth) else sort(unique(as.character(truth)))
      if (length(lev)!=2L) .smf_abort("EXPLAIN_PROB_MATRIX_REQUIRED", "Classification permutation importance needs a probability matrix for multiclass outcomes.", class="smf_explain_error")
      pos <- if(length(task@positive_label)) as.character(task@positive_label) else lev[[2L]]
      pred <- cbind(1-pred,pred); colnames(pred) <- c(setdiff(lev,pos)[[1L]],pos)
    }
    return(smf_evaluate(truth,pred,list(metric),positive_label=if(length(task@positive_label))as.character(task@positive_label) else NULL)$value[[1L]])
  }
  smf_evaluate(truth,pred,list(metric))$value[[1L]]
}

#' Trace engineered features back to source variables when mapping exists
#' @export
smf_trace_features <- function(result) {
  fit <- .smf_explain_fit(result); rows <- list(); k <- 0L
  st <- fit@preprocessing@state
  for (nm in st$numeric %||% character()) { k<-k+1L; rows[[k]]<-data.frame(transformed=nm,source=nm,weight=1,type="numeric",stringsAsFactors=FALSE) }
  for (nm in st$categorical %||% character()) {
    if (isTRUE(fit@preprocessing@spec@one_hot)) {
      for (lv in st$levels[[nm]] %||% character()) { k<-k+1L; rows[[k]]<-data.frame(transformed=paste0(nm,"__",make.names(lv)),source=nm,weight=1,type="one_hot",stringsAsFactors=FALSE) }
    } else { k<-k+1L; rows[[k]]<-data.frame(transformed=nm,source=nm,weight=1,type="categorical",stringsAsFactors=FALSE) }
  }
  fs <- fit@features
  if (!is.null(fs) && S7::S7_inherits(fs, RepresentationResult) && !is.null(fs@feature_map)) {
    m <- as.matrix(fs@feature_map); cn <- colnames(m) %||% paste0("component_",seq_len(ncol(m))); rn <- rownames(m) %||% st$numeric[seq_len(nrow(m))]
    map <- do.call(rbind,lapply(seq_len(ncol(m)),function(j)data.frame(transformed=cn[[j]],source=rn,weight=as.numeric(m[,j]),type="representation_loading",stringsAsFactors=FALSE)))
    return(map)
  }
  if (!length(rows)) return(data.frame(transformed=character(),source=character(),weight=numeric(),type=character()))
  do.call(rbind,rows)
}

.smf_correlated_feature_warnings <- function(data, features, threshold=0.8) {
  num <- intersect(features,names(data)[vapply(data,is.numeric,logical(1))]); if(length(num)<2L)return(list())
  C <- abs(stats::cor(data[num],use="pairwise.complete.obs")); diag(C)<-0
  idx <- which(C>=threshold,arr.ind=TRUE); if(!nrow(idx))return(list())
  idx <- idx[idx[,1]<idx[,2],,drop=FALSE]; if(!nrow(idx))return(list())
  pairs <- apply(idx,1,function(z)paste0(colnames(C)[z[[1]]]," ~ ",colnames(C)[z[[2]]]," (|r|=",round(C[z[[1]],z[[2]]],3),")"))
  list(smf_warning_record("CORRELATED_FEATURE_EXPLANATION", "Model-agnostic perturbation explanations can redistribute importance among correlated predictors; interpret feature rankings conditionally.", "warning", evidence=list(threshold=threshold,pairs=pairs), override_allowed=TRUE))
}

#' Diagnose extrapolation of explanation data relative to a reference set
#' @export
smf_explanation_domain <- function(reference, new_data, features=intersect(names(reference),names(new_data))) {
  rows <- lapply(features,function(nm){
    a<-reference[[nm]]; b<-new_data[[nm]]
    if(is.numeric(a)) {
      lo<-min(a,na.rm=TRUE); hi<-max(a,na.rm=TRUE); outside<-mean(b<lo|b>hi,na.rm=TRUE)
      data.frame(feature=nm,type="numeric",outside_fraction=outside,novel_levels=NA_integer_,reference_min=lo,reference_max=hi,stringsAsFactors=FALSE)
    } else {
      lv<-unique(as.character(a)); novel<-setdiff(unique(as.character(b)),lv)
      data.frame(feature=nm,type="categorical",outside_fraction=NA_real_,novel_levels=length(novel),reference_min=NA_real_,reference_max=NA_real_,stringsAsFactors=FALSE)
    }
  })
  do.call(rbind,rows)
}

#' Model-agnostic permutation importance on held-out or explicitly supplied evaluation data
#' @export
smf_permutation_importance <- function(result, data, truth=NULL, metric=NULL, features=character(), n_repeats=20L, seed=260915L) {
  task <- .smf_explain_task(result); target <- task@target
  if(is.null(truth)) { if(!target %in% names(data)) .smf_abort("EXPLAIN_TRUTH_REQUIRED", "Permutation importance requires truth or a target column in data.",class="smf_explain_error"); truth<-data[[target]] }
  x <- data[setdiff(names(data),target)]
  if(!length(features)) features <- intersect(.smf_explain_fit(result)@preprocessing@state$predictors,names(x))
  .smf_abort_missing_columns(x,features,"permutation importance")
  metric <- metric %||% if(task@kind=="regression") smf_metric_spec("rmse") else smf_metric_spec("log_loss")
  base_pred <- if(task@kind %in% c("binary","multiclass")) smf_predict(result,x) else .smf_explain_response(result,x)
  baseline <- .smf_explain_metric(result,truth,base_pred,metric); minimize <- identical(metric@direction,"minimize")
  rows<-list();k<-0L
  for(nm in features) {
    vals<-numeric(n_repeats)
    for(r in seq_len(n_repeats)) {
      xp<-x; xp[[nm]]<-smf_with_seed(as.integer(seed+r+match(nm,features)*10000L),sample(xp[[nm]],length(xp[[nm]]),replace=FALSE))
      pp<-if(task@kind %in% c("binary","multiclass")) smf_predict(result,xp) else .smf_explain_response(result,xp)
      vals[[r]] <- .smf_explain_metric(result,truth,pp,metric)
    }
    k<-k+1L; pm<-mean(vals,na.rm=TRUE); imp<-if(minimize) pm-baseline else baseline-pm
    rows[[k]]<-data.frame(feature=nm,importance=imp,baseline=baseline,permuted_mean=pm,sd=stats::sd(vals,na.rm=TRUE),n_repeats=n_repeats,metric=metric@name,direction=metric@direction,stringsAsFactors=FALSE)
  }
  out<-do.call(rbind,rows); out[order(out$importance,decreasing=TRUE),,drop=FALSE]
}

.smf_feature_grid <- function(z,n=20L) {
  if(is.numeric(z)) unique(as.numeric(stats::quantile(z,seq(0,1,length.out=n),na.rm=TRUE,names=FALSE))) else unique(as.character(z))
}

#' Partial dependence profile
#' @export
smf_pdp <- function(result, data, features=character(), grid_size=20L, class=NULL) {
  target <- .smf_explain_task(result)@target; x<-data[setdiff(names(data),target)]
  if(!length(features))features<-.smf_explain_fit(result)@preprocessing@state$predictors
  .smf_abort_missing_columns(x,features,"PDP")
  rows<-list();k<-0L
  for(nm in features) for(v in .smf_feature_grid(x[[nm]],grid_size)) {
    xx<-x; xx[[nm]]<-if(is.factor(x[[nm]]))factor(v,levels=levels(x[[nm]])) else v
    k<-k+1L; rows[[k]]<-data.frame(feature=nm,value=as.character(v),prediction=mean(.smf_explain_response(result,xx,class),na.rm=TRUE),stringsAsFactors=FALSE)
  }
  do.call(rbind,rows)
}

#' Individual conditional expectation profiles
#' @export
smf_ice <- function(result, data, features=character(), grid_size=20L, n=50L, class=NULL, seed=260915L) {
  target <- .smf_explain_task(result)@target; x<-data[setdiff(names(data),target)]
  if(!length(features))features<-.smf_explain_fit(result)@preprocessing@state$predictors
  .smf_abort_missing_columns(x,features,"ICE"); ids<-smf_with_seed(seed,sort(sample.int(nrow(x),min(as.integer(n),nrow(x)))))
  rows<-list();k<-0L
  for(nm in features) for(v in .smf_feature_grid(x[[nm]],grid_size)) {
    xx<-x[ids,,drop=FALSE]; xx[[nm]]<-if(is.factor(x[[nm]]))factor(v,levels=levels(x[[nm]])) else v
    pr<-.smf_explain_response(result,xx,class)
    k<-k+1L; rows[[k]]<-data.frame(feature=nm,value=as.character(v),row_id=ids,prediction=pr,stringsAsFactors=FALSE)
  }
  do.call(rbind,rows)
}

#' One-dimensional accumulated local effects for numeric predictors
#' @export
smf_ale <- function(result, data, features=character(), bins=20L, class=NULL) {
  target <- .smf_explain_task(result)@target; x<-data[setdiff(names(data),target)]
  if(!length(features))features<-names(x)[vapply(x,is.numeric,logical(1))]
  features<-features[vapply(x[features],is.numeric,logical(1))]; if(!length(features)) .smf_abort("ALE_NUMERIC_REQUIRED","ALE currently requires at least one numeric feature.",class="smf_explain_error")
  rows<-list();kk<-0L
  for(nm in features) {
    z<-x[[nm]]; br<-unique(as.numeric(stats::quantile(z,seq(0,1,length.out=as.integer(bins)+1L),na.rm=TRUE,names=FALSE))); if(length(br)<3L)next
    bin<-cut(z,br,include.lowest=TRUE,labels=FALSE); dif<-cnt<-numeric(length(br)-1L)
    for(j in seq_len(length(br)-1L)) {
      ii<-which(bin==j); if(!length(ii))next; lo<-x[ii,,drop=FALSE]; hi<-lo; lo[[nm]]<-br[[j]]; hi[[nm]]<-br[[j+1L]]
      dif[[j]]<-mean(.smf_explain_response(result,hi,class)-.smf_explain_response(result,lo,class),na.rm=TRUE); cnt[[j]]<-length(ii)
    }
    eff<-cumsum(dif); ctr<-if(sum(cnt)>0)sum(eff*cnt)/sum(cnt) else mean(eff); eff<-eff-ctr
    mid<-(br[-1L]+br[-length(br)])/2
    kk<-kk+1L; rows[[kk]]<-data.frame(feature=nm,value=mid,effect=eff,n=cnt,stringsAsFactors=FALSE)
  }
  if(!length(rows))return(data.frame()); do.call(rbind,rows)
}

#' Local perturbation explanation for one or more observations
#' @export
smf_local_explain <- function(result, new_data, background, features=character(), class=NULL) {
  target<-.smf_explain_task(result)@target; x<-new_data[setdiff(names(new_data),target)]; bg<-background[setdiff(names(background),target)]
  if(!length(features))features<-.smf_explain_fit(result)@preprocessing@state$predictors
  .smf_abort_missing_columns(x,features,"local explanation"); .smf_abort_missing_columns(bg,features,"local explanation background")
  base<-.smf_explain_response(result,x,class); rows<-list();k<-0L
  refs<-lapply(bg[features],function(z) if(is.numeric(z))stats::median(z,na.rm=TRUE) else names(sort(table(z),decreasing=TRUE))[[1L]])
  for(i in seq_len(nrow(x))) for(nm in features) {
    xx<-x[i,,drop=FALSE]; original<-as.character(xx[[nm]]); ref<-refs[[nm]]; xx[[nm]]<-if(is.factor(x[[nm]]))factor(ref,levels=levels(x[[nm]])) else ref
    pr<-.smf_explain_response(result,xx,class)
    k<-k+1L; rows[[k]]<-data.frame(row_id=i,feature=nm,original=original,reference=as.character(ref),prediction=base[[i]],reference_prediction=pr[[1L]],contribution=base[[i]]-pr[[1L]],stringsAsFactors=FALSE)
  }
  do.call(rbind,rows)
}

#' Optional SHAP adapter using fastshap
#' @export
smf_shap <- function(result, background, new_data=background, nsim=100L, class=NULL, seed=260915L) {
  if(!requireNamespace("fastshap",quietly=TRUE)) .smf_abort("SHAP_BACKEND_MISSING","SHAP explanations require optional package 'fastshap'.",class="smf_capability_error")
  target<-.smf_explain_task(result)@target; X<-background[setdiff(names(background),target)]; newX<-new_data[intersect(names(X),names(new_data))]
  pred_wrapper<-function(object,newdata).smf_explain_response(object,newdata,class)
  ans<-smf_with_seed(seed,fastshap::explain(object=result,X=X,newdata=newX,pred_wrapper=pred_wrapper,nsim=as.integer(nsim),adjust=TRUE))
  as.data.frame(ans)
}

#' Find simple observed-data counterfactual candidates
#' @export
smf_counterfactual <- function(result, new_data, reference, target_value=NULL, target_class=NULL, threshold=0.5, max_candidates=5L) {
  task<-.smf_explain_task(result); target<-task@target; x<-new_data[setdiff(names(new_data),target)]; ref<-reference[setdiff(names(reference),target)]
  if(nrow(x)!=1L).smf_abort("COUNTERFACTUAL_SINGLE_ROW","The reference counterfactual search currently accepts one focal row.",class="smf_explain_error")
  pred<-.smf_explain_response(result,ref,target_class)
  keep<-if(task@kind=="regression") { if(is.null(target_value)).smf_abort("COUNTERFACTUAL_TARGET_REQUIRED","Regression counterfactuals require target_value.",class="smf_explain_error"); abs(pred-target_value)<=stats::quantile(abs(pred-target_value),0.1,na.rm=TRUE) } else pred >= threshold
  cand<-ref[keep,,drop=FALSE]; if(!nrow(cand))return(data.frame())
  num<-intersect(names(cand),names(cand)[vapply(cand,is.numeric,logical(1))]); den<-vapply(ref[num],stats::sd,numeric(1),na.rm=TRUE); den[!is.finite(den)|den==0]<-1
  d<-rep(0,nrow(cand)); for(nm in names(cand)) { if(is.numeric(cand[[nm]]))d<-d+abs(cand[[nm]]-x[[nm]][[1]])/(den[[nm]]%||%1) else d<-d+as.numeric(as.character(cand[[nm]])!=as.character(x[[nm]][[1]])) }
  cand$.smf_distance<-d; cand$.smf_prediction<-pred[keep]; head(cand[order(cand$.smf_distance),,drop=FALSE],as.integer(max_candidates))
}

#' Unified explainability interface
#' @export
smf_explain <- function(result, data, spec=smf_explain_spec(), truth=NULL, new_data=NULL) {
  feats<-if(length(spec@features))spec@features else intersect(.smf_explain_fit(result)@preprocessing@state$predictors,names(data))
  warns<-.smf_correlated_feature_warnings(data,feats,spec@parameters$correlation_threshold %||% 0.8)
  fmap<-smf_trace_features(result); vals<-list(); cls<-spec@parameters$class %||% NULL
  for(m in spec@methods) {
    vals[[m]]<-switch(m,
      permutation=smf_permutation_importance(result,data,truth,spec@parameters$metric %||% NULL,feats,spec@n_repeats,spec@seed),
      pdp=smf_pdp(result,data,feats,spec@grid_size,cls),
      ice=smf_ice(result,data,feats,spec@grid_size,spec@ice_n,cls,spec@seed),
      ale=smf_ale(result,data,feats,spec@parameters$bins %||% spec@grid_size,cls),
      shap=smf_shap(result,data,new_data %||% data, spec@parameters$nsim %||% 100L,cls,spec@seed),
      local=smf_local_explain(result,new_data %||% data[1,,drop=FALSE],data,feats,cls),
      counterfactual=smf_counterfactual(result,new_data %||% data[1,,drop=FALSE],data,spec@parameters$target_value,spec@parameters$target_class,spec@parameters$threshold %||% 0.5,spec@parameters$max_candidates %||% 5L))
  }
  ExplainResult(spec=spec,method=paste(spec@methods,collapse="+"),scope=spec@scope,values=vals,feature_map=fmap,
    diagnostics=list(domain=if(!is.null(new_data))smf_explanation_domain(data,new_data,feats)else NULL),causal_interpretation=FALSE,warnings=warns,
    provenance=list(data_hash=smf_data_hash(data),seed=spec@seed,non_causal=TRUE,methods=spec@methods))
}
