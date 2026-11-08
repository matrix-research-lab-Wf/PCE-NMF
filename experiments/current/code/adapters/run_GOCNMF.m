function [pred,info] = run_GOCNMF(X,y,labeled,W0,H0,opt)
% Public GOCNMF update semantics with paired initialization adaptation.
t0=tic; small=1e-12; n=length(y); c=size(H0,1); L=find(labeled); Uidx=find(~labeled);
perm=[L;Uidx]; invperm=zeros(n,1); invperm(perm)=1:n; Xp=X(:,perm); yp=y(perm);
p=opt.goc_p(opt.dataset_index); persistent cache_dataset cache_p cache_S
if isempty(cache_dataset) || ~strcmp(cache_dataset,opt.dataset) || cache_p~=p, cache_S=local_binary_knn(X,p); cache_dataset=opt.dataset; cache_p=p; end
S=cache_S(perm,perm); degree=full(sum(S,2));
U=max(W0,small); V=max(H0(:,perm)',small); C=zeros(length(L),c);
idx=sub2ind(size(C),(1:length(L))',yp(1:length(L))); C(idx)=1;
alpha=opt.goc_alpha(opt.dataset_index);
for it=1:50
    V(1:length(L),:)=C;
    U=U.*((Xp*V)./max(U*(V'*V),small));
    V=V.*((Xp'*U+alpha*(S*V))./max(V*(U'*U)+alpha*bsxfun(@times,degree,V),small));
end
[dummy,predp]=max(V,[],2); %#ok<ASGLU>
pred=predp(invperm);
info.iterations=it; info.runtime_sec=toc(t0);
info.U=U; info.V=V(invperm,:);
info.init_mode='exact_common_W0_H0_protocol_adaptation';
info.parameter_tag=opt.goc_parameter_tag{opt.dataset_index};
info.source_id='public_GOCNMF_semantics_local_verified_gate';
end

function S=local_binary_knn(X,p)
n=size(X,2); block=128; x2=sum(X.^2,1)'; rows=zeros(n*p,1); cols=zeros(n*p,1); ptr=0;
for first=1:block:n
    last=min(n,first+block-1); B=X(:,first:last);
    D=bsxfun(@plus,x2,sum(B.^2,1))-2*(X'*B); D(D<0)=0;
    for j=1:(last-first+1), D(first+j-1,j)=Inf; end
    [dummy,ord]=sort(D,1,'ascend'); %#ok<ASGLU>
    ord=ord(1:p,:);
    for j=1:(last-first+1), i=first+j-1; rows(ptr+1:ptr+p)=i; cols(ptr+1:ptr+p)=ord(:,j); ptr=ptr+p; end
end
A=sparse(rows,cols,1,n,n); S=spones(A+A');
end
