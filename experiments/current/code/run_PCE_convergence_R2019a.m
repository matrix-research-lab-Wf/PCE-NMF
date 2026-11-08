function run_PCE_convergence_R2019a()
%RUN_PCE_CONVERGENCE_R2019A 固定代表数据集的 PCE-NMF 数值收敛诊断。
% 入口：run_PCE_convergence_R2019a；输出：results/convergence/raw.csv。
cfg=rebuild_config(); addpath(cfg.adapter_dir);
ids=[1 2 5 6]; seed=20261029;
out_dir=fullfile(cfg.results_dir,'convergence');
if exist(out_dir,'dir')~=7, mkdir(out_dir); end
raw=fullfile(out_dir,'raw.csv');
fid=fopen(raw,'w'); assert(fid>0,'Cannot open convergence output.');
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'dataset,seed,iteration,objective,constraint_violation,relative_change\n');
for d=ids
    S=load(fullfile(cfg.data_dir,[cfg.datasets{d} '.mat']));
    if isfield(S,'fea'), X=double(S.fea'); else, X=double(S.X'); end
    if isfield(S,'gnd'), y=double(S.gnd(:)); else, y=double(S.Y(:)); end
    if size(X,2)~=numel(y), X=X'; end
    [~,~,y]=unique(y); c=max(y); [m,n]=size(X);
    assert(n==cfg.expected_samples(d) && m==cfg.expected_features(d) && c==cfg.expected_classes(d));
    assert(all(isfinite(X(:))) && all(X(:)>=0));
    nr=sqrt(sum(X.^2,1)); nr(nr==0)=1; X=bsxfun(@rdivide,X,nr);
    rng(seed,'twister'); labeled=false(n,1);
    for k=1:c
        ix=find(y==k); ix=ix(randperm(numel(ix)));
        labeled(ix(1:max(1,floor(cfg.label_ratio*numel(ix)))))=true;
    end
    W0=max(rand(m,c),eps); H0=max(rand(c,n),eps);
    opt=cfg; opt.dataset=cfg.datasets{d}; opt.dataset_index=d;
    opt.graph_p=cfg.pce_p_locked; opt.pce_lambda=cfg.pce_lambda_locked(d);
    opt.trace_objective=true;
    clear run_PCE_NMF
    [~,info]=run_PCE_NMF(X,y,labeled,W0,H0,opt);
    f=info.objective_trace; v=info.constraint_trace;
    assert(numel(f)==51 && all(isfinite(f)) && all(isfinite(v)));
    for it=0:50
        if it==0, change=0; else, change=(f(it+1)-f(it))/max(abs(f(it)),1); end
        fprintf(fid,'%s,%d,%d,%.17g,%.17g,%.17g\n',cfg.datasets{d},seed,it,f(it+1),v(it+1),change);
    end
    fprintf('%s: objective %.9g -> %.9g; max increase %.3g; max violation %.3g\n', ...
        cfg.datasets{d},f(1),f(end),max(diff(f)./max(abs(f(1:end-1)),1)),max(v));
end
end
