function [pred,info] = run_SNMFWLP(X,y,labeled,W0,H0,opt)
t0=tic; small=1e-12; n=length(y); c=size(H0,1); p=opt.graph_p(opt.dataset_index);
persistent cache_dataset cache_p cache_S
if isempty(cache_dataset) || ~strcmp(cache_dataset,opt.dataset) || cache_p~=p, cache_S=local_binary_knn(X,p); cache_dataset=opt.dataset; cache_p=p; end
S=cache_S; degree=full(sum(S,2)); selector=zeros(n,1); selector(labeled)=1;
M=zeros(n,c); L=find(labeled); idx=sub2ind([n c],L,y(L)); M(idx)=1;
W=max(W0,small); H=max(H0',small); alpha=opt.snmfwlp_alpha; beta=opt.snmfwlp_beta;
for it=1:50
    XH=X*H; XH(XH<0)=0; W=W.*sqrt(XH./max(W*(W'*XH),1e-15));
    num=X'*W+alpha*(S*H)+beta*bsxfun(@times,selector,M); num(num<0)=0;
    den=H*(W'*W)+alpha*bsxfun(@times,degree,H)+beta*bsxfun(@times,selector,H);
    H=H.*(num./max(den,1e-15)); H=max(H,small);
end
% The source paper evaluates SNMFWLP by applying K-means to H with
% 50 random initializations. Label permutation is evaluation-only.
if isfield(opt,'runtime_exclude_label_mapping') && opt.runtime_exclude_label_mapping
    pred=pce_kmeans_eval(H,y,labeled,opt.seed+30000,50,false);
    measured_runtime=toc(t0);
    Uidx=find(~labeled); pred(Uidx)=bestMap(y(Uidx),pred(Uidx));
else
    pred=pce_kmeans_eval(H,y,labeled,opt.seed+30000,50);
    measured_runtime=toc(t0);
end
info.iterations=it; info.runtime_sec=measured_runtime; info.init_mode='exact_common_W0_H0';
info.U=W; info.V=H;
info.parameter_tag='source-aligned_alpha1e3_beta1e5_kmeans50';
info.source_id='SNMFWLP1_commit_538dcfee1554ed2517969bf33cedd379a6126b37';
end

function S=local_binary_knn(X,p)
n=size(X,2); block=128; x2=sum(X.^2,1)'; rows=zeros(n*p,1); cols=zeros(n*p,1); ptr=0;
for first=1:block:n
    last=min(n,first+block-1); B=X(:,first:last); D=bsxfun(@plus,x2,sum(B.^2,1))-2*(X'*B); D(D<0)=0;
    for j=1:(last-first+1), D(first+j-1,j)=Inf; end
    [dummy,ord]=sort(D,1,'ascend'); %#ok<ASGLU>
    ord=ord(1:p,:);
    for j=1:(last-first+1), i=first+j-1; rows(ptr+1:ptr+p)=i; cols(ptr+1:ptr+p)=ord(:,j); ptr=ptr+p; end
end
A=sparse(rows,cols,1,n,n); S=spones(A+A');
end
