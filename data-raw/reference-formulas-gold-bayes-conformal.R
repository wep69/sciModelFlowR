# R reference formulas for the version-0.7 Bayesian and conformal Gold fixtures.
# This file documents the scientific data-generating equations only. It is NOT
# the byte-exact generator because R and NumPy use different RNG streams.
# Use data-raw/generate-gold-bayes-conformal.py for exact regeneration.
set.seed(260917)
n <- 600L
x1 <- rnorm(n); x2 <- rnorm(n); sigma <- 0.8
mu <- 1.5 + 2*x1 - x2
gold_bayesian_linear <- data.frame(row_id=sprintf("B%04d",seq_len(n)),x1=x1,x2=x2,y=mu+rnorm(n,0,sigma),mu_truth=mu,sigma_truth=sigma)

set.seed(260918)
n_train <- 500L; n_cal <- 500L; n_test <- 1200L; n <- n_train+n_cal+n_test
x1 <- runif(n,-2.5,2.5); x2 <- rnorm(n); mu <- 2+1.4*x1+0.45*x2+0.3*sin(2*x1); sigma <- 0.55+0.18*abs(x1)
gold_conformal_regression <- data.frame(row_id=sprintf("C%04d",seq_len(n)),partition=c(rep("train",n_train),rep("calibration",n_cal),rep("test",n_test)),x1=x1,x2=x2,y=mu+rnorm(n,0,sigma),mu_truth=mu,sigma_truth=sigma)
