"""Release provenance for the 13 Gold datasets introduced in sciModelFlowR 0.9.0.
Frozen CSV files and SHA-256 values are authoritative. RNG: NumPy PCG64, seed 260919.
Exact regeneration must reproduce the frozen hashes before replacement.
"""
SEED = 260919
GOLD_DATASETS = ['gold_hierarchical_yield', 'gold_time_climate', 'gold_spatial_soil', 'gold_spectral_curve', 'gold_hyperspectral_small', 'gold_rgb_leaf_small', 'gold_multimodal_stress', 'gold_count_pests', 'gold_nonlinear_bart', 'gold_gp_surface', 'gold_distributional_yield', 'gold_covariate_shift', 'gold_missingness_mcar_mar', 'gold_conformal_heteroscedastic', 'gold_dl_tiny']
