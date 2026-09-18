# sciModelFlowR 0.2.0 simulation validation.
# Run locally during the consolidated final validation cycle.
# Environment variables can reduce/increase runtime:
#   SMF_SIM_N=200
#   SMF_BOOT_B=399

suppressPackageStartupMessages(library(sciModelFlowR))

NSIM <- as.integer(Sys.getenv("SMF_SIM_N", "200"))
B <- as.integer(Sys.getenv("SMF_BOOT_B", "399"))
if (NSIM < 50L) warning("NSIM < 50 is suitable for smoke testing only, not coverage certification.")
if (B < 199L) warning("B < 199 is suitable for smoke testing only, not interval certification.")

set.seed(260915)

cover_iid <- logical(NSIM)
width_iid <- numeric(NSIM)
for (i in seq_len(NSIM)) {
  d <- data.frame(y = rnorm(60, mean = 2, sd = 1.5))
  spec <- smf_bootstrap_spec("case", n_resamples = B, interval = "percentile", level = .95, seed = 10000L + i)
  out <- smf_bootstrap(d, spec, function(z) c(mean = mean(z$y)))
  lo <- out@interval["mean", "lower"]; hi <- out@interval["mean", "upper"]
  cover_iid[i] <- lo <= 2 && 2 <= hi
  width_iid[i] <- hi - lo
}

iid_summary <- data.frame(
  scenario = "iid_normal_mean_percentile",
  nsim = NSIM,
  B = B,
  coverage = mean(cover_iid),
  mean_width = mean(width_iid),
  acceptance_lower = .88,
  acceptance_upper = .99
)

# Clustered mean scenario. Resample complete clusters.
cover_cluster <- logical(NSIM)
width_cluster <- numeric(NSIM)
for (i in seq_len(NSIM)) {
  G <- 20L; m <- 5L
  u <- rnorm(G, 0, .8)
  d <- data.frame(
    field = rep(seq_len(G), each = m),
    y = 5 + rep(u, each = m) + rnorm(G * m, 0, 1)
  )
  des <- smf_design_spec(group_columns = "field")
  spec <- smf_bootstrap_spec("cluster", n_resamples = B, sampling_unit = "field", interval = "percentile", level = .95, seed = 20000L + i)
  out <- smf_bootstrap(d, spec, function(z) c(mean = mean(z$y)), design = des)
  lo <- out@interval["mean", "lower"]; hi <- out@interval["mean", "upper"]
  cover_cluster[i] <- lo <= 5 && 5 <= hi
  width_cluster[i] <- hi - lo
}

cluster_summary <- data.frame(
  scenario = "clustered_mean_cluster_bootstrap",
  nsim = NSIM,
  B = B,
  coverage = mean(cover_cluster),
  mean_width = mean(width_cluster),
  acceptance_lower = .85,
  acceptance_upper = .995
)

results <- rbind(iid_summary, cluster_summary)
print(results)

if (any(results$coverage < results$acceptance_lower | results$coverage > results$acceptance_upper)) {
  stop("One or more bootstrap coverage scenarios fell outside the predeclared acceptance band.")
}

# Resampling invariants over repeated random seeds.
for (seed in 1:50) {
  d <- data.frame(id = 1:60, field = rep(1:12, each = 5), y = rnorm(60))
  r <- smf_group_vfold_cv(d, "field", v = 4, id_column = "id", seed = seed)
  for (s in r@splits) {
    stopifnot(length(intersect(unique(d$field[s@train_index]), unique(d$field[s@test_index]))) == 0L)
  }
}

cat("Simulation validation passed.\n")
invisible(results)
