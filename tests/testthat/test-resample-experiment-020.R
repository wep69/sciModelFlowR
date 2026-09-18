test_that("grouped resample experiment fits preprocessing and selection inside folds", {
  d <- smf_load_dataset("gold_grouped_fields")
  target <- if("yield" %in% names(d)) "yield" else names(d)[vapply(d,is.numeric,logical(1))][1]
  id <- if("obs_id" %in% names(d)) "obs_id" else names(d)[1]
  group <- if("field" %in% names(d)) "field" else names(d)[2]
  preds <- setdiff(names(d),c(target,id,group)); preds <- preds[vapply(d[preds],function(z)is.numeric(z)||is.factor(z)||is.character(z),logical(1))]
  spec <- smf_experiment_spec(
    task=smf_task_spec("regression",target),
    data=smf_data_spec(target,preds,id_column=id),
    design=smf_design_spec(id_column=id,group_columns=group),
    preprocessing=smf_preprocess_spec("median",TRUE,TRUE),
    resampling=smf_resampling_spec("group",n_splits=3,parameters=list(groups=group)),
    model=smf_model_spec("linear_regression","stats"),
    metrics=list(smf_metric_spec("rmse")),
    features=smf_feature_spec("nzv")
  )
  r <- smf_resample_experiment(spec,d)
  expect_true(S7::S7_inherits(r,sciModelFlowR:::ResampleResult))
  expect_equal(nrow(r@aggregate),1L)
  expect_equal(length(r@fold_results),length(r@resamples@splits))
  for(fr in r@fold_results) expect_true(!is.null(fr$feature_result))
})


test_that("PCA representation is learned and applied independently inside folds", {
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
    resampling=smf_resampling_spec("kfold",n_splits=3),
    model=smf_model_spec("linear_regression","stats"),
    metrics=list(smf_metric_spec("rmse")),
    features=smf_feature_spec("pca",n_features=min(2L,length(preds)))
  )
  r <- smf_resample_experiment(spec,d)
  expect_equal(length(r@fold_results),3L)
  expect_true(all(vapply(r@fold_results,function(z) S7::S7_inherits(z$feature_result,sciModelFlowR:::RepresentationResult),logical(1))))
})
