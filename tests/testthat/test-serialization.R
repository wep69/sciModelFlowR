test_that("core specs round-trip through JSON", {
  x <- smf_experiment_spec(
    smf_task_spec("regression","y"),
    smf_data_spec("y",c("x"),id_column="id"),
    smf_design_spec(id_column="id"),
    smf_preprocess_spec("median",TRUE,TRUE),
    smf_resampling_spec("holdout",.8,seed=91L),
    smf_model_spec("linear_regression","stats"),
    list(smf_metric_spec("rmse")),
    reproducibility=smf_reproducibility_spec(91L)
  )
  y <- smf_from_json(smf_to_json(x))
  expect_true(S7::S7_inherits(y, sciModelFlowR:::ExperimentSpec))
  expect_identical(smf_hash(x),smf_hash(y))
})

test_that("hash changes when scientific specification changes", {
  a <- smf_task_spec("regression","y")
  b <- smf_task_spec("regression","z")
  expect_false(identical(smf_hash(a),smf_hash(b)))
})


test_that("portable schemas use unqualified stable class names", {
  x <- smf_task_spec("regression", "y")
  z <- jsonlite::fromJSON(smf_to_json(x), simplifyVector = TRUE, simplifyDataFrame = FALSE)
  expect_identical(z$`__class__`, "TaskSpec")
})


test_that("run metadata generation does not consume the global RNG stream", {
  set.seed(31415)
  before <- .Random.seed
  sciModelFlowR::smf_audit_data(data.frame(id=1:4, x=1:4, y=2:5), sciModelFlowR::smf_data_spec("y", "x", "id"))
  expect_identical(.Random.seed, before)
})
