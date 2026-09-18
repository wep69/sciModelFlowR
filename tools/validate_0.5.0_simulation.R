# Simulation/property checks for sciModelFlowR 0.5.0.
suppressPackageStartupMessages(library(sciModelFlowR))
d <- smf_load_dataset("gold_xai_stability")
stopifnot(abs(cor(d$signal_primary,d$signal_correlated)) > .95)
# The main runtime script performs repeated resampling stability checks.
# Extend locally with model seeds/backends and pre-specified tolerances.
cat("0.5.0 simulation/property scaffold passed.\n")
