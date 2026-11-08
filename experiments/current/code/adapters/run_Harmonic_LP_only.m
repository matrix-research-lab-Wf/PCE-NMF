function [pred,info] = run_Harmonic_LP_only(X,y,labeled,opt)
%RUN_HARMONIC_LP_ONLY Harmonic label propagation without NMF.
% MATLAB R2019a compatible. The graph and component-wise Dirichlet solve
% are identical to PCE-NMF. For an unanchored connected component, predict
% the most frequent labeled class (ties go to the smallest class index).

t0=tic; small=1e-12; n=numel(y); c=max(y);
p=opt.graph_p(opt.dataset_index);
S=local_binary_knn(X,p);
P=local_harmonic(S,labeled,y,c,small);
[row_sum,pred]=max(P,[],2);

counts=accumarray(y(labeled),1,[c 1]);
[~,fallback_class]=max(counts);
unanchored=(row_sum<=small);
pred(unanchored)=fallback_class;

info.runtime_sec=toc(t0);
info.iterations=1;
info.coverage=mean(~unanchored(~labeled));
info.n_unanchored=sum(unanchored & ~labeled);
info.fallback_class=fallback_class;
info.parameter_tag=sprintf('binary_union_knn_p%d_component_harmonic_prior_fallback',p);
info.source_id='PCE_graph_and_harmonic_field_LP_only_control';
if isfield(opt,'trace_prediction') && opt.trace_prediction
    info.harmonic_field=P;
end
end

function P=local_harmonic(S,labeled,y,c,small)
n=numel(y); P=zeros(n,c); L=find(labeled);
P(sub2ind([n c],L,y(L)))=1;
comp=local_components(S); ids=unique(comp);
for z=1:numel(ids)
    nodes=find(comp==ids(z)); lab=nodes(labeled(nodes));
    unlab=nodes(~labeled(nodes));
    if isempty(lab) || isempty(unlab), continue; end
    Wc=S(nodes,nodes); d=full(sum(Wc,2));
    Lap=spdiags(d,0,numel(nodes),numel(nodes))-Wc;
    islab=labeled(nodes); il=find(islab); iu=find(~islab);
    Yl=zeros(numel(il),c);
    Yl(sub2ind(size(Yl),(1:numel(il))',y(nodes(il))))=1;
    F=-(Lap(iu,iu)+small*speye(numel(iu)))\(Lap(iu,il)*Yl);
    F(F<0)=0; rs=sum(F,2); good=rs>small;
    F(good,:)=bsxfun(@rdivide,F(good,:),rs(good));
    P(nodes(iu),:)=F;
end
end

function comp=local_components(S)
n=size(S,1); comp=zeros(n,1); queue=zeros(n,1); cc=0;
for start=1:n
    if comp(start)~=0, continue; end
    cc=cc+1; head=1; tail=1; queue(1)=start; comp(start)=cc;
    while head<=tail
        v=queue(head); head=head+1; nb=find(S(v,:)>0);
        for j=1:numel(nb)
            u=nb(j);
            if comp(u)==0
                tail=tail+1; queue(tail)=u; comp(u)=cc;
            end
        end
    end
end
end

function S=local_binary_knn(X,p)
n=size(X,2); block=128; x2=sum(X.^2,1)';
rows=zeros(n*p,1); cols=zeros(n*p,1); ptr=0;
for first=1:block:n
    last=min(n,first+block-1); B=X(:,first:last);
    D=bsxfun(@plus,x2,sum(B.^2,1))-2*(X'*B); D(D<0)=0;
    for j=1:(last-first+1), D(first+j-1,j)=Inf; end
    [~,ord]=sort(D,1,'ascend'); ord=ord(1:p,:);
    for j=1:(last-first+1)
        i=first+j-1; rows(ptr+1:ptr+p)=i;
        cols(ptr+1:ptr+p)=ord(:,j); ptr=ptr+p;
    end
end
A=sparse(rows,cols,1,n,n); S=spones(A+A');
end
