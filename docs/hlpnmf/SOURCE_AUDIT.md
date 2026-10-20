# HLPNMF author-code audit

Date: 2026-10-20. Author source: https://github.com/ljisxz/HLPNMF
Frozen commit: 00ba5aacd210e5df2304ae370d34a4395a706e27.
Author files are unchanged. This is a preliminary execution audit, not a
paper-table reproduction or a six-dataset comparison.

## Verified native protocol

- Row-normalized samples; author input is n-by-d.
- Full classes, 10% labels per class rounded upward by ceil.
- Labeled samples placed first; class IDs remapped by selected class order.
- Random internal U and V; native decision is row-wise argmax(V).
- main.m: 30 iterations, alpha=1000. Dataset settings: PIE p=3/k=5;
  YaleB p=2/k=3; COIL20 p=2/k=3; COIL100 p=2/k=3.
- No ORL or Optdigits setting is documented in main.m.
- Author NMI uses MI/max(H1,H2); the current PCE paper uses
  MI/sqrt(H1*H2). Author evaluator also smooths missing classes by appending
  samples. It must not be reused as the common external evaluation function.

## Executed author-flow smoke test

MATLAB R2019a, singleCompThread, author COIL20.mat, seed 20260617.
1440 samples, 1024 features, 160 labeled samples, 1280 evaluated samples.
Native and permutation-aligned ACC: 0.9640625.
Author NMI: approximately 0.9645 (console precision).
Solver time: 5.366371 seconds, including graph construction.
Factors and stored objectives finite; no observed objective increases.
Saved prediction and objective record: author_COIL20_seed20260617.mat.
The target protocol uses floor and therefore 140 COIL20 labels; the current
result is not directly comparable with the PCE formal table.

## Code details requiring paper verification

1. Author objective is ||X-UV'||_F^2 + alpha*trace(V'*(I-S^k)*V),
   with a row-stochastic transition S and symmetric part in the update.
2. Labeled rows are clamped at the start of each iteration, then updated.
   Returned labeled rows are not clamped after the final update. Preserve
   this native sequence until the paper algorithm has been checked.
3. Objectives are stored before each update, so the final returned factors
   are one update ahead of the last recorded objective.
4. Dense n-by-n matrices, matrix power, and explicit dense inverse occur in
   the author code. Largest-dataset memory and runtime need measurement.
5. No numerical paper-table matching threshold is justified yet. The earlier
   generic 0.02/0.05 thresholds should not be treated as validated criteria.
   Check exact data, label budget, metrics, and reported variability first.

## Next gate

Obtain the primary full paper and identify its dataset tables, prediction
definition, and parameter-selection procedure. Then perform a matched author
reproduction. Six-dataset results require the locked PCE splits and common
unlabeled-only metrics while preserving HLPNMF's native argmax decision.

## Follow-up verification: data identity and repeat execution

Author datasets and current protocol datasets were compared after sample L2
normalization and sorting by canonical class ID and the complete feature row.
YaleB (2414x1024), COIL20 (1440x1024), PIE (2856x1024), and COIL100
(7200x1024) all have maximum absolute feature difference 0 and identical
canonical labels. Source: data_identity.csv.

Three author-protocol COIL20 trials were run in MATLAB R2019a with unchanged
author code, p=2, k=3, alpha=1000, 30 iterations, and ceil(10%) labels.

| Seed | Native/aligned ACC | Author NMI | Solver seconds |
|---|---:|---:|---:|
| 20260617 | 0.964062500 | 0.964512630 | 9.0821768 |
| 20260618 | 0.975000000 | 0.972308050 | 2.7500676 |
| 20260619 | 0.950781250 | 0.949269813 | 3.1313797 |

Mean +/- sample SD: ACC 0.963281250 +/- 0.012128261;
author NMI 0.962030164 +/- 0.011718023. All factors/objectives were finite,
and all three stored objective traces had zero increases at the stated
numerical tolerance. The rerun at seed 20260617 exactly reproduced the
previous prediction accuracy and author NMI; runtime is environment dependent.
These development-seed execution checks are not formal comparative results.

The 17-page primary article in Pattern Recognition 180 (2026) 114657 was
subsequently supplied and checked against the frozen author code. The detailed
model, update, parameter, dataset, and native-decision audit is recorded in
`PAPER_CODE_ALIGNMENT.md`. No source-paper value is substituted for a
common-protocol result.
