# Method provenance and release boundary

The current paper compares PCE-NMF with NMF, CNMF, GNMFLD, EDNMF, LCNMF, GOCNMF, SNMFWLP, and HLPNMF. HCE-NMF and harmonic-only are matched mechanism controls. The exact parameter lock is in `docs/current/PARAMETER_LOCK.csv`; implementation and source notes are in `docs/current/METHOD_SOURCE_NOTES.md`.

The released adapters are under `experiments/current/code/adapters/`. They retain the method-specific training and native prediction rules used for the recorded experiments. The HLPNMF adapter calls the author's `HLPNMF` function; the author source is not included. Other third-party source snapshots and all benchmark datasets are also omitted. The Hungarian-assignment helpers in the adapter directory carry their original attribution and are not covered by the repository's MIT grant for `code/`.

Use the result records in `results/current/` to inspect the exact comparisons without downloading the datasets or external implementations. To rerun the full benchmark, obtain the original materials and add the HLPNMF source under `third_party/HLPNMF`.
