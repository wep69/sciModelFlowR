.make_040_reference <- function() {
  d <- smf_load_dataset("gold_linear_regression")
  task <- smf_task_spec("regression","yield")
  ds <- smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),id_column="obs_id")
  design <- smf_design_spec(id_column="obs_id")
  rs <- smf_resampling_spec("kfold",n_splits=2,seed=440)
  spec <- smf_experiment_spec(task,ds,design=design,resampling=rs,model=smf_model_spec("lm","stats"),metrics=list(smf_metric_spec("rmse","minimize")))
  list(d=d,spec=spec,rs=rs)
}

test_that("racing and Bayesian optimization create inspectable archives", {
  x <- .make_040_reference()
  sp <- smf_search_space(dummy=smf_param_dbl(0,1))
  race <- smf_tune(x$spec,x$d,sp,smf_tuning_spec("racing",budget=3,inner_resampling=x$rs,objectives=list(smf_metric_spec("rmse","minimize")),seed=441,parameters=list(min_folds=2)))
  expect_true(nrow(race@archive)>=1)
  bo <- smf_tune(x$spec,x$d,sp,smf_tuning_spec("bayesian",budget=6,inner_resampling=x$rs,objectives=list(smf_metric_spec("rmse","minimize")),seed=442,parameters=list(initial=3,candidate_pool=32)))
  expect_true(nrow(bo@archive)>=3)
})

test_that("successive halving and Hyperband use an explicit resource parameter", {
  x <- .make_040_reference()
  sp <- smf_search_space(dummy_resource=smf_param_int(values=c(1L,2L,4L),resource=TRUE),dummy=smf_param_dbl(values=c(0,1)))
  sh <- smf_tune(x$spec,x$d,sp,smf_tuning_spec("successive_halving",budget=3,inner_resampling=x$rs,objectives=list(smf_metric_spec("rmse","minimize")),seed=443,parameters=list(resource_param="dummy_resource",min_resource=1,max_resource=4,eta=2)))
  expect_true(all(c("stage","resource_value") %in% names(sh@archive)))
  hb <- smf_tune(x$spec,x$d,sp,smf_tuning_spec("hyperband",budget=3,inner_resampling=x$rs,objectives=list(smf_metric_spec("rmse","minimize")),seed=444,parameters=list(resource_param="dummy_resource",min_resource=1,max_resource=4,eta=2)))
  expect_true("bracket" %in% names(hb@archive))
})
