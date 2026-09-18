test_that("benchmark specification never implies a universal winner by default", {
  b <- smf_benchmark_spec(
    candidates=list(a=smf_model_spec("lm","stats"),b=smf_model_spec("lm","stats",parameters=list(dummy=1))),
    metrics=list(smf_metric_spec("rmse","minimize")),
    decision_rule=NULL
  )
  expect_null(b@decision_rule)
})

test_that("benchmark decision can be changed explicitly after evaluation", {
  # Build a small structural result without running a model backend.
  b <- smf_benchmark_spec(candidates=list(a=smf_model_spec("lm","stats"),b=smf_model_spec("lm","stats")),metrics=list(smf_metric_spec("rmse","minimize")))
  rs <- ResampleCollection(method="kfold",splits=list(),seed=1L,source_spec=NULL,design=NULL,manifest_hash="h",diagnostics=list(),nested=list())
  sm <- data.frame(candidate=c("a","b"),metric=c("rmse","rmse"),mean=c(1,2),sd=c(.1,.2),se=c(.1,.2),lower=c(.8,1.6),upper=c(1.2,2.4),n=c(3,3))
  base <- smf_experiment_spec(smf_task_spec("regression","y"),smf_data_spec("y","x"),model=smf_model_spec("lm","stats"))
  br <- BenchmarkResult(spec=base,benchmark_spec=b,resamples=rs,performance=data.frame(),summary=sm,uncertainty=data.frame(),compute=data.frame(),stability=data.frame(),pareto=data.frame(),decision=NULL,warnings=list(),provenance=list())
  dec <- smf_decide_benchmark(br,list(type="weighted_sum",weights=c(rmse=1)))
  expect_equal(dec$candidate[[1]],"a")
})
