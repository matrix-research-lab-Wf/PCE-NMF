function [pred,info] = run_PCE_HCE_FORMAL_CORE_STABILIZED(X,y,labeled,U0,V0,opt,lambda)
% Stabilized PCE/HCE core using (L_UU + 1e-12 I) in the harmonic solve.
t0=tic; small=1e-12; c=size(V0,2); p=opt.graph_p(opt.dataset_index);
if islogical(labeled), labeled=find(labeled); else, labeled=labeled(:); end
persistent cache_dataset cache_p cache_W cache_L
if isempty(cache_dataset) || ~strcmp(cache_dataset,opt.dataset) || cache_p~=p
    cache_W=local_binary_cosine_pnn(X,p);
    D=full(sum(cache_W,2)); cache_L=spdiags(D,0,size(X,2),size(X,2))-cache_W;
    cache_dataset=opt.dataset; cache_p=p;
end
[Qeff,coverage]=local_harmonic_exclusion(cache_W,cache_L,labeled,y,c,small);
[U,V,objective_trace]=local_train_pce_lowmem(X,labeled,y,U0,V0,Qeff,lambda,50,small);
pred=local_energy_argmax(U,V);
info.iterations=50; info.runtime_sec=toc(t0); info.anchor_coverage=coverage;
info.objective_trace=objective_trace;
info.U=U; info.V=V;
info.Qeff=Qeff;
info.init_mode='formal_seed_plus_97_rand_plus_0p01';
if lambda==0, info.parameter_tag='HCE_lambda0'; info.source_id='formal_core_HCE';
else, info.parameter_tag='PCE_lambda100'; info.source_id='formal_core_PCE'; end
end

function W=local_binary_cosine_pnn(X,p)
n=size(X,2); block_size=32; rows=zeros(n*p,1); cols=zeros(n*p,1); ptr=0;
for first=1:block_size:n
    last=min(n,first+block_size-1); S=X'*X(:,first:last);
    for local_col=1:(last-first+1)
        i=first+local_col-1; S(i,local_col)=-Inf;
        [dummy,ord]=sort(S(:,local_col),'descend'); %#ok<ASGLU>
        nb=ord(1:p); rows(ptr+1:ptr+p)=i; cols(ptr+1:ptr+p)=nb; ptr=ptr+p;
    end
end
A=sparse(rows,cols,1,n,n); W=spones(A+A'); W=W-spdiags(diag(W),0,n,n); W=spones(W);
end

function [Qeff,coverage]=local_harmonic_exclusion(W,L,labeled,y,c,small)
n=size(W,1); is_labeled=false(n,1); is_labeled(labeled)=true;
C=zeros(length(labeled),c); idx=sub2ind(size(C),(1:length(labeled))',y(labeled)); C(idx)=1;
Qeff=zeros(n,c); component=local_components(W); anchored=0; total=sum(~is_labeled);
for comp=1:max(component)
    nodes=find(component==comp); lab_nodes=nodes(is_labeled(nodes)); unlab_nodes=nodes(~is_labeled(nodes));
    if isempty(unlab_nodes), continue; end
    if isempty(lab_nodes), continue; end
    anchored=anchored+length(unlab_nodes); [dummy,loc_lab]=ismember(lab_nodes,labeled); %#ok<ASGLU>
    Luu=L(unlab_nodes,unlab_nodes);
    Pcomp=(Luu+small*speye(length(unlab_nodes)))\ ...
        (W(unlab_nodes,lab_nodes)*C(loc_lab,:));
    if any(~isfinite(Pcomp(:))), error('Nonfinite harmonic solution.'); end
    Pcomp(Pcomp<0 & Pcomp>-1e-10)=0;
    if min(Pcomp(:))<-1e-8, error('Materially negative harmonic solution.'); end
    Pcomp(Pcomp<0)=0; rowsum=sum(Pcomp,2);
    if any(rowsum<=small), error('Harmonic row sum is numerically zero.'); end
    Pcomp=Pcomp./repmat(rowsum,1,c); Qeff(unlab_nodes,:)=1-Pcomp;
end
if total==0, coverage=1; else, coverage=anchored/total; end
end

function component=local_components(W)
n=size(W,1); component=zeros(n,1); queue=zeros(n,1); cc=0;
for start=1:n
    if component(start)~=0, continue; end
    cc=cc+1; head=1; tail=1; queue(1)=start; component(start)=cc;
    while head<=tail
        v=queue(head); head=head+1; nb=find(W(v,:)>0);
        for j=1:length(nb)
            u=nb(j); if component(u)==0, tail=tail+1; queue(tail)=u; component(u)=cc; end
        end
    end
end
end

function [U,V,objective_trace]=local_train_pce_lowmem(X,labeled,y,U0,V0,Qeff,lambda,maxiter,small)
U=max(U0,small); V=max(V0,small); n=size(V,1); c=size(V,2);
for t=1:length(labeled), row=labeled(t); yi=y(row); V(row,:)=0; V(row,yi)=max(V0(row,yi),small); end
objective_trace=zeros(maxiter+1,1);
objective_trace(1)=local_objective(X,U,V,Qeff,lambda);
block_size=64;
for it=1:maxiter
    b=zeros(c,1);
    for k=1:c, vk=V(:,k); b(k)=sum(Qeff(:,k).*(vk.^2)); end
    numU=X*V; denU=U*(V'*V)+lambda*(U.*repmat(b',size(U,1),1));
    U=U.*(numU./max(denU,small)); U=max(U,small);
    a=sum(U.^2,1); UtU=U'*U;
    for first=1:block_size:n
        last=min(n,first+block_size-1); ids=first:last; numB=X(:,ids)'*U;
        denB=V(ids,:)*UtU+lambda*((Qeff(ids,:).*V(ids,:)).*repmat(a,length(ids),1));
        V(ids,:)=V(ids,:).*(numB./max(denB,small)); V(ids,:)=max(V(ids,:),small);
    end
    for t=1:length(labeled), row=labeled(t); yi=y(row); keep=V(row,yi); V(row,:)=0; V(row,yi)=max(keep,small); end
    objective_trace(it+1)=local_objective(X,U,V,Qeff,lambda);
end
end

function f=local_objective(X,U,V,Qeff,lambda)
UtU=U'*U; VtV=V'*V;
fit=sum(X(:).^2)-2*sum(sum(U.*(X*V)))+sum(sum(UtU.*VtV));
a=sum(U.^2,1);
penalty=lambda*sum(sum(Qeff.*(V.^2).*repmat(a,size(V,1),1)));
f=max(fit,0)+penalty;
end

function pred=local_energy_argmax(U,V)
n=size(V,1); a=sum(U.^2,1); best=-Inf(n,1); pred=ones(n,1);
for k=1:size(V,2), s=a(k)*(V(:,k).^2); idx=s>best; best(idx)=s(idx); pred(idx)=k; end
end
