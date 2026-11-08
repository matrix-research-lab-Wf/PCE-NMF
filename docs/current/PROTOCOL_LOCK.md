# PCE-NMF complete manuscript rebuild: protocol lock

Date locked: 2026-10-29

## 1. Fixed scientific target

The target remains Propagated Class-Exclusion NMF (PCE-NMF). The PCE-NMF
objective function, hard labeled support constraint, harmonic propagation
mechanism, and scale-invariant class-energy decision are not modified during
the rebuild. The purpose of the rebuild is to generate a new theoretical,
experimental, visual, and bibliographic evidence package rather than reuse
the previous manuscript package.

## 2. Questions tested by the new experiments

1. Does PCE-NMF remain competitive across face, object, digit, and palm-image
   data under a common semi-supervised clustering protocol?
2. Does propagated exclusion improve over hard class exclusion when all other
   components are held fixed?
3. Does coupling propagated exclusion with NMF improve over harmonic label
   propagation alone?
4. How sensitive is PCE-NMF to the exclusion weight, graph neighborhood, and
   labeled proportion?
5. How do noise, sample size, and graph construction affect accuracy, memory,
   and end-to-end running time?

The outcome of Questions 1--3 may change the main scientific conclusion.
Questions 4--5 change only the scope, robustness, and efficiency claims.

## 3. Data sets

Target data sets:

1. YaleB
2. COIL20
3. Optdigits
4. ORL
5. PIE
6. COIL100
7. AR
8. MSRA25
9. MNIST
10. USPS

Every file must pass a data audit before execution: variable names, sample
orientation, sample count, feature dimension, class count, finite values,
non-negativity, label completeness, class balance, duplicate samples, and
source/version identity. A data set that fails the audit remains listed as
unavailable and is not silently replaced by another version.

Palm was considered during the pre-execution audit because it appears in the
HLPNMF reference study. The author-provided `Palm.mat` contains 1122 negative
entries (minimum approximately -11.12), while PCE-NMF and the NMF baselines
require non-negative input. The accompanying HLPNMF code applies only
Euclidean normalization and does not define a negative-value correction.
Palm is therefore excluded before any formal result is generated. USPS is
used as the tenth data set and must pass the same non-negativity and version
audit. The downloaded Palm file and audit record are retained as an excluded
case.

## 4. Formal comparison

Methods:

1. NMF
2. CNMF
3. GNMFLD
4. EDNMF/ERDNMF
5. LCNMF
6. GOCNMF
7. SNMFWLP
8. HLPNMF
9. PCE-NMF

Each method retains its native training formulation and native prediction
mechanism. Interface changes are limited to arbitrary labeled indices,
shared data splits, deterministic seeds, logging, and output conversion.

## 5. Shared evaluation protocol

- MATLAB R2019a on Windows.
- Samples stored as columns and normalized to unit Euclidean norm.
- Approximately 10% labeled samples per class using
  `max(1,floor(0.1*n_k))`.
- Formal seeds: `20261029:20261048` (20 paired splits). Seed identifiers are
  consecutive integers, not calendar dates.
- Evaluation is restricted to unlabeled samples.
- The same labeled split is supplied to every method.
- Main clustering metrics: ACC, NMI, Purity, F-score, Precision, and Recall.
- Main ACC uses a common optimal permutation of predicted cluster identifiers.
- NMI is the mutual information divided by the geometric mean of the true-
  label and predicted-label entropies.
- Purity is the sample-weighted majority-class proportion over predicted
  clusters.
- Precision, Recall, and F-score use pair counting: a positive pair contains
  two samples assigned to the same cluster. Precision is TP/(TP+FP), Recall
  is TP/(TP+FN), and F-score is their harmonic mean. These three metrics are
  computed from the contingency table without enumerating all sample pairs.
- Native class-semantic ACC is additionally reported for PCE-NMF and every
  baseline whose source formulation assigns fixed class meanings.
- All failed or missing runs remain visible in the raw records.

## 6. Parameter protocol

- Source-recommended data-set parameters are used when available.
- Values transferred to a new target data set are marked `transferred` and
  are never described as published optima.
- Parameter development uses separate development splits and cannot inspect
  the formal-test labels or formal-test performance.
- The formal seeds, iteration budgets, stopping rules, and parameter grids are
  frozen before formal execution.
- No outcome-driven rescue tuning is allowed.

### PCE-NMF development protocol

- Development seeds are `20261009:20261013`; they do not overlap the formal
  seeds.
- The labeled pool uses the same 10% per-class rule as the formal experiment.
  When a class has at least two labeled-pool samples, 80% (at least one) are
  used as inner training labels and the remainder as validation labels.
- PCE-NMF uses its native class-semantic predictions during parameter
  development. Mean native validation ACC is the primary selection criterion;
  NMI and the other metrics are diagnostic only.
- Parameter selection follows the reference-paper sequential presentation:
  first search `lambda` in `{0.1,1,10,100,1000,10000}` at `p=3`, then search
  `p` in `{2,3,5,7,10}` at the selected `lambda`.
- Exact ties are resolved by the smaller parameter value.
- ORL and AR have only one labeled-pool sample per class at the locked 10%
  budget, so inner labeled-only validation is undefined. Their PCE-NMF values
  are transferred from the median selections on the tunable face datasets
  YaleB, PIE, and MSRA25 and are marked `transferred-face-development`.

## 7. New controlled experiments

### Component ablation

- HCE-NMF: remove propagated exclusion while retaining NMF and hard support.
- LP-only: use the same harmonic field without NMF coupling.
- PCE-NMF: full model.

### Label proportion

- 5%, 10%, 15%, and 20% labeled samples per class.

### Noise robustness

- The noise model and intensities must be fixed before execution.
- Clean and corrupted data use the same splits and method parameters.
- Noise results affect only robustness claims.

### Scalability and running time

- Timing begins after data loading and includes graph/hypergraph construction,
  model fitting, and native prediction.
- No persistent graph cache is shared across timed trials.
- Report wall-clock time, peak memory when measurable, and failure status.
- Scalability uses deterministic stratified subsets fixed before execution.

## 8. Required outputs

- `data_audit.csv` and `data_audit.txt`
- `METHOD_SOURCE_NOTES.md`
- `PARAMETER_LOCK.csv`
- formal raw, summary, rank, and pairwise CSV files
- diagnostics and failure logs
- ablation, sensitivity, label-ratio, noise, scalability, convergence, and
  runtime source data
- newly generated PDF/EPS/300-dpi PNG figures
- newly generated LaTeX tables
- a new manuscript based on the PCR-NMF LaTeX template
- a newly verified and first-appearance-ordered bibliography

## 9. Manuscript length and references

- The complete main manuscript must not exceed 35 pages in the PCR-NMF
  template layout.
- The bibliography must contain at least 35 independently verified references.
- References are numbered by first appearance in the main text.
- Main-text figures and tables are selected by claim relevance. Full
  per-split records, extended parameter tables, and secondary diagnostics are
  placed in the reproducibility package or supplementary material rather than
  compressed into unreadable main-text figures.

## 10. Evidence boundary

No numerical result, ranking, significance statement, robustness claim, or
runtime claim from the previous PCE-NMF manuscript is copied into the rebuilt
manuscript. Previous files may be used only to identify the fixed PCE-NMF
model and to audit implementation consistency. All statements in the rebuilt
paper must trace to the new protocol outputs.

