# sciModelFlowR 0.3.0 consolidated runtime validation entry point.
# Intended for the final local validation cycle; not executed during source-only development.

suppressPackageStartupMessages(library(sciModelFlowR))
stopifnot(as.character(utils::packageVersion("sciModelFlowR")) == "0.3.0")
cat("sciModelFlowR 0.3.0 runtime validation\n", R.version.string, "\n", R.version$platform, "\n\n")

# 1. stats adapter equivalence: Gaussian regression.
d <- smf_load_dataset("gold_linear_regression")
task <- smf_task_spec("regression", target = "yield")
model <- smf_model_spec("linear_regression", "stats")
x <- d[c("nitrogen", "rainfall", "soil_n")]
fa <- smf_fit_model(task, model, x, d$yield)
pa <- smf_predict_model(fa, task, x, type = "response")
ref <- stats::lm(yield ~ nitrogen + rainfall + soil_n, data = d)
pr <- as.numeric(stats::predict(ref, newdata = d))
stopifnot(isTRUE(all.equal(pa, pr, tolerance = 1e-12)))

# 2. Binary class-probability normalization.
b <- smf_load_dataset("gold_binary_calibration")
tb <- smf_task_spec("binary", target = "event", positive_label = "1")
mb <- smf_model_spec("logistic_regression", "stats")
xb <- b[c("x1", "x2")]
fb <- smf_fit_model(tb, mb, xb, b$event)
pb <- smf_predict_model(fb, tb, xb, type = "prob")
stopifnot(max(abs(rowSums(pb) - 1)) < 1e-12, all(pb >= 0 & pb <= 1), identical(colnames(pb), c("0", "1")))

# 3. PredictionDistribution supports class log probability but not a CDF.
pdist <- smf_prediction_distribution(
  "class_probabilities",
  list(prob = pb, classes = colnames(pb)),
  capabilities = list(log_prob = TRUE, calibration = TRUE)
)
stopifnot(all(is.finite(smf_dist_log_prob(pdist, b$event))))
cdf_blocked <- inherits(try(smf_dist_cdf(pdist, 0.5), silent = TRUE), "try-error")
stopifnot(cdf_blocked)

# 4. Calibration uses a development-only calibration partition.
set.seed(260915)
idx <- sample(seq_len(nrow(b)), floor(0.7 * nrow(b)))
cal_idx <- setdiff(seq_len(nrow(b)), idx)
fit_dev <- smf_fit_model(tb, mb, xb[idx, , drop = FALSE], b$event[idx])
raw_cal <- smf_predict_model(fit_dev, tb, xb[cal_idx, , drop = FALSE], type = "prob")
cs <- smf_calibration_spec(method = "isotonic")
cal <- smf_calibrate(b$event[cal_idx], raw_cal, cs, training_data = b[cal_idx, , drop = FALSE])
pc <- smf_apply_calibration(cal, raw_cal)
stopifnot(max(abs(rowSums(pc) - 1)) < 1e-10)

# 5. Imbalance operations are analysis-only.
im <- smf_load_dataset("gold_multiclass_imbalanced")
ispec <- smf_imbalance_spec(method = "weights")
ires <- smf_apply_imbalance(im, outcome = "class", spec = ispec, context = "analysis")
stopifnot(length(ires@weights) == nrow(im), all(is.finite(ires@weights)))
assessment_blocked <- inherits(try(smf_apply_imbalance(im, "class", ispec, context = "assessment"), silent = TRUE), "try-error")
stopifnot(assessment_blocked)

# 6. Multiclass probabilistic scores.
pm <- as.matrix(im[c("true_p_A", "true_p_B", "true_p_C")]); colnames(pm) <- c("A", "B", "C")
mdist <- smf_prediction_distribution("class_probabilities", list(prob = pm, classes = colnames(pm)), capabilities = list(log_prob = TRUE, calibration = TRUE))
sc <- smf_evaluate_probabilistic(factor(im$class, levels = colnames(pm)), mdist, metrics = c("log_loss", "brier", "ece"))
stopifnot(all(is.finite(sc$value)))

# 7. Threshold optimization uses development labels only.
th <- smf_optimize_threshold(factor(b$event[cal_idx], levels = c(0, 1)), raw_cal[, "1"], metric = "balanced_accuracy", positive_label = "1")
stopifnot(is.finite(th$threshold), th$threshold >= 0, th$threshold <= 1)

# 8. Optional backend adapters when installed.
if (requireNamespace("parsnip", quietly = TRUE)) {
  mt <- smf_model_spec("linear_regression", "tidymodels", parameters = list(model_engine = "lm"))
  ft <- smf_fit_model(task, mt, x, d$yield)
  pt <- smf_predict_model(ft, task, x, type = "response")
  stopifnot(isTRUE(all.equal(pt, pr, tolerance = 1e-10)))
}
if (requireNamespace("mlr3", quietly = TRUE) && requireNamespace("mlr3learners", quietly = TRUE)) {
  mm <- smf_model_spec("linear_regression", "mlr3", parameters = list(learner_id = "regr.lm"))
  fm <- smf_fit_model(task, mm, x, d$yield)
  pm3 <- smf_predict_model(fm, task, x, type = "response")
  stopifnot(isTRUE(all.equal(pm3, pr, tolerance = 1e-8)))
}

cat("\nAll validate_0.3.0.R checks passed.\n")
invisible(TRUE)
