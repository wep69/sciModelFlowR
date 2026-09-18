# sciModelFlowR 0.2.0 consolidated runtime validation entry point.
# Intended for local execution after installation of the frozen source snapshot.

suppressPackageStartupMessages(library(sciModelFlowR))
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "0.2.0")

cat("sciModelFlowR 0.2.0 runtime validation\n")
cat(R.version.string, "\n")
cat(R.version$platform, "\n\n")

# 1. Design-aware grouped resampling.
set.seed(101)
dg <- data.frame(
  id = sprintf("R%03d", 1:60),
  field = rep(sprintf("F%02d", 1:12), each = 5),
  x = rnorm(60),
  y = rnorm(60)
)
rg <- smf_group_vfold_cv(dg, "field", v = 4, id_column = "id", seed = 12L)
for (s in rg@splits) {
  stopifnot(length(intersect(unique(dg$field[s@train_index]), unique(dg$field[s@test_index]))) == 0L)
}

# 2. Temporal ordering.
dt <- data.frame(id = 1:30, time = rep(1:10, each = 3), x = rnorm(30))
rt <- smf_time_cv(dt, "time", initial = 5, assess = 2, id_column = "id")
for (s in rt@splits) stopifnot(max(dt$time[s@train_index]) < min(dt$time[s@test_index]))

# 3. Spatial reproducibility.
ds <- expand.grid(x = 1:8, y = 1:6)
ds$id <- seq_len(nrow(ds))
rs1 <- smf_spatial_cv(ds, c("x", "y"), v = 4, id_column = "id", seed = 99L, n_x = 4, n_y = 3)
rs2 <- smf_spatial_cv(ds, c("x", "y"), v = 4, id_column = "id", seed = 99L, n_x = 4, n_y = 3)
stopifnot(identical(rs1@manifest_hash, rs2@manifest_hash))

# 4. RFE and sequential selection.
set.seed(21)
n <- 100
fd <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n), x4 = rnorm(n))
fd$y <- 4 * fd$x1 - 2 * fd$x2 + rnorm(n, sd = 0.4)
rfe <- smf_select_features(fd, "y", smf_feature_spec("rfe", n_features = 2L, parameters = list(criterion = "bic")), context = "training")
seqf <- smf_select_features(fd, "y", smf_feature_spec("sequential", n_features = 2L, parameters = list(criterion = "bic", direction = "forward")), context = "training")
stopifnot(length(rfe@selected) == 2L, length(seqf@selected) == 2L, "x1" %in% rfe@selected, "x1" %in% seqf@selected)

# 5. PCA state transfer must agree with direct predict.prcomp.
set.seed(7)
tr <- data.frame(x1 = rnorm(50), x2 = rnorm(50), x3 = rnorm(50), y = rnorm(50))
te <- data.frame(x1 = rnorm(12), x2 = rnorm(12), x3 = rnorm(12))
pca_state <- smf_build_representation(tr, "y", smf_feature_spec("pca", n_features = 2L), context = "training")
pca_pkg <- smf_apply_representation(pca_state, te)
pca_ref <- as.data.frame(stats::predict(pca_state@state, newdata = te)[, 1:2, drop = FALSE])
stopifnot(isTRUE(all.equal(unname(as.matrix(pca_pkg)), unname(as.matrix(pca_ref)), tolerance = 1e-10)))

# 6. Studentized bootstrap.
set.seed(4)
bd <- data.frame(y = rnorm(40, 3, 2))
stat <- function(z) c(mean = mean(z$y))
sefun <- function(z) c(mean = stats::sd(z$y) / sqrt(nrow(z)))
bs <- smf_bootstrap_spec("case", n_resamples = 199L, interval = "studentized", seed = 12L, parameters = list(standard_error = sefun))
bout <- smf_bootstrap(bd, bs, stat)
stopifnot(all(is.finite(bout@interval)), bout@interval["mean", "lower"] < bout@interval["mean", "upper"])

# 7. End-to-end resample experiment with fold-local feature learning.
d <- smf_load_dataset("gold_grouped_fields")
target <- if ("yield" %in% names(d)) "yield" else names(d)[vapply(d, is.numeric, logical(1))][1]
id <- if ("obs_id" %in% names(d)) "obs_id" else names(d)[1]
group <- if ("field" %in% names(d)) "field" else names(d)[2]
preds <- setdiff(names(d), c(target, id, group))
preds <- preds[vapply(d[preds], function(z) is.numeric(z) || is.factor(z) || is.character(z), logical(1))]
spec <- smf_experiment_spec(
  task = smf_task_spec("regression", target),
  data = smf_data_spec(target, preds, id_column = id),
  design = smf_design_spec(id_column = id, group_columns = group),
  preprocessing = smf_preprocess_spec("median", TRUE, TRUE),
  resampling = smf_resampling_spec("group", n_splits = 3L, parameters = list(groups = group)),
  model = smf_model_spec("linear_regression", "stats"),
  metrics = list(smf_metric_spec("rmse")),
  features = smf_feature_spec("nzv")
)
r <- smf_resample_experiment(spec, d)
stopifnot(length(r@fold_results) == length(r@resamples@splits), nrow(r@aggregate) == 1L)

cat("\nAll validate_0.2.0.R checks passed.\n")
invisible(TRUE)
