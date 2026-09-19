# Validation record — sciModelFlowR 1.0.2 (patch release)

> Artefacto validado: **tarball 1.0.2** construído da derived working copy
> (source freeze 1.0.0 + 22 correções de 1.0.1 + 5 correções da auditoria do
> tutorial de 1.0.1, ver `NEWS.md` 1.0.2 e
> `tests/testthat/test-regressions-102.R`). O freeze 1.0.0 (ZIP/TAR.GZ,
> hashes, metadata) permanece intacto como referência histórica. Nenhuma
> classificação converte ausência de backend/hardware/snapshot em PASS.

## Source integrity

- Base freeze ZIP SHA-256: `9483b17fe2bec07c7cd4c66dd6db7e4e44f632ac48d2b9a0f2a7bd671e36bb6d` — VERIFIED
- Base freeze TAR.GZ SHA-256: `ef684ad7d511a31d5487a1366b6fe099488f1fe98dbe57fd26f707136b144c3e` — VERIFIED
- Correções derivadas: **22** (1.0.1, `DERIVED_PATCH_NOTES.md`) + **5**
  (1.0.2, auditoria do tutorial da 1.0.1; relatório ao autor em
  `RELATORIO-AO-AUTOR.md` do projeto do roteiro)
- API: 246 exports inalterados; `api_freeze` permanece `1.0.0`
  (`RELEASE_MANIFEST_1.0.2.json`: `api_changed_since_1_0_0 = false`)
- Tarball 1.0.2: `outputs/built-tarballs/sciModelFlowR_1.0.2.tar.gz`
  SHA-256 `46755FD7445A0120D5DE921FF84E9AEE1C83E3E6396714D839F6E1215163AE1C`
- `00check.log` SHA-256: `B7E116D58EDA7AA335AF692F33E191E0828367DC5BAD76AED2A2DA7319B9C0F8`
- Verified: **PASS**

## Environment

- Date: 2026-09-18 (America/Sao_Paulo)
- R: 4.6.0 (2026-04-24 ucrt), x86_64-w64-mingw32; gcc 14.3.0 (Rtools)
- OS: Windows 11 x64 (build 26200)
- CPU: Intel(R) Core(TM) i7-9700F @ 3.00GHz, 8 logical / 8 physical cores
- RAM: 31.9 GB · GPU: Radeon RX 570 (sem CUDA; `torch::cuda_is_available() == FALSE`)
- Quarto: 1.11.0 · Pandoc: 3.8.3 · RNGkind: Mersenne-Twister/Inversion/Rejection
- Biblioteca de validação: `D:/RLibrary/sciModelFlowR-1.0.2` (dedicada).
  A instalação padrão em `D:/RLibrary/sciModelFlowR` é propriedade de
  `BUILTIN\Administradores` e não pôde ser substituída sem elevação; o gates e
  os notebooks usaram `.libPaths` com a biblioteca dedicada à frente. A
  atualização da biblioteca principal exige um terminal elevado.

## Core runtime

- static audit 1.0.2 (`tools/static_validate_1.0.2.py`): **600/600 PASS**
  (`outputs/final-reports/STATIC_AUDIT_1.0.2.md`)
- testthat (fonte): 62 arquivos, **322 PASS / 0 FAIL / 0 ERROR / 1 SKIP**
  (`tests/testthat/test-regressions-102.R` acrescenta 6 blocos de regressão)
- testthat (instalado do tarball, dentro do check):
  `[ FAIL 0 | WARN 2 | SKIP 1 | PASS 322 ]`
  (`outputs/evidence/check102b/sciModelFlowR.Rcheck/tests/testthat.Rout`)
- Gates 1.0.2: `tools/validate_1.0.2.R` **PASS**
  (“Source/reference contract checks completed for 1.0.2.”) e
  `tools/validate_1.0.2_release.R` **PASS**
  (“Release metadata contract checks complete for 1.0.2.”)
- Evidência: `outputs/evidence/final_gates_1.0.2.log`,
  `outputs/evidence/release_gate_1.0.2.log`

## Numerical/reference

- status: **PASS** — tolerâncias verificadas pelos gates de referência
  (`smf_run_reference_validation()`; ~1e-15) e cross-language 25/25

## Gold

- hashes: 25/25 **PASS** (`smf_run_gold_validation()`)
- known truth: verificado pela suíte congelada
- regeneração: não executada (fixtures congelados)

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
- notebooks: **27/27** executados em kernels IR limpos contra o 1.0.2 instalado
  (`outputs/evidence/notebooks_execution_1.0.2.csv`; cópias executadas em
  `outputs/rendered-docs/notebooks/`)
- pkgdown: **28/28 artigos**, site completo em `docs/` com versão 1.0.2
  (home, reference, news, sitemap; `outputs/evidence/pkgdown_site_1.0.2.log`).
  O build usou o harness `tools/pkgdown_build_1.0.2.R` (workaround documentado
  do bug de path absoluto pkgdown 2.2.1 + Quarto 1.11.0 no Windows,
  `DERIVED_PATCH_NOTES.md` item 21); a primeira tentativa direta está
  preservada em `outputs/evidence/pkgdown_articles_1.0.2.log`.

## R CMD build/check

- built tarball: `outputs/built-tarballs/sciModelFlowR_1.0.2.tar.gz`
- SHA-256: `46755FD7445A0120D5DE921FF84E9AEE1C83E3E6396714D839F6E1215163AE1C`
- check status (`--as-cran`): **0 ERROR / 0 WARNING / 2 NOTEs**
  (`outputs/evidence/check102b/sciModelFlowR.Rcheck/00check.log`). A primeira
  execução foi abortada por um lock transiente do Windows (`00LOCK` residual,
  3º NOTE de harness); a re-execução limpa é a oficial.
- NOTEs (revisadas e aceites): (1) CRAN incoming feasibility — New submission;
  Suggests fora de repositórios mainstream (`fastshap`, `vip`, `cmdstanr`);
  (2) top-level files — documentos de governança/release intencionais
  (`BIBLIOGRAPHY_VERIFICATION`, `COMPATIBILITY`, `DEPRECATION_POLICY`,
  `MIGRATION_*`, `RELEASE_*`, `SECURITY_REVIEW`, `SOURCE_MANIFEST`, `data-raw`).

## Publication

- Repositório: `https://github.com/wep69/sciModelFlowR` (público)
- GitHub Pages: `https://wep69.github.io/sciModelFlowR/` (`main` → `/docs`)
- Tags: `v1.0.0` (freeze histórico), `v1.0.1`, `v1.0.2` (este patch)
- GitHub Release `v1.0.2` com o tarball anexado

## Final classification

**PASS (patch release 1.0.2)** — caveats obrigatórios:

- campanha histórica 0.1.0–0.9.0: `NOT RUN` (snapshots indisponíveis);
- GPU/CUDA: `SKIP/UNAVAILABLE`; ONNX: `QUARANTINED`;
- 2 NOTEs do check aceites formalmente;
- pacote **não** declarado CRAN-ready;
- biblioteca padrão `D:/RLibrary/sciModelFlowR` ainda contém 1.0.1 (instalação
  admin); a validação de 1.0.2 usou a biblioteca dedicada
  `D:/RLibrary/sciModelFlowR-1.0.2`.
