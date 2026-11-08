function pred = pce_kmeans_eval(H,y,labeled,seed,nstarts,map_labels)
% Deterministic multi-start k-means; permutation matching is evaluation-only.
if nargin<5 || isempty(nstarts), nstarts=20; end
if nargin<6 || isempty(map_labels), map_labels=true; end
n=size(H,1); c=length(unique(y)); best=Inf; bestidx=ones(n,1);
h2=sum(H.^2,2); blockSize=512;
for r=1:nstarts
    rand('twister',seed+10000+r-1); order=randperm(n); C=H(order(1:c),:); idx=zeros(n,1);
    for it=1:100
        c2=sum(C.^2,2)'; mind=zeros(n,1); newidx=zeros(n,1);
        for first=1:blockSize:n
            ids=first:min(n,first+blockSize-1);
            d=bsxfun(@plus,h2(ids),c2)-2*(H(ids,:)*C'); d(d<0)=0;
            [mind(ids),newidx(ids)]=min(d,[],2);
        end
        if all(newidx==idx), break; end
        idx=newidx;
        for k=1:c
            q=find(idx==k); if isempty(q), [dummy,j]=max(mind); C(k,:)=H(j,:); else, C(k,:)=mean(H(q,:),1); end %#ok<ASGLU>
        end
    end
    score=sum(mind);
    if score<best, best=score; bestidx=idx; end
end
pred=bestidx;
if map_labels
    U=find(~labeled); pred(U)=bestMap(y(U),bestidx(U));
end
end
