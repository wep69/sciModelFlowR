# Validation record — sciModelFlowR 1.0.1 (patch release)

> Artefacto validado: **tarball 1.0.1** construído da derived working copy
> (source freeze 1.0.0 + 22 correções documentadas em `DERIVED_PATCH_NOTES.md`).
> O freeze 1.0.0 (ZIP/TAR.GZ, hashes, metadata) permanece intacto como
> referência histórica. Nenhuma classificação converte ausência de
> backend/hardware/snapshot em PASS.

## Source integrity

- Base freeze ZIP SHA-256: `9483b17fe2bec07c7cd4c66dd6db7e4e44f632ac48d2b9a0f2a7bd671e36bb6d` — VERIFIED
- Base freeze TAR.GZ SHA-256: `ef684ad7d511a31d5487a1366b6fe099488f1fe98dbe57fd26f707136b144c3e` — VERIFIED
- Correções derivadas: **22** (`DERIVED_PATCH_NOTES.md`, originais pré-fix em
  `outputs/validation-records/*.frozen_orig`)
- API: 246 exports inalterados; `api_freeze` permanece `1.0.0`
  (`RELEASE_MANIFEST_1.0.1.json`: `api_changed_since_1_0_0 = false`)
- Tarball 1.0.1: `outputs/built-tarballs/sciModelFlowR_1.0.1.tar.gz`
  SHA-256 `F395795E874E6CFEECDD1F52BDB5469339E5100CC9D6FA75EA9CE1EE07E90DB4`
- `00check.log` SHA-256: `E5417B2C6F434EDE7BDBBC9C14B576EC40D744C1129D1FE08F2C59CB080898FE`
- Verified: **PASS**

## Environment

- Date: 2026-09-18 (America/Sao_Paulo)
- R: 4.6.0 (2026-04-24 ucrt), x86_64-w64-mingw32; gcc 14.3.0 (Rtools)
- OS: Windows 11 x64 (build 26200)
- CPU: Intel(R) Core(TM) i7-9700F @ 3.00GHz, 8 logical / 8 physical cores
- RAM: 31.9 GB · GPU: Radeon RX 570 (sem CUDA; `torch::cuda_is_available() == FALSE`)
- Quarto: 1.11.0 · Pandoc: 3.8.3 · RNGkind: Mersenne-Twister/Inversion/Rejection

## Core runtime

- static audit 1.0.1 (`tools/static_validate_1.0.1.py`): **600/600 PASS**
  (`outputs/final-reports/STATIC_AUDIT_1.0.1.md`)
- testthat (fonte): 61 arquivos, **299 PASS / 0 FAIL**
- testthat (instalado do tarball, biblioteca limpa): 61 arquivos,
  **0 failed / 0 errors / 1 skip / 2 warnings benignos**
- Gates 1.0.1: `tools/validate_1.0.1.R` **PASS**
  (“Source/reference contract checks completed for 1.0.1.”) e
  `tools/validate_1.0.1_release.R` **PASS**
  (“Release metadata contract checks complete for 1.0.1.”)
- Evidência: `outputs/evidence/final_gates_1.0.1.log`

## Numerical/reference

- status: **PASS** — coef max abs err `7.105e-15`, metric max abs err `5.773e-15`
- tolerâncias: `1e-10` predição / `1e-12` métrica

## Gold

- hashes: 25/25 **PASS** (`smf_run_gold_validation()`)
- known truth: verificado pela suíte congelada
- regeneração: não executada (fixtures congelados)
- layout: `inst/gold_data/` + `inst/extdata/gold_data/` (fix #14; conteúdo e
  hashes inalterados)

## Simulations

- **NOT RUN / UNAVAILABLE** — validadores históricos 0.1.0–0.9.0 exigem os
  snapshots próprios (não distribuídos com 1.0.x).

## Optional backends

- Exercício runtime via suíte congelada (adapters tidymodels, DL/torch CPU,
  Bayes/GP/conformal, persistência, deployment, batch/resume) sem falhas.
- Certificação formal de backends não reivindicada; GPU/CUDA **SKIP/UNAVAILABLE**;
  ONNX **QUARANTINED**.

## Documentation

- vignettes: **28/28** renderizadas em `inst/doc` (build) e reconstruídas pelo
  check (`re-building of vignette outputs ... OK`)
- notebooks: **27/27** executados em kernels IR limpos contra o 1.0.1 instalado
  (`outputs/evidence/notebooks_execution_1.0.1.csv`; cópias executadas em
  `outputs/rendered-docs/notebooks/`)
- pkgdown: **28/28 artigos**, site completo em `docs/` com versão 1.0.1
  (home, reference, news, sitemap; `pkgdown_site_articles_1.0.1.csv`)

## R CMD build/check

- built tarball: `outputs/built-tarballs/sciModelFlowR_1.0.1.tar.gz`
- SHA-256: `F395795E874E6CFEECDD1F52BDB5469339E5100CC9D6FA75EA9CE1EE07E90DB4`
- check status (`--as-cran`): **0 ERROR / 0 WARNING / 2 NOTEs**
- NOTEs (revisadas e aceites): (1) CRAN incoming feasibility — New submission;
  Suggests fora de repositórios mainstream (`fastshap`, `vip`, `cmdstanr`);
  (2) top-level files — documentos de governança/release intencionais
  (`BIBLIOGRAPHY_VERIFICATION`, `COMPATIBILITY`, `DEPRECATION_POLICY`,
  `MIGRATION_*`, `RELEASE_*`, `SECURITY_REVIEW`, `SOURCE_MANIFEST`, `data-raw`).

## Publication

- Repositório: `https://github.com/wep69/sciModelFlowR` (público)
- GitHub Pages: `https://wep69.github.io/sciModelFlowR/` (`main` → `/docs`)
- Tags: `v1.0.0` (freeze histórico importado) e `v1.0.1` (este patch)
- GitHub Release `v1.0.1` com o tarball anexado

## Final classification

**PASS (patch release 1.0.1)** — caveats obrigatórios:

- campanha histórica 0.1.0–0.9.0: `NOT RUN` (snapshots indisponíveis);
- GPU/CUDA: `SKIP/UNAVAILABLE`; ONNX: `QUARANTINED`;
- 2 NOTEs do check aceites formalmente;
- pacote **não** declarado CRAN-ready.
