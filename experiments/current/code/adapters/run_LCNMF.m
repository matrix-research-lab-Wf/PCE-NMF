function [pred,info] = run_LCNMF(X,y,labeled,W0,H0,opt)
% Author LCNMF update semantics with injected paired initialization.
t0=tic; small=1e-12; n=length(y); c=size(H0,1); L=find(labeled); Uidx=find(~labeled);
perm=[L;Uidx]; invperm=zeros(n,1); invperm(perm)=1:n;
Xp=X(:,perm); yp=y(perm); W=max(W0,small); H=max(H0(:,perm)',small);
Y=zeros(length(L),c); idx=sub2ind(size(Y),(1:length(L))',yp(1:length(L))); Y(idx)=1;
for it=1:opt.max_iter
    H(1:length(L),:)=H(1:length(L),:).*Y;
    W=W.*((Xp*H)./max(W*(H'*H),small));
    H=H.*((Xp'*W)./max(H*(W'*W),small));
end
[dummy,p]=max(H,[],2); %#ok<ASGLU>
pred=p(invperm);
info.iterations=it; info.runtime_sec=toc(t0); info.init_mode='exact_common_W0_H0_protocol_adaptation';
info.U=W; info.V=H(invperm,:);
info.parameter_tag='author-objective-and-updates_no_tuned_parameter';
info.source_id='LCNMF_commit_7a53ca760a648122e1c71651fdf36f0d23e3225e';
end
