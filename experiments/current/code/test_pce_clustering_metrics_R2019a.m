function test_pce_clustering_metrics_R2019a()
%TEST_PCE_CLUSTERING_METRICS_R2019A Deterministic metric unit tests.

addpath(fullfile(fileparts(mfilename('fullpath')),'adapters'));
tol = 1e-12;

truth = [1;1;2;2;3;3];
perfect_permuted = [3;3;1;1;2;2];
M = pce_clustering_metrics(truth,perfect_permuted);
v = [M.ACC M.NMI M.Purity M.Fscore M.Precision M.Recall];
assert(all(abs(v-1) < tol),'Perfect-permutation test failed.');

pred = [1;1;1;2;2;2];
M = pce_clustering_metrics(truth,pred);
% Contingency: [2 0;1 1;0 2]. TP=2, predicted pairs=6, true pairs=3.
assert(abs(M.Precision-1/3) < tol,'Pairwise precision test failed.');
assert(abs(M.Recall-2/3) < tol,'Pairwise recall test failed.');
assert(abs(M.Fscore-4/9) < tol,'Pairwise F-score test failed.');
assert(abs(M.Purity-4/6) < tol,'Purity test failed.');

singletons = (1:numel(truth))';
M = pce_clustering_metrics(truth,singletons);
assert(abs(M.Precision-1) < tol,'Zero-predicted-pair convention failed.');
assert(abs(M.Recall-0) < tol,'Singleton recall test failed.');
assert(abs(M.Fscore-0) < tol,'Singleton F-score test failed.');

fprintf('pce_clustering_metrics: all R2019a unit tests PASS.\n');
end
