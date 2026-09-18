# Validation harness workaround — sciModelFlowR 1.0.0

No source freeze 1.0.0, `tools/validate_1.0.0.R` e
`tools/validate_1.0.0_release.R` estão gravados como **uma única linha**
contendo sequências literais `\n` entre comandos (limitação do harness
congelado, §18.2 do protocolo de validação local). O R não consegue fazer
`parse` desses ficheiros nesse estado.

## Política (§29 do protocolo)

- Os artefactos ZIP/TAR.GZ congelados **não foram alterados** (hashes §2
  verificados: ZIP `28f45620…`—`9483b17f…`, TAR.GZ correspondentes).
- Os originais estão preservados como:
  - `tools/validate_1.0.0.R.frozen_orig`
    (SHA-256 `E0186E0CF83337D43E08462F8D0CBD94946255E4F0482BD819A0E35A6B78CA15`)
  - `tools/validate_1.0.0_release.R.frozen_orig`
    (SHA-256 `26172422A910E0390B572FD63A431BEB746A0C6C2D30441EEA32B86EFD748553`)
- As cópias de trabalho `tools/validate_1.0.0.R` e
  `tools/validate_1.0.0_release.R` são **derivados de validação**: mesma
  semântica, separadores de linha reais. `audit@n_exports` (slot S7) foi
  preservado como no original congelado (o protocolo §18.3 traz `$` por lapso).

## Uso

```r
source("tools/validate_1.0.0.R")          # gate §18.3
source("tools/validate_1.0.0_release.R")  # gate §18.4
```

Toda a repetição afetada deve ser reexecutada após qualquer correção de
harness, com logs arquivados em `outputs/evidence/`.
