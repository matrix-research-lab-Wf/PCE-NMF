# Dataset preparation

Dataset files are not included. Obtain them from their original providers and
respect their terms of use.

| Dataset | Features | Samples | Classes | Source |
|---|---:|---:|---:|---|
| YaleB | 1024 | 2414 | 38 | https://vision.ucsd.edu/datasets/extended-yale-face-database-b-b |
| COIL20 | 1024 | 1440 | 20 | https://www1.cs.columbia.edu/CAVE/software/softlib/coil-20.php |
| Optdigits | 64 | 5620 | 10 | https://archive.ics.uci.edu/ml/datasets/Optical |
| ORL | 4096 | 400 | 40 | https://cam-orl.co.uk/facedatabase.html |
| PIE | 1024 | 2856 | 68 | https://publications.ri.cmu.edu/the-cmu-pose-illumination-and-expression-pie-database-of-human-faces |
| COIL100 | 1024 | 7200 | 100 | https://www.cs.columbia.edu/CAVE/software/softlib/coil-100.php |

Prepare one MAT file per dataset with `X` (`features x samples`, finite and
non-negative) and `y` (`samples x 1`). The paper applies no centering,
dimensional reduction, balancing, or dataset subsampling and normalizes each
column of `X` to unit Euclidean norm.
