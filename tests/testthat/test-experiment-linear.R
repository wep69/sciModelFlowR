test_that("linear reference workflow is end-to-end", {
  d <- smf_load_dataset("gold_linear_regression")
  spec <- smf_experiment_spec(
    task=smf_task_spec("regression","yield"),
    data=smf_data_spec("yield",c("nitrogen","rainfall","soil_n"),id_column="obs_id"),
    design=smf_design_spec(id_column="obs_id"),
    preprocessing=smf_preprocess_spec("median",center=TRUE,scale=TRUE),
    resampling=smf_resampling_spec("holdout",train_prop=.8,seed=260915L),
    model=smf_model_spec("linear_regression","stats"),
    metrics=list(smf_metric_spec("rmse"),smf_metric_spec("mae")),
    reproducibility=smf_reproducibility_spec(260915L)
  )
  r <- smf_fit_experiment(spec,d)
  expect_true(S7::S7_inherits(r, sciModelFlowR:::ExperimentResult))
  expect_equal(nrow(r@metrics),2)
  expect_true(all(is.finite(r@prediction@estimate)))
  expect_equal(r@manifest@split_hash,r@split@hash)
  direct <- stats::predict(smf_backend_object(r),newdata=smf_apply_preprocessor(r@fit@preprocessing,d[r@split@test_index,,drop=FALSE]))
  expect_equal(r@prediction@estimate,as.numeric(direct),tolerance=1e-10)
})

test_that("blocking leakage stops a managed experiment", {
  d <- data.frame(id=1:30,x=rnorm(30),y=rnorm(30)); d$copy <- d$y
  spec <- smf_experiment_spec(smf_task_spec("regression","y"),smf_data_spec("y",c("x","copy"),id_column="id"),smf_design_spec(id_column="id"),smf_preprocess_spec(),smf_resampling_spec("holdout"),smf_model_spec("linear_regression","stats"))
  expect_error(smf_fit_experiment(spec,d),class="smf_leakage_error")
})


test_that("holdout experiment retains feature state for new-data prediction", {
  d <- smf_load_dataset("gold_linear_regression")
  target <- if("y" %in% names(d)) "y" else names(d)[vapply(d,is.numeric,logical(1))][1]
  id <- if("id" %in% names(d)) "id" else names(d)[1]
  preds <- setdiff(names(d),c(target,id)); preds <- preds[vapply(d[preds],is.numeric,logical(1))]
  if(length(preds) < 2L) skip("Gold fixture has fewer than two numeric predictors")
  spec <- smf_experiment_spec(
    task=smf_task_spec("regression",target),
    data=smf_data_spec(target,preds,id_column=id),
    design=smf_design_spec(id_column=id),
    preprocessing=smf_preprocess_spec("median",TRUE,TRUE),
    resampling=smf_resampling_spec("holdout",train_prop=.75,seed=4L),
    model=smf_model_spec("linear_regression","stats"),
    metrics=list(smf_metric_spec("rmse")),
    features=smf_feature_spec("pca",n_features=min(2L,length(preds)))
  )
  out <- smf_fit_experiment(spec,d)
  expect_true(S7::S7_inherits(out@fit@features,sciModelFlowR:::RepresentationResult))
  p <- smf_predict(out,d[1:3,,drop=FALSE])
  expect_equal(length(p),3L)
})
