.make_080_linear <- function() {
  d <- smf_load_dataset("gold_linear_regression")
  spec <- smf_experiment_spec(
    task=smf_task_spec("regression","yield"),
    data=smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),id_column="obs_id"),
    design=smf_design_spec(id_column="obs_id"),
    preprocessing=smf_preprocess_spec("median",center=TRUE,scale=TRUE),
    resampling=smf_resampling_spec("holdout",train_prop=.8,seed=260915L),
    model=smf_model_spec("linear_regression","stats"), metrics=list(smf_metric_spec("rmse"))
  )
  list(data=d,result=smf_fit_experiment(spec,d))
}

test_that("portable bundle round-trip reproduces predictions", {
  z <- .make_080_linear(); path <- tempfile("bundle-")
  smf_save_bundle(z$result,path,mode="portable")
  val <- smf_validate_bundle(path); expect_true(val@valid); expect_length(val@unsafe_components,0L)
  b <- smf_load_bundle(path)
  nd <- z$data[1:7,,drop=FALSE]
  expect_equal(as.numeric(smf_predict_bundle(b,nd)),as.numeric(smf_predict(z$result,nd)),tolerance=1e-12)
})

test_that("checksum corruption is rejected before loading", {
  z <- .make_080_linear(); path <- tempfile("bundle-"); smf_save_bundle(z$result,path,mode="portable")
  cat("corrupt",file=file.path(path,"schema.json"),append=TRUE)
  expect_error(smf_validate_bundle(path),class="smf_persistence_error")
})

test_that("opaque bundles require explicit trust", {
  z <- .make_080_linear(); path <- tempfile("bundle-"); smf_save_bundle(z$result,path,mode="opaque")
  expect_error(smf_load_bundle(path),class="smf_security_error")
  expect_true(S7::S7_inherits(smf_load_bundle(path,trusted=TRUE),sciModelFlowR:::InferenceBundle))
})

test_that("opaque calibrated classification bundle replays calibration after trusted load", {
  d <- smf_load_dataset("gold_binary_calibration")
  d$event <- factor(ifelse(d$event %in% c(1,"1",TRUE,"yes"),"yes","no"), levels=c("no","yes"))
  spec <- smf_experiment_spec(
    task=smf_task_spec("binary","event",positive_label="yes"),
    data=smf_data_spec("event",c("x1","x2"),id_column="obs_id"),
    design=smf_design_spec(id_column="obs_id"),
    preprocessing=smf_preprocess_spec("median",center=TRUE,scale=TRUE),
    resampling=smf_resampling_spec("stratified_holdout",train_prop=.75,strata="event",seed=260915L),
    model=smf_model_spec("logistic_regression","stats"),
    metrics=list(smf_metric_spec("log_loss")),
    calibration=smf_calibration_spec("platt",calibration_prop=.2),
    imbalance=smf_imbalance_spec("none"),
    reproducibility=smf_reproducibility_spec(260915L)
  )
  fit <- smf_fit_experiment(spec,d)
  path <- tempfile("bundle-"); smf_save_bundle(fit,path,mode="opaque")
  b <- smf_load_bundle(path,trusted=TRUE)
  nd <- d[1:11,,drop=FALSE]
  expect_true(S7::S7_inherits(b@calibration,sciModelFlowR:::CalibrationResult))
  expect_equal(smf_predict_bundle(b,nd,type="prob"),smf_predict(fit,nd),tolerance=1e-12)
})
