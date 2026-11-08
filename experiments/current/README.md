# MATLAB R2019a experiment code

The scripts in `code/` are the released copy of the locked experiment drivers. `rebuild_config.m` changes only repository-relative paths from the original workspace: data go under repository-root `data/`, output records under `results/current/`, and the HLPNMF author implementation under `third_party/HLPNMF/`. The objective, methods, parameters, seeds, and evaluation rules are unchanged.

From the repository root in MATLAB R2019a:

```matlab
addpath('experiments/current/code');
addpath('experiments/current/code/adapters');
run_PCE_formal20_R2019a;  % full nine-method comparison, after data/source setup
```

Other drivers cover the mechanism controls, label ratios, incorrect observed labels, image corruption, class count, no-cache runtime, parameter development, and numerical convergence. Each script header describes its entry point. Inspect `results/current/` first: the drivers use resumable CSV keys, while the convergence driver writes its diagnostic file afresh.

The standalone core solver and synthetic smoke test are in repository-root `code/`. The full experiment drivers require the audited datasets and HLPNMF author source. The metrics adapter uses a Hungarian assignment helper attributed in its source header.
