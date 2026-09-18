test_that("conformal spec is part of ExperimentSpec", {
  cf <- smf_conformal_spec("split",level=.9)
  ex <- smf_experiment_spec(smf_task_spec("regression","y"),smf_data_spec("y","x"),model=smf_model_spec("linear_regression","stats"),conformal=cf)
  expect_true(S7::S7_inherits(ex@conformal,sciModelFlowR:::ConformalSpec))
  rt <- smf_from_json(smf_to_json(ex))
  expect_equal(rt@conformal@method,"split")
})
