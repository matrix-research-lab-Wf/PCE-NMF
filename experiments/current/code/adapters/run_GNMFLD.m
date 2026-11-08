function [pred,info] = run_GNMFLD(X,y,labeled,W0,H0,opt)
% Source-aligned GNMFLD updates extracted from the verified local baseline.
t0=tic; small=1e-12; V=max(H0',small); U=max(W0,small); n=length(y); c=size(V,2);
persistent cache_dataset cache_S
if isempty(cache_dataset) || ~strcmp(cache_dataset,opt.dataset), cache_S=local_binary_knn(X,5); cache_dataset=opt.dataset; end
S=cache_S; degree=full(sum(S,2)); Y=zeros(n,c); mask=zeros(n,1);
L=find(labeled); mask(L)=1; idx=sub2ind([n c],L,y(L)); Y(idx)=1;
alpha=opt.gnmfld_alpha(opt.dataset_index); beta=opt.gnmfld_beta(opt.dataset_index);
for it=1:200
    U=U.*((X*V)./max(U*(V'*V),small));
    num=X'*U+alpha*Y+beta*(S*V);
    den=V*(U'*U)+alpha*bsxfun(@times,mask,V)+beta*bsxfun(@times,degree,V);
    V=V.*(num./max(den,small)); V=max(V,small);
end
[dummy,pred]=max(V,[],2); %#ok<ASGLU>
info.iterations=it; info.runtime_sec=toc(t0); info.init_mode='exact_common_W0_H0';
info.U=U; info.V=V;
info.parameter_tag=opt.gnmfld_parameter_tag{opt.dataset_index};
info.source_id='local_verified_run_three_direct_methods_R2009a';
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
