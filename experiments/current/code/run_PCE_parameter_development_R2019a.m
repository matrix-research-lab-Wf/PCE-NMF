function run_PCE_parameter_development_R2019a()
%RUN_PCE_PARAMETER_DEVELOPMENT_R2019A Labeled-only PCE parameter selection.
% Stage A selects lambda at p=3. Stage B selects p at the chosen lambda.
% Formal seeds and formal unlabeled labels are never used.

cfg = rebuild_config();
addpath(cfg.adapter_dir);
out_dir = fullfile(cfg.results_dir,'parameter_development');
if exist(out_dir,'dir') ~= 7, mkdir(out_dir); end
raw_file = fullfile(out_dir,'raw.csv');
local_init_raw(raw_file);

% ORL and AR cannot support inner labeled validation at the locked 10% pool.
tunable = true(1,numel(cfg.datasets));
tunable(strcmp(cfg.datasets,'ORL') | strcmp(cfg.datasets,'AR')) = false;

for d = find(tunable)
    [X,y] = local_load(cfg,d);
    fprintf('Stage A: %s\n',cfg.datasets{d});
    for s = cfg.seeds_development
        [train_labeled,val_labeled,W0,H0] = local_prepare(X,y,cfg.label_ratio,s);
        for lambda = cfg.pce_dev_lambda_grid
            if local_has_key(raw_file,cfg.datasets{d},s,'lambda', ...
                    cfg.pce_dev_p_fixed,lambda), continue; end
            local_run_one(raw_file,cfg,d,X,y,train_labeled,val_labeled, ...
                W0,H0,s,'lambda',cfg.pce_dev_p_fixed,lambda);
        end
    end
end

stage_a = local_select(raw_file,cfg,'lambda',tunable,[]);
writetable(stage_a,fullfile(out_dir,'stageA_lambda_selected.csv'));

for d = find(tunable)
    [X,y] = local_load(cfg,d);
    lambda = stage_a.selected_lambda(strcmp(stage_a.dataset,cfg.datasets{d}));
    fprintf('Stage B: %s, lambda=%g\n',cfg.datasets{d},lambda);
    for s = cfg.seeds_development
        [train_labeled,val_labeled,W0,H0] = local_prepare(X,y,cfg.label_ratio,s);
        for p = cfg.pce_dev_p_grid
            if local_has_key(raw_file,cfg.datasets{d},s,'p',p,lambda), continue; end
            local_run_one(raw_file,cfg,d,X,y,train_labeled,val_labeled, ...
                W0,H0,s,'p',p,lambda);
        end
    end
end

stage_b = local_select(raw_file,cfg,'p',tunable,stage_a);
writetable(stage_b,fullfile(out_dir,'stageB_p_selected.csv'));
local_write_final(cfg,stage_a,stage_b,tunable,out_dir);
fprintf('PCE parameter development complete.\n');
end

function local_run_one(raw_file,cfg,d,X,y,train_labeled,val_labeled,W0,H0,seed,stage,p,lambda)
status='OK'; msg=''; M=local_empty_metrics(); native_acc=NaN;
try
    opt=cfg; opt.dataset=cfg.datasets{d}; opt.dataset_index=d;
    opt.seed=seed; opt.graph_p=cfg.graph_p; opt.graph_p(d)=p;
    opt.pce_lambda=lambda;
    local_seed(seed);
    pred=run_PCE_NMF(X,y,train_labeled,W0,H0,opt);
    truth=y(val_labeled); guess=pred(val_labeled);
    native_acc=mean(guess(:)==truth(:));
    M=pce_clustering_metrics(truth,guess);
catch err
    status='FAILED'; msg=err.message;
end
fid=fopen(raw_file,'a'); cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s,%d,%s,%g,%.17g,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s,%s\n', ...
    cfg.datasets{d},seed,stage,p,lambda,sum(train_labeled),sum(val_labeled), ...
    native_acc,M.ACC,M.NMI,M.Purity,M.Fscore,M.Precision,M.Recall,status,local_safe(msg));
fprintf('%s seed=%d stage=%s p=%g lambda=%g nativeACC=%.5f %s\n', ...
    cfg.datasets{d},seed,stage,p,lambda,native_acc,status);
end

function Tsel=local_select(raw_file,cfg,stage,tunable,lambda_lock)
T=readtable(raw_file,'Delimiter',',');
T=T(strcmp(T.stage,stage) & strcmp(T.status,'OK'),:);
datasets=cfg.datasets(tunable)'; n=numel(datasets);
selected_lambda=NaN(n,1); selected_p=NaN(n,1);
mean_native_ACC=NaN(n,1); mean_NMI=NaN(n,1); n_records=zeros(n,1);
for i=1:n
    Q=T(strcmp(T.dataset,datasets{i}),:);
    if strcmp(stage,'lambda'), values=cfg.pce_dev_lambda_grid;
    else
        values=cfg.pce_dev_p_grid;
        selected= lambda_lock.selected_lambda(strcmp(lambda_lock.dataset,datasets{i}));
        Q=Q(abs(Q.lambda-selected)<1e-14,:);
    end
    best_score=-Inf; best_nmi=NaN; best_value=NaN; best_count=0;
    for value=values
        if strcmp(stage,'lambda'), R=Q(abs(Q.lambda-value)<1e-14,:);
        else, R=Q(Q.p==value,:); end
        if height(R)~=numel(cfg.seeds_development), continue; end
        score=mean(R.native_ACC); nmi=mean(R.NMI);
        if score>best_score+1e-12 || ...
                (abs(score-best_score)<=1e-12 && value<best_value)
            best_score=score; best_nmi=nmi; best_value=value; best_count=height(R);
        end
    end
    if ~isfinite(best_value), error('Incomplete %s development results for %s.',stage,datasets{i}); end
    mean_native_ACC(i)=best_score; mean_NMI(i)=best_nmi; n_records(i)=best_count;
    if strcmp(stage,'lambda')
        selected_lambda(i)=best_value; selected_p(i)=cfg.pce_dev_p_fixed;
    else
        selected_p(i)=best_value;
        selected_lambda(i)=Q.lambda(1);
    end
end
Tsel=table(datasets,selected_p,selected_lambda,mean_native_ACC,mean_NMI,n_records, ...
    'VariableNames',{'dataset','selected_p','selected_lambda','mean_native_ACC','mean_NMI','n_records'});
end

function local_write_final(cfg,A,B,tunable,out_dir)
dataset=cfg.datasets'; selected_p=NaN(numel(dataset),1);
selected_lambda=NaN(numel(dataset),1); parameter_tag=cell(numel(dataset),1);
for d=find(tunable)
    ia=strcmp(A.dataset,cfg.datasets{d}); ib=strcmp(B.dataset,cfg.datasets{d});
    selected_lambda(d)=A.selected_lambda(ia); selected_p(d)=B.selected_p(ib);
    parameter_tag{d}='labeled-only-development';
end
face={'YaleB','PIE','MSRA25'}; face_p=zeros(numel(face),1); face_lambda=zeros(numel(face),1);
for i=1:numel(face)
    d=find(strcmp(dataset,face{i})); face_p(i)=selected_p(d); face_lambda(i)=selected_lambda(d);
end
transfer_p=median(face_p); transfer_lambda=10^median(log10(face_lambda));
transfer_lambda=cfg.pce_dev_lambda_grid(find(abs(log10(cfg.pce_dev_lambda_grid)-log10(transfer_lambda))== ...
    min(abs(log10(cfg.pce_dev_lambda_grid)-log10(transfer_lambda))),1,'first'));
for name={'ORL','AR'}
    d=find(strcmp(dataset,name{1})); selected_p(d)=transfer_p;
    selected_lambda(d)=transfer_lambda; parameter_tag{d}='transferred-face-development';
end
development_seeds=repmat({'20261009:20261013'},numel(dataset),1);
selection_criterion=repmat({'mean native validation ACC; smaller value on exact tie; NMI diagnostic only'},numel(dataset),1);
T=table(dataset,selected_p,selected_lambda,parameter_tag,development_seeds,selection_criterion);
writetable(T,fullfile(out_dir,'PCE_PARAMETER_LOCK.csv'));
end

function [X,y]=local_load(cfg,d)
S=load(fullfile(cfg.data_dir,[cfg.datasets{d} '.mat']));
if isfield(S,'fea'), X=double(S.fea'); else, X=double(S.X'); end
if isfield(S,'gnd'), y=double(S.gnd(:)); else, y=double(S.Y(:)); end
if size(X,2)~=numel(y), X=X'; end
[~,~,y]=unique(y); nr=sqrt(sum(X.^2,1)); nr(nr==0)=1; X=bsxfun(@rdivide,X,nr);
end

function [train_labeled,val_labeled,W0,H0]=local_prepare(X,y,ratio,seed)
local_seed(seed); n=numel(y); c=max(y); pool=false(n,1);
for k=1:c
    idx=find(y==k); idx=idx(randperm(numel(idx)));
    pool(idx(1:max(1,floor(ratio*numel(idx)))))=true;
end
train_labeled=false(n,1); val_labeled=false(n,1);
for k=1:c
    idx=find(pool & y==k); idx=idx(randperm(numel(idx)));
    if numel(idx)<2, error('Class %d has fewer than two labeled-pool samples.',k); end
    nt=min(numel(idx)-1,max(1,floor(0.8*numel(idx))));
    train_labeled(idx(1:nt))=true; val_labeled(idx(nt+1:end))=true;
end
W0=max(rand(size(X,1),c),eps); H0=max(rand(c,size(X,2)),eps);
end

function tf=local_has_key(file,dataset,seed,stage,p,lambda)
tf=false; if exist(file,'file')~=2, return; end
T=readtable(file,'Delimiter',','); if isempty(T), return; end
tf=any(strcmp(T.dataset,dataset) & T.seed==seed & strcmp(T.stage,stage) & ...
    T.p==p & abs(T.lambda-lambda)<1e-14 & strcmp(T.status,'OK'));
end

function local_init_raw(file)
if exist(file,'file')==2, return; end
fid=fopen(file,'w'); cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['dataset,seed,stage,p,lambda,n_train_labels,n_validation_labels,' ...
    'native_ACC,ACC,NMI,Purity,Fscore,Precision,Recall,status,message\n']);
end

function M=local_empty_metrics()
M=struct('ACC',NaN,'NMI',NaN,'Purity',NaN,'Fscore',NaN,'Precision',NaN,'Recall',NaN);
end

function local_seed(seed)
rand('twister',seed); randn('state',seed); %#ok<RAND>
end

function s=local_safe(s)
if ~ischar(s), s=''; end
s=strrep(s,',',';'); s=strrep(s,sprintf('\n'),' '); s=strrep(s,sprintf('\r'),' ');
end
