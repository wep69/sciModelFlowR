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

## 4. `R/provenance.R` — `si[["model"]]` inexistente (runtime blocker)

- **Estado no freeze:** `.smf_hardware_info()` lê `si[["model"]]` de
  `Sys.info()`, que não tem esse elemento em nenhuma plataforma
  (`[[` em vetor atómico dispara `subscript out of bounds`). Todo o caminho
  que constrói `RunManifest` abortava: batch/resume, calibration, deployment,
  experimentos — 6 erros em `testthat`.
- **Derivado:** helper `.smf_cpu_model()` — usa `model` se existir, senão
  `PROCESSOR_IDENTIFIER` (Windows), senão `machine`.
- **Proveniência:**
  - `outputs/validation-records/provenance.R.frozen_orig`
    SHA-256 `5632B45E108221D2AFBFBB5725A68BA096B9EE01F066BA1F20913B34D4A610FB`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.

## 5. `R/calibration.R` — isotonic em `x` não ordenado + linha degenerada

- **Estado no freeze:** `smf_calibrate(..., "isotonic")` chama
  `stats::isoreg(prob[, cl], ...)` com scores fora de ordem; o PAVA corre na
  ordem de entrada e o ajuste é lixo (ex.: `yf = 0,0,0,0,1,1` desalinhados),
  produzindo linhas calibradas todas-zero; o guarda `rs[rs==0]<-1` emitia uma
  linha `0` — fora do simplex (`FAIL` em
  `test-calibration-030.R:28`, desvio `1`).
- **Derivado:** ordena por score antes do `isoreg`; linha degenerada recai na
  linha de entrada (simplex validado) e, em último caso, uniforme `1/K`.
- **Proveniência:**
  - `outputs/validation-records/calibration.R.frozen_orig`
    SHA-256 `3CC05A2B5A658D0B695BB99035C52E6A5AB3576295FA2DAD656D558F533850BD`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.

## 6. `R/core-serialization.R` — `[]` JSON vira lista vazia (round-trip blocker)

- **Estado no freeze:** `smf_to_json()` serializa `character()` como `[]`;
  `smf_from_json()` devolve lista vazia e o S7 rejeita
  (`@layer must be <character>, not <list>`). Quebrava round-trip de
  `DLGradientExplanation` (`test-dl-xai-060.R:4`) e `ExplainSpec`
  (`test-explain-050.R:3`) — qualquer propriedade atómica vazia.
- **Derivado:** `.smf_empty_for_class()` + coerção em `smf_from_list()` via
  introspecção `ctor@properties[[nm]]$class` (character/numeric/integer/
  logical; `class_any` já aceitava lista). Cobre JSON e YAML.
- **Proveniência:**
  - `outputs/validation-records/core-serialization.R.frozen_orig`
    SHA-256 `06C6912E05C5CA80866EED9C19477D2D823F5B171F3C1B48F57BD3CA59B48644`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.
- **Observação (não alterada):** `.smf_class_map()` não lista
  `ExternalValidationResult`/`ReportingResult`/`ReleaseCandidateAudit` —
  `smf_from_json()` desses aborta `Unknown serialized class`. Gap de cobertura
  registado para 1.0.1; nenhum gate/teste atual o exercita.

## 7. `tests/testthat/test-release-100-contract.R` + `test-security-100-contract.R` — harness de linha única

- **Estado no freeze:** múltiplos blocos `test_that()` separados por `\n`
  literais — `parse()` aborta (`unexpected symbol`). Mesma classe de defeito
  dos validators 1.0.0.
- **Derivado:** transcrição fiel com linhas reais (semântica idêntica;
  `collapse="\n"` preservado dentro da string).
- **Proveniência:**
  - `outputs/validation-records/test-release-100-contract.R.frozen_orig`
    SHA-256 `C822E9693A7411272FDAEFB384CD1328DC324960F2C42E17FC7E00AB84D876F3`
  - `outputs/validation-records/test-security-100-contract.R.frozen_orig`
    SHA-256 `CDC632273D5EF662AB1FDB2E8E902D99D98993850C35DE6D76B0B6D4D512941F`
- **Política (§29):** correção de harness/teste, mantida como derivado com
  hash próprio (não exige nova versão científica, mas exige rerun — feito).

## 8. `tests/testthat/test-090-api-freeze.R` + `test-090-release-candidate.R` — constantes 0.9.0 obsoletas

- **Estado no freeze:** os testes exigem `api_freeze == "0.9.0"` e
  `release_status %in% c("pending-final-runtime",
  "quarantined-pending-local-validation")`, mas os metadados 1.0.0 congelados
  usam `api_freeze == "1.0.0"` (`status stable_1x`, 246 linhas) e
  `release_status == "pending-final-local-certification"` (14 linhas) —
  vocabulário evoluído de forma consistente (cf. `BACKEND_MATRIX_0.9.0.csv`
  vs `BACKEND_MATRIX_1.0.0.csv`).
- **Derivado:** expectativas alinhadas ao vocabulário 1.0.0 congelado, com
  igualdade estrita (`==`, sem enfraquecimento).
- **Proveniência:**
  - `outputs/validation-records/test-090-api-freeze.R.frozen_orig`
    SHA-256 `739D872178820E52827CC2D3ABEA7CD8C2965CE699DD63A6E3C170A28A241AED`
  - `outputs/validation-records/test-090-release-candidate.R.frozen_orig`
    SHA-256 `208EA8BDF0C42A4696341199D9875EA02175E59A17BBD88A941EC2AFE2944255`

## 9. `R/model-adapters.R` — alias `"linear"` rejeitado (capability blocker)

- **Estado no freeze:** `.smf_stats_fit()` aceita apenas
  `c("linear_regression","lm")`, mas `"linear"` é o alias usado no próprio
  `tools/validate_0.5.0.R`, em 2 vinhetas (v05, v10) e em 5 call sites de
  teste 050 — todos abortavam `STATS_MODEL_UNSUPPORTED task=regression
  family=linear` (5 erros em `testthat`).
- **Derivado:** `"linear"` admitido como alias no stats adapter e no mapeamento
  parsnip (`linear=, linear_regression=` + engine `"lm"`). Sem mudança para
  famílias existentes.
- **Proveniência:**
  - `outputs/validation-records/model-adapters.R.frozen_orig`
    SHA-256 `D731BF6C7AE4939A61B5C688BE9FD4B717CCFF30EBA14AB8FE96763F6B473503`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.

## 10. `tests/testthat/test-gold.R` + `test-gold-070.R` — constantes obsoletas/strictness

- **Estado no freeze:** `expect_length(smf_list_datasets(),12)` contra 25
  datasets congelados; `expect_equal(table(c$partition),
  c(calibration=500,test=1200,train=500))` falha por atributos
  (dim/dimnames de `table`) embora as contagens estejam exatas
  (500/1200/500 verificadas no CSV).
- **Derivado:** `12`→`25` (+rótulo); comparação por contagens ordenadas
  `unname(tb[c(...)])`, igualmente estrita.
- **Proveniência:** originais em
  `outputs/validation-records/test-gold.R.frozen_orig` e
  `test-gold-070.R.frozen_orig`.
  (`unname()` não remove `dim` de `table`; versão final usa `as.vector()`.)

## 11. `R/tuning-core.R` — schema heterogéneo no archive de racing (rbind blocker)

- **Estado no freeze:** `.smf_tune_racing()` monta linhas per-fold com extra
  `list(stage, status)` e linhas agregadas com `list(n_folds, status)`; o
  `do.call(rbind, ...)` final aborta `names do not match previous names`
  (`FAIL` em `test-optimizers-040.R:14` — racing nunca produzia archive).
- **Derivado:** schema único `list(stage, n_folds, status)` — per-fold com
  `n_folds=1L`, agregadas com `stage=NA_integer_`. Nenhum consumidor
  downstream usa `stage` (só `nrow` + colunas de objetivos).
- **Proveniência:**
  - `outputs/validation-records/tuning-core.R.frozen_orig`
    SHA-256 `C2BA5217BB81E03C820CCF90A3AD3B9FCE3EB87832AC731F925F4D2765612186`
- **Política (§29):** idem fix 1 — recomenda-se publicar como **1.0.1**.

## 12. Strictness de tipos em 3 testes (sem mudança científica)

- `test-pareto-040.R:5`: `expect_false(anyDuplicated(p$id))` — base R devolve
  `0L`, não `FALSE` → `expect_identical(anyDuplicated(p$id), 0L)` (orig.
  `.../test-pareto-040.R.frozen_orig`
  SHA-256 `1A3F9F6FE3C3C9340C21F926E96EF5C9DC781878DF332C7B81D0B7A295238E34`).
- `test-probabilistic-030.R:7`: `smf_dist_interval()` rotula colunas
  lower/upper por design; o teste comparava com a matriz sem rótulos —
  valores via `as.vector()` + `colnames()` asserido separadamente (orig.
  `.../test-probabilistic-030.R.frozen_orig`
  SHA-256 `BB7BDABE763F444389EFC77696B1F0315340C41D6B479D15990BB9276C0FFF0B`).
- Intenção de cada asserção preservada; apenas alinhamento de tipos.

## 13. `man/`: páginas por tópico, não por função (+ regra dev)

- **Contexto:** o freeze traz 11 tópicos que, via `\alias`, cobrem os 246
  exports (verificado: 0 faltas). `devtools::document()` (roxygen2 8.1.0)
  gerou 246 páginas esqueléticas por função (sem `@param` nos fontes) que
  duplicam todos os aliases → 3 classes de WARNING no check (Rd metadata,
  Rd usage, HTML anchors).
- **Derivado:** removidas as 246 páginas geradas (mais `smf_explain_api.Rd`,
  detalhado em item próprio abaixo — duplicata quebrada cujos 13 aliases já
  vivem em `additional-api-070.Rd`); `man/` volta aos 10 tópicos congelados.
  Removidos ainda os blocos `\usage{}` ilustrativos de
  `external-validation-090.Rd`, `smf_core_api.Rd` e
  `tracking-persistence-080.Rd` (assinaturas sem `\arguments` correspondente;
  o conteúdo científico vive nas vinhetas + freeze de API). Exemplos
  `\dontrun` preservados.
- **Regra dev (obrigatória):** NÃO executar `devtools::document()` cheio —
  ele recria as 246 páginas e reintroduz os WARNINGs. Para sincronizar
  apenas NAMESPACE no futuro:
  `roxygen2::roxygenise(roclets = "namespace")`. DESCRIPTION teve o churn
  `RoxygenNote→Config/roxygen2/version` revertido (mantida só a moção
  tibble/vctrs Imports→Suggests).

## 14. `inst/gold/` → `inst/gold_data/` (build/packaging blocker crítico)

- **Causa raiz (verificada no R 4.6.0 instalado):** `R CMD build` exclui
  diretórios cujo basename casa `grepl("([Oo]ld|\\.Rcheck)$", bases)`
  (`tools:::.build_packages`, convenção de diretórios backup) — `gold`
  termina em `old`. Prova: pacote mínimo com `inst/{mydata,gold,extdata,
  golden,...}/x.csv` perde exatamente os ramos `*gold`; `golden` sobrevive;
  `tools:::inRbuildignore()` com/sem `.Rbuildignore` não exclui nada.
- **Impacto no freeze:** o tarball 1.0.0 construído do freeze perde
  `inst/gold/` (cards, `gold_hashes.csv`, `known_truth.json`, manifest),
  `inst/extdata/gold/` (25 CSVs) e `inst/crosslang/gold/`
  (`gold_suite_manifest_v1.json`) — 133 entradas em vez do completo. O pacote
  instalado ficaria sem `smf_load_dataset()`, Gold, reference e parte do
  crosslang; `R CMD check` falharia em massa. Ou seja: sem rename, o tarball
  **não distribui a funcionalidade central anunciada**.
- **Derivado:** `inst/gold/`→`inst/gold_data/`,
  `inst/extdata/gold/`→`inst/extdata/gold_data/`,
  `inst/crosslang/gold/`→`inst/crosslang/gold_data/` (`git mv`, conteúdo e
  hashes de ficheiros intactos) + atualização dos caminhos em
  `R/datasets.R`, `R/validation-gold.R`, `tools/static_validate_1.0.0.py`,
  `data-raw/generate-gold-xai-stability.R`,
  `data-raw/generate-gold-bayes-conformal.py`, `data-raw/README.md`.
  Nomes de datasets (`gold_*`), hashes e conteúdo: inalterados.
- **Congelados preservados:** layout original só existe nos ZIP/TAR.GZ +
  `SOURCE_MANIFEST_SHA256.txt` (registo histórico, não editado).
- **Política (§29):** mudança com efeito em paths instalados — exige **1.0.1**.

## 15. Aviso: validadores estáticos reescrevem `STATIC_AUDIT.md`

- `tools/static_validate_1.0.0.py` (linhas 82–93) e
  `tools/static_validate_0.9.0.py` (linhas 83–88) escrevem `STATIC_AUDIT.md`
  in-tree como efeito colateral. O run 1.0.0 regenera conteúdo idêntico ao
  congelado (verificado: 31879 chars, igual modulo line-endings); o run
  legado 0.9.0 **sobrescreveu** com conteúdo 0.9.0 — revertido via git
  (byte-idêntico ao freeze). **Não executar validadores legados na árvore de
  trabalho**; validação histórica exige os snapshots próprios (§8, §29).

## 16. `man/smf_explain_api.Rd` — tópico redundante e ilegível (build blocker)

- **Estado no freeze:** 1 linha com `\n` literais (mesma classe de defeito do
  harness) + `title{...}` sem barra invertida → `R CMD build` aborta
  (`Sections \title and \name must exist`). O ficheiro não é gerado pelo
  roxygen (246 páginas geradas cobrem os 13 aliases — verificado).
- **Derivado:** removido; original em
  `outputs/validation-records/smf_explain_api.Rd.frozen_orig`
  (SHA-256 `FCF89E6814F500DEA16C4F278E55121A194A7B35B34823F2EC04035DD78C3B02`).
- **Política (§29):** correção de docs/harness, mantida como derivado.

## 19. `R/deep-learning-train.R`, `R/scalability.R`, `DESCRIPTION` (check WARNINGs)

- `torch::nn_lazy_linear` não existe no torch R (0.17.0 instalado; nem
  interno): guarda runtime via `utils::getFromNamespace()` + erro de
  capacidade explícito `TORCH_LAZY_UNSUPPORTED` (orig.
  `outputs/validation-records/deep-learning-train.R.frozen_orig`
  SHA-256 `658C66D8CF123EF5BC6C45CE01050A6553E4CD50687BBEDD99B05808C3D5BB0F`).
- `sciModelFlowR:::.smf_predict_any` em worker paralelo → chamada nua
  (o closure já carrega o namespace; igual à `worker_fun` vizinha) (orig.
  `outputs/validation-records/scalability.R.frozen_orig`
  SHA-256 `86FC3987610C5860E59C5635D19C7FBB51AE783E1A7E8B1FE63332A611EF9DB2`).
- `tibble`/`vctrs` sem uso em `R/` e sem `importFrom` no NAMESPACE:
  Imports→Suggests (orig. `outputs/validation-records/DESCRIPTION.frozen_orig`
  SHA-256 `816D3A2EA606B412676E84332E92695C6DE3DBDD802F3945F5DB018B68E9AB34`).
- **Política (§29):** guarda de capacidade + metadados → 1.0.1; o `:::` nu é
  equivalência comprovada pelo padrão vizinho.
- **Adenda check (2ª rodada):** `stats`/`utils` estavam no Imports mas sem
  diretiva `import()` no NAMESPACE (que só tinha `export`s) → codoc seguia
  cego. Acrescentado `#' @import utils stats` em
  `R/sciModelFlowR-package.R` + `import(stats)`/`import(utils)` no NAMESPACE
  (verificado com pacote mínimo: Imports sem import() NÃO silencia; com
  import() silencia). `LICENSE` reduzido ao stub DCF de 2 linhas
  (texto BSD-3 integral preservado em
  `outputs/validation-records/LICENSE.frozen_orig`, SHA-256
  `9E8F1B8DF8BA309B019F81999FD58D637E5D427AA4DD0BB31B1EBA59B993049F`;
  BSD_3_clause é licença-padrão do R) + `License: BSD_3_clause + file
  LICENSE` restaurado (elimina os NOTEs de DESCRIPTION). `self` (NSE do
  `torch::nn_module`) declarado via `utils::globalVariables()` em `R/zzz.R`.

## 20. `vignettes/*.qmd` — metadados de vignette em falta + engine errado (WARNING)

- **Estado no freeze:** os 28 `.qmd` não tinham bloco `vignette:` com
  `%\VignetteEngine{}` (e 3 tinham engine incompatível: `knitr::rmarkdown`,
  `knitr::knitr` — patterns de knitr não cobrem `.qmd`, verificado via
  `tools::vignetteEngine()`). Com `VignetteBuilder: knitr` (congelado), o
  `R CMD build` **não construía nenhum vignette** (0 entradas `inst/doc`),
  produzindo `WARNING: Files in 'vignettes' but no files in 'inst/doc'` e
  NOTE "no prebuilt vignette index" no check.
- **Derivado:** adicionado `vignette: >` com `%\VignetteIndexEntry{<título>}`
  + `%\VignetteEngine{quarto::html}` + `%\VignetteEncoding{UTF-8}` aos 28
  qmds (títulos preservados; 3 engines normalizados) e
  `VignetteBuilder: quarto` (o pacote `quarto` registra o engine
  `quarto::html`; `quarto` já estava em Suggests).
- **Resultado (verificado):** `R CMD build` passa a construir
  `inst/doc/` com **28 HTML + 28 .R + 28 .qmd** (62 entradas); o check
  re-constroi todos os vignettes (`re-building of vignette outputs ... OK`,
  101 s). Hashes congelados dos 28 qmds em
  `outputs/validation-records/vignettes_qmd_frozen_sha256.csv`.
- **Política (§29):** metadados de release engineering → 1.0.1.

## 21. pkgdown + Quarto no Windows — bug de path absoluto (harness de docs)

- **Sintoma:** `pkgdown::build_article()` abortava com
  `os error 123: stat 'D:\...\vignettes\C:\Users\...\pkgdown-quarto-<id>'`
  (pkgdown 2.2.1 + Quarto 1.11.0): o `quarto_render()` interno passa
  `--output-dir` com path absoluto do `tempdir()` e o Quarto CLI junta-o ao
  diretório do input.
- **Workaround usado (derivado de harness, fora do package):**
  `TMPDIR=D:\smf_tmp` + patch em sessão de `pkgdown:::quarto_render` que
  (a) absolutiza o input e (b) passa `--output-dir` **relativo** ao dir do
  input. Script em `outputs/evidence/` logs; nenhum ficheiro do pacote foi
  alterado por esse motivo.
- **Resultado:** 28/28 artigos renderizados
  (`outputs/evidence/pkgdown_articles_1.0.0.csv`), site completo em `docs/`
  (home, reference 11 tópicos, 28 artigos, news, 404, `.nojekyll`).
- **Política (§29):** workaround de harness documentado; sem impacto no
  código científico. Rerun em ambiente limpo recomendado para certificação
  pkgdown definitiva.

## 22. `inst/notebooks/jupyter/*.ipynb` — asserção de versão 0.9.0 obsoleta (27 notebooks)

- **Estado no freeze:** os 27 notebooks (IRkernel, `paired_vignette` com
  metadata `"release": "1.0.0"`) terminam com
  `stopifnot(as.character(packageVersion("sciModelFlowR")) == "0.9.0")` —
  contradiz o próprio metadata e o pacote 1.0.0. Execução em kernel limpo
  **falharia** em todos; a campanha §17.9/§21.3 exige 27/27 executados.
- **Derivado:** asserção atualizada para `"1.0.0"` (metadata preservado;
  estrutura de células intacta). Originais em
  `outputs/validation-records/notebooks_frozen/` + hashes em
  `outputs/validation-records/notebooks_frozen_sha256.csv`.
- **Resultado (verificado):** 27/27 executados em kernels IR limpos
  (`R_LIBS` apontando para o tarball derivado instalado), cópias executadas
  fora do source tree em `outputs/rendered-docs/notebooks/`, evidência em
  `outputs/evidence/notebooks_execution_1.0.0.csv`.
- **Política (§29):** material didático/validação → 1.0.1.

## 17. `tools/validate_1.0.0.R` — harness de linha única

- **Estado no freeze:** 1 linha com `\n` literais entre comandos (não faz parse).
  Original em `outputs/validation-records/validate_1.0.0.R.frozen_orig`
  (SHA-256 `E0186E0CF83337D43E08462F8D0CBD94946255E4F0482BD819A0E35A6B78CA15`).
- **Derivado:** comandos equivalentes §18.3 em linhas reais; `audit@n_exports`
  (slot S7) preservado como no original. Detalhes em
  `tools/VALIDATION_HARNESS_WORKAROUND.md`.
  SHA-256 `4A5D744B97D45831B0DBB84DC54A6B0D5DE31BA42DA98746A378C57A3EB2`.

## 18. `tools/validate_1.0.0_release.R` — harness de linha única

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
- **Owner do repositório:** `walterufpb` não existe no GitHub (404). URLs
  atualizadas para o owner real `wep69` em `DESCRIPTION` (URL/BugReports),
  `CITATION.cff` (repository-code) e `_pkgdown.yml` (site →
  `https://wep69.github.io/sciModelFlowR/`); site pkgdown reconstruído
  (28/28 artigos) e `sitemap.xml` regenerado. E-mail do autor
  (`walterufpb@yahoo.com.br`) preservado.
- **Publicação (2026-09-18):** repo público
  `https://github.com/wep69/sciModelFlowR` (branch `main`, sem CI);
  GitHub Pages ativo via *Deploy from a branch* → `main` → `/docs`
  (`https://wep69.github.io/sciModelFlowR/`, build `built`; home/reference/artigo
  verificados HTTP 200). Tarball final reconstruído
  (`B35A37D0E6F8FAE2DFF32DE838EBC3D860B40E69CB7CBB58F352CEC25172289B`) e
  check re-executado: **0 ERROR / 0 WARNING / 2 NOTEs** — a nota de URLs
  inválidas desapareceu com o repo publicado.

## Correções 1.0.2 (auditoria do tutorial da 1.0.1)

Cinco correções derivadas da auditoria da biblioteca instalada (skill
`api-audited-tutorial`), com o relatório ao autor em `RELATORIO-AO-AUTOR.md`
(projeto do roteiro) e testes de regressão em
`tests/testthat/test-regressions-102.R`. A API pública de 246 símbolos e o
freeze 1.0.0 permanecem intactos; detalhes completos em `NEWS.md` (1.0.2).

1. **`smf_to_json()` sem `na = "null"`** — `NA_real_` virava texto `"NA"` e o
   bundle portátil com pré-processamento padrão falhava só na previsão;
   corrigido em `R/core-serialization.R` (+ higiene em `R/tracking.R`) e
   tolerância a estados textuais/NULL em `R/preprocess.R`.
2. **Objetivo de tuning fora de `spec@metrics`** — archive com coluna toda
   `NA` e seleção vazia sem aviso; agora aborta com `smf_tuning_error`
   (`R/tuning-core.R`) e o `print` distingue o motivo (`R/print-methods.R`).
3. **`value` textual no PDP/ICE numérico** — passa a preservar o tipo
   numérico (`R/explain.R`), como o ALE, eliminando também a sensibilidade a
   `OutDec`.
4. **Intervalo degenerado em representação `point`** — agora recusa, como o
   CDF da mesma representação (`R/probabilistic-core.R`).
5. **Mensagem de engine desconhecido** — passa a listar os engines aceitos e
   apontar `smf_available_model_adapters()` (`R/core-capabilities.R`).
