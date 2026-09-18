# Gold dataset card: `gold_bayesian_linear`

**Purpose.** Frozen synthetic Gaussian-regression fixture for posterior recovery, posterior predictive checks and PSIS-LOO smoke tests.

**Generator seed:** `260917`. **Rows:** 600.
**Exact generator:** `data-raw/generate-gold-bayes-conformal.py` using NumPy `default_rng` (PCG64) and `%.12g` numeric serialization. The R companion file documents the formulas only and is not the byte-exact RNG generator.


The data-generating model is `y = 1.5 + 2*x1 - 1*x2 + epsilon`, with `epsilon ~ Normal(0, 0.8^2)`. Columns `mu_truth` and `sigma_truth` are generator truth and must not be used as ordinary predictors.

The dataset is simulated validation material, not empirical evidence. Runtime acceptance bands are defined in the local validation script rather than inferred from one realization.
