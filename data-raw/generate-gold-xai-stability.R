# Deterministic generator for gold_xai_stability (0.5.0)
i <- seq_len(240)
signal_primary <- seq(-2.5, 2.5, length.out = 240)
signal_correlated <- 0.96 * signal_primary + 0.04 * sin(i * 0.37)
weak_feature <- cos(i * 0.21)
noise <- 0.15 * sin(i * 0.73) + 0.08 * cos(i * 0.11)
response <- 10 + 5 * signal_primary + 0.5 * weak_feature + noise
gold_xai_stability <- data.frame(
  obs_id = sprintf("XA%03d", i), signal_primary, signal_correlated, weak_feature, response
)
utils::write.csv(gold_xai_stability, "inst/extdata/gold_data/gold_xai_stability.csv", row.names = FALSE)
