function metrics = pce_clustering_metrics(truth,pred)
%PCE_CLUSTERING_METRICS Six locked clustering metrics for unlabeled samples.
% Inputs:
%   truth - n-by-1 ground-truth class labels.
%   pred  - n-by-1 predicted cluster identifiers from a method's native rule.
% Output fields:
%   ACC, NMI, Purity, Fscore, Precision, Recall, mapped_prediction.
%
% ACC uses optimal label permutation. NMI, Purity, and pair-counting metrics
% are invariant to cluster-label names. Compatible with MATLAB R2019a.

truth = truth(:); pred = pred(:);
if numel(truth) ~= numel(pred) || isempty(truth)
    error('truth and pred must be nonempty vectors of equal length.');
end
if any(~isfinite(truth)) || any(~isfinite(pred))
    error('truth and pred must contain finite labels.');
end

[~,~,ti] = unique(truth);
[~,~,pi] = unique(pred);
nt = max(ti); np = max(pi); n = numel(ti);
C = accumarray([ti pi],1,[nt np]);

q = max(nt,np);
G = zeros(q,q);
G(1:nt,1:np) = C;
[assignment,~] = hungarian(-G);
mapped = zeros(n,1);
correct = 0;
for j = 1:np
    r = assignment(j);
    if r >= 1 && r <= nt
        mapped(pi == j) = r;
        correct = correct + C(r,j);
    end
end
acc = correct/n;

row_sum = sum(C,2);
col_sum = sum(C,1);
purity = sum(max(C,[],1))/n;

Pij = C/n;
Pt = row_sum/n;
Pp = col_sum/n;
den = Pt*Pp;
nz = Pij > 0;
mi = sum(Pij(nz).*log(Pij(nz)./den(nz)));
ht = -sum(Pt(Pt>0).*log(Pt(Pt>0)));
hp = -sum(Pp(Pp>0).*log(Pp(Pp>0)));
if ht == 0 && hp == 0
    nmi = double(isequal(ti,pi));
elseif ht == 0 || hp == 0
    nmi = 0;
else
    nmi = mi/sqrt(ht*hp);
end

tp = sum(local_choose2(C(:)));
predicted_positive = sum(local_choose2(col_sum(:)));
true_positive_pairs = sum(local_choose2(row_sum(:)));
if predicted_positive == 0
    precision = double(tp == 0);
else
    precision = tp/predicted_positive;
end
if true_positive_pairs == 0
    recall = double(tp == 0);
else
    recall = tp/true_positive_pairs;
end
if precision + recall == 0
    fscore = 0;
else
    fscore = 2*precision*recall/(precision+recall);
end

metrics = struct('ACC',acc,'NMI',nmi,'Purity',purity, ...
    'Fscore',fscore,'Precision',precision,'Recall',recall, ...
    'mapped_prediction',mapped,'contingency',C);
end

function z = local_choose2(x)
z = x.*(x-1)/2;
end
