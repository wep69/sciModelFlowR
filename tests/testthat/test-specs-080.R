test_that("0.8 specifications validate", {
  tr <- smf_tracking_spec("local", tempdir(), "science")
  ps <- smf_persistence_spec()
  ds <- smf_deployment_spec("local", batch_size=128L)
  ss <- smf_scalability_spec(256L, workers=1L)
  expect_true(S7::S7_inherits(tr, sciModelFlowR:::TrackingSpec))
  expect_true(S7::S7_inherits(ps, sciModelFlowR:::PersistenceSpec))
  expect_true(S7::S7_inherits(ds, sciModelFlowR:::DeploymentSpec))
  expect_true(S7::S7_inherits(ss, sciModelFlowR:::ScalabilitySpec))
})

test_that("ExperimentSpec carries optional operations layer", {
  spec <- smf_experiment_spec(
    smf_task_spec("regression","y"), smf_data_spec("y","x"),
    model=smf_model_spec("linear_regression","stats"),
    tracking=smf_tracking_spec("none"), persistence=smf_persistence_spec(),
    deployment=smf_deployment_spec(), scalability=smf_scalability_spec()
  )
  expect_equal(spec@tracking@provider,"none")
  rt <- smf_from_json(smf_to_json(spec))
  expect_equal(rt@persistence@schema_version,"1.0.0")
})
