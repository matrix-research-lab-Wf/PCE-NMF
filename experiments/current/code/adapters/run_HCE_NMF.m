function [pred,info] = run_HCE_NMF(X,y,labeled,W0,H0,opt)
%RUN_HCE_NMF Hard class-exclusion control matched to run_PCE_NMF.
% Removes only the propagated exclusion penalty (lambda=0), while retaining
% the same initialization, 50 multiplicative-update iterations, hard labeled
% support, and scale-invariant contribution-energy decision.
t0=tic; small=1e-12; n=numel(y); c=size(H0,1); L=find(labeled);
U=max(W0,small); V=max(H0',small);
Qlabel=ones(numel(L),c); Qlabel(sub2ind(size(Qlabel),(1:numel(L))',y(L)))=0;
V(L,:)=V(L,:).*(1-Qlabel);
for it=1:50
    U=U.*((X*V)./max(U*(V'*V),small)); U=max(U,small);
    V=V.*((X'*U)./max(V*(U'*U),small)); V=max(V,small);
    V(L,:)=V(L,:).*(1-Qlabel);
end
score=bsxfun(@times,V.^2,sum(U.^2,1)); [~,pred]=max(score,[],2);
info.iterations=it; info.runtime_sec=toc(t0);
info.parameter_tag='lambda0_hard_support_matched_PCE';
info.source_id='controlled_HCE_ablation';
end
