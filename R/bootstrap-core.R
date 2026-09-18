.smf_bootstrap_stat <- function(statistic, data) {
  val <- statistic(data)
  if (!is.numeric(val) || !length(val) || any(!is.finite(val))) {
    .smf_abort("BOOTSTRAP_STATISTIC_INVALID", "Bootstrap statistic must return a finite numeric vector.", class="smf_bootstrap_error")
  }
  if (is.null(names(val))) names(val) <- paste0("stat", seq_along(val))
  val
}

.smf_bootstrap_rows <- function(data, spec, design) {
  n <- nrow(data); method <- spec@method; p <- spec@parameters
  if (method=="case") return(sample.int(n,n,replace=TRUE))
  if (method=="stratified") {
    strata <- p$strata %||% spec@sampling_unit
    if (!length(strata)) .smf_abort("BOOTSTRAP_STRATA_MISSING", "Stratified bootstrap requires parameters$strata or sampling_unit.")
    .smf_abort_missing_columns(data,strata,"stratified bootstrap")
    g <- interaction(data[strata],drop=TRUE,lex.order=TRUE)
    return(unlist(lapply(split(seq_len(n),g),function(ii) sample(ii,length(ii),replace=TRUE)),use.names=FALSE))
  }
  if (method=="cluster") {
    unit <- spec@sampling_unit %||% p$cluster %||% design@group_columns
    if (!length(unit)) .smf_abort("BOOTSTRAP_CLUSTER_MISSING", "Cluster bootstrap requires a declared sampling unit.")
    .smf_abort_missing_columns(data,unit,"cluster bootstrap")
    g <- interaction(data[unit],drop=TRUE,lex.order=TRUE); lev <- levels(g); sampled <- sample(lev,length(lev),replace=TRUE)
    return(unlist(lapply(sampled,function(z) which(as.character(g)==z)),use.names=FALSE))
  }
  if (method=="hierarchical") {
    hierarchy <- p$hierarchy %||% unlist(design@hierarchy,use.names=FALSE)
    hierarchy <- unique(as.character(hierarchy))
    if (!length(hierarchy)) .smf_abort("BOOTSTRAP_HIERARCHY_MISSING", "Hierarchical bootstrap requires ordered hierarchy columns in parameters$hierarchy.")
    .smf_abort_missing_columns(data,hierarchy,"hierarchical bootstrap")
    rec <- function(ii, level) {
      if (level>length(hierarchy)) return(ii)
      z <- as.character(data[[hierarchy[[level]]]][ii]); units <- unique(z); sampled <- sample(units,length(units),replace=TRUE)
      unlist(lapply(sampled,function(u) rec(ii[z==u],level+1L)),use.names=FALSE)
    }
    return(rec(seq_len(n),1L))
  }
  if (method %in% c("moving_block","stationary_block")) {
    order_col <- p$order %||% design@time_column
    ord <- if (length(order_col)) { .smf_abort_missing_columns(data,order_col,"block bootstrap"); order(data[[order_col]]) } else seq_len(n)
    L <- as.integer(spec@block_length %||% p$block_length %||% max(2L,round(sqrt(n))))
    if (L<1L || L>n) .smf_abort("BOOTSTRAP_BLOCK_LENGTH_INVALID", "Block length must lie between 1 and n.")
    if (method=="moving_block") {
      starts <- seq_len(n-L+1L); out <- integer()
      while(length(out)<n) { st <- sample(starts,1L); out <- c(out,ord[st:(st+L-1L)]) }
      return(out[seq_len(n)])
    }
    out <- integer()
    prob_end <- 1/L
    while(length(out)<n) {
      pos <- sample.int(n,1L)
      repeat {
        out <- c(out,ord[pos]); if(length(out)>=n || runif(1)<prob_end) break
        pos <- if(pos==n) 1L else pos+1L
      }
    }
    return(out[seq_len(n)])
  }
  if (method=="spatial_block") {
    block_col <- p$block_column
    if (length(block_col)) {
      .smf_abort_missing_columns(data,block_col,"spatial block bootstrap"); g <- factor(data[[block_col]])
    } else {
      coords <- p$coords %||% design@coordinate_columns
      if (length(coords)!=2L) .smf_abort("BOOTSTRAP_SPATIAL_CONFIG_MISSING", "Spatial-block bootstrap requires block_column or two coordinates.")
      g <- .smf_spatial_grid(data,coords,p$n_x %||% 2L,p$n_y %||% 2L)
    }
    lev <- levels(g); sampled <- sample(lev,length(lev),replace=TRUE)
    return(unlist(lapply(sampled,function(z) which(as.character(g)==z)),use.names=FALSE))
  }
  .smf_abort("BOOTSTRAP_INDEX_METHOD_UNSUPPORTED", paste0("Index bootstrap is not available for method ",method,"."), class="smf_bootstrap_error")
}

#' Validate bootstrap unit against declared dependence
#' @export
smf_validate_bootstrap_design <- function(data, spec, design=smf_design_spec(), override=FALSE) {
  smf_validate_design(data,design)
  dep_group <- length(design@repeated_unit) || length(design@group_columns)
  dep_time <- length(design@time_column)
  dep_space <- length(design@coordinate_columns)
  iid <- spec@method %in% c("case","stratified")
  bad <- (iid && (dep_group || dep_time || dep_space)) ||
    (dep_group && !spec@method %in% c("cluster","hierarchical")) ||
    (dep_time && !spec@method %in% c("moving_block","stationary_block","hierarchical","cluster")) ||
    (dep_space && !spec@method %in% c("spatial_block","cluster","hierarchical"))
  if (bad) {
    msg <- "The requested bootstrap unit does not preserve dependence declared in DesignSpec."
    if (!override) .smf_abort("BOOTSTRAP_DESIGN_MISMATCH",msg,evidence=list(method=spec@method),class="smf_design_mismatch_error")
    return(list(smf_warning_record("BOOTSTRAP_DESIGN_MISMATCH",msg,"high",evidence=list(method=spec@method),suggested_action="Choose cluster, hierarchical, temporal-block, or spatial-block bootstrap as appropriate.")))
  }
  list()
}

.smf_bootstrap_se <- function(se_fun, data, expected_names) {
  se <- se_fun(data)
  if (!is.numeric(se) || length(se) != length(expected_names) || any(!is.finite(se)) || any(se <= 0)) {
    .smf_abort("BOOTSTRAP_SE_INVALID", "Bootstrap standard_error must return a positive finite numeric vector matching the statistic length.", class="smf_bootstrap_error")
  }
  if (is.null(names(se))) names(se) <- expected_names
  se <- se[expected_names]
  if (anyNA(se)) .smf_abort("BOOTSTRAP_SE_NAMES_INVALID", "Bootstrap standard_error names must match statistic names.", class="smf_bootstrap_error")
  se
}

.smf_bootstrap_interval <- function(estimates, original, level, method, data=NULL, statistic=NULL, se_fun=NULL, replicate_se=NULL) {
  alpha <- 1-level; est <- as.matrix(estimates); out <- vector("list",ncol(est)); names(out) <- colnames(est)
  original_se <- if (method=="studentized") .smf_bootstrap_se(se_fun, data, names(original)) else NULL
  for (j in seq_len(ncol(est))) {
    z <- est[,j]; ok <- is.finite(z); z <- z[ok]; theta <- original[[j]]
    if (!length(z)) { out[[j]] <- c(lower=NA_real_,upper=NA_real_); next }
    if (method=="percentile") q <- stats::quantile(z,c(alpha/2,1-alpha/2),names=FALSE,type=7)
    else if (method=="basic") { qq <- stats::quantile(z,c(alpha/2,1-alpha/2),names=FALSE,type=7); q <- c(2*theta-qq[2],2*theta-qq[1]) }
    else if (method=="bca") {
      if (is.null(data) || is.null(statistic)) .smf_abort("BCA_REQUIRES_DATA", "BCa intervals require original data and a statistic function.")
      jack <- vapply(seq_len(nrow(data)),function(i) .smf_bootstrap_stat(statistic,data[-i,,drop=FALSE])[[j]],numeric(1))
      jm <- mean(jack); num <- sum((jm-jack)^3); den <- 6*(sum((jm-jack)^2)^(3/2)); acc <- if(den==0) 0 else num/den
      prop <- min(max(mean(z<theta),1/(2*length(z))),1-1/(2*length(z))); z0 <- stats::qnorm(prop)
      za <- stats::qnorm(c(alpha/2,1-alpha/2)); probs <- stats::pnorm(z0+(z0+za)/(1-acc*(z0+za)))
      q <- stats::quantile(z,probs,names=FALSE,type=7)
    } else if (method=="studentized") {
      if (is.null(se_fun) || is.null(data) || is.null(replicate_se)) .smf_abort("STUDENTIZED_REQUIRES_SE", "Studentized intervals require parameters$standard_error and replicate-specific standard errors.")
      se_j <- as.matrix(replicate_se)[,j][ok]
      keep <- is.finite(se_j) & se_j > 0
      if (!any(keep)) .smf_abort("STUDENTIZED_SE_ALL_INVALID", "All replicate-specific standard errors are invalid for a statistic.", class="smf_bootstrap_error")
      tstar <- (z[keep] - theta) / se_j[keep]
      tq <- stats::quantile(tstar,c(1-alpha/2,alpha/2),names=FALSE,type=7)
      q <- c(theta - tq[1]*original_se[[j]], theta - tq[2]*original_se[[j]])
    } else .smf_abort("BOOTSTRAP_INTERVAL_UNKNOWN","Unknown bootstrap interval method.")
    out[[j]] <- setNames(as.numeric(q),c("lower","upper"))
  }
  do.call(rbind,out)
}

.smf_bootstrap_stability <- function(estimates, level=0.95) {
  est <- as.data.frame(estimates); B <- nrow(est); checkpoints <- unique(pmin(B,c(25L,50L,100L,200L,500L,1000L,B)))
  do.call(rbind,lapply(checkpoints,function(b) {
    do.call(rbind,lapply(names(est),function(nm) {
      z <- est[[nm]][seq_len(b)]; q <- stats::quantile(z,c((1-level)/2,1-(1-level)/2),na.rm=TRUE,names=FALSE)
      data.frame(B=b,statistic=nm,mean=mean(z,na.rm=TRUE),sd=stats::sd(z,na.rm=TRUE),lower=q[1],upper=q[2],width=q[2]-q[1],row.names=NULL)
    }))
  }))
}

#' Bootstrap a statistic with design-aware resampling
#' @export
smf_bootstrap <- function(data, spec, statistic, design=smf_design_spec(), override=FALSE) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data.frame.")
  if (!is.function(statistic)) cli::cli_abort("{.arg statistic} must be a function accepting one bootstrap data frame.")
  warnings <- smf_validate_bootstrap_design(data,spec,design,override)
  original <- .smf_bootstrap_stat(statistic,data); B <- as.integer(spec@n_resamples)
  if (B<2L) .smf_abort("BOOTSTRAP_B_TOO_SMALL","At least two bootstrap replicates are required.")
  estimates <- matrix(NA_real_,nrow=B,ncol=length(original),dimnames=list(NULL,names(original))); failures <- list()
  se_fun <- spec@parameters$standard_error
  replicate_se <- if (spec@interval=="studentized") matrix(NA_real_,nrow=B,ncol=length(original),dimnames=list(NULL,names(original))) else NULL
  if (spec@interval=="studentized" && !is.function(se_fun)) .smf_abort("STUDENTIZED_REQUIRES_SE", "Studentized bootstrap requires parameters$standard_error, a function returning standard errors.", class="smf_bootstrap_error")
  generator_method <- spec@method %in% c("residual","parametric","wild")
  for (b in seq_len(B)) {
    ans <- tryCatch(smf_with_seed(spec@seed+b-1L, {
      if (generator_method) {
        gen <- spec@parameters$generator
        if (!is.function(gen)) .smf_abort("BOOTSTRAP_GENERATOR_MISSING",paste0(spec@method," bootstrap requires parameters$generator(data, method, replicate)."),class="smf_bootstrap_error")
        db <- gen(data=data,method=spec@method,replicate=b)
      } else {
        ii <- .smf_bootstrap_rows(data,spec,design); db <- data[ii,,drop=FALSE]
      }
      est_b <- .smf_bootstrap_stat(statistic,db)
      se_b <- if (spec@interval=="studentized") .smf_bootstrap_se(se_fun,db,names(original)) else NULL
      list(estimate=est_b,se=se_b)
    }), error=function(e)e)
    if (inherits(ans,"error")) failures[[length(failures)+1L]] <- list(replicate=b,message=conditionMessage(ans),class=class(ans)[1]) else {
      estimates[b,] <- ans$estimate
      if (spec@interval=="studentized") replicate_se[b,] <- ans$se
    }
  }
  ok <- stats::complete.cases(estimates); if(spec@interval=="studentized") ok <- ok & stats::complete.cases(replicate_se)
  good <- estimates[ok,,drop=FALSE]; good_se <- if(spec@interval=="studentized") replicate_se[ok,,drop=FALSE] else NULL
  if (!nrow(good)) .smf_abort("BOOTSTRAP_ALL_FAILED","All bootstrap replicates failed.",evidence=list(failures=failures),class="smf_bootstrap_error")
  if (spec@interval=="bca" && spec@method != "case") {
    .smf_abort("BCA_SCHEME_UNSUPPORTED","The generic row-delete BCa implementation is available only for case bootstrap; other dependence-aware schemes require a scheme-specific jackknife and are blocked rather than approximated.",class="smf_bootstrap_error")
  }
  interval <- .smf_bootstrap_interval(good,original,spec@level,spec@interval,data=data,statistic=statistic,se_fun=se_fun,replicate_se=good_se)
  meta <- ResultMeta(run_id=.smf_new_run_id(),created_at=.smf_now(),package_version=.smf_version(),backend="bootstrap",backend_version=character(),data_hash=smf_data_hash(data),split_hash=character(),spec_hash=smf_hash(spec),seed=spec@seed,warnings=warnings,provenance=list(operation="bootstrap"))
  BootstrapResult(meta=meta,spec=spec,original=original,estimates=as.data.frame(good),successful=as.integer(nrow(good)),failed=as.integer(B-nrow(good)),failures=failures,interval=interval,sampling_unit=.smf_chr(spec@sampling_unit),stability=.smf_bootstrap_stability(good,spec@level))
}

#' Compute bootstrap intervals from a BootstrapResult
#' @export
smf_bootstrap_interval <- function(result) {
  if (!S7::S7_inherits(result,BootstrapResult)) cli::cli_abort("{.arg result} must be a BootstrapResult.")
  result@interval
}

#' Return bootstrap stability diagnostics versus replicate count
#' @export
smf_bootstrap_stability <- function(result) {
  if (!S7::S7_inherits(result,BootstrapResult)) cli::cli_abort("{.arg result} must be a BootstrapResult.")
  result@stability
}
