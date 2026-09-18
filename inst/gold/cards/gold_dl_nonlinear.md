# Gold dataset card: `gold_dl_nonlinear`

**Purpose.** Frozen synthetic regression fixture for Deep Learning and probabilistic Deep Learning.

**Generator seed:** `260915`. **Rows:** 480.

The response follows a nonlinear conditional mean with heteroscedastic Gaussian noise. Columns `mu_truth` and `sigma_truth` are generator truth and must never be used as predictors in ordinary benchmark workflows. They support numerical validation of distributional heads, interval coverage and uncertainty decomposition.

This dataset is simulated teaching/validation material, not empirical evidence.
