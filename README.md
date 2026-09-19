# sciModelFlowR

**Version 1.0.2 - patch release of the Consolidated Scientific Release**

`sciModelFlowR` is a design-aware scientific modeling framework for explicit data/design declarations, leakage-safe preprocessing and resampling, deterministic and probabilistic ML, tuning, benchmarking, explainability, Deep Learning, Bayesian and conformal inference, typed uncertainty, experiment tracking, safe persistence, scalable inference, protected external validation, and scientific reporting.

Version 1.0.2 releases the five corrections reported by the audited tutorial of the 1.0.1 installed library (`NEWS.md`; regression tests in `tests/testthat/test-regressions-102.R`), on top of the 22 documented corrections of 1.0.1 from the local validation campaign of the frozen 1.0.0 source tree (see `DERIVED_PATCH_NOTES.md`). The **246-symbol public API** is unchanged; the 1.0.0 freeze, hashes and release metadata remain the historical reference.

## Installation

```r
# Installs the vignettes, and pays the full rebuild locally.
remotes::install_github("wep69/sciModelFlowR", build_vignettes = TRUE, dependencies=TRUE, upgrade="ask")
```

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

## Complete tutorial (PT-BR + EN)

A six-part teaching tutorial walks a new user from the first command to the
full scientific flow, using **simulated data with planted discrepancies and
known truth** (outliers, MCAR/MAR missingness, heteroscedasticity, imbalance,
label noise, clustering, time series, spatial autocorrelation, high dimension,
superdispersion, nonlinearity). Every chapter runs real code, shows numbered
figures and tables with interpretation boxes, and ends with exercises and
collapsible solutions.

- Sources: `tutorial-completo-1.0.2/` (simulation script, `pt/` and `en/` qmds)
- Rendered self-contained HTML + PDF: `outputs/rendered-docs/tutorial-completo/`
  (`pt/` and `en/`, 6 parts each; ~115 pages per language)
- API coverage appendix: 112 of 246 exports called, gaps declared with reasons

## Certification status

Local validation campaign (Windows 11, R 4.6.0, Quarto 1.11.0, 2026-09-18):
`testthat` 62 files / 322 pass / 0 fail, Gold 25/25, cross-language 25/25,
reference tolerances ~1e-15, 28/28 vignettes rendered, 27/27 notebooks executed
in clean IR kernels, and `R CMD build` + `R CMD check --as-cran` completed with
**0 ERROR / 0 WARNING / 2 NOTEs** (new-submission metadata; intentional
top-level release documents). The 2 NOTEs are reviewed and accepted.

The package is **not claimed CRAN-ready**. Optional backends are exercised by
the frozen test suite where installed but are not formally certified; GPU/CUDA
was unavailable (`SKIP`); ONNX remains `QUARANTINED`; the historical 0.1.0–0.9.0
campaigns require their own snapshots and remain `NOT RUN` in this environment.
Full evidence: `outputs/final-reports/VALIDATION_RECORD_1.0.2.md`.

## Stable API

`inst/metadata/API_FREEZE_1.0.0.csv` contains the stable 1.x export contract
(the 1.0.0 freeze point; preserved unchanged in 1.0.1).
`inst/metadata/API_DIFF_0.9.0_TO_1.0.0.csv` records that no public symbol or
signature was intentionally changed during consolidation. Any future 1.x
deprecation follows `DEPRECATION_POLICY.md`.

## Release evidence

Key release evidence is stored under `inst/metadata/`: final compatibility
matrix, Gold release manifest, benchmark baselines, security review, API
freeze/diff, bibliography ledger, and the 1.0.0/1.0.1/1.0.2 release manifests.
`inst/metadata/RELEASE_MANIFEST_1.0.2.json` records the audited-tutorial
corrections and validation outcomes without redefining scientific semantics.
