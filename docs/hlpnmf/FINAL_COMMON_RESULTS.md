# HLPNMF common-protocol final results

Completed 2026-10-20 in MATLAB R2019a, single-threaded. The author solver was
kept unchanged. All 120 trials completed with finite output. ACC uses the
evaluation-only optimal permutation on unlabeled samples. The NMI column below
uses the arithmetic normalization `2I/(H_true+H_pred)`, matching the historical
eight-method formal records.

| Dataset | HLPNMF ACC | HLPNMF NMI | PCE minus HLPNMF ACC | PCE minus HLPNMF NMI |
|---|---:|---:|---:|---:|
| YaleB | 0.7325 +/- 0.0130 | 0.7350 +/- 0.0082 | -0.03921 | -0.03322 |
| COIL20 | 0.9486 +/- 0.0128 | 0.9488 +/- 0.0119 | +0.01923 | +0.01963 |
| Optdigits | 0.9856 +/- 0.0014 | 0.9626 +/- 0.0026 | -0.00227 | -0.00472 |
| ORL | 0.6039 +/- 0.0152 | 0.7972 +/- 0.0087 | +0.04292 | -0.00997 |
| PIE | 0.9577 +/- 0.0116 | 0.9710 +/- 0.0055 | -0.02703 | -0.02287 |
| COIL100 | 0.8769 +/- 0.0105 | 0.9253 +/- 0.0055 | +0.03240 | +0.01904 |

All 12 paired comparisons remain significant after Holm correction. The
adjusted p value is 0.0083084 for ORL NMI and 2.2888e-5 for each of the other
11 comparisons. Positive differences favor PCE-NMF.

Interpretation fixed before the run: adding HLPNMF changes the strongest-method
ranking on YaleB, Optdigits, and PIE, while PCE-NMF retains clear advantages on
COIL20 and COIL100. ORL is metric-dependent: PCE-NMF has higher ACC and HLPNMF
has higher NMI. These outcomes require revision of any blanket superiority
claim but do not alter the PCE-NMF objective or its mechanism-level ablation.

Runtime in `summary.csv` includes HLPNMF hypergraph construction and is not
directly comparable with the graph-excluded runtime table in the manuscript.
Optdigits and ORL use transferred, predeclared `(p,k)` settings; they are not
claimed as published target-dataset optima.
