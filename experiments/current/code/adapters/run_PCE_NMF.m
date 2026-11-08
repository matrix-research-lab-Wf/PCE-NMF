function [pred,info] = run_PCE_NMF(X,y,labeled,W0,H0,opt)
% Frozen PCE objective:
% ||X-UV'||_F^2 + lambda*sum_ik Q_ik*||u_k||_2^2*v_ik^2.
t0=tic; small=1e-12; n=length(y); c=size(H0,1); p=opt.graph_p(opt.dataset_index);
persistent cache_dataset cache_p cache_S
if isempty(cache_dataset) || ~strcmp(cache_dataset,opt.dataset) || cache_p~=p, cache_S=local_binary_knn(X,p); cache_dataset=opt.dataset; cache_p=p; end
S=cache_S; P=local_harmonic(S,labeled,y,c,small); mask=sum(P,2)>0;
Q=bsxfun(@times,double(mask),1-P); L=find(labeled); Q(L,:)=1; idx=sub2ind([n c],L,y(L)); Q(idx)=0;
U=max(W0,small); V=max(H0',small); V(L,:)=V(L,:).*(1-Q(L,:)); lambda=opt.pce_lambda;
trace_enabled=isfield(opt,'trace_objective') && opt.trace_objective;
if trace_enabled
    objective_trace=zeros(51,1); constraint_trace=zeros(51,1);
    [objective_trace(1),constraint_trace(1)]=local_diagnostics(X,U,V,Q,lambda,L);
end
for it=1:50
    b=sum(Q.*(V.^2),1)';
    U=U.*((X*V)./max(U*(V'*V)+lambda*bsxfun(@times,U,b'),small)); U=max(U,small);
    a=sum(U.^2,1);
    V=V.*((X'*U)./max(V*(U'*U)+lambda*(Q.*V.*bsxfun(@times,ones(n,1),a)),small));
    V=max(V,small); V(L,:)=V(L,:).*(1-Q(L,:));
    if trace_enabled
        [objective_trace(it+1),constraint_trace(it+1)]=local_diagnostics(X,U,V,Q,lambda,L);
    end
end
score=bsxfun(@times,V.^2,sum(U.^2,1)); [dummy,pred]=max(score,[],2); %#ok<ASGLU>
info.iterations=it; info.runtime_sec=toc(t0); info.init_mode='exact_common_W0_H0';
info.parameter_tag='frozen_lambda100_labeled_only_selection'; info.source_id='frozen_PCE_objective';
if isfield(opt,'trace_prediction') && opt.trace_prediction
    info.class_energy=score;
    info.basis=U;
    info.coefficients=V;
end
if trace_enabled
    info.objective_trace=objective_trace;
    info.constraint_trace=constraint_trace;
end
end

function [f,violation]=local_diagnostics(X,U,V,Q,lambda,L)
% 与训练目标一致；仅在诊断开关打开时额外计算。
UtU=U'*U; VtV=V'*V;
fit=sum(X(:).^2)-2*sum(sum(U.*(X*V)))+sum(sum(UtU.*VtV));
penalty=lambda*sum(sum(Q.*(V.^2).*repmat(sum(U.^2,1),size(V,1),1)));
f=fit+penalty;
forbidden=V(L,:).*Q(L,:);
violation=max([0;-U(:);-V(:);abs(forbidden(:))]);
end

function P=local_harmonic(S,labeled,y,c,small)
n=length(y); P=zeros(n,c); L=find(labeled); idx=sub2ind([n c],L,y(L)); P(idx)=1;
comp=local_components(S); ids=unique(comp);
for z=1:length(ids)
    nodes=find(comp==ids(z)); lab=nodes(labeled(nodes)); unlab=nodes(~labeled(nodes));
    if isempty(lab) || isempty(unlab), continue; end
    Wc=S(nodes,nodes); d=full(sum(Wc,2)); Lap=spdiags(d,0,length(nodes),length(nodes))-Wc;
    islab=labeled(nodes); il=find(islab); iu=find(~islab); Yl=zeros(length(il),c);
    idy=sub2ind(size(Yl),(1:length(il))',y(nodes(il))); Yl(idy)=1;
    F=-(Lap(iu,iu)+small*speye(length(iu)))\(Lap(iu,il)*Yl); F(F<0)=0;
    rs=sum(F,2); good=rs>small; F(good,:)=bsxfun(@rdivide,F(good,:),rs(good)); P(nodes(iu),:)=F;
end
end

function comp=local_components(S)
n=size(S,1); comp=zeros(n,1); queue=zeros(n,1); cc=0;
for start=1:n
    if comp(start)~=0, continue; end
    cc=cc+1; head=1; tail=1; queue(1)=start; comp(start)=cc;
    while head<=tail
        v=queue(head); head=head+1; nb=find(S(v,:)>0);
        for j=1:length(nb), u=nb(j); if comp(u)==0, tail=tail+1; queue(tail)=u; comp(u)=cc; end, end
    end
end
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
