function run_PCE_scalability_R2019a(class_counts,method_ids,seeds)
%RUN_PCE_SCALABILITY_R2019A 锁定的 COIL100 规模实验，兼容 MATLAB R2019a。
% 入口示例：run_PCE_scalability_R2019a(20,[9 8 6],20261029)
% class_counts: 20、40、60、80、100；method_ids: 9 PCE、8 HLP、6 GOC。
cfg=rebuild_config(); d=6;
if nargin<1||isempty(class_counts),class_counts=[20 40 60 80 100];end
if nargin<2||isempty(method_ids),method_ids=[9 8 6];end
if nargin<3||isempty(seeds),seeds=cfg.seeds_formal;end
if any(~ismember(class_counts,[20 40 60 80 100]))||...
   any(~ismember(method_ids,[9 8 6]))||any(~ismember(seeds,cfg.seeds_formal))
    error('Outside locked scalability protocol.');
end
addpath(cfg.adapter_dir);addpath(cfg.hlpnmf_dir);
S=load(fullfile(cfg.data_dir,'COIL100.mat'));
if isfield(S,'fea'),X=double(S.fea');else,X=double(S.X');end
if isfield(S,'gnd'),y=double(S.gnd(:));else,y=double(S.Y(:));end
if size(X,2)~=numel(y),X=X';end
[~,~,y]=unique(y);
if ~isequal(size(X),[1024 7200])||max(y)~=100||...
   any(accumarray(y,1,[100 1])~=72)||any(~isfinite(X(:)))||any(X(:)<0)
    error('COIL100 identity or class balance changed.');
end
nr=sqrt(sum(X.^2,1));nr(nr==0)=1;X=bsxfun(@rdivide,X,nr);
out=fullfile(cfg.results_dir,'scalability');if exist(out,'dir')~=7,mkdir(out);end
file=fullfile(out,'raw.csv');
if exist(file,'file')~=2
    fid=fopen(file,'w');fprintf(fid,['class_count,n_samples,seed,method,ACC,NMI,' ...
      'wall_seconds,data_bytes,dense_graph_bytes,status,message\n']);fclose(fid);
end
done=containers.Map('KeyType','char','ValueType','logical');
T=readtable(file,'Delimiter',',');
for i=1:height(T)
    done(sprintf('%d|%d|%s',T.class_count(i),T.seed(i),T.method{i}))=true;
end
for count=class_counts
    idx=find(y<=count);Xs=X(:,idx);ys=y(idx);[m,n]=size(Xs);
    if n~=72*count||max(ys)~=count,error('Subset identity changed.');end
    data_bytes=8*numel(Xs);dense_graph_bytes=8*n*n;
    for seed=seeds
        rng(seed,'twister');labeled=false(n,1);
        for k=1:count
            j=find(ys==k);j=j(randperm(numel(j)));
            labeled(j(1:floor(.10*numel(j))))=true;
        end
        unlabeled=~labeled;W0=max(rand(m,count),eps);H0=max(rand(count,n),eps);
        for method_id=method_ids
            method=cfg.methods{method_id};key=sprintf('%d|%d|%s',count,seed,method);
            if isKey(done,key),continue;end
            status='OK';message='';acc=NaN;nmi=NaN;wall=NaN;
            try
                opt=cfg;opt.dataset='COIL100';opt.dataset_index=d;opt.seed=seed;
                if method_id==9
                    opt.graph_p=cfg.pce_p_locked;
                    opt.pce_lambda=cfg.pce_lambda_locked(d);
                else
                    opt.graph_p=cfg.graph_p;
                end
                % 清除适配器的持久图缓存，保证每次计时含图构建且规模切换不复用旧图。
                clear run_PCE_NMF run_GOCNMF
                rng(seed,'twister');tick=tic;
                [pred,~]=feval(['run_' method],Xs,ys,labeled,W0,H0,opt);
                wall=toc(tick);pred=pred(:);
                if numel(pred)~=n||any(~isfinite(pred)),error('Invalid prediction.');end
                M=pce_clustering_metrics(ys(unlabeled),pred(unlabeled));
                acc=M.ACC;nmi=M.NMI;
                if ~all(isfinite([acc nmi wall])),error('Nonfinite result.');end
            catch err
                status='FAILED';message=err.message;
            end
            fid=fopen(file,'a');
            fprintf(fid,'%d,%d,%d,%s,%.17g,%.17g,%.17g,%.17g,%.17g,%s,%s\n',...
                count,n,seed,method,acc,nmi,wall,data_bytes,dense_graph_bytes,...
                status,strrep(strrep(message,',',';'),sprintf('\n'),' '));
            fclose(fid);done(key)=true;
            fprintf('COIL100 c=%d seed=%d %s ACC=%.5f NMI=%.5f wall=%.2fs %s\n',...
                count,seed,method,acc,nmi,wall,status);
            if ~strcmp(status,'OK'),error('Scalability block failed: %s',message);end
        end
    end
end
end
