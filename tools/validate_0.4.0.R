# sciModelFlowR 0.4.0 runtime validation entry point.
# Intended for the consolidated final local validation cycle; not executed during source-only development.

suppressPackageStartupMessages(library(sciModelFlowR))
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "0.4.0")
cat("sciModelFlowR 0.4.0 runtime validation\n", R.version.string, "\n", R.version$platform, "\n\n")

# 1. Conditional search-space semantics and reproducibility.
space <- smf_search_space(
  booster = smf_param_fct(c("linear", "tree")),
  depth = smf_param_int(2, 4, depends_on = list(param = "booster", values = "tree")),
  rate = smf_param_dbl(0.01, 0.30, log = TRUE)
)
grid <- smf_search_grid(space, levels = 3)
stopifnot(all(is.na(grid$depth[grid$booster == "linear"])))
r1 <- smf_search_random(space, 20, seed = 401)
r2 <- smf_search_random(space, 20, seed = 401)
stopifnot(identical(r1, r2))
stopifnot(identical(names(smf_from_json(smf_to_json(space))@parameters), names(space@parameters)))

# 2. Single-objective objective tuning.
space1 <- smf_search_space(x = smf_param_dbl(values = c(-2, 0, 2)))
t1 <- smf_tuning_spec("grid", budget = 3, objectives = list(smf_metric_spec("loss", "minimize")), seed = 402)
z1 <- smf_tune_objective(space1, t1, function(cfg) c(loss = (cfg$x - 1)^2))
stopifnot(nrow(z1@archive) == 3, z1@selected$x[[1]] == 0)

# 3. Multi-objective Pareto semantics.
space2 <- smf_search_space(x = smf_param_dbl(values = c(0, .5, 1)))
objs <- list(smf_metric_spec("error", "minimize"), smf_metric_spec("cost", "minimize"))
t2 <- smf_tuning_spec("grid", 3, objectives = objs)
z2 <- smf_tune_objective(space2, t2, function(cfg) c(error = (cfg$x - 1)^2, cost = cfg$x^2))
stopifnot(is.null(z2@selected), nrow(z2@pareto) >= 2)
rule <- list(type = "weighted_sum", weights = c(error = .7, cost = .3))
pick <- smf_select_compromise(z2@pareto, c("error", "cost"), c(error = "minimize", cost = "minimize"), rule)
stopifnot(nrow(pick) == 1)

# 4. Cross-language Pareto fixture.
fixture <- jsonlite::fromJSON(system.file("crosslang/expected/pareto_reference_v1.json", package = "sciModelFlowR"))
cand <- fixture$candidates
pf <- smf_pareto_front(cand, c("error", "cost"), c(error = "minimize", cost = "minimize"))
stopifnot(setequal(pf$id, fixture$pareto_ids))

# 5. Nested split geometry: inner partitions are built only from each outer analysis set.
d <- smf_load_dataset("gold_linear_regression")
task <- smf_task_spec("regression", "yield")
ds <- smf_data_spec("yield", c("nitrogen", "rainfall", "soil_n"), id_column = "obs_id")
design <- smf_design_spec(id_column = "obs_id")
outer <- smf_resampling_spec("kfold", n_splits = 3, seed = 410)
inner <- smf_resampling_spec("kfold", n_splits = 2, seed = 411)
nested <- smf_nested_resampler(d, outer, inner, design, task)
stopifnot(length(nested@splits) == 3, length(nested@nested) == 3)
for (i in seq_along(nested@splits)) {
  outer_train <- nested@splits[[i]]@train_index
  inner_indices <- unique(unlist(lapply(nested@nested[[i]]@splits, function(s) c(s@train_index, s@test_index))))
  stopifnot(all(inner_indices %in% outer_train), nested@splits[[i]]@hash != nested@nested[[i]]@manifest_hash)
}

# 6. Managed tuning rejects final-test data.
final <- d
attr(final, "smf_partition_role") <- "final_test"
spec <- smf_experiment_spec(task, ds, design = design, model = smf_model_spec("lm", "stats"), metrics = list(smf_metric_spec("rmse", "minimize")))
blocked <- inherits(try(smf_tune(spec, final, smf_search_space(dummy = smf_param_int(values = 1:2)), smf_tuning_spec("grid", 2)), silent = TRUE), "try-error")
stopifnot(blocked)

# 7. Benchmark specification does not emit a universal winner by default.
bs <- smf_benchmark_spec(
  candidates = list(reference = smf_model_spec("lm", "stats"), reference2 = smf_model_spec("lm", "stats", parameters = list(dummy = 1))),
  metrics = list(smf_metric_spec("rmse", "minimize")),
  resampling = outer,
  decision_rule = NULL
)
br <- smf_benchmark(spec, d, bs)
stopifnot(is.null(br@decision), isTRUE(br@provenance$no_universal_winner), identical(br@resamples@manifest_hash, br@provenance$shared_resampling_hash))
explicit <- smf_decide_benchmark(br, list(type = "weighted_sum", weights = c(rmse = 1)))
stopifnot(nrow(explicit) == 1)

# 8. Optional XGBoost tuning smoke test.
if (requireNamespace("xgboost", quietly = TRUE)) {
  xspec <- smf_experiment_spec(
    task = task, data = ds, design = design,
    resampling = smf_resampling_spec("kfold", n_splits = 3, seed = 420),
    model = smf_model_spec("boosted_tree", "xgboost", parameters = list(params = list(max_depth = 3, eta = .1), nrounds = 50L)),
    metrics = list(smf_metric_spec("rmse", "minimize"))
  )
  xs <- smf_search_space(
    nrounds = smf_param_int(values = c(25L, 50L), resource = TRUE),
    params.max_depth = smf_param_int(values = c(2L, 4L)),
    params.eta = smf_param_dbl(values = c(.05, .15))
  )
  xt <- smf_tuning_spec("random", budget = 3, objectives = list(smf_metric_spec("rmse", "minimize")), seed = 421)
  xr <- smf_tune(xspec, d, xs, xt)
  stopifnot(nrow(xr@archive) >= 1, !is.null(xr@selected))
}

cat("\nAll validate_0.4.0.R checks passed.\n")
invisible(TRUE)
