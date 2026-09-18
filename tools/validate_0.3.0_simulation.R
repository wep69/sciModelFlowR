# sciModelFlowR 0.3.0 simulation validation for the final local cycle.
# Environment variables: SMF_SIM_N (default 200), SMF_CAL_N (default 1000).

suppressPackageStartupMessages(library(sciModelFlowR))
NSIM <- as.integer(Sys.getenv("SMF_SIM_N", "200")); N <- as.integer(Sys.getenv("SMF_CAL_N", "1000"))
if (NSIM < 50L) warning("NSIM < 50 is smoke testing only.")
set.seed(260915)
res <- data.frame(sim = seq_len(NSIM), ece_raw = NA_real_, ece_cal = NA_real_, logloss_raw = NA_real_, logloss_cal = NA_real_)
for (i in seq_len(NSIM)) {
  x <- rnorm(N); p_true <- plogis(-0.3 + 1.1 * x)
  y <- factor(ifelse(runif(N) < p_true, "event", "none"), levels = c("none", "event"))
  score <- plogis(1.6 * qlogis(pmin(pmax(p_true, 1e-6), 1 - 1e-6)))
  prob <- cbind(none = 1 - score, event = score)
  idx <- sample(seq_len(N), floor(.5 * N)); cal_idx <- idx[seq_len(floor(length(idx) / 2))]; test_idx <- setdiff(seq_len(N), idx)
  cfit <- smf_calibrate(y[cal_idx], prob[cal_idx, , drop = FALSE], smf_calibration_spec("isotonic"), training_data = data.frame(id = cal_idx, y = y[cal_idx]))
  pcal <- smf_apply_calibration(cfit, prob[test_idx, , drop = FALSE])
  draw <- smf_prediction_distribution("class_probabilities", list(prob = prob[test_idx, , drop = FALSE], classes = colnames(prob)), capabilities = list(log_prob = TRUE, calibration = TRUE))
  dcal <- smf_prediction_distribution("class_probabilities", list(prob = pcal, classes = colnames(pcal)), capabilities = list(log_prob = TRUE, calibration = TRUE))
  raw <- smf_evaluate_probabilistic(y[test_idx], draw, metrics = c("ece", "log_loss"))
  adj <- smf_evaluate_probabilistic(y[test_idx], dcal, metrics = c("ece", "log_loss"))
  res$ece_raw[i] <- raw$value[raw$metric == "ece"]; res$ece_cal[i] <- adj$value[adj$metric == "ece"]
  res$logloss_raw[i] <- raw$value[raw$metric == "log_loss"]; res$logloss_cal[i] <- adj$value[adj$metric == "log_loss"]
}
print(summary(res))
if (mean(res$ece_cal) >= mean(res$ece_raw)) stop("Isotonic calibration did not improve mean ECE in the predeclared simulation.")

d <- smf_load_dataset("gold_multiclass_imbalanced")
p <- as.matrix(d[c("true_p_A", "true_p_B", "true_p_C")])
stopifnot(max(abs(rowSums(p) - 1)) < 1e-10, all(p >= 0 & p <= 1))
for (seed in 1:50) {
  set.seed(seed)
  stopifnot(inherits(try(smf_apply_imbalance(d, "class", smf_imbalance_spec("upsample"), context = "test"), silent = TRUE), "try-error"))
}
cat("Simulation validation passed.\n")
invisible(res)
