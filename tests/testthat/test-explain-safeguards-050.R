test_that("correlated feature warnings are explicit and XAI is non-causal", {
  d <- smf_load_dataset("gold_xai_stability")
  sp <- smf_experiment_spec(task=smf_task_spec("regression","response"),data=smf_data_spec("response",c("signal_primary","signal_correlated","weak_feature"),"obs_id"),design=smf_design_spec(id_column="obs_id"),model=smf_model_spec("linear","stats"))
  fit <- smf_fit_experiment(sp,d)
  z <- smf_explain(fit,d,smf_explain_spec("permutation",n_repeats=3L))
  expect_false(z@causal_interpretation)
  expect_true(any(vapply(z@warnings,function(w)w@code=="CORRELATED_FEATURE_EXPLANATION",logical(1))))
})

test_that("feature tracing maps dummy variables to their source", {
  d <- data.frame(id=1:12,g=factor(rep(c("A","B","C"),4)),x=1:12,y=2*(1:12))
  sp <- smf_experiment_spec(task=smf_task_spec("regression","y"),data=smf_data_spec("y",c("g","x"),"id"),design=smf_design_spec(id_column="id"),model=smf_model_spec("linear","stats"))
  fit <- smf_fit_experiment(sp,d)
  mp <- smf_trace_features(fit)
  expect_true(any(mp$source=="g" & grepl("g__",mp$transformed)))
})
