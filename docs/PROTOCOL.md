# Experimental protocol

## Common settings

- MATLAB R2019a on Windows, double precision.
- Samples are columns of `X` and normalized to unit Euclidean norm.
- Datasets: YaleB, COIL20, Optdigits, ORL, PIE, and COIL100.
- Development seeds: `20260617:20260626`.
- Independent test seeds: `20260627:20260646`.
- Per-class labeled count: `max(1,floor(0.10*n_k))`.
- ACC and NMI are evaluated on unlabeled samples only.
- All methods receive the same labeled split within each dataset-seed pair.
- Shared non-negative initial factors are used when dimensions permit.

## PCE-NMF settings

- `lambda = 100` for all datasets.
- `max_iter = 50`.
- Binary cosine-neighbour graph, union symmetrization, and no self-loops.
- Neighbourhood sizes for YaleB, COIL20, Optdigits, ORL, PIE, COIL100:
  `[2, 2, 4, 3, 3, 2]`.
- Direct score: `||u_k||_2^2 * v_ik^2`.

## Compared methods and native decisions

- Methods: NMF, CNMF, GNMFLD, EDNMF (ERDNMF), LCNMF, GOCNMF, SNMFWLP,
  and PCE-NMF.
- NMF, CNMF, and SNMFWLP: 50-start K-means on the learned representation.
- GNMFLD, ERDNMF, LCNMF, and GOCNMF: row-wise class-semantic maximum.
- PCE-NMF: maximum scale-invariant contribution energy.
- Primary ACC uses an evaluation-only optimal permutation of the native
  predictions. NMI is permutation invariant.

## Result files

- `overall_summary.csv`: means, standard deviations, confidence intervals,
  and runtime over the independent test seeds.
- `paired_tests.csv`: paired differences and Holm-adjusted Wilcoxon tests.
- `hce_ablation_summary.csv`: PCE-NMF versus hard class exclusion on the
  independent test seeds.
- `label_ratio_summary.csv`: 5%, 10%, 15%, and 20% label rates.
- `lambda_sensitivity.csv` and `neighborhood_sensitivity.csv`: sensitivity.
- `convergence_summary.csv`: objective trajectories and diagnostics.
