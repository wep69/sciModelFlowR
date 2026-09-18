test_that("Platt calibration never requires final test labels", {
  d <- smf_load_dataset("gold_binary_calibration")
  d$event <- factor(ifelse(d$event %in% c(1,"1",TRUE,"yes"),"yes","no"),levels=c("no","yes"))
  spec <- smf_experiment_spec(
    task=smf_task_spec("binary","event",positive_label="yes"),
    data=smf_data_spec("event",c("x1","x2"),id_column="obs_id"),
    design=smf_design_spec(id_column="obs_id"),
    preprocessing=smf_preprocess_spec("median",TRUE,TRUE),
    resampling=smf_resampling_spec("stratified_holdout",train_prop=.75,strata="event",seed=41L),
    model=smf_model_spec("logistic_regression","stats"),
    metrics=list(smf_metric_spec("log_loss"),smf_metric_spec("brier")),
    calibration=smf_calibration_spec("platt",calibration_prop=.2),
    imbalance=smf_imbalance_spec("none"),
    reproducibility=smf_reproducibility_spec(41L)
  )
  fit <- smf_fit_experiment(spec,d)
  expect_true(S7::S7_inherits(fit@prediction@calibration,sciModelFlowR:::CalibrationResult))
  expect_true(all(abs(rowSums(fit@prediction@probabilities)-1)<1e-8))
  cm <- fit@fit@training_summary$calibration_split
  expect_length(intersect(cm$test_ids, fit@split@test_ids),0L)
})

test_that("isotonic multiclass calibration renormalizes probabilities", {
  y <- factor(c("a","a","b","b","c","c"))
  p <- rbind(c(.7,.2,.1),c(.6,.3,.1),c(.3,.6,.1),c(.2,.7,.1),c(.3,.2,.5),c(.2,.2,.6)); colnames(p)<-levels(y)
  cal <- smf_calibrate(y,p,smf_calibration_spec("isotonic"))
  out <- smf_apply_calibration(cal,p)
  expect_true(all(abs(rowSums(out)-1)<1e-8))
})

test_that("external calibration cannot overlap final test IDs", {
  set.seed(42)
  d <- smf_load_dataset("gold_binary_calibration")
  d$event <- factor(d$event, levels = c(0, 1))
  spec <- smf_experiment_spec(
    task = smf_task_spec("binary", "event", positive_label = "1"),
    data = smf_data_spec("event", c("x1", "x2"), id_column = "obs_id"),
    design = smf_design_spec(id_column = "obs_id"),
    preprocessing = smf_preprocess_spec("median", TRUE, TRUE),
    resampling = smf_resampling_spec("stratified_holdout", train_prop = .8, strata = "event", seed = 42L),
    model = smf_model_spec("logistic_regression", "stats"),
    metrics = list(smf_metric_spec("log_loss")),
    calibration = smf_calibration_spec("platt", source = "external_predictions"),
    reproducibility = smf_reproducibility_spec(42L)
  )
  split <- smf_holdout_split(d, .8, "event", "obs_id", 42L)
  leaked <- d[split@test_index[seq_len(min(5L, length(split@test_index)))], , drop = FALSE]
  expect_error(smf_fit_experiment(spec, d, split = split, calibration_data = leaked), class = "smf_leakage_error")
})
