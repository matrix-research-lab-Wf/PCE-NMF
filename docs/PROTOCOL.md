# Experimental protocol

## Common settings

- MATLAB R2019a on Windows, double precision.
- Samples are columns of `X` and normalized to unit Euclidean norm.
- Datasets: YaleB, COIL20, Optdigits, ORL, PIE, and COIL100.
- Development seeds: `20260617:20260626`.
- Independent test seeds: `20260627:20260646`.
- Per-class labeled count: `max(1,floor(0.10*n_k))`.
- ACC and NMI are evaluated on unlabeled samples only.
- NMI uses `2*I(Y;Yhat)/(H(Y)+H(Yhat))` in the common comparison.
- All methods receive the same labeled split within each dataset-seed pair.
- Shared non-negative initial factors are used when dimensions permit.

## PCE-NMF settings

- `lambda = 100` for all datasets.
- `max_iter = 50`.
- Binary cosine-neighbour graph, union symmetrization, and no self-loops.
- Neighbourhood sizes for YaleB, COIL20, Optdigits, ORL, PIE, COIL100:
  `[2, 2, 4, 3, 3, 2]`.
- Direct score: `||u_k||_2^2 * v_ik^2`.

The PCE-NMF values of `lambda` and `p` for YaleB, COIL20, and COIL100 were
selected on the 10 development seeds. The values of `p` for Optdigits, ORL,
and PIE were retained from the initial locked protocol and were not selected
from the independent test results.

## Compared methods and native decisions

- Methods: NMF, CNMF, GNMFLD, EDNMF (ERDNMF), LCNMF, GOCNMF, SNMFWLP,
  HLPNMF, and PCE-NMF.
- NMF, CNMF, and SNMFWLP: 50-start K-means on the learned representation.
- GNMFLD, ERDNMF, LCNMF, GOCNMF, and HLPNMF: row-wise class-semantic maximum.
- PCE-NMF: maximum scale-invariant contribution energy.
- Primary ACC uses an evaluation-only optimal permutation of the native
  predictions. NMI is permutation invariant.
- Paired PCE-minus-baseline tests use a two-sided exact Wilcoxon signed-rank
  test. Holm correction is applied separately within each baseline family of
  12 comparisons (six datasets by two metrics).

## HLPNMF extension

- Author source frozen at commit `00ba5aacd210e5df2304ae370d34a4395a706e27`.
- `alpha = 1000`, `maxIter = 30` on all datasets.
- `(p,k)`: YaleB `(2,3)`, COIL20 `(2,3)`, Optdigits `(5,1)`,
  ORL `(2,3)`, PIE `(3,5)`, and COIL100 `(2,3)`.
- Optdigits inherits the paper's MNIST setting; ORL inherits its YaleB setting.
  These two transferred configurations are not published target-dataset optima.
- The author interface initializes factors internally. The random seed is aligned,
  but common initial factors cannot be injected.
- HLPNMF runtime includes hypergraph construction and is not pooled with the
  graph-excluded runtime comparison.

## Result files

- `overall_summary.csv`: means, standard deviations, confidence intervals,
  and runtime over the independent test seeds.
- `paired_tests.csv`: paired differences and Holm-adjusted Wilcoxon tests.
- `hce_ablation_summary.csv`: PCE-NMF versus hard class exclusion on the
  independent test seeds.
- `label_ratio_summary.csv`: 5%, 10%, 15%, and 20% label rates.
- `lambda_sensitivity.csv` and `neighborhood_sensitivity.csv`: sensitivity.
- `convergence_summary.csv`: objective trajectories and diagnostics.
- `hlpnmf/`: 120 raw trials, dual-NMI evaluation, summary, paired tests,
  dataset-identity audit, and author-code replay evidence.
