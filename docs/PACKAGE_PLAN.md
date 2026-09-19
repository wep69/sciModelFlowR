# sciModelFlowR 1.0.0 Consolidation Plan

The 1.0.0 phase certifies the 0.9.0 scientific grammar. New algorithm
families are out of scope unless required to correct a release blocker.

## P0

- preserve the 246-export API;
- rerun complete historical and 1.0.0 validation suites;
- certify Gold/reference/numerical semantics;
- audit leakage/design/test-set boundaries;
- certify serialization/security pathways;
- classify optional backends;
- execute documentation curriculum;
- complete package build/check matrix.

## P1

- freeze benchmark timing baselines on reference hardware;
- build final pkgdown site;
- complete software-paper bibliography ledger if the manuscript is
  released with the package.

## Release rule

The 1.0.0 source tree may be definitively frozen before runtime
certification, but `CRAN-ready`, `fully validated`, or equivalent
wording is prohibited until the actual deferred gates pass. Any
corrective source change after the freeze requires a subsequent version.
