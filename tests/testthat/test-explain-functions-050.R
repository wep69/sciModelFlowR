test_that("permutation importance, PDP, ICE and ALE return scientific tables", {
  d <- smf_load_dataset("gold_linear_regression")
  sp <- smf_experiment_spec(
    task=smf_task_spec("regression","yield"),
    data=smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),"obs_id"),
    design=smf_design_spec(id_column="obs_id"),
    preprocessing=smf_preprocess_spec(),
    resampling=smf_resampling_spec("holdout",train_prop=.8,seed=101L),
    model=smf_model_spec("linear","stats"),
    metrics=list(smf_metric_spec("rmse")))
  fit <- smf_fit_experiment(sp,d)
  test <- d[fit@split@test_index,,drop=FALSE]
  imp <- smf_permutation_importance(fit,test,n_repeats=3L,seed=9L)
  expect_true(all(c("feature","importance","sd") %in% names(imp)))
  expect_true(nrow(smf_pdp(fit,test,"nitrogen",5L)) >= 2L)
  expect_true(nrow(smf_ice(fit,test,"nitrogen",5L,5L)) >= 5L)
  expect_true(nrow(smf_ale(fit,test,"nitrogen",5L)) >= 2L)
})

test_that("local explanations retain sign semantics", {
  d <- smf_load_dataset("gold_linear_regression")
  sp <- smf_experiment_spec(task=smf_task_spec("regression","yield"),data=smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),"obs_id"),model=smf_model_spec("linear","stats"))
  fit <- smf_fit_experiment(sp,d)
  loc <- smf_local_explain(fit,d[1,,drop=FALSE],d,c("nitrogen","rainfall"))
  expect_equal(loc$contribution, loc$prediction-loc$reference_prediction)
})
