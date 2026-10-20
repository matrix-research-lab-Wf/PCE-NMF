# HLPNMF primary-paper versus author-code verification

Primary source: author-supplied copy of the published article
17 pages; Pattern Recognition 180 (2026) 114657.
SHA256: EA0FDFC10220412702AAF055B4533EECE45B191F89D5B6AB95F493B0CBB67563.
Author code: https://github.com/ljisxz/HLPNMF
Commit: 00ba5aacd210e5df2304ae370d34a4395a706e27.

## Model and native decision

Page 4, Eq. (22): minimize ||X-UV'||_F^2 + alpha tr(V'(I-S_k)V),
subject to U,V>=0 and V_l=Y_l. S_k=(P^k+(P^k)')/2 (page 3, Eq. 18).
Page 5, Eqs. (30)-(31), Algorithm 1: multiplicative U and unlabeled V_u
updates; native prediction is argmax over V_u coordinates. These agree with
the author solver on unlabeled sample updates.

The source records trace(V'(I-P^k)V) rather than its symmetric part. These
scalars are mathematically equal because trace(V' A V) only depends on the
symmetric part of A. This is not an objective mismatch.

The source clamps V_l before each iteration and updates all rows, whereas
the paper updates only V_u. The updated labeled rows are reset before the
next U update. Therefore, the extra labeled-row calculation has no effect on
the next iteration or returned unlabeled predictions (in exact arithmetic).
Returned labeled rows need not satisfy the constraint, and the final stored
objective precedes the last update. These are output-diagnostic caveats,
not grounds to replace the native unlabeled prediction rule.

## Paper settings: page 6, Section 4.2

All datasets: alpha=1000, T=30, 20 repetitions, per-class 10% labels,
unit Euclidean sample norm. Original code uses ceil for labeled count.

| Dataset | p | k | Status in current six-dataset protocol |
|---|---:|---:|---|
| YaleB | 2 | 3 | published dataset-specific setting |
| COIL20 | 2 | 3 | published dataset-specific setting |
| PIE | 3 | 5 | published dataset-specific setting |
| COIL100 | 2 | 3 | published dataset-specific setting |
| Optdigits | -- | -- | no published dataset-specific setting |
| ORL | -- | -- | no published dataset-specific setting |

Page 6 specifies AR (5,1), while main.m comments list AR (10,1).
This discrepancy does not affect the four overlapping datasets. MNIST is
(5,1) in both sources. Any use on ORL/Optdigits needs a prospectively frozen
and explicitly transferred parameter setting; no target-label tuning.

Section 4.4, page 7 selects alpha,p,k using ACC grids; these are paper-selected
settings and must not be described as independently validated optima.

## Original overlap results: Tables 2 and 3, pages 7 and 10

| Dataset | ACC mean +/- SD | NMI mean +/- SD |
|---|---:|---:|
| YaleB | 0.7574 +/- 0.0074 | 0.7498 +/- 0.0057 |
| COIL20 | 0.9643 +/- 0.0115 | 0.9616 +/- 0.0106 |
| PIE | 0.9731 +/- 0.0043 | 0.9783 +/- 0.0025 |
| COIL100 | 0.8932 +/- 0.0126 | 0.9348 +/- 0.0078 |

Do not compare these directly against the PCE formal table: author label
rounding, random splits, NMI normalization, and parameter selection differ.
Author evaluator uses MI/max(H1,H2), with missing-class smoothing; formal
PCE comparison must recompute common NMI from unchanged native predictions.

## Verification boundary

Primary paper and author code support the same core model, native decision,
and four overlapping parameter pairs. All four normalized datasets were
already verified identical to the current PCE data. COIL20 author-protocol
20-seed replay is recorded separately; it tests paper-result agreement before
any common-protocol comparison. No six-dataset performance is claimed here.

## Completed COIL20 author-protocol replay

MATLAB R2019a, singleCompThread, author code unchanged, 20 seeds
20260617:20260636. Alpha=1000, p=2, k=3, T=30, ceil label count=160.
All 20 runs finite; all 20 stored objective traces have zero increases at the
recorded tolerance. Native and aligned ACC agree in all 20 trials.

| Metric | Paper mean +/- SD | Local mean +/- SD | Local minus paper mean |
|---|---:|---:|---:|
| ACC | 0.9643 +/- 0.0115 | 0.956015625 +/- 0.013481940 | -0.008284375 |
| Author NMI | 0.9616 +/- 0.0106 | 0.954369602 +/- 0.012908678 | -0.007230398 |

The local means differ by 0.83 and 0.72 percentage points. Local variation
is of similar order to the published standard deviations. Published random
seeds are not supplied, so this is a distributional comparison, not exact
trial reproduction or proof of equality. These differences do not justify
changing author parameters. The 20-row raw evidence is
author_COIL20_repeat20.csv. Common-protocol six-dataset testing remains a
separate experiment and needs explicit transferred settings for ORL/Optdigits.
