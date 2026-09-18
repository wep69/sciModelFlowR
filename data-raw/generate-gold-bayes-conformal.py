#!/usr/bin/env python3
"""Exact generator for sciModelFlowR 0.7.0 Bayesian/conformal Gold fixtures.

The NumPy PCG64/default_rng stream is part of the frozen generator contract.
Changing RNG, draw order, formulas, row order, or float formatting requires a
new Gold-data version and new hashes.
"""
from pathlib import Path
import numpy as np
import pandas as pd

OUT = Path(__file__).resolve().parents[1] / "inst" / "extdata" / "gold_data"
OUT.mkdir(parents=True, exist_ok=True)

rng = np.random.default_rng(260917)
n = 600
x1 = rng.normal(size=n)
x2 = rng.normal(size=n)
sigma = 0.8
mu = 1.5 + 2.0 * x1 - x2
y = mu + rng.normal(0.0, sigma, size=n)
bayes = pd.DataFrame({
    "row_id": [f"B{i:04d}" for i in range(1, n + 1)],
    "x1": x1,
    "x2": x2,
    "y": y,
    "mu_truth": mu,
    "sigma_truth": sigma,
})
bayes.to_csv(OUT / "gold_bayesian_linear.csv", index=False, float_format="%.12g")

rng = np.random.default_rng(260918)
n_train, n_cal, n_test = 500, 500, 1200
n = n_train + n_cal + n_test
x1 = rng.uniform(-2.5, 2.5, size=n)
x2 = rng.normal(size=n)
mu = 2.0 + 1.4 * x1 + 0.45 * x2 + 0.3 * np.sin(2.0 * x1)
sigma = 0.55 + 0.18 * np.abs(x1)
y = mu + rng.normal(0.0, sigma, size=n)
conf = pd.DataFrame({
    "row_id": [f"C{i:04d}" for i in range(1, n + 1)],
    "partition": ["train"] * n_train + ["calibration"] * n_cal + ["test"] * n_test,
    "x1": x1,
    "x2": x2,
    "y": y,
    "mu_truth": mu,
    "sigma_truth": sigma,
})
conf.to_csv(OUT / "gold_conformal_regression.csv", index=False, float_format="%.12g")
