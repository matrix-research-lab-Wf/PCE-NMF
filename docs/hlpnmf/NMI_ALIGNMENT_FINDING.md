# NMI evaluation identity finding

Observed during HLPNMF integration, 2026-10-20.

PCE manuscript formula and HLPNMF integration raw.csv use geometric NMI:
I/sqrt(Ha*Hb). The current released PCE formal rows instead match arithmetic
NMI 2I/(Ha+Hb), as explicitly used by run_pce_p2_formal20_v2.m, line 113.
The harmonic stabilization audit uses geometric NMI and exposes the gap.

Examples, same seed/prediction, formal arithmetic versus audit geometric:
YaleB/20260627: 0.679809308751429 vs 0.67982309693322074.
ORL/20260627: 0.803792862245111 vs 0.80387284278280458.
COIL20/20260627: 0.967638794850062 vs 0.96763925578188636.
Small magnitude does not justify mixing the definitions.

No model run needs to be discarded. HLPNMF predictions and splits are saved.
analyze_HLPNMF_common_R2019a recomputes both definitions from saved predictions,
preserves original raw.csv, and uses arithmetic NMI for comparisons with
the existing PCE numerical records. Source-paper NMI uses MI/max(Ha,Hb),
which is a third definition and is not used in the common comparison.

The historical eight-method formal core was subsequently verified at
PCE_NMF_BASELINE_ALIGN_core_R2009a.m, lines 1721--1753. It computes
2I/(Hx+Hy) for every method. The p-calibrated PCE replay independently uses
the same definition at run_pce_p2_formal20_v2.m, lines 100--113. Hence the
existing main-table records are internally aligned to arithmetic NMI; the
manuscript's displayed NMI formula, rather than the numerical table, is the
item that requires correction.

All 120 HLPNMF predictions were retained and evaluated under both definitions.
The common comparison and paired tests use arithmetic NMI, exactly matching
the historical eight-method records. No model rerun is required. No manuscript
or existing main-table number has yet been changed by this finding.
