.smf_feature_predictors <- function(data, outcome=character(), id=character()) setdiff(names(data),c(outcome,id))

.smf_discretize <- function(x,bins=10L) {
  if (is.factor(x) || is.character(x) || is.logical(x)) return(factor(x,exclude=NULL))
  z <- as.numeric(x); probs <- seq(0,1,length.out=as.integer(bins)+1L); br <- unique(stats::quantile(z,probs,na.rm=TRUE,names=FALSE,type=7))
  if(length(br)<3L) return(factor(rep(1L,length(z))))
  cut(z,breaks=br,include.lowest=TRUE,ordered_result=TRUE)
}

.smf_mutual_information <- function(x,y,bins=10L) {
  a <- .smf_discretize(x,bins); b <- .smf_discretize(y,bins); ok <- !is.na(a)&!is.na(b); a <- a[ok]; b <- b[ok]
  if(!length(a)) return(NA_real_)
  tab <- table(a,b); pxy <- tab/sum(tab); px <- rowSums(pxy); py <- colSums(pxy)
  sum(vapply(which(pxy>0),function(k) { ij <- arrayInd(k,dim(pxy)); pxy[k]*log(pxy[k]/(px[ij[1]]*py[ij[2]])) },numeric(1)))
}

.smf_vif_scores <- function(df) {
  if(ncol(df)<2L) return(setNames(rep(1,ncol(df)),names(df)))
  out <- vapply(names(df),function(nm) {
    others <- setdiff(names(df),nm); if(!length(others)) return(1)
    dat <- df[c(nm,others)]; dat <- dat[stats::complete.cases(dat),,drop=FALSE]
    if(nrow(dat)<3L) return(Inf)
    f <- stats::reformulate(others,response=nm); fit <- tryCatch(stats::lm(f,dat),error=function(e)NULL)
    if(is.null(fit)) return(Inf); r2 <- summary(fit)$r.squared; if(!is.finite(r2)||r2>=1) Inf else 1/(1-r2)
  },numeric(1))
  out
}


.smf_feature_reference_score <- function(data, outcome, predictors, criterion = c("aic", "bic")) {
  criterion <- match.arg(criterion)
  if (length(outcome) != 1L) .smf_abort("FEATURE_OUTCOME_REQUIRED", "Reference subset selection requires exactly one outcome.")
  y <- data[[outcome]]
  if (!length(predictors)) {
    dat <- data.frame(.smf_y = y)
    fit <- if (is.factor(y) || (is.logical(y)) || length(unique(stats::na.omit(y))) == 2L) {
      stats::glm(.smf_y ~ 1, data = dat, family = stats::binomial())
    } else stats::lm(.smf_y ~ 1, data = dat)
  } else {
    dat <- data[c(outcome, predictors)]
    names(dat)[1L] <- ".smf_y"
    rhs <- names(dat)[-1L]
    f <- stats::reformulate(rhs, response = ".smf_y")
    fit <- if (is.factor(y) || is.logical(y) || length(unique(stats::na.omit(y))) == 2L) {
      if (length(unique(stats::na.omit(y))) != 2L) .smf_abort("FEATURE_BINARY_REQUIRED", "Reference subset selection currently supports regression and binary outcomes.")
      stats::glm(f, data = dat, family = stats::binomial())
    } else stats::lm(f, data = dat)
  }
  if (criterion == "aic") stats::AIC(fit) else stats::BIC(fit)
}

.smf_subset_search <- function(data, outcome, predictors, method, n_features, parameters) {
  criterion <- tolower(parameters$criterion %||% "aic")
  if (!criterion %in% c("aic", "bic")) .smf_abort("FEATURE_CRITERION_UNSUPPORTED", "RFE/sequential selection supports criterion = 'aic' or 'bic' in the 0.2.0 reference selector.")
  target <- as.integer(n_features %||% max(1L, floor(sqrt(length(predictors)))))
  target <- max(1L, min(target, length(predictors)))
  history <- list()
  score_set <- function(vars) .smf_feature_reference_score(data, outcome, vars, criterion)

  if (method == "rfe") {
    current <- predictors
    history[[1L]] <- data.frame(step = 0L, action = "start", feature = NA_character_, score = score_set(current), n_features = length(current))
    step <- 0L
    while (length(current) > target) {
      candidates <- lapply(current, function(drop) {
        vars <- setdiff(current, drop)
        data.frame(feature = drop, score = score_set(vars), stringsAsFactors = FALSE)
      })
      tab <- do.call(rbind, candidates)
      drop <- tab$feature[[which.min(tab$score)]]
      current <- setdiff(current, drop); step <- step + 1L
      history[[length(history)+1L]] <- data.frame(step = step, action = "remove", feature = drop, score = min(tab$score), n_features = length(current))
    }
    return(list(selected = current, history = do.call(rbind, history), criterion = criterion))
  }

  direction <- tolower(parameters$direction %||% "forward")
  if (!direction %in% c("forward", "backward")) .smf_abort("FEATURE_DIRECTION_UNSUPPORTED", "Sequential selection direction must be 'forward' or 'backward'.")
  if (direction == "backward") {
    current <- predictors
    history[[1L]] <- data.frame(step = 0L, action = "start", feature = NA_character_, score = score_set(current), n_features = length(current))
    step <- 0L
    while (length(current) > target) {
      tab <- do.call(rbind, lapply(current, function(drop) data.frame(feature=drop, score=score_set(setdiff(current,drop)), stringsAsFactors=FALSE)))
      drop <- tab$feature[[which.min(tab$score)]]
      current <- setdiff(current, drop); step <- step + 1L
      history[[length(history)+1L]] <- data.frame(step=step, action="remove", feature=drop, score=min(tab$score), n_features=length(current))
    }
    return(list(selected=current, history=do.call(rbind,history), criterion=criterion))
  }

  current <- character(); remaining <- predictors; step <- 0L
  history[[1L]] <- data.frame(step=0L, action="start", feature=NA_character_, score=score_set(current), n_features=0L)
  while (length(current) < target && length(remaining)) {
    tab <- do.call(rbind, lapply(remaining, function(add) data.frame(feature=add, score=score_set(c(current,add)), stringsAsFactors=FALSE)))
    add <- tab$feature[[which.min(tab$score)]]
    current <- c(current, add); remaining <- setdiff(remaining, add); step <- step + 1L
    history[[length(history)+1L]] <- data.frame(step=step, action="add", feature=add, score=min(tab$score), n_features=length(current))
  }
  list(selected=current, history=do.call(rbind,history), criterion=criterion)
}

.smf_selection_guard <- function(spec, context) {
  if(spec@method!="none" && context!="training" && !isTRUE(spec@parameters$externally_fixed)) {
    .smf_abort("FEATURE_SELECTION_OUTSIDE_RESAMPLING",
      "Learned feature selection/representation must be fitted on a training partition, not globally before resampling.",
      evidence=list(method=spec@method,context=context),class="smf_leakage_error")
  }
}

#' Select features within an explicit training context
#' @export
smf_select_features <- function(data, outcome=character(), spec=smf_feature_spec(), id_column=character(), context=c("global","training")) {
  context <- match.arg(context); .smf_selection_guard(spec,context)
  if(!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data.frame.")
  if(length(outcome)) .smf_abort_missing_columns(data,outcome,"feature selection outcome")
  predictors <- .smf_feature_predictors(data,outcome,id_column); X <- data[predictors]
  method <- spec@method
  if(method=="none") return(FeatureSelectionResult(spec=spec,selected=predictors,scores=data.frame(feature=predictors,score=NA_real_),fold_results=list(),stability=NULL,provenance=list(training_hash=smf_data_hash(data),context=context),warnings=list()))
  scores <- data.frame(feature=predictors,score=NA_real_,row.names=NULL); selected <- predictors; warnings <- list()
  if(method=="nzv") {
    stats <- lapply(X,function(z) { zz <- z[!is.na(z)]; c(unique=length(unique(zz)),fraction_unique=if(length(zz))length(unique(zz))/length(zz) else 0) })
    score <- vapply(stats,function(z) z[["fraction_unique"]],numeric(1)); names(score) <- names(X)
    freq_ratio <- vapply(X,function(z) { t <- sort(table(z),decreasing=TRUE); if(length(t)<2L) Inf else as.numeric(t[1]/t[2]) },numeric(1))
    unique_cut <- spec@parameters$unique_cut %||% 0.01; freq_cut <- spec@parameters$freq_cut %||% 95/5
    keep <- vapply(names(X),function(nm) length(unique(stats::na.omit(X[[nm]])))>1L && !(score[[nm]]<=unique_cut && freq_ratio[[nm]]>=freq_cut),logical(1))
    selected <- names(X)[keep]; scores <- data.frame(feature=names(X),score=score,freq_ratio=freq_ratio,selected=keep,row.names=NULL)
  } else if(method=="correlation") {
    num <- names(X)[vapply(X,is.numeric,logical(1))]; keep <- predictors
    if(length(num)>1L) {
      C <- abs(stats::cor(X[num],use="pairwise.complete.obs")); diag(C) <- 0
      while(any(C>spec@threshold,na.rm=TRUE) && ncol(C)>1L) {
        mean_c <- colMeans(C,na.rm=TRUE); drop <- names(which.max(mean_c)); keep <- setdiff(keep,drop); num <- setdiff(num,drop); C <- if(length(num)>1L) abs(stats::cor(X[num],use="pairwise.complete.obs")) else matrix(0,1,1,dimnames=list(num,num)); diag(C)<-0
      }
    }
    selected <- keep; scores$score <- vapply(predictors,function(nm) if(is.numeric(X[[nm]]) && length(num)) max(abs(stats::cor(X[[nm]],X[num],use="pairwise.complete.obs")),na.rm=TRUE) else NA_real_,numeric(1)); scores$selected <- predictors %in% selected
  } else if(method=="vif") {
    num <- names(X)[vapply(X,is.numeric,logical(1))]; keep_num <- num; cutoff <- spec@threshold
    if(cutoff<=1) cutoff <- 5
    repeat {
      vif <- .smf_vif_scores(X[keep_num]); if(!length(vif) || max(vif,na.rm=TRUE)<=cutoff || length(keep_num)<=1L) break
      keep_num <- setdiff(keep_num,names(which.max(vif)))
    }
    final_vif <- .smf_vif_scores(X[keep_num]); selected <- c(setdiff(predictors,num),keep_num)
    scores <- data.frame(feature=predictors,score=vapply(predictors,function(nm) if(nm%in%names(final_vif))final_vif[[nm]] else NA_real_,numeric(1)),selected=predictors%in%selected,row.names=NULL)
  } else if(method=="mutual_information") {
    if(!length(outcome)) .smf_abort("FEATURE_OUTCOME_REQUIRED","Mutual information selection requires an outcome.")
    y <- data[[outcome[[1]]]]; mi <- vapply(X,function(z).smf_mutual_information(z,y,spec@parameters$bins %||% 10L),numeric(1))
    k <- as.integer(spec@n_features %||% min(10L,length(mi))); ord <- order(mi,decreasing=TRUE,na.last=NA); selected <- names(mi)[head(ord,k)]
    scores <- data.frame(feature=names(mi),score=as.numeric(mi),selected=names(mi)%in%selected,row.names=NULL)
  } else if(method=="regularized") {
    if(!requireNamespace("glmnet",quietly=TRUE)) .smf_abort("FEATURE_BACKEND_MISSING","Regularized selection requires optional package 'glmnet'.",class="smf_capability_error")
    if(!length(outcome)) .smf_abort("FEATURE_OUTCOME_REQUIRED","Regularized selection requires an outcome.")
    mm <- stats::model.matrix(~ . -1,data=X); y <- data[[outcome[[1]]]]; family <- spec@parameters$family %||% if(is.factor(y)||length(unique(y))==2L) "binomial" else "gaussian"
    fit <- glmnet::cv.glmnet(mm,y,alpha=spec@parameters$alpha %||% 1,family=family,nfolds=spec@parameters$nfolds %||% 5)
    cf <- as.matrix(stats::coef(fit,s=spec@parameters$s %||% "lambda.1se")); active <- setdiff(rownames(cf)[cf[,1]!=0],"(Intercept)")
    # map dummy columns back to source features conservatively
    selected <- predictors[vapply(predictors,function(nm) any(startsWith(active,make.names(nm))|startsWith(active,nm)),logical(1))]
    scores <- data.frame(feature=predictors,score=as.numeric(predictors%in%selected),selected=predictors%in%selected,row.names=NULL)
  } else if(method=="tree") {
    if(!requireNamespace("ranger",quietly=TRUE)) .smf_abort("FEATURE_BACKEND_MISSING","Tree-based selection requires optional package 'ranger'.",class="smf_capability_error")
    if(!length(outcome)) .smf_abort("FEATURE_OUTCOME_REQUIRED","Tree-based selection requires an outcome.")
    f <- stats::reformulate(predictors,response=outcome[[1]]); fit <- ranger::ranger(f,data=data,importance=spec@parameters$importance %||% "permutation",num.trees=spec@parameters$num.trees %||% 500)
    imp <- fit$variable.importance; k <- as.integer(spec@n_features %||% min(10L,length(imp))); selected <- names(sort(imp,decreasing=TRUE))[seq_len(min(k,length(imp)))]
    scores <- data.frame(feature=names(imp),score=as.numeric(imp),selected=names(imp)%in%selected,row.names=NULL)
  } else if(method %in% c("rfe","sequential")) {
    if(!length(outcome)) .smf_abort("FEATURE_OUTCOME_REQUIRED", paste0(toupper(method), " selection requires an outcome."))
    search <- .smf_subset_search(data, outcome[[1]], predictors, method, spec@n_features, spec@parameters)
    selected <- search$selected
    last_step <- setNames(rep(NA_real_, length(predictors)), predictors)
    if(nrow(search$history)) {
      touched <- search$history$feature[!is.na(search$history$feature)]
      for(i in seq_along(touched)) last_step[[touched[[i]]]] <- i
    }
    scores <- data.frame(feature=predictors, score=as.numeric(last_step[predictors]), selected=predictors %in% selected, row.names=NULL)
    scores$criterion <- search$criterion
    scores$final_score <- tail(search$history$score, 1L)
    warnings <- list(smf_warning_record("REFERENCE_SUBSET_SELECTOR", "RFE/sequential selection in 0.2.0 uses the package-native stats reference criterion on the training partition. Advanced model-specific wrappers are introduced by later backend modules.", "info", evidence=list(method=method,criterion=search$criterion), override_allowed=FALSE))
  } else if(method %in% c("pca","pls")) {
    rep <- smf_build_representation(data,outcome,spec,id_column,context="training")
    selected <- colnames(rep@transformed); scores <- data.frame(feature=selected,score=NA_real_,selected=TRUE,row.names=NULL)
  } else if(method=="stability") {
    base_method <- spec@parameters$base_method %||% "mutual_information"; B <- as.integer(spec@parameters$B %||% 100L)
    base <- smf_feature_spec(base_method,n_features=spec@n_features,threshold=spec@threshold,parameters=spec@parameters$base_parameters %||% list())
    freq <- setNames(numeric(length(predictors)),predictors)
    for(b in seq_len(B)) { ii <- smf_with_seed((spec@parameters$seed %||% 260915L)+b-1L,sample.int(nrow(data),nrow(data),replace=TRUE)); rr <- smf_select_features(data[ii,,drop=FALSE],outcome,base,id_column,"training"); freq[rr@selected] <- freq[rr@selected]+1 }
    freq <- freq/B; cutoff <- spec@parameters$frequency_cutoff %||% 0.7; selected <- names(freq)[freq>=cutoff]
    scores <- data.frame(feature=names(freq),score=as.numeric(freq),selected=freq>=cutoff,row.names=NULL)
  } else .smf_abort("FEATURE_METHOD_UNKNOWN",paste0("Unknown feature method: ",method))
  FeatureSelectionResult(spec=spec,selected=.smf_chr(selected),scores=scores,fold_results=list(),stability=if(method=="stability")scores else NULL,provenance=list(training_hash=smf_data_hash(data),context=context,outcome=outcome),warnings=warnings)
}

#' Fit PCA or PLS representation on a training partition
#' @export
smf_build_representation <- function(data, outcome=character(), spec=smf_feature_spec("pca"), id_column=character(), context=c("global","training")) {
  context <- match.arg(context); .smf_selection_guard(spec,context)
  predictors <- .smf_feature_predictors(data,outcome,id_column); X <- data[predictors]
  if(spec@method=="pca") {
    num <- names(X)[vapply(X,is.numeric,logical(1))]; if(!length(num)) .smf_abort("PCA_NUMERIC_REQUIRED","PCA requires numeric predictors.")
    cc <- stats::complete.cases(X[num]); if(!all(cc)) .smf_abort("PCA_MISSING_VALUES","PCA representation requires missing values to be handled in preprocessing first.",class="smf_leakage_error")
    fit <- stats::prcomp(X[num],center=spec@parameters$center %||% TRUE,scale.=spec@parameters$scale %||% TRUE)
    k <- min(as.integer(spec@n_features %||% ncol(fit$x)),ncol(fit$x)); transformed <- as.data.frame(fit$x[,seq_len(k),drop=FALSE]); names(transformed) <- paste0("PC",seq_len(k))
    map <- abs(fit$rotation[,seq_len(k),drop=FALSE]); return(RepresentationResult(spec=spec,state=fit,transformed=transformed,training_hash=smf_data_hash(data),feature_map=map))
  }
  if(spec@method=="pls") {
    if(!requireNamespace("pls",quietly=TRUE)) .smf_abort("FEATURE_BACKEND_MISSING","PLS representation requires optional package 'pls'.",class="smf_capability_error")
    if(length(outcome)!=1L) .smf_abort("PLS_OUTCOME_REQUIRED","PLS requires exactly one outcome.")
    if(!all(vapply(X,is.numeric,logical(1)))) .smf_abort("PLS_NUMERIC_REQUIRED","The 0.2.0 PLS representation requires numeric predictors after preprocessing.")
    if(any(!stats::complete.cases(X))) .smf_abort("PLS_MISSING_VALUES","PLS representation requires missing values to be handled in preprocessing first.",class="smf_leakage_error")
    dat <- data[c(outcome,predictors)]; ncomp <- min(as.integer(spec@n_features %||% min(10L,length(predictors))), ncol(X), max(1L,nrow(data)-1L))
    f <- stats::reformulate(predictors,response=outcome); fit <- pls::plsr(f,data=dat,ncomp=ncomp,validation="none",scale=TRUE)
    transformed <- as.data.frame(fit$scores[,seq_len(ncomp),drop=FALSE]); names(transformed) <- paste0("PLS",seq_len(ncol(transformed)))
    return(RepresentationResult(spec=spec,state=fit,transformed=transformed,training_hash=smf_data_hash(data),feature_map=fit$loadings))
  }
  .smf_abort("REPRESENTATION_METHOD_UNSUPPORTED","smf_build_representation supports PCA and PLS.")
}

#' Apply a training-fitted PCA or PLS representation to new data
#' @export
smf_apply_representation <- function(result, newdata) {
  if(!S7::S7_inherits(result,RepresentationResult)) cli::cli_abort("{.arg result} must be a RepresentationResult.")
  if(!is.data.frame(newdata)) cli::cli_abort("{.arg newdata} must be a data.frame.")
  method <- result@spec@method; fit <- result@state; k <- ncol(result@transformed)
  if(method=="pca") {
    predictors <- rownames(fit$rotation); .smf_abort_missing_columns(newdata,predictors,"PCA assessment transformation")
    X <- newdata[predictors]
    if(any(!stats::complete.cases(X))) .smf_abort("PCA_MISSING_VALUES","PCA assessment data contain missing values after preprocessing.",class="smf_leakage_error")
    z <- stats::predict(fit,newdata=X)
    z <- as.data.frame(z[,seq_len(k),drop=FALSE]); names(z) <- paste0("PC",seq_len(k)); return(z)
  }
  if(method=="pls") {
    predictors <- rownames(as.matrix(fit$loadings)); .smf_abort_missing_columns(newdata,predictors,"PLS assessment transformation")
    X <- as.matrix(newdata[predictors]); if(any(!is.finite(X))) .smf_abort("PLS_MISSING_VALUES","PLS assessment data contain non-finite values after preprocessing.",class="smf_leakage_error")
    projection <- as.matrix(fit$projection)[,seq_len(k),drop=FALSE]
    center <- fit$Xmeans
    if(length(center)==ncol(X)) X <- sweep(X,2,center,"-")
    sc <- fit$scale
    if(is.numeric(sc) && length(sc)==ncol(X)) X <- sweep(X,2,sc,"/")
    z <- as.data.frame(X %*% projection); names(z) <- paste0("PLS",seq_len(k)); return(z)
  }
  .smf_abort("REPRESENTATION_METHOD_UNSUPPORTED","Only PCA and PLS representation states can be applied.")
}

#' Fit feature selection separately inside every resampling analysis fold
#' @export
smf_feature_select_resamples <- function(data, outcome, feature_spec, resamples, id_column=character()) {
  if(!S7::S7_inherits(resamples,ResampleCollection)) cli::cli_abort("{.arg resamples} must be a ResampleCollection.")
  if(feature_spec@method %in% c("pca","pls")) {
    fold_results <- lapply(resamples@splits,function(s) smf_build_representation(data[s@train_index,,drop=FALSE],outcome,feature_spec,id_column,"training"))
    comps <- if(length(fold_results)) colnames(fold_results[[1L]]@transformed) else character()
    return(FeatureSelectionResult(spec=feature_spec,selected=.smf_chr(comps),scores=data.frame(feature=comps,selection_frequency=1,row.names=NULL),fold_results=fold_results,stability=NULL,provenance=list(resample_manifest_hash=resamples@manifest_hash,outcome=outcome,kind="representation"),warnings=list()))
  }
  fold_results <- lapply(resamples@splits,function(s) smf_select_features(data[s@train_index,,drop=FALSE],outcome,feature_spec,id_column,"training"))
  predictors <- .smf_feature_predictors(data,outcome,id_column); freq <- setNames(numeric(length(predictors)),predictors)
  for(r in fold_results) freq[r@selected] <- freq[r@selected]+1
  freq <- freq/length(fold_results); selected <- names(freq)[freq>= (feature_spec@parameters$fold_frequency_cutoff %||% 0.5)]
  FeatureSelectionResult(spec=feature_spec,selected=selected,scores=data.frame(feature=names(freq),selection_frequency=as.numeric(freq),row.names=NULL),fold_results=fold_results,stability=data.frame(feature=names(freq),frequency=as.numeric(freq),row.names=NULL),provenance=list(resample_manifest_hash=resamples@manifest_hash,outcome=outcome),warnings=list())
}

#' Return feature-selection stability information
#' @export
smf_feature_stability <- function(result) {
  if(!S7::S7_inherits(result,FeatureSelectionResult)) cli::cli_abort("{.arg result} must be a FeatureSelectionResult.")
  result@stability
}
