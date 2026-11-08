# PCE-NMF

Current manuscript and MATLAB R2019a reproducibility package for **Propagated class exclusion for direct semi-supervised non-negative matrix factorization**.

## Current version

- [Paper (PDF)](paper/PCE-NMF.pdf) and [LaTeX source](paper/PCE-NMF.tex). The source includes the current theorem, mechanism figure, all cited figures, and its full-metric tables. Compile from `paper/` with `pdflatex PCE-NMF.tex` (twice for references).
- [Frozen protocol](docs/current/PROTOCOL_LOCK.md), [parameter lock](docs/current/PARAMETER_LOCK.csv), and [method/source notes](docs/current/METHOD_SOURCE_NOTES.md).
- [Current experimental records](results/current/README.md) for the ten-data-set, nine-method main comparison and the reported mechanism, label, noise, scalability, timing, and convergence analyses.
- [MATLAB R2019a experiment code](experiments/current/README.md). The standalone [core solver](code/pce_nmf.m) and [synthetic demo](code/demo_synthetic.m) remain available.

The paper uses 20 paired formal runs, six clustering metrics on unlabeled samples, and each external method's native decision rule. PCE-NMF uses the frozen objective, class-support constraint, harmonic evidence, and contribution-energy decision. The paper reports the measured strengths and losses of the method across data sets.

## Data and external code

The image datasets and third-party implementations are not redistributed. See [dataset preparation](docs/DATASETS.md) and [method provenance](docs/THIRD_PARTY_METHODS.md). The repository includes the recorded outputs needed to inspect every reported result. Re-running the full nine-method benchmark requires the original data and the HLPNMF author implementation; the released adapters and protocol specify the remaining method calls.

## Quick start

In MATLAB R2019a, from the repository root:

```matlab
addpath('code');
demo_synthetic;
```

The demo uses synthetic data and requires no toolbox. The full experimental package is described in `experiments/current/README.md`.

## License and citation

The original core solver and demo in `code/` are released under the MIT License. Datasets, author implementations, and attributed helper code retain their own terms. Citation metadata are in `CITATION.cff`.
