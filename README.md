# sciModelFlowR

**Version 1.0.0 - Consolidated Scientific Release source tree**

`sciModelFlowR` is a design-aware scientific modeling framework for explicit data/design declarations, leakage-safe preprocessing and resampling, deterministic and probabilistic ML, tuning, benchmarking, explainability, Deep Learning, Bayesian and conformal inference, typed uncertainty, experiment tracking, safe persistence, scalable inference, protected external validation, and scientific reporting.

The 1.0.0 source tree preserves the **246-symbol public API frozen at 0.9.0**. This release phase is consolidation rather than algorithm expansion: stable contracts, Gold/reference evidence, cross-language fixtures, compatibility metadata, security review, release manifests, migration material, and final certification entry points are synchronized around one 1.x grammar.

```r
library(sciModelFlowR)
smf_doctor()
smf_list_datasets()
head(smf_api_catalog())
smf_backend_matrix()
```

Recommended scientific sequence:

**question -> design -> audit -> protected domains -> design-aware resampling -> training-only learning -> baseline -> justified complexity -> diagnostics -> typed uncertainty -> explanation stability -> external validation -> reporting -> reproducibility manifest**

The distributed Gold datasets are synthetic software-validation and teaching fixtures. They are not empirical field evidence.

## Certification status

The source implementation is consolidated for 1.0.0, but runtime certification is reported separately. In this environment no R executable is available, so `testthat`, numerical/reference tolerances, optional-backend certification, CPU/GPU execution, rendered Quarto/Jupyter documentation, pkgdown, `R CMD build`, and `R CMD check --as-cran` are **not claimed as passed**. They are reserved for the final local validation campaign.

The package must not be described as CRAN-ready until the actual build/check artifacts and logs exist. Optional backends remain quarantined until their rows in the final compatibility matrix are certified.

## Stable API

`inst/metadata/API_FREEZE_1.0.0.csv` contains the stable 1.x export contract. `inst/metadata/API_DIFF_0.9.0_TO_1.0.0.csv` records that no public symbol or signature was intentionally changed during consolidation. Any future 1.x deprecation follows `DEPRECATION_POLICY.md`.

## Release evidence

Key release evidence is stored under `inst/metadata/`: final compatibility matrix, Gold release manifest, benchmark baselines, security review, API freeze/diff, bibliography ledger, and the 1.0.0 release manifest. The final local validation campaign will update certification status without redefining scientific semantics.
