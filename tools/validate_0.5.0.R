# sciModelFlowR 0.5.0 runtime validation entry point.
# Intended for consolidated final local validation; not executed during source-only development.
suppressPackageStartupMessages(library(sciModelFlowR))
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "0.5.0")
cat("sciModelFlowR 0.5.0 runtime validation\n", R.version.string, "\n", R.version$platform, "\n\n")

# 1. Gold fixture and correlated-feature contract.
d <- smf_load_dataset("gold_xai_stability")
stopifnot(abs(cor(d$signal_primary, d$signal_correlated)) > .95)

# 2. Fit a transparent reference model.
sp <- smf_experiment_spec(
  task=smf_task_spec("regression","response"),
  data=smf_data_spec("response",c("signal_primary","signal_correlated","weak_feature"),"obs_id"),
  design=smf_design_spec(id_column="obs_id"),
  resampling=smf_resampling_spec("holdout",train_prop=.8,seed=51L),
  model=smf_model_spec("linear","stats"),
  metrics=list(smf_metric_spec("rmse")),
  explain=smf_explain_spec(c("permutation","pdp","ale"),n_repeats=10L,grid_size=10L,seed=52L)
)
fit <- smf_fit_experiment(sp,d)
te <- d[fit@split@test_index,,drop=FALSE]

# 3. Core XAI outputs and non-causal flag.
ex <- smf_explain(fit,te,sp@explain)
stopifnot(S7::S7_inherits(ex, ExplainResult), identical(ex@causal_interpretation,FALSE))
stopifnot(all(c("permutation","pdp","ale") %in% names(ex@values)))
stopifnot(any(vapply(ex@warnings,function(w) w@code=="CORRELATED_FEATURE_EXPLANATION",logical(1))))

# 4. Feature tracing and sign/direction semantics.
mp <- smf_trace_features(fit)
stopifnot(all(c("transformed","source","weight","type") %in% names(mp)))
imp <- ex@values$permutation
stopifnot(all(c("importance","baseline","permuted_mean","direction") %in% names(imp)))
stopifnot(all(imp$importance == imp$permuted_mean - imp$baseline))

# 5. Local explanation identity.
loc <- smf_local_explain(fit,te[1,,drop=FALSE],d,c("signal_primary","weak_feature"))
stopifnot(isTRUE(all.equal(loc$contribution,loc$prediction-loc$reference_prediction)))

# 6. Domain diagnostics.
dom <- smf_explanation_domain(d[fit@split@train_index,,drop=FALSE],te)
stopifnot(all(c("feature","outside_fraction","novel_levels") %in% names(dom)))

# 7. Explanation stability reproducibility.
cv <- smf_resampling_spec("kfold",n_splits=3L,seed=60L)
sp2 <- smf_experiment_spec(task=sp@task,data=sp@data,design=sp@design,resampling=cv,model=sp@model,metrics=sp@metrics)
es <- smf_explain_spec("permutation",n_repeats=3L,seed=61L)
a <- smf_explanation_stability(sp2,d,es,top_k=2L)
b <- smf_explanation_stability(sp2,d,es,top_k=2L)
stopifnot(identical(a@summary,b@summary), identical(a@rank_stability,b@rank_stability))
stopifnot(isFALSE(a@provenance$final_test_used))

# 8. Optional SHAP smoke test.
if (requireNamespace("fastshap",quietly=TRUE)) {
  sh <- smf_shap(fit,d[fit@split@train_index,,drop=FALSE],te[1:3,,drop=FALSE],nsim=10L,seed=62L)
  stopifnot(nrow(sh)==3L)
}

cat("\nAll validate_0.5.0.R checks passed.\n")
invisible(TRUE)
