# Parameter provenance

The independent comparison uses configurations fixed before evaluation on
test seeds `20260627:20260646`. Unlabeled ground-truth labels are used only to
compute the final ACC and NMI values.

| Method | Locked setting and provenance |
|---|---|
| NMF | 200 multiplicative-update iterations; shared non-negative initialization where dimensions permit. |
| CNMF | 200 iterations; hard constrained representation; shared initialization where permitted. |
| GNMFLD | Dataset-specific `alpha` and `beta` are recorded in `experiments/config/pce_protocol_config.m`; transferred values are tagged there and are not presented as published target-dataset optima. |
| EDNMF | ERDNMF variant; author-code implementation; dataset-specific `alpha` values and transfer tags are recorded in the protocol configuration. |
| LCNMF | Author-code implementation; 200 iterations and the source-aligned native class-semantic decision. |
| GOCNMF | 50 iterations; dataset-specific `alpha` values and the transferred ORL setting are recorded in the protocol configuration. |
| SNMFWLP | `alpha=10^3`, `beta=10^5`; 50 iterations; source-aligned 50-start K-means decision. |
| PCE-NMF | `lambda=100`, 50 iterations, and graph neighbourhood sizes `[2,2,4,3,3,2]`. YaleB, COIL20, and COIL100 were selected on development seeds; Optdigits, ORL, and PIE retain the initial locked values. |

The parameter budget is source aligned rather than a common retuning grid.
Transferred settings remain explicitly tagged to distinguish them from values
reported for the same target dataset in an original paper.
