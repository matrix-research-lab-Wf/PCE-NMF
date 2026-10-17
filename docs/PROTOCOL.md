# Experimental protocol

## Common settings

- MATLAB R2019a on Windows, double precision.
- Samples are columns of `X` and normalized to unit Euclidean norm.
- Datasets: YaleB, COIL20, Optdigits, ORL, PIE, and COIL100.
- Seeds: `20260617:20260636`.
- Per-class labeled count: `max(1,floor(0.10*n_k))`.
- ACC and NMI are evaluated on unlabeled samples only.
- All methods receive the same labeled split within each dataset-seed pair.
- Shared non-negative initial factors are used when dimensions permit.

## PCE-NMF settings

- `lambda = 100` for all datasets.
- `max_iter = 50`.
- Binary cosine-neighbour graph, union symmetrization, and no self-loops.
- Neighbourhood sizes for YaleB, COIL20, Optdigits, ORL, PIE, COIL100:
  `[2, 3, 4, 3, 3, 3]`.
- Direct score: `||u_k||_2^2 * v_ik^2`.

## Result files

- `overall_summary.csv`: means, standard deviations, and ranks.
- `paired_tests.csv`: paired differences and Holm-adjusted Wilcoxon tests.
- `hce_ablation_summary.csv`: PCE-NMF versus hard class exclusion.
- `label_ratio_summary.csv`: 5%, 10%, 15%, and 20% label rates.
- `lambda_sensitivity.csv` and `neighborhood_sensitivity.csv`: sensitivity.
- `convergence_summary.csv`: objective trajectories and diagnostics.
