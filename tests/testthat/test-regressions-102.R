# Regression tests for the fixes published in 1.0.2 (audit of 1.0.1).
# Each block corresponds to one item of RELATORIO-AO-AUTOR.md.

test_that("portable bundle predicts with every preprocessing configuration", {
  d <- smf_load_dataset("gold_linear_regression")
  for (imp in c("none", "mean", "median")) for (ctr in c(FALSE, TRUE)) for (scl in c(FALSE, TRUE)) {
    spec <- smf_experiment_spec(
      task = smf_task_spec("regression", "yield"),
      data = smf_data_spec("yield", c("nitrogen", "rainfall", "soil_n"), "obs_id"),
      design = smf_design_spec(id_column = "obs_id"),
      preprocessing = smf_preprocess_spec(imp, center = ctr, scale = scl),
      resampling = smf_resampling_spec("holdout", train_prop = 0.8, seed = 1L),
      model = smf_model_spec("linear_regression", "stats"),
      metrics = list(smf_metric_spec("rmse"))
    )
    fit <- smf_fit_experiment(spec, d)
    path <- tempfile("bundle-"); smf_save_bundle(fit, path, mode = "portable")
    b <- smf_load_bundle(path)
    expect_equal(as.numeric(smf_predict_bundle(b, d[1:7, ])),
                 as.numeric(smf_predict(fit, d[1:7, ])), tolerance = 1e-12)
  }
})

test_that("JSON encodes missing numeric values as null, not as text", {
  txt <- as.character(smf_to_json(NA_real_, pretty = FALSE))
  expect_false(grepl("\"NA\"", txt, fixed = TRUE))
  expect_match(txt, "null", fixed = TRUE)
})

test_that("tuning objective must be declared in spec@metrics", {
  d <- smf_load_dataset("gold_linear_regression")
  spec <- smf_experiment_spec(
    task = smf_task_spec("regression", "yield"),
    data = smf_data_spec("yield", c("nitrogen", "rainfall", "soil_n"), "obs_id"),
    design = smf_design_spec(id_column = "obs_id"),
    model = smf_model_spec("linear_regression", "stats"),
    metrics = list(smf_metric_spec("rmse", "minimize"))
  )
  space <- smf_search_space(nrounds = smf_param_int(30L, 90L))
  expect_error(
    smf_tune(spec, d, space,
             smf_tuning_spec("random", budget = 2L,
                             inner_resampling = smf_resampling_spec("kfold", n_splits = 2L, seed = 1L),
                             objectives = list(smf_metric_spec("mae", "minimize")),
                             seed = 1L)),
    class = "smf_tuning_error")
})

test_that("PDP and ICE keep numeric value type for numeric predictors", {
  d <- smf_load_dataset("gold_xai_stability")
  spec <- smf_experiment_spec(
    task = smf_task_spec("regression", "response"),
    data = smf_data_spec("response", c("signal_primary", "signal_correlated", "weak_feature"), "obs_id"),
    design = smf_design_spec(id_column = "obs_id"),
    model = smf_model_spec("linear_regression", "stats"),
    metrics = list(smf_metric_spec("rmse"))
  )
  fit <- smf_fit_experiment(spec, d)
  pdp <- smf_pdp(fit, d, features = "signal_primary", grid_size = 5L)
  ice <- smf_ice(fit, d, features = "signal_primary", grid_size = 5L, n = 3L)
  expect_type(pdp$value, "double")
  expect_type(ice$value, "double")
  expect_identical(order(pdp$value), order(as.numeric(pdp$value)))
})

test_that("point representation refuses intervals like it refuses cdf", {
  d <- smf_load_dataset("gold_linear_regression")
  spec <- smf_experiment_spec(
    task = smf_task_spec("regression", "yield"),
    data = smf_data_spec("yield", c("nitrogen", "rainfall", "soil_n"), "obs_id"),
    design = smf_design_spec(id_column = "obs_id"),
    model = smf_model_spec("linear_regression", "stats"),
    metrics = list(smf_metric_spec("rmse"))
  )
  pd <- smf_predict_distribution(smf_fit_experiment(spec, d), d[1:3, ])
  expect_identical(pd@representation, "point")
  expect_error(smf_dist_interval(pd, 0.90), class = "smf_capability_error")
})

test_that("unknown engine message lists accepted engines", {
  err <- tryCatch(smf_backend_capabilities("ranger"), error = function(e) conditionMessage(e))
  expect_match(err, "stats")
  expect_match(err, "tidymodels")
  expect_match(err, "smf_available_model_adapters")
})
