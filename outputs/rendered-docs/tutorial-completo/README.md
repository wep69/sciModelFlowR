# Tutorial completo do sciModelFlowR 1.0.2

**Complete tutorial for sciModelFlowR 1.0.2** — PT-BR + EN

Material didático de referência para novos usuários: do primeiro comando ao
fluxo científico completo, com **dados simulados de discrepâncias plantadas e
verdade conhecida** (outliers, ausências MCAR/MAR, heterocedasticidade,
desbalanceamento, ruído de rótulo, agrupamento, série temporal, autocorrelação
espacial, alta dimensão, superdispersão e não linearidade).

*Teaching reference for new users: from the first command to the complete
scientific flow, with **simulated data containing planted discrepancies and
known truth**.*

## Estrutura / Structure

```
tutorial-completo-1.0.2/
├── data-sim/simular-dados.R     # gerador dos 9 conjuntos + gabarito
├── dados/                       # CSVs gerados + verdade.rds + gabarito.csv
├── pt/                          # versão em português (6 partes)
│   ├── _comum.R
│   ├── parte-1-fundamentos.qmd
│   ├── parte-2-desenho-preparacao.qmd
│   ├── parte-3-modelagem-probabilidades.qmd
│   ├── parte-4-tuning-calibracao.qmd
│   ├── parte-5-explicabilidade-incerteza.qmd
│   └── parte-6-avancado-producao.qmd
├── en/                          # English version (6 parts)
│   ├── _common.R
│   └── part-1..6-*.qmd
├── _saida/                      # HTML autocontido + PDF (pt/ e en/)
└── _artefatos/                  # cache e artefatos de render
```

## Partes / Parts

| # | PT-BR | EN | Páginas |
|:--|:--|:--|:--|
| 1 | Fundamentos: o pacote, os dados e a auditoria | Foundations: the package, the data and the audit | 25 |
| 2 | Desenho, reamostragem e preparação | Design, resampling and preparation | 24 |
| 3 | Modelagem supervisionada e probabilidades | Supervised modeling and probabilities | 14 |
| 4 | Tuning, benchmark, calibração e limiares | Tuning, benchmarking, calibration and thresholds | 16 |
| 5 | Explicabilidade e incerteza | Explainability and uncertainty | 16 |
| 6 | Avançado e produção: Bayes, DL, persistência e relato | Advanced and production: Bayes, DL, persistence and reporting | 20–24 |

Cada parte traz objetivos, código executado, figuras e tabelas numeradas com
explicação, caixas de *Interpretação / Armadilha / Boa prática / No seu
experimento* e exercícios com soluções colapsáveis. Os apêndices da Parte 6
trazem o catálogo da API com cobertura calculada, glossário e ambiente.

## Como reproduzir / How to reproduce

```r
# 1. Dados (seed fixa; sobrescreve dados/)
Rscript data-sim/simular-dados.R

# 2. Render (na raiz do projeto; requer Quarto >= 1.5 e o pacote 1.0.2)
quarto render pt/parte-1-fundamentos.qmd --output-dir _saida
# ... e assim por diante para as demais partes (pt/ e en/)
```

- Figuras e eixos em inglês (convenção científica); prosa em PT-BR ou EN.
- Números da prosa vêm do próprio código (inline R), nunca digitados.
- Nenhum HTML depende de recurso externo (`embed-resources: true`).

## Cobertura da API / API coverage

**112 de 246** funções exportadas foram chamadas ao longo do material (45,5%),
por categoria, com a lista explícita das não chamadas e o motivo (Apêndice A).
O tutorial cobre **todas as áreas funcionais** de forma prática; as lacunas são
variantes de estruturas específicas (tensores de DL, backends opcionais) e
utilitários de governança.

## Licença e citação

Material didático derivado do pacote `sciModelFlowR` (Walter Esfrain Pereira).
Cite o pacote e este material ao reutilizar.
