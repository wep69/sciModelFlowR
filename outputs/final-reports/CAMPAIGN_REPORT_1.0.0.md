# sciModelFlowR — Consolidated local validation campaign report

**Artefacto:** source freeze 1.0.0 + derived working copy `1.0.0+derived-fix`
**Repo:** `D:\Walter\R\Pacotes_criados\sciModelFlowR\repo` (git, sem CI, GitHub Pages via `/docs`)
**Data:** 2026-09-18 · **Máquina:** Windows 11 x64, R 4.6.0, Quarto 1.11.0, 8 cores, 32 GB, sem CUDA

---

## 1. O que foi entregue

| Entregável | Local | Estado |
|---|---|---|
| Repositório publicado no GitHub | `https://github.com/wep69/sciModelFlowR` (público, branch `main`, 7 commits) | PASS |
| Snapshot congelado preservado | ZIP/TAR.GZ originais intactos em `D:\Walter\R\Pacotes_criados\sciModelFlowR\` (hashes §2) | PASS |
| Tarball derivado construído | `repo/outputs/built-tarballs/sciModelFlowR_1.0.0_derived.tar.gz` (`B35A37D0…`) | PASS |
| GitHub Pages | `https://wep69.github.io/sciModelFlowR/` (branch `main` → `/docs`; build `built`) | PASS |
| `R CMD check --as-cran` | 0 ERROR / 0 WARNING / 2 NOTEs aceites | PASS |
| testthat | 61 arquivos, 299 PASS / 0 FAIL (fonte) · 0 falhas (instalado) | PASS |
| Gold + reference + crosslang | 25/25 + tolerâncias ~1e-15 + 25/25 | PASS |
| Vinhetas | 28/28 em `inst/doc` (check rebuild OK) | PASS |
| Notebooks (27, IRkernel) | 27/27 executados em kernel limpo (fix derivado #22) | PASS |
| pkgdown / GitHub Pages | `docs/` completo (28 artigos) | PASS |
| Fixes derivados documentados | `DERIVED_PATCH_NOTES.md` (22 itens) | PASS |
| Registro de validação (§27) | `outputs/final-reports/VALIDATION_RECORD_1.0.0.md` | PASS |

## 2. Evidência (índice)

```
outputs/evidence/
├── 00check_1.0.0.log              # R CMD check --as-cran (2 NOTEs)
├── 00install_1.0.0.out            # install do tarball em check
├── build_1.0.0.log                # build --no-build-vignettes (histórico)
├── build_full_1.0.0.log           # build COM vignettes (28 HTML em inst/doc)
├── check_console_1.0.0.log        # stdout do check
├── document_1.0.0.log             # devtools::document() (roxygen 8.1.0)
├── final_gates_1.0.0.log          # gates A–G no tarball instalado (biblioteca limpa)
├── smoke_1.0.0.log                # smoke 1.0.0 (API/Gold/ref/crosslang/audit)
├── static_1.0.0.log               # static_validate_1.0.0.py: 599/599
├── static_090.log                 # validator legado 0.9.0 (esperado FAIL no source 1.0.0)
├── static_legacy_080.log          # validator legado 0.8.0 (esperado FAIL no source 1.0.0)
├── testthat_1.0.0_full2.log       # devtools::test completo
├── testthat_1.0.0_results2.csv    # resultados por arquivo
├── testthat_check.Rout.fail       # testthat durante check (pré-fixes, histórico)
├── pkgdown_articles_1.0.0.csv     # 28/28 artigos PASS
└── pkgdown_articles_1.0.0.log     # log de render dos artigos

outputs/validation-records/
├── *.frozen_orig                  # originais pré-fix (23 arquivos) + hashes
├── vignettes_qmd_frozen_sha256.csv
└── LICENSE.frozen_orig

outputs/final-reports/
├── VALIDATION_RECORD_1.0.0.md     # template §27 preenchido
└── CAMPAIGN_REPORT_1.0.0.md       # este relatório
```

## 3. Fixes derivados (resumo por impacto)

| # | Item | Classe | Efeito |
|---|---|---|---|
| 1 | `R/resampling.R` `repeat=` sem backticks | load-blocker | pacote não carregava |
| 2 | `R/bayesian-adapters.R` métodos S7 fora de ordem | load-blocker | `load_all`/install abortava |
| 3 | `R/release-candidate.R` reference gate com escopo errado | scientific FAIL | `passed=FALSE` determinístico |
| 4 | `R/provenance.R` `si[["model"]]` | runtime blocker | 6 erros; manifests quebravam |
| 5 | `R/calibration.R` isotonic fora de ordem + linha zero | scientific FAIL | fora do simplex |
| 6 | `R/core-serialization.R` `[]` JSON → lista | round-trip blocker | DL/Explain specs |
| 7 | 2 testes com `\n` literais | harness | parse abortava |
| 8 | 2 testes com constantes 0.9.0 | stale constants | FAIL no source 1.0.0 |
| 9 | `R/model-adapters.R` alias `"linear"` | capability blocker | 5 erros |
| 10 | 2 testes Gold (12 vs 25; `table`) | stale/strictness | FAIL |
| 11 | `R/tuning-core.R` racing archive heterogéneo | rbind blocker | racing nunca arquivava |
| 12 | 3 testes (tipos `anyDuplicated`/`dimnames`) | strictness | FAIL |
| 13 | `man/` 246 páginas geradas vs tópicos | check WARNINGs | 3 classes de WARNING |
| 14 | `inst/gold/` → `inst/gold_data/` | **build/packaging blocker** | `R CMD build` descarta dirs `*old` — tarball perdia Gold inteiro |
| 15 | `STATIC_AUDIT.md` reescrito por validators legados | harness | conteúdo 0.9.0; revertido |
| 16 | `man/smf_explain_api.Rd` ilegível | build blocker | `R CMD build` abortava |
| 17–18 | 2 validators 1.0.0 com `\n` literais | harness | parse abortava |
| 19 | `torch::nn_lazy_linear` inexistente; `:::`; tibble/vctrs | check WARNINGs | codoc/namespace |
| 20 | 28 vinhetas sem metadados + engine errado | check WARNING | 0 inst/doc → 28 HTML |
| 21 | Quarto CLI + tempdir path absoluto (pkgdown) | harness docs | 28 artigos renderizados |
| 22 | 27 notebooks com asserção `0.9.0` | stale constants | execução falharia; 27/27 PASS após fix |

Originais pré-fix preservados em `outputs/validation-records/*.frozen_orig`;
hashes no próprio arquivo `DERIVED_PATCH_NOTES.md`.

## 4. Classificações finais por gate (protocolo §8/§27)

| Gate | Classificação | Evidência |
|---|---|---|
| Source integrity (ZIP/TAR.GZ) | **PASS** | hashes §2 do protocolo |
| Core runtime (load/install/testthat) | **PASS** | `testthat_1.0.0_full2.log`, `final_gates` |
| Numerical/reference | **PASS** | erros ≤ 7.2e-15 |
| Gold (25) | **PASS** | `smoke_1.0.0.log` |
| Cross-language (25 fixtures) | **PASS** | idem |
| API freeze 246 | **PASS** | `smf_api_catalog()`, gates §18.3/§18.4 |
| RC audit | **PASS** (`certification-ready` com `runtime_certified=TRUE`) | `final_gates` |
| `R CMD build` + check | **PASS** (0E/0W/2N aceites) | `00check_1.0.0.log` |
| Vinhetas | **PASS** (28/28) | `build_full_1.0.0.log` |
| Notebooks (27) | **PASS** (27/27 em kernel IR limpo) | `notebooks_execution_1.0.0.csv` |
| pkgdown | **PASS** (28/28) | `pkgdown_articles_1.0.0.csv` |
| Campanha histórica 0.1–0.9 | **NOT RUN** (snapshots ausentes) | — |
| GPU/CUDA | **SKIP/UNAVAILABLE** | sem CUDA |
| ONNX | **QUARANTINED** | como no freeze |

## 5. Próximos passos recomendados

1. **Repositório publicado** — ✅ `https://github.com/wep69/sciModelFlowR`
   (público; Pages ativo em `https://wep69.github.io/sciModelFlowR/`).
   O owner `walterufpb` não existe no GitHub; URLs do pacote apontam para `wep69`.
2. **Publicar 1.0.1** com os 22 fixes derivados (§29: correção em código
   científico exige nova versão), preservando o freeze 1.0.0 como histórico.
3. **Campanha histórica** 0.1.0–0.9.0 nos snapshots próprios (Fases B–D do §25)
   quando os ZIP/TAR.GZ históricos estiverem disponíveis.
4. **Notebooks** — ✅ executados nesta campanha (27/27); manter o fix #22
   (asserção 1.0.0) e as cópias executadas em `outputs/rendered-docs/notebooks/`.
5. Re-render pkgdown em ambiente limpo sem o workaround de path (se pkgdown
   ou Quarto corrigirem o bug), ou manter o script de patch documentado.
