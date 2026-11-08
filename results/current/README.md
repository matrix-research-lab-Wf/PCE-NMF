# Current paper records

All CSV files here are the records supporting `paper/PCE-NMF.tex`. Formal accuracy comparisons use `formal20/raw.csv`; runtime uses the separate no-cache `runtime20/raw.csv`.

| Experiment | Released records | Scope |
|---|---:|---|
| Main comparison | 1800 | 10 datasets × 9 methods × 20 paired runs |
| Mechanism controls | 400 | 10 datasets × 2 controls × 20 paired runs |
| Label ratio, new runs | 2880 | PIE, MSRA25, COIL20, MNIST × 4 non-10% rates × 9 methods × 20 runs |
| Label ratio, 10% reuse | 720 | The matching rows in `formal20/raw.csv` |
| Incorrect observed labels | 1440 | COIL20 and PIE, locked levels and methods |
| Input corruption | 5400 | 3 datasets × 2 corruption types × 5 levels × 9 methods × 20 runs |
| Scalability | 300 | 5 class counts × 3 methods × 20 runs |
| No-cache runtime | 1800 | 10 datasets × 9 methods × 20 runs |
| Numerical convergence | 204 | 4 datasets × 51 recorded iterations |
| Parameter development | 465 | Development runs; separate from formal comparison |

`label_ratio20/raw_scoped.csv` is a filtered release copy. The original local raw file also retains out-of-scope historical rows, which are not used in the manuscript. The release copy contains only the four declared datasets and the 5%, 15%, 20%, and 30% conditions. The 10% condition comes from `formal20/raw.csv`.

All formal method rows are unique, have `OK` status, and have finite six-metric values. The summary and statistical tables used in the paper are under `analysis/`. See `docs/current/FINAL_EVIDENCE_AUDIT.md` for the completed integrity check and the separate timing comparison boundary.
