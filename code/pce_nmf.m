function [pred, model] = pce_nmf(X, y, labeled, opts)
%PCE_NMF Propagated class-exclusion non-negative matrix factorization.
% X is m-by-n with samples in columns; y uses labels 1,...,c.
% Required/optional OPTS fields: graph_p, lambda, max_iter, seed, W0, H0.
% Compatible with MATLAB R2019a; no toolbox is required.

if nargin < 4 || isempty(opts), opts = struct; end
if ~isfield(opts,'graph_p'), opts.graph_p = 3; end
if ~isfield(opts,'lambda'), opts.lambda = 100; end
if ~isfield(opts,'max_iter'), opts.max_iter = 50; end
if ~isfield(opts,'seed'), opts.seed = 20260617; end
validate_inputs(X,y,labeled,opts);

X = double(X); y = double(y(:)); labeled = logical(labeled(:));
[m,n] = size(X); c = max(y); small = 1e-12;
col_norms=sqrt(sum(X.^2,1)); nz=col_norms>small;
if any(abs(col_norms(nz)-1)>1e-8)
    error('PCE:Normalization', ...
        'Nonzero sample columns must have unit Euclidean norm.');
end
if isfield(opts,'W0') && ~isempty(opts.W0)
    U = max(double(opts.W0),small);
else
    rng(opts.seed,'twister'); U = max(rand(m,c),small);
end
if isfield(opts,'H0') && ~isempty(opts.H0)
    V = max(double(opts.H0'),small);
else
    rng(opts.seed+1,'twister'); V = max(rand(n,c),small);
end
if ~isequal(size(U),[m c]) || ~isequal(size(V),[n c])
    error('PCE:InitialSize','W0 must be m-by-c and H0 must be c-by-n.');
end

t0 = tic;
S = binary_knn_graph(X,opts.graph_p);
P = harmonic_evidence(S,labeled,y,c,small);
anchored = sum(P,2)>0;
Q = bsxfun(@times,double(anchored),1-P);
L = find(labeled); Q(L,:) = 0;
V(L,:) = V(L,:).*(1-Q(L,:));

% Hard labeled-support zeros are represented by a separate mask.
hard_zero=false(n,c); hard_zero(L,:)=true;
hard_zero(sub2ind([n c],L,y(L)))=false;
V(hard_zero)=0;

objective = zeros(opts.max_iter+1,1);
objective(1)=objective_value(X,U,V,Q,opts.lambda);
for it=1:opts.max_iter
    b = sum(Q.*(V.^2),1)';
    denU = U*(V'*V)+opts.lambda*bsxfun(@times,U,b');
    U = max(U.*((X*V)./max(denU,small)),small);
    a = sum(U.^2,1);
    penaltyV = Q.*V.*bsxfun(@times,ones(n,1),a);
    denV = V*(U'*U)+opts.lambda*penaltyV;
    V = max(V.*((X'*U)./max(denV,small)),small);
    V(hard_zero)=0;
    objective(it+1)=objective_value(X,U,V,Q,opts.lambda);
end

score = bsxfun(@times,V.^2,sum(U.^2,1));
[~,pred] = max(score,[],2);
model.U=U; model.V=V; model.P=P; model.Q=Q; model.graph=S;
model.score=score; model.objective=objective;
tol=1e-10*max(1,max(abs(objective(1:end-1))));
model.max_objective_increase=max(diff(objective));
model.monotone_with_tolerance=all(diff(objective)<=tol);
model.runtime_sec=toc(t0); model.options=opts;
end

function f=objective_value(X,U,V,Q,lambda)
R=X-U*V';
E=Q.*(V.^2).*bsxfun(@times,ones(size(V,1),1),sum(U.^2,1));
f=sum(R(:).^2)+lambda*sum(E(:));
end

function validate_inputs(X,y,labeled,opts)
if ~isnumeric(X) || ~ismatrix(X) || isempty(X) || ...
        any(~isfinite(X(:))) || any(X(:)<0)
    error('PCE:Input','X must be a finite non-negative matrix.');
end
n=size(X,2); y=y(:); labeled=labeled(:);
if length(y)~=n || length(labeled)~=n
    error('PCE:Input','Y and LABELED must contain one entry per sample.');
end
classes=unique(y);
if isempty(classes) || any(classes(:)'~=1:length(classes)) || ...
        any(~isfinite(y)) || any(y~=round(y))
    error('PCE:Labels','Y must use consecutive integer labels 1,...,c.');
end
for k=1:length(classes)
    if ~any(logical(labeled)&y==k)
        error('PCE:Labels','Each class must contain a labeled sample.');
    end
end
if opts.graph_p<1 || opts.graph_p>=n || opts.graph_p~=round(opts.graph_p)
    error('PCE:Option','graph_p must be an integer in [1,n-1].');
end
if opts.lambda<0 || ~isfinite(opts.lambda)
    error('PCE:Option','lambda must be finite and non-negative.');
end
if opts.max_iter<1 || opts.max_iter~=round(opts.max_iter)
    error('PCE:Option','max_iter must be a positive integer.');
end
end

function S=binary_knn_graph(X,p)
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

function P=harmonic_evidence(S,labeled,y,c,small)
n=length(y); P=zeros(n,c); L=find(labeled);
P(sub2ind([n c],L,y(L)))=1;
component=graph_components(S); ids=unique(component);
for z=1:length(ids)
    nodes=find(component==ids(z));
    if ~any(labeled(nodes)) || all(labeled(nodes)), continue; end
    Wc=S(nodes,nodes); d=full(sum(Wc,2));
    Lap=spdiags(d,0,length(nodes),length(nodes))-Wc;
    il=find(labeled(nodes)); iu=find(~labeled(nodes));
    Yl=zeros(length(il),c);
    Yl(sub2ind(size(Yl),(1:length(il))',y(nodes(il))))=1;
    F=-(Lap(iu,iu)+small*speye(length(iu)))\(Lap(iu,il)*Yl);
    F(F<0)=0; rs=sum(F,2); good=rs>small;
    F(good,:)=bsxfun(@rdivide,F(good,:),rs(good));
    P(nodes(iu),:)=F;
end
end

function component=graph_components(S)
n=size(S,1); component=zeros(n,1); queue=zeros(n,1); count=0;
for start=1:n
    if component(start)~=0, continue; end
    count=count+1; head=1; tail=1; queue(1)=start; component(start)=count;
    while head<=tail
        v=queue(head); head=head+1; nb=find(S(v,:)>0);
        for j=1:length(nb)
            u=nb(j);
            if component(u)==0
                tail=tail+1; queue(tail)=u; component(u)=count;
            end
        end
    end
end
end
