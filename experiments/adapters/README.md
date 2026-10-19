# Baseline adapter contract

The formal runner calls `run_<METHOD>(X,y,labeled,W0,H0,opt)` and expects
`[pred,info]`. The returned `pred` is an `n x 1` native cluster or class index.
The `info` structure records iterations, runtime, initialization mode,
parameter tag, and source identifier.

Only the original PCE-NMF core is distributed here. Third-party source and
adapted files are omitted because they retain their original licenses. Obtain
the following implementations from their authors and connect them through the
documented contract:

- EDNMF commit `f2fd73adbc38947ee1848f500c84a770ea09e9a5`
- LCNMF commit `7a53ca760a648122e1c71651fdf36f0d23e3225e`
- GOCNMF commit `1ecd7ab0261644c67b55dbfa9bc022fdeb4e5a08`
- SNMFWLP commit `538dcfee1554ed2517969bf33cedd379a6126b37`

NMF, CNMF, and SNMFWLP return representations to their source-aligned
50-start K-means decision stage. GNMFLD, ERDNMF, LCNMF, and GOCNMF use their
native class-semantic row-wise decision. PCE-NMF uses the maximum
scale-invariant contribution energy.

The public raw records permit verification of the reported summaries without
redistributing restricted third-party implementations or benchmark data.
The full runner also expects an optimal label-permutation utility named
`bestMap`, used only for evaluation ACC; this utility is commonly bundled with
the cited baseline packages. The released aggregation script verifies all
reported results directly from `results/independent_test_raw.csv` and has no
third-party dependency.
