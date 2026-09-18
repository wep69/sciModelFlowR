# Validation record — sciModelFlowR 1.0.0 (derived working copy `1.0.0+derived-fix`)

> Artefacto validado: cópia de trabalho derivada do source freeze 1.0.0
> (`D:\Walter\R\Pacotes_criados\sciModelFlowR\repo`), com 21 desvios
> documentados em `DERIVED_PATCH_NOTES.md`. Os ZIP/TAR.GZ congelados **não**
> foram alterados. Nenhuma classificação abaixo converte ausência de
> backend/hardware/snapshot em PASS.

## Source integrity

- ZIP SHA-256: `9483b17fe2bec07c7cd4c66dd6db7e4e44f632ac48d2b9a0f2a7bd671e36bb6d` — **VERIFIED** (§2)
- TAR.GZ SHA-256: `ef684ad7d511a31d5487a1366b6fe099488f1fe98dbe57fd26f707136b144c3e` — **VERIFIED** (§2)
- Derived working tarball: `outputs/built-tarballs/sciModelFlowR_1.0.0_derived.tar.gz`
  SHA-256 `B35A37D0E6F8FAE2DFF32DE838EBC3D860B40E69CB7CBB58F352CEC25172289B`
- `00check.log` SHA-256: `E2D61CED5AA1752A01DA3D06783600BCE6933B86378E3BF1703291E1F741609D`
- Verified: **PASS**

## Environment

- Date: 2026-09-18 (America/Sao_Paulo)
- R: 4.6.0 (2026-04-24 ucrt), x86_64-w64-mingw32
- Rtools/compiler: gcc.exe (GCC) 14.3.0 (per check log)
- OS: Windows 11 x64 (build 26200)
- CPU: Intel(R) Core(TM) i7-9700F @ 3.00GHz, 8 logical / 8 physical cores
- RAM: 31.9 GB
- GPU: Radeon RX 570 Series (sem CUDA; `torch::cuda_is_available() == FALSE`)
- CUDA: indisponível
- Quarto: 1.11.0
- Pandoc: 3.8.3 (bundled Quarto)
- RNGkind: Mersenne-Twister / Inversion / Rejection

## Core runtime

- document: `devtools::document()` executado (roxygen2 8.1.0) — 246 páginas por
  função **rejeitadas** em favor dos 10 tópicos congelados (decisão e regra dev
  documentadas em `DERIVED_PATCH_NOTES.md` §13); NAMESPACE mantido com 246 exports.
- testthat (fonte, `devtools::test`): 61 arquivos, **299 PASS / 0 FAIL / 1 SKIP**
  (`outputs/evidence/testthat_1.0.0_full2.log`, `testthat_1.0.0_results2.csv`)
- testthat (instalado do tarball, biblioteca limpa): 61 arquivos,
  **0 failed / 0 errors / 1 skip / 2 warnings benignos**
  (`outputs/evidence/final_gates_1.0.0.log`)
- load/install: `R CMD INSTALL` em biblioteca limpa — OK; `smf_doctor()` OK
- Gates §18.3/§18.4 (harness derivado): **PASS**
  (“Source/reference contract checks completed.” / “Release metadata contract checks complete.”)

## Numerical/reference

- status: **PASS**
- `smf_run_reference_validation()`: coef max abs err `7.105e-15`,
  metric max abs err `5.773e-15` (tolerâncias 1e-10/1e-12)
- artefactos: `outputs/evidence/final_gates_1.0.0.log`
- nota: o gate congelado ajustava OLS em train+test e comparava com fixture
  gerado em train→test; corrigido (fix derivado §3) — o fixture reproduz
  exatamente o escopo train/test.

## Gold

- hashes: 25/25 **PASS** (`smf_run_gold_validation()`)
- known truth: verificado pelos testes congelados (test-gold*, test-dl-gold*)
- regeneração: **não executada** (fixtures congelados; geradores byte-exact
  distribuídos apenas para 0.5.0/0.7.0; decisão documentada no freeze)
- hashes independentes: `outputs/evidence/` (via package-native) +
  `inst/gold_data/gold_hashes.csv`

## Simulations

- seeds: —
- repetitions: —
- acceptance bands: —
- result: **NOT RUN / UNAVAILABLE** — os validadores históricos
  (`tools/validate_0.1.0.R`…`validate_0.9.0*.R`) exigem os snapshots
  históricos 0.1.0–0.9.0, que não estão presentes neste workspace
  (apenas o snapshot 1.0.0 foi distribuído). Registado como `NOT RUN`, nunca PASS.
  Os scripts históricos foram verificados sintaticamente (`parse`) e ficam
  prontos para a campanha histórica nos snapshots próprios (§8/§29).

## Optional backends

- Instalados na máquina: stats (core), tidymodels/parsnip/workflows/rsample/
  hardhat/yardstick/probably/spatialsample, mlr3* (+paradox/bbotk), xgboost,
  ranger, glmnet, pls, nnet, themis, DALEX/ingredients/iml/fastshap/vip,
  torch/coro/luz/keras3/torchvision, brms/posterior/loo/bayesplot/cmdstanr
  (CmdStan 2.37.0), dbarts, DiceKriging, mlflow, pins, vetiver, plumber, arrow.
- Exercício runtime nesta campanha: o testthat congelado correu integralmente
  (incl. adapters tidymodels, DL/torch CPU, Bayes/GP/conformal, persistência,
  deployment, batch/resume) sem falhas; **certificação formal de backends não
  é reivindicada** — as linhas de `inst/metadata/FINAL_COMPATIBILITY_MATRIX_1.0.0.csv`
  permanecem declarações de fonte congelada.
- GPU/CUDA: **SKIP/UNAVAILABLE** (sem CUDA nesta máquina).
- ONNX: **QUARANTINED** (como no freeze; sem differential prediction executado).

## Documentation

- vignettes: **28/28 renderizadas** — `R CMD build` construiu `inst/doc/`
  (28 HTML + 28 .R + 28 .qmd) e o check reconstruiu todas
  (`re-building of vignette outputs ... OK`, 101 s)
- notebooks: 27 presentes (`inst/notebooks/jupyter/`); **27/27 EXECUTADOS**
  em kernels IR limpos após fix derivado #22 (asserção `0.9.0`→`1.0.0`);
  cópias executadas em `outputs/rendered-docs/notebooks/`; evidência
  `outputs/evidence/notebooks_execution_1.0.0.csv` (todos PASS, ~11–25 s cada)
- pkgdown: **PASS** — 28/28 artigos + home + reference (11 tópicos) + news +
  404; site em `docs/` (GitHub Pages, Deploy from branch → `/docs`);
  `outputs/evidence/pkgdown_articles_1.0.0.csv`
- workaround de harness documentado (Quarto CLI + path absoluto do tempdir;
  `DERIVED_PATCH_NOTES.md` §21)

## R CMD build/check

- built tarball: `outputs/built-tarballs/sciModelFlowR_1.0.0_derived.tar.gz`
- SHA-256: `B35A37D0E6F8FAE2DFF32DE838EBC3D860B40E69CB7CBB58F352CEC25172289B`
- check status: **0 ERROR, 0 WARNING, 2 NOTEs** (`--as-cran`)
- warnings: nenhum
- notes (revisados e aceites):
  1. *CRAN incoming feasibility* — New submission; Suggests fora de
     repositórios mainstream (`fastshap`, `vip`, `cmdstanr` — backends
     opcionais GitHub-only). A nota de “invalid URLs” desapareceu após o
     push: `https://github.com/wep69/sciModelFlowR` resolve (repo público).
  2. *Top-level files* — documentos de governança/release no topo
     (BIBLIOGRAPHY_VERIFICATION, COMPATIBILITY, DEPRECATION_POLICY,
     MIGRATION_*, RELEASE_*, SECURITY_REVIEW, SOURCE_MANIFEST, data-raw):
     artefactos intencionais do freeze 1.0.0.

## Publication

- Repositório: `https://github.com/wep69/sciModelFlowR` (público, branch `main`, 7 commits)
- GitHub Pages: `https://wep69.github.io/sciModelFlowR/` (Deploy from branch → `main` → `/docs`)
  — build `built` (30.8 s); home, `reference/index.html` e artigo v15 verificados HTTP 200
- Topics: r, r-package, statistics, machine-learning, reproducibility, bayesian,
  deep-learning, conformal-prediction, agronomy, scientific-computing
- Sem CI (workflows removidos, conforme pedido); Pages servido de `docs/`

## Final classification

**PASS (derived working copy `1.0.0+derived-fix`)** — com os seguintes
caveats obrigatórios:

- campanha histórica 0.1.0–0.9.0: `NOT RUN` (snapshots indisponíveis);
- GPU/CUDA: `SKIP/UNAVAILABLE`;
- ONNX: `QUARANTINED`;
- 2 NOTEs do check aceites formalmente acima;
- 22 fixes derivados documentados; correções em código científico exigem
  publicação como **1.0.1** (§29).
