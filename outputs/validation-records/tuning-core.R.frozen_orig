# Hyperparameter search spaces and scientific tuning (0.4.0).

.smf_param_domain <- function(type, lower=NULL, upper=NULL, values=NULL, log=FALSE, depends_on=NULL, resource=FALSE) {
  type <- match.arg(type, c("dbl","int","fct","lgl"))
  if (!is.null(depends_on) && !is.list(depends_on)) .smf_abort("SEARCH_CONDITION_INVALID", "depends_on must be a portable list such as list(param='booster', values='dart').", class="smf_tuning_error")
  if (type %in% c("dbl","int")) {
    if (is.null(values) && (is.null(lower) || is.null(upper) || !is.finite(lower) || !is.finite(upper) || lower > upper))
      .smf_abort("SEARCH_DOMAIN_INVALID", "Numeric parameter domains require finite lower <= upper or explicit values.", class="smf_tuning_error")
  }
  if (type == "fct" && (is.null(values) || !length(values))) .smf_abort("SEARCH_DOMAIN_INVALID", "Factor domains require at least one value.", class="smf_tuning_error")
  list(type=type, lower=lower, upper=upper, values=values, log=isTRUE(log), depends_on=depends_on, resource=isTRUE(resource))
}

#' Define a continuous tuning parameter
#' @export
smf_param_dbl <- function(lower=NULL, upper=NULL, values=NULL, log=FALSE, depends_on=NULL, resource=FALSE) {
  .smf_param_domain("dbl", lower, upper, values, log, depends_on, resource)
}

#' Define an integer tuning parameter
#' @export
smf_param_int <- function(lower=NULL, upper=NULL, values=NULL, log=FALSE, depends_on=NULL, resource=FALSE) {
  .smf_param_domain("int", lower, upper, values, log, depends_on, resource)
}

#' Define a categorical tuning parameter
#' @export
smf_param_fct <- function(values, depends_on=NULL) .smf_param_domain("fct", values=.smf_chr(values), depends_on=depends_on)

#' Define a logical tuning parameter
#' @export
smf_param_lgl <- function(values=c(FALSE,TRUE), depends_on=NULL) .smf_param_domain("lgl", values=as.logical(values), depends_on=depends_on)

#' Create a conditional hyperparameter search space
#' @export
smf_search_space <- function(..., parameters=NULL, metadata=list()) {
  dots <- list(...)
  if (is.null(parameters)) parameters <- dots else if (length(dots)) parameters <- c(parameters, dots)
  if (!is.list(parameters) || !length(parameters) || is.null(names(parameters)) || any(!nzchar(names(parameters))) || anyDuplicated(names(parameters)))
    .smf_abort("SEARCH_SPACE_INVALID", "Search space parameters must be a non-empty named list with unique names.", class="smf_tuning_error")
  for (i in seq_along(parameters)) {
    dep <- parameters[[i]]$depends_on
    if (!is.null(dep)) {
      ref <- dep$param %||% names(dep)[[1]]
      if (is.null(ref) || !ref %in% names(parameters)) .smf_abort("SEARCH_CONDITION_REFERENCE_UNKNOWN", paste0("Conditional parameter '", names(parameters)[[i]], "' references an unknown parameter."), class="smf_tuning_error")
      if (match(ref, names(parameters)) >= i) .smf_abort("SEARCH_CONDITION_ORDER", "Conditional parameters must depend on a parameter declared earlier in the search space.", class="smf_tuning_error")
    }
  }
  cond <- lapply(parameters, function(z) z$depends_on)
  SearchSpace(parameters=parameters, conditions=cond, metadata=metadata)
}

#' Create a tuning specification
#' @export
smf_tuning_spec <- function(method=c("grid","random","racing","bayesian","successive_halving","hyperband"), budget=20L,
                            inner_resampling=NULL, objectives=list(), backend=c("native","mlr3"), seed=260915L,
                            decision_rule=NULL, parameters=list()) {
  TuningSpec(method=match.arg(method), budget=as.integer(budget), inner_resampling=inner_resampling,
    objectives=objectives, backend=match.arg(backend), seed=as.integer(seed), decision_rule=decision_rule, parameters=parameters)
}

.smf_condition_active <- function(dep, config) {
  if (is.null(dep) || !length(dep)) return(TRUE)
  if (!is.list(dep)) .smf_abort("SEARCH_CONDITION_INVALID", "depends_on must be a portable list.", class="smf_tuning_error")
  nm <- dep$param %||% names(dep)[[1]]
  vals <- dep$values %||% dep[[nm]]
  if (is.null(nm) || !nm %in% names(config)) return(FALSE)
  config[[nm]] %in% vals
}

.smf_grid_values <- function(domain, levels=5L) {
  if (!is.null(domain$values)) return(domain$values)
  if (domain$type == "int") {
    z <- seq(domain$lower, domain$upper, length.out=min(levels, max(1L, as.integer(domain$upper-domain$lower+1))))
    return(unique(as.integer(round(z))))
  }
  if (domain$type == "dbl") {
    if (isTRUE(domain$log)) return(exp(seq(log(domain$lower), log(domain$upper), length.out=levels)))
    return(seq(domain$lower, domain$upper, length.out=levels))
  }
  if (domain$type == "lgl") return(c(FALSE,TRUE))
  domain$values
}

.smf_clean_conditional_config <- function(config, space) {
  out <- as.list(config)
  for (nm in names(space@parameters)) {
    if (!.smf_condition_active(space@parameters[[nm]]$depends_on, out)) out[[nm]] <- NA
  }
  out
}

#' Generate a deterministic grid from a SearchSpace
#' @export
smf_search_grid <- function(search_space, levels=5L, max_size=10000L) {
  vals <- lapply(search_space@parameters, .smf_grid_values, levels=as.integer(levels))
  g <- do.call(expand.grid, c(vals, stringsAsFactors=FALSE, KEEP.OUT.ATTRS=FALSE))
  if (nrow(g) > max_size) .smf_abort("GRID_TOO_LARGE", paste0("Grid contains ", nrow(g), " configurations; increase max_size explicitly or use random search."), class="smf_tuning_error")
  rows <- lapply(seq_len(nrow(g)), function(i) .smf_clean_conditional_config(g[i,,drop=FALSE], search_space))
  out <- unique(as.data.frame(do.call(rbind, lapply(rows, function(z) as.data.frame(z, stringsAsFactors=FALSE))), stringsAsFactors=FALSE))
  rownames(out) <- NULL
  out
}

.smf_sample_one <- function(domain) {
  if (!is.null(domain$values)) return(sample(domain$values, 1L))
  if (domain$type == "dbl") {
    if (isTRUE(domain$log)) return(exp(stats::runif(1L, log(domain$lower), log(domain$upper))))
    return(stats::runif(1L, domain$lower, domain$upper))
  }
  if (domain$type == "int") {
    if (isTRUE(domain$log)) return(as.integer(round(exp(stats::runif(1L, log(domain$lower), log(domain$upper))))))
    return(sample(seq.int(as.integer(domain$lower), as.integer(domain$upper)), 1L))
  }
  if (domain$type == "lgl") return(sample(c(FALSE,TRUE),1L))
  sample(domain$values,1L)
}

#' Draw random configurations from a SearchSpace
#' @export
smf_search_random <- function(search_space, n=20L, seed=260915L) {
  n <- as.integer(n); if (n < 1L) .smf_abort("RANDOM_SEARCH_N_INVALID", "n must be at least 1.", class="smf_tuning_error")
  z <- smf_with_seed(seed, lapply(seq_len(n), function(i) {
    cfg <- list()
    for (nm in names(search_space@parameters)) {
      d <- search_space@parameters[[nm]]
      cfg[[nm]] <- if (.smf_condition_active(d$depends_on, cfg)) .smf_sample_one(d) else NA
    }
    cfg
  }))
  out <- unique(as.data.frame(do.call(rbind, lapply(z, function(x) as.data.frame(x, stringsAsFactors=FALSE))), stringsAsFactors=FALSE))
  rownames(out) <- NULL
  out
}

.smf_objective_specs <- function(tuning, spec=NULL) {
  obj <- tuning@objectives
  if (!length(obj) && !is.null(spec)) obj <- spec@metrics
  if (!is.list(obj)) obj <- list(obj)
  if (!length(obj)) .smf_abort("TUNING_OBJECTIVE_MISSING", "At least one explicit tuning objective is required.", class="smf_tuning_error")
  bad <- !vapply(obj, function(x) .smf_is_s7(x) && identical(S7::S7_class(x)@name, "MetricSpec"), logical(1))
  if (any(bad)) .smf_abort("TUNING_OBJECTIVE_INVALID", "Tuning objectives must be MetricSpec objects.", class="smf_tuning_error")
  obj
}

.smf_objective_names <- function(objectives) vapply(objectives, function(x) x@name, character(1))
.smf_objective_directions <- function(objectives) stats::setNames(vapply(objectives, function(x) x@direction, character(1)), .smf_objective_names(objectives))

.smf_metric_vector <- function(metric_table, objectives) {
  nm <- .smf_objective_names(objectives)
  out <- stats::setNames(rep(NA_real_, length(nm)), nm)
  for (m in nm) {
    zz <- metric_table[metric_table$metric == m,,drop=FALSE]
    if (nrow(zz)) out[[m]] <- mean(zz$value, na.rm=TRUE)
  }
  out
}

.smf_config_id <- function(cfg) paste0("cfg_", substr(smf_hash(as.list(cfg)),1,12))

.smf_set_nested_param <- function(x, path, value) {
  bits <- strsplit(path, "\\.", fixed=FALSE)[[1]]
  if (length(bits)==1L) { x[[bits]] <- value; return(x) }
  head <- bits[[1]]; rest <- paste(bits[-1], collapse=".")
  sub <- x[[head]] %||% list(); sub <- .smf_set_nested_param(sub, rest, value); x[[head]] <- sub; x
}

.smf_update_model_params <- function(spec, params) {
  params <- as.list(params); params <- params[!vapply(params, function(x) length(x)==1L && is.na(x), logical(1))]
  merged <- spec@model@parameters
  for (nm in names(params)) merged <- .smf_set_nested_param(merged, nm, params[[nm]])
  model <- smf_model_spec(spec@model@family, spec@model@engine, parameters=merged, seed=spec@model@seed)
  ExperimentSpec(task=spec@task,data=spec@data,design=spec@design,preprocessing=spec@preprocessing,resampling=spec@resampling,
    model=model,metrics=spec@metrics,features=spec@features,bootstrap=spec@bootstrap,probabilistic=spec@probabilistic,
    calibration=spec@calibration,imbalance=spec@imbalance,tuning=spec@tuning,benchmark=spec@benchmark,explain=spec@explain,reporting=spec@reporting,
    bayesian=spec@bayesian,deep_learning=spec@deep_learning,uncertainty=spec@uncertainty,reproducibility=spec@reproducibility)
}

.smf_tuning_guard <- function(data) {
  role <- attr(data, "smf_partition_role", exact=TRUE)
  if (!is.null(role) && role %in% c("test","final_test","external_test","assessment"))
    .smf_abort("TEST_DATA_IN_TUNING", "Managed tuning cannot operate on data marked as assessment/final test data.", class="smf_leakage_error")
  invisible(TRUE)
}

.smf_eval_config_resamples <- function(spec, data, resamples, config, objectives, fold_limit=NULL) {
  use <- seq_along(resamples@splits)
  if (!is.null(fold_limit)) use <- head(use, as.integer(fold_limit))
  sp <- .smf_update_model_params(spec, config)
  rows <- lapply(use, function(i) {
    fr <- .smf_fit_one_split(sp, data, resamples@splits[[i]])
    v <- .smf_metric_vector(fr$metrics, objectives)
    data.frame(fold=i, metric=names(v), value=as.numeric(v), stringsAsFactors=FALSE)
  })
  raw <- do.call(rbind, rows)
  means <- tapply(raw$value, raw$metric, mean, na.rm=TRUE)
  list(values=means, fold_metrics=raw)
}

.smf_archive_row <- function(config, values, trial, elapsed, extra=list()) {
  z <- c(list(trial=as.integer(trial), config_id=.smf_config_id(config)), as.list(config), as.list(values), list(elapsed_seconds=as.numeric(elapsed)), extra)
  as.data.frame(z, stringsAsFactors=FALSE, check.names=FALSE)
}

#' Return the nondominated Pareto set for explicit objectives
#' @export
smf_pareto_front <- function(data, objectives, directions) {
  if (!nrow(data)) return(data)
  objectives <- as.character(objectives); directions <- directions[objectives]
  x <- as.matrix(data[objectives]); storage.mode(x) <- "double"
  for (j in seq_along(objectives)) if (directions[[j]] == "maximize") x[,j] <- -x[,j]
  dominated <- logical(nrow(x))
  for (i in seq_len(nrow(x))) {
    for (j in seq_len(nrow(x))) if (i != j && all(x[j,] <= x[i,], na.rm=FALSE) && any(x[j,] < x[i,], na.rm=FALSE)) { dominated[i] <- TRUE; break }
  }
  data[!dominated,,drop=FALSE]
}

#' Select an explicit compromise from candidates or a Pareto set
#' @export
smf_select_compromise <- function(data, objectives, directions, rule) {
  if (is.null(rule) || !length(rule)) return(NULL)
  type <- rule$type %||% "weighted_sum"
  objectives <- as.character(objectives); directions <- directions[objectives]
  if (type == "lexicographic") {
    ord_obj <- rule$order %||% objectives
    idx <- seq_len(nrow(data))
    for (m in rev(ord_obj)) idx <- idx[order(if (directions[[m]]=="maximize") -data[[m]][idx] else data[[m]][idx], na.last=TRUE)]
    return(data[idx[[1]],,drop=FALSE])
  }
  if (type == "weighted_sum") {
    weights <- rule$weights %||% rep(1/length(objectives),length(objectives)); names(weights) <- names(weights) %||% objectives
    weights <- weights[objectives]; weights[is.na(weights)] <- 0; if (sum(weights)<=0) .smf_abort("DECISION_WEIGHTS_INVALID","Decision-rule weights must sum to a positive value.",class="smf_tuning_error")
    weights <- weights/sum(weights)
    score <- rep(0,nrow(data))
    for (m in objectives) {
      z <- data[[m]]; rng <- range(z,na.rm=TRUE); q <- if (diff(rng)==0) rep(0,length(z)) else (z-rng[[1]])/diff(rng)
      if (directions[[m]]=="maximize") q <- 1-q
      score <- score + weights[[m]]*q
    }
    out <- data[which.min(score),,drop=FALSE]; out$.decision_score <- min(score); return(out)
  }
  .smf_abort("DECISION_RULE_UNSUPPORTED", paste0("Unsupported decision rule: ",type), class="smf_tuning_error")
}

.smf_finalize_tuning <- function(tuning, space, archive, objectives, resamples, warnings=list(), provenance=list()) {
  dirs <- .smf_objective_directions(objectives); obj_names <- names(dirs)
  valid <- archive[stats::complete.cases(archive[obj_names]),,drop=FALSE]
  pareto <- if (length(obj_names)>1L && nrow(valid)) smf_pareto_front(valid,obj_names,dirs) else valid
  selected <- NULL
  if (nrow(valid)) {
    if (length(obj_names)==1L) {
      m <- obj_names[[1]]; i <- if (dirs[[m]]=="maximize") which.max(valid[[m]]) else which.min(valid[[m]])
      selected <- valid[i,,drop=FALSE]
    } else selected <- smf_select_compromise(pareto,obj_names,dirs,tuning@decision_rule)
  }
  TuningResult(spec=tuning,search_space=space,archive=archive,selected=selected,pareto=pareto,
    decision_rule=tuning@decision_rule,inner_resampling=resamples,
    split_hashes=lapply(resamples@splits,function(s)s@hash),warnings=warnings,
    provenance=c(list(method=tuning@method,backend=tuning@backend,selection_estimate="inner_resampling",final_test_used=FALSE),provenance))
}

.smf_candidate_configs <- function(space,tuning) {
  if (tuning@method=="grid") {
    g <- smf_search_grid(space, levels=tuning@parameters$levels %||% 5L, max_size=tuning@parameters$max_grid_size %||% 10000L)
    return(head(g,tuning@budget))
  }
  smf_search_random(space,tuning@budget,tuning@seed)
}

.smf_tune_standard <- function(spec,data,space,tuning,resamples,objectives) {
  cfgs <- .smf_candidate_configs(space,tuning); out <- vector("list",nrow(cfgs))
  for (i in seq_len(nrow(cfgs))) {
    start <- proc.time()[[3]]; cfg <- as.list(cfgs[i,,drop=FALSE]); ev <- .smf_eval_config_resamples(spec,data,resamples,cfg,objectives)
    out[[i]] <- .smf_archive_row(cfg,ev$values,i,proc.time()[[3]]-start,list(n_folds=length(resamples@splits)))
  }
  do.call(rbind,out)
}

.smf_primary_loss <- function(values, objective) {
  x <- as.numeric(values[[objective@name]])
  if (objective@direction=="maximize") -x else x
}

.smf_tune_racing <- function(spec,data,space,tuning,resamples,objectives) {
  cfgs <- smf_search_random(space,tuning@budget,tuning@seed); active <- seq_len(nrow(cfgs)); hist <- list(); alpha <- tuning@parameters$alpha %||% 0.10
  min_folds <- max(2L,as.integer(tuning@parameters$min_folds %||% 2L)); primary <- objectives[[1]]; fold_values <- vector("list",nrow(cfgs))
  for (f in seq_along(resamples@splits)) {
    for (i in active) {
      sp <- .smf_update_model_params(spec,as.list(cfgs[i,,drop=FALSE])); fr <- .smf_fit_one_split(sp,data,resamples@splits[[f]])
      v <- .smf_metric_vector(fr$metrics,objectives); fold_values[[i]] <- rbind(fold_values[[i]],data.frame(fold=f,metric=names(v),value=as.numeric(v)))
      hist[[length(hist)+1L]] <- .smf_archive_row(as.list(cfgs[i,,drop=FALSE]),v,length(hist)+1L,NA_real_,list(stage=f,status="active"))
    }
    if (f >= min_folds && length(active)>1L) {
      means <- vapply(active,function(i){z<-fold_values[[i]]; mean(z$value[z$metric==primary@name],na.rm=TRUE)},numeric(1))
      best_local <- if(primary@direction=="maximize") which.max(means) else which.min(means); best_i <- active[[best_local]]
      survivors <- active[vapply(active,function(i){
        if(i==best_i) return(TRUE)
        zi<-fold_values[[i]]; zb<-fold_values[[best_i]]; ai<-zi$value[zi$metric==primary@name]; ab<-zb$value[zb$metric==primary@name]
        d <- if(primary@direction=="maximize") ab-ai else ai-ab
        if(length(d)<2L || stats::sd(d)==0) return(mean(d,na.rm=TRUE) <= 0)
        lower <- mean(d,na.rm=TRUE) - stats::qt(1-alpha,df=length(d)-1L)*stats::sd(d,na.rm=TRUE)/sqrt(length(d))
        lower <= 0
      },logical(1))]
      if (!length(survivors)) survivors <- best_i
      active <- survivors
    }
    if(length(active)==1L && f>=min_folds) break
  }
  # Add one aggregate record per configuration evaluated at least once.
  agg <- lapply(seq_len(nrow(cfgs)),function(i){ z<-fold_values[[i]]; if(is.null(z)||!nrow(z))return(NULL); vals=tapply(z$value,z$metric,mean,na.rm=TRUE); .smf_archive_row(as.list(cfgs[i,,drop=FALSE]),vals,100000L+i,NA_real_,list(n_folds=length(unique(z$fold)),status=if(i%in%active)"survivor" else "eliminated")) })
  do.call(rbind,c(hist,Filter(Negate(is.null),agg)))
}

.smf_encode_configs <- function(df, space) {
  m <- matrix(0,nrow(df),0); colnames(m)<-character()
  for(nm in names(space@parameters)) {
    d<-space@parameters[[nm]]; z<-df[[nm]]; active<-!is.na(z)
    if(d$type %in% c("dbl","int")) {
      zz<-as.numeric(z); lo<-d$lower %||% min(zz,na.rm=TRUE); hi<-d$upper %||% max(zz,na.rm=TRUE); zz[!active]<-(lo+hi)/2; if(isTRUE(d$log)){zz<-log(pmax(zz,.Machine$double.eps));lo<-log(lo);hi<-log(hi)}; zz<-if(hi==lo)rep(0,length(zz))else(zz-lo)/(hi-lo); m<-cbind(m,zz,as.numeric(active)); colnames(m)[(ncol(m)-1):ncol(m)]<-c(nm,paste0(nm,"__active"))
    } else {
      lev<-as.character(d$values %||% c(FALSE,TRUE)); zz<-match(as.character(z),lev); zz[!active]<-0; denom<-max(1,length(lev)); m<-cbind(m,zz/denom,as.numeric(active)); colnames(m)[(ncol(m)-1):ncol(m)]<-c(nm,paste0(nm,"__active"))
    }
  }
  m
}

.smf_gp_fit <- function(x,y,noise=1e-8) {
  ymean<-mean(y); ysd<-stats::sd(y); if(!is.finite(ysd)||ysd==0)ysd<-1; ys<-(y-ymean)/ysd
  d<-as.matrix(stats::dist(x)); positive<-d[d>0]; ell<-if(length(positive))stats::median(positive) else 1; if(!is.finite(ell)||ell<=0)ell<-1
  base<-exp(-(d^2)/(2*ell^2)); cholK<-NULL; used_noise<-noise
  for (jitter in c(noise,1e-7,1e-6,1e-5,1e-4,1e-3)) {
    k<-base; diag(k)<-diag(k)+jitter; candidate<-try(chol(k),silent=TRUE)
    if(!inherits(candidate,"try-error")){cholK<-candidate;used_noise<-jitter;break}
  }
  if(is.null(cholK)) .smf_abort("BAYESIAN_SURROGATE_SINGULAR","Gaussian-process surrogate covariance remained singular after jitter escalation.",class="smf_tuning_error")
  alpha<-backsolve(cholK,forwardsolve(t(cholK),ys))
  list(x=x,ymean=ymean,ysd=ysd,ell=ell,chol=cholK,alpha=alpha,noise=used_noise)
}

.smf_gp_predict <- function(fit,xnew) {
  d2<-outer(seq_len(nrow(xnew)),seq_len(nrow(fit$x)),Vectorize(function(i,j)sum((xnew[i,]-fit$x[j,])^2)))
  ks<-exp(-d2/(2*fit$ell^2)); mu<-as.numeric(ks%*%fit$alpha); v<-forwardsolve(t(fit$chol),t(ks)); var<-pmax(1-rowSums(t(v)^2),1e-12)
  list(mean=fit$ymean+fit$ysd*mu,sd=fit$ysd*sqrt(var))
}

.smf_tune_bayesian <- function(spec,data,space,tuning,resamples,objectives) {
  primary<-objectives[[1]]; init_n<-min(tuning@budget,max(5L,as.integer(tuning@parameters$initial %||% max(5L,2L*length(space@parameters)))))
  cfgs<-smf_search_random(space,init_n,tuning@seed); archive<-list()
  eval_cfg<-function(cfg,i){ st<-proc.time()[[3]]; ev<-.smf_eval_config_resamples(spec,data,resamples,cfg,objectives); .smf_archive_row(cfg,ev$values,i,proc.time()[[3]]-st,list(acquisition=if(i<=init_n)"initial" else "expected_improvement")) }
  for(i in seq_len(nrow(cfgs))) archive[[i]]<-eval_cfg(as.list(cfgs[i,,drop=FALSE]),i)
  if(tuning@budget>init_n) for(i in seq.int(init_n+1L,tuning@budget)) {
    ar<-do.call(rbind,archive); x<-.smf_encode_configs(ar[names(space@parameters)],space); y<-ar[[primary@name]]; if(primary@direction=="maximize")y<--y
    gp<-.smf_gp_fit(x,y); pool<-smf_search_random(space,as.integer(tuning@parameters$candidate_pool %||% 512L),tuning@seed+i); xp<-.smf_encode_configs(pool,space); pr<-.smf_gp_predict(gp,xp)
    best<-min(y,na.rm=TRUE); z<-(best-pr$mean)/pmax(pr$sd,1e-12); ei<-(best-pr$mean)*stats::pnorm(z)+pr$sd*stats::dnorm(z); pick<-which.max(ei)
    archive[[i]]<-eval_cfg(as.list(pool[pick,,drop=FALSE]),i)
  }
  do.call(rbind,archive)
}

.smf_resource_param <- function(space,tuning) {
  p<-tuning@parameters$resource_param
  if(is.null(p)) {rr<-names(space@parameters)[vapply(space@parameters,function(z)isTRUE(z$resource),logical(1))]; if(length(rr)==1L)p<-rr}
  if(is.null(p)||!length(p)||!p%in%names(space@parameters)) .smf_abort("RESOURCE_PARAMETER_REQUIRED","Successive halving/Hyperband requires a declared resource parameter.",class="smf_tuning_error")
  p
}

.smf_tune_halving_bracket <- function(spec,data,space,tuning,resamples,objectives,n_configs,min_resource,max_resource,eta,bracket=1L) {
  resource<-.smf_resource_param(space,tuning); cfgs<-smf_search_random(space,n_configs,tuning@seed+bracket); active<-seq_len(nrow(cfgs)); stage<-0L; archive<-list(); trial<-0L; r<-min_resource; primary<-objectives[[1]]
  while(length(active)>0L && r<=max_resource) {
    stage<-stage+1L
    vals<-numeric(length(active))
    for(k in seq_along(active)) {i<-active[[k]]; cfg<-as.list(cfgs[i,,drop=FALSE]); cfg[[resource]]<-as.integer(round(r)); st<-proc.time()[[3]]; ev<-.smf_eval_config_resamples(spec,data,resamples,cfg,objectives); trial<-trial+1L; archive[[trial]]<-.smf_archive_row(cfg,ev$values,trial,proc.time()[[3]]-st,list(stage=stage,bracket=bracket,resource_value=r)); vals[[k]]<-.smf_primary_loss(ev$values,primary)}
    if(length(active)==1L||r>=max_resource)break
    keep<-max(1L,floor(length(active)/eta)); active<-active[order(vals)][seq_len(keep)]; r<-min(max_resource,r*eta)
  }
  do.call(rbind,archive)
}

.smf_tune_halving <- function(spec,data,space,tuning,resamples,objectives) {
  eta<-as.numeric(tuning@parameters$eta %||% 3)
  resource <- .smf_resource_param(space,tuning); domain <- space@parameters[[resource]]
  default_min <- if (!is.null(domain$lower)) domain$lower else min(as.numeric(domain$values),na.rm=TRUE)
  default_max <- if (!is.null(domain$upper)) domain$upper else max(as.numeric(domain$values),na.rm=TRUE)
  minr<-as.numeric(tuning@parameters$min_resource %||% default_min); maxr<-as.numeric(tuning@parameters$max_resource %||% default_max)
  if (!is.finite(minr) || !is.finite(maxr) || minr <= 0 || maxr < minr) .smf_abort("RESOURCE_RANGE_INVALID","Resource bounds must satisfy 0 < min_resource <= max_resource.",class="smf_tuning_error")
  if(tuning@method=="successive_halving") return(.smf_tune_halving_bracket(spec,data,space,tuning,resamples,objectives,tuning@budget,minr,maxr,eta,1L))
  smax<-floor(log(maxr/minr,base=eta)); all<-list()
  for(s in 0:smax){ n<-ceiling((smax+1)/(s+1)*eta^s); r<-maxr*eta^(-s); all[[length(all)+1L]]<-.smf_tune_halving_bracket(spec,data,space,tuning,resamples,objectives,n,r,maxr,eta,s+1L)}
  do.call(rbind,all)
}

#' Tune an arbitrary objective callback using package-native search algorithms
#' @export
smf_tune_objective <- function(search_space, tuning, evaluator) {
  if (!is.function(evaluator)) .smf_abort("TUNING_EVALUATOR_INVALID", "evaluator must be a function accepting one configuration list.", class="smf_tuning_error")
  objectives<-.smf_objective_specs(tuning); cfgs<-.smf_candidate_configs(search_space,tuning); rows<-list()
  if(tuning@method %in% c("successive_halving","hyperband")) .smf_abort("OBJECTIVE_RESOURCE_UNSUPPORTED","Resource-aware tuning requires smf_tune() so resource values can be propagated to ModelSpec.",class="smf_tuning_error")
  # The callback path is intentionally deterministic and primarily supports grid/random plus archive testing.
  if(!tuning@method %in% c("grid","random")) .smf_abort("OBJECTIVE_METHOD_REQUIRES_MODEL","Racing and Bayesian methods require managed resampling through smf_tune().",class="smf_tuning_error")
  for(i in seq_len(nrow(cfgs))){cfg<-as.list(cfgs[i,,drop=FALSE]);st<-proc.time()[[3]];val<-evaluator(cfg);if(is.null(names(val)))names(val)<-.smf_objective_names(objectives);rows[[i]]<-.smf_archive_row(cfg,val,i,proc.time()[[3]]-st)}
  dummy<-ResampleCollection(method="objective",splits=list(),seed=tuning@seed,source_spec=NULL,design=NULL,manifest_hash=smf_hash(list(method="objective",seed=tuning@seed)),diagnostics=list(),nested=list())
  .smf_finalize_tuning(tuning,search_space,do.call(rbind,rows),objectives,dummy,provenance=list(callback=TRUE))
}

#' Tune model hyperparameters using design-aware inner resampling
#' @export
smf_tune <- function(spec, data, search_space, tuning=smf_tuning_spec(), resamples=NULL, override=FALSE) {
  .smf_tuning_guard(data); smf_validate_schema(data,spec@data)
  if (tuning@backend == "mlr3") .smf_abort("MLR3_TUNING_PIPELINE_NOT_CERTIFIED", "The mlr3 tuning backend is reserved but not allowed to bypass sciModelFlowR fold-safe preprocessing in 0.4.0; use backend='native'.", class="smf_capability_error")
  objectives<-.smf_objective_specs(tuning,spec)
  if(is.null(resamples)) {
    inner<-tuning@inner_resampling %||% spec@resampling
    if(is.null(inner)) .smf_abort("INNER_RESAMPLING_REQUIRED","Managed tuning requires an explicit inner ResamplingSpec.",class="smf_tuning_error")
    if(inner@method=="external") .smf_abort("EXTERNAL_TEST_IN_TUNING","External/final validation cannot be used as an inner tuning resampler.",class="smf_leakage_error")
    resamples<-smf_make_resampler(data,inner,spec@design,spec@task,override=override)
  }
  if(!S7::S7_inherits(resamples,ResampleCollection)) .smf_abort("TUNING_RESAMPLES_INVALID","resamples must be a ResampleCollection.",class="smf_tuning_error")
  if (identical(resamples@method, "external")) .smf_abort("EXTERNAL_TEST_IN_TUNING", "An external/final validation collection cannot be supplied to managed tuning.", class="smf_leakage_error")
  archive<-switch(tuning@method,
    grid=.smf_tune_standard(spec,data,search_space,tuning,resamples,objectives),
    random=.smf_tune_standard(spec,data,search_space,tuning,resamples,objectives),
    racing=.smf_tune_racing(spec,data,search_space,tuning,resamples,objectives),
    bayesian=.smf_tune_bayesian(spec,data,search_space,tuning,resamples,objectives),
    successive_halving=.smf_tune_halving(spec,data,search_space,tuning,resamples,objectives),
    hyperband=.smf_tune_halving(spec,data,search_space,tuning,resamples,objectives),
    .smf_abort("TUNING_METHOD_UNSUPPORTED",paste0("Unsupported tuning method: ",tuning@method),class="smf_tuning_error"))
  .smf_finalize_tuning(tuning,search_space,archive,objectives,resamples,provenance=list(data_hash=smf_data_hash(data),nested=FALSE))
}

#' Perform nested model selection with separate selection and generalization estimates
#' @export
smf_nested_tune <- function(spec, data, search_space, tuning, outer, inner, override=FALSE) {
  .smf_tuning_guard(data); nested<-smf_nested_resampler(data,outer,inner,spec@design,spec@task,override)
  objectives<-.smf_objective_specs(tuning,spec); outer_results<-vector("list",length(nested@splits)); sel_rows<-list(); gen_rows<-list(); hashes<-list()
  for(i in seq_along(nested@splits)) {
    inn<-nested@nested[[i]]; tune_i<-TuningSpec(method=tuning@method,budget=tuning@budget,inner_resampling=inner,objectives=tuning@objectives,backend=tuning@backend,seed=as.integer(tuning@seed+i-1L),decision_rule=tuning@decision_rule,parameters=tuning@parameters)
    tr<-smf_tune(spec,data,search_space,tune_i,resamples=inn,override=override)
    if(is.null(tr@selected)||!nrow(tr@selected)) .smf_abort("NESTED_COMPROMISE_REQUIRED","Nested multi-objective tuning requires an explicit compromise rule before outer refitting.",class="smf_tuning_error")
    cfg<-as.list(tr@selected[1,names(search_space@parameters),drop=FALSE]); sp<-.smf_update_model_params(spec,cfg); fr<-.smf_fit_one_split(sp,data,nested@splits[[i]])
    sv<-tr@selected[1,.smf_objective_names(objectives),drop=FALSE]; sv$outer_fold<-i; sel_rows[[i]]<-sv
    gv<-.smf_metric_vector(fr$metrics,objectives); gen_rows[[i]]<-data.frame(outer_fold=i,metric=names(gv),outer_generalization=as.numeric(gv),stringsAsFactors=FALSE)
    hashes[[i]]<-list(outer=nested@splits[[i]]@hash,inner=inn@manifest_hash)
    outer_results[[i]]<-list(tuning=tr,selected_config=cfg,fit=fr)
  }
  NestedTuningResult(spec=spec,tuning=tuning,search_space=search_space,outer_resampling=nested,outer_results=outer_results,
    selection_scores=do.call(rbind,sel_rows),generalization_scores=do.call(rbind,gen_rows),split_hashes=hashes,warnings=list(),
    provenance=list(selection_estimate="inner_resampling",generalization_estimate="outer_resampling",final_test_used=FALSE,distinct_split_hashes=TRUE))
}
