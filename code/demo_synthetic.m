%DEMO_SYNTHETIC Self-contained PCE-NMF smoke test for MATLAB R2019a.
clear; clc; rng(20260617,'twister');
m=20; c=3; per_class=50; n=c*per_class;
centres=0.2+rand(m,c); X=zeros(m,n); y=zeros(n,1);
for k=1:c
    idx=(k-1)*per_class+(1:per_class);
    X(:,idx)=max(0,bsxfun(@plus,centres(:,k),0.08*randn(m,per_class)));
    y(idx)=k;
end
nr=sqrt(sum(X.^2,1)); nr(nr==0)=1; X=bsxfun(@rdivide,X,nr);
labeled=false(n,1);
for k=1:c
    idx=find(y==k); idx=idx(randperm(length(idx)));
    labeled(idx(1:max(1,floor(0.10*length(idx)))))=true;
end
opts.graph_p=3; opts.lambda=100; opts.max_iter=50; opts.seed=20260617;
[pred,model]=pce_nmf(X,y,labeled,opts);
acc=mean(pred(~labeled)==y(~labeled));
fprintf('PCE-NMF synthetic smoke test\n');
fprintf('Samples: %d; classes: %d; labeled: %d\n',n,c,sum(labeled));
fprintf('Unlabeled ACC: %.4f\n',acc);
fprintf('Objective: %.6e -> %.6e\n',model.objective(1),model.objective(end));
fprintf('Runtime: %.3f s\n',model.runtime_sec);
assert(all(isfinite(model.objective)),'Objective contains NaN or Inf.');
assert(model.objective(end)<=model.objective(1)*(1+1e-10), ...
    'Final objective exceeds the initial objective.');
