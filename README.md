# PCE-NMF

MATLAB R2019a implementation and reproducibility materials for **Propagated
Class-Exclusion Non-negative Matrix Factorization (PCE-NMF)**.

PCE-NMF propagates partial class evidence through a sample graph, converts the
evidence into class-incompatibility weights, and suppresses incompatible
rank-one reconstruction contributions. The same scale-invariant contribution
energies provide the final class assignment.

## Repository contents

- `code/pce_nmf.m`: core PCE-NMF solver.
- `code/demo_synthetic.m`: self-contained smoke test with synthetic data.
- `docs/PROTOCOL.md`: locked experimental protocol and parameters.
- `docs/DATASETS.md`: expected data format and official dataset sources.
- `docs/THIRD_PARTY_METHODS.md`: baseline provenance and release boundary.
- `docs/PARAMETER_PROVENANCE.md`: locked settings and selection provenance.
- `docs/hlpnmf/`: HLPNMF source audit, locked protocol, NMI alignment, and final interpretation.
- `results/`: compact tables from the independent-test comparison and supporting analyses.
- `figures/`: selected current paper figures.
- `paper/PCE-NMF.tex` and `paper/PCE-NMF.pdf`: current manuscript source and PDF.
- `experiments/`: MATLAB R2019a protocol, aggregation, audit, and plotting scripts.

The benchmark datasets and third-party baseline implementations are not
redistributed in this repository.

## Quick start

1. Open MATLAB R2019a or later.
2. Set the current folder to the repository root.
3. Run:

```matlab
addpath('code');
demo_synthetic;
```

The demo constructs a non-negative three-class dataset, selects 10% labeled
samples per class, runs PCE-NMF, and prints accuracy on the unlabeled samples.
No toolbox is required for the core solver or the demo.

## Core call

```matlab
[pred, model] = pce_nmf(X, y, labeled, opts);
```

- `X`: non-negative `m x n` matrix; samples are columns.
- `y`: `n x 1` class labels encoded as consecutive integers `1,...,c`.
- `labeled`: `n x 1` logical vector indicating labeled samples.
- `opts`: options structure; see `help pce_nmf`.
- `pred`: direct class assignments for all samples.
- `model`: learned factors, propagated evidence, exclusion weights, scores,
  objective history, and runtime.

For the paper protocol, normalize every sample to unit Euclidean norm before
calling the solver. The formal setting uses 50 iterations, `lambda = 100`, and
dataset-specific neighborhood sizes listed in `docs/PROTOCOL.md`.

## Reproducibility scope

The CSV files contain the retained numerical records used for the manuscript
tables and figures. The primary comparison uses 20 independent test seeds and
nine methods. Development seeds used for sensitivity analysis are kept
separate from the independent-test records. Full reruns require users to obtain
the datasets from their original providers and prepare the matrices described
in `docs/DATASETS.md`.

`results/independent_test_raw.csv` contains the original 960 records for the
eight-method comparison. `results/hlpnmf/` adds 120 HLPNMF records, producing
1080 method--data-set--seed records in the nine-method comparison. Third-party source files are not
redistributed. The required adapter contract, verified source revisions, and
release boundary are documented under `experiments/adapters/` and
`docs/THIRD_PARTY_METHODS.md`.

To verify the original 960-row integrity gate and regenerate its summary, pairwise,
diagnostic, and LaTeX outputs from the released raw records, run:

```matlab
addpath('experiments');
assemble_independent_formal20_R2019a;
```

The HLPNMF extension is reproduced separately because its author implementation
uses an internal initialization interface. Obtain the author source at the
commit recorded in `docs/hlpnmf/SOURCE_AUDIT.md`, place it under
`third_party/HLPNMF`, prepare the six datasets under `data/`, and run:

```matlab
addpath(fullfile('experiments','hlpnmf'));
run_HLPNMF_common_R2019a('formal');
analyze_HLPNMF_common_R2019a;
```

## Citation

Citation metadata are provided in `CITATION.cff`. Please cite the associated
paper when using this implementation.

## License

The original PCE-NMF code in `code/` is released under the MIT License. Dataset
files and third-party methods retain their original terms and are not covered
by this repository's MIT License.
