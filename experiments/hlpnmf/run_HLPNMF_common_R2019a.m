function run_HLPNMF_common_R2019a(mode)
% MATLAB R2019a；原封不动调用作者求解器，统一划分及评价。
if nargin<1, mode='smoke'; end
script_dir=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(script_dir));
src=fullfile(repo,'third_party','HLPNMF');
data_dir=fullfile(repo,'data');
out=fullfile(repo,'results','hlpnmf','rerun');
if ~exist(out,'dir'), mkdir(out); end
if exist(fullfile(src,'HLPNMF.m'),'file')~=2
    error('HLPNMF:missingSource',['Place the frozen HLPNMF author source at ' ...
        'third_party/HLPNMF; see docs/hlpnmf/SOURCE_AUDIT.md.']);
end
if exist(data_dir,'dir')~=7
    error('HLPNMF:missingData',['Create data/ with the six MAT files described ' ...
        'in docs/DATASETS.md.']);
end
addpath(src);
diary(fullfile(out,'console.txt')); clean=onCleanup(@()diary('off')); %#ok<NASGU>
if strcmp(mode,'smoke'), seeds=20260627; elseif strcmp(mode,'formal'), seeds=20260627:20260646; else, error('Unknown mode'); end
names={'YaleB','COIL20','Optdigits','ORL','PIE','COIL100'};
ps=[2 2 5 2 3 2]; ks=[3 3 1 3 5 3];
raw=fullfile(out,'raw.csv');
if ~exist(raw,'file')
    fid=fopen(raw,'w'); fprintf(fid,'dataset,seed,method,p,k,alpha,iterations,n_labeled,n_unlabeled,ACC,direct_ACC,NMI,runtime_seconds,finite,objective_increases,parameter_source,status\n'); fclose(fid);
end
for d=1:6
    S=load(fullfile(data_dir,[names{d} '.mat']));
    if isfield(S,'X'), X=double(S.X); else, X=double(S.fea)'; end
    if isfield(S,'y'), y=double(S.y(:)); else, y=double(S.gnd(:)); end
    if size(X,2)~=numel(y), X=X'; end
    [~,~,y]=unique(y); c=max(y); n=numel(y);
    norms=sqrt(sum(X.^2,1)); norms(norms==0)=1; X=bsxfun(@rdivide,X,norms);
    if any(~isfinite(X(:))) || any(X(:)<0), error('Invalid data'); end
    for seed=seeds
        T=readtable(raw,'Delimiter',',');
        if ~isempty(T) && any(strcmp(T.dataset,names{d}) & T.seed==seed & strcmp(T.status,'OK')), continue; end
        rand('twister',seed); randn('state',seed); %#ok<RAND>
        labeled=false(n,1);
        for j=1:c
            ids=find(y==j); ids=ids(randperm(numel(ids)));
            labeled(ids(1:max(1,floor(0.1*numel(ids)))))=true;
        end
        order=[find(labeled);find(~labeled)]; nl=sum(labeled);
        opt.maxIter=30; opt.p=ps(d); opt.k=ks(d); opt.alpha=1000;
        % 未标记标签以0传入；作者仅访问最前面的已标记行。
        observed=zeros(n,1); observed(labeled)=y(labeled);
        opt.SampNum=nl; opt.SampGnd=observed(order); opt.SelectClasses=c;
        rand('twister',seed); randn('state',seed); %#ok<RAND>
        fprintf('START %s seed=%d p=%d k=%d\n',names{d},seed,ps(d),ks(d));
        tic; [U,V,obj]=HLPNMF(X(:,order)',opt); elapsed=toc;
        [~,reordered]=max(V,[],2); pred=zeros(n,1); pred(order)=reordered;
        ids=find(~labeled); truth=y(ids); guess=pred(ids);
        acc=local_cluster_accuracy(truth,guess,c); direct=mean(guess==truth);
        M=full(sparse(truth,guess,1,c,c)); P=M/numel(ids); px=sum(P,2); py=sum(P,1);
        denom=px*py; nz=P>0; mi=sum(P(nz).*log(P(nz)./denom(nz)));
        hx=-sum(px(px>0).*log(px(px>0))); hy=-sum(py(py>0).*log(py(py>0)));
        if hx*hy>0, nmi=mi/sqrt(hx*hy); else, nmi=0; end
        finite=all(isfinite([U(:);V(:);obj(:);acc;nmi]));
        inc=sum(diff(obj)>1e-8*max(1,abs(obj(1:end-1))));
        tag='paper'; if d==3, tag='transfer_MNIST'; elseif d==4, tag='transfer_YaleB'; end
        status='OK'; if ~finite, status='FAILED'; end
        save(fullfile(out,sprintf('%s_%d.mat',names{d},seed)),'pred','labeled','order','obj','opt','acc','direct','nmi','elapsed','finite');
        fid=fopen(raw,'a'); fprintf(fid,'%s,%d,HLPNMF,%d,%d,1000,30,%d,%d,%.17g,%.17g,%.17g,%.9g,%d,%d,%s,%s\n',names{d},seed,ps(d),ks(d),nl,n-nl,acc,direct,nmi,elapsed,finite,inc,tag,status); fclose(fid);
        fprintf('DONE %s %d ACC=%.6f NMI=%.6f seconds=%.3f finite=%d\n',names{d},seed,acc,nmi,elapsed,finite);
        clear U V;
        if ~finite, error('Nonfinite trial'); end
    end
end
fprintf('HLPNMF_COMMON_%s_COMPLETE\n',upper(mode));
end

function acc=local_cluster_accuracy(ytrue,cluster,c)
ytrue=ytrue(:); cluster=cluster(:);
M=full(sparse(ytrue,cluster,1,c,c));
assignment=local_hungarian_min(max(M(:))-M);
correct=0;
for i=1:c
    j=assignment(i);
    if j>=1 && j<=c, correct=correct+M(i,j); end
end
acc=correct/length(ytrue);
end

function assignment=local_hungarian_min(cost)
% Square-cost shortest-augmenting-path Hungarian algorithm.
n=size(cost,1);
if size(cost,2)~=n, error('HLPNMF:hungarian','Cost matrix must be square.'); end
u=zeros(n,1); v=zeros(n+1,1); p=zeros(n+1,1); way=zeros(n+1,1);
for ii=1:n
    p(1)=ii; j0=1; minv=Inf(n+1,1); used=false(n+1,1);
    while true
        used(j0)=true; i0=p(j0); delta=Inf; j1=0;
        for j=2:(n+1)
            if ~used(j)
                cur=cost(i0,j-1)-u(i0)-v(j);
                if cur<minv(j), minv(j)=cur; way(j)=j0; end
                if minv(j)<delta, delta=minv(j); j1=j; end
            end
        end
        if j1==0 || ~isfinite(delta), error('HLPNMF:hungarian','Assignment failed.'); end
        for j=1:(n+1)
            if used(j)
                if p(j)>0, u(p(j))=u(p(j))+delta; end
                v(j)=v(j)-delta;
            elseif j>1
                minv(j)=minv(j)-delta;
            end
        end
        j0=j1;
        if p(j0)==0, break; end
    end
    while true
        j1=way(j0); p(j0)=p(j1); j0=j1;
        if j0==1, break; end
    end
end
assignment=zeros(n,1);
for j=2:(n+1)
    if p(j)>0, assignment(p(j))=j-1; end
end
end
