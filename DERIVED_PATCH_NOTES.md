# Derived patch notes — working copy vs frozen 1.0.0 source

Os artefactos congelados **não foram modificados**:

- `sciModelFlowR_1.0.0-source-snapshot.zip`
  SHA-256 `9483b17fe2bec07c7cd4c66dd6db7e4e44f632ac48d2b9a0f2a7bd671e36bb6d` — VERIFIED
- `sciModelFlowR_1.0.0-source-snapshot.tar.gz`
  SHA-256 `ef684ad7d511a31d5487a1366b6fe099488f1fe98dbe57fd26f707136b144c3e` — VERIFIED

Este repositório é uma **cópia de trabalho derivada** (`1.0.0+derived-fix`)
com três desvios documentados em relação ao freeze. Originais preservados em
`outputs/validation-records/` e diffs arquivados no relatório de validação.

## 1. `R/resampling.R` linha 124 — reserved word `repeat` (load-blocker)

- **Estado no freeze:** `summary=list(repeat=r, fold=j, v=v, strata=strata)`
  falha em `parse()` (`'=' inesperado`, `repeat` é palavra reservada do R).
  Consequência: o pacote **não carrega nem instala** a partir do freeze
  1.0.0 tal como distribuído — classificação `FAIL — source parse`.
- **Derivado nesta cópia:** `` summary=list(`repeat`=r, fold=j, v=v, strata=strata) ``
  (backtick-quote; nome do elemento `"repeat"` preservado, semântica idêntica).
- **Proveniência:**
  - `outputs/validation-records/resampling.R.frozen_orig`
    SHA-256 `8050FF1F36884EA25FF87EBDBC7DE573305A254B68B006BA5B49AD18C4C59563`
  - `R/resampling.R` (patched)
    SHA-256 `05507F2F4BBD7D556F696A54EA7835AE06E246D18FECDEEB60CA05CE1079E5D2`
- **Política (§29 do protocolo):** correção em código científico exige nova
  versão do pacote. Recomendação: publicar este fix como **1.0.1** (ou
  1.0.0-patch1) após a campanha; até lá, nenhum artefacto 1.0.0 deve ser
  descrito como instalável sem este registo.

## 2. `R/bayesian-adapters.R` → `R/bayesian-core.R` — S7 method order (load-blocker)

- **Estado no freeze:** `R/bayesian-adapters.R` (linhas 83–84) regista
  `S7::method(print, GPFitResult)` e `S7::method(print, BARTFitResult)`, mas
  ambas as classes são definidas em `R/bayesian-core.R`, que é sourced
  depois (ordem alfabética, sem campo `Collate` no DESCRIPTION).
  `devtools::load_all()` aborta com `objeto 'GPFitResult' não encontrado`;
  `R CMD INSTALL` falharia da mesma forma — classificação
  `FAIL — source load`.
- **Derivado nesta cópia:** as duas linhas (idênticas, byte-por-byte) foram
  movidas para o fim de `R/bayesian-core.R`, junto aos métodos `print`
  siblings (`BayesFitResult`, `BayesianDiagnosticResult`). Semântica idêntica,
  footprint mínimo (sem `Collate`, sem renomeações).
- **Proveniência:**
  - `outputs/validation-records/bayesian-adapters.R.frozen_orig`
    SHA-256 `D995D92D34BEAAD47E291DDD1A580BA79EA5182D24459EA01102F7E00F0E6431`
  - `outputs/validation-records/bayesian-core.R.frozen_orig`
    SHA-256 `71A74286615BC1560171E8BD84D50BBB948A3B6A19248421FA367E3DCFC81B0C`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.

## 3. `R/release-candidate.R` — reference gate com escopo errado (scientific FAIL)

- **Estado no freeze:** `smf_run_reference_validation()` ajusta
  `stats::lm(yield ~ nitrogen + rainfall + soil_n)` nas **240 linhas**
  (train + test) e avalia nas 240 linhas, mas compara com o fixture
  `inst/crosslang/expected/gold_linear_reference.json`, que foi gerado por
  OLS nas **train rows LR001–LR192** com rmse/mae avaliados nas **test rows
  LR193–LR240** (`inst/crosslang/splits/gold_linear_holdout_v1.json`,
  seed 260915). Resultado determinístico: `passed = FALSE`
  (`coefficient_max_abs_error ≈ 1.05`, `metric_max_abs_error ≈ 0.16`).
  Evidência: OLS-train reproduz os coeficientes do fixture a `7.1e-15` e as
  métricas de teste exatamente; o ajuste full-data não.
- **Derivado nesta cópia:** o gate lê o split fixture, ajusta no train e
  avalia no test — espelhando o fixture e a doutrina anti-leakage do próprio
  pacote (o comportamento congelado *vazava* test rows para a estimação).
  Defaults de tolerância inalterados.
- **Proveniência:**
  - `outputs/validation-records/release-candidate.R.frozen_orig`
    SHA-256 `E2664B46A9AC33AD9AA07C0B784AC3F9D59BA9880D5C2621C07B9B9F186FC56D`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.

## 4. `tools/validate_1.0.0.R` — harness de linha única

- **Estado no freeze:** 1 linha com `\n` literais entre comandos (não faz parse).
  Original em `outputs/validation-records/validate_1.0.0.R.frozen_orig`
  (SHA-256 `E0186E0CF83337D43E08462F8D0CBD94946255E4F0482BD819A0E35A6B78CA15`).
- **Derivado:** comandos equivalentes §18.3 em linhas reais; `audit@n_exports`
  (slot S7) preservado como no original. Detalhes em
  `tools/VALIDATION_HARNESS_WORKAROUND.md`.
  SHA-256 `4A5D744B97D45831B0DBB84DC54A6B0D5DE31BA42DA98746A378C57A3EB2`.

## 5. `tools/validate_1.0.0_release.R` — harness de linha única

- **Estado no freeze:** idem; original em
  `outputs/validation-records/validate_1.0.0_release.R.frozen_orig`
  (SHA-256 `26172422A910E0390B572FD63A431BEB746A0C6C2D30441EEA32B86EFD748553`).
- **Derivado:** gate §18.4 em linhas reais.
  SHA-256 `4BF01F4F3D23860C72498E67678A39C4B6639382232257A4F3FC9FAB1E099D8E`.

## GitHub repo adaptations (não científicas)

- Removido `.github/workflows/R-CMD-check.yaml` (**sem CI**, por pedido).
- `_pkgdown.yml`: `destination: docs` para GitHub Pages (Deploy from branch → `/docs`); `docs/.nojekyll` incluído.
- Outputs organizados em subfolders: `outputs/{evidence,rendered-docs,built-tarballs,final-reports,validation-records}` (+ `.gitkeep`).
- `.gitignore` para artefactos R/pkgdown/outputs pesados.
