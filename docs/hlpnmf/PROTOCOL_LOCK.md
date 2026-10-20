# HLPNMF common-protocol lock

Frozen before examining common-protocol results, 2026-10-20.
Purpose: test whether the newest closely related propagation baseline changes
PCE's dataset-level ranking and the claimed advantage on COIL20/COIL100.
If rankings change, revise the corresponding claims; do not retune either method.

Six datasets in existing order: YaleB, COIL20, Optdigits, ORL, PIE, COIL100.
Formal seeds 20260627:20260646; smoke seed 20260627 (also retained formally).
Use existing data, original sample order, L2 column normalization, and the
formal stratified floor(0.1*n_class) labels with minimum one per class.
Legacy rand('twister',seed), randn('state',seed) split generator.
Only observed labeled ground truth enters the solver.
Move labeled indices first without changing remaining sample order; invert
this permutation before evaluating the original unlabeled index set.
Solver unmodified from author commit 00ba5aacd210e5df2304ae370d34a4395a706e27.
Internal random U,V use the legacy seed reset at seed; shared factors cannot
be supplied by the author interface. Explicitly disclose this distinction.
Native argmax(V), evaluation-only Hungarian ACC, and direct ACC additionally
recorded. The run-time raw file records geometric-entropy NMI
MI/sqrt(H1*H2), as frozen before execution. Because a post-run source audit
showed that the historical eight-method formal records uniformly use
arithmetic NMI 2I/(H1+H2), both definitions are recomputed from the saved
predictions and the arithmetic form is used in common-protocol comparisons.
This evaluation correction does not change training or require a rerun.
Alpha=1000 and 30 iterations everywhere; no stopping-rule changes.

| Dataset | p | k | Parameter source |
|---|---:|---:|---|
| YaleB | 2 | 3 | paper Section 4.2 |
| COIL20 | 2 | 3 | paper Section 4.2 |
| Optdigits | 5 | 1 | transferred from paper MNIST digit setting |
| ORL | 2 | 3 | transferred from paper YaleB face setting |
| PIE | 3 | 5 | paper Section 4.2 |
| COIL100 | 2 | 3 | paper Section 4.2 |

Transferred values are not published optima for target datasets. No unlabeled
labels may select parameters. Raw rows are appended after each completed run;
predictions, split, and objective trace are saved per trial. Finite failures
remain visible and fail the smoke gate. Runtime includes graph construction
and must not be compared with graph-excluded main-table timings.

Completion record: 120/120 trials (six datasets by 20 seeds) finished with
status OK; no non-finite result or failed trial was observed.
