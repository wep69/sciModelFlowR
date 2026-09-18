# sciModelFlowR 0.4.0 simulation validation for the final local cycle.
# Environment variable SMF_TUNE_SIM_N controls Monte Carlo repetitions (default 100).

suppressPackageStartupMessages(library(sciModelFlowR))
NSIM <- as.integer(Sys.getenv("SMF_TUNE_SIM_N", "100"))
if (NSIM < 30L) warning("SMF_TUNE_SIM_N < 30 is smoke testing only.")

# Study 1: Pareto recovery is deterministic for a frozen analytic objective.
space <- smf_search_space(x = smf_param_dbl(values = seq(0, 1, by = .1)))
objs <- list(smf_metric_spec("error", "minimize"), smf_metric_spec("cost", "minimize"))
tune <- smf_tuning_spec("grid", budget = 11, objectives = objs)
res <- smf_tune_objective(space, tune, function(cfg) c(error = (1 - cfg$x)^2, cost = cfg$x^2))
stopifnot(nrow(res@pareto) > 1, is.null(res@selected))

# Study 2: random-search reproducibility and best-observed convergence on a smooth objective.
best <- numeric(NSIM)
for (i in seq_len(NSIM)) {
  tr <- smf_tuning_spec("random", budget = 30, objectives = list(smf_metric_spec("loss", "minimize")), seed = 5000L + i)
  rr <- smf_tune_objective(
    smf_search_space(x = smf_param_dbl(-4, 4), y = smf_param_dbl(-4, 4)),
    tr,
    function(cfg) c(loss = (cfg$x - 1.25)^2 + (cfg$y + .75)^2)
  )
  best[i] <- min(rr@archive$loss)
}
print(summary(best))
if (stats::median(best) > 1.0) stop("Random search failed the predeclared smooth-objective performance threshold.")

# Study 3: explicit decision rules can legitimately select different Pareto candidates.
d <- data.frame(candidate=c("A","B","C"), error=c(.10,.15,.25), cost=c(.90,.50,.25))
dirs <- c(error="minimize",cost="minimize")
a <- smf_select_compromise(d,c("error","cost"),dirs,list(type="weighted_sum",weights=c(error=.9,cost=.1)))
b <- smf_select_compromise(d,c("error","cost"),dirs,list(type="weighted_sum",weights=c(error=.1,cost=.9)))
stopifnot(a$candidate[[1]] != b$candidate[[1]])

# Study 4: optional XGBoost nested-selection simulation when available.
if (requireNamespace("xgboost", quietly = TRUE)) {
  set.seed(260915)
  n <- 240
  x1 <- rnorm(n); x2 <- rnorm(n); y <- 2*x1 - .7*x2 + .8*x1*x2 + rnorm(n, sd=.8)
  dat <- data.frame(id=sprintf("S%03d",seq_len(n)),x1=x1,x2=x2,y=y)
  task <- smf_task_spec("regression","y")
  ds <- smf_data_spec("y",c("x1","x2"),id_column="id")
  design <- smf_design_spec(id_column="id")
  spec <- smf_experiment_spec(task,ds,design=design,model=smf_model_spec("boosted_tree","xgboost",parameters=list(params=list(objective="reg:squarederror"),nrounds=50L)),metrics=list(smf_metric_spec("rmse","minimize")))
  ss <- smf_search_space(nrounds=smf_param_int(values=c(25L,50L,100L),resource=TRUE),params.max_depth=smf_param_int(values=c(2L,4L)),params.eta=smf_param_dbl(values=c(.05,.15)))
  ts <- smf_tuning_spec("random",budget=4,objectives=list(smf_metric_spec("rmse","minimize")),seed=260916)
  nr <- smf_nested_tune(spec,dat,ss,ts,outer=smf_resampling_spec("kfold",n_splits=3,seed=260917),inner=smf_resampling_spec("kfold",n_splits=2,seed=260918))
  stopifnot(nrow(nr@generalization_scores) == 3)
}

cat("0.4.0 simulation validation passed.\n")
invisible(best)
