test_that("core specifications construct valid objects", {
  task <- smf_task_spec("regression", "yield")
  data <- smf_data_spec("yield", c("x1","x2"), id_column="id")
  design <- smf_design_spec(id_column="id", group_columns="field")
  prep <- smf_preprocess_spec("median", center=TRUE, scale=TRUE)
  res <- smf_resampling_spec("holdout", train_prop=.8, seed=11L)
  model <- smf_model_spec("linear_regression","stats")
  metric <- smf_metric_spec("rmse")
  exp <- smf_experiment_spec(task,data,design,prep,res,model,list(metric))
  expect_true(S7::S7_inherits(task, sciModelFlowR:::TaskSpec))
  expect_true(S7::S7_inherits(exp, sciModelFlowR:::ExperimentSpec))
  expect_equal(task@target,"yield")
})

test_that("invalid task and preprocessing specifications fail", {
  expect_error(smf_task_spec("unknown","y"))
  expect_error(smf_preprocess_spec("bad"))
  expect_error(smf_resampling_spec("holdout",train_prop=1))
})
