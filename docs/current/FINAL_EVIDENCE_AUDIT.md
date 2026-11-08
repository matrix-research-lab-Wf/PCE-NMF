# Final experiment evidence audit (2026-11-04)

The locked experiment scope was checked against raw records. This file does not modify the manuscript.

| Evidence | Scoped records | Audit |
|---|---:|---|
| Main comparison | 1800 | 10 datasets x 9 methods x 20 seeds; unique, OK, finite six metrics |
| Label ratio | 2880 new + 720 formal10 reuse | 4 datasets x 5 ratios x 9 methods x 20 seeds; unique, OK, finite six metrics |
| Label records outside scope | 558 | Retained only; excluded from claims |
| Noise robustness | 5400 | 3 datasets x 2 noises x 5 ratios x 9 methods x 20 seeds; unique, OK |
| Scalability | 300 | 5 class counts x 3 methods x 20 seeds; unique, OK, finite ACC/NMI/time |
| Mechanism controls | 400 | 10 datasets x 2 controls x 20 seeds; unique, OK |
| Parameter development | 465 | Development seeds only; unique, OK, finite six metrics; excluded from formal performance claims |
| No-cache runtime | 1800 | 10 datasets x 9 methods x 20 seeds; unique, OK, finite time |
| Convergence | 204 | 4 datasets x 51 iterations; all finite, monotone within declared tolerance, constraints satisfied |

## Runtime replacement

`analysis/runtime_summary.csv` and `analysis/figures/runtime_by_dataset.{png,pdf,eps}` now derive from `results/runtime20/raw.csv`.
The previous cached-timing artifacts were copied to `analysis/legacy_cached_runtime/` and must not support manuscript efficiency claims.
Runtime is machine- and implementation-specific, not a complexity proof.

## Metric consistency between formal20 and runtime20

3 of 1800 matched trial keys differ in at least one of the six metrics (tolerance 1e-10).
All other trial keys match exactly. The differing trials are:
- YaleB, seed 20261037, CNMF: maximum absolute metric difference 0.01975969.
- COIL100, seed 20261032, CNMF: maximum absolute metric difference 0.042923077.
- MSRA25, seed 20261043, CNMF: maximum absolute metric difference 0.0064939096.
These are CNMF trials. The timing correction remains valid as a separate run; do not claim every runtime20 prediction is identical to formal20.
The formal20 file remains the source for effectiveness comparisons and runtime20 remains the source for timing.

## Claim-to-evidence decisions

- Main performance: describe dataset-specific strengths and weaknesses. HLPNMF has better mean ACC on several datasets; no universal PCE-NMF superiority claim.
- Mechanism: use matched control results for propagated exclusion and harmonic-only comparisons; avoid causal claims beyond these controls.
- Label ratio: use only PIE, MSRA25, COIL20, MNIST; include all declared ratios, including reused formal10.
- Noise: use paired clean-versus-corrupted deltas; report both saltpepper and occlusion and all declared levels.
- Scalability: report measured accuracy, runtime and structural storage only; no unmeasured peak-memory claim.
- Runtime: PCE-NMF is faster than HLPNMF and slower than GOCNMF across all ten datasets in this implementation; do not claim fastest overall.
- Convergence: numerical decrease on four representative seed-20261029 runs; no general convergence theorem from these traces.
