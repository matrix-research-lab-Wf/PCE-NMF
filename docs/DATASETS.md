# Dataset preparation for the current manuscript

Dataset files are not included. Obtain the image datasets from their providers and respect their terms. The formal experiment uses the following audited matrix identities:

| Dataset | Features | Samples | Classes |
|---|---:|---:|---:|
| YaleB | 1024 | 2414 | 38 |
| COIL20 | 1024 | 1440 | 20 |
| Optdigits | 64 | 5620 | 10 |
| ORL | 4096 | 400 | 40 |
| PIE | 1024 | 2856 | 68 |
| COIL100 | 1024 | 7200 | 100 |
| AR | 2000 | 1680 | 120 |
| MSRA25 | 256 | 1799 | 12 |
| MNIST | 784 | 6996 | 10 |
| USPS | 256 | 9298 | 10 |

Place `<dataset>.mat` files under repository-root `data/`. The released MATLAB loader accepts `fea`/`gnd` or `X`/`Y`, transposes if needed so that samples are columns, remaps class IDs to consecutive integers, checks the identities above, requires finite nonnegative values, and normalizes nonzero sample columns to unit Euclidean norm. The dataset source/version must match the audited matrix identity before a numerical comparison is treated as a reproduction.
