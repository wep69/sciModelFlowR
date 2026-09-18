# Gold dataset card: `gold_conformal_regression`

**Purpose.** Frozen synthetic regression fixture for split-conformal calibration and untouched-test coverage checks.

**Generator seed:** `260918`. **Rows:** 2200: 500 train, 500 calibration and 1200 final test.
**Exact generator:** `data-raw/generate-gold-bayes-conformal.py` using NumPy `default_rng` (PCG64) and `%.12g` numeric serialization. The R companion file documents the formulas only and is not the byte-exact RNG generator.


The conditional mean is mildly nonlinear and the residual scale is heteroscedastic. The `partition` column is frozen so calibration and final test roles cannot drift between R and Python. Columns `mu_truth` and `sigma_truth` are generator truth and must not be used as predictors.

The target coverage used by the version-0.7 reference workflow is 0.90. Conformal coverage is interpreted marginally under the declared exchangeability assumptions; no conditional-coverage guarantee is claimed. This dataset is simulated validation material, not empirical evidence.
