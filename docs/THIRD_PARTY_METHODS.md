# Third-party methods

The paper compares PCE-NMF with NMF, CNMF, GNMFLD, EDNMF (ERDNMF), LCNMF,
GOCNMF, SNMFWLP, and HLPNMF.

This repository releases the original PCE-NMF solver and numerical comparison
tables. It does not redistribute third-party implementations. EDNMF and LCNMF
were evaluated from preserved author-code snapshots; the other baselines were
executed through audited local adapters aligned with their reported models and
parameters. HLPNMF was run from the author's public repository at frozen commit
`00ba5aacd210e5df2304ae370d34a4395a706e27`; its source is not redistributed.
Each baseline retains its native decision mechanism. Dataset-specific
transferred parameters are identified in the manuscript and protocol records.

Users reproducing the full comparison should obtain each implementation from
its authors or official project page and retain its license and attribution.
The HLPNMF source and paper/code alignment audit are documented under
`docs/hlpnmf/`.
