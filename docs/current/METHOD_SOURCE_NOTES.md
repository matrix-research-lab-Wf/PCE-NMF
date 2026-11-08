# Method source and native-decision audit

This file records the implementation identity required before the rebuilt
formal experiment. Reusing audited source code is permitted; reusing previous
numerical outputs is prohibited.

| Method | Training source | Native prediction used in the rebuild | Status |
|---|---|---|---|
| NMF | audited local Euclidean-NMF implementation | 50-start K-means on the learned representation | source present; new smoke test required |
| CNMF | audited local constrained-NMF implementation | 50-start K-means on the learned representation | source present; new smoke test required |
| GNMFLD | audited local implementation aligned to the published model | row-wise maximum of class-semantic coordinates | source present; new-data parameters pending |
| EDNMF/ERDNMF | preserved author MATLAB code with index-interface adapter | author-code row-wise class decision followed by common ACC mapping | source snapshot present; new-data parameters pending |
| LCNMF | preserved author MATLAB code with index-interface adapter | row-wise maximum of class-semantic coordinates | source snapshot present; new-data parameters pending |
| GOCNMF | preserved author MATLAB code with index-interface adapter | row-wise maximum of the one-hot-constrained representation | source snapshot present; new-data parameters pending |
| SNMFWLP | preserved author MATLAB code with paired-split adapter | source-protocol K-means on the learned representation | source snapshot present; new smoke test required |
| HLPNMF | author code from `https://github.com/ljisxz/HLPNMF` | row-wise maximum of the class-semantic representation | source files downloaded individually; wrapper required |
| PCE-NMF | fixed project implementation | maximum scale-invariant contribution energy | source present; rebuilt implementation audit required |

## Timing boundary

For the rebuilt timing experiment, every method is timed from the start of
its split-dependent graph or hypergraph construction through native
prediction. Data loading and shared split generation are outside the timer.
Persistent graph caches are disabled. A separate training-only time may be
recorded, but the main comparison uses the common end-to-end boundary.

## Allowed implementation changes

- arbitrary labeled-index support;
- shared paired splits and deterministic initialization;
- input-orientation conversion;
- result logging, diagnostics, and common metric calculation;
- MATLAB R2019a compatibility fixes that do not alter the mathematical model.

No method-specific objective, update equation, stopping rule, iteration
budget, or source-native prediction mechanism may be changed after inspecting
formal results.

