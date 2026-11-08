function [pred,info] = run_CNMF(X,y,labeled,W0,H0,opt)
t0=tic; small=1e-12; n=length(y); c=size(H0,1); Uidx=find(~labeled); q=c+length(Uidx);
col=zeros(n,1); L=find(labeled); col(L)=y(L); col(Uidx)=c+(1:length(Uidx))';
A=sparse((1:n)',col,1,n,q); diagAtA=full(sum(A,1))';
U=max(W0,small); rand('twister',opt.seed+197); Z=rand(q,c)+0.01;
for it=1:200
    V=A*Z; U=U.*((X*V)./max(U*(V'*V),small));
    Z=Z.*((A'*(X'*U))./max(bsxfun(@times,diagAtA,Z)*(U'*U),small));
end
V=A*Z; pred=pce_kmeans_eval(V,y,labeled,opt.seed+20000,50);
info.iterations=it; info.runtime_sec=toc(t0); info.init_mode='common_U0_seed_aligned_Z0';
info.parameter_tag='source-aligned_200iter_kmeans50'; info.source_id='local_verified_section52_CNMF';
end
