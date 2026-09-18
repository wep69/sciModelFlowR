# Scientific benchmarking with explicit decision rules (0.4.0).

#' Create a scientific benchmark specification
#' @export
smf_benchmark_spec <- function(candidates, metrics=list(), resampling=NULL, decision_rule=NULL,
                               compute_measures=c("fit_time","predict_time","total_time"), repetitions=1L,
                               seed=260915L, parameters=list()) {
  if (is.null(names(candidates)) || any(!nzchar(names(candidates)))) names(candidates) <- paste0("candidate_",seq_along(candidates))
  BenchmarkSpec(candidates=candidates,metrics=metrics,resampling=resampling,decision_rule=decision_rule,
    compute_measures=.smf_chr(compute_measures),repetitions=as.integer(repetitions),seed=as.integer(seed),parameters=parameters)
}

.smf_benchmark_metrics <- function(bspec,spec) {
  z<-bspec@metrics; if(!length(z)) z<-spec@metrics; if(!is.list(z))z<-list(z)
  if(!length(z)) .smf_abort("BENCHMARK_METRICS_MISSING","Scientific benchmarking requires explicit metrics.",class="smf_benchmark_error")
  z
}

.smf_replace_model <- function(spec,model,metrics=NULL) {
  ExperimentSpec(task=spec@task,data=spec@data,design=spec@design,preprocessing=spec@preprocessing,resampling=spec@resampling,
    model=model,metrics=metrics %||% spec@metrics,features=spec@features,bootstrap=spec@bootstrap,probabilistic=spec@probabilistic,
    calibration=spec@calibration,imbalance=spec@imbalance,tuning=spec@tuning,benchmark=spec@benchmark,explain=spec@explain,reporting=spec@reporting,
    bayesian=spec@bayesian,deep_learning=spec@deep_learning,uncertainty=spec@uncertainty,reproducibility=spec@reproducibility)
}

.smf_benchmark_summary <- function(perf, metrics) {
  rows<-list();k<-0L
  for(cand in unique(perf$candidate)) for(m in unique(perf$metric)) {
    z<-perf$value[perf$candidate==cand & perf$metric==m]; if(!length(z))next;k<-k+1L
    n<-sum(is.finite(z)); meanz<-mean(z,na.rm=TRUE); sdz<-stats::sd(z,na.rm=TRUE); se<-if(n>1)sdz/sqrt(n)else NA_real_; crit<-if(n>1)stats::qt(.975,n-1)else NA_real_
    rows[[k]]<-data.frame(candidate=cand,metric=m,mean=meanz,sd=sdz,se=se,lower=meanz-crit*se,upper=meanz+crit*se,n=n,stringsAsFactors=FALSE)
  }
  do.call(rbind,rows)
}

.smf_benchmark_rank_stability <- function(perf, metrics) {
  dirs<-.smf_objective_directions(metrics); rows<-list();k<-0L
  keys<-unique(perf[c("split_id","metric")])
  for(j in seq_len(nrow(keys))) {
    sid<-keys$split_id[[j]]; m<-keys$metric[[j]]; z<-perf[perf$split_id==sid & perf$metric==m,,drop=FALSE]
    if(!nrow(z))next; z$rank<-rank(if(dirs[[m]]=="maximize")-z$value else z$value,ties.method="average",na.last="keep")
    rows[[length(rows)+1L]]<-z[c("candidate","split_id","metric","rank")]
  }
  rr<-do.call(rbind,rows); if(is.null(rr)||!nrow(rr))return(data.frame())
  out<-do.call(rbind,lapply(split(rr,interaction(rr$candidate,rr$metric,drop=TRUE)),function(z)data.frame(candidate=z$candidate[[1]],metric=z$metric[[1]],mean_rank=mean(z$rank,na.rm=TRUE),sd_rank=stats::sd(z$rank,na.rm=TRUE),n=nrow(z),stringsAsFactors=FALSE)))
  rownames(out)<-NULL;out
}

.smf_benchmark_wide <- function(summary) {
  if(!nrow(summary))return(data.frame())
  out <- reshape(summary[c("candidate","metric","mean")], idvar="candidate", timevar="metric", direction="wide", v.names="mean")
  names(out) <- sub("^mean\\.", "", names(out))
  out
}

#' Recompute an explicit scientific benchmark decision rule
#' @export
smf_decide_benchmark <- function(result, decision_rule) {
  if(!S7::S7_inherits(result,BenchmarkResult)) .smf_abort("BENCHMARK_RESULT_REQUIRED","result must be a BenchmarkResult.",class="smf_benchmark_error")
  metrics<-.smf_benchmark_metrics(result@benchmark_spec,result@spec); dirs<-.smf_objective_directions(metrics); obj<-names(dirs)
  wide<-.smf_benchmark_wide(result@summary); if(!nrow(wide))return(NULL)
  smf_select_compromise(wide,obj,dirs,decision_rule)
}

#' Benchmark multiple candidate models on identical design-aware resamples
#' @export
smf_benchmark <- function(spec, data, benchmark, resamples=NULL, override=FALSE) {
  .smf_tuning_guard(data); metrics<-.smf_benchmark_metrics(benchmark,spec)
  if(is.null(resamples)) {
    rspec<-benchmark@resampling %||% spec@resampling
    if(is.null(rspec)||rspec@method=="external") .smf_abort("BENCHMARK_RESAMPLING_INVALID","Benchmarking requires non-final-test development resampling.",class="smf_leakage_error")
    resamples<-smf_make_resampler(data,rspec,spec@design,spec@task,override)
  }
  if (!S7::S7_inherits(resamples, ResampleCollection)) .smf_abort("BENCHMARK_RESAMPLES_INVALID", "resamples must be a ResampleCollection.", class="smf_benchmark_error")
  if (identical(resamples@method, "external")) .smf_abort("EXTERNAL_TEST_IN_BENCHMARK", "Scientific model-development benchmarks cannot consume final external validation folds.", class="smf_leakage_error")
  perf<-list(); comp<-list(); idx<-0L
  for(rep in seq_len(benchmark@repetitions)) for(nm in names(benchmark@candidates)) {
    model<-benchmark@candidates[[nm]]; if(!.smf_is_s7(model)||S7::S7_class(model)@name!="ModelSpec") .smf_abort("BENCHMARK_CANDIDATE_INVALID",paste0("Candidate ",nm," is not a ModelSpec."),class="smf_benchmark_error")
    sp<-.smf_replace_model(spec,model,metrics); started<-proc.time()[[3]]; rr<-smf_resample_experiment(sp,data,resamples,override); total<-proc.time()[[3]]-started
    z<-rr@metrics; z$candidate<-nm; z$repetition<-rep; idx<-idx+1L; perf[[idx]]<-z
    comp[[idx]]<-data.frame(candidate=nm,repetition=rep,total_time=as.numeric(total),n_folds=length(resamples@splits),stringsAsFactors=FALSE)
  }
  perf<-do.call(rbind,perf); summary<-.smf_benchmark_summary(perf,metrics); uncertainty<-summary[c("candidate","metric","se","lower","upper","n")]
  compute<-do.call(rbind,comp); stability<-.smf_benchmark_rank_stability(perf,metrics); dirs<-.smf_objective_directions(metrics); obj<-names(dirs); wide<-.smf_benchmark_wide(summary)
  pareto<-if(length(obj)>1L&&nrow(wide))smf_pareto_front(wide,obj,dirs)else wide
  decision<-if(is.null(benchmark@decision_rule))NULL else smf_select_compromise(if(length(obj)>1L)pareto else wide,obj,dirs,benchmark@decision_rule)
  BenchmarkResult(spec=spec,benchmark_spec=benchmark,resamples=resamples,performance=perf,summary=summary,uncertainty=uncertainty,compute=compute,stability=stability,pareto=pareto,decision=decision,warnings=list(),
    provenance=list(shared_resampling_hash=resamples@manifest_hash,no_universal_winner=is.null(benchmark@decision_rule),decision_rule=benchmark@decision_rule,final_test_used=FALSE))
}
